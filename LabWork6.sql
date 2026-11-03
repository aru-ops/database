-- PART 1: DATABASE SETUP

-- Drop old tables so the script can be re-run safely
DROP TABLE IF EXISTS projects;
DROP TABLE IF EXISTS employees;
DROP TABLE IF EXISTS departments;

-- Step 1.1: Create tables
CREATE TABLE employees (
    emp_id    INT PRIMARY KEY,
    emp_name  VARCHAR(50),
    dept_id   INT,
    salary    DECIMAL(10, 2)
);

CREATE TABLE departments (
    dept_id   INT PRIMARY KEY,
    dept_name VARCHAR(50),
    location  VARCHAR(50)
);

CREATE TABLE projects (
    project_id   INT PRIMARY KEY,
    project_name VARCHAR(50),
    dept_id      INT,
    budget       DECIMAL(10, 2)
);

-- Step 1.2: Insert sample data
INSERT INTO employees (emp_id, emp_name, dept_id, salary) VALUES
(1, 'John Smith',     101,  50000),
(2, 'Jane Doe',       102,  60000),
(3, 'Mike Johnson',   101,  55000),
(4, 'Sarah Williams', 103,  65000),
(5, 'Tom Brown',      NULL, 45000);

INSERT INTO departments (dept_id, dept_name, location) VALUES
(101, 'IT',        'Building A'),
(102, 'HR',        'Building B'),
(103, 'Finance',   'Building C'),
(104, 'Marketing', 'Building D');

INSERT INTO projects (project_id, project_name, dept_id, budget) VALUES
(1, 'Website Redesign',   101, 100000),
(2, 'Employee Training',  102,  50000),
(3, 'Budget Analysis',    103,  75000),
(4, 'Cloud Migration',    101, 150000),
(5, 'AI Research',        NULL, 200000);


-- PART 2: CROSS JOIN

-- Exercise 2.1: Basic CROSS JOIN (all employee-department combinations)
SELECT e.emp_name, d.dept_name
FROM employees e CROSS JOIN departments d;
-- Answer: 20 rows. N x M = 5 employees x 4 departments = 20.

-- Exercise 2.2: Alternative CROSS JOIN syntax
-- a) Comma notation
SELECT e.emp_name, d.dept_name
FROM employees e, departments d;

-- b) INNER JOIN with a TRUE condition (every pair matches)
SELECT e.emp_name, d.dept_name
FROM employees e
INNER JOIN departments d ON TRUE;

-- Exercise 2.3: Practical CROSS JOIN (employee x project availability matrix)
SELECT e.emp_name, p.project_name
FROM employees e
CROSS JOIN projects p
ORDER BY e.emp_name, p.project_name;
-- 5 x 5 = 25 rows


-- PART 3: INNER JOIN

-- Exercise 3.1: Basic INNER JOIN with ON
SELECT e.emp_name, d.dept_name, d.location
FROM employees e
INNER JOIN departments d ON e.dept_id = d.dept_id;
-- Answer: 4 rows. Tom Brown is not included because his dept_id is NULL,
-- and NULL is never equal to any value, so he has no match in departments.

-- Exercise 3.2: INNER JOIN with USING
SELECT emp_name, dept_name, location
FROM employees
INNER JOIN departments USING (dept_id);
-- Answer: With ON, SELECT * returns dept_id twice (e.dept_id and d.dept_id).
-- With USING, the join column appears only once in the output.

-- Exercise 3.3: NATURAL INNER JOIN (joins on all same-named columns: dept_id)
SELECT emp_name, dept_name, location
FROM employees
NATURAL INNER JOIN departments;

-- Exercise 3.4: Multi-table INNER JOIN
SELECT e.emp_name, d.dept_name, p.project_name
FROM employees e
INNER JOIN departments d ON e.dept_id = d.dept_id
INNER JOIN projects p    ON d.dept_id = p.dept_id;
-- 6 rows (IT has two projects, so John and Mike each appear twice)

-- PART 4: LEFT JOIN

-- Exercise 4.1: Basic LEFT JOIN (keeps employees without a department)
SELECT e.emp_name, e.dept_id AS emp_dept, d.dept_id AS dept_dept, d.dept_name
FROM employees e
LEFT JOIN departments d ON e.dept_id = d.dept_id;
-- Answer: Tom Brown appears with NULL in emp_dept, dept_dept and dept_name.

-- Exercise 4.2: LEFT JOIN with USING
SELECT emp_name, dept_id, dept_name
FROM employees
LEFT JOIN departments USING (dept_id);

-- Exercise 4.3: Find unmatched records (anti-join pattern)
-- Rows with no match in departments have NULL in d.dept_id
SELECT e.emp_name, e.dept_id
FROM employees e
LEFT JOIN departments d ON e.dept_id = d.dept_id
WHERE d.dept_id IS NULL;
-- Result: Tom Brown

