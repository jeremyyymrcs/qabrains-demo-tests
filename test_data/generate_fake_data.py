import random

from faker import Faker

fake = Faker()


class CreateFakeData:
    ACCOUNT_TYPES = ["Engineer", "Private Job", "Student", "Government Job"]

    def __init__(self, locale: str = "en_US"):
        self.fake = Faker(locale)
        self.first_name = self.fake.first_name()
        self.country = self.fake.country()
        self.contact_number = self.fake.bothify(text='###########')
        self.random_email = f"{self.first_name}@{fake.free_email_domain()}"
        self.account_type = random.choice(self.ACCOUNT_TYPES)

    def to_dict(self):
        return self.__dict__
