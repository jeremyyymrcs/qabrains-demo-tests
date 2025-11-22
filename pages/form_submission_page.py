from utils import ActionHandler, get_custom_logger, handle_exceptions_class, Config
from locators import XPath, CssSelector, Common
import allure

logger = get_custom_logger(__name__)


@handle_exceptions_class
class FormSubmissionPage(ActionHandler):
    name = CssSelector.input_by_id('name')
    email = CssSelector.input_by_id('email')
    contact_number = CssSelector.input_by_id('contact')
    date = CssSelector.input_by_id('date')
    upload = CssSelector.input_by_id('file')
    red = "//label[@for='Red']"
    pasta = "//label[@for='Pasta']"
    select_country = CssSelector.select_by_id('country')
    submit_button = Common.submit()
    successfully_submitted_message = XPath.header_normalize('successfully submitted')

    def navigate_to_tab(self):
        logger.info(f'Navigating to Form Submission page')
        self.click_by_text("Form Submission")
        self.assert_element(self.name)
        logger.info(f'Navigated to Form Submission page successfully')

    @allure.step('Successful Submission of Form')
    def successful_form_submission(self, name, email, contact_number, date, upload_file, country):
        logger.info('Starting to Submit Form')
        self.type(self.name, name)
        self.type(self.email, email)
        self.type(self.contact_number, contact_number)
        self.type(self.date, date)
        self.upload_file(self.upload, upload_file)
        self.click(self.red)
        self.click(self.pasta)
        self.page.select_option(self.select_country, country)
        self.click(self.submit_button)
        self.assert_element(self.successfully_submitted_message)
        logger.info('Form successfully submitted')
