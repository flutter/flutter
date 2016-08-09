# mock.py
# Test tools for mocking and patching.
# Copyright (C) 2007-2012 Michael Foord & the mock team
# E-mail: fuzzyman AT voidspace DOT org DOT uk

# mock 1.0
# http://www.voidspace.org.uk/python/mock/

# Released subject to the BSD License
# Please see http://www.voidspace.org.uk/python/license.shtml

# Scripts maintained at http://www.voidspace.org.uk/python/index.shtml
# Comments, suggestions and bug reports welcome.


__all__ = (
    'Mock',
    'MagicMock',
    'patch',
    'sentinel',
    'DEFAULT',
    'ANY',
    'call',
    'create_autospec',
    'FILTER_DIR',
    'NonCallableMock',
    'NonCallableMagicMock',
    'mock_open',
    'PropertyMock',
)


__version__ = '1.0.1'


import pprint
import sys

try:
    import inspect
except ImportError:
    # for alternative platforms that
    # may not have inspect
    inspect = None

try:
    from functools import wraps as original_wraps
except ImportError:
    # Python 2.4 compatibility
    def wraps(original):
        def inner(f):
            f.__name__ = original.__name__
            f.__doc__ = original.__doc__
            f.__module__ = original.__module__
            f.__wrapped__ = original
            return f
        return inner
else:
    if sys.version_info[:2] >= (3, 3):
        wraps = original_wraps
    else:
        def wraps(func):
            def inner(f):
                f = original_wraps(func)(f)
                f.__wrapped__ = func
                return f
            return inner

try:
    unicode
except NameError:
    # Python 3
    basestring = unicode = str

try:
    long
except NameError:
    # Python 3
    long = int

try:
    BaseException
except NameError:
    # Python 2.4 compatibility
    BaseException = Exception

try:
    next
except NameError:
    def next(obj):
        return obj.next()


BaseExceptions = (BaseException,)
if 'java' in sys.platform:
    # jython
    import java
    BaseExceptions = (BaseException, java.lang.Throwable)

try:
    _isidentifier = str.isidentifier
except AttributeError:
    # Python 2.X
    import keyword
    import re
    regex = re.compile(r'^[a-z_][a-z0-9_]*$', re.I)
    def _isidentifier(string):
        if string in keyword.kwlist:
            return False
        return regex.match(string)


inPy3k = sys.version_info[0] == 3

# Needed to work around Python 3 bug where use of "super" interferes with
# defining __class__ as a descriptor
_super = super

self = 'im_self'
builtin = '__builtin__'
if inPy3k:
    self = '__self__'
    builtin = 'builtins'

FILTER_DIR = True


def _is_instance_mock(obj):
    # can't use isinstance on Mock objects because they override __class__
    # The base class for all mocks is NonCallableMock
    return issubclass(type(obj), NonCallableMock)


def _is_exception(obj):
    return (
        isinstance(obj, BaseExceptions) or
        isinstance(obj, ClassTypes) and issubclass(obj, BaseExceptions)
    )


class _slotted(object):
    __slots__ = ['a']


DescriptorTypes = (
    type(_slotted.a),
    property,
)


def _getsignature(func, skipfirst, instance=False):
    if inspect is None:
        raise ImportError('inspect module not available')

    if isinstance(func, ClassTypes) and not instance:
        try:
            func = func.__init__
        except AttributeError:
            return
        skipfirst = True
    elif not isinstance(func, FunctionTypes):
        # for classes where instance is True we end up here too
        try:
            func = func.__call__
        except AttributeError:
            return

    if inPy3k:
        try:
            argspec = inspect.getfullargspec(func)
        except TypeError:
            # C function / method, possibly inherited object().__init__
            return
        regargs, varargs, varkw, defaults, kwonly, kwonlydef, ann = argspec
    else:
        try:
            regargs, varargs, varkwargs, defaults = inspect.getargspec(func)
        except TypeError:
            # C function / method, possibly inherited object().__init__
            return

    # instance methods and classmethods need to lose the self argument
    if getattr(func, self, None) is not None:
        regargs = regargs[1:]
    if skipfirst:
        # this condition and the above one are never both True - why?
        regargs = regargs[1:]

    if inPy3k:
        signature = inspect.formatargspec(
            regargs, varargs, varkw, defaults,
            kwonly, kwonlydef, ann, formatvalue=lambda value: "")
    else:
        signature = inspect.formatargspec(
            regargs, varargs, varkwargs, defaults,
            formatvalue=lambda value: "")
    return signature[1:-1], func


def _check_signature(func, mock, skipfirst, instance=False):
    if not _callable(func):
        return

    result = _getsignature(func, skipfirst, instance)
    if result is None:
        return
    signature, func = result

    # can't use self because "self" is common as an argument name
    # unfortunately even not in the first place
    src = "lambda _mock_self, %s: None" % signature
    checksig = eval(src, {})
    _copy_func_details(func, checksig)
    type(mock)._mock_check_sig = checksig


def _copy_func_details(func, funcopy):
    funcopy.__name__ = func.__name__
    funcopy.__doc__ = func.__doc__
    #funcopy.__dict__.update(func.__dict__)
    funcopy.__module__ = func.__module__
    if not inPy3k:
        funcopy.func_defaults = func.func_defaults
        return
    funcopy.__defaults__ = func.__defaults__
    funcopy.__kwdefaults__ = func.__kwdefaults__


def _callable(obj):
    if isinstance(obj, ClassTypes):
        return True
    if getattr(obj, '__call__', None) is not None:
        return True
    return False


def _is_list(obj):
    # checks for list or tuples
    # XXXX badly named!
    return type(obj) in (list, tuple)


def _instance_callable(obj):
    """Given an object, return True if the object is callable.
    For classes, return True if instances would be callable."""
    if not isinstance(obj, ClassTypes):
        # already an instance
        return getattr(obj, '__call__', None) is not None

    klass = obj
    # uses __bases__ instead of __mro__ so that we work with old style classes
    if klass.__dict__.get('__call__') is not None:
        return True

    for base in klass.__bases__:
        if _instance_callable(base):
            return True
    return False


def _set_signature(mock, original, instance=False):
    # creates a function with signature (*args, **kwargs) that delegates to a
    # mock. It still does signature checking by calling a lambda with the same
    # signature as the original.
    if not _callable(original):
        return

    skipfirst = isinstance(original, ClassTypes)
    result = _getsignature(original, skipfirst, instance)
    if result is None:
        # was a C function (e.g. object().__init__ ) that can't be mocked
        return

    signature, func = result

    src = "lambda %s: None" % signature
    checksig = eval(src, {})
    _copy_func_details(func, checksig)

    name = original.__name__
    if not _isidentifier(name):
        name = 'funcopy'
    context = {'_checksig_': checksig, 'mock': mock}
    src = """def %s(*args, **kwargs):
    _checksig_(*args, **kwargs)
    return mock(*args, **kwargs)""" % name
    exec (src, context)
    funcopy = context[name]
    _setup_func(funcopy, mock)
    return funcopy


def _setup_func(funcopy, mock):
    funcopy.mock = mock

    # can't use isinstance with mocks
    if not _is_instance_mock(mock):
        return

    def assert_called_with(*args, **kwargs):
        return mock.assert_called_with(*args, **kwargs)
    def assert_called_once_with(*args, **kwargs):
        return mock.assert_called_once_with(*args, **kwargs)
    def assert_has_calls(*args, **kwargs):
        return mock.assert_has_calls(*args, **kwargs)
    def assert_any_call(*args, **kwargs):
        return mock.assert_any_call(*args, **kwargs)
    def reset_mock():
        funcopy.method_calls = _CallList()
        funcopy.mock_calls = _CallList()
        mock.reset_mock()
        ret = funcopy.return_value
        if _is_instance_mock(ret) and not ret is mock:
            ret.reset_mock()

    funcopy.called = False
    funcopy.call_count = 0
    funcopy.call_args = None
    funcopy.call_args_list = _CallList()
    funcopy.method_calls = _CallList()
    funcopy.mock_calls = _CallList()

    funcopy.return_value = mock.return_value
    funcopy.side_effect = mock.side_effect
    funcopy._mock_children = mock._mock_children

    funcopy.assert_called_with = assert_called_with
    funcopy.assert_called_once_with = assert_called_once_with
    funcopy.assert_has_calls = assert_has_calls
    funcopy.assert_any_call = assert_any_call
    funcopy.reset_mock = reset_mock

    mock._mock_delegate = funcopy


