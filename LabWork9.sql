-- Laboratory Work 9: Stored Procedures and User-Defined Functions
-- Part 1: Database Setup  (CityBike rental network)

DROP TABLE IF EXISTS rentals, bikes, members, stations CASCADE;

-- Create table: stations
CREATE TABLE stations (
    station_id   INT PRIMARY KEY,
    station_name VARCHAR(50) NOT NULL,
    city         VARCHAR(40) NOT NULL,
    capacity     INT NOT NULL
);

-- Create table: bikes
CREATE TABLE bikes (
    bike_id    INT PRIMARY KEY,
    model      VARCHAR(50) NOT NULL,
    station_id INT REFERENCES stations(station_id),
    daily_rate NUMERIC(8,2) NOT NULL
);

-- Create table: members
CREATE TABLE members (
    member_id INT PRIMARY KEY,
    full_name VARCHAR(60) NOT NULL,
    city      VARCHAR(40) NOT NULL,
    joined_on DATE NOT NULL
);

-- Create table: rentals
CREATE TABLE rentals (
    rental_id  INT PRIMARY KEY,
    member_id  INT REFERENCES members(member_id),
    bike_id    INT REFERENCES bikes(bike_id),
    start_date DATE NOT NULL,
    end_date   DATE,
    fee        NUMERIC(8,2)
);

INSERT INTO stations VALUES
 (10, 'Central Park', 'Almaty',   4),
 (20, 'Riverside',    'Almaty',   3),
 (30, 'Expo Gate',    'Astana',   5),
 (40, 'Old Town',     'Shymkent', 2),
 (50, 'Depot',        'Astana',   0);

INSERT INTO bikes VALUES
 (101, 'City Cruiser', 10,  4.50),
 (102, 'City Cruiser', 10,  4.50),
 (103, 'Mountain X',   20,  7.00),
 (104, 'Mountain X',   30,  7.00),
 (105, 'Road Sprint',  30,  9.25),
 (106, 'Folding Mini', 40,  3.75),
 (107, 'Cargo Hauler', 20, 12.00),
 (108, 'Road Sprint',  10,  9.25);

INSERT INTO members VALUES
 (1, 'Aisha Nurlanova', 'Almaty',   DATE '2023-03-14'),
 (2, 'Daniyar Serik',   'Almaty',   DATE '2023-07-02'),
 (3, 'Marta Kowalski',  'Astana',   DATE '2024-01-20'),
 (4, 'Chen Wei',        'Astana',   DATE '2024-05-11'),
 (5, 'Omar Haddad',     'Shymkent', DATE '2024-09-30'),
 (6, 'Elena Petrova',   'Almaty',   DATE '2025-02-05');

INSERT INTO rentals VALUES
 ( 1, 1, 101, DATE '2024-04-05', DATE '2024-04-08', 13.50),
 ( 2, 1, 103, DATE '2024-06-11', DATE '2024-06-16', 35.00),
 ( 3, 1, 108, DATE '2025-02-02', DATE '2025-02-04', 18.50),
 ( 4, 1, 102, DATE '2025-05-20', DATE '2025-05-27', 31.50),
 ( 5, 2, 101, DATE '2024-05-01', DATE '2024-05-02',  4.50),
 ( 6, 2, 107, DATE '2024-11-15', DATE '2024-11-19', 48.00),
 ( 7, 2, 107, DATE '2025-03-08', DATE '2025-03-14', 72.00),
 ( 8, 3, 104, DATE '2024-02-14', DATE '2024-02-18', 28.00),
 ( 9, 3, 105, DATE '2024-08-03', DATE '2024-08-06', 27.75),
 (10, 3, 104, DATE '2025-01-09', DATE '2025-01-10',  7.00),
 (11, 3, 105, DATE '2025-06-01', DATE '2025-06-09', 74.00),
 (12, 4, 104, DATE '2024-07-19', DATE '2024-07-21', 14.00),
 (13, 4, 105, DATE '2025-04-12', DATE '2025-04-15', 27.75),
 (14, 4, 103, DATE '2025-07-23', DATE '2025-07-29', 42.00),
 (15, 5, 106, DATE '2024-10-05', DATE '2024-10-12', 26.25),
 (16, 5, 106, DATE '2025-01-18', DATE '2025-01-20',  7.50),
 (17, 5, 106, DATE '2025-08-14', DATE '2025-08-21', 26.25),
 (18, 2, 102, DATE '2025-09-02', DATE '2025-09-05', 13.50),
 (19, 1, 101, DATE '2025-10-10', NULL,              NULL),
 (20, 4, 108, DATE '2024-12-28', DATE '2025-01-03', 55.50),
 (21, 3, 103, DATE '2025-02-26', DATE '2025-03-02', 28.00),
 (22, 5, 104, DATE '2025-05-05', DATE '2025-05-08', 21.00);


