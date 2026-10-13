-- Name: Taboldieva Aruzhan
-- ID: 25B031961

DROP SCHEMA IF EXISTS ecommerce CASCADE;
DROP TABLE IF EXISTS order_items, orders, products_fk, categories, books, publishers, authors,
    employees_dept, student_courses, departments, course_enrollments, users,
    inventory, customers, bookings, products_catalog, employees CASCADE;

-- PART 1: CHECK

-- Task 1.1
CREATE TABLE employees (
    employee_id INTEGER,
    first_name  TEXT,
    last_name   TEXT,
    age         INTEGER CHECK (age BETWEEN 18 AND 65),  -- age must be 18..65
    salary      NUMERIC CHECK (salary > 0)              -- salary must be positive
);

-- Task 1.2
CREATE TABLE products_catalog (
    product_id     INTEGER,
    product_name   TEXT,
    regular_price  NUMERIC,
    discount_price NUMERIC,
    -- both prices positive and discount strictly lower than regular price
    CONSTRAINT valid_discount CHECK (
        regular_price > 0 AND discount_price > 0 AND discount_price < regular_price)
);

-- Task 1.3
CREATE TABLE bookings (
    booking_id     INTEGER,
    check_in_date  DATE,
    check_out_date DATE,
    num_guests     INTEGER,
    CONSTRAINT valid_guests CHECK (num_guests BETWEEN 1 AND 10),     -- 1..10 guests
    CONSTRAINT valid_dates  CHECK (check_out_date > check_in_date)   -- check-out after check-in
);

-- Task 1.4: tests
-- valid rows (all inserted successfully)
INSERT INTO employees VALUES (1, 'Aigerim', 'Nurlanova', 28, 450000), (2, 'Daniyar', 'Sadykov', 45, 620000);
INSERT INTO products_catalog VALUES (1, 'Laptop', 1000, 850), (2, 'Headphones', 120, 99.99);
INSERT INTO bookings VALUES (1, '2026-11-01', '2026-11-05', 2), (2, '2026-12-20', '2026-12-27', 4);

-- age 17 is below the minimum 18
-- INSERT INTO employees VALUES (3, 'Young', 'Person', 17, 300000);
-- RESULT: ERROR: new row for relation "employees" violates check constraint "employees_age_check"
-- salary 0 is not greater than 0
-- INSERT INTO employees VALUES (4, 'Zero', 'Salary', 30, 0);
-- RESULT: ERROR: new row for relation "employees" violates check constraint "employees_salary_check"
-- discount_price is higher than regular_price
-- INSERT INTO products_catalog VALUES (3, 'Bad Discount', 100, 150);
-- RESULT: ERROR: new row for relation "products_catalog" violates check constraint "valid_discount"
-- regular_price is 0
-- INSERT INTO products_catalog VALUES (4, 'Free Item', 0, 0);
-- RESULT: ERROR: new row for relation "products_catalog" violates check constraint "valid_discount"
-- 11 guests is more than the maximum 10
-- INSERT INTO bookings VALUES (3, '2026-11-01', '2026-11-05', 11);
-- RESULT: ERROR: new row for relation "bookings" violates check constraint "valid_guests"
-- check-out is before check-in
-- INSERT INTO bookings VALUES (4, '2026-11-10', '2026-11-05', 2);
-- RESULT: ERROR: new row for relation "bookings" violates check constraint "valid_dates"


-- PART 2: NOT NULL

-- Task 2.1
CREATE TABLE customers (
    customer_id       INTEGER NOT NULL,
    email             TEXT    NOT NULL,
    phone             TEXT,                -- optional
    registration_date DATE    NOT NULL
);

-- Task 2.2
CREATE TABLE inventory (
    item_id      INTEGER   NOT NULL,
    item_name    TEXT      NOT NULL,
    quantity     INTEGER   NOT NULL CHECK (quantity >= 0),
    unit_price   NUMERIC   NOT NULL CHECK (unit_price > 0),
    last_updated TIMESTAMP NOT NULL
);

-- Task 2.3: tests
-- complete records (inserted successfully)
INSERT INTO customers VALUES (1, 'aigerim@example.com', '+7 701 111 2233', '2026-01-15'),
                             (2, 'daniyar@example.com', '+7 702 444 5566', '2026-02-20');
