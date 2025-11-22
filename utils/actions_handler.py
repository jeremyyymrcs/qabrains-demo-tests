import os, shutil
import random
import string
import time
from pathlib import Path
import allure
from playwright.sync_api import Page, expect
from utils.custom_logger import get_custom_logger

logger = get_custom_logger(__name__)


class ActionHandler:
    # Define the class-level variable for tracking if the folder is cleared
    FOLDER_CLEARED = False
    ACTION_COUNT = 0
    DEFAULT_ELEMENT_TIME_OUT = 10000

    def __init__(self, page: Page):
        self.page = page
        self.default_window = page  # Store the default (original) page
        self.current_window = page  # Track the current window explicitly
        self.screenshots_dir = os.path.join('..', 'reports', 'screenshots')
        self.allure_dir = os.path.join('..', 'reports', 'allure-results')
        self.clear_screenshot_folder()

    def assert_element(
            self,
            locator: str,
            element_timeout: int = DEFAULT_ELEMENT_TIME_OUT,
            delay: int = None,
            locator_index: int = None
    ):
        """Asserts that an element is visible on the page."""
        try:
            element = self._handle_multiple_element(locator, locator_index)
            expect(element).to_be_visible(timeout=element_timeout)
            self.take_screenshot('assert_element')
            if delay is not None:
                self.page.wait_for_timeout(delay)
            logger.debug(f"Element with locator '{locator}' is visible.")
        except AssertionError:
            self.take_screenshot('failed_assert_element')
            logger.error(f"Element with locator '{locator}' is NOT visible.")
            raise  # Re-raise the exception to ensure the test fails

    def assert_text(self, text: str, element_timeout: int = DEFAULT_ELEMENT_TIME_OUT):
        """Asserts that a specific text is visible on the page."""
        try:
            expect(self.page.get_by_text(text, exact=True)).to_be_visible(timeout=element_timeout)
            self.take_screenshot('assert_text')
            logger.debug(f"Text '{text}' is visible on the page.")
        except AssertionError:
            logger.error(f"{text}' is NOT visible on the page.")
            self.take_screenshot('assert_text_failure')
            raise  # Re-raise the exception to ensure the test fails

    def remove_focus(self, locator: str, locator_index: int = None, element_timeout: int = DEFAULT_ELEMENT_TIME_OUT):
        """
        Removes focus from the currently active element or from a specified element.
        This triggers blur/focusout events in the UI without clicking elsewhere.
        """
        try:
            element = self._handle_multiple_element(locator, locator_index)
            expect(element).to_be_visible(timeout=element_timeout)
            element.evaluate("el => el.blur()")
            logger.debug(f"Blurred element with locator '{locator}'.")
            self.take_screenshot('blur_element')
        except Exception as e:
            self.take_screenshot('failed_blur_element')
            logger.error(f"Failed to blur element. Error: {str(e)}")
            raise

    def clear_screenshot_folder(self):
        """Clears all files in the screenshot folder only once when initializing."""
        if not ActionHandler.FOLDER_CLEARED:
            # Ensure the parent directory exists
            parent_dir = os.path.dirname(self.screenshots_dir)
            if not os.path.exists(parent_dir):
                os.makedirs(parent_dir)  # Create the parent directory if it doesn't exist

            # Ensure the screenshots directory exists
            if not os.path.exists(self.screenshots_dir):
                os.makedirs(self.screenshots_dir)

            try:
                for path in Path(self.allure_dir).glob("**/*"):
                    if path.is_file():
                        path.unlink()
                    elif path.is_dir():
                        shutil.rmtree(path)
            except OSError:
                print(f"Warning occurred while clearing the screenshot folder in allure folder")
                pass

            for screenshot_file_name in os.listdir(self.screenshots_dir):
                file_path = os.path.join(self.screenshots_dir, screenshot_file_name)
                if screenshot_file_name.endswith(".png"):
                    # if os.path.isfile(file_path):
                    try:
                        os.remove(file_path)
                        logger.debug(f"Deleted existing screenshot: {file_path}")
                    except OSError:
                        print(f"Warning occurred while clearing the main screenshot folder")
                        pass

            ActionHandler.FOLDER_CLEARED = True

    def click(self, locator_type: str, element_timeout: int = DEFAULT_ELEMENT_TIME_OUT, locator_index: int = None):
        """Clicks a button by its locator."""
        try:
            button = self._handle_multiple_element(locator_type, locator_index)
            expect(button).to_be_visible(timeout=element_timeout)
            button.click()
            self.take_screenshot('click')
        except Exception as e:
            self.take_screenshot('failed_click')
            logger.error(f"Failed to click with selector '{locator_type}'. Error: {str(e)}")
            raise

    def click_and_open_new_page(
            self,
            locator: str,
            page_class,
            element_timeout: int = DEFAULT_ELEMENT_TIME_OUT,
            locator_index: int = None
    ):
        """Clicks on an element to open a new page and returns the page instance."""
        try:
            with self.page.context.expect_page(timeout=element_timeout) as new_page_info:
                self.click(locator, locator_index)
                self.take_screenshot('click_and_open_new_page')

            # Capture the new page
            new_page = new_page_info.value

            # Wait for the new page to be fully loaded or for a specific element to be visible
            new_page.wait_for_load_state('load')
            logger.info(f"New page opened")
            return page_class(new_page)
        except Exception as e:
            self.take_screenshot('failed_click_and_open_new_page')
            logger.error(f"Failed to click with '{locator}'. Error: {str(e)}")
            raise

    def click_by_text(self, button_text: str, element_timeout: int = DEFAULT_ELEMENT_TIME_OUT):
        """Clicks a button by its text."""
        try:
            button = self.page.get_by_text(button_text)
            expect(button).to_be_visible(timeout=element_timeout)
            self.take_screenshot('click_by_text')
            button.click()
        except Exception as e:
            self.take_screenshot('failed_click_by_text')
            logger.error(f"Failed to click with text '{button_text}'. Error: {str(e)}")
            raise

    def close_a_window(self, index: int):
        """Close a window by its index."""
        pages = self.page.context.pages
        if index < len(pages):
            pages[index].close()
            logger.debug(f"Closed window at index {index}")
        else:
            logger.error(f"No window found at index {index}.")

    def close_newest_window(self):
        """Closes the newest browser window/tab."""
        # Check if there's more than one window and if the current window is not the default one
        if len(self.page.context.pages) > 1 and self.current_window != self.default_window:
            self.current_window.close()
            logger.debug(f"Closed the newest window")
            # Reset to default window after closing the current one
            self.current_window = self.default_window
        else:
            logger.debug("No additional windows to close.")

    def hover_and_click(
            self,
            hover_locator: str,
            click_locator: str,
            element_timeout: int = DEFAULT_ELEMENT_TIME_OUT,
            locator_index: int = None
    ):
        """Hovers over an element using hover_locator and then clicks another element."""
        try:
            self.take_screenshot('hover_and_click')
            hover_element = self._handle_multiple_element(hover_locator, locator_index)
            expect(hover_element).to_be_visible(timeout=element_timeout)
            hover_element.hover()
            logger.debug(f"Hovered over the element with locator: '{hover_locator}'")

            self.click(click_locator, element_timeout, locator_index)
            logger.debug(f"Clicked on the element with locator: '{click_locator}'")

        except Exception as e:
            self.take_screenshot('failed_hover_and_click')
            logger.error(
                f"Failed to hover and click with locators '{hover_locator}' and '{click_locator}'. Error: {str(e)}")
            raise

    def is_text_visible(self, text: str):
        """Checks if the text is visible on the page."""
        try:
            self.take_screenshot('is_text_visible')
            expect(self.page.locator(f"text={text}")).to_be_visible()
        except AssertionError:
            self.take_screenshot('failed_is_text_visible')
            logger.error(f"Text: '{text}' is NOT visible.")
            raise

    def upload_file(
            self,
            file_input_locator: str,
            file_path: str,
            element_timeout: int = DEFAULT_ELEMENT_TIME_OUT,
            locator_index: int = None
    ):
        """Uploads a file using the specified file input locator."""
        try:
            file_input = self._handle_multiple_element(file_input_locator, locator_index)

            if not os.path.exists(file_path):
                raise FileNotFoundError(f"File not found: {file_path}")

            file_input.set_input_files(file_path, timeout=element_timeout)

            self.take_screenshot('upload_file')
            logger.debug(f"Uploaded file '{file_path}' using locator '{file_input_locator}'")

        except Exception as e:
            self.take_screenshot('failed_upload_file')
            logger.error(f"Failed to upload file '{file_path}' using locator '{file_input_locator}'. Error: {str(e)}")
            raise

    def select_dropdown_by_index(
            self,
            dropdown_locator: str,
            options_locator: str,
            index: int,
            element_timeout: int = DEFAULT_ELEMENT_TIME_OUT,
            locator_index: int = None
    ):
        """Selects an option from a dropdown by index."""
        try:
            dropdown = self._handle_multiple_element(dropdown_locator, locator_index)
            expect(dropdown).to_be_visible(timeout=element_timeout)
            dropdown.click()

            options = self.page.locator(options_locator)
            expect(options.nth(index)).to_be_visible(timeout=element_timeout)
            options.nth(index).click()

            self.take_screenshot('select_dropdown_by_index')

        except Exception as e:
            self.take_screenshot('failed_select_dropdown_by_index')
            logger.error(f"Failed to select option at index {index} from dropdown. Error: {str(e)}")
            raise

    def select_dropdown_by_text(
            self,
            dropdown_locator: str,
            option_text: str,
            element_timeout: int = DEFAULT_ELEMENT_TIME_OUT,
            locator_index: int = None
    ):
        """Selects an option from a dropdown by visible text."""
        try:
            dropdown = self._handle_multiple_element(dropdown_locator, locator_index)
            expect(dropdown).to_be_visible(timeout=element_timeout)
            dropdown.click()
            option = self.page.get_by_role("option", name=option_text, exact=True)
            expect(option).to_be_visible(timeout=element_timeout)
            option.click(force=True)
            self.take_screenshot('select_dropdown_by_text')
        except Exception as e:
            self.take_screenshot('failed_select_dropdown_by_text')
            logger.error(f"Failed to select option '{option_text}' from dropdown. Error: {str(e)}")
            raise  # Re-raise the exception to ensure the error is handled properly

    def switch_to_default_window(self):
        """Switches back to the default window."""
        self.default_window.bring_to_front()
        self.page = self.default_window

    def switch_to_window(self, index: int, element_timeout: int = DEFAULT_ELEMENT_TIME_OUT):
        """Switch to a specific window by its index, with better handling for new popups."""
        if len(self.page.context.pages) <= index:
            logger.debug(f"Waiting for a new window to open...")

            self.page.wait_for_event('popup', timeout=element_timeout)

        pages = self.page.context.pages
        logger.debug(f"Currently, there are {len(pages)} open window(s).")

        if len(pages) > index:
            self.page = self.page.context.pages[index]  # Switching to the correct window
            self.current_window = self.page
            self.page.bring_to_front()
            time.sleep(1)
            logger.debug(f"Switched to window at index {index}")
        else:
            logger.error(f"No window found at index {index}. There are only {len(pages)} window(s) open.")

    def take_screenshot(self, action_name: str):
        """Takes a full-page screenshot after an action in a specific order."""
        ActionHandler.ACTION_COUNT += 1  # Increment class-level action_count
        try:
            self.page.wait_for_load_state("load")  # 30 seconds timeout
        except Exception as e:
            print(f"Wait for load state failed for action '{action_name}': {e}. Continuing without waiting.")

        # Add action_count to the filename to maintain order
        pid = os.getpid()
        random_string = ''.join(
            random.choices(string.ascii_lowercase + string.digits, k=8))  # Random 8-character string
        timestamp = time.strftime("%Y%m%d_%H%M%S")

        file_name = f"screenshot_{ActionHandler.ACTION_COUNT}_{action_name}_{timestamp}_{pid}_{random_string}.png"
        screenshot_path = os.path.join(self.screenshots_dir, file_name)

        try:
            self.page.screenshot(full_page=True, path=screenshot_path)
            logger.debug(
                f"Screenshot {ActionHandler.ACTION_COUNT} taken for action '{action_name}' and saved to '{screenshot_path}'")

            # Attach the screenshot to Allure report
            with open(screenshot_path, "rb") as f:
                allure.attach(f.read(), name=file_name, attachment_type=allure.attachment_type.PNG)
            return screenshot_path

        except Exception as e:
            logger.error(f"Failed to take screenshot for action '{action_name}': {e}")
            raise

    def type(
            self,
            selector_value: str,
            value: str,
            element_timeout: int = DEFAULT_ELEMENT_TIME_OUT,
            locator_index: int = None
    ):
        """Fills an input field based on the locator type and its corresponding value."""
        try:
            text_box = self._handle_multiple_element(selector_value, locator_index)
            expect(text_box).to_be_visible(timeout=element_timeout)
            text_box.clear()
            text_box.fill(value)
        except Exception as e:
            self.take_screenshot('failed_type')
            logger.error(
                f"Failed to fill input field with selector '{selector_value}' and value '{value}'. Error: {str(e)}")
            raise

    def _handle_multiple_element(self, locator: str, locator_index: int = None):
        """Returns a locator element, optionally by index."""
        element = self.page.locator(locator)
        return element.nth(locator_index) if locator_index is not None else element
