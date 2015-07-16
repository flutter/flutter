import os, tempfile
from Cython.Shadow import inline
from Cython.Build.Inline import safe_type
from Cython.TestUtils import CythonTest

try:
    import numpy
    has_numpy = True
except:
    has_numpy = False

test_kwds = dict(force=True, quiet=True)

global_value = 100

class TestInline(CythonTest):
    def setUp(self):
        CythonTest.setUp(self)
        self.test_kwds = dict(test_kwds)
        if os.path.isdir('BUILD'):
            lib_dir = os.path.join('BUILD','inline')
        else:
            lib_dir = tempfile.mkdtemp(prefix='cython_inline_')
        self.test_kwds['lib_dir'] = lib_dir

    def test_simple(self):
        self.assertEquals(inline("return 1+2", **self.test_kwds), 3)

    def test_types(self):
        self.assertEquals(inline("""
            cimport cython
            return cython.typeof(a), cython.typeof(b)
        """, a=1.0, b=[], **self.test_kwds), ('double', 'list object'))

    def test_locals(self):
        a = 1
        b = 2
        self.assertEquals(inline("return a+b", **self.test_kwds), 3)

    def test_globals(self):
        self.assertEquals(inline("return global_value + 1", **self.test_kwds), global_value + 1)

    def test_pure(self):    
        import cython as cy
        b = inline("""
        b = cy.declare(float, a)
        c = cy.declare(cy.pointer(cy.float), &b)
        return b
        """, a=3)
        self.assertEquals(type(b), float)

    if has_numpy:

        def test_numpy(self):
            import numpy
            a = numpy.ndarray((10, 20))
            a[0,0] = 10
            self.assertEquals(safe_type(a), 'numpy.ndarray[numpy.float64_t, ndim=2]')
            self.assertEquals(inline("return a[0,0]", a=a, **self.test_kwds), 10.0)