INSERT INTO inventory VALUES (1, 'USB Cable', 200, 3.50, '2026-10-01 09:30:00'),
                             (2, 'Keyboard', 0, 45.00, '2026-10-02 14:00:00');
-- NULL in a nullable column (phone) is allowed
INSERT INTO customers VALUES (3, 'elena@example.com', NULL, '2026-03-05');

-- NULL in NOT NULL columns
-- INSERT INTO customers VALUES (NULL, 'x@example.com', '123', '2026-05-01');
-- RESULT: ERROR: null value in column "customer_id" of relation "customers" violates not-null constraint
-- INSERT INTO customers VALUES (4, NULL, '123', '2026-05-01');
-- RESULT: ERROR: null value in column "email" of relation "customers" violates not-null constraint
-- INSERT INTO inventory VALUES (3, NULL, 10, 5.00, '2026-10-03 10:00:00');
-- RESULT: ERROR: null value in column "item_name" of relation "inventory" violates not-null constraint
-- NOT NULL + CHECK in inventory
-- INSERT INTO inventory VALUES (4, 'Cable', -5, 5.00, '2026-10-03 10:00:00');
-- RESULT: ERROR: new row for relation "inventory" violates check constraint "inventory_quantity_check"
-- INSERT INTO inventory VALUES (5, 'Adapter', 5, 0, '2026-10-03 10:00:00');
-- RESULT: ERROR: new row for relation "inventory" violates check constraint "inventory_unit_price_check"


-- PART 3: UNIQUE

-- Task 3.1
CREATE TABLE users (
    user_id    INTEGER,
    username   TEXT UNIQUE,
    email      TEXT UNIQUE,
    created_at TIMESTAMP
);

-- Task 3.2
CREATE TABLE course_enrollments (
    enrollment_id INTEGER,
    student_id    INTEGER,
    course_code   TEXT,
    semester      TEXT,
    UNIQUE (student_id, course_code, semester)   -- the combination must be unique
);
INSERT INTO course_enrollments VALUES (1, 101, 'CS101', 'Fall 2026'),
                                      (2, 101, 'CS102', 'Fall 2026'),
                                      (3, 101, 'CS101', 'Spring 2027');   -- same course, other semester: OK
-- same student + course + semester again
--[FAIL] INSERT INTO course_enrollments VALUES (4, 101, 'CS101', 'Fall 2026');

-- Task 3.3: replace auto-named constraints with named ones
ALTER TABLE users DROP CONSTRAINT users_username_key;
ALTER TABLE users DROP CONSTRAINT users_email_key;
ALTER TABLE users ADD CONSTRAINT unique_username UNIQUE (username);
ALTER TABLE users ADD CONSTRAINT unique_email    UNIQUE (email);

INSERT INTO users VALUES (1, 'aigerim', 'aigerim@example.com', now()),
                         (2, 'daniyar', 'daniyar@example.com', now());
-- duplicate username
-- INSERT INTO users VALUES (3, 'aigerim', 'other@example.com', now());
-- RESULT: ERROR: duplicate key value violates unique constraint "unique_username"
-- duplicate email
-- INSERT INTO users VALUES (4, 'newuser', 'daniyar@example.com', now());
-- RESULT: ERROR: duplicate key value violates unique constraint "unique_email"


-- PART 4: PRIMARY KEY


-- Task 4.1
CREATE TABLE departments (
    dept_id   INTEGER PRIMARY KEY,    -- unique and not null
    dept_name TEXT NOT NULL,
    location  TEXT
);
INSERT INTO departments VALUES (1, 'Engineering', 'Almaty'),
                               (2, 'Marketing', 'Astana'),
                               (3, 'Finance', 'Almaty');
-- duplicate dept_id
-- INSERT INTO departments VALUES (1, 'Duplicate', 'Shymkent');
-- RESULT: ERROR: duplicate key value violates unique constraint "departments_pkey"
-- NULL dept_id
-- INSERT INTO departments VALUES (NULL, 'Null Dept', 'Shymkent');
-- RESULT: ERROR: null value in column "dept_id" of relation "departments" violates not-null constraint

