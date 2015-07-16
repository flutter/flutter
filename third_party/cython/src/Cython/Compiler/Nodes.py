#
#   Parse tree nodes
#

import cython
cython.declare(sys=object, os=object, copy=object,
               Builtin=object, error=object, warning=object, Naming=object, PyrexTypes=object,
               py_object_type=object, ModuleScope=object, LocalScope=object, ClosureScope=object,
               StructOrUnionScope=object, PyClassScope=object,
               CppClassScope=object, UtilityCode=object, EncodedString=object,
               absolute_path_length=cython.Py_ssize_t)

import sys, os, copy
from itertools import chain

import Builtin
from Errors import error, warning, InternalError, CompileError
import Naming
import PyrexTypes
import TypeSlots
from PyrexTypes import py_object_type, error_type
from Symtab import (ModuleScope, LocalScope, ClosureScope,
    StructOrUnionScope, PyClassScope, CppClassScope, TemplateScope)
from Code import UtilityCode
from StringEncoding import EncodedString, escape_byte_string, split_string_literal
import Options
import DebugFlags
from Cython.Utils import cached_function

absolute_path_length = 0

def relative_position(pos):
    """
    We embed the relative filename in the generated C file, since we
    don't want to have to regenerate and compile all the source code
    whenever the Python install directory moves (which could happen,
    e.g,. when distributing binaries.)

    INPUT:
        a position tuple -- (absolute filename, line number column position)

    OUTPUT:
        relative filename
        line number

    AUTHOR: William Stein
    """
    global absolute_path_length
    if absolute_path_length==0:
        absolute_path_length = len(os.path.abspath(os.getcwd()))
    return (pos[0].get_filenametable_entry()[absolute_path_length+1:], pos[1])

def embed_position(pos, docstring):
    if not Options.embed_pos_in_docstring:
        return docstring
    pos_line = u'File: %s (starting at line %s)' % relative_position(pos)
    if docstring is None:
        # unicode string
        return EncodedString(pos_line)

    # make sure we can encode the filename in the docstring encoding
    # otherwise make the docstring a unicode string
    encoding = docstring.encoding
    if encoding is not None:
        try:
            pos_line.encode(encoding)
        except UnicodeEncodeError:
            encoding = None

    if not docstring:
        # reuse the string encoding of the original docstring
        doc = EncodedString(pos_line)
    else:
        doc = EncodedString(pos_line + u'\n' + docstring)
    doc.encoding = encoding
    return doc


def write_func_call(func, codewriter_class):
    def f(*args, **kwds):
        if len(args) > 1 and isinstance(args[1], codewriter_class):
            # here we annotate the code with this function call
            # but only if new code is generated
            node, code = args[:2]
            marker = '                    /* %s -> %s.%s %s */' % (
                    ' ' * code.call_level,
                    node.__class__.__name__,
                    func.__name__,
                    node.pos[1:])
            pristine = code.buffer.stream.tell()
            code.putln(marker)
            start = code.buffer.stream.tell()
            code.call_level += 4
            res = func(*args, **kwds)
            code.call_level -= 4
            if start == code.buffer.stream.tell():
                code.buffer.stream.seek(pristine)
            else:
                marker = marker.replace('->', '<-')
                code.putln(marker)
            return res
        else:
            return func(*args, **kwds)
    return f

class VerboseCodeWriter(type):
    # Set this as a metaclass to trace function calls in code.
    # This slows down code generation and makes much larger files.
    def __new__(cls, name, bases, attrs):
        from types import FunctionType
        from Code import CCodeWriter
        attrs = dict(attrs)
        for mname, m in attrs.items():
            if isinstance(m, FunctionType):
                attrs[mname] = write_func_call(m, CCodeWriter)
        return super(VerboseCodeWriter, cls).__new__(cls, name, bases, attrs)


class CheckAnalysers(type):
    """Metaclass to check that type analysis functions return a node.
    """
    methods = set(['analyse_types',
                   'analyse_expressions',
                   'analyse_target_types'])

    def __new__(cls, name, bases, attrs):
        from types import FunctionType
        def check(name, func):
            def call(*args, **kwargs):
                retval = func(*args, **kwargs)
                if retval is None:
                    print name, args, kwargs
                return retval
            return call

        attrs = dict(attrs)
        for mname, m in attrs.items():
            if isinstance(m, FunctionType) and mname in cls.methods:
                attrs[mname] = check(mname, m)
        return super(CheckAnalysers, cls).__new__(cls, name, bases, attrs)


class Node(object):
    #  pos         (string, int, int)   Source file position
    #  is_name     boolean              Is a NameNode
    #  is_literal  boolean              Is a ConstNode

    #__metaclass__ = CheckAnalysers
    if DebugFlags.debug_trace_code_generation:
        __metaclass__ = VerboseCodeWriter

    is_name = 0
    is_none = 0
    is_nonecheck = 0
    is_literal = 0
    is_terminator = 0
    temps = None

    # All descendants should set child_attrs to a list of the attributes
    # containing nodes considered "children" in the tree. Each such attribute
    # can either contain a single node or a list of nodes. See Visitor.py.
    child_attrs = None

    cf_state = None

    # This may be an additional (or 'actual') type that will be checked when
    # this node is coerced to another type. This could be useful to set when
    # the actual type to which it can coerce is known, but you want to leave
    # the type a py_object_type
    coercion_type = None

    def __init__(self, pos, **kw):
        self.pos = pos
        self.__dict__.update(kw)

    gil_message = "Operation"

    nogil_check = None

    def gil_error(self, env=None):
        error(self.pos, "%s not allowed without gil" % self.gil_message)

    cpp_message = "Operation"

    def cpp_check(self, env):
        if not env.is_cpp():
            self.cpp_error()

    def cpp_error(self):
        error(self.pos, "%s only allowed in c++" % self.cpp_message)

    def clone_node(self):
        """Clone the node. This is defined as a shallow copy, except for member lists
           amongst the child attributes (from get_child_accessors) which are also
           copied. Lists containing child nodes are thus seen as a way for the node
           to hold multiple children directly; the list is not treated as a separate
           level in the tree."""
        result = copy.copy(self)
        for attrname in result.child_attrs:
            value = getattr(result, attrname)
            if isinstance(value, list):
                setattr(result, attrname, [x for x in value])
        return result


    #
    #  There are 3 phases of parse tree processing, applied in order to
    #  all the statements in a given scope-block:
    #
    #  (0) analyse_declarations
    #        Make symbol table entries for all declarations at the current
    #        level, both explicit (def, cdef, etc.) and implicit (assignment
    #        to an otherwise undeclared name).
    #
    #  (1) analyse_expressions
    #         Determine the result types of expressions and fill in the
    #         'type' attribute of each ExprNode. Insert coercion nodes into the
    #         tree where needed to convert to and from Python objects.
    #         Allocate temporary locals for intermediate results. Fill
    #         in the 'result_code' attribute of each ExprNode with a C code
    #         fragment.
    #
    #  (2) generate_code
    #         Emit C code for all declarations, statements and expressions.
    #         Recursively applies the 3 processing phases to the bodies of
    #         functions.
    #

    def analyse_declarations(self, env):
        pass

    def analyse_expressions(self, env):
        raise InternalError("analyse_expressions not implemented for %s" % \
            self.__class__.__name__)

    def generate_code(self, code):
        raise InternalError("generate_code not implemented for %s" % \
            self.__class__.__name__)

    def annotate(self, code):
        # mro does the wrong thing
        if isinstance(self, BlockNode):
            self.body.annotate(code)

    def end_pos(self):
        try:
            return self._end_pos
        except AttributeError:
            pos = self.pos
            if not self.child_attrs:
                self._end_pos = pos
                return pos
            for attr in self.child_attrs:
                child = getattr(self, attr)
                # Sometimes lists, sometimes nodes
                if child is None:
                    pass
                elif isinstance(child, list):
                    for c in child:
                        pos = max(pos, c.end_pos())
                else:
                    pos = max(pos, child.end_pos())
            self._end_pos = pos
            return pos

    def dump(self, level=0, filter_out=("pos",), cutoff=100, encountered=None):
        """Debug helper method that returns a recursive string representation of this node.
        """
        if cutoff == 0:
            return "<...nesting level cutoff...>"
        if encountered is None:
            encountered = set()
        if id(self) in encountered:
            return "<%s (0x%x) -- already output>" % (self.__class__.__name__, id(self))
        encountered.add(id(self))

        def dump_child(x, level):
            if isinstance(x, Node):
                return x.dump(level, filter_out, cutoff-1, encountered)
            elif isinstance(x, list):
                return "[%s]" % ", ".join([dump_child(item, level) for item in x])
            else:
                return repr(x)


        attrs = [(key, value) for key, value in self.__dict__.items() if key not in filter_out]
        if len(attrs) == 0:
            return "<%s (0x%x)>" % (self.__class__.__name__, id(self))
        else:
            indent = "  " * level
            res = "<%s (0x%x)\n" % (self.__class__.__name__, id(self))
            for key, value in attrs:
                res += "%s  %s: %s\n" % (indent, key, dump_child(value, level + 1))
            res += "%s>" % indent
            return res

    def dump_pos(self, mark_column=False, marker='(#)'):
        """Debug helper method that returns the source code context of this node as a string.
        """
        if not self.pos:
            return u''
        source_desc, line, col = self.pos
        contents = source_desc.get_lines(encoding='ASCII',
                                         error_handling='ignore')
        # line numbers start at 1
        lines = contents[max(0,line-3):line]
        current = lines[-1]
        if mark_column:
            current = current[:col] + marker + current[col:]
        lines[-1] = current.rstrip() + u'             # <<<<<<<<<<<<<<\n'
        lines += contents[line:line+2]
        return u'"%s":%d:%d\n%s\n' % (
            source_desc.get_escaped_description(), line, col, u''.join(lines))

class CompilerDirectivesNode(Node):
    """
    Sets compiler directives for the children nodes
    """
    #  directives     {string:value}  A dictionary holding the right value for
    #                                 *all* possible directives.
    #  body           Node
    child_attrs = ["body"]

    def analyse_declarations(self, env):
        old = env.directives
        env.directives = self.directives
        self.body.analyse_declarations(env)
        env.directives = old

    def analyse_expressions(self, env):
        old = env.directives
        env.directives = self.directives
        self.body = self.body.analyse_expressions(env)
        env.directives = old
        return self

    def generate_function_definitions(self, env, code):
        env_old = env.directives
        code_old = code.globalstate.directives
        code.globalstate.directives = self.directives
        self.body.generate_function_definitions(env, code)
        env.directives = env_old
        code.globalstate.directives = code_old

    def generate_execution_code(self, code):
        old = code.globalstate.directives
        code.globalstate.directives = self.directives
        self.body.generate_execution_code(code)
        code.globalstate.directives = old

    def annotate(self, code):
        old = code.globalstate.directives
        code.globalstate.directives = self.directives
        self.body.annotate(code)
        code.globalstate.directives = old

class BlockNode(object):
    #  Mixin class for nodes representing a declaration block.

    def generate_cached_builtins_decls(self, env, code):
        entries = env.global_scope().undeclared_cached_builtins
        for entry in entries:
            code.globalstate.add_cached_builtin_decl(entry)
        del entries[:]

    def generate_lambda_definitions(self, env, code):
        for node in env.lambda_defs:
            node.generate_function_definitions(env, code)

class StatListNode(Node):
    # stats     a list of StatNode

    child_attrs = ["stats"]

    def create_analysed(pos, env, *args, **kw):
        node = StatListNode(pos, *args, **kw)
        return node # No node-specific analysis necesarry
    create_analysed = staticmethod(create_analysed)

    def analyse_declarations(self, env):
        #print "StatListNode.analyse_declarations" ###
        for stat in self.stats:
            stat.analyse_declarations(env)

    def analyse_expressions(self, env):
        #print "StatListNode.analyse_expressions" ###
        self.stats = [ stat.analyse_expressions(env)
                       for stat in self.stats ]
        return self

    def generate_function_definitions(self, env, code):
        #print "StatListNode.generate_function_definitions" ###
        for stat in self.stats:
            stat.generate_function_definitions(env, code)

    def generate_execution_code(self, code):
        #print "StatListNode.generate_execution_code" ###
        for stat in self.stats:
            code.mark_pos(stat.pos)
            stat.generate_execution_code(code)

    def annotate(self, code):
        for stat in self.stats:
            stat.annotate(code)


class StatNode(Node):
    #
    #  Code generation for statements is split into the following subphases:
    #
    #  (1) generate_function_definitions
    #        Emit C code for the definitions of any structs,
    #        unions, enums and functions defined in the current
    #        scope-block.
    #
    #  (2) generate_execution_code
    #        Emit C code for executable statements.
    #

    def generate_function_definitions(self, env, code):
        pass

    def generate_execution_code(self, code):
        raise InternalError("generate_execution_code not implemented for %s" % \
            self.__class__.__name__)


class CDefExternNode(StatNode):
    #  include_file   string or None
    #  body           StatNode

    child_attrs = ["body"]

    def analyse_declarations(self, env):
        if self.include_file:
            env.add_include_file(self.include_file)
        old_cinclude_flag = env.in_cinclude
        env.in_cinclude = 1
        self.body.analyse_declarations(env)
        env.in_cinclude = old_cinclude_flag

    def analyse_expressions(self, env):
        return self

    def generate_execution_code(self, code):
        pass

    def annotate(self, code):
        self.body.annotate(code)


class CDeclaratorNode(Node):
    # Part of a C declaration.
    #
    # Processing during analyse_declarations phase:
    #
    #   analyse
    #      Returns (name, type) pair where name is the
    #      CNameDeclaratorNode of the name being declared
    #      and type is the type it is being declared as.
    #
    #  calling_convention  string   Calling convention of CFuncDeclaratorNode
    #                               for which this is a base

    child_attrs = []

    calling_convention = ""

    def analyse_templates(self):
        # Only C++ functions have templates.
        return None

class CNameDeclaratorNode(CDeclaratorNode):
    #  name    string             The Cython name being declared
    #  cname   string or None     C name, if specified
    #  default ExprNode or None   the value assigned on declaration

    child_attrs = ['default']

    default = None

    def analyse(self, base_type, env, nonempty = 0):
        if nonempty and self.name == '':
            # May have mistaken the name for the type.
            if base_type.is_ptr or base_type.is_array or base_type.is_buffer:
                error(self.pos, "Missing argument name")
            elif base_type.is_void:
                error(self.pos, "Use spam() rather than spam(void) to declare a function with no arguments.")
            else:
                self.name = base_type.declaration_code("", for_display=1, pyrex=1)
                base_type = py_object_type

        if base_type.is_fused and env.fused_to_specific:
            base_type = base_type.specialize(env.fused_to_specific)

        self.type = base_type
        return self, base_type

class CPtrDeclaratorNode(CDeclaratorNode):
    # base     CDeclaratorNode

    child_attrs = ["base"]

    def analyse(self, base_type, env, nonempty = 0):
        if base_type.is_pyobject:
            error(self.pos,
                "Pointer base type cannot be a Python object")
        ptr_type = PyrexTypes.c_ptr_type(base_type)
        return self.base.analyse(ptr_type, env, nonempty = nonempty)

class CReferenceDeclaratorNode(CDeclaratorNode):
    # base     CDeclaratorNode

    child_attrs = ["base"]

    def analyse(self, base_type, env, nonempty = 0):
        if base_type.is_pyobject:
            error(self.pos,
                  "Reference base type cannot be a Python object")
        ref_type = PyrexTypes.c_ref_type(base_type)
        return self.base.analyse(ref_type, env, nonempty = nonempty)

class CArrayDeclaratorNode(CDeclaratorNode):
    # base        CDeclaratorNode
    # dimension   ExprNode

    child_attrs = ["base", "dimension"]

    def analyse(self, base_type, env, nonempty = 0):
        if base_type.is_cpp_class or base_type.is_cfunction:
            from ExprNodes import TupleNode
            if isinstance(self.dimension, TupleNode):
                args = self.dimension.args
            else:
                args = self.dimension,
            values = [v.analyse_as_type(env) for v in args]
            if None in values:
                ix = values.index(None)
                error(args[ix].pos, "Template parameter not a type")
                base_type = error_type
            else:
                base_type = base_type.specialize_here(self.pos, values)
            return self.base.analyse(base_type, env, nonempty = nonempty)
        if self.dimension:
            self.dimension = self.dimension.analyse_const_expression(env)
            if not self.dimension.type.is_int:
                error(self.dimension.pos, "Array dimension not integer")
            size = self.dimension.get_constant_c_result_code()
            if size is not None:
                try:
                    size = int(size)
                except ValueError:
                    # runtime constant?
                    pass
        else:
            size = None
        if not base_type.is_complete():
            error(self.pos,
                "Array element type '%s' is incomplete" % base_type)
        if base_type.is_pyobject:
            error(self.pos,
                "Array element cannot be a Python object")
        if base_type.is_cfunction:
            error(self.pos,
                "Array element cannot be a function")
        array_type = PyrexTypes.c_array_type(base_type, size)
        return self.base.analyse(array_type, env, nonempty = nonempty)


class CFuncDeclaratorNode(CDeclaratorNode):
    # base             CDeclaratorNode
    # args             [CArgDeclNode]
    # templates        [TemplatePlaceholderType]
    # has_varargs      boolean
    # exception_value  ConstNode
    # exception_check  boolean    True if PyErr_Occurred check needed
    # nogil            boolean    Can be called without gil
    # with_gil         boolean    Acquire gil around function body
    # is_const_method  boolean    Whether this is a const method

    child_attrs = ["base", "args", "exception_value"]

    overridable = 0
    optional_arg_count = 0
    is_const_method = 0
    templates = None

    def analyse_templates(self):
        if isinstance(self.base, CArrayDeclaratorNode):
            from ExprNodes import TupleNode, NameNode
            template_node = self.base.dimension
            if isinstance(template_node, TupleNode):
                template_nodes = template_node.args
            elif isinstance(template_node, NameNode):
                template_nodes = [template_node]
            else:
                error(template_node.pos, "Template arguments must be a list of names")
                return None
            self.templates = []
            for template in template_nodes:
                if isinstance(template, NameNode):
                    self.templates.append(PyrexTypes.TemplatePlaceholderType(template.name))
                else:
                    error(template.pos, "Template arguments must be a list of names")
            self.base = self.base.base
            return self.templates
        else:
            return None

    def analyse(self, return_type, env, nonempty = 0, directive_locals = {}):
        if nonempty:
            nonempty -= 1
        func_type_args = []
        for i, arg_node in enumerate(self.args):
            name_declarator, type = arg_node.analyse(env, nonempty = nonempty,
                                                     is_self_arg = (i == 0 and env.is_c_class_scope))
            name = name_declarator.name
            if name in directive_locals:
                type_node = directive_locals[name]
                other_type = type_node.analyse_as_type(env)
                if other_type is None:
                    error(type_node.pos, "Not a type")
                elif (type is not PyrexTypes.py_object_type
                      and not type.same_as(other_type)):
                    error(self.base.pos, "Signature does not agree with previous declaration")
                    error(type_node.pos, "Previous declaration here")
                else:
                    type = other_type
            if name_declarator.cname:
                error(self.pos,
                    "Function argument cannot have C name specification")
            if i==0 and env.is_c_class_scope and type.is_unspecified:
                # fix the type of self
                type = env.parent_type
            # Turn *[] argument into **
            if type.is_array:
                type = PyrexTypes.c_ptr_type(type.base_type)
            # Catch attempted C-style func(void) decl
            if type.is_void:
                error(arg_node.pos, "Use spam() rather than spam(void) to declare a function with no arguments.")
            func_type_args.append(
                PyrexTypes.CFuncTypeArg(name, type, arg_node.pos))
            if arg_node.default:
                self.optional_arg_count += 1
            elif self.optional_arg_count:
                error(self.pos, "Non-default argument follows default argument")

        exc_val = None
        exc_check = 0
        if self.exception_check == '+':
            env.add_include_file('ios')         # for std::ios_base::failure
            env.add_include_file('new')         # for std::bad_alloc
            env.add_include_file('stdexcept')
            env.add_include_file('typeinfo')    # for std::bad_cast
        if (return_type.is_pyobject
                and (self.exception_value or self.exception_check)
                and self.exception_check != '+'):
            error(self.pos,
                "Exception clause not allowed for function returning Python object")
        else:
            if self.exception_value:
                self.exception_value = self.exception_value.analyse_const_expression(env)
                if self.exception_check == '+':
                    exc_val_type = self.exception_value.type
                    if (not exc_val_type.is_error
                            and not exc_val_type.is_pyobject
                            and not (exc_val_type.is_cfunction
                                     and not exc_val_type.return_type.is_pyobject
                                     and not exc_val_type.args)):
                        error(self.exception_value.pos,
                              "Exception value must be a Python exception or cdef function with no arguments.")
                    exc_val = self.exception_value
                else:
                    self.exception_value = self.exception_value.coerce_to(
                        return_type, env).analyse_const_expression(env)
                    exc_val = self.exception_value.get_constant_c_result_code()
                    if exc_val is None:
                        raise InternalError(
                            "get_constant_c_result_code not implemented for %s" %
                            self.exception_value.__class__.__name__)
                    if not return_type.assignable_from(self.exception_value.type):
                        error(self.exception_value.pos,
                              "Exception value incompatible with function return type")
            exc_check = self.exception_check
        if return_type.is_cfunction:
            error(self.pos,
                "Function cannot return a function")
        func_type = PyrexTypes.CFuncType(
            return_type, func_type_args, self.has_varargs,
            optional_arg_count = self.optional_arg_count,
            exception_value = exc_val, exception_check = exc_check,
            calling_convention = self.base.calling_convention,
            nogil = self.nogil, with_gil = self.with_gil, is_overridable = self.overridable,
            is_const_method = self.is_const_method,
            templates = self.templates)

        if self.optional_arg_count:
            if func_type.is_fused:
                # This is a bit of a hack... When we need to create specialized CFuncTypes
                # on the fly because the cdef is defined in a pxd, we need to declare the specialized optional arg
                # struct
                def declare_opt_arg_struct(func_type, fused_cname):
                    self.declare_optional_arg_struct(func_type, env, fused_cname)

                func_type.declare_opt_arg_struct = declare_opt_arg_struct
            else:
                self.declare_optional_arg_struct(func_type, env)

        callspec = env.directives['callspec']
        if callspec:
            current = func_type.calling_convention
            if current and current != callspec:
                error(self.pos, "cannot have both '%s' and '%s' "
                      "calling conventions" % (current, callspec))
            func_type.calling_convention = callspec
        return self.base.analyse(func_type, env)

    def declare_optional_arg_struct(self, func_type, env, fused_cname=None):
        """
        Declares the optional argument struct (the struct used to hold the
        values for optional arguments). For fused cdef functions, this is
        deferred as analyse_declarations is called only once (on the fused
        cdef function).
        """
        scope = StructOrUnionScope()
        arg_count_member = '%sn' % Naming.pyrex_prefix
        scope.declare_var(arg_count_member, PyrexTypes.c_int_type, self.pos)

        for arg in func_type.args[len(func_type.args)-self.optional_arg_count:]:
            scope.declare_var(arg.name, arg.type, arg.pos, allow_pyobject = 1)

        struct_cname = env.mangle(Naming.opt_arg_prefix, self.base.name)

        if fused_cname is not None:
            struct_cname = PyrexTypes.get_fused_cname(fused_cname, struct_cname)

        op_args_struct = env.global_scope().declare_struct_or_union(
                name = struct_cname,
                kind = 'struct',
                scope = scope,
                typedef_flag = 0,
                pos = self.pos,
                cname = struct_cname)

        op_args_struct.defined_in_pxd = 1
        op_args_struct.used = 1

        func_type.op_arg_struct = PyrexTypes.c_ptr_type(op_args_struct.type)


class CConstDeclaratorNode(CDeclaratorNode):
    # base     CDeclaratorNode

    child_attrs = ["base"]

    def analyse(self, base_type, env, nonempty = 0):
        if base_type.is_pyobject:
            error(self.pos,
                  "Const base type cannot be a Python object")
        const = PyrexTypes.c_const_type(base_type)
        return self.base.analyse(const, env, nonempty = nonempty)


class CArgDeclNode(Node):
    # Item in a function declaration argument list.
    #
    # base_type      CBaseTypeNode
    # declarator     CDeclaratorNode
    # not_none       boolean            Tagged with 'not None'
    # or_none        boolean            Tagged with 'or None'
    # accept_none    boolean            Resolved boolean for not_none/or_none
    # default        ExprNode or None
    # default_value  PyObjectConst      constant for default value
    # annotation     ExprNode or None   Py3 function arg annotation
    # is_self_arg    boolean            Is the "self" arg of an extension type method
    # is_type_arg    boolean            Is the "class" arg of an extension type classmethod
    # is_kw_only     boolean            Is a keyword-only argument
    # is_dynamic     boolean            Non-literal arg stored inside CyFunction

    child_attrs = ["base_type", "declarator", "default", "annotation"]

    is_self_arg = 0
    is_type_arg = 0
    is_generic = 1
    kw_only = 0
    not_none = 0
    or_none = 0
    type = None
    name_declarator = None
    default_value = None
    annotation = None
    is_dynamic = 0

    def analyse(self, env, nonempty = 0, is_self_arg = False):
        if is_self_arg:
            self.base_type.is_self_arg = self.is_self_arg = True
        if self.type is None:
            # The parser may misinterpret names as types. We fix that here.
            if isinstance(self.declarator, CNameDeclaratorNode) and self.declarator.name == '':
                if nonempty:
                    if self.base_type.is_basic_c_type:
                        # char, short, long called "int"
                        type = self.base_type.analyse(env, could_be_name = True)
                        arg_name = type.declaration_code("")
                    else:
                        arg_name = self.base_type.name
                    self.declarator.name = EncodedString(arg_name)
                    self.base_type.name = None
                    self.base_type.is_basic_c_type = False
                could_be_name = True
            else:
                could_be_name = False
            self.base_type.is_arg = True
            base_type = self.base_type.analyse(env, could_be_name = could_be_name)
            if hasattr(self.base_type, 'arg_name') and self.base_type.arg_name:
                self.declarator.name = self.base_type.arg_name
            # The parser is unable to resolve the ambiguity of [] as part of the
            # type (e.g. in buffers) or empty declarator (as with arrays).
            # This is only arises for empty multi-dimensional arrays.
            if (base_type.is_array
                    and isinstance(self.base_type, TemplatedTypeNode)
                    and isinstance(self.declarator, CArrayDeclaratorNode)):
                declarator = self.declarator
                while isinstance(declarator.base, CArrayDeclaratorNode):
                    declarator = declarator.base
                declarator.base = self.base_type.array_declarator
                base_type = base_type.base_type
            return self.declarator.analyse(base_type, env, nonempty = nonempty)
        else:
            return self.name_declarator, self.type

    def calculate_default_value_code(self, code):
        if self.default_value is None:
            if self.default:
                if self.default.is_literal:
                    # will not output any code, just assign the result_code
                    self.default.generate_evaluation_code(code)
                    return self.type.cast_code(self.default.result())
                self.default_value = code.get_argument_default_const(self.type)
        return self.default_value

    def annotate(self, code):
        if self.default:
            self.default.annotate(code)

    def generate_assignment_code(self, code, target=None):
        default = self.default
        if default is None or default.is_literal:
            return
        if target is None:
            target = self.calculate_default_value_code(code)
        default.generate_evaluation_code(code)
        default.make_owned_reference(code)
        result = default.result_as(self.type)
        code.putln("%s = %s;" % (target, result))
        if self.type.is_pyobject:
            code.put_giveref(default.result())
        default.generate_post_assignment_code(code)
        default.free_temps(code)


class CBaseTypeNode(Node):
    # Abstract base class for C base type nodes.
    #
    # Processing during analyse_declarations phase:
    #
    #   analyse
    #     Returns the type.

    pass

    def analyse_as_type(self, env):
        return self.analyse(env)

class CAnalysedBaseTypeNode(Node):
    # type            type

    child_attrs = []

    def analyse(self, env, could_be_name = False):
        return self.type

class CSimpleBaseTypeNode(CBaseTypeNode):
    # name             string
    # module_path      [string]     Qualifying name components
    # is_basic_c_type  boolean
    # signed           boolean
    # longness         integer
    # complex          boolean
    # is_self_arg      boolean      Is self argument of C method
    # ##is_type_arg      boolean      Is type argument of class method

    child_attrs = []
    arg_name = None   # in case the argument name was interpreted as a type
    module_path = []
    is_basic_c_type = False
    complex = False

    def analyse(self, env, could_be_name = False):
        # Return type descriptor.
        #print "CSimpleBaseTypeNode.analyse: is_self_arg =", self.is_self_arg ###
        type = None
        if self.is_basic_c_type:
            type = PyrexTypes.simple_c_type(self.signed, self.longness, self.name)
            if not type:
                error(self.pos, "Unrecognised type modifier combination")
        elif self.name == "object" and not self.module_path:
            type = py_object_type
        elif self.name is None:
            if self.is_self_arg and env.is_c_class_scope:
                #print "CSimpleBaseTypeNode.analyse: defaulting to parent type" ###
                type = env.parent_type
            ## elif self.is_type_arg and env.is_c_class_scope:
            ##     type = Builtin.type_type
            else:
                type = py_object_type
        else:
            if self.module_path:
                # Maybe it's a nested C++ class.
                scope = env
                for item in self.module_path:
                    entry = scope.lookup(item)
                    if entry is not None and entry.is_cpp_class:
                        scope = entry.type.scope
                    else:
                        scope = None
                        break

                if scope is None:
                    # Maybe it's a cimport.
                    scope = env.find_imported_module(self.module_path, self.pos)
                    if scope:
                        scope.fused_to_specific = env.fused_to_specific
            else:
                scope = env

            if scope:
                if scope.is_c_class_scope:
                    scope = scope.global_scope()

                type = scope.lookup_type(self.name)
                if type is not None:
                    pass
                elif could_be_name:
                    if self.is_self_arg and env.is_c_class_scope:
                        type = env.parent_type
                    ## elif self.is_type_arg and env.is_c_class_scope:
                    ##     type = Builtin.type_type
                    else:
                        type = py_object_type
                    self.arg_name = EncodedString(self.name)
                else:
                    if self.templates:
                        if not self.name in self.templates:
                            error(self.pos, "'%s' is not a type identifier" % self.name)
                        type = PyrexTypes.TemplatePlaceholderType(self.name)
                    else:
                        error(self.pos, "'%s' is not a type identifier" % self.name)
        if self.complex:
            if not type.is_numeric or type.is_complex:
                error(self.pos, "can only complexify c numeric types")
            type = PyrexTypes.CComplexType(type)
            type.create_declaration_utility_code(env)
        elif type is Builtin.complex_type:
            # Special case: optimise builtin complex type into C's
            # double complex.  The parser cannot do this (as for the
            # normal scalar types) as the user may have redeclared the
            # 'complex' type.  Testing for the exact type here works.
            type = PyrexTypes.c_double_complex_type
            type.create_declaration_utility_code(env)
            self.complex = True
        if type:
            return type
        else:
            return PyrexTypes.error_type

class MemoryViewSliceTypeNode(CBaseTypeNode):

    name = 'memoryview'
    child_attrs = ['base_type_node', 'axes']

    def analyse(self, env, could_be_name = False):

        base_type = self.base_type_node.analyse(env)
        if base_type.is_error: return base_type

        import MemoryView

        try:
            axes_specs = MemoryView.get_axes_specs(env, self.axes)
        except CompileError, e:
            error(e.position, e.message_only)
            self.type = PyrexTypes.ErrorType()
            return self.type

        if not MemoryView.validate_axes(self.pos, axes_specs):
            self.type = error_type
        else:
            MemoryView.validate_memslice_dtype(self.pos, base_type)
            self.type = PyrexTypes.MemoryViewSliceType(base_type, axes_specs)
            self.use_memview_utilities(env)

        return self.type

    def use_memview_utilities(self, env):
        import MemoryView
        env.use_utility_code(MemoryView.view_utility_code)


class CNestedBaseTypeNode(CBaseTypeNode):
    # For C++ classes that live inside other C++ classes.

    # name             string
    # base_type        CBaseTypeNode

    child_attrs = ['base_type']

    def analyse(self, env, could_be_name = None):
        base_type = self.base_type.analyse(env)
        if base_type is PyrexTypes.error_type:
            return PyrexTypes.error_type
        if not base_type.is_cpp_class:
            error(self.pos, "'%s' is not a valid type scope" % base_type)
            return PyrexTypes.error_type
        type_entry = base_type.scope.lookup_here(self.name)
        if not type_entry or not type_entry.is_type:
            error(self.pos, "'%s.%s' is not a type identifier" % (base_type, self.name))
            return PyrexTypes.error_type
        return type_entry.type


class TemplatedTypeNode(CBaseTypeNode):
    #  After parsing:
    #  positional_args  [ExprNode]        List of positional arguments
    #  keyword_args     DictNode          Keyword arguments
    #  base_type_node   CBaseTypeNode

    #  After analysis:
    #  type             PyrexTypes.BufferType or PyrexTypes.CppClassType  ...containing the right options

    child_attrs = ["base_type_node", "positional_args",
                   "keyword_args", "dtype_node"]

    dtype_node = None

    name = None

    def analyse(self, env, could_be_name = False, base_type = None):
        if base_type is None:
            base_type = self.base_type_node.analyse(env)
        if base_type.is_error: return base_type

        if base_type.is_cpp_class:
            # Templated class
            if self.keyword_args and self.keyword_args.key_value_pairs:
                error(self.pos, "c++ templates cannot take keyword arguments")
                self.type = PyrexTypes.error_type
            else:
                template_types = []
                for template_node in self.positional_args:
                    type = template_node.analyse_as_type(env)
                    if type is None:
                        error(template_node.pos, "unknown type in template argument")
                        return error_type
                    template_types.append(type)
                self.type = base_type.specialize_here(self.pos, template_types)

        elif base_type.is_pyobject:
            # Buffer
            import Buffer

            options = Buffer.analyse_buffer_options(
                self.pos,
                env,
                self.positional_args,
                self.keyword_args,
                base_type.buffer_defaults)

            if sys.version_info[0] < 3:
                # Py 2.x enforces byte strings as keyword arguments ...
                options = dict([ (name.encode('ASCII'), value)
                                 for name, value in options.items() ])

            self.type = PyrexTypes.BufferType(base_type, **options)

        else:
            # Array
            empty_declarator = CNameDeclaratorNode(self.pos, name="", cname=None)
            if len(self.positional_args) > 1 or self.keyword_args.key_value_pairs:
                error(self.pos, "invalid array declaration")
                self.type = PyrexTypes.error_type
            else:
                # It would be nice to merge this class with CArrayDeclaratorNode,
                # but arrays are part of the declaration, not the type...
                if not self.positional_args:
                    dimension = None
                else:
                    dimension = self.positional_args[0]
                self.array_declarator = CArrayDeclaratorNode(self.pos,
                    base = empty_declarator,
                    dimension = dimension)
                self.type = self.array_declarator.analyse(base_type, env)[1]

        if self.type.is_fused and env.fused_to_specific:
            self.type = self.type.specialize(env.fused_to_specific)

        return self.type