-- Verify database setup: expected 5 stations, 8 bikes, 6 members, 22 rentals.
SELECT (SELECT COUNT(*) FROM stations) AS stations,
       (SELECT COUNT(*) FROM bikes) AS bikes,
       (SELECT COUNT(*) FROM members) AS members,
       (SELECT COUNT(*) FROM rentals) AS rentals;

-- ============================================================
-- PART 2: YOUR FIRST FUNCTION
-- ============================================================

-- Exercise 2.1: A function over one row
CREATE OR REPLACE FUNCTION rental_days(p_rental_id INT)
RETURNS INT AS $$
DECLARE
    v_days INT;
BEGIN
    SELECT end_date - start_date
      INTO v_days
      FROM rentals
     WHERE rental_id = p_rental_id;
    RETURN v_days;
END;
$$ LANGUAGE plpgsql;

SELECT rental_days(2) AS rental_2_days;   -- expected 5
SELECT rental_days(11) AS rental_11_days; -- expected 8
SELECT rental_days(19) AS rental_19_days; -- NULL: end_date is NULL
SELECT rental_days(999) AS rental_999_days; -- NULL: no matching row
-- Answer: both results are NULL, but for different reasons: rental 19 exists
-- and its end_date is NULL; rental 999 does not exist, so SELECT INTO finds no row.

-- Exercise 2.2: A function over many rows
CREATE OR REPLACE FUNCTION member_rental_count(p_member_id INT)
RETURNS INT AS $$
DECLARE
    v_count INT;
BEGIN
    SELECT COUNT(*)
      INTO v_count
      FROM rentals
     WHERE member_id = p_member_id;
    RETURN v_count;
END;
$$ LANGUAGE plpgsql;

SELECT member_rental_count(1) AS member_1_rentals; -- 5
SELECT member_rental_count(5) AS member_5_rentals; -- 4
SELECT member_rental_count(6) AS member_6_rentals; -- 0
SELECT member_rental_count(99) AS member_99_rentals; -- 0
-- Answer: COUNT(*) is an aggregate and returns one row with 0 when no rows
-- match. It does not return NULL (unlike SUM over an empty input).

-- Exercise 2.3: Returning text
CREATE OR REPLACE FUNCTION station_city(p_station_id INT)
RETURNS VARCHAR AS $$
DECLARE
    v_city VARCHAR(40);
BEGIN
    SELECT city INTO v_city
      FROM stations
     WHERE station_id = p_station_id;
    RETURN v_city;
END;
$$ LANGUAGE plpgsql;

SELECT station_city(30) AS station_30_city; -- Astana
SELECT station_city(77) AS station_77_city; -- NULL (no matching station)

-- Exercise 2.4: Using a function inside a query
SELECT rental_id, member_id, rental_days(rental_id) AS duration_days
FROM rentals
WHERE rental_days(rental_id) > 4
ORDER BY duration_days DESC, rental_id;

-- ============================================================
-- PART 3: PARAMETER MODES
-- ============================================================

-- Exercise 3.1: IN parameters
CREATE OR REPLACE FUNCTION fee_with_discount(p_fee NUMERIC, p_percent NUMERIC)
RETURNS NUMERIC AS $$
BEGIN
    RETURN ROUND(p_fee * (1 - p_percent / 100), 2);
END;
$$ LANGUAGE plpgsql;

SELECT fee_with_discount(74.00, 15) AS discounted_fee; -- 62.90

-- Exercise 3.2: OUT parameters
CREATE OR REPLACE FUNCTION member_stats(
    p_member_id INT,
    OUT rental_cnt INT,
    OUT total_fee NUMERIC,
    OUT last_start DATE
) AS $$
BEGIN
    SELECT COUNT(*)::INT,
           COALESCE(SUM(fee), 0),
           MAX(start_date)
      INTO rental_cnt, total_fee, last_start
      FROM rentals
     WHERE member_id = p_member_id;
