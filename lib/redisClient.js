const Redis = require('ioredis');

const client = new Redis({
  port: 6379,
  host: process.env.REDIS_URL,
});

client.on('connect', () => {
  console.log('\x1b[32m[LOG] Redis client started.');
});

client.on('error', (error) => {
  console.log('\x1b[31m[ERR] Redis client error:', error);
});

client.on('end', () => {
  console.log('\x1b[31m[ERR] Redis client closed.');
});

client.on('ready', () => {
  console.log('\x1b[32m[LOG] Redis client ready.');
});

module.exports = client;
