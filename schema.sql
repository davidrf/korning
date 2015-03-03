DROP TABLE IF EXISTS employees, invoices, customers, products, sales;

CREATE TABLE employees (
  id SERIAL PRIMARY KEY,
  name varchar(255),
  email varchar(255)
);

CREATE TABLE invoices (
  id SERIAL PRIMARY KEY,
  no integer,
  frequency varchar(255)
);

CREATE TABLE customers (
  id SERIAL PRIMARY KEY,
  name varchar(255),
  account_no varchar(255)
);

CREATE TABLE products (
  id SERIAL PRIMARY KEY,
  name varchar(255)
);

CREATE TABLE sales (
  id SERIAL PRIMARY KEY,
  sale_date date,
  units_sold integer,
  sale_amount numeric,
  employee_id integer REFERENCES employees(id),
  invoice_id integer REFERENCES invoices(id),
  customer_id integer REFERENCES customers(id),
  product_id integer REFERENCES products(id)
);
