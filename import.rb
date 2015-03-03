require "pg"
require "csv"
require "pry"

ARTICLE_FILE = "sales.csv"

def db_connection
  begin
    connection = PG.connect(dbname: "korning")
    yield(connection)
  ensure
    connection.close
  end
end

def add_employee(employee_info)
  employee_name = employee_info.match(/\A.+\s/)[0][0..-1]
  employee_email = employee_info.match(/\(.+\)/)[0][1..-2]

  db_connection do |conn|
    employee_id = conn.exec_params("SELECT id FROM employees WHERE name = $1", [employee_name])
    if employee_id.to_a.empty?
      conn.exec_params("INSERT INTO employees (name, email) VALUES ($1, $2)", [employee_name, employee_email])
    end
  end
end

def add_invoice(number, frequency)
  db_connection do |conn|
    invoice_id = conn.exec_params("SELECT id FROM invoices WHERE no = $1", [number])
    if invoice_id.to_a.empty?
      conn.exec_params("INSERT INTO invoices (no, frequency) VALUES ($1, $2)", [number, frequency])
    end
  end
end

def add_customer(customer_info)
  customer_name = customer_info.match(/\A.+\s/)[0][0..-1]
  account_number = customer_info.match(/\(.+\)/)[0][1..-2]

  db_connection do |conn|
      customer_id = conn.exec_params("SELECT id FROM customers WHERE account_no = $1", [account_number])
      if customer_id.to_a.empty?
        conn.exec_params("INSERT INTO customers (name, account_no) VALUES ($1, $2)", [customer_name, account_number])
      end
  end
end

def add_product(name)
  db_connection do |conn|
    product_id = conn.exec_params("SELECT id FROM products WHERE name = $1", [name])
    if product_id.to_a.empty?
      conn.exec_params("INSERT INTO products (name) VALUES ($1)", [name])
    end
  end
end

def add_sale(info)
  date = info[:sale_date].split("/")
  date = date.unshift(date.pop).join("-")
  units = info[:units_sold]

  sale_amount = info[:sale_amount][1..-1]
  employee_name = info[:employee].match(/\A.+\s/)[0][0..-1]
  invoice_number = info[:invoice_no]
  account_number = info[:customer_and_account_no].match(/\(.+\)/)[0][1..-2]
  product_name = info[:product_name]

  db_connection do |conn|
    sale_id = conn.exec_params("SELECT id FROM sales WHERE sale_date = $1 AND units_sold = $2 AND sale_amount = $3", [date, units, sale_amount])
    if sale_id.to_a.empty?
      employee_id = conn.exec_params("SELECT id FROM employees WHERE name = $1", [employee_name]).to_a[0]["id"]
      invoice_id = conn.exec_params("SELECT id FROM invoices WHERE no = $1", [invoice_number]).to_a[0]["id"]
      customer_id = conn.exec_params("SELECT id FROM customers WHERE account_no = $1", [account_number]).to_a[0]["id"]
      product_id = conn.exec_params("SELECT id FROM products WHERE name = $1", [product_name]).to_a[0]["id"]
      data = [date, units, sale_amount, employee_id, invoice_id, customer_id, product_id]

      conn.exec_params("INSERT INTO sales (sale_date, units_sold, sale_amount, employee_id, invoice_id, customer_id, product_id) VALUES ($1, $2, $3, $4, $5, $6, $7)", data)
    end
  end
end

def import
  CSV.foreach(ARTICLE_FILE, headers: true, header_converters: :symbol) do |row|
    sale = row.to_hash
    add_employee(sale[:employee])
    add_invoice(sale[:invoice_no], sale[:invoice_frequency])
    add_customer(sale[:customer_and_account_no])
    add_product(sale[:product_name])
    add_sale(sale)
  end
end

import
