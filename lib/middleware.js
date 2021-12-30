
const jwt = require('jsonwebtoken');
const knex = require('./database');
const { decodeJwtToken } = require('./helper');
const secret = process.env.APP_KEY;

// authentication middleware
const auth = async (req, res, next) => {
    if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
        const jwt_token = req.headers.authorization.substr(7);
        const query = await knex('Revoked Tokens').where({ token: jwt_token });

        if (query.length > 0 && query[0].signed_out === 0) {
            try {
                const decoded = jwt.verify(jwt_token, secret)
                if (decoded) {
                    next();
                }
            } catch (error) {
                res.status(503).send({
                    status: 503,
                    success: false,
                    data: null,
                    message: error.message
                })
            }
        } else if (query.length === 0) {
            res.status(503).send({
                status: 503,
                success: false,
                data: null,
                message: "Wrong Token!"
            })
        } else if (query.length > 0 && query[0].signed_out === 1) {
            res.status(503).send({
                status: 503,
                success: false,
                data: null,
                message: "Please Login!"
            })
        }
    } else {
        res.status(503).send({
            status: 503,
            success: false,
            data: null,
            message: "Please Login!"
        })
    }
}

// admin only
const admin = async (req, res, next) => {
    if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
        const jwt_token = req.headers.authorization.substr(7);
        const user = decodeJwtToken(jwt_token, secret);

        if (user.role === "admin") {
            next();
        } else {
            res.status(503).send({
                status: 503,
                success: false,
                data: null,
                message: "You have no Access to do that!"
            })
        }
    } else {
        res.status(503).send({
            status: 503,
            success: false,
            data: null,
            message: "Please Login!"
        })
    }
}

// cashier only
const cashier = async (req, res, next) => {
    if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
        const jwt_token = req.headers.authorization.substr(7);
        const user = decodeJwtToken(jwt_token, secret);

        if (user.role === "cashier") {
            next();
        } else {
            res.status(503).send({
                status: 503,
                success: false,
                data: null,
                message: "You have no Access to do that!"
            })
        }
    }
}

module.exports = {
    auth,
    admin,
    cashier,
}
