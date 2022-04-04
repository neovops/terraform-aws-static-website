from abc import ABC, abstractmethod
from base64 import b64decode
import json
from typing import Any, Dict

import boto3
from botocore.exceptions import ClientError


class CredentialsValidator(ABC):
    @abstractmethod
    def validate(self, user: str, password: str) -> bool:
        ...


class StaticCredentialsValidator(CredentialsValidator):

    _user: str
    _password: str

    def __init__(self, user: str, password: str) -> None:
        self._user = user
        self._password = password

    def validate(self, user: str, password: str) -> bool:
        return user == self._user and password == self._password


class AWSSecretCredentialsValidator(CredentialsValidator):

    _secret_name: str = "${SECRET_NAME}"  # will be replaced by terraform tpl

    def __init__(self) -> None:
        session = boto3.session.Session()
        self._client = session.client(
            service_name="secretsmanager",
            region_name="us-east-1",
        )

    def validate(self, user: str, password: str) -> bool:
        try:
            credentials = json.loads(
                self._client.get_secret_value(SecretId=self._secret_name)[
                    "SecretString"
                ]
            )
        except ClientError:
            return False
        return bool(credentials["user"] == user and credentials["password"] == password)


class BasicAuthHandler:

    _credentials_validator: CredentialsValidator

    def __init__(self, credentials_validator: CredentialsValidator) -> None:
        self._credentials_validator = credentials_validator

    def handle(self, event: Dict[str, Any]) -> Dict[str, Any]:
        try:
            authorization = event["Records"][0]["cf"]["request"]["headers"][
                "authorization"
            ][0]["value"]
            authorization_encoded = authorization.split(" ")[1]
            user, password = (
                b64decode(authorization_encoded).decode("utf8").split(":", 1)
            )
        except (KeyError, IndexError):
            return self._get_unauthorized_response()

        if self._credentials_validator.validate(user, password):
            return event["Records"][0]["cf"]["request"]
        else:
            return self._get_unauthorized_response()

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
