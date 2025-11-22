from tests import BaseTest
import allure
import pytest
from utils import Config


@allure.feature("Password Reset Feature")
@allure.suite("Password Reset Test Suite")
class TestResetPassword(BaseTest):

    @allure.title("Successful Password Reset")
    @allure.story("User can reset their password successfully")
    @allure.severity(allure.severity_level.CRITICAL)
    @allure.description("""
        This test verifies that a user can successfully reset their password
        using a valid email. The test will fail if the password reset process
        does not complete or the confirmation message is not displayed.
    """)
    @pytest.mark.postive
    @pytest.mark.skip_auto_login
    def test_successful_reset_password(self):
        """Test to verify login fails with invalid password"""
        self.forgot_password_page.navigate_to_tab()
        self.forgot_password_page.successful_reset_password(email=Config.EMAIL)