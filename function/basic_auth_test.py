from base64 import b64encode
from copy import deepcopy

from basic_auth import BasicAuthHandler, COOKIE_NAME
from credentials import StaticCredentialsValidator
from sessions import Session


TEST_USER = "test_user"
TEST_PASSWORD = "test_password"

base_event = {
    "Records": [
        {
            "cf": {
                "config": {
                    "distributionDomainName": "d111111abcdef8.cloudfront.net",
                    "distributionId": "EDFDVBD6EXAMPLE",
                    "eventType": "viewer-request",
                    "requestId": "4TyzHTaYWb1GX1qTfsHhEqV6HUDd_BzoBZnwfnvQc_1oF26ClkoUSEQ==",
                },
                "request": {
                    "clientIp": "203.0.113.178",
                    "headers": {
                        "host": [
                            {"key": "Host", "value": "d111111abcdef8.cloudfront.net"}
                        ],
                        "user-agent": [{"key": "User-Agent", "value": "curl/7.66.0"}],
                        "accept": [{"key": "accept", "value": "*/*"}],
                    },
                    "method": "GET",
                    "querystring": "",
                    "uri": "/",
                },
            }
        }
    ]
}

test_basic_auth_handler = BasicAuthHandler(
    StaticCredentialsValidator(TEST_USER, TEST_PASSWORD)
)


def generate_authorization(user: str, password: str) -> str:
    credentials = b64encode(f"{user}:{password}".encode("utf8")).decode("utf8")
    return f"Basic {credentials}"


def test_no_auth_return_401() -> None:
    response = test_basic_auth_handler.handle(base_event)
    assert response["status"] == "401"
    assert "www-authenticate" in response["headers"]
    assert response["headers"]["www-authenticate"][0]["key"] == "WWW-Authenticate"


def test_invalid_auth_return_401() -> None:
    event = deepcopy(base_event)
    event["Records"][0]["cf"]["request"]["headers"]["authorization"] = [
        {
            "key": "Authorization",
            "value": generate_authorization(TEST_USER, "bad password"),
        }
    ]
    response = test_basic_auth_handler.handle(event)

    assert response["status"] == "401"
    assert "www-authenticate" in response["headers"]
    assert response["headers"]["www-authenticate"][0]["key"] == "WWW-Authenticate"
    assert response["headers"]["www-authenticate"][0]["value"].startswith("Basic")


def test_valid_auth_return_set_valid_cookie() -> None:
    event = deepcopy(base_event)
    event["Records"][0]["cf"]["request"]["headers"]["authorization"] = [
        {
            "key": "Authorization",
            "value": generate_authorization(TEST_USER, TEST_PASSWORD),
        }
    ]
    response = test_basic_auth_handler.handle(event)

    assert response["status"] == "302"
    assert "set-cookie" in response["headers"]
    assert response["headers"]["set-cookie"][0]["key"] == "Set-Cookie"
    session_str = response["headers"]["set-cookie"][0]["value"].split("=")[1].strip()
    assert Session().validate_session(session_str)


def test_valid_cookie_return_original_request() -> None:
    event = deepcopy(base_event)
    session = Session().generate_session()
    event["Records"][0]["cf"]["request"]["headers"]["cookie"] = [
        {
            "key": "Cookie",
            "value": f"{COOKIE_NAME}={session}",
        }
    ]
    response = test_basic_auth_handler.handle(event)

    assert response == event["Records"][0]["cf"]["request"]


def test_parse_cookies() -> None:
    event = deepcopy(base_event)
    event["Records"][0]["cf"]["request"]["headers"]["cookie"] = [
        {
            "key": "Cookie",
            "value": "First=1; Second=2",
        }
    ]
    assert test_basic_auth_handler._parse_cookies(event) == {
        "First": "1",
        "Second": "2",
    }