END;
$$ LANGUAGE plpgsql;

SELECT member_stats(3);
SELECT * FROM member_stats(3);
SELECT * FROM member_stats(6);
-- Answer: SELECT member_stats(3) displays one composite-valued column;
-- SELECT * FROM member_stats(3) expands the OUT values into separate columns,
-- which is more convenient in larger queries. Member 6 returns 0, 0, and NULL.

-- Exercise 3.3: INOUT parameters
CREATE OR REPLACE FUNCTION apply_late_fee(INOUT p_fee NUMERIC) AS $$
BEGIN
    p_fee := p_fee + 5.00;
END;
$$ LANGUAGE plpgsql;

SELECT apply_late_fee(fee) AS fee_with_late_charge
FROM rentals
WHERE rental_id = 1;
-- Answer: INOUT is itself an output parameter. PostgreSQL returns its final
-- value automatically, so neither a RETURNS clause nor RETURN is required.

-- Exercise 3.4: VARIADIC parameters
CREATE OR REPLACE FUNCTION fee_summary(
    VARIADIC p_fees NUMERIC[],
    OUT total NUMERIC,
    OUT average NUMERIC,
    OUT largest NUMERIC
) AS $$
BEGIN
    SELECT COALESCE(SUM(p_fees[g.i]), 0),
           ROUND(AVG(p_fees[g.i]), 2),
           MAX(p_fees[g.i])
      INTO total, average, largest
      FROM generate_subscripts(p_fees, 1) AS g(i);
END;
$$ LANGUAGE plpgsql;

SELECT * FROM fee_summary(13.50, 35.00, 18.50, 31.50);
SELECT * FROM fee_summary();
-- Answer: with no arguments the variadic array is empty: total is 0,
-- average and largest are NULL. VARIADIC must be last because it consumes
-- all remaining positional arguments; later parameters could not be identified.

-- Exercise 3.5: Choosing a mode
-- (a) IN: a row id is input used for lookup and is not modified.
-- (b) INOUT: the caller supplies a balance and receives its updated value.
-- (c) VARIADIC: it accepts an unknown number of station ids in one array.
-- (d) OUT parameters: return two statistics together from one function call.

-- ============================================================
-- PART 4: DEFAULT VALUES AND FUNCTION OVERLOADING
-- ============================================================

-- Exercise 4.1: A function with one parameter
CREATE OR REPLACE FUNCTION total_fees(p_member_id INT)
RETURNS NUMERIC AS $$
DECLARE
    v_total NUMERIC;
BEGIN
    SELECT COALESCE(SUM(fee), 0)
      INTO v_total
      FROM rentals
     WHERE member_id = p_member_id;
    RETURN v_total;
END;
$$ LANGUAGE plpgsql;

SELECT total_fees(1) AS member_1_total; -- 98.00
SELECT total_fees(6) AS member_6_total; -- 0

-- Exercise 4.2: Overloading the name
CREATE OR REPLACE FUNCTION total_fees(p_member_id INT, p_from_date DATE)
RETURNS NUMERIC AS $$
DECLARE
    v_total NUMERIC;
BEGIN
    SELECT COALESCE(SUM(fee), 0)
      INTO v_total
      FROM rentals
     WHERE member_id = p_member_id
       AND start_date >= p_from_date;
    RETURN v_total;
END;
$$ LANGUAGE plpgsql;

SELECT total_fees(1, DATE '2024-01-01');
SELECT total_fees(1, DATE '2025-01-01');

-- Exercise 4.3: Giving a parameter a default value
-- PostgreSQL can reject the one-argument call as ambiguous because both
-- overloads can accept one argument after the second overload gets a default.
CREATE OR REPLACE FUNCTION total_fees(
    p_member_id INT,
    p_from_date DATE DEFAULT DATE '2025-01-01'
)
RETURNS NUMERIC AS $$
DECLARE
    v_total NUMERIC;
BEGIN
    SELECT COALESCE(SUM(fee), 0)
      INTO v_total
      FROM rentals
     WHERE member_id = p_member_id
       AND start_date >= p_from_date;
    RETURN v_total;
