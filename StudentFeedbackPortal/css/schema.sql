-- Student Feedback Management Portal - Database Schema

CREATE DATABASE IF NOT EXISTS student_feedback_db;
USE student_feedback_db;

-- Drop in the right order (child tables first) so the script can be re-run
DROP TABLE IF EXISTS feedback_responses;
DROP TABLE IF EXISTS feedback;
DROP TABLE IF EXISTS questions;
DROP TABLE IF EXISTS subjects;
DROP TABLE IF EXISTS faculty;
DROP TABLE IF EXISTS admins;
DROP TABLE IF EXISTS students;

-- ---------- STUDENTS ----------
CREATE TABLE students (
    id INT AUTO_INCREMENT PRIMARY KEY,
    student_id VARCHAR(20) NOT NULL UNIQUE,      -- roll number / register number
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,              -- stores the HASH, never plain text
    department VARCHAR(100) NOT NULL,
    year INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ---------- ADMINS ----------
CREATE TABLE admins (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL
);

-- ---------- FACULTY ----------
CREATE TABLE faculty (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    department VARCHAR(100) NOT NULL,
    designation VARCHAR(100) NOT NULL
);

-- ---------- SUBJECTS ----------
CREATE TABLE subjects (
    id INT AUTO_INCREMENT PRIMARY KEY,
    subject_code VARCHAR(20) NOT NULL UNIQUE,
    subject_name VARCHAR(150) NOT NULL,
    faculty_id INT NOT NULL,
    semester INT NOT NULL,
    FOREIGN KEY (faculty_id) REFERENCES faculty(id) ON DELETE CASCADE
);

-- ---------- QUESTIONS ----------
CREATE TABLE questions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    question_text VARCHAR(255) NOT NULL,
    status VARCHAR(10) NOT NULL DEFAULT 'active'  -- 'active' or 'inactive'
);

-- ---------- FEEDBACK ----------
CREATE TABLE feedback (
    id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT NOT NULL,
    faculty_id INT NOT NULL,
    subject_id INT NOT NULL,
    semester INT NOT NULL,
    academic_year VARCHAR(20) NOT NULL,           -- e.g. 2025-2026
    comment TEXT,
    submitted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE,
    FOREIGN KEY (faculty_id) REFERENCES faculty(id) ON DELETE CASCADE,
    FOREIGN KEY (subject_id) REFERENCES subjects(id) ON DELETE CASCADE,
    -- Prevents duplicate feedback for the same student/faculty/subject/period
    UNIQUE KEY unique_feedback (student_id, faculty_id, subject_id, semester, academic_year)
);

-- ---------- FEEDBACK RESPONSES (one row per question rating) ----------
CREATE TABLE feedback_responses (
    id INT AUTO_INCREMENT PRIMARY KEY,
    feedback_id INT NOT NULL,
    question_id INT NOT NULL,
    rating INT NOT NULL CHECK (rating BETWEEN 1 AND 5),
    FOREIGN KEY (feedback_id) REFERENCES feedback(id) ON DELETE CASCADE,
    FOREIGN KEY (question_id) REFERENCES questions(id) ON DELETE CASCADE
);

-- =====================================================
-- SAMPLE DATA
-- (Admin and students are added by seed_users.py so that
--  their passwords are properly hashed.)
-- =====================================================

INSERT INTO faculty (name, email, department, designation) VALUES
('Dr. R. Kumar',   'kumar@college.edu',   'Computer Science', 'Professor'),
('Ms. S. Priya',   'priya@college.edu',   'Computer Science', 'Assistant Professor'),
('Mr. A. Arun',    'arun@college.edu',    'Computer Science', 'Assistant Professor'),
('Dr. M. Lakshmi', 'lakshmi@college.edu', 'Information Technology', 'Associate Professor');

INSERT INTO subjects (subject_code, subject_name, faculty_id, semester) VALUES
('CS301', 'Python Programming',       1, 3),
('CS302', 'Database Management',      2, 3),
('CS303', 'Web Technologies',         3, 3),
('CS304', 'Data Structures',          1, 3),
('IT305', 'Computer Networks',        4, 3);

INSERT INTO questions (question_text, status) VALUES
('Faculty explains concepts clearly.', 'active'),
('Faculty uses appropriate teaching methods.', 'active'),
('Faculty encourages student participation.', 'active'),
('Faculty provides practical examples.', 'active'),
('Faculty completes the syllabus on time.', 'active'),
('Faculty is punctual and regular.', 'active'),
('Faculty clears students'' doubts.', 'active'),
('Course content is easy to understand.', 'active'),
('Laboratory/practical sessions are useful.', 'active'),
('Overall satisfaction with the faculty.', 'active');

# database.py - MySQL connection (Phase 3)

import mysql.connector
from mysql.connector import Error
import config


def get_connection():
    """Return a MySQL connection, or None if the connection fails."""
    try:
        connection = mysql.connector.connect(
            host=config.DB_HOST,
            user=config.DB_USER,
            password=config.DB_PASSWORD,
            database=config.DB_NAME,
        )
        return connection
    except Error as error:
        print("Database connection error:", error)
        return None

# seed_users.py - run ONCE after importing schema.sql

from werkzeug.security import generate_password_hash
from database import get_connection

connection = get_connection()
if connection is None:
    print("❌ Could not connect to the database. Check config.py")
    raise SystemExit

cursor = connection.cursor()

# ---- Admin: username = admin, password = admin123 ----
cursor.execute(
    "INSERT IGNORE INTO admins (username, password) VALUES (%s, %s)",
    ("admin", generate_password_hash("admin123")),
)

# ---- Sample students: password for all = student123 ----
students = [
    ("CS2023001", "Ravi Kumar",  "ravi@student.edu",  "Computer Science", 2),
    ("CS2023002", "Anitha S",    "anitha@student.edu", "Computer Science", 2),
    ("IT2023003", "Karthik M",   "karthik@student.edu", "Information Technology", 2),
]

for student_id, name, email, department, year in students:
    cursor.execute(
        """INSERT IGNORE INTO students
           (student_id, name, email, password, department, year)
           VALUES (%s, %s, %s, %s, %s, %s)""",
        (student_id, name, email, generate_password_hash("student123"), department, year),
    )

connection.commit()
cursor.close()
connection.close()
print("✅ Sample admin and students added.")
print("   Admin   -> username: admin      | password: admin123")
print("   Student -> ID: CS2023001        | password: student123")