-- Task 4.2
CREATE TABLE student_courses (
    student_id      INTEGER,
    course_id       INTEGER,
    enrollment_date DATE,
    grade           TEXT,
    PRIMARY KEY (student_id, course_id)   -- the pair identifies a row
);
INSERT INTO student_courses VALUES (1, 10, '2026-09-01', 'A'),
                                   (1, 20, '2026-09-01', 'B+'),
                                   (2, 10, '2026-09-02', 'A-');
-- duplicate pair (1, 10)
-- INSERT INTO student_courses VALUES (1, 10, '2026-10-01', 'C');
-- RESULT: ERROR: duplicate key value violates unique constraint "student_courses_pkey"

-- Task 4.3: explanation
-- 1. UNIQUE vs PRIMARY KEY: both forbid duplicates, but PRIMARY KEY also forbids
--    NULL, is the main identifier of a row and is what FOREIGN KEYs reference by
--    default. UNIQUE columns can contain NULL (many NULLs are allowed).
-- 2. Single-column PK: normal case when one value identifies a row (dept_id).
--    Composite PK: when only a combination identifies a row, e.g. junction tables
--    like student_courses (student_id, course_id).
-- 3. A table has one main identity, so only one PRIMARY KEY. UNIQUE constraints
--    are extra rules (e.g. unique username and unique email), so there can be many.


-- PART 5: FOREIGN KEY

-- Task 5.1
CREATE TABLE employees_dept (
    emp_id    INTEGER PRIMARY KEY,
    emp_name  TEXT NOT NULL,
    dept_id   INTEGER REFERENCES departments,
    hire_date DATE
);
INSERT INTO employees_dept VALUES (1, 'Aigerim Nurlanova', 1, '2024-03-01'),
                                  (2, 'Daniyar Sadykov', 2, '2025-06-15');
-- dept_id 99 does not exist in departments
-- INSERT INTO employees_dept VALUES (3, 'Ghost Employee', 99, '2026-07-01');
-- RESULT: ERROR: insert or update on table "employees_dept" violates foreign key constraint "employees_dept_dept_id_fkey"

-- Task 5.2
CREATE TABLE authors (
    author_id   INTEGER PRIMARY KEY,
    author_name TEXT NOT NULL,
    country     TEXT
);
CREATE TABLE publishers (
    publisher_id   INTEGER PRIMARY KEY,
    publisher_name TEXT NOT NULL,
    city           TEXT
);
CREATE TABLE books (
    book_id          INTEGER PRIMARY KEY,
    title            TEXT NOT NULL,
    author_id        INTEGER REFERENCES authors,
    publisher_id     INTEGER REFERENCES publishers,
    publication_year INTEGER,
    isbn             TEXT UNIQUE
);
INSERT INTO authors VALUES (1, 'Leo Tolstoy', 'Russia'), (2, 'Abai Kunanbaiuly', 'Kazakhstan'),
                           (3, 'George Orwell', 'United Kingdom');
INSERT INTO publishers VALUES (1, 'Penguin Books', 'London'), (2, 'Zhazushy', 'Almaty');
INSERT INTO books VALUES (1, 'War and Peace', 1, 1, 1869, '978-0-14-044793-4'),
                         (2, 'Book of Words', 2, 2, 1909, '978-601-01-0001-1'),
                         (3, '1984', 3, 1, 1949, '978-0-452-28423-4');
-- duplicate ISBN
-- INSERT INTO books VALUES (4, 'Fake Copy', 1, 1, 2000, '978-0-14-044793-4');
-- RESULT: ERROR: duplicate key value violates unique constraint "books_isbn_key"
-- author_id 99 does not exist
-- INSERT INTO books VALUES (5, 'No Author', 99, 1, 2000, '978-1-00-000000-1');
-- RESULT: ERROR: insert or update on table "books" violates foreign key constraint "books_author_id_fkey"

