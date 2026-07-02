import time
import uuid
import structlog
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request

from app.monitoring.metrics import http_requests_total, http_errors_total, http_request_duration_seconds


class LoggingMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        request_id = str(uuid.uuid4())
        request.state.request_id = request_id
        start_time = time.time()

        response = await call_next(request)

        latency = time.time() - start_time
        logger = structlog.get_logger()

        # Record metrics
        http_requests_total.labels(
            method=request.method,
            path=request.url.path,
            status=response.status_code,
        ).inc()

        http_request_duration_seconds.labels(
            method=request.method,
            path=request.url.path,
        ).observe(latency)

        if response.status_code >= 400:
            http_errors_total.labels(
                method=request.method,
                path=request.url.path,
                status=response.status_code,
            ).inc()

        logger.info(
            "gateway_request",
            request_id=request_id,
            method=request.method,
            path=request.url.path,
            status=response.status_code,
            latency=round(latency, 4),
            client_ip=request.client.host if request.client else "unknown",
            user_agent=request.headers.get("user-agent", "unknown"),
            response_time=round(latency * 1000, 2),
        )

        response.headers["X-Request-ID"] = request_id
        return response
