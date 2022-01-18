const knex = require('../lib/database');
const helper = require('../lib/helper');
const express = require('express');
const {auth} = require('../lib/middleware');
// eslint-disable-next-line new-cap
const router = express.Router();

// testing endpoint
router.get('/test', auth, async (req, res, next) => {
  const {id} = req.query;
  const query = await knex('Product').where({id}).select('id');
  console.log(query[0].id);
  // const result = await helper.knexQuery(query);
  res.status(200).send('result');
});

// create category
router.post('/', auth, async (req, res, next) => {
  const {name} = req.body;
  const query = knex('Product Category').insert({name});
  const result = await helper.knexQuery(query);
  res.status(result.status).send(result);
});

// get all categories
router.get('/', auth, async (req, res, next) => {
  const query = knex('Product Category').select('*');
  const result = await helper.knexQuery(query, 'allCategory');
  res.status(result.status).send(result);
});

// get 1 category
router.get('/:id', auth, async (req, res, next) => {
  const {id} = req.params;
  const query = knex('Product Category').where({id});
  const result = await helper.knexQuery(query);
  res.status(result.status).send(result);
});

// update category
router.put('/:id', auth, async (req, res, next) => {
  const {id} = req.params;
  const {name} = req.body;
  const query = knex('Product Category').where({id}).update({name});
  const result = await helper.knexQuery(query);
  res.status(result.status).send(result);
});

// delete category
router.delete('/:id', auth, async (req, res, next) => {
  const {id} = req.params;
  const query = knex('Product Category').where({id}).del();
  const result = await helper.knexQuery(query);
  res.status(result.status).send(result);
});

module.exports = router;
