const express = require('express');
// eslint-disable-next-line new-cap
const router = express.Router();

// returns the name of the user
router.post('/', (req, res, next) => {
  const data = req.body;
  console.log(`hello ${data.name}! nice to meet you!`);
  res.status(200).send('testing');
});

module.exports = router;