class CComplexBaseTypeNode(CBaseTypeNode):
    # base_type   CBaseTypeNode
    # declarator  CDeclaratorNode

    child_attrs = ["base_type", "declarator"]

    def analyse(self, env, could_be_name = False):
        base = self.base_type.analyse(env, could_be_name)
        _, type = self.declarator.analyse(base, env)
        return type


class FusedTypeNode(CBaseTypeNode):
    """
    Represents a fused type in a ctypedef statement:

        ctypedef cython.fused_type(int, long, long long) integral

    name            str                     name of this fused type
    types           [CSimpleBaseTypeNode]   is the list of types to be fused
    """

    child_attrs = []

    def analyse_declarations(self, env):
        type = self.analyse(env)
        entry = env.declare_typedef(self.name, type, self.pos)

        # Omit the typedef declaration that self.declarator would produce
        entry.in_cinclude = True

    def analyse(self, env):
        types = []
        for type_node in self.types:
            type = type_node.analyse_as_type(env)

            if not type:
                error(type_node.pos, "Not a type")
                continue

            if type in types:
                error(type_node.pos, "Type specified multiple times")
            elif type.is_fused:
                error(type_node.pos, "Cannot fuse a fused type")
            else:
                types.append(type)

        # if len(self.types) == 1:
        #     return types[0]

        return PyrexTypes.FusedType(types, name=self.name)


class CConstTypeNode(CBaseTypeNode):
    # base_type     CBaseTypeNode

    child_attrs = ["base_type"]

    def analyse(self, env, could_be_name = False):
        base = self.base_type.analyse(env, could_be_name)
        if base.is_pyobject:
            error(self.pos,
                  "Const base type cannot be a Python object")
        return PyrexTypes.c_const_type(base)


class CVarDefNode(StatNode):
    #  C variable definition or forward/extern function declaration.
    #
    #  visibility    'private' or 'public' or 'extern'
    #  base_type     CBaseTypeNode
    #  declarators   [CDeclaratorNode]
    #  in_pxd        boolean
    #  api           boolean
    #  overridable   boolean        whether it is a cpdef
    #  modifiers     ['inline']

    #  decorators    [cython.locals(...)] or None
    #  directive_locals { string : NameNode } locals defined by cython.locals(...)

    child_attrs = ["base_type", "declarators"]

    decorators = None
    directive_locals = None

    def analyse_declarations(self, env, dest_scope = None):
        if self.directive_locals is None:
            self.directive_locals = {}
        if not dest_scope:
            dest_scope = env
        self.dest_scope = dest_scope

        if self.declarators:
            templates = self.declarators[0].analyse_templates()
        else:
            templates = None
        if templates is not None:
            if self.visibility != 'extern':
                error(self.pos, "Only extern functions allowed")
            if len(self.declarators) > 1:
                error(self.declarators[1].pos, "Can't multiply declare template types")
            env = TemplateScope('func_template', env)
            env.directives = env.outer_scope.directives
            for template_param in templates:
                env.declare_type(template_param.name, template_param, self.pos)

        base_type = self.base_type.analyse(env)

        if base_type.is_fused and not self.in_pxd and (env.is_c_class_scope or
                                                       env.is_module_scope):
            error(self.pos, "Fused types not allowed here")
            return error_type

        self.entry = None
        visibility = self.visibility

        for declarator in self.declarators:

            if (len(self.declarators) > 1
                and not isinstance(declarator, CNameDeclaratorNode)
                and env.directives['warn.multiple_declarators']):
                warning(declarator.pos,
                    "Non-trivial type declarators in shared declaration (e.g. mix of pointers and values). " +
                    "Each pointer declaration should be on its own line.", 1)

            if isinstance(declarator, CFuncDeclaratorNode):
                name_declarator, type = declarator.analyse(base_type, env, directive_locals=self.directive_locals)
            else:
                name_declarator, type = declarator.analyse(base_type, env)
            if not type.is_complete():
                if not (self.visibility == 'extern' and type.is_array or type.is_memoryviewslice):
                    error(declarator.pos,
                        "Variable type '%s' is incomplete" % type)
            if self.visibility == 'extern' and type.is_pyobject:
                error(declarator.pos,
                    "Python object cannot be declared extern")
            name = name_declarator.name
            cname = name_declarator.cname
            if name == '':
                error(declarator.pos, "Missing name in declaration.")
                return
            if type.is_cfunction:
                self.entry = dest_scope.declare_cfunction(name, type, declarator.pos,
                    cname = cname, visibility = self.visibility, in_pxd = self.in_pxd,
                    api = self.api, modifiers = self.modifiers)
                if self.entry is not None:
                    self.entry.is_overridable = self.overridable
                    self.entry.directive_locals = copy.copy(self.directive_locals)
            else:
                if self.directive_locals:
                    error(self.pos, "Decorators can only be followed by functions")
                self.entry = dest_scope.declare_var(name, type, declarator.pos,
                            cname=cname, visibility=visibility, in_pxd=self.in_pxd,
                            api=self.api, is_cdef=1)
                if Options.docstrings:
                    self.entry.doc = embed_position(self.pos, self.doc)


class CStructOrUnionDefNode(StatNode):
    #  name          string
    #  cname         string or None
    #  kind          "struct" or "union"
    #  typedef_flag  boolean
    #  visibility    "public" or "private"
    #  api           boolean
    #  in_pxd        boolean
    #  attributes    [CVarDefNode] or None
    #  entry         Entry
    #  packed        boolean

    child_attrs = ["attributes"]

    def declare(self, env, scope=None):
        if self.visibility == 'extern' and self.packed and not scope:
            error(self.pos, "Cannot declare extern struct as 'packed'")
        self.entry = env.declare_struct_or_union(
            self.name, self.kind, scope, self.typedef_flag, self.pos,
            self.cname, visibility = self.visibility, api = self.api,
            packed = self.packed)

    def analyse_declarations(self, env):
        scope = None
        if self.attributes is not None:
            scope = StructOrUnionScope(self.name)
        self.declare(env, scope)
        if self.attributes is not None:
            if self.in_pxd and not env.in_cinclude:
                self.entry.defined_in_pxd = 1
            for attr in self.attributes:
                attr.analyse_declarations(env, scope)
            if self.visibility != 'extern':
                for attr in scope.var_entries:
                    type = attr.type
                    while type.is_array:
                        type = type.base_type
                    if type == self.entry.type:
                        error(attr.pos, "Struct cannot contain itself as a member.")

    def analyse_expressions(self, env):
        return self

    def generate_execution_code(self, code):
        pass


class CppClassNode(CStructOrUnionDefNode, BlockNode):

    #  name          string
    #  cname         string or None
    #  visibility    "extern"
    #  in_pxd        boolean
    #  attributes    [CVarDefNode] or None
    #  entry         Entry
    #  base_classes  [CBaseTypeNode]
    #  templates     [string] or None

    def declare(self, env):
        if self.templates is None:
            template_types = None
        else:
            template_types = [PyrexTypes.TemplatePlaceholderType(template_name) for template_name in self.templates]
        self.entry = env.declare_cpp_class(
            self.name, None, self.pos,
            self.cname, base_classes = [], visibility = self.visibility, templates = template_types)

    def analyse_declarations(self, env):
        scope = None
        if self.attributes is not None:
            scope = CppClassScope(self.name, env, templates = self.templates)
        def base_ok(base_class):
            if base_class.is_cpp_class or base_class.is_struct:
                return True
            else:
                error(self.pos, "Base class '%s' not a struct or class." % base_class)
        base_class_types = filter(base_ok, [b.analyse(scope or env) for b in self.base_classes])
        if self.templates is None:
            template_types = None
        else:
            template_types = [PyrexTypes.TemplatePlaceholderType(template_name) for template_name in self.templates]
        self.entry = env.declare_cpp_class(
            self.name, scope, self.pos,
            self.cname, base_class_types, visibility = self.visibility, templates = template_types)
        if self.entry is None:
            return
        self.entry.is_cpp_class = 1
        if scope is not None:
            scope.type = self.entry.type
        defined_funcs = []
        if self.attributes is not None:
            if self.in_pxd and not env.in_cinclude:
                self.entry.defined_in_pxd = 1
            for attr in self.attributes:
                attr.analyse_declarations(scope)
                if isinstance(attr, CFuncDefNode):
                    defined_funcs.append(attr)
                    if self.templates is not None:
                        attr.template_declaration = "template <typename %s>" % ", typename ".join(self.templates)
        self.body = StatListNode(self.pos, stats=defined_funcs)
        self.scope = scope

    def analyse_expressions(self, env):
        self.body = self.body.analyse_expressions(self.entry.type.scope)
        return self

    def generate_function_definitions(self, env, code):
        self.body.generate_function_definitions(self.entry.type.scope, code)

    def generate_execution_code(self, code):
        self.body.generate_execution_code(code)

    def annotate(self, code):
        self.body.annotate(code)


class CEnumDefNode(StatNode):
    #  name           string or None
    #  cname          string or None
    #  items          [CEnumDefItemNode]
    #  typedef_flag   boolean
    #  visibility     "public" or "private"
    #  api            boolean
    #  in_pxd         boolean
    #  entry          Entry

    child_attrs = ["items"]

    def declare(self, env):
         self.entry = env.declare_enum(self.name, self.pos,
             cname = self.cname, typedef_flag = self.typedef_flag,
             visibility = self.visibility, api = self.api)

    def analyse_declarations(self, env):
        if self.items is not None:
            if self.in_pxd and not env.in_cinclude:
                self.entry.defined_in_pxd = 1
            for item in self.items:
                item.analyse_declarations(env, self.entry)

    def analyse_expressions(self, env):
        return self

    def generate_execution_code(self, code):
        if self.visibility == 'public' or self.api:
            temp = code.funcstate.allocate_temp(PyrexTypes.py_object_type, manage_ref=True)
            for item in self.entry.enum_values:
                code.putln("%s = PyInt_FromLong(%s); %s" % (
                        temp,
                        item.cname,
                        code.error_goto_if_null(temp, item.pos)))
                code.put_gotref(temp)
                code.putln('if (PyDict_SetItemString(%s, "%s", %s) < 0) %s' % (
                        Naming.moddict_cname,
                        item.name,
                        temp,
                        code.error_goto(item.pos)))
                code.put_decref_clear(temp, PyrexTypes.py_object_type)
            code.funcstate.release_temp(temp)


class CEnumDefItemNode(StatNode):
    #  name     string
    #  cname    string or None
    #  value    ExprNode or None

    child_attrs = ["value"]

    def analyse_declarations(self, env, enum_entry):
        if self.value:
            self.value = self.value.analyse_const_expression(env)
            if not self.value.type.is_int:
                self.value = self.value.coerce_to(PyrexTypes.c_int_type, env)
                self.value = self.value.analyse_const_expression(env)
        entry = env.declare_const(self.name, enum_entry.type,
            self.value, self.pos, cname = self.cname,
            visibility = enum_entry.visibility, api = enum_entry.api)
        enum_entry.enum_values.append(entry)


class CTypeDefNode(StatNode):
    #  base_type    CBaseTypeNode
    #  declarator   CDeclaratorNode
    #  visibility   "public" or "private"
    #  api          boolean
    #  in_pxd       boolean

    child_attrs = ["base_type", "declarator"]

    def analyse_declarations(self, env):
        base = self.base_type.analyse(env)
        name_declarator, type = self.declarator.analyse(base, env)
        name = name_declarator.name
        cname = name_declarator.cname

        entry = env.declare_typedef(name, type, self.pos,
            cname = cname, visibility = self.visibility, api = self.api)

        if type.is_fused:
            entry.in_cinclude = True

        if self.in_pxd and not env.in_cinclude:
            entry.defined_in_pxd = 1

    def analyse_expressions(self, env):
        return self

    def generate_execution_code(self, code):
        pass


class FuncDefNode(StatNode, BlockNode):
    #  Base class for function definition nodes.
    #
    #  return_type     PyrexType
    #  #filename        string        C name of filename string const
    #  entry           Symtab.Entry
    #  needs_closure   boolean        Whether or not this function has inner functions/classes/yield
    #  needs_outer_scope boolean      Whether or not this function requires outer scope
    #  pymethdef_required boolean     Force Python method struct generation
    #  directive_locals { string : ExprNode } locals defined by cython.locals(...)
    #  directive_returns [ExprNode] type defined by cython.returns(...)
    # star_arg      PyArgDeclNode or None  * argument
    # starstar_arg  PyArgDeclNode or None  ** argument

    #  has_fused_arguments  boolean
    #       Whether this cdef function has fused parameters. This is needed
    #       by AnalyseDeclarationsTransform, so it can replace CFuncDefNodes
    #       with fused argument types with a FusedCFuncDefNode

    py_func = None
    needs_closure = False
    needs_outer_scope = False
    pymethdef_required = False
    is_generator = False
    is_generator_body = False
    modifiers = []
    has_fused_arguments = False
    star_arg = None
    starstar_arg = None
    is_cyfunction = False

    def analyse_default_values(self, env):
        default_seen = 0
        for arg in self.args:
            if arg.default:
                default_seen = 1
                if arg.is_generic:
                    arg.default = arg.default.analyse_types(env)
                    arg.default = arg.default.coerce_to(arg.type, env)
                else:
                    error(arg.pos,
                        "This argument cannot have a default value")
                    arg.default = None
            elif arg.kw_only:
                default_seen = 1
            elif default_seen:
                error(arg.pos, "Non-default argument following default argument")

    def align_argument_type(self, env, arg):
        directive_locals = self.directive_locals
        type = arg.type
        if arg.name in directive_locals:
            type_node = directive_locals[arg.name]
            other_type = type_node.analyse_as_type(env)
            if other_type is None:
                error(type_node.pos, "Not a type")
            elif (type is not PyrexTypes.py_object_type
                    and not type.same_as(other_type)):
                error(arg.base_type.pos, "Signature does not agree with previous declaration")
                error(type_node.pos, "Previous declaration here")
            else:
                arg.type = other_type
        return arg

    def need_gil_acquisition(self, lenv):
        return 0

    def create_local_scope(self, env):
        genv = env
        while genv.is_py_class_scope or genv.is_c_class_scope:
            genv = genv.outer_scope
        if self.needs_closure:
            lenv = ClosureScope(name=self.entry.name,
                                outer_scope = genv,
                                parent_scope = env,
                                scope_name=self.entry.cname)
        else:
            lenv = LocalScope(name=self.entry.name,
                              outer_scope=genv,
                              parent_scope=env)
        lenv.return_type = self.return_type
        type = self.entry.type
        if type.is_cfunction:
            lenv.nogil = type.nogil and not type.with_gil
        self.local_scope = lenv
        lenv.directives = env.directives
        return lenv

    def generate_function_body(self, env, code):
        self.body.generate_execution_code(code)

    def generate_function_definitions(self, env, code):
        import Buffer
        if self.return_type.is_memoryviewslice:
            import MemoryView

        lenv = self.local_scope
        if lenv.is_closure_scope and not lenv.is_passthrough:
            outer_scope_cname = "%s->%s" % (Naming.cur_scope_cname,
                                            Naming.outer_scope_cname)
        else:
            outer_scope_cname = Naming.outer_scope_cname
        lenv.mangle_closure_cnames(outer_scope_cname)
        # Generate closure function definitions
        self.body.generate_function_definitions(lenv, code)
        # generate lambda function definitions
        self.generate_lambda_definitions(lenv, code)

        is_getbuffer_slot = (self.entry.name == "__getbuffer__" and
                             self.entry.scope.is_c_class_scope)
        is_releasebuffer_slot = (self.entry.name == "__releasebuffer__" and
                                 self.entry.scope.is_c_class_scope)
        is_buffer_slot = is_getbuffer_slot or is_releasebuffer_slot
        if is_buffer_slot:
            if 'cython_unused' not in self.modifiers:
                self.modifiers = self.modifiers + ['cython_unused']

        preprocessor_guard = self.get_preprocessor_guard()

        profile = code.globalstate.directives['profile']
        linetrace = code.globalstate.directives['linetrace']
        if (linetrace or profile) and lenv.nogil:
            warning(self.pos, "Cannot profile nogil function.", 1)
            profile = linetrace = False
        if profile or linetrace:
            code.globalstate.use_utility_code(
                UtilityCode.load_cached("Profile", "Profile.c"))

        # Generate C code for header and body of function
        code.enter_cfunc_scope()
        code.return_from_error_cleanup_label = code.new_label()

        # ----- Top-level constants used by this function
        code.mark_pos(self.pos)
        self.generate_cached_builtins_decls(lenv, code)
        # ----- Function header
        code.putln("")

        if preprocessor_guard:
            code.putln(preprocessor_guard)

        with_pymethdef = (self.needs_assignment_synthesis(env, code) or
                          self.pymethdef_required)
        if self.py_func:
            self.py_func.generate_function_header(code,
                with_pymethdef = with_pymethdef,
                proto_only=True)
        self.generate_function_header(code,
            with_pymethdef = with_pymethdef)
        # ----- Local variable declarations
        # Find function scope
        cenv = env
        while cenv.is_py_class_scope or cenv.is_c_class_scope:
            cenv = cenv.outer_scope
        if self.needs_closure:
            code.put(lenv.scope_class.type.declaration_code(Naming.cur_scope_cname))
            code.putln(";")
        elif self.needs_outer_scope:
            if lenv.is_passthrough:
                code.put(lenv.scope_class.type.declaration_code(Naming.cur_scope_cname))
                code.putln(";")
            code.put(cenv.scope_class.type.declaration_code(Naming.outer_scope_cname))
            code.putln(";")
        self.generate_argument_declarations(lenv, code)

        for entry in lenv.var_entries:
            if not (entry.in_closure or entry.is_arg):
                code.put_var_declaration(entry)

        # Initialize the return variable __pyx_r
        init = ""
        if not self.return_type.is_void:
            if self.return_type.is_pyobject:
                init = " = NULL"
            elif self.return_type.is_memoryviewslice:
                init = ' = ' + MemoryView.memslice_entry_init

            code.putln(
                "%s%s;" %
                    (self.return_type.declaration_code(Naming.retval_cname),
                     init))

        tempvardecl_code = code.insertion_point()
        self.generate_keyword_list(code)

        if profile or linetrace:
            code.put_trace_declarations()

        # ----- Extern library function declarations
        lenv.generate_library_function_declarations(code)

        # ----- GIL acquisition
        acquire_gil = self.acquire_gil

        # See if we need to acquire the GIL for variable declarations, or for
        # refnanny only

        # Profiling or closures are not currently possible for cdef nogil
        # functions, but check them anyway
        have_object_args = (self.needs_closure or self.needs_outer_scope or
                            profile or linetrace)
        for arg in lenv.arg_entries:
            if arg.type.is_pyobject:
                have_object_args = True
                break

        acquire_gil_for_var_decls_only = (
                lenv.nogil and lenv.has_with_gil_block and
                (have_object_args or lenv.buffer_entries))

        acquire_gil_for_refnanny_only = (
                lenv.nogil and lenv.has_with_gil_block and not
                acquire_gil_for_var_decls_only)

        use_refnanny = not lenv.nogil or lenv.has_with_gil_block

        if acquire_gil or acquire_gil_for_var_decls_only:
            code.put_ensure_gil()
        elif lenv.nogil and lenv.has_with_gil_block:
            code.declare_gilstate()

        # ----- set up refnanny
        if use_refnanny:
            tempvardecl_code.put_declare_refcount_context()
            code.put_setup_refcount_context(
                self.entry.name, acquire_gil=acquire_gil_for_refnanny_only)

        # ----- Automatic lead-ins for certain special functions
        if is_getbuffer_slot:
            self.getbuffer_init(code)
        # ----- Create closure scope object
        if self.needs_closure:
            tp_slot = TypeSlots.ConstructorSlot("tp_new", '__new__')
            slot_func_cname = TypeSlots.get_slot_function(lenv.scope_class.type.scope, tp_slot)
            if not slot_func_cname:
                slot_func_cname = '%s->tp_new' % lenv.scope_class.type.typeptr_cname
            code.putln("%s = (%s)%s(%s, %s, NULL);" % (
                Naming.cur_scope_cname,
                lenv.scope_class.type.declaration_code(''),
                slot_func_cname,
                lenv.scope_class.type.typeptr_cname,
                Naming.empty_tuple))
            code.putln("if (unlikely(!%s)) {" % Naming.cur_scope_cname)
            if is_getbuffer_slot:
                self.getbuffer_error_cleanup(code)

            if use_refnanny:
                code.put_finish_refcount_context()
                if acquire_gil or acquire_gil_for_var_decls_only:
                    code.put_release_ensured_gil()

            # FIXME: what if the error return value is a Python value?
            code.putln("return %s;" % self.error_value())
            code.putln("}")
            code.put_gotref(Naming.cur_scope_cname)
            # Note that it is unsafe to decref the scope at this point.
        if self.needs_outer_scope:
            if self.is_cyfunction:
                code.putln("%s = (%s) __Pyx_CyFunction_GetClosure(%s);" % (
                    outer_scope_cname,
                    cenv.scope_class.type.declaration_code(''),
                    Naming.self_cname))
            else:
                code.putln("%s = (%s) %s;" % (
                    outer_scope_cname,
                    cenv.scope_class.type.declaration_code(''),
                    Naming.self_cname))
            if lenv.is_passthrough:
                code.putln("%s = %s;" % (Naming.cur_scope_cname, outer_scope_cname))
            elif self.needs_closure:
                # inner closures own a reference to their outer parent
                code.put_incref(outer_scope_cname, cenv.scope_class.type)
                code.put_giveref(outer_scope_cname)
        # ----- Trace function call
        if profile or linetrace:
            # this looks a bit late, but if we don't get here due to a
            # fatal error before hand, it's not really worth tracing
            code.put_trace_call(self.entry.name, self.pos)
            code.funcstate.can_trace = True
        # ----- Fetch arguments
        self.generate_argument_parsing_code(env, code)
        # If an argument is assigned to in the body, we must
        # incref it to properly keep track of refcounts.
        is_cdef = isinstance(self, CFuncDefNode)
        for entry in lenv.arg_entries:
            if entry.type.is_pyobject:
                if ((acquire_gil or len(entry.cf_assignments) > 1) and
                    not entry.in_closure):
                    code.put_var_incref(entry)

            # Note: defaults are always incref-ed. For def functions, we
            #       we aquire arguments from object converstion, so we have
            #       new references. If we are a cdef function, we need to
            #       incref our arguments
            elif (is_cdef and entry.type.is_memoryviewslice and
                  len(entry.cf_assignments) > 1):
                code.put_incref_memoryviewslice(entry.cname,
                                                have_gil=not lenv.nogil)
        for entry in lenv.var_entries:
            if entry.is_arg and len(entry.cf_assignments) > 1:
                code.put_var_incref(entry)

        # ----- Initialise local buffer auxiliary variables
        for entry in lenv.var_entries + lenv.arg_entries:
            if entry.type.is_buffer and entry.buffer_aux.buflocal_nd_var.used:
                Buffer.put_init_vars(entry, code)

        # ----- Check and convert arguments
        self.generate_argument_type_tests(code)
        # ----- Acquire buffer arguments
        for entry in lenv.arg_entries:
            if entry.type.is_buffer:
                Buffer.put_acquire_arg_buffer(entry, code, self.pos)

        if acquire_gil_for_var_decls_only:
            code.put_release_ensured_gil()

        # -------------------------
        # ----- Function body -----
        # -------------------------
        self.generate_function_body(env, code)

        code.mark_pos(self.pos)
        code.putln("")
        code.putln("/* function exit code */")

        # ----- Default return value
        if not self.body.is_terminator:
            if self.return_type.is_pyobject:
                #if self.return_type.is_extension_type:
                #    lhs = "(PyObject *)%s" % Naming.retval_cname
                #else:
                lhs = Naming.retval_cname
                code.put_init_to_py_none(lhs, self.return_type)
            else:
                val = self.return_type.default_value
                if val:
                    code.putln("%s = %s;" % (Naming.retval_cname, val))
        # ----- Error cleanup
        if code.error_label in code.labels_used:
            if not self.body.is_terminator:
                code.put_goto(code.return_label)
            code.put_label(code.error_label)
            for cname, type in code.funcstate.all_managed_temps():
                code.put_xdecref(cname, type, have_gil=not lenv.nogil)

            # Clean up buffers -- this calls a Python function
            # so need to save and restore error state
            buffers_present = len(lenv.buffer_entries) > 0
            memslice_entries = [e for e in lenv.entries.itervalues()
                                      if e.type.is_memoryviewslice]
            if buffers_present:
                code.globalstate.use_utility_code(restore_exception_utility_code)
                code.putln("{ PyObject *__pyx_type, *__pyx_value, *__pyx_tb;")
                code.putln("__Pyx_ErrFetch(&__pyx_type, &__pyx_value, &__pyx_tb);")
                for entry in lenv.buffer_entries:
                    Buffer.put_release_buffer_code(code, entry)
                    #code.putln("%s = 0;" % entry.cname)
                code.putln("__Pyx_ErrRestore(__pyx_type, __pyx_value, __pyx_tb);}")

            if self.return_type.is_memoryviewslice:
                MemoryView.put_init_entry(Naming.retval_cname, code)
                err_val = Naming.retval_cname
            else:
                err_val = self.error_value()

            exc_check = self.caller_will_check_exceptions()
            if err_val is not None or exc_check:
                # TODO: Fix exception tracing (though currently unused by cProfile).
                # code.globalstate.use_utility_code(get_exception_tuple_utility_code)
                # code.put_trace_exception()

                if lenv.nogil and not lenv.has_with_gil_block:
                    code.putln("{")
                    code.put_ensure_gil()

                code.put_add_traceback(self.entry.qualified_name)

                if lenv.nogil and not lenv.has_with_gil_block:
                    code.put_release_ensured_gil()
                    code.putln("}")
            else:
                warning(self.entry.pos,
                        "Unraisable exception in function '%s'." %
                        self.entry.qualified_name, 0)
                code.put_unraisable(self.entry.qualified_name)
            default_retval = self.return_type.default_value
            if err_val is None and default_retval:
                err_val = default_retval
            if err_val is not None:
                code.putln("%s = %s;" % (Naming.retval_cname, err_val))

            if is_getbuffer_slot:
                self.getbuffer_error_cleanup(code)

            # If we are using the non-error cleanup section we should
            # jump past it if we have an error. The if-test below determine
            # whether this section is used.
            if buffers_present or is_getbuffer_slot or self.return_type.is_memoryviewslice:
                code.put_goto(code.return_from_error_cleanup_label)

        # ----- Non-error return cleanup
        code.put_label(code.return_label)
        for entry in lenv.buffer_entries:
            if entry.used:
                Buffer.put_release_buffer_code(code, entry)
        if is_getbuffer_slot:
            self.getbuffer_normal_cleanup(code)

        if self.return_type.is_memoryviewslice:
            # See if our return value is uninitialized on non-error return
            # import MemoryView
            # MemoryView.err_if_nogil_initialized_check(self.pos, env)
            cond = code.unlikely(self.return_type.error_condition(
                                                    Naming.retval_cname))
            code.putln(
                'if (%s) {' % cond)
            if env.nogil:
                code.put_ensure_gil()
            code.putln(
                    'PyErr_SetString('
                        'PyExc_TypeError,'
                        '"Memoryview return value is not initialized");')
            if env.nogil:
                code.put_release_ensured_gil()
            code.putln(
                '}')

        # ----- Return cleanup for both error and no-error return
        code.put_label(code.return_from_error_cleanup_label)

        for entry in lenv.var_entries:
            if not entry.used or entry.in_closure:
                continue

            if entry.type.is_memoryviewslice:
                code.put_xdecref_memoryviewslice(entry.cname,
                                                 have_gil=not lenv.nogil)
            elif entry.type.is_pyobject:
                if not entry.is_arg or len(entry.cf_assignments) > 1:
                    code.put_var_decref(entry)

        # Decref any increfed args
        for entry in lenv.arg_entries:
            if entry.type.is_pyobject:
                if ((acquire_gil or len(entry.cf_assignments) > 1) and
                    not entry.in_closure):
                    code.put_var_decref(entry)
            elif (entry.type.is_memoryviewslice and
                  (not is_cdef or len(entry.cf_assignments) > 1)):
                # decref slices of def functions and acquired slices from cdef
                # functions, but not borrowed slices from cdef functions.
                code.put_xdecref_memoryviewslice(entry.cname,
                                                 have_gil=not lenv.nogil)
        if self.needs_closure:
            code.put_decref(Naming.cur_scope_cname, lenv.scope_class.type)

        # ----- Return
        # This code is duplicated in ModuleNode.generate_module_init_func
        if not lenv.nogil:
            default_retval = self.return_type.default_value
            err_val = self.error_value()
            if err_val is None and default_retval:
                err_val = default_retval  # FIXME: why is err_val not used?
            if self.return_type.is_pyobject:
                code.put_xgiveref(self.return_type.as_pyobject(Naming.retval_cname))

        if self.entry.is_special and self.entry.name == "__hash__":
            # Returning -1 for __hash__ is supposed to signal an error
            # We do as Python instances and coerce -1 into -2.
            code.putln("if (unlikely(%s == -1) && !PyErr_Occurred()) %s = -2;" % (
                    Naming.retval_cname, Naming.retval_cname))

        if profile or linetrace:
            code.funcstate.can_trace = False
            if self.return_type.is_pyobject:
                code.put_trace_return(Naming.retval_cname)
            else:
                code.put_trace_return("Py_None")

        if not lenv.nogil:
            # GIL holding function
            code.put_finish_refcount_context()

        if acquire_gil or (lenv.nogil and lenv.has_with_gil_block):
            # release the GIL (note that with-gil blocks acquire it on exit in their EnsureGILNode)
            code.put_release_ensured_gil()

        if not self.return_type.is_void:
            code.putln("return %s;" % Naming.retval_cname)

        code.putln("}")

        if preprocessor_guard:
            code.putln("#endif /*!(%s)*/" % preprocessor_guard)

        # ----- Go back and insert temp variable declarations
        tempvardecl_code.put_temp_declarations(code.funcstate)

        # ----- Python version
        code.exit_cfunc_scope()
        if self.py_func:
            self.py_func.generate_function_definitions(env, code)
        self.generate_wrapper_functions(code)

    def declare_argument(self, env, arg):
        if arg.type.is_void:
            error(arg.pos, "Invalid use of 'void'")
        elif not arg.type.is_complete() and not (arg.type.is_array or arg.type.is_memoryviewslice):
            error(arg.pos,
                "Argument type '%s' is incomplete" % arg.type)
        return env.declare_arg(arg.name, arg.type, arg.pos)

    def generate_arg_type_test(self, arg, code):
        # Generate type test for one argument.
        if arg.type.typeobj_is_available():
            code.globalstate.use_utility_code(
                UtilityCode.load_cached("ArgTypeTest", "FunctionArguments.c"))
            typeptr_cname = arg.type.typeptr_cname
            arg_code = "((PyObject *)%s)" % arg.entry.cname
            code.putln(
                'if (unlikely(!__Pyx_ArgTypeTest(%s, %s, %d, "%s", %s))) %s' % (
                    arg_code,
                    typeptr_cname,
                    arg.accept_none,
                    arg.name,
                    arg.type.is_builtin_type,
                    code.error_goto(arg.pos)))
        else:
            error(arg.pos, "Cannot test type of extern C class "
                "without type object name specification")

    def generate_arg_none_check(self, arg, code):
        # Generate None check for one argument.
        if arg.type.is_memoryviewslice:
            cname = "%s.memview" % arg.entry.cname
        else:
            cname = arg.entry.cname

        code.putln('if (unlikely(((PyObject *)%s) == Py_None)) {' % cname)
        code.putln('''PyErr_Format(PyExc_TypeError, "Argument '%%.%ds' must not be None", "%s"); %s''' % (
            max(200, len(arg.name)), arg.name,
            code.error_goto(arg.pos)))
        code.putln('}')

    def generate_wrapper_functions(self, code):
        pass

    def generate_execution_code(self, code):
        # Evaluate and store argument default values
        for arg in self.args:
            if not arg.is_dynamic:
                arg.generate_assignment_code(code)

    #
    # Special code for the __getbuffer__ function
    #
    def getbuffer_init(self, code):
        info = self.local_scope.arg_entries[1].cname
        # Python 3.0 betas have a bug in memoryview which makes it call
        # getbuffer with a NULL parameter. For now we work around this;
        # the following block should be removed when this bug is fixed.
        code.putln("if (%s != NULL) {" % info)
        code.putln("%s->obj = Py_None; __Pyx_INCREF(Py_None);" % info)
        code.put_giveref("%s->obj" % info) # Do not refnanny object within structs
        code.putln("}")

    def getbuffer_error_cleanup(self, code):
        info = self.local_scope.arg_entries[1].cname
        code.putln("if (%s != NULL && %s->obj != NULL) {"
                   % (info, info))
        code.put_gotref("%s->obj" % info)
        code.putln("__Pyx_DECREF(%s->obj); %s->obj = NULL;"
                   % (info, info))
        code.putln("}")

    def getbuffer_normal_cleanup(self, code):
        info = self.local_scope.arg_entries[1].cname
        code.putln("if (%s != NULL && %s->obj == Py_None) {" % (info, info))
        code.put_gotref("Py_None")
        code.putln("__Pyx_DECREF(Py_None); %s->obj = NULL;" % info)
        code.putln("}")

    def get_preprocessor_guard(self):
        if not self.entry.is_special:
            return None
        name = self.entry.name
        slot = TypeSlots.method_name_to_slot.get(name)
        if not slot:
            return None
        if name == '__long__' and not self.entry.scope.lookup_here('__int__'):
            return None
        if name in ("__getbuffer__", "__releasebuffer__") and self.entry.scope.is_c_class_scope:
            return None
        return slot.preprocessor_guard_code()


