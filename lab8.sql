-- Laboratory Work 8: SQL Indexes 

-- ---------------------------------------------------------------------
-- Part 1: Database Setup
-- ---------------------------------------------------------------------
DROP VIEW  IF EXISTS index_documentation;
DROP TABLE IF EXISTS projects  CASCADE;
DROP TABLE IF EXISTS employees CASCADE;
DROP TABLE IF EXISTS departments CASCADE;

CREATE TABLE departments (
    dept_id   INT PRIMARY KEY,
    dept_name VARCHAR(50),
    location  VARCHAR(50)
);

CREATE TABLE employees (
    emp_id   INT PRIMARY KEY,
    emp_name VARCHAR(100),
    dept_id  INT,
    salary   DECIMAL(10,2),
    FOREIGN KEY (dept_id) REFERENCES departments(dept_id)
);

CREATE TABLE projects (
    proj_id   INT PRIMARY KEY,
    proj_name VARCHAR(100),
    budget    DECIMAL(12,2),
    dept_id   INT,
    FOREIGN KEY (dept_id) REFERENCES departments(dept_id)
);

INSERT INTO departments VALUES
(101, 'IT', 'Building A'),
(102, 'HR', 'Building B'),
(103, 'Operations', 'Building C');

INSERT INTO employees VALUES
(1, 'John Smith',     101, 50000),
(2, 'Jane Doe',       101, 55000),
(3, 'Mike Johnson',   102, 48000),
(4, 'Sarah Williams', 102, 52000),
(5, 'Tom Brown',      103, 60000);

INSERT INTO projects VALUES
(201, 'Website Redesign',    75000,  101),
(202, 'Database Migration',  120000, 101),
(203, 'HR System Upgrade',   50000,  102);

-- ---------------------------------------------------------------------
-- Part 2: Creating Basic Indexes
-- ---------------------------------------------------------------------
-- Exercise 2.1
CREATE INDEX emp_salary_idx ON employees(salary);

SELECT indexname, indexdef
FROM pg_indexes
WHERE tablename = 'employees';
-- Q: How many indexes exist on employees?
-- A: 2  ->  employees_pkey (automatic, PRIMARY KEY) + emp_salary_idx.

-- Exercise 2.2
CREATE INDEX emp_dept_idx ON employees(dept_id);

SELECT * FROM employees WHERE dept_id = 101;
-- Q: Why index foreign key columns?
-- A: PostgreSQL does NOT index FK columns automatically. An index speeds up
--    JOINs on the FK, lookups of "all children of a parent", and makes
--    DELETE/UPDATE on the parent table faster (the FK check must find child rows
--    without scanning the whole child table).

-- Exercise 2.3
SELECT tablename, indexname, indexdef
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename, indexname;
-- Q: List indexes; which were automatic?
-- A: departments_pkey, employees_pkey, projects_pkey  -> automatic (PRIMARY KEY).
--    emp_salary_idx, emp_dept_idx                      -> created manually.

-- ---------------------------------------------------------------------
-- Part 3: Multicolumn Indexes
-- ---------------------------------------------------------------------
-- Exercise 3.1
CREATE INDEX emp_dept_salary_idx ON employees(dept_id, salary);

SELECT emp_name, salary
FROM employees
WHERE dept_id = 101 AND salary > 52000;
-- Q: Useful for a query filtering only by salary?
-- A: Generally no/poorly. A B-tree multicolumn index is sorted by the leftmost
--    column first (dept_id), so without a condition on dept_id the planner can't
--    efficiently seek into it (it can only scan the whole index).

-- Exercise 3.2
CREATE INDEX emp_salary_dept_idx ON employees(salary, dept_id);

SELECT * FROM employees WHERE dept_id = 102 AND salary > 50000;  -- Query 1
SELECT * FROM employees WHERE salary > 50000 AND dept_id = 102;  -- Query 2
-- Q: Does column order matter?
-- A: Yes, for the index. The order of conditions in WHERE does NOT matter (the
--    planner treats both queries identically). The order of columns in the INDEX
--    matters: put the column used with equality (dept_id) first and the range
--    column (salary) second; the leftmost column should be the one used most often.

-- ---------------------------------------------------------------------
-- Part 4: Unique Indexes
-- ---------------------------------------------------------------------
-- Exercise 4.1
ALTER TABLE employees ADD COLUMN email VARCHAR(100);
UPDATE employees SET email = 'john.smith@company.com'      WHERE emp_id = 1;
UPDATE employees SET email = 'jane.doe@company.com'        WHERE emp_id = 2;
UPDATE employees SET email = 'mike.johnson@company.com'    WHERE emp_id = 3;
UPDATE employees SET email = 'sarah.williams@company.com'  WHERE emp_id = 4;
UPDATE employees SET email = 'tom.brown@company.com'       WHERE emp_id = 5;

