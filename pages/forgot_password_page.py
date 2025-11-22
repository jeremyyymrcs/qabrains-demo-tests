from utils import ActionHandler, get_custom_logger, handle_exceptions_class, Config
from locators import XPath, CssSelector, Common
import allure
logger = get_custom_logger(__name__)


@handle_exceptions_class
class ForgotPasswordPage(ActionHandler):
    email = Common.email()
    reset_password_button = Common.submit()
    check_email_message = XPath.header_normalize('Check Email')
    user_authentication_label = XPath.header_normalize('User Authentication')

    def navigate_to_tab(self):
        logger.info(f'Navigating to forgot password page')
        self.click_by_text("Forgot Password")
        self.assert_element(self.user_authentication_label)
        logger.info(f'Navigated to forgot password page successfully')

    @allure.step('Successful Reset Password')
    def successful_reset_password(self, email):
        logger.info(f"Starting to Reset Password for: {email}")
        self.type(self.email, email)
        self.click(self.reset_password_button)
        self.assert_element(self.check_email_message)
        logger.info(f"Successfully Reset Password for: {email}")



