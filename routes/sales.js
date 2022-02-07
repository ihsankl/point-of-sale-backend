/* eslint-disable camelcase */
const knex = require('../lib/database');
const helper = require('../lib/helper');
const express = require('express');
const {auth} = require('../lib/middleware');
// eslint-disable-next-line new-cap
const router = express.Router();
const dayjs = require('dayjs');
const escpos = require('escpos');
const htmlToText = require('html-to-text');
escpos.USB = require('escpos-usb');

// check printer status
router.get('/printer', auth, async (req, res, next) => {
  try {
    const device = escpos.USB.findPrinter();
    console.log(device);
    if (device.length > 0) {
      res.status(200).send({
        status: 200,
        message: 'Printer found',
        success: true,
        data: device,
      });
    } else {
      res.status(200).send({
        status: 200,
        message: 'Printer not found',
        success: true,
        data: null,
      });
    }
  } catch (error) {
    res.status(503).send({
      status: 503,
      message: 'Internal server error',
      success: false,
      data: null,
    });
  }
});

// create sales
router.post('/', auth, async (req, res, next) => {
  const {
    products,
    user_id,
    customer_id,
    date_recorded = dayjs(new Date()).format('YYYY-MM-DD'),
    invoice_id,
    amount_tendered,
  } = req.body;
  const query = knex.transaction(async (trx) => {
    try {
      const total_amount = products
          .reduce((acc, cur) => parseInt(acc) + parseInt(cur.sub_total), 0);
      let invoiceId = null;
      if (invoice_id) {
        // add total_amount
        await trx('Invoice')
            .update({
              total_amount: knex.raw('total_amount + ?', total_amount),
            })
            .where({id: invoice_id});
      } else {
        invoiceId = await trx('Invoice')
            .insert({
              total_amount,
              amount_tendered,
              date_recorded,
              user_id,
              customer_id,
            });
      }
      const promises = [];
      products.map( (v, i) => {
        promises.push(
            trx('Product')
                .update({unit_in_stock: knex.raw('unit_in_stock - ?', v.qty)})
                .where({id: v.product_id}),
        );
        promises.push(
            trx('Sales')
                .insert({
                  qty: v.qty,
                  unit_price: v.unit_price,
                  sub_total: v.sub_total,
                  invoice_id: invoice_id ?? invoiceId[0],
                  product_id: v.product_id,
                }),
        );
      });
      return await Promise.all(promises);
    } catch (error) {
      throw new Error(error);
    }
  });
  const result = await helper.knexQuery(query);
  res.status(result.status).send(result);
});

// get sales with pagination filtered by date
router.get('/pagination', auth, async (req, res, next) => {
  const {page, limit, start_date, end_date} = req.query;
  const offset = (page - 1) * limit;
  const query = knex
      .select(
          'c.name',
          'a.*',
          'b.total_amount',
          'b.amount_tendered',
          'b.date_recorded',
      )
      .from('Sales')
      .leftJoin('Invoice as b', 'b.id', 'a.invoice_id')
      .leftJoin('Product as c', 'c.id', 'a.product_id')
      .whereBetween('b.date_recorded', [start_date, end_date])
      .offset(offset)
      .limit(limit);
  const result = await helper.knexQuery(query, `getSalesPage:${page}`);
  // generate metadata
  const data = {
    total_data: result.data.length,
    limit: limit,
    page: page,
    params: req.query,
    base_url: `${req.protocol}://${req.get('host')}/api/sales/`,
  };
  const _metadata = helper.generateMetadata(data);
  res.status(result.status).send({...result, _metadata});
});

// get all sales
router.get('/', auth, async (req, res, next) => {
  const query = knex
      .select(
          'c.name',
          'a.*',
          'b.date_recorded',
      )
      .from('Sales as a')
      .leftJoin('Invoice as b', 'b.id', 'a.invoice_id')
      .leftJoin('Product as c', 'c.id', 'a.product_id');
  const result = await helper.knexQuery(query, 'getAllSales');
  res.status(result.status).send(result);
});

// get 1 sales
router.get('/:id', auth, async (req, res, next) => {
  const {id} = req.params;
  const query = knex
      .select(
          'c.name',
          'a.*',
          'b.total_amount',
          'b.amount_tendered',
          'b.date_recorded',
      )
      .from('Sales as a')
      .leftJoin('Invoice as b', 'b.id', 'a.invoice_id')
      .leftJoin('Product as c', 'c.id', 'a.product_id')
      .where({id});
  const result = await helper.knexQuery(query);
  res.status(result.status).send(result);
});

