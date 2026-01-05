import os
import time

import allure
import pytest
from playwright.sync_api import sync_playwright, TimeoutError

from utils import Config
from utils import get_custom_logger

logger = get_custom_logger(__name__)

@pytest.hookimpl(tryfirst=True, hookwrapper=True)
def pytest_runtest_makereport(item):
   """
   Automatically take screenshots on test failure.
   Captures main page and any new windows opened.
   """
   outcome = yield
   rep = outcome.get_result()

   if rep.when == "call":
       screenshots_dir = os.path.join('..', 'reports', 'screenshots')
       os.makedirs(screenshots_dir, exist_ok=True)
       timestamp = time.strftime("%Y%m%d_%H%M%S")

       status = "failed" if rep.failed else "passed"

       base_test = getattr(item, "instance", None)
       if not base_test:
           return

       # Prepare list of (name, page) tuples
       pages_to_capture = []

       # Main base page
       base_page = getattr(base_test, "base_page", None)
       if getattr(base_page, "page", None):
           pages_to_capture.append(("base_page", base_page.page))

       # Extra pages opened in new windows
       for idx, (page_candidate, *_) in enumerate(getattr(base_test, "_extra_pages", [])):
           page_obj = getattr(page_candidate, "page", page_candidate)
           pages_to_capture.append((f"new_window_{idx + 1}", page_obj))

       for name, page in pages_to_capture:
           try:
               # Wait for page to stabilize
               try:
                   page.wait_for_load_state("networkidle", timeout=3000)
               except TimeoutError:
                   pass

               file_name = f"screenshot_{item.name}_{name}_{status}_{timestamp}.png"
               screenshot_path = os.path.join(screenshots_dir, file_name)
               page.screenshot(full_page=True, path=screenshot_path)

               # Attach to Allure
               with open(screenshot_path, "rb") as f:
                   allure.attach(
                       f.read(),
                       name=file_name,
                       attachment_type=allure.attachment_type.PNG
                   )
           except Exception as e:
               logger.info(f"[WARNING] Failed to capture screenshot for {name}: {e}")


@pytest.fixture(scope="session")
def playwright_instance():
   with sync_playwright() as p:
       yield p


@pytest.fixture(scope="session")
def browser(playwright_instance, request):
   headless = Config.HEADLESS.lower() == "true"
   browser_args = ["--start-maximized"] if not headless else []
   browser = playwright_instance.chromium.launch(
       headless=headless,
       args=browser_args,
       channel="chrome" if not headless else None
   )
   yield browser
   browser.close()


@pytest.fixture(scope="function")
def context(browser):
   headless = Config.HEADLESS.lower() == "true"
   context = browser.new_context(
       viewport={
           "width": int(Config.HEADLESS_SCREEN_WIDTH),
           "height": int(Config.HEADLESS_SCREEN_HEIGHT)
       } if headless else None,
       no_viewport=not headless
   )
   yield context
   context.close()


@pytest.fixture(scope="function")
def page(context, request):
   page = context.new_page()
   yield page
   page.close()
