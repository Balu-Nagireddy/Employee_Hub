import structlog
from typing import Optional
from fastapi import HTTPException, status
from app.models.employee import Employee
from app.schemas.employee import EmployeeCreate, EmployeeUpdate
from app.repositories.employee import EmployeeRepository

logger = structlog.get_logger()


class EmployeeService:
    def __init__(self, repo: EmployeeRepository):
        self.repo = repo

    def list_employees(
        self, skip: int = 0, limit: int = 100,
        department: Optional[str] = None, status: Optional[str] = None
    ) -> tuple[list[Employee], int]:
        employees = self.repo.get_all(skip, limit, department, status)
        total = self.repo.count(department, status)
        return employees, total

    def get_employee(self, employee_id: int) -> Employee:
        employee = self.repo.get_by_id(employee_id)
        if not employee:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Employee with id {employee_id} not found",
            )
        return employee

    def create_employee(self, data: EmployeeCreate) -> Employee:
        if self.repo.get_by_employee_code(data.employee_code):
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail=f"Employee with code {data.employee_code} already exists",
            )
        if self.repo.get_by_email(data.email):
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail=f"Employee with email {data.email} already exists",
            )
        employee = Employee(**data.model_dump())
        created = self.repo.create(employee)
        logger.info("employee_created", employee_code=created.employee_code, employee_id=created.id)
        return created

    def update_employee(self, employee_id: int, data: EmployeeUpdate) -> Employee:
        employee = self.get_employee(employee_id)
        update_data = data.model_dump(exclude_unset=True)
        if not update_data:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="No fields to update",
            )
        if "email" in update_data and update_data["email"] != employee.email:
            if self.repo.get_by_email(update_data["email"]):
                raise HTTPException(
                    status_code=status.HTTP_409_CONFLICT,
                    detail="Email already in use",
                )
        for field, value in update_data.items():
            setattr(employee, field, value)
        updated = self.repo.update(employee)
        logger.info("employee_updated", employee_code=updated.employee_code, employee_id=updated.id)
        return updated

    def delete_employee(self, employee_id: int) -> None:
        employee = self.get_employee(employee_id)
        self.repo.delete(employee)
        logger.info("employee_deleted", employee_code=employee.employee_code, employee_id=employee.id)
