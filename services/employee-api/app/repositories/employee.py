from sqlalchemy.orm import Session
from sqlalchemy import func
from typing import Optional
from app.models.employee import Employee


class EmployeeRepository:
    def __init__(self, db: Session):
        self.db = db

    def get_all(self, skip: int = 0, limit: int = 100, department: Optional[str] = None, status: Optional[str] = None) -> list[Employee]:
        query = self.db.query(Employee)
        if department:
            query = query.filter(Employee.department == department)
        if status:
            query = query.filter(Employee.status == status)
        return query.offset(skip).limit(limit).all()

    def count(self, department: Optional[str] = None, status: Optional[str] = None) -> int:
        query = self.db.query(func.count(Employee.id))
        if department:
            query = query.filter(Employee.department == department)
        if status:
            query = query.filter(Employee.status == status)
        return query.scalar()

    def get_by_id(self, employee_id: int) -> Optional[Employee]:
        return self.db.query(Employee).filter(Employee.id == employee_id).first()

    def get_by_employee_code(self, code: str) -> Optional[Employee]:
        return self.db.query(Employee).filter(Employee.employee_code == code).first()

    def get_by_email(self, email: str) -> Optional[Employee]:
        return self.db.query(Employee).filter(Employee.email == email).first()

    def create(self, employee: Employee) -> Employee:
        self.db.add(employee)
        self.db.commit()
        self.db.refresh(employee)
        return employee

    def update(self, employee: Employee) -> Employee:
        self.db.commit()
        self.db.refresh(employee)
        return employee

    def delete(self, employee: Employee) -> None:
        self.db.delete(employee)
        self.db.commit()
