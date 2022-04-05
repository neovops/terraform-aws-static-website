from hashlib import blake2b
from datetime import datetime, timedelta


class Session:
    _session_duration: timedelta
    _sign_secret: bytes = b"${SIGN_SECRET}"  # will be replaced by terraform tpl

    def __init__(self, session_duration_minutes: int = 30):
        self._session_duration = timedelta(minutes=session_duration_minutes)

    def generate_session(self, start_time: datetime = datetime.now()) -> str:
        timestamp_str = str(int((start_time + self._session_duration).timestamp()))
        return f"{timestamp_str}:{self._sign(str(timestamp_str))}"

    def validate_session(self, session: str) -> bool:
        timestamp_str, sig = session.split(":")
        return not (self._is_expired(timestamp_str)) and sig == self._sign(
            timestamp_str
        )

    def _sign(self, data: str) -> str:
        h = blake2b(digest_size=32, key=self._sign_secret)
        h.update(data.encode("utf8"))
        return h.hexdigest()

    @staticmethod
    def _is_expired(session: str) -> bool:
        return datetime.now().timestamp() > float(session)
