import os

from .generate_fake_data import CreateFakeData

def get_test_image_path(filename="test_image_01.jpg"):
    """Return absolute path to an image in test_data/images/."""
    return os.path.join(
        os.path.abspath(os.path.dirname(__file__)),
        "images",
        filename
    )
