from Cython.TestUtils import CythonTest
import Cython.Compiler.Errors as Errors
from Cython.Compiler.Nodes import *
from Cython.Compiler.ParseTreeTransforms import *
from Cython.Compiler.Buffer import *


class TestBufferParsing(CythonTest):
    # First, we only test the raw parser, i.e.
    # the number and contents of arguments are NOT checked.
    # However "dtype"/the first positional argument is special-cased
    #  to parse a type argument rather than an expression

    def parse(self, s):
        return self.should_not_fail(lambda: self.fragment(s)).root

    def not_parseable(self, expected_error, s):
        e = self.should_fail(lambda: self.fragment(s),  Errors.CompileError)
        self.assertEqual(expected_error, e.message_only)

    def test_basic(self):
        t = self.parse(u"cdef object[float, 4, ndim=2, foo=foo] x")
        bufnode = t.stats[0].base_type
        self.assert_(isinstance(bufnode, TemplatedTypeNode))
        self.assertEqual(2, len(bufnode.positional_args))
#        print bufnode.dump()
        # should put more here...

    def test_type_pos(self):
        self.parse(u"cdef object[short unsigned int, 3] x")

    def test_type_keyword(self):
        self.parse(u"cdef object[foo=foo, dtype=short unsigned int] x")

    def test_pos_after_key(self):
        self.not_parseable("Non-keyword arg following keyword arg",
                           u"cdef object[foo=1, 2] x")


# See also tests/error/e_bufaccess.pyx and tets/run/bufaccess.pyx
# THESE TESTS ARE NOW DISABLED, the code they test was pretty much
# refactored away
class TestBufferOptions(CythonTest):
    # Tests the full parsing of the options within the brackets

    def nonfatal_error(self, error):
        # We're passing self as context to transform to trap this
        self.error = error
        self.assert_(self.expect_error)

    def parse_opts(self, opts, expect_error=False):
        assert opts != ""
        s = u"def f():\n  cdef object[%s] x" % opts
        self.expect_error = expect_error
        root = self.fragment(s, pipeline=[NormalizeTree(self), PostParse(self)]).root
        if not expect_error:
            vardef = root.stats[0].body.stats[0]
            assert isinstance(vardef, CVarDefNode) # use normal assert as this is to validate the test code
            buftype = vardef.base_type
            self.assert_(isinstance(buftype, TemplatedTypeNode))
            self.assert_(isinstance(buftype.base_type_node, CSimpleBaseTypeNode))
            self.assertEqual(u"object", buftype.base_type_node.name)
            return buftype
        else:
            self.assert_(len(root.stats[0].body.stats) == 0)

    def non_parse(self, expected_err, opts):
        self.parse_opts(opts, expect_error=True)
#        e = self.should_fail(lambda: self.parse_opts(opts))
        self.assertEqual(expected_err, self.error.message_only)

    def __test_basic(self):
        buf = self.parse_opts(u"unsigned short int, 3")
        self.assert_(isinstance(buf.dtype_node, CSimpleBaseTypeNode))
        self.assert_(buf.dtype_node.signed == 0 and buf.dtype_node.longness == -1)
        self.assertEqual(3, buf.ndim)

    def __test_dict(self):
        buf = self.parse_opts(u"ndim=3, dtype=unsigned short int")
        self.assert_(isinstance(buf.dtype_node, CSimpleBaseTypeNode))
        self.assert_(buf.dtype_node.signed == 0 and buf.dtype_node.longness == -1)
        self.assertEqual(3, buf.ndim)

    def __test_ndim(self):
        self.parse_opts(u"int, 2")
        self.non_parse(ERR_BUF_NDIM, u"int, 'a'")
        self.non_parse(ERR_BUF_NDIM, u"int, -34")

    def __test_use_DEF(self):
        t = self.fragment(u"""
        DEF ndim = 3
        def f():
            cdef object[int, ndim] x
            cdef object[ndim=ndim, dtype=int] y
        """, pipeline=[NormalizeTree(self), PostParse(self)]).root
        stats = t.stats[0].body.stats
        self.assert_(stats[0].base_type.ndim == 3)
        self.assert_(stats[1].base_type.ndim == 3)

    # add exotic and impossible combinations as they come along...

if __name__ == '__main__':
    import unittest
    unittest.main()

