import { useEffect, useState } from 'react';
import { api } from '../api/client';

interface HealthData {
  backend: { status: string; service: string; version: string; environment: string } | null;
  database: { status: string; database: string } | null;
  liveness: { status: string; timestamp: string } | null;
  loading: boolean;
  error: string | null;
  lastChecked: string | null;
}

export default function Health() {
  const [data, setData] = useState<HealthData>({
    backend: null,
    database: null,
    liveness: null,
    loading: true,
    error: null,
    lastChecked: null,
  });

  const checkHealth = async () => {
    try {
      const [health, ready, live] = await Promise.all([
        api.health(),
        api.ready(),
        api.live(),
      ]);
      setData({
        backend: {
          status: health.status,
          service: health.service,
          version: health.version,
          environment: health.environment,
        },
        database: {
          status: ready.status,
          database: ready.database,
        },
        liveness: live,
        loading: false,
        error: null,
        lastChecked: new Date().toLocaleTimeString(),
      });
    } catch (err) {
      setData((prev) => ({
        ...prev,
        loading: false,
        error: err instanceof Error ? err.message : 'Health check failed',
        lastChecked: new Date().toLocaleTimeString(),
      }));
    }
  };

  useEffect(() => {
    checkHealth();
    const interval = setInterval(checkHealth, 10000);
    return () => clearInterval(interval);
  }, []);

  const getStatusDot = (status: string, goodValue: string) => {
    if (status === goodValue) return 'healthy';
    if (status) return 'degraded';
    return 'unhealthy';
  };

  if (data.loading) return <div className="loading">Checking system health...</div>;

  return (
    <div>
      <div className="page-header">
        <h1>System Health</h1>
        <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
          {data.lastChecked && (
            <span style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>
              Last checked: {data.lastChecked}
            </span>
          )}
          <button className="btn btn-secondary" onClick={checkHealth}>
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
              <polyline points="23 4 23 10 17 10" />
              <path d="M20.49 15a9 9 0 1 1-2.12-9.36L23 10" />
            </svg>
            Refresh
          </button>
        </div>
      </div>

      {data.error && <div className="alert alert-error">{data.error}</div>}

      <div className="grid grid-2" style={{ marginBottom: 32 }}>
        {/* Backend Status */}
        <div className="card">
          <div className="card-header">
            <h2>
              <span className={`status-dot ${getStatusDot(data.backend?.status ?? '', 'healthy')}`} style={{ marginRight: 8 }} />
              Backend API
            </h2>
          </div>
          {data.backend ? (
            <table>
              <tbody>
                <tr><td style={{ color: 'var(--text-muted)' }}>Status</td><td style={{ textTransform: 'capitalize' }}>{data.backend.status}</td></tr>
                <tr><td style={{ color: 'var(--text-muted)' }}>Service</td><td>{data.backend.service}</td></tr>
                <tr><td style={{ color: 'var(--text-muted)' }}>Version</td><td>{data.backend.version}</td></tr>
                <tr><td style={{ color: 'var(--text-muted)' }}>Environment</td><td><span className="badge badge-active">{data.backend.environment}</span></td></tr>
              </tbody>
            </table>
          ) : (
            <p style={{ color: 'var(--danger)' }}>Backend unreachable</p>
          )}
        </div>

        {/* Database Status */}
        <div className="card">
          <div className="card-header">
            <h2>
              <span className={`status-dot ${getStatusDot(data.database?.database ?? '', 'connected')}`} style={{ marginRight: 8 }} />
              Database
            </h2>
          </div>
          {data.database ? (
            <table>
              <tbody>
                <tr><td style={{ color: 'var(--text-muted)' }}>Status</td><td style={{ textTransform: 'capitalize' }}>{data.database.status}</td></tr>
                <tr><td style={{ color: 'var(--text-muted)' }}>Connection</td><td style={{ textTransform: 'capitalize' }}>{data.database.database}</td></tr>
                <tr><td style={{ color: 'var(--text-muted)' }}>Type</td><td>PostgreSQL</td></tr>
              </tbody>
            </table>
          ) : (
            <p style={{ color: 'var(--danger)' }}>Database unreachable</p>
          )}
        </div>
      </div>

      {/* Gateway Info */}
      <div className="card" style={{ marginBottom: 32 }}>
        <div className="card-header">
          <h2>
            <span className="status-dot healthy" style={{ marginRight: 8 }} />
            API Gateway
          </h2>
        </div>
        <table>
          <tbody>
            <tr><td style={{ color: 'var(--text-muted)' }}>Gateway</td><td>KrakenD API Gateway</td></tr>
            <tr><td style={{ color: 'var(--text-muted)' }}>Endpoint</td><td style={{ fontFamily: 'monospace' }}>http://localhost:8080</td></tr>
            <tr><td style={{ color: 'var(--text-muted)' }}>Routes</td><td style={{ fontFamily: 'monospace' }}>/api/employees, /api/health, /api/ready, /api/live</td></tr>
          </tbody>
        </table>
      </div>

      {/* Monitoring Stack */}
      <div className="card">
        <div className="card-header">
          <h2>Monitoring Stack</h2>
        </div>
        <div className="grid grid-4" style={{ marginTop: 16 }}>
          <div>
            <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)', marginBottom: 4 }}>Prometheus</div>
            <div style={{ fontFamily: 'monospace', fontSize: '0.8125rem' }}>
              <a href="http://localhost:9090" target="_blank" rel="noopener noreferrer">localhost:9090</a>
            </div>
          </div>
          <div>
            <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)', marginBottom: 4 }}>Grafana</div>
            <div style={{ fontFamily: 'monospace', fontSize: '0.8125rem' }}>
              <a href="http://localhost:3001" target="_blank" rel="noopener noreferrer">localhost:3001</a>
            </div>
          </div>
          <div>
            <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)', marginBottom: 4 }}>Loki</div>
            <div style={{ fontFamily: 'monospace', fontSize: '0.8125rem' }}>localhost:3100</div>
          </div>
          <div>
            <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)', marginBottom: 4 }}>Node Exporter</div>
            <div style={{ fontFamily: 'monospace', fontSize: '0.8125rem' }}>localhost:9100</div>
          </div>
        </div>
      </div>
    </div>
  );
}
