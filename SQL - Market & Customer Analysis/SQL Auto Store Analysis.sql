-- DESCRIBING TABLES: Model Car Store

-- productlines: A line that can have multiple products (>=0)
-- Primary Key: productLine
-- Other Attributes: textDescription, htmlDescription, image
-- Relationships: Has a one to many relationship with 'products'.

-- products: One type of car that must be part of a 'productLine', and may be referenced in 'orderdetails'
-- Primary Key: productCode
-- Foreign Key: productLine REFERENCES productlines
-- Other Attributes: productName, productScale, productVendor, productDescription, quantityInStock, buyPrice, MSRP
-- Relationships: Has a many to one relationship with 'productlines', and a one to one relationship with 'orderdetails'

-- orderdetails: Contains details of an order regarding one product
-- Primary Key: orderNumber, productCode
-- Foreign Key: orderNumber REFERENCES orders, productCode REFERENCES products
-- Other Attributes: quantityOrdered, priceEach, orderLineNumber
-- Relationships: Has a one to one relationship with 'products' and 'orders'

-- orders: Order containing orderdetails that must be coming from a customer
-- Primary Key: orderNumber
-- Foreign Key: customerNumber REFERENCES customers
-- Other Attributes: orderDate, requiredDate, shippedDate, status, comments, customerNumber
-- Relationships: Has a one to one relationship with 'orderdetails' and 'customers'

-- customers: Details on a customer, who may have a dedicated sales rep
-- Primary Key: customerNumber
-- Foreign Key: salesRepEmployeeNumber REFERENCES employeeNumber
-- Other Attributes: customerName, contactLastName, contactFirstName, phone, addressLine1, addressLine2, city, state, postalCode, country, creditLimit
-- Relationships: Has a one to one relationship with 'orders', 'payments' and 'employees'

-- payments: payment details of customer
-- Primary Key: customerNumber, checkNumber
-- Foreign Key: customerNumber REFERENCES customers
-- Other Attributes: paymentDate, amount
-- Relationships: Has a one to one relationship with 'customers'

-- employees: Details on an employee, who may report to another employee and must have a dedicated office
-- Primary Key: employeeNumber
-- Foreign Key: officeCode REFERENCES offices, reportsTo REFERENCES employeeNumber
-- Other Attributes: lastName, firstName, extension, email, jobTitle
-- Relationships: Has a many to one relationship with 'employees', and 'offices'

-- offices: Details on an office location
-- Primary Key: officeCode
-- Other Attributes: city, phone, addressLine1, addressLine2, state, postalCode, country, territory
-- Relationships: Has a one to many relationship with 'employees'
		
-- Overview of Dataset
SELECT 
	'customers' as table_name, 
	(SELECT COUNT(*) FROM pragma_table_info('customers')) AS number_of_attributes, 
	(SELECT COUNT(*) FROM customers) AS number_of_rows
UNION ALL
SELECT 
	'employees' as table_name, 
	(SELECT COUNT(*) FROM pragma_table_info('employees')) AS number_of_attributes, 
	(SELECT COUNT(*) FROM employees) AS number_of_rows
UNION ALL
SELECT 
	'offices' as table_name, 
	(SELECT COUNT(*) FROM pragma_table_info('offices')) AS number_of_attributes, 
	(SELECT COUNT(*) FROM offices) AS number_of_rows
UNION ALL
SELECT 
	'orderdetails' as table_name, 
	(SELECT COUNT(*) FROM pragma_table_info('orderdetails')) AS number_of_attributes, 
	(SELECT COUNT(*) FROM orderdetails) AS number_of_rows
UNION ALL
SELECT 
	'orders' as table_name, 
	(SELECT COUNT(*) FROM pragma_table_info('orders')) AS number_of_attributes, 
	(SELECT COUNT(*) FROM orders) AS number_of_rows
UNION ALL
SELECT 
	'payments' as table_name, 
	(SELECT COUNT(*) FROM pragma_table_info('payments')) AS number_of_attributes, 
	(SELECT COUNT(*) FROM payments) AS number_of_rows
