#!/usr/bin/python

# NOTE: this file is taken from the Python source distribution
# It can be found under Tools/gdb/libpython.py. It is shipped with Cython
# because it's not installed as a python module, and because changes are only
# merged into new python versions (v3.2+).

'''
From gdb 7 onwards, gdb's build can be configured --with-python, allowing gdb
to be extended with Python code e.g. for library-specific data visualizations,
such as for the C++ STL types.  Documentation on this API can be seen at:
http://sourceware.org/gdb/current/onlinedocs/gdb/Python-API.html


This python module deals with the case when the process being debugged (the
"inferior process" in gdb parlance) is itself python, or more specifically,
linked against libpython.  In this situation, almost every item of data is a
(PyObject*), and having the debugger merely print their addresses is not very
enlightening.

This module embeds knowledge about the implementation details of libpython so
that we can emit useful visualizations e.g. a string, a list, a dict, a frame
giving file/line information and the state of local variables

In particular, given a gdb.Value corresponding to a PyObject* in the inferior
process, we can generate a "proxy value" within the gdb process.  For example,
given a PyObject* in the inferior process that is in fact a PyListObject*
holding three PyObject* that turn out to be PyStringObject* instances, we can
generate a proxy value within the gdb process that is a list of strings:
  ["foo", "bar", "baz"]

Doing so can be expensive for complicated graphs of objects, and could take
some time, so we also have a "write_repr" method that writes a representation
of the data to a file-like object.  This allows us to stop the traversal by
having the file-like object raise an exception if it gets too much data.

With both "proxyval" and "write_repr" we keep track of the set of all addresses
visited so far in the traversal, to avoid infinite recursion due to cycles in
the graph of object references.

We try to defer gdb.lookup_type() invocations for python types until as late as
possible: for a dynamically linked python binary, when the process starts in
the debugger, the libpython.so hasn't been dynamically loaded yet, so none of
the type names are known to the debugger

The module also extends gdb with some python-specific commands.
'''
from __future__ import with_statement

import os
import re
import sys
import struct
import locale
import atexit
import warnings
import tempfile
import textwrap
import itertools

import gdb

if sys.version_info[0] < 3:
    # I think this is the only way to fix this bug :'(
    # http://sourceware.org/bugzilla/show_bug.cgi?id=12285
    out, err = sys.stdout, sys.stderr
    reload(sys).setdefaultencoding('UTF-8')
    sys.stdout = out
    sys.stderr = err

# Look up the gdb.Type for some standard types:
_type_char_ptr = gdb.lookup_type('char').pointer() # char*
_type_unsigned_char_ptr = gdb.lookup_type('unsigned char').pointer()
_type_void_ptr = gdb.lookup_type('void').pointer() # void*

SIZEOF_VOID_P = _type_void_ptr.sizeof

Py_TPFLAGS_HEAPTYPE = (1L << 9)

Py_TPFLAGS_INT_SUBCLASS      = (1L << 23)
Py_TPFLAGS_LONG_SUBCLASS     = (1L << 24)
Py_TPFLAGS_LIST_SUBCLASS     = (1L << 25)
Py_TPFLAGS_TUPLE_SUBCLASS    = (1L << 26)
Py_TPFLAGS_STRING_SUBCLASS   = (1L << 27)
Py_TPFLAGS_BYTES_SUBCLASS    = (1L << 27)
Py_TPFLAGS_UNICODE_SUBCLASS  = (1L << 28)
Py_TPFLAGS_DICT_SUBCLASS     = (1L << 29)
Py_TPFLAGS_BASE_EXC_SUBCLASS = (1L << 30)
Py_TPFLAGS_TYPE_SUBCLASS     = (1L << 31)

MAX_OUTPUT_LEN = 1024

hexdigits = "0123456789abcdef"

ENCODING = locale.getpreferredencoding()

class NullPyObjectPtr(RuntimeError):
    pass


def safety_limit(val):
    # Given a integer value from the process being debugged, limit it to some
    # safety threshold so that arbitrary breakage within said process doesn't
    # break the gdb process too much (e.g. sizes of iterations, sizes of lists)
    return min(val, 1000)


def safe_range(val):
    # As per range, but don't trust the value too much: cap it to a safety
    # threshold in case the data was corrupted
    return xrange(safety_limit(val))

def write_unicode(file, text):
    # Write a byte or unicode string to file. Unicode strings are encoded to
    # ENCODING encoding with 'backslashreplace' error handler to avoid
    # UnicodeEncodeError.
    if isinstance(text, unicode):
        text = text.encode(ENCODING, 'backslashreplace')
    file.write(text)

def os_fsencode(filename):
    if not isinstance(filename, unicode):
        return filename
    encoding = sys.getfilesystemencoding()
    if encoding == 'mbcs':
        # mbcs doesn't support surrogateescape
        return filename.encode(encoding)
    encoded = []
    for char in filename:
        # surrogateescape error handler
        if 0xDC80 <= ord(char) <= 0xDCFF:
            byte = chr(ord(char) - 0xDC00)
        else:
            byte = char.encode(encoding)
        encoded.append(byte)
    return ''.join(encoded)

class StringTruncated(RuntimeError):
    pass

class TruncatedStringIO(object):
    '''Similar to cStringIO, but can truncate the output by raising a
    StringTruncated exception'''
    def __init__(self, maxlen=None):
        self._val = ''
        self.maxlen = maxlen

    def write(self, data):
        if self.maxlen:
            if len(data) + len(self._val) > self.maxlen:
                # Truncation:
                self._val += data[0:self.maxlen - len(self._val)]
                raise StringTruncated()

        self._val += data

    def getvalue(self):
        return self._val


# pretty printer lookup
all_pretty_typenames = set()

class PrettyPrinterTrackerMeta(type):

    def __init__(self, name, bases, dict):
        super(PrettyPrinterTrackerMeta, self).__init__(name, bases, dict)
        all_pretty_typenames.add(self._typename)


