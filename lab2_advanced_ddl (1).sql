-- ============================================================
-- Laboratory Work #2: Advanced DDL Operations
-- Database Creation, Table Management & Data Types
-- ============================================================
-- NOTE: CREATE DATABASE / DROP DATABASE cannot run inside a
-- transaction block. Run this script with psql (e.g.
-- psql -U postgres -f lab2_advanced_ddl.sql) so each statement
-- executes on its own. The \c commands switch the active
-- connection to the relevant database, which is required before
-- creating tables inside it.
-- ============================================================


-- ============================================================
-- PART 1: MULTIPLE DATABASE MANAGEMENT
-- ============================================================

-- ---------- Task 1.1: Database Creation with Parameters ----------

-- 1. university_main: owner = current user, template0, UTF8 encoding
CREATE DATABASE university_main
    OWNER = CURRENT_USER
    TEMPLATE = template0
    ENCODING = 'UTF8';

-- 2. university_archive: connection limit 50, template0
CREATE DATABASE university_archive
    TEMPLATE = template0
    CONNECTION LIMIT = 50;

-- 3. university_test: marked as template database, connection limit 10
CREATE DATABASE university_test
    IS_TEMPLATE = true
    CONNECTION LIMIT = 10;


-- ---------- Task 1.2: Tablespace Operations ----------

-- 1. student_data tablespace
CREATE TABLESPACE student_data LOCATION '/data/students';

-- 2. course_data tablespace, owner = current user
CREATE TABLESPACE course_data
    OWNER CURRENT_USER
    LOCATION '/data/courses';

-- 3. university_distributed database using student_data tablespace, LATIN9 encoding
--    (template0 required because default template1 is usually locked to a
--    different encoding/locale)
CREATE DATABASE university_distributed
    TABLESPACE = student_data
    TEMPLATE = template0
    ENCODING = 'LATIN9';


-- ============================================================
-- PART 2: COMPLEX TABLE CREATION
-- ============================================================

-- Switch connection into university_main to create the tables there
\c university_main

-- ---------- Task 2.1: University Management System ----------

CREATE TABLE students (
    student_id       SERIAL PRIMARY KEY,
    first_name       VARCHAR(50),
    last_name        VARCHAR(50),
    email            VARCHAR(100),
    phone            CHAR(15),
    date_of_birth    DATE,
    enrollment_date  DATE,
    gpa              NUMERIC(3,2),
    is_active        BOOLEAN,
    graduation_year  SMALLINT
);

CREATE TABLE professors (
    professor_id      SERIAL PRIMARY KEY,
    first_name        VARCHAR(50),
    last_name         VARCHAR(50),
    email             VARCHAR(100),
    office_number     VARCHAR(20),
    hire_date         DATE,
    salary            NUMERIC(12,2),
    is_tenured        BOOLEAN,
    years_experience  INTEGER
);

CREATE TABLE courses (
    course_id        SERIAL PRIMARY KEY,
    course_code      CHAR(8),
    course_title     VARCHAR(100),
    description      TEXT,
    credits          SMALLINT,
    max_enrollment   INTEGER,
    course_fee       NUMERIC(8,2),
    is_online        BOOLEAN,
    created_at       TIMESTAMP
);


-- ---------- Task 2.2: Time-based and Specialized Tables ----------

CREATE TABLE class_schedule (
    schedule_id    SERIAL PRIMARY KEY,
    course_id      INTEGER,
    professor_id   INTEGER,
    classroom      VARCHAR(20),
    class_date     DATE,
    start_time     TIME,
    end_time       TIME,
    duration       INTERVAL
);

CREATE TABLE student_records (
    record_id               SERIAL PRIMARY KEY,
    student_id               INTEGER,
    course_id                INTEGER,
    semester                 VARCHAR(20),
    year                      INTEGER,
    grade                     CHAR(2),
    attendance_percentage    NUMERIC(4,1),
    submission_timestamp     TIMESTAMPTZ,
    last_updated             TIMESTAMPTZ
);


-- ============================================================
-- PART 3: ADVANCED ALTER TABLE OPERATIONS
-- ============================================================

-- ---------- Task 3.1: Modifying Existing Tables ----------

-- students table
ALTER TABLE students ADD COLUMN middle_name VARCHAR(30);
ALTER TABLE students ADD COLUMN student_status VARCHAR(20);
ALTER TABLE students ALTER COLUMN phone TYPE VARCHAR(20);
ALTER TABLE students ALTER COLUMN student_status SET DEFAULT 'ACTIVE';
ALTER TABLE students ALTER COLUMN gpa SET DEFAULT 0.00;

-- professors table
ALTER TABLE professors ADD COLUMN department_code CHAR(5);
ALTER TABLE professors ADD COLUMN research_area TEXT;
ALTER TABLE professors ALTER COLUMN years_experience TYPE SMALLINT;
ALTER TABLE professors ALTER COLUMN is_tenured SET DEFAULT false;
ALTER TABLE professors ADD COLUMN last_promotion_date DATE;

