from datetime import datetime, timedelta

from sessions import Session


def test_valid_session() -> None:
    session = Session()
    assert session.validate_session(session.generate_session()) is True


def test_invalid_session() -> None:
    session = Session()
    session_str = session.generate_session() + "invalid"
    assert session.validate_session(session_str) is False


def test_expired_session() -> None:
    session = Session()
    start_time = datetime.now() - timedelta(hours=3)
    session_str = session.generate_session(start_time=start_time)
    assert session.validate_session(session_str) is False
