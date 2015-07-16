#
#   Symbol Table
#

import copy
import re
from Errors import warning, error, InternalError
from StringEncoding import EncodedString
import Options, Naming
import PyrexTypes
from PyrexTypes import py_object_type, unspecified_type
from TypeSlots import \
    pyfunction_signature, pymethod_signature, \
    get_special_method_signature, get_property_accessor_signature
import Code
import __builtin__ as builtins

iso_c99_keywords = set(
['auto', 'break', 'case', 'char', 'const', 'continue', 'default', 'do',
    'double', 'else', 'enum', 'extern', 'float', 'for', 'goto', 'if',
    'int', 'long', 'register', 'return', 'short', 'signed', 'sizeof',
    'static', 'struct', 'switch', 'typedef', 'union', 'unsigned', 'void',
    'volatile', 'while',
    '_Bool', '_Complex'', _Imaginary', 'inline', 'restrict'])

def c_safe_identifier(cname):
    # There are some C limitations on struct entry names.
    if ((cname[:2] == '__'
         and not (cname.startswith(Naming.pyrex_prefix)
                  or cname == '__weakref__'))
        or cname in iso_c99_keywords):
        cname = Naming.pyrex_prefix + cname
    return cname

class BufferAux(object):
    writable_needed = False

    def __init__(self, buflocal_nd_var, rcbuf_var):
        self.buflocal_nd_var = buflocal_nd_var
        self.rcbuf_var = rcbuf_var

    def __repr__(self):
        return "<BufferAux %r>" % self.__dict__


class Entry(object):
    # A symbol table entry in a Scope or ModuleNamespace.
    #
    # name             string     Python name of entity
    # cname            string     C name of entity
    # type             PyrexType  Type of entity
    # doc              string     Doc string
    # init             string     Initial value
    # visibility       'private' or 'public' or 'extern'
    # is_builtin       boolean    Is an entry in the Python builtins dict
    # is_cglobal       boolean    Is a C global variable
    # is_pyglobal      boolean    Is a Python module-level variable
    #                               or class attribute during
    #                               class construction
    # is_member        boolean    Is an assigned class member
    # is_pyclass_attr  boolean    Is a name in a Python class namespace
    # is_variable      boolean    Is a variable
    # is_cfunction     boolean    Is a C function
    # is_cmethod       boolean    Is a C method of an extension type
    # is_builtin_cmethod boolean  Is a C method of a builtin type (implies is_cmethod)
    # is_unbound_cmethod boolean  Is an unbound C method of an extension type
    # is_final_cmethod   boolean  Is non-overridable C method
    # is_inline_cmethod  boolean  Is inlined C method
    # is_anonymous     boolean    Is a anonymous pyfunction entry
    # is_type          boolean    Is a type definition
    # is_cclass        boolean    Is an extension class
    # is_cpp_class     boolean    Is a C++ class
    # is_const         boolean    Is a constant
    # is_property      boolean    Is a property of an extension type:
    # doc_cname        string or None  C const holding the docstring
    # getter_cname     string          C func for getting property
    # setter_cname     string          C func for setting or deleting property
    # is_self_arg      boolean    Is the "self" arg of an exttype method
    # is_arg           boolean    Is the arg of a method
    # is_local         boolean    Is a local variable
    # in_closure       boolean    Is referenced in an inner scope
    # is_readonly      boolean    Can't be assigned to
    # func_cname       string     C func implementing Python func
    # func_modifiers   [string]   C function modifiers ('inline')
    # pos              position   Source position where declared
    # namespace_cname  string     If is_pyglobal, the C variable
    #                               holding its home namespace
    # pymethdef_cname  string     PyMethodDef structure
    # signature        Signature  Arg & return types for Python func
    # as_variable      Entry      Alternative interpretation of extension
    #                               type name or builtin C function as a variable
    # xdecref_cleanup  boolean    Use Py_XDECREF for error cleanup
    # in_cinclude      boolean    Suppress C declaration code
    # enum_values      [Entry]    For enum types, list of values
    # qualified_name   string     "modname.funcname" or "modname.classname"
    #                               or "modname.classname.funcname"
    # is_declared_generic  boolean  Is declared as PyObject * even though its
    #                                 type is an extension type
    # as_module        None       Module scope, if a cimported module
    # is_inherited     boolean    Is an inherited attribute of an extension type
    # pystring_cname   string     C name of Python version of string literal
    # is_interned      boolean    For string const entries, value is interned
    # is_identifier    boolean    For string const entries, value is an identifier
    # used             boolean
    # is_special       boolean    Is a special method or property accessor
    #                               of an extension type
    # defined_in_pxd   boolean    Is defined in a .pxd file (not just declared)
    # api              boolean    Generate C API for C class or function
    # utility_code     string     Utility code needed when this entry is used
    #
    # buffer_aux       BufferAux or None  Extra information needed for buffer variables
    # inline_func_in_pxd boolean  Hacky special case for inline function in pxd file.
    #                             Ideally this should not be necesarry.
    # might_overflow   boolean    In an arithmetic expression that could cause
    #                             overflow (used for type inference).
    # utility_code_definition     For some Cython builtins, the utility code
    #                             which contains the definition of the entry.
    #                             Currently only supported for CythonScope entries.
    # error_on_uninitialized      Have Control Flow issue an error when this entry is
    #                             used uninitialized
    # cf_used          boolean    Entry is used
    # is_fused_specialized boolean Whether this entry of a cdef or def function
    #                              is a specialization

    # TODO: utility_code and utility_code_definition serves the same purpose...

    inline_func_in_pxd = False
    borrowed = 0
    init = ""
    visibility = 'private'
    is_builtin = 0
    is_cglobal = 0
    is_pyglobal = 0
    is_member = 0
    is_pyclass_attr = 0
    is_variable = 0
    is_cfunction = 0
    is_cmethod = 0
    is_builtin_cmethod = False
    is_unbound_cmethod = 0
    is_final_cmethod = 0
    is_inline_cmethod = 0
    is_anonymous = 0
    is_type = 0
    is_cclass = 0
    is_cpp_class = 0
    is_const = 0
    is_property = 0
    doc_cname = None
    getter_cname = None
    setter_cname = None
    is_self_arg = 0
    is_arg = 0
    is_local = 0
    in_closure = 0
    from_closure = 0
    is_declared_generic = 0
    is_readonly = 0
    pyfunc_cname = None
    func_cname = None
    func_modifiers = []
    final_func_cname = None
    doc = None
    as_variable = None
    xdecref_cleanup = 0
    in_cinclude = 0
    as_module = None
    is_inherited = 0
    pystring_cname = None
    is_identifier = 0
    is_interned = 0
    used = 0
    is_special = 0
    defined_in_pxd = 0
    is_implemented = 0
    api = 0
    utility_code = None
    is_overridable = 0
    buffer_aux = None
    prev_entry = None
    might_overflow = 0
    fused_cfunction = None
    is_fused_specialized = False
    utility_code_definition = None
    needs_property = False
    in_with_gil_block = 0
    from_cython_utility_code = None
    error_on_uninitialized = False
    cf_used = True
    outer_entry = None

    def __init__(self, name, cname, type, pos = None, init = None):
        self.name = name
        self.cname = cname
        self.type = type
        self.pos = pos
        self.init = init
        self.overloaded_alternatives = []
        self.cf_assignments = []
        self.cf_references = []
        self.inner_entries = []
        self.defining_entry = self

    def __repr__(self):
        return "%s(<%x>, name=%s, type=%s)" % (type(self).__name__, id(self), self.name, self.type)

    def redeclared(self, pos):
        error(pos, "'%s' does not match previous declaration" % self.name)
        error(self.pos, "Previous declaration is here")

    def all_alternatives(self):
        return [self] + self.overloaded_alternatives

    def all_entries(self):
        return [self] + self.inner_entries


class InnerEntry(Entry):
    """
    An entry in a closure scope that represents the real outer Entry.
    """
    from_closure = True

    def __init__(self, outer_entry, scope):
        Entry.__init__(self, outer_entry.name,
                       outer_entry.cname,
                       outer_entry.type,
                       outer_entry.pos)
        self.outer_entry = outer_entry
        self.scope = scope

        # share state with (outermost) defining entry
        outermost_entry = outer_entry
        while outermost_entry.outer_entry:
            outermost_entry = outermost_entry.outer_entry
        self.defining_entry = outermost_entry
        self.inner_entries = outermost_entry.inner_entries
        self.cf_assignments = outermost_entry.cf_assignments
        self.cf_references = outermost_entry.cf_references
        self.overloaded_alternatives = outermost_entry.overloaded_alternatives
        self.inner_entries.append(self)

    def __getattr__(self, name):
        if name.startswith('__'):
            # we wouldn't have been called if it was there
            raise AttributeError(name)
        return getattr(self.defining_entry, name)

    def all_entries(self):
        return self.defining_entry.all_entries()


