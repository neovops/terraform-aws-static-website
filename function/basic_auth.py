from base64 import b64decode
from typing import Any, Dict

from credentials import CredentialsValidator, AWSSecretCredentialsValidator
from sessions import Session

COOKIE_NAME = "CFAUTH"


class BasicAuthHandler:

    _credentials_validator: CredentialsValidator
    _session: Session

    def __init__(self, credentials_validator: CredentialsValidator) -> None:
        self._credentials_validator = credentials_validator
        self._session = Session()

    @staticmethod
    def _parse_cookies(event: Dict[str, Any]) -> Dict[str, str]:
        try:
            cookies = event["Records"][0]["cf"]["request"]["headers"]["cookie"][0][
                "value"
            ]
            return {
                cookie.split("=")[0].strip(): cookie.split("=")[1].strip()
                for cookie in cookies.split(";")
            }
        except (KeyError, IndexError):
            return {}

    def handle(self, event: Dict[str, Any]) -> Dict[str, Any]:
        if self._have_valid_cookie(event):
            return event["Records"][0]["cf"]["request"]
        if self._have_valid_authorization_header(event):
            return self._get_set_header_response(
                self._session.generate_session(),
                event["Records"][0]["cf"]["request"]["uri"],
            )
        return self._get_unauthorized_response()

    def _have_valid_cookie(self, event: Dict[str, Any]) -> bool:
        cookies = self._parse_cookies(event)
        return COOKIE_NAME in cookies and self._session.validate_session(
            cookies[COOKIE_NAME]
        )

    def _have_valid_authorization_header(self, event: Dict[str, Any]) -> bool:
        try:
            authorization = event["Records"][0]["cf"]["request"]["headers"][
                "authorization"
            ][0]["value"]
            authorization_encoded = authorization.split(" ")[1]
            user, password = (
                b64decode(authorization_encoded).decode("utf8").split(":", 1)
            )
        except (KeyError, IndexError):
            return False

        return self._credentials_validator.validate(user, password)

    @staticmethod
    def _get_set_header_response(session: str, uri: str) -> Dict[str, Any]:
        return {
            "status": "302",
            "statusDescription": "Found",
            "headers": {
                "location": [
                    {
                        "key": "Location",
                        "value": uri,
                    }
                ],
                "set-cookie": [
                    {
                        "key": "Set-Cookie",
                        "value": f"{COOKIE_NAME}={session}",
                    }
                ],
            },
        }

    @staticmethod
    def _get_unauthorized_response() -> Dict[str, Any]:
        return {
            "status": "401",
            "statusDescription": "Unauthorized",
            "headers": {
                "www-authenticate": [
                    {
                        "key": "WWW-Authenticate",
                        "value": 'Basic realm="Basic Auth", charset="UTF-8"',
                    }
                ]
            },
        }


def handler(event: Dict[str, Any], context: Dict[str, Any]) -> Dict[str, Any]:
    basic_auth_handler = BasicAuthHandler(AWSSecretCredentialsValidator())
    return basic_auth_handler.handle(event)