class CFuncDefNode(FuncDefNode):
    #  C function definition.
    #
    #  modifiers     ['inline']
    #  visibility    'private' or 'public' or 'extern'
    #  base_type     CBaseTypeNode
    #  declarator    CDeclaratorNode
    #  cfunc_declarator  the CFuncDeclarator of this function
    #                    (this is also available through declarator or a
    #                     base thereof)
    #  body          StatListNode
    #  api           boolean
    #  decorators    [DecoratorNode]        list of decorators
    #
    #  with_gil      boolean    Acquire GIL around body
    #  type          CFuncType
    #  py_func       wrapper for calling from Python
    #  overridable   whether or not this is a cpdef function
    #  inline_in_pxd whether this is an inline function in a pxd file
    #  template_declaration  String or None   Used for c++ class methods
    #  is_const_method whether this is a const method

    child_attrs = ["base_type", "declarator", "body", "py_func"]

    inline_in_pxd = False
    decorators = None
    directive_locals = None
    directive_returns = None
    override = None
    template_declaration = None
    is_const_method = False

    def unqualified_name(self):
        return self.entry.name

    def analyse_declarations(self, env):
        if self.directive_locals is None:
            self.directive_locals = {}
        self.directive_locals.update(env.directives['locals'])
        if self.directive_returns is not None:
            base_type = self.directive_returns.analyse_as_type(env)
            if base_type is None:
                error(self.directive_returns.pos, "Not a type")
                base_type = PyrexTypes.error_type
        else:
            base_type = self.base_type.analyse(env)
        # The 2 here is because we need both function and argument names.
        if isinstance(self.declarator, CFuncDeclaratorNode):
            name_declarator, type = self.declarator.analyse(base_type, env,
                                                            nonempty = 2 * (self.body is not None),
                                                            directive_locals = self.directive_locals)
        else:
            name_declarator, type = self.declarator.analyse(base_type, env, nonempty = 2 * (self.body is not None))
        if not type.is_cfunction:
            error(self.pos,
                "Suite attached to non-function declaration")
        # Remember the actual type according to the function header
        # written here, because the type in the symbol table entry
        # may be different if we're overriding a C method inherited
        # from the base type of an extension type.
        self.type = type
        type.is_overridable = self.overridable
        declarator = self.declarator
        while not hasattr(declarator, 'args'):
            declarator = declarator.base

        self.cfunc_declarator = declarator
        self.args = declarator.args

        opt_arg_count = self.cfunc_declarator.optional_arg_count
        if (self.visibility == 'public' or self.api) and opt_arg_count:
            error(self.cfunc_declarator.pos,
                  "Function with optional arguments may not be declared "
                  "public or api")

        if (type.exception_check == '+' and self.visibility != 'extern'):
            warning(self.cfunc_declarator.pos,
                    "Only extern functions can throw C++ exceptions.")

        for formal_arg, type_arg in zip(self.args, type.args):
            self.align_argument_type(env, type_arg)
            formal_arg.type = type_arg.type
            formal_arg.name = type_arg.name
            formal_arg.cname = type_arg.cname

            self._validate_type_visibility(type_arg.type, type_arg.pos, env)

            if type_arg.type.is_fused:
                self.has_fused_arguments = True

            if type_arg.type.is_buffer and 'inline' in self.modifiers:
                warning(formal_arg.pos, "Buffer unpacking not optimized away.", 1)

            if type_arg.type.is_buffer:
                if self.type.nogil:
                    error(formal_arg.pos,
                          "Buffer may not be acquired without the GIL. "
                          "Consider using memoryview slices instead.")
                elif 'inline' in self.modifiers:
                    warning(formal_arg.pos, "Buffer unpacking not optimized away.", 1)

        self._validate_type_visibility(type.return_type, self.pos, env)

        name = name_declarator.name
        cname = name_declarator.cname

        type.is_const_method = self.is_const_method
        self.entry = env.declare_cfunction(
            name, type, self.pos,
            cname = cname, visibility = self.visibility, api = self.api,
            defining = self.body is not None, modifiers = self.modifiers)
        self.entry.inline_func_in_pxd = self.inline_in_pxd
        self.return_type = type.return_type
        if self.return_type.is_array and self.visibility != 'extern':
            error(self.pos,
                "Function cannot return an array")
        if self.return_type.is_cpp_class:
            self.return_type.check_nullary_constructor(self.pos, "used as a return value")

        if self.overridable and not env.is_module_scope:
            if len(self.args) < 1 or not self.args[0].type.is_pyobject:
                # An error will be produced in the cdef function
                self.overridable = False

        self.declare_cpdef_wrapper(env)
        self.create_local_scope(env)

    def declare_cpdef_wrapper(self, env):
        if self.overridable:
            name = self.entry.name
            py_func_body = self.call_self_node(is_module_scope = env.is_module_scope)
            self.py_func = DefNode(pos = self.pos,
                                   name = self.entry.name,
                                   args = self.args,
                                   star_arg = None,
                                   starstar_arg = None,
                                   doc = self.doc,
                                   body = py_func_body,
                                   is_wrapper = 1)
            self.py_func.is_module_scope = env.is_module_scope
            self.py_func.analyse_declarations(env)
            self.entry.as_variable = self.py_func.entry
            self.entry.used = self.entry.as_variable.used = True
            # Reset scope entry the above cfunction
            env.entries[name] = self.entry
            if (not self.entry.is_final_cmethod and
                (not env.is_module_scope or Options.lookup_module_cpdef)):
                self.override = OverrideCheckNode(self.pos, py_func = self.py_func)
                self.body = StatListNode(self.pos, stats=[self.override, self.body])

    def _validate_type_visibility(self, type, pos, env):
        """
        Ensure that types used in cdef functions are public or api, or
        defined in a C header.
        """
        public_or_api = (self.visibility == 'public' or self.api)
        entry = getattr(type, 'entry', None)
        if public_or_api and entry and env.is_module_scope:
            if not (entry.visibility in ('public', 'extern') or
                    entry.api or entry.in_cinclude):
                error(pos, "Function declared public or api may not have "
                           "private types")

    def call_self_node(self, omit_optional_args=0, is_module_scope=0):
        import ExprNodes
        args = self.type.args
        if omit_optional_args:
            args = args[:len(args) - self.type.optional_arg_count]
        arg_names = [arg.name for arg in args]
        if is_module_scope:
            cfunc = ExprNodes.NameNode(self.pos, name=self.entry.name)
        else:
            self_arg = ExprNodes.NameNode(self.pos, name=arg_names[0])
            cfunc = ExprNodes.AttributeNode(self.pos, obj=self_arg, attribute=self.entry.name)
        skip_dispatch = not is_module_scope or Options.lookup_module_cpdef
        c_call = ExprNodes.SimpleCallNode(self.pos, function=cfunc, args=[ExprNodes.NameNode(self.pos, name=n) for n in arg_names[1-is_module_scope:]], wrapper_call=skip_dispatch)
        return ReturnStatNode(pos=self.pos, return_type=PyrexTypes.py_object_type, value=c_call)

    def declare_arguments(self, env):
        for arg in self.type.args:
            if not arg.name:
                error(arg.pos, "Missing argument name")
            self.declare_argument(env, arg)

    def need_gil_acquisition(self, lenv):
        return self.type.with_gil

    def nogil_check(self, env):
        type = self.type
        with_gil = type.with_gil
        if type.nogil and not with_gil:
            if type.return_type.is_pyobject:
                error(self.pos,
                      "Function with Python return type cannot be declared nogil")
            for entry in self.local_scope.var_entries:
                if entry.type.is_pyobject and not entry.in_with_gil_block:
                    error(self.pos, "Function declared nogil has Python locals or temporaries")

    def analyse_expressions(self, env):
        self.local_scope.directives = env.directives
        if self.py_func is not None:
            # this will also analyse the default values
            self.py_func = self.py_func.analyse_expressions(env)
        else:
            self.analyse_default_values(env)
        self.acquire_gil = self.need_gil_acquisition(self.local_scope)
        return self

    def needs_assignment_synthesis(self, env, code=None):
        return False

    def generate_function_header(self, code, with_pymethdef, with_opt_args = 1, with_dispatch = 1, cname = None):
        scope = self.local_scope
        arg_decls = []
        type = self.type
        for arg in type.args[:len(type.args)-type.optional_arg_count]:
            arg_decl = arg.declaration_code()
            entry = scope.lookup(arg.name)
            if not entry.cf_used:
                arg_decl = 'CYTHON_UNUSED %s' % arg_decl
            arg_decls.append(arg_decl)
        if with_dispatch and self.overridable:
            dispatch_arg = PyrexTypes.c_int_type.declaration_code(
                Naming.skip_dispatch_cname)
            if self.override:
                arg_decls.append(dispatch_arg)
            else:
                arg_decls.append('CYTHON_UNUSED %s' % dispatch_arg)
        if type.optional_arg_count and with_opt_args:
            arg_decls.append(type.op_arg_struct.declaration_code(Naming.optional_args_cname))
        if type.has_varargs:
            arg_decls.append("...")
        if not arg_decls:
            arg_decls = ["void"]
        if cname is None:
            cname = self.entry.func_cname
        entity = type.function_header_code(cname, ', '.join(arg_decls))
        if self.entry.visibility == 'private' and '::' not in cname:
            storage_class = "static "
        else:
            storage_class = ""
        dll_linkage = None
        modifiers = code.build_function_modifiers(self.entry.func_modifiers)

        header = self.return_type.declaration_code(entity, dll_linkage=dll_linkage)
        #print (storage_class, modifiers, header)
        if self.template_declaration:
            code.putln(self.template_declaration)
        code.putln("%s%s%s {" % (storage_class, modifiers, header))

    def generate_argument_declarations(self, env, code):
        scope = self.local_scope
        for arg in self.args:
            if arg.default:
                entry = scope.lookup(arg.name)
                if self.override or entry.cf_used:
                    result = arg.calculate_default_value_code(code)
                    code.putln('%s = %s;' % (
                        arg.type.declaration_code(arg.cname), result))

    def generate_keyword_list(self, code):
        pass

    def generate_argument_parsing_code(self, env, code):
        i = 0
        used = 0
        if self.type.optional_arg_count:
            scope = self.local_scope
            code.putln('if (%s) {' % Naming.optional_args_cname)
            for arg in self.args:
                if arg.default:
                    entry = scope.lookup(arg.name)
                    if self.override or entry.cf_used:
                        code.putln('if (%s->%sn > %s) {' %
                                   (Naming.optional_args_cname,
                                    Naming.pyrex_prefix, i))
                        declarator = arg.declarator
                        while not hasattr(declarator, 'name'):
                            declarator = declarator.base
                        code.putln('%s = %s->%s;' %
                                   (arg.cname, Naming.optional_args_cname,
                                    self.type.opt_arg_cname(declarator.name)))
                        used += 1
                    i += 1
            for _ in range(used):
                code.putln('}')
            code.putln('}')

    def generate_argument_conversion_code(self, code):
        pass

    def generate_argument_type_tests(self, code):
        # Generate type tests for args whose type in a parent
        # class is a supertype of the declared type.
        for arg in self.type.args:
            if arg.needs_type_test:
                self.generate_arg_type_test(arg, code)
            elif arg.type.is_pyobject and not arg.accept_none:
                self.generate_arg_none_check(arg, code)

    def error_value(self):
        if self.return_type.is_pyobject:
            return "0"
        else:
            #return None
            return self.entry.type.exception_value

    def caller_will_check_exceptions(self):
        return self.entry.type.exception_check

    def generate_wrapper_functions(self, code):
        # If the C signature of a function has changed, we need to generate
        # wrappers to put in the slots here.
        k = 0
        entry = self.entry
        func_type = entry.type
        while entry.prev_entry is not None:
            k += 1
            entry = entry.prev_entry
            entry.func_cname = "%s%swrap_%s" % (self.entry.func_cname, Naming.pyrex_prefix, k)
            code.putln()
            self.generate_function_header(code,
                                          0,
                                          with_dispatch = entry.type.is_overridable,
                                          with_opt_args = entry.type.optional_arg_count,
                                          cname = entry.func_cname)
            if not self.return_type.is_void:
                code.put('return ')
            args = self.type.args
            arglist = [arg.cname for arg in args[:len(args)-self.type.optional_arg_count]]
            if entry.type.is_overridable:
                arglist.append(Naming.skip_dispatch_cname)
            elif func_type.is_overridable:
                arglist.append('0')
            if entry.type.optional_arg_count:
                arglist.append(Naming.optional_args_cname)
            elif func_type.optional_arg_count:
                arglist.append('NULL')
            code.putln('%s(%s);' % (self.entry.func_cname, ', '.join(arglist)))
            code.putln('}')


class PyArgDeclNode(Node):
    # Argument which must be a Python object (used
    # for * and ** arguments).
    #
    # name        string
    # entry       Symtab.Entry
    # annotation  ExprNode or None   Py3 argument annotation
    child_attrs = []
    is_self_arg = False
    is_type_arg = False

    def generate_function_definitions(self, env, code):
        self.entry.generate_function_definitions(env, code)

class DecoratorNode(Node):
    # A decorator
    #
    # decorator    NameNode or CallNode or AttributeNode
    child_attrs = ['decorator']


class DefNode(FuncDefNode):
    # A Python function definition.
    #
    # name          string                 the Python name of the function
    # lambda_name   string                 the internal name of a lambda 'function'
    # decorators    [DecoratorNode]        list of decorators
    # args          [CArgDeclNode]         formal arguments
    # doc           EncodedString or None
    # body          StatListNode
    # return_type_annotation
    #               ExprNode or None       the Py3 return type annotation
    #
    #  The following subnode is constructed internally
    #  when the def statement is inside a Python class definition.
    #
    #  fused_py_func        DefNode     The original fused cpdef DefNode
    #                                   (in case this is a specialization)
    #  specialized_cpdefs   [DefNode]   list of specialized cpdef DefNodes
    #  py_cfunc_node  PyCFunctionNode/InnerFunctionNode   The PyCFunction to create and assign
    #
    # decorator_indirection IndirectionNode Used to remove __Pyx_Method_ClassMethod for fused functions

    child_attrs = ["args", "star_arg", "starstar_arg", "body", "decorators"]

    lambda_name = None
    reqd_kw_flags_cname = "0"
    is_wrapper = 0
    no_assignment_synthesis = 0
    decorators = None
    return_type_annotation = None
    entry = None
    acquire_gil = 0
    self_in_stararg = 0
    py_cfunc_node = None
    requires_classobj = False
    defaults_struct = None # Dynamic kwrds structure name
    doc = None

    fused_py_func = False
    specialized_cpdefs = None
    py_wrapper = None
    py_wrapper_required = True
    func_cname = None

    defaults_getter = None

    def __init__(self, pos, **kwds):
        FuncDefNode.__init__(self, pos, **kwds)
        k = rk = r = 0
        for arg in self.args:
            if arg.kw_only:
                k += 1
                if not arg.default:
                    rk += 1
            if not arg.default:
                r += 1
        self.num_kwonly_args = k
        self.num_required_kw_args = rk
        self.num_required_args = r

    def as_cfunction(self, cfunc=None, scope=None, overridable=True, returns=None):
        if self.star_arg:
            error(self.star_arg.pos, "cdef function cannot have star argument")
        if self.starstar_arg:
            error(self.starstar_arg.pos, "cdef function cannot have starstar argument")
        if cfunc is None:
            cfunc_args = []
            for formal_arg in self.args:
                name_declarator, type = formal_arg.analyse(scope, nonempty=1)
                cfunc_args.append(PyrexTypes.CFuncTypeArg(name = name_declarator.name,
                                                          cname = None,
                                                          type = py_object_type,
                                                          pos = formal_arg.pos))
            cfunc_type = PyrexTypes.CFuncType(return_type = py_object_type,
                                              args = cfunc_args,
                                              has_varargs = False,
                                              exception_value = None,
                                              exception_check = False,
                                              nogil = False,
                                              with_gil = False,
                                              is_overridable = overridable)
            cfunc = CVarDefNode(self.pos, type=cfunc_type)
        else:
            if scope is None:
                scope = cfunc.scope
            cfunc_type = cfunc.type
            if len(self.args) != len(cfunc_type.args) or cfunc_type.has_varargs:
                error(self.pos, "wrong number of arguments")
                error(cfunc.pos, "previous declaration here")
            for i, (formal_arg, type_arg) in enumerate(zip(self.args, cfunc_type.args)):
                name_declarator, type = formal_arg.analyse(scope, nonempty=1,
                                                           is_self_arg = (i == 0 and scope.is_c_class_scope))
                if type is None or type is PyrexTypes.py_object_type:
                    formal_arg.type = type_arg.type
                    formal_arg.name_declarator = name_declarator
        import ExprNodes
        if cfunc_type.exception_value is None:
            exception_value = None
        else:
            exception_value = ExprNodes.ConstNode(self.pos, value=cfunc_type.exception_value, type=cfunc_type.return_type)
        declarator = CFuncDeclaratorNode(self.pos,
                                         base = CNameDeclaratorNode(self.pos, name=self.name, cname=None),
                                         args = self.args,
                                         has_varargs = False,
                                         exception_check = cfunc_type.exception_check,
                                         exception_value = exception_value,
                                         with_gil = cfunc_type.with_gil,
                                         nogil = cfunc_type.nogil)
        return CFuncDefNode(self.pos,
                            modifiers = [],
                            base_type = CAnalysedBaseTypeNode(self.pos, type=cfunc_type.return_type),
                            declarator = declarator,
                            body = self.body,
                            doc = self.doc,
                            overridable = cfunc_type.is_overridable,
                            type = cfunc_type,
                            with_gil = cfunc_type.with_gil,
                            nogil = cfunc_type.nogil,
                            visibility = 'private',
                            api = False,
                            directive_locals = getattr(cfunc, 'directive_locals', {}),
                            directive_returns = returns)

    def is_cdef_func_compatible(self):
        """Determines if the function's signature is compatible with a
        cdef function.  This can be used before calling
        .as_cfunction() to see if that will be successful.
        """
        if self.needs_closure:
            return False
        if self.star_arg or self.starstar_arg:
            return False
        return True

    def analyse_declarations(self, env):
        self.is_classmethod = self.is_staticmethod = False
        if self.decorators:
            for decorator in self.decorators:
                func = decorator.decorator
                if func.is_name:
                    self.is_classmethod |= func.name == 'classmethod'
                    self.is_staticmethod |= func.name == 'staticmethod'

        if self.is_classmethod and env.lookup_here('classmethod'):
            # classmethod() was overridden - not much we can do here ...
            self.is_classmethod = False
        if self.is_staticmethod and env.lookup_here('staticmethod'):
            # staticmethod() was overridden - not much we can do here ...
            self.is_staticmethod = False

        if self.name == '__new__' and env.is_py_class_scope:
            self.is_staticmethod = 1

        self.analyse_argument_types(env)
        if self.name == '<lambda>':
            self.declare_lambda_function(env)
        else:
            self.declare_pyfunction(env)

        self.analyse_signature(env)
        self.return_type = self.entry.signature.return_type()
        self.create_local_scope(env)

        self.py_wrapper = DefNodeWrapper(
            self.pos,
            target=self,
            name=self.entry.name,
            args=self.args,
            star_arg=self.star_arg,
            starstar_arg=self.starstar_arg,
            return_type=self.return_type)
        self.py_wrapper.analyse_declarations(env)

    def analyse_argument_types(self, env):
        self.directive_locals = env.directives['locals']
        allow_none_for_extension_args = env.directives['allow_none_for_extension_args']

        f2s = env.fused_to_specific
        env.fused_to_specific = None

        for arg in self.args:
            if hasattr(arg, 'name'):
                name_declarator = None
            else:
                base_type = arg.base_type.analyse(env)
                name_declarator, type = \
                    arg.declarator.analyse(base_type, env)
                arg.name = name_declarator.name
                arg.type = type

                if type.is_fused:
                    self.has_fused_arguments = True

            self.align_argument_type(env, arg)
            if name_declarator and name_declarator.cname:
                error(self.pos,
                    "Python function argument cannot have C name specification")
            arg.type = arg.type.as_argument_type()
            arg.hdr_type = None
            arg.needs_conversion = 0
            arg.needs_type_test = 0
            arg.is_generic = 1
            if arg.type.is_pyobject or arg.type.is_buffer or arg.type.is_memoryviewslice:
                if arg.or_none:
                    arg.accept_none = True
                elif arg.not_none:
                    arg.accept_none = False
                elif (arg.type.is_extension_type or arg.type.is_builtin_type
                      or arg.type.is_buffer or arg.type.is_memoryviewslice):
                    if arg.default and arg.default.constant_result is None:
                        # special case: def func(MyType obj = None)
                        arg.accept_none = True
                    else:
                        # default depends on compiler directive
                        arg.accept_none = allow_none_for_extension_args
                else:
                    # probably just a plain 'object'
                    arg.accept_none = True
            else:
                arg.accept_none = True # won't be used, but must be there
                if arg.not_none:
                    error(arg.pos, "Only Python type arguments can have 'not None'")
                if arg.or_none:
                    error(arg.pos, "Only Python type arguments can have 'or None'")

        env.fused_to_specific = f2s

    def analyse_signature(self, env):
        if self.entry.is_special:
            if self.decorators:
                error(self.pos, "special functions of cdef classes cannot have decorators")
            self.entry.trivial_signature = len(self.args) == 1 and not (self.star_arg or self.starstar_arg)
        elif not env.directives['always_allow_keywords'] and not (self.star_arg or self.starstar_arg):
            # Use the simpler calling signature for zero- and one-argument functions.
            if self.entry.signature is TypeSlots.pyfunction_signature:
                if len(self.args) == 0:
                    self.entry.signature = TypeSlots.pyfunction_noargs
                elif len(self.args) == 1:
                    if self.args[0].default is None and not self.args[0].kw_only:
                        self.entry.signature = TypeSlots.pyfunction_onearg
            elif self.entry.signature is TypeSlots.pymethod_signature:
                if len(self.args) == 1:
                    self.entry.signature = TypeSlots.unaryfunc
                elif len(self.args) == 2:
                    if self.args[1].default is None and not self.args[1].kw_only:
                        self.entry.signature = TypeSlots.ibinaryfunc

        sig = self.entry.signature
        nfixed = sig.num_fixed_args()
        if sig is TypeSlots.pymethod_signature and nfixed == 1 \
               and len(self.args) == 0 and self.star_arg:
            # this is the only case where a diverging number of
            # arguments is not an error - when we have no explicit
            # 'self' parameter as in method(*args)
            sig = self.entry.signature = TypeSlots.pyfunction_signature # self is not 'really' used
            self.self_in_stararg = 1
            nfixed = 0

        if self.is_staticmethod and env.is_c_class_scope:
            nfixed = 0
            self.self_in_stararg = True  # FIXME: why for staticmethods?

            self.entry.signature = sig = copy.copy(sig)
            sig.fixed_arg_format = "*"
            sig.is_staticmethod = True
            sig.has_generic_args = True

        if ((self.is_classmethod or self.is_staticmethod) and
            self.has_fused_arguments and env.is_c_class_scope):
            del self.decorator_indirection.stats[:]

        for i in range(min(nfixed, len(self.args))):
            arg = self.args[i]
            arg.is_generic = 0
            if sig.is_self_arg(i) and not self.is_staticmethod:
                if self.is_classmethod:
                    arg.is_type_arg = 1
                    arg.hdr_type = arg.type = Builtin.type_type
                else:
                    arg.is_self_arg = 1
                    arg.hdr_type = arg.type = env.parent_type
                arg.needs_conversion = 0
            else:
                arg.hdr_type = sig.fixed_arg_type(i)
                if not arg.type.same_as(arg.hdr_type):
                    if arg.hdr_type.is_pyobject and arg.type.is_pyobject:
                        arg.needs_type_test = 1
                    else:
                        arg.needs_conversion = 1
            if arg.needs_conversion:
                arg.hdr_cname = Naming.arg_prefix + arg.name
            else:
                arg.hdr_cname = Naming.var_prefix + arg.name

        if nfixed > len(self.args):
            self.bad_signature()
            return
        elif nfixed < len(self.args):
            if not sig.has_generic_args:
                self.bad_signature()
            for arg in self.args:
                if arg.is_generic and \
                        (arg.type.is_extension_type or arg.type.is_builtin_type):
                    arg.needs_type_test = 1

    def bad_signature(self):
        sig = self.entry.signature
        expected_str = "%d" % sig.num_fixed_args()
        if sig.has_generic_args:
            expected_str += " or more"
        name = self.name
        if name.startswith("__") and name.endswith("__"):
            desc = "Special method"
        else:
            desc = "Method"
        error(self.pos,
            "%s %s has wrong number of arguments "
            "(%d declared, %s expected)" % (
                desc, self.name, len(self.args), expected_str))

    def declare_pyfunction(self, env):
        #print "DefNode.declare_pyfunction:", self.name, "in", env ###
        name = self.name
        entry = env.lookup_here(name)
        if entry:
            if entry.is_final_cmethod and not env.parent_type.is_final_type:
                error(self.pos, "Only final types can have final Python (def/cpdef) methods")
            if (entry.type.is_cfunction and not entry.is_builtin_cmethod
                and not self.is_wrapper):
                warning(self.pos, "Overriding cdef method with def method.", 5)
        entry = env.declare_pyfunction(name, self.pos, allow_redefine=not self.is_wrapper)
        self.entry = entry
        prefix = env.next_id(env.scope_prefix)
        self.entry.pyfunc_cname = Naming.pyfunc_prefix + prefix + name
        if Options.docstrings:
            entry.doc = embed_position(self.pos, self.doc)
            entry.doc_cname = Naming.funcdoc_prefix + prefix + name
            if entry.is_special:
                if entry.name in TypeSlots.invisible or not entry.doc or (entry.name in '__getattr__' and env.directives['fast_getattr']):
                    entry.wrapperbase_cname = None
                else:
                    entry.wrapperbase_cname = Naming.wrapperbase_prefix + prefix + name
        else:
            entry.doc = None

    def declare_lambda_function(self, env):
        entry = env.declare_lambda_function(self.lambda_name, self.pos)
        entry.doc = None
        self.entry = entry
        self.entry.pyfunc_cname = entry.cname

    def declare_arguments(self, env):
        for arg in self.args:
            if not arg.name:
                error(arg.pos, "Missing argument name")
            if arg.needs_conversion:
                arg.entry = env.declare_var(arg.name, arg.type, arg.pos)
                if arg.type.is_pyobject:
                    arg.entry.init = "0"
            else:
                arg.entry = self.declare_argument(env, arg)
            arg.entry.is_arg = 1
            arg.entry.used = 1
            arg.entry.is_self_arg = arg.is_self_arg
        self.declare_python_arg(env, self.star_arg)
        self.declare_python_arg(env, self.starstar_arg)

    def declare_python_arg(self, env, arg):
        if arg:
            if env.directives['infer_types'] != False:
                type = PyrexTypes.unspecified_type
            else:
                type = py_object_type
            entry = env.declare_var(arg.name, type, arg.pos)
            entry.is_arg = 1
            entry.used = 1
            entry.init = "0"
            entry.xdecref_cleanup = 1
            arg.entry = entry

    def analyse_expressions(self, env):
        self.local_scope.directives = env.directives
        self.analyse_default_values(env)

        if not self.needs_assignment_synthesis(env) and self.decorators:
            for decorator in self.decorators[::-1]:
                decorator.decorator = decorator.decorator.analyse_expressions(env)

        self.py_wrapper.prepare_argument_coercion(env)
        return self

    def needs_assignment_synthesis(self, env, code=None):
        if self.is_wrapper or self.specialized_cpdefs or self.entry.is_fused_specialized:
            return False
        if self.is_staticmethod:
            return True
        if self.no_assignment_synthesis:
            return False
        # Should enable for module level as well, that will require more testing...
        if self.entry.is_anonymous:
            return True
        if env.is_module_scope:
            if code is None:
                return env.directives['binding']
            else:
                return code.globalstate.directives['binding']
        return env.is_py_class_scope or env.is_closure_scope

    def error_value(self):
        return self.entry.signature.error_value

    def caller_will_check_exceptions(self):
        return self.entry.signature.exception_check

    def generate_function_definitions(self, env, code):
        if self.defaults_getter:
            self.defaults_getter.generate_function_definitions(env, code)

        # Before closure cnames are mangled
        if self.py_wrapper_required:
            # func_cname might be modified by @cname
            self.py_wrapper.func_cname = self.entry.func_cname
            self.py_wrapper.generate_function_definitions(env, code)
        FuncDefNode.generate_function_definitions(self, env, code)

    def generate_function_header(self, code, with_pymethdef, proto_only=0):
        if proto_only:
            if self.py_wrapper_required:
                self.py_wrapper.generate_function_header(
                    code, with_pymethdef, True)
            return
        arg_code_list = []
        if self.entry.signature.has_dummy_arg:
            self_arg = 'PyObject *%s' % Naming.self_cname
            if not self.needs_outer_scope:
                self_arg = 'CYTHON_UNUSED ' + self_arg
            arg_code_list.append(self_arg)

        def arg_decl_code(arg):
            entry = arg.entry
            if entry.in_closure:
                cname = entry.original_cname
            else:
                cname = entry.cname
            decl = entry.type.declaration_code(cname)
            if not entry.cf_used:
                decl = 'CYTHON_UNUSED ' + decl
            return decl

        for arg in self.args:
            arg_code_list.append(arg_decl_code(arg))
        if self.star_arg:
            arg_code_list.append(arg_decl_code(self.star_arg))
        if self.starstar_arg:
            arg_code_list.append(arg_decl_code(self.starstar_arg))
        arg_code = ', '.join(arg_code_list)
        dc = self.return_type.declaration_code(self.entry.pyfunc_cname)

        decls_code = code.globalstate['decls']
        preprocessor_guard = self.get_preprocessor_guard()
        if preprocessor_guard:
            decls_code.putln(preprocessor_guard)
        decls_code.putln(
            "static %s(%s); /* proto */" % (dc, arg_code))
        if preprocessor_guard:
            decls_code.putln("#endif")
        code.putln("static %s(%s) {" % (dc, arg_code))

    def generate_argument_declarations(self, env, code):
        pass

    def generate_keyword_list(self, code):
        pass

    def generate_argument_parsing_code(self, env, code):
        # Move arguments into closure if required
        def put_into_closure(entry):
            if entry.in_closure:
                code.putln('%s = %s;' % (entry.cname, entry.original_cname))
                code.put_var_incref(entry)
                code.put_var_giveref(entry)
        for arg in self.args:
            put_into_closure(arg.entry)
        for arg in self.star_arg, self.starstar_arg:
            if arg:
                put_into_closure(arg.entry)

    def generate_argument_type_tests(self, code):
        pass