def _is_magic(name):
    return '__%s__' % name[2:-2] == name


class _SentinelObject(object):
    "A unique, named, sentinel object."
    def __init__(self, name):
        self.name = name

    def __repr__(self):
        return 'sentinel.%s' % self.name


class _Sentinel(object):
    """Access attributes to return a named object, usable as a sentinel."""
    def __init__(self):
        self._sentinels = {}

    def __getattr__(self, name):
        if name == '__bases__':
            # Without this help(mock) raises an exception
            raise AttributeError
        return self._sentinels.setdefault(name, _SentinelObject(name))


sentinel = _Sentinel()

DEFAULT = sentinel.DEFAULT
_missing = sentinel.MISSING
_deleted = sentinel.DELETED


class OldStyleClass:
    pass
ClassType = type(OldStyleClass)


def _copy(value):
    if type(value) in (dict, list, tuple, set):
        return type(value)(value)
    return value


ClassTypes = (type,)
if not inPy3k:
    ClassTypes = (type, ClassType)

_allowed_names = set(
    [
        'return_value', '_mock_return_value', 'side_effect',
        '_mock_side_effect', '_mock_parent', '_mock_new_parent',
        '_mock_name', '_mock_new_name'
    ]
)


def _delegating_property(name):
    _allowed_names.add(name)
    _the_name = '_mock_' + name
    def _get(self, name=name, _the_name=_the_name):
        sig = self._mock_delegate
        if sig is None:
            return getattr(self, _the_name)
        return getattr(sig, name)
    def _set(self, value, name=name, _the_name=_the_name):
        sig = self._mock_delegate
        if sig is None:
            self.__dict__[_the_name] = value
        else:
            setattr(sig, name, value)

    return property(_get, _set)



class _CallList(list):

    def __contains__(self, value):
        if not isinstance(value, list):
            return list.__contains__(self, value)
        len_value = len(value)
        len_self = len(self)
        if len_value > len_self:
            return False

        for i in range(0, len_self - len_value + 1):
            sub_list = self[i:i+len_value]
            if sub_list == value:
                return True
        return False

    def __repr__(self):
        return pprint.pformat(list(self))


def _check_and_set_parent(parent, value, name, new_name):
    if not _is_instance_mock(value):
        return False
    if ((value._mock_name or value._mock_new_name) or
        (value._mock_parent is not None) or
        (value._mock_new_parent is not None)):
        return False

    _parent = parent
    while _parent is not None:
        # setting a mock (value) as a child or return value of itself
        # should not modify the mock
        if _parent is value:
            return False
        _parent = _parent._mock_new_parent

    if new_name:
        value._mock_new_parent = parent
        value._mock_new_name = new_name
    if name:
        value._mock_parent = parent
        value._mock_name = name
    return True



class Base(object):
    _mock_return_value = DEFAULT
    _mock_side_effect = None
    def __init__(self, *args, **kwargs):
        pass