class Scope(object):
    # name              string             Unqualified name
    # outer_scope       Scope or None      Enclosing scope
    # entries           {string : Entry}   Python name to entry, non-types
    # const_entries     [Entry]            Constant entries
    # type_entries      [Entry]            Struct/union/enum/typedef/exttype entries
    # sue_entries       [Entry]            Struct/union/enum entries
    # arg_entries       [Entry]            Function argument entries
    # var_entries       [Entry]            User-defined variable entries
    # pyfunc_entries    [Entry]            Python function entries
    # cfunc_entries     [Entry]            C function entries
    # c_class_entries   [Entry]            All extension type entries
    # cname_to_entry    {string : Entry}   Temp cname to entry mapping
    # return_type       PyrexType or None  Return type of function owning scope
    # is_builtin_scope  boolean            Is the builtin scope of Python/Cython
    # is_py_class_scope boolean            Is a Python class scope
    # is_c_class_scope  boolean            Is an extension type scope
    # is_closure_scope  boolean            Is a closure scope
    # is_passthrough    boolean            Outer scope is passed directly
    # is_cpp_class_scope  boolean          Is a C++ class scope
    # is_property_scope boolean            Is a extension type property scope
    # scope_prefix      string             Disambiguator for C names
    # in_cinclude       boolean            Suppress C declaration code
    # qualified_name    string             "modname" or "modname.classname"
    #                                        Python strings in this scope
    # nogil             boolean            In a nogil section
    # directives        dict               Helper variable for the recursive
    #                                      analysis, contains directive values.
    # is_internal       boolean            Is only used internally (simpler setup)

    is_builtin_scope = 0
    is_py_class_scope = 0
    is_c_class_scope = 0
    is_closure_scope = 0
    is_passthrough = 0
    is_cpp_class_scope = 0
    is_property_scope = 0
    is_module_scope = 0
    is_internal = 0
    scope_prefix = ""
    in_cinclude = 0
    nogil = 0
    fused_to_specific = None

    def __init__(self, name, outer_scope, parent_scope):
        # The outer_scope is the next scope in the lookup chain.
        # The parent_scope is used to derive the qualified name of this scope.
        self.name = name
        self.outer_scope = outer_scope
        self.parent_scope = parent_scope
        mangled_name = "%d%s_" % (len(name), name)
        qual_scope = self.qualifying_scope()
        if qual_scope:
            self.qualified_name = qual_scope.qualify_name(name)
            self.scope_prefix = qual_scope.scope_prefix + mangled_name
        else:
            self.qualified_name = EncodedString(name)
            self.scope_prefix = mangled_name
        self.entries = {}
        self.const_entries = []
        self.type_entries = []
        self.sue_entries = []
        self.arg_entries = []
        self.var_entries = []
        self.pyfunc_entries = []
        self.cfunc_entries = []
        self.c_class_entries = []
        self.defined_c_classes = []
        self.imported_c_classes = {}
        self.cname_to_entry = {}
        self.string_to_entry = {}
        self.identifier_to_entry = {}
        self.num_to_entry = {}
        self.obj_to_entry = {}
        self.buffer_entries = []
        self.lambda_defs = []
        self.return_type = None
        self.id_counters = {}

    def __deepcopy__(self, memo):
        return self

    def merge_in(self, other, merge_unused=True, whitelist=None):
        # Use with care...
        entries = []
        for name, entry in other.entries.iteritems():
            if not whitelist or name in whitelist:
                if entry.used or merge_unused:
                    entries.append((name, entry))

        self.entries.update(entries)

        for attr in ('const_entries',
                     'type_entries',
                     'sue_entries',
                     'arg_entries',
                     'var_entries',
                     'pyfunc_entries',
                     'cfunc_entries',
                     'c_class_entries'):
            self_entries = getattr(self, attr)
            names = set([e.name for e in self_entries])
            for entry in getattr(other, attr):
                if (entry.used or merge_unused) and entry.name not in names:
                    self_entries.append(entry)

    def __str__(self):
        return "<%s %s>" % (self.__class__.__name__, self.qualified_name)

    def qualifying_scope(self):
        return self.parent_scope

    def mangle(self, prefix, name = None):
        if name:
            return "%s%s%s" % (prefix, self.scope_prefix, name)
        else:
            return self.parent_scope.mangle(prefix, self.name)

    def mangle_internal(self, name):
        # Mangle an internal name so as not to clash with any
        # user-defined name in this scope.
        prefix = "%s%s_" % (Naming.pyrex_prefix, name)
        return self.mangle(prefix)
        #return self.parent_scope.mangle(prefix, self.name)

    def mangle_class_private_name(self, name):
        if self.parent_scope:
            return self.parent_scope.mangle_class_private_name(name)
        return name

    def next_id(self, name=None):
        # Return a cname fragment that is unique for this module
        counters = self.global_scope().id_counters
        try:
            count = counters[name] + 1
        except KeyError:
            count = 0
        counters[name] = count
        if name:
            if not count:
                # unique names don't need a suffix, reoccurrences will get one
                return name
            return '%s%d' % (name, count)
        else:
            return '%d' % count

    def global_scope(self):
        """ Return the module-level scope containing this scope. """
        return self.outer_scope.global_scope()

    def builtin_scope(self):
        """ Return the module-level scope containing this scope. """
        return self.outer_scope.builtin_scope()

    def declare(self, name, cname, type, pos, visibility, shadow = 0, is_type = 0):
        # Create new entry, and add to dictionary if
        # name is not None. Reports a warning if already
        # declared.
        if type.is_buffer and not isinstance(self, LocalScope): # and not is_type:
            error(pos, 'Buffer types only allowed as function local variables')
        if not self.in_cinclude and cname and re.match("^_[_A-Z]+$", cname):
            # See http://www.gnu.org/software/libc/manual/html_node/Reserved-Names.html#Reserved-Names
            warning(pos, "'%s' is a reserved name in C." % cname, -1)
        entries = self.entries
        if name and name in entries and not shadow:
            if visibility == 'extern':
                warning(pos, "'%s' redeclared " % name, 0)
            elif visibility != 'ignore':
                error(pos, "'%s' redeclared " % name)
        entry = Entry(name, cname, type, pos = pos)
        entry.in_cinclude = self.in_cinclude
        if name:
            entry.qualified_name = self.qualify_name(name)
