
# Point of Sales REST-API

An API to used with cashier or e-commerce (still work in progress).


## Environment Variables

To run this project, you will need to add the following environment variables to your .env file

`PORT`

`DB_HOST`

`DB_USER`

`DB_PASSWORD`

`DB_DATABASE`

`APP_KEY`

`APP_BASEURL`
## Run Locally

Clone the project

```bash
  git clone https://github.com/ihsankl/point-of-sale-backend
```

Go to the project directory

```bash
  cd point-of-sale-backend
```

Install dependencies

```bash
  yarn
```

Import the database 
```bash
  mysql -u username -p your_database_name < point-of-sale.sql
```
change the **username** with your mysql username.

Start the server

```bash
  nodemon index.js
```


## API Reference
All endpoints except create user **require token**
### USERS
#### create user

```http
  POST /api/user
```

| Parameter(JSON) | Type     | Description                |
| :-------- | :------- | :------------------------- |
| `username` | `string` | **Required**. Your username |
| `password` | `string` | **Required**. Your password |
| `role` | `string` | **Required**. Your role (admin or cashier) |

#### get all users

```http
  GET /api/user
```

#### get 1 user

```http
  GET /api/user/:id
```

| Parameter(Params) | Type     | Description                |
| :-------- | :------- | :------------------------- |
| `id` | `number` | **Required**. id of the user |

#### get users with pagination

```http
  GET /api/user/pagination?page=1&limit=5
```

| Parameter(Query String) | Type     | Description                |
| :-------- | :------- | :------------------------- |
| `page` | `number` |  **Required**.the page you want to see |
| `limit` | `number` |  **Required**. limit data for 1 page |


#### update a user

```http
  PUT /api/user/:id
```

| Parameter(JSON) | Type     | Description                |
| :-------- | :------- | :------------------------- |
| `id`(params) | `number` |  **Required**.the user id |
| `username` | `string` |  **Required**. new username for the user |
| `password` | `string` |  **Required**. new password for the user |
| `role` | `string` |  **Required**. new role for the user |
| `fullname` | `string` |  fullname of the user |
| `contact` | `string` |  contact number of the user |

#### delete a user

```http
  DELETE /api/user/:id
```
| Parameter(Params) | Type     | Description                |
| :-------- | :------- | :------------------------- |
| `id` | `number` |  **Required**.the user id |

### AUTHENTICATION
#### login
```http
  POST /api/authentication/login
```
| Parameter(JSON) | Type     | Description                |
| :-------- | :------- | :------------------------- |
| `username` | `string` |  **Required** |
| `password` | `string` |  **Required** |

#### logout
```http
  POST /api/authentication/logout
```
| Parameter(JSON) | Type     | Description                |
| :-------- | :------- | :------------------------- |
| `username` | `string` |  **Required** |
| `password` | `string` |  **Required** |

### PRODUCT CATEGORY
#### create category
```http
  POST /api/category
```
| Parameter(JSON) | Type     | Description                |
| :-------- | :------- | :------------------------- |
| `name` | `string` |  **Required** |

#### get all categories
```http
  GET /api/category
```
#### get 1 category
```http
  GET /api/category/:id
```
| Parameter(Params) | Type     | Description                |
| :-------- | :------- | :------------------------- |
| `id` | `number` |  **Required** |

#### update category
```http
  PUT /api/category/:id
```
| Parameter(JSON) | Type     | Description                |
| :-------- | :------- | :------------------------- |
| `id`(params) | `number` |  **Required** |
| `name` | `string` |   |

#### delete category
```http
  DELETE /api/category/:id
```
| Parameter(params) | Type     | Description                |
| :-------- | :------- | :------------------------- |
| `id` | `number` |  **Required** |

### CUSTOMER
#### create customer
```http
  POST /api/customer
```
| Parameter(JSON) | Type     | Description                |
| :-------- | :------- | :------------------------- |
| `code` | `string` |   |
| `name` | `string` |   |
| `address` | `string` |   |
| `contact` | `string` | the contact number of the customer  |

#### get all customer
```http
  GET /api/customer
```
#### get 1 customer
```http
  GET /api/customer/:id
```
| Parameter(Params) | Type     | Description                |
| :-------- | :------- | :------------------------- |
| `id` | `number` |  **Required** |