UNION ALL
SELECT 
	'productlines' as table_name, 
	(SELECT COUNT(*) FROM pragma_table_info('productlines')) AS number_of_attributes, 
	(SELECT COUNT(*) FROM productlines) AS number_of_rows
UNION ALL
SELECT 
	'products' as table_name, 
	(SELECT COUNT(*) FROM pragma_table_info('products')) AS number_of_attributes, 
	(SELECT COUNT(*) FROM products) AS number_of_rows;

-- Q1: What products should we order more of

WITH low_stock AS ( --find products that are low/out of stock
    SELECT 
        p.productCode,
        p.productName,
        p.quantityInStock,
		p.productLine,
        (SELECT SUM(od.quantityOrdered) 
         FROM orderdetails od 
         WHERE od.productCode = p.productCode) AS total_ordered,
        ROUND((SELECT SUM(od.quantityOrdered) 
               FROM orderdetails od 
               WHERE od.productCode = p.productCode) * 1.0 / p.quantityInStock, 2) AS low_stock
    FROM products p
    ORDER BY low_stock DESC
),
high_performance AS ( -- find the products that have brought in the most money
    SELECT
        p.productCode,
        p.productName,
        (SELECT SUM(od.quantityOrdered * od.priceEach)
         FROM orderdetails od
         WHERE od.productCode = p.productCode) AS product_performance
    FROM products p
    ORDER BY product_performance DESC
)
SELECT 
    ls.productName,
	ls.productLine
FROM low_stock ls
JOIN high_performance hp ON ls.productCode = hp.productCode
ORDER BY ls.low_stock DESC, hp.product_performance DESC
LIMIT 10;

-----------------------------------------------------------------------------------------------------

-- Q2: How should we match marketing and communication strategies to customer behaviour
-- We can categorize customers by how much profit they bring to the store by implementing a VIP system. We can take some marketing action based on this categorization (ex. rewards and events for VIPs and a marketing campaign for the regular customers)

-- LOCATING VIPs
-- Compute top 5 customers with the highest profit
WITH customer_profit AS (
	SELECT
		o.customerNumber,
		(SELECT SUM(od.quantityOrdered * (od.priceEach - p.buyPrice))) AS profit
	FROM orderdetails od
	JOIN products p ON p.productCode = od.productCode
	JOIN orders o ON o.orderNumber= od.orderNumber
	GROUP BY o.customerNumber
)
SELECT
	c.contactLastName,
	c.contactFirstName,
	c.city,
	c.country,
	cp.profit
FROM customers c
JOIN customer_profit cp ON c.customerNumber = cp.customerNumber
ORDER BY profit DESC
LIMIT 5;

-- Compute top 5 customers with the least profit
WITH customer_profit AS (
	SELECT
		o.customerNumber,
		(SELECT SUM(od.quantityOrdered * (od.priceEach - p.buyPrice))) AS profit
	FROM orderdetails od
	JOIN products p ON p.productCode = od.productCode
	JOIN orders o ON o.orderNumber= od.orderNumber
	GROUP BY o.customerNumber
)
SELECT
	c.contactLastName,
	c.contactFirstName,
	c.city,
	c.country,
	cp.profit
FROM customers c
JOIN customer_profit cp ON c.customerNumber = cp.customerNumber
ORDER BY profit ASC
LIMIT 5;

-----------------------------------------------------------------------------------------------------

-- Q3: How much can we spend on acquiring new customers

WITH money_in_by_customer_table AS (
	SELECT o.customerNumber, SUM(quantityOrdered * (priceEach - buyPrice)) AS revenue
	FROM products p
	JOIN orderdetails od ON p.productCode = od.productCode
	JOIN orders o ON o.orderNumber = od.orderNumber
	GROUP BY o.customerNumber
)
SELECT AVG(mc.revenue) AS ltv
FROM money_in_by_customer_table mc;
