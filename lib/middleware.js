/* eslint-disable camelcase */

const knex = require('./database');
const {decodeJwtToken} = require('./helper');
const secret = process.env.APP_KEY;

// authentication middleware
const auth = async (req, res, next) => {
  try {
    if (req.headers.authorization &&
      req.headers.authorization.startsWith('Bearer')) {
      const jwt_token = req.headers.authorization.substr(7);
      const tokenExist = await knex('Revoked Tokens').where({token: jwt_token});
      if (tokenExist.length > 0 && tokenExist[0].signed_out === 0) {
        try {
          const decoded = decodeJwtToken(jwt_token, secret);
          if (decoded) {
            next();
          } else {
            throw new Error('Invalid Token');
          }
        } catch (error) {
          throw new Error(error);
        }
      } else {
        throw new Error('Token not found. Please Login!');
      }
    } else {
      throw new Error('Please Login!');
    }
  } catch (error) {
    res.status(503).send({
      status: 503,
      success: false,
      data: null,
      message: error.message,
    });
  }
};

// admin only
const admin = async (req, res, next) => {
  try {
    if (req.headers.authorization &&
      req.headers.authorization.startsWith('Bearer')) {
      const jwt_token = req.headers.authorization.substr(7);
      const user = decodeJwtToken(jwt_token, secret);
      if (user.role === 'admin') {
        next();
      } else {
        throw new Error('You have no Access to do that!');
      }
    } else {
      throw new Error('Please Login!');
    }
  } catch (error) {
    res.status(503).send({
      status: 503,
      success: false,
      data: null,
      message: error.message,
    });
  }
};

// cashier only
const cashier = async (req, res, next) => {
  try {
    if (req.headers.authorization &&
      req.headers.authorization.startsWith('Bearer')) {
      const jwt_token = req.headers.authorization.substr(7);
      const user = decodeJwtToken(jwt_token, secret);
      if (user.role === 'cashier') {
        next();
      } else {
        throw new Error('You have no Access to do that!');
      }
    } else {
      throw new Error('Please Login!');
    }
  } catch (error) {
    res.status(503).send({
      status: 503,
      success: false,
      data: null,
      message: error.message,
    });
  }
};

module.exports = {
  auth,
  admin,
  cashier,
};
