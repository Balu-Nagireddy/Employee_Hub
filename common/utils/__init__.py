import uuid
import hashlib
from datetime import datetime, timezone


def generate_request_id() -> str:
    return str(uuid.uuid4())


def generate_employee_code(prefix: str = "EMP") -> str:
    random_suffix = uuid.uuid4().hex[:6].upper()
    return f"{prefix}{random_suffix}"


def utc_now() -> datetime:
    return datetime.now(timezone.utc)


def hash_string(value: str) -> str:
    return hashlib.sha256(value.encode()).hexdigest()


def truncate_string(value: str, max_length: int = 100) -> str:
    if len(value) <= max_length:
        return value
    return value[: max_length - 3] + "..."
