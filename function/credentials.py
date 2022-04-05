from abc import ABC, abstractmethod
import json

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