#### update customer
```http
  PUT /api/customer/:id
```
| Parameter(JSON) | Type     | Description                |
| :-------- | :------- | :------------------------- |
| `id`(params) | `number` |  **Required** |
| `code` | `string` |   |
| `name` | `string` |   |
| `address` | `string` |   |
| `contact` | `string` | the contact number of the customer  |

#### delete customer
```http
  DELETE /api/customer/:id
```
| Parameter(params) | Type     | Description                |
| :-------- | :------- | :------------------------- |
| `id` | `number` |  **Required** |

### INVOICE
#### create invoice
```http
  POST /api/invoice
```
| Parameter(JSON) | Type     | Description                |
| :-------- | :------- | :------------------------- |
| `total_amount` | `number` | **Required**. The total amount of customer should spend  |
| `amount_tendered` | `number` | **Required**. The amount of customer offered.  |
| `date_recorded` | `date` | **Required**. the date of invoice issued  |
| `user_id` | `number` | **Required**. the users which handled the customer  |
| `customer_id` | `number` | the customer which is being served  |

#### get all invoice
```http
  GET /api/invoice
```
#### get 1 invoice
```http
  GET /api/invoice/:id
```
| Parameter(Params) | Type     | Description                |
| :-------- | :------- | :------------------------- |
| `id` | `number` |  **Required** |

#### get invoice with pagination filtered by date
```http
  GET /api/invoice/pagination?page=1&limit=5&date_from=2021-12-30&date_to=2021-12-30
```
| Parameter(Query String) | Type     | Description                |
| :-------- | :------- | :------------------------- |
| `page` | `number` |  **Required** |
| `limit` | `number` |  **Required** |
| `date_from` | `date` |  **Required** |
| `date_to` | `date` |  **Required** |


#### update invoice
```http
  PUT /api/invoice/:id
```
| Parameter(JSON) | Type     | Description                |
| :-------- | :------- | :------------------------- |
| `id`(params) | `number` |  **Required** |
| `total_amount` | `number` | **Required**. The total amount of customer should spend  |
| `amount_tendered` | `number` | **Required**. The amount of customer offered.  |
| `date_recorded` | `date` | **Required**. the date of invoice issued  |
| `user_id` | `number` | **Required**. the users which handled the customer  |
| `customer_id` | `number` | the customer which is being served  |

#### delete invoice
```http
  DELETE /api/invoice/:id
```
| Parameter(params) | Type     | Description                |
| :-------- | :------- | :------------------------- |
| `id` | `number` |  **Required** |

### PRODUCT UNIT
#### create product_unit
```http
  POST /api/product_unit
```
| Parameter(JSON) | Type     | Description                |
| :-------- | :------- | :------------------------- |
| `name` | `string` |  **Required**. The unit of the product (Kg, m, pcs) |

#### get all product_unit
```http
  GET /api/product_unit
```
#### get 1 product_unit
```http
  GET /api/product_unit/:id
```
| Parameter(Params) | Type     | Description                |
| :-------- | :------- | :------------------------- |
| `id` | `number` |  **Required** |

#### update product_unit
```http
  PUT /api/product_unit/:id
```
| Parameter(JSON) | Type     | Description                |
| :-------- | :------- | :------------------------- |
| `id`(params) | `number` |  **Required** |
| `name` | `string` |  **Required** |

#### delete product_unit
```http
  DELETE /api/product_unit/:id
```
| Parameter(params) | Type     | Description                |
| :-------- | :------- | :------------------------- |
| `id` | `number` |  **Required** |

### PRODUCT
#### create product
```http
  POST /api/product
```
| Parameter(JSON) | Type     | Description                |
| :-------- | :------- | :------------------------- |
| `code` | `string` |  **Required** |
| `name` | `string` |  **Required** |
| `unit_in_stock` | `number` |  **Required** |
| `disc_percentage` | `number` |   |
| `unit_price` | `number` |  **Required** |
| `re_order_level` | `number` |  default = 0 |
| `unit_id` | `number` |  **Required** |
| `category_id` | `number` |  **Required** |
| `user_id` | `number` |  **Required** 

