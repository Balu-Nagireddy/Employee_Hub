from enum import Enum


class EmployeeStatus(str, Enum):
    ACTIVE = "active"
    INACTIVE = "inactive"
    TERMINATED = "terminated"


class Environment(str, Enum):
    DEVELOPMENT = "development"
    STAGING = "staging"
    PRODUCTION = "production"


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

DEFAULT_PAGE_SIZE = 100
MAX_PAGE_SIZE = 500
