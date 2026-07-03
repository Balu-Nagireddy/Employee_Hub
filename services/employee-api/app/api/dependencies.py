from fastapi import Depends
from sqlalchemy.orm import Session
from app.database import get_db
from app.repositories.employee import EmployeeRepository
from app.services.employee import EmployeeService


def get_employee_service(db: Session = Depends(get_db)) -> EmployeeService:
    repo = EmployeeRepository(db)
    return EmployeeService(repo)
