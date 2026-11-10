-- PART 1: Setup 

CREATE TABLE IF NOT EXISTS employees (
    emp_id   INT PRIMARY KEY,
    emp_name VARCHAR(50),
    dept_id  INT,
    salary   DECIMAL(10, 2)
);

CREATE TABLE IF NOT EXISTS departments (
    dept_id   INT PRIMARY KEY,
    dept_name VARCHAR(50),
    location  VARCHAR(50)
);

CREATE TABLE IF NOT EXISTS projects (
    project_id   INT PRIMARY KEY,
    project_name VARCHAR(50),
    dept_id      INT,
    budget       DECIMAL(10, 2)
);

INSERT INTO employees (emp_id, emp_name, dept_id, salary) VALUES
(1, 'John Smith', 101, 50000),
(2, 'Jane Doe', 102, 60000),
(3, 'Mike Johnson', 101, 55000),
(4, 'Sarah Williams', 103, 65000),
(5, 'Tom Brown', NULL, 45000)
ON CONFLICT DO NOTHING;

INSERT INTO departments (dept_id, dept_name, location) VALUES
(101, 'IT', 'Building A'),
(102, 'HR', 'Building B'),
(103, 'Finance', 'Building C'),
(104, 'Marketing', 'Building D')
ON CONFLICT DO NOTHING;

INSERT INTO projects (project_id, project_name, dept_id, budget) VALUES
(1, 'Website Redesign', 101, 100000),
(2, 'Employee Training', 102, 50000),
(3, 'Budget Analysis', 103, 75000),
(4, 'Cloud Migration', 101, 150000),
(5, 'AI Research', NULL, 200000)
ON CONFLICT DO NOTHING;

-- =====================================================
-- PART 2: Basic Views
-- =====================================================

-- 2.1
CREATE VIEW employee_details AS
SELECT e.emp_name, e.salary, d.dept_name, d.location
FROM employees e
JOIN departments d ON e.dept_id = d.dept_id;

SELECT * FROM employee_details;
-- Answer: 4 rows. Tom Brown does not appear because his dept_id is NULL,
-- and an INNER JOIN keeps only rows that have a match in departments.

-- 2.2
CREATE VIEW dept_statistics AS
SELECT d.dept_name,
       COUNT(e.emp_id)                    AS employee_count,
       COALESCE(ROUND(AVG(e.salary), 2), 0) AS avg_salary,
       COALESCE(MAX(e.salary), 0)         AS max_salary,
       COALESCE(MIN(e.salary), 0)         AS min_salary
FROM departments d
LEFT JOIN employees e ON d.dept_id = e.dept_id
GROUP BY d.dept_id, d.dept_name;

SELECT * FROM dept_statistics ORDER BY employee_count DESC;

-- 2.3
CREATE VIEW project_overview AS
SELECT p.project_name,
       p.budget,
       d.dept_name,
       d.location,
       (SELECT COUNT(*) FROM employees e WHERE e.dept_id = p.dept_id) AS team_size
FROM projects p
LEFT JOIN departments d ON p.dept_id = d.dept_id;

SELECT * FROM project_overview;

-- 2.4
CREATE VIEW high_earners AS
SELECT e.emp_name, e.salary, d.dept_name
FROM employees e
JOIN departments d ON e.dept_id = d.dept_id
WHERE e.salary > 55000;

SELECT * FROM high_earners;
-- Answer: Only employees with salary > 55000 AND a department are shown (INNER JOIN).
-- A high earner with dept_id = NULL will not appear in the view.
-- (Use LEFT JOIN to include them.)

-- =====================================================
-- PART 3: Modifying and Managing Views
-- =====================================================

-- 3.1 (CREATE OR REPLACE VIEW can only add new columns at the end)
CREATE OR REPLACE VIEW employee_details AS
SELECT e.emp_name, e.salary, d.dept_name, d.location,
       CASE
           WHEN e.salary > 60000 THEN 'High'
           WHEN e.salary > 50000 THEN 'Medium'
           ELSE 'Standard'
       END AS salary_grade
FROM employees e
JOIN departments d ON e.dept_id = d.dept_id;

SELECT * FROM employee_details;

-- 3.2
ALTER VIEW high_earners RENAME TO top_performers;
SELECT * FROM top_performers;

-- 3.3
CREATE VIEW temp_view AS
SELECT emp_name, salary FROM employees WHERE salary < 50000;
SELECT * FROM temp_view;
DROP VIEW temp_view;

-- =====================================================
-- PART 4: Updatable Views
-- =====================================================

-- 4.1
CREATE VIEW employee_salaries AS
SELECT emp_id, emp_name, dept_id, salary
FROM employees;

