from utils import ActionHandler, get_custom_logger, handle_exceptions_class, Config
from locators import XPath, Common
import allure

logger = get_custom_logger(__name__)


@handle_exceptions_class
class LoginPage(ActionHandler):
    email = Common.email()
    password = Common.password()
    login_button = Common.submit()
    login_successful_message = XPath.header_normalize('Login Successful')
    password_is_invalid = XPath.span_normalize_space('Your password is invalid!')

    @allure.step('Enter Credentials')
    def enter_credentials(self, email, password):
        logger.info("Starting to Login as user")
        self.type(self.email, email)
        self.type(self.password, password)
        self.click(self.login_button)

    @allure.step('Login Successful')
    def successful_login(self, email, password):
        self.enter_credentials(email, password)
        self.verify_login_success_message()

    @allure.step('Verify Login Successful Message')
    def verify_login_success_message(self):
        self.assert_element(self.login_successful_message)
        logger.info('Login has been successful')

    @allure.step('Verify Invalid Password Message')
    def verify_invalid_password_message(self):
        self.assert_element(self.password_is_invalid)
        logger.info('Password is invalid as expected')