class NonCallableMock(Base):
    """A non-callable version of `Mock`"""

    def __new__(cls, *args, **kw):
        # every instance has its own class
        # so we can create magic methods on the
        # class without stomping on other mocks
        new = type(cls.__name__, (cls,), {'__doc__': cls.__doc__})
        instance = object.__new__(new)
        return instance


    def __init__(
            self, spec=None, wraps=None, name=None, spec_set=None,
            parent=None, _spec_state=None, _new_name='', _new_parent=None,
            **kwargs
        ):
        if _new_parent is None:
            _new_parent = parent

        __dict__ = self.__dict__
        __dict__['_mock_parent'] = parent
        __dict__['_mock_name'] = name
        __dict__['_mock_new_name'] = _new_name
        __dict__['_mock_new_parent'] = _new_parent

        if spec_set is not None:
            spec = spec_set
            spec_set = True

        self._mock_add_spec(spec, spec_set)

        __dict__['_mock_children'] = {}
        __dict__['_mock_wraps'] = wraps
        __dict__['_mock_delegate'] = None

        __dict__['_mock_called'] = False
        __dict__['_mock_call_args'] = None
        __dict__['_mock_call_count'] = 0
        __dict__['_mock_call_args_list'] = _CallList()
        __dict__['_mock_mock_calls'] = _CallList()

        __dict__['method_calls'] = _CallList()

        if kwargs:
            self.configure_mock(**kwargs)

        _super(NonCallableMock, self).__init__(
            spec, wraps, name, spec_set, parent,
            _spec_state
        )


    def attach_mock(self, mock, attribute):
        """
        Attach a mock as an attribute of this one, replacing its name and
        parent. Calls to the attached mock will be recorded in the
        `method_calls` and `mock_calls` attributes of this one."""
        mock._mock_parent = None
        mock._mock_new_parent = None
        mock._mock_name = ''
        mock._mock_new_name = None

        setattr(self, attribute, mock)


    def mock_add_spec(self, spec, spec_set=False):
        """Add a spec to a mock. `spec` can either be an object or a
        list of strings. Only attributes on the `spec` can be fetched as
        attributes from the mock.

        If `spec_set` is True then only attributes on the spec can be set."""
        self._mock_add_spec(spec, spec_set)


    def _mock_add_spec(self, spec, spec_set):
        _spec_class = None

        if spec is not None and not _is_list(spec):
            if isinstance(spec, ClassTypes):
                _spec_class = spec
            else:
                _spec_class = _get_class(spec)

            spec = dir(spec)

        __dict__ = self.__dict__
        __dict__['_spec_class'] = _spec_class
        __dict__['_spec_set'] = spec_set
        __dict__['_mock_methods'] = spec


    def __get_return_value(self):
        ret = self._mock_return_value
        if self._mock_delegate is not None:
            ret = self._mock_delegate.return_value

        if ret is DEFAULT:
            ret = self._get_child_mock(
                _new_parent=self, _new_name='()'
            )
            self.return_value = ret
        return ret


    def __set_return_value(self, value):
        if self._mock_delegate is not None:
            self._mock_delegate.return_value = value
        else:
            self._mock_return_value = value
            _check_and_set_parent(self, value, None, '()')

    __return_value_doc = "The value to be returned when the mock is called."
    return_value = property(__get_return_value, __set_return_value,
                            __return_value_doc)


    @property
    def __class__(self):
        if self._spec_class is None:
            return type(self)
        return self._spec_class

    called = _delegating_property('called')
    call_count = _delegating_property('call_count')
    call_args = _delegating_property('call_args')
    call_args_list = _delegating_property('call_args_list')
    mock_calls = _delegating_property('mock_calls')


    def __get_side_effect(self):
        sig = self._mock_delegate
        if sig is None:
            return self._mock_side_effect
        return sig.side_effect

    def __set_side_effect(self, value):
        value = _try_iter(value)
        sig = self._mock_delegate
        if sig is None:
            self._mock_side_effect = value
        else:
            sig.side_effect = value

    side_effect = property(__get_side_effect, __set_side_effect)


    def reset_mock(self):
        "Restore the mock object to its initial state."
        self.called = False
        self.call_args = None
        self.call_count = 0
        self.mock_calls = _CallList()
        self.call_args_list = _CallList()
        self.method_calls = _CallList()

        for child in self._mock_children.values():
            if isinstance(child, _SpecState):
                continue
            child.reset_mock()

        ret = self._mock_return_value
        if _is_instance_mock(ret) and ret is not self:
            ret.reset_mock()


    def configure_mock(self, **kwargs):
        """Set attributes on the mock through keyword arguments.

        Attributes plus return values and side effects can be set on child
        mocks using standard dot notation and unpacking a dictionary in the
        method call:

        >>> attrs = {'method.return_value': 3, 'other.side_effect': KeyError}
        >>> mock.configure_mock(**attrs)"""
        for arg, val in sorted(kwargs.items(),
                               # we sort on the number of dots so that
                               # attributes are set before we set attributes on
                               # attributes
                               key=lambda entry: entry[0].count('.')):
            args = arg.split('.')
            final = args.pop()
            obj = self
            for entry in args:
                obj = getattr(obj, entry)
            setattr(obj, final, val)


    def __getattr__(self, name):
        if name == '_mock_methods':
            raise AttributeError(name)
        elif self._mock_methods is not None:
            if name not in self._mock_methods or name in _all_magics:
                raise AttributeError("Mock object has no attribute %r" % name)
        elif _is_magic(name):
            raise AttributeError(name)

        result = self._mock_children.get(name)
        if result is _deleted:
            raise AttributeError(name)
        elif result is None:
            wraps = None
            if self._mock_wraps is not None:
                # XXXX should we get the attribute without triggering code
                # execution?
                wraps = getattr(self._mock_wraps, name)

            result = self._get_child_mock(
                parent=self, name=name, wraps=wraps, _new_name=name,
                _new_parent=self
            )
            self._mock_children[name]  = result

        elif isinstance(result, _SpecState):
            result = create_autospec(
                result.spec, result.spec_set, result.instance,
                result.parent, result.name
            )
            self._mock_children[name]  = result

        return result


    def __repr__(self):
        _name_list = [self._mock_new_name]
        _parent = self._mock_new_parent
        last = self

        dot = '.'
        if _name_list == ['()']:
            dot = ''
        seen = set()
        while _parent is not None:
            last = _parent

            _name_list.append(_parent._mock_new_name + dot)
            dot = '.'
            if _parent._mock_new_name == '()':
                dot = ''

            _parent = _parent._mock_new_parent

            # use ids here so as not to call __hash__ on the mocks
            if id(_parent) in seen:
                break
            seen.add(id(_parent))

        _name_list = list(reversed(_name_list))
        _first = last._mock_name or 'mock'
        if len(_name_list) > 1:
            if _name_list[1] not in ('()', '().'):
                _first += '.'
        _name_list[0] = _first
        name = ''.join(_name_list)

        name_string = ''
        if name not in ('mock', 'mock.'):
            name_string = ' name=%r' % name

        spec_string = ''
        if self._spec_class is not None:
            spec_string = ' spec=%r'
            if self._spec_set:
                spec_string = ' spec_set=%r'
            spec_string = spec_string % self._spec_class.__name__
        return "<%s%s%s id='%s'>" % (
            type(self).__name__,
            name_string,
            spec_string,
            id(self)
        )


    def __dir__(self):
        """Filter the output of `dir(mock)` to only useful members.
        XXXX
        """
        extras = self._mock_methods or []
        from_type = dir(type(self))
        from_dict = list(self.__dict__)

        if FILTER_DIR:
            from_type = [e for e in from_type if not e.startswith('_')]
            from_dict = [e for e in from_dict if not e.startswith('_') or
                         _is_magic(e)]
        return sorted(set(extras + from_type + from_dict +
                          list(self._mock_children)))


    def __setattr__(self, name, value):
        if name in _allowed_names:
            # property setters go through here
            return object.__setattr__(self, name, value)
        elif (self._spec_set and self._mock_methods is not None and
            name not in self._mock_methods and
            name not in self.__dict__):
            raise AttributeError("Mock object has no attribute '%s'" % name)
        elif name in _unsupported_magics:
            msg = 'Attempting to set unsupported magic method %r.' % name
            raise AttributeError(msg)
        elif name in _all_magics:
            if self._mock_methods is not None and name not in self._mock_methods:
                raise AttributeError("Mock object has no attribute '%s'" % name)

            if not _is_instance_mock(value):
                setattr(type(self), name, _get_method(name, value))
                original = value
                value = lambda *args, **kw: original(self, *args, **kw)
            else:
                # only set _new_name and not name so that mock_calls is tracked
                # but not method calls
                _check_and_set_parent(self, value, None, name)
                setattr(type(self), name, value)
                self._mock_children[name] = value
        elif name == '__class__':
            self._spec_class = value
            return
        else:
            if _check_and_set_parent(self, value, name, name):
                self._mock_children[name] = value
        return object.__setattr__(self, name, value)


    def __delattr__(self, name):
        if name in _all_magics and name in type(self).__dict__:
            delattr(type(self), name)
            if name not in self.__dict__:
                # for magic methods that are still MagicProxy objects and
                # not set on the instance itself
                return

        if name in self.__dict__:
            object.__delattr__(self, name)

        obj = self._mock_children.get(name, _missing)
        if obj is _deleted:
            raise AttributeError(name)
        if obj is not _missing:
            del self._mock_children[name]
        self._mock_children[name] = _deleted



    def _format_mock_call_signature(self, args, kwargs):
        name = self._mock_name or 'mock'
        return _format_call_signature(name, args, kwargs)


    def _format_mock_failure_message(self, args, kwargs):
        message = 'Expected call: %s\nActual call: %s'
        expected_string = self._format_mock_call_signature(args, kwargs)
        call_args = self.call_args
        if len(call_args) == 3:
            call_args = call_args[1:]
        actual_string = self._format_mock_call_signature(*call_args)
        return message % (expected_string, actual_string)


    def assert_called_with(_mock_self, *args, **kwargs):
        """assert that the mock was called with the specified arguments.

        Raises an AssertionError if the args and keyword args passed in are
        different to the last call to the mock."""
        self = _mock_self
        if self.call_args is None:
            expected = self._format_mock_call_signature(args, kwargs)
            raise AssertionError('Expected call: %s\nNot called' % (expected,))

        if self.call_args != (args, kwargs):
            msg = self._format_mock_failure_message(args, kwargs)
            raise AssertionError(msg)


    def assert_called_once_with(_mock_self, *args, **kwargs):
        """assert that the mock was called exactly once and with the specified
        arguments."""
        self = _mock_self
        if not self.call_count == 1:
            msg = ("Expected to be called once. Called %s times." %
                   self.call_count)
            raise AssertionError(msg)
        return self.assert_called_with(*args, **kwargs)


    def assert_has_calls(self, calls, any_order=False):
        """assert the mock has been called with the specified calls.
        The `mock_calls` list is checked for the calls.

        If `any_order` is False (the default) then the calls must be
        sequential. There can be extra calls before or after the
        specified calls.

        If `any_order` is True then the calls can be in any order, but
        they must all appear in `mock_calls`."""
        if not any_order:
            if calls not in self.mock_calls:
                raise AssertionError(
                    'Calls not found.\nExpected: %r\n'
                    'Actual: %r' % (calls, self.mock_calls)
                )
            return

        all_calls = list(self.mock_calls)

        not_found = []
        for kall in calls:
            try:
                all_calls.remove(kall)
            except ValueError:
                not_found.append(kall)
        if not_found:
            raise AssertionError(
                '%r not all found in call list' % (tuple(not_found),)
            )


    def assert_any_call(self, *args, **kwargs):
        """assert the mock has been called with the specified arguments.

        The assert passes if the mock has *ever* been called, unlike
        `assert_called_with` and `assert_called_once_with` that only pass if
        the call is the most recent one."""
        kall = call(*args, **kwargs)
        if kall not in self.call_args_list:
            expected_string = self._format_mock_call_signature(args, kwargs)
            raise AssertionError(
                '%s call not found' % expected_string
            )


    def _get_child_mock(self, **kw):
        """Create the child mocks for attributes and return value.
        By default child mocks will be the same type as the parent.
        Subclasses of Mock may want to override this to customize the way
        child mocks are made.

        For non-callable mocks the callable variant will be used (rather than
        any custom subclass)."""
        _type = type(self)
        if not issubclass(_type, CallableMixin):
            if issubclass(_type, NonCallableMagicMock):
                klass = MagicMock
            elif issubclass(_type, NonCallableMock) :
                klass = Mock
        else:
            klass = _type.__mro__[1]
        return klass(**kw)



def _try_iter(obj):
    if obj is None:
        return obj
    if _is_exception(obj):
        return obj
    if _callable(obj):
        return obj
    try:
        return iter(obj)
    except TypeError:
        # XXXX backwards compatibility
        # but this will blow up on first call - so maybe we should fail early?
        return obj



