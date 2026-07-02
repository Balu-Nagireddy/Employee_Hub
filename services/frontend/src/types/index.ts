export interface Employee {
  id: number;
  employee_code: string;
  name: string;
  email: string;
  department: string;
  designation: string;
  salary: number;
  status: 'active' | 'inactive' | 'terminated';
  created_at: string;
  updated_at: string;
}

export interface EmployeeCreate {
  employee_code: string;
  name: string;
  email: string;
  department: string;
  designation: string;
  salary: number;
  status?: 'active' | 'inactive' | 'terminated';
}

export interface EmployeeUpdate {
  name?: string;
  email?: string;
  department?: string;
  designation?: string;
  salary?: number;
  status?: 'active' | 'inactive' | 'terminated';
}

export interface EmployeeListResponse {
  total: number;
  items: Employee[];
}

export interface HealthStatus {
  status: string;
  service: string;
  version: string;
  environment: string;
  timestamp: string;
}

export interface ReadinessStatus {
  status: string;
  database: string;
  timestamp: string;
}
