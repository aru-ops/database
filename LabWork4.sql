-- Part 1: Basic SELECT Queries

-- Task 1.1
-- Select all employees, displaying full name, department, and salary.
SELECT
    CONCAT(first_name, ' ', last_name) AS full_name,
    department,
    salary
FROM employees;

-- Task 1.2
-- Find all unique departments.
SELECT DISTINCT department
FROM employees;

-- Task 1.3
-- Show project name, budget, and budget category.
SELECT
    project_name,
    budget,
    CASE
        WHEN budget > 150000 THEN 'Large'
        WHEN budget BETWEEN 100000 AND 150000 THEN 'Medium'
        ELSE 'Small'
    END AS budget_category
FROM projects;

-- Task 1.4
-- Display employee names and email; replace NULL email with text.
SELECT
    CONCAT(first_name, ' ', last_name) AS full_name,
    COALESCE(email, 'No email provided') AS email
FROM employees;

-- Part 2: WHERE Clause and Comparison Operators

-- Task 2.1
-- Find employees hired after January 1, 2020.
SELECT *
FROM employees
WHERE hire_date > DATE '2020-01-01';

-- Task 2.2
-- Find employees whose salary is between 60000 and 70000.
SELECT *
FROM employees
WHERE salary BETWEEN 60000 AND 70000;

-- Task 2.3
-- Find employees whose last name starts with S or J.
SELECT *
FROM employees
WHERE last_name LIKE 'S%'
   OR last_name LIKE 'J%';

-- Task 2.4
-- Find IT employees who have a manager.
SELECT *
FROM employees
WHERE manager_id IS NOT NULL
  AND department = 'IT';

-- Part 3: String and Mathematical Functions

-- Task 3.1
-- Uppercase name, last-name length, and first 3 email characters.
SELECT
    UPPER(CONCAT(first_name, ' ', last_name)) AS employee_name_upper,
    LENGTH(last_name) AS last_name_length,
    SUBSTRING(email FROM 1 FOR 3) AS email_first_3_chars
FROM employees;

-- Task 3.2
-- Annual salary, monthly salary rounded to 2 decimals, and 10% raise amount.
SELECT
    CONCAT(first_name, ' ', last_name) AS full_name,
    salary AS annual_salary,
    ROUND(salary / 12, 2) AS monthly_salary,
    salary * 0.10 AS raise_amount_10_percent
FROM employees;

-- Task 3.3
-- Create a formatted project description.
SELECT
    format(
        'Project: %s - Budget: $%s - Status: %s',
        project_name,
        budget,
        status
    ) AS project_info
FROM projects;

-- Task 3.4
-- Calculate completed years with the company.
SELECT
    CONCAT(first_name, ' ', last_name) AS full_name,
    EXTRACT(YEAR FROM AGE(CURRENT_DATE, hire_date)) AS years_with_company
FROM employees;

-- Part 4: Aggregate Functions and GROUP BY

-- Task 4.1
-- Average salary for each department.
SELECT
    department,
    ROUND(AVG(salary), 2) AS average_salary
FROM employees
GROUP BY department;

-- Task 4.2
-- Total hours worked on each project, including project name.
SELECT
    p.project_name,
    COALESCE(SUM(a.hours_worked), 0) AS total_hours_worked
FROM projects p
LEFT JOIN assignments a
    ON p.project_id = a.project_id
GROUP BY p.project_id, p.project_name;

-- Task 4.3
-- Count employees in each department; show only departments with > 1 employee.
SELECT
    department,
    COUNT(*) AS employee_count
FROM employees
GROUP BY department
HAVING COUNT(*) > 1;

-- Task 4.4
-- Maximum salary, minimum salary, and total payroll.
SELECT
    MAX(salary) AS maximum_salary,
    MIN(salary) AS minimum_salary,
    SUM(salary) AS total_payroll
FROM employees;

-- Part 5: Set Operations

-- Task 5.1
-- Employees with salary > 65000 UNION employees hired after 2020-01-01.
SELECT
    employee_id,
    CONCAT(first_name, ' ', last_name) AS full_name,
    salary