class CallableMixin(Base):

    def __init__(self, spec=None, side_effect=None, return_value=DEFAULT,
                 wraps=None, name=None, spec_set=None, parent=None,
                 _spec_state=None, _new_name='', _new_parent=None, **kwargs):
        self.__dict__['_mock_return_value'] = return_value

        _super(CallableMixin, self).__init__(
            spec, wraps, name, spec_set, parent,
            _spec_state, _new_name, _new_parent, **kwargs
        )

        self.side_effect = side_effect


    def _mock_check_sig(self, *args, **kwargs):
        # stub method that can be replaced with one with a specific signature
        pass


    def __call__(_mock_self, *args, **kwargs):
        # can't use self in-case a function / method we are mocking uses self
        # in the signature
        _mock_self._mock_check_sig(*args, **kwargs)
        return _mock_self._mock_call(*args, **kwargs)


    def _mock_call(_mock_self, *args, **kwargs):
        self = _mock_self
        self.called = True
        self.call_count += 1
        self.call_args = _Call((args, kwargs), two=True)
        self.call_args_list.append(_Call((args, kwargs), two=True))

        _new_name = self._mock_new_name
        _new_parent = self._mock_new_parent
        self.mock_calls.append(_Call(('', args, kwargs)))

        seen = set()
        skip_next_dot = _new_name == '()'
        do_method_calls = self._mock_parent is not None
        name = self._mock_name
        while _new_parent is not None:
            this_mock_call = _Call((_new_name, args, kwargs))
            if _new_parent._mock_new_name:
                dot = '.'
                if skip_next_dot:
                    dot = ''

                skip_next_dot = False
                if _new_parent._mock_new_name == '()':
                    skip_next_dot = True

                _new_name = _new_parent._mock_new_name + dot + _new_name

            if do_method_calls:
                if _new_name == name:
                    this_method_call = this_mock_call
                else:
                    this_method_call = _Call((name, args, kwargs))
                _new_parent.method_calls.append(this_method_call)

                do_method_calls = _new_parent._mock_parent is not None
                if do_method_calls:
                    name = _new_parent._mock_name + '.' + name

            _new_parent.mock_calls.append(this_mock_call)
            _new_parent = _new_parent._mock_new_parent

            # use ids here so as not to call __hash__ on the mocks
            _new_parent_id = id(_new_parent)
            if _new_parent_id in seen:
                break
            seen.add(_new_parent_id)

        ret_val = DEFAULT
        effect = self.side_effect
        if effect is not None:
            if _is_exception(effect):
                raise effect

            if not _callable(effect):
                result = next(effect)
                if _is_exception(result):
                    raise result
                return result

            ret_val = effect(*args, **kwargs)
            if ret_val is DEFAULT:
                ret_val = self.return_value

        if (self._mock_wraps is not None and
             self._mock_return_value is DEFAULT):
            return self._mock_wraps(*args, **kwargs)
        if ret_val is DEFAULT:
            ret_val = self.return_value
        return ret_val



class Mock(CallableMixin, NonCallableMock):
    """
    Create a new `Mock` object. `Mock` takes several optional arguments
    that specify the behaviour of the Mock object:

    * `spec`: This can be either a list of strings or an existing object (a
      class or instance) that acts as the specification for the mock object. If
      you pass in an object then a list of strings is formed by calling dir on
      the object (excluding unsupported magic attributes and methods). Accessing
      any attribute not in this list will raise an `AttributeError`.

      If `spec` is an object (rather than a list of strings) then
      `mock.__class__` returns the class of the spec object. This allows mocks
      to pass `isinstance` tests.

    * `spec_set`: A stricter variant of `spec`. If used, attempting to *set*
      or get an attribute on the mock that isn't on the object passed as
      `spec_set` will raise an `AttributeError`.

    * `side_effect`: A function to be called whenever the Mock is called. See
      the `side_effect` attribute. Useful for raising exceptions or
      dynamically changing return values. The function is called with the same
      arguments as the mock, and unless it returns `DEFAULT`, the return
      value of this function is used as the return value.

      Alternatively `side_effect` can be an exception class or instance. In
      this case the exception will be raised when the mock is called.

      If `side_effect` is an iterable then each call to the mock will return
      the next value from the iterable. If any of the members of the iterable
      are exceptions they will be raised instead of returned.

    * `return_value`: The value returned when the mock is called. By default
      this is a new Mock (created on first access). See the
      `return_value` attribute.

    * `wraps`: Item for the mock object to wrap. If `wraps` is not None then
      calling the Mock will pass the call through to the wrapped object
      (returning the real result). Attribute access on the mock will return a
      Mock object that wraps the corresponding attribute of the wrapped object
      (so attempting to access an attribute that doesn't exist will raise an
      `AttributeError`).

      If the mock has an explicit `return_value` set then calls are not passed
      to the wrapped object and the `return_value` is returned instead.

    * `name`: If the mock has a name then it will be used in the repr of the
      mock. This can be useful for debugging. The name is propagated to child
      mocks.

    Mocks can also be called with arbitrary keyword arguments. These will be
    used to set attributes on the mock after it is created.
    """



def _dot_lookup(thing, comp, import_path):
    try:
        return getattr(thing, comp)
    except AttributeError:
        __import__(import_path)
        return getattr(thing, comp)


def _importer(target):
    components = target.split('.')
    import_path = components.pop(0)
    thing = __import__(import_path)

    for comp in components:
        import_path += ".%s" % comp
        thing = _dot_lookup(thing, comp, import_path)
    return thing


def _is_started(patcher):
    # XXXX horrible
    return hasattr(patcher, 'is_local')


