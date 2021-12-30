const knex = require('../lib/database');
const helper = require('../lib/helper');
const express = require("express");
const { auth } = require('../lib/middleware');
const router = express.Router();

// create receive product
router.post("/", auth, async (req, res, next) => {
    const { qty, unit_price, sub_total, received_date, product_id, user_id, supplier_id } = req.body;
    const query = knex.transaction(async (trx) => {
        try {
            const productId = await trx("Product").where({ id: product_id }).select("id");
            const x = await trx.insert({ qty, unit_price, sub_total, received_date, product_id: productId[0].id, user_id, supplier_id }).into("Receive Product");
            await trx("Product").where({ id: productId[0].id }).update({ qty: knex.raw("qty + ?", [qty]) });
            return x
        } catch (error) {
            throw new Error(error);
        }
    })
    const result = await helper.knexQuery(query);
    res.status(result.status).send(result);
});

// get receive product with pagination filtered by received_date
router.get("pagination", auth, async (req, res, next) => {
    const { page, limit, date_from, date_to, } = req.query;
    const query = knex
        .select(
            "a.qty",
            "a.unit_price",
            "a.sub_total",
            "a.received_date",
            "a.product_id",
            "b.name as product_name",
            "c.name as supplier_name"
        )
        .from("Receive Product as a")
        .leftJoin("Product as b", "a.product_id", "b.id")
        .leftJoin("Supplier as c", "a.supplier_id", "c.id")
        .whereBetween("received_date", [date_from, date_to,])
        .limit(limit)
        .offset(page);
    const result = await helper.knexQuery(query);
    // generate metadata
    const data = {
        total_data: result.data.length,
        limit: limit,
        page: page,
        params: req.query,
        base_url: `${req.protocol}://${req.get("host")}/api/receive_product/pagination`,
    };
    const _metadata = helper.generateMetadata(data);
    res.status(result.status).send({ ...result, _metadata });
});

// get all receive products
router.get("/", auth, async (req, res, next) => {
    const query = knex("Receive Product").select("*");
    const result = await helper.knexQuery(query);
    res.status(result.status).send(result);
});

// get 1 receive product
router.get("/:id", auth, async (req, res, next) => {
    const { id } = req.params;
    const query = knex("Receive Product").where({ id });
    const result = await helper.knexQuery(query);
    res.status(result.status).send(result);
});

// update receive product
router.put("/:id", auth, async (req, res, next) => {
    const { id } = req.params;
    const { qty, unit_price, sub_total, received_date, product_id, user_id, supplier_id } = req.body;
    const query = knex("Receive Product").where({ id }).update({ qty, unit_price, sub_total, received_date, product_id, user_id, supplier_id });
    const result = await helper.knexQuery(query);
    res.status(result.status).send(result);
});

// delete receive product
router.delete("/:id", auth, async (req, res, next) => {
    const { id } = req.params;
    const query = knex("Receive Product").where({ id }).del();
    const result = await helper.knexQuery(query);
    res.status(result.status).send(result);
});

module.exports = router;