from test_data import CreateFakeData
from tests import BaseTest
import allure
import pytest
from utils import Config


@allure.feature("Registration Feature")
@allure.suite("Registration Test Suite")
class TestRegistration(BaseTest):
    fake_data = CreateFakeData()

    @allure.title("Successful Registration with valid data")
    @allure.story("User can register with valid credentials")
    @allure.severity(allure.severity_level.CRITICAL)
    @allure.description("""
        This test verifies that a user can successfully register
        with valid details including name, email, country, account type, 
        and password. The test will fail if registration is unsuccessful 
        or the registration page behavior changes.
    """)
    @pytest.mark.positive
    @pytest.mark.skip_auto_login
    def test_successful_registration(self):
        self.registration_page.navigate_to_tab()
        self.registration_page.successful_registration(
            name=self.fake_data.first_name,
            email=self.fake_data.random_email,
            country="Philippines",
            account_type=self.fake_data.account_type,
            password=Config.PASSWORD
        )







