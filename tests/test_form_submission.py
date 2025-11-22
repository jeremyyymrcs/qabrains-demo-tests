from test_data import CreateFakeData, get_test_image_path
from tests import BaseTest
import allure
import pytest


@allure.feature("Form Submission Feature")
@allure.suite("Form Submission Test Suite")
class TestFormSubmission(BaseTest):
    fake_data = CreateFakeData()

    @allure.title("Successful Form Submission with Valid Data")
    @allure.story("User can submit the form with valid details")
    @allure.severity(allure.severity_level.CRITICAL)
    @allure.description("""
        This test verifies that a user can successfully submit the form
        with valid details including name, email, contact number, date, 
        file upload, and country. The test will fail if form submission 
        is unsuccessful or validation errors occur.
    """)
    @pytest.mark.positive
    @pytest.mark.skip_auto_login
    def test_successful_form_submission(self):
        image_path = get_test_image_path()
        self.form_submission_page.navigate_to_tab()
        self.form_submission_page.successful_form_submission(
            name=self.fake_data.first_name,
            email=self.fake_data.random_email,
            contact_number=self.fake_data.contact_number,
            date="2025-11-22",
            upload_file=image_path,
            country="Argentina",
        )
