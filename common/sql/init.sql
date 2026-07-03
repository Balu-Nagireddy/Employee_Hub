CREATE TABLE IF NOT EXISTS employees (
    id SERIAL PRIMARY KEY,
    employee_code VARCHAR(20) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    department VARCHAR(50) NOT NULL,
    designation VARCHAR(100) NOT NULL,
    salary FLOAT NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'active',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_employees_employee_code ON employees(employee_code);
CREATE INDEX IF NOT EXISTS idx_employees_status ON employees(status);
CREATE INDEX IF NOT EXISTS idx_employees_department ON employees(department);

-- Seed Data
INSERT INTO employees (employee_code, name, email, department, designation, salary, status)
VALUES
    ('EMP001', 'Alice Johnson', 'alice.johnson@example.com', 'Engineering', 'Senior Software Engineer', 95000, 'active'),
    ('EMP002', 'Bob Smith', 'bob.smith@example.com', 'Marketing', 'Marketing Manager', 75000, 'active'),
    ('EMP003', 'Carol Williams', 'carol.williams@example.com', 'Finance', 'Financial Analyst', 68000, 'active'),
    ('EMP004', 'David Brown', 'david.brown@example.com', 'Engineering', 'DevOps Engineer', 85000, 'active'),
    ('EMP005', 'Eva Martinez', 'eva.martinez@example.com', 'Human Resources', 'HR Coordinator', 55000, 'active'),
    ('EMP006', 'Frank Lee', 'frank.lee@example.com', 'Engineering', 'Frontend Developer', 78000, 'inactive'),
    ('EMP007', 'Grace Kim', 'grace.kim@example.com', 'Sales', 'Sales Representative', 62000, 'active'),
    ('EMP008', 'Henry Chen', 'henry.chen@example.com', 'Engineering', 'Backend Developer', 82000, 'active'),
    ('EMP009', 'Iris Davis', 'iris.davis@example.com', 'Design', 'UI/UX Designer', 71000, 'active'),
    ('EMP010', 'Jack Wilson', 'jack.wilson@example.com', 'Operations', 'Operations Manager', 88000, 'terminated')
ON CONFLICT (employee_code) DO NOTHING;
