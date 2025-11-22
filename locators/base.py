class CssSelector:
    INPUT_BY_ID = "input[id='{input_id}']"
    BUTTON_BY_TYPE = "button[type='{button_type}']"
    SELECT_BY_ID = "select[id='{input_id}']"

    @staticmethod
    def input_by_id(input_id: str):
        return CssSelector.INPUT_BY_ID.format(input_id=input_id)

    @staticmethod
    def button_by_type(button_type: str):
        return CssSelector.BUTTON_BY_TYPE.format(button_type=button_type)

    @staticmethod
    def select_by_id(input_id: str):
        return CssSelector.SELECT_BY_ID.format(input_id=input_id)


class XPath:
    HEADER_NORMALIZE_SPACE = "//h2[normalize-space()='{text}']"
    SPAN_NORMALIZE_SPACE = " //span[normalize-space()='{text}']"

    @staticmethod
    def header_normalize(text: str):
        return XPath.HEADER_NORMALIZE_SPACE.format(text=text)

    @staticmethod
    def span_normalize_space(text: str):
        return XPath.SPAN_NORMALIZE_SPACE.format(text=text)


class Common:

    @staticmethod
    def password():
        return CssSelector.input_by_id(input_id='password')

    @staticmethod
    def submit():
        return CssSelector.BUTTON_BY_TYPE.format(button_type='submit')

    @staticmethod
    def email():
        return CssSelector.input_by_id('email')