-- 4.2
UPDATE employee_salaries SET salary = 52000 WHERE emp_name = 'John Smith';
SELECT * FROM employees WHERE emp_name = 'John Smith';
-- Answer: Yes, the underlying employees table was updated (a simple view is updatable).

-- 4.3
INSERT INTO employee_salaries (emp_id, emp_name, dept_id, salary)
VALUES (6, 'Alice Johnson', 102, 58000);
SELECT * FROM employees;
-- Answer: Yes, the insert succeeded and the row appears in employees.

-- 4.4
CREATE VIEW it_employees AS
SELECT emp_id, emp_name, dept_id, salary
FROM employees
WHERE dept_id = 101
WITH LOCAL CHECK OPTION;

-- This should fail:
-- INSERT INTO it_employees (emp_id, emp_name, dept_id, salary)
-- VALUES (7, 'Bob Wilson', 103, 60000);
-- Answer: ERROR: new row violates check option for view "it_employees".
-- The row with dept_id = 103 does not satisfy the view's WHERE dept_id = 101.

-- =====================================================
-- PART 5: Materialized Views
-- =====================================================

-- 5.1 (subqueries are used to avoid row duplication from multiple JOINs)
CREATE MATERIALIZED VIEW dept_summary_mv AS
SELECT d.dept_id,
       d.dept_name,
       (SELECT COUNT(*) FROM employees e WHERE e.dept_id = d.dept_id)              AS total_employees,
       (SELECT COALESCE(SUM(e.salary), 0) FROM employees e WHERE e.dept_id = d.dept_id) AS total_salaries,
       (SELECT COUNT(*) FROM projects p WHERE p.dept_id = d.dept_id)               AS total_projects,
       (SELECT COALESCE(SUM(p.budget), 0) FROM projects p WHERE p.dept_id = d.dept_id)  AS total_project_budget
FROM departments d
WITH DATA;

SELECT * FROM dept_summary_mv ORDER BY total_employees DESC;

-- 5.2
INSERT INTO employees (emp_id, emp_name, dept_id, salary)
VALUES (8, 'Charlie Brown', 101, 54000);

SELECT * FROM dept_summary_mv ORDER BY total_employees DESC;  -- BEFORE refresh: IT does not include Charlie
REFRESH MATERIALIZED VIEW dept_summary_mv;
SELECT * FROM dept_summary_mv ORDER BY total_employees DESC;  -- AFTER refresh: IT has +1 employee and +54000 in salaries
-- Answer: A materialized view stores a snapshot of the data; before REFRESH it shows
-- old data, after REFRESH it shows current data.

-- 5.3
CREATE UNIQUE INDEX idx_dept_summary_mv_dept_id ON dept_summary_mv (dept_id);
REFRESH MATERIALIZED VIEW CONCURRENTLY dept_summary_mv;
-- Answer: CONCURRENTLY does not lock out reads while the view is refreshing
-- (SELECT queries keep working). It requires a unique index.

-- 5.4
CREATE MATERIALIZED VIEW project_stats_mv AS
SELECT p.project_name,
       p.budget,
       d.dept_name,
       (SELECT COUNT(*) FROM employees e WHERE e.dept_id = p.dept_id) AS assigned_employees
FROM projects p
LEFT JOIN departments d ON p.dept_id = d.dept_id
WITH NO DATA;

-- SELECT * FROM project_stats_mv;
-- Answer: ERROR: materialized view "project_stats_mv" has not been populated
-- HINT: Use the REFRESH MATERIALIZED VIEW command.
REFRESH MATERIALIZED VIEW project_stats_mv;
SELECT * FROM project_stats_mv;

-- =====================================================
-- PART 6: Database Roles
-- =====================================================

-- 6.1
CREATE ROLE analyst;
CREATE ROLE data_viewer LOGIN PASSWORD 'viewer123';
CREATE USER report_user PASSWORD 'report456';

SELECT rolname FROM pg_roles WHERE rolname NOT LIKE 'pg_%';

-- 6.2
CREATE ROLE db_creator   CREATEDB   LOGIN PASSWORD 'creator789';
CREATE ROLE user_manager CREATEROLE LOGIN PASSWORD 'manager101';
CREATE ROLE admin_user   SUPERUSER  LOGIN PASSWORD 'admin999';

-- 6.3
GRANT SELECT ON employees, departments, projects TO analyst;
GRANT ALL PRIVILEGES ON employee_details TO data_viewer;
GRANT SELECT, INSERT ON employees TO report_user;

-- 6.4
CREATE ROLE hr_team;
CREATE ROLE finance_team;
CREATE ROLE it_team;

CREATE USER hr_user1      PASSWORD 'hr001';
CREATE USER hr_user2      PASSWORD 'hr002';
CREATE USER finance_user1 PASSWORD 'fin001';