-- Task 5.3
CREATE TABLE categories (
    category_id   INTEGER PRIMARY KEY,
    category_name TEXT NOT NULL
);
CREATE TABLE products_fk (
    product_id   INTEGER PRIMARY KEY,
    product_name TEXT NOT NULL,
    category_id  INTEGER REFERENCES categories ON DELETE RESTRICT   -- cannot delete a used category
);
CREATE TABLE orders (
    order_id   INTEGER PRIMARY KEY,
    order_date DATE NOT NULL
);
CREATE TABLE order_items (
    item_id    INTEGER PRIMARY KEY,
    order_id   INTEGER REFERENCES orders ON DELETE CASCADE,         -- items are deleted with the order
    product_id INTEGER REFERENCES products_fk,
    quantity   INTEGER CHECK (quantity > 0)
);
INSERT INTO categories VALUES (1, 'Electronics'), (2, 'Books');
INSERT INTO products_fk VALUES (1, 'Laptop', 1), (2, 'Smartphone', 1), (3, 'SQL Handbook', 2);
INSERT INTO orders VALUES (1, '2026-10-01'), (2, '2026-10-05');
INSERT INTO order_items VALUES (1, 1, 1, 1), (2, 1, 3, 2), (3, 2, 2, 1);

-- Scenario 1 (RESTRICT): category 1 still has products, so the delete is rejected
-- and nothing is removed.
-- DELETE FROM categories WHERE category_id = 1;
-- RESULT: ERROR: update or delete on table "categories" violates foreign key constraint "products_fk_category_id_fkey" on table "products_fk"

-- Scenario 2 (CASCADE): deleting order 1 also deletes its items (item 1 and 2).
SELECT * FROM order_items ORDER BY item_id;


DELETE FROM orders WHERE order_id = 1;
SELECT * FROM order_items ORDER BY item_id;

-- Documented: RESTRICT blocks deleting the parent while children exist (error);
-- CASCADE deletes the parent and automatically deletes its children.


-- PART 6: E-COMMERCE

CREATE SCHEMA ecommerce;
SET search_path TO ecommerce;

CREATE TABLE customers (
    customer_id       INTEGER PRIMARY KEY,
    name              TEXT NOT NULL,
    email             TEXT NOT NULL UNIQUE,          -- unique email
    phone             TEXT,
    registration_date DATE NOT NULL DEFAULT CURRENT_DATE
);

CREATE TABLE products (
    product_id     INTEGER PRIMARY KEY,
    name           TEXT NOT NULL,
    description    TEXT,
    price          NUMERIC(10,2) NOT NULL CHECK (price >= 0),          -- non-negative
    stock_quantity INTEGER NOT NULL DEFAULT 0 CHECK (stock_quantity >= 0)
);

CREATE TABLE orders (
    order_id     INTEGER PRIMARY KEY,
    -- RESTRICT: a customer with orders cannot be deleted (keeps order history)
    customer_id  INTEGER NOT NULL REFERENCES customers ON DELETE RESTRICT,
    order_date   DATE NOT NULL DEFAULT CURRENT_DATE,
    total_amount NUMERIC(12,2) NOT NULL DEFAULT 0 CHECK (total_amount >= 0),
    status       TEXT NOT NULL DEFAULT 'pending',
    CONSTRAINT valid_status CHECK (status IN ('pending','processing','shipped','delivered','cancelled'))
);

CREATE TABLE order_details (
    order_detail_id INTEGER PRIMARY KEY,
    -- CASCADE: details have no meaning without their order
    order_id   INTEGER NOT NULL REFERENCES orders ON DELETE CASCADE,
    -- RESTRICT: a sold product cannot be deleted
    product_id INTEGER NOT NULL REFERENCES products ON DELETE RESTRICT,
    quantity   INTEGER NOT NULL CHECK (quantity > 0),               -- positive quantity
    unit_price NUMERIC(10,2) NOT NULL CHECK (unit_price >= 0)
);

INSERT INTO customers VALUES
    (1, 'Aigerim Nurlanova', 'aigerim@example.com', '+7 701 111 2233', '2026-01-15'),
    (2, 'Daniyar Sadykov',   'daniyar@example.com', '+7 702 444 5566', '2026-02-20'),
    (3, 'Elena Petrova',     'elena@example.com',   NULL,              '2026-03-05'),
    (4, 'John Smith',        'john@example.com',    '+1 555 010 0199', '2026-04-01'),
    (5, 'Madina Akhmetova',  'madina@example.com',  '+7 777 888 9900', '2026-05-12');

