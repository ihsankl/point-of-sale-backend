const express = require('express');
const jwt = require('jsonwebtoken');
// eslint-disable-next-line new-cap
const router = express.Router();
const secret = process.env.APP_KEY;

const knex = require('../lib/database.js');
const helper = require('../lib/helper.js');
const {auth} = require('../lib/middleware.js');

// user login
router.post('/login', async (req, res, next) => {
  const {username, password} = req.body;
  // let usernameQuery;
  const query = knex.transaction(async (trx) => {
    try {
      const usernameExists = await trx('User').where({username});
      if (usernameExists.length > 0) {
        const passwordMatch = helper.compare(
            password, usernameExists[0].password,
        );
        if (passwordMatch) {
          const token = jwt.sign({
            ...usernameExists[0],
          }, secret, {expiresIn: '24h'});
          await trx('Revoked Tokens').insert({token, signed_out: 0});
          return token;
        } else {
          throw new Error('Wrong password');
        }
      } else {
        throw new Error('User not found');
      }
    } catch (error) {
      throw new Error(error);
    }
  });
  const result = await helper.knexQuery(query);
  res.status(result.status).send(result);
});

// user logout
router.post('/logout', auth, async (req, res, next) => {
  const token = req.headers.authorization.substr(7);
  const query = knex.transaction(async (trx) => {
    try {
      const signedOut = await trx('Revoked Tokens').where({token});
      if (signedOut.length > 0) {
        await trx('Revoked Tokens').where({token}).update({signed_out: 1});
        return 'Logged out';
      } else {
        throw new Error('Token not found');
      }
    } catch (error) {
      throw new Error(error);
    }
  });
  const result = await helper.knexQuery(query);
  res.status(result.status).send(result);
});

// check if token is valid
router.get('/check', auth, async (req, res, next) => {
  const token = req.headers.authorization.substr(7);
  const query = knex.transaction(async (trx) => {
    try {
      const revoked = await trx('Revoked Tokens').where({token});
      if (revoked.length > 0) {
        if (revoked[0].signed_out === 0) {
          // return back the token
          return token;
        } else {
          throw new Error('Token has been revoked');
        }
      } else {
        throw new Error('Token not found');
      }
    } catch (error) {
      throw new Error(error);
    }
  });
  const result = await helper.knexQuery(query);
  res.status(result.status).send(result);
});

module.exports = router;
