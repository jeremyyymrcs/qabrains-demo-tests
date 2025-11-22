from tests import BaseTest
import allure
import pytest
from utils import Config


@allure.feature("Login Feature")
@allure.suite("Login Test Suite")
class TestLogin(BaseTest):

    @allure.title("Login Test with valid credentials")
    @allure.story("User can log in with valid credentials")
    @allure.severity(allure.severity_level.CRITICAL)
    @allure.description("""
        This test verifies that a user can successfully log in
        with valid username and password. The test will fail if
        login is unsuccessful or the login page behavior changes.
    """)
    @pytest.mark.positive
    def test_successful_login(self):
        """
        This is Automatic Login from BaseTest
        Test to verify successful login
        """

    @allure.title("Login Test with Invalid Password")
    @allure.story("User cannot log in with invalid password")
    @allure.severity(allure.severity_level.NORMAL)
    @allure.description("""
        This test verifies that a user cannot log in with an invalid password.
        The test expects the login page to show an error message and prevent access.
    """)
    @pytest.mark.negative
    @pytest.mark.skip_auto_login
    def test_invalid_password_login(self):
        """Test to verify login fails with invalid password"""
        self.login_page.enter_credentials(Config.EMAIL, "WrongPassword123")
        self.login_page.verify_invalid_password_message()




