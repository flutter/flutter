#
#  Cython - Compilation-wide options and pragma declarations
#

# Perform lookups on builtin names only once, at module initialisation
# time.  This will prevent the module from getting imported if a
# builtin name that it uses cannot be found during initialisation.
cache_builtins = True

embed_pos_in_docstring = False
gcc_branch_hints = True

pre_import = None
docstrings = True

# Decref global variables in this module on exit for garbage collection.
# 0: None, 1+: interned objects, 2+: cdef globals, 3+: types objects
# Mostly for reducing noise for Valgrind, only executes at process exit
# (when all memory will be reclaimed anyways).
generate_cleanup_code = False

annotate = False

# This will abort the compilation on the first error occured rather than trying
# to keep going and printing further error messages.
fast_fail = False

# Make all warnings into errors.
warning_errors = False

# Make unknown names an error.  Python raises a NameError when
# encountering unknown names at runtime, whereas this option makes
# them a compile time error.  If you want full Python compatibility,
# you should disable this option and also 'cache_builtins'.
error_on_unknown_names = True

# Make uninitialized local variable reference a compile time error.
# Python raises UnboundLocalError at runtime, whereas this option makes
# them a compile time error. Note that this option affects only variables
# of "python object" type.
error_on_uninitialized = True

# This will convert statements of the form "for i in range(...)"
# to "for i from ..." when i is a cdef'd integer type, and the direction
# (i.e. sign of step) can be determined.
# WARNING: This may change the semantics if the range causes assignment to
# i to overflow. Specifically, if this option is set, an error will be
# raised before the loop is entered, wheras without this option the loop
# will execute until an overflowing value is encountered.
convert_range = True

# Enable this to allow one to write your_module.foo = ... to overwrite the
# definition if the cpdef function foo, at the cost of an extra dictionary
# lookup on every call.
# If this is 0 it simply creates a wrapper.
lookup_module_cpdef = False

# Whether or not to embed the Python interpreter, for use in making a
# standalone executable or calling from external libraries.
# This will provide a method which initalizes the interpreter and
# executes the body of this module.
embed = None

# In previous iterations of Cython, globals() gave the first non-Cython module
# globals in the call stack.  Sage relies on this behavior for variable injection.
old_style_globals = False

# Allows cimporting from a pyx file without a pxd file.
cimport_from_pyx = False

# max # of dims for buffers -- set lower than number of dimensions in numpy, as
# slices are passed by value and involve a lot of copying
buffer_max_dims = 8

# Number of function closure instances to keep in a freelist (0: no freelists)
closure_freelist_size = 8

# Should tp_clear() set object fields to None instead of clearing them to NULL?
clear_to_none = True


# Declare compiler directives
directive_defaults = {
    'boundscheck' : True,
    'nonecheck' : False,
    'initializedcheck' : True,
    'embedsignature' : False,
    'locals' : {},
    'auto_cpdef': False,
    'cdivision': False, # was True before 0.12
    'cdivision_warnings': False,
    'overflowcheck': False,
    'overflowcheck.fold': True,
    'always_allow_keywords': False,
    'allow_none_for_extension_args': True,
    'wraparound' : True,
    'ccomplex' : False, # use C99/C++ for complex types and arith
    'callspec' : "",
    'final' : False,
    'internal' : False,
    'profile': False,
    'no_gc_clear': False,
    'linetrace': False,
    'infer_types': None,
    'infer_types.verbose': False,
    'autotestdict': True,
    'autotestdict.cdef': False,
    'autotestdict.all': False,
    'language_level': 2,
    'fast_getattr': False, # Undocumented until we come up with a better way to handle this everywhere.
    'py2_import': False, # For backward compatibility of Cython's source code in Py3 source mode
    'c_string_type': 'bytes',
    'c_string_encoding': '',
    'type_version_tag': True,   # enables Py_TPFLAGS_HAVE_VERSION_TAG on extension types
    'unraisable_tracebacks': False,

    # set __file__ and/or __path__ to known source/target path at import time (instead of not having them available)
    'set_initial_path' : None,  # SOURCEFILE or "/full/path/to/module"

    'warn': None,
    'warn.undeclared': False,
    'warn.unreachable': True,
    'warn.maybe_uninitialized': False,
    'warn.unused': False,
    'warn.unused_arg': False,
    'warn.unused_result': False,
    'warn.multiple_declarators': True,

# optimizations
    'optimize.inline_defnode_calls': True,

# remove unreachable code
    'remove_unreachable': True,

# control flow debug directives
    'control_flow.dot_output': "", # Graphviz output filename
    'control_flow.dot_annotate_defs': False, # Annotate definitions

# test support
    'test_assert_path_exists' : [],
    'test_fail_if_path_exists' : [],

# experimental, subject to change
    'binding': None,
    'freelist': 0,
}

# Extra warning directives
extra_warnings = {
    'warn.maybe_uninitialized': True,
    'warn.unreachable': True,
    'warn.unused': True,
}

def one_of(*args):
    def validate(name, value):
        if value not in args:
            raise ValueError("%s directive must be one of %s, got '%s'" % (
                name, args, value))
        else:
            return value
    return validate


