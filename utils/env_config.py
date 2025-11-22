from dotenv import load_dotenv
import os


class Config:
    load_dotenv()  # This will load variables from the .env file into the environment

    # Access environment variables
    HEADLESS_SCREEN_WIDTH = os.getenv("HEADLESS_SCREEN_WIDTH")
    HEADLESS_SCREEN_HEIGHT = os.getenv("HEADLESS_SCREEN_HEIGHT")
    HEADLESS = os.getenv("HEADLESS")
    QA_BRAINS_URL = os.getenv("QA_BRAINS_URL")
    EMAIL = os.getenv("EMAIL")
    PASSWORD = os.getenv("PASSWORD")



