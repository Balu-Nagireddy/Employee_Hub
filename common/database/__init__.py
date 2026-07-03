"""
Database configuration helpers shared across services.

This module provides database connection utilities for use
by the employee-api and any future backend services.
"""

from dataclasses import dataclass


@dataclass
class DatabaseConfig:
    host: str = "postgres"
    port: int = 5432
    user: str = "employee_user"
    password: str = "employee_pass"
    database: str = "employee_db"

    @property
    def connection_string(self) -> str:
        return f"postgresql://{self.user}:{self.password}@{self.host}:{self.port}/{self.database}"

    @property
    def async_connection_string(self) -> str:
        return f"postgresql+asyncpg://{self.user}:{self.password}@{self.host}:{self.port}/{self.database}"
