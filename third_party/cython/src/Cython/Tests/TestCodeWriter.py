from Cython.TestUtils import CythonTest

class TestCodeWriter(CythonTest):
    # CythonTest uses the CodeWriter heavily, so do some checking by
    # roundtripping Cython code through the test framework.

    # Note that this test is dependant upon the normal Cython parser
    # to generate the input trees to the CodeWriter. This save *a lot*
    # of time; better to spend that time writing other tests than perfecting
    # this one...

    # Whitespace is very significant in this process:
    #  - always newline on new block (!)
    #  - indent 4 spaces
    #  - 1 space around every operator

    def t(self, codestr):
        self.assertCode(codestr, self.fragment(codestr).root)

    def test_print(self):
        self.t(u"""
                    print x, y
                    print x + y ** 2
                    print x, y, z,
               """)

    def test_if(self):
        self.t(u"if x:\n    pass")

    def test_ifelifelse(self):
        self.t(u"""
                    if x:
                        pass
                    elif y:
                        pass
                    elif z + 34 ** 34 - 2:
                        pass
                    else:
                        pass
                """)

    def test_def(self):
        self.t(u"""
                    def f(x, y, z):
                        pass
                    def f(x = 34, y = 54, z):
                        pass
               """)

    def test_longness_and_signedness(self):
        self.t(u"def f(unsigned long long long long long int y):\n    pass")

    def test_signed_short(self):
        self.t(u"def f(signed short int y):\n    pass")

    def test_typed_args(self):
        self.t(u"def f(int x, unsigned long int y):\n    pass")

    def test_cdef_var(self):
        self.t(u"""
                    cdef int hello
                    cdef int hello = 4, x = 3, y, z
                """)

    def test_for_loop(self):
        self.t(u"""
                    for x, y, z in f(g(h(34) * 2) + 23):
                        print x, y, z
                    else:
                        print 43
                """)

    def test_inplace_assignment(self):
        self.t(u"x += 43")

    def test_attribute(self):
        self.t(u"a.x")

if __name__ == "__main__":
    import unittest
    unittest.main()