class _patch(object):

    attribute_name = None
    _active_patches = set()

    def __init__(
            self, getter, attribute, new, spec, create,
            spec_set, autospec, new_callable, kwargs
        ):
        if new_callable is not None:
            if new is not DEFAULT:
                raise ValueError(
                    "Cannot use 'new' and 'new_callable' together"
                )
            if autospec is not None:
                raise ValueError(
                    "Cannot use 'autospec' and 'new_callable' together"
                )

        self.getter = getter
        self.attribute = attribute
        self.new = new
        self.new_callable = new_callable
        self.spec = spec
        self.create = create
        self.has_local = False
        self.spec_set = spec_set
        self.autospec = autospec
        self.kwargs = kwargs
        self.additional_patchers = []


    def copy(self):
        patcher = _patch(
            self.getter, self.attribute, self.new, self.spec,
            self.create, self.spec_set,
            self.autospec, self.new_callable, self.kwargs
        )
        patcher.attribute_name = self.attribute_name
        patcher.additional_patchers = [
            p.copy() for p in self.additional_patchers
        ]
        return patcher


    def __call__(self, func):
        if isinstance(func, ClassTypes):
            return self.decorate_class(func)
        return self.decorate_callable(func)


    def decorate_class(self, klass):
        for attr in dir(klass):
            if not attr.startswith(patch.TEST_PREFIX):
                continue

            attr_value = getattr(klass, attr)
            if not hasattr(attr_value, "__call__"):
                continue

            patcher = self.copy()
            setattr(klass, attr, patcher(attr_value))
        return klass


    def decorate_callable(self, func):
        if hasattr(func, 'patchings'):
            func.patchings.append(self)
            return func

        @wraps(func)
        def patched(*args, **keywargs):
            # don't use a with here (backwards compatability with Python 2.4)
            extra_args = []
            entered_patchers = []

            # can't use try...except...finally because of Python 2.4
            # compatibility
            exc_info = tuple()
            try:
                try:
                    for patching in patched.patchings:
                        arg = patching.__enter__()
                        entered_patchers.append(patching)
                        if patching.attribute_name is not None:
                            keywargs.update(arg)
                        elif patching.new is DEFAULT:
                            extra_args.append(arg)

                    args += tuple(extra_args)
                    return func(*args, **keywargs)
                except:
                    if (patching not in entered_patchers and
                        _is_started(patching)):
                        # the patcher may have been started, but an exception
                        # raised whilst entering one of its additional_patchers
                        entered_patchers.append(patching)
                    # Pass the exception to __exit__
                    exc_info = sys.exc_info()
                    # re-raise the exception
                    raise
            finally:
                for patching in reversed(entered_patchers):
                    patching.__exit__(*exc_info)

        patched.patchings = [self]
        if hasattr(func, 'func_code'):
            # not in Python 3
            patched.compat_co_firstlineno = getattr(
                func, "compat_co_firstlineno",
                func.func_code.co_firstlineno
            )
        return patched


    def get_original(self):
        target = self.getter()
        name = self.attribute

        original = DEFAULT
        local = False

        try:
            original = target.__dict__[name]
        except (AttributeError, KeyError):
            original = getattr(target, name, DEFAULT)
        else:
            local = True

        if not self.create and original is DEFAULT:
            raise AttributeError(
                "%s does not have the attribute %r" % (target, name)
            )
        return original, local


    def __enter__(self):
        """Perform the patch."""
        new, spec, spec_set = self.new, self.spec, self.spec_set
        autospec, kwargs = self.autospec, self.kwargs
        new_callable = self.new_callable
        self.target = self.getter()

        # normalise False to None
        if spec is False:
            spec = None
        if spec_set is False:
            spec_set = None
        if autospec is False:
            autospec = None

        if spec is not None and autospec is not None:
            raise TypeError("Can't specify spec and autospec")
        if ((spec is not None or autospec is not None) and
            spec_set not in (True, None)):
            raise TypeError("Can't provide explicit spec_set *and* spec or autospec")

        original, local = self.get_original()

        if new is DEFAULT and autospec is None:
            inherit = False
            if spec is True:
                # set spec to the object we are replacing
                spec = original
                if spec_set is True:
                    spec_set = original
                    spec = None
            elif spec is not None:
                if spec_set is True:
                    spec_set = spec
                    spec = None
            elif spec_set is True:
                spec_set = original

            if spec is not None or spec_set is not None:
                if original is DEFAULT:
                    raise TypeError("Can't use 'spec' with create=True")
                if isinstance(original, ClassTypes):
                    # If we're patching out a class and there is a spec
                    inherit = True

            Klass = MagicMock
            _kwargs = {}
            if new_callable is not None:
                Klass = new_callable
            elif spec is not None or spec_set is not None:
                this_spec = spec
                if spec_set is not None:
                    this_spec = spec_set
                if _is_list(this_spec):
                    not_callable = '__call__' not in this_spec
                else:
                    not_callable = not _callable(this_spec)
                if not_callable:
                    Klass = NonCallableMagicMock

            if spec is not None:
                _kwargs['spec'] = spec
            if spec_set is not None:
                _kwargs['spec_set'] = spec_set

            # add a name to mocks
            if (isinstance(Klass, type) and
                issubclass(Klass, NonCallableMock) and self.attribute):
                _kwargs['name'] = self.attribute

            _kwargs.update(kwargs)
            new = Klass(**_kwargs)

            if inherit and _is_instance_mock(new):
                # we can only tell if the instance should be callable if the
                # spec is not a list
                this_spec = spec
                if spec_set is not None:
                    this_spec = spec_set
                if (not _is_list(this_spec) and not
                    _instance_callable(this_spec)):
                    Klass = NonCallableMagicMock

                _kwargs.pop('name')
                new.return_value = Klass(_new_parent=new, _new_name='()',
                                         **_kwargs)
        elif autospec is not None:
            # spec is ignored, new *must* be default, spec_set is treated
            # as a boolean. Should we check spec is not None and that spec_set
            # is a bool?
            if new is not DEFAULT:
                raise TypeError(
                    "autospec creates the mock for you. Can't specify "
                    "autospec and new."
                )
            if original is DEFAULT:
                raise TypeError("Can't use 'autospec' with create=True")
            spec_set = bool(spec_set)
            if autospec is True:
                autospec = original

            new = create_autospec(autospec, spec_set=spec_set,
                                  _name=self.attribute, **kwargs)
        elif kwargs:
            # can't set keyword args when we aren't creating the mock
            # XXXX If new is a Mock we could call new.configure_mock(**kwargs)
            raise TypeError("Can't pass kwargs to a mock we aren't creating")

        new_attr = new

        self.temp_original = original
        self.is_local = local
        setattr(self.target, self.attribute, new_attr)
        if self.attribute_name is not None:
            extra_args = {}
            if self.new is DEFAULT:
                extra_args[self.attribute_name] =  new
            for patching in self.additional_patchers:
                arg = patching.__enter__()
                if patching.new is DEFAULT:
                    extra_args.update(arg)
            return extra_args

        return new


    def __exit__(self, *exc_info):
        """Undo the patch."""
        if not _is_started(self):
            raise RuntimeError('stop called on unstarted patcher')

        if self.is_local and self.temp_original is not DEFAULT:
            setattr(self.target, self.attribute, self.temp_original)
        else:
            delattr(self.target, self.attribute)
            if not self.create and not hasattr(self.target, self.attribute):
                # needed for proxy objects like django settings
                setattr(self.target, self.attribute, self.temp_original)

        del self.temp_original
        del self.is_local
        del self.target
        for patcher in reversed(self.additional_patchers):
            if _is_started(patcher):
                patcher.__exit__(*exc_info)


    def start(self):
        """Activate a patch, returning any created mock."""
        result = self.__enter__()
        self._active_patches.add(self)
        return result


    def stop(self):
        """Stop an active patch."""
        self._active_patches.discard(self)
        return self.__exit__()



def _get_target(target):
    try:
        target, attribute = target.rsplit('.', 1)
    except (TypeError, ValueError):
        raise TypeError("Need a valid target to patch. You supplied: %r" %
                        (target,))
    getter = lambda: _importer(target)
    return getter, attribute


def _patch_object(
        target, attribute, new=DEFAULT, spec=None,
        create=False, spec_set=None, autospec=None,
        new_callable=None, **kwargs
    ):
    """
    patch.object(target, attribute, new=DEFAULT, spec=None, create=False,
                 spec_set=None, autospec=None, new_callable=None, **kwargs)

    patch the named member (`attribute`) on an object (`target`) with a mock
    object.

    `patch.object` can be used as a decorator, class decorator or a context
    manager. Arguments `new`, `spec`, `create`, `spec_set`,
    `autospec` and `new_callable` have the same meaning as for `patch`. Like
    `patch`, `patch.object` takes arbitrary keyword arguments for configuring
    the mock object it creates.

    When used as a class decorator `patch.object` honours `patch.TEST_PREFIX`
    for choosing which methods to wrap.
    """
    getter = lambda: target
    return _patch(
        getter, attribute, new, spec, create,
        spec_set, autospec, new_callable, kwargs
    )


def _patch_multiple(target, spec=None, create=False, spec_set=None,
                    autospec=None, new_callable=None, **kwargs):
    """Perform multiple patches in a single call. It takes the object to be
    patched (either as an object or a string to fetch the object by importing)
    and keyword arguments for the patches::

        with patch.multiple(settings, FIRST_PATCH='one', SECOND_PATCH='two'):
            ...

    Use `DEFAULT` as the value if you want `patch.multiple` to create
    mocks for you. In this case the created mocks are passed into a decorated
    function by keyword, and a dictionary is returned when `patch.multiple` is
    used as a context manager.

    `patch.multiple` can be used as a decorator, class decorator or a context
    manager. The arguments `spec`, `spec_set`, `create`,
    `autospec` and `new_callable` have the same meaning as for `patch`. These
    arguments will be applied to *all* patches done by `patch.multiple`.

    When used as a class decorator `patch.multiple` honours `patch.TEST_PREFIX`
    for choosing which methods to wrap.
    """
    if type(target) in (unicode, str):
        getter = lambda: _importer(target)
    else:
        getter = lambda: target

    if not kwargs:
        raise ValueError(
            'Must supply at least one keyword argument with patch.multiple'
        )
    # need to wrap in a list for python 3, where items is a view
    items = list(kwargs.items())
    attribute, new = items[0]
    patcher = _patch(
        getter, attribute, new, spec, create, spec_set,
        autospec, new_callable, {}
    )
    patcher.attribute_name = attribute
    for attribute, new in items[1:]:
        this_patcher = _patch(
            getter, attribute, new, spec, create, spec_set,
            autospec, new_callable, {}
        )
        this_patcher.attribute_name = attribute
        patcher.additional_patchers.append(this_patcher)
    return patcher