#            if name in entries and self.is_cpp():
#                entries[name].overloaded_alternatives.append(entry)
#            else:
#                entries[name] = entry
            if not shadow:
                entries[name] = entry

        if type.is_memoryviewslice:
            import MemoryView
            entry.init = MemoryView.memslice_entry_init

        entry.scope = self
        entry.visibility = visibility
        return entry

    def qualify_name(self, name):
        return EncodedString("%s.%s" % (self.qualified_name, name))

    def declare_const(self, name, type, value, pos, cname = None, visibility = 'private', api = 0):
        # Add an entry for a named constant.
        if not cname:
            if self.in_cinclude or (visibility == 'public' or api):
                cname = name
            else:
                cname = self.mangle(Naming.enum_prefix, name)
        entry = self.declare(name, cname, type, pos, visibility)
        entry.is_const = 1
        entry.value_node = value
        return entry

    def declare_type(self, name, type, pos,
            cname = None, visibility = 'private', api = 0, defining = 1,
            shadow = 0, template = 0):
        # Add an entry for a type definition.
        if not cname:
            cname = name
        entry = self.declare(name, cname, type, pos, visibility, shadow,
                             is_type=True)
        entry.is_type = 1
        entry.api = api
        if defining:
            self.type_entries.append(entry)

        if not template:
            type.entry = entry

        # here we would set as_variable to an object representing this type
        return entry

    def declare_typedef(self, name, base_type, pos, cname = None,
                        visibility = 'private', api = 0):
        if not cname:
            if self.in_cinclude or (visibility == 'public' or api):
                cname = name
            else:
                cname = self.mangle(Naming.type_prefix, name)
        try:
            type = PyrexTypes.create_typedef_type(name, base_type, cname,
                                                  (visibility == 'extern'))
        except ValueError, e:
            error(pos, e.args[0])
            type = PyrexTypes.error_type
        entry = self.declare_type(name, type, pos, cname,
                                  visibility = visibility, api = api)
        type.qualified_name = entry.qualified_name
        return entry

    def declare_struct_or_union(self, name, kind, scope,
                                typedef_flag, pos, cname = None,
                                visibility = 'private', api = 0,
                                packed = False):
        # Add an entry for a struct or union definition.
        if not cname:
            if self.in_cinclude or (visibility == 'public' or api):
                cname = name
            else:
                cname = self.mangle(Naming.type_prefix, name)
        entry = self.lookup_here(name)
        if not entry:
            type = PyrexTypes.CStructOrUnionType(
                name, kind, scope, typedef_flag, cname, packed)
            entry = self.declare_type(name, type, pos, cname,
                visibility = visibility, api = api,
                defining = scope is not None)
            self.sue_entries.append(entry)
            type.entry = entry
        else:
            if not (entry.is_type and entry.type.is_struct_or_union
                    and entry.type.kind == kind):
                warning(pos, "'%s' redeclared  " % name, 0)
            elif scope and entry.type.scope:
                warning(pos, "'%s' already defined  (ignoring second definition)" % name, 0)
            else:
                self.check_previous_typedef_flag(entry, typedef_flag, pos)
                self.check_previous_visibility(entry, visibility, pos)
                if scope:
                    entry.type.scope = scope
                    self.type_entries.append(entry)
        return entry

    def declare_cpp_class(self, name, scope,
            pos, cname = None, base_classes = (),
            visibility = 'extern', templates = None):
        if cname is None:
            if self.in_cinclude or (visibility != 'private'):
                cname = name
            else:
                cname = self.mangle(Naming.type_prefix, name)
        base_classes = list(base_classes)
        entry = self.lookup_here(name)
        if not entry:
            type = PyrexTypes.CppClassType(
                name, scope, cname, base_classes, templates = templates)
            entry = self.declare_type(name, type, pos, cname,
                visibility = visibility, defining = scope is not None)
            self.sue_entries.append(entry)
        else:
            if not (entry.is_type and entry.type.is_cpp_class):
                error(pos, "'%s' redeclared " % name)
                return None
            elif scope and entry.type.scope:
                warning(pos, "'%s' already defined  (ignoring second definition)" % name, 0)
            else:
                if scope:
                    entry.type.scope = scope
                    self.type_entries.append(entry)
            if base_classes:
                if entry.type.base_classes and entry.type.base_classes != base_classes:
                    error(pos, "Base type does not match previous declaration")
                else:
                    entry.type.base_classes = base_classes
            if templates or entry.type.templates:
                if templates != entry.type.templates:
                    error(pos, "Template parameters do not match previous declaration")

        def declare_inherited_attributes(entry, base_classes):
            for base_class in base_classes:
                if base_class is PyrexTypes.error_type:
                    continue
                if base_class.scope is None:
                    error(pos, "Cannot inherit from incomplete type")
                else:
                    declare_inherited_attributes(entry, base_class.base_classes)
                    entry.type.scope.declare_inherited_cpp_attributes(base_class.scope)
        if entry.type.scope:
            declare_inherited_attributes(entry, base_classes)
            entry.type.scope.declare_var(name="this", cname="this", type=PyrexTypes.CPtrType(entry.type), pos=entry.pos)
        if self.is_cpp_class_scope:
            entry.type.namespace = self.outer_scope.lookup(self.name).type
        return entry

    def check_previous_typedef_flag(self, entry, typedef_flag, pos):
        if typedef_flag != entry.type.typedef_flag:
            error(pos, "'%s' previously declared using '%s'" % (
                entry.name, ("cdef", "ctypedef")[entry.type.typedef_flag]))

    def check_previous_visibility(self, entry, visibility, pos):
        if entry.visibility != visibility:
            error(pos, "'%s' previously declared as '%s'" % (
                entry.name, entry.visibility))

    def declare_enum(self, name, pos, cname, typedef_flag,
            visibility = 'private', api = 0):
        if name:
            if not cname:
                if self.in_cinclude or (visibility == 'public' or api):
                    cname = name
                else:
                    cname = self.mangle(Naming.type_prefix, name)
            type = PyrexTypes.CEnumType(name, cname, typedef_flag)
        else:
            type = PyrexTypes.c_anon_enum_type
        entry = self.declare_type(name, type, pos, cname = cname,
            visibility = visibility, api = api)
        entry.enum_values = []
        self.sue_entries.append(entry)
        return entry

    def declare_var(self, name, type, pos,
                    cname = None, visibility = 'private',
                    api = 0, in_pxd = 0, is_cdef = 0):
        # Add an entry for a variable.
        if not cname:
            if visibility != 'private' or api:
                cname = name
            else:
                cname = self.mangle(Naming.var_prefix, name)
        if type.is_cpp_class and visibility != 'extern':
            type.check_nullary_constructor(pos)
        entry = self.declare(name, cname, type, pos, visibility)
        entry.is_variable = 1
        if in_pxd and visibility != 'extern':
            entry.defined_in_pxd = 1
            entry.used = 1
        if api:
            entry.api = 1
            entry.used = 1
        return entry

    def declare_builtin(self, name, pos):
        return self.outer_scope.declare_builtin(name, pos)

    def _declare_pyfunction(self, name, pos, visibility='extern', entry=None):
        if entry and not entry.type.is_cfunction:
            error(pos, "'%s' already declared" % name)
            error(entry.pos, "Previous declaration is here")
        entry = self.declare_var(name, py_object_type, pos, visibility=visibility)
        entry.signature = pyfunction_signature
        self.pyfunc_entries.append(entry)
        return entry

    def declare_pyfunction(self, name, pos, allow_redefine=False, visibility='extern'):
        # Add an entry for a Python function.
        entry = self.lookup_here(name)
        if not allow_redefine:
            return self._declare_pyfunction(name, pos, visibility=visibility, entry=entry)
        if entry:
            if entry.type.is_unspecified:
                entry.type = py_object_type
            elif entry.type is not py_object_type:
                return self._declare_pyfunction(name, pos, visibility=visibility, entry=entry)
        else: # declare entry stub
            self.declare_var(name, py_object_type, pos, visibility=visibility)
        entry = self.declare_var(None, py_object_type, pos,
                                 cname=name, visibility='private')
        entry.name = EncodedString(name)
        entry.qualified_name = self.qualify_name(name)
        entry.signature = pyfunction_signature
        entry.is_anonymous = True
        return entry

    def declare_lambda_function(self, lambda_name, pos):
        # Add an entry for an anonymous Python function.
        func_cname = self.mangle(Naming.lambda_func_prefix + u'funcdef_', lambda_name)
        pymethdef_cname = self.mangle(Naming.lambda_func_prefix + u'methdef_', lambda_name)
        qualified_name = self.qualify_name(lambda_name)

        entry = self.declare(None, func_cname, py_object_type, pos, 'private')
        entry.name = lambda_name
        entry.qualified_name = qualified_name
        entry.pymethdef_cname = pymethdef_cname
        entry.func_cname = func_cname
        entry.signature = pyfunction_signature
        entry.is_anonymous = True
        return entry

    def add_lambda_def(self, def_node):
        self.lambda_defs.append(def_node)

    def register_pyfunction(self, entry):
        self.pyfunc_entries.append(entry)

    def declare_cfunction(self, name, type, pos,
                          cname = None, visibility = 'private', api = 0, in_pxd = 0,
                          defining = 0, modifiers = (), utility_code = None):
        # Add an entry for a C function.
        if not cname:
            if visibility != 'private' or api:
                cname = name
            else:
                cname = self.mangle(Naming.func_prefix, name)
        entry = self.lookup_here(name)
        if entry:
            if visibility != 'private' and visibility != entry.visibility:
                warning(pos, "Function '%s' previously declared as '%s'" % (name, entry.visibility), 1)
            if not entry.type.same_as(type):
                if visibility == 'extern' and entry.visibility == 'extern':
                    can_override = False
                    if self.is_cpp():
                        can_override = True
                    elif cname:
                        # if all alternatives have different cnames,
                        # it's safe to allow signature overrides
                        for alt_entry in entry.all_alternatives():
                            if not alt_entry.cname or cname == alt_entry.cname:
                                break # cname not unique!
                        else:
                            can_override = True
                    if can_override:
                        temp = self.add_cfunction(name, type, pos, cname, visibility, modifiers)
                        temp.overloaded_alternatives = entry.all_alternatives()
                        entry = temp
                    else:
                        warning(pos, "Function signature does not match previous declaration", 1)
                        entry.type = type
                else:
                    error(pos, "Function signature does not match previous declaration")
        else:
            entry = self.add_cfunction(name, type, pos, cname, visibility, modifiers)
            entry.func_cname = cname
        if in_pxd and visibility != 'extern':
            entry.defined_in_pxd = 1
        if api:
            entry.api = 1
        if not defining and not in_pxd and visibility != 'extern':
            error(pos, "Non-extern C function '%s' declared but not defined" % name)
        if defining:
            entry.is_implemented = True
        if modifiers:
            entry.func_modifiers = modifiers
        if utility_code:
            assert not entry.utility_code, "duplicate utility code definition in entry %s (%s)" % (name, cname)
            entry.utility_code = utility_code
        type.entry = entry
        return entry

    def add_cfunction(self, name, type, pos, cname, visibility, modifiers):
        # Add a C function entry without giving it a func_cname.
        entry = self.declare(name, cname, type, pos, visibility)
        entry.is_cfunction = 1
        if modifiers:
            entry.func_modifiers = modifiers
        self.cfunc_entries.append(entry)
        return entry

    def find(self, name, pos):
        # Look up name, report error if not found.
        entry = self.lookup(name)
        if entry:
            return entry
        else:
            error(pos, "'%s' is not declared" % name)

    def find_imported_module(self, path, pos):
        # Look up qualified name, must be a module, report error if not found.
        # Path is a list of names.
        scope = self
        for name in path:
            entry = scope.find(name, pos)
            if not entry:
                return None
            if entry.as_module:
                scope = entry.as_module
            else:
                error(pos, "'%s' is not a cimported module" % '.'.join(path))
                return None
        return scope

    def lookup(self, name):
        # Look up name in this scope or an enclosing one.
        # Return None if not found.
        return (self.lookup_here(name)
            or (self.outer_scope and self.outer_scope.lookup(name))
            or None)

    def lookup_here(self, name):
        # Look up in this scope only, return None if not found.
        return self.entries.get(name, None)

    def lookup_target(self, name):
        # Look up name in this scope only. Declare as Python
        # variable if not found.
        entry = self.lookup_here(name)
        if not entry:
            entry = self.declare_var(name, py_object_type, None)
        return entry

    def lookup_type(self, name):
        entry = self.lookup(name)
        if entry and entry.is_type:
            if entry.type.is_fused and self.fused_to_specific:
                return entry.type.specialize(self.fused_to_specific)
            return entry.type

    def lookup_operator(self, operator, operands):
        if operands[0].type.is_cpp_class:
            obj_type = operands[0].type
            method = obj_type.scope.lookup("operator%s" % operator)
            if method is not None:
                res = PyrexTypes.best_match(operands[1:], method.all_alternatives())
                if res is not None:
                    return res
        function = self.lookup("operator%s" % operator)
        if function is None:
            return None
        return PyrexTypes.best_match(operands, function.all_alternatives())

    def lookup_operator_for_types(self, pos, operator, types):
        from Nodes import Node
        class FakeOperand(Node):
            pass
        operands = [FakeOperand(pos, type=type) for type in types]
        return self.lookup_operator(operator, operands)

    def use_utility_code(self, new_code):
        self.global_scope().use_utility_code(new_code)

    def generate_library_function_declarations(self, code):
        # Generate extern decls for C library funcs used.
        pass

    def defines_any(self, names):
        # Test whether any of the given names are
        # defined in this scope.
        for name in names:
            if name in self.entries:
                return 1
        return 0

    def infer_types(self):
        from TypeInference import get_type_inferer
        get_type_inferer().infer_types(self)

    def is_cpp(self):
        outer = self.outer_scope
        if outer is None:
            return False
        else:
            return outer.is_cpp()

    def add_include_file(self, filename):
        self.outer_scope.add_include_file(filename)


class PreImportScope(Scope):

    namespace_cname = Naming.preimport_cname

    def __init__(self):
        Scope.__init__(self, Options.pre_import, None, None)

    def declare_builtin(self, name, pos):
        entry = self.declare(name, name, py_object_type, pos, 'private')
        entry.is_variable = True
        entry.is_pyglobal = True
        return entry


