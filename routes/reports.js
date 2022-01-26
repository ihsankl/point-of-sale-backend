/* eslint-disable camelcase */
const knex = require('../lib/database');
const helper = require('../lib/helper');
const express = require('express');
const {auth} = require('../lib/middleware');
const dayjs = require('dayjs');
// eslint-disable-next-line new-cap
const router = express.Router();

// count budget this month from `Purchase Order` table
router.get('/budget', async (req, res, next) => {
  const query = knex.transaction(async (trx) => {
    try {
      const total_budget = await trx('Purchase Order')
          .whereBetween('order_date', [
            // get first day of this month with dayjs
            dayjs().startOf('month').format('YYYY-MM-DD HH:mm:ss'),
            // get last day of this month with dayjs
            dayjs().endOf('month').format('YYYY-MM-DD HH:mm:ss'),
          ])
          .sum('sub_total as total_budget');
      const lastMonth = await trx('Purchase Order')
          .whereBetween('order_date', [
            // get first day of last month with dayjs
            dayjs()
                .subtract(1, 'month')
                .startOf('month')
                .format('YYYY-MM-DD HH:mm:ss'),
            // get last day of last month with dayjs
            dayjs()
                .subtract(1, 'month')
                .endOf('month')
                .format('YYYY-MM-DD HH:mm:ss'),
          ])
          .sum('sub_total as total_budget');
      const totalBudget = total_budget?.[0]?.total_budget ?? 0;
      const totalLastMonth = lastMonth?.[0]?.total_budget ?? 0;
      // eslint-disable-next-line max-len
      let diffFromLastMonth = (((totalBudget - totalLastMonth) / totalLastMonth) * 100).toFixed(2);
      // if percent is infinity, set it to 100
      if (!isFinite(diffFromLastMonth)) diffFromLastMonth = '100';
      return {totalBudget, diffFromLastMonth};
    } catch (error) {
      throw new Error(error);
    }
  });
  const result = await helper.knexQuery(query);
  res.status(result.status).send(result);
});

// count total transaction happened this month from `Invoice` table
router.get('/transaction', async (req, res, next) => {
  const query = knex.transaction(async (trx) => {
    try {
      const total_transaction = await trx('Invoice')
          .whereBetween('date_recorded', [
            // get first day of this month with dayjs
            dayjs().startOf('month').format('YYYY-MM-DD HH:mm:ss'),
            // get last day of this month with dayjs
            dayjs().endOf('month').format('YYYY-MM-DD HH:mm:ss'),
          ])
          .count('id as total_transaction');
      const lastMonth = await trx('Invoice')
          .whereBetween('date_recorded', [
            // get first day of last month with dayjs
            dayjs()
                .subtract(1, 'month')
                .startOf('month')
                .format('YYYY-MM-DD HH:mm:ss'),
            // get last day of last month with dayjs
            dayjs()
                .subtract(1, 'month')
                .endOf('month')
                .format('YYYY-MM-DD HH:mm:ss'),
          ])
          .count('id as total_transaction');
      const totalTransaction = total_transaction?.[0]?.total_transaction ?? 0;
      const totalLastMonth = lastMonth?.[0]?.total_transaction ?? 0;
      // eslint-disable-next-line max-len
      let diffFromLastMonth = (((totalTransaction - totalLastMonth) / totalLastMonth) * 100).toFixed(2);
      // if percent is infinity, set it to 100
      if (!isFinite(diffFromLastMonth)) diffFromLastMonth = '100';
      return {totalTransaction, diffFromLastMonth};
    } catch (error) {
      throw new Error(error);
    }
  });
  const result = await helper.knexQuery(query, 'transactionMonthly');
  res.status(result.status).send(result);
});

// count total gross this month from `Invoice` table
router.get('/gross', auth, async (req, res, next) => {
  const query = knex.transaction(async (trx) => {
    try {
      const total_gross = await trx('Invoice')
          .whereBetween('date_recorded', [
            // get first day of this month with dayjs
            dayjs().startOf('month').format('YYYY-MM-DD HH:mm:ss'),
            // get last day of this month with dayjs
            dayjs().endOf('month').format('YYYY-MM-DD HH:mm:ss'),
          ])
          .sum('total_amount as total_gross');
      const lastMonth = await trx('Invoice')
          .whereBetween('date_recorded', [
            // get first day of last month with dayjs
            dayjs()
                .subtract(1, 'month')
                .startOf('month')
                .format('YYYY-MM-DD HH:mm:ss'),
            // get last day of last month with dayjs
            dayjs()
                .subtract(1, 'month')
                .endOf('month')
                .format('YYYY-MM-DD HH:mm:ss'),
          ])
          .sum('total_amount as total_gross');
      const totalGross = total_gross?.[0]?.total_gross ?? 0;
      const totalLastMonth = lastMonth?.[0]?.total_gross ?? 0;
      // eslint-disable-next-line max-len
      let diffFromLastMonth = (((totalGross - totalLastMonth) / totalLastMonth) * 100).toFixed(2);
      // if percent is infinity, set it to 100
      if (!isFinite(diffFromLastMonth)) diffFromLastMonth = '100';
      return {totalGross, diffFromLastMonth};
    } catch (error) {
      throw new Error(error);
    }
  });
  const result = await helper.knexQuery(query, 'grossMonthly');
  res.status(result.status).send(result);
});