CREATE UNIQUE INDEX emp_email_unique_idx ON employees(email);

-- Wrapped in DO block so the script doesn't stop on the expected error;
-- the message is shown in the "Messages/Output" panel.
DO $$
BEGIN
    INSERT INTO employees (emp_id, emp_name, dept_id, salary, email)
    VALUES (6, 'New Employee', 101, 55000, 'john.smith@company.com');
EXCEPTION WHEN unique_violation THEN
    RAISE NOTICE 'Expected error: %', SQLERRM;
END $$;
-- Q: What error message?
-- A: ERROR: duplicate key value violates unique constraint "emp_email_unique_idx"
--    DETAIL: Key (email)=(john.smith@company.com) already exists.   (SQLSTATE 23505)

-- Exercise 4.2
ALTER TABLE employees ADD COLUMN phone VARCHAR(20) UNIQUE;

SELECT indexname, indexdef
FROM pg_indexes
WHERE tablename = 'employees' AND indexname LIKE '%phone%';
-- Q: Was an index created automatically? What type?
-- A: Yes: employees_phone_key, a UNIQUE B-tree index
--    (PostgreSQL implements UNIQUE constraints via unique B-tree indexes).

-- ---------------------------------------------------------------------
-- Part 5: Indexes and Sorting
-- ---------------------------------------------------------------------
-- Exercise 5.1
CREATE INDEX emp_salary_desc_idx ON employees(salary DESC);

SELECT emp_name, salary
FROM employees
ORDER BY salary DESC;
-- Q: How does it help ORDER BY?
-- A: Index entries are already stored in descending order, so the planner can
--    read rows in that order directly (Index Scan) instead of sorting them.
--    (Note: a plain ASC B-tree can also be scanned backwards, so DESC matters
--    mostly for multicolumn indexes with mixed directions.)

-- Exercise 5.2
CREATE INDEX proj_budget_nulls_first_idx ON projects(budget NULLS FIRST);

SELECT proj_name, budget
FROM projects
ORDER BY budget NULLS FIRST;
-- Index stores NULL budgets first, matching ORDER BY ... NULLS FIRST, so no sort is needed.

-- ---------------------------------------------------------------------
-- Part 6: Indexes on Expressions
-- ---------------------------------------------------------------------
-- Exercise 6.1
CREATE INDEX emp_name_lower_idx ON employees(LOWER(emp_name));

SELECT * FROM employees WHERE LOWER(emp_name) = 'john smith';
-- Q: Without the index, how does PostgreSQL search case-insensitively?
-- A: Sequential scan: it reads every row and computes LOWER(emp_name) for each
--    one, then compares. A normal index on emp_name can't be used for this.

-- Exercise 6.2
ALTER TABLE employees ADD COLUMN hire_date DATE;
UPDATE employees SET hire_date = '2020-01-15' WHERE emp_id = 1;
UPDATE employees SET hire_date = '2019-06-20' WHERE emp_id = 2;
UPDATE employees SET hire_date = '2021-03-10' WHERE emp_id = 3;
UPDATE employees SET hire_date = '2020-11-05' WHERE emp_id = 4;
UPDATE employees SET hire_date = '2018-08-25' WHERE emp_id = 5;

CREATE INDEX emp_hire_year_idx ON employees(EXTRACT(YEAR FROM hire_date));

SELECT emp_name, hire_date
FROM employees
WHERE EXTRACT(YEAR FROM hire_date) = 2020;

-- ---------------------------------------------------------------------
-- Part 7: Managing Indexes
-- ---------------------------------------------------------------------
-- Exercise 7.1
ALTER INDEX emp_salary_idx RENAME TO employees_salary_index;
SELECT indexname FROM pg_indexes WHERE tablename = 'employees';

-- Exercise 7.2
DROP INDEX emp_salary_dept_idx;
-- Q: Why drop an index?
-- A: It's redundant/duplicate or unused; every index costs disk space and slows
--    INSERT/UPDATE/DELETE, and adds maintenance (VACUUM) overhead.

-- Exercise 7.3
REINDEX INDEX employees_salary_index;
-- Useful after bulk inserts, when the index is bloated, after big data modifications.

-- ---------------------------------------------------------------------
-- Part 8: Practical Scenarios
-- ---------------------------------------------------------------------
-- Exercise 8.1
SELECT e.emp_name, e.salary, d.dept_name
FROM employees e
JOIN departments d ON e.dept_id = d.dept_id
WHERE e.salary > 50000
ORDER BY e.salary DESC;

CREATE INDEX emp_salary_filter_idx ON employees(salary) WHERE salary > 50000;
-- JOIN:     emp_dept_idx          (already created)
-- ORDER BY: emp_salary_desc_idx   (already created)