END;
$$ LANGUAGE plpgsql;

DO $$
BEGIN
    BEGIN
        EXECUTE 'SELECT total_fees(1)';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'Exercise 4.3 captured error: %', SQLERRM;
    END;
END;
$$;
-- The NOTICE above prints the exact error text produced by the PostgreSQL
-- version running this script. Copy that server output into a separate report
-- only if one is requested. Cause: both the one-argument overload and the
-- two-argument overload with a default can match the call.

-- Exercise 4.4: Resolving the ambiguity
DROP FUNCTION total_fees(INTEGER);
SELECT total_fees(1) AS member_1_from_default_date;
-- Answer: the two-argument version with its default date is now selected.
-- For member 1 it sums fees from 2025-01-01 onward: 50.00.
-- Dropping the two-argument version instead would leave the one-argument
-- version and produce the all-time total (99.00), so it is not the same.

-- Exercise 4.5: Overloading on type, not just on count
CREATE OR REPLACE FUNCTION total_fees(p_member_name VARCHAR)
RETURNS NUMERIC AS $$
DECLARE
    v_total NUMERIC;
BEGIN
    SELECT COALESCE(SUM(r.fee), 0)
      INTO v_total
      FROM members AS m
      LEFT JOIN rentals AS r ON r.member_id = m.member_id
     WHERE m.full_name = p_member_name;
    RETURN v_total;
END;
$$ LANGUAGE plpgsql;

SELECT total_fees('Aisha Nurlanova') AS aisha_total_by_name;
SELECT total_fees(1) AS aisha_total_by_id;
-- Answer: the string call resolves to total_fees(VARCHAR), while the integer
-- call resolves to total_fees(INT, DATE DEFAULT ...). The latter uses the
-- default cutoff 2025-01-01, so it returns 50.00 rather than the all-time
-- name-based total of 99.00. The VARCHAR overload does not accept an integer.

-- ============================================================
-- PART 5: FUNCTIONS THAT RETURN A TABLE
-- ============================================================