#### get all product
```http
  GET /api/product
```
#### get 1 product
```http
  GET /api/product/:id
```
| Parameter(Params) | Type     | Description                |
| :-------- | :------- | :------------------------- |
| `id` | `number` |  **Required** |

#### get product with pagination filtered by name or category
```http
  GET /api/product/pagination?page=1&limit=5&name=bowl&category_id=1
```
| Parameter(Query String) | Type     | Description                |
| :-------- | :------- | :------------------------- |
| `page` | `number` |  **Required** |
| `limit` | `number` |  **Required** |
| `name` | `number` |  **Required** |
| `category_id` | `number` |  **Required** |

#### update product
```http
  PUT /api/product/:id
```
| Parameter(JSON) | Type     | Description                |
| :-------- | :------- | :------------------------- |
| `id`(params) | `number` |  **Required** |
| `code` | `string` |  **Required** |
| `name` | `string` |  **Required** |
| `unit_in_stock` | `number` |  **Required** |
| `disc_percentage` | `number` |   |
| `unit_price` | `number` |  **Required** |
| `re_order_level` | `number` |  default = 0 |
| `unit_id` | `number` |  **Required** |
| `category_id` | `number` |  **Required** |
| `user_id` | `number` |  **Required** |
 
#### delete product
```http
  DELETE /api/product/:id
```
| Parameter(params) | Type     | Description                |
| :-------- | :------- | :------------------------- |
| `id` | `number` |  **Required** |

### PURCHASE ORDER 
#### create purchase_order
```http
  POST /api/purchase_order
```
| Parameter(JSON) | Type     | Description                |
| :-------- | :------- | :------------------------- |
| `qty` | `number` |  **Required** |
| `sub_total` | `number` |  **Required** |
| `order_date` | `date` |  **Required** |
| `unit_price` | `number` |  **Required** |
| `product_id` | `number` |  **Required** |
| `user_id` | `number` |  **Required** |
| `supplier_id` | `number` |  **Required** |


#### get all purchase_orders
```http
  GET /api/purchase_order
```
#### get 1 purchase_order
```http
  GET /api/purchase_order/:id
```
| Parameter(Params) | Type     | Description                |
| :-------- | :------- | :------------------------- |
| `id` | `number` |  **Required** |

#### get purchase_order with pagination filtered by date
```http
  GET /api/purchase_order/pagination?page=1&limit=5&date_from=2021-12-30&date_to=2021-12-30
```
| Parameter(Query String) | Type     | Description                |
| :-------- | :------- | :------------------------- |
| `date_from` | `date` |  **Required** |
| `date_to` | `date` |  **Required** |
| `page` | `number` |  **Required** |
| `limit` | `number` |  **Required** |

#### update purchase_order
```http
  PUT /api/purchase_order/:id
```
| Parameter(JSON) | Type     | Description                |
| :-------- | :------- | :------------------------- |
| `id`(params) | `number` |  **Required** |
| `qty` | `number` |  **Required** |
| `sub_total` | `number` |  **Required** |
| `order_date` | `date` |  **Required** |
| `unit_price` | `number` |  **Required** |
| `product_id` | `number` |  **Required** |
| `user_id` | `number` |  **Required** |
| `supplier_id` | `number` |  **Required** |

#### delete purchase_order
```http
  DELETE /api/purchase_order/:id
```
| Parameter(params) | Type     | Description                |
| :-------- | :------- | :------------------------- |
| `id` | `number` |  **Required** |

### RECEIVE PRODUCT
#### create receive_product
```http
  POST /api/receive_product
```
| Parameter(JSON) | Type     | Description                |
| :-------- | :------- | :------------------------- |
| `qty` | `number` |  **Required** |
| `unit_price` | `number` |  **Required** |
| `sub_total` | `number` |  **Required** |
| `received_date` | `string` |  **Required** |
| `product_id` | `number` |  **Required** |
| `user_id` | `number` |  **Required** |
| `supplier_id` | `number` |  **Required** |