-- Exercise 8.2
CREATE INDEX proj_high_budget_idx ON projects(budget) WHERE budget > 80000;

SELECT proj_name, budget FROM projects WHERE budget > 80000;
-- Q: Advantage of a partial index?
-- A: Smaller (only indexes matching rows), faster to scan, cheaper to maintain
--    (writes to non-matching rows don't touch it), saves disk space.

-- Exercise 8.3
EXPLAIN SELECT * FROM employees WHERE salary > 52000;
-- Q: Index Scan or Seq Scan? What does it tell?
-- A: With only 5 rows the planner will almost certainly choose Seq Scan: reading
--    one small page is cheaper than going through an index. The index is used
--    only when it's cheaper (large tables, selective conditions). To see the index
--    in action on tiny data (for the screenshot), run:
SET enable_seqscan = off;
EXPLAIN SELECT * FROM employees WHERE salary > 52000;
RESET enable_seqscan;
-- REAL OUTPUT (PostgreSQL 16, 5 rows):
--   Seq Scan on employees  (cost=0.00..1.06 rows=2 width=522)
--     Filter: (salary > '52000'::numeric)
-- => Seq Scan: the table is tiny, so the planner doesn't use the index.

-- ---------------------------------------------------------------------
-- Part 9: Index Types Comparison
-- ---------------------------------------------------------------------
-- Exercise 9.1
CREATE INDEX dept_name_hash_idx ON departments USING HASH (dept_name);

SELECT * FROM departments WHERE dept_name = 'IT';
-- Q: When use HASH instead of B-tree?
-- A: Only when you do pure equality (=) lookups on a column and never need
--    range queries, sorting or multicolumn/unique indexes. Can be slightly
--    smaller/faster for long values; in practice B-tree is almost always enough.

-- Exercise 9.2
CREATE INDEX proj_name_btree_idx ON projects(proj_name);
CREATE INDEX proj_name_hash_idx  ON projects USING HASH (proj_name);

SELECT * FROM projects WHERE proj_name = 'Website Redesign';  -- both can be used
SELECT * FROM projects WHERE proj_name > 'Database';          -- only B-tree

-- ---------------------------------------------------------------------
-- Part 10: Cleanup and Best Practices
-- ---------------------------------------------------------------------
-- Exercise 10.1
SELECT
    schemaname,
    tablename,
    indexname,
    pg_size_pretty(pg_relation_size(indexname::regclass)) AS index_size
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename, indexname;
-- Q: Which is the largest? Why?
-- A: The hash indexes (dept_name_hash_idx and proj_name_hash_idx) - 32 kB each;
--    all other indexes are 16 kB. Tables have only a few rows, so size is set by
--    the minimum index structure: a hash index pre-allocates several bucket pages,
--    a B-tree needs just a metapage + one leaf page. On a big table the B-tree grows
--    with the number of rows (index on 200,000 rows ~ 6 MB).

-- Exercise 10.2
DROP INDEX IF EXISTS proj_name_hash_idx;

-- Exercise 10.3
CREATE VIEW index_documentation AS
SELECT
    tablename,
    indexname,
    indexdef,
    'Improves salary-based queries' AS purpose
FROM pg_indexes
WHERE schemaname = 'public'
  AND indexname LIKE '%salary%';

SELECT * FROM index_documentation;

-- =====================================================================
-- SUMMARY QUESTIONS
-- =====================================================================
-- 1. Default index type in PostgreSQL?
--    B-tree.
-- 2. Three scenarios where you should create an index:
--    (a) columns frequently used in WHERE;
--    (b) foreign key columns / columns used in JOIN conditions;
--    (c) columns used in ORDER BY on large tables (and columns that must be unique).
-- 3. Two scenarios where you should NOT create an index:
--    (a) very small tables (seq scan is faster);
--    (b) write-heavy tables or low-selectivity / rarely queried columns.
-- 4. What happens to indexes on INSERT, UPDATE, DELETE?
--    PostgreSQL must update every affected index, so writes get slower and
--    indexes can become bloated over time.
-- 5. How to check if a query uses an index?
--    EXPLAIN / EXPLAIN ANALYZE: look for Index Scan, Index Only Scan or
--    Bitmap Index Scan instead of Seq Scan.

-- =====================================================================
-- REFLECTION: when to use indexes
-- =====================================================================
-- Indexes are a trade-off: they make reads faster but cost disk space and slow
-- down writes. Create them on columns used often in WHERE, JOIN and ORDER BY,
-- especially foreign keys; use multicolumn, partial and expression indexes for
-- specific query patterns. Don't index everything or tiny tables - the planner
-- ignores indexes there. Always verify with EXPLAIN ANALYZE and remove duplicate
-- or unused indexes.