INSERT INTO products VALUES
    (1, 'Laptop',              '15-inch laptop',        899.99, 15),
    (2, 'Wireless Mouse',      'Ergonomic mouse',        24.50, 150),
    (3, 'Mechanical Keyboard', 'Hot-swappable switches', 79.00, 60),
    (4, 'USB-C Hub',           '7-in-1 hub',             39.90, 0),
    (5, '27" Monitor',         '4K IPS display',        249.00, 25);

INSERT INTO orders VALUES
    (1, 1, '2026-09-01', 948.99, 'delivered'),
    (2, 2, '2026-09-10', 103.50, 'shipped'),
    (3, 3, '2026-09-20', 498.00, 'processing'),
    (4, 1, '2026-10-01', 119.70, 'pending'),
    (5, 4, '2026-10-05', 899.99, 'cancelled');

INSERT INTO order_details VALUES
    (1, 1, 1, 1, 899.99), (2, 1, 2, 2, 24.50),
    (3, 2, 3, 1, 79.00),  (4, 2, 2, 1, 24.50),
    (5, 3, 5, 2, 249.00), (6, 4, 4, 3, 39.90),
    (7, 5, 1, 1, 899.99);

-- ---- Tests ----
-- UNIQUE: duplicate email
-- INSERT INTO customers VALUES (6, 'Copy', 'aigerim@example.com', NULL, '2026-06-01');
-- RESULT: ERROR: duplicate key value violates unique constraint "customers_email_key"
-- PRIMARY KEY: duplicate id
-- INSERT INTO customers VALUES (1, 'Dup Id', 'dup@example.com', NULL, '2026-06-01');
-- RESULT: ERROR: duplicate key value violates unique constraint "customers_pkey"
-- NOT NULL: missing name
-- INSERT INTO customers VALUES (6, NULL, 'noname@example.com', NULL, '2026-06-01');
-- RESULT: ERROR: null value in column "name" of relation "customers" violates not-null constraint
-- CHECK: negative price and negative stock
-- INSERT INTO products VALUES (6, 'Bad Price', NULL, -1.00, 5);
-- RESULT: ERROR: new row for relation "products" violates check constraint "products_price_check"
-- INSERT INTO products VALUES (7, 'Bad Stock', NULL, 10.00, -3);
-- RESULT: ERROR: new row for relation "products" violates check constraint "products_stock_quantity_check"
-- CHECK: invalid order status
-- INSERT INTO orders VALUES (6, 1, '2026-10-10', 10.00, 'lost');
-- RESULT: ERROR: new row for relation "orders" violates check constraint "valid_status"
-- CHECK: quantity must be positive
-- INSERT INTO order_details VALUES (8, 3, 1, 0, 10.00);
-- RESULT: ERROR: new row for relation "order_details" violates check constraint "order_details_quantity_check"
-- FOREIGN KEY: customer 99 / product 99 do not exist
-- INSERT INTO orders VALUES (6, 99, '2026-10-10', 10.00, 'pending');
-- RESULT: ERROR: insert or update on table "orders" violates foreign key constraint "orders_customer_id_fkey"
-- INSERT INTO order_details VALUES (8, 3, 99, 1, 10.00);
-- RESULT: ERROR: insert or update on table "order_details" violates foreign key constraint "order_details_product_id_fkey"
-- ON DELETE RESTRICT: customer 1 has orders, product 1 was sold
-- DELETE FROM customers WHERE customer_id = 1;
-- RESULT: ERROR: update or delete on table "customers" violates foreign key constraint "orders_customer_id_fkey" on table "orders"
-- DELETE FROM products WHERE product_id = 1;
-- RESULT: ERROR: update or delete on table "products" violates foreign key constraint "order_details_product_id_fkey" on table "order_details"
-- ON DELETE CASCADE: add a temporary order with 1 line, then delete the order
INSERT INTO orders VALUES (6, 5, '2026-10-10', 79.00, 'pending');
INSERT INTO order_details VALUES (8, 6, 3, 1, 79.00);
DELETE FROM orders WHERE order_id = 6;
SELECT COUNT(*) AS lines_left_for_order_6 FROM order_details WHERE order_id = 6;
-- Result:
--   lines_left_for_order_6
--   ----------------------
--   0
--   (1 row)

RESET search_path;