class BuiltinScope(Scope):
    #  The builtin namespace.

    is_builtin_scope = True

    def __init__(self):
        if Options.pre_import is None:
            Scope.__init__(self, "__builtin__", None, None)
        else:
            Scope.__init__(self, "__builtin__", PreImportScope(), None)
        self.type_names = {}

        for name, definition in self.builtin_entries.iteritems():
            cname, type = definition
            self.declare_var(name, type, None, cname)

    def lookup(self, name, language_level=None):
        # 'language_level' is passed by ModuleScope
        if language_level == 3:
            if name == 'str':
                name = 'unicode'
        return Scope.lookup(self, name)

    def declare_builtin(self, name, pos):
        if not hasattr(builtins, name):
            if self.outer_scope is not None:
                return self.outer_scope.declare_builtin(name, pos)
            else:
                if Options.error_on_unknown_names:
                    error(pos, "undeclared name not builtin: %s" % name)
                else:
                    warning(pos, "undeclared name not builtin: %s" % name, 2)

    def declare_builtin_cfunction(self, name, type, cname, python_equiv = None,
            utility_code = None):
        # If python_equiv == "*", the Python equivalent has the same name
        # as the entry, otherwise it has the name specified by python_equiv.
        name = EncodedString(name)
        entry = self.declare_cfunction(name, type, None, cname, visibility='extern',
                                       utility_code = utility_code)
        if python_equiv:
            if python_equiv == "*":
                python_equiv = name
            else:
                python_equiv = EncodedString(python_equiv)
            var_entry = Entry(python_equiv, python_equiv, py_object_type)
            var_entry.is_variable = 1
            var_entry.is_builtin = 1
            var_entry.utility_code = utility_code
            entry.as_variable = var_entry
        return entry

    def declare_builtin_type(self, name, cname, utility_code = None, objstruct_cname = None):
        name = EncodedString(name)
        type = PyrexTypes.BuiltinObjectType(name, cname, objstruct_cname)
        scope = CClassScope(name, outer_scope=None, visibility='extern')
        scope.directives = {}
        if name == 'bool':
            type.is_final_type = True
        type.set_scope(scope)
        self.type_names[name] = 1
        entry = self.declare_type(name, type, None, visibility='extern')
        entry.utility_code = utility_code

        var_entry = Entry(name = entry.name,
            type = self.lookup('type').type, # make sure "type" is the first type declared...
            pos = entry.pos,
            cname = "((PyObject*)%s)" % entry.type.typeptr_cname)
        var_entry.is_variable = 1
        var_entry.is_cglobal = 1
        var_entry.is_readonly = 1
        var_entry.is_builtin = 1
        var_entry.utility_code = utility_code
        if Options.cache_builtins:
            var_entry.is_const = True
        entry.as_variable = var_entry

        return type

    def builtin_scope(self):
        return self

    builtin_entries = {

        "type":   ["((PyObject*)&PyType_Type)", py_object_type],

        "bool":   ["((PyObject*)&PyBool_Type)", py_object_type],
        "int":    ["((PyObject*)&PyInt_Type)", py_object_type],
        "long":   ["((PyObject*)&PyLong_Type)", py_object_type],
        "float":  ["((PyObject*)&PyFloat_Type)", py_object_type],
        "complex":["((PyObject*)&PyComplex_Type)", py_object_type],

        "bytes":  ["((PyObject*)&PyBytes_Type)", py_object_type],
        "bytearray":   ["((PyObject*)&PyByteArray_Type)", py_object_type],
        "str":    ["((PyObject*)&PyString_Type)", py_object_type],
        "unicode":["((PyObject*)&PyUnicode_Type)", py_object_type],

        "tuple":  ["((PyObject*)&PyTuple_Type)", py_object_type],
        "list":   ["((PyObject*)&PyList_Type)", py_object_type],
        "dict":   ["((PyObject*)&PyDict_Type)", py_object_type],
        "set":    ["((PyObject*)&PySet_Type)", py_object_type],
        "frozenset":   ["((PyObject*)&PyFrozenSet_Type)", py_object_type],

        "slice":  ["((PyObject*)&PySlice_Type)", py_object_type],
#        "file":   ["((PyObject*)&PyFile_Type)", py_object_type],  # not in Py3

        "None":   ["Py_None", py_object_type],
        "False":  ["Py_False", py_object_type],
        "True":   ["Py_True", py_object_type],
    }

const_counter = 1 # As a temporary solution for compiling code in pxds