class PyObjectPtr(object):
    """
    Class wrapping a gdb.Value that's a either a (PyObject*) within the
    inferior process, or some subclass pointer e.g. (PyStringObject*)

    There will be a subclass for every refined PyObject type that we care
    about.

    Note that at every stage the underlying pointer could be NULL, point
    to corrupt data, etc; this is the debugger, after all.
    """

    __metaclass__ = PrettyPrinterTrackerMeta

    _typename = 'PyObject'

    def __init__(self, gdbval, cast_to=None):
        if cast_to:
            self._gdbval = gdbval.cast(cast_to)
        else:
            self._gdbval = gdbval

    def field(self, name):
        '''
        Get the gdb.Value for the given field within the PyObject, coping with
        some python 2 versus python 3 differences.

        Various libpython types are defined using the "PyObject_HEAD" and
        "PyObject_VAR_HEAD" macros.

        In Python 2, this these are defined so that "ob_type" and (for a var
        object) "ob_size" are fields of the type in question.

        In Python 3, this is defined as an embedded PyVarObject type thus:
           PyVarObject ob_base;
        so that the "ob_size" field is located insize the "ob_base" field, and
        the "ob_type" is most easily accessed by casting back to a (PyObject*).
        '''
        if self.is_null():
            raise NullPyObjectPtr(self)

        if name == 'ob_type':
            pyo_ptr = self._gdbval.cast(PyObjectPtr.get_gdb_type())
            return pyo_ptr.dereference()[name]

        if name == 'ob_size':
            pyo_ptr = self._gdbval.cast(PyVarObjectPtr.get_gdb_type())
            return pyo_ptr.dereference()[name]

        # General case: look it up inside the object:
        return self._gdbval.dereference()[name]

    def pyop_field(self, name):
        '''
        Get a PyObjectPtr for the given PyObject* field within this PyObject,
        coping with some python 2 versus python 3 differences.
        '''
        return PyObjectPtr.from_pyobject_ptr(self.field(name))

    def write_field_repr(self, name, out, visited):
        '''
        Extract the PyObject* field named "name", and write its representation
        to file-like object "out"
        '''
        field_obj = self.pyop_field(name)
        field_obj.write_repr(out, visited)

    def get_truncated_repr(self, maxlen):
        '''
        Get a repr-like string for the data, but truncate it at "maxlen" bytes
        (ending the object graph traversal as soon as you do)
        '''
        out = TruncatedStringIO(maxlen)
        try:
            self.write_repr(out, set())
        except StringTruncated:
            # Truncation occurred:
            return out.getvalue() + '...(truncated)'

        # No truncation occurred:
        return out.getvalue()

    def type(self):
        return PyTypeObjectPtr(self.field('ob_type'))

    def is_null(self):
        return 0 == long(self._gdbval)

    def is_optimized_out(self):
        '''
        Is the value of the underlying PyObject* visible to the debugger?

        This can vary with the precise version of the compiler used to build
        Python, and the precise version of gdb.

        See e.g. https://bugzilla.redhat.com/show_bug.cgi?id=556975 with
        PyEval_EvalFrameEx's "f"
        '''
        return self._gdbval.is_optimized_out

    def safe_tp_name(self):
        try:
            return self.type().field('tp_name').string()
        except NullPyObjectPtr:
            # NULL tp_name?
            return 'unknown'
        except RuntimeError:
            # Can't even read the object at all?
            return 'unknown'

    def proxyval(self, visited):
        '''
        Scrape a value from the inferior process, and try to represent it
        within the gdb process, whilst (hopefully) avoiding crashes when
        the remote data is corrupt.

        Derived classes will override this.

        For example, a PyIntObject* with ob_ival 42 in the inferior process
        should result in an int(42) in this process.

        visited: a set of all gdb.Value pyobject pointers already visited
        whilst generating this value (to guard against infinite recursion when
        visiting object graphs with loops).  Analogous to Py_ReprEnter and
        Py_ReprLeave
        '''

        class FakeRepr(object):
            """
            Class representing a non-descript PyObject* value in the inferior
            process for when we don't have a custom scraper, intended to have
            a sane repr().
            """

            def __init__(self, tp_name, address):
                self.tp_name = tp_name
                self.address = address

            def __repr__(self):
                # For the NULL pointer, we have no way of knowing a type, so
                # special-case it as per
                # http://bugs.python.org/issue8032#msg100882
                if self.address == 0:
                    return '0x0'
                return '<%s at remote 0x%x>' % (self.tp_name, self.address)

        return FakeRepr(self.safe_tp_name(),
                        long(self._gdbval))

    def write_repr(self, out, visited):
        '''
        Write a string representation of the value scraped from the inferior
        process to "out", a file-like object.
        '''
        # Default implementation: generate a proxy value and write its repr
        # However, this could involve a lot of work for complicated objects,
        # so for derived classes we specialize this
        return out.write(repr(self.proxyval(visited)))

    @classmethod
    def subclass_from_type(cls, t):
        '''
        Given a PyTypeObjectPtr instance wrapping a gdb.Value that's a
        (PyTypeObject*), determine the corresponding subclass of PyObjectPtr
        to use

        Ideally, we would look up the symbols for the global types, but that
        isn't working yet:
          (gdb) python print gdb.lookup_symbol('PyList_Type')[0].value
          Traceback (most recent call last):
            File "<string>", line 1, in <module>
          NotImplementedError: Symbol type not yet supported in Python scripts.
          Error while executing Python code.

        For now, we use tp_flags, after doing some string comparisons on the
        tp_name for some special-cases that don't seem to be visible through
        flags
        '''
        try:
            tp_name = t.field('tp_name').string()
            tp_flags = int(t.field('tp_flags'))
        except RuntimeError:
            # Handle any kind of error e.g. NULL ptrs by simply using the base
            # class
            return cls

        #print 'tp_flags = 0x%08x' % tp_flags
        #print 'tp_name = %r' % tp_name

        name_map = {'bool': PyBoolObjectPtr,
                    'classobj': PyClassObjectPtr,
                    'instance': PyInstanceObjectPtr,
                    'NoneType': PyNoneStructPtr,
                    'frame': PyFrameObjectPtr,
                    'set' : PySetObjectPtr,
                    'frozenset' : PySetObjectPtr,
                    'builtin_function_or_method' : PyCFunctionObjectPtr,
                    }
        if tp_name in name_map:
            return name_map[tp_name]

        if tp_flags & (Py_TPFLAGS_HEAPTYPE|Py_TPFLAGS_TYPE_SUBCLASS):
            return PyTypeObjectPtr

        if tp_flags & Py_TPFLAGS_INT_SUBCLASS:
            return PyIntObjectPtr
        if tp_flags & Py_TPFLAGS_LONG_SUBCLASS:
            return PyLongObjectPtr
        if tp_flags & Py_TPFLAGS_LIST_SUBCLASS:
            return PyListObjectPtr
        if tp_flags & Py_TPFLAGS_TUPLE_SUBCLASS:
            return PyTupleObjectPtr
        if tp_flags & Py_TPFLAGS_STRING_SUBCLASS:
            try:
                gdb.lookup_type('PyBytesObject')
                return PyBytesObjectPtr
            except RuntimeError:
                return PyStringObjectPtr
        if tp_flags & Py_TPFLAGS_UNICODE_SUBCLASS:
            return PyUnicodeObjectPtr
        if tp_flags & Py_TPFLAGS_DICT_SUBCLASS:
            return PyDictObjectPtr
        if tp_flags & Py_TPFLAGS_BASE_EXC_SUBCLASS:
            return PyBaseExceptionObjectPtr

        # Use the base class:
        return cls

    @classmethod
    def from_pyobject_ptr(cls, gdbval):
        '''
        Try to locate the appropriate derived class dynamically, and cast
        the pointer accordingly.
        '''
        try:
            p = PyObjectPtr(gdbval)
            cls = cls.subclass_from_type(p.type())
            return cls(gdbval, cast_to=cls.get_gdb_type())
        except RuntimeError, exc:
            # Handle any kind of error e.g. NULL ptrs by simply using the base
            # class
            pass
        return cls(gdbval)

    @classmethod
    def get_gdb_type(cls):
        return gdb.lookup_type(cls._typename).pointer()

    def as_address(self):
        return long(self._gdbval)


class PyVarObjectPtr(PyObjectPtr):
    _typename = 'PyVarObject'

class ProxyAlreadyVisited(object):
    '''
    Placeholder proxy to use when protecting against infinite recursion due to
    loops in the object graph.

    Analogous to the values emitted by the users of Py_ReprEnter and Py_ReprLeave
    '''
    def __init__(self, rep):
        self._rep = rep

    def __repr__(self):
        return self._rep


def _write_instance_repr(out, visited, name, pyop_attrdict, address):
    '''Shared code for use by old-style and new-style classes:
    write a representation to file-like object "out"'''
    out.write('<')
    out.write(name)

    # Write dictionary of instance attributes:
    if isinstance(pyop_attrdict, PyDictObjectPtr):
        out.write('(')
        first = True
        for pyop_arg, pyop_val in pyop_attrdict.iteritems():
            if not first:
                out.write(', ')
            first = False
            out.write(pyop_arg.proxyval(visited))
            out.write('=')
            pyop_val.write_repr(out, visited)
        out.write(')')
    out.write(' at remote 0x%x>' % address)


class InstanceProxy(object):

    def __init__(self, cl_name, attrdict, address):
        self.cl_name = cl_name
        self.attrdict = attrdict
        self.address = address

    def __repr__(self):
        if isinstance(self.attrdict, dict):
            kwargs = ', '.join(["%s=%r" % (arg, val)
                                for arg, val in self.attrdict.iteritems()])
            return '<%s(%s) at remote 0x%x>' % (self.cl_name,
                                                kwargs, self.address)
        else:
            return '<%s at remote 0x%x>' % (self.cl_name,
                                            self.address)

def _PyObject_VAR_SIZE(typeobj, nitems):
    return ( ( typeobj.field('tp_basicsize') +
               nitems * typeobj.field('tp_itemsize') +
               (SIZEOF_VOID_P - 1)
             ) & ~(SIZEOF_VOID_P - 1)
           ).cast(gdb.lookup_type('size_t'))

class PyTypeObjectPtr(PyObjectPtr):
    _typename = 'PyTypeObject'

    def get_attr_dict(self):
        '''
        Get the PyDictObject ptr representing the attribute dictionary
        (or None if there's a problem)
        '''
        try:
            typeobj = self.type()
            dictoffset = int_from_int(typeobj.field('tp_dictoffset'))
            if dictoffset != 0:
                if dictoffset < 0:
                    type_PyVarObject_ptr = gdb.lookup_type('PyVarObject').pointer()
                    tsize = int_from_int(self._gdbval.cast(type_PyVarObject_ptr)['ob_size'])
                    if tsize < 0:
                        tsize = -tsize
                    size = _PyObject_VAR_SIZE(typeobj, tsize)
                    dictoffset += size
                    assert dictoffset > 0
                    assert dictoffset % SIZEOF_VOID_P == 0

                dictptr = self._gdbval.cast(_type_char_ptr) + dictoffset
                PyObjectPtrPtr = PyObjectPtr.get_gdb_type().pointer()
                dictptr = dictptr.cast(PyObjectPtrPtr)
                return PyObjectPtr.from_pyobject_ptr(dictptr.dereference())
        except RuntimeError:
            # Corrupt data somewhere; fail safe
            pass

        # Not found, or some kind of error:
        return None

    def proxyval(self, visited):
        '''
        Support for new-style classes.

        Currently we just locate the dictionary using a transliteration to
        python of _PyObject_GetDictPtr, ignoring descriptors
        '''
        # Guard against infinite loops:
        if self.as_address() in visited:
            return ProxyAlreadyVisited('<...>')
        visited.add(self.as_address())

        pyop_attr_dict = self.get_attr_dict()
        if pyop_attr_dict:
            attr_dict = pyop_attr_dict.proxyval(visited)
        else:
            attr_dict = {}
        tp_name = self.safe_tp_name()

        # New-style class:
        return InstanceProxy(tp_name, attr_dict, long(self._gdbval))

    def write_repr(self, out, visited):
        # Guard against infinite loops:
        if self.as_address() in visited:
            out.write('<...>')
            return
        visited.add(self.as_address())

        try:
            tp_name = self.field('tp_name').string()
        except RuntimeError:
            tp_name = 'unknown'

        out.write('<type %s at remote 0x%x>' % (tp_name,
                                                self.as_address()))
        # pyop_attrdict = self.get_attr_dict()
        # _write_instance_repr(out, visited,
                             # self.safe_tp_name(), pyop_attrdict, self.as_address())

class ProxyException(Exception):
    def __init__(self, tp_name, args):
        self.tp_name = tp_name
        self.args = args

    def __repr__(self):
        return '%s%r' % (self.tp_name, self.args)