-- Exercise 4.4: LEFT JOIN with aggregation
-- COUNT(e.emp_id) ignores NULLs, so Marketing gets 0 instead of 1
SELECT d.dept_name, COUNT(e.emp_id) AS employee_count
FROM departments d
LEFT JOIN employees e ON d.dept_id = e.dept_id
GROUP BY d.dept_id, d.dept_name
ORDER BY employee_count DESC;
-- IT = 2, HR = 1, Finance = 1, Marketing = 0


-- PART 5: RIGHT JOIN

-- Exercise 5.1: Basic RIGHT JOIN (keeps all departments)
SELECT e.emp_name, d.dept_name
FROM employees e
RIGHT JOIN departments d ON e.dept_id = d.dept_id;

-- Exercise 5.2: Same query as LEFT JOIN (tables swapped)
SELECT e.emp_name, d.dept_name
FROM departments d
LEFT JOIN employees e ON e.dept_id = d.dept_id;

-- Exercise 5.3: Find departments without employees
SELECT d.dept_name, d.location
FROM employees e
RIGHT JOIN departments d ON e.dept_id = d.dept_id
WHERE e.emp_id IS NULL;
-- Result: Marketing, Building D


-- PART 6: FULL JOIN

-- Exercise 6.1: Basic FULL JOIN
SELECT e.emp_name, e.dept_id AS emp_dept, d.dept_id AS dept_dept, d.dept_name
FROM employees e
FULL JOIN departments d ON e.dept_id = d.dept_id;
-- Answer: NULLs on the left (employee columns): Marketing (no employees).
--         NULLs on the right (department columns): Tom Brown (no department).

-- Exercise 6.2: FULL JOIN of departments and projects
SELECT d.dept_name, p.project_name, p.budget
FROM departments d
FULL JOIN projects p ON d.dept_id = p.dept_id;
-- Marketing has no projects; the AI Research project has no department.

-- Exercise 6.3: Find orphaned records on both sides
-- CASE labels each unmatched row depending on which side is missing
SELECT
    CASE
        WHEN e.emp_id IS NULL THEN 'Department without employees'
        WHEN d.dept_id IS NULL THEN 'Employee without department'
        ELSE 'Matched'
    END AS record_status,
    e.emp_name,
    d.dept_name
FROM employees e
FULL JOIN departments d ON e.dept_id = d.dept_id
WHERE e.emp_id IS NULL OR d.dept_id IS NULL;


-- PART 7: ON vs WHERE


-- Exercise 7.1: Filter in the ON clause (LEFT JOIN) - Query 1
SELECT e.emp_name, d.dept_name, e.salary
FROM employees e
LEFT JOIN departments d ON e.dept_id = d.dept_id AND d.location = 'Building A';
-- 5 rows: all employees are kept; dept_name is filled only for John and Mike.

-- Exercise 7.2: Filter in the WHERE clause (LEFT JOIN) - Query 2
SELECT e.emp_name, d.dept_name, e.salary
FROM employees e
LEFT JOIN departments d ON e.dept_id = d.dept_id
WHERE d.location = 'Building A';
-- 2 rows: only John and Mike.
-- Answer:
--  * Query 1 (ON): the condition is part of the join, so employees without
--    a matching Building A department are kept with NULLs.
--  * Query 2 (WHERE): the filter runs AFTER the join and removes rows with
--    NULL location, so the LEFT JOIN effectively behaves like an INNER JOIN.

-- Exercise 7.3: ON vs WHERE with INNER JOIN
-- Query 1 (filter in ON)
SELECT e.emp_name, d.dept_name, e.salary
FROM employees e
INNER JOIN departments d ON e.dept_id = d.dept_id AND d.location = 'Building A';

-- Query 2 (filter in WHERE)
SELECT e.emp_name, d.dept_name, e.salary
FROM employees e
INNER JOIN departments d ON e.dept_id = d.dept_id
WHERE d.location = 'Building A';
-- Answer: The results are identical (John and Mike). INNER JOIN discards
-- non-matching rows anyway, so it does not matter whether the filter is
-- applied before or after the join. In outer joins non-matching rows are
-- preserved with NULLs, so the filter position changes the result.


-- PART 8: COMPLEX JOIN SCENARIOS

-- Exercise 8.1: Multiple joins (all departments, plus employees and projects if any)
-- Note: employees and projects are not related to each other, so each
-- department shows every employee x project combination.
SELECT
    d.dept_name,
    e.emp_name,
    e.salary,
    p.project_name,
    p.budget
FROM departments d
LEFT JOIN employees e ON d.dept_id = e.dept_id
LEFT JOIN projects p  ON d.dept_id = p.dept_id
ORDER BY d.dept_name, e.emp_name;

-- Exercise 8.2: Self join
-- Add manager_id column
ALTER TABLE employees ADD COLUMN manager_id INT;

