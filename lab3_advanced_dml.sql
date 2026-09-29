-- Laboratory Work #3 - DML Operations

-- PART A: Database and Table Setup
-- 1. Create database
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

INSERT INTO employees (emp_id, first_name, last_name, department)
VALUES (101, 'Aigerim', 'Sadykova', 'IT'),
       (102, 'Daniyar', 'Omarov', 'Sales');

SELECT setval(pg_get_serial_sequence('employees', 'emp_id'),
              (SELECT MAX(emp_id) FROM employees));

INSERT INTO employees (first_name, last_name, department, salary, status)
VALUES ('Nurlan', 'Bekov', 'HR', DEFAULT, DEFAULT);

INSERT INTO departments (dept_name, budget, manager_id)
VALUES ('IT',    150000, 101),
       ('Sales', 120000, 102),
       ('HR',     80000, NULL);

INSERT INTO employees (first_name, last_name, department, salary, hire_date)
VALUES ('Aliya', 'Nurpeisova', 'IT', 50000 * 1.1, CURRENT_DATE);

CREATE TEMPORARY TABLE temp_employees (LIKE employees);
 
INSERT INTO temp_employees
SELECT *
FROM employees
WHERE department = 'IT';
 
SELECT * FROM temp_employees;

-- SAMPLE DATA #1:

INSERT INTO employees (first_name, last_name, department, salary, hire_date, status)
VALUES ('Marat',    'Zhaksybekov', 'IT',    95000, '2018-03-15', 'Active'),
       ('Saltanat', 'Ibragimova',  'Sales', 72000, '2019-07-01', 'Active'),
       ('Timur',    'Kassymov',    'Sales', 48000, '2021-09-10', 'Active'),
       ('Madina',   'Abenova',     'HR',    65000, '2017-11-20', 'Active'),
       ('Ruslan',   'Tulegenov',   'IT',    55000, '2020-02-01', 'Inactive'),
       ('Zhanar',   'Ospanova',    'Sales', 40000, '2022-05-05', 'Terminated'),
       ('Erlan',    'Dosov',       'HR',    30000, '2019-12-12', 'Terminated');\

-- PART C: Complex UPDATE Operations

UPDATE employees
SET salary = salary * 1.1;

UPDATE employees
SET status = 'Senior'
WHERE salary > 60000
  AND hire_date < '2020-01-01';

UPDATE employees
SET department = CASE
                     WHEN salary > 80000              THEN 'Management'
                     WHEN salary BETWEEN 50000 AND 80000 THEN 'Senior'
                     ELSE 'Junior'
                 END;

-- SAMPLE DATA #2:

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

UPDATE employees
SET department = DEFAULT
WHERE status = 'Inactive';

UPDATE departments d
SET budget = (SELECT ROUND(AVG(e.salary) * 1.2)
              FROM employees e
              WHERE e.department = d.dept_name)
WHERE EXISTS (SELECT 1
              FROM employees e
              WHERE e.department = d.dept_name);

UPDATE employees
SET salary = salary * 1.15,
    status = 'Promoted'
WHERE department = 'Sales';

-- PART D: Advanced DELETE Operations

DELETE FROM employees
WHERE status = 'Terminated';

DELETE FROM employees
WHERE salary < 40000
  AND hire_date > '2023-01-01'
  AND department IS NULL;

DELETE FROM departments
WHERE dept_name NOT IN (SELECT DISTINCT department
                        FROM employees
                        WHERE department IS NOT NULL);
 
DELETE FROM projects
WHERE end_date < '2023-01-01'
RETURNING *;

-- PART E: Operations with NULL Values

INSERT INTO employees (first_name, last_name, department, salary, hire_date)
VALUES ('Test', 'NullUser', NULL, NULL, '2024-01-15');

UPDATE employees
SET department = 'Unassigned'
WHERE department IS NULL;

DELETE FROM employees
WHERE salary IS NULL
   OR department IS NULL;

-- PART F: RETURNING Clause Operations

INSERT INTO employees (first_name, last_name, department, salary, hire_date)
VALUES ('Sultan', 'Mukhamedov', 'IT', 62000, CURRENT_DATE)
RETURNING emp_id, first_name || ' ' || last_name AS full_name;
 
UPDATE employees e
SET salary = e.salary + 5000
FROM (SELECT emp_id, salary AS old_salary
      FROM employees
      WHERE department = 'IT') AS old_data
WHERE e.emp_id = old_data.emp_id
RETURNING e.emp_id, old_data.old_salary, e.salary AS new_salary;

DELETE FROM employees
WHERE hire_date < '2020-01-01'
RETURNING *;
 
-- SAMPLE DATA #3:

INSERT INTO employees (first_name, last_name, department, salary, hire_date, status)
VALUES ('Alikhan', 'Baimukhanov', 'IT', 66000, '2021-10-01', 'Active'),
       ('Aruzhan', 'Kenzhebek',   'IT', 59000, '2022-02-14', 'Active'),
       ('Bekzat',  'Sadvakasov',  'IT', 64000, '2023-01-09', 'Active'),
       ('Laura',   'Yesenova',    'HR', 47000, '2021-07-07', 'Inactive'),
       ('Anuar',   'Tokhtarov',   'Sales', 51000, '2022-11-11', 'Inactive');

UPDATE departments SET budget = 150000 WHERE dept_name = 'IT';

-- PART G: Advanced DML Patterns

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

UPDATE employees e
SET salary = salary * CASE
                          WHEN (SELECT d.budget
                                FROM departments d
                                WHERE d.dept_name = e.department) > 100000
                              THEN 1.10
                          ELSE 1.05
                      END;

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

CREATE TABLE employee_archive (LIKE employees INCLUDING ALL);

INSERT INTO employee_archive
SELECT *
FROM employees
WHERE status = 'Inactive';
 
DELETE FROM employees
WHERE status = 'Inactive';
 
SELECT * FROM employee_archive;

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