// count profit this month calculated from `Invoice` table
// and `Purchase Order` table joined
router.get('/profit', async (req, res, next) => {
  const query = knex.transaction(async (trx) => {
    try {
      const total_budget = await trx
          .sum('a.sub_total as total_budget')
          .from('Purchase Order as a')
          .whereBetween('a.order_date', [
            // get first day of this month with dayjs
            dayjs().startOf('month').format('YYYY-MM-DD HH:mm:ss'),
            // get last day of this month with dayjs
            dayjs().endOf('month').format('YYYY-MM-DD HH:mm:ss'),
          ]);
      const total_gross = await trx
          .sum('a.total_amount as total_total_gross')
          .from('Invoice as a')
          .whereBetween('a.date_recorded', [
            // get first day of this month with dayjs
            dayjs().startOf('month').format('YYYY-MM-DD HH:mm:ss'),
            // get last day of this month with dayjs
            dayjs().endOf('month').format('YYYY-MM-DD HH:mm:ss'),
          ]);
      // total budget and total gross last month
      const lastMonthTotalBudget = await trx
          .sum('a.sub_total as total_budget')
          .from('Purchase Order as a')
          .whereBetween('a.order_date', [
            // get first day of last month with dayjs
            dayjs()
                .subtract(1, 'month')
                .startOf('month')
                .format('YYYY-MM-DD HH:mm:ss'),
            // get last day of last month with dayjs
            dayjs()
                .subtract(1, 'month')
                .endOf('month')
                .format('YYYY-MM-DD HH:mm:ss'),
          ]);
      const lastMonthTotalGross = await trx
          .sum('a.total_amount as total_total_gross')
          .from('Invoice as a')
          .whereBetween('a.date_recorded', [
            // get first day of last month with dayjs
            dayjs()
                .subtract(1, 'month')
                .startOf('month')
                .format('YYYY-MM-DD HH:mm:ss'),
            // get last day of last month with dayjs
            dayjs()
                .subtract(1, 'month')
                .endOf('month')
                .format('YYYY-MM-DD HH:mm:ss'),
          ]);
      const totalBudgetLastMonth = lastMonthTotalBudget?.[0]?.total_budget ?? 0;
      // eslint-disable-next-line max-len
      const totalGrossLastMonth = lastMonthTotalGross?.[0]?.total_total_gross ?? 0;
      const totalGross = total_gross?.[0]?.total_total_gross ?? 0;
      const totalBudget = total_budget?.[0]?.total_budget ?? 0;
      // eslint-disable-next-line max-len
      const totalProfit = totalGross - totalBudget;
      const totalProfitLastMonth = totalGrossLastMonth - totalBudgetLastMonth;
      // count percent difference between this month and last month
      // eslint-disable-next-line max-len
      let diffFromLastMonth = (((totalProfit - totalProfitLastMonth) / totalProfitLastMonth) * 100).toFixed(2);
      // if percent is infinity, set it to 100
      if (!isFinite(diffFromLastMonth)) diffFromLastMonth = '100';
      return {totalProfit, diffFromLastMonth};
    } catch (error) {
      throw new Error(error);
    }
  });
  const result = await helper.knexQuery(query, 'profitMonthly');
  res.status(result.status).send(result);
});

// sum up last 7 days invoice total_amount
// grouped by day
router.get('/last7days', auth, async (req, res, next) => {
  const query = knex('Invoice')
      .whereBetween('date_recorded', [
        // get last 7 day from now with dayjs
        dayjs().subtract(7, 'day').format('YYYY-MM-DD HH:mm:ss'),
        // today
        dayjs().format('YYYY-MM-DD HH:mm:ss'),
      ])
      .sum('total_amount as total_amount')
      .groupBy('date_recorded')
      .orderBy('date_recorded', 'desc');
  const result = await helper.knexQuery(query, 'last7days');
  res.status(result.status).send(result);
});

// sum up last 30 days invoice total_amount
// grouped by day
router.get('/last30days', auth, async (req, res, next) => {
  const query = knex('Invoice')
      .whereBetween('date_recorded', [
        // get last 30 day from now with dayjs
        dayjs().subtract(30, 'day').format('YYYY-MM-DD HH:mm:ss'),
        // today
        dayjs().format('YYYY-MM-DD HH:mm:ss'),
      ])
      .sum('total_amount as total_amount')
      .groupBy('date_recorded')
      .orderBy('date_recorded', 'desc');
  const result = await helper.knexQuery(query, 'last30days');
  res.status(result.status).send(result);
});

