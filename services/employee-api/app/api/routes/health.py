import structlog
from datetime import datetime
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from sqlalchemy import text
from app.database import get_db, engine
from app.config import settings

logger = structlog.get_logger()
router = APIRouter(tags=["Health"])


@router.get("/health")
def health():
    logger.info("health_check", status="ok")
    return {
        "status": "healthy",
        "service": settings.APP_NAME,
        "version": settings.APP_VERSION,
        "environment": settings.APP_ENV,
        "timestamp": datetime.utcnow().isoformat(),
    }


@router.get("/ready")
def readiness(db: Session = Depends(get_db)):
    try:
        db.execute(text("SELECT 1"))
        db_status = "connected"
    except Exception as e:
        db_status = "disconnected"
        logger.error("readiness_db_failed", error=str(e))
    status = "ready" if db_status == "connected" else "not_ready"
    logger.info("readiness_check", status=status, database=db_status)
    return {
        "status": status,
        "database": db_status,
        "timestamp": datetime.utcnow().isoformat(),
    }


@router.get("/live")
def liveness():
    return {
        "status": "alive",
        "timestamp": datetime.utcnow().isoformat(),
    }
