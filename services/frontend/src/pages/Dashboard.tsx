import { useEffect, useState } from 'react';
import { api } from '../api/client';
import type { Employee, HealthStatus, ReadinessStatus } from '../types';

interface DashboardData {
  totalEmployees: number;
  activeEmployees: number;
  health: HealthStatus | null;
  readiness: ReadinessStatus | null;
  latestEmployees: Employee[];
  loading: boolean;
  error: string | null;
}

export default function Dashboard() {
  const [data, setData] = useState<DashboardData>({
    totalEmployees: 0,
    activeEmployees: 0,
    health: null,
    readiness: null,
    latestEmployees: [],
    loading: true,
    error: null,
  });

  useEffect(() => {
    async function load() {
      try {
        const [empList, health, readiness] = await Promise.all([
          api.listEmployees({ limit: 5 }),
          api.health(),
          api.ready(),
        ]);
        setData({
          totalEmployees: empList.total,
          activeEmployees: empList.items.filter((e) => e.status === 'active').length,
          health,
          readiness,
          latestEmployees: empList.items,
          loading: false,
          error: null,
        });
      } catch (err) {
        setData((prev) => ({
          ...prev,
          loading: false,
          error: err instanceof Error ? err.message : 'Failed to load dashboard data',
        }));
      }
    }
    load();
    const interval = setInterval(load, 15000);
    return () => clearInterval(interval);
  }, []);

  if (data.loading) {
    return <div className="loading">Loading dashboard...</div>;
  }

  return (
    <div>
      <div className="page-header">
        <h1>Dashboard</h1>
      </div>

      {data.error && <div className="alert alert-error">{data.error}</div>}

      {/* Stats Cards */}
      <div className="grid grid-4" style={{ marginBottom: 32 }}>
        <div className="card">
          <div className="card-title">Total Employees</div>
          <div className="card-value">{data.totalEmployees}</div>
        </div>
        <div className="card">
          <div className="card-title">Active Employees</div>
          <div className="card-value">{data.activeEmployees}</div>
        </div>
        <div className="card">
          <div className="card-title">Backend Status</div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginTop: 8 }}>
            <span className={`status-dot ${data.health?.status === 'healthy' ? 'healthy' : 'unhealthy'}`} />
            <span style={{ fontSize: '0.875rem' }}>{data.health?.status ?? 'unknown'}</span>
          </div>
        </div>
        <div className="card">
          <div className="card-title">Database Status</div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginTop: 8 }}>
            <span className={`status-dot ${data.readiness?.database === 'connected' ? 'healthy' : 'unhealthy'}`} />
            <span style={{ fontSize: '0.875rem' }}>{data.readiness?.database ?? 'unknown'}</span>
          </div>
        </div>
      </div>

      {/* Service Info */}
      <div className="grid grid-2" style={{ marginBottom: 32 }}>
        <div className="card">
          <div className="card-header">
            <h2>Service Info</h2>
          </div>
          {data.health && (
            <table>
              <tbody>
                <tr><td style={{ color: 'var(--text-muted)' }}>Service</td><td>{data.health.service}</td></tr>
                <tr><td style={{ color: 'var(--text-muted)' }}>Version</td><td>{data.health.version}</td></tr>
                <tr><td style={{ color: 'var(--text-muted)' }}>Environment</td><td><span className="badge badge-active">{data.health.environment}</span></td></tr>
              </tbody>
            </table>
          )}
        </div>
        <div className="card">
          <div className="card-header">
            <h2>Quick Actions</h2>
          </div>
          <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap' }}>
            <a href="/employees" className="btn btn-primary">Manage Employees</a>
            <a href="/health" className="btn btn-secondary">View Health</a>
          </div>
        </div>
      </div>

      {/* Latest Employees */}
      <div className="card">
        <div className="card-header">
          <h2>Latest Employees</h2>
        </div>
        {data.latestEmployees.length > 0 ? (
          <div className="table-container">
            <table>
              <thead>
                <tr>
                  <th>Code</th>
                  <th>Name</th>
                  <th>Department</th>
                  <th>Designation</th>
                  <th>Status</th>
                </tr>
              </thead>
              <tbody>
                {data.latestEmployees.map((emp) => (
                  <tr key={emp.id}>
                    <td style={{ fontFamily: 'monospace' }}>{emp.employee_code}</td>
                    <td>{emp.name}</td>
                    <td>{emp.department}</td>
                    <td>{emp.designation}</td>
                    <td>
                      <span className={`badge badge-${emp.status}`}>{emp.status}</span>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        ) : (
          <p style={{ color: 'var(--text-muted)' }}>No employees yet. Create one from the Employees page.</p>
        )}
      </div>
    </div>
  );
}
