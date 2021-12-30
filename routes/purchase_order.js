const knex = require('../lib/database');
const helper = require('../lib/helper');
const express = require("express");
const { auth } = require('../lib/middleware');
const router = express.Router();

// create purchase order
router.post("/", auth, async (req, res, next) => {
    const { qty, sub_total, order_date, unit_price, product_id, user_id, supplier_id } = req.body;
    const query = knex("Purchase Order").insert({ qty, sub_total, order_date, unit_price, product_id, user_id, supplier_id });
    const result = await helper.knexQuery(query);
    res.status(result.status).send(result);
});

// get all purchase orders
router.get("/", auth, async (req, res, next) => {
    const query = knex("Purchase Order").select("*");
    const result = await helper.knexQuery(query);
    res.status(result.status).send(result);
});

// get purchase order with pagination filtered by order_date
router.get("/pagination", auth, async (req, res, next) => {
    const { date_from, date_to, page, limit } = req.query;
    const offset = (page - 1) * limit;
    const query = knex("Purchase Order")
        .select("*")
        .whereBetween("order_date", [date_from, date_to])
        .offset(offset)
        .limit(limit);
    const result = await helper.knexQuery(query);
    // generate metadata
    const data = {
        total_data: result.data.length,
        limit: limit,
        page: page,
        params: req.query,
        base_url: `${req.protocol}://${req.get("host")}/api/purchase_order/pagination`,
    };
    const _metadata = helper.generateMetadata(data);
    res.status(result.status).send({ ...result, _metadata });
});

// get 1 purchase order
router.get("/:id", auth, async (req, res, next) => {
    const { id } = req.params;
    const query = knex("Purchase Order").where({ id });
    const result = await helper.knexQuery(query);
    res.status(result.status).send(result);
});

// update purchase order
router.put("/:id", auth, async (req, res, next) => {
    const { id } = req.params;
    const { qty, sub_total, order_date, unit_price, product_id, user_id, supplier_id } = req.body;
    const query = knex("Purchase Order").where({ id }).update({ qty, sub_total, order_date, unit_price, product_id, user_id, supplier_id });
    const result = await helper.knexQuery(query);
    res.status(result.status).send(result);
});

// delete purchase order
router.delete("/:id", auth, async (req, res, next) => {
    const { id } = req.params;
    const query = knex("Purchase Order").where({ id }).del();
    const result = await helper.knexQuery(query);
    res.status(result.status).send(result);
});

module.exports = router;