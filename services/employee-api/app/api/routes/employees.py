from fastapi import APIRouter, Depends, Query
from typing import Optional
from app.schemas.employee import EmployeeCreate, EmployeeUpdate, EmployeeResponse, EmployeeListResponse
from app.services.employee import EmployeeService
from app.api.dependencies import get_employee_service

router = APIRouter(prefix="/employees", tags=["Employees"])


@router.get("", response_model=EmployeeListResponse)
def list_employees(
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=500),
    department: Optional[str] = Query(None),
    status: Optional[str] = Query(None),
    service: EmployeeService = Depends(get_employee_service),
):
    employees, total = service.list_employees(skip, limit, department, status)
    return EmployeeListResponse(total=total, items=employees)


@router.get("/{employee_id}", response_model=EmployeeResponse)
def get_employee(
    employee_id: int,
    service: EmployeeService = Depends(get_employee_service),
):
    return service.get_employee(employee_id)


@router.post("", response_model=EmployeeResponse, status_code=201)
def create_employee(
    data: EmployeeCreate,
    service: EmployeeService = Depends(get_employee_service),
):
    return service.create_employee(data)


@router.put("/{employee_id}", response_model=EmployeeResponse)
def update_employee(
    employee_id: int,
    data: EmployeeUpdate,
    service: EmployeeService = Depends(get_employee_service),
):
    return service.update_employee(employee_id, data)


@router.delete("/{employee_id}", status_code=204)
def delete_employee(
    employee_id: int,
    service: EmployeeService = Depends(get_employee_service),
):
    service.delete_employee(employee_id)
