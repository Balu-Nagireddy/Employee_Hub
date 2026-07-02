import type { Employee, EmployeeCreate, EmployeeUpdate, EmployeeListResponse, HealthStatus, ReadinessStatus } from '../types';

const API_BASE = '/api';

async function request<T>(path: string, options?: RequestInit): Promise<T> {
  const url = `${API_BASE}${path}`;
  const response = await fetch(url, {
    ...options,
    headers: {
      'Content-Type': 'application/json',
      ...options?.headers,
    },
  });

  if (response.status === 204) {
    return undefined as T;
  }

  const data = await response.json();

  if (!response.ok) {
    throw new Error(data.detail || `HTTP ${response.status}`);
  }

  return data;
}

export const api = {
  // Employees
  listEmployees: (params?: { skip?: number; limit?: number; department?: string; status?: string }) => {
    const searchParams = new URLSearchParams();
    if (params?.skip) searchParams.set('skip', String(params.skip));
    if (params?.limit) searchParams.set('limit', String(params.limit));
    if (params?.department) searchParams.set('department', params.department);
    if (params?.status) searchParams.set('status', params.status);
    const qs = searchParams.toString();
    return request<EmployeeListResponse>(`/employees${qs ? `?${qs}` : ''}`);
  },

  getEmployee: (id: number) => request<Employee>(`/employees/${id}`),

  createEmployee: (data: EmployeeCreate) =>
    request<Employee>('/employees', { method: 'POST', body: JSON.stringify(data) }),

  updateEmployee: (id: number, data: EmployeeUpdate) =>
    request<Employee>(`/employees/${id}`, { method: 'PUT', body: JSON.stringify(data) }),

  deleteEmployee: (id: number) =>
    request<void>(`/employees/${id}`, { method: 'DELETE' }),

  // Health
  health: () => request<HealthStatus>('/health'),
  ready: () => request<ReadinessStatus>('/ready'),
  live: () => request<{ status: string; timestamp: string }>('/live'),
};
