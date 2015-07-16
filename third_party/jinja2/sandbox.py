# -*- coding: utf-8 -*-
"""
    jinja2.sandbox
    ~~~~~~~~~~~~~~

    Adds a sandbox layer to Jinja as it was the default behavior in the old
    Jinja 1 releases.  This sandbox is slightly different from Jinja 1 as the
    default behavior is easier to use.

    The behavior can be changed by subclassing the environment.

    :copyright: (c) 2010 by the Jinja Team.
    :license: BSD.
"""
import operator
from jinja2.environment import Environment
from jinja2.exceptions import SecurityError
from jinja2._compat import string_types, function_type, method_type, \
     traceback_type, code_type, frame_type, generator_type, PY2


#: maximum number of items a range may produce
MAX_RANGE = 100000

#: attributes of function objects that are considered unsafe.
UNSAFE_FUNCTION_ATTRIBUTES = set(['func_closure', 'func_code', 'func_dict',
                                  'func_defaults', 'func_globals'])

#: unsafe method attributes.  function attributes are unsafe for methods too
UNSAFE_METHOD_ATTRIBUTES = set(['im_class', 'im_func', 'im_self'])

#: unsafe generator attirbutes.
UNSAFE_GENERATOR_ATTRIBUTES = set(['gi_frame', 'gi_code'])

# On versions > python 2 the special attributes on functions are gone,
# but they remain on methods and generators for whatever reason.
if not PY2:
    UNSAFE_FUNCTION_ATTRIBUTES = set()

import warnings

# make sure we don't warn in python 2.6 about stuff we don't care about
warnings.filterwarnings('ignore', 'the sets module', DeprecationWarning,
                        module='jinja2.sandbox')

from collections import deque

_mutable_set_types = (set,)
_mutable_mapping_types = (dict,)
_mutable_sequence_types = (list,)


# on python 2.x we can register the user collection types
try:
    from UserDict import UserDict, DictMixin
    from UserList import UserList
    _mutable_mapping_types += (UserDict, DictMixin)
    _mutable_set_types += (UserList,)
except ImportError:
    pass

# if sets is still available, register the mutable set from there as well
try:
    from sets import Set
    _mutable_set_types += (Set,)
except ImportError:
    pass

#: register Python 2.6 abstract base classes
try:
    from collections import MutableSet, MutableMapping, MutableSequence
    _mutable_set_types += (MutableSet,)
    _mutable_mapping_types += (MutableMapping,)
    _mutable_sequence_types += (MutableSequence,)
except ImportError:
    pass

_mutable_spec = (
    (_mutable_set_types, frozenset([
        'add', 'clear', 'difference_update', 'discard', 'pop', 'remove',
        'symmetric_difference_update', 'update'
    ])),
    (_mutable_mapping_types, frozenset([
        'clear', 'pop', 'popitem', 'setdefault', 'update'
    ])),
    (_mutable_sequence_types, frozenset([
        'append', 'reverse', 'insert', 'sort', 'extend', 'remove'
    ])),
    (deque, frozenset([
        'append', 'appendleft', 'clear', 'extend', 'extendleft', 'pop',
        'popleft', 'remove', 'rotate'
    ]))
)


def safe_range(*args):
    """A range that can't generate ranges with a length of more than
    MAX_RANGE items.
    """
    rng = range(*args)
    if len(rng) > MAX_RANGE:
        raise OverflowError('range too big, maximum size for range is %d' %
                            MAX_RANGE)
    return rng


def unsafe(f):
    """Marks a function or method as unsafe.

    ::

        @unsafe
        def delete(self):
            pass
    """
    f.unsafe_callable = True
    return f


