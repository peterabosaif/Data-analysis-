CREATE TABLE customers (
    customer_id CHAR(32) NOT NULL,
    customer_unique_id CHAR(32) NOT NULL,
    zip_code_prefix VARCHAR(10) NOT NULL,
    customer_city VARCHAR(100) NOT NULL,
    customer_state CHAR(2) NOT NULL,
    PRIMARY KEY (customer_id)
);

CREATE TABLE geolocation (
    zip_code_prefix VARCHAR(10) NOT NULL PRIMARY KEY,
    geolocation_lat DECIMAL(10, 8) NOT NULL,
    geolocation_lng DECIMAL(11, 8) NOT NULL,
    geolocation_city VARCHAR(100) NOT NULL,
    geolocation_state CHAR(2) NOT NULL
);

CREATE TABLE orders (
    order_id CHAR(32) PRIMARY KEY,
    customer_id CHAR(32),
    order_status VARCHAR(20),
    order_purchase_timestamp DATETIME,
    order_approved_at DATETIME,
    order_delivered_carrier_date DATETIME,
    order_delivered_customer_date DATETIME,
    order_estimated_delivery_date DATETIME,
    FOREIGN KEY (customer_id) REFERENCES customers (customer_id)
);

CREATE TABLE products (
    product_id CHAR(32) PRIMARY KEY,
    product_category_name VARCHAR(50),
    product_name_lenght INT,
    product_description_lenght INT,
    product_photos_qty INT,
    product_weight_g INT,
    product_length_cm INT,
    product_height_cm INT,
    product_width_cm INT
);

CREATE TABLE sellers(
    seller_id CHAR(32) PRIMARY KEY,
    zip_code_prefix VARCHAR(10) NOT NULL,
    seller_city VARCHAR(50),
    seller_state VARCHAR(2)
    FOREIGN KEY (zip_code_prefix) REFERENCES geolocation (zip_code_prefix)
);

CREATE TABLE order_items (
	order_id CHAR(32),
	order_item_id INT,
	product_id CHAR(32),
	seller_id CHAR(32),
	shipping_limit_date DATETIME,
	price DECIMAL(6,2),
	freight_value DECIMAL(5,2)
	FOREIGN KEY (order_id) REFERENCES orders (order_id),
	FOREIGN KEY (product_id) REFERENCES products (product_id),
	FOREIGN KEY (seller_id) REFERENCES sellers (seller_id),
);

CREATE TABLE order_payments (
	order_id CHAR(32),
	payment_sequential INT, 
	payment_type VARCHAR(11),
	payment_installments INT,
	payment_value DECIMAL(7,2),
	FOREIGN KEY (order_id) REFERENCES orders (order_id)
);
CREATE TABLE order_reviews (
    review_id CHAR(32) PRIMARY KEY,
    order_id CHAR(32),
    review_score INT CHECK (review_score BETWEEN 1 AND 5),
    review_comment_title VARCHAR(50),
    review_comment_message NVARCHAR(MAX),
    review_creation_date DATE,
    review_answer_timestamp DATETIME,
    FOREIGN KEY (order_id) REFERENCES orders (order_id)
);

SELECT 
    o.order_id,
    c.customer_state,
    o.order_purchase_timestamp,
    DATEDIFF(day, o.order_estimated_delivery_date, o.order_delivered_customer_date) AS delivery_accuracy_days,
    DATEDIFF(day, o.order_delivered_carrier_date, o.order_delivered_customer_date) AS shipping_time_days,

    CASE 
        WHEN o.order_delivered_customer_date <= o.order_estimated_delivery_date THEN 'On Time or Early'
        ELSE 'Late'
    END AS delivery_status
FROM olist_orders_dataset o
JOIN olist_customers_dataset c ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL;
  SELECT 
    c.customer_state,
    AVG(DATEDIFF(day, o.order_estimated_delivery_date, o.order_delivered_customer_date)) AS avg_delay_days,
    COUNT(o.order_id) AS total_orders
FROM olist_orders_dataset o
JOIN olist_customers_dataset c ON o.customer_id = c.customer_id
GROUP BY c.customer_state
ORDER BY avg_delay_days DESC; 

-- ============================================
-- Data Cleaning & Preprocessing � (Logistics & Delivery)
-- ============================================

-- Step 1: Convert date columns to DATETIME
ALTER TABLE olist_orders_dataset ALTER COLUMN order_purchase_timestamp DATETIME;
ALTER TABLE olist_orders_dataset ALTER COLUMN order_approved_at DATETIME;
ALTER TABLE olist_orders_dataset ALTER COLUMN order_delivered_carrier_date DATETIME;
ALTER TABLE olist_orders_dataset ALTER COLUMN order_delivered_customer_date DATETIME;
ALTER TABLE olist_orders_dataset ALTER COLUMN order_estimated_delivery_date DATETIME;

-- Step 2: Identify missing values in delivery date
SELECT order_id, order_status
FROM olist_orders_dataset
WHERE order_delivered_customer_date IS NULL;

-- Step 2 (continued): Use conditions instead of UPDATE
SELECT AVG(DATEDIFF(day, order_estimated_delivery_date, order_delivered_customer_date)) AS avg_delay
FROM olist_orders_dataset
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL
  AND order_estimated_delivery_date IS NOT NULL;

-- Step 3: Standardize state names to uppercase
UPDATE olist_customers_dataset
SET customer_state = UPPER(customer_state);

-- Step 4 (continued): Verify states after update
SELECT DISTINCT customer_state
FROM olist_customers_dataset
ORDER BY customer_state;


 --Notebook Outline :

 1: Average Delivery Delay
SELECT 
    AVG(DATEDIFF(day, order_estimated_delivery_date, order_delivered_customer_date)) AS avg_delivery_delay
FROM olist_orders_dataset
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL
  AND order_estimated_delivery_date IS NOT NULL;
 
  2: Top States/Cities by Orders

 SELECT 
    c.customer_state,
    c.customer_city,
    COUNT(o.order_id) AS total_orders
FROM olist_orders_dataset o
JOIN olist_customers_dataset c ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_state, c.customer_city
ORDER BY total_orders DESC;

3: Late vs On-Time Orders
SELECT 
    CASE 
        WHEN o.order_delivered_customer_date <= o.order_estimated_delivery_date THEN 'On Time'
        ELSE 'Late'
    END AS delivery_status,
    COUNT(o.order_id) AS total_orders
FROM olist_orders_dataset o
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
  AND o.order_estimated_delivery_date IS NOT NULL
GROUP BY 
    CASE 
        WHEN o.order_delivered_customer_date <= o.order_estimated_delivery_date THEN 'On Time'
        ELSE 'Late'
        END;
       
  4: Shipping Lead Time

    SELECT 
    AVG(DATEDIFF(day, order_approved_at, order_delivered_carrier_date)) AS avg_shipping_lead_time
FROM olist_orders_dataset
WHERE order_status = 'delivered'
  AND order_delivered_carrier_date IS NOT NULL
  AND order_approved_at IS NOT NULL;