class PyBaseExceptionObjectPtr(PyObjectPtr):
    """
    Class wrapping a gdb.Value that's a PyBaseExceptionObject* i.e. an exception
    within the process being debugged.
    """
    _typename = 'PyBaseExceptionObject'

    def proxyval(self, visited):
        # Guard against infinite loops:
        if self.as_address() in visited:
            return ProxyAlreadyVisited('(...)')
        visited.add(self.as_address())
        arg_proxy = self.pyop_field('args').proxyval(visited)
        return ProxyException(self.safe_tp_name(),
                              arg_proxy)

    def write_repr(self, out, visited):
        # Guard against infinite loops:
        if self.as_address() in visited:
            out.write('(...)')
            return
        visited.add(self.as_address())

        out.write(self.safe_tp_name())
        self.write_field_repr('args', out, visited)


class PyClassObjectPtr(PyObjectPtr):
    """
    Class wrapping a gdb.Value that's a PyClassObject* i.e. a <classobj>
    instance within the process being debugged.
    """
    _typename = 'PyClassObject'


class BuiltInFunctionProxy(object):
    def __init__(self, ml_name):
        self.ml_name = ml_name

    def __repr__(self):
        return "<built-in function %s>" % self.ml_name

class BuiltInMethodProxy(object):
    def __init__(self, ml_name, pyop_m_self):
        self.ml_name = ml_name
        self.pyop_m_self = pyop_m_self

    def __repr__(self):
        return ('<built-in method %s of %s object at remote 0x%x>'
                % (self.ml_name,
                   self.pyop_m_self.safe_tp_name(),
                   self.pyop_m_self.as_address())
                )

class PyCFunctionObjectPtr(PyObjectPtr):
    """
    Class wrapping a gdb.Value that's a PyCFunctionObject*
    (see Include/methodobject.h and Objects/methodobject.c)
    """
    _typename = 'PyCFunctionObject'

    def proxyval(self, visited):
        m_ml = self.field('m_ml') # m_ml is a (PyMethodDef*)
        ml_name = m_ml['ml_name'].string()

        pyop_m_self = self.pyop_field('m_self')
        if pyop_m_self.is_null():
            return BuiltInFunctionProxy(ml_name)
        else:
            return BuiltInMethodProxy(ml_name, pyop_m_self)


class PyCodeObjectPtr(PyObjectPtr):
    """
    Class wrapping a gdb.Value that's a PyCodeObject* i.e. a <code> instance
    within the process being debugged.
    """
    _typename = 'PyCodeObject'

    def addr2line(self, addrq):
        '''
        Get the line number for a given bytecode offset

        Analogous to PyCode_Addr2Line; translated from pseudocode in
        Objects/lnotab_notes.txt
        '''
        co_lnotab = self.pyop_field('co_lnotab').proxyval(set())

        # Initialize lineno to co_firstlineno as per PyCode_Addr2Line
        # not 0, as lnotab_notes.txt has it:
        lineno = int_from_int(self.field('co_firstlineno'))

        addr = 0
        for addr_incr, line_incr in zip(co_lnotab[::2], co_lnotab[1::2]):
            addr += ord(addr_incr)
            if addr > addrq:
                return lineno
            lineno += ord(line_incr)
        return lineno


class PyDictObjectPtr(PyObjectPtr):
    """
    Class wrapping a gdb.Value that's a PyDictObject* i.e. a dict instance
    within the process being debugged.
    """
    _typename = 'PyDictObject'

    def iteritems(self):
        '''
        Yields a sequence of (PyObjectPtr key, PyObjectPtr value) pairs,
        analagous to dict.iteritems()
        '''
        for i in safe_range(self.field('ma_mask') + 1):
            ep = self.field('ma_table') + i
            pyop_value = PyObjectPtr.from_pyobject_ptr(ep['me_value'])
            if not pyop_value.is_null():
                pyop_key = PyObjectPtr.from_pyobject_ptr(ep['me_key'])
                yield (pyop_key, pyop_value)

    def proxyval(self, visited):
        # Guard against infinite loops:
        if self.as_address() in visited:
            return ProxyAlreadyVisited('{...}')
        visited.add(self.as_address())

        result = {}
        for pyop_key, pyop_value in self.iteritems():
            proxy_key = pyop_key.proxyval(visited)
            proxy_value = pyop_value.proxyval(visited)
            result[proxy_key] = proxy_value
        return result

    def write_repr(self, out, visited):
        # Guard against infinite loops:
        if self.as_address() in visited:
            out.write('{...}')
            return
        visited.add(self.as_address())

        out.write('{')
        first = True
        for pyop_key, pyop_value in self.iteritems():
            if not first:
                out.write(', ')
            first = False
            pyop_key.write_repr(out, visited)
            out.write(': ')
            pyop_value.write_repr(out, visited)
        out.write('}')

class PyInstanceObjectPtr(PyObjectPtr):
    _typename = 'PyInstanceObject'

    def proxyval(self, visited):
        # Guard against infinite loops:
        if self.as_address() in visited:
            return ProxyAlreadyVisited('<...>')
        visited.add(self.as_address())

        # Get name of class:
        in_class = self.pyop_field('in_class')
        cl_name = in_class.pyop_field('cl_name').proxyval(visited)

        # Get dictionary of instance attributes:
        in_dict = self.pyop_field('in_dict').proxyval(visited)

        # Old-style class:
        return InstanceProxy(cl_name, in_dict, long(self._gdbval))

    def write_repr(self, out, visited):
        # Guard against infinite loops:
        if self.as_address() in visited:
            out.write('<...>')
            return
        visited.add(self.as_address())

        # Old-style class:

        # Get name of class:
        in_class = self.pyop_field('in_class')
        cl_name = in_class.pyop_field('cl_name').proxyval(visited)

        # Get dictionary of instance attributes:
        pyop_in_dict = self.pyop_field('in_dict')

        _write_instance_repr(out, visited,
                             cl_name, pyop_in_dict, self.as_address())

class PyIntObjectPtr(PyObjectPtr):
    _typename = 'PyIntObject'

    def proxyval(self, visited):
        result = int_from_int(self.field('ob_ival'))
        return result

class PyListObjectPtr(PyObjectPtr):
    _typename = 'PyListObject'

    def __getitem__(self, i):
        # Get the gdb.Value for the (PyObject*) with the given index:
        field_ob_item = self.field('ob_item')
        return field_ob_item[i]

    def proxyval(self, visited):
        # Guard against infinite loops:
        if self.as_address() in visited:
            return ProxyAlreadyVisited('[...]')
        visited.add(self.as_address())

        result = [PyObjectPtr.from_pyobject_ptr(self[i]).proxyval(visited)
                  for i in safe_range(int_from_int(self.field('ob_size')))]
        return result

    def write_repr(self, out, visited):
        # Guard against infinite loops:
        if self.as_address() in visited:
            out.write('[...]')
            return
        visited.add(self.as_address())

        out.write('[')
        for i in safe_range(int_from_int(self.field('ob_size'))):
            if i > 0:
                out.write(', ')
            element = PyObjectPtr.from_pyobject_ptr(self[i])
            element.write_repr(out, visited)
        out.write(']')

class PyLongObjectPtr(PyObjectPtr):
    _typename = 'PyLongObject'

    def proxyval(self, visited):
        '''
        Python's Include/longobjrep.h has this declaration:
           struct _longobject {
               PyObject_VAR_HEAD
               digit ob_digit[1];
           };

        with this description:
            The absolute value of a number is equal to
                 SUM(for i=0 through abs(ob_size)-1) ob_digit[i] * 2**(SHIFT*i)
            Negative numbers are represented with ob_size < 0;
            zero is represented by ob_size == 0.

        where SHIFT can be either:
            #define PyLong_SHIFT        30
            #define PyLong_SHIFT        15
        '''
        ob_size = long(self.field('ob_size'))
        if ob_size == 0:
            return 0L

        ob_digit = self.field('ob_digit')

        if gdb.lookup_type('digit').sizeof == 2:
            SHIFT = 15L
        else:
            SHIFT = 30L

        digits = [long(ob_digit[i]) * 2**(SHIFT*i)
                  for i in safe_range(abs(ob_size))]
        result = sum(digits)
        if ob_size < 0:
            result = -result
        return result

    def write_repr(self, out, visited):
        # Write this out as a Python 3 int literal, i.e. without the "L" suffix
        proxy = self.proxyval(visited)
        out.write("%s" % proxy)


class PyBoolObjectPtr(PyLongObjectPtr):
    """
    Class wrapping a gdb.Value that's a PyBoolObject* i.e. one of the two
    <bool> instances (Py_True/Py_False) within the process being debugged.
    """
    _typename = 'PyBoolObject'

    def proxyval(self, visited):
        castto = gdb.lookup_type('PyLongObject').pointer()
        self._gdbval = self._gdbval.cast(castto)
        return bool(PyLongObjectPtr(self._gdbval).proxyval(visited))


class PyNoneStructPtr(PyObjectPtr):
    """
    Class wrapping a gdb.Value that's a PyObject* pointing to the
    singleton (we hope) _Py_NoneStruct with ob_type PyNone_Type
    """
    _typename = 'PyObject'

    def proxyval(self, visited):
        return None


