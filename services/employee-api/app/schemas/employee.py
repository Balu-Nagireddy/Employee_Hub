from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime


class EmployeeBase(BaseModel):
    name: str = Field(..., min_length=1, max_length=100)
    email: str = Field(..., max_length=100)
    department: str = Field(..., min_length=1, max_length=50)
    designation: str = Field(..., min_length=1, max_length=100)
    salary: float = Field(..., gt=0)
    status: str = Field(default="active", pattern="^(active|inactive|terminated)$")


class EmployeeCreate(EmployeeBase):
    employee_code: str = Field(..., min_length=1, max_length=20)


class EmployeeUpdate(BaseModel):
    name: Optional[str] = Field(None, min_length=1, max_length=100)
    email: Optional[str] = Field(None, max_length=100)
    department: Optional[str] = Field(None, min_length=1, max_length=50)
    designation: Optional[str] = Field(None, min_length=1, max_length=100)
    salary: Optional[float] = Field(None, gt=0)
    status: Optional[str] = Field(None, pattern="^(active|inactive|terminated)$")


class EmployeeResponse(EmployeeBase):
    id: int
    employee_code: str
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}


class EmployeeListResponse(BaseModel):
    total: int
    items: list[EmployeeResponse]