def is_internal_attribute(obj, attr):
    """Test if the attribute given is an internal python attribute.  For
    example this function returns `True` for the `func_code` attribute of
    python objects.  This is useful if the environment method
    :meth:`~SandboxedEnvironment.is_safe_attribute` is overridden.

    >>> from jinja2.sandbox import is_internal_attribute
    >>> is_internal_attribute(lambda: None, "func_code")
    True
    >>> is_internal_attribute((lambda x:x).func_code, 'co_code')
    True
    >>> is_internal_attribute(str, "upper")
    False
    """
    if isinstance(obj, function_type):
        if attr in UNSAFE_FUNCTION_ATTRIBUTES:
            return True
    elif isinstance(obj, method_type):
        if attr in UNSAFE_FUNCTION_ATTRIBUTES or \
           attr in UNSAFE_METHOD_ATTRIBUTES:
            return True
    elif isinstance(obj, type):
        if attr == 'mro':
            return True
    elif isinstance(obj, (code_type, traceback_type, frame_type)):
        return True
    elif isinstance(obj, generator_type):
        if attr in UNSAFE_GENERATOR_ATTRIBUTES:
            return True
    return attr.startswith('__')


def modifies_known_mutable(obj, attr):
    """This function checks if an attribute on a builtin mutable object
    (list, dict, set or deque) would modify it if called.  It also supports
    the "user"-versions of the objects (`sets.Set`, `UserDict.*` etc.) and
    with Python 2.6 onwards the abstract base classes `MutableSet`,
    `MutableMapping`, and `MutableSequence`.

    >>> modifies_known_mutable({}, "clear")
    True
    >>> modifies_known_mutable({}, "keys")
    False
    >>> modifies_known_mutable([], "append")
    True
    >>> modifies_known_mutable([], "index")
    False

    If called with an unsupported object (such as unicode) `False` is
    returned.

    >>> modifies_known_mutable("foo", "upper")
    False
    """
    for typespec, unsafe in _mutable_spec:
        if isinstance(obj, typespec):
            return attr in unsafe
    return False