#### get all receive_products
```http
  GET /api/receive_product
```
#### get 1 receive_product
```http
  GET /api/receive_product/:id
```
| Parameter(Params) | Type     | Description                |
| :-------- | :------- | :------------------------- |
| `id` | `number` |  **Required** |

#### get receive_product with pagination filtered by date
```http
  GET /api/receive_product/pagination?page=1&limit=5&date_from=2021-12-30&date_to=2021-12-30
```
| Parameter(Query String) | Type     | Description                |
| :-------- | :------- | :------------------------- |
| `date_from` | `date` |  **Required** |
| `date_to` | `date` |  **Required** |
| `page` | `number` |  **Required** |
| `limit` | `number` |  **Required** |

#### update receive_product
```http
  PUT /api/receive_product/:id
```
| Parameter(JSON) | Type     | Description                |
| :-------- | :------- | :------------------------- |
| `id`(params) | `number` |  **Required** |
| `qty` | `number` |  **Required** |
| `unit_price` | `number` |  **Required** |
| `sub_total` | `number` |  **Required** |
| `received_date` | `string` |  **Required** |
| `product_id` | `number` |  **Required** |
| `user_id` | `number` |  **Required** |
| `supplier_id` | `number` |  **Required** |

#### delete receive_product
```http
  DELETE /api/receive_product/:id
```
| Parameter(params) | Type     | Description                |
| :-------- | :------- | :------------------------- |
| `id` | `number` |  **Required** |

### SALES
#### create sales
```http
  POST /api/sales
```
| Parameter(JSON) | Type     | Description                |
| :-------- | :------- | :------------------------- |
| `qty` | `number` |  **Required** |
| `unit_price` | `number` |  **Required** |
| `sub_total` | `number` |  **Required** |
| `product_id` | `number` |  **Required** |
| `user_id` | `number` |  **Required** |
| `customer_id` | `number` |  **Required** |

#### get all sales
```http
  GET /api/sales
```
#### get 1 sales
```http
  GET /api/sales/:id
```
| Parameter(Params) | Type     | Description                |
| :-------- | :------- | :------------------------- |
| `id` | `number` |  **Required** |

#### get sales with pagination filtered by date
```http
  GET /api/sales/pagination?page=1&limit=5&date_from=2021-12-30&date_to=2021-12-30
```
| Parameter(Query String) | Type     | Description                |
| :-------- | :------- | :------------------------- |
| `date_from` | `date` |  **Required** |
| `date_to` | `date` |  **Required** |
| `page` | `number` |  **Required** |
| `limit` | `number` |  **Required** |

#### update sales
```http
  PUT /api/sales/:id
```
| Parameter(JSON) | Type     | Description                |
| :-------- | :------- | :------------------------- |
| `id`(params) | `number` |  **Required** |
| `qty` | `number` |  **Required** |
| `unit_price` | `number` |  **Required** |
| `sub_total` | `number` |  **Required** |
| `product_id` | `number` |  **Required** |
| `user_id` | `number` |  **Required** |
| `customer_id` | `number` |  **Required** |

#### delete sales
```http
  DELETE /api/sales/:id
```
| Parameter(params) | Type     | Description                |
| :-------- | :------- | :------------------------- |
| `id` | `number` |  **Required** |

### SUPPLIER
#### create supplier
```http
  POST /api/supplier
```
| Parameter(JSON) | Type     | Description                |
| :-------- | :------- | :------------------------- |
| `name` | `string` |  **Required** |

#### get all suppliers
```http
  GET /api/supplier
```
#### get 1 supplier
```http
  GET /api/supplier/:id
```
| Parameter(Params) | Type     | Description                |
| :-------- | :------- | :------------------------- |
| `id` | `number` |  **Required** |

#### update supplier
```http
  PUT /api/supplier/:id
```
| Parameter(JSON) | Type     | Description                |
| :-------- | :------- | :------------------------- |
| `id`(params) | `number` |  **Required** |
| `name` | `string` |   |

#### delete supplier
```http
  DELETE /api/supplier/:id
```
| Parameter(params) | Type     | Description                |
| :-------- | :------- | :------------------------- |
| `id` | `number` |  **Required** |
## Authors

- [@ihsankl](https://www.github.com/ihsankl)