def patch(
        target, new=DEFAULT, spec=None, create=False,
        spec_set=None, autospec=None, new_callable=None, **kwargs
    ):
    """
    `patch` acts as a function decorator, class decorator or a context
    manager. Inside the body of the function or with statement, the `target`
    is patched with a `new` object. When the function/with statement exits
    the patch is undone.

    If `new` is omitted, then the target is replaced with a
    `MagicMock`. If `patch` is used as a decorator and `new` is
    omitted, the created mock is passed in as an extra argument to the
    decorated function. If `patch` is used as a context manager the created
    mock is returned by the context manager.

    `target` should be a string in the form `'package.module.ClassName'`. The
    `target` is imported and the specified object replaced with the `new`
    object, so the `target` must be importable from the environment you are
    calling `patch` from. The target is imported when the decorated function
    is executed, not at decoration time.

    The `spec` and `spec_set` keyword arguments are passed to the `MagicMock`
    if patch is creating one for you.

    In addition you can pass `spec=True` or `spec_set=True`, which causes
    patch to pass in the object being mocked as the spec/spec_set object.

    `new_callable` allows you to specify a different class, or callable object,
    that will be called to create the `new` object. By default `MagicMock` is
    used.

    A more powerful form of `spec` is `autospec`. If you set `autospec=True`
    then the mock with be created with a spec from the object being replaced.
    All attributes of the mock will also have the spec of the corresponding
    attribute of the object being replaced. Methods and functions being
    mocked will have their arguments checked and will raise a `TypeError` if
    they are called with the wrong signature. For mocks replacing a class,
    their return value (the 'instance') will have the same spec as the class.

    Instead of `autospec=True` you can pass `autospec=some_object` to use an
    arbitrary object as the spec instead of the one being replaced.

    By default `patch` will fail to replace attributes that don't exist. If
    you pass in `create=True`, and the attribute doesn't exist, patch will
    create the attribute for you when the patched function is called, and
    delete it again afterwards. This is useful for writing tests against
    attributes that your production code creates at runtime. It is off by by
    default because it can be dangerous. With it switched on you can write
    passing tests against APIs that don't actually exist!

    Patch can be used as a `TestCase` class decorator. It works by
    decorating each test method in the class. This reduces the boilerplate
    code when your test methods share a common patchings set. `patch` finds
    tests by looking for method names that start with `patch.TEST_PREFIX`.
    By default this is `test`, which matches the way `unittest` finds tests.
    You can specify an alternative prefix by setting `patch.TEST_PREFIX`.

    Patch can be used as a context manager, with the with statement. Here the
    patching applies to the indented block after the with statement. If you
    use "as" then the patched object will be bound to the name after the
    "as"; very useful if `patch` is creating a mock object for you.

    `patch` takes arbitrary keyword arguments. These will be passed to
    the `Mock` (or `new_callable`) on construction.

    `patch.dict(...)`, `patch.multiple(...)` and `patch.object(...)` are
    available for alternate use-cases.
    """
    getter, attribute = _get_target(target)
    return _patch(
        getter, attribute, new, spec, create,
        spec_set, autospec, new_callable, kwargs
    )


class _patch_dict(object):
    """
    Patch a dictionary, or dictionary like object, and restore the dictionary
    to its original state after the test.

    `in_dict` can be a dictionary or a mapping like container. If it is a
    mapping then it must at least support getting, setting and deleting items
    plus iterating over keys.

    `in_dict` can also be a string specifying the name of the dictionary, which
    will then be fetched by importing it.

    `values` can be a dictionary of values to set in the dictionary. `values`
    can also be an iterable of `(key, value)` pairs.

    If `clear` is True then the dictionary will be cleared before the new
    values are set.

    `patch.dict` can also be called with arbitrary keyword arguments to set
    values in the dictionary::

        with patch.dict('sys.modules', mymodule=Mock(), other_module=Mock()):
            ...

    `patch.dict` can be used as a context manager, decorator or class
    decorator. When used as a class decorator `patch.dict` honours
    `patch.TEST_PREFIX` for choosing which methods to wrap.
    """

    def __init__(self, in_dict, values=(), clear=False, **kwargs):
        if isinstance(in_dict, basestring):
            in_dict = _importer(in_dict)
        self.in_dict = in_dict
        # support any argument supported by dict(...) constructor
        self.values = dict(values)
        self.values.update(kwargs)
        self.clear = clear
        self._original = None


    def __call__(self, f):
        if isinstance(f, ClassTypes):
            return self.decorate_class(f)
        @wraps(f)
        def _inner(*args, **kw):
            self._patch_dict()
            try:
                return f(*args, **kw)
            finally:
                self._unpatch_dict()

        return _inner


    def decorate_class(self, klass):
        for attr in dir(klass):
            attr_value = getattr(klass, attr)
            if (attr.startswith(patch.TEST_PREFIX) and
                 hasattr(attr_value, "__call__")):
                decorator = _patch_dict(self.in_dict, self.values, self.clear)
                decorated = decorator(attr_value)
                setattr(klass, attr, decorated)
        return klass


    def __enter__(self):
        """Patch the dict."""
        self._patch_dict()


    def _patch_dict(self):
        values = self.values
        in_dict = self.in_dict
        clear = self.clear

        try:
            original = in_dict.copy()
        except AttributeError:
            # dict like object with no copy method
            # must support iteration over keys
            original = {}
            for key in in_dict:
                original[key] = in_dict[key]
        self._original = original

        if clear:
            _clear_dict(in_dict)

        try:
            in_dict.update(values)
        except AttributeError:
            # dict like object with no update method
            for key in values:
                in_dict[key] = values[key]


    def _unpatch_dict(self):
        in_dict = self.in_dict
        original = self._original

        _clear_dict(in_dict)

        try:
            in_dict.update(original)
        except AttributeError:
            for key in original:
                in_dict[key] = original[key]


    def __exit__(self, *args):
        """Unpatch the dict."""
        self._unpatch_dict()
        return False

    start = __enter__
    stop = __exit__


def _clear_dict(in_dict):
    try:
        in_dict.clear()
    except AttributeError:
        keys = list(in_dict)
        for key in keys:
            del in_dict[key]


def _patch_stopall():
    """Stop all active patches."""
    for patch in list(_patch._active_patches):
        patch.stop()


patch.object = _patch_object
patch.dict = _patch_dict
patch.multiple = _patch_multiple
patch.stopall = _patch_stopall
patch.TEST_PREFIX = 'test'

magic_methods = (
    "lt le gt ge eq ne "
    "getitem setitem delitem "
    "len contains iter "
    "hash str sizeof "
    "enter exit "
    "divmod neg pos abs invert "
    "complex int float index "
    "trunc floor ceil "
)

numerics = "add sub mul div floordiv mod lshift rshift and xor or pow "
inplace = ' '.join('i%s' % n for n in numerics.split())
right = ' '.join('r%s' % n for n in numerics.split())
extra = ''
if inPy3k:
    extra = 'bool next '
else:
    extra = 'unicode long nonzero oct hex truediv rtruediv '

# not including __prepare__, __instancecheck__, __subclasscheck__
# (as they are metaclass methods)
# __del__ is not supported at all as it causes problems if it exists

_non_defaults = set('__%s__' % method for method in [
    'cmp', 'getslice', 'setslice', 'coerce', 'subclasses',
    'format', 'get', 'set', 'delete', 'reversed',
    'missing', 'reduce', 'reduce_ex', 'getinitargs',
    'getnewargs', 'getstate', 'setstate', 'getformat',
    'setformat', 'repr', 'dir'
])


def _get_method(name, func):
    "Turns a callable object (like a mock) into a real function"
    def method(self, *args, **kw):
        return func(self, *args, **kw)
    method.__name__ = name
    return method


_magics = set(
    '__%s__' % method for method in
    ' '.join([magic_methods, numerics, inplace, right, extra]).split()
)

