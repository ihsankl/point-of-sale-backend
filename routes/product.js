/* eslint-disable camelcase */
const knex = require('../lib/database');
const helper = require('../lib/helper');
const express = require('express');
const {auth} = require('../lib/middleware');
// eslint-disable-next-line new-cap
const router = express.Router();

// create product
router.post('/', auth, async (req, res, next) => {
  const {
    code,
    name,
    unit_in_stock,
    disc_percentage,
    unit_price,
    re_order_level = 0,
    unit_id,
    category_id,
    user_id,
    distributor_price,
  } = req.body;
  const query = knex.transaction(async (trx) => {
    try {
      // check if product code already exist
      const productCode = await trx('Product')
          .where({code})
          .select('id');
      if (productCode.length > 0) {
        throw new Error('Product code already exist');
      }
      return await trx.insert({
        code,
        name,
        unit_in_stock,
        disc_percentage,
        unit_price,
        re_order_level,
        unit_id,
        category_id,
        user_id,
        distributor_price,
      }).into('Product');
    } catch (error) {
      throw new Error(error);
    }
  });
  const result = await helper.knexQuery(query);
  res.status(result.status).send(result);
});

// get products with pagination filtered by name or category
router.get('/pagination', auth, async (req, res, next) => {
  const {page, limit, name = '', category_id = 0} = req.query;
  const query = knex
      .select(
          'a.*',
          'a.id as product_id',
          'b.name as unit_name',
          'c.name as category_name',
          'd.username',
      )
      .from('Product as a')
      .leftJoin('Product Unit as b', 'a.unit_id', 'b.id')
      .leftJoin('Product Category as c', 'a.category_id', 'c.id')
      .leftJoin('User as d', 'a.user_id', 'd.id')
      .where('a.name', 'like', `%${name}%`)
      .orWhere('a.category_id', category_id)
      .limit(limit)
      .offset(page)
      .orderBy('a.name', 'asc');
  const result = await helper.knexQuery(query, `getProduct:${page}`);

  // generate metadata
  const total = result.data.length;
  const data = {
    total: total,
    limit: limit,
    page: page,
    params: req.query,
    base_url: `${req.protocol}://${req.get('host')}/api/product/pagination`,
  };
  const _metadata = helper.generateMetadata(data);
  res.status(result.status).send({...result, _metadata});
});

// get all products
router.get('/', auth, async (req, res, next) => {
  const query = knex
      .select(
          'a.*',
          'a.id as product_id',
          'b.name as unit_name',
          'c.name as category_name',
          'd.username',
      )
      .from('Product as a')
      .leftJoin('Product Unit as b', 'a.unit_id', 'b.id')
      .leftJoin('Product Category as c', 'a.category_id', 'c.id')
      .leftJoin('User as d', 'a.user_id', 'd.id')
      .orderBy('a.name', 'asc');
  const result = await helper.knexQuery(query, 'allProducts');
  res.status(result.status).send(result);
});

// get 1 product
router.get('/:id', auth, async (req, res, next) => {
  const {id} = req.params;
  const query = knex
      .select(
          'a.id as product_id',
          'a.*',
          'b.name as unit_name',
          'c.name as category_name',
          'd.username',
      )
      .from('Product as a')
      .leftJoin('Product Unit as b', 'a.unit_id', 'b.id')
      .leftJoin('Product Category as c', 'a.category_id', 'c.id')
      .leftJoin('User as d', 'a.user_id', 'd.id')
      .where({id});
  const result = await helper.knexQuery(query);
  res.status(result.status).send(result);
});

// update product
router.put('/:id', auth, async (req, res, next) => {
  const {id} = req.params;
  const {
    code,
    name,
    unit_in_stock,
    disc_percentage,
    unit_price,
    re_order_level = 0,
    unit_id,
    category_id,
    user_id,
    distributor_price,
  } = req.body;
  const query = knex('Product')
      .where({id})
      .update({
        code,
        name,
        unit_in_stock,
        disc_percentage,
        unit_price,
        re_order_level,
        unit_id,
        category_id,
        user_id,
        distributor_price,
      });
  const result = await helper.knexQuery(query);
  res.status(result.status).send(result);
});

// delete product
router.delete('/:id', auth, async (req, res, next) => {
  const {id} = req.params;
  const query = knex('Product').where({id}).del();
  const result = await helper.knexQuery(query);
  res.status(result.status).send(result);
});

module.exports = router;
