# -*- coding: UTF-8 -*-

"""
Test libpython.py. This is already partly tested by test_libcython_in_gdb and
Lib/test/test_gdb.py in the Python source. These tests are run in gdb and
called from test_libcython_in_gdb.main()
"""

import os
import sys

import gdb

from Cython.Debugger import libcython
from Cython.Debugger import libpython

import test_libcython_in_gdb
from test_libcython_in_gdb import _debug, inferior_python_version


class TestPrettyPrinters(test_libcython_in_gdb.DebugTestCase):
    """
    Test whether types of Python objects are correctly inferred and that
    the right libpython.PySomeTypeObjectPtr classes are instantiated.

    Also test whether values are appropriately formatted (don't be too
    laborious as Lib/test/test_gdb.py already covers this extensively).

    Don't take care of decreffing newly allocated objects as a new
    interpreter is started for every test anyway.
    """

    def setUp(self):
        super(TestPrettyPrinters, self).setUp()
        self.break_and_run('b = c = d = 0')

    def get_pyobject(self, code):
        value = gdb.parse_and_eval(code)
        assert libpython.pointervalue(value) != 0
        return value

    def pyobject_fromcode(self, code, gdbvar=None):
        if gdbvar is not None:
            d = {'varname':gdbvar, 'code':code}
            gdb.execute('set $%(varname)s = %(code)s' % d)
            code = '$' + gdbvar

        return libpython.PyObjectPtr.from_pyobject_ptr(self.get_pyobject(code))

    def get_repr(self, pyobject):
        return pyobject.get_truncated_repr(libpython.MAX_OUTPUT_LEN)

    def alloc_bytestring(self, string, gdbvar=None):
        if inferior_python_version < (3, 0):
            funcname = 'PyString_FromStringAndSize'
        else:
            funcname = 'PyBytes_FromStringAndSize'

        assert '"' not in string

        # ensure double quotes
        code = '(PyObject *) %s("%s", %d)' % (funcname, string, len(string))
        return self.pyobject_fromcode(code, gdbvar=gdbvar)

    def alloc_unicodestring(self, string, gdbvar=None):
        self.alloc_bytestring(string.encode('UTF-8'), gdbvar='_temp')

        postfix = libpython.get_inferior_unicode_postfix()
        funcname = 'PyUnicode%s_FromEncodedObject' % (postfix,)

        return self.pyobject_fromcode(
            '(PyObject *) %s($_temp, "UTF-8", "strict")' % funcname,
            gdbvar=gdbvar)

    def test_bytestring(self):
        bytestring = self.alloc_bytestring("spam")

        if inferior_python_version < (3, 0):
            bytestring_class = libpython.PyStringObjectPtr
            expected = repr("spam")
        else:
            bytestring_class = libpython.PyBytesObjectPtr
            expected = "b'spam'"

        self.assertEqual(type(bytestring), bytestring_class)
        self.assertEqual(self.get_repr(bytestring), expected)

    def test_unicode(self):
        unicode_string = self.alloc_unicodestring(u"spam ἄλφα")

        expected = "'spam ἄλφα'"
        if inferior_python_version < (3, 0):
            expected = 'u' + expected

        self.assertEqual(type(unicode_string), libpython.PyUnicodeObjectPtr)
        self.assertEqual(self.get_repr(unicode_string), expected)

    def test_int(self):
        if inferior_python_version < (3, 0):
            intval = self.pyobject_fromcode('PyInt_FromLong(100)')
            self.assertEqual(type(intval), libpython.PyIntObjectPtr)
            self.assertEqual(self.get_repr(intval), '100')

    def test_long(self):
        longval = self.pyobject_fromcode('PyLong_FromLong(200)',
                                         gdbvar='longval')
        assert gdb.parse_and_eval('$longval->ob_type == &PyLong_Type')

        self.assertEqual(type(longval), libpython.PyLongObjectPtr)
        self.assertEqual(self.get_repr(longval), '200')

    def test_frame_type(self):
        frame = self.pyobject_fromcode('PyEval_GetFrame()')

        self.assertEqual(type(frame), libpython.PyFrameObjectPtr)
