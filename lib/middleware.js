
const knex = require('./database');
const { decodeJwtToken } = require('./helper');
const secret = process.env.APP_KEY;

// authentication middleware
const auth = async (req, res, next) => {
    if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
        const query = knex.transaction(async trx => {
            try {
                const jwt_token = req.headers.authorization.substr(7);
                const tokenExist = await trx('Revoked Tokens').where({ token: jwt_token });
                if (tokenExist.length > 0 && tokenExist[0].signed_out === 0) {
                    try {
                        const decoded = decodeJwtToken(jwt_token, secret);
                        if (decoded) {
                            next();
                        }
                    } catch (error) {
                        throw new Error(error);
                    }
                } else {
                    throw new Error("Token not found");
                }

            } catch (error) {
                throw new Error(error);
            }
        });
        const result = await helper.knexQuery(query);
        res.status(result.status).send(result);
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
        const query = knex.transaction(async trx => {
            try {
                const jwt_token = req.headers.authorization.substr(7);
                const user = decodeJwtToken(jwt_token, secret);
                if (user.role === "admin") {
                    next();
                } else {
                    throw new Error("You have no Access to do that!");
                }
            } catch (error) {
                throw new Error(error);
            }
        });
        const result = await helper.knexQuery(query);
        res.status(result.status).send(result);
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
        const query = knex.transaction(async trx => {
            try {
                const jwt_token = req.headers.authorization.substr(7);
                const user = decodeJwtToken(jwt_token, secret);
                if (user.role === "cashier") {
                    next();
                } else {
                    throw new Error("You have no Access to do that!");
                }
            } catch (error) {
                throw new Error(error);
            }
        });
        const result = await helper.knexQuery(query);
        res.status(result.status).send(result);
    } else {
        res.status(503).send({
            status: 503,
            success: false,
            data: null,
            message: "Please Login!"
        })
    }
}

module.exports = {
    auth,
    admin,
    cashier,
}
