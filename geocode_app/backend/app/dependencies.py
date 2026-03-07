import logging
from typing import Generator
from sqlalchemy.orm import Session
from app.models.database import get_db as _get_db
from app.config import settings

logger = logging.getLogger(__name__)


def get_db() -> Generator[Session, None, None]:
    """Dependency for getting database session"""
    db = _get_db()
    try:
        yield next(db)
    except StopIteration:
        pass
    finally:
        next(db, None)


# For direct access without FastAPI dependency injection
def get_db_direct() -> Session:
    """Direct database session (for non-FastAPI use)"""
    from app.models.database import SessionLocal
    return SessionLocal()
