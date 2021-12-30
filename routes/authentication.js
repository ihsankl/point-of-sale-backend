const express = require("express");
const jwt = require('jsonwebtoken');
const router = express.Router();
const secret = process.env.APP_KEY;

const knex = require("../lib/database.js");
const helper = require("../lib/helper.js");
const { auth } = require("../lib/middleware.js");

// user login
router.post("/login", async (req, res, next) => {
    const { username, password } = req.body;
    // let usernameQuery;
    await knex.transaction(async trx => {
        try {
            const usernameQuery = await trx("User").where({ username });
            if (usernameQuery.length > 0) {
                const passwordMatch = helper.compare(password, usernameQuery[0].password);
                if (passwordMatch) {
                    const token = jwt.sign({
                        ...usernameQuery[0],
                    }, secret, { expiresIn: '24h' });
                    await trx("Revoked Tokens").insert({ token, signed_out: 0 });
                    res.status(200).send({
                        status: 200,
                        success: true,
                        data: {
                            token,
                            user: usernameQuery[0].username,
                        },
                        message: "Login successful!"
                    });

                } else {
                    res.status(503).send({
                        status: 503,
                        success: false,
                        data: null,
                        message: "Wrong Password!"
                    })
                }
            } else {
                res.status(503).send({
                    status: 503,
                    success: false,
                    data: null,
                    message: "User not found!"
                })
            }
            // console.log(usernameQuery);
        } catch (error) {
            console.log(error.message);
            res.status(503).send({
                status: 503,
                success: false,
                data: null,
                message: error.message
            });
        }
    });
});

// user logout
router.post("/logout", auth, async (req, res, next) => {
    const token = req.headers.authorization.substr(7);
    const query = knex("Revoked Tokens").where({ token });
    const result = await helper.knexQuery(query);
    if (result.status === 200) {
        const updateQuery = knex("Revoked Tokens").where({ token }).update({ signed_out: 1 });
        const updateResult = await helper.knexQuery(updateQuery);
        res.status(updateResult.status).send(updateResult);
    } else {
        res.status(result.status).send(result);
    }
});

module.exports = router;