// update sales
router.put('/:id', async (req, res, next) => {
  const {id} = req.params;
  const {qty, unit_price, sub_total, invoice_id, product_id} = req.body;
  const query = knex.transaction(async (trx) => {
    try {
      const sales_before = await trx('Sales')
          .select(
              'sub_total',
              'qty',
          )
          .where({id});
      if (sub_total > sales_before[0].sub_total) {
        await trx
            .update({
              total_amount: knex.raw(
                  '`total_amount` + ?',
                  sub_total - sales_before[0].sub_total,
              ),
            })
            .from('Invoice')
            .where({id: invoice_id});
      } else if (sub_total > sales_before[0].sub_total) {
        await trx
            .update({
              total_amount: knex.raw(
                  '`total_amount` - ?',
                  sub_total - sales_before[0].sub_total,
              ),
            })
            .from('Invoice')
            .where({id: invoice_id});
      }
      if (qty < sales_before[0].qty) {
        await trx
            .update({
              unit_in_stock: knex.raw(
                  '`unit_in_stock` - ?',
                  qty - sales_before[0].qty,
              ),
            })
            .from('Product')
            .where({id: product_id});
      } else if (qty < sales_before[0].qty) {
        await trx
            .update({
              unit_in_stock: knex.raw(
                  '`unit_in_stock` + ?',
                  sales_before[0].qty - qty,
              ),
            })
            .from('Product')
            .where({id: product_id});
      }

      return await trx('Sales')
          .where({id})
          .update({qty, unit_price, sub_total, invoice_id, product_id});
    } catch (error) {
      throw new Error(error);
    }
  });
  const result = await helper.knexQuery(query);
  res.status(result.status).send(result);
});

// delete sales
router.delete('/:id', auth, async (req, res, next) => {
  const {id} = req.params;
  const query = knex.transaction(async (trx) => {
    try {
      // revert stock from product table
      const sales_before = await trx('Sales')
          .select('*')
          .where({id});
      await trx
          .update({
            unit_in_stock: knex.raw(
                '`unit_in_stock` + ?',
                sales_before[0].qty,
            ),
          })
          .from('Product')
          .where({id: sales_before[0].product_id});
      // revert total amount from invoice table
      await trx
          .update({
            total_amount: knex.raw(
                '`total_amount` - ?',
                sales_before[0].sub_total,
            ),
          })
          .from('Invoice')
          .where({id: sales_before[0].invoice_id});
      return await trx('Sales')
          .where({id})
          .del();
    } catch (error) {
      throw new Error(error);
    }
  });
  const result = await helper.knexQuery(query);
  res.status(result.status).send(result);
});

// print receipt
router.post('/print', auth, async (req, res, next) => {
  const {
    products,
    receipt_id,
    operator,
    date,
    total,
    change,
    paid,
  } = req.body;

  const data = products.map((product) => {
    const product_name = product.product_name.replace(/\(.*\)/, '').trim();
    return {
      product_name,
      qty: product.qty,
      sub_total: product.sub_total,
    };
  });

  const table = `
    <!doctype html>
    <html>
        <head>
            <meta charset="utf-8">
            <title>Testing Title for table</title>
        </head>
        <body>
            <div class="invoice-box">
                <table
                  class="receipt-table"
                  cellpadding="0"
                  cellspacing="0"
                  border="0"
                >
                    <thead>
                        <tr class="heading">
                            <th>Item</th>
                            <th>Quantity</th>
                            <th>Total</th>
                        </tr>
                    </thead>
                    <tbody>
                        ${data.map((item) =>
    `
                          <tr>
                              <td>${item.product_name}</td>
                              <td>${item.qty}</td>
                              <td>${item.sub_total}</td>
                          </tr>
                          `,
  )}
                    </tbody>
                    <tfoot>
                        <tr>
                            <td>
                                TOTAL:${total}
                            </td>
                        </tr>
                        <tr>
                            <td>
                                Pembayaran:${paid}
                            </td>
                        </tr>
                        <tr>
                            <td>
                                Kembalian:${change}
                            </td>
                        </tr>
                    </tfoot>
            </table>
            </div>
        </body>
    </html>
    `;

  try {
    const options = {
      encoding: 'GB18030',
    };
      // encoding is optional

    const device = new escpos.USB(0x9C5, 0x589E);
    const printer = new escpos.Printer(device, options);
    device.open(function(error) {
      if (error) {
        throw new Error(error);
      }
      const text = htmlToText.fromString(table, {
        wordwrap: false,
        tables: ['.receipt-box', '.receipt-table'],
      });
      printer
          .font('b')
          .align('ct')
          .style('bu')
          .size(.01, .01)
          .encode('utf8')
          .text('\n*****THIBBUL HAYAWAN*****\n\n')
      // RECEIPT ID
          .table(['RECEIPT # :', receipt_id])
      // DATE
          .table(['DATE: ', dayjs(date).format('DD/MM/YYYY')])
          .text('----------ITEM LIST----------\n')
      // ITEM LIST STARTS HERE
          .text(text)
      // ITEM LIST ENDS HERE
          .text('--------------------------------')
      // OPERATOR
          .text(`Operator: ${operator}\n-------------------------------\n`)
          .text('\nTHANK YOU\n')
          .close();
    });
    res.status(200).send({
      status: 200,
      message: 'Receipt printed successfully',
      success: true,
      data: null,
    });
  } catch (error) {
    console.error(error.message);
    res.status(503).send({
      status: 503,
      message: 'Internal server error',
      success: false,
      data: null,
    });
  }
});

module.exports = router;