def normalise_encoding_name(option_name, encoding):
    """
    >>> normalise_encoding_name('c_string_encoding', 'ascii')
    'ascii'
    >>> normalise_encoding_name('c_string_encoding', 'AsCIi')
    'ascii'
    >>> normalise_encoding_name('c_string_encoding', 'us-ascii')
    'ascii'
    >>> normalise_encoding_name('c_string_encoding', 'utF8')
    'utf8'
    >>> normalise_encoding_name('c_string_encoding', 'utF-8')
    'utf8'
    >>> normalise_encoding_name('c_string_encoding', 'deFAuLT')
    'default'
    >>> normalise_encoding_name('c_string_encoding', 'default')
    'default'
    >>> normalise_encoding_name('c_string_encoding', 'SeriousLyNoSuch--Encoding')
    'SeriousLyNoSuch--Encoding'
    """
    if not encoding:
        return ''
    if encoding.lower() in ('default', 'ascii', 'utf8'):
        return encoding.lower()
    import codecs
    try:
        decoder = codecs.getdecoder(encoding)
    except LookupError:
        return encoding  # may exists at runtime ...
    for name in ('ascii', 'utf8'):
        if codecs.getdecoder(name) == decoder:
            return name
    return encoding


# Override types possibilities above, if needed
directive_types = {
    'final' : bool,  # final cdef classes and methods
    'internal' : bool,  # cdef class visibility in the module dict
    'infer_types' : bool, # values can be True/None/False
    'binding' : bool,
    'cfunc' : None, # decorators do not take directive value
    'ccall' : None,
    'cclass' : None,
    'returns' : type,
    'set_initial_path': str,
    'freelist': int,
    'c_string_type': one_of('bytes', 'bytearray', 'str', 'unicode'),
    'c_string_encoding': normalise_encoding_name,
}

for key, val in directive_defaults.items():
    if key not in directive_types:
        directive_types[key] = type(val)

directive_scopes = { # defaults to available everywhere
    # 'module', 'function', 'class', 'with statement'
    'final' : ('cclass', 'function'),
    'no_gc_clear' : ('cclass',),
    'internal' : ('cclass',),
    'autotestdict' : ('module',),
    'autotestdict.all' : ('module',),
    'autotestdict.cdef' : ('module',),
    'set_initial_path' : ('module',),
    'test_assert_path_exists' : ('function', 'class', 'cclass'),
    'test_fail_if_path_exists' : ('function', 'class', 'cclass'),
    'freelist': ('cclass',),
    # Avoid scope-specific to/from_py_functions for c_string.
    'c_string_type': ('module',),
    'c_string_encoding': ('module',),
    'type_version_tag': ('module', 'cclass'),
}

def parse_directive_value(name, value, relaxed_bool=False):
    """
    Parses value as an option value for the given name and returns
    the interpreted value. None is returned if the option does not exist.

    >>> print parse_directive_value('nonexisting', 'asdf asdfd')
    None
    >>> parse_directive_value('boundscheck', 'True')
    True
    >>> parse_directive_value('boundscheck', 'true')
    Traceback (most recent call last):
       ...
    ValueError: boundscheck directive must be set to True or False, got 'true'

    >>> parse_directive_value('c_string_encoding', 'us-ascii')
    'ascii'
    >>> parse_directive_value('c_string_type', 'str')
    'str'
    >>> parse_directive_value('c_string_type', 'bytes')
    'bytes'
    >>> parse_directive_value('c_string_type', 'bytearray')
    'bytearray'
    >>> parse_directive_value('c_string_type', 'unicode')
    'unicode'
    >>> parse_directive_value('c_string_type', 'unnicode')
    Traceback (most recent call last):
    ValueError: c_string_type directive must be one of ('bytes', 'bytearray', 'str', 'unicode'), got 'unnicode'
    """
    type = directive_types.get(name)
    if not type: return None
    orig_value = value
    if type is bool:
        value = str(value)
        if value == 'True': return True
        if value == 'False': return False
        if relaxed_bool:
            value = value.lower()
            if value in ("true", "yes"): return True
            elif value in ("false", "no"): return False
        raise ValueError("%s directive must be set to True or False, got '%s'" % (
            name, orig_value))
    elif type is int:
        try:
            return int(value)
        except ValueError:
            raise ValueError("%s directive must be set to an integer, got '%s'" % (
                name, orig_value))
    elif type is str:
        return str(value)
    elif callable(type):
        return type(name, value)
    else:
        assert False

def parse_directive_list(s, relaxed_bool=False, ignore_unknown=False,
                         current_settings=None):
    """
    Parses a comma-separated list of pragma options. Whitespace
    is not considered.

    >>> parse_directive_list('      ')
    {}
    >>> (parse_directive_list('boundscheck=True') ==
    ... {'boundscheck': True})
    True
    >>> parse_directive_list('  asdf')
    Traceback (most recent call last):
       ...
    ValueError: Expected "=" in option "asdf"
    >>> parse_directive_list('boundscheck=hey')
    Traceback (most recent call last):
       ...
    ValueError: boundscheck directive must be set to True or False, got 'hey'
    >>> parse_directive_list('unknown=True')
    Traceback (most recent call last):
       ...
    ValueError: Unknown option: "unknown"
    >>> warnings = parse_directive_list('warn.all=True')
    >>> len(warnings) > 1
    True
    >>> sum(warnings.values()) == len(warnings)  # all true.
    True
    """
    if current_settings is None:
        result = {}
    else:
        result = current_settings
    for item in s.split(','):
        item = item.strip()
        if not item: continue
        if not '=' in item: raise ValueError('Expected "=" in option "%s"' % item)
        name, value = [ s.strip() for s in item.strip().split('=', 1) ]
        if name not in directive_defaults:
            found = False
            if name.endswith('.all'):
                prefix = name[:-3]
                for directive in directive_defaults:
                    if directive.startswith(prefix):
                        found = True
                        parsed_value = parse_directive_value(directive, value, relaxed_bool=relaxed_bool)
                        result[directive] = parsed_value
            if not found and not ignore_unknown:
                raise ValueError('Unknown option: "%s"' % name)
        else:
            parsed_value = parse_directive_value(name, value, relaxed_bool=relaxed_bool)
            result[name] = parsed_value
    return result
