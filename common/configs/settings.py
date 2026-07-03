"""
Shared configuration constants for Employee Hub.
These values should be overridden via environment variables in production.
"""

# API Configuration
API_VERSION = "v1"
API_PREFIX = "/api"

# Pagination
DEFAULT_PAGE_SIZE = 100
MAX_PAGE_SIZE = 500

# Employee Statuses
EMPLOYEE_STATUSES = ["active", "inactive", "terminated"]

# Departments
DEPARTMENTS = [
    "Engineering",
    "Marketing",
    "Finance",
    "Human Resources",
    "Sales",
    "Design",
    "Operations",
    "Legal",
]

# Database
DB_POOL_SIZE = 10
DB_MAX_OVERFLOW = 20
DB_POOL_TIMEOUT = 30

# Monitoring
METRICS_PORT = 8090
HEALTH_CHECK_INTERVAL = 30