class PyFrameObjectPtr(PyObjectPtr):
    _typename = 'PyFrameObject'

    def __init__(self, gdbval, cast_to=None):
        PyObjectPtr.__init__(self, gdbval, cast_to)

        if not self.is_optimized_out():
            self.co = PyCodeObjectPtr.from_pyobject_ptr(self.field('f_code'))
            self.co_name = self.co.pyop_field('co_name')
            self.co_filename = self.co.pyop_field('co_filename')

            self.f_lineno = int_from_int(self.field('f_lineno'))
            self.f_lasti = int_from_int(self.field('f_lasti'))
            self.co_nlocals = int_from_int(self.co.field('co_nlocals'))
            self.co_varnames = PyTupleObjectPtr.from_pyobject_ptr(self.co.field('co_varnames'))

    def iter_locals(self):
        '''
        Yield a sequence of (name,value) pairs of PyObjectPtr instances, for
        the local variables of this frame
        '''
        if self.is_optimized_out():
            return

        f_localsplus = self.field('f_localsplus')
        for i in safe_range(self.co_nlocals):
            pyop_value = PyObjectPtr.from_pyobject_ptr(f_localsplus[i])
            if not pyop_value.is_null():
                pyop_name = PyObjectPtr.from_pyobject_ptr(self.co_varnames[i])
                yield (pyop_name, pyop_value)

    def iter_globals(self):
        '''
        Yield a sequence of (name,value) pairs of PyObjectPtr instances, for
        the global variables of this frame
        '''
        if self.is_optimized_out():
            return

        pyop_globals = self.pyop_field('f_globals')
        return pyop_globals.iteritems()

    def iter_builtins(self):
        '''
        Yield a sequence of (name,value) pairs of PyObjectPtr instances, for
        the builtin variables
        '''
        if self.is_optimized_out():
            return

        pyop_builtins = self.pyop_field('f_builtins')
        return pyop_builtins.iteritems()

    def get_var_by_name(self, name):
        '''
        Look for the named local variable, returning a (PyObjectPtr, scope) pair
        where scope is a string 'local', 'global', 'builtin'

        If not found, return (None, None)
        '''
        for pyop_name, pyop_value in self.iter_locals():
            if name == pyop_name.proxyval(set()):
                return pyop_value, 'local'
        for pyop_name, pyop_value in self.iter_globals():
            if name == pyop_name.proxyval(set()):
                return pyop_value, 'global'
        for pyop_name, pyop_value in self.iter_builtins():
            if name == pyop_name.proxyval(set()):
                return pyop_value, 'builtin'
        return None, None

    def filename(self):
        '''Get the path of the current Python source file, as a string'''
        if self.is_optimized_out():
            return '(frame information optimized out)'
        return self.co_filename.proxyval(set())

    def current_line_num(self):
        '''Get current line number as an integer (1-based)

        Translated from PyFrame_GetLineNumber and PyCode_Addr2Line

        See Objects/lnotab_notes.txt
        '''
        if self.is_optimized_out():
            return None
        f_trace = self.field('f_trace')
        if long(f_trace) != 0:
            # we have a non-NULL f_trace:
            return self.f_lineno
        else:
            #try:
            return self.co.addr2line(self.f_lasti)
            #except ValueError:
            #    return self.f_lineno

    def current_line(self):
        '''Get the text of the current source line as a string, with a trailing
        newline character'''
        if self.is_optimized_out():
            return '(frame information optimized out)'
        filename = self.filename()
        with open(os_fsencode(filename), 'r') as f:
            all_lines = f.readlines()
            # Convert from 1-based current_line_num to 0-based list offset:
            return all_lines[self.current_line_num()-1]

    def write_repr(self, out, visited):
        if self.is_optimized_out():
            out.write('(frame information optimized out)')
            return
        out.write('Frame 0x%x, for file %s, line %i, in %s ('
                  % (self.as_address(),
                     self.co_filename.proxyval(visited),
                     self.current_line_num(),
                     self.co_name.proxyval(visited)))
        first = True
        for pyop_name, pyop_value in self.iter_locals():
            if not first:
                out.write(', ')
            first = False

            out.write(pyop_name.proxyval(visited))
            out.write('=')
            pyop_value.write_repr(out, visited)

        out.write(')')

class PySetObjectPtr(PyObjectPtr):
    _typename = 'PySetObject'

    def proxyval(self, visited):
        # Guard against infinite loops:
        if self.as_address() in visited:
            return ProxyAlreadyVisited('%s(...)' % self.safe_tp_name())
        visited.add(self.as_address())

        members = []
        table = self.field('table')
        for i in safe_range(self.field('mask')+1):
            setentry = table[i]
            key = setentry['key']
            if key != 0:
                key_proxy = PyObjectPtr.from_pyobject_ptr(key).proxyval(visited)
                if key_proxy != '<dummy key>':
                    members.append(key_proxy)
        if self.safe_tp_name() == 'frozenset':
            return frozenset(members)
        else:
            return set(members)

    def write_repr(self, out, visited):
        # Emulate Python 3's set_repr
        tp_name = self.safe_tp_name()

        # Guard against infinite loops:
        if self.as_address() in visited:
            out.write('(...)')
            return
        visited.add(self.as_address())

        # Python 3's set_repr special-cases the empty set:
        if not self.field('used'):
            out.write(tp_name)
            out.write('()')
            return

        # Python 3 uses {} for set literals:
        if tp_name != 'set':
            out.write(tp_name)
            out.write('(')

        out.write('{')
        first = True
        table = self.field('table')
        for i in safe_range(self.field('mask')+1):
            setentry = table[i]
            key = setentry['key']
            if key != 0:
                pyop_key = PyObjectPtr.from_pyobject_ptr(key)
                key_proxy = pyop_key.proxyval(visited) # FIXME!
                if key_proxy != '<dummy key>':
                    if not first:
                        out.write(', ')
                    first = False
                    pyop_key.write_repr(out, visited)
        out.write('}')

        if tp_name != 'set':
            out.write(')')


class PyBytesObjectPtr(PyObjectPtr):
    _typename = 'PyBytesObject'

    def __str__(self):
        field_ob_size = self.field('ob_size')
        field_ob_sval = self.field('ob_sval')
        return ''.join(struct.pack('b', field_ob_sval[i])
                           for i in safe_range(field_ob_size))

    def proxyval(self, visited):
        return str(self)

    def write_repr(self, out, visited, py3=True):
        # Write this out as a Python 3 bytes literal, i.e. with a "b" prefix

        # Get a PyStringObject* within the Python 2 gdb process:
        proxy = self.proxyval(visited)

        # Transliteration of Python 3's Objects/bytesobject.c:PyBytes_Repr
        # to Python 2 code:
        quote = "'"
        if "'" in proxy and not '"' in proxy:
            quote = '"'

        if py3:
            out.write('b')

        out.write(quote)
        for byte in proxy:
            if byte == quote or byte == '\\':
                out.write('\\')
                out.write(byte)
            elif byte == '\t':
                out.write('\\t')
            elif byte == '\n':
                out.write('\\n')
            elif byte == '\r':
                out.write('\\r')
            elif byte < ' ' or ord(byte) >= 0x7f:
                out.write('\\x')
                out.write(hexdigits[(ord(byte) & 0xf0) >> 4])
                out.write(hexdigits[ord(byte) & 0xf])
            else:
                out.write(byte)
        out.write(quote)

class PyStringObjectPtr(PyBytesObjectPtr):
    _typename = 'PyStringObject'

    def write_repr(self, out, visited):
        return super(PyStringObjectPtr, self).write_repr(out, visited, py3=False)

class PyTupleObjectPtr(PyObjectPtr):
    _typename = 'PyTupleObject'

    def __getitem__(self, i):
        # Get the gdb.Value for the (PyObject*) with the given index:
        field_ob_item = self.field('ob_item')
        return field_ob_item[i]

    def proxyval(self, visited):
        # Guard against infinite loops:
        if self.as_address() in visited:
            return ProxyAlreadyVisited('(...)')
        visited.add(self.as_address())

        result = tuple([PyObjectPtr.from_pyobject_ptr(self[i]).proxyval(visited)
                        for i in safe_range(int_from_int(self.field('ob_size')))])
        return result

    def write_repr(self, out, visited):
        # Guard against infinite loops:
        if self.as_address() in visited:
            out.write('(...)')
            return
        visited.add(self.as_address())

        out.write('(')
        for i in safe_range(int_from_int(self.field('ob_size'))):
            if i > 0:
                out.write(', ')
            element = PyObjectPtr.from_pyobject_ptr(self[i])
            element.write_repr(out, visited)
        if self.field('ob_size') == 1:
            out.write(',)')
        else:
            out.write(')')


def _unichr_is_printable(char):
    # Logic adapted from Python 3's Tools/unicode/makeunicodedata.py
    if char == u" ":
        return True
    import unicodedata
    return unicodedata.category(char) not in ("C", "Z")

if sys.maxunicode >= 0x10000:
    _unichr = unichr
else:
    # Needed for proper surrogate support if sizeof(Py_UNICODE) is 2 in gdb
    def _unichr(x):
        if x < 0x10000:
            return unichr(x)
        x -= 0x10000
        ch1 = 0xD800 | (x >> 10)
        ch2 = 0xDC00 | (x & 0x3FF)
        return unichr(ch1) + unichr(ch2)

