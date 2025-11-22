from utils import ActionHandler, get_custom_logger, handle_exceptions_class, Config
from locators import XPath, CssSelector, Common
import allure

logger = get_custom_logger(__name__)


@handle_exceptions_class
class RegistrationPage(ActionHandler):
    name = CssSelector.input_by_id('name')
    select_country = CssSelector.select_by_id('country')
    account_type = CssSelector.select_by_id('account')
    email = CssSelector.input_by_id('email')
    password = Common.password()
    confirm_password = CssSelector.input_by_id('confirm_password')
    sign_up_button = Common.submit()
    registration_successful_message = XPath.header_normalize('Registration Successful')

    def navigate_to_tab(self):
        logger.info(f'Navigating to Registration page')
        self.click_by_text("Registration")
        self.assert_text("Sign Up")
        logger.info(f'Navigated to Registration page successfully')

    @allure.step('Successful Registration')
    def successful_registration(self, name, email, country, account_type, password):
        self.type(self.name, name)
        self.page.select_option(self.select_country, country)
        self.page.select_option(self.account_type, account_type)
        self.type(self.email, email)
        self.type(self.password, password)
        self.type(self.confirm_password, password)
        self.click(self.sign_up_button)
        self.assert_element(self.registration_successful_message)
