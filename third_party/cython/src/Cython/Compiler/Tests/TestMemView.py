from Cython.TestUtils import CythonTest
import Cython.Compiler.Errors as Errors
from Cython.Compiler.Nodes import *
from Cython.Compiler.ParseTreeTransforms import *
from Cython.Compiler.Buffer import *


class TestMemviewParsing(CythonTest):

    def parse(self, s):
        return self.should_not_fail(lambda: self.fragment(s)).root

    def not_parseable(self, expected_error, s):
        e = self.should_fail(lambda: self.fragment(s),  Errors.CompileError)
        self.assertEqual(expected_error, e.message_only)
    
    def test_default_1dim(self):
        self.parse(u"cdef int[:] x")
        self.parse(u"cdef short int[:] x")

    def test_default_ndim(self):
        self.parse(u"cdef int[:,:,:,:,:] x")
        self.parse(u"cdef unsigned long int[:,:,:,:,:] x")
        self.parse(u"cdef unsigned int[:,:,:,:,:] x")

    def test_zero_offset(self):
        self.parse(u"cdef long double[0:] x")
        self.parse(u"cdef int[0:] x")

    def test_zero_offset_ndim(self):
        self.parse(u"cdef int[0:,0:,0:,0:] x")

    def test_def_arg(self):
        self.parse(u"def foo(int[:,:] x): pass")

    def test_cdef_arg(self):
        self.parse(u"cdef foo(int[:,:] x): pass")

    def test_general_slice(self):
        self.parse(u'cdef float[::ptr, ::direct & contig, 0::full & strided] x')

    def test_non_slice_memview(self):
        self.not_parseable(u"An axis specification in memoryview declaration does not have a ':'.",
                u"cdef double[:foo, bar] x")
        self.not_parseable(u"An axis specification in memoryview declaration does not have a ':'.",
                u"cdef double[0:foo, bar] x")

    def test_basic(self):
        t = self.parse(u"cdef int[:] x")
        memv_node = t.stats[0].base_type
        self.assert_(isinstance(memv_node, MemoryViewSliceTypeNode))

    # we also test other similar declarations (buffers, anonymous C arrays)
    # since the parsing has to distinguish between them.

    def disable_test_no_buf_arg(self): # TODO
        self.not_parseable(u"Expected ']'",
                u"cdef extern foo(object[int, ndim=2])")

    def disable_test_parse_sizeof(self): # TODO
        self.parse(u"sizeof(int[NN])")
        self.parse(u"sizeof(int[])")
        self.parse(u"sizeof(int[][NN])")
        self.not_parseable(u"Expected an identifier or literal",
                u"sizeof(int[:NN])")
        self.not_parseable(u"Expected ']'",
                u"sizeof(foo[dtype=bar]")

if __name__ == '__main__':
    import unittest
    unittest.main()