class PyUnicodeObjectPtr(PyObjectPtr):
    _typename = 'PyUnicodeObject'

    def char_width(self):
        _type_Py_UNICODE = gdb.lookup_type('Py_UNICODE')
        return _type_Py_UNICODE.sizeof

    def proxyval(self, visited):
        # From unicodeobject.h:
        #     Py_ssize_t length;  /* Length of raw Unicode data in buffer */
        #     Py_UNICODE *str;    /* Raw Unicode buffer */
        field_length = long(self.field('length'))
        field_str = self.field('str')

        # Gather a list of ints from the Py_UNICODE array; these are either
        # UCS-2 or UCS-4 code points:
        if self.char_width() > 2:
            Py_UNICODEs = [int(field_str[i]) for i in safe_range(field_length)]
        else:
            # A more elaborate routine if sizeof(Py_UNICODE) is 2 in the
            # inferior process: we must join surrogate pairs.
            Py_UNICODEs = []
            i = 0
            limit = safety_limit(field_length)
            while i < limit:
                ucs = int(field_str[i])
                i += 1
                if ucs < 0xD800 or ucs >= 0xDC00 or i == field_length:
                    Py_UNICODEs.append(ucs)
                    continue
                # This could be a surrogate pair.
                ucs2 = int(field_str[i])
                if ucs2 < 0xDC00 or ucs2 > 0xDFFF:
                    continue
                code = (ucs & 0x03FF) << 10
                code |= ucs2 & 0x03FF
                code += 0x00010000
                Py_UNICODEs.append(code)
                i += 1

        # Convert the int code points to unicode characters, and generate a
        # local unicode instance.
        # This splits surrogate pairs if sizeof(Py_UNICODE) is 2 here (in gdb).
        result = u''.join([_unichr(ucs) for ucs in Py_UNICODEs])
        return result

    def write_repr(self, out, visited):
        # Get a PyUnicodeObject* within the Python 2 gdb process:
        proxy = self.proxyval(visited)

        # Transliteration of Python 3's Object/unicodeobject.c:unicode_repr
        # to Python 2:
        try:
            gdb.parse_and_eval('PyString_Type')
        except RuntimeError:
            # Python 3, don't write 'u' as prefix
            pass
        else:
            # Python 2, write the 'u'
            out.write('u')

        if "'" in proxy and '"' not in proxy:
            quote = '"'
        else:
            quote = "'"
        out.write(quote)

        i = 0
        while i < len(proxy):
            ch = proxy[i]
            i += 1

            # Escape quotes and backslashes
            if ch == quote or ch == '\\':
                out.write('\\')
                out.write(ch)

            #  Map special whitespace to '\t', \n', '\r'
            elif ch == '\t':
                out.write('\\t')
            elif ch == '\n':
                out.write('\\n')
            elif ch == '\r':
                out.write('\\r')

            # Map non-printable US ASCII to '\xhh' */
            elif ch < ' ' or ch == 0x7F:
                out.write('\\x')
                out.write(hexdigits[(ord(ch) >> 4) & 0x000F])
                out.write(hexdigits[ord(ch) & 0x000F])

            # Copy ASCII characters as-is
            elif ord(ch) < 0x7F:
                out.write(ch)

            # Non-ASCII characters
            else:
                ucs = ch
                ch2 = None
                if sys.maxunicode < 0x10000:
                    # If sizeof(Py_UNICODE) is 2 here (in gdb), join
                    # surrogate pairs before calling _unichr_is_printable.
                    if (i < len(proxy)
                    and 0xD800 <= ord(ch) < 0xDC00 \
                    and 0xDC00 <= ord(proxy[i]) <= 0xDFFF):
                        ch2 = proxy[i]
                        ucs = ch + ch2
                        i += 1

                # Unfortuately, Python 2's unicode type doesn't seem
                # to expose the "isprintable" method
                printable = _unichr_is_printable(ucs)
                if printable:
                    try:
                        ucs.encode(ENCODING)
                    except UnicodeEncodeError:
                        printable = False

                # Map Unicode whitespace and control characters
                # (categories Z* and C* except ASCII space)
                if not printable:
                    if ch2 is not None:
                        # Match Python 3's representation of non-printable
                        # wide characters.
                        code = (ord(ch) & 0x03FF) << 10
                        code |= ord(ch2) & 0x03FF
                        code += 0x00010000
                    else:
                        code = ord(ucs)

                    # Map 8-bit characters to '\\xhh'
                    if code <= 0xff:
                        out.write('\\x')
                        out.write(hexdigits[(code >> 4) & 0x000F])
                        out.write(hexdigits[code & 0x000F])
                    # Map 21-bit characters to '\U00xxxxxx'
                    elif code >= 0x10000:
                        out.write('\\U')
                        out.write(hexdigits[(code >> 28) & 0x0000000F])
                        out.write(hexdigits[(code >> 24) & 0x0000000F])
                        out.write(hexdigits[(code >> 20) & 0x0000000F])
                        out.write(hexdigits[(code >> 16) & 0x0000000F])
                        out.write(hexdigits[(code >> 12) & 0x0000000F])
                        out.write(hexdigits[(code >> 8) & 0x0000000F])
                        out.write(hexdigits[(code >> 4) & 0x0000000F])
                        out.write(hexdigits[code & 0x0000000F])
                    # Map 16-bit characters to '\uxxxx'
                    else:
                        out.write('\\u')
                        out.write(hexdigits[(code >> 12) & 0x000F])
                        out.write(hexdigits[(code >> 8) & 0x000F])
                        out.write(hexdigits[(code >> 4) & 0x000F])
                        out.write(hexdigits[code & 0x000F])
                else:
                    # Copy characters as-is
                    out.write(ch)
                    if ch2 is not None:
                        out.write(ch2)

        out.write(quote)

    def __unicode__(self):
        return self.proxyval(set())

    def __str__(self):
        # In Python 3, everything is unicode (including attributes of e.g.
        # code objects, such as function names). The Python 2 debugger code
        # uses PyUnicodePtr objects to format strings etc, whereas with a
        # Python 2 debuggee we'd get PyStringObjectPtr instances with __str__.
        # Be compatible with that.
        return unicode(self).encode('UTF-8')

def int_from_int(gdbval):
    return int(str(gdbval))


def stringify(val):
    # TODO: repr() puts everything on one line; pformat can be nicer, but
    # can lead to v.long results; this function isolates the choice
    if True:
        return repr(val)
    else:
        from pprint import pformat
        return pformat(val)


class PyObjectPtrPrinter:
    "Prints a (PyObject*)"

    def __init__ (self, gdbval):
        self.gdbval = gdbval

    def to_string (self):
        pyop = PyObjectPtr.from_pyobject_ptr(self.gdbval)
        if True:
            return pyop.get_truncated_repr(MAX_OUTPUT_LEN)
        else:
            # Generate full proxy value then stringify it.
            # Doing so could be expensive
            proxyval = pyop.proxyval(set())
            return stringify(proxyval)

def pretty_printer_lookup(gdbval):
    type = gdbval.type.unqualified()
    if type.code == gdb.TYPE_CODE_PTR:
        type = type.target().unqualified()
        if str(type) in all_pretty_typenames:
            return PyObjectPtrPrinter(gdbval)

"""
During development, I've been manually invoking the code in this way:
(gdb) python

import sys
sys.path.append('/home/david/coding/python-gdb')
import libpython
end

then reloading it after each edit like this:
(gdb) python reload(libpython)

The following code should ensure that the prettyprinter is registered
if the code is autoloaded by gdb when visiting libpython.so, provided
that this python file is installed to the same path as the library (or its
.debug file) plus a "-gdb.py" suffix, e.g:
  /usr/lib/libpython2.6.so.1.0-gdb.py
  /usr/lib/debug/usr/lib/libpython2.6.so.1.0.debug-gdb.py
"""
def register (obj):
    if obj == None:
        obj = gdb

    # Wire up the pretty-printer
    obj.pretty_printers.append(pretty_printer_lookup)

register (gdb.current_objfile ())

# Unfortunately, the exact API exposed by the gdb module varies somewhat
# from build to build
# See http://bugs.python.org/issue8279?#msg102276

class Frame(object):
    '''
    Wrapper for gdb.Frame, adding various methods
    '''
    def __init__(self, gdbframe):
        self._gdbframe = gdbframe

    def older(self):
        older = self._gdbframe.older()
        if older:
            return Frame(older)
        else:
            return None

    def newer(self):
        newer = self._gdbframe.newer()
        if newer:
            return Frame(newer)
        else:
            return None

    def select(self):
        '''If supported, select this frame and return True; return False if unsupported

        Not all builds have a gdb.Frame.select method; seems to be present on Fedora 12
        onwards, but absent on Ubuntu buildbot'''
        if not hasattr(self._gdbframe, 'select'):
            print ('Unable to select frame: '
                   'this build of gdb does not expose a gdb.Frame.select method')
            return False
        self._gdbframe.select()
        return True

    def get_index(self):
        '''Calculate index of frame, starting at 0 for the newest frame within
        this thread'''
        index = 0
        # Go down until you reach the newest frame:
        iter_frame = self
        while iter_frame.newer():
            index += 1
            iter_frame = iter_frame.newer()
        return index

    def is_evalframeex(self):
        '''Is this a PyEval_EvalFrameEx frame?'''
        if self._gdbframe.name() == 'PyEval_EvalFrameEx':
            '''
            I believe we also need to filter on the inline
            struct frame_id.inline_depth, only regarding frames with
            an inline depth of 0 as actually being this function

            So we reject those with type gdb.INLINE_FRAME
            '''
            if self._gdbframe.type() == gdb.NORMAL_FRAME:
                # We have a PyEval_EvalFrameEx frame:
                return True

        return False

    def read_var(self, varname):
        """
        read_var with respect to code blocks (gdbframe.read_var works with
        respect to the most recent block)

        Apparently this function doesn't work, though, as it seems to read
        variables in other frames also sometimes.
        """
        block = self._gdbframe.block()
        var = None

        while block and var is None:
            try:
                var = self._gdbframe.read_var(varname, block)
            except ValueError:
                pass

            block = block.superblock

        return var

    def get_pyop(self):
        try:
            # self.read_var does not always work properly, so select our frame
            # and restore the previously selected frame
            selected_frame = gdb.selected_frame()
            self._gdbframe.select()
            f = gdb.parse_and_eval('f')
            selected_frame.select()
        except RuntimeError:
            return None
        else:
            return PyFrameObjectPtr.from_pyobject_ptr(f)

    @classmethod
    def get_selected_frame(cls):
        _gdbframe = gdb.selected_frame()
        if _gdbframe:
            return Frame(_gdbframe)
        return None

    @classmethod
    def get_selected_python_frame(cls):
        '''Try to obtain the Frame for the python code in the selected frame,
        or None'''
        frame = cls.get_selected_frame()

        while frame:
            if frame.is_evalframeex():
                return frame
            frame = frame.older()

        # Not found:
        return None

    def print_summary(self):
        if self.is_evalframeex():
            pyop = self.get_pyop()
            if pyop:
                line = pyop.get_truncated_repr(MAX_OUTPUT_LEN)
                write_unicode(sys.stdout, '#%i %s\n' % (self.get_index(), line))
                sys.stdout.write(pyop.current_line())
            else:
                sys.stdout.write('#%i (unable to read python frame information)\n' % self.get_index())
        else:
            sys.stdout.write('#%i\n' % self.get_index())