class ModuleScope(Scope):
    # module_name          string             Python name of the module
    # module_cname         string             C name of Python module object
    # #module_dict_cname   string             C name of module dict object
    # method_table_cname   string             C name of method table
    # doc                  string             Module doc string
    # doc_cname            string             C name of module doc string
    # utility_code_list    [UtilityCode]      Queuing utility codes for forwarding to Code.py
    # python_include_files [string]           Standard  Python headers to be included
    # include_files        [string]           Other C headers to be included
    # string_to_entry      {string : Entry}   Map string const to entry
    # identifier_to_entry  {string : Entry}   Map identifier string const to entry
    # context              Context
    # parent_module        Scope              Parent in the import namespace
    # module_entries       {string : Entry}   For cimport statements
    # type_names           {string : 1}       Set of type names (used during parsing)
    # included_files       [string]           Cython sources included with 'include'
    # pxd_file_loaded      boolean            Corresponding .pxd file has been processed
    # cimported_modules    [ModuleScope]      Modules imported with cimport
    # types_imported       {PyrexType}        Set of types for which import code generated
    # has_import_star      boolean            Module contains import *
    # cpp                  boolean            Compiling a C++ file
    # is_cython_builtin    boolean            Is this the Cython builtin scope (or a child scope)
    # is_package           boolean            Is this a package module? (__init__)

    is_module_scope = 1
    has_import_star = 0
    is_cython_builtin = 0

    def __init__(self, name, parent_module, context):
        import Builtin
        self.parent_module = parent_module
        outer_scope = Builtin.builtin_scope
        Scope.__init__(self, name, outer_scope, parent_module)
        if name == "__init__":
            # Treat Spam/__init__.pyx specially, so that when Python loads
            # Spam/__init__.so, initSpam() is defined.
            self.module_name = parent_module.module_name
            self.is_package = True
        else:
            self.module_name = name
            self.is_package = False
        self.module_name = EncodedString(self.module_name)
        self.context = context
        self.module_cname = Naming.module_cname
        self.module_dict_cname = Naming.moddict_cname
        self.method_table_cname = Naming.methtable_cname
        self.doc = ""
        self.doc_cname = Naming.moddoc_cname
        self.utility_code_list = []
        self.module_entries = {}
        self.python_include_files = ["Python.h"]
        self.include_files = []
        self.type_names = dict(outer_scope.type_names)
        self.pxd_file_loaded = 0
        self.cimported_modules = []
        self.types_imported = set()
        self.included_files = []
        self.has_extern_class = 0
        self.cached_builtins = []
        self.undeclared_cached_builtins = []
        self.namespace_cname = self.module_cname
        for var_name in ['__builtins__', '__name__', '__file__', '__doc__', '__path__']:
            self.declare_var(EncodedString(var_name), py_object_type, None)

    def qualifying_scope(self):
        return self.parent_module

    def global_scope(self):
        return self

    def lookup(self, name):
        entry = self.lookup_here(name)
        if entry is not None:
            return entry

        if self.context is not None:
            language_level = self.context.language_level
        else:
            language_level = 3

        return self.outer_scope.lookup(name, language_level=language_level)

    def declare_builtin(self, name, pos):
        if not hasattr(builtins, name) \
               and name not in Code.non_portable_builtins_map \
               and name not in Code.uncachable_builtins:
            if self.has_import_star:
                entry = self.declare_var(name, py_object_type, pos)
                return entry
            else:
                if Options.error_on_unknown_names:
                    error(pos, "undeclared name not builtin: %s" % name)
                else:
                    warning(pos, "undeclared name not builtin: %s" % name, 2)
                # unknown - assume it's builtin and look it up at runtime
                entry = self.declare(name, None, py_object_type, pos, 'private')
                entry.is_builtin = 1
                return entry
        if Options.cache_builtins:
            for entry in self.cached_builtins:
                if entry.name == name:
                    return entry
        entry = self.declare(None, None, py_object_type, pos, 'private')
        if Options.cache_builtins and name not in Code.uncachable_builtins:
            entry.is_builtin = 1
            entry.is_const = 1 # cached
            entry.name = name
            entry.cname = Naming.builtin_prefix + name
            self.cached_builtins.append(entry)
            self.undeclared_cached_builtins.append(entry)
        else:
            entry.is_builtin = 1
            entry.name = name
        return entry

    def find_module(self, module_name, pos):
        # Find a module in the import namespace, interpreting
        # relative imports relative to this module's parent.
        # Finds and parses the module's .pxd file if the module
        # has not been referenced before.
        return self.global_scope().context.find_module(
            module_name, relative_to = self.parent_module, pos = pos)

    def find_submodule(self, name):
        # Find and return scope for a submodule of this module,
        # creating a new empty one if necessary. Doesn't parse .pxd.
        scope = self.lookup_submodule(name)
        if not scope:
            scope = ModuleScope(name,
                parent_module = self, context = self.context)
            self.module_entries[name] = scope
        return scope

    def lookup_submodule(self, name):
        # Return scope for submodule of this module, or None.
        return self.module_entries.get(name, None)

    def add_include_file(self, filename):
        if filename not in self.python_include_files \
            and filename not in self.include_files:
                self.include_files.append(filename)

    def add_imported_module(self, scope):
        if scope not in self.cimported_modules:
            for filename in scope.include_files:
                self.add_include_file(filename)
            self.cimported_modules.append(scope)
            for m in scope.cimported_modules:
                self.add_imported_module(m)

    def add_imported_entry(self, name, entry, pos):
        if entry not in self.entries:
            self.entries[name] = entry
        else:
            warning(pos, "'%s' redeclared  " % name, 0)

    def declare_module(self, name, scope, pos):
        # Declare a cimported module. This is represented as a
        # Python module-level variable entry with a module
        # scope attached to it. Reports an error and returns
        # None if previously declared as something else.
        entry = self.lookup_here(name)
        if entry:
            if entry.is_pyglobal and entry.as_module is scope:
                return entry # Already declared as the same module
            if not (entry.is_pyglobal and not entry.as_module):
                # SAGE -- I put this here so Pyrex
                # cimport's work across directories.
                # Currently it tries to multiply define
                # every module appearing in an import list.
                # It shouldn't be an error for a module
                # name to appear again, and indeed the generated
                # code compiles fine.
                return entry
        else:
            entry = self.declare_var(name, py_object_type, pos)
        entry.as_module = scope
        self.add_imported_module(scope)
        return entry

    def declare_var(self, name, type, pos,
                    cname = None, visibility = 'private',
                    api = 0, in_pxd = 0, is_cdef = 0):
        # Add an entry for a global variable. If it is a Python
        # object type, and not declared with cdef, it will live
        # in the module dictionary, otherwise it will be a C
        # global variable.
        if not visibility in ('private', 'public', 'extern'):
            error(pos, "Module-level variable cannot be declared %s" % visibility)
        if not is_cdef:
            if type is unspecified_type:
                type = py_object_type
            if not (type.is_pyobject and not type.is_extension_type):
                raise InternalError(
                    "Non-cdef global variable is not a generic Python object")

        if not cname:
            defining = not in_pxd
            if visibility == 'extern' or (visibility == 'public' and defining):
                cname = name
            else:
                cname = self.mangle(Naming.var_prefix, name)

        entry = self.lookup_here(name)
        if entry and entry.defined_in_pxd:
            #if visibility != 'private' and visibility != entry.visibility:
            #    warning(pos, "Variable '%s' previously declared as '%s'" % (name, entry.visibility), 1)
            if not entry.type.same_as(type):
                if visibility == 'extern' and entry.visibility == 'extern':
                    warning(pos, "Variable '%s' type does not match previous declaration" % name, 1)
                    entry.type = type
                #else:
                #    error(pos, "Variable '%s' type does not match previous declaration" % name)
            if entry.visibility != "private":
                mangled_cname = self.mangle(Naming.var_prefix, name)
                if entry.cname == mangled_cname:
                    cname = name
                    entry.cname = name
            if not entry.is_implemented:
                entry.is_implemented = True
                return entry

        entry = Scope.declare_var(self, name, type, pos,
                                  cname=cname, visibility=visibility,
                                  api=api, in_pxd=in_pxd, is_cdef=is_cdef)
        if is_cdef:
            entry.is_cglobal = 1
            if entry.type.is_pyobject:
                entry.init = 0
            self.var_entries.append(entry)
        else:
            entry.is_pyglobal = 1
        if Options.cimport_from_pyx:
            entry.used = 1
        return entry

    def declare_cfunction(self, name, type, pos,
                          cname = None, visibility = 'private', api = 0, in_pxd = 0,
                          defining = 0, modifiers = (), utility_code = None):
        # Add an entry for a C function.
        if not cname:
            if visibility == 'extern' or (visibility == 'public' and defining):
                cname = name
            else:
                cname = self.mangle(Naming.func_prefix, name)
        entry = self.lookup_here(name)
        if entry and entry.defined_in_pxd:
            if entry.visibility != "private":
                mangled_cname = self.mangle(Naming.var_prefix, name)
                if entry.cname == mangled_cname:
                    cname = name
                    entry.cname = cname
                    entry.func_cname = cname
        entry = Scope.declare_cfunction(
            self, name, type, pos,
            cname = cname, visibility = visibility, api = api, in_pxd = in_pxd,
            defining = defining, modifiers = modifiers, utility_code = utility_code)
        return entry

    def declare_global(self, name, pos):
        entry = self.lookup_here(name)
        if not entry:
            self.declare_var(name, py_object_type, pos)

    def use_utility_code(self, new_code):
        if new_code is not None:
            self.utility_code_list.append(new_code)

    def declare_c_class(self, name, pos, defining = 0, implementing = 0,
        module_name = None, base_type = None, objstruct_cname = None,
        typeobj_cname = None, typeptr_cname = None, visibility = 'private', typedef_flag = 0, api = 0,
        buffer_defaults = None, shadow = 0):
        # If this is a non-extern typedef class, expose the typedef, but use
        # the non-typedef struct internally to avoid needing forward
        # declarations for anonymous structs.
        if typedef_flag and visibility != 'extern':
            if not (visibility == 'public' or api):
                warning(pos, "ctypedef only valid for 'extern' , 'public', and 'api'", 2)
            objtypedef_cname = objstruct_cname
            typedef_flag = 0
        else:
            objtypedef_cname = None
        #
        #  Look for previous declaration as a type
        #
        entry = self.lookup_here(name)
        if entry and not shadow:
            type = entry.type
            if not (entry.is_type and type.is_extension_type):
                entry = None # Will cause redeclaration and produce an error
            else:
                scope = type.scope
                if typedef_flag and (not scope or scope.defined):
                    self.check_previous_typedef_flag(entry, typedef_flag, pos)
                if (scope and scope.defined) or (base_type and type.base_type):
                    if base_type and base_type is not type.base_type:
                        error(pos, "Base type does not match previous declaration")
                if base_type and not type.base_type:
                    type.base_type = base_type
        #
        #  Make a new entry if needed
        #
        if not entry or shadow:
            type = PyrexTypes.PyExtensionType(name, typedef_flag, base_type, visibility == 'extern')
            type.pos = pos
            type.buffer_defaults = buffer_defaults
            if objtypedef_cname is not None:
                type.objtypedef_cname = objtypedef_cname
            if visibility == 'extern':
                type.module_name = module_name
            else:
                type.module_name = self.qualified_name
            if typeptr_cname:
                type.typeptr_cname = typeptr_cname
            else:
                type.typeptr_cname = self.mangle(Naming.typeptr_prefix, name)
            entry = self.declare_type(name, type, pos, visibility = visibility,
                defining = 0, shadow = shadow)
            entry.is_cclass = True
            if objstruct_cname:
                type.objstruct_cname = objstruct_cname
            elif not entry.in_cinclude:
                type.objstruct_cname = self.mangle(Naming.objstruct_prefix, name)
            else:
                error(entry.pos,
                    "Object name required for 'public' or 'extern' C class")
            self.attach_var_entry_to_c_class(entry)
            self.c_class_entries.append(entry)
        #
        #  Check for re-definition and create scope if needed
        #
        if not type.scope:
            if defining or implementing:
                scope = CClassScope(name = name, outer_scope = self,
                    visibility = visibility)
                scope.directives = self.directives.copy()
                if base_type and base_type.scope:
                    scope.declare_inherited_c_attributes(base_type.scope)
                type.set_scope(scope)
                self.type_entries.append(entry)
        else:
            if defining and type.scope.defined:
                error(pos, "C class '%s' already defined" % name)
            elif implementing and type.scope.implemented:
                error(pos, "C class '%s' already implemented" % name)
        #
        #  Fill in options, checking for compatibility with any previous declaration
        #
        if defining:
            entry.defined_in_pxd = 1
        if implementing:   # So that filenames in runtime exceptions refer to
            entry.pos = pos  # the .pyx file and not the .pxd file
        if visibility != 'private' and entry.visibility != visibility:
            error(pos, "Class '%s' previously declared as '%s'"
                % (name, entry.visibility))
        if api:
            entry.api = 1
        if objstruct_cname:
            if type.objstruct_cname and type.objstruct_cname != objstruct_cname:
                error(pos, "Object struct name differs from previous declaration")
            type.objstruct_cname = objstruct_cname
        if typeobj_cname:
            if type.typeobj_cname and type.typeobj_cname != typeobj_cname:
                    error(pos, "Type object name differs from previous declaration")
            type.typeobj_cname = typeobj_cname

        if self.directives.get('final'):
            entry.type.is_final_type = True

        # cdef classes are always exported, but we need to set it to
        # distinguish between unused Cython utility code extension classes
        entry.used = True

        #
        # Return new or existing entry
        #
        return entry

    def allocate_vtable_names(self, entry):
        #  If extension type has a vtable, allocate vtable struct and
        #  slot names for it.
        type = entry.type
        if type.base_type and type.base_type.vtabslot_cname:
            #print "...allocating vtabslot_cname because base type has one" ###
            type.vtabslot_cname = "%s.%s" % (
                Naming.obj_base_cname, type.base_type.vtabslot_cname)
        elif type.scope and type.scope.cfunc_entries:
            # one special case here: when inheriting from builtin
            # types, the methods may also be built-in, in which
            # case they won't need a vtable
            entry_count = len(type.scope.cfunc_entries)
            base_type = type.base_type
            while base_type:
                # FIXME: this will break if we ever get non-inherited C methods
                if not base_type.scope or entry_count > len(base_type.scope.cfunc_entries):
                    break
                if base_type.is_builtin_type:
                    # builtin base type defines all methods => no vtable needed
                    return
                base_type = base_type.base_type
            #print "...allocating vtabslot_cname because there are C methods" ###
            type.vtabslot_cname = Naming.vtabslot_cname
        if type.vtabslot_cname:
            #print "...allocating other vtable related cnames" ###
            type.vtabstruct_cname = self.mangle(Naming.vtabstruct_prefix, entry.name)
            type.vtabptr_cname = self.mangle(Naming.vtabptr_prefix, entry.name)

    def check_c_classes_pxd(self):
        # Performs post-analysis checking and finishing up of extension types
        # being implemented in this module. This is called only for the .pxd.
        #
        # Checks all extension types declared in this scope to
        # make sure that:
        #
        #    * The extension type is fully declared
        #
        # Also allocates a name for the vtable if needed.
        #
        for entry in self.c_class_entries:
            # Check defined
            if not entry.type.scope:
                error(entry.pos, "C class '%s' is declared but not defined" % entry.name)

    def check_c_class(self, entry):
        type = entry.type
        name = entry.name
        visibility = entry.visibility
        # Check defined
        if not type.scope:
            error(entry.pos, "C class '%s' is declared but not defined" % name)
        # Generate typeobj_cname
        if visibility != 'extern' and not type.typeobj_cname:
            type.typeobj_cname = self.mangle(Naming.typeobj_prefix, name)
        ## Generate typeptr_cname
        #type.typeptr_cname = self.mangle(Naming.typeptr_prefix, name)
        # Check C methods defined
        if type.scope:
            for method_entry in type.scope.cfunc_entries:
                if not method_entry.is_inherited and not method_entry.func_cname:
                    error(method_entry.pos, "C method '%s' is declared but not defined" %
                        method_entry.name)
        # Allocate vtable name if necessary
        if type.vtabslot_cname:
            #print "ModuleScope.check_c_classes: allocating vtable cname for", self ###
            type.vtable_cname = self.mangle(Naming.vtable_prefix, entry.name)

    def check_c_classes(self):
        # Performs post-analysis checking and finishing up of extension types
        # being implemented in this module. This is called only for the main
        # .pyx file scope, not for cimported .pxd scopes.
        #
        # Checks all extension types declared in this scope to
        # make sure that:
        #
        #    * The extension type is implemented
        #    * All required object and type names have been specified or generated
        #    * All non-inherited C methods are implemented
        #
        # Also allocates a name for the vtable if needed.
        #
        debug_check_c_classes = 0
        if debug_check_c_classes:
            print("Scope.check_c_classes: checking scope " + self.qualified_name)
        for entry in self.c_class_entries:
            if debug_check_c_classes:
                print("...entry %s %s" % (entry.name, entry))
                print("......type = ",  entry.type)
                print("......visibility = ", entry.visibility)
            self.check_c_class(entry)

    def check_c_functions(self):
        # Performs post-analysis checking making sure all
        # defined c functions are actually implemented.
        for name, entry in self.entries.items():
            if entry.is_cfunction:
                if (entry.defined_in_pxd
                        and entry.scope is self
                        and entry.visibility != 'extern'
                        and not entry.in_cinclude
                        and not entry.is_implemented):
                    error(entry.pos, "Non-extern C function '%s' declared but not defined" % name)

    def attach_var_entry_to_c_class(self, entry):
        # The name of an extension class has to serve as both a type
        # name and a variable name holding the type object. It is
        # represented in the symbol table by a type entry with a
        # variable entry attached to it. For the variable entry,
        # we use a read-only C global variable whose name is an
        # expression that refers to the type object.
        import Builtin
        var_entry = Entry(name = entry.name,
            type = Builtin.type_type,
            pos = entry.pos,
            cname = "((PyObject*)%s)" % entry.type.typeptr_cname)
        var_entry.is_variable = 1
        var_entry.is_cglobal = 1
        var_entry.is_readonly = 1
        entry.as_variable = var_entry

    def is_cpp(self):
        return self.cpp

    def infer_types(self):
        from TypeInference import PyObjectTypeInferer
        PyObjectTypeInferer().infer_types(self)


