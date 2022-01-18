const knex = require('../lib/database');
const helper = require('../lib/helper');
const express = require('express');
const {auth} = require('../lib/middleware');
// eslint-disable-next-line new-cap
const router = express.Router();

// create customer
router.post('/', auth, async (req, res, next) => {
  const {code, name, address, contact} = req.body;
  const query = knex('Customer').insert({code, name, address, contact});
  const result = await helper.knexQuery(query);
  res.status(result.status).send(result);
});

// get all customers
router.get('/', auth, async (req, res, next) => {
  const query = knex('Customer').select('*');
  const result = await helper.knexQuery(query, 'getAllCustomers');
  res.status(result.status).send(result);
});

// get 1 customer
router.get('/:id', auth, async (req, res, next) => {
  const {id} = req.params;
  const query = knex('Customer').where({id});
  const result = await helper.knexQuery(query);
  res.status(result.status).send(result);
});

// update customer
router.put('/:id', auth, async (req, res, next) => {
  const {id} = req.params;
  const {code, name, address, contact} = req.body;
  const query = knex('Customer')
      .update({code, name, address, contact})
      .where({id});
  const result = await helper.knexQuery(query);
  res.status(result.status).send(result);
});

// delete customer
router.delete('/:id', auth, async (req, res, next) => {
  const {id} = req.params;
  const query = knex('Customer').where({id}).del();
  const result = await helper.knexQuery(query);
  res.status(result.status).send(result);
});

module.exports = router;