class DefNodeWrapper(FuncDefNode):
    # DefNode python wrapper code generator

    defnode = None
    target = None # Target DefNode

    def __init__(self, *args, **kwargs):
        FuncDefNode.__init__(self, *args, **kwargs)
        self.num_kwonly_args = self.target.num_kwonly_args
        self.num_required_kw_args = self.target.num_required_kw_args
        self.num_required_args = self.target.num_required_args
        self.self_in_stararg = self.target.self_in_stararg
        self.signature = None

    def analyse_declarations(self, env):
        target_entry = self.target.entry
        name = self.name
        prefix = env.next_id(env.scope_prefix)
        target_entry.func_cname = Naming.pywrap_prefix + prefix + name
        target_entry.pymethdef_cname = Naming.pymethdef_prefix + prefix + name

        self.signature = target_entry.signature

    def prepare_argument_coercion(self, env):
        # This is only really required for Cython utility code at this time,
        # everything else can be done during code generation.  But we expand
        # all utility code here, simply because we cannot easily distinguish
        # different code types.
        for arg in self.args:
            if not arg.type.is_pyobject:
                if not arg.type.create_from_py_utility_code(env):
                    pass # will fail later
            elif arg.hdr_type and not arg.hdr_type.is_pyobject:
                if not arg.hdr_type.create_to_py_utility_code(env):
                    pass # will fail later

    def signature_has_nongeneric_args(self):
        argcount = len(self.args)
        if argcount == 0 or (
                argcount == 1 and (self.args[0].is_self_arg or
                                   self.args[0].is_type_arg)):
            return 0
        return 1

    def signature_has_generic_args(self):
        return self.signature.has_generic_args

    def generate_function_body(self, code):
        args = []
        if self.signature.has_dummy_arg:
            args.append(Naming.self_cname)
        for arg in self.args:
            if arg.hdr_type and not (arg.type.is_memoryviewslice or
                                     arg.type.is_struct or
                                     arg.type.is_complex):
                args.append(arg.type.cast_code(arg.entry.cname))
            else:
                args.append(arg.entry.cname)
        if self.star_arg:
            args.append(self.star_arg.entry.cname)
        if self.starstar_arg:
            args.append(self.starstar_arg.entry.cname)
        args = ', '.join(args)
        if not self.return_type.is_void:
            code.put('%s = ' % Naming.retval_cname)
        code.putln('%s(%s);' % (
            self.target.entry.pyfunc_cname, args))

    def generate_function_definitions(self, env, code):
        lenv = self.target.local_scope
        # Generate C code for header and body of function
        code.mark_pos(self.pos)
        code.putln("")
        code.putln("/* Python wrapper */")
        preprocessor_guard = self.target.get_preprocessor_guard()
        if preprocessor_guard:
            code.putln(preprocessor_guard)

        code.enter_cfunc_scope()
        code.return_from_error_cleanup_label = code.new_label()

        with_pymethdef = (self.target.needs_assignment_synthesis(env, code) or
                          self.target.pymethdef_required)
        self.generate_function_header(code, with_pymethdef)
        self.generate_argument_declarations(lenv, code)
        tempvardecl_code = code.insertion_point()

        if self.return_type.is_pyobject:
            retval_init = ' = 0'
        else:
            retval_init = ''
        if not self.return_type.is_void:
            code.putln('%s%s;' % (
                self.return_type.declaration_code(Naming.retval_cname),
                retval_init))
        code.put_declare_refcount_context()
        code.put_setup_refcount_context('%s (wrapper)' % self.name)

        self.generate_argument_parsing_code(lenv, code)
        self.generate_argument_type_tests(code)
        self.generate_function_body(code)

        # ----- Go back and insert temp variable declarations
        tempvardecl_code.put_temp_declarations(code.funcstate)

        code.mark_pos(self.pos)
        code.putln("")
        code.putln("/* function exit code */")

        # ----- Error cleanup
        if code.error_label in code.labels_used:
            code.put_goto(code.return_label)
            code.put_label(code.error_label)
            for cname, type in code.funcstate.all_managed_temps():
                code.put_xdecref(cname, type)
            err_val = self.error_value()
            if err_val is not None:
                code.putln("%s = %s;" % (Naming.retval_cname, err_val))

        # ----- Non-error return cleanup
        code.put_label(code.return_label)
        for entry in lenv.var_entries:
            if entry.is_arg and entry.type.is_pyobject:
                code.put_var_decref(entry)

        code.put_finish_refcount_context()
        if not self.return_type.is_void:
            code.putln("return %s;" % Naming.retval_cname)
        code.putln('}')
        code.exit_cfunc_scope()
        if preprocessor_guard:
            code.putln("#endif /*!(%s)*/" % preprocessor_guard)

    def generate_function_header(self, code, with_pymethdef, proto_only=0):
        arg_code_list = []
        sig = self.signature

        if sig.has_dummy_arg or self.self_in_stararg:
            arg_code = "PyObject *%s" % Naming.self_cname
            if not sig.has_dummy_arg:
                arg_code = 'CYTHON_UNUSED ' + arg_code
            arg_code_list.append(arg_code)

        for arg in self.args:
            if not arg.is_generic:
                if arg.is_self_arg or arg.is_type_arg:
                    arg_code_list.append("PyObject *%s" % arg.hdr_cname)
                else:
                    arg_code_list.append(
                        arg.hdr_type.declaration_code(arg.hdr_cname))
        entry = self.target.entry
        if not entry.is_special and sig.method_flags() == [TypeSlots.method_noargs]:
            arg_code_list.append("CYTHON_UNUSED PyObject *unused")
        if entry.scope.is_c_class_scope and entry.name == "__ipow__":
            arg_code_list.append("CYTHON_UNUSED PyObject *unused")
        if sig.has_generic_args:
            arg_code_list.append(
                "PyObject *%s, PyObject *%s"
                    % (Naming.args_cname, Naming.kwds_cname))
        arg_code = ", ".join(arg_code_list)

        # Prevent warning: unused function '__pyx_pw_5numpy_7ndarray_1__getbuffer__'
        mf = ""
        if (entry.name in ("__getbuffer__", "__releasebuffer__")
            and entry.scope.is_c_class_scope):
            mf = "CYTHON_UNUSED "
            with_pymethdef = False

        dc = self.return_type.declaration_code(entry.func_cname)
        header = "static %s%s(%s)" % (mf, dc, arg_code)
        code.putln("%s; /*proto*/" % header)

        if proto_only:
            if self.target.fused_py_func:
                # If we are the specialized version of the cpdef, we still
                # want the prototype for the "fused cpdef", in case we're
                # checking to see if our method was overridden in Python
                self.target.fused_py_func.generate_function_header(
                                    code, with_pymethdef, proto_only=True)
            return

        if (Options.docstrings and entry.doc and
                not self.target.fused_py_func and
                not entry.scope.is_property_scope and
                (not entry.is_special or entry.wrapperbase_cname)):
            # h_code = code.globalstate['h_code']
            docstr = entry.doc

            if docstr.is_unicode:
                docstr = docstr.utf8encode()

            code.putln(
                'static char %s[] = "%s";' % (
                    entry.doc_cname,
                    split_string_literal(escape_byte_string(docstr))))

            if entry.is_special:
                code.putln('#if CYTHON_COMPILING_IN_CPYTHON')
                code.putln(
                    "struct wrapperbase %s;" % entry.wrapperbase_cname)
                code.putln('#endif')

        if with_pymethdef or self.target.fused_py_func:
            code.put(
                "static PyMethodDef %s = " %
                    entry.pymethdef_cname)
            code.put_pymethoddef(self.target.entry, ";", allow_skip=False)
        code.putln("%s {" % header)

    def generate_argument_declarations(self, env, code):
        for arg in self.args:
            if arg.is_generic:
                if arg.needs_conversion:
                    code.putln("PyObject *%s = 0;" % arg.hdr_cname)
                else:
                    code.put_var_declaration(arg.entry)
        for entry in env.var_entries:
            if entry.is_arg:
                code.put_var_declaration(entry)

    def generate_argument_parsing_code(self, env, code):
        # Generate fast equivalent of PyArg_ParseTuple call for
        # generic arguments, if any, including args/kwargs
        old_error_label = code.new_error_label()
        our_error_label = code.error_label
        end_label = code.new_label("argument_unpacking_done")

        has_kwonly_args = self.num_kwonly_args > 0
        has_star_or_kw_args = self.star_arg is not None \
            or self.starstar_arg is not None or has_kwonly_args

        for arg in self.args:
            if not arg.type.is_pyobject:
                if not arg.type.create_from_py_utility_code(env):
                    pass # will fail later

        if not self.signature_has_generic_args():
            if has_star_or_kw_args:
                error(self.pos, "This method cannot have * or keyword arguments")
            self.generate_argument_conversion_code(code)

        elif not self.signature_has_nongeneric_args():
            # func(*args) or func(**kw) or func(*args, **kw)
            self.generate_stararg_copy_code(code)

        else:
            self.generate_tuple_and_keyword_parsing_code(self.args, end_label, code)

        code.error_label = old_error_label
        if code.label_used(our_error_label):
            if not code.label_used(end_label):
                code.put_goto(end_label)
            code.put_label(our_error_label)
            if has_star_or_kw_args:
                self.generate_arg_decref(self.star_arg, code)
                if self.starstar_arg:
                    if self.starstar_arg.entry.xdecref_cleanup:
                        code.put_var_xdecref_clear(self.starstar_arg.entry)
                    else:
                        code.put_var_decref_clear(self.starstar_arg.entry)
            code.put_add_traceback(self.target.entry.qualified_name)
            code.put_finish_refcount_context()
            code.putln("return %s;" % self.error_value())
        if code.label_used(end_label):
            code.put_label(end_label)

    def generate_arg_xdecref(self, arg, code):
        if arg:
            code.put_var_xdecref_clear(arg.entry)

    def generate_arg_decref(self, arg, code):
        if arg:
            code.put_var_decref_clear(arg.entry)

    def generate_stararg_copy_code(self, code):
        if not self.star_arg:
            code.globalstate.use_utility_code(
                UtilityCode.load_cached("RaiseArgTupleInvalid", "FunctionArguments.c"))
            code.putln("if (unlikely(PyTuple_GET_SIZE(%s) > 0)) {" %
                       Naming.args_cname)
            code.put('__Pyx_RaiseArgtupleInvalid("%s", 1, 0, 0, PyTuple_GET_SIZE(%s)); return %s;' % (
                    self.name, Naming.args_cname, self.error_value()))
            code.putln("}")

        if self.starstar_arg:
            if self.star_arg:
                kwarg_check = "unlikely(%s)" % Naming.kwds_cname
            else:
                kwarg_check = "%s" % Naming.kwds_cname
        else:
            kwarg_check = "unlikely(%s) && unlikely(PyDict_Size(%s) > 0)" % (
                Naming.kwds_cname, Naming.kwds_cname)
        code.globalstate.use_utility_code(
            UtilityCode.load_cached("KeywordStringCheck", "FunctionArguments.c"))
        code.putln(
            "if (%s && unlikely(!__Pyx_CheckKeywordStrings(%s, \"%s\", %d))) return %s;" % (
                kwarg_check, Naming.kwds_cname, self.name,
                bool(self.starstar_arg), self.error_value()))

        if self.starstar_arg:
            code.putln("%s = (%s) ? PyDict_Copy(%s) : PyDict_New();" % (
                    self.starstar_arg.entry.cname,
                    Naming.kwds_cname,
                    Naming.kwds_cname))
            code.putln("if (unlikely(!%s)) return %s;" % (
                    self.starstar_arg.entry.cname, self.error_value()))
            self.starstar_arg.entry.xdecref_cleanup = 0
            code.put_gotref(self.starstar_arg.entry.cname)

        if self.self_in_stararg and not self.target.is_staticmethod:
            # need to create a new tuple with 'self' inserted as first item
            code.put("%s = PyTuple_New(PyTuple_GET_SIZE(%s)+1); if (unlikely(!%s)) " % (
                    self.star_arg.entry.cname,
                    Naming.args_cname,
                    self.star_arg.entry.cname))
            if self.starstar_arg:
                code.putln("{")
                code.put_decref_clear(self.starstar_arg.entry.cname, py_object_type)
                code.putln("return %s;" % self.error_value())
                code.putln("}")
            else:
                code.putln("return %s;" % self.error_value())
            code.put_gotref(self.star_arg.entry.cname)
            code.put_incref(Naming.self_cname, py_object_type)
            code.put_giveref(Naming.self_cname)
            code.putln("PyTuple_SET_ITEM(%s, 0, %s);" % (
                self.star_arg.entry.cname, Naming.self_cname))
            temp = code.funcstate.allocate_temp(PyrexTypes.c_py_ssize_t_type, manage_ref=False)
            code.putln("for (%s=0; %s < PyTuple_GET_SIZE(%s); %s++) {" % (
                temp, temp, Naming.args_cname, temp))
            code.putln("PyObject* item = PyTuple_GET_ITEM(%s, %s);" % (
                Naming.args_cname, temp))
            code.put_incref("item", py_object_type)
            code.put_giveref("item")
            code.putln("PyTuple_SET_ITEM(%s, %s+1, item);" % (
                self.star_arg.entry.cname, temp))
            code.putln("}")
            code.funcstate.release_temp(temp)
            self.star_arg.entry.xdecref_cleanup = 0
        elif self.star_arg:
            code.put_incref(Naming.args_cname, py_object_type)
            code.putln("%s = %s;" % (
                    self.star_arg.entry.cname,
                    Naming.args_cname))
            self.star_arg.entry.xdecref_cleanup = 0

    def generate_tuple_and_keyword_parsing_code(self, args, success_label, code):
        argtuple_error_label = code.new_label("argtuple_error")

        positional_args = []
        required_kw_only_args = []
        optional_kw_only_args = []
        for arg in args:
            if arg.is_generic:
                if arg.default:
                    if not arg.is_self_arg and not arg.is_type_arg:
                        if arg.kw_only:
                            optional_kw_only_args.append(arg)
                        else:
                            positional_args.append(arg)
                elif arg.kw_only:
                    required_kw_only_args.append(arg)
                elif not arg.is_self_arg and not arg.is_type_arg:
                    positional_args.append(arg)

        # sort required kw-only args before optional ones to avoid special
        # cases in the unpacking code
        kw_only_args = required_kw_only_args + optional_kw_only_args

        min_positional_args = self.num_required_args - self.num_required_kw_args
        if len(args) > 0 and (args[0].is_self_arg or args[0].is_type_arg):
            min_positional_args -= 1
        max_positional_args = len(positional_args)
        has_fixed_positional_count = not self.star_arg and \
            min_positional_args == max_positional_args
        has_kw_only_args = bool(kw_only_args)

        if self.num_required_kw_args:
            code.globalstate.use_utility_code(
                UtilityCode.load_cached("RaiseKeywordRequired", "FunctionArguments.c"))

        if self.starstar_arg or self.star_arg:
            self.generate_stararg_init_code(max_positional_args, code)

        code.putln('{')
        all_args = tuple(positional_args) + tuple(kw_only_args)
        code.putln("static PyObject **%s[] = {%s,0};" % (
            Naming.pykwdlist_cname,
            ','.join([ '&%s' % code.intern_identifier(arg.name)
                        for arg in all_args ])))

        # Before being converted and assigned to the target variables,
        # borrowed references to all unpacked argument values are
        # collected into a local PyObject* array called "values",
        # regardless if they were taken from default arguments,
        # positional arguments or keyword arguments.  Note that
        # C-typed default arguments are handled at conversion time,
        # so their array value is NULL in the end if no argument
        # was passed for them.
        self.generate_argument_values_setup_code(all_args, code)

        # --- optimised code when we receive keyword arguments
        code.putln("if (%s(%s)) {" % (
            (self.num_required_kw_args > 0) and "likely" or "unlikely",
            Naming.kwds_cname))
        self.generate_keyword_unpacking_code(
            min_positional_args, max_positional_args,
            has_fixed_positional_count, has_kw_only_args,
            all_args, argtuple_error_label, code)

        # --- optimised code when we do not receive any keyword arguments
        if (self.num_required_kw_args and min_positional_args > 0) or min_positional_args == max_positional_args:
            # Python raises arg tuple related errors first, so we must
            # check the length here
            if min_positional_args == max_positional_args and not self.star_arg:
                compare = '!='
            else:
                compare = '<'
            code.putln('} else if (PyTuple_GET_SIZE(%s) %s %d) {' % (
                    Naming.args_cname, compare, min_positional_args))
            code.put_goto(argtuple_error_label)

        if self.num_required_kw_args:
            # pure error case: keywords required but not passed
            if max_positional_args > min_positional_args and not self.star_arg:
                code.putln('} else if (PyTuple_GET_SIZE(%s) > %d) {' % (
                        Naming.args_cname, max_positional_args))
                code.put_goto(argtuple_error_label)
            code.putln('} else {')
            for i, arg in enumerate(kw_only_args):
                if not arg.default:
                    pystring_cname = code.intern_identifier(arg.name)
                    # required keyword-only argument missing
                    code.put('__Pyx_RaiseKeywordRequired("%s", %s); ' % (
                            self.name,
                            pystring_cname))
                    code.putln(code.error_goto(self.pos))
                    break

        else:
            # optimised tuple unpacking code
            code.putln('} else {')
            if min_positional_args == max_positional_args:
                # parse the exact number of positional arguments from
                # the args tuple
                for i, arg in enumerate(positional_args):
                    code.putln("values[%d] = PyTuple_GET_ITEM(%s, %d);" % (i, Naming.args_cname, i))
            else:
                # parse the positional arguments from the variable length
                # args tuple and reject illegal argument tuple sizes
                code.putln('switch (PyTuple_GET_SIZE(%s)) {' % Naming.args_cname)
                if self.star_arg:
                    code.putln('default:')
                reversed_args = list(enumerate(positional_args))[::-1]
                for i, arg in reversed_args:
                    if i >= min_positional_args-1:
                        code.put('case %2d: ' % (i+1))
                    code.putln("values[%d] = PyTuple_GET_ITEM(%s, %d);" % (i, Naming.args_cname, i))
                if min_positional_args == 0:
                    code.put('case  0: ')
                code.putln('break;')
                if self.star_arg:
                    if min_positional_args:
                        for i in range(min_positional_args-1, -1, -1):
                            code.putln('case %2d:' % i)
                        code.put_goto(argtuple_error_label)
                else:
                    code.put('default: ')
                    code.put_goto(argtuple_error_label)
                code.putln('}')

        code.putln('}') # end of the conditional unpacking blocks

        # Convert arg values to their final type and assign them.
        # Also inject non-Python default arguments, which do cannot
        # live in the values[] array.
        for i, arg in enumerate(all_args):
            self.generate_arg_assignment(arg, "values[%d]" % i, code)

        code.putln('}') # end of the whole argument unpacking block

        if code.label_used(argtuple_error_label):
            code.put_goto(success_label)
            code.put_label(argtuple_error_label)
            code.globalstate.use_utility_code(
                UtilityCode.load_cached("RaiseArgTupleInvalid", "FunctionArguments.c"))
            code.put('__Pyx_RaiseArgtupleInvalid("%s", %d, %d, %d, PyTuple_GET_SIZE(%s)); ' % (
                    self.name, has_fixed_positional_count,
                    min_positional_args, max_positional_args,
                    Naming.args_cname))
            code.putln(code.error_goto(self.pos))

    def generate_arg_assignment(self, arg, item, code):
        if arg.type.is_pyobject:
            # Python default arguments were already stored in 'item' at the very beginning
            if arg.is_generic:
                item = PyrexTypes.typecast(arg.type, PyrexTypes.py_object_type, item)
            entry = arg.entry
            code.putln("%s = %s;" % (entry.cname, item))
        else:
            func = arg.type.from_py_function
            if func:
                if arg.default:
                    # C-typed default arguments must be handled here
                    code.putln('if (%s) {' % item)
                rhs = "%s(%s)" % (func, item)
                if arg.type.is_enum:
                    rhs = arg.type.cast_code(rhs)
                code.putln("%s = %s; %s" % (
                    arg.entry.cname,
                    rhs,
                    code.error_goto_if(arg.type.error_condition(arg.entry.cname), arg.pos)))
                if arg.default:
                    code.putln('} else {')
                    code.putln(
                        "%s = %s;" % (
                            arg.entry.cname,
                            arg.calculate_default_value_code(code)))
                    if arg.type.is_memoryviewslice:
                        code.put_incref_memoryviewslice(arg.entry.cname,
                                                        have_gil=True)
                    code.putln('}')
            else:
                error(arg.pos, "Cannot convert Python object argument to type '%s'" % arg.type)

    def generate_stararg_init_code(self, max_positional_args, code):
        if self.starstar_arg:
            self.starstar_arg.entry.xdecref_cleanup = 0
            code.putln('%s = PyDict_New(); if (unlikely(!%s)) return %s;' % (
                    self.starstar_arg.entry.cname,
                    self.starstar_arg.entry.cname,
                    self.error_value()))
            code.put_gotref(self.starstar_arg.entry.cname)
        if self.star_arg:
            self.star_arg.entry.xdecref_cleanup = 0
            code.putln('if (PyTuple_GET_SIZE(%s) > %d) {' % (
                    Naming.args_cname,
                    max_positional_args))
            code.putln('%s = PyTuple_GetSlice(%s, %d, PyTuple_GET_SIZE(%s));' % (
                    self.star_arg.entry.cname, Naming.args_cname,
                    max_positional_args, Naming.args_cname))
            code.putln("if (unlikely(!%s)) {" % self.star_arg.entry.cname)
            if self.starstar_arg:
                code.put_decref_clear(self.starstar_arg.entry.cname, py_object_type)
            code.put_finish_refcount_context()
            code.putln('return %s;' % self.error_value())
            code.putln('}')
            code.put_gotref(self.star_arg.entry.cname)
            code.putln('} else {')
            code.put("%s = %s; " % (self.star_arg.entry.cname, Naming.empty_tuple))
            code.put_incref(Naming.empty_tuple, py_object_type)
            code.putln('}')

    def generate_argument_values_setup_code(self, args, code):
        max_args = len(args)
        # the 'values' array collects borrowed references to arguments
        # before doing any type coercion etc.
        code.putln("PyObject* values[%d] = {%s};" % (
            max_args, ','.join('0'*max_args)))

        if self.target.defaults_struct:
            code.putln('%s *%s = __Pyx_CyFunction_Defaults(%s, %s);' % (
                self.target.defaults_struct, Naming.dynamic_args_cname,
                self.target.defaults_struct, Naming.self_cname))

        # assign borrowed Python default values to the values array,
        # so that they can be overwritten by received arguments below
        for i, arg in enumerate(args):
            if arg.default and arg.type.is_pyobject:
                default_value = arg.calculate_default_value_code(code)
                code.putln('values[%d] = %s;' % (i, arg.type.as_pyobject(default_value)))

    def generate_keyword_unpacking_code(self, min_positional_args, max_positional_args,
                                        has_fixed_positional_count, has_kw_only_args,
                                        all_args, argtuple_error_label, code):
        code.putln('Py_ssize_t kw_args;')
        code.putln('const Py_ssize_t pos_args = PyTuple_GET_SIZE(%s);' % Naming.args_cname)
        # copy the values from the args tuple and check that it's not too long
        code.putln('switch (pos_args) {')
        if self.star_arg:
            code.putln('default:')
        for i in range(max_positional_args-1, -1, -1):
            code.put('case %2d: ' % (i+1))
            code.putln("values[%d] = PyTuple_GET_ITEM(%s, %d);" % (
                    i, Naming.args_cname, i))
        code.putln('case  0: break;')
        if not self.star_arg:
            code.put('default: ') # more arguments than allowed
            code.put_goto(argtuple_error_label)
        code.putln('}')

        # The code above is very often (but not always) the same as
        # the optimised non-kwargs tuple unpacking code, so we keep
        # the code block above at the very top, before the following
        # 'external' PyDict_Size() call, to make it easy for the C
        # compiler to merge the two separate tuple unpacking
        # implementations into one when they turn out to be identical.

        # If we received kwargs, fill up the positional/required
        # arguments with values from the kw dict
        code.putln('kw_args = PyDict_Size(%s);' % Naming.kwds_cname)
        if self.num_required_args or max_positional_args > 0:
            last_required_arg = -1
            for i, arg in enumerate(all_args):
                if not arg.default:
                    last_required_arg = i
            if last_required_arg < max_positional_args:
                last_required_arg = max_positional_args-1
            if max_positional_args > 0:
                code.putln('switch (pos_args) {')
            for i, arg in enumerate(all_args[:last_required_arg+1]):
                if max_positional_args > 0 and i <= max_positional_args:
                    if self.star_arg and i == max_positional_args:
                        code.putln('default:')
                    else:
                        code.putln('case %2d:' % i)
                pystring_cname = code.intern_identifier(arg.name)
                if arg.default:
                    if arg.kw_only:
                        # optional kw-only args are handled separately below
                        continue
                    code.putln('if (kw_args > 0) {')
                    # don't overwrite default argument
                    code.putln('PyObject* value = PyDict_GetItem(%s, %s);' % (
                        Naming.kwds_cname, pystring_cname))
                    code.putln('if (value) { values[%d] = value; kw_args--; }' % i)
                    code.putln('}')
                else:
                    code.putln('if (likely((values[%d] = PyDict_GetItem(%s, %s)) != 0)) kw_args--;' % (
                        i, Naming.kwds_cname, pystring_cname))
                    if i < min_positional_args:
                        if i == 0:
                            # special case: we know arg 0 is missing
                            code.put('else ')
                            code.put_goto(argtuple_error_label)
                        else:
                            # print the correct number of values (args or
                            # kwargs) that were passed into positional
                            # arguments up to this point
                            code.putln('else {')
                            code.globalstate.use_utility_code(
                                UtilityCode.load_cached("RaiseArgTupleInvalid", "FunctionArguments.c"))
                            code.put('__Pyx_RaiseArgtupleInvalid("%s", %d, %d, %d, %d); ' % (
                                    self.name, has_fixed_positional_count,
                                    min_positional_args, max_positional_args, i))
                            code.putln(code.error_goto(self.pos))
                            code.putln('}')
                    elif arg.kw_only:
                        code.putln('else {')
                        code.put('__Pyx_RaiseKeywordRequired("%s", %s); ' %(
                                self.name, pystring_cname))
                        code.putln(code.error_goto(self.pos))
                        code.putln('}')
            if max_positional_args > 0:
                code.putln('}')

        if has_kw_only_args:
            # unpack optional keyword-only arguments separately because
            # checking for interned strings in a dict is faster than iterating
            self.generate_optional_kwonly_args_unpacking_code(all_args, code)

        code.putln('if (unlikely(kw_args > 0)) {')
        # non-positional/-required kw args left in dict: default args,
        # kw-only args, **kwargs or error
        #
        # This is sort of a catch-all: except for checking required
        # arguments, this will always do the right thing for unpacking
        # keyword arguments, so that we can concentrate on optimising
        # common cases above.
        if max_positional_args == 0:
            pos_arg_count = "0"
        elif self.star_arg:
            code.putln("const Py_ssize_t used_pos_args = (pos_args < %d) ? pos_args : %d;" % (
                    max_positional_args, max_positional_args))
            pos_arg_count = "used_pos_args"
        else:
            pos_arg_count = "pos_args"
        code.globalstate.use_utility_code(
            UtilityCode.load_cached("ParseKeywords", "FunctionArguments.c"))
        code.putln(
            'if (unlikely(__Pyx_ParseOptionalKeywords(%s, %s, %s, values, %s, "%s") < 0)) %s' % (
                Naming.kwds_cname,
                Naming.pykwdlist_cname,
                self.starstar_arg and self.starstar_arg.entry.cname or '0',
                pos_arg_count,
                self.name,
                code.error_goto(self.pos)))
        code.putln('}')

    def generate_optional_kwonly_args_unpacking_code(self, all_args, code):
        optional_args = []
        first_optional_arg = -1
        for i, arg in enumerate(all_args):
            if not arg.kw_only or not arg.default:
                continue
            if not optional_args:
                first_optional_arg = i
            optional_args.append(arg.name)
        if optional_args:
            if len(optional_args) > 1:
                # if we receive more than the named kwargs, we either have **kwargs
                # (in which case we must iterate anyway) or it's an error (which we
                # also handle during iteration) => skip this part if there are more
                code.putln('if (kw_args > 0 && %s(kw_args <= %d)) {' % (
                    not self.starstar_arg and 'likely' or '',
                    len(optional_args)))
                code.putln('Py_ssize_t index;')
                # not unrolling the loop here reduces the C code overhead
                code.putln('for (index = %d; index < %d && kw_args > 0; index++) {' % (
                    first_optional_arg, first_optional_arg + len(optional_args)))
            else:
                code.putln('if (kw_args == 1) {')
                code.putln('const Py_ssize_t index = %d;' % first_optional_arg)
            code.putln('PyObject* value = PyDict_GetItem(%s, *%s[index]);' % (
                Naming.kwds_cname, Naming.pykwdlist_cname))
            code.putln('if (value) { values[index] = value; kw_args--; }')
            if len(optional_args) > 1:
                code.putln('}')
            code.putln('}')

    def generate_argument_conversion_code(self, code):
        # Generate code to convert arguments from signature type to
        # declared type, if needed.  Also copies signature arguments
        # into closure fields.
        for arg in self.args:
            if arg.needs_conversion:
                self.generate_arg_conversion(arg, code)

    def generate_arg_conversion(self, arg, code):
        # Generate conversion code for one argument.
        old_type = arg.hdr_type
        new_type = arg.type
        if old_type.is_pyobject:
            if arg.default:
                code.putln("if (%s) {" % arg.hdr_cname)
            else:
                code.putln("assert(%s); {" % arg.hdr_cname)
            self.generate_arg_conversion_from_pyobject(arg, code)
            code.putln("}")
        elif new_type.is_pyobject:
            self.generate_arg_conversion_to_pyobject(arg, code)
        else:
            if new_type.assignable_from(old_type):
                code.putln(
                    "%s = %s;" % (arg.entry.cname, arg.hdr_cname))
            else:
                error(arg.pos,
                    "Cannot convert 1 argument from '%s' to '%s'" %
                        (old_type, new_type))

    def generate_arg_conversion_from_pyobject(self, arg, code):
        new_type = arg.type
        func = new_type.from_py_function
        # copied from CoerceFromPyTypeNode
        if func:
            lhs = arg.entry.cname
            rhs = "%s(%s)" % (func, arg.hdr_cname)
            if new_type.is_enum:
                rhs = PyrexTypes.typecast(new_type, PyrexTypes.c_long_type, rhs)
            code.putln("%s = %s; %s" % (
                lhs,
                rhs,
                code.error_goto_if(new_type.error_condition(arg.entry.cname), arg.pos)))
        else:
            error(arg.pos,
                "Cannot convert Python object argument to type '%s'"
                    % new_type)

    def generate_arg_conversion_to_pyobject(self, arg, code):
        old_type = arg.hdr_type
        func = old_type.to_py_function
        if func:
            code.putln("%s = %s(%s); %s" % (
                arg.entry.cname,
                func,
                arg.hdr_cname,
                code.error_goto_if_null(arg.entry.cname, arg.pos)))
            code.put_var_gotref(arg.entry)
        else:
            error(arg.pos,
                "Cannot convert argument of type '%s' to Python object"
                    % old_type)

    def generate_argument_type_tests(self, code):
        # Generate type tests for args whose signature
        # type is PyObject * and whose declared type is
        # a subtype thereof.
        for arg in self.args:
            if arg.needs_type_test:
                self.generate_arg_type_test(arg, code)
            elif not arg.accept_none and (arg.type.is_pyobject or
                                          arg.type.is_buffer or
                                          arg.type.is_memoryviewslice):
                self.generate_arg_none_check(arg, code)

    def error_value(self):
        return self.signature.error_value


class GeneratorDefNode(DefNode):
    # Generator function node that creates a new generator instance when called.
    #
    # gbody          GeneratorBodyDefNode   the function implementing the generator
    #

    is_generator = True
    needs_closure = True

    child_attrs = DefNode.child_attrs + ["gbody"]

    def __init__(self, **kwargs):
        # XXX: don't actually needs a body
        kwargs['body'] = StatListNode(kwargs['pos'], stats=[])
        super(GeneratorDefNode, self).__init__(**kwargs)

    def analyse_declarations(self, env):
        super(GeneratorDefNode, self).analyse_declarations(env)
        self.gbody.local_scope = self.local_scope
        self.gbody.analyse_declarations(env)

    def generate_function_body(self, env, code):
        body_cname = self.gbody.entry.func_cname

        code.putln('{')
        code.putln('__pyx_GeneratorObject *gen = __Pyx_Generator_New('
                   '(__pyx_generator_body_t) %s, (PyObject *) %s); %s' % (
                       body_cname, Naming.cur_scope_cname,
                       code.error_goto_if_null('gen', self.pos)))
        code.put_decref(Naming.cur_scope_cname, py_object_type)
        if self.requires_classobj:
            classobj_cname = 'gen->classobj'
            code.putln('%s = __Pyx_CyFunction_GetClassObj(%s);' % (
                classobj_cname, Naming.self_cname))
            code.put_incref(classobj_cname, py_object_type)
            code.put_giveref(classobj_cname)
        code.put_finish_refcount_context()
        code.putln('return (PyObject *) gen;')
        code.putln('}')

    def generate_function_definitions(self, env, code):
        env.use_utility_code(UtilityCode.load_cached("Generator", "Generator.c"))

        self.gbody.generate_function_header(code, proto=True)
        super(GeneratorDefNode, self).generate_function_definitions(env, code)
        self.gbody.generate_function_definitions(env, code)


class GeneratorBodyDefNode(DefNode):
    # Main code body of a generator implemented as a DefNode.
    #

    is_generator_body = True

    def __init__(self, pos=None, name=None, body=None):
        super(GeneratorBodyDefNode, self).__init__(
            pos=pos, body=body, name=name, doc=None,
            args=[], star_arg=None, starstar_arg=None)

    def declare_generator_body(self, env):
        prefix = env.next_id(env.scope_prefix)
        name = env.next_id('generator')
        cname = Naming.genbody_prefix + prefix + name
        entry = env.declare_var(None, py_object_type, self.pos,
                                cname=cname, visibility='private')
        entry.func_cname = cname
        entry.qualified_name = EncodedString(self.name)
        self.entry = entry

    def analyse_declarations(self, env):
        self.analyse_argument_types(env)
        self.declare_generator_body(env)

    def generate_function_header(self, code, proto=False):
        header = "static PyObject *%s(__pyx_GeneratorObject *%s, PyObject *%s)" % (
            self.entry.func_cname,
            Naming.generator_cname,
            Naming.sent_value_cname)
        if proto:
            code.putln('%s; /* proto */' % header)
        else:
            code.putln('%s /* generator body */\n{' % header)

    def generate_function_definitions(self, env, code):
        lenv = self.local_scope

        # Generate closure function definitions
        self.body.generate_function_definitions(lenv, code)

        # Generate C code for header and body of function
        code.enter_cfunc_scope()
        code.return_from_error_cleanup_label = code.new_label()

        # ----- Top-level constants used by this function
        code.mark_pos(self.pos)
        self.generate_cached_builtins_decls(lenv, code)
        # ----- Function header
        code.putln("")
        self.generate_function_header(code)
        closure_init_code = code.insertion_point()
        # ----- Local variables
        code.putln("PyObject *%s = NULL;" % Naming.retval_cname)
        tempvardecl_code = code.insertion_point()
        code.put_declare_refcount_context()
        code.put_setup_refcount_context(self.entry.name)

        # ----- Resume switch point.
        code.funcstate.init_closure_temps(lenv.scope_class.type.scope)
        resume_code = code.insertion_point()
        first_run_label = code.new_label('first_run')
        code.use_label(first_run_label)
        code.put_label(first_run_label)
        code.putln('%s' %
                   (code.error_goto_if_null(Naming.sent_value_cname, self.pos)))

        # ----- Function body
        self.generate_function_body(env, code)
        # ----- Closure initialization
        if lenv.scope_class.type.scope.entries:
            closure_init_code.putln('%s = %s;' % (
                lenv.scope_class.type.declaration_code(Naming.cur_scope_cname),
                lenv.scope_class.type.cast_code('%s->closure' %
                                                Naming.generator_cname)))

        code.mark_pos(self.pos)
        code.putln("")
        code.putln("/* function exit code */")

        # on normal generator termination, we do not take the exception propagation
        # path: no traceback info is required and not creating it is much faster
        if not self.body.is_terminator:
            code.putln('PyErr_SetNone(PyExc_StopIteration);')
        # ----- Error cleanup
        if code.error_label in code.labels_used:
            if not self.body.is_terminator:
                code.put_goto(code.return_label)
            code.put_label(code.error_label)
            for cname, type in code.funcstate.all_managed_temps():
                code.put_xdecref(cname, type)
            code.put_add_traceback(self.entry.qualified_name)

        # ----- Non-error return cleanup
        code.put_label(code.return_label)
        code.put_xdecref(Naming.retval_cname, py_object_type)
        code.putln('%s->resume_label = -1;' % Naming.generator_cname)
        # clean up as early as possible to help breaking any reference cycles
        code.putln('__Pyx_Generator_clear((PyObject*)%s);' % Naming.generator_cname)
        code.put_finish_refcount_context()
        code.putln('return NULL;')
        code.putln("}")

        # ----- Go back and insert temp variable declarations
        tempvardecl_code.put_temp_declarations(code.funcstate)
        # ----- Generator resume code
        resume_code.putln("switch (%s->resume_label) {" % (
                       Naming.generator_cname))
        resume_code.putln("case 0: goto %s;" % first_run_label)

        for i, label in code.yield_labels:
            resume_code.putln("case %d: goto %s;" % (i, label))
        resume_code.putln("default: /* CPython raises the right error here */")
        resume_code.put_finish_refcount_context()
        resume_code.putln("return NULL;")
        resume_code.putln("}")

        code.exit_cfunc_scope()


class OverrideCheckNode(StatNode):
    # A Node for dispatching to the def method if it
    # is overriden.
    #
    #  py_func
    #
    #  args
    #  func_temp
    #  body

    child_attrs = ['body']

    body = None

    def analyse_expressions(self, env):
        self.args = env.arg_entries
        if self.py_func.is_module_scope:
            first_arg = 0
        else:
            first_arg = 1
        import ExprNodes
        self.func_node = ExprNodes.RawCNameExprNode(self.pos, py_object_type)
        call_node = ExprNodes.SimpleCallNode(
            self.pos, function=self.func_node,
            args=[ ExprNodes.NameNode(self.pos, name=arg.name)
                   for arg in self.args[first_arg:] ])
        self.body = ReturnStatNode(self.pos, value=call_node)
        self.body = self.body.analyse_expressions(env)
        return self

    def generate_execution_code(self, code):
        interned_attr_cname = code.intern_identifier(self.py_func.entry.name)
        # Check to see if we are an extension type
        if self.py_func.is_module_scope:
            self_arg = "((PyObject *)%s)" % Naming.module_cname
        else:
            self_arg = "((PyObject *)%s)" % self.args[0].cname
        code.putln("/* Check if called by wrapper */")
        code.putln("if (unlikely(%s)) ;" % Naming.skip_dispatch_cname)
        code.putln("/* Check if overridden in Python */")
        if self.py_func.is_module_scope:
            code.putln("else {")
        else:
            code.putln("else if (unlikely(Py_TYPE(%s)->tp_dictoffset != 0)) {" % self_arg)
        func_node_temp = code.funcstate.allocate_temp(py_object_type, manage_ref=True)
        self.func_node.set_cname(func_node_temp)
        # need to get attribute manually--scope would return cdef method
        code.globalstate.use_utility_code(
            UtilityCode.load_cached("PyObjectGetAttrStr", "ObjectHandling.c"))
        err = code.error_goto_if_null(func_node_temp, self.pos)
        code.putln("%s = __Pyx_PyObject_GetAttrStr(%s, %s); %s" % (
            func_node_temp, self_arg, interned_attr_cname, err))
        code.put_gotref(func_node_temp)
        is_builtin_function_or_method = "PyCFunction_Check(%s)" % func_node_temp
        is_overridden = "(PyCFunction_GET_FUNCTION(%s) != (PyCFunction)%s)" % (
            func_node_temp, self.py_func.entry.func_cname)
        code.putln("if (!%s || %s) {" % (is_builtin_function_or_method, is_overridden))
        self.body.generate_execution_code(code)
        code.putln("}")
        code.put_decref_clear(func_node_temp, PyrexTypes.py_object_type)
        code.funcstate.release_temp(func_node_temp)
        code.putln("}")

class ClassDefNode(StatNode, BlockNode):
    pass