-- Update with sample data (Mike Johnson is the manager of everyone else)
UPDATE employees SET manager_id = 3    WHERE emp_id = 1;
UPDATE employees SET manager_id = 3    WHERE emp_id = 2;
UPDATE employees SET manager_id = NULL WHERE emp_id = 3;
UPDATE employees SET manager_id = 3    WHERE emp_id = 4;
UPDATE employees SET manager_id = 3    WHERE emp_id = 5;

-- Same table used twice: e = employee, m = manager
SELECT
    e.emp_name AS employee,
    m.emp_name AS manager
FROM employees e
LEFT JOIN employees m ON e.manager_id = m.emp_id;

-- Exercise 8.3: Departments where the average salary is above 50000
SELECT d.dept_name, AVG(e.salary) AS avg_salary
FROM departments d
INNER JOIN employees e ON d.dept_id = e.dept_id
GROUP BY d.dept_id, d.dept_name
HAVING AVG(e.salary) > 50000;
-- Result: IT (52500), HR (60000), Finance (65000)


-- LAB QUESTIONS (answers)

-- 1. INNER JOIN returns only rows that have a match in both tables.
--    LEFT JOIN returns all rows from the left table; if there is no match
--    on the right, the right-side columns are filled with NULL.
--
-- 2. CROSS JOIN is used when all combinations are needed: availability
--    matrices (employees x projects), generating test data, calendars
--    (dates x employees), product variants (size x color).
--
-- 3. In an INNER JOIN, non-matching rows are dropped anyway, so a
--    condition in ON or WHERE gives the same result. In an OUTER JOIN, a
--    condition in ON only decides which rows match (the rest stay with
--    NULLs), while WHERE removes rows from the final result, including the
--    NULL-extended ones, which turns the outer join into an inner join.
--
-- 4. 5 x 10 = 50 rows.
--
-- 5. NATURAL JOIN automatically joins on ALL columns that have the same
--    name in both tables; each such column appears once in the result.
--
-- 6. Risks of NATURAL JOIN: adding a new column with a matching name
--    silently changes the join; accidental name matches (e.g. created_at,
--    name) give wrong results; with no common columns it becomes a CROSS
--    JOIN; the query is harder to read and maintain.
--
-- 7. SELECT * FROM B RIGHT JOIN A ON A.id = B.id
--    (same rows; column order in SELECT * is different).
--
-- 8. Use FULL OUTER JOIN when you need all rows from both tables:
--    finding orphaned records on both sides, reconciling data from two
--    systems, auditing differences.


-- ADDITIONAL CHALLENGES (optional)

-- Challenge 1: Simulate FULL OUTER JOIN with UNION of LEFT and RIGHT joins
-- UNION removes the duplicate matched rows that both queries return
SELECT e.emp_name, e.dept_id AS emp_dept, d.dept_id AS dept_dept, d.dept_name
FROM employees e
LEFT JOIN departments d ON e.dept_id = d.dept_id
UNION
SELECT e.emp_name, e.dept_id, d.dept_id, d.dept_name
FROM employees e
RIGHT JOIN departments d ON e.dept_id = d.dept_id;

-- Challenge 2: Employees in departments that have more than one project
-- The subquery finds departments with 2+ projects
SELECT e.emp_name, d.dept_name
FROM employees e
JOIN departments d ON e.dept_id = d.dept_id
WHERE d.dept_id IN (
    SELECT dept_id
    FROM projects
    WHERE dept_id IS NOT NULL
    GROUP BY dept_id
    HAVING COUNT(*) > 1
);
-- Result: John Smith, Mike Johnson (IT has 2 projects)

-- Challenge 3: Hierarchy (employee -> manager -> manager's manager)
SELECT
    e.emp_name  AS employee,
    m1.emp_name AS manager,
    m2.emp_name AS managers_manager
FROM employees e
LEFT JOIN employees m1 ON e.manager_id  = m1.emp_id
LEFT JOIN employees m2 ON m1.manager_id = m2.emp_id;

-- Same idea for any depth using a recursive CTE
-- Anchor: top-level employees (no manager). Recursive part: their reports.
WITH RECURSIVE org AS (
    SELECT emp_id, emp_name, manager_id, 1 AS level,
           CAST(emp_name AS VARCHAR(500)) AS path
    FROM employees
    WHERE manager_id IS NULL
    UNION ALL
    SELECT e.emp_id, e.emp_name, e.manager_id, o.level + 1,
           CAST(o.path || ' -> ' || e.emp_name AS VARCHAR(500))
    FROM employees e
    JOIN org o ON e.manager_id = o.emp_id
)
SELECT level, path FROM org ORDER BY level, path;

-- Challenge 4: All pairs of employees in the same department
-- e1.emp_id < e2.emp_id avoids self-pairs and duplicate (reversed) pairs
SELECT
    e1.emp_name AS employee_1,
    e2.emp_name AS employee_2,
    d.dept_name
FROM employees e1
JOIN employees e2 ON e1.dept_id = e2.dept_id AND e1.emp_id < e2.emp_id
JOIN departments d ON e1.dept_id = d.dept_id;
-- Result: John Smith + Mike Johnson (IT)