class LocalScope(Scope):

    # Does the function have a 'with gil:' block?
    has_with_gil_block = False

    # Transient attribute, used for symbol table variable declarations
    _in_with_gil_block = False

    def __init__(self, name, outer_scope, parent_scope = None):
        if parent_scope is None:
            parent_scope = outer_scope
        Scope.__init__(self, name, outer_scope, parent_scope)

    def mangle(self, prefix, name):
        return prefix + name

    def declare_arg(self, name, type, pos):
        # Add an entry for an argument of a function.
        cname = self.mangle(Naming.var_prefix, name)
        entry = self.declare(name, cname, type, pos, 'private')
        entry.is_variable = 1
        if type.is_pyobject:
            entry.init = "0"
        entry.is_arg = 1
        #entry.borrowed = 1 # Not using borrowed arg refs for now
        self.arg_entries.append(entry)
        return entry

    def declare_var(self, name, type, pos,
                    cname = None, visibility = 'private',
                    api = 0, in_pxd = 0, is_cdef = 0):
        # Add an entry for a local variable.
        if visibility in ('public', 'readonly'):
            error(pos, "Local variable cannot be declared %s" % visibility)
        entry = Scope.declare_var(self, name, type, pos,
                                  cname=cname, visibility=visibility,
                                  api=api, in_pxd=in_pxd, is_cdef=is_cdef)
        if type.is_pyobject:
            entry.init = "0"
        entry.is_local = 1

        entry.in_with_gil_block = self._in_with_gil_block
        self.var_entries.append(entry)
        return entry

    def declare_global(self, name, pos):
        # Pull entry from global scope into local scope.
        if self.lookup_here(name):
            warning(pos, "'%s' redeclared  ", 0)
        else:
            entry = self.global_scope().lookup_target(name)
            self.entries[name] = entry

    def declare_nonlocal(self, name, pos):
        # Pull entry from outer scope into local scope
        orig_entry = self.lookup_here(name)
        if orig_entry and orig_entry.scope is self and not orig_entry.from_closure:
            error(pos, "'%s' redeclared as nonlocal" % name)
        else:
            entry = self.lookup(name)
            if entry is None or not entry.from_closure:
                error(pos, "no binding for nonlocal '%s' found" % name)

    def lookup(self, name):
        # Look up name in this scope or an enclosing one.
        # Return None if not found.
        entry = Scope.lookup(self, name)
        if entry is not None:
            if entry.scope is not self and entry.scope.is_closure_scope:
                if hasattr(entry.scope, "scope_class"):
                    raise InternalError("lookup() after scope class created.")
                # The actual c fragment for the different scopes differs
                # on the outside and inside, so we make a new entry
                entry.in_closure = True
                inner_entry = InnerEntry(entry, self)
                inner_entry.is_variable = True
                self.entries[name] = inner_entry
                return inner_entry
        return entry

    def mangle_closure_cnames(self, outer_scope_cname):
        for entry in self.entries.values():
            if entry.from_closure:
                cname = entry.outer_entry.cname
                if self.is_passthrough:
                    entry.cname = cname
                else:
                    if cname.startswith(Naming.cur_scope_cname):
                        cname = cname[len(Naming.cur_scope_cname)+2:]
                    entry.cname = "%s->%s" % (outer_scope_cname, cname)
            elif entry.in_closure:
                entry.original_cname = entry.cname
                entry.cname = "%s->%s" % (Naming.cur_scope_cname, entry.cname)


class GeneratorExpressionScope(Scope):
    """Scope for generator expressions and comprehensions.  As opposed
    to generators, these can be easily inlined in some cases, so all
    we really need is a scope that holds the loop variable(s).
    """
    def __init__(self, outer_scope):
        name = outer_scope.global_scope().next_id(Naming.genexpr_id_ref)
        Scope.__init__(self, name, outer_scope, outer_scope)
        self.directives = outer_scope.directives
        self.genexp_prefix = "%s%d%s" % (Naming.pyrex_prefix, len(name), name)

    def mangle(self, prefix, name):
        return '%s%s' % (self.genexp_prefix, self.parent_scope.mangle(prefix, name))

    def declare_var(self, name, type, pos,
                    cname = None, visibility = 'private',
                    api = 0, in_pxd = 0, is_cdef = True):
        if type is unspecified_type:
            # if the outer scope defines a type for this variable, inherit it
            outer_entry = self.outer_scope.lookup(name)
            if outer_entry and outer_entry.is_variable:
                type = outer_entry.type # may still be 'unspecified_type' !
        # the parent scope needs to generate code for the variable, but
        # this scope must hold its name exclusively
        cname = '%s%s' % (self.genexp_prefix, self.parent_scope.mangle(Naming.var_prefix, name or self.next_id()))
        entry = self.declare(name, cname, type, pos, visibility)
        entry.is_variable = 1
        entry.is_local = 1
        self.var_entries.append(entry)
        self.entries[name] = entry
        return entry

    def declare_pyfunction(self, name, pos, allow_redefine=False):
        return self.outer_scope.declare_pyfunction(
            name, pos, allow_redefine)

    def declare_lambda_function(self, func_cname, pos):
        return self.outer_scope.declare_lambda_function(func_cname, pos)

    def add_lambda_def(self, def_node):
        return self.outer_scope.add_lambda_def(def_node)


class ClosureScope(LocalScope):

    is_closure_scope = True

    def __init__(self, name, scope_name, outer_scope, parent_scope=None):
        LocalScope.__init__(self, name, outer_scope, parent_scope)
        self.closure_cname = "%s%s" % (Naming.closure_scope_prefix, scope_name)

#    def mangle_closure_cnames(self, scope_var):
#        for entry in self.entries.values() + self.temp_entries:
#            entry.in_closure = 1
#        LocalScope.mangle_closure_cnames(self, scope_var)

#    def mangle(self, prefix, name):
#        return "%s->%s" % (self.cur_scope_cname, name)
#        return "%s->%s" % (self.closure_cname, name)

    def declare_pyfunction(self, name, pos, allow_redefine=False):
        return LocalScope.declare_pyfunction(self, name, pos, allow_redefine, visibility='private')


class StructOrUnionScope(Scope):
    #  Namespace of a C struct or union.

    def __init__(self, name="?"):
        Scope.__init__(self, name, None, None)

    def declare_var(self, name, type, pos,
                    cname = None, visibility = 'private',
                    api = 0, in_pxd = 0, is_cdef = 0,
                    allow_pyobject = 0):
        # Add an entry for an attribute.
        if not cname:
            cname = name
            if visibility == 'private':
                cname = c_safe_identifier(cname)
        if type.is_cfunction:
            type = PyrexTypes.CPtrType(type)
        entry = self.declare(name, cname, type, pos, visibility)
        entry.is_variable = 1
        self.var_entries.append(entry)
        if type.is_pyobject and not allow_pyobject:
            error(pos,
                  "C struct/union member cannot be a Python object")
        if visibility != 'private':
            error(pos,
                  "C struct/union member cannot be declared %s" % visibility)
        return entry

    def declare_cfunction(self, name, type, pos,
                          cname = None, visibility = 'private', api = 0, in_pxd = 0,
                          defining = 0, modifiers = ()): # currently no utility code ...
        return self.declare_var(name, type, pos,
                                cname=cname, visibility=visibility)


class ClassScope(Scope):
    #  Abstract base class for namespace of
    #  Python class or extension type.
    #
    #  class_name     string   Python name of the class
    #  scope_prefix   string   Additional prefix for names
    #                          declared in the class
    #  doc    string or None   Doc string

    def __init__(self, name, outer_scope):
        Scope.__init__(self, name, outer_scope, outer_scope)
        self.class_name = name
        self.doc = None

    def lookup(self, name):
        entry = Scope.lookup(self, name)
        if entry:
            return entry
        if name == "classmethod":
            # We don't want to use the builtin classmethod here 'cause it won't do the
            # right thing in this scope (as the class members aren't still functions).
            # Don't want to add a cfunction to this scope 'cause that would mess with
            # the type definition, so we just return the right entry.
            entry = Entry(
                "classmethod",
                "__Pyx_Method_ClassMethod",
                PyrexTypes.CFuncType(
                    py_object_type,
                    [PyrexTypes.CFuncTypeArg("", py_object_type, None)], 0, 0))
            entry.utility_code_definition = Code.UtilityCode.load_cached("ClassMethod", "CythonFunction.c")
            entry.is_cfunction = 1
        return entry


