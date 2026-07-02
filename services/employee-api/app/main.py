import structlog
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import PlainTextResponse
from app.config import settings
from app.database import engine, Base
from app.api.routes.employees import router as employees_router
from app.api.routes.health import router as health_router
from app.middleware.logging_middleware import LoggingMiddleware
from app.monitoring.metrics import get_metrics

logger = structlog.get_logger()


def create_app() -> FastAPI:
    app = FastAPI(
        title=settings.APP_NAME,
        version=settings.APP_VERSION,
        docs_url="/docs",
        redoc_url="/redoc",
        openapi_url="/openapi.json",
    )

    # Middleware
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.CORS_ORIGINS.split(","),
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )
    app.add_middleware(LoggingMiddleware)

    # Routes
    app.include_router(employees_router)
    app.include_router(health_router)

    # Metrics endpoint
    @app.get("/metrics", include_in_schema=False)
    async def metrics():
        return PlainTextResponse(get_metrics(), media_type="text/plain")

    # Events
    @app.on_event("startup")
    async def startup():
        logger.info("application_started", environment=settings.APP_ENV, version=settings.APP_VERSION)

    @app.on_event("shutdown")
    async def shutdown():
        logger.info("application_shutdown")

    return app


app = create_app()
