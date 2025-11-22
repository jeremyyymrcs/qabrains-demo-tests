import pytest
from playwright.sync_api import sync_playwright
from typing import Optional
from pages import BasePage, LoginPage, ForgotPasswordPage, RegistrationPage, FormSubmissionPage

from utils import get_custom_logger, handle_exceptions, Config

logger = get_custom_logger(__name__)


class BaseTest:
    """Base test class to handle common setup and login for test cases."""
    base_page: Optional[BasePage]
    login_page: Optional[LoginPage]
    forgot_password_page: Optional[ForgotPasswordPage]
    registration_page: Optional[RegistrationPage]
    form_submission_page: Optional[FormSubmissionPage]

    @pytest.fixture(autouse=True)
    def setup_and_teardown(self, request):
        """Fixture to set up the page for each test and handle login functionality."""
        print("")
        logger.info(f"\033[94m[STARTING TEST CASE: {request.node.name}]")

        run_mode = Config.HEADLESS.lower() == "true"

        browser_channel = "chrome" if not run_mode else None

        # Start Playwright and launch the browser maximized
        with sync_playwright() as p:
            browser = p.chromium.launch(headless=run_mode, args=["--start-maximized"], channel=browser_channel)
            context = browser.new_context(
                viewport={
                    "width": int(Config.HEADLESS_SCREEN_WIDTH),
                    "height": int(Config.HEADLESS_SCREEN_HEIGHT)
                } if run_mode else None,
                no_viewport=not run_mode
            )

            page = context.new_page()
            self.base_page = BasePage(page)
            self.base_page.open_page()
            self._initialize_pages()
            self._perform_login(request)

            yield
            context.close()
            browser.close()

        logger.info(f"\033[94m[TEST CASE COMPLETED: {request.node.name}]")
        print("")

    def _initialize_page_objects(self, base_page, new_window: bool = False):
        """Helper method to initialize page objects for a given BasePage instance."""
        for app_pages in [
            "login_page",
            "forgot_password_page",
            "registration_page",
            "form_submission_page"
        ]:
            if new_window:
                setattr(base_page, app_pages, getattr(base_page, f"get_{app_pages}")())
                # This is an equivalent to: new_base_page.login_page = new_base_page.get_login_page() etc..
            else:
                setattr(self, app_pages, getattr(base_page, f"get_{app_pages}")())
                # This is an equivalent to: self.login_page = self.base_page.get_login_page() etc..

    @handle_exceptions
    def _initialize_pages(self):
        """Initialize the necessary page objects for the test."""
        self._initialize_page_objects(self.base_page)

    @handle_exceptions
    def initialize_new_page_window(self):
        """Open the login page in a new browser window and return a new BasePage with all sub-pages initialized."""
        new_base_page = self.base_page.open_page_in_new_window()
        self._initialize_page_objects(new_base_page, new_window=True)
        return new_base_page

    @handle_exceptions
    def _perform_login(self, request):
        """Perform login unless explicitly skipped by a test marker."""
        login_not_required = request.node.get_closest_marker("skip_auto_login")

        if login_not_required:
            logger.info("Skipping login as requested by test marker.")
        else:
            logger.info("Performing successful login.")
            self.login_page.successful_login(Config.EMAIL, Config.PASSWORD)