class SandboxedEnvironment(Environment):
    """The sandboxed environment.  It works like the regular environment but
    tells the compiler to generate sandboxed code.  Additionally subclasses of
    this environment may override the methods that tell the runtime what
    attributes or functions are safe to access.

    If the template tries to access insecure code a :exc:`SecurityError` is
    raised.  However also other exceptions may occour during the rendering so
    the caller has to ensure that all exceptions are catched.
    """
    sandboxed = True

    #: default callback table for the binary operators.  A copy of this is
    #: available on each instance of a sandboxed environment as
    #: :attr:`binop_table`
    default_binop_table = {
        '+':        operator.add,
        '-':        operator.sub,
        '*':        operator.mul,
        '/':        operator.truediv,
        '//':       operator.floordiv,
        '**':       operator.pow,
        '%':        operator.mod
    }

    #: default callback table for the unary operators.  A copy of this is
    #: available on each instance of a sandboxed environment as
    #: :attr:`unop_table`
    default_unop_table = {
        '+':        operator.pos,
        '-':        operator.neg
    }

    #: a set of binary operators that should be intercepted.  Each operator
    #: that is added to this set (empty by default) is delegated to the
    #: :meth:`call_binop` method that will perform the operator.  The default
    #: operator callback is specified by :attr:`binop_table`.
    #:
    #: The following binary operators are interceptable:
    #: ``//``, ``%``, ``+``, ``*``, ``-``, ``/``, and ``**``
    #:
    #: The default operation form the operator table corresponds to the
    #: builtin function.  Intercepted calls are always slower than the native
    #: operator call, so make sure only to intercept the ones you are
    #: interested in.
    #:
    #: .. versionadded:: 2.6
    intercepted_binops = frozenset()

    #: a set of unary operators that should be intercepted.  Each operator
    #: that is added to this set (empty by default) is delegated to the
    #: :meth:`call_unop` method that will perform the operator.  The default
    #: operator callback is specified by :attr:`unop_table`.
    #:
    #: The following unary operators are interceptable: ``+``, ``-``
    #:
    #: The default operation form the operator table corresponds to the
    #: builtin function.  Intercepted calls are always slower than the native
    #: operator call, so make sure only to intercept the ones you are
    #: interested in.
    #:
    #: .. versionadded:: 2.6
    intercepted_unops = frozenset()

    def intercept_unop(self, operator):
        """Called during template compilation with the name of a unary
        operator to check if it should be intercepted at runtime.  If this
        method returns `True`, :meth:`call_unop` is excuted for this unary
        operator.  The default implementation of :meth:`call_unop` will use
        the :attr:`unop_table` dictionary to perform the operator with the
        same logic as the builtin one.

        The following unary operators are interceptable: ``+`` and ``-``

        Intercepted calls are always slower than the native operator call,
        so make sure only to intercept the ones you are interested in.

        .. versionadded:: 2.6
        """
        return False


    def __init__(self, *args, **kwargs):
        Environment.__init__(self, *args, **kwargs)
        self.globals['range'] = safe_range
        self.binop_table = self.default_binop_table.copy()
        self.unop_table = self.default_unop_table.copy()

    def is_safe_attribute(self, obj, attr, value):
        """The sandboxed environment will call this method to check if the
        attribute of an object is safe to access.  Per default all attributes
        starting with an underscore are considered private as well as the
        special attributes of internal python objects as returned by the
        :func:`is_internal_attribute` function.
        """
        return not (attr.startswith('_') or is_internal_attribute(obj, attr))

    def is_safe_callable(self, obj):
        """Check if an object is safely callable.  Per default a function is
        considered safe unless the `unsafe_callable` attribute exists and is
        True.  Override this method to alter the behavior, but this won't
        affect the `unsafe` decorator from this module.
        """
        return not (getattr(obj, 'unsafe_callable', False) or
                    getattr(obj, 'alters_data', False))

    def call_binop(self, context, operator, left, right):
        """For intercepted binary operator calls (:meth:`intercepted_binops`)
        this function is executed instead of the builtin operator.  This can
        be used to fine tune the behavior of certain operators.

        .. versionadded:: 2.6
        """
        return self.binop_table[operator](left, right)

    def call_unop(self, context, operator, arg):
        """For intercepted unary operator calls (:meth:`intercepted_unops`)
        this function is executed instead of the builtin operator.  This can
        be used to fine tune the behavior of certain operators.

        .. versionadded:: 2.6
        """
        return self.unop_table[operator](arg)

    def getitem(self, obj, argument):
        """Subscribe an object from sandboxed code."""
        try:
            return obj[argument]
        except (TypeError, LookupError):
            if isinstance(argument, string_types):
                try:
                    attr = str(argument)
                except Exception:
                    pass
                else:
                    try:
                        value = getattr(obj, attr)
                    except AttributeError:
                        pass
                    else:
                        if self.is_safe_attribute(obj, argument, value):
                            return value
                        return self.unsafe_undefined(obj, argument)
        return self.undefined(obj=obj, name=argument)

    def getattr(self, obj, attribute):
        """Subscribe an object from sandboxed code and prefer the
        attribute.  The attribute passed *must* be a bytestring.
        """
        try:
            value = getattr(obj, attribute)
        except AttributeError:
            try:
                return obj[attribute]
            except (TypeError, LookupError):
                pass
        else:
            if self.is_safe_attribute(obj, attribute, value):
                return value
            return self.unsafe_undefined(obj, attribute)
        return self.undefined(obj=obj, name=attribute)

    def unsafe_undefined(self, obj, attribute):
        """Return an undefined object for unsafe attributes."""
        return self.undefined('access to attribute %r of %r '
                              'object is unsafe.' % (
            attribute,
            obj.__class__.__name__
        ), name=attribute, obj=obj, exc=SecurityError)

    def call(__self, __context, __obj, *args, **kwargs):
        """Call an object from sandboxed code."""
        # the double prefixes are to avoid double keyword argument
        # errors when proxying the call.
        if not __self.is_safe_callable(__obj):
            raise SecurityError('%r is not safely callable' % (__obj,))
        return __context.call(__obj, *args, **kwargs)


class ImmutableSandboxedEnvironment(SandboxedEnvironment):
    """Works exactly like the regular `SandboxedEnvironment` but does not
    permit modifications on the builtin mutable objects `list`, `set`, and
    `dict` by using the :func:`modifies_known_mutable` function.
    """

    def is_safe_attribute(self, obj, attr, value):
        if not SandboxedEnvironment.is_safe_attribute(self, obj, attr, value):
            return False
        return not modifies_known_mutable(obj, attr)