class PyClassScope(ClassScope):
    #  Namespace of a Python class.
    #
    #  class_obj_cname     string   C variable holding class object

    is_py_class_scope = 1

    def mangle_class_private_name(self, name):
        return self.mangle_special_name(name)

    def mangle_special_name(self, name):
        if name and name.startswith('__') and not name.endswith('__'):
            name = EncodedString('_%s%s' % (self.class_name.lstrip('_'), name))
        return name

    def lookup_here(self, name):
        name = self.mangle_special_name(name)
        return ClassScope.lookup_here(self, name)

    def declare_var(self, name, type, pos,
                    cname = None, visibility = 'private',
                    api = 0, in_pxd = 0, is_cdef = 0):
        name = self.mangle_special_name(name)
        if type is unspecified_type:
            type = py_object_type
        # Add an entry for a class attribute.
        entry = Scope.declare_var(self, name, type, pos,
                                  cname=cname, visibility=visibility,
                                  api=api, in_pxd=in_pxd, is_cdef=is_cdef)
        entry.is_pyglobal = 1
        entry.is_pyclass_attr = 1
        return entry

    def declare_nonlocal(self, name, pos):
        # Pull entry from outer scope into local scope
        orig_entry = self.lookup_here(name)
        if orig_entry and orig_entry.scope is self and not orig_entry.from_closure:
            error(pos, "'%s' redeclared as nonlocal" % name)
        else:
            entry = self.lookup(name)
            if entry is None:
                error(pos, "no binding for nonlocal '%s' found" % name)
            else:
                # FIXME: this works, but it's unclear if it's the
                # right thing to do
                self.entries[name] = entry

    def declare_global(self, name, pos):
        # Pull entry from global scope into local scope.
        if self.lookup_here(name):
            warning(pos, "'%s' redeclared  ", 0)
        else:
            entry = self.global_scope().lookup_target(name)
            self.entries[name] = entry

    def add_default_value(self, type):
        return self.outer_scope.add_default_value(type)


class CClassScope(ClassScope):
    #  Namespace of an extension type.
    #
    #  parent_type           CClassType
    #  #typeobj_cname        string or None
    #  #objstruct_cname      string
    #  method_table_cname    string
    #  getset_table_cname    string
    #  has_pyobject_attrs    boolean  Any PyObject attributes?
    #  has_memoryview_attrs  boolean  Any memory view attributes?
    #  has_cyclic_pyobject_attrs    boolean  Any PyObject attributes that may need GC?
    #  property_entries      [Entry]
    #  defined               boolean  Defined in .pxd file
    #  implemented           boolean  Defined in .pyx file
    #  inherited_var_entries [Entry]  Adapted var entries from base class

    is_c_class_scope = 1

    has_pyobject_attrs = False
    has_memoryview_attrs = False
    has_cyclic_pyobject_attrs = False
    defined = False
    implemented = False

    def __init__(self, name, outer_scope, visibility):
        ClassScope.__init__(self, name, outer_scope)
        if visibility != 'extern':
            self.method_table_cname = outer_scope.mangle(Naming.methtab_prefix, name)
            self.getset_table_cname = outer_scope.mangle(Naming.gstab_prefix, name)
        self.property_entries = []
        self.inherited_var_entries = []

    def needs_gc(self):
        # If the type or any of its base types have Python-valued
        # C attributes, then it needs to participate in GC.
        if self.has_cyclic_pyobject_attrs:
            return True
        base_type = self.parent_type.base_type
        if base_type and base_type.scope is not None:
            return base_type.scope.needs_gc()
        elif self.parent_type.is_builtin_type:
            return not self.parent_type.is_gc_simple
        return False

    def needs_tp_clear(self):
        """
        Do we need to generate an implementation for the tp_clear slot? Can
        be disabled to keep references for the __dealloc__ cleanup function.
        """
        return self.needs_gc() and not self.directives.get('no_gc_clear', False)

    def get_refcounted_entries(self, include_weakref=False,
                               include_gc_simple=True):
        py_attrs = []
        py_buffers = []
        memoryview_slices = []

        for entry in self.var_entries:
            if entry.type.is_pyobject:
                if include_weakref or entry.name != "__weakref__":
                    if include_gc_simple or not entry.type.is_gc_simple:
                        py_attrs.append(entry)
            elif entry.type == PyrexTypes.c_py_buffer_type:
                py_buffers.append(entry)
            elif entry.type.is_memoryviewslice:
                memoryview_slices.append(entry)

        have_entries = py_attrs or py_buffers or memoryview_slices
        return have_entries, (py_attrs, py_buffers, memoryview_slices)

    def declare_var(self, name, type, pos,
                    cname = None, visibility = 'private',
                    api = 0, in_pxd = 0, is_cdef = 0):
        if is_cdef:
            # Add an entry for an attribute.
            if self.defined:
                error(pos,
                    "C attributes cannot be added in implementation part of"
                    " extension type defined in a pxd")
            if get_special_method_signature(name):
                error(pos,
                    "The name '%s' is reserved for a special method."
                        % name)
            if not cname:
                cname = name
                if visibility == 'private':
                    cname = c_safe_identifier(cname)
            if type.is_cpp_class and visibility != 'extern':
                type.check_nullary_constructor(pos)
                self.use_utility_code(Code.UtilityCode("#include <new>"))
            entry = self.declare(name, cname, type, pos, visibility)
            entry.is_variable = 1
            self.var_entries.append(entry)
            if type.is_memoryviewslice:
                self.has_memoryview_attrs = True
            elif type.is_pyobject and name != '__weakref__':
                self.has_pyobject_attrs = True
                if (not type.is_builtin_type
                        or not type.scope or type.scope.needs_gc()):
                    self.has_cyclic_pyobject_attrs = True
            if visibility not in ('private', 'public', 'readonly'):
                error(pos,
                    "Attribute of extension type cannot be declared %s" % visibility)
            if visibility in ('public', 'readonly'):
                # If the field is an external typedef, we cannot be sure about the type,
                # so do conversion ourself rather than rely on the CPython mechanism (through
                # a property; made in AnalyseDeclarationsTransform).
                entry.needs_property = True
                if name == "__weakref__":
                    error(pos, "Special attribute __weakref__ cannot be exposed to Python")
                if not type.is_pyobject:
                    if (not type.create_to_py_utility_code(self) or
                        (visibility=='public' and not
                         type.create_from_py_utility_code(self))):
                        error(pos,
                              "C attribute of type '%s' cannot be accessed from Python" % type)
            else:
                entry.needs_property = False
            return entry
        else:
            if type is unspecified_type:
                type = py_object_type
            # Add an entry for a class attribute.
            entry = Scope.declare_var(self, name, type, pos,
                                      cname=cname, visibility=visibility,
                                      api=api, in_pxd=in_pxd, is_cdef=is_cdef)
            entry.is_member = 1
            entry.is_pyglobal = 1 # xxx: is_pyglobal changes behaviour in so many places that
                                  # I keep it in for now. is_member should be enough
                                  # later on
            self.namespace_cname = "(PyObject *)%s" % self.parent_type.typeptr_cname
            return entry

    def declare_pyfunction(self, name, pos, allow_redefine=False):
        # Add an entry for a method.
        if name in ('__eq__', '__ne__', '__lt__', '__gt__', '__le__', '__ge__'):
            error(pos, "Special method %s must be implemented via __richcmp__" % name)
        if name == "__new__":
            error(pos, "__new__ method of extension type will change semantics "
                "in a future version of Pyrex and Cython. Use __cinit__ instead.")
        entry = self.declare_var(name, py_object_type, pos,
                                 visibility='extern')
        special_sig = get_special_method_signature(name)
        if special_sig:
            # Special methods get put in the method table with a particular
            # signature declared in advance.
            entry.signature = special_sig
            entry.is_special = 1
        else:
            entry.signature = pymethod_signature
            entry.is_special = 0

        self.pyfunc_entries.append(entry)
        return entry

    def lookup_here(self, name):
        if name == "__new__":
            name = EncodedString("__cinit__")
        entry = ClassScope.lookup_here(self, name)
        if entry and entry.is_builtin_cmethod:
            if not self.parent_type.is_builtin_type:
                # For subtypes of builtin types, we can only return
                # optimised C methods if the type if final.
                # Otherwise, subtypes may choose to override the
                # method, but the optimisation would prevent the
                # subtype method from being called.
                if not self.parent_type.is_final_type:
                    return None
        return entry

    def declare_cfunction(self, name, type, pos,
                          cname = None, visibility = 'private', api = 0, in_pxd = 0,
                          defining = 0, modifiers = (), utility_code = None):
        if get_special_method_signature(name) and not self.parent_type.is_builtin_type:
            error(pos, "Special methods must be declared with 'def', not 'cdef'")
        args = type.args
        if not args:
            error(pos, "C method has no self argument")
        elif not self.parent_type.assignable_from(args[0].type):
            error(pos, "Self argument (%s) of C method '%s' does not match parent type (%s)" %
                  (args[0].type, name, self.parent_type))
        entry = self.lookup_here(name)
        if cname is None:
            cname = c_safe_identifier(name)
        if entry:
            if not entry.is_cfunction:
                warning(pos, "'%s' redeclared  " % name, 0)
            else:
                if defining and entry.func_cname:
                    error(pos, "'%s' already defined" % name)
                #print "CClassScope.declare_cfunction: checking signature" ###
                if entry.is_final_cmethod and entry.is_inherited:
                    error(pos, "Overriding final methods is not allowed")
                elif type.same_c_signature_as(entry.type, as_cmethod = 1) and type.nogil == entry.type.nogil:
                    pass
                elif type.compatible_signature_with(entry.type, as_cmethod = 1) and type.nogil == entry.type.nogil:
                    entry = self.add_cfunction(name, type, pos, cname, visibility='ignore', modifiers=modifiers)
                    defining = 1
                else:
                    error(pos, "Signature not compatible with previous declaration")
                    error(entry.pos, "Previous declaration is here")
        else:
            if self.defined:
                error(pos,
                    "C method '%s' not previously declared in definition part of"
                    " extension type" % name)
            entry = self.add_cfunction(name, type, pos, cname,
                                       visibility, modifiers)
        if defining:
            entry.func_cname = self.mangle(Naming.func_prefix, name)
        entry.utility_code = utility_code
        type.entry = entry

        if u'inline' in modifiers:
            entry.is_inline_cmethod = True

        if (self.parent_type.is_final_type or entry.is_inline_cmethod or
            self.directives.get('final')):
            entry.is_final_cmethod = True
            entry.final_func_cname = entry.func_cname

        return entry

    def add_cfunction(self, name, type, pos, cname, visibility, modifiers):
        # Add a cfunction entry without giving it a func_cname.
        prev_entry = self.lookup_here(name)
        entry = ClassScope.add_cfunction(self, name, type, pos, cname,
                                         visibility, modifiers)
        entry.is_cmethod = 1
        entry.prev_entry = prev_entry
        return entry

    def declare_builtin_cfunction(self, name, type, cname, utility_code = None):
        # overridden methods of builtin types still have their Python
        # equivalent that must be accessible to support bound methods
        name = EncodedString(name)
        entry = self.declare_cfunction(name, type, None, cname, visibility='extern',
                                       utility_code = utility_code)
        var_entry = Entry(name, name, py_object_type)
        var_entry.is_variable = 1
        var_entry.is_builtin = 1
        var_entry.utility_code = utility_code
        entry.as_variable = var_entry
        return entry

    def declare_property(self, name, doc, pos):
        entry = self.lookup_here(name)
        if entry is None:
            entry = self.declare(name, name, py_object_type, pos, 'private')
        entry.is_property = 1
        entry.doc = doc
        entry.scope = PropertyScope(name,
            outer_scope = self.global_scope(), parent_scope = self)
        entry.scope.parent_type = self.parent_type
        self.property_entries.append(entry)
        return entry

    def declare_inherited_c_attributes(self, base_scope):
        # Declare entries for all the C attributes of an
        # inherited type, with cnames modified appropriately
        # to work with this type.
        def adapt(cname):
            return "%s.%s" % (Naming.obj_base_cname, base_entry.cname)

        entries = base_scope.inherited_var_entries + base_scope.var_entries
        for base_entry in entries:
            entry = self.declare(
                base_entry.name, adapt(base_entry.cname),
                base_entry.type, None, 'private')
            entry.is_variable = 1
            self.inherited_var_entries.append(entry)

        # If the class defined in a pxd, specific entries have not been added.
        # Ensure now that the parent (base) scope has specific entries
        # Iterate over a copy as get_all_specialized_function_types() will mutate
        for base_entry in base_scope.cfunc_entries[:]:
            if base_entry.type.is_fused:
                base_entry.type.get_all_specialized_function_types()

        for base_entry in base_scope.cfunc_entries:
            cname = base_entry.cname
            var_entry = base_entry.as_variable
            is_builtin = var_entry and var_entry.is_builtin
            if not is_builtin:
                cname = adapt(cname)
            entry = self.add_cfunction(base_entry.name, base_entry.type,
                                       base_entry.pos, cname,
                                       base_entry.visibility, base_entry.func_modifiers)
            entry.is_inherited = 1
            if base_entry.is_final_cmethod:
                entry.is_final_cmethod = True
                entry.is_inline_cmethod = base_entry.is_inline_cmethod
                if (self.parent_scope == base_scope.parent_scope or
                        entry.is_inline_cmethod):
                    entry.final_func_cname = base_entry.final_func_cname
            if is_builtin:
                entry.is_builtin_cmethod = True
                entry.as_variable = var_entry
            if base_entry.utility_code:
                entry.utility_code = base_entry.utility_code


