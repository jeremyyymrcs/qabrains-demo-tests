import re
from playwright.sync_api import Page, expect

from pages.form_submission_page import FormSubmissionPage
from pages.login_page import LoginPage
from pages.registration_page import RegistrationPage
from pages.forgot_password_page import ForgotPasswordPage

from utils import ActionHandler, get_custom_logger, handle_exceptions, Config


logger = get_custom_logger(__name__)


class BasePage:

    def __init__(self, page: Page):
        self.page = page
        self.current_window = page
        self.action_handler = ActionHandler(self.page)

    @handle_exceptions
    def open_page(self):
        """Navigate to the login page and perform validation checks."""
        logger.info("Navigating to the login page.")
        self.page.goto(Config.QA_BRAINS_URL, timeout=120000)
        expect(self.page).to_have_title(re.compile("QA Practice Site"))
        logger.info("Successfully reached the login page.")

    def open_page_in_new_window(self):
        """Open the login page in a new browser window and return a new BasePage instance for it."""
        run_mode = Config.HEADLESS.lower() == "true"
        new_context = self.page.context.browser.new_context(
            viewport={
                "width": Config.HEADLESS_SCREEN_WIDTH,
                "height": Config.HEADLESS_SCREEN_HEIGHT
            }
            if run_mode else None,
            no_viewport=not run_mode
        )
        new_page = new_context.new_page()
        new_page.goto(Config.QA_BRAINS_URL, timeout=120000)
        expect(self.page).to_have_title(re.compile("QA Practice Site"))
        new_page.bring_to_front()

        logger.info("Opened new isolated window")

        return BasePage(new_page)

    def get_login_page(self):
        return LoginPage(self.page)

    def get_forgot_password_page(self):
        return ForgotPasswordPage(self.page)

    def get_registration_page(self):
        return RegistrationPage(self.page)

    def get_form_submission_page(self):
        return FormSubmissionPage(self.page)

