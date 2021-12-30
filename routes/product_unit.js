const knex = require('../lib/database');
const helper = require('../lib/helper');
const express = require("express");
const { auth } = require('../lib/middleware');
const router = express.Router();

// create product unit
router.post("/", auth, async (req, res, next) => {
    const { name } = req.body;
    const query = knex("Product Unit").insert({ name });
    const result = await helper.knexQuery(query);
    res.status(result.status).send(result);
});

// get all product units
router.get("/", auth, async (req, res, next) => {
    const query = knex("Product Unit").select("*");
    const result = await helper.knexQuery(query);
    res.status(result.status).send(result);
});

// get 1 product unit
router.get("/:id", auth, async (req, res, next) => {
    const { id } = req.params;
    const query = knex("Product Unit").where({ id });
    const result = await helper.knexQuery(query);
    res.status(result.status).send(result);
});

// update product unit
router.put("/:id", auth, async (req, res, next) => {
    const { id } = req.params;
    const { name } = req.body;
    const query = knex("Product Unit").where({ id }).update({ name });
    const result = await helper.knexQuery(query);
    res.status(result.status).send(result);
});

// delete product unit
router.delete("/:id", auth, async (req, res, next) => {
    const { id } = req.params;
    const query = knex("Product Unit").where({ id }).del();
    const result = await helper.knexQuery(query);
    res.status(result.status).send(result);
});

module.exports = router;