_all_magics = _magics | _non_defaults

_unsupported_magics = set([
    '__getattr__', '__setattr__',
    '__init__', '__new__', '__prepare__'
    '__instancecheck__', '__subclasscheck__',
    '__del__'
])

_calculate_return_value = {
    '__hash__': lambda self: object.__hash__(self),
    '__str__': lambda self: object.__str__(self),
    '__sizeof__': lambda self: object.__sizeof__(self),
    '__unicode__': lambda self: unicode(object.__str__(self)),
}

_return_values = {
    '__lt__': NotImplemented,
    '__gt__': NotImplemented,
    '__le__': NotImplemented,
    '__ge__': NotImplemented,
    '__int__': 1,
    '__contains__': False,
    '__len__': 0,
    '__exit__': False,
    '__complex__': 1j,
    '__float__': 1.0,
    '__bool__': True,
    '__nonzero__': True,
    '__oct__': '1',
    '__hex__': '0x1',
    '__long__': long(1),
    '__index__': 1,
}


def _get_eq(self):
    def __eq__(other):
        ret_val = self.__eq__._mock_return_value
        if ret_val is not DEFAULT:
            return ret_val
        return self is other
    return __eq__

def _get_ne(self):
    def __ne__(other):
        if self.__ne__._mock_return_value is not DEFAULT:
            return DEFAULT
        return self is not other
    return __ne__

def _get_iter(self):
    def __iter__():
        ret_val = self.__iter__._mock_return_value
        if ret_val is DEFAULT:
            return iter([])
        # if ret_val was already an iterator, then calling iter on it should
        # return the iterator unchanged
        return iter(ret_val)
    return __iter__

_side_effect_methods = {
    '__eq__': _get_eq,
    '__ne__': _get_ne,
    '__iter__': _get_iter,
}



def _set_return_value(mock, method, name):
    fixed = _return_values.get(name, DEFAULT)
    if fixed is not DEFAULT:
        method.return_value = fixed
        return

    return_calulator = _calculate_return_value.get(name)
    if return_calulator is not None:
        try:
            return_value = return_calulator(mock)
        except AttributeError:
            # XXXX why do we return AttributeError here?
            #      set it as a side_effect instead?
            return_value = AttributeError(name)
        method.return_value = return_value
        return

    side_effector = _side_effect_methods.get(name)
    if side_effector is not None:
        method.side_effect = side_effector(mock)



class MagicMixin(object):
    def __init__(self, *args, **kw):
        _super(MagicMixin, self).__init__(*args, **kw)
        self._mock_set_magics()


    def _mock_set_magics(self):
        these_magics = _magics

        if self._mock_methods is not None:
            these_magics = _magics.intersection(self._mock_methods)

            remove_magics = set()
            remove_magics = _magics - these_magics

            for entry in remove_magics:
                if entry in type(self).__dict__:
                    # remove unneeded magic methods
                    delattr(self, entry)

        # don't overwrite existing attributes if called a second time
        these_magics = these_magics - set(type(self).__dict__)

        _type = type(self)
        for entry in these_magics:
            setattr(_type, entry, MagicProxy(entry, self))



class NonCallableMagicMock(MagicMixin, NonCallableMock):
    """A version of `MagicMock` that isn't callable."""
    def mock_add_spec(self, spec, spec_set=False):
        """Add a spec to a mock. `spec` can either be an object or a
        list of strings. Only attributes on the `spec` can be fetched as
        attributes from the mock.

        If `spec_set` is True then only attributes on the spec can be set."""
        self._mock_add_spec(spec, spec_set)
        self._mock_set_magics()



class MagicMock(MagicMixin, Mock):
    """
    MagicMock is a subclass of Mock with default implementations
    of most of the magic methods. You can use MagicMock without having to
    configure the magic methods yourself.

    If you use the `spec` or `spec_set` arguments then *only* magic
    methods that exist in the spec will be created.

    Attributes and the return value of a `MagicMock` will also be `MagicMocks`.
    """
    def mock_add_spec(self, spec, spec_set=False):
        """Add a spec to a mock. `spec` can either be an object or a
        list of strings. Only attributes on the `spec` can be fetched as
        attributes from the mock.

        If `spec_set` is True then only attributes on the spec can be set."""
        self._mock_add_spec(spec, spec_set)
        self._mock_set_magics()



class MagicProxy(object):
    def __init__(self, name, parent):
        self.name = name
        self.parent = parent

    def __call__(self, *args, **kwargs):
        m = self.create_mock()
        return m(*args, **kwargs)

    def create_mock(self):
        entry = self.name
        parent = self.parent
        m = parent._get_child_mock(name=entry, _new_name=entry,
                                   _new_parent=parent)
        setattr(parent, entry, m)
        _set_return_value(parent, m, entry)
        return m

    def __get__(self, obj, _type=None):
        return self.create_mock()



class _ANY(object):
    "A helper object that compares equal to everything."

    def __eq__(self, other):
        return True

    def __ne__(self, other):
        return False

    def __repr__(self):
        return '<ANY>'

ANY = _ANY()



def _format_call_signature(name, args, kwargs):
    message = '%s(%%s)' % name
    formatted_args = ''
    args_string = ', '.join([repr(arg) for arg in args])
    kwargs_string = ', '.join([
        '%s=%r' % (key, value) for key, value in kwargs.items()
    ])
    if args_string:
        formatted_args = args_string
    if kwargs_string:
        if formatted_args:
            formatted_args += ', '
        formatted_args += kwargs_string

    return message % formatted_args



class _Call(tuple):
    """
    A tuple for holding the results of a call to a mock, either in the form
    `(args, kwargs)` or `(name, args, kwargs)`.

    If args or kwargs are empty then a call tuple will compare equal to
    a tuple without those values. This makes comparisons less verbose::

        _Call(('name', (), {})) == ('name',)
        _Call(('name', (1,), {})) == ('name', (1,))
        _Call(((), {'a': 'b'})) == ({'a': 'b'},)

    The `_Call` object provides a useful shortcut for comparing with call::

        _Call(((1, 2), {'a': 3})) == call(1, 2, a=3)
        _Call(('foo', (1, 2), {'a': 3})) == call.foo(1, 2, a=3)

    If the _Call has no name then it will match any name.
    """
    def __new__(cls, value=(), name=None, parent=None, two=False,
                from_kall=True):
        name = ''
        args = ()
        kwargs = {}
        _len = len(value)
        if _len == 3:
            name, args, kwargs = value
        elif _len == 2:
            first, second = value
            if isinstance(first, basestring):
                name = first
                if isinstance(second, tuple):
                    args = second
                else:
                    kwargs = second
            else:
                args, kwargs = first, second
        elif _len == 1:
            value, = value
            if isinstance(value, basestring):
                name = value
            elif isinstance(value, tuple):
                args = value
            else:
                kwargs = value

        if two:
            return tuple.__new__(cls, (args, kwargs))

        return tuple.__new__(cls, (name, args, kwargs))


    def __init__(self, value=(), name=None, parent=None, two=False,
                 from_kall=True):
        self.name = name
        self.parent = parent
        self.from_kall = from_kall


    def __eq__(self, other):
        if other is ANY:
            return True
        try:
            len_other = len(other)
        except TypeError:
            return False

        self_name = ''
        if len(self) == 2:
            self_args, self_kwargs = self
        else:
            self_name, self_args, self_kwargs = self

        other_name = ''
        if len_other == 0:
            other_args, other_kwargs = (), {}
        elif len_other == 3:
            other_name, other_args, other_kwargs = other
        elif len_other == 1:
            value, = other
            if isinstance(value, tuple):
                other_args = value
                other_kwargs = {}
            elif isinstance(value, basestring):
                other_name = value
                other_args, other_kwargs = (), {}
            else:
                other_args = ()
                other_kwargs = value
        else:
            # len 2
            # could be (name, args) or (name, kwargs) or (args, kwargs)
            first, second = other
            if isinstance(first, basestring):
                other_name = first
                if isinstance(second, tuple):
                    other_args, other_kwargs = second, {}
                else:
                    other_args, other_kwargs = (), second
            else:
                other_args, other_kwargs = first, second

        if self_name and other_name != self_name:
            return False

        # this order is important for ANY to work!
        return (other_args, other_kwargs) == (self_args, self_kwargs)


    def __ne__(self, other):
        return not self.__eq__(other)


    def __call__(self, *args, **kwargs):
        if self.name is None:
            return _Call(('', args, kwargs), name='()')

        name = self.name + '()'
        return _Call((self.name, args, kwargs), name=name, parent=self)


    def __getattr__(self, attr):
        if self.name is None:
            return _Call(name=attr, from_kall=False)
        name = '%s.%s' % (self.name, attr)
        return _Call(name=name, parent=self, from_kall=False)


    def __repr__(self):
        if not self.from_kall:
            name = self.name or 'call'
            if name.startswith('()'):
                name = 'call%s' % name
            return name

        if len(self) == 2:
            name = 'call'
            args, kwargs = self
        else:
            name, args, kwargs = self
            if not name:
                name = 'call'
            elif not name.startswith('()'):
                name = 'call.%s' % name
            else:
                name = 'call%s' % name
        return _format_call_signature(name, args, kwargs)


    def call_list(self):
        """For a call object that represents multiple calls, `call_list`
        returns a list of all the intermediate calls as well as the
        final call."""
        vals = []
        thing = self
        while thing is not None:
            if thing.from_kall:
                vals.append(thing)
            thing = thing.parent
        return _CallList(reversed(vals))


