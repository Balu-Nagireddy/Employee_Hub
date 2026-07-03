import { useEffect, useState, useCallback } from 'react';
import { api } from '../api/client';
import type { Employee, EmployeeCreate, EmployeeUpdate } from '../types';

const emptyForm: EmployeeCreate = {
  employee_code: '',
  name: '',
  email: '',
  department: '',
  designation: '',
  salary: 0,
  status: 'active',
};

export default function Employees() {
  const [employees, setEmployees] = useState<Employee[]>([]);
  const [total, setTotal] = useState(0);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [showModal, setShowModal] = useState(false);
  const [editingId, setEditingId] = useState<number | null>(null);
  const [form, setForm] = useState<EmployeeCreate>(emptyForm);
  const [saving, setSaving] = useState(false);
  const [success, setSuccess] = useState<string | null>(null);

  const loadEmployees = useCallback(async () => {
    try {
      const data = await api.listEmployees({ limit: 200 });
      setEmployees(data.items);
      setTotal(data.total);
      setError(null);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load employees');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    loadEmployees();
  }, [loadEmployees]);

  const openCreate = () => {
    setEditingId(null);
    setForm(emptyForm);
    setShowModal(true);
  };

  const openEdit = (emp: Employee) => {
    setEditingId(emp.id);
    setForm({
      employee_code: emp.employee_code,
      name: emp.name,
      email: emp.email,
      department: emp.department,
      designation: emp.designation,
      salary: emp.salary,
      status: emp.status,
    });
    setShowModal(true);
  };

  const handleSave = async () => {
    setSaving(true);
    setError(null);
    try {
      if (editingId) {
        const update: EmployeeUpdate = { ...form };
        await api.updateEmployee(editingId, update);
        setSuccess('Employee updated successfully');
      } else {
        await api.createEmployee(form);
        setSuccess('Employee created successfully');
      }
      setShowModal(false);
      await loadEmployees();
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to save employee');
    } finally {
      setSaving(false);
      setTimeout(() => setSuccess(null), 3000);
    }
  };

  const handleDelete = async (id: number) => {
    if (!window.confirm('Are you sure you want to delete this employee?')) return;
    try {
      await api.deleteEmployee(id);
      setSuccess('Employee deleted successfully');
      await loadEmployees();
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to delete employee');
    }
    setTimeout(() => setSuccess(null), 3000);
  };

  if (loading) return <div className="loading">Loading employees...</div>;

  return (
    <div>
      <div className="page-header">
        <h1>Employees</h1>
        <button className="btn btn-primary" onClick={openCreate}>
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
            <line x1="12" y1="5" x2="12" y2="19" />
            <line x1="5" y1="12" x2="19" y2="12" />
          </svg>
          Add Employee
        </button>
      </div>

      {error && <div className="alert alert-error">{error}</div>}
      {success && <div className="alert alert-success">{success}</div>}

      <div className="card">
        <div className="card-header">
          <h2>All Employees ({total})</h2>
        </div>
        {employees.length > 0 ? (
          <div className="table-container">
            <table>
              <thead>
                <tr>
                  <th>Code</th>
                  <th>Name</th>
                  <th>Email</th>
                  <th>Department</th>
                  <th>Designation</th>
                  <th>Salary</th>
                  <th>Status</th>
                  <th>Actions</th>
                </tr>
              </thead>
              <tbody>
                {employees.map((emp) => (
                  <tr key={emp.id}>
                    <td style={{ fontFamily: 'monospace', fontSize: '0.8125rem' }}>{emp.employee_code}</td>
                    <td style={{ fontWeight: 500 }}>{emp.name}</td>
                    <td style={{ color: 'var(--text-muted)' }}>{emp.email}</td>
                    <td>{emp.department}</td>
                    <td>{emp.designation}</td>
                    <td>${emp.salary.toLocaleString()}</td>
                    <td><span className={`badge badge-${emp.status}`}>{emp.status}</span></td>
                    <td>
                      <div style={{ display: 'flex', gap: 4 }}>
                        <button className="btn btn-secondary btn-sm" onClick={() => openEdit(emp)}>Edit</button>
                        <button className="btn btn-danger btn-sm" onClick={() => handleDelete(emp.id)}>Delete</button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        ) : (
          <p style={{ color: 'var(--text-muted)', textAlign: 'center', padding: 32 }}>
            No employees found. Click "Add Employee" to create one.
          </p>
        )}
      </div>

      {/* Modal */}
      {showModal && (
        <div className="modal-overlay" onClick={() => setShowModal(false)}>
          <div className="modal" onClick={(e) => e.stopPropagation()}>
            <h2>{editingId ? 'Edit Employee' : 'Add Employee'}</h2>
            <div className="form-row">
              <div className="form-group">
                <label>Employee Code</label>
                <input
                  type="text"
                  value={form.employee_code}
                  onChange={(e) => setForm({ ...form, employee_code: e.target.value })}
                  disabled={editingId !== null}
                  placeholder="e.g. EMP001"
                />
              </div>
              <div className="form-group">
                <label>Name</label>
                <input
                  type="text"
                  value={form.name}
                  onChange={(e) => setForm({ ...form, name: e.target.value })}
                  placeholder="John Doe"
                />
              </div>
            </div>
            <div className="form-group">
              <label>Email</label>
              <input
                type="email"
                value={form.email}
                onChange={(e) => setForm({ ...form, email: e.target.value })}
                placeholder="john@example.com"
              />
            </div>
            <div className="form-row">
              <div className="form-group">
                <label>Department</label>
                <input
                  type="text"
                  value={form.department}
                  onChange={(e) => setForm({ ...form, department: e.target.value })}
                  placeholder="Engineering"
                />
              </div>
              <div className="form-group">
                <label>Designation</label>
                <input
                  type="text"
                  value={form.designation}
                  onChange={(e) => setForm({ ...form, designation: e.target.value })}
                  placeholder="Senior Engineer"
                />
              </div>
            </div>
            <div className="form-row">
              <div className="form-group">
                <label>Salary</label>
                <input
                  type="number"
                  value={form.salary || ''}
                  onChange={(e) => setForm({ ...form, salary: parseFloat(e.target.value) || 0 })}
                  placeholder="75000"
                />
              </div>
              <div className="form-group">
                <label>Status</label>
                <select
                  value={form.status}
                  onChange={(e) => setForm({ ...form, status: e.target.value as EmployeeCreate['status'] })}
                >
                  <option value="active">Active</option>
                  <option value="inactive">Inactive</option>
                  <option value="terminated">Terminated</option>
                </select>
              </div>
            </div>
            <div className="modal-actions">
              <button className="btn btn-secondary" onClick={() => setShowModal(false)}>Cancel</button>
              <button className="btn btn-primary" onClick={handleSave} disabled={saving}>
                {saving ? 'Saving...' : editingId ? 'Update' : 'Create'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
