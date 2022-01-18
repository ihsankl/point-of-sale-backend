/* eslint-disable camelcase */
const knex = require('../lib/database');
const helper = require('../lib/helper');
const express = require('express');
const {auth} = require('../lib/middleware');
// eslint-disable-next-line new-cap
const router = express.Router();

// create invoice
router.post('/', auth, async (req, res, next) => {
  const {
    total_amount,
    amount_tendered,
    date_recorded,
    user_id,
    customer_id} =
     req.body;
  const query = knex('Invoice')
      .insert({
        total_amount,
        amount_tendered,
        date_recorded,
        user_id,
        customer_id,
      });
  const result = await helper.knexQuery(query);
  res.status(result.status).send(result);
});

// get invoice with pagination and filtered by date_recorded
router.get('/pagination', auth, async (req, res, next) => {
  const {page, limit, date_from, date_to} = req.query;
  const query = knex
      .select(
          'a.*',
          'b.username as user_name',
          'c.name as customer',
      )
      .from('Invoice as a')
      .leftJoin('User as b', 'a.user_id', 'b.id')
      .leftJoin('Customer as c', 'a.customer_id', 'c.id')
      .whereBetween('date_recorded', [date_from, date_to])
      .limit(limit).offset(page);
  const result = await helper.knexQuery(query, `getInvoicePage:${page}`);
  // generate metadata
  const data = {
    total_data: result.data.length,
    limit: limit,
    page: page,
    params: req.query,
    base_url: `${req.protocol}://${req.get('host')}/api/invoice`,
  };
  const _metadata = helper.generateMetadata(data);
  res.status(result.status).send({...result, _metadata});
});

// get all invoices
router.get('/', auth, async (req, res, next) => {
  const query = knex
      .select(
          'a.*',
          'b.username as user_name',
          'c.name as customer',
      )
      .from('Invoice as a')
      .leftJoin('User as b', 'a.user_id', 'b.id')
      .leftJoin('Customer as c', 'a.customer_id', 'c.id');
  const result = await helper.knexQuery(query, 'getAllInvoice');
  res.status(result.status).send(result);
});

// get 1 invoice
router.get('/:id', auth, async (req, res, next) => {
  const {id} = req.params;
  const query = knex
      .select(
          'a.*',
          'b.username as user_name',
          'c.name as customer',
      )
      .from('Invoice as a')
      .leftJoin('User as b', 'a.user_id', 'b.id')
      .leftJoin('Customer as c', 'a.customer_id', 'c.id')
      .where({id});
  const result = await helper.knexQuery(query);
  res.status(result.status).send(result);
});

// update invoice
router.put('/:id', auth, async (req, res, next) => {
  const {id} = req.params;
  const {
    total_amount,
    amount_tendered,
    date_recorded,
    user_id,
    customer_id,
  } = req.body;
  const query = knex('Invoice')
      .where({id})
      .update({
        total_amount,
        amount_tendered,
        date_recorded,
        user_id,
        customer_id,
      });
  const result = await helper.knexQuery(query);
  res.status(result.status).send(result);
});

module.exports = router;
