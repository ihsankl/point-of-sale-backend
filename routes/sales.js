/* eslint-disable camelcase */
const knex = require('../lib/database');
const helper = require('../lib/helper');
const express = require('express');
const {auth} = require('../lib/middleware');
// eslint-disable-next-line new-cap
const router = express.Router();
const dayjs = require('dayjs');

// create sales
router.post('/', auth, async (req, res, next) => {
  const {
    products,
    user_id,
    customer_id,
    date_recorded = dayjs(new Date()).format('YYYY-MM-DD'),
    invoice_id,
    amount_tendered,
  } = req.body;
  const query = knex.transaction(async (trx) => {
    try {
      const total_amount = products
          .reduce((acc, cur) => acc + cur.sub_total, 0);
      const invoiceId = await trx('Invoice')
          .insert({
            total_amount,
            amount_tendered,
            date_recorded,
            user_id,
            customer_id,
          });
      const promises = [];
      products.map( (v, i) => {
        const x = trx('Product')
            .update({unit_in_stock: knex.raw('unit_in_stock - ?', v.qty)})
            .where({id: v.product_id});
        const y = trx('Sales')
            .insert({
              qty: v.qty,
              unit_price: v.unit_price,
              sub_total: v.sub_total,
              invoice_id: invoice_id ?? invoiceId[0],
              product_id: v.product_id,
            });
        promises.push(x, y);
      });
      return await Promise.all(promises);
    } catch (error) {
      throw new Error(error);
    }
  });
  const result = await helper.knexQuery(query);
  res.status(result.status).send(result);
});

// get sales with pagination filtered by date
router.get('/pagination', auth, async (req, res, next) => {
  const {page, limit, start_date, end_date} = req.query;
  const offset = (page - 1) * limit;
  const query = knex
      .select(
          'a.*',
          'b.total_amount',
          'b.amount_tendered',
          'b.date_recorded',
          'c.name',
      )
      .from('Sales')
      .leftJoin('Invoice as b', 'b.id', 'a.invoice_id')
      .leftJoin('Product as c', 'c.id', 'a.product_id')
      .whereBetween('b.date_recorded', [start_date, end_date])
      .offset(offset)
      .limit(limit);
  const result = await helper.knexQuery(query, `getSalesPage:${page}`);
  // generate metadata
  const data = {
    total_data: result.data.length,
    limit: limit,
    page: page,
    params: req.query,
    base_url: `${req.protocol}://${req.get('host')}/api/sales/`,
  };
  const _metadata = helper.generateMetadata(data);
  res.status(result.status).send({...result, _metadata});
});

// get all sales
router.get('/', auth, async (req, res, next) => {
  const query = knex
      .select(
          'a.*',
          'b.total_amount',
          'b.amount_tendered',
          'b.date_recorded',
          'c.name',
      )
      .from('Sales as a')
      .leftJoin('Invoice as b', 'b.id', 'a.invoice_id')
      .leftJoin('Product as c', 'c.id', 'a.product_id');
  const result = await helper.knexQuery(query, 'getAllSales');
  res.status(result.status).send(result);
});

// get 1 sales
router.get('/:id', auth, async (req, res, next) => {
  const {id} = req.params;
  const query = knex
      .select(
          'a.*',
          'b.total_amount',
          'b.amount_tendered',
          'b.date_recorded',
          'c.name',
      )
      .from('Sales as a')
      .leftJoin('Invoice as b', 'b.id', 'a.invoice_id')
      .leftJoin('Product as c', 'c.id', 'a.product_id')
      .where({id});
  const result = await helper.knexQuery(query);
  res.status(result.status).send(result);
});

// update sales
router.put('/:id', auth, async (req, res, next) => {
  const {id} = req.params;
  const {qty, unit_price, sub_total, invoice_id, product_id} = req.body;
  const query = knex('Sales')
      .where({id}).update({qty, unit_price, sub_total, invoice_id, product_id});
  const result = await helper.knexQuery(query);
  res.status(result.status).send(result);
});

// delete sales
router.delete('/:id', auth, async (req, res, next) => {
  const {id} = req.params;
  const query = knex('Sales').where({id}).del();
  const result = await helper.knexQuery(query);
  res.status(result.status).send(result);
});

module.exports = router;