call = _Call(from_kall=False)



def create_autospec(spec, spec_set=False, instance=False, _parent=None,
                    _name=None, **kwargs):
    """Create a mock object using another object as a spec. Attributes on the
    mock will use the corresponding attribute on the `spec` object as their
    spec.

    Functions or methods being mocked will have their arguments checked
    to check that they are called with the correct signature.

    If `spec_set` is True then attempting to set attributes that don't exist
    on the spec object will raise an `AttributeError`.

    If a class is used as a spec then the return value of the mock (the
    instance of the class) will have the same spec. You can use a class as the
    spec for an instance object by passing `instance=True`. The returned mock
    will only be callable if instances of the mock are callable.

    `create_autospec` also takes arbitrary keyword arguments that are passed to
    the constructor of the created mock."""
    if _is_list(spec):
        # can't pass a list instance to the mock constructor as it will be
        # interpreted as a list of strings
        spec = type(spec)

    is_type = isinstance(spec, ClassTypes)

    _kwargs = {'spec': spec}
    if spec_set:
        _kwargs = {'spec_set': spec}
    elif spec is None:
        # None we mock with a normal mock without a spec
        _kwargs = {}

    _kwargs.update(kwargs)

    Klass = MagicMock
    if type(spec) in DescriptorTypes:
        # descriptors don't have a spec
        # because we don't know what type they return
        _kwargs = {}
    elif not _callable(spec):
        Klass = NonCallableMagicMock
    elif is_type and instance and not _instance_callable(spec):
        Klass = NonCallableMagicMock

    _new_name = _name
    if _parent is None:
        # for a top level object no _new_name should be set
        _new_name = ''

    mock = Klass(parent=_parent, _new_parent=_parent, _new_name=_new_name,
                 name=_name, **_kwargs)

    if isinstance(spec, FunctionTypes):
        # should only happen at the top level because we don't
        # recurse for functions
        mock = _set_signature(mock, spec)
    else:
        _check_signature(spec, mock, is_type, instance)

    if _parent is not None and not instance:
        _parent._mock_children[_name] = mock

    if is_type and not instance and 'return_value' not in kwargs:
        mock.return_value = create_autospec(spec, spec_set, instance=True,
                                            _name='()', _parent=mock)

    for entry in dir(spec):
        if _is_magic(entry):
            # MagicMock already does the useful magic methods for us
            continue

        if isinstance(spec, FunctionTypes) and entry in FunctionAttributes:
            # allow a mock to actually be a function
            continue

        # XXXX do we need a better way of getting attributes without
        # triggering code execution (?) Probably not - we need the actual
        # object to mock it so we would rather trigger a property than mock
        # the property descriptor. Likewise we want to mock out dynamically
        # provided attributes.
        # XXXX what about attributes that raise exceptions other than
        # AttributeError on being fetched?
        # we could be resilient against it, or catch and propagate the
        # exception when the attribute is fetched from the mock
        try:
            original = getattr(spec, entry)
        except AttributeError:
            continue

        kwargs = {'spec': original}
        if spec_set:
            kwargs = {'spec_set': original}

        if not isinstance(original, FunctionTypes):
            new = _SpecState(original, spec_set, mock, entry, instance)
            mock._mock_children[entry] = new
        else:
            parent = mock
            if isinstance(spec, FunctionTypes):
                parent = mock.mock

            new = MagicMock(parent=parent, name=entry, _new_name=entry,
                            _new_parent=parent, **kwargs)
            mock._mock_children[entry] = new
            skipfirst = _must_skip(spec, entry, is_type)
            _check_signature(original, new, skipfirst=skipfirst)

        # so functions created with _set_signature become instance attributes,
        # *plus* their underlying mock exists in _mock_children of the parent
        # mock. Adding to _mock_children may be unnecessary where we are also
        # setting as an instance attribute?
        if isinstance(new, FunctionTypes):
            setattr(mock, entry, new)

    return mock


def _must_skip(spec, entry, is_type):
    if not isinstance(spec, ClassTypes):
        if entry in getattr(spec, '__dict__', {}):
            # instance attribute - shouldn't skip
            return False
        spec = spec.__class__
    if not hasattr(spec, '__mro__'):
        # old style class: can't have descriptors anyway
        return is_type

    for klass in spec.__mro__:
        result = klass.__dict__.get(entry, DEFAULT)
        if result is DEFAULT:
            continue
        if isinstance(result, (staticmethod, classmethod)):
            return False
        return is_type

    # shouldn't get here unless function is a dynamically provided attribute
    # XXXX untested behaviour
    return is_type


def _get_class(obj):
    try:
        return obj.__class__
    except AttributeError:
        # in Python 2, _sre.SRE_Pattern objects have no __class__
        return type(obj)


class _SpecState(object):

    def __init__(self, spec, spec_set=False, parent=None,
                 name=None, ids=None, instance=False):
        self.spec = spec
        self.ids = ids
        self.spec_set = spec_set
        self.parent = parent
        self.instance = instance
        self.name = name


FunctionTypes = (
    # python function
    type(create_autospec),
    # instance method
    type(ANY.__eq__),
    # unbound method
    type(_ANY.__eq__),
)

FunctionAttributes = set([
    'func_closure',
    'func_code',
    'func_defaults',
    'func_dict',
    'func_doc',
    'func_globals',
    'func_name',
])


file_spec = None


def mock_open(mock=None, read_data=''):
    """
    A helper function to create a mock to replace the use of `open`. It works
    for `open` called directly or used as a context manager.

    The `mock` argument is the mock object to configure. If `None` (the
    default) then a `MagicMock` will be created for you, with the API limited
    to methods or attributes available on standard file handles.

    `read_data` is a string for the `read` method of the file handle to return.
    This is an empty string by default.
    """
    global file_spec
    if file_spec is None:
        # set on first use
        if inPy3k:
            import _io
            file_spec = list(set(dir(_io.TextIOWrapper)).union(set(dir(_io.BytesIO))))
        else:
            file_spec = file

    if mock is None:
        mock = MagicMock(name='open', spec=open)

    handle = MagicMock(spec=file_spec)
    handle.write.return_value = None
    handle.__enter__.return_value = handle
    handle.read.return_value = read_data

    mock.return_value = handle
    return mock


class PropertyMock(Mock):
    """
    A mock intended to be used as a property, or other descriptor, on a class.
    `PropertyMock` provides `__get__` and `__set__` methods so you can specify
    a return value when it is fetched.

    Fetching a `PropertyMock` instance from an object calls the mock, with
    no args. Setting it calls the mock with the value being set.
    """
    def _get_child_mock(self, **kwargs):
        return MagicMock(**kwargs)

    def __get__(self, obj, obj_type):
        return self()
    def __set__(self, obj, val):
        self(val)