class PyClassDefNode(ClassDefNode):
    #  A Python class definition.
    #
    #  name     EncodedString   Name of the class
    #  doc      string or None
    #  body     StatNode        Attribute definition code
    #  entry    Symtab.Entry
    #  scope    PyClassScope
    #  decorators    [DecoratorNode]        list of decorators or None
    #
    #  The following subnodes are constructed internally:
    #
    #  dict     DictNode   Class dictionary or Py3 namespace
    #  classobj ClassNode  Class object
    #  target   NameNode   Variable to assign class object to

    child_attrs = ["body", "dict", "metaclass", "mkw", "bases", "class_result",
                   "target", "class_cell", "decorators"]
    decorators = None
    class_result = None
    is_py3_style_class = False  # Python3 style class (kwargs)
    metaclass = None
    mkw = None

    def __init__(self, pos, name, bases, doc, body, decorators=None,
                 keyword_args=None, starstar_arg=None, force_py3_semantics=False):
        StatNode.__init__(self, pos)
        self.name = name
        self.doc = doc
        self.body = body
        self.decorators = decorators
        self.bases = bases
        import ExprNodes
        if self.doc and Options.docstrings:
            doc = embed_position(self.pos, self.doc)
            doc_node = ExprNodes.StringNode(pos, value=doc)
        else:
            doc_node = None

        allow_py2_metaclass = not force_py3_semantics
        if keyword_args or starstar_arg:
            allow_py2_metaclass = False
            self.is_py3_style_class = True
            if keyword_args and not starstar_arg:
                for i, item in list(enumerate(keyword_args.key_value_pairs))[::-1]:
                    if item.key.value == 'metaclass':
                        if self.metaclass is not None:
                            error(item.pos, "keyword argument 'metaclass' passed multiple times")
                        # special case: we already know the metaclass,
                        # so we don't need to do the "build kwargs,
                        # find metaclass" dance at runtime
                        self.metaclass = item.value
                        del keyword_args.key_value_pairs[i]
            if starstar_arg:
                self.mkw = ExprNodes.KeywordArgsNode(
                    pos, keyword_args=keyword_args and keyword_args.key_value_pairs or [],
                    starstar_arg=starstar_arg)
            elif keyword_args.key_value_pairs:
                self.mkw = keyword_args
            else:
                assert self.metaclass is not None

        if force_py3_semantics or self.bases or self.mkw or self.metaclass:
            if self.metaclass is None:
                if starstar_arg:
                    # **kwargs may contain 'metaclass' arg
                    mkdict = self.mkw
                else:
                    mkdict = None
                if (not mkdict and
                        self.bases.is_sequence_constructor and
                        not self.bases.args):
                    pass  # no base classes => no inherited metaclass
                else:
                    self.metaclass = ExprNodes.PyClassMetaclassNode(
                        pos, mkw=mkdict, bases=self.bases)
                needs_metaclass_calculation = False
            else:
                needs_metaclass_calculation = True

            self.dict = ExprNodes.PyClassNamespaceNode(
                pos, name=name, doc=doc_node,
                metaclass=self.metaclass, bases=self.bases, mkw=self.mkw)
            self.classobj = ExprNodes.Py3ClassNode(
                pos, name=name,
                bases=self.bases, dict=self.dict, doc=doc_node,
                metaclass=self.metaclass, mkw=self.mkw,
                calculate_metaclass=needs_metaclass_calculation,
                allow_py2_metaclass=allow_py2_metaclass)
        else:
            # no bases, no metaclass => old style class creation
            self.dict = ExprNodes.DictNode(pos, key_value_pairs=[])
            self.classobj = ExprNodes.ClassNode(
                pos, name=name,
                bases=bases, dict=self.dict, doc=doc_node)

        self.target = ExprNodes.NameNode(pos, name=name)
        self.class_cell = ExprNodes.ClassCellInjectorNode(self.pos)

    def as_cclass(self):
        """
        Return this node as if it were declared as an extension class
        """
        if self.is_py3_style_class:
            error(self.classobj.pos, "Python3 style class could not be represented as C class")
            return
        bases = self.classobj.bases.args
        if len(bases) == 0:
            base_class_name = None
            base_class_module = None
        elif len(bases) == 1:
            base = bases[0]
            path = []
            from ExprNodes import AttributeNode, NameNode
            while isinstance(base, AttributeNode):
                path.insert(0, base.attribute)
                base = base.obj
            if isinstance(base, NameNode):
                path.insert(0, base.name)
                base_class_name = path[-1]
                if len(path) > 1:
                    base_class_module = u'.'.join(path[:-1])
                else:
                    base_class_module = None
            else:
                error(self.classobj.bases.args.pos, "Invalid base class")
        else:
            error(self.classobj.bases.args.pos, "C class may only have one base class")
            return None

        return CClassDefNode(self.pos,
                             visibility = 'private',
                             module_name = None,
                             class_name = self.name,
                             base_class_module = base_class_module,
                             base_class_name = base_class_name,
                             decorators = self.decorators,
                             body = self.body,
                             in_pxd = False,
                             doc = self.doc)

    def create_scope(self, env):
        genv = env
        while genv.is_py_class_scope or genv.is_c_class_scope:
            genv = genv.outer_scope
        cenv = self.scope = PyClassScope(name = self.name, outer_scope = genv)
        return cenv

    def analyse_declarations(self, env):
        class_result = self.classobj
        if self.decorators:
            from ExprNodes import SimpleCallNode
            for decorator in self.decorators[::-1]:
                class_result = SimpleCallNode(
                    decorator.pos,
                    function = decorator.decorator,
                    args = [class_result])
            self.decorators = None
        self.class_result = class_result
        self.class_result.analyse_declarations(env)
        self.target.analyse_target_declaration(env)
        cenv = self.create_scope(env)
        cenv.directives = env.directives
        cenv.class_obj_cname = self.target.entry.cname
        self.body.analyse_declarations(cenv)

    def analyse_expressions(self, env):
        if self.bases:
            self.bases = self.bases.analyse_expressions(env)
        if self.metaclass:
            self.metaclass = self.metaclass.analyse_expressions(env)
        if self.mkw:
            self.mkw = self.mkw.analyse_expressions(env)
        self.dict = self.dict.analyse_expressions(env)
        self.class_result = self.class_result.analyse_expressions(env)
        genv = env.global_scope()
        cenv = self.scope
        self.body = self.body.analyse_expressions(cenv)
        self.target.analyse_target_expression(env, self.classobj)
        self.class_cell = self.class_cell.analyse_expressions(cenv)
        return self

    def generate_function_definitions(self, env, code):
        self.generate_lambda_definitions(self.scope, code)
        self.body.generate_function_definitions(self.scope, code)

    def generate_execution_code(self, code):
        code.pyclass_stack.append(self)
        cenv = self.scope
        if self.bases:
            self.bases.generate_evaluation_code(code)
        if self.mkw:
            self.mkw.generate_evaluation_code(code)
        if self.metaclass:
            self.metaclass.generate_evaluation_code(code)
        self.dict.generate_evaluation_code(code)
        cenv.namespace_cname = cenv.class_obj_cname = self.dict.result()
        self.class_cell.generate_evaluation_code(code)
        self.body.generate_execution_code(code)
        self.class_result.generate_evaluation_code(code)
        self.class_cell.generate_injection_code(
            code, self.class_result.result())
        self.class_cell.generate_disposal_code(code)
        cenv.namespace_cname = cenv.class_obj_cname = self.classobj.result()
        self.target.generate_assignment_code(self.class_result, code)
        self.dict.generate_disposal_code(code)
        self.dict.free_temps(code)
        if self.metaclass:
            self.metaclass.generate_disposal_code(code)
            self.metaclass.free_temps(code)
        if self.mkw:
            self.mkw.generate_disposal_code(code)
            self.mkw.free_temps(code)
        if self.bases:
            self.bases.generate_disposal_code(code)
            self.bases.free_temps(code)
        code.pyclass_stack.pop()

class CClassDefNode(ClassDefNode):
    #  An extension type definition.
    #
    #  visibility         'private' or 'public' or 'extern'
    #  typedef_flag       boolean
    #  api                boolean
    #  module_name        string or None    For import of extern type objects
    #  class_name         string            Unqualified name of class
    #  as_name            string or None    Name to declare as in this scope
    #  base_class_module  string or None    Module containing the base class
    #  base_class_name    string or None    Name of the base class
    #  objstruct_name     string or None    Specified C name of object struct
    #  typeobj_name       string or None    Specified C name of type object
    #  in_pxd             boolean           Is in a .pxd file
    #  decorators         [DecoratorNode]   list of decorators or None
    #  doc                string or None
    #  body               StatNode or None
    #  entry              Symtab.Entry
    #  base_type          PyExtensionType or None
    #  buffer_defaults_node DictNode or None Declares defaults for a buffer
    #  buffer_defaults_pos

    child_attrs = ["body"]
    buffer_defaults_node = None
    buffer_defaults_pos = None
    typedef_flag = False
    api = False
    objstruct_name = None
    typeobj_name = None
    decorators = None
    shadow = False

    def buffer_defaults(self, env):
        if not hasattr(self, '_buffer_defaults'):
            import Buffer
            if self.buffer_defaults_node:
                self._buffer_defaults = Buffer.analyse_buffer_options(
                    self.buffer_defaults_pos,
                    env, [], self.buffer_defaults_node,
                    need_complete=False)
            else:
                self._buffer_defaults = None
        return self._buffer_defaults

    def declare(self, env):
        if self.module_name and self.visibility != 'extern':
            module_path = self.module_name.split(".")
            home_scope = env.find_imported_module(module_path, self.pos)
            if not home_scope:
                return None
        else:
            home_scope = env

        self.entry = home_scope.declare_c_class(
            name = self.class_name,
            pos = self.pos,
            defining = 0,
            implementing = 0,
            module_name = self.module_name,
            base_type = None,
            objstruct_cname = self.objstruct_name,
            typeobj_cname = self.typeobj_name,
            visibility = self.visibility,
            typedef_flag = self.typedef_flag,
            api = self.api,
            buffer_defaults = self.buffer_defaults(env),
            shadow = self.shadow)

    def analyse_declarations(self, env):
        #print "CClassDefNode.analyse_declarations:", self.class_name
        #print "...visibility =", self.visibility
        #print "...module_name =", self.module_name

        if env.in_cinclude and not self.objstruct_name:
            error(self.pos, "Object struct name specification required for "
                "C class defined in 'extern from' block")
        if self.decorators:
            error(self.pos,
                  "Decorators not allowed on cdef classes (used on type '%s')" % self.class_name)
        self.base_type = None
        # Now that module imports are cached, we need to
        # import the modules for extern classes.
        if self.module_name:
            self.module = None
            for module in env.cimported_modules:
                if module.name == self.module_name:
                    self.module = module
            if self.module is None:
                self.module = ModuleScope(self.module_name, None, env.context)
                self.module.has_extern_class = 1
                env.add_imported_module(self.module)

        if self.base_class_name:
            if self.base_class_module:
                base_class_scope = env.find_module(self.base_class_module, self.pos)
            else:
                base_class_scope = env
            if self.base_class_name == 'object':
                # extension classes are special and don't need to inherit from object
                if base_class_scope is None or base_class_scope.lookup('object') is None:
                    self.base_class_name = None
                    self.base_class_module = None
                    base_class_scope = None
            if base_class_scope:
                base_class_entry = base_class_scope.find(self.base_class_name, self.pos)
                if base_class_entry:
                    if not base_class_entry.is_type:
                        error(self.pos, "'%s' is not a type name" % self.base_class_name)
                    elif not base_class_entry.type.is_extension_type and \
                             not (base_class_entry.type.is_builtin_type and
                                  base_class_entry.type.objstruct_cname):
                        error(self.pos, "'%s' is not an extension type" % self.base_class_name)
                    elif not base_class_entry.type.is_complete():
                        error(self.pos, "Base class '%s' of type '%s' is incomplete" % (
                            self.base_class_name, self.class_name))
                    elif base_class_entry.type.scope and base_class_entry.type.scope.directives and \
                             base_class_entry.type.is_final_type:
                        error(self.pos, "Base class '%s' of type '%s' is final" % (
                            self.base_class_name, self.class_name))
                    elif base_class_entry.type.is_builtin_type and \
                             base_class_entry.type.name in ('tuple', 'str', 'bytes'):
                        error(self.pos, "inheritance from PyVarObject types like '%s' is not currently supported"
                              % base_class_entry.type.name)
                    else:
                        self.base_type = base_class_entry.type
                if env.directives.get('freelist', 0) > 0:
                    warning(self.pos, "freelists cannot be used on subtypes, only the base class can manage them", 1)

        has_body = self.body is not None
        if has_body and self.base_type and not self.base_type.scope:
            # To properly initialize inherited attributes, the base type must
            # be analysed before this type.
            self.base_type.defered_declarations.append(lambda : self.analyse_declarations(env))
            return

        if self.module_name and self.visibility != 'extern':
            module_path = self.module_name.split(".")
            home_scope = env.find_imported_module(module_path, self.pos)
            if not home_scope:
                return
        else:
            home_scope = env

        if self.visibility == 'extern':
            if (self.module_name == '__builtin__' and
                self.class_name in Builtin.builtin_types and
                env.qualified_name[:8] != 'cpython.'): # allow overloaded names for cimporting from cpython
                warning(self.pos, "%s already a builtin Cython type" % self.class_name, 1)

        self.entry = home_scope.declare_c_class(
            name = self.class_name,
            pos = self.pos,
            defining = has_body and self.in_pxd,
            implementing = has_body and not self.in_pxd,
            module_name = self.module_name,
            base_type = self.base_type,
            objstruct_cname = self.objstruct_name,
            typeobj_cname = self.typeobj_name,
            visibility = self.visibility,
            typedef_flag = self.typedef_flag,
            api = self.api,
            buffer_defaults = self.buffer_defaults(env),
            shadow = self.shadow)

        if self.shadow:
            home_scope.lookup(self.class_name).as_variable = self.entry
        if home_scope is not env and self.visibility == 'extern':
            env.add_imported_entry(self.class_name, self.entry, self.pos)
        self.scope = scope = self.entry.type.scope
        if scope is not None:
            scope.directives = env.directives

        if self.doc and Options.docstrings:
            scope.doc = embed_position(self.pos, self.doc)

        if has_body:
            self.body.analyse_declarations(scope)
            if self.in_pxd:
                scope.defined = 1
            else:
                scope.implemented = 1
        env.allocate_vtable_names(self.entry)

        for thunk in self.entry.type.defered_declarations:
            thunk()

    def analyse_expressions(self, env):
        if self.body:
            scope = self.entry.type.scope
            self.body = self.body.analyse_expressions(scope)
        return self

    def generate_function_definitions(self, env, code):
        if self.body:
            self.generate_lambda_definitions(self.scope, code)
            self.body.generate_function_definitions(self.scope, code)

    def generate_execution_code(self, code):
        # This is needed to generate evaluation code for
        # default values of method arguments.
        if self.body:
            self.body.generate_execution_code(code)

    def annotate(self, code):
        if self.body:
            self.body.annotate(code)


class PropertyNode(StatNode):
    #  Definition of a property in an extension type.
    #
    #  name   string
    #  doc    EncodedString or None    Doc string
    #  entry  Symtab.Entry
    #  body   StatListNode

    child_attrs = ["body"]

    def analyse_declarations(self, env):
        self.entry = env.declare_property(self.name, self.doc, self.pos)
        self.entry.scope.directives = env.directives
        self.body.analyse_declarations(self.entry.scope)

    def analyse_expressions(self, env):
        self.body = self.body.analyse_expressions(env)
        return self

    def generate_function_definitions(self, env, code):
        self.body.generate_function_definitions(env, code)

    def generate_execution_code(self, code):
        pass

    def annotate(self, code):
        self.body.annotate(code)


class GlobalNode(StatNode):
    # Global variable declaration.
    #
    # names    [string]

    child_attrs = []

    def analyse_declarations(self, env):
        for name in self.names:
            env.declare_global(name, self.pos)

    def analyse_expressions(self, env):
        return self

    def generate_execution_code(self, code):
        pass


class NonlocalNode(StatNode):
    # Nonlocal variable declaration via the 'nonlocal' keyword.
    #
    # names    [string]

    child_attrs = []

    def analyse_declarations(self, env):
        for name in self.names:
            env.declare_nonlocal(name, self.pos)

    def analyse_expressions(self, env):
        return self

    def generate_execution_code(self, code):
        pass


class ExprStatNode(StatNode):
    #  Expression used as a statement.
    #
    #  expr   ExprNode

    child_attrs = ["expr"]

    def analyse_declarations(self, env):
        import ExprNodes
        if isinstance(self.expr, ExprNodes.GeneralCallNode):
            func = self.expr.function.as_cython_attribute()
            if func == u'declare':
                args, kwds = self.expr.explicit_args_kwds()
                if len(args):
                    error(self.expr.pos, "Variable names must be specified.")
                for var, type_node in kwds.key_value_pairs:
                    type = type_node.analyse_as_type(env)
                    if type is None:
                        error(type_node.pos, "Unknown type")
                    else:
                        env.declare_var(var.value, type, var.pos, is_cdef = True)
                self.__class__ = PassStatNode

    def analyse_expressions(self, env):
        self.expr.result_is_used = False # hint that .result() may safely be left empty
        self.expr = self.expr.analyse_expressions(env)
        return self

    def nogil_check(self, env):
        if self.expr.type.is_pyobject and self.expr.is_temp:
            self.gil_error()

    gil_message = "Discarding owned Python object"

    def generate_execution_code(self, code):
        self.expr.generate_evaluation_code(code)
        if not self.expr.is_temp and self.expr.result():
            code.putln("%s;" % self.expr.result())
        self.expr.generate_disposal_code(code)
        self.expr.free_temps(code)

    def generate_function_definitions(self, env, code):
        self.expr.generate_function_definitions(env, code)

    def annotate(self, code):
        self.expr.annotate(code)


class AssignmentNode(StatNode):
    #  Abstract base class for assignment nodes.
    #
    #  The analyse_expressions and generate_execution_code
    #  phases of assignments are split into two sub-phases
    #  each, to enable all the right hand sides of a
    #  parallel assignment to be evaluated before assigning
    #  to any of the left hand sides.

    def analyse_expressions(self, env):
        return self.analyse_types(env)

#       def analyse_expressions(self, env):
#           self.analyse_expressions_1(env)
#           self.analyse_expressions_2(env)

    def generate_execution_code(self, code):
        self.generate_rhs_evaluation_code(code)
        self.generate_assignment_code(code)


class SingleAssignmentNode(AssignmentNode):
    #  The simplest case:
    #
    #    a = b
    #
    #  lhs      ExprNode      Left hand side
    #  rhs      ExprNode      Right hand side
    #  first    bool          Is this guaranteed the first assignment to lhs?

    child_attrs = ["lhs", "rhs"]
    first = False
    declaration_only = False

    def analyse_declarations(self, env):
        import ExprNodes

        # handle declarations of the form x = cython.foo()
        if isinstance(self.rhs, ExprNodes.CallNode):
            func_name = self.rhs.function.as_cython_attribute()
            if func_name:
                args, kwds = self.rhs.explicit_args_kwds()

                if func_name in ['declare', 'typedef']:
                    if len(args) > 2 or kwds is not None:
                        error(self.rhs.pos, "Can only declare one type at a time.")
                        return

                    type = args[0].analyse_as_type(env)
                    if type is None:
                        error(args[0].pos, "Unknown type")
                        return
                    lhs = self.lhs
                    if func_name == 'declare':
                        if isinstance(lhs, ExprNodes.NameNode):
                            vars = [(lhs.name, lhs.pos)]
                        elif isinstance(lhs, ExprNodes.TupleNode):
                            vars = [(var.name, var.pos) for var in lhs.args]
                        else:
                            error(lhs.pos, "Invalid declaration")
                            return
                        for var, pos in vars:
                            env.declare_var(var, type, pos, is_cdef = True)
                        if len(args) == 2:
                            # we have a value
                            self.rhs = args[1]
                        else:
                            self.declaration_only = True
                    else:
                        self.declaration_only = True
                        if not isinstance(lhs, ExprNodes.NameNode):
                            error(lhs.pos, "Invalid declaration.")
                        env.declare_typedef(lhs.name, type, self.pos, visibility='private')

                elif func_name in ['struct', 'union']:
                    self.declaration_only = True
                    if len(args) > 0 or kwds is None:
                        error(self.rhs.pos, "Struct or union members must be given by name.")
                        return
                    members = []
                    for member, type_node in kwds.key_value_pairs:
                        type = type_node.analyse_as_type(env)
                        if type is None:
                            error(type_node.pos, "Unknown type")
                        else:
                            members.append((member.value, type, member.pos))
                    if len(members) < len(kwds.key_value_pairs):
                        return
                    if not isinstance(self.lhs, ExprNodes.NameNode):
                        error(self.lhs.pos, "Invalid declaration.")
                    name = self.lhs.name
                    scope = StructOrUnionScope(name)
                    env.declare_struct_or_union(name, func_name, scope, False, self.rhs.pos)
                    for member, type, pos in members:
                        scope.declare_var(member, type, pos)

                elif func_name == 'fused_type':
                    # dtype = cython.fused_type(...)
                    self.declaration_only = True
                    if kwds:
                        error(self.rhs.function.pos,
                              "fused_type does not take keyword arguments")

                    fusednode = FusedTypeNode(self.rhs.pos,
                                              name = self.lhs.name, types=args)
                    fusednode.analyse_declarations(env)

        if self.declaration_only:
            return
        else:
            self.lhs.analyse_target_declaration(env)

    def analyse_types(self, env, use_temp = 0):
        import ExprNodes

        self.rhs = self.rhs.analyse_types(env)
        self.lhs = self.lhs.analyse_target_types(env)
        self.lhs.gil_assignment_check(env)

        if self.lhs.memslice_broadcast or self.rhs.memslice_broadcast:
            self.lhs.memslice_broadcast = True
            self.rhs.memslice_broadcast = True

        is_index_node = isinstance(self.lhs, ExprNodes.IndexNode)
        if (is_index_node and not self.rhs.type.is_memoryviewslice and
            (self.lhs.memslice_slice or self.lhs.is_memslice_copy) and
            (self.lhs.type.dtype.assignable_from(self.rhs.type) or
             self.rhs.type.is_pyobject)):
            # scalar slice assignment
            self.lhs.is_memslice_scalar_assignment = True
            dtype = self.lhs.type.dtype
        else:
            dtype = self.lhs.type

        rhs = self.rhs.coerce_to(dtype, env)
        if use_temp or rhs.is_attribute or (
                not rhs.is_name and not rhs.is_literal and
                rhs.type.is_pyobject):
            # things like (cdef) attribute access are not safe (traverses pointers)
            rhs = rhs.coerce_to_temp(env)
        elif rhs.type.is_pyobject:
            rhs = rhs.coerce_to_simple(env)
        self.rhs = rhs
        return self

    def generate_rhs_evaluation_code(self, code):
        self.rhs.generate_evaluation_code(code)

    def generate_assignment_code(self, code):
        self.lhs.generate_assignment_code(self.rhs, code)

    def generate_function_definitions(self, env, code):
        self.rhs.generate_function_definitions(env, code)

    def annotate(self, code):
        self.lhs.annotate(code)
        self.rhs.annotate(code)


class CascadedAssignmentNode(AssignmentNode):
    #  An assignment with multiple left hand sides:
    #
    #    a = b = c
    #
    #  lhs_list   [ExprNode]   Left hand sides
    #  rhs        ExprNode     Right hand sides
    #
    #  Used internally:
    #
    #  coerced_rhs_list   [ExprNode]   RHS coerced to type of each LHS

    child_attrs = ["lhs_list", "rhs", "coerced_rhs_list"]
    coerced_rhs_list = None

    def analyse_declarations(self, env):
        for lhs in self.lhs_list:
            lhs.analyse_target_declaration(env)

    def analyse_types(self, env, use_temp = 0):
        from ExprNodes import CloneNode, ProxyNode

        rhs = self.rhs.analyse_types(env)
        if use_temp or rhs.is_attribute or (
                not rhs.is_name and not rhs.is_literal and
                rhs.type.is_pyobject):
            rhs = rhs.coerce_to_temp(env)
        else:
            rhs = rhs.coerce_to_simple(env)
        self.rhs = ProxyNode(rhs)

        self.coerced_rhs_list = []
        for lhs in self.lhs_list:
            lhs.analyse_target_types(env)
            lhs.gil_assignment_check(env)
            rhs = CloneNode(self.rhs)
            rhs = rhs.coerce_to(lhs.type, env)
            self.coerced_rhs_list.append(rhs)
        return self

    def generate_rhs_evaluation_code(self, code):
        self.rhs.generate_evaluation_code(code)

    def generate_assignment_code(self, code):
        for i in range(len(self.lhs_list)):
            lhs = self.lhs_list[i]
            rhs = self.coerced_rhs_list[i]
            rhs.generate_evaluation_code(code)
            lhs.generate_assignment_code(rhs, code)
            # Assignment has disposed of the cloned RHS
        self.rhs.generate_disposal_code(code)
        self.rhs.free_temps(code)

    def generate_function_definitions(self, env, code):
        self.rhs.generate_function_definitions(env, code)

    def annotate(self, code):
        for i in range(len(self.lhs_list)):
            self.lhs_list[i].annotate(code)
            self.coerced_rhs_list[i].annotate(code)
        self.rhs.annotate(code)


class ParallelAssignmentNode(AssignmentNode):
    #  A combined packing/unpacking assignment:
    #
    #    a, b, c =  d, e, f
    #
    #  This has been rearranged by the parser into
    #
    #    a = d ; b = e ; c = f
    #
    #  but we must evaluate all the right hand sides
    #  before assigning to any of the left hand sides.
    #
    #  stats     [AssignmentNode]   The constituent assignments

    child_attrs = ["stats"]

    def analyse_declarations(self, env):
        for stat in self.stats:
            stat.analyse_declarations(env)

    def analyse_expressions(self, env):
        self.stats = [ stat.analyse_types(env, use_temp = 1)
                       for stat in self.stats ]
        return self

#    def analyse_expressions(self, env):
#        for stat in self.stats:
#            stat.analyse_expressions_1(env, use_temp = 1)
#        for stat in self.stats:
#            stat.analyse_expressions_2(env)

    def generate_execution_code(self, code):
        for stat in self.stats:
            stat.generate_rhs_evaluation_code(code)
        for stat in self.stats:
            stat.generate_assignment_code(code)

    def generate_function_definitions(self, env, code):
        for stat in self.stats:
            stat.generate_function_definitions(env, code)

    def annotate(self, code):
        for stat in self.stats:
            stat.annotate(code)


class InPlaceAssignmentNode(AssignmentNode):
    #  An in place arithmetic operand:
    #
    #    a += b
    #    a -= b
    #    ...
    #
    #  lhs      ExprNode      Left hand side
    #  rhs      ExprNode      Right hand side
    #  operator char          one of "+-*/%^&|"
    #
    #  This code is a bit tricky because in order to obey Python
    #  semantics the sub-expressions (e.g. indices) of the lhs must
    #  not be evaluated twice. So we must re-use the values calculated
    #  in evaluation phase for the assignment phase as well.
    #  Fortunately, the type of the lhs node is fairly constrained
    #  (it must be a NameNode, AttributeNode, or IndexNode).

    child_attrs = ["lhs", "rhs"]

    def analyse_declarations(self, env):
        self.lhs.analyse_target_declaration(env)

    def analyse_types(self, env):
        self.rhs = self.rhs.analyse_types(env)
        self.lhs = self.lhs.analyse_target_types(env)

        # When assigning to a fully indexed buffer or memoryview, coerce the rhs
        if (self.lhs.is_subscript and
                (self.lhs.memslice_index or self.lhs.is_buffer_access)):
            self.rhs = self.rhs.coerce_to(self.lhs.type, env)
        elif self.lhs.type.is_string and self.operator in '+-':
            # use pointer arithmetic for char* LHS instead of string concat
            self.rhs = self.rhs.coerce_to(PyrexTypes.c_py_ssize_t_type, env)
        return self

    def generate_execution_code(self, code):
        self.rhs.generate_evaluation_code(code)
        self.lhs.generate_subexpr_evaluation_code(code)
        c_op = self.operator
        if c_op == "//":
            c_op = "/"
        elif c_op == "**":
            error(self.pos, "No C inplace power operator")
        if self.lhs.is_subscript and self.lhs.is_buffer_access:
            if self.lhs.type.is_pyobject:
                error(self.pos, "In-place operators not allowed on object buffers in this release.")
            if (c_op in ('/', '%') and self.lhs.type.is_int
                and not code.globalstate.directives['cdivision']):
                error(self.pos, "In-place non-c divide operators not allowed on int buffers.")
            self.lhs.generate_buffer_setitem_code(self.rhs, code, c_op)
        else:
            # C++
            # TODO: make sure overload is declared
            code.putln("%s %s= %s;" % (self.lhs.result(), c_op, self.rhs.result()))
        self.lhs.generate_subexpr_disposal_code(code)
        self.lhs.free_subexpr_temps(code)
        self.rhs.generate_disposal_code(code)
        self.rhs.free_temps(code)

    def annotate(self, code):
        self.lhs.annotate(code)
        self.rhs.annotate(code)

    def create_binop_node(self):
        import ExprNodes
        return ExprNodes.binop_node(self.pos, self.operator, self.lhs, self.rhs)


class PrintStatNode(StatNode):
    #  print statement
    #
    #  arg_tuple         TupleNode
    #  stream            ExprNode or None (stdout)
    #  append_newline    boolean

    child_attrs = ["arg_tuple", "stream"]

    def analyse_expressions(self, env):
        if self.stream:
            stream = self.stream.analyse_expressions(env)
            self.stream = stream.coerce_to_pyobject(env)
        arg_tuple = self.arg_tuple.analyse_expressions(env)
        self.arg_tuple = arg_tuple.coerce_to_pyobject(env)
        env.use_utility_code(printing_utility_code)
        if len(self.arg_tuple.args) == 1 and self.append_newline:
            env.use_utility_code(printing_one_utility_code)
        return self

    nogil_check = Node.gil_error
    gil_message = "Python print statement"

    def generate_execution_code(self, code):
        if self.stream:
            self.stream.generate_evaluation_code(code)
            stream_result = self.stream.py_result()
        else:
            stream_result = '0'
        if len(self.arg_tuple.args) == 1 and self.append_newline:
            arg = self.arg_tuple.args[0]
            arg.generate_evaluation_code(code)

            code.putln(
                "if (__Pyx_PrintOne(%s, %s) < 0) %s" % (
                    stream_result,
                    arg.py_result(),
                    code.error_goto(self.pos)))
            arg.generate_disposal_code(code)
            arg.free_temps(code)
        else:
            self.arg_tuple.generate_evaluation_code(code)
            code.putln(
                "if (__Pyx_Print(%s, %s, %d) < 0) %s" % (
                    stream_result,
                    self.arg_tuple.py_result(),
                    self.append_newline,
                    code.error_goto(self.pos)))
            self.arg_tuple.generate_disposal_code(code)
            self.arg_tuple.free_temps(code)

        if self.stream:
            self.stream.generate_disposal_code(code)
            self.stream.free_temps(code)

    def generate_function_definitions(self, env, code):
        if self.stream:
            self.stream.generate_function_definitions(env, code)
        self.arg_tuple.generate_function_definitions(env, code)

    def annotate(self, code):
        if self.stream:
            self.stream.annotate(code)
        self.arg_tuple.annotate(code)


class ExecStatNode(StatNode):
    #  exec statement
    #
    #  args     [ExprNode]

    child_attrs = ["args"]

    def analyse_expressions(self, env):
        for i, arg in enumerate(self.args):
            arg = arg.analyse_expressions(env)
            arg = arg.coerce_to_pyobject(env)
            self.args[i] = arg
        env.use_utility_code(Builtin.pyexec_utility_code)
        return self

    nogil_check = Node.gil_error
    gil_message = "Python exec statement"

    def generate_execution_code(self, code):
        args = []
        for arg in self.args:
            arg.generate_evaluation_code(code)
            args.append( arg.py_result() )
        args = tuple(args + ['0', '0'][:3-len(args)])
        temp_result = code.funcstate.allocate_temp(PyrexTypes.py_object_type, manage_ref=True)
        code.putln("%s = __Pyx_PyExec3(%s, %s, %s);" % (
                (temp_result,) + args))
        for arg in self.args:
            arg.generate_disposal_code(code)
            arg.free_temps(code)
        code.putln(
            code.error_goto_if_null(temp_result, self.pos))
        code.put_gotref(temp_result)
        code.put_decref_clear(temp_result, py_object_type)
        code.funcstate.release_temp(temp_result)

    def annotate(self, code):
        for arg in self.args:
            arg.annotate(code)


class DelStatNode(StatNode):
    #  del statement
    #
    #  args     [ExprNode]

    child_attrs = ["args"]
    ignore_nonexisting = False

    def analyse_declarations(self, env):
        for arg in self.args:
            arg.analyse_target_declaration(env)

    def analyse_expressions(self, env):
        for i, arg in enumerate(self.args):
            arg = self.args[i] = arg.analyse_target_expression(env, None)
            if arg.type.is_pyobject or (arg.is_name and
                                        arg.type.is_memoryviewslice):
                if arg.is_name and arg.entry.is_cglobal:
                    error(arg.pos, "Deletion of global C variable")
            elif arg.type.is_ptr and arg.type.base_type.is_cpp_class:
                self.cpp_check(env)
            elif arg.type.is_cpp_class:
                error(arg.pos, "Deletion of non-heap C++ object")
            elif arg.is_subscript and arg.base.type is Builtin.bytearray_type:
                pass  # del ba[i]
            else:
                error(arg.pos, "Deletion of non-Python, non-C++ object")
            #arg.release_target_temp(env)
        return self

    def nogil_check(self, env):
        for arg in self.args:
            if arg.type.is_pyobject:
                self.gil_error()

    gil_message = "Deleting Python object"

    def generate_execution_code(self, code):
        for arg in self.args:
            if (arg.type.is_pyobject or
                    arg.type.is_memoryviewslice or
                    arg.is_subscript and arg.base.type is Builtin.bytearray_type):
                arg.generate_deletion_code(
                    code, ignore_nonexisting=self.ignore_nonexisting)
            elif arg.type.is_ptr and arg.type.base_type.is_cpp_class:
                arg.generate_result_code(code)
                code.putln("delete %s;" % arg.result())
            # else error reported earlier

    def annotate(self, code):
        for arg in self.args:
            arg.annotate(code)


class PassStatNode(StatNode):
    #  pass statement

    child_attrs = []

    def analyse_expressions(self, env):
        return self

    def generate_execution_code(self, code):
        pass


class IndirectionNode(StatListNode):
    """
    This adds an indirection so that the node can be shared and a subtree can
    be removed at any time by clearing self.stats.
    """

    def __init__(self, stats):
        super(IndirectionNode, self).__init__(stats[0].pos, stats=stats)

class BreakStatNode(StatNode):

    child_attrs = []
    is_terminator = True

    def analyse_expressions(self, env):
        return self

    def generate_execution_code(self, code):
        if not code.break_label:
            error(self.pos, "break statement not inside loop")
        else:
            code.put_goto(code.break_label)


