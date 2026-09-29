-- Laboratory Work #3 - DML Operations

-- PART A: Database and Table Setup
-- 1. Create database and tables
CREATE DATABASE advanced_lab;

CREATE TABLE employees (
    emp_id     SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name  VARCHAR(50) NOT NULL,
    department VARCHAR(50),
    salary     INTEGER DEFAULT 30000,
    hire_date  DATE,
    status     VARCHAR(20) DEFAULT 'Active'
);

CREATE TABLE departments (
    dept_id    SERIAL PRIMARY KEY,
    dept_name  VARCHAR(50) NOT NULL,
    budget     INTEGER,
    manager_id INTEGER
);

CREATE TABLE projects (
    project_id   SERIAL PRIMARY KEY,
    project_name VARCHAR(100) NOT NULL,
    dept_id      INTEGER,
    start_date   DATE,
    end_date     DATE,
    budget       INTEGER
);

-- PART B: Advanced INSERT Operations

-- 2. INSERT with column specification
INSERT INTO employees (emp_id, first_name, last_name, department)
VALUES (101, 'Aigerim', 'Sadykova', 'IT'),
       (102, 'Daniyar', 'Omarov', 'Sales');

-- sync the sequence after inserting emp_id manually
SELECT setval(pg_get_serial_sequence('employees', 'emp_id'),
              (SELECT MAX(emp_id) FROM employees));

-- 3. INSERT with DEFAULT values
INSERT INTO employees (first_name, last_name, department, salary, status)
VALUES ('Nurlan', 'Bekov', 'HR', DEFAULT, DEFAULT);

-- 4. INSERT multiple rows in single statement
INSERT INTO departments (dept_name, budget, manager_id)
VALUES ('IT',    150000, 101),
       ('Sales', 120000, 102),
       ('HR',     80000, NULL);

-- 5. INSERT with expressions
INSERT INTO employees (first_name, last_name, department, salary, hire_date)
VALUES ('Aliya', 'Nurpeisova', 'IT', 50000 * 1.1, CURRENT_DATE);

-- 6. INSERT from SELECT (subquery)
CREATE TEMPORARY TABLE temp_employees (LIKE employees);

INSERT INTO temp_employees
SELECT *
FROM employees
WHERE department = 'IT';

SELECT * FROM temp_employees;

-- SAMPLE DATA #1 (test data for parts C and D)
INSERT INTO employees (first_name, last_name, department, salary, hire_date, status)
VALUES ('Marat',    'Zhaksybekov', 'IT',    95000, '2018-03-15', 'Active'),
       ('Saltanat', 'Ibragimova',  'Sales', 72000, '2019-07-01', 'Active'),
       ('Timur',    'Kassymov',    'Sales', 48000, '2021-09-10', 'Active'),
       ('Madina',   'Abenova',     'HR',    65000, '2017-11-20', 'Active'),
       ('Ruslan',   'Tulegenov',   'IT',    55000, '2020-02-01', 'Inactive'),
       ('Zhanar',   'Ospanova',    'Sales', 40000, '2022-05-05', 'Terminated'),
       ('Erlan',    'Dosov',       'HR',    30000, '2019-12-12', 'Terminated');

-- PART C: Complex UPDATE Operations

-- 7. UPDATE with arithmetic expressions
UPDATE employees
SET salary = salary * 1.1;

-- 8. UPDATE with WHERE clause and multiple conditions
UPDATE employees
SET status = 'Senior'
WHERE salary > 60000
  AND hire_date < '2020-01-01';

-- 9. UPDATE using CASE expression
UPDATE employees
SET department = CASE
                     WHEN salary > 80000                 THEN 'Management'
                     WHEN salary BETWEEN 50000 AND 80000 THEN 'Senior'
                     ELSE 'Junior'
                 END;

-- SAMPLE DATA #2 (task 9 renamed the departments, so we add new data;
-- also departments and projects for later tasks)
INSERT INTO employees (first_name, last_name, department, salary, hire_date, status)
VALUES ('Kanat',   'Ermekov',    'IT',    70000, '2021-04-01', 'Active'),
       ('Dana',    'Serikova',   'IT',    58000, '2022-08-15', 'Active'),
       ('Asel',    'Nurgaliyeva','Sales', 52000, '2021-01-10', 'Active'),
       ('Yerbol',  'Kim',        'Sales', 61000, '2020-06-01', 'Active'),
       ('Gulnara', 'Akhmetova',  'HR',    45000, '2022-03-03', 'Active'),
       ('Ivan',    'Petrov',     NULL,    35000, '2023-06-01', 'Active');

INSERT INTO departments (dept_name, budget, manager_id)
VALUES ('Marketing', 60000, NULL);

INSERT INTO projects (project_name, dept_id, start_date, end_date, budget)
VALUES ('Website Redesign',  1, '2022-01-01', '2022-12-31',  40000),
       ('Mobile App',        1, '2023-03-01', '2024-03-01',  90000),
       ('CRM Migration',     2, '2023-06-01', '2024-06-01',  75000),
       ('Sales Campaign',    2, '2021-05-01', '2022-05-01',  30000),
       ('Hiring Portal',     3, '2023-09-01', '2024-09-01',  20000);

-- 10. UPDATE with DEFAULT (department has no default, so it becomes NULL)
UPDATE employees
SET department = DEFAULT
WHERE status = 'Inactive';

-- 11. UPDATE with subquery
-- departments are linked to employees by dept_name = department
UPDATE departments d
SET budget = (SELECT ROUND(AVG(e.salary) * 1.2)
              FROM employees e
              WHERE e.department = d.dept_name)
