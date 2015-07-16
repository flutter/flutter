# -*- coding: utf-8 -*-
"""
    jinja2._compat
    ~~~~~~~~~~~~~~

    Some py2/py3 compatibility support based on a stripped down
    version of six so we don't have to depend on a specific version
    of it.

    :copyright: Copyright 2013 by the Jinja team, see AUTHORS.
    :license: BSD, see LICENSE for details.
"""
import sys

PY2 = sys.version_info[0] == 2
PYPY = hasattr(sys, 'pypy_translation_info')
_identity = lambda x: x


if not PY2:
    unichr = chr
    range_type = range
    text_type = str
    string_types = (str,)

    iterkeys = lambda d: iter(d.keys())
    itervalues = lambda d: iter(d.values())
    iteritems = lambda d: iter(d.items())

    import pickle
    from io import BytesIO, StringIO
    NativeStringIO = StringIO

    def reraise(tp, value, tb=None):
        if value.__traceback__ is not tb:
            raise value.with_traceback(tb)
        raise value

    ifilter = filter
    imap = map
    izip = zip
    intern = sys.intern

    implements_iterator = _identity
    implements_to_string = _identity
    encode_filename = _identity
    get_next = lambda x: x.__next__

else:
    unichr = unichr
    text_type = unicode
    range_type = xrange
    string_types = (str, unicode)

    iterkeys = lambda d: d.iterkeys()
    itervalues = lambda d: d.itervalues()
    iteritems = lambda d: d.iteritems()

    import cPickle as pickle
    from cStringIO import StringIO as BytesIO, StringIO
    NativeStringIO = BytesIO

    exec('def reraise(tp, value, tb=None):\n raise tp, value, tb')

    from itertools import imap, izip, ifilter
    intern = intern

    def implements_iterator(cls):
        cls.next = cls.__next__
        del cls.__next__
        return cls

    def implements_to_string(cls):
        cls.__unicode__ = cls.__str__
        cls.__str__ = lambda x: x.__unicode__().encode('utf-8')
        return cls

    get_next = lambda x: x.next

    def encode_filename(filename):
        if isinstance(filename, unicode):
            return filename.encode('utf-8')
        return filename

try:
    next = next
except NameError:
    def next(it):
        return it.next()


def with_metaclass(meta, *bases):
    # This requires a bit of explanation: the basic idea is to make a
    # dummy metaclass for one level of class instanciation that replaces
    # itself with the actual metaclass.  Because of internal type checks
    # we also need to make sure that we downgrade the custom metaclass
    # for one level to something closer to type (that's why __call__ and
    # __init__ comes back from type etc.).
    #
    # This has the advantage over six.with_metaclass in that it does not
    # introduce dummy classes into the final MRO.
    class metaclass(meta):
        __call__ = type.__call__
        __init__ = type.__init__
        def __new__(cls, name, this_bases, d):
            if this_bases is None:
                return type.__new__(cls, name, (), d)
            return meta(name, bases, d)
    return metaclass('temporary_class', None, {})


try:
    from collections import Mapping as mapping_types
except ImportError:
    import UserDict
    mapping_types = (UserDict.UserDict, UserDict.DictMixin, dict)


# common types.  These do exist in the special types module too which however
# does not exist in IronPython out of the box.  Also that way we don't have
# to deal with implementation specific stuff here
class _C(object):
    def method(self): pass
def _func():
    yield None
function_type = type(_func)
generator_type = type(_func())
method_type = type(_C().method)
code_type = type(_C.method.__code__)
try:
    raise TypeError()
except TypeError:
    _tb = sys.exc_info()[2]
    traceback_type = type(_tb)
    frame_type = type(_tb.tb_frame)


try:
    from urllib.parse import quote_from_bytes as url_quote
except ImportError:
    from urllib import quote as url_quote


try:
    from thread import allocate_lock
except ImportError:
    try:
        from threading import Lock as allocate_lock
    except ImportError:
        from dummy_thread import allocate_lock