class ContinueStatNode(StatNode):

    child_attrs = []
    is_terminator = True

    def analyse_expressions(self, env):
        return self

    def generate_execution_code(self, code):
        if code.funcstate.in_try_finally:
            error(self.pos, "continue statement inside try of try...finally")
        elif not code.continue_label:
            error(self.pos, "continue statement not inside loop")
        else:
            code.put_goto(code.continue_label)


class ReturnStatNode(StatNode):
    #  return statement
    #
    #  value         ExprNode or None
    #  return_type   PyrexType
    #  in_generator  return inside of generator => raise StopIteration

    child_attrs = ["value"]
    is_terminator = True
    in_generator = False

    # Whether we are in a parallel section
    in_parallel = False

    def analyse_expressions(self, env):
        return_type = env.return_type
        self.return_type = return_type
        if not return_type:
            error(self.pos, "Return not inside a function body")
            return self
        if self.value:
            self.value = self.value.analyse_types(env)
            if return_type.is_void or return_type.is_returncode:
                error(self.value.pos,
                    "Return with value in void function")
            else:
                self.value = self.value.coerce_to(env.return_type, env)
        else:
            if (not return_type.is_void
                and not return_type.is_pyobject
                and not return_type.is_returncode):
                    error(self.pos, "Return value required")
        return self

    def nogil_check(self, env):
        if self.return_type.is_pyobject:
            self.gil_error()

    gil_message = "Returning Python object"

    def generate_execution_code(self, code):
        code.mark_pos(self.pos)
        if not self.return_type:
            # error reported earlier
            return
        if self.return_type.is_pyobject:
            code.put_xdecref(Naming.retval_cname,
                             self.return_type)

        if self.value:
            self.value.generate_evaluation_code(code)
            if self.return_type.is_memoryviewslice:
                import MemoryView
                MemoryView.put_acquire_memoryviewslice(
                        lhs_cname=Naming.retval_cname,
                        lhs_type=self.return_type,
                        lhs_pos=self.value.pos,
                        rhs=self.value,
                        code=code,
                        have_gil=self.in_nogil_context)
            elif self.in_generator:
                # return value == raise StopIteration(value), but uncatchable
                code.putln(
                    "%s = NULL; PyErr_SetObject(PyExc_StopIteration, %s);" % (
                        Naming.retval_cname,
                        self.value.result_as(self.return_type)))
                self.value.generate_disposal_code(code)
            else:
                self.value.make_owned_reference(code)
                code.putln(
                    "%s = %s;" % (
                        Naming.retval_cname,
                        self.value.result_as(self.return_type)))
            self.value.generate_post_assignment_code(code)
            self.value.free_temps(code)
        else:
            if self.return_type.is_pyobject:
                code.put_init_to_py_none(Naming.retval_cname, self.return_type)
            elif self.return_type.is_returncode:
                self.put_return(code, self.return_type.default_value)

        for cname, type in code.funcstate.temps_holding_reference():
            code.put_decref_clear(cname, type)

        code.put_goto(code.return_label)

    def put_return(self, code, value):
        if self.in_parallel:
            code.putln_openmp("#pragma omp critical(__pyx_returning)")
        code.putln("%s = %s;" % (Naming.retval_cname, value))

    def generate_function_definitions(self, env, code):
        if self.value is not None:
            self.value.generate_function_definitions(env, code)

    def annotate(self, code):
        if self.value:
            self.value.annotate(code)


class RaiseStatNode(StatNode):
    #  raise statement
    #
    #  exc_type    ExprNode or None
    #  exc_value   ExprNode or None
    #  exc_tb      ExprNode or None
    #  cause       ExprNode or None

    child_attrs = ["exc_type", "exc_value", "exc_tb", "cause"]
    is_terminator = True

    def analyse_expressions(self, env):
        if self.exc_type:
            exc_type = self.exc_type.analyse_types(env)
            self.exc_type = exc_type.coerce_to_pyobject(env)
        if self.exc_value:
            exc_value = self.exc_value.analyse_types(env)
            self.exc_value = exc_value.coerce_to_pyobject(env)
        if self.exc_tb:
            exc_tb = self.exc_tb.analyse_types(env)
            self.exc_tb = exc_tb.coerce_to_pyobject(env)
        if self.cause:
            cause = self.cause.analyse_types(env)
            self.cause = cause.coerce_to_pyobject(env)
        # special cases for builtin exceptions
        self.builtin_exc_name = None
        if self.exc_type and not self.exc_value and not self.exc_tb:
            exc = self.exc_type
            import ExprNodes
            if (isinstance(exc, ExprNodes.SimpleCallNode) and
                not (exc.args or (exc.arg_tuple is not None and
                                  exc.arg_tuple.args))):
                exc = exc.function # extract the exception type
            if exc.is_name and exc.entry.is_builtin:
                self.builtin_exc_name = exc.name
                if self.builtin_exc_name == 'MemoryError':
                    self.exc_type = None # has a separate implementation
        return self

    nogil_check = Node.gil_error
    gil_message = "Raising exception"

    def generate_execution_code(self, code):
        if self.builtin_exc_name == 'MemoryError':
            code.putln('PyErr_NoMemory(); %s' % code.error_goto(self.pos))
            return

        if self.exc_type:
            self.exc_type.generate_evaluation_code(code)
            type_code = self.exc_type.py_result()
        else:
            type_code = "0"
        if self.exc_value:
            self.exc_value.generate_evaluation_code(code)
            value_code = self.exc_value.py_result()
        else:
            value_code = "0"
        if self.exc_tb:
            self.exc_tb.generate_evaluation_code(code)
            tb_code = self.exc_tb.py_result()
        else:
            tb_code = "0"
        if self.cause:
            self.cause.generate_evaluation_code(code)
            cause_code = self.cause.py_result()
        else:
            cause_code = "0"
        code.globalstate.use_utility_code(raise_utility_code)
        code.putln(
            "__Pyx_Raise(%s, %s, %s, %s);" % (
                type_code,
                value_code,
                tb_code,
                cause_code))
        for obj in (self.exc_type, self.exc_value, self.exc_tb, self.cause):
            if obj:
                obj.generate_disposal_code(code)
                obj.free_temps(code)
        code.putln(
            code.error_goto(self.pos))

    def generate_function_definitions(self, env, code):
        if self.exc_type is not None:
            self.exc_type.generate_function_definitions(env, code)
        if self.exc_value is not None:
            self.exc_value.generate_function_definitions(env, code)
        if self.exc_tb is not None:
            self.exc_tb.generate_function_definitions(env, code)
        if self.cause is not None:
            self.cause.generate_function_definitions(env, code)

    def annotate(self, code):
        if self.exc_type:
            self.exc_type.annotate(code)
        if self.exc_value:
            self.exc_value.annotate(code)
        if self.exc_tb:
            self.exc_tb.annotate(code)
        if self.cause:
            self.cause.annotate(code)


class ReraiseStatNode(StatNode):

    child_attrs = []
    is_terminator = True

    def analyse_expressions(self, env):
        return self

    nogil_check = Node.gil_error
    gil_message = "Raising exception"

    def generate_execution_code(self, code):
        vars = code.funcstate.exc_vars
        if vars:
            code.globalstate.use_utility_code(restore_exception_utility_code)
            code.put_giveref(vars[0])
            code.put_giveref(vars[1])
            # fresh exceptions may not have a traceback yet (-> finally!)
            code.put_xgiveref(vars[2])
            code.putln("__Pyx_ErrRestore(%s, %s, %s);" % tuple(vars))
            for varname in vars:
                code.put("%s = 0; " % varname)
            code.putln()
            code.putln(code.error_goto(self.pos))
        else:
            code.globalstate.use_utility_code(
                UtilityCode.load_cached("ReRaiseException", "Exceptions.c"))
            code.putln("__Pyx_ReraiseException(); %s" % code.error_goto(self.pos))

class AssertStatNode(StatNode):
    #  assert statement
    #
    #  cond    ExprNode
    #  value   ExprNode or None

    child_attrs = ["cond", "value"]

    def analyse_expressions(self, env):
        self.cond = self.cond.analyse_boolean_expression(env)
        if self.value:
            value = self.value.analyse_types(env)
            if value.type is Builtin.tuple_type or not value.type.is_builtin_type:
                # prevent tuple values from being interpreted as argument value tuples
                from ExprNodes import TupleNode
                value = TupleNode(value.pos, args=[value], slow=True)
                self.value = value.analyse_types(env, skip_children=True)
            else:
                self.value = value.coerce_to_pyobject(env)
        return self

    nogil_check = Node.gil_error
    gil_message = "Raising exception"

    def generate_execution_code(self, code):
        code.putln("#ifndef CYTHON_WITHOUT_ASSERTIONS")
        code.putln("if (unlikely(!Py_OptimizeFlag)) {")
        self.cond.generate_evaluation_code(code)
        code.putln(
            "if (unlikely(!%s)) {" %
                self.cond.result())
        if self.value:
            self.value.generate_evaluation_code(code)
            code.putln(
                "PyErr_SetObject(PyExc_AssertionError, %s);" %
                    self.value.py_result())
            self.value.generate_disposal_code(code)
            self.value.free_temps(code)
        else:
            code.putln(
                "PyErr_SetNone(PyExc_AssertionError);")
        code.putln(
                code.error_goto(self.pos))
        code.putln(
            "}")
        self.cond.generate_disposal_code(code)
        self.cond.free_temps(code)
        code.putln(
            "}")
        code.putln("#endif")

    def generate_function_definitions(self, env, code):
        self.cond.generate_function_definitions(env, code)
        if self.value is not None:
            self.value.generate_function_definitions(env, code)

    def annotate(self, code):
        self.cond.annotate(code)
        if self.value:
            self.value.annotate(code)


class IfStatNode(StatNode):
    #  if statement
    #
    #  if_clauses   [IfClauseNode]
    #  else_clause  StatNode or None

    child_attrs = ["if_clauses", "else_clause"]

    def analyse_declarations(self, env):
        for if_clause in self.if_clauses:
            if_clause.analyse_declarations(env)
        if self.else_clause:
            self.else_clause.analyse_declarations(env)

    def analyse_expressions(self, env):
        self.if_clauses = [ if_clause.analyse_expressions(env)
                            for if_clause in self.if_clauses ]
        if self.else_clause:
            self.else_clause = self.else_clause.analyse_expressions(env)
        return self

    def generate_execution_code(self, code):
        code.mark_pos(self.pos)
        end_label = code.new_label()
        for if_clause in self.if_clauses:
            if_clause.generate_execution_code(code, end_label)
        if self.else_clause:
            code.putln("/*else*/ {")
            self.else_clause.generate_execution_code(code)
            code.putln("}")
        code.put_label(end_label)

    def generate_function_definitions(self, env, code):
        for clause in self.if_clauses:
            clause.generate_function_definitions(env, code)
        if self.else_clause is not None:
            self.else_clause.generate_function_definitions(env, code)

    def annotate(self, code):
        for if_clause in self.if_clauses:
            if_clause.annotate(code)
        if self.else_clause:
            self.else_clause.annotate(code)


class IfClauseNode(Node):
    #  if or elif clause in an if statement
    #
    #  condition   ExprNode
    #  body        StatNode

    child_attrs = ["condition", "body"]

    def analyse_declarations(self, env):
        self.body.analyse_declarations(env)

    def analyse_expressions(self, env):
        self.condition = \
            self.condition.analyse_temp_boolean_expression(env)
        self.body = self.body.analyse_expressions(env)
        return self

    def generate_execution_code(self, code, end_label):
        self.condition.generate_evaluation_code(code)
        code.putln(
            "if (%s) {" %
                self.condition.result())
        self.condition.generate_disposal_code(code)
        self.condition.free_temps(code)
        self.body.generate_execution_code(code)
        if not self.body.is_terminator:
            code.put_goto(end_label)
        code.putln("}")

    def generate_function_definitions(self, env, code):
        self.condition.generate_function_definitions(env, code)
        self.body.generate_function_definitions(env, code)

    def annotate(self, code):
        self.condition.annotate(code)
        self.body.annotate(code)


class SwitchCaseNode(StatNode):
    # Generated in the optimization of an if-elif-else node
    #
    # conditions    [ExprNode]
    # body          StatNode

    child_attrs = ['conditions', 'body']

    def generate_execution_code(self, code):
        for cond in self.conditions:
            code.mark_pos(cond.pos)
            cond.generate_evaluation_code(code)
            code.putln("case %s:" % cond.result())
        self.body.generate_execution_code(code)
        code.putln("break;")

    def generate_function_definitions(self, env, code):
        for cond in self.conditions:
            cond.generate_function_definitions(env, code)
        self.body.generate_function_definitions(env, code)

    def annotate(self, code):
        for cond in self.conditions:
            cond.annotate(code)
        self.body.annotate(code)

class SwitchStatNode(StatNode):
    # Generated in the optimization of an if-elif-else node
    #
    # test          ExprNode
    # cases         [SwitchCaseNode]
    # else_clause   StatNode or None

    child_attrs = ['test', 'cases', 'else_clause']

    def generate_execution_code(self, code):
        self.test.generate_evaluation_code(code)
        code.putln("switch (%s) {" % self.test.result())
        for case in self.cases:
            case.generate_execution_code(code)
        if self.else_clause is not None:
            code.putln("default:")
            self.else_clause.generate_execution_code(code)
            code.putln("break;")
        else:
            # Always generate a default clause to prevent C compiler warnings
            # about unmatched enum values (it was not the user who decided to
            # generate the switch statement, so shouldn't be bothered).
            code.putln("default: break;")
        code.putln("}")

    def generate_function_definitions(self, env, code):
        self.test.generate_function_definitions(env, code)
        for case in self.cases:
            case.generate_function_definitions(env, code)
        if self.else_clause is not None:
            self.else_clause.generate_function_definitions(env, code)

    def annotate(self, code):
        self.test.annotate(code)
        for case in self.cases:
            case.annotate(code)
        if self.else_clause is not None:
            self.else_clause.annotate(code)

class LoopNode(object):
    pass


class WhileStatNode(LoopNode, StatNode):
    #  while statement
    #
    #  condition    ExprNode
    #  body         StatNode
    #  else_clause  StatNode

    child_attrs = ["condition", "body", "else_clause"]

    def analyse_declarations(self, env):
        self.body.analyse_declarations(env)
        if self.else_clause:
            self.else_clause.analyse_declarations(env)

    def analyse_expressions(self, env):
        if self.condition:
            self.condition = self.condition.analyse_temp_boolean_expression(env)
        self.body = self.body.analyse_expressions(env)
        if self.else_clause:
            self.else_clause = self.else_clause.analyse_expressions(env)
        return self

    def generate_execution_code(self, code):
        old_loop_labels = code.new_loop_labels()
        code.putln(
            "while (1) {")
        if self.condition:
            self.condition.generate_evaluation_code(code)
            self.condition.generate_disposal_code(code)
            code.putln(
                "if (!%s) break;" %
                    self.condition.result())
            self.condition.free_temps(code)
        self.body.generate_execution_code(code)
        code.put_label(code.continue_label)
        code.putln("}")
        break_label = code.break_label
        code.set_loop_labels(old_loop_labels)
        if self.else_clause:
            code.mark_pos(self.else_clause.pos)
            code.putln("/*else*/ {")
            self.else_clause.generate_execution_code(code)
            code.putln("}")
        code.put_label(break_label)

    def generate_function_definitions(self, env, code):
        if self.condition:
            self.condition.generate_function_definitions(env, code)
        self.body.generate_function_definitions(env, code)
        if self.else_clause is not None:
            self.else_clause.generate_function_definitions(env, code)

    def annotate(self, code):
        if self.condition:
            self.condition.annotate(code)
        self.body.annotate(code)
        if self.else_clause:
            self.else_clause.annotate(code)


class DictIterationNextNode(Node):
    # Helper node for calling PyDict_Next() inside of a WhileStatNode
    # and checking the dictionary size for changes.  Created in
    # Optimize.py.
    child_attrs = ['dict_obj', 'expected_size', 'pos_index_var',
                   'coerced_key_var', 'coerced_value_var', 'coerced_tuple_var',
                   'key_target', 'value_target', 'tuple_target', 'is_dict_flag']

    coerced_key_var = key_ref = None
    coerced_value_var = value_ref = None
    coerced_tuple_var = tuple_ref = None

    def __init__(self, dict_obj, expected_size, pos_index_var,
                 key_target, value_target, tuple_target, is_dict_flag):
        Node.__init__(
            self, dict_obj.pos,
            dict_obj = dict_obj,
            expected_size = expected_size,
            pos_index_var = pos_index_var,
            key_target = key_target,
            value_target = value_target,
            tuple_target = tuple_target,
            is_dict_flag = is_dict_flag,
            is_temp = True,
            type = PyrexTypes.c_bint_type)

    def analyse_expressions(self, env):
        import ExprNodes
        self.dict_obj = self.dict_obj.analyse_types(env)
        self.expected_size = self.expected_size.analyse_types(env)
        if self.pos_index_var:
            self.pos_index_var = self.pos_index_var.analyse_types(env)
        if self.key_target:
            self.key_target = self.key_target.analyse_target_types(env)
            self.key_ref = ExprNodes.TempNode(self.key_target.pos, PyrexTypes.py_object_type)
            self.coerced_key_var = self.key_ref.coerce_to(self.key_target.type, env)
        if self.value_target:
            self.value_target = self.value_target.analyse_target_types(env)
            self.value_ref = ExprNodes.TempNode(self.value_target.pos, type=PyrexTypes.py_object_type)
            self.coerced_value_var = self.value_ref.coerce_to(self.value_target.type, env)
        if self.tuple_target:
            self.tuple_target = self.tuple_target.analyse_target_types(env)
            self.tuple_ref = ExprNodes.TempNode(self.tuple_target.pos, PyrexTypes.py_object_type)
            self.coerced_tuple_var = self.tuple_ref.coerce_to(self.tuple_target.type, env)
        self.is_dict_flag = self.is_dict_flag.analyse_types(env)
        return self

    def generate_function_definitions(self, env, code):
        self.dict_obj.generate_function_definitions(env, code)

    def generate_execution_code(self, code):
        code.globalstate.use_utility_code(UtilityCode.load_cached("dict_iter", "Optimize.c"))
        self.dict_obj.generate_evaluation_code(code)

        assignments = []
        temp_addresses = []
        for var, result, target in [(self.key_ref, self.coerced_key_var, self.key_target),
                                    (self.value_ref, self.coerced_value_var, self.value_target),
                                    (self.tuple_ref, self.coerced_tuple_var, self.tuple_target)]:
            if target is None:
                addr = 'NULL'
            else:
                assignments.append((var, result, target))
                var.allocate(code)
                addr = '&%s' % var.result()
            temp_addresses.append(addr)

        result_temp = code.funcstate.allocate_temp(PyrexTypes.c_int_type, False)
        code.putln("%s = __Pyx_dict_iter_next(%s, %s, &%s, %s, %s, %s, %s);" % (
            result_temp,
            self.dict_obj.py_result(),
            self.expected_size.result(),
            self.pos_index_var.result(),
            temp_addresses[0],
            temp_addresses[1],
            temp_addresses[2],
            self.is_dict_flag.result()
        ))
        code.putln("if (unlikely(%s == 0)) break;" % result_temp)
        code.putln(code.error_goto_if("%s == -1" % result_temp, self.pos))
        code.funcstate.release_temp(result_temp)

        # evaluate all coercions before the assignments
        for var, result, target in assignments:
            code.put_gotref(var.result())
        for var, result, target in assignments:
            result.generate_evaluation_code(code)
        for var, result, target in assignments:
            target.generate_assignment_code(result, code)
            var.release(code)

def ForStatNode(pos, **kw):
    if 'iterator' in kw:
        return ForInStatNode(pos, **kw)
    else:
        return ForFromStatNode(pos, **kw)

class ForInStatNode(LoopNode, StatNode):
    #  for statement
    #
    #  target        ExprNode
    #  iterator      IteratorNode
    #  body          StatNode
    #  else_clause   StatNode
    #  item          NextNode       used internally

    child_attrs = ["target", "iterator", "body", "else_clause"]
    item = None

    def analyse_declarations(self, env):
        import ExprNodes
        self.target.analyse_target_declaration(env)
        self.body.analyse_declarations(env)
        if self.else_clause:
            self.else_clause.analyse_declarations(env)
        self.item = ExprNodes.NextNode(self.iterator)

    def analyse_expressions(self, env):
        self.target = self.target.analyse_target_types(env)
        self.iterator = self.iterator.analyse_expressions(env)
        import ExprNodes
        self.item = ExprNodes.NextNode(self.iterator)  # must rewrap after analysis
        self.item = self.item.analyse_expressions(env)
        if (self.iterator.type.is_ptr or self.iterator.type.is_array) and \
            self.target.type.assignable_from(self.iterator.type):
            # C array slice optimization.
            pass
        else:
            self.item = self.item.coerce_to(self.target.type, env)
        self.body = self.body.analyse_expressions(env)
        if self.else_clause:
            self.else_clause = self.else_clause.analyse_expressions(env)
        return self

    def generate_execution_code(self, code):
        old_loop_labels = code.new_loop_labels()
        self.iterator.generate_evaluation_code(code)
        code.putln("for (;;) {")
        self.item.generate_evaluation_code(code)
        self.target.generate_assignment_code(self.item, code)
        self.body.generate_execution_code(code)
        code.put_label(code.continue_label)
        code.putln("}")
        break_label = code.break_label
        code.set_loop_labels(old_loop_labels)

        if self.else_clause:
            # in nested loops, the 'else' block can contain a
            # 'continue' statement for the outer loop, but we may need
            # to generate cleanup code before taking that path, so we
            # intercept it here
            orig_continue_label = code.continue_label
            code.continue_label = code.new_label('outer_continue')

            code.putln("/*else*/ {")
            self.else_clause.generate_execution_code(code)
            code.putln("}")

            if code.label_used(code.continue_label):
                code.put_goto(break_label)
                code.put_label(code.continue_label)
                self.iterator.generate_disposal_code(code)
                code.put_goto(orig_continue_label)
            code.set_loop_labels(old_loop_labels)

        if code.label_used(break_label):
            code.put_label(break_label)
        self.iterator.generate_disposal_code(code)
        self.iterator.free_temps(code)

    def generate_function_definitions(self, env, code):
        self.target.generate_function_definitions(env, code)
        self.iterator.generate_function_definitions(env, code)
        self.body.generate_function_definitions(env, code)
        if self.else_clause is not None:
            self.else_clause.generate_function_definitions(env, code)

    def annotate(self, code):
        self.target.annotate(code)
        self.iterator.annotate(code)
        self.body.annotate(code)
        if self.else_clause:
            self.else_clause.annotate(code)
        self.item.annotate(code)


class ForFromStatNode(LoopNode, StatNode):
    #  for name from expr rel name rel expr
    #
    #  target        NameNode
    #  bound1        ExprNode
    #  relation1     string
    #  relation2     string
    #  bound2        ExprNode
    #  step          ExprNode or None
    #  body          StatNode
    #  else_clause   StatNode or None
    #
    #  Used internally:
    #
    #  from_range         bool
    #  is_py_target       bool
    #  loopvar_node       ExprNode (usually a NameNode or temp node)
    #  py_loopvar_node    PyTempNode or None
    child_attrs = ["target", "bound1", "bound2", "step", "body", "else_clause"]

    is_py_target = False
    loopvar_node = None
    py_loopvar_node = None
    from_range = False

    gil_message = "For-loop using object bounds or target"

    def nogil_check(self, env):
        for x in (self.target, self.bound1, self.bound2):
            if x.type.is_pyobject:
                self.gil_error()

    def analyse_declarations(self, env):
        self.target.analyse_target_declaration(env)
        self.body.analyse_declarations(env)
        if self.else_clause:
            self.else_clause.analyse_declarations(env)

    def analyse_expressions(self, env):
        import ExprNodes
        self.target = self.target.analyse_target_types(env)
        self.bound1 = self.bound1.analyse_types(env)
        self.bound2 = self.bound2.analyse_types(env)
        if self.step is not None:
            if isinstance(self.step, ExprNodes.UnaryMinusNode):
                warning(self.step.pos, "Probable infinite loop in for-from-by statement. Consider switching the directions of the relations.", 2)
            self.step = self.step.analyse_types(env)

        if self.target.type.is_numeric:
            loop_type = self.target.type
        else:
            loop_type = PyrexTypes.c_int_type
            if not self.bound1.type.is_pyobject:
                loop_type = PyrexTypes.widest_numeric_type(loop_type, self.bound1.type)
            if not self.bound2.type.is_pyobject:
                loop_type = PyrexTypes.widest_numeric_type(loop_type, self.bound2.type)
            if self.step is not None and not self.step.type.is_pyobject:
                loop_type = PyrexTypes.widest_numeric_type(loop_type, self.step.type)
        self.bound1 = self.bound1.coerce_to(loop_type, env)
        self.bound2 = self.bound2.coerce_to(loop_type, env)
        if not self.bound2.is_literal:
            self.bound2 = self.bound2.coerce_to_temp(env)
        if self.step is not None:
            self.step = self.step.coerce_to(loop_type, env)
            if not self.step.is_literal:
                self.step = self.step.coerce_to_temp(env)

        target_type = self.target.type
        if not (target_type.is_pyobject or target_type.is_numeric):
            error(self.target.pos,
                "for-from loop variable must be c numeric type or Python object")
        if target_type.is_numeric:
            self.is_py_target = False
            if isinstance(self.target, ExprNodes.IndexNode) and self.target.is_buffer_access:
                raise error(self.pos, "Buffer indexing not allowed as for loop target.")
            self.loopvar_node = self.target
            self.py_loopvar_node = None
        else:
            self.is_py_target = True
            c_loopvar_node = ExprNodes.TempNode(self.pos, loop_type, env)
            self.loopvar_node = c_loopvar_node
            self.py_loopvar_node = \
                ExprNodes.CloneNode(c_loopvar_node).coerce_to_pyobject(env)
        self.body = self.body.analyse_expressions(env)
        if self.else_clause:
            self.else_clause = self.else_clause.analyse_expressions(env)
        return self

    def generate_execution_code(self, code):
        old_loop_labels = code.new_loop_labels()
        from_range = self.from_range
        self.bound1.generate_evaluation_code(code)
        self.bound2.generate_evaluation_code(code)
        offset, incop = self.relation_table[self.relation1]
        if self.step is not None:
            self.step.generate_evaluation_code(code)
            step = self.step.result()
            incop = "%s=%s" % (incop[0], step)
        import ExprNodes
        if isinstance(self.loopvar_node, ExprNodes.TempNode):
            self.loopvar_node.allocate(code)
        if isinstance(self.py_loopvar_node, ExprNodes.TempNode):
            self.py_loopvar_node.allocate(code)
        if from_range:
            loopvar_name = code.funcstate.allocate_temp(self.target.type, False)
        else:
            loopvar_name = self.loopvar_node.result()
        code.putln(
            "for (%s = %s%s; %s %s %s; %s%s) {" % (
                loopvar_name,
                self.bound1.result(), offset,
                loopvar_name, self.relation2, self.bound2.result(),
                loopvar_name, incop))
        if self.py_loopvar_node:
            self.py_loopvar_node.generate_evaluation_code(code)
            self.target.generate_assignment_code(self.py_loopvar_node, code)
        elif from_range:
            code.putln("%s = %s;" % (
                            self.target.result(), loopvar_name))
        self.body.generate_execution_code(code)
        code.put_label(code.continue_label)
        if self.py_loopvar_node:
            # This mess is to make for..from loops with python targets behave
            # exactly like those with C targets with regards to re-assignment
            # of the loop variable.
            import ExprNodes
            if self.target.entry.is_pyglobal:
                # We know target is a NameNode, this is the only ugly case.
                target_node = ExprNodes.PyTempNode(self.target.pos, None)
                target_node.allocate(code)
                interned_cname = code.intern_identifier(self.target.entry.name)
                if self.target.entry.scope.is_module_scope:
                    code.globalstate.use_utility_code(
                        UtilityCode.load_cached("GetModuleGlobalName", "ObjectHandling.c"))
                    lookup_func = '__Pyx_GetModuleGlobalName(%s)'
                else:
                    code.globalstate.use_utility_code(
                        UtilityCode.load_cached("GetNameInClass", "ObjectHandling.c"))
                    lookup_func = '__Pyx_GetNameInClass(%s, %%s)' % (
                        self.target.entry.scope.namespace_cname)
                code.putln("%s = %s; %s" % (
                    target_node.result(),
                    lookup_func % interned_cname,
                    code.error_goto_if_null(target_node.result(), self.target.pos)))
                code.put_gotref(target_node.result())
            else:
                target_node = self.target
            from_py_node = ExprNodes.CoerceFromPyTypeNode(
                self.loopvar_node.type, target_node, self.target.entry.scope)
            from_py_node.temp_code = loopvar_name
            from_py_node.generate_result_code(code)
            if self.target.entry.is_pyglobal:
                code.put_decref(target_node.result(), target_node.type)
                target_node.release(code)
        code.putln("}")
        if self.py_loopvar_node:
            # This is potentially wasteful, but we don't want the semantics to
            # depend on whether or not the loop is a python type.
            self.py_loopvar_node.generate_evaluation_code(code)
            self.target.generate_assignment_code(self.py_loopvar_node, code)
        if from_range:
            code.funcstate.release_temp(loopvar_name)
        break_label = code.break_label
        code.set_loop_labels(old_loop_labels)
        if self.else_clause:
            code.putln("/*else*/ {")
            self.else_clause.generate_execution_code(code)
            code.putln("}")
        code.put_label(break_label)
        self.bound1.generate_disposal_code(code)
        self.bound1.free_temps(code)
        self.bound2.generate_disposal_code(code)
        self.bound2.free_temps(code)
        if isinstance(self.loopvar_node, ExprNodes.TempNode):
            self.loopvar_node.release(code)
        if isinstance(self.py_loopvar_node, ExprNodes.TempNode):
            self.py_loopvar_node.release(code)
        if self.step is not None:
            self.step.generate_disposal_code(code)
            self.step.free_temps(code)

    relation_table = {
        # {relop : (initial offset, increment op)}
        '<=': ("",   "++"),
        '<' : ("+1", "++"),
        '>=': ("",   "--"),
        '>' : ("-1", "--")
    }

    def generate_function_definitions(self, env, code):
        self.target.generate_function_definitions(env, code)
        self.bound1.generate_function_definitions(env, code)
        self.bound2.generate_function_definitions(env, code)
        if self.step is not None:
            self.step.generate_function_definitions(env, code)
        self.body.generate_function_definitions(env, code)
        if self.else_clause is not None:
            self.else_clause.generate_function_definitions(env, code)

    def annotate(self, code):
        self.target.annotate(code)
        self.bound1.annotate(code)
        self.bound2.annotate(code)
        if self.step:
            self.step.annotate(code)
        self.body.annotate(code)
        if self.else_clause:
            self.else_clause.annotate(code)


class WithStatNode(StatNode):
    """
    Represents a Python with statement.

    Implemented by the WithTransform as follows:

        MGR = EXPR
        EXIT = MGR.__exit__
        VALUE = MGR.__enter__()
        EXC = True
        try:
            try:
                TARGET = VALUE  # optional
                BODY
            except:
                EXC = False
                if not EXIT(*EXCINFO):
                    raise
        finally:
            if EXC:
                EXIT(None, None, None)
            MGR = EXIT = VALUE = None
    """
    #  manager          The with statement manager object
    #  target           ExprNode  the target lhs of the __enter__() call
    #  body             StatNode
    #  enter_call       ExprNode  the call to the __enter__() method
    #  exit_var         String    the cname of the __exit__() method reference

    child_attrs = ["manager", "enter_call", "target", "body"]

    enter_call = None

    def analyse_declarations(self, env):
        self.manager.analyse_declarations(env)
        self.enter_call.analyse_declarations(env)
        self.body.analyse_declarations(env)

    def analyse_expressions(self, env):
        self.manager = self.manager.analyse_types(env)
        self.enter_call = self.enter_call.analyse_types(env)
        self.body = self.body.analyse_expressions(env)
        return self

    def generate_function_definitions(self, env, code):
        self.manager.generate_function_definitions(env, code)
        self.enter_call.generate_function_definitions(env, code)
        self.body.generate_function_definitions(env, code)

    def generate_execution_code(self, code):
        code.putln("/*with:*/ {")
        self.manager.generate_evaluation_code(code)
        self.exit_var = code.funcstate.allocate_temp(py_object_type, manage_ref=False)
        code.globalstate.use_utility_code(
            UtilityCode.load_cached("PyObjectLookupSpecial", "ObjectHandling.c"))
        code.putln("%s = __Pyx_PyObject_LookupSpecial(%s, %s); %s" % (
            self.exit_var,
            self.manager.py_result(),
            code.intern_identifier(EncodedString('__exit__')),
            code.error_goto_if_null(self.exit_var, self.pos),
            ))
        code.put_gotref(self.exit_var)

        # need to free exit_var in the face of exceptions during setup
        old_error_label = code.new_error_label()
        intermediate_error_label = code.error_label

        self.enter_call.generate_evaluation_code(code)
        if not self.target:
            self.enter_call.generate_disposal_code(code)
            self.enter_call.free_temps(code)
        else:
            # Otherwise, the node will be cleaned up by the
            # WithTargetAssignmentStatNode after assigning its result
            # to the target of the 'with' statement.
            pass
        self.manager.generate_disposal_code(code)
        self.manager.free_temps(code)

        code.error_label = old_error_label
        self.body.generate_execution_code(code)

        if code.label_used(intermediate_error_label):
            step_over_label = code.new_label()
            code.put_goto(step_over_label)
            code.put_label(intermediate_error_label)
            code.put_decref_clear(self.exit_var, py_object_type)
            code.put_goto(old_error_label)
            code.put_label(step_over_label)

        code.funcstate.release_temp(self.exit_var)
        code.putln('}')

class WithTargetAssignmentStatNode(AssignmentNode):
    # The target assignment of the 'with' statement value (return
    # value of the __enter__() call).
    #
    # This is a special cased assignment that steals the RHS reference
    # and frees its temp.
    #
    # lhs       ExprNode   the assignment target
    # rhs       CloneNode  a (coerced) CloneNode for the orig_rhs (not owned by this node)
    # orig_rhs  ExprNode   the original ExprNode of the rhs. this node will clean up the
    #                      temps of the orig_rhs. basically, it takes ownership of the node
    #                      when the WithStatNode is done with it.

    child_attrs = ["lhs"]

    def analyse_declarations(self, env):
        self.lhs.analyse_target_declaration(env)

    def analyse_expressions(self, env):
        self.rhs = self.rhs.analyse_types(env)
        self.lhs = self.lhs.analyse_target_types(env)
        self.lhs.gil_assignment_check(env)
        self.rhs = self.rhs.coerce_to(self.lhs.type, env)
        return self

    def generate_execution_code(self, code):
        if self.orig_rhs.type.is_pyobject:
            # make sure rhs gets freed on errors, see below
            old_error_label = code.new_error_label()
            intermediate_error_label = code.error_label

        self.rhs.generate_evaluation_code(code)
        self.lhs.generate_assignment_code(self.rhs, code)

        if self.orig_rhs.type.is_pyobject:
            self.orig_rhs.generate_disposal_code(code)
            code.error_label = old_error_label
            if code.label_used(intermediate_error_label):
                step_over_label = code.new_label()
                code.put_goto(step_over_label)
                code.put_label(intermediate_error_label)
                self.orig_rhs.generate_disposal_code(code)
                code.put_goto(old_error_label)
                code.put_label(step_over_label)

        self.orig_rhs.free_temps(code)

    def annotate(self, code):
        self.lhs.annotate(code)
        self.rhs.annotate(code)


