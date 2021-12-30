const express = require("express");
const router = express.Router();
const knex = require("../lib/database.js");
const helper = require("../lib/helper.js");
const { auth, admin } = require("../lib/middleware.js");

// create user
router.post("/", async (req, res, next) => {
  const { username, password, role } = req.body;
  const hash = helper.encrypt(password);

  const alreadyExists = await knex("User").where({ username });

  if (!alreadyExists) {
    const query = knex("User").insert({ username, password: hash, role });
    const result = await helper.knexQuery(query);
    res.status(result.status).send(result);
  } else {
    res.status(503).send({
      status: 503,
      data: null,
      message: "User already exists!"
    });
  }

  // example using commit and rollback
  // try {
  //   const query = knex.transaction(async trx => {
  //     const hash = helper.encrypt(password);
  //     try {
  //       await trx("User").insert({ username, password: hash, role })
  //       await trx.commit()
  //     } catch (error) {
  //       trx.rollback();
  //     }
  //   })
  //   res.status(201).send("User created");
  //   if (query) {
  //   }
  // } catch (error) {
  //   console.log(`\x1b[0m[LOG] ${error.message}`);
  //   res.status(500).send(error.message);
  // }

});

// delete user
router.delete("/:id", auth, admin, async (req, res, next) => {
  const { id } = req.params;
  const query = knex("User").where({ id }).del();
  const result = await helper.knexQuery(query);
  res.status(result.status).send(result);
});

// update user
router.put("/:id", auth, admin, async (req, res, next) => {
  const { id } = req.params;
  const { username, password, role, fullname = "-", contact = "-" } = req.body;
  const alreadyExists = await knex("User").where({ username });

  if (!alreadyExists) {
    const query = knex("User").where({ id }).update({ username, password, role, fullname, contact });
    const result = await helper.knexQuery(query);
    res.status(result.status).send(result);
  } else {
    res.status(503).send({
      status: 503,
      data: null,
      message: "User already exists!"
    });
  }
});

// get all users
router.get("/", async (req, res, next) => {
  const query = knex("User").select("*");
  const result = await helper.knexQuery(query);
  res.status(result.status).send({ ...result, _metadata: { total_count: result.data.length } });
});

// get all user with pagination
router.get("/pagination", async (req, res, next) => {
  const { page, limit } = req.query;
  const offset = (page - 1) * limit;
  const query = knex("User").select("*").offset(offset).limit(limit);
  const result = await helper.knexQuery(query);
  const totalCount = knex("User").count("* as total");
  const total = await helper.knexQuery(totalCount);
  const data = {
    total: total.data?.[0]?.total,
    limit: limit,
    page,
    params: req.query,
    base_url: `${req.protocol}://${req.get("host")}/api/user/pagination`,
  }
  const metadata = helper.generateMetadata(data)
  res.status(result.status).send({ ...result, _metadata: metadata });
});

// get 1 user
router.get("/:id", async (req, res, next) => {
  const { id } = req.params;
  const query = knex("User").where({ id }).select("*");
  const result = await helper.knexQuery(query);
  res.status(result.status).send(result);
});

module.exports = router;