class PyList(gdb.Command):
    '''List the current Python source code, if any

    Use
       py-list START
    to list at a different line number within the python source.

    Use
       py-list START, END
    to list a specific range of lines within the python source.
    '''

    def __init__(self):
        gdb.Command.__init__ (self,
                              "py-list",
                              gdb.COMMAND_FILES,
                              gdb.COMPLETE_NONE)


    def invoke(self, args, from_tty):
        import re

        start = None
        end = None

        m = re.match(r'\s*(\d+)\s*', args)
        if m:
            start = int(m.group(0))
            end = start + 10

        m = re.match(r'\s*(\d+)\s*,\s*(\d+)\s*', args)
        if m:
            start, end = map(int, m.groups())

        frame = Frame.get_selected_python_frame()
        if not frame:
            print 'Unable to locate python frame'
            return

        pyop = frame.get_pyop()
        if not pyop:
            print 'Unable to read information on python frame'
            return

        filename = pyop.filename()
        lineno = pyop.current_line_num()

        if start is None:
            start = lineno - 5
            end = lineno + 5

        if start<1:
            start = 1

        with open(os_fsencode(filename), 'r') as f:
            all_lines = f.readlines()
            # start and end are 1-based, all_lines is 0-based;
            # so [start-1:end] as a python slice gives us [start, end] as a
            # closed interval
            for i, line in enumerate(all_lines[start-1:end]):
                linestr = str(i+start)
                # Highlight current line:
                if i + start == lineno:
                    linestr = '>' + linestr
                sys.stdout.write('%4s    %s' % (linestr, line))


# ...and register the command:
PyList()

def move_in_stack(move_up):
    '''Move up or down the stack (for the py-up/py-down command)'''
    frame = Frame.get_selected_python_frame()
    while frame:
        if move_up:
            iter_frame = frame.older()
        else:
            iter_frame = frame.newer()

        if not iter_frame:
            break

        if iter_frame.is_evalframeex():
            # Result:
            if iter_frame.select():
                iter_frame.print_summary()
            return

        frame = iter_frame

    if move_up:
        print 'Unable to find an older python frame'
    else:
        print 'Unable to find a newer python frame'

class PyUp(gdb.Command):
    'Select and print the python stack frame that called this one (if any)'
    def __init__(self):
        gdb.Command.__init__ (self,
                              "py-up",
                              gdb.COMMAND_STACK,
                              gdb.COMPLETE_NONE)


    def invoke(self, args, from_tty):
        move_in_stack(move_up=True)

class PyDown(gdb.Command):
    'Select and print the python stack frame called by this one (if any)'
    def __init__(self):
        gdb.Command.__init__ (self,
                              "py-down",
                              gdb.COMMAND_STACK,
                              gdb.COMPLETE_NONE)


    def invoke(self, args, from_tty):
        move_in_stack(move_up=False)

# Not all builds of gdb have gdb.Frame.select
if hasattr(gdb.Frame, 'select'):
    PyUp()
    PyDown()

class PyBacktrace(gdb.Command):
    'Display the current python frame and all the frames within its call stack (if any)'
    def __init__(self):
        gdb.Command.__init__ (self,
                              "py-bt",
                              gdb.COMMAND_STACK,
                              gdb.COMPLETE_NONE)


    def invoke(self, args, from_tty):
        frame = Frame.get_selected_python_frame()
        while frame:
            if frame.is_evalframeex():
                frame.print_summary()
            frame = frame.older()

PyBacktrace()

class PyPrint(gdb.Command):
    'Look up the given python variable name, and print it'
    def __init__(self):
        gdb.Command.__init__ (self,
                              "py-print",
                              gdb.COMMAND_DATA,
                              gdb.COMPLETE_NONE)


    def invoke(self, args, from_tty):
        name = str(args)

        frame = Frame.get_selected_python_frame()
        if not frame:
            print 'Unable to locate python frame'
            return

        pyop_frame = frame.get_pyop()
        if not pyop_frame:
            print 'Unable to read information on python frame'
            return

        pyop_var, scope = pyop_frame.get_var_by_name(name)

        if pyop_var:
            print ('%s %r = %s'
                   % (scope,
                      name,
                      pyop_var.get_truncated_repr(MAX_OUTPUT_LEN)))
        else:
            print '%r not found' % name

PyPrint()

class PyLocals(gdb.Command):
    'Look up the given python variable name, and print it'

    def invoke(self, args, from_tty):
        name = str(args)

        frame = Frame.get_selected_python_frame()
        if not frame:
            print 'Unable to locate python frame'
            return

        pyop_frame = frame.get_pyop()
        if not pyop_frame:
            print 'Unable to read information on python frame'
            return

        namespace = self.get_namespace(pyop_frame)
        namespace = [(name.proxyval(set()), val) for name, val in namespace]

        if namespace:
            name, val = max(namespace, key=lambda (name, val): len(name))
            max_name_length = len(name)

            for name, pyop_value in namespace:
                value = pyop_value.get_truncated_repr(MAX_OUTPUT_LEN)
                print ('%-*s = %s' % (max_name_length, name, value))

    def get_namespace(self, pyop_frame):
        return pyop_frame.iter_locals()


class PyGlobals(PyLocals):
    'List all the globals in the currently select Python frame'

    def get_namespace(self, pyop_frame):
        return pyop_frame.iter_globals()


PyLocals("py-locals", gdb.COMMAND_DATA, gdb.COMPLETE_NONE)
PyGlobals("py-globals", gdb.COMMAND_DATA, gdb.COMPLETE_NONE)


class PyNameEquals(gdb.Function):

    def _get_pycurframe_attr(self, attr):
        frame = Frame(gdb.selected_frame())
        if frame.is_evalframeex():
            pyframe = frame.get_pyop()
            if pyframe is None:
                warnings.warn("Use a Python debug build, Python breakpoints "
                              "won't work otherwise.")
                return None

            return getattr(pyframe, attr).proxyval(set())

        return None

    def invoke(self, funcname):
        attr = self._get_pycurframe_attr('co_name')
        return attr is not None and attr == funcname.string()

PyNameEquals("pyname_equals")


class PyModEquals(PyNameEquals):

    def invoke(self, modname):
        attr = self._get_pycurframe_attr('co_filename')
        if attr is not None:
            filename, ext = os.path.splitext(os.path.basename(attr))
            return filename == modname.string()
        return False

PyModEquals("pymod_equals")


class PyBreak(gdb.Command):
    """
    Set a Python breakpoint. Examples:

    Break on any function or method named 'func' in module 'modname'

        py-break modname.func

    Break on any function or method named 'func'

        py-break func
    """

    def invoke(self, funcname, from_tty):
        if '.' in funcname:
            modname, dot, funcname = funcname.rpartition('.')
            cond = '$pyname_equals("%s") && $pymod_equals("%s")' % (funcname,
                                                                    modname)
        else:
            cond = '$pyname_equals("%s")' % funcname

        gdb.execute('break PyEval_EvalFrameEx if ' + cond)

PyBreak("py-break", gdb.COMMAND_RUNNING, gdb.COMPLETE_NONE)


class _LoggingState(object):
    """
    State that helps to provide a reentrant gdb.execute() function.
    """

    def __init__(self):
        self.fd, self.filename = tempfile.mkstemp()
        self.file = os.fdopen(self.fd, 'r+')
        _execute("set logging file %s" % self.filename)
        self.file_position_stack = []

        atexit.register(os.close, self.fd)
        atexit.register(os.remove, self.filename)

    def __enter__(self):
        if not self.file_position_stack:
            _execute("set logging redirect on")
            _execute("set logging on")
            _execute("set pagination off")

        self.file_position_stack.append(os.fstat(self.fd).st_size)
        return self

    def getoutput(self):
        gdb.flush()
        self.file.seek(self.file_position_stack[-1])
        result = self.file.read()
        return result

    def __exit__(self, exc_type, exc_val, tb):
        startpos = self.file_position_stack.pop()
        self.file.seek(startpos)
        self.file.truncate()
        if not self.file_position_stack:
            _execute("set logging off")
            _execute("set logging redirect off")
            _execute("set pagination on")


def execute(command, from_tty=False, to_string=False):
    """
    Replace gdb.execute() with this function and have it accept a 'to_string'
    argument (new in 7.2). Have it properly capture stderr also. Ensure
    reentrancy.
    """
    if to_string:
        with _logging_state as state:
            _execute(command, from_tty)
            return state.getoutput()
    else:
        _execute(command, from_tty)


_execute = gdb.execute
gdb.execute = execute
_logging_state = _LoggingState()