FROM employees
WHERE salary > 65000

UNION

SELECT
    employee_id,
    CONCAT(first_name, ' ', last_name) AS full_name,
    salary
FROM employees
WHERE hire_date > DATE '2020-01-01';

-- Task 5.2
-- Employees who work in IT INTERSECT employees with salary > 65000.
SELECT
    employee_id,
    CONCAT(first_name, ' ', last_name) AS full_name,
    salary
FROM employees
WHERE department = 'IT'

INTERSECT

SELECT
    employee_id,
    CONCAT(first_name, ' ', last_name) AS full_name,
    salary
FROM employees
WHERE salary > 65000;

-- Task 5.3
-- Employees who are NOT assigned to any project.
SELECT employee_id
FROM employees

EXCEPT

SELECT employee_id
FROM assignments;

-- Part 6: Subqueries

-- Task 6.1
-- Employees who have at least one project assignment.
SELECT
    e.employee_id,
    CONCAT(e.first_name, ' ', e.last_name) AS full_name
FROM employees e
WHERE EXISTS (
    SELECT 1
    FROM assignments a
    WHERE a.employee_id = e.employee_id
);

-- Task 6.2
-- Employees working on projects with status 'Active'.
SELECT
    employee_id,
    CONCAT(first_name, ' ', last_name) AS full_name
FROM employees
WHERE employee_id IN (
    SELECT a.employee_id
    FROM assignments a
    JOIN projects p
        ON p.project_id = a.project_id
    WHERE p.status = 'Active'
);

-- Task 6.3
-- Employees whose salary is greater than ANY Sales employee salary.
SELECT
    employee_id,
    CONCAT(first_name, ' ', last_name) AS full_name,
    salary
FROM employees
WHERE salary > ANY (
    SELECT salary
    FROM employees
    WHERE department = 'Sales'
);

-- Part 7: Complex Queries

-- Task 7.1
-- Employee name, department, average assignment hours, and salary rank in department.
SELECT
    e.employee_id,
    CONCAT(e.first_name, ' ', e.last_name) AS employee_name,
    e.department,
    ROUND(AVG(a.hours_worked), 2) AS average_hours_worked,
    DENSE_RANK() OVER (
        PARTITION BY e.department
        ORDER BY e.salary DESC
    ) AS salary_rank_in_department
FROM employees e
LEFT JOIN assignments a
    ON e.employee_id = a.employee_id
GROUP BY
    e.employee_id,
    e.first_name,
    e.last_name,
    e.department,
    e.salary
ORDER BY e.department, salary_rank_in_department;

-- Task 7.2
-- Projects where total hours worked exceeds 150.
SELECT
    p.project_name,
    SUM(a.hours_worked) AS total_hours,
    COUNT(DISTINCT a.employee_id) AS number_of_employees
FROM projects p
JOIN assignments a
    ON p.project_id = a.project_id
GROUP BY p.project_id, p.project_name
HAVING SUM(a.hours_worked) > 150;

-- Task 7.3
-- Department report: employee count, average salary, highest-paid employee.
-- GREATEST and LEAST are included to satisfy the task requirement.
WITH ranked_employees AS (
    SELECT
        e.*,
        ROW_NUMBER() OVER (
            PARTITION BY department
            ORDER BY salary DESC, employee_id
        ) AS salary_position
    FROM employees e
),
department_stats AS (
    SELECT
        department,
        COUNT(*) AS total_employees,
        ROUND(AVG(salary), 2) AS average_salary,
        GREATEST(MAX(salary), MIN(salary)) AS highest_salary,
        LEAST(MAX(salary), MIN(salary)) AS lowest_salary
    FROM employees
    GROUP BY department
)
SELECT
    ds.department,
    ds.total_employees,
    ds.average_salary,
    CONCAT(re.first_name, ' ', re.last_name) AS highest_paid_employee,
    ds.highest_salary,
    ds.lowest_salary
FROM department_stats ds
JOIN ranked_employees re
    ON re.department = ds.department
   AND re.salary_position = 1
ORDER BY ds.department;