-- courses table
ALTER TABLE courses ADD COLUMN prerequisite_course_id INTEGER;
ALTER TABLE courses ADD COLUMN difficulty_level SMALLINT;
ALTER TABLE courses ALTER COLUMN course_code TYPE VARCHAR(10);
ALTER TABLE courses ALTER COLUMN credits SET DEFAULT 3;
ALTER TABLE courses ADD COLUMN lab_required BOOLEAN DEFAULT false;


-- ---------- Task 3.2: Column Management Operations ----------

-- class_schedule table
ALTER TABLE class_schedule ADD COLUMN room_capacity INTEGER;
ALTER TABLE class_schedule DROP COLUMN duration;
ALTER TABLE class_schedule ADD COLUMN session_type VARCHAR(15);
ALTER TABLE class_schedule ALTER COLUMN classroom TYPE VARCHAR(30);
ALTER TABLE class_schedule ADD COLUMN equipment_needed TEXT;

-- student_records table
ALTER TABLE student_records ADD COLUMN extra_credit_points NUMERIC(3,1);
ALTER TABLE student_records ALTER COLUMN grade TYPE VARCHAR(5);
ALTER TABLE student_records ALTER COLUMN extra_credit_points SET DEFAULT 0.0;
ALTER TABLE student_records ADD COLUMN final_exam_date DATE;
ALTER TABLE student_records DROP COLUMN last_updated;


-- ============================================================
-- PART 4: TABLE RELATIONSHIPS AND MANAGEMENT
-- ============================================================

-- ---------- Task 4.1: Additional Supporting Tables ----------

CREATE TABLE departments (
    department_id      SERIAL PRIMARY KEY,
    department_name    VARCHAR(100),
    department_code    CHAR(5),
    building            VARCHAR(50),
    phone               VARCHAR(15),
    budget              NUMERIC(14,2),
    established_year    INTEGER
);

CREATE TABLE library_books (
    book_id                 SERIAL PRIMARY KEY,
    isbn                    CHAR(13),
    title                   VARCHAR(200),
    author                  VARCHAR(100),
    publisher               VARCHAR(100),
    publication_date        DATE,
    price                   NUMERIC(8,2),
    is_available            BOOLEAN,
    acquisition_timestamp   TIMESTAMP
);

CREATE TABLE student_book_loans (
    loan_id        SERIAL PRIMARY KEY,
    student_id      INTEGER,
    book_id         INTEGER,
    loan_date       DATE,
    due_date        DATE,
    return_date     DATE,
    fine_amount     NUMERIC(6,2),
    loan_status     VARCHAR(20)
);


-- ---------- Task 4.2: Table Modifications for Integration ----------

-- 1. Add foreign-key-style columns (no constraints yet, just columns)
ALTER TABLE professors ADD COLUMN department_id INTEGER;
ALTER TABLE students ADD COLUMN advisor_id INTEGER;
ALTER TABLE courses ADD COLUMN department_id INTEGER;

-- 2. Lookup tables
CREATE TABLE grade_scale (
    grade_id         SERIAL PRIMARY KEY,
    letter_grade     CHAR(2),
    min_percentage   NUMERIC(4,1),
    max_percentage   NUMERIC(4,1),
    gpa_points       NUMERIC(3,2)
);

CREATE TABLE semester_calendar (
    semester_id             SERIAL PRIMARY KEY,
    semester_name           VARCHAR(20),
    academic_year           INTEGER,
    start_date              DATE,
    end_date                DATE,
    registration_deadline   TIMESTAMPTZ,
    is_current               BOOLEAN
);


-- ============================================================
-- PART 5: TABLE DELETION AND CLEANUP
-- ============================================================

-- ---------- Task 5.1: Conditional Table Operations ----------

-- 1. Drop tables if they exist
DROP TABLE IF EXISTS student_book_loans;
DROP TABLE IF EXISTS library_books;
DROP TABLE IF EXISTS grade_scale;

-- 2. Recreate grade_scale with an additional "description" column
CREATE TABLE grade_scale (
    grade_id         SERIAL PRIMARY KEY,
    letter_grade     CHAR(2),
    min_percentage   NUMERIC(4,1),
    max_percentage   NUMERIC(4,1),
    gpa_points       NUMERIC(3,2),
    description      TEXT
);

-- 3. Drop and recreate semester_calendar with CASCADE
DROP TABLE IF EXISTS semester_calendar CASCADE;

CREATE TABLE semester_calendar (
    semester_id             SERIAL PRIMARY KEY,
    semester_name           VARCHAR(20),
    academic_year           INTEGER,
    start_date              DATE,
    end_date                DATE,
    registration_deadline   TIMESTAMPTZ,
    is_current               BOOLEAN
);


-- ---------- Task 5.2: Database Cleanup ----------

-- Switch back to a maintenance database before dropping others,
-- since you cannot DROP DATABASE while connected to it.
\c postgres

-- 1. Drop test/distributed databases if they exist
DROP DATABASE IF EXISTS university_test;
DROP DATABASE IF EXISTS university_distributed;

-- 2. Create a backup database using university_main as template
--    NOTE: this requires no other active connections to university_main
--    at the moment this command runs.
CREATE DATABASE university_backup TEMPLATE university_main;

-- ============================================================
-- END OF SCRIPT
-- ============================================================