class TryExceptStatNode(StatNode):
    #  try .. except statement
    #
    #  body             StatNode
    #  except_clauses   [ExceptClauseNode]
    #  else_clause      StatNode or None

    child_attrs = ["body", "except_clauses", "else_clause"]

    def analyse_declarations(self, env):
        self.body.analyse_declarations(env)
        for except_clause in self.except_clauses:
            except_clause.analyse_declarations(env)
        if self.else_clause:
            self.else_clause.analyse_declarations(env)

    def analyse_expressions(self, env):
        self.body = self.body.analyse_expressions(env)
        default_clause_seen = 0
        for i, except_clause in enumerate(self.except_clauses):
            except_clause = self.except_clauses[i] = except_clause.analyse_expressions(env)
            if default_clause_seen:
                error(except_clause.pos, "default 'except:' must be last")
            if not except_clause.pattern:
                default_clause_seen = 1
        self.has_default_clause = default_clause_seen
        if self.else_clause:
            self.else_clause = self.else_clause.analyse_expressions(env)
        return self

    nogil_check = Node.gil_error
    gil_message = "Try-except statement"

    def generate_execution_code(self, code):
        old_return_label = code.return_label
        old_break_label = code.break_label
        old_continue_label = code.continue_label
        old_error_label = code.new_error_label()
        our_error_label = code.error_label
        except_end_label = code.new_label('exception_handled')
        except_error_label = code.new_label('except_error')
        except_return_label = code.new_label('except_return')
        try_return_label = code.new_label('try_return')
        try_break_label = code.new_label('try_break')
        try_continue_label = code.new_label('try_continue')
        try_end_label = code.new_label('try_end')

        exc_save_vars = [code.funcstate.allocate_temp(py_object_type, False)
                         for _ in xrange(3)]
        code.putln("{")
        save_exc = code.insertion_point()
        code.putln(
            "/*try:*/ {")
        code.return_label = try_return_label
        code.break_label = try_break_label
        code.continue_label = try_continue_label
        self.body.generate_execution_code(code)
        code.putln(
            "}")
        temps_to_clean_up = code.funcstate.all_free_managed_temps()
        can_raise = code.label_used(our_error_label)

        if can_raise:
            # inject code before the try block to save away the exception state
            code.globalstate.use_utility_code(reset_exception_utility_code)
            save_exc.putln("__Pyx_ExceptionSave(%s);" %
                           ', '.join(['&%s' % var for var in exc_save_vars]))
            for var in exc_save_vars:
                save_exc.put_xgotref(var)

            def restore_saved_exception():
                for name in exc_save_vars:
                    code.put_xgiveref(name)
                code.putln("__Pyx_ExceptionReset(%s);" %
                           ', '.join(exc_save_vars))
        else:
            # try block cannot raise exceptions, but we had to allocate the temps above,
            # so just keep the C compiler from complaining about them being unused
            save_exc.putln("if (%s); else {/*mark used*/};" % '||'.join(exc_save_vars))

            def restore_saved_exception():
                pass

        code.error_label = except_error_label
        code.return_label = except_return_label
        if self.else_clause:
            code.putln(
                "/*else:*/ {")
            self.else_clause.generate_execution_code(code)
            code.putln(
                "}")

        if can_raise:
            for var in exc_save_vars:
                code.put_xdecref_clear(var, py_object_type)
            code.put_goto(try_end_label)
            code.put_label(our_error_label)
            for temp_name, temp_type in temps_to_clean_up:
                code.put_xdecref_clear(temp_name, temp_type)
            for except_clause in self.except_clauses:
                except_clause.generate_handling_code(code, except_end_label)
            if not self.has_default_clause:
                code.put_goto(except_error_label)

        for exit_label, old_label in [(except_error_label, old_error_label),
                                      (try_break_label, old_break_label),
                                      (try_continue_label, old_continue_label),
                                      (try_return_label, old_return_label),
                                      (except_return_label, old_return_label)]:
            if code.label_used(exit_label):
                if not code.label_used(try_end_label):
                    code.put_goto(try_end_label)
                code.put_label(exit_label)
                restore_saved_exception()
                code.put_goto(old_label)

        if code.label_used(except_end_label):
            if not code.label_used(try_end_label):
                code.put_goto(try_end_label)
            code.put_label(except_end_label)
            restore_saved_exception()
        if code.label_used(try_end_label):
            code.put_label(try_end_label)
        code.putln("}")

        for cname in exc_save_vars:
            code.funcstate.release_temp(cname)

        code.return_label = old_return_label
        code.break_label = old_break_label
        code.continue_label = old_continue_label
        code.error_label = old_error_label

    def generate_function_definitions(self, env, code):
        self.body.generate_function_definitions(env, code)
        for except_clause in self.except_clauses:
            except_clause.generate_function_definitions(env, code)
        if self.else_clause is not None:
            self.else_clause.generate_function_definitions(env, code)

    def annotate(self, code):
        self.body.annotate(code)
        for except_node in self.except_clauses:
            except_node.annotate(code)
        if self.else_clause:
            self.else_clause.annotate(code)


class ExceptClauseNode(Node):
    #  Part of try ... except statement.
    #
    #  pattern        [ExprNode]
    #  target         ExprNode or None
    #  body           StatNode
    #  excinfo_target TupleNode(3*ResultRefNode) or None   optional target for exception info (not owned here!)
    #  match_flag     string             result of exception match
    #  exc_value      ExcValueNode       used internally
    #  function_name  string             qualified name of enclosing function
    #  exc_vars       (string * 3)       local exception variables
    #  is_except_as   bool               Py3-style "except ... as xyz"

    # excinfo_target is never set by the parser, but can be set by a transform
    # in order to extract more extensive information about the exception as a
    # sys.exc_info()-style tuple into a target variable

    child_attrs = ["pattern", "target", "body", "exc_value"]

    exc_value = None
    excinfo_target = None
    is_except_as = False

    def analyse_declarations(self, env):
        if self.target:
            self.target.analyse_target_declaration(env)
        self.body.analyse_declarations(env)

    def analyse_expressions(self, env):
        self.function_name = env.qualified_name
        if self.pattern:
            # normalise/unpack self.pattern into a list
            for i, pattern in enumerate(self.pattern):
                pattern = pattern.analyse_expressions(env)
                self.pattern[i] = pattern.coerce_to_pyobject(env)

        if self.target:
            import ExprNodes
            self.exc_value = ExprNodes.ExcValueNode(self.pos)
            self.target = self.target.analyse_target_expression(env, self.exc_value)

        self.body = self.body.analyse_expressions(env)
        return self

    def generate_handling_code(self, code, end_label):
        code.mark_pos(self.pos)
        if self.pattern:
            exc_tests = []
            for pattern in self.pattern:
                pattern.generate_evaluation_code(code)
                exc_tests.append("PyErr_ExceptionMatches(%s)" % pattern.py_result())

            match_flag = code.funcstate.allocate_temp(PyrexTypes.c_int_type, False)
            code.putln(
                "%s = %s;" % (match_flag, ' || '.join(exc_tests)))
            for pattern in self.pattern:
                pattern.generate_disposal_code(code)
                pattern.free_temps(code)
            code.putln(
                "if (%s) {" %
                    match_flag)
            code.funcstate.release_temp(match_flag)
        else:
            code.putln("/*except:*/ {")

        if (not getattr(self.body, 'stats', True)
                and self.excinfo_target is None
                and self.target is None):
            # most simple case: no exception variable, empty body (pass)
            # => reset the exception state, done
            code.putln("PyErr_Restore(0,0,0);")
            code.put_goto(end_label)
            code.putln("}")
            return

        exc_vars = [code.funcstate.allocate_temp(py_object_type,
                                                 manage_ref=True)
                    for _ in xrange(3)]
        code.put_add_traceback(self.function_name)
        # We always have to fetch the exception value even if
        # there is no target, because this also normalises the
        # exception and stores it in the thread state.
        code.globalstate.use_utility_code(get_exception_utility_code)
        exc_args = "&%s, &%s, &%s" % tuple(exc_vars)
        code.putln("if (__Pyx_GetException(%s) < 0) %s" % (exc_args,
            code.error_goto(self.pos)))
        for x in exc_vars:
            code.put_gotref(x)
        if self.target:
            self.exc_value.set_var(exc_vars[1])
            self.exc_value.generate_evaluation_code(code)
            self.target.generate_assignment_code(self.exc_value, code)
        if self.excinfo_target is not None:
            for tempvar, node in zip(exc_vars, self.excinfo_target.args):
                node.set_var(tempvar)

        old_break_label, old_continue_label = code.break_label, code.continue_label
        code.break_label = code.new_label('except_break')
        code.continue_label = code.new_label('except_continue')

        old_exc_vars = code.funcstate.exc_vars
        code.funcstate.exc_vars = exc_vars
        self.body.generate_execution_code(code)
        code.funcstate.exc_vars = old_exc_vars
        for var in exc_vars:
            code.put_decref_clear(var, py_object_type)
        code.put_goto(end_label)

        for new_label, old_label in [(code.break_label, old_break_label),
                                     (code.continue_label, old_continue_label)]:
            if code.label_used(new_label):
                code.put_label(new_label)
                for var in exc_vars:
                    code.put_decref_clear(var, py_object_type)
                code.put_goto(old_label)
        code.break_label = old_break_label
        code.continue_label = old_continue_label

        for temp in exc_vars:
            code.funcstate.release_temp(temp)

        code.putln(
            "}")

    def generate_function_definitions(self, env, code):
        if self.target is not None:
            self.target.generate_function_definitions(env, code)
        self.body.generate_function_definitions(env, code)

    def annotate(self, code):
        if self.pattern:
            for pattern in self.pattern:
                pattern.annotate(code)
        if self.target:
            self.target.annotate(code)
        self.body.annotate(code)


class TryFinallyStatNode(StatNode):
    #  try ... finally statement
    #
    #  body             StatNode
    #  finally_clause   StatNode
    #
    #  The plan is that we funnel all continue, break
    #  return and error gotos into the beginning of the
    #  finally block, setting a variable to remember which
    #  one we're doing. At the end of the finally block, we
    #  switch on the variable to figure out where to go.
    #  In addition, if we're doing an error, we save the
    #  exception on entry to the finally block and restore
    #  it on exit.

    child_attrs = ["body", "finally_clause"]

    preserve_exception = 1

    # handle exception case, in addition to return/break/continue
    handle_error_case = True
    func_return_type = None

    disallow_continue_in_try_finally = 0
    # There doesn't seem to be any point in disallowing
    # continue in the try block, since we have no problem
    # handling it.

    is_try_finally_in_nogil = False

    def create_analysed(pos, env, body, finally_clause):
        node = TryFinallyStatNode(pos, body=body, finally_clause=finally_clause)
        return node
    create_analysed = staticmethod(create_analysed)

    def analyse_declarations(self, env):
        self.body.analyse_declarations(env)
        self.finally_clause.analyse_declarations(env)

    def analyse_expressions(self, env):
        self.body = self.body.analyse_expressions(env)
        self.finally_clause = self.finally_clause.analyse_expressions(env)
        if env.return_type and not env.return_type.is_void:
            self.func_return_type = env.return_type
        return self

    nogil_check = Node.gil_error
    gil_message = "Try-finally statement"

    def generate_execution_code(self, code):
        old_error_label = code.error_label
        old_labels = code.all_new_labels()
        new_labels = code.get_all_labels()
        new_error_label = code.error_label
        if not self.handle_error_case:
            code.error_label = old_error_label
        catch_label = code.new_label()

        code.putln("/*try:*/ {")

        if self.disallow_continue_in_try_finally:
            was_in_try_finally = code.funcstate.in_try_finally
            code.funcstate.in_try_finally = 1

        self.body.generate_execution_code(code)

        if self.disallow_continue_in_try_finally:
            code.funcstate.in_try_finally = was_in_try_finally

        code.putln("}")
        code.set_all_labels(old_labels)

        temps_to_clean_up = code.funcstate.all_free_managed_temps()
        code.mark_pos(self.finally_clause.pos)
        code.putln("/*finally:*/ {")

        def fresh_finally_clause(_next=[self.finally_clause]):
            # generate the original subtree once and always keep a fresh copy
            node = _next[0]
            node_copy = copy.deepcopy(node)
            if node is self.finally_clause:
                _next[0] = node_copy
            else:
                node = node_copy
            return node

        preserve_error = self.preserve_exception and code.label_used(new_error_label)
        needs_success_cleanup = not self.finally_clause.is_terminator

        if not self.body.is_terminator:
            code.putln('/*normal exit:*/{')
            fresh_finally_clause().generate_execution_code(code)
            if not self.finally_clause.is_terminator:
                code.put_goto(catch_label)
            code.putln('}')

        if preserve_error:
            code.putln('/*exception exit:*/{')
            if self.is_try_finally_in_nogil:
                code.declare_gilstate()
            if needs_success_cleanup:
                exc_lineno_cnames = tuple([
                    code.funcstate.allocate_temp(PyrexTypes.c_int_type, manage_ref=False)
                    for _ in range(2)])
                exc_filename_cname = code.funcstate.allocate_temp(
                    PyrexTypes.CPtrType(PyrexTypes.c_const_type(PyrexTypes.c_char_type)),
                    manage_ref=False)
            else:
                exc_lineno_cnames = exc_filename_cname = None
            exc_vars = tuple([
                code.funcstate.allocate_temp(py_object_type, manage_ref=False)
                for _ in range(6)])
            code.put_label(new_error_label)
            self.put_error_catcher(
                code, temps_to_clean_up, exc_vars, exc_lineno_cnames, exc_filename_cname)
            finally_old_labels = code.all_new_labels()

            code.putln('{')
            old_exc_vars = code.funcstate.exc_vars
            code.funcstate.exc_vars = exc_vars[:3]
            fresh_finally_clause().generate_execution_code(code)
            code.funcstate.exc_vars = old_exc_vars
            code.putln('}')

            if needs_success_cleanup:
                self.put_error_uncatcher(code, exc_vars, exc_lineno_cnames, exc_filename_cname)
                if exc_lineno_cnames:
                    for cname in exc_lineno_cnames:
                        code.funcstate.release_temp(cname)
                if exc_filename_cname:
                    code.funcstate.release_temp(exc_filename_cname)
                code.put_goto(old_error_label)

            for new_label, old_label in zip(code.get_all_labels(), finally_old_labels):
                if not code.label_used(new_label):
                    continue
                code.put_label(new_label)
                self.put_error_cleaner(code, exc_vars)
                code.put_goto(old_label)

            for cname in exc_vars:
                code.funcstate.release_temp(cname)
            code.putln('}')

        code.set_all_labels(old_labels)
        return_label = code.return_label
        for i, (new_label, old_label) in enumerate(zip(new_labels, old_labels)):
            if not code.label_used(new_label):
                continue
            if new_label == new_error_label and preserve_error:
                continue  # handled above

            code.put('%s: ' % new_label)
            code.putln('{')
            ret_temp = None
            if old_label == return_label and not self.finally_clause.is_terminator:
                # store away return value for later reuse
                if (self.func_return_type and
                        not self.is_try_finally_in_nogil and
                        not isinstance(self.finally_clause, GILExitNode)):
                    ret_temp = code.funcstate.allocate_temp(
                        self.func_return_type, manage_ref=False)
                    code.putln("%s = %s;" % (ret_temp, Naming.retval_cname))
                    if self.func_return_type.is_pyobject:
                        code.putln("%s = 0;" % Naming.retval_cname)
            fresh_finally_clause().generate_execution_code(code)
            if ret_temp:
                code.putln("%s = %s;" % (Naming.retval_cname, ret_temp))
                if self.func_return_type.is_pyobject:
                    code.putln("%s = 0;" % ret_temp)
                code.funcstate.release_temp(ret_temp)
                ret_temp = None
            if not self.finally_clause.is_terminator:
                code.put_goto(old_label)
            code.putln('}')

        # End finally
        code.put_label(catch_label)
        code.putln(
            "}")

    def generate_function_definitions(self, env, code):
        self.body.generate_function_definitions(env, code)
        self.finally_clause.generate_function_definitions(env, code)

    def put_error_catcher(self, code, temps_to_clean_up, exc_vars,
                          exc_lineno_cnames, exc_filename_cname):
        code.globalstate.use_utility_code(restore_exception_utility_code)
        code.globalstate.use_utility_code(get_exception_utility_code)
        code.globalstate.use_utility_code(swap_exception_utility_code)

        code.putln(' '.join(["%s = 0;"]*len(exc_vars)) % exc_vars)
        if self.is_try_finally_in_nogil:
            code.put_ensure_gil(declare_gilstate=False)

        for temp_name, type in temps_to_clean_up:
            code.put_xdecref_clear(temp_name, type)

        # not using preprocessor here to avoid warnings about
        # unused utility functions and/or temps
        code.putln("if (PY_MAJOR_VERSION >= 3)"
                   " __Pyx_ExceptionSwap(&%s, &%s, &%s);" % exc_vars[3:])
        code.putln("if ((PY_MAJOR_VERSION < 3) ||"
                   # if __Pyx_GetException() fails in Py3,
                   # store the newly raised exception instead
                   " unlikely(__Pyx_GetException(&%s, &%s, &%s) < 0)) "
                   "__Pyx_ErrFetch(&%s, &%s, &%s);" % (exc_vars[:3] * 2))
        for var in exc_vars:
            code.put_xgotref(var)
        if exc_lineno_cnames:
            code.putln("%s = %s; %s = %s; %s = %s;" % (
                exc_lineno_cnames[0], Naming.lineno_cname,
                exc_lineno_cnames[1], Naming.clineno_cname,
                exc_filename_cname, Naming.filename_cname))

        if self.is_try_finally_in_nogil:
            code.put_release_ensured_gil()

    def put_error_uncatcher(self, code, exc_vars, exc_lineno_cnames, exc_filename_cname):
        code.globalstate.use_utility_code(restore_exception_utility_code)
        code.globalstate.use_utility_code(reset_exception_utility_code)

        if self.is_try_finally_in_nogil:
            code.put_ensure_gil(declare_gilstate=False)

        # not using preprocessor here to avoid warnings about
        # unused utility functions and/or temps
        code.putln("if (PY_MAJOR_VERSION >= 3) {")
        for var in exc_vars[3:]:
            code.put_xgiveref(var)
        code.putln("__Pyx_ExceptionReset(%s, %s, %s);" % exc_vars[3:])
        code.putln("}")
        for var in exc_vars[:3]:
            code.put_xgiveref(var)
        code.putln("__Pyx_ErrRestore(%s, %s, %s);" % exc_vars[:3])

        if self.is_try_finally_in_nogil:
            code.put_release_ensured_gil()

        code.putln(' '.join(["%s = 0;"]*len(exc_vars)) % exc_vars)
        if exc_lineno_cnames:
            code.putln("%s = %s; %s = %s; %s = %s;" % (
                Naming.lineno_cname, exc_lineno_cnames[0],
                Naming.clineno_cname, exc_lineno_cnames[1],
                Naming.filename_cname, exc_filename_cname))

    def put_error_cleaner(self, code, exc_vars):
        code.globalstate.use_utility_code(reset_exception_utility_code)
        if self.is_try_finally_in_nogil:
            code.put_ensure_gil(declare_gilstate=False)
        # not using preprocessor here to avoid warnings about
        # unused utility functions and/or temps
        code.putln("if (PY_MAJOR_VERSION >= 3) {")
        for var in exc_vars[3:]:
            code.put_xgiveref(var)
        code.putln("__Pyx_ExceptionReset(%s, %s, %s);" % exc_vars[3:])
        code.putln("}")
        for var in exc_vars[:3]:
            code.put_xdecref_clear(var, py_object_type)
        if self.is_try_finally_in_nogil:
            code.put_release_ensured_gil()
        code.putln(' '.join(["%s = 0;"]*3) % exc_vars[3:])

    def annotate(self, code):
        self.body.annotate(code)
        self.finally_clause.annotate(code)


class NogilTryFinallyStatNode(TryFinallyStatNode):
    """
    A try/finally statement that may be used in nogil code sections.
    """

    preserve_exception = False
    nogil_check = None


class GILStatNode(NogilTryFinallyStatNode):
    #  'with gil' or 'with nogil' statement
    #
    #   state   string   'gil' or 'nogil'

    state_temp = None

    def __init__(self, pos, state, body):
        self.state = state
        self.create_state_temp_if_needed(pos, state, body)
        TryFinallyStatNode.__init__(self, pos,
            body=body,
            finally_clause=GILExitNode(
                pos, state=state, state_temp=self.state_temp))

    def create_state_temp_if_needed(self, pos, state, body):
        from ParseTreeTransforms import YieldNodeCollector
        collector = YieldNodeCollector()
        collector.visitchildren(body)
        if not collector.yields:
            return

        if state == 'gil':
            temp_type = PyrexTypes.c_gilstate_type
        else:
            temp_type = PyrexTypes.c_threadstate_ptr_type
        import ExprNodes
        self.state_temp = ExprNodes.TempNode(pos, temp_type)

    def analyse_declarations(self, env):
        env._in_with_gil_block = (self.state == 'gil')
        if self.state == 'gil':
            env.has_with_gil_block = True

        return super(GILStatNode, self).analyse_declarations(env)

    def analyse_expressions(self, env):
        env.use_utility_code(
            UtilityCode.load_cached("ForceInitThreads", "ModuleSetupCode.c"))
        was_nogil = env.nogil
        env.nogil = self.state == 'nogil'
        node = TryFinallyStatNode.analyse_expressions(self, env)
        env.nogil = was_nogil
        return node

    def generate_execution_code(self, code):
        code.mark_pos(self.pos)
        code.begin_block()
        if self.state_temp:
            self.state_temp.allocate(code)
            variable = self.state_temp.result()
        else:
            variable = None

        old_trace_config = code.funcstate.can_trace
        if self.state == 'gil':
            code.put_ensure_gil(variable=variable)
            # FIXME: not that easy, tracing may not be possible at all here
            #code.funcstate.can_trace = True
        else:
            code.put_release_gil(variable=variable)
            code.funcstate.can_trace = False

        TryFinallyStatNode.generate_execution_code(self, code)

        if self.state_temp:
            self.state_temp.release(code)

        code.funcstate.can_trace = old_trace_config
        code.end_block()


class GILExitNode(StatNode):
    """
    Used as the 'finally' block in a GILStatNode

    state   string   'gil' or 'nogil'
    """

    child_attrs = []
    state_temp = None

    def analyse_expressions(self, env):
        return self

    def generate_execution_code(self, code):
        if self.state_temp:
            variable = self.state_temp.result()
        else:
            variable = None

        if self.state == 'gil':
            code.put_release_ensured_gil(variable)
        else:
            code.put_acquire_gil(variable)


class EnsureGILNode(GILExitNode):
    """
    Ensure the GIL in nogil functions for cleanup before returning.
    """

    def generate_execution_code(self, code):
        code.put_ensure_gil(declare_gilstate=False)

utility_code_for_cimports = {
    # utility code (or inlining c) in a pxd (or pyx) file.
    # TODO: Consider a generic user-level mechanism for importing
    'cpython.array'         : ("ArrayAPI", "arrayarray.h"),
    'cpython.array.array'   : ("ArrayAPI", "arrayarray.h"),
}

class CImportStatNode(StatNode):
    #  cimport statement
    #
    #  module_name   string           Qualified name of module being imported
    #  as_name       string or None   Name specified in "as" clause, if any

    child_attrs = []

    def analyse_declarations(self, env):
        if not env.is_module_scope:
            error(self.pos, "cimport only allowed at module level")
            return
        module_scope = env.find_module(self.module_name, self.pos)
        if "." in self.module_name:
            names = [EncodedString(name) for name in self.module_name.split(".")]
            top_name = names[0]
            top_module_scope = env.context.find_submodule(top_name)
            module_scope = top_module_scope
            for name in names[1:]:
                submodule_scope = module_scope.find_submodule(name)
                module_scope.declare_module(name, submodule_scope, self.pos)
                module_scope = submodule_scope
            if self.as_name:
                env.declare_module(self.as_name, module_scope, self.pos)
            else:
                env.add_imported_module(module_scope)
                env.declare_module(top_name, top_module_scope, self.pos)
        else:
            name = self.as_name or self.module_name
            env.declare_module(name, module_scope, self.pos)
        if self.module_name in utility_code_for_cimports:
            env.use_utility_code(UtilityCode.load_cached(
                *utility_code_for_cimports[self.module_name]))

    def analyse_expressions(self, env):
        return self

    def generate_execution_code(self, code):
        pass


class FromCImportStatNode(StatNode):
    #  from ... cimport statement
    #
    #  module_name     string                        Qualified name of module
    #  imported_names  [(pos, name, as_name, kind)]  Names to be imported

    child_attrs = []

    def analyse_declarations(self, env):
        if not env.is_module_scope:
            error(self.pos, "cimport only allowed at module level")
            return
        module_scope = env.find_module(self.module_name, self.pos)
        env.add_imported_module(module_scope)
        for pos, name, as_name, kind in self.imported_names:
            if name == "*":
                for local_name, entry in module_scope.entries.items():
                    env.add_imported_entry(local_name, entry, pos)
            else:
                entry = module_scope.lookup(name)
                if entry:
                    if kind and not self.declaration_matches(entry, kind):
                        entry.redeclared(pos)
                    entry.used = 1
                else:
                    if kind == 'struct' or kind == 'union':
                        entry = module_scope.declare_struct_or_union(name,
                            kind = kind, scope = None, typedef_flag = 0, pos = pos)
                    elif kind == 'class':
                        entry = module_scope.declare_c_class(name, pos = pos,
                            module_name = self.module_name)
                    else:
                        submodule_scope = env.context.find_module(name, relative_to = module_scope, pos = self.pos)
                        if submodule_scope.parent_module is module_scope:
                            env.declare_module(as_name or name, submodule_scope, self.pos)
                        else:
                            error(pos, "Name '%s' not declared in module '%s'"
                                % (name, self.module_name))

                if entry:
                    local_name = as_name or name
                    env.add_imported_entry(local_name, entry, pos)

        if self.module_name.startswith('cpython'): # enough for now
            if self.module_name in utility_code_for_cimports:
                env.use_utility_code(UtilityCode.load_cached(
                    *utility_code_for_cimports[self.module_name]))
            for _, name, _, _ in self.imported_names:
                fqname = '%s.%s' % (self.module_name, name)
                if fqname in utility_code_for_cimports:
                    env.use_utility_code(UtilityCode.load_cached(
                        *utility_code_for_cimports[fqname]))

    def declaration_matches(self, entry, kind):
        if not entry.is_type:
            return 0
        type = entry.type
        if kind == 'class':
            if not type.is_extension_type:
                return 0
        else:
            if not type.is_struct_or_union:
                return 0
            if kind != type.kind:
                return 0
        return 1

    def analyse_expressions(self, env):
        return self

    def generate_execution_code(self, code):
        pass


class FromImportStatNode(StatNode):
    #  from ... import statement
    #
    #  module           ImportNode
    #  items            [(string, NameNode)]
    #  interned_items   [(string, NameNode, ExprNode)]
    #  item             PyTempNode            used internally
    #  import_star      boolean               used internally

    child_attrs = ["module"]
    import_star = 0

    def analyse_declarations(self, env):
        for name, target in self.items:
            if name == "*":
                if not env.is_module_scope:
                    error(self.pos, "import * only allowed at module level")
                    return
                env.has_import_star = 1
                self.import_star = 1
            else:
                target.analyse_target_declaration(env)

    def analyse_expressions(self, env):
        import ExprNodes
        self.module = self.module.analyse_expressions(env)
        self.item = ExprNodes.RawCNameExprNode(self.pos, py_object_type)
        self.interned_items = []
        for name, target in self.items:
            if name == '*':
                for _, entry in env.entries.items():
                    if not entry.is_type and entry.type.is_extension_type:
                        env.use_utility_code(UtilityCode.load_cached("ExtTypeTest", "ObjectHandling.c"))
                        break
            else:
                entry =  env.lookup(target.name)
                # check whether or not entry is already cimported
                if (entry.is_type and entry.type.name == name
                        and hasattr(entry.type, 'module_name')):
                    if entry.type.module_name == self.module.module_name.value:
                        # cimported with absolute name
                        continue
                    try:
                        # cimported with relative name
                        module = env.find_module(self.module.module_name.value,
                                                 pos=None)
                        if entry.type.module_name == module.qualified_name:
                            continue
                    except AttributeError:
                        pass
                target = target.analyse_target_expression(env, None)  # FIXME?
                if target.type is py_object_type:
                    coerced_item = None
                else:
                    coerced_item = self.item.coerce_to(target.type, env)
                self.interned_items.append((name, target, coerced_item))
        return self

    def generate_execution_code(self, code):
        self.module.generate_evaluation_code(code)
        if self.import_star:
            code.putln(
                'if (%s(%s) < 0) %s;' % (
                    Naming.import_star,
                    self.module.py_result(),
                    code.error_goto(self.pos)))
        item_temp = code.funcstate.allocate_temp(py_object_type, manage_ref=True)
        self.item.set_cname(item_temp)
        if self.interned_items:
            code.globalstate.use_utility_code(
                UtilityCode.load_cached("ImportFrom", "ImportExport.c"))
        for name, target, coerced_item in self.interned_items:
            code.putln(
                '%s = __Pyx_ImportFrom(%s, %s); %s' % (
                    item_temp,
                    self.module.py_result(),
                    code.intern_identifier(name),
                    code.error_goto_if_null(item_temp, self.pos)))
            code.put_gotref(item_temp)
            if coerced_item is None:
                target.generate_assignment_code(self.item, code)
            else:
                coerced_item.allocate_temp_result(code)
                coerced_item.generate_result_code(code)
                target.generate_assignment_code(coerced_item, code)
            code.put_decref_clear(item_temp, py_object_type)
        code.funcstate.release_temp(item_temp)
        self.module.generate_disposal_code(code)
        self.module.free_temps(code)


class ParallelNode(Node):
    """
    Base class for cython.parallel constructs.
    """

    nogil_check = None