def get_selected_inferior():
    """
    Return the selected inferior in gdb.
    """
    # Woooh, another bug in gdb! Is there an end in sight?
    # http://sourceware.org/bugzilla/show_bug.cgi?id=12212
    return gdb.inferiors()[0]

    selected_thread = gdb.selected_thread()

    for inferior in gdb.inferiors():
        for thread in inferior.threads():
            if thread == selected_thread:
                return inferior

def source_gdb_script(script_contents, to_string=False):
    """
    Source a gdb script with script_contents passed as a string. This is useful
    to provide defines for py-step and py-next to make them repeatable (this is
    not possible with gdb.execute()). See
    http://sourceware.org/bugzilla/show_bug.cgi?id=12216
    """
    fd, filename = tempfile.mkstemp()
    f = os.fdopen(fd, 'w')
    f.write(script_contents)
    f.close()
    gdb.execute("source %s" % filename, to_string=to_string)
    os.remove(filename)

def register_defines():
    source_gdb_script(textwrap.dedent("""\
        define py-step
        -py-step
        end

        define py-next
        -py-next
        end

        document py-step
        %s
        end

        document py-next
        %s
        end
    """) % (PyStep.__doc__, PyNext.__doc__))


def stackdepth(frame):
    "Tells the stackdepth of a gdb frame."
    depth = 0
    while frame:
        frame = frame.older()
        depth += 1

    return depth

class ExecutionControlCommandBase(gdb.Command):
    """
    Superclass for language specific execution control. Language specific
    features should be implemented by lang_info using the LanguageInfo
    interface. 'name' is the name of the command.
    """

    def __init__(self, name, lang_info):
        super(ExecutionControlCommandBase, self).__init__(
                                name, gdb.COMMAND_RUNNING, gdb.COMPLETE_NONE)
        self.lang_info = lang_info

    def install_breakpoints(self):
        all_locations = itertools.chain(
            self.lang_info.static_break_functions(),
            self.lang_info.runtime_break_functions())

        for location in all_locations:
            result = gdb.execute('break %s' % location, to_string=True)
            yield re.search(r'Breakpoint (\d+)', result).group(1)

    def delete_breakpoints(self, breakpoint_list):
        for bp in breakpoint_list:
            gdb.execute("delete %s" % bp)

    def filter_output(self, result):
        reflags = re.MULTILINE

        output_on_halt = [
            (r'^Program received signal .*', reflags|re.DOTALL),
            (r'.*[Ww]arning.*', 0),
            (r'^Program exited .*', reflags),
        ]

        output_always = [
            # output when halting on a watchpoint
            (r'^(Old|New) value = .*', reflags),
            # output from the 'display' command
            (r'^\d+: \w+ = .*', reflags),
        ]

        def filter_output(regexes):
            output = []
            for regex, flags in regexes:
                for match in re.finditer(regex, result, flags):
                    output.append(match.group(0))

            return '\n'.join(output)

        # Filter the return value output of the 'finish' command
        match_finish = re.search(r'^Value returned is \$\d+ = (.*)', result,
                                 re.MULTILINE)
        if match_finish:
            finish_output = 'Value returned: %s\n' % match_finish.group(1)
        else:
            finish_output = ''

        return (filter_output(output_on_halt),
                finish_output + filter_output(output_always))


    def stopped(self):
        return get_selected_inferior().pid == 0

    def finish_executing(self, result):
        """
        After doing some kind of code running in the inferior, print the line
        of source code or the result of the last executed gdb command (passed
        in as the `result` argument).
        """
        output_on_halt, output_always = self.filter_output(result)

        if self.stopped():
            print output_always
            print output_on_halt
        else:
            frame = gdb.selected_frame()
            source_line = self.lang_info.get_source_line(frame)
            if self.lang_info.is_relevant_function(frame):
                raised_exception = self.lang_info.exc_info(frame)
                if raised_exception:
                    print raised_exception

            if source_line:
                if output_always.rstrip():
                    print output_always.rstrip()
                print source_line
            else:
                print result

    def _finish(self):
        """
        Execute until the function returns (or until something else makes it
        stop)
        """
        if gdb.selected_frame().older() is not None:
            return gdb.execute('finish', to_string=True)
        else:
            # outermost frame, continue
            return gdb.execute('cont', to_string=True)

    def _finish_frame(self):
        """
        Execute until the function returns to a relevant caller.
        """
        while True:
            result = self._finish()

            try:
                frame = gdb.selected_frame()
            except RuntimeError:
                break

            hitbp = re.search(r'Breakpoint (\d+)', result)
            is_relevant = self.lang_info.is_relevant_function(frame)
            if hitbp or is_relevant or self.stopped():
                break

        return result

    def finish(self, *args):
        "Implements the finish command."
        result = self._finish_frame()
        self.finish_executing(result)

    def step(self, stepinto, stepover_command='next'):
        """
        Do a single step or step-over. Returns the result of the last gdb
        command that made execution stop.

        This implementation, for stepping, sets (conditional) breakpoints for
        all functions that are deemed relevant. It then does a step over until
        either something halts execution, or until the next line is reached.

        If, however, stepover_command is given, it should be a string gdb
        command that continues execution in some way. The idea is that the
        caller has set a (conditional) breakpoint or watchpoint that can work
        more efficiently than the step-over loop. For Python this means setting
        a watchpoint for f->f_lasti, which means we can then subsequently
        "finish" frames.
        We want f->f_lasti instead of f->f_lineno, because the latter only
        works properly with local trace functions, see
        PyFrameObjectPtr.current_line_num and PyFrameObjectPtr.addr2line.
        """
        if stepinto:
            breakpoint_list = list(self.install_breakpoints())

        beginframe = gdb.selected_frame()

        if self.lang_info.is_relevant_function(beginframe):
            # If we start in a relevant frame, initialize stuff properly. If
            # we don't start in a relevant frame, the loop will halt
            # immediately. So don't call self.lang_info.lineno() as it may
            # raise for irrelevant frames.
            beginline = self.lang_info.lineno(beginframe)

            if not stepinto:
                depth = stackdepth(beginframe)

        newframe = beginframe

        while True:
            if self.lang_info.is_relevant_function(newframe):
                result = gdb.execute(stepover_command, to_string=True)
            else:
                result = self._finish_frame()

            if self.stopped():
                break

            newframe = gdb.selected_frame()
            is_relevant_function = self.lang_info.is_relevant_function(newframe)
            try:
                framename = newframe.name()
            except RuntimeError:
                framename = None

            m = re.search(r'Breakpoint (\d+)', result)
            if m:
                if is_relevant_function and m.group(1) in breakpoint_list:
                    # although we hit a breakpoint, we still need to check
                    # that the function, in case hit by a runtime breakpoint,
                    # is in the right context
                    break

            if newframe != beginframe:
                # new function

                if not stepinto:
                    # see if we returned to the caller
                    newdepth = stackdepth(newframe)
                    is_relevant_function = (newdepth < depth and
                                            is_relevant_function)

                if is_relevant_function:
                    break
            else:
                # newframe equals beginframe, check for a difference in the
                # line number
                lineno = self.lang_info.lineno(newframe)
                if lineno and lineno != beginline:
                    break

        if stepinto:
            self.delete_breakpoints(breakpoint_list)

        self.finish_executing(result)

    def run(self, args, from_tty):
        self.finish_executing(gdb.execute('run ' + args, to_string=True))

    def cont(self, *args):
        self.finish_executing(gdb.execute('cont', to_string=True))


class LanguageInfo(object):
    """
    This class defines the interface that ExecutionControlCommandBase needs to
    provide language-specific execution control.

    Classes that implement this interface should implement:

        lineno(frame)
            Tells the current line number (only called for a relevant frame).
            If lineno is a false value it is not checked for a difference.

        is_relevant_function(frame)
            tells whether we care about frame 'frame'

        get_source_line(frame)
            get the line of source code for the current line (only called for a
            relevant frame). If the source code cannot be retrieved this
            function should return None

        exc_info(frame) -- optional
            tells whether an exception was raised, if so, it should return a
            string representation of the exception value, None otherwise.

        static_break_functions()
            returns an iterable of function names that are considered relevant
            and should halt step-into execution. This is needed to provide a
            performing step-into

        runtime_break_functions() -- optional
            list of functions that we should break into depending on the
            context
    """

    def exc_info(self, frame):
        "See this class' docstring."

    def runtime_break_functions(self):
        """
        Implement this if the list of step-into functions depends on the
        context.
        """
        return ()

class PythonInfo(LanguageInfo):

    def pyframe(self, frame):
        pyframe = Frame(frame).get_pyop()
        if pyframe:
            return pyframe
        else:
            raise gdb.RuntimeError(
                "Unable to find the Python frame, run your code with a debug "
                "build (configure with --with-pydebug or compile with -g).")

    def lineno(self, frame):
        return self.pyframe(frame).current_line_num()

    def is_relevant_function(self, frame):
        return Frame(frame).is_evalframeex()

    def get_source_line(self, frame):
        try:
            pyframe = self.pyframe(frame)
            return '%4d    %s' % (pyframe.current_line_num(),
                                  pyframe.current_line().rstrip())
        except IOError, e:
            return None

    def exc_info(self, frame):
        try:
            tstate = frame.read_var('tstate').dereference()
            if gdb.parse_and_eval('tstate->frame == f'):
                # tstate local variable initialized, check for an exception
                inf_type = tstate['curexc_type']
                inf_value = tstate['curexc_value']

                if inf_type:
                    return 'An exception was raised: %s' % (inf_value,)
        except (ValueError, RuntimeError), e:
            # Could not read the variable tstate or it's memory, it's ok
            pass

    def static_break_functions(self):
        yield 'PyEval_EvalFrameEx'


