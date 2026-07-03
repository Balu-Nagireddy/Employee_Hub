#!/usr/bin/env python3
"""
Database seed script for generating sample employee data.
Uses raw SQL via psycopg2 to avoid module import path issues.
Usage: python scripts/seed.py [--host postgres] [--port 5432] [--user employee_user] [--password employee_pass] [--db employee_db] [--count 50]
"""

import argparse
import random
import psycopg2
from psycopg2.extras import execute_values

FIRST_NAMES = [
    "Alice", "Bob", "Carol", "David", "Eva", "Frank", "Grace", "Henry",
    "Iris", "Jack", "Kate", "Liam", "Mia", "Noah", "Olivia", "Paul",
    "Quinn", "Rose", "Sam", "Tina", "Uma", "Victor", "Wendy", "Xander",
    "Yara", "Zack",
]

LAST_NAMES = [
    "Johnson", "Smith", "Williams", "Brown", "Jones", "Garcia", "Miller",
    "Davis", "Rodriguez", "Martinez", "Hernandez", "Lopez", "Gonzalez",
    "Wilson", "Anderson", "Thomas", "Taylor", "Moore", "Jackson", "Martin",
]

DEPARTMENTS = [
    "Engineering", "Marketing", "Finance", "Human Resources",
    "Sales", "Design", "Operations", "Legal",
]

DESIGNATIONS = {
    "Engineering": [
        "Software Engineer", "Senior Engineer", "Staff Engineer",
        "Principal Engineer", "Engineering Manager", "DevOps Engineer",
        "Frontend Developer", "Backend Developer", "Full Stack Developer",
    ],
    "Marketing": [
        "Marketing Manager", "Content Writer", "SEO Specialist",
        "Social Media Manager", "Brand Manager",
    ],
    "Finance": [
        "Financial Analyst", "Accountant", "Finance Manager",
        "Auditor", "Controller",
    ],
    "Human Resources": [
        "HR Coordinator", "HR Manager", "Recruiter",
        "Benefits Administrator", "HR Director",
    ],
    "Sales": [
        "Sales Representative", "Sales Manager", "Account Executive",
        "Business Development Manager",
    ],
    "Design": [
        "UI/UX Designer", "Graphic Designer", "Product Designer",
        "Design Director",
    ],
    "Operations": [
        "Operations Manager", "Supply Chain Analyst", "Logistics Coordinator",
        "Operations Director",
    ],
    "Legal": [
        "Legal Counsel", "Paralegal", "Compliance Officer",
        "Corporate Lawyer",
    ],
}


def generate_employees(count: int = 50) -> list[tuple]:
    employees = []
    used_codes = set()
    used_emails = set()

    for i in range(count):
        first = random.choice(FIRST_NAMES)
        last = random.choice(LAST_NAMES)

        code = f"EMP{str(i + 1).zfill(3)}"
        while code in used_codes:
            code = f"EMP{random.randint(100, 999)}"
        used_codes.add(code)

        email = f"{first.lower()}.{last.lower()}@example.com"
        while email in used_emails:
            suffix = random.randint(1, 99)
            email = f"{first.lower()}.{last.lower()}.{suffix}@example.com"
        used_emails.add(email)

        department = random.choice(DEPARTMENTS)
        designation = random.choice(DESIGNATIONS[department])
        salary = round(random.uniform(45000, 150000), 2)

        status = random.choices(
            ["active", "inactive", "terminated"],
            weights=[0.8, 0.15, 0.05],
        )[0]

        employees.append((code, f"{first} {last}", email, department,
                         designation, salary, status))

    return employees


def seed(host: str, port: int, user: str, password: str, dbname: str, count: int):
    conn = psycopg2.connect(
        host=host, port=port, user=user, password=password, dbname=dbname
    )
    conn.autocommit = False

    try:
        with conn.cursor() as cur:
            cur.execute("SELECT COUNT(*) FROM employees")
            existing = cur.fetchone()[0]
            if existing > 0:
                print(f"Database already has {existing} employees. Skipping seed.")
                return

            employees = generate_employees(count)
            insert_sql = """
                INSERT INTO employees
                    (employee_code, name, email, department, designation, salary, status)
                VALUES %s
                ON CONFLICT (employee_code) DO NOTHING
            """
            execute_values(cur, insert_sql, employees)
            conn.commit()
            print(f"Seeded {len(employees)} employees successfully!")
    except Exception as e:
        conn.rollback()
        print(f"Error seeding database: {e}")
        raise
    finally:
        conn.close()


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Seed employee data")
    parser.add_argument("--host", default="localhost")
    parser.add_argument("--port", type=int, default=5432)
    parser.add_argument("--user", default="employee_user")
    parser.add_argument("--password", default="employee_pass")
    parser.add_argument("--db", default="employee_db")
    parser.add_argument("--count", type=int, default=50)
    args = parser.parse_args()

    seed(args.host, args.port, args.user, args.password, args.db, args.count)
