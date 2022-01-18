/* eslint-disable camelcase */
const bcrypt = require('bcryptjs');
const secret = process.env.APP_KEY;
const jwt = require('jsonwebtoken');
const Redis = require('ioredis');

const redisClient = new Redis({
  port: 6379,
  host: process.env.REDIS_URL,
});

// 24 hours in milliseconds
const DEFAULT_EXPIRATION = 24 * 60 * 60 * 1000;

const encrypt = (data) => {
  return bcrypt.hashSync(data, 10);
};

const compare = (data, hash) => {
  return bcrypt.compareSync(data, hash);
};

// TODO: add specific http response codes
// TODO: add seeder
const knexQuery = async (query, key = undefined) => {
  return new Promise(async (resolve, reject) => {
    try {
      let data = null;
      if (!!key) {
        data = await getSetDataFromCache(key, query);
      } else {
        data = await query;
      }
      resolve({
        status: 200,
        success: true,
        data,
        message: 'Success',
      });
    } catch (error) {
      resolve({
        status: 503,
        success: false,
        data: null,
        message: error.message,
      });
    }
  });
};

// create jwt token
const generateJwtToken = (data) => {
  return jwt.sign(data, secret);
};

// jwt decode
const decodeJwtToken = (token) => {
  return jwt.verify(token, secret);
};

// create unique id
const uuid = () => {
  return Math.random().toString(36).substring(2, 15) +
  Math.random().toString(36).substring(2, 15);
};

// generate metadata
const generateMetadata = (data) => {
  const page_count = Math.ceil(data.total / data.limit);
  let params = '&';
  for (const property in data.params) {
    if (data.params.hasOwnProperty(property)) {
      params += `${property}=${data.params[property]}&`;
    }
  }
  return {
    page_count,
    current_page: data.page,
    next_page: data.page < page_count ? data.page.parseInt() + 1 : null,
    prev_page: data.page > 1 ? data.page.parseInt() - 1 : null,
    first_page: 1,
    last_page: page_count,
    links: {
      first: `${data.base_url}?page=1&limit=${data.limit}${params}`,
      last: `${data.base_url}?page=${page_count}&limit=${data.limit}${params}`,
      prev: data.page > 1 ?
      `${data.base_url}?page=${data.page - 1}&limit=${data.limit}${params}` :
      null,
      next: data.page < page_count ?
      // eslint-disable-next-line max-len
      `${data.base_url}?page=${parseInt(data.page) + 1}&limit=${data.limit}${params}` :
      null,
      current:
      `${data.base_url}?page=${data.page}&limit=${data.limit}${params}`,
    },
    total_count: data.total,
  };
};

const getSetDataFromCache = async (key, query) => {
  try {
    redisClient.on('ready', async ()=> {
      console.log('\x1b[32m[LOG] Redis client started.');
      handleData(key, query);
    });
    redisClient.on('error', async (error)=> {
      handleError(error);
    });
    redisClient.removeListener('error', handleError);
    redisClient.removeListener('ready', handleData);
    return await query;
  } catch (error) {
    throw new Error(error);
  }
};

const handleData = async (key, query) => {
  const data = await redisClient.get(key);
  if (!!data) return JSON.parse(data);
  const result = await query;
  await redisClient
      .setex(key, DEFAULT_EXPIRATION, JSON.stringify(result));
  return result;
};

const handleError = async (error) => {
  console.log(`\x1b[32m[LOG] Redis client error: ${error.message}`);
};
module.exports = {
  encrypt,
  compare,
  knexQuery,
  uuid,
  generateJwtToken,
  decodeJwtToken,
  generateMetadata,
  getSetDataFromCache,
  redisClient,
};
