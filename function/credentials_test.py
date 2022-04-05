from credentials import StaticCredentialsValidator


def test_valid_credentials() -> None:
    validator = StaticCredentialsValidator("user1", "password1")
    assert validator.validate("user1", "password1") is True


def test_invalid_user() -> None:
    validator = StaticCredentialsValidator("user1", "password1")
    assert validator.validate("invalid", "password1") is False


def test_invalid_password() -> None:
    validator = StaticCredentialsValidator("user1", "password1")
    assert validator.validate("user1", "invalid") is False