// sum up last 365 days invoice total_amount
// grouped by day
router.get('/last365days', auth, async (req, res, next) => {
  const query = knex('Invoice')
      .whereBetween('date_recorded', [
        // get last 365 day from now with dayjs
        dayjs().subtract(365, 'day').format('YYYY-MM-DD HH:mm:ss'),
        // today
        dayjs().format('YYYY-MM-DD HH:mm:ss'),
      ])
      .sum('total_amount as total_amount')
      .groupBy('date_recorded')
      .orderBy('date_recorded', 'desc');
  const result = await helper.knexQuery(query, 'last365days');
  res.status(result.status).send(result);
});

// find top 5 sales this month
// steps:
// 1. find all invoice this month
// 2. find all sales which has invoice_id in `Sales` table
// 3. get all products which has product_id in result of step 2
// 4. sum all qty with same produt_id in result of step 3
// 5. get top 5 product with max qty from result of step 4
router.get('/top5', auth, async (req, res, next) => {
  const query = knex.transaction(async (trx) => {
    try {
      const invoicesThisMonth = await trx
          .select('id')
          .from('Invoice')
          .whereBetween('date_recorded', [
            // get first day of this month with dayjs
            dayjs().startOf('month').format('YYYY-MM-DD HH:mm:ss'),
            // get last day of this month with dayjs
            dayjs().endOf('month').format('YYYY-MM-DD HH:mm:ss'),
          ]);
      const invoiceIds = invoicesThisMonth.map((invoice) => invoice.id);
      const salesThisMonth = await trx
          .select('*')
          .from('Sales')
          .whereIn('invoice_id', invoiceIds);
      const productIds = salesThisMonth.map((sale) => sale.product_id);
      const productsThisMonth = await trx
          .select('*')
          .from('Product')
          .whereIn('id', productIds);
      const productQty = productsThisMonth.map((product) => {
        const qty = salesThisMonth
            .find((sale) => sale.product_id === product.id)
            .qty;
        return {
          product_name: product.name,
          qty,
        };
      });
      const top5 = productQty.sort((a, b) => b.qty - a.qty).slice(0, 5);
      return top5;
    } catch (error) {
      throw new Error(error);
    }
  });
  const result = await helper.knexQuery(query);
  res.status(result.status).send(result);
});

// find yearly gross
// steps:
// 1. make an array of years 6 years ago to now
// 2. find all invoice with year in this array
// 3. get invoice for each month in each year
// 4. sum up all invoice for each month in each year
// 5. get yearly gross for each year
router.get('/yearly', async (req, res, next) => {
  const query = knex.transaction(async (trx) => {
    try {
      const years = Array.from(Array(6).keys()).map((i) => {
        return dayjs().subtract(i, 'year').format('YYYY');
      });
      const invoiceEachYearPromises = [];
      years.map((year) => {
        const query = trx
            .select('*')
            .from('Invoice')
            .whereBetween('date_recorded', [
              // whole year of year variable with dayjs
              dayjs(`${year}-01-01 00:00:00`).format('YYYY-MM-DD HH:mm:ss'),
              dayjs(`${year}-12-31 23:59:59`).format('YYYY-MM-DD HH:mm:ss'),
            ]);
        invoiceEachYearPromises.push(query);
      });
      const invoiceEachYear = await Promise.all(invoiceEachYearPromises);
      const summaryInvoiceEachYear = invoiceEachYear.map((invoice, index) => {
        return {
          [years[index]]: invoice,
        };
      });
      const monthlyTotalInvoices = summaryInvoiceEachYear.map((year) => {
        const yearKey = Object.keys(year)[0];
        const yearValue = Object.values(year)[0];
        const invoiceEachMonth = yearValue.map((invoice) => {
          const month = dayjs(invoice.date_recorded).format('MMM');
          const totalAmount = invoice.total_amount;
          return {
            month,
            total_amount: totalAmount,
          };
        });
        const summaryInvoiceEachMonth = invoiceEachMonth.reduce(
            (acc, curr) => {
              if (acc[curr.month]) {
                acc[curr.month] += curr.total_amount;
              } else {
                acc[curr.month] = curr.total_amount;
              }
              return acc;
            },
            {},
        );
        return {
          [yearKey]: summaryInvoiceEachMonth,
        };
      });
      const yearlyGross = monthlyTotalInvoices.map((year) => {
        const yearKey = Object.keys(year)[0];
        const yearValue = Object.values(year)[0];
        const yearlyGross = Object.values(yearValue).reduce(
            (acc, curr) => acc + curr,
            0,
        );
        return {
          [yearKey]: yearlyGross,
        };
      });
      const result = monthlyTotalInvoices.map((value, index) => {
        const year = Object.keys(value)[0];
        // if year variable is the same as year in yearlyGross
        // then append total key to monthlyTotalInvoices
        const x = yearlyGross.find((y) => y[year]);
        if (!!x) return {...value, total: yearlyGross[index][year]};
        return value;
      });
      return result;
    } catch (error) {
      throw new Error(error);
    }
  });
  const result = await helper.knexQuery(query);
  res.status(result.status).send(result);
});


module.exports = router;
