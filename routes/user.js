const express = require('express');
// eslint-disable-next-line new-cap
const router = express.Router();
const knex = require('../lib/database.js');
const helper = require('../lib/helper.js');
const {auth, admin} = require('../lib/middleware.js');

// create user
router.post('/', async (req, res, next) => {
  const {username, password, role} = req.body;
  const hash = helper.encrypt(password);

  const query = knex.transaction(async (trx) => {
    try {
      const alreadyExists = await trx('User').where({username});
      if (!alreadyExists.length > 0) {
        return await trx('User').insert({username, password: hash, role});
      } else {
        throw new Error('User already exists');
      }
    } catch (error) {
      throw new Error(error);
    }
  });
  const result = await helper.knexQuery(query);
  res.status(result.status).send(result);
});

// delete user
router.delete('/:id', auth, admin, async (req, res, next) => {
  const {id} = req.params;
  const query = knex('User').where({id}).del();
  const result = await helper.knexQuery(query);
  res.status(result.status).send(result);
});

// update user
router.put('/:id', auth, admin, async (req, res, next) => {
  const {id} = req.params;
  const {username, password, role, fullname = '-', contact = '-'} = req.body;

  const hash = helper.encrypt(password);

  const query = knex.transaction(async (trx) => {
    try {
      const alreadyExists = await trx('User').where({username});
      if (!alreadyExists.length > 0) {
        return await trx('User')
            .where({id})
            .update({username, password: hash, role, fullname, contact});
      } else {
        throw new Error('User already exists');
      }
    } catch (error) {
      throw new Error(error);
    }
  });
  const result = await helper.knexQuery(query);
  res.status(result.status).send(result);
});

// get all users
router.get('/', async (req, res, next) => {
  const query = knex('User').select('*');
  const result = await helper.knexQuery(query, 'getAllUsers');
  res.status(result.status).send(result);
});

// get all user with pagination
router.get('/pagination', async (req, res, next) => {
  const {page, limit} = req.query;
  const offset = (page - 1) * limit;
  const query = knex('User').select('*').offset(offset).limit(limit);
  const result = await helper.knexQuery(query, `getAllUsersPage:${page}`);
  const totalCount = knex('User').count('* as total');
  const total = await helper.knexQuery(totalCount);
  const data = {
    total: total.data?.[0]?.total,
    limit: limit,
    page,
    params: req.query,
    base_url: `${req.protocol}://${req.get('host')}/api/user/pagination`,
  };
  const metadata = helper.generateMetadata(data);
  res.status(result.status).send({...result, _metadata: metadata});
});

// get 1 user
router.get('/:id', async (req, res, next) => {
  const {id} = req.params;
  const query = knex('User').where({id}).select('*');
  const result = await helper.knexQuery(query);
  res.status(result.status).send(result);
});

module.exports = router;