WHERE EXISTS (SELECT 1
              FROM employees e
              WHERE e.department = d.dept_name);

-- 12. UPDATE multiple columns
UPDATE employees
SET salary = salary * 1.15,
    status = 'Promoted'
WHERE department = 'Sales';

-- PART D: Advanced DELETE Operations

-- 13. DELETE with simple WHERE condition
DELETE FROM employees
WHERE status = 'Terminated';

-- 14. DELETE with complex WHERE clause
DELETE FROM employees
WHERE salary < 40000
  AND hire_date > '2023-01-01'
  AND department IS NULL;

-- 15. DELETE with subquery
-- dept_id is integer and department is text, so we compare by dept_name
DELETE FROM departments
WHERE dept_name NOT IN (SELECT DISTINCT department
                        FROM employees
                        WHERE department IS NOT NULL);

-- 16. DELETE with RETURNING clause
DELETE FROM projects
WHERE end_date < '2023-01-01'
RETURNING *;

-- PART E: Operations with NULL Values

-- 17. INSERT with NULL values
INSERT INTO employees (first_name, last_name, department, salary, hire_date)
VALUES ('Test', 'NullUser', NULL, NULL, '2024-01-15');

-- 18. UPDATE NULL handling
UPDATE employees
SET department = 'Unassigned'
WHERE department IS NULL;

-- 19. DELETE with NULL conditions
DELETE FROM employees
WHERE salary IS NULL
   OR department IS NULL;

-- PART F: RETURNING Clause Operations

-- 20. INSERT with RETURNING
INSERT INTO employees (first_name, last_name, department, salary, hire_date)
VALUES ('Sultan', 'Mukhamedov', 'IT', 62000, CURRENT_DATE)
RETURNING emp_id, first_name || ' ' || last_name AS full_name;

-- 21. UPDATE with RETURNING
-- RETURNING shows only new values, so the old salary is taken from a subquery
UPDATE employees e
SET salary = e.salary + 5000
FROM (SELECT emp_id, salary AS old_salary
      FROM employees
      WHERE department = 'IT') AS old_data
WHERE e.emp_id = old_data.emp_id
RETURNING e.emp_id, old_data.old_salary, e.salary AS new_salary;

-- 22. DELETE with RETURNING all columns
DELETE FROM employees
WHERE hire_date < '2020-01-01'
RETURNING *;

-- SAMPLE DATA #3 (test data for tasks 24, 26 and 27)
INSERT INTO employees (first_name, last_name, department, salary, hire_date, status)
VALUES ('Alikhan', 'Baimukhanov', 'IT', 66000, '2021-10-01', 'Active'),
       ('Aruzhan', 'Kenzhebek',   'IT', 59000, '2022-02-14', 'Active'),
       ('Bekzat',  'Sadvakasov',  'IT', 64000, '2023-01-09', 'Active'),
       ('Laura',   'Yesenova',    'HR', 47000, '2021-07-07', 'Inactive'),
       ('Anuar',   'Tokhtarov',   'Sales', 51000, '2022-11-11', 'Inactive');

UPDATE departments SET budget = 150000 WHERE dept_name = 'IT';

-- PART G: Advanced DML Patterns

-- 23. Conditional INSERT (first one is skipped because the employee exists)
INSERT INTO employees (first_name, last_name, department, salary, hire_date)
SELECT 'Aigerim', 'Sadykova', 'IT', 60000, CURRENT_DATE
WHERE NOT EXISTS (SELECT 1
                  FROM employees
                  WHERE first_name = 'Aigerim'
                    AND last_name  = 'Sadykova');

INSERT INTO employees (first_name, last_name, department, salary, hire_date)
SELECT 'Zarina', 'Baitursynova', 'HR', 50000, CURRENT_DATE
WHERE NOT EXISTS (SELECT 1
                  FROM employees
                  WHERE first_name = 'Zarina'
                    AND last_name  = 'Baitursynova');

-- 24. UPDATE with JOIN logic using subqueries
UPDATE employees e
SET salary = salary * CASE
                          WHEN (SELECT d.budget
                                FROM departments d
                                WHERE d.dept_name = e.department) > 100000
                              THEN 1.10
                          ELSE 1.05
                      END;

-- 25. Bulk operations
INSERT INTO employees (first_name, last_name, department, salary, hire_date)
VALUES ('Bulk1', 'User', 'Support', 40000, CURRENT_DATE),
       ('Bulk2', 'User', 'Support', 42000, CURRENT_DATE),
       ('Bulk3', 'User', 'Support', 44000, CURRENT_DATE),
       ('Bulk4', 'User', 'Support', 46000, CURRENT_DATE),
       ('Bulk5', 'User', 'Support', 48000, CURRENT_DATE);

UPDATE employees
SET salary = salary * 1.1
WHERE department = 'Support'
RETURNING emp_id, first_name, salary;

-- 26. Data migration simulation
CREATE TABLE employee_archive (LIKE employees INCLUDING ALL);

INSERT INTO employee_archive
SELECT *
FROM employees
WHERE status = 'Inactive';

DELETE FROM employees
WHERE status = 'Inactive';

SELECT * FROM employee_archive;

-- 27. Complex business logic
UPDATE projects p
SET end_date = end_date + 30
WHERE p.budget > 50000
  AND (SELECT COUNT(*)
       FROM employees e
       JOIN departments d ON d.dept_name = e.department
       WHERE d.dept_id = p.dept_id) > 3;

SELECT * FROM employees;
SELECT * FROM departments;
SELECT * FROM projects;