-- Exercise 5.1: Search by pattern
CREATE OR REPLACE FUNCTION find_bikes(p_pattern VARCHAR)
RETURNS TABLE (
    found_id INT,
    found_model VARCHAR,
    found_rate NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT b.bike_id, b.model::VARCHAR, b.daily_rate
      FROM bikes AS b
     WHERE b.model ILIKE p_pattern
     ORDER BY b.bike_id;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM find_bikes('%road%');
SELECT * FROM find_bikes('%Mini');
SELECT find_bikes('%road%');
-- Answer: with FROM, each returned table row is a normal query row with
-- three columns. Without FROM, each result row is one composite value.

-- Exercise 5.2: A table from a join
CREATE OR REPLACE FUNCTION member_history(p_member_id INT)
RETURNS TABLE (
    history_rental_id INT,
    bike_model VARCHAR,
    station_name VARCHAR,
    duration_days INT,
    rental_fee NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT r.rental_id,
           b.model::VARCHAR,
           s.station_name::VARCHAR,
           (r.end_date - r.start_date)::INT,
           r.fee
      FROM rentals AS r
      JOIN bikes AS b ON b.bike_id = r.bike_id
      LEFT JOIN stations AS s ON s.station_id = b.station_id
     WHERE r.member_id = p_member_id
     ORDER BY r.start_date;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM member_history(3);

-- Exercise 5.3: When the column names collide
-- This version is intentionally created to demonstrate the runtime ambiguity.
CREATE OR REPLACE FUNCTION bike_list(p_station_id INT)
RETURNS TABLE (bike_id INT, model VARCHAR) AS $$
BEGIN
    RETURN QUERY
    SELECT bike_id, model
      FROM bikes
     WHERE station_id = p_station_id;
END;
$$ LANGUAGE plpgsql;

DO $$
BEGIN
    BEGIN
        PERFORM * FROM bike_list(10);
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'Exercise 5.3 captured error: %', SQLERRM;
    END;
END;
$$;
-- Answer: CREATE succeeds because the PL/pgSQL body is parsed/validated when
-- invoked. At call time, bike_id/model can refer either to OUT variables or
-- table columns, so PostgreSQL reports ambiguity.

-- Fix 1: rename the output columns
CREATE OR REPLACE FUNCTION bike_list(p_station_id INT)
RETURNS TABLE (result_bike_id INT, result_model VARCHAR) AS $$
BEGIN
    RETURN QUERY
    SELECT b.bike_id, b.model::VARCHAR
      FROM bikes AS b
     WHERE b.station_id = p_station_id
     ORDER BY b.bike_id;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM bike_list(10);

-- Fix 2: keep output names, qualify every table column with an alias
CREATE OR REPLACE FUNCTION bike_list(p_station_id INT)
RETURNS TABLE (bike_id INT, model VARCHAR) AS $$
BEGIN
    RETURN QUERY
    SELECT b.bike_id, b.model::VARCHAR
      FROM bikes AS b
     WHERE b.station_id = p_station_id
     ORDER BY b.bike_id;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM bike_list(10);

-- Exercise 5.4: Casting the output
CREATE OR REPLACE FUNCTION station_board(p_city VARCHAR)
RETURNS TABLE (
    s_name VARCHAR,
    s_bikes INT,
    s_free INT
) AS $$
BEGIN
    RETURN QUERY
    SELECT s.station_name::VARCHAR,
           COUNT(b.bike_id)::INT,
           (s.capacity - COUNT(b.bike_id))::INT
      FROM stations AS s
      LEFT JOIN bikes AS b ON b.station_id = s.station_id
     WHERE s.city = p_city
     GROUP BY s.station_id, s.station_name, s.capacity
     ORDER BY s.station_id;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM station_board('Almaty');
SELECT * FROM station_board('Astana');

-- Demonstrate the BIGINT-to-INT mismatch and capture the server's exact text.
CREATE OR REPLACE FUNCTION station_board_uncast(p_city VARCHAR)
RETURNS TABLE (s_name VARCHAR, s_bikes INT, s_free INT) AS $$
BEGIN
    RETURN QUERY
    SELECT s.station_name::VARCHAR,
           COUNT(b.bike_id),
           (s.capacity - COUNT(b.bike_id))::INT
      FROM stations AS s
      LEFT JOIN bikes AS b ON b.station_id = s.station_id
     WHERE s.city = p_city
     GROUP BY s.station_id, s.station_name, s.capacity;
END;
$$ LANGUAGE plpgsql;

DO $$
BEGIN
    BEGIN
        PERFORM * FROM station_board_uncast('Almaty');
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'Exercise 5.4 captured error: %', SQLERRM;
    END;
END;
$$;
-- Answer: COUNT returns BIGINT, while the declared output is INT. Without
-- casting, RETURN QUERY fails at execution because the query column type
-- does not match the declared result type. The NOTICE prints exact wording.

-- ============================================================
-- PART 6: BLOCK STRUCTURE, DO BLOCKS AND SUBBLOCKS
-- ============================================================

-- Exercise 6.1: An anonymous labelled block
DO $$
<<rental_report>>
DECLARE
    total_rentals INTEGER := 0;
BEGIN
    SELECT COUNT(*)::INT INTO total_rentals FROM rentals;
    RAISE NOTICE 'The rentals table holds % rows.', total_rentals;
END rental_report;
$$;
-- Answer: a mismatched label after END causes a syntax/compile error because
-- the closing block label must match its opening label.

-- Exercise 6.2: A subblock and a hidden variable
DO $$
<<outer_block>>
DECLARE
    fee_total NUMERIC;
BEGIN
    SELECT COALESCE(SUM(fee), 0) INTO fee_total FROM rentals;
    RAISE NOTICE '1. Outer total before subblock: %', fee_total;

    DECLARE
        fee_total NUMERIC;
    BEGIN
        SELECT COALESCE(SUM(fee), 0)
          INTO fee_total
          FROM rentals
         WHERE start_date >= DATE '2025-01-01';
        RAISE NOTICE '2. Subblock total: %', fee_total;
        RAISE NOTICE '3. Outer total from subblock: %', outer_block.fee_total;
    END;

    RAISE NOTICE '4. Outer total after subblock: %', fee_total;
END outer_block;
$$;
-- Answer: the subblock's local declaration shadows the outer variable.
-- Assigning the local variable does not change the outer one; the outer
-- variable is accessible as outer_block.fee_total.

-- Exercise 6.3: Declarations are local
DO $$
BEGIN
    BEGIN
        DECLARE
            first_only NUMERIC := 123;
        BEGIN
            RAISE NOTICE 'First subblock value: %', first_only;
        END;
    END;

    BEGIN
        -- Dynamic execution allows the invalid example to be caught so that
        -- the rest of this single-file script can continue.
        BEGIN
            EXECUTE 'DO $inner$ BEGIN RAISE NOTICE ''%'' , first_only; END $inner$';
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'Exercise 6.3 local-scope error: %', SQLERRM;
        END;
    END;
END;
$$;

-- Corrected demonstration: declare the shared variable in the outer block.
DO $$
DECLARE
    shared_value NUMERIC := 456;
BEGIN
    BEGIN
        RAISE NOTICE 'First subblock sees shared value: %', shared_value;
    END;
    BEGIN
        RAISE NOTICE 'Second subblock also sees shared value: %', shared_value;
    END;
END;
$$;
-- Answer: a variable declared in a subblock ceases to be in scope when that
-- subblock ends. Moving its declaration to the outer block makes it visible
-- to both nested blocks.

-- Exercise 6.4: From a block to a function
CREATE OR REPLACE FUNCTION fee_split(
    p_from_date DATE,
    OUT before_total NUMERIC,
    OUT after_total NUMERIC
) AS $$
BEGIN
    SELECT COALESCE(SUM(fee), 0)
      INTO before_total
      FROM rentals
     WHERE start_date < p_from_date;

    SELECT COALESCE(SUM(fee), 0)
      INTO after_total
      FROM rentals
     WHERE start_date >= p_from_date;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM fee_split(DATE '2025-01-01');
SELECT before_total + after_total AS combined_total,
       (SELECT COALESCE(SUM(fee), 0) FROM rentals) AS whole_table_total
FROM fee_split(DATE '2025-01-01');

-- ============================================================
-- PART 7: PRACTICAL SCENARIOS
-- ============================================================

-- Exercise 7.1: Station occupancy
CREATE OR REPLACE FUNCTION station_load(
    p_station_id INT,
    OUT bikes_parked INT,
    OUT capacity_pct NUMERIC
) AS $$
DECLARE
    v_capacity INT;
BEGIN
    SELECT s.capacity, COUNT(b.bike_id)::INT
      INTO v_capacity, bikes_parked
      FROM stations AS s
      LEFT JOIN bikes AS b ON b.station_id = s.station_id
     WHERE s.station_id = p_station_id
     GROUP BY s.capacity;

    capacity_pct :=
        CASE WHEN v_capacity = 0 THEN 0
             ELSE ROUND(bikes_parked * 100.0 / v_capacity, 1)
        END;
END;
$$ LANGUAGE plpgsql;

SELECT s.station_id, s.station_name, l.*
FROM stations AS s,
     LATERAL station_load(s.station_id) AS l
ORDER BY s.station_id;
-- Answer: for zero capacity (station 50), return 0.0% as a safe sentinel:
-- no docks exist, so a percentage is undefined; this avoids division by zero.

-- Exercise 7.2: Top members, with a default
CREATE OR REPLACE FUNCTION top_members(p_limit INT DEFAULT 3)
RETURNS TABLE (
    member_name VARCHAR,
    rental_count BIGINT,
    amount_spent NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT m.full_name::VARCHAR,
           COUNT(r.rental_id),
           COALESCE(SUM(r.fee), 0)::NUMERIC
      FROM members AS m
      LEFT JOIN rentals AS r ON r.member_id = m.member_id
     GROUP BY m.member_id, m.full_name
     ORDER BY COALESCE(SUM(r.fee), 0) DESC, COUNT(r.rental_id) DESC, m.member_id
     LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM top_members();
SELECT * FROM top_members(6);
-- Answer: member 1 (Aisha Nurlanova) has 5 rentals and spends 98.00,
-- while member 2 (Daniyar Serik) has 4 rentals and spends 138.00. Member 2
-- ranks higher because the ordering is by total amount spent, not rental count.

-- Exercise 7.3: An invoice for an open rental
CREATE OR REPLACE FUNCTION rental_invoice(p_rental_id INT)
RETURNS TABLE (
    invoice_member VARCHAR,
    invoice_model VARCHAR,
    invoice_days INT,
    amount_owed NUMERIC,
    rental_status VARCHAR
) AS $$
BEGIN
    RETURN QUERY
    SELECT m.full_name::VARCHAR,
           b.model::VARCHAR,
           (COALESCE(r.end_date, CURRENT_DATE) - r.start_date)::INT,
           ROUND((COALESCE(r.end_date, CURRENT_DATE) - r.start_date)
                 * b.daily_rate, 2)::NUMERIC,
           CASE WHEN r.end_date IS NULL THEN 'OPEN'::VARCHAR
                ELSE 'CLOSED'::VARCHAR
           END
      FROM rentals AS r
      JOIN members AS m ON m.member_id = r.member_id
      JOIN bikes AS b ON b.bike_id = r.bike_id
     WHERE r.rental_id = p_rental_id;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM rental_invoice(11);
SELECT * FROM rental_invoice(19);
-- Answer: rental 11's calculated charge equals its stored fee (74.00).
-- Rental 19 changes as CURRENT_DATE advances. A function depending on the
-- current date is not IMMUTABLE; it is at least STABLE for a statement.

-- Exercise 7.4: A report per city
CREATE OR REPLACE FUNCTION city_report(p_city VARCHAR)
RETURNS TABLE (
    city_members BIGINT,
    city_rentals BIGINT,
    city_revenue NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT COUNT(DISTINCT m.member_id),
           COUNT(r.rental_id),
           COALESCE(SUM(r.fee), 0)::NUMERIC
      FROM members AS m
      LEFT JOIN rentals AS r ON r.member_id = m.member_id
     WHERE m.city = p_city;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION city_report(p_city VARCHAR, p_from_date DATE)
RETURNS TABLE (
    city_members BIGINT,
    city_rentals BIGINT,
    city_revenue NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT COUNT(DISTINCT m.member_id),
           COUNT(r.rental_id),
           COALESCE(SUM(r.fee), 0)::NUMERIC
      FROM members AS m
      LEFT JOIN rentals AS r
        ON r.member_id = m.member_id
       AND r.start_date >= p_from_date
     WHERE m.city = p_city;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM city_report('Almaty');
SELECT * FROM city_report('Almaty', DATE '2025-01-01');
-- Answer: the date predicate belongs in the LEFT JOIN's ON clause. Putting
-- it in WHERE removes NULL-extended rows for members without qualifying
-- rentals and changes the member count. For Almaty, ON preserves all 3
-- members; WHERE would count only members with rentals since the cutoff.

-- ============================================================
-- LAB QUESTIONS ANSWERS
-- ============================================================

-- 1. A function name is its identifier; its signature is its name plus
--    argument types. DROP needs the signature because overloads share a name.
-- 2. Dollar quoting marks a function body without escaping its single quotes.
--    Example: RETURN 'Member''s total'; is straightforward inside $$ ... $$.
-- 3. OUT parameters suit a small fixed set of scalar outputs from one call.
--    RETURNS TABLE is preferable when the result is naturally rows that can
--    be queried, filtered, joined, or ordered by SQL.
-- 4. VARIADIC consumes all remaining arguments. If a required parameter came
--    after it, a call such as f(10, 20, 30) could not identify which trailing
--    value belongs to that later parameter versus the variadic array.
-- 5. RETURN ends a scalar function with one value (or exits a void function);
--    RETURN QUERY appends all rows from a query to a set/table result.
-- 6. A DEFAULT overload can make a call match more than one function.
--    Avoid this by designing non-overlapping signatures and testing call
--    resolution before deploying; remove obsolete overloads deliberately.
-- 7. A subblock variable leaves scope when the block ends. A shadowed outer
--    variable is accessed using its block label, e.g. outer_block.fee_total.
-- 8. Advantage: one centrally enforced business rule and fewer client/server
--    round trips. Disadvantage: database-specific logic is harder to port,
--    version, and test independently.
-- 9. A trusted language is restricted from unsafe access outside the server;
--    ordinary users with suitable privileges may create PL/pgSQL functions.
--    An untrusted language can access external resources and is restricted
--    to superusers; PL/Python is untrusted in the standard installation.
-- 10. Changing argument types creates a different overload; CREATE OR REPLACE
--     does not replace the old signature. The old function remains and can
--     cause ambiguity or unexpected resolution unless explicitly dropped.