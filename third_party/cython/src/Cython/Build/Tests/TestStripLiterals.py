from Cython.Build.Dependencies import strip_string_literals

from Cython.TestUtils import CythonTest

class TestStripLiterals(CythonTest):

    def t(self, before, expected):
        actual, literals = strip_string_literals(before, prefix="_L")
        self.assertEquals(expected, actual)
        for key, value in literals.items():
            actual = actual.replace(key, value)
        self.assertEquals(before, actual)

    def test_empty(self):
        self.t("", "")

    def test_single_quote(self):
        self.t("'x'", "'_L1_'")

    def test_double_quote(self):
        self.t('"x"', '"_L1_"')

    def test_nested_quotes(self):
        self.t(""" '"' "'" """, """ '_L1_' "_L2_" """)

    def test_triple_quote(self):
        self.t(" '''a\n''' ", " '''_L1_''' ")

    def test_backslash(self):
        self.t(r"'a\'b'", "'_L1_'")
        self.t(r"'a\\'", "'_L1_'")
        self.t(r"'a\\\'b'", "'_L1_'")

    def test_unicode(self):
        self.t("u'abc'", "u'_L1_'")

    def test_raw(self):
        self.t(r"r'abc\\'", "r'_L1_'")

    def test_raw_unicode(self):
        self.t(r"ru'abc\\'", "ru'_L1_'")

    def test_comment(self):
        self.t("abc # foo", "abc #_L1_")

    def test_comment_and_quote(self):
        self.t("abc # 'x'", "abc #_L1_")
        self.t("'abc#'", "'_L1_'")

    def test_include(self):
        self.t("include 'a.pxi' # something here",
               "include '_L1_' #_L2_")

    def test_extern(self):
        self.t("cdef extern from 'a.h': # comment",
               "cdef extern from '_L1_': #_L2_")