class ParallelStatNode(StatNode, ParallelNode):
    """
    Base class for 'with cython.parallel.parallel():' and 'for i in prange():'.

    assignments     { Entry(var) : (var.pos, inplace_operator_or_None) }
                    assignments to variables in this parallel section

    parent          parent ParallelStatNode or None
    is_parallel     indicates whether this node is OpenMP parallel
                    (true for #pragma omp parallel for and
                              #pragma omp parallel)

    is_parallel is true for:

        #pragma omp parallel
        #pragma omp parallel for

    sections, but NOT for

        #pragma omp for

    We need this to determine the sharing attributes.

    privatization_insertion_point   a code insertion point used to make temps
                                    private (esp. the "nsteps" temp)

    args         tuple          the arguments passed to the parallel construct
    kwargs       DictNode       the keyword arguments passed to the parallel
                                construct (replaced by its compile time value)
    """

    child_attrs = ['body', 'num_threads']

    body = None

    is_prange = False
    is_nested_prange = False

    error_label_used = False

    num_threads = None
    chunksize = None

    parallel_exc = (
        Naming.parallel_exc_type,
        Naming.parallel_exc_value,
        Naming.parallel_exc_tb,
    )

    parallel_pos_info = (
        Naming.parallel_filename,
        Naming.parallel_lineno,
        Naming.parallel_clineno,
    )

    pos_info = (
        Naming.filename_cname,
        Naming.lineno_cname,
        Naming.clineno_cname,
    )

    critical_section_counter = 0

    def __init__(self, pos, **kwargs):
        super(ParallelStatNode, self).__init__(pos, **kwargs)

        # All assignments in this scope
        self.assignments = kwargs.get('assignments') or {}

        # All seen closure cnames and their temporary cnames
        self.seen_closure_vars = set()

        # Dict of variables that should be declared (first|last|)private or
        # reduction { Entry: (op, lastprivate) }.
        # If op is not None, it's a reduction.
        self.privates = {}

        # [NameNode]
        self.assigned_nodes = []

    def analyse_declarations(self, env):
        self.body.analyse_declarations(env)

        self.num_threads = None

        if self.kwargs:
            # Try to find num_threads and chunksize keyword arguments
            pairs = []
            for dictitem in self.kwargs.key_value_pairs:
                if dictitem.key.value == 'num_threads':
                    self.num_threads = dictitem.value
                elif self.is_prange and dictitem.key.value == 'chunksize':
                    self.chunksize = dictitem.value
                else:
                    pairs.append(dictitem)

            self.kwargs.key_value_pairs = pairs

            try:
                self.kwargs = self.kwargs.compile_time_value(env)
            except Exception, e:
                error(self.kwargs.pos, "Only compile-time values may be "
                                       "supplied as keyword arguments")
        else:
            self.kwargs = {}

        for kw, val in self.kwargs.iteritems():
            if kw not in self.valid_keyword_arguments:
                error(self.pos, "Invalid keyword argument: %s" % kw)
            else:
                setattr(self, kw, val)

    def analyse_expressions(self, env):
        if self.num_threads:
            self.num_threads = self.num_threads.analyse_expressions(env)

        if self.chunksize:
            self.chunksize = self.chunksize.analyse_expressions(env)

        self.body = self.body.analyse_expressions(env)
        self.analyse_sharing_attributes(env)

        if self.num_threads is not None:
            if (self.parent and self.parent.num_threads is not None and not
                                                    self.parent.is_prange):
                error(self.pos,
                      "num_threads already declared in outer section")
            elif self.parent and not self.parent.is_prange:
                error(self.pos,
                      "num_threads must be declared in the parent parallel section")
            elif (self.num_threads.type.is_int and
                  self.num_threads.is_literal and
                  self.num_threads.compile_time_value(env) <= 0):
                error(self.pos,
                      "argument to num_threads must be greater than 0")

            if not self.num_threads.is_simple():
                self.num_threads = self.num_threads.coerce_to(
                    PyrexTypes.c_int_type, env).coerce_to_temp(env)
        return self

    def analyse_sharing_attributes(self, env):
        """
        Analyse the privates for this block and set them in self.privates.
        This should be called in a post-order fashion during the
        analyse_expressions phase
        """
        for entry, (pos, op) in self.assignments.iteritems():

            if self.is_prange and not self.is_parallel:
                # closely nested prange in a with parallel block, disallow
                # assigning to privates in the with parallel block (we
                # consider it too implicit and magicky for users)
                if entry in self.parent.assignments:
                    error(pos,
                          "Cannot assign to private of outer parallel block")
                    continue

            if not self.is_prange and op:
                # Again possible, but considered to magicky
                error(pos, "Reductions not allowed for parallel blocks")
                continue

            # By default all variables should have the same values as if
            # executed sequentially
            lastprivate = True
            self.propagate_var_privatization(entry, pos, op, lastprivate)

    def propagate_var_privatization(self, entry, pos, op, lastprivate):
        """
        Propagate the sharing attributes of a variable. If the privatization is
        determined by a parent scope, done propagate further.

        If we are a prange, we propagate our sharing attributes outwards to
        other pranges. If we are a prange in parallel block and the parallel
        block does not determine the variable private, we propagate to the
        parent of the parent. Recursion stops at parallel blocks, as they have
        no concept of lastprivate or reduction.

        So the following cases propagate:

            sum is a reduction for all loops:

                for i in prange(n):
                    for j in prange(n):
                        for k in prange(n):
                            sum += i * j * k

            sum is a reduction for both loops, local_var is private to the
            parallel with block:

                for i in prange(n):
                    with parallel:
                        local_var = ... # private to the parallel
                        for j in prange(n):
                            sum += i * j

        Nested with parallel blocks are disallowed, because they wouldn't
        allow you to propagate lastprivates or reductions:

            #pragma omp parallel for lastprivate(i)
            for i in prange(n):

                sum = 0

                #pragma omp parallel private(j, sum)
                with parallel:

                    #pragma omp parallel
                    with parallel:

                        #pragma omp for lastprivate(j) reduction(+:sum)
                        for j in prange(n):
                            sum += i

                    # sum and j are well-defined here

                # sum and j are undefined here

            # sum and j are undefined here
        """
        self.privates[entry] = (op, lastprivate)

        if entry.type.is_memoryviewslice:
            error(pos, "Memoryview slices can only be shared in parallel sections")
            return

        if self.is_prange:
            if not self.is_parallel and entry not in self.parent.assignments:
                # Parent is a parallel with block
                parent = self.parent.parent
            else:
                parent = self.parent

            # We don't need to propagate privates, only reductions and
            # lastprivates
            if parent and (op or lastprivate):
                parent.propagate_var_privatization(entry, pos, op, lastprivate)

    def _allocate_closure_temp(self, code, entry):
        """
        Helper function that allocate a temporary for a closure variable that
        is assigned to.
        """
        if self.parent:
            return self.parent._allocate_closure_temp(code, entry)

        if entry.cname in self.seen_closure_vars:
            return entry.cname

        cname = code.funcstate.allocate_temp(entry.type, True)

        # Add both the actual cname and the temp cname, as the actual cname
        # will be replaced with the temp cname on the entry
        self.seen_closure_vars.add(entry.cname)
        self.seen_closure_vars.add(cname)

        self.modified_entries.append((entry, entry.cname))
        code.putln("%s = %s;" % (cname, entry.cname))
        entry.cname = cname

    def initialize_privates_to_nan(self, code, exclude=None):
        first = True

        for entry, (op, lastprivate) in self.privates.iteritems():
            if not op and (not exclude or entry != exclude):
                invalid_value = entry.type.invalid_value()

                if invalid_value:
                    if first:
                        code.putln("/* Initialize private variables to "
                                   "invalid values */")
                        first = False
                    code.putln("%s = %s;" % (entry.cname,
                                             entry.type.cast_code(invalid_value)))

    def evaluate_before_block(self, code, expr):
        c = self.begin_of_parallel_control_block_point_after_decls
        # we need to set the owner to ourselves temporarily, as
        # allocate_temp may generate a comment in the middle of our pragma
        # otherwise when DebugFlags.debug_temp_code_comments is in effect
        owner = c.funcstate.owner
        c.funcstate.owner = c
        expr.generate_evaluation_code(c)
        c.funcstate.owner = owner

        return expr.result()

    def put_num_threads(self, code):
        """
        Write self.num_threads if set as the num_threads OpenMP directive
        """
        if self.num_threads is not None:
            code.put(" num_threads(%s)" % self.evaluate_before_block(code,
                                                        self.num_threads))


    def declare_closure_privates(self, code):
        """
        If a variable is in a scope object, we need to allocate a temp and
        assign the value from the temp to the variable in the scope object
        after the parallel section. This kind of copying should be done only
        in the outermost parallel section.
        """
        self.modified_entries = []

        for entry in self.assignments:
            if entry.from_closure or entry.in_closure:
                self._allocate_closure_temp(code, entry)

    def release_closure_privates(self, code):
        """
        Release any temps used for variables in scope objects. As this is the
        outermost parallel block, we don't need to delete the cnames from
        self.seen_closure_vars.
        """
        for entry, original_cname in self.modified_entries:
            code.putln("%s = %s;" % (original_cname, entry.cname))
            code.funcstate.release_temp(entry.cname)
            entry.cname = original_cname

    def privatize_temps(self, code, exclude_temps=()):
        """
        Make any used temporaries private. Before the relevant code block
        code.start_collecting_temps() should have been called.
        """
        if self.is_parallel:
            c = self.privatization_insertion_point

            self.temps = temps = code.funcstate.stop_collecting_temps()
            privates, firstprivates = [], []
            for temp, type in temps:
                if type.is_pyobject or type.is_memoryviewslice:
                    firstprivates.append(temp)
                else:
                    privates.append(temp)

            if privates:
                c.put(" private(%s)" % ", ".join(privates))
            if firstprivates:
                c.put(" firstprivate(%s)" % ", ".join(firstprivates))

            if self.breaking_label_used:
                shared_vars = [Naming.parallel_why]
                if self.error_label_used:
                    shared_vars.extend(self.parallel_exc)
                    c.put(" private(%s, %s, %s)" % self.pos_info)

                c.put(" shared(%s)" % ', '.join(shared_vars))

    def cleanup_temps(self, code):
        # Now clean up any memoryview slice and object temporaries
        if self.is_parallel and not self.is_nested_prange:
            code.putln("/* Clean up any temporaries */")
            for temp, type in self.temps:
                if type.is_memoryviewslice:
                    code.put_xdecref_memoryviewslice(temp, have_gil=False)
                elif type.is_pyobject:
                    code.put_xdecref(temp, type)
                    code.putln("%s = NULL;" % temp)

    def setup_parallel_control_flow_block(self, code):
        """
        Sets up a block that surrounds the parallel block to determine
        how the parallel section was exited. Any kind of return is
        trapped (break, continue, return, exceptions). This is the idea:

        {
            int why = 0;

            #pragma omp parallel
            {
                return # -> goto new_return_label;
                goto end_parallel;

            new_return_label:
                why = 3;
                goto end_parallel;

            end_parallel:;
                #pragma omp flush(why) # we need to flush for every iteration
            }

            if (why == 3)
                goto old_return_label;
        }
        """
        self.old_loop_labels = code.new_loop_labels()
        self.old_error_label = code.new_error_label()
        self.old_return_label = code.return_label
        code.return_label = code.new_label(name="return")

        code.begin_block() # parallel control flow block
        self.begin_of_parallel_control_block_point = code.insertion_point()
        self.begin_of_parallel_control_block_point_after_decls = code.insertion_point()

        self.undef_builtin_expect_apple_gcc_bug(code)

    def begin_parallel_block(self, code):
        """
        Each OpenMP thread in a parallel section that contains a with gil block
        must have the thread-state initialized. The call to
        PyGILState_Release() then deallocates our threadstate. If we wouldn't
        do this, each with gil block would allocate and deallocate one, thereby
        losing exception information before it can be saved before leaving the
        parallel section.
        """
        self.begin_of_parallel_block = code.insertion_point()

    def end_parallel_block(self, code):
        """
        To ensure all OpenMP threads have thread states, we ensure the GIL
        in each thread (which creates a thread state if it doesn't exist),
        after which we release the GIL.
        On exit, reacquire the GIL and release the thread state.

        If compiled without OpenMP support (at the C level), then we still have
        to acquire the GIL to decref any object temporaries.
        """
        if self.error_label_used:
            begin_code = self.begin_of_parallel_block
            end_code = code

            begin_code.putln("#ifdef _OPENMP")
            begin_code.put_ensure_gil(declare_gilstate=True)
            begin_code.putln("Py_BEGIN_ALLOW_THREADS")
            begin_code.putln("#endif /* _OPENMP */")

            end_code.putln("#ifdef _OPENMP")
            end_code.putln("Py_END_ALLOW_THREADS")
            end_code.putln("#else")
            end_code.put_safe("{\n")
            end_code.put_ensure_gil()
            end_code.putln("#endif /* _OPENMP */")
            self.cleanup_temps(end_code)
            end_code.put_release_ensured_gil()
            end_code.putln("#ifndef _OPENMP")
            end_code.put_safe("}\n")
            end_code.putln("#endif /* _OPENMP */")

    def trap_parallel_exit(self, code, should_flush=False):
        """
        Trap any kind of return inside a parallel construct. 'should_flush'
        indicates whether the variable should be flushed, which is needed by
        prange to skip the loop. It also indicates whether we need to register
        a continue (we need this for parallel blocks, but not for prange
        loops, as it is a direct jump there).

        It uses the same mechanism as try/finally:
            1 continue
            2 break
            3 return
            4 error
        """
        save_lastprivates_label = code.new_label()
        dont_return_label = code.new_label()

        self.any_label_used = False
        self.breaking_label_used = False
        self.error_label_used = False

        self.parallel_private_temps = []

        all_labels = code.get_all_labels()

        # Figure this out before starting to generate any code
        for label in all_labels:
            if code.label_used(label):
                self.breaking_label_used = (self.breaking_label_used or
                                            label != code.continue_label)
                self.any_label_used = True

        if self.any_label_used:
            code.put_goto(dont_return_label)

        for i, label in enumerate(all_labels):
            if not code.label_used(label):
                continue

            is_continue_label = label == code.continue_label

            code.put_label(label)

            if not (should_flush and is_continue_label):
                if label == code.error_label:
                    self.error_label_used = True
                    self.fetch_parallel_exception(code)

                code.putln("%s = %d;" % (Naming.parallel_why, i + 1))

            if (self.breaking_label_used and self.is_prange and not
                    is_continue_label):
                code.put_goto(save_lastprivates_label)
            else:
                code.put_goto(dont_return_label)

        if self.any_label_used:
            if self.is_prange and self.breaking_label_used:
                # Don't rely on lastprivate, save our lastprivates
                code.put_label(save_lastprivates_label)
                self.save_parallel_vars(code)

            code.put_label(dont_return_label)

            if should_flush and self.breaking_label_used:
                code.putln_openmp("#pragma omp flush(%s)" % Naming.parallel_why)

    def save_parallel_vars(self, code):
        """
        The following shenanigans are instated when we break, return or
        propagate errors from a prange. In this case we cannot rely on
        lastprivate() to do its job, as no iterations may have executed yet
        in the last thread, leaving the values undefined. It is most likely
        that the breaking thread has well-defined values of the lastprivate
        variables, so we keep those values.
        """
        section_name = ("__pyx_parallel_lastprivates%d" %
                                            self.critical_section_counter)
        code.putln_openmp("#pragma omp critical(%s)" % section_name)
        ParallelStatNode.critical_section_counter += 1

        code.begin_block() # begin critical section

        c = self.begin_of_parallel_control_block_point

        temp_count = 0
        for entry, (op, lastprivate) in self.privates.iteritems():
            if not lastprivate or entry.type.is_pyobject:
                continue

            type_decl = entry.type.declaration_code("")
            temp_cname = "__pyx_parallel_temp%d" % temp_count
            private_cname = entry.cname

            temp_count += 1

            invalid_value = entry.type.invalid_value()
            if invalid_value:
                init = ' = ' + invalid_value
            else:
                init = ''
            # Declare the parallel private in the outer block
            c.putln("%s %s%s;" % (type_decl, temp_cname, init))

            # Initialize before escaping
            code.putln("%s = %s;" % (temp_cname, private_cname))

            self.parallel_private_temps.append((temp_cname, private_cname))

        code.end_block() # end critical section

    def fetch_parallel_exception(self, code):
        """
        As each OpenMP thread may raise an exception, we need to fetch that
        exception from the threadstate and save it for after the parallel
        section where it can be re-raised in the master thread.

        Although it would seem that __pyx_filename, __pyx_lineno and
        __pyx_clineno are only assigned to under exception conditions (i.e.,
        when we have the GIL), and thus should be allowed to be shared without
        any race condition, they are in fact subject to the same race
        conditions that they were previously when they were global variables
        and functions were allowed to release the GIL:

            thread A                thread B
                acquire
                set lineno
                release
                                        acquire
                                        set lineno
                                        release
                acquire
                fetch exception
                release
                                        skip the fetch

                deallocate threadstate  deallocate threadstate
        """
        code.begin_block()
        code.put_ensure_gil(declare_gilstate=True)

        code.putln_openmp("#pragma omp flush(%s)" % Naming.parallel_exc_type)
        code.putln(
            "if (!%s) {" % Naming.parallel_exc_type)

        code.putln("__Pyx_ErrFetch(&%s, &%s, &%s);" % self.parallel_exc)
        pos_info = chain(*zip(self.parallel_pos_info, self.pos_info))
        code.funcstate.uses_error_indicator = True
        code.putln("%s = %s; %s = %s; %s = %s;" % tuple(pos_info))
        code.put_gotref(Naming.parallel_exc_type)

        code.putln(
            "}")

        code.put_release_ensured_gil()
        code.end_block()

    def restore_parallel_exception(self, code):
        "Re-raise a parallel exception"
        code.begin_block()
        code.put_ensure_gil(declare_gilstate=True)

        code.put_giveref(Naming.parallel_exc_type)
        code.putln("__Pyx_ErrRestore(%s, %s, %s);" % self.parallel_exc)
        pos_info = chain(*zip(self.pos_info, self.parallel_pos_info))
        code.putln("%s = %s; %s = %s; %s = %s;" % tuple(pos_info))

        code.put_release_ensured_gil()
        code.end_block()

    def restore_labels(self, code):
        """
        Restore all old labels. Call this before the 'else' clause to for
        loops and always before ending the parallel control flow block.
        """
        code.set_all_labels(self.old_loop_labels + (self.old_return_label,
                                                    self.old_error_label))

    def end_parallel_control_flow_block(self, code,
                                        break_=False, continue_=False):
        """
        This ends the parallel control flow block and based on how the parallel
        section was exited, takes the corresponding action. The break_ and
        continue_ parameters indicate whether these should be propagated
        outwards:

            for i in prange(...):
                with cython.parallel.parallel():
                    continue

        Here break should be trapped in the parallel block, and propagated to
        the for loop.
        """
        c = self.begin_of_parallel_control_block_point

        # Firstly, always prefer errors over returning, continue or break
        if self.error_label_used:
            c.putln("const char *%s = NULL; int %s = 0, %s = 0;" %
                                                self.parallel_pos_info)

            c.putln("PyObject *%s = NULL, *%s = NULL, *%s = NULL;" %
                                                        self.parallel_exc)

            code.putln(
                "if (%s) {" % Naming.parallel_exc_type)
            code.putln("/* This may have been overridden by a continue, "
                       "break or return in another thread. Prefer the error. */")
            code.putln("%s = 4;" % Naming.parallel_why)
            code.putln(
                "}")

        if continue_:
            any_label_used = self.any_label_used
        else:
            any_label_used = self.breaking_label_used

        if any_label_used:
            # __pyx_parallel_why is used, declare and initialize
            c.putln("int %s;" % Naming.parallel_why)
            c.putln("%s = 0;" % Naming.parallel_why)

            code.putln(
                "if (%s) {" % Naming.parallel_why)

            for temp_cname, private_cname in self.parallel_private_temps:
                code.putln("%s = %s;" % (private_cname, temp_cname))

            code.putln("switch (%s) {" % Naming.parallel_why)
            if continue_:
                code.put("    case 1: ")
                code.put_goto(code.continue_label)

            if break_:
                code.put("    case 2: ")
                code.put_goto(code.break_label)

            code.put("    case 3: ")
            code.put_goto(code.return_label)

            if self.error_label_used:
                code.globalstate.use_utility_code(restore_exception_utility_code)
                code.putln("    case 4:")
                self.restore_parallel_exception(code)
                code.put_goto(code.error_label)

            code.putln("}") # end switch
            code.putln(
                "}") # end if

        code.end_block() # end parallel control flow block
        self.redef_builtin_expect_apple_gcc_bug(code)

    # FIXME: improve with version number for OS X Lion
    buggy_platform_macro_condition = "(defined(__APPLE__) || defined(__OSX__))"
    have_expect_condition = "(defined(__GNUC__) && " \
                             "(__GNUC__ > 2 || (__GNUC__ == 2 && (__GNUC_MINOR__ > 95))))"
    redef_condition = "(%s && %s)" % (buggy_platform_macro_condition, have_expect_condition)

    def undef_builtin_expect_apple_gcc_bug(self, code):
        """
        A bug on OS X Lion disallows __builtin_expect macros. This code avoids them
        """
        if not self.parent:
            code.undef_builtin_expect(self.redef_condition)

    def redef_builtin_expect_apple_gcc_bug(self, code):
        if not self.parent:
            code.redef_builtin_expect(self.redef_condition)


class ParallelWithBlockNode(ParallelStatNode):
    """
    This node represents a 'with cython.parallel.parallel():' block
    """

    valid_keyword_arguments = ['num_threads']

    num_threads = None

    def analyse_declarations(self, env):
        super(ParallelWithBlockNode, self).analyse_declarations(env)
        if self.args:
            error(self.pos, "cython.parallel.parallel() does not take "
                            "positional arguments")

    def generate_execution_code(self, code):
        self.declare_closure_privates(code)
        self.setup_parallel_control_flow_block(code)

        code.putln("#ifdef _OPENMP")
        code.put("#pragma omp parallel ")

        if self.privates:
            privates = [e.cname for e in self.privates
                                    if not e.type.is_pyobject]
            code.put('private(%s)' % ', '.join(privates))

        self.privatization_insertion_point = code.insertion_point()
        self.put_num_threads(code)
        code.putln("")

        code.putln("#endif /* _OPENMP */")

        code.begin_block() # parallel block
        self.begin_parallel_block(code)
        self.initialize_privates_to_nan(code)
        code.funcstate.start_collecting_temps()
        self.body.generate_execution_code(code)
        self.trap_parallel_exit(code)
        self.privatize_temps(code)
        self.end_parallel_block(code)
        code.end_block() # end parallel block

        continue_ = code.label_used(code.continue_label)
        break_ = code.label_used(code.break_label)

        self.restore_labels(code)
        self.end_parallel_control_flow_block(code, break_=break_,
                                             continue_=continue_)
        self.release_closure_privates(code)


class ParallelRangeNode(ParallelStatNode):
    """
    This node represents a 'for i in cython.parallel.prange():' construct.

    target       NameNode       the target iteration variable
    else_clause  Node or None   the else clause of this loop
    """

    child_attrs = ['body', 'target', 'else_clause', 'args', 'num_threads',
                   'chunksize']

    body = target = else_clause = args = None

    start = stop = step = None

    is_prange = True

    nogil = None
    schedule = None

    valid_keyword_arguments = ['schedule', 'nogil', 'num_threads', 'chunksize']

    def __init__(self, pos, **kwds):
        super(ParallelRangeNode, self).__init__(pos, **kwds)
        # Pretend to be a ForInStatNode for control flow analysis
        self.iterator = PassStatNode(pos)

    def analyse_declarations(self, env):
        super(ParallelRangeNode, self).analyse_declarations(env)
        self.target.analyse_target_declaration(env)
        if self.else_clause is not None:
            self.else_clause.analyse_declarations(env)

        if not self.args or len(self.args) > 3:
            error(self.pos, "Invalid number of positional arguments to prange")
            return

        if len(self.args) == 1:
            self.stop, = self.args
        elif len(self.args) == 2:
            self.start, self.stop = self.args
        else:
            self.start, self.stop, self.step = self.args

        if hasattr(self.schedule, 'decode'):
            self.schedule = self.schedule.decode('ascii')

        if self.schedule not in (None, 'static', 'dynamic', 'guided',
                                 'runtime'):
            error(self.pos, "Invalid schedule argument to prange: %s" %
                                                        (self.schedule,))

    def analyse_expressions(self, env):
        was_nogil = env.nogil
        if self.nogil:
            env.nogil = True

        if self.target is None:
            error(self.pos, "prange() can only be used as part of a for loop")
            return self

        self.target = self.target.analyse_target_types(env)

        if not self.target.type.is_numeric:
            # Not a valid type, assume one for now anyway

            if not self.target.type.is_pyobject:
                # nogil_check will catch the is_pyobject case
                error(self.target.pos,
                      "Must be of numeric type, not %s" % self.target.type)

            self.index_type = PyrexTypes.c_py_ssize_t_type
        else:
            self.index_type = self.target.type
            if not self.index_type.signed:
                warning(self.target.pos,
                        "Unsigned index type not allowed before OpenMP 3.0",
                        level=2)

        # Setup start, stop and step, allocating temps if needed
        self.names = 'start', 'stop', 'step'
        start_stop_step = self.start, self.stop, self.step

        for node, name in zip(start_stop_step, self.names):
            if node is not None:
                node.analyse_types(env)
                if not node.type.is_numeric:
                    error(node.pos, "%s argument must be numeric" % name)
                    continue

                if not node.is_literal:
                    node = node.coerce_to_temp(env)
                    setattr(self, name, node)

                # As we range from 0 to nsteps, computing the index along the
                # way, we need a fitting type for 'i' and 'nsteps'
                self.index_type = PyrexTypes.widest_numeric_type(
                                        self.index_type, node.type)

        if self.else_clause is not None:
            self.else_clause = self.else_clause.analyse_expressions(env)

        # Although not actually an assignment in this scope, it should be
        # treated as such to ensure it is unpacked if a closure temp, and to
        # ensure lastprivate behaviour and propagation. If the target index is
        # not a NameNode, it won't have an entry, and an error was issued by
        # ParallelRangeTransform
        if hasattr(self.target, 'entry'):
            self.assignments[self.target.entry] = self.target.pos, None

        node = super(ParallelRangeNode, self).analyse_expressions(env)

        if node.chunksize:
            if not node.schedule:
                error(node.chunksize.pos,
                      "Must provide schedule with chunksize")
            elif node.schedule == 'runtime':
                error(node.chunksize.pos,
                      "Chunksize not valid for the schedule runtime")
            elif (node.chunksize.type.is_int and
                  node.chunksize.is_literal and
                  node.chunksize.compile_time_value(env) <= 0):
                error(node.chunksize.pos, "Chunksize must not be negative")

            node.chunksize = node.chunksize.coerce_to(
                PyrexTypes.c_int_type, env).coerce_to_temp(env)

        if node.nogil:
            env.nogil = was_nogil

        node.is_nested_prange = node.parent and node.parent.is_prange
        if node.is_nested_prange:
            parent = node
            while parent.parent and parent.parent.is_prange:
                parent = parent.parent

            parent.assignments.update(node.assignments)
            parent.privates.update(node.privates)
            parent.assigned_nodes.extend(node.assigned_nodes)
        return node

    def nogil_check(self, env):
        names = 'start', 'stop', 'step', 'target'
        nodes = self.start, self.stop, self.step, self.target
        for name, node in zip(names, nodes):
            if node is not None and node.type.is_pyobject:
                error(node.pos, "%s may not be a Python object "
                                "as we don't have the GIL" % name)

    def generate_execution_code(self, code):
        """
        Generate code in the following steps

            1)  copy any closure variables determined thread-private
                into temporaries

            2)  allocate temps for start, stop and step

            3)  generate a loop that calculates the total number of steps,
                which then computes the target iteration variable for every step:

                    for i in prange(start, stop, step):
                        ...

                becomes

                    nsteps = (stop - start) / step;
                    i = start;

                    #pragma omp parallel for lastprivate(i)
                    for (temp = 0; temp < nsteps; temp++) {
                        i = start + step * temp;
                        ...
                    }

                Note that accumulation of 'i' would have a data dependency
                between iterations.

                Also, you can't do this

                    for (i = start; i < stop; i += step)
                        ...

                as the '<' operator should become '>' for descending loops.
                'for i from x < i < y:' does not suffer from this problem
                as the relational operator is known at compile time!

            4) release our temps and write back any private closure variables
        """
        self.declare_closure_privates(code)

        # This can only be a NameNode
        target_index_cname = self.target.entry.cname

        # This will be used as the dict to format our code strings, holding
        # the start, stop , step, temps and target cnames
        fmt_dict = {
            'target': target_index_cname,
        }

        # Setup start, stop and step, allocating temps if needed
        start_stop_step = self.start, self.stop, self.step
        defaults = '0', '0', '1'
        for node, name, default in zip(start_stop_step, self.names, defaults):
            if node is None:
                result = default
            elif node.is_literal:
                result = node.get_constant_c_result_code()
            else:
                node.generate_evaluation_code(code)
                result = node.result()

            fmt_dict[name] = result

        fmt_dict['i'] = code.funcstate.allocate_temp(self.index_type, False)
        fmt_dict['nsteps'] = code.funcstate.allocate_temp(self.index_type, False)

        # TODO: check if the step is 0 and if so, raise an exception in a
        # 'with gil' block. For now, just abort
        code.putln("if (%(step)s == 0) abort();" % fmt_dict)

        self.setup_parallel_control_flow_block(code) # parallel control flow block

        self.control_flow_var_code_point = code.insertion_point()

        # Note: nsteps is private in an outer scope if present
        code.putln("%(nsteps)s = (%(stop)s - %(start)s) / %(step)s;" % fmt_dict)

        # The target iteration variable might not be initialized, do it only if
        # we are executing at least 1 iteration, otherwise we should leave the
        # target unaffected. The target iteration variable is firstprivate to
        # shut up compiler warnings caused by lastprivate, as the compiler
        # erroneously believes that nsteps may be <= 0, leaving the private
        # target index uninitialized
        code.putln("if (%(nsteps)s > 0)" % fmt_dict)
        code.begin_block() # if block
        self.generate_loop(code, fmt_dict)
        code.end_block() # end if block

        self.restore_labels(code)

        if self.else_clause:
            if self.breaking_label_used:
                code.put("if (%s < 2)" % Naming.parallel_why)

            code.begin_block() # else block
            code.putln("/* else */")
            self.else_clause.generate_execution_code(code)
            code.end_block() # end else block

        # ------ cleanup ------
        self.end_parallel_control_flow_block(code) # end parallel control flow block

        # And finally, release our privates and write back any closure
        # variables
        for temp in start_stop_step:
            if temp is not None:
                temp.generate_disposal_code(code)
                temp.free_temps(code)

        code.funcstate.release_temp(fmt_dict['i'])
        code.funcstate.release_temp(fmt_dict['nsteps'])

        self.release_closure_privates(code)

    def generate_loop(self, code, fmt_dict):
        if self.is_nested_prange:
            code.putln("#if 0")
        else:
            code.putln("#ifdef _OPENMP")

        if not self.is_parallel:
            code.put("#pragma omp for")
            self.privatization_insertion_point = code.insertion_point()
            reduction_codepoint = self.parent.privatization_insertion_point
        else:
            code.put("#pragma omp parallel")
            self.privatization_insertion_point = code.insertion_point()
            reduction_codepoint = self.privatization_insertion_point
            code.putln("")
            code.putln("#endif /* _OPENMP */")

            code.begin_block() # pragma omp parallel begin block

            # Initialize the GIL if needed for this thread
            self.begin_parallel_block(code)

            if self.is_nested_prange:
                code.putln("#if 0")
            else:
                code.putln("#ifdef _OPENMP")
            code.put("#pragma omp for")

        for entry, (op, lastprivate) in self.privates.iteritems():
            # Don't declare the index variable as a reduction
            if op and op in "+*-&^|" and entry != self.target.entry:
                if entry.type.is_pyobject:
                    error(self.pos, "Python objects cannot be reductions")
                else:
                    #code.put(" reduction(%s:%s)" % (op, entry.cname))
                    # This is the only way reductions + nesting works in gcc4.5
                    reduction_codepoint.put(
                                " reduction(%s:%s)" % (op, entry.cname))
            else:
                if entry == self.target.entry:
                    code.put(" firstprivate(%s)" % entry.cname)
                    code.put(" lastprivate(%s)" % entry.cname)
                    continue

                if not entry.type.is_pyobject:
                    if lastprivate:
                        private = 'lastprivate'
                    else:
                        private = 'private'

                    code.put(" %s(%s)" % (private, entry.cname))

        if self.schedule:
            if self.chunksize:
                chunksize = ", %s" % self.evaluate_before_block(code,
                                                                self.chunksize)
            else:
                chunksize = ""

            code.put(" schedule(%s%s)" % (self.schedule, chunksize))

        self.put_num_threads(reduction_codepoint)

        code.putln("")
        code.putln("#endif /* _OPENMP */")

        code.put("for (%(i)s = 0; %(i)s < %(nsteps)s; %(i)s++)" % fmt_dict)
        code.begin_block() # for loop block

        guard_around_body_codepoint = code.insertion_point()

        # Start if guard block around the body. This may be unnecessary, but
        # at least it doesn't spoil indentation
        code.begin_block()

        code.putln("%(target)s = %(start)s + %(step)s * %(i)s;" % fmt_dict)
        self.initialize_privates_to_nan(code, exclude=self.target.entry)

        if self.is_parallel:
            code.funcstate.start_collecting_temps()

        self.body.generate_execution_code(code)
        self.trap_parallel_exit(code, should_flush=True)
        self.privatize_temps(code)

        if self.breaking_label_used:
            # Put a guard around the loop body in case return, break or
            # exceptions might be used
            guard_around_body_codepoint.putln("if (%s < 2)" % Naming.parallel_why)

        code.end_block() # end guard around loop body
        code.end_block() # end for loop block

        if self.is_parallel:
            # Release the GIL and deallocate the thread state
            self.end_parallel_block(code)
            code.end_block() # pragma omp parallel end block


class CnameDecoratorNode(StatNode):
    """
    This node is for the cname decorator in CythonUtilityCode:

        @cname('the_cname')
        cdef func(...):
            ...

    In case of a cdef class the cname specifies the objstruct_cname.

    node        the node to which the cname decorator is applied
    cname       the cname the node should get
    """

    child_attrs = ['node']

    def analyse_declarations(self, env):
        self.node.analyse_declarations(env)

        node = self.node
        if isinstance(node, CompilerDirectivesNode):
            node = node.body.stats[0]

        self.is_function = isinstance(node, FuncDefNode)
        is_struct_or_enum = isinstance(node, (CStructOrUnionDefNode,
                                                   CEnumDefNode))
        e = node.entry

        if self.is_function:
            e.cname = self.cname
            e.func_cname = self.cname
            e.used = True
            if e.pyfunc_cname and '.' in e.pyfunc_cname:
                e.pyfunc_cname = self.mangle(e.pyfunc_cname)
        elif is_struct_or_enum:
            e.cname = e.type.cname = self.cname
        else:
            scope = node.scope

            e.cname = self.cname
            e.type.objstruct_cname = self.cname + '_obj'
            e.type.typeobj_cname = Naming.typeobj_prefix + self.cname
            e.type.typeptr_cname = self.cname + '_type'
            e.type.scope.namespace_cname = e.type.typeptr_cname

            e.as_variable.cname = py_object_type.cast_code(e.type.typeptr_cname)

            scope.scope_prefix = self.cname + "_"

            for name, entry in scope.entries.iteritems():
                if entry.func_cname:
                    entry.func_cname = self.mangle(entry.cname)
                if entry.pyfunc_cname:
                    entry.pyfunc_cname = self.mangle(entry.pyfunc_cname)

    def mangle(self, cname):
        if '.' in cname:
            # remove __pyx_base from func_cname
            cname = cname.split('.')[-1]
        return '%s_%s' % (self.cname, cname)

    def analyse_expressions(self, env):
        self.node = self.node.analyse_expressions(env)
        return self

    def generate_function_definitions(self, env, code):
        "Ensure a prototype for every @cname method in the right place"
        if self.is_function and env.is_c_class_scope:
            # method in cdef class, generate a prototype in the header
            h_code = code.globalstate['utility_code_proto']

            if isinstance(self.node, DefNode):
                self.node.generate_function_header(
                            h_code, with_pymethdef=False, proto_only=True)
            else:
                import ModuleNode
                entry = self.node.entry
                cname = entry.cname
                entry.cname = entry.func_cname

                ModuleNode.generate_cfunction_declaration(
                        entry,
                        env.global_scope(),
                        h_code,
                        definition=True)

                entry.cname = cname

        self.node.generate_function_definitions(env, code)

    def generate_execution_code(self, code):
        self.node.generate_execution_code(code)


#------------------------------------------------------------------------------------
#
#  Runtime support code
#
#------------------------------------------------------------------------------------

if Options.gcc_branch_hints:
    branch_prediction_macros = """
/* Test for GCC > 2.95 */
#if defined(__GNUC__) \
    && (__GNUC__ > 2 || (__GNUC__ == 2 && (__GNUC_MINOR__ > 95)))
  #define likely(x)   __builtin_expect(!!(x), 1)
  #define unlikely(x) __builtin_expect(!!(x), 0)
#else /* !__GNUC__ or GCC < 2.95 */
  #define likely(x)   (x)
  #define unlikely(x) (x)
#endif /* __GNUC__ */
"""
else:
    branch_prediction_macros = """
#define likely(x)   (x)
#define unlikely(x) (x)
"""

#------------------------------------------------------------------------------------

printing_utility_code = UtilityCode.load_cached("Print", "Printing.c")
printing_one_utility_code = UtilityCode.load_cached("PrintOne", "Printing.c")

#------------------------------------------------------------------------------------

# Exception raising code
#
# Exceptions are raised by __Pyx_Raise() and stored as plain
# type/value/tb in PyThreadState->curexc_*.  When being caught by an
# 'except' statement, curexc_* is moved over to exc_* by
# __Pyx_GetException()

restore_exception_utility_code = UtilityCode.load_cached("PyErrFetchRestore", "Exceptions.c")
raise_utility_code = UtilityCode.load_cached("RaiseException", "Exceptions.c")
get_exception_utility_code = UtilityCode.load_cached("GetException", "Exceptions.c")
swap_exception_utility_code = UtilityCode.load_cached("SwapException", "Exceptions.c")
reset_exception_utility_code = UtilityCode.load_cached("SaveResetException", "Exceptions.c")
traceback_utility_code = UtilityCode.load_cached("AddTraceback", "Exceptions.c")

#------------------------------------------------------------------------------------

get_exception_tuple_utility_code = UtilityCode(proto="""
static PyObject *__Pyx_GetExceptionTuple(void); /*proto*/
""",
# I doubt that calling __Pyx_GetException() here is correct as it moves
# the exception from tstate->curexc_* to tstate->exc_*, which prevents
# exception handlers later on from receiving it.
impl = """
static PyObject *__Pyx_GetExceptionTuple(void) {
    PyObject *type = NULL, *value = NULL, *tb = NULL;
    if (__Pyx_GetException(&type, &value, &tb) == 0) {
        PyObject* exc_info = PyTuple_New(3);
        if (exc_info) {
            Py_INCREF(type);
            Py_INCREF(value);
            Py_INCREF(tb);
            PyTuple_SET_ITEM(exc_info, 0, type);
            PyTuple_SET_ITEM(exc_info, 1, value);
            PyTuple_SET_ITEM(exc_info, 2, tb);
            return exc_info;
        }
    }
    return NULL;
}
""",
requires=[get_exception_utility_code])