class CppClassScope(Scope):
    #  Namespace of a C++ class.

    is_cpp_class_scope = 1

    default_constructor = None
    type = None

    def __init__(self, name, outer_scope, templates=None):
        Scope.__init__(self, name, outer_scope, None)
        self.directives = outer_scope.directives
        self.inherited_var_entries = []
        if templates is not None:
            for T in templates:
                template_entry = self.declare(
                    T, T, PyrexTypes.TemplatePlaceholderType(T), None, 'extern')
                template_entry.is_type = 1

    def declare_var(self, name, type, pos,
                    cname = None, visibility = 'extern',
                    api = 0, in_pxd = 0, is_cdef = 0,
                    allow_pyobject = 0, defining = 0):
        # Add an entry for an attribute.
        if not cname:
            cname = name
        entry = self.lookup_here(name)
        if defining and entry is not None:
            if not entry.type.same_as(type):
                error(pos, "Function signature does not match previous declaration")
        else:
            entry = self.declare(name, cname, type, pos, visibility)
        entry.is_variable = 1
        if type.is_cfunction and self.type:
            entry.func_cname = "%s::%s" % (self.type.declaration_code(""), cname)
        if name != "this" and (defining or name != "<init>"):
            self.var_entries.append(entry)
        if type.is_pyobject and not allow_pyobject:
            error(pos,
                "C++ class member cannot be a Python object")
        return entry

    def check_base_default_constructor(self, pos):
        # Look for default constructors in all base classes.
        if self.default_constructor is None:
            entry = self.lookup(self.name)
            if not entry.type.base_classes:
                self.default_constructor = True
                return
            for base_class in entry.type.base_classes:
                if base_class is PyrexTypes.error_type:
                    continue
                temp_entry = base_class.scope.lookup_here("<init>")
                found = False
                if temp_entry is None:
                    continue
                for alternative in temp_entry.all_alternatives():
                    type = alternative.type
                    if type.is_ptr:
                        type = type.base_type
                    if not type.args:
                        found = True
                        break
                if not found:
                    self.default_constructor = temp_entry.scope.name
                    error(pos, "no matching function for call to " \
                            "%s::%s()" % (temp_entry.scope.name, temp_entry.scope.name))
        elif not self.default_constructor:
            error(pos, "no matching function for call to %s::%s()" %
                  (self.default_constructor, self.default_constructor))

    def declare_cfunction(self, name, type, pos,
                          cname = None, visibility = 'extern', api = 0, in_pxd = 0,
                          defining = 0, modifiers = (), utility_code = None):
        if name in (self.name.split('::')[-1], '__init__') and cname is None:
            self.check_base_default_constructor(pos)
            cname = self.type.cname
            name = '<init>'
            type.return_type = PyrexTypes.InvisibleVoidType()
        elif name == '__dealloc__' and cname is None:
            cname = "~%s" % self.type.cname
            name = '<del>'
            type.return_type = PyrexTypes.InvisibleVoidType()
        prev_entry = self.lookup_here(name)
        entry = self.declare_var(name, type, pos,
                                 defining=defining,
                                 cname=cname, visibility=visibility)
        if prev_entry and not defining:
            entry.overloaded_alternatives = prev_entry.all_alternatives()
        entry.utility_code = utility_code
        type.entry = entry
        return entry

    def declare_inherited_cpp_attributes(self, base_scope):
        # Declare entries for all the C++ attributes of an
        # inherited type, with cnames modified appropriately
        # to work with this type.
        for base_entry in \
            base_scope.inherited_var_entries + base_scope.var_entries:
                #contructor is not inherited
                if base_entry.name == "<init>":
                    continue
                #print base_entry.name, self.entries
                if base_entry.name in self.entries:
                    base_entry.name    # FIXME: is there anything to do in this case?
                entry = self.declare(base_entry.name, base_entry.cname,
                    base_entry.type, None, 'extern')
                entry.is_variable = 1
                self.inherited_var_entries.append(entry)
        for base_entry in base_scope.cfunc_entries:
            entry = self.declare_cfunction(base_entry.name, base_entry.type,
                                           base_entry.pos, base_entry.cname,
                                           base_entry.visibility, 0,
                                           modifiers = base_entry.func_modifiers,
                                           utility_code = base_entry.utility_code)
            entry.is_inherited = 1

    def specialize(self, values):
        scope = CppClassScope(self.name, self.outer_scope)
        for entry in self.entries.values():
            if entry.is_type:
                scope.declare_type(entry.name,
                                   entry.type.specialize(values),
                                   entry.pos,
                                   entry.cname,
                                   template=1)
            elif entry.type.is_cfunction:
                for e in entry.all_alternatives():
                    scope.declare_cfunction(e.name,
                                            e.type.specialize(values),
                                            e.pos,
                                            e.cname,
                                            utility_code = e.utility_code)
            else:
                scope.declare_var(entry.name,
                                  entry.type.specialize(values),
                                  entry.pos,
                                  entry.cname,
                                  entry.visibility)

        return scope


class PropertyScope(Scope):
    #  Scope holding the __get__, __set__ and __del__ methods for
    #  a property of an extension type.
    #
    #  parent_type   PyExtensionType   The type to which the property belongs

    is_property_scope = 1

    def declare_pyfunction(self, name, pos, allow_redefine=False):
        # Add an entry for a method.
        signature = get_property_accessor_signature(name)
        if signature:
            entry = self.declare(name, name, py_object_type, pos, 'private')
            entry.is_special = 1
            entry.signature = signature
            return entry
        else:
            error(pos, "Only __get__, __set__ and __del__ methods allowed "
                "in a property declaration")
            return None


class CConstScope(Scope):

    def __init__(self, const_base_type_scope):
        Scope.__init__(
            self,
            'const_' + const_base_type_scope.name,
            const_base_type_scope.outer_scope,
            const_base_type_scope.parent_scope)
        self.const_base_type_scope = const_base_type_scope

    def lookup_here(self, name):
        entry = self.const_base_type_scope.lookup_here(name)
        if entry is not None:
            entry = copy.copy(entry)
            entry.type = PyrexTypes.c_const_type(entry.type)
            return entry

class TemplateScope(Scope):
    def __init__(self, name, outer_scope):
        Scope.__init__(self, name, outer_scope, None)
        self.directives = outer_scope.directives
