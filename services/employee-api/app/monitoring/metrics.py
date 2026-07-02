from prometheus_client import Counter, Histogram, Gauge, generate_latest, REGISTRY
import psutil
import os

# HTTP Metrics
http_requests_total = Counter("http_requests_total", "Total HTTP requests", ["method", "path", "status"])

http_request_duration_seconds = Histogram(
    "http_request_duration_seconds",
    "HTTP request duration in seconds",
    ["method", "path"],
    buckets=(0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1.0, 2.5, 5.0),
)

http_errors_total = Counter("http_errors_total", "Total HTTP errors", ["method", "path", "status"])

# Database Metrics
db_query_duration_seconds = Histogram(
    "db_query_duration_seconds",
    "Database query duration in seconds",
    ["query_type"],
    buckets=(0.001, 0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1.0),
)

db_queries_total = Counter("db_queries_total", "Total database queries", ["query_type"])

# Python Runtime Metrics
python_memory_bytes = Gauge("python_memory_bytes", "Python process memory usage in bytes", ["type"])

python_cpu_seconds_total = Gauge("python_cpu_seconds_total", "Python process CPU time in seconds")

python_gc_objects = Gauge("python_gc_objects", "Python garbage collector tracked objects")

# Business Metrics
employees_total = Gauge("employees_total", "Total number of employees")

active_employees = Gauge("active_employees", "Number of active employees")


def update_runtime_metrics():
    process = psutil.Process(os.getpid())
    memory_info = process.memory_info()
    python_memory_bytes.labels(type="rss").set(memory_info.rss)
    python_memory_bytes.labels(type="vms").set(memory_info.vms)
    cpu_times = process.cpu_times()
    python_cpu_seconds_total.set(cpu_times.user + cpu_times.system)


def get_metrics():
    update_runtime_metrics()
    return generate_latest(REGISTRY)