GRANT hr_team      TO hr_user1;
GRANT hr_team      TO hr_user2;
GRANT finance_team TO finance_user1;

GRANT SELECT, UPDATE ON employees TO hr_team;
GRANT SELECT ON dept_statistics TO finance_team;

-- 6.5
REVOKE UPDATE ON employees FROM hr_team;
REVOKE hr_team FROM hr_user2;
REVOKE ALL PRIVILEGES ON employee_details FROM data_viewer;

-- 6.6
ALTER ROLE analyst WITH LOGIN PASSWORD 'analyst123';
ALTER ROLE user_manager WITH SUPERUSER;
ALTER ROLE analyst WITH PASSWORD NULL;
ALTER ROLE data_viewer WITH CONNECTION LIMIT 5;

-- =====================================================
-- PART 7: Advanced Role Management
-- =====================================================

-- 7.1
CREATE ROLE read_only;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO read_only;

CREATE ROLE junior_analyst LOGIN PASSWORD 'junior123';
CREATE ROLE senior_analyst LOGIN PASSWORD 'senior123';

GRANT read_only TO junior_analyst;
GRANT read_only TO senior_analyst;

GRANT INSERT, UPDATE ON employees TO senior_analyst;

-- 7.2
CREATE ROLE project_manager LOGIN PASSWORD 'pm123';
ALTER VIEW dept_statistics OWNER TO project_manager;
ALTER TABLE projects OWNER TO project_manager;

SELECT tablename, tableowner
FROM pg_tables
WHERE schemaname = 'public';

-- 7.3
CREATE ROLE temp_owner LOGIN;
CREATE TABLE temp_table (id INT);
ALTER TABLE temp_table OWNER TO temp_owner;

REASSIGN OWNED BY temp_owner TO postgres;
DROP OWNED BY temp_owner;
DROP ROLE temp_owner;

-- 7.4
CREATE VIEW hr_employee_view AS
SELECT * FROM employees WHERE dept_id = 102;
GRANT SELECT ON hr_employee_view TO hr_team;

CREATE VIEW finance_employee_view AS
SELECT emp_id, emp_name, salary FROM employees;
GRANT SELECT ON finance_employee_view TO finance_team;

-- =====================================================
-- PART 8: Practical Scenarios
-- =====================================================

-- 8.1
CREATE VIEW dept_dashboard AS
SELECT d.dept_name,
       d.location,
       emp.employee_count,
       COALESCE(ROUND(emp.avg_salary, 2), 0)  AS avg_salary,
       proj.project_count                      AS active_projects,
       proj.total_budget                       AS total_project_budget,
       ROUND(proj.total_budget / NULLIF(emp.employee_count, 0), 2) AS budget_per_employee
FROM departments d
CROSS JOIN LATERAL (
    SELECT COUNT(*) AS employee_count, AVG(e.salary) AS avg_salary
    FROM employees e WHERE e.dept_id = d.dept_id
) emp
CROSS JOIN LATERAL (
    SELECT COUNT(*) AS project_count, COALESCE(SUM(p.budget), 0) AS total_budget
    FROM projects p WHERE p.dept_id = d.dept_id
) proj;

-- budget_per_employee: NULLIF protects against division by zero (returns NULL);
-- wrap in COALESCE(..., 0) if you need 0 instead

SELECT * FROM dept_dashboard;

-- 8.2
ALTER TABLE projects ADD COLUMN created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP;

CREATE VIEW high_budget_projects AS
SELECT p.project_name,
       p.budget,
       d.dept_name,
       p.created_date,
       CASE
           WHEN p.budget > 150000 THEN 'Critical Review Required'
           WHEN p.budget > 100000 THEN 'Management Approval Needed'
           ELSE 'Standard Process'
       END AS approval_status
FROM projects p
LEFT JOIN departments d ON p.dept_id = d.dept_id
WHERE p.budget > 75000;

SELECT * FROM high_budget_projects;

-- 8.3
-- Level 1
CREATE ROLE viewer_role;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO viewer_role;  -- includes views as well

-- Level 2
CREATE ROLE entry_role;
GRANT viewer_role TO entry_role;
GRANT INSERT ON employees, projects TO entry_role;

-- Level 3
CREATE ROLE analyst_role;
GRANT entry_role TO analyst_role;
GRANT UPDATE ON employees, projects TO analyst_role;

-- Level 4
CREATE ROLE manager_role;
GRANT analyst_role TO manager_role;
GRANT DELETE ON employees, projects TO manager_role;

-- Users
CREATE USER alice   PASSWORD 'alice123';
CREATE USER bob     PASSWORD 'bob123';
CREATE USER charlie PASSWORD 'charlie123';

GRANT viewer_role  TO alice;
GRANT analyst_role TO bob;
GRANT manager_role TO charlie;