class PythonStepperMixin(object):
    """
    Make this a mixin so CyStep can also inherit from this and use a
    CythonCodeStepper at the same time.
    """

    def python_step(self, stepinto):
        """
        Set a watchpoint on the Python bytecode instruction pointer and try
        to finish the frame
        """
        output = gdb.execute('watch f->f_lasti', to_string=True)
        watchpoint = int(re.search(r'[Ww]atchpoint (\d+):', output).group(1))
        self.step(stepinto=stepinto, stepover_command='finish')
        gdb.execute('delete %s' % watchpoint)


class PyStep(ExecutionControlCommandBase, PythonStepperMixin):
    "Step through Python code."

    stepinto = True

    def invoke(self, args, from_tty):
        self.python_step(stepinto=self.stepinto)

class PyNext(PyStep):
    "Step-over Python code."

    stepinto = False

class PyFinish(ExecutionControlCommandBase):
    "Execute until function returns to a caller."

    invoke = ExecutionControlCommandBase.finish

class PyRun(ExecutionControlCommandBase):
    "Run the program."

    invoke = ExecutionControlCommandBase.run

class PyCont(ExecutionControlCommandBase):

    invoke = ExecutionControlCommandBase.cont


def _pointervalue(gdbval):
    """
    Return the value of the pionter as a Python int.

    gdbval.type must be a pointer type
    """
    # don't convert with int() as it will raise a RuntimeError
    if gdbval.address is not None:
        return long(gdbval.address)
    else:
        # the address attribute is None sometimes, in which case we can
        # still convert the pointer to an int
        return long(gdbval)

def pointervalue(gdbval):
    pointer = _pointervalue(gdbval)
    try:
        if pointer < 0:
            raise gdb.GdbError("Negative pointer value, presumably a bug "
                               "in gdb, aborting.")
    except RuntimeError:
        # work around yet another bug in gdb where you get random behaviour
        # and tracebacks
        pass

    return pointer

def get_inferior_unicode_postfix():
    try:
        gdb.parse_and_eval('PyUnicode_FromEncodedObject')
    except RuntimeError:
        try:
            gdb.parse_and_eval('PyUnicodeUCS2_FromEncodedObject')
        except RuntimeError:
            return 'UCS4'
        else:
            return 'UCS2'
    else:
        return ''

class PythonCodeExecutor(object):

    Py_single_input = 256
    Py_file_input = 257
    Py_eval_input = 258

    def malloc(self, size):
        chunk = (gdb.parse_and_eval("(void *) malloc((size_t) %d)" % size))

        pointer = pointervalue(chunk)
        if pointer == 0:
            raise gdb.GdbError("No memory could be allocated in the inferior.")

        return pointer

    def alloc_string(self, string):
        pointer = self.malloc(len(string))
        get_selected_inferior().write_memory(pointer, string)

        return pointer

    def alloc_pystring(self, string):
        stringp = self.alloc_string(string)
        PyString_FromStringAndSize = 'PyString_FromStringAndSize'

        try:
            gdb.parse_and_eval(PyString_FromStringAndSize)
        except RuntimeError:
            # Python 3
            PyString_FromStringAndSize = ('PyUnicode%s_FromStringAndSize' %
                                               (get_inferior_unicode_postfix(),))

        try:
            result = gdb.parse_and_eval(
                '(PyObject *) %s((char *) %d, (size_t) %d)' % (
                            PyString_FromStringAndSize, stringp, len(string)))
        finally:
            self.free(stringp)

        pointer = pointervalue(result)
        if pointer == 0:
            raise gdb.GdbError("Unable to allocate Python string in "
                               "the inferior.")

        return pointer

    def free(self, pointer):
        gdb.parse_and_eval("free((void *) %d)" % pointer)

    def incref(self, pointer):
        "Increment the reference count of a Python object in the inferior."
        gdb.parse_and_eval('Py_IncRef((PyObject *) %d)' % pointer)

    def xdecref(self, pointer):
        "Decrement the reference count of a Python object in the inferior."
        # Py_DecRef is like Py_XDECREF, but a function. So we don't have
        # to check for NULL. This should also decref all our allocated
        # Python strings.
        gdb.parse_and_eval('Py_DecRef((PyObject *) %d)' % pointer)

    def evalcode(self, code, input_type, global_dict=None, local_dict=None):
        """
        Evaluate python code `code` given as a string in the inferior and
        return the result as a gdb.Value. Returns a new reference in the
        inferior.

        Of course, executing any code in the inferior may be dangerous and may
        leave the debuggee in an unsafe state or terminate it alltogether.
        """
        if '\0' in code:
            raise gdb.GdbError("String contains NUL byte.")

        code += '\0'

        pointer = self.alloc_string(code)

        globalsp = pointervalue(global_dict)
        localsp = pointervalue(local_dict)

        if globalsp == 0 or localsp == 0:
            raise gdb.GdbError("Unable to obtain or create locals or globals.")

        code = """
            PyRun_String(
                (char *) %(code)d,
                (int) %(start)d,
                (PyObject *) %(globals)s,
                (PyObject *) %(locals)d)
        """ % dict(code=pointer, start=input_type,
                   globals=globalsp, locals=localsp)

        with FetchAndRestoreError():
            try:
                pyobject_return_value = gdb.parse_and_eval(code)
            finally:
                self.free(pointer)

        return pyobject_return_value

class FetchAndRestoreError(PythonCodeExecutor):
    """
    Context manager that fetches the error indicator in the inferior and
    restores it on exit.
    """

    def __init__(self):
        self.sizeof_PyObjectPtr = gdb.lookup_type('PyObject').pointer().sizeof
        self.pointer = self.malloc(self.sizeof_PyObjectPtr * 3)

        type = self.pointer
        value = self.pointer + self.sizeof_PyObjectPtr
        traceback = self.pointer + self.sizeof_PyObjectPtr * 2

        self.errstate = type, value, traceback

    def __enter__(self):
        gdb.parse_and_eval("PyErr_Fetch(%d, %d, %d)" % self.errstate)

    def __exit__(self, *args):
        if gdb.parse_and_eval("(int) PyErr_Occurred()"):
            gdb.parse_and_eval("PyErr_Print()")

        pyerr_restore = ("PyErr_Restore("
                            "(PyObject *) *%d,"
                            "(PyObject *) *%d,"
                            "(PyObject *) *%d)")

        try:
            gdb.parse_and_eval(pyerr_restore % self.errstate)
        finally:
            self.free(self.pointer)


class FixGdbCommand(gdb.Command):

    def __init__(self, command, actual_command):
        super(FixGdbCommand, self).__init__(command, gdb.COMMAND_DATA,
                                            gdb.COMPLETE_NONE)
        self.actual_command = actual_command

    def fix_gdb(self):
        """
        It seems that invoking either 'cy exec' and 'py-exec' work perfectly 
        fine, but after this gdb's python API is entirely broken. 
        Maybe some uncleared exception value is still set?
        sys.exc_clear() didn't help. A demonstration:

        (gdb) cy exec 'hello'
        'hello'
        (gdb) python gdb.execute('cont')
        RuntimeError: Cannot convert value to int.
        Error while executing Python code.
        (gdb) python gdb.execute('cont')
        [15148 refs]

        Program exited normally.
        """
        warnings.filterwarnings('ignore', r'.*', RuntimeWarning,
                                re.escape(__name__))
        try:
            long(gdb.parse_and_eval("(void *) 0")) == 0
        except RuntimeError:
            pass
        # warnings.resetwarnings()

    def invoke(self, args, from_tty):
        self.fix_gdb()
        try:
            gdb.execute('%s %s' % (self.actual_command, args))
        except RuntimeError, e:
            raise gdb.GdbError(str(e))
        self.fix_gdb()


def _evalcode_python(executor, code, input_type):
    """
    Execute Python code in the most recent stack frame.
    """
    global_dict = gdb.parse_and_eval('PyEval_GetGlobals()')
    local_dict = gdb.parse_and_eval('PyEval_GetLocals()')

    if (pointervalue(global_dict) == 0 or pointervalue(local_dict) == 0):
        raise gdb.GdbError("Unable to find the locals or globals of the "
                           "most recent Python function (relative to the "
                           "selected frame).")

    return executor.evalcode(code, input_type, global_dict, local_dict)

class PyExec(gdb.Command):

    def readcode(self, expr):
        if expr:
            return expr, PythonCodeExecutor.Py_single_input
        else:
            lines = []
            while True:
                try:
                    line = raw_input('>')
                except EOFError:
                    break
                else:
                    if line.rstrip() == 'end':
                        break

                    lines.append(line)

            return '\n'.join(lines), PythonCodeExecutor.Py_file_input

    def invoke(self, expr, from_tty):
        expr, input_type = self.readcode(expr)
        executor = PythonCodeExecutor()
        executor.xdecref(_evalcode_python(executor, input_type, global_dict,
                                          local_dict))


gdb.execute('set breakpoint pending on')

if hasattr(gdb, 'GdbError'):
     # Wrap py-step and py-next in gdb defines to make them repeatable.
    py_step = PyStep('-py-step', PythonInfo())
    py_next = PyNext('-py-next', PythonInfo())
    register_defines()
    py_finish = PyFinish('py-finish', PythonInfo())
    py_run = PyRun('py-run', PythonInfo())
    py_cont = PyCont('py-cont', PythonInfo())

    py_exec = FixGdbCommand('py-exec', '-py-exec')
    _py_exec = PyExec("-py-exec", gdb.COMMAND_DATA, gdb.COMPLETE_NONE)
else:
    warnings.warn("Use gdb 7.2 or higher to use the py-exec command.")
