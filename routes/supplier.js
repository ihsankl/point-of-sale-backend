const knex = require('../lib/database');
const helper = require('../lib/helper');
const express = require('express');
const {auth} = require('../lib/middleware');
// eslint-disable-next-line new-cap
const router = express.Router();

// create supplier
router.post('/', auth, async (req, res, next) => {
  const {code, name, address, contact, email} = req.body;
  const query = knex('Supplier').insert({code, name, address, contact, email});
  const result = await helper.knexQuery(query);
  res.status(result.status).send(result);
});

// get all suppliers
router.get('/', auth, async (req, res, next) => {
  const query = knex('Supplier').select('*');
  const result = await helper.knexQuery(query, 'getAllSuppliers');
  res.status(result.status).send(result);
});

// get 1 supplier
router.get('/:id', auth, async (req, res, next) => {
  const {id} = req.params;
  const query = knex('Supplier').where({id});
  const result = await helper.knexQuery(query);
  res.status(result.status).send(result);
});

// update supplier
router.put('/:id', auth, async (req, res, next) => {
  const {id} = req.params;
  const {code, name, address, contact, email} = req.body;
  const query = knex('Supplier')
      .where({id}).update({code, name, address, contact, email});
  const result = await helper.knexQuery(query);
  res.status(result.status).send(result);
});

// delete supplier
router.delete('/:id', auth, async (req, res, next) => {
  const {id} = req.params;
  const query = knex('Supplier').where({id}).del();
  const result = await helper.knexQuery(query);
  res.status(result.status).send(result);
});

module.exports = router;
