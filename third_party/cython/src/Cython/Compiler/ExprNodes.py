#
#   Parse tree nodes for expressions
#

import cython
cython.declare(error=object, warning=object, warn_once=object, InternalError=object,
               CompileError=object, UtilityCode=object, TempitaUtilityCode=object,
               StringEncoding=object, operator=object,
               Naming=object, Nodes=object, PyrexTypes=object, py_object_type=object,
               list_type=object, tuple_type=object, set_type=object, dict_type=object,
               unicode_type=object, str_type=object, bytes_type=object, type_type=object,
               Builtin=object, Symtab=object, Utils=object, find_coercion_error=object,
               debug_disposal_code=object, debug_temp_alloc=object, debug_coercion=object,
               bytearray_type=object, slice_type=object)

import sys
import copy
import operator

from Errors import error, warning, warn_once, InternalError, CompileError
from Errors import hold_errors, release_errors, held_errors, report_error
from Code import UtilityCode, TempitaUtilityCode
import StringEncoding
import Naming
import Nodes
from Nodes import Node
import PyrexTypes
from PyrexTypes import py_object_type, c_long_type, typecast, error_type, \
    unspecified_type
import TypeSlots
from Builtin import list_type, tuple_type, set_type, dict_type, type_type, \
     unicode_type, str_type, bytes_type, bytearray_type, basestring_type, slice_type
import Builtin
import Symtab
from Cython import Utils
from Annotate import AnnotationItem
from Cython.Compiler import Future
from Cython.Debugging import print_call_chain
from DebugFlags import debug_disposal_code, debug_temp_alloc, \
    debug_coercion

try:
    from __builtin__ import basestring
except ImportError:
    basestring = str # Python 3

try:
    from builtins import bytes
except ImportError:
    bytes = str # Python 2


class NotConstant(object):
    _obj = None

    def __new__(cls):
        if NotConstant._obj is None:
            NotConstant._obj = super(NotConstant, cls).__new__(cls)

        return NotConstant._obj

    def __repr__(self):
        return "<NOT CONSTANT>"

not_a_constant = NotConstant()
constant_value_not_set = object()

# error messages when coercing from key[0] to key[1]
coercion_error_dict = {
    # string related errors
    (Builtin.unicode_type, Builtin.bytes_type) : "Cannot convert Unicode string to 'bytes' implicitly, encoding required.",
    (Builtin.unicode_type, Builtin.str_type)   : "Cannot convert Unicode string to 'str' implicitly. This is not portable and requires explicit encoding.",
    (Builtin.unicode_type, PyrexTypes.c_char_ptr_type) : "Unicode objects only support coercion to Py_UNICODE*.",
    (Builtin.unicode_type, PyrexTypes.c_uchar_ptr_type) : "Unicode objects only support coercion to Py_UNICODE*.",
    (Builtin.bytes_type, Builtin.unicode_type) : "Cannot convert 'bytes' object to unicode implicitly, decoding required",
    (Builtin.bytes_type, Builtin.str_type) : "Cannot convert 'bytes' object to str implicitly. This is not portable to Py3.",
    (Builtin.bytes_type, Builtin.basestring_type) : "Cannot convert 'bytes' object to basestring implicitly. This is not portable to Py3.",
    (Builtin.bytes_type, PyrexTypes.c_py_unicode_ptr_type) : "Cannot convert 'bytes' object to Py_UNICODE*, use 'unicode'.",
    (Builtin.basestring_type, Builtin.bytes_type) : "Cannot convert 'basestring' object to bytes implicitly. This is not portable.",
    (Builtin.str_type, Builtin.unicode_type) : "str objects do not support coercion to unicode, use a unicode string literal instead (u'')",
    (Builtin.str_type, Builtin.bytes_type) : "Cannot convert 'str' to 'bytes' implicitly. This is not portable.",
    (Builtin.str_type, PyrexTypes.c_char_ptr_type) : "'str' objects do not support coercion to C types (use 'bytes'?).",
    (Builtin.str_type, PyrexTypes.c_uchar_ptr_type) : "'str' objects do not support coercion to C types (use 'bytes'?).",
    (Builtin.str_type, PyrexTypes.c_py_unicode_ptr_type) : "'str' objects do not support coercion to C types (use 'unicode'?).",
    (PyrexTypes.c_char_ptr_type, Builtin.unicode_type) : "Cannot convert 'char*' to unicode implicitly, decoding required",
    (PyrexTypes.c_uchar_ptr_type, Builtin.unicode_type) : "Cannot convert 'char*' to unicode implicitly, decoding required",
}

def find_coercion_error(type_tuple, default, env):
    err = coercion_error_dict.get(type_tuple)
    if err is None:
        return default
    elif ((PyrexTypes.c_char_ptr_type in type_tuple or PyrexTypes.c_uchar_ptr_type in type_tuple)
            and env.directives['c_string_encoding']):
        if type_tuple[1].is_pyobject:
            return default
        elif env.directives['c_string_encoding'] in ('ascii', 'default'):
            return default
        else:
            return "'%s' objects do not support coercion to C types with non-ascii or non-default c_string_encoding" % type_tuple[0].name
    else:
        return err


def default_str_type(env):
    return {
        'bytes': bytes_type,
        'bytearray': bytearray_type,
        'str': str_type,
        'unicode': unicode_type
    }.get(env.directives['c_string_type'])


def check_negative_indices(*nodes):
    """
    Raise a warning on nodes that are known to have negative numeric values.
    Used to find (potential) bugs inside of "wraparound=False" sections.
    """
    for node in nodes:
        if (node is None
                or not isinstance(node.constant_result, (int, float, long))):
            continue
        if node.constant_result < 0:
            warning(node.pos,
                    "the result of using negative indices inside of "
                    "code sections marked as 'wraparound=False' is "
                    "undefined", level=1)


def infer_sequence_item_type(env, seq_node, index_node=None, seq_type=None):
    if not seq_node.is_sequence_constructor:
        if seq_type is None:
            seq_type = seq_node.infer_type(env)
        if seq_type is tuple_type:
            # tuples are immutable => we can safely follow assignments
            if seq_node.cf_state and len(seq_node.cf_state) == 1:
                try:
                    seq_node = seq_node.cf_state[0].rhs
                except AttributeError:
                    pass
    if seq_node is not None and seq_node.is_sequence_constructor:
        if index_node is not None and index_node.has_constant_result():
            try:
                item = seq_node.args[index_node.constant_result]
            except (ValueError, TypeError, IndexError):
                pass
            else:
                return item.infer_type(env)
        # if we're lucky, all items have the same type
        item_types = set([item.infer_type(env) for item in seq_node.args])
        if len(item_types) == 1:
            return item_types.pop()
    return None


class ExprNode(Node):
    #  subexprs     [string]     Class var holding names of subexpr node attrs
    #  type         PyrexType    Type of the result
    #  result_code  string       Code fragment
    #  result_ctype string       C type of result_code if different from type
    #  is_temp      boolean      Result is in a temporary variable
    #  is_sequence_constructor
    #               boolean      Is a list or tuple constructor expression
    #  is_starred   boolean      Is a starred expression (e.g. '*a')
    #  saved_subexpr_nodes
    #               [ExprNode or [ExprNode or None] or None]
    #                            Cached result of subexpr_nodes()
    #  use_managed_ref boolean   use ref-counted temps/assignments/etc.
    #  result_is_used  boolean   indicates that the result will be dropped and the
    #                            result_code/temp_result can safely be set to None

    result_ctype = None
    type = None
    temp_code = None
    old_temp = None # error checker for multiple frees etc.
    use_managed_ref = True # can be set by optimisation transforms
    result_is_used = True

    #  The Analyse Expressions phase for expressions is split
    #  into two sub-phases:
    #
    #    Analyse Types
    #      Determines the result type of the expression based
    #      on the types of its sub-expressions, and inserts
    #      coercion nodes into the expression tree where needed.
    #      Marks nodes which will need to have temporary variables
    #      allocated.
    #
    #    Allocate Temps
    #      Allocates temporary variables where needed, and fills
    #      in the result_code field of each node.
    #
    #  ExprNode provides some convenience routines which
    #  perform both of the above phases. These should only
    #  be called from statement nodes, and only when no
    #  coercion nodes need to be added around the expression
    #  being analysed. In that case, the above two phases
    #  should be invoked separately.
    #
    #  Framework code in ExprNode provides much of the common
    #  processing for the various phases. It makes use of the
    #  'subexprs' class attribute of ExprNodes, which should
    #  contain a list of the names of attributes which can
    #  hold sub-nodes or sequences of sub-nodes.
    #
    #  The framework makes use of a number of abstract methods.
    #  Their responsibilities are as follows.
    #
    #    Declaration Analysis phase
    #
    #      analyse_target_declaration
    #        Called during the Analyse Declarations phase to analyse
    #        the LHS of an assignment or argument of a del statement.
    #        Nodes which cannot be the LHS of an assignment need not
    #        implement it.
    #
    #    Expression Analysis phase
    #
    #      analyse_types
    #        - Call analyse_types on all sub-expressions.
    #        - Check operand types, and wrap coercion nodes around
    #          sub-expressions where needed.
    #        - Set the type of this node.
    #        - If a temporary variable will be required for the
    #          result, set the is_temp flag of this node.
    #
    #      analyse_target_types
    #        Called during the Analyse Types phase to analyse
    #        the LHS of an assignment or argument of a del
    #        statement. Similar responsibilities to analyse_types.
    #
    #      target_code
    #        Called by the default implementation of allocate_target_temps.
    #        Should return a C lvalue for assigning to the node. The default
    #        implementation calls calculate_result_code.
    #
    #      check_const
    #        - Check that this node and its subnodes form a
    #          legal constant expression. If so, do nothing,
    #          otherwise call not_const.
    #
    #        The default implementation of check_const
    #        assumes that the expression is not constant.
    #
    #      check_const_addr
    #        - Same as check_const, except check that the
    #          expression is a C lvalue whose address is
    #          constant. Otherwise, call addr_not_const.
    #
    #        The default implementation of calc_const_addr
    #        assumes that the expression is not a constant
    #        lvalue.
    #
    #   Code Generation phase
    #
    #      generate_evaluation_code
    #        - Call generate_evaluation_code for sub-expressions.
    #        - Perform the functions of generate_result_code
    #          (see below).
    #        - If result is temporary, call generate_disposal_code
    #          on all sub-expressions.
    #
    #        A default implementation of generate_evaluation_code
    #        is provided which uses the following abstract methods:
    #
    #          generate_result_code
    #            - Generate any C statements necessary to calculate
    #              the result of this node from the results of its
    #              sub-expressions.
    #
    #          calculate_result_code
    #            - Should return a C code fragment evaluating to the
    #              result. This is only called when the result is not
    #              a temporary.
    #
    #      generate_assignment_code
    #        Called on the LHS of an assignment.
    #        - Call generate_evaluation_code for sub-expressions.
    #        - Generate code to perform the assignment.
    #        - If the assignment absorbed a reference, call
    #          generate_post_assignment_code on the RHS,
    #          otherwise call generate_disposal_code on it.
    #
    #      generate_deletion_code
    #        Called on an argument of a del statement.
    #        - Call generate_evaluation_code for sub-expressions.
    #        - Generate code to perform the deletion.
    #        - Call generate_disposal_code on all sub-expressions.
    #
    #

    is_sequence_constructor = 0
    is_string_literal = 0
    is_attribute = 0
    is_subscript = 0

    saved_subexpr_nodes = None
    is_temp = 0
    is_target = 0
    is_starred = 0

    constant_result = constant_value_not_set

    # whether this node with a memoryview type should be broadcast
    memslice_broadcast = False

    child_attrs = property(fget=operator.attrgetter('subexprs'))

    def not_implemented(self, method_name):
        print_call_chain(method_name, "not implemented") ###
        raise InternalError(
            "%s.%s not implemented" %
                (self.__class__.__name__, method_name))

    def is_lvalue(self):
        return 0

    def is_addressable(self):
        return self.is_lvalue() and not self.type.is_memoryviewslice

    def is_ephemeral(self):
        #  An ephemeral node is one whose result is in
        #  a Python temporary and we suspect there are no
        #  other references to it. Certain operations are
        #  disallowed on such values, since they are
        #  likely to result in a dangling pointer.
        return self.type.is_pyobject and self.is_temp

    def subexpr_nodes(self):
        #  Extract a list of subexpression nodes based
        #  on the contents of the subexprs class attribute.
        nodes = []
        for name in self.subexprs:
            item = getattr(self, name)
            if item is not None:
                if type(item) is list:
                    nodes.extend(item)
                else:
                    nodes.append(item)
        return nodes

    def result(self):
        if self.is_temp:
            return self.temp_code
        else:
            return self.calculate_result_code()

    def result_as(self, type = None):
        #  Return the result code cast to the specified C type.
        if (self.is_temp and self.type.is_pyobject and
                type != py_object_type):
            # Allocated temporaries are always PyObject *, which may not
            # reflect the actual type (e.g. an extension type)
            return typecast(type, py_object_type, self.result())
        return typecast(type, self.ctype(), self.result())

    def py_result(self):
        #  Return the result code cast to PyObject *.
        return self.result_as(py_object_type)

    def ctype(self):
        #  Return the native C type of the result (i.e. the
        #  C type of the result_code expression).
        return self.result_ctype or self.type

    def get_constant_c_result_code(self):
        # Return the constant value of this node as a result code
        # string, or None if the node is not constant.  This method
        # can be called when the constant result code is required
        # before the code generation phase.
        #
        # The return value is a string that can represent a simple C
        # value, a constant C name or a constant C expression.  If the
        # node type depends on Python code, this must return None.
        return None

    def calculate_constant_result(self):
        # Calculate the constant compile time result value of this
        # expression and store it in ``self.constant_result``.  Does
        # nothing by default, thus leaving ``self.constant_result``
        # unknown.  If valid, the result can be an arbitrary Python
        # value.
        #
        # This must only be called when it is assured that all
        # sub-expressions have a valid constant_result value.  The
        # ConstantFolding transform will do this.
        pass

    def has_constant_result(self):
        return self.constant_result is not constant_value_not_set and \
               self.constant_result is not not_a_constant

    def compile_time_value(self, denv):
        #  Return value of compile-time expression, or report error.
        error(self.pos, "Invalid compile-time expression")

    def compile_time_value_error(self, e):
        error(self.pos, "Error in compile-time expression: %s: %s" % (
            e.__class__.__name__, e))

    # ------------- Declaration Analysis ----------------

    def analyse_target_declaration(self, env):
        error(self.pos, "Cannot assign to or delete this")

    # ------------- Expression Analysis ----------------

    def analyse_const_expression(self, env):
        #  Called during the analyse_declarations phase of a
        #  constant expression. Analyses the expression's type,
        #  checks whether it is a legal const expression,
        #  and determines its value.
        node = self.analyse_types(env)
        node.check_const()
        return node

    def analyse_expressions(self, env):
        #  Convenience routine performing both the Type
        #  Analysis and Temp Allocation phases for a whole
        #  expression.
        return self.analyse_types(env)

    def analyse_target_expression(self, env, rhs):
        #  Convenience routine performing both the Type
        #  Analysis and Temp Allocation phases for the LHS of
        #  an assignment.
        return self.analyse_target_types(env)

    def analyse_boolean_expression(self, env):
        #  Analyse expression and coerce to a boolean.
        node = self.analyse_types(env)
        bool = node.coerce_to_boolean(env)
        return bool

    def analyse_temp_boolean_expression(self, env):
        #  Analyse boolean expression and coerce result into
        #  a temporary. This is used when a branch is to be
        #  performed on the result and we won't have an
        #  opportunity to ensure disposal code is executed
        #  afterwards. By forcing the result into a temporary,
        #  we ensure that all disposal has been done by the
        #  time we get the result.
        node = self.analyse_types(env)
        return node.coerce_to_boolean(env).coerce_to_simple(env)

    # --------------- Type Inference -----------------

    def type_dependencies(self, env):
        # Returns the list of entries whose types must be determined
        # before the type of self can be inferred.
        if hasattr(self, 'type') and self.type is not None:
            return ()
        return sum([node.type_dependencies(env) for node in self.subexpr_nodes()], ())

    def infer_type(self, env):
        # Attempt to deduce the type of self.
        # Differs from analyse_types as it avoids unnecessary
        # analysis of subexpressions, but can assume everything
        # in self.type_dependencies() has been resolved.
        if hasattr(self, 'type') and self.type is not None:
            return self.type
        elif hasattr(self, 'entry') and self.entry is not None:
            return self.entry.type
        else:
            self.not_implemented("infer_type")

    def nonlocally_immutable(self):
        # Returns whether this variable is a safe reference, i.e.
        # can't be modified as part of globals or closures.
        return self.is_literal or self.is_temp or self.type.is_array or self.type.is_cfunction

    # --------------- Type Analysis ------------------

    def analyse_as_module(self, env):
        # If this node can be interpreted as a reference to a
        # cimported module, return its scope, else None.
        return None

    def analyse_as_type(self, env):
        # If this node can be interpreted as a reference to a
        # type, return that type, else None.
        return None

    def analyse_as_extension_type(self, env):
        # If this node can be interpreted as a reference to an
        # extension type or builtin type, return its type, else None.
        return None

    def analyse_types(self, env):
        self.not_implemented("analyse_types")

    def analyse_target_types(self, env):
        return self.analyse_types(env)

    def nogil_check(self, env):
        # By default, any expression based on Python objects is
        # prevented in nogil environments.  Subtypes must override
        # this if they can work without the GIL.
        if self.type and self.type.is_pyobject:
            self.gil_error()

    def gil_assignment_check(self, env):
        if env.nogil and self.type.is_pyobject:
            error(self.pos, "Assignment of Python object not allowed without gil")

    def check_const(self):
        self.not_const()
        return False

    def not_const(self):
        error(self.pos, "Not allowed in a constant expression")

    def check_const_addr(self):
        self.addr_not_const()
        return False

    def addr_not_const(self):
        error(self.pos, "Address is not constant")

    # ----------------- Result Allocation -----------------

    def result_in_temp(self):
        #  Return true if result is in a temporary owned by
        #  this node or one of its subexpressions. Overridden
        #  by certain nodes which can share the result of
        #  a subnode.
        return self.is_temp

    def target_code(self):
        #  Return code fragment for use as LHS of a C assignment.
        return self.calculate_result_code()

    def calculate_result_code(self):
        self.not_implemented("calculate_result_code")

#    def release_target_temp(self, env):
#        #  Release temporaries used by LHS of an assignment.
#        self.release_subexpr_temps(env)

    def allocate_temp_result(self, code):
        if self.temp_code:
            raise RuntimeError("Temp allocated multiple times in %r: %r" % (self.__class__.__name__, self.pos))
        type = self.type
        if not type.is_void:
            if type.is_pyobject:
                type = PyrexTypes.py_object_type
            self.temp_code = code.funcstate.allocate_temp(
                type, manage_ref=self.use_managed_ref)
        else:
            self.temp_code = None

    def release_temp_result(self, code):
        if not self.temp_code:
            if not self.result_is_used:
                # not used anyway, so ignore if not set up
                return
            if self.old_temp:
                raise RuntimeError("temp %s released multiple times in %s" % (
                        self.old_temp, self.__class__.__name__))
            else:
                raise RuntimeError("no temp, but release requested in %s" % (
                        self.__class__.__name__))
        code.funcstate.release_temp(self.temp_code)
        self.old_temp = self.temp_code
        self.temp_code = None

    # ---------------- Code Generation -----------------

    def make_owned_reference(self, code):
        """
        If result is a pyobject, make sure we own a reference to it.
        If the result is in a temp, it is already a new reference.
        """
        if self.type.is_pyobject and not self.result_in_temp():
            code.put_incref(self.result(), self.ctype())

    def make_owned_memoryviewslice(self, code):
        """
        Make sure we own the reference to this memoryview slice.
        """
        if not self.result_in_temp():
            code.put_incref_memoryviewslice(self.result(),
                                            have_gil=self.in_nogil_context)

    def generate_evaluation_code(self, code):
        #  Generate code to evaluate this node and
        #  its sub-expressions, and dispose of any
        #  temporary results of its sub-expressions.
        self.generate_subexpr_evaluation_code(code)

        code.mark_pos(self.pos)
        if self.is_temp:
            self.allocate_temp_result(code)

        self.generate_result_code(code)
        if self.is_temp:
            # If we are temp we do not need to wait until this node is disposed
            # before disposing children.
            self.generate_subexpr_disposal_code(code)
            self.free_subexpr_temps(code)

    def generate_subexpr_evaluation_code(self, code):
        for node in self.subexpr_nodes():
            node.generate_evaluation_code(code)

    def generate_result_code(self, code):
        self.not_implemented("generate_result_code")

    def generate_disposal_code(self, code):
        if self.is_temp:
            if self.result():
                if self.type.is_pyobject:
                    code.put_decref_clear(self.result(), self.ctype())
                elif self.type.is_memoryviewslice:
                    code.put_xdecref_memoryviewslice(
                            self.result(), have_gil=not self.in_nogil_context)
        else:
            # Already done if self.is_temp
            self.generate_subexpr_disposal_code(code)

    def generate_subexpr_disposal_code(self, code):
        #  Generate code to dispose of temporary results
        #  of all sub-expressions.
        for node in self.subexpr_nodes():
            node.generate_disposal_code(code)

    def generate_post_assignment_code(self, code):
        if self.is_temp:
            if self.type.is_pyobject:
                code.putln("%s = 0;" % self.result())
            elif self.type.is_memoryviewslice:
                code.putln("%s.memview = NULL;" % self.result())
                code.putln("%s.data = NULL;" % self.result())
        else:
            self.generate_subexpr_disposal_code(code)

    def generate_assignment_code(self, rhs, code):
        #  Stub method for nodes which are not legal as
        #  the LHS of an assignment. An error will have
        #  been reported earlier.
        pass

    def generate_deletion_code(self, code, ignore_nonexisting=False):
        #  Stub method for nodes that are not legal as
        #  the argument of a del statement. An error
        #  will have been reported earlier.
        pass

    def free_temps(self, code):
        if self.is_temp:
            if not self.type.is_void:
                self.release_temp_result(code)
        else:
            self.free_subexpr_temps(code)

    def free_subexpr_temps(self, code):
        for sub in self.subexpr_nodes():
            sub.free_temps(code)

    def generate_function_definitions(self, env, code):
        pass

    # ---------------- Annotation ---------------------

    def annotate(self, code):
        for node in self.subexpr_nodes():
            node.annotate(code)

    # ----------------- Coercion ----------------------

    def coerce_to(self, dst_type, env):
        #   Coerce the result so that it can be assigned to
        #   something of type dst_type. If processing is necessary,
        #   wraps this node in a coercion node and returns that.
        #   Otherwise, returns this node unchanged.
        #
        #   This method is called during the analyse_expressions
        #   phase of the src_node's processing.
        #
        #   Note that subclasses that override this (especially
        #   ConstNodes) must not (re-)set their own .type attribute
        #   here.  Since expression nodes may turn up in different
        #   places in the tree (e.g. inside of CloneNodes in cascaded
        #   assignments), this method must return a new node instance
        #   if it changes the type.
        #
        src = self
        src_type = self.type

        if self.check_for_coercion_error(dst_type, env):
            return self

        if dst_type.is_reference and not src_type.is_reference:
            dst_type = dst_type.ref_base_type

        if src_type.is_const:
            src_type = src_type.const_base_type

        if src_type.is_fused or dst_type.is_fused:
            # See if we are coercing a fused function to a pointer to a
            # specialized function
            if (src_type.is_cfunction and not dst_type.is_fused and
                    dst_type.is_ptr and dst_type.base_type.is_cfunction):

                dst_type = dst_type.base_type

                for signature in src_type.get_all_specialized_function_types():
                    if signature.same_as(dst_type):
                        src.type = signature
                        src.entry = src.type.entry
                        src.entry.used = True
                        return self

            if src_type.is_fused:
                error(self.pos, "Type is not specialized")
            else:
                error(self.pos, "Cannot coerce to a type that is not specialized")

            self.type = error_type
            return self

        if self.coercion_type is not None:
            # This is purely for error checking purposes!
            node = NameNode(self.pos, name='', type=self.coercion_type)
            node.coerce_to(dst_type, env)

        if dst_type.is_memoryviewslice:
            import MemoryView
            if not src.type.is_memoryviewslice:
                if src.type.is_pyobject:
                    src = CoerceToMemViewSliceNode(src, dst_type, env)
                elif src.type.is_array:
                    src = CythonArrayNode.from_carray(src, env).coerce_to(
                                                            dst_type, env)
                elif not src_type.is_error:
                    error(self.pos,
                          "Cannot convert '%s' to memoryviewslice" %
                                                                (src_type,))
            elif not MemoryView.src_conforms_to_dst(
                        src.type, dst_type, broadcast=self.memslice_broadcast):
                if src.type.dtype.same_as(dst_type.dtype):
                    msg = "Memoryview '%s' not conformable to memoryview '%s'."
                    tup = src.type, dst_type
                else:
                    msg = "Different base types for memoryviews (%s, %s)"
                    tup = src.type.dtype, dst_type.dtype

                error(self.pos, msg % tup)

        elif dst_type.is_pyobject:
            if not src.type.is_pyobject:
                if dst_type is bytes_type and src.type.is_int:
                    src = CoerceIntToBytesNode(src, env)
                else:
                    src = CoerceToPyTypeNode(src, env, type=dst_type)
            if not src.type.subtype_of(dst_type):
                if src.constant_result is not None:
                    src = PyTypeTestNode(src, dst_type, env)
        elif src.type.is_pyobject:
            src = CoerceFromPyTypeNode(dst_type, src, env)
        elif (dst_type.is_complex
              and src_type != dst_type
              and dst_type.assignable_from(src_type)):
            src = CoerceToComplexNode(src, dst_type, env)
        else: # neither src nor dst are py types
            # Added the string comparison, since for c types that
            # is enough, but Cython gets confused when the types are
            # in different pxi files.
            if not (str(src.type) == str(dst_type) or dst_type.assignable_from(src_type)):
                self.fail_assignment(dst_type)
        return src

    def fail_assignment(self, dst_type):
        error(self.pos, "Cannot assign type '%s' to '%s'" % (self.type, dst_type))

    def check_for_coercion_error(self, dst_type, env, fail=False, default=None):
        if fail and not default:
            default = "Cannot assign type '%(FROM)s' to '%(TO)s'"
        message = find_coercion_error((self.type, dst_type), default, env)
        if message is not None:
            error(self.pos, message % {'FROM': self.type, 'TO': dst_type})
            return True
        if fail:
            self.fail_assignment(dst_type)
            return True
        return False

    def coerce_to_pyobject(self, env):
        return self.coerce_to(PyrexTypes.py_object_type, env)

    def coerce_to_boolean(self, env):
        #  Coerce result to something acceptable as
        #  a boolean value.

        # if it's constant, calculate the result now
        if self.has_constant_result():
            bool_value = bool(self.constant_result)
            return BoolNode(self.pos, value=bool_value,
                            constant_result=bool_value)

        type = self.type
        if type.is_enum or type.is_error:
            return self
        elif type.is_pyobject or type.is_int or type.is_ptr or type.is_float:
            return CoerceToBooleanNode(self, env)
        else:
            error(self.pos, "Type '%s' not acceptable as a boolean" % type)
            return self

    def coerce_to_integer(self, env):
        # If not already some C integer type, coerce to longint.
        if self.type.is_int:
            return self
        else:
            return self.coerce_to(PyrexTypes.c_long_type, env)

    def coerce_to_temp(self, env):
        #  Ensure that the result is in a temporary.
        if self.result_in_temp():
            return self
        else:
            return CoerceToTempNode(self, env)

    def coerce_to_simple(self, env):
        #  Ensure that the result is simple (see is_simple).
        if self.is_simple():
            return self
        else:
            return self.coerce_to_temp(env)

    def is_simple(self):
        #  A node is simple if its result is something that can
        #  be referred to without performing any operations, e.g.
        #  a constant, local var, C global var, struct member
        #  reference, or temporary.
        return self.result_in_temp()

    def may_be_none(self):
        if self.type and not (self.type.is_pyobject or
                              self.type.is_memoryviewslice):
            return False
        if self.has_constant_result():
            return self.constant_result is not None
        return True

    def as_cython_attribute(self):
        return None

    def as_none_safe_node(self, message, error="PyExc_TypeError", format_args=()):
        # Wraps the node in a NoneCheckNode if it is not known to be
        # not-None (e.g. because it is a Python literal).
        if self.may_be_none():
            return NoneCheckNode(self, error, message, format_args)
        else:
            return self

    @classmethod
    def from_node(cls, node, **kwargs):
        """Instantiate this node class from another node, properly
        copying over all attributes that one would forget otherwise.
        """
        attributes = "cf_state cf_maybe_null cf_is_null constant_result".split()
        for attr_name in attributes:
            if attr_name in kwargs:
                continue
            try:
                value = getattr(node, attr_name)
            except AttributeError:
                pass
            else:
                kwargs[attr_name] = value
        return cls(node.pos, **kwargs)


class AtomicExprNode(ExprNode):
    #  Abstract base class for expression nodes which have
    #  no sub-expressions.

    subexprs = []

    # Override to optimize -- we know we have no children
    def generate_subexpr_evaluation_code(self, code):
        pass
    def generate_subexpr_disposal_code(self, code):
        pass

class PyConstNode(AtomicExprNode):
    #  Abstract base class for constant Python values.

    is_literal = 1
    type = py_object_type

    def is_simple(self):
        return 1

    def may_be_none(self):
        return False

    def analyse_types(self, env):
        return self

    def calculate_result_code(self):
        return self.value

    def generate_result_code(self, code):
        pass


class NoneNode(PyConstNode):
    #  The constant value None

    is_none = 1
    value = "Py_None"

    constant_result = None

    nogil_check = None

    def compile_time_value(self, denv):
        return None

    def may_be_none(self):
        return True


class EllipsisNode(PyConstNode):
    #  '...' in a subscript list.

    value = "Py_Ellipsis"

    constant_result = Ellipsis

    def compile_time_value(self, denv):
        return Ellipsis


class ConstNode(AtomicExprNode):
    # Abstract base type for literal constant nodes.
    #
    # value     string      C code fragment

    is_literal = 1
    nogil_check = None

    def is_simple(self):
        return 1

    def nonlocally_immutable(self):
        return 1

    def may_be_none(self):
        return False

    def analyse_types(self, env):
        return self  # Types are held in class variables

    def check_const(self):
        return True

    def get_constant_c_result_code(self):
        return self.calculate_result_code()

    def calculate_result_code(self):
        return str(self.value)

    def generate_result_code(self, code):
        pass


class BoolNode(ConstNode):
    type = PyrexTypes.c_bint_type
    #  The constant value True or False

    def calculate_constant_result(self):
        self.constant_result = self.value

    def compile_time_value(self, denv):
        return self.value

    def calculate_result_code(self):
        if self.type.is_pyobject:
            return self.value and 'Py_True' or 'Py_False'
        else:
            return str(int(self.value))

    def coerce_to(self, dst_type, env):
        if dst_type.is_pyobject and self.type.is_int:
            return BoolNode(
                self.pos, value=self.value,
                constant_result=self.constant_result,
                type=Builtin.bool_type)
        if dst_type.is_int and self.type.is_pyobject:
            return BoolNode(
                self.pos, value=self.value,
                constant_result=self.constant_result,
                type=PyrexTypes.c_bint_type)
        return ConstNode.coerce_to(self, dst_type, env)


class NullNode(ConstNode):
    type = PyrexTypes.c_null_ptr_type
    value = "NULL"
    constant_result = 0

    def get_constant_c_result_code(self):
        return self.value


class CharNode(ConstNode):
    type = PyrexTypes.c_char_type

    def calculate_constant_result(self):
        self.constant_result = ord(self.value)

    def compile_time_value(self, denv):
        return ord(self.value)

    def calculate_result_code(self):
        return "'%s'" % StringEncoding.escape_char(self.value)


class IntNode(ConstNode):

    # unsigned     "" or "U"
    # longness     "" or "L" or "LL"
    # is_c_literal   True/False/None   creator considers this a C integer literal

    unsigned = ""
    longness = ""
    is_c_literal = None # unknown

    def __init__(self, pos, **kwds):
        ExprNode.__init__(self, pos, **kwds)
        if 'type' not in kwds:
            self.type = self.find_suitable_type_for_value()

    def find_suitable_type_for_value(self):
        if self.constant_result is constant_value_not_set:
            try:
                self.calculate_constant_result()
            except ValueError:
                pass
        # we ignore 'is_c_literal = True' and instead map signed 32bit
        # integers as C long values
        if self.is_c_literal or \
               self.constant_result in (constant_value_not_set, not_a_constant) or \
               self.unsigned or self.longness == 'LL':
            # clearly a C literal
            rank = (self.longness == 'LL') and 2 or 1
            suitable_type = PyrexTypes.modifiers_and_name_to_type[not self.unsigned, rank, "int"]
            if self.type:
                suitable_type = PyrexTypes.widest_numeric_type(suitable_type, self.type)
        else:
            # C literal or Python literal - split at 32bit boundary
            if -2**31 <= self.constant_result < 2**31:
                if self.type and self.type.is_int:
                    suitable_type = self.type
                else:
                    suitable_type = PyrexTypes.c_long_type
            else:
                suitable_type = PyrexTypes.py_object_type
        return suitable_type

    def coerce_to(self, dst_type, env):
        if self.type is dst_type:
            return self
        elif dst_type.is_float:
            if self.has_constant_result():
                return FloatNode(self.pos, value='%d.0' % int(self.constant_result), type=dst_type,
                                 constant_result=float(self.constant_result))
            else:
                return FloatNode(self.pos, value=self.value, type=dst_type,
                                 constant_result=not_a_constant)
        if dst_type.is_numeric and not dst_type.is_complex:
            node = IntNode(self.pos, value=self.value, constant_result=self.constant_result,
                           type = dst_type, is_c_literal = True,
                           unsigned=self.unsigned, longness=self.longness)
            return node
        elif dst_type.is_pyobject:
            node = IntNode(self.pos, value=self.value, constant_result=self.constant_result,
                           type = PyrexTypes.py_object_type, is_c_literal = False,
                           unsigned=self.unsigned, longness=self.longness)
        else:
            # FIXME: not setting the type here to keep it working with
            # complex numbers. Should they be special cased?
            node = IntNode(self.pos, value=self.value, constant_result=self.constant_result,
                           unsigned=self.unsigned, longness=self.longness)
        # We still need to perform normal coerce_to processing on the
        # result, because we might be coercing to an extension type,
        # in which case a type test node will be needed.
        return ConstNode.coerce_to(node, dst_type, env)

    def coerce_to_boolean(self, env):
        return IntNode(
            self.pos, value=self.value,
            constant_result=self.constant_result,
            type=PyrexTypes.c_bint_type,
            unsigned=self.unsigned, longness=self.longness)

    def generate_evaluation_code(self, code):
        if self.type.is_pyobject:
            # pre-allocate a Python version of the number
            plain_integer_string = str(Utils.str_to_number(self.value))
            self.result_code = code.get_py_int(plain_integer_string, self.longness)
        else:
            self.result_code = self.get_constant_c_result_code()

    def get_constant_c_result_code(self):
        return self.value_as_c_integer_string() + self.unsigned + self.longness

    def value_as_c_integer_string(self):
        value = self.value
        if len(value) > 2:
            # convert C-incompatible Py3 oct/bin notations
            if value[1] in 'oO':
                value = value[0] + value[2:] # '0o123' => '0123'
            elif value[1] in 'bB':
                value = int(value[2:], 2)
        return str(value)

    def calculate_result_code(self):
        return self.result_code

    def calculate_constant_result(self):
        self.constant_result = Utils.str_to_number(self.value)

    def compile_time_value(self, denv):
        return Utils.str_to_number(self.value)


class FloatNode(ConstNode):
    type = PyrexTypes.c_double_type

    def calculate_constant_result(self):
        self.constant_result = float(self.value)

    def compile_time_value(self, denv):
        return float(self.value)

    def coerce_to(self, dst_type, env):
        if dst_type.is_pyobject and self.type.is_float:
            return FloatNode(
                self.pos, value=self.value,
                constant_result=self.constant_result,
                type=Builtin.float_type)
        if dst_type.is_float and self.type.is_pyobject:
            return FloatNode(
                self.pos, value=self.value,
                constant_result=self.constant_result,
                type=dst_type)
        return ConstNode.coerce_to(self, dst_type, env)

    def calculate_result_code(self):
        return self.result_code

    def get_constant_c_result_code(self):
        strval = self.value
        assert isinstance(strval, (str, unicode))
        cmpval = repr(float(strval))
        if cmpval == 'nan':
            return "(Py_HUGE_VAL * 0)"
        elif cmpval == 'inf':
            return "Py_HUGE_VAL"
        elif cmpval == '-inf':
            return "(-Py_HUGE_VAL)"
        else:
            return strval

    def generate_evaluation_code(self, code):
        c_value = self.get_constant_c_result_code()
        if self.type.is_pyobject:
            self.result_code = code.get_py_float(self.value, c_value)
        else:
            self.result_code = c_value


class BytesNode(ConstNode):
    # A char* or bytes literal
    #
    # value      BytesLiteral

    is_string_literal = True
    # start off as Python 'bytes' to support len() in O(1)
    type = bytes_type

    def calculate_constant_result(self):
        self.constant_result = self.value

    def as_sliced_node(self, start, stop, step=None):
        value = StringEncoding.BytesLiteral(self.value[start:stop:step])
        value.encoding = self.value.encoding
        return BytesNode(
            self.pos, value=value, constant_result=value)

    def compile_time_value(self, denv):
        return self.value

    def analyse_as_type(self, env):
        type = PyrexTypes.parse_basic_type(self.value)
        if type is not None:
            return type
        from TreeFragment import TreeFragment
        pos = (self.pos[0], self.pos[1], self.pos[2]-7)
        declaration = TreeFragment(u"sizeof(%s)" % self.value, name=pos[0].filename, initial_pos=pos)
        sizeof_node = declaration.root.stats[0].expr
        sizeof_node = sizeof_node.analyse_types(env)
        if isinstance(sizeof_node, SizeofTypeNode):
            return sizeof_node.arg_type

    def can_coerce_to_char_literal(self):
        return len(self.value) == 1

    def coerce_to_boolean(self, env):
        # This is special because testing a C char* for truth directly
        # would yield the wrong result.
        bool_value = bool(self.value)
        return BoolNode(self.pos, value=bool_value, constant_result=bool_value)

    def coerce_to(self, dst_type, env):
        if self.type == dst_type:
            return self
        if dst_type.is_int:
            if not self.can_coerce_to_char_literal():
                error(self.pos, "Only single-character string literals can be coerced into ints.")
                return self
            if dst_type.is_unicode_char:
                error(self.pos, "Bytes literals cannot coerce to Py_UNICODE/Py_UCS4, use a unicode literal instead.")
                return self
            return CharNode(self.pos, value=self.value,
                            constant_result=ord(self.value))

        node = BytesNode(self.pos, value=self.value,
                         constant_result=self.constant_result)
        if dst_type.is_pyobject:
            if dst_type in (py_object_type, Builtin.bytes_type):
                node.type = Builtin.bytes_type
            else:
                self.check_for_coercion_error(dst_type, env, fail=True)
                return node
        elif dst_type == PyrexTypes.c_char_ptr_type:
            node.type = dst_type
            return node
        elif dst_type == PyrexTypes.c_uchar_ptr_type:
            node.type = PyrexTypes.c_char_ptr_type
            return CastNode(node, PyrexTypes.c_uchar_ptr_type)
        elif dst_type.assignable_from(PyrexTypes.c_char_ptr_type):
            node.type = dst_type
            return node

        # We still need to perform normal coerce_to processing on the
        # result, because we might be coercing to an extension type,
        # in which case a type test node will be needed.
        return ConstNode.coerce_to(node, dst_type, env)

    def generate_evaluation_code(self, code):
        if self.type.is_pyobject:
            self.result_code = code.get_py_string_const(self.value)
        else:
            self.result_code = code.get_string_const(self.value)

    def get_constant_c_result_code(self):
        return None # FIXME

    def calculate_result_code(self):
        return self.result_code


class UnicodeNode(ConstNode):
    # A Py_UNICODE* or unicode literal
    #
    # value        EncodedString
    # bytes_value  BytesLiteral    the literal parsed as bytes string
    #                              ('-3' unicode literals only)

    is_string_literal = True
    bytes_value = None
    type = unicode_type

    def calculate_constant_result(self):
        self.constant_result = self.value

    def as_sliced_node(self, start, stop, step=None):
        if StringEncoding.string_contains_surrogates(self.value[:stop]):
            # this is unsafe as it may give different results
            # in different runtimes
            return None
        value = StringEncoding.EncodedString(self.value[start:stop:step])
        value.encoding = self.value.encoding
        if self.bytes_value is not None:
            bytes_value = StringEncoding.BytesLiteral(
                self.bytes_value[start:stop:step])
            bytes_value.encoding = self.bytes_value.encoding
        else:
            bytes_value = None
        return UnicodeNode(
            self.pos, value=value, bytes_value=bytes_value,
            constant_result=value)

    def coerce_to(self, dst_type, env):
        if dst_type is self.type:
            pass
        elif dst_type.is_unicode_char:
            if not self.can_coerce_to_char_literal():
                error(self.pos,
                      "Only single-character Unicode string literals or "
                      "surrogate pairs can be coerced into Py_UCS4/Py_UNICODE.")
                return self
            int_value = ord(self.value)
            return IntNode(self.pos, type=dst_type, value=str(int_value),
                           constant_result=int_value)
        elif not dst_type.is_pyobject:
            if dst_type.is_string and self.bytes_value is not None:
                # special case: '-3' enforced unicode literal used in a
                # C char* context
                return BytesNode(self.pos, value=self.bytes_value
                    ).coerce_to(dst_type, env)
            if dst_type.is_pyunicode_ptr:
                node = UnicodeNode(self.pos, value=self.value)
                node.type = dst_type
                return node
            error(self.pos,
                  "Unicode literals do not support coercion to C types other "
                  "than Py_UNICODE/Py_UCS4 (for characters) or Py_UNICODE* "
                  "(for strings).")
        elif dst_type not in (py_object_type, Builtin.basestring_type):
            self.check_for_coercion_error(dst_type, env, fail=True)
        return self

    def can_coerce_to_char_literal(self):
        return len(self.value) == 1
            ## or (len(self.value) == 2
            ##     and (0xD800 <= self.value[0] <= 0xDBFF)
            ##     and (0xDC00 <= self.value[1] <= 0xDFFF))

    def coerce_to_boolean(self, env):
        bool_value = bool(self.value)
        return BoolNode(self.pos, value=bool_value, constant_result=bool_value)

    def contains_surrogates(self):
        return StringEncoding.string_contains_surrogates(self.value)

    def generate_evaluation_code(self, code):
        if self.type.is_pyobject:
            if self.contains_surrogates():
                # surrogates are not really portable and cannot be
                # decoded by the UTF-8 codec in Py3.3
                self.result_code = code.get_py_const(py_object_type, 'ustring')
                data_cname = code.get_pyunicode_ptr_const(self.value)
                code = code.get_cached_constants_writer()
                code.mark_pos(self.pos)
                code.putln(
                    "%s = PyUnicode_FromUnicode(%s, (sizeof(%s) / sizeof(Py_UNICODE))-1); %s" % (
                        self.result_code,
                        data_cname,
                        data_cname,
                        code.error_goto_if_null(self.result_code, self.pos)))
                code.putln("#if CYTHON_PEP393_ENABLED")
                code.put_error_if_neg(
                    self.pos, "PyUnicode_READY(%s)" % self.result_code)
                code.putln("#endif")
            else:
                self.result_code = code.get_py_string_const(self.value)
        else:
            self.result_code = code.get_pyunicode_ptr_const(self.value)

    def calculate_result_code(self):
        return self.result_code

    def compile_time_value(self, env):
        return self.value


class StringNode(PyConstNode):
    # A Python str object, i.e. a byte string in Python 2.x and a
    # unicode string in Python 3.x
    #
    # value          BytesLiteral (or EncodedString with ASCII content)
    # unicode_value  EncodedString or None
    # is_identifier  boolean

    type = str_type
    is_string_literal = True
    is_identifier = None
    unicode_value = None

    def calculate_constant_result(self):
        if self.unicode_value is not None:
            # only the Unicode value is portable across Py2/3
            self.constant_result = self.unicode_value

    def as_sliced_node(self, start, stop, step=None):
        value = type(self.value)(self.value[start:stop:step])
        value.encoding = self.value.encoding
        if self.unicode_value is not None:
            if StringEncoding.string_contains_surrogates(self.unicode_value[:stop]):
                # this is unsafe as it may give different results in different runtimes
                return None
            unicode_value = StringEncoding.EncodedString(
                self.unicode_value[start:stop:step])
        else:
            unicode_value = None
        return StringNode(
            self.pos, value=value, unicode_value=unicode_value,
            constant_result=value, is_identifier=self.is_identifier)

    def coerce_to(self, dst_type, env):
        if dst_type is not py_object_type and not str_type.subtype_of(dst_type):
#            if dst_type is Builtin.bytes_type:
#                # special case: bytes = 'str literal'
#                return BytesNode(self.pos, value=self.value)
            if not dst_type.is_pyobject:
                return BytesNode(self.pos, value=self.value).coerce_to(dst_type, env)
            if dst_type is not Builtin.basestring_type:
                self.check_for_coercion_error(dst_type, env, fail=True)
        return self

    def can_coerce_to_char_literal(self):
        return not self.is_identifier and len(self.value) == 1

    def generate_evaluation_code(self, code):
        self.result_code = code.get_py_string_const(
            self.value, identifier=self.is_identifier, is_str=True,
            unicode_value=self.unicode_value)

    def get_constant_c_result_code(self):
        return None

    def calculate_result_code(self):
        return self.result_code

    def compile_time_value(self, env):
        return self.value


class IdentifierStringNode(StringNode):
    # A special str value that represents an identifier (bytes in Py2,
    # unicode in Py3).
    is_identifier = True


class ImagNode(AtomicExprNode):
    #  Imaginary number literal
    #
    #  value   float    imaginary part

    type = PyrexTypes.c_double_complex_type

    def calculate_constant_result(self):
        self.constant_result = complex(0.0, self.value)

    def compile_time_value(self, denv):
        return complex(0.0, self.value)

    def analyse_types(self, env):
        self.type.create_declaration_utility_code(env)
        return self

    def may_be_none(self):
        return False

    def coerce_to(self, dst_type, env):
        if self.type is dst_type:
            return self
        node = ImagNode(self.pos, value=self.value)
        if dst_type.is_pyobject:
            node.is_temp = 1
            node.type = PyrexTypes.py_object_type
        # We still need to perform normal coerce_to processing on the
        # result, because we might be coercing to an extension type,
        # in which case a type test node will be needed.
        return AtomicExprNode.coerce_to(node, dst_type, env)

    gil_message = "Constructing complex number"

    def calculate_result_code(self):
        if self.type.is_pyobject:
            return self.result()
        else:
            return "%s(0, %r)" % (self.type.from_parts, float(self.value))

    def generate_result_code(self, code):
        if self.type.is_pyobject:
            code.putln(
                "%s = PyComplex_FromDoubles(0.0, %r); %s" % (
                    self.result(),
                    float(self.value),
                    code.error_goto_if_null(self.result(), self.pos)))
            code.put_gotref(self.py_result())


class NewExprNode(AtomicExprNode):

    # C++ new statement
    #
    # cppclass              node                 c++ class to create

    type = None

    def infer_type(self, env):
        type = self.cppclass.analyse_as_type(env)
        if type is None or not type.is_cpp_class:
            error(self.pos, "new operator can only be applied to a C++ class")
            self.type = error_type
            return
        self.cpp_check(env)
        constructor = type.scope.lookup(u'<init>')
        if constructor is None:
            func_type = PyrexTypes.CFuncType(type, [], exception_check='+')
            type.scope.declare_cfunction(u'<init>', func_type, self.pos)
            constructor = type.scope.lookup(u'<init>')
        self.class_type = type
        self.entry = constructor
        self.type = constructor.type
        return self.type

    def analyse_types(self, env):
        if self.type is None:
            self.infer_type(env)
        return self

    def may_be_none(self):
        return False

    def generate_result_code(self, code):
        pass

    def calculate_result_code(self):
        return "new " + self.class_type.declaration_code("")


class NameNode(AtomicExprNode):
    #  Reference to a local or global variable name.
    #
    #  name            string    Python name of the variable
    #  entry           Entry     Symbol table entry
    #  type_entry      Entry     For extension type names, the original type entry
    #  cf_is_null      boolean   Is uninitialized before this node
    #  cf_maybe_null   boolean   Maybe uninitialized before this node
    #  allow_null      boolean   Don't raise UnboundLocalError
    #  nogil           boolean   Whether it is used in a nogil context

    is_name = True
    is_cython_module = False
    cython_attribute = None
    lhs_of_first_assignment = False # TODO: remove me
    is_used_as_rvalue = 0
    entry = None
    type_entry = None
    cf_maybe_null = True
    cf_is_null = False
    allow_null = False
    nogil = False
    inferred_type = None

    def as_cython_attribute(self):
        return self.cython_attribute

    def type_dependencies(self, env):
        if self.entry is None:
            self.entry = env.lookup(self.name)
        if self.entry is not None and self.entry.type.is_unspecified:
            return (self,)
        else:
            return ()

    def infer_type(self, env):
        if self.entry is None:
            self.entry = env.lookup(self.name)
        if self.entry is None or self.entry.type is unspecified_type:
            if self.inferred_type is not None:
                return self.inferred_type
            return py_object_type
        elif (self.entry.type.is_extension_type or self.entry.type.is_builtin_type) and \
                self.name == self.entry.type.name:
            # Unfortunately the type attribute of type objects
            # is used for the pointer to the type they represent.
            return type_type
        elif self.entry.type.is_cfunction:
            if self.entry.scope.is_builtin_scope:
                # special case: optimised builtin functions must be treated as Python objects
                return py_object_type
            else:
                # special case: referring to a C function must return its pointer
                return PyrexTypes.CPtrType(self.entry.type)
        else:
            # If entry is inferred as pyobject it's safe to use local
            # NameNode's inferred_type.
            if self.entry.type.is_pyobject and self.inferred_type:
                # Overflow may happen if integer
                if not (self.inferred_type.is_int and self.entry.might_overflow):
                    return self.inferred_type
            return self.entry.type

    def compile_time_value(self, denv):
        try:
            return denv.lookup(self.name)
        except KeyError:
            error(self.pos, "Compile-time name '%s' not defined" % self.name)

    def get_constant_c_result_code(self):
        if not self.entry or self.entry.type.is_pyobject:
            return None
        return self.entry.cname

    def coerce_to(self, dst_type, env):
        #  If coercing to a generic pyobject and this is a builtin
        #  C function with a Python equivalent, manufacture a NameNode
        #  referring to the Python builtin.
        #print "NameNode.coerce_to:", self.name, dst_type ###
        if dst_type is py_object_type:
            entry = self.entry
            if entry and entry.is_cfunction:
                var_entry = entry.as_variable
                if var_entry:
                    if var_entry.is_builtin and var_entry.is_const:
                        var_entry = env.declare_builtin(var_entry.name, self.pos)
                    node = NameNode(self.pos, name = self.name)
                    node.entry = var_entry
                    node.analyse_rvalue_entry(env)
                    return node

        return super(NameNode, self).coerce_to(dst_type, env)

    def analyse_as_module(self, env):
        # Try to interpret this as a reference to a cimported module.
        # Returns the module scope, or None.
        entry = self.entry
        if not entry:
            entry = env.lookup(self.name)
        if entry and entry.as_module:
            return entry.as_module
        return None

    def analyse_as_type(self, env):
        if self.cython_attribute:
            type = PyrexTypes.parse_basic_type(self.cython_attribute)
        else:
            type = PyrexTypes.parse_basic_type(self.name)
        if type:
            return type
        entry = self.entry
        if not entry:
            entry = env.lookup(self.name)
        if entry and entry.is_type:
            return entry.type
        else:
            return None

    def analyse_as_extension_type(self, env):
        # Try to interpret this as a reference to an extension type.
        # Returns the extension type, or None.
        entry = self.entry
        if not entry:
            entry = env.lookup(self.name)
        if entry and entry.is_type:
            if entry.type.is_extension_type or entry.type.is_builtin_type:
                return entry.type
        return None

    def analyse_target_declaration(self, env):
        if not self.entry:
            self.entry = env.lookup_here(self.name)
        if not self.entry:
            if env.directives['warn.undeclared']:
                warning(self.pos, "implicit declaration of '%s'" % self.name, 1)
            if env.directives['infer_types'] != False:
                type = unspecified_type
            else:
                type = py_object_type
            self.entry = env.declare_var(self.name, type, self.pos)
        if self.entry.is_declared_generic:
            self.result_ctype = py_object_type

    def analyse_types(self, env):
        self.initialized_check = env.directives['initializedcheck']
        if self.entry is None:
            self.entry = env.lookup(self.name)
        if not self.entry:
            self.entry = env.declare_builtin(self.name, self.pos)
        if not self.entry:
            self.type = PyrexTypes.error_type
            return self
        entry = self.entry
        if entry:
            entry.used = 1
            if entry.type.is_buffer:
                import Buffer
                Buffer.used_buffer_aux_vars(entry)
        self.analyse_rvalue_entry(env)
        return self

    def analyse_target_types(self, env):
        self.analyse_entry(env, is_target=True)

        if (not self.is_lvalue() and self.entry.is_cfunction and
                self.entry.fused_cfunction and self.entry.as_variable):
            # We need this for the fused 'def' TreeFragment
            self.entry = self.entry.as_variable
            self.type = self.entry.type

        if self.type.is_const:
            error(self.pos, "Assignment to const '%s'" % self.name)
        if self.type.is_reference:
            error(self.pos, "Assignment to reference '%s'" % self.name)
        if not self.is_lvalue():
            error(self.pos, "Assignment to non-lvalue '%s'"
                % self.name)
            self.type = PyrexTypes.error_type
        self.entry.used = 1
        if self.entry.type.is_buffer:
            import Buffer
            Buffer.used_buffer_aux_vars(self.entry)
        return self

    def analyse_rvalue_entry(self, env):
        #print "NameNode.analyse_rvalue_entry:", self.name ###
        #print "Entry:", self.entry.__dict__ ###
        self.analyse_entry(env)
        entry = self.entry

        if entry.is_declared_generic:
            self.result_ctype = py_object_type

        if entry.is_pyglobal or entry.is_builtin:
            if entry.is_builtin and entry.is_const:
                self.is_temp = 0
            else:
                self.is_temp = 1

            self.is_used_as_rvalue = 1
        elif entry.type.is_memoryviewslice:
            self.is_temp = False
            self.is_used_as_rvalue = True
            self.use_managed_ref = True
        return self

    def nogil_check(self, env):
        self.nogil = True
        if self.is_used_as_rvalue:
            entry = self.entry
            if entry.is_builtin:
                if not entry.is_const: # cached builtins are ok
                    self.gil_error()
            elif entry.is_pyglobal:
                self.gil_error()
            elif self.entry.type.is_memoryviewslice:
                if self.cf_is_null or self.cf_maybe_null:
                    import MemoryView
                    MemoryView.err_if_nogil_initialized_check(self.pos, env)

    gil_message = "Accessing Python global or builtin"

    def analyse_entry(self, env, is_target=False):
        #print "NameNode.analyse_entry:", self.name ###
        self.check_identifier_kind()
        entry = self.entry
        type = entry.type
        if (not is_target and type.is_pyobject and self.inferred_type and
                self.inferred_type.is_builtin_type):
            # assume that type inference is smarter than the static entry
            type = self.inferred_type
        self.type = type

    def check_identifier_kind(self):
        # Check that this is an appropriate kind of name for use in an
        # expression.  Also finds the variable entry associated with
        # an extension type.
        entry = self.entry
        if entry.is_type and entry.type.is_extension_type:
            self.type_entry = entry
        if not (entry.is_const or entry.is_variable
            or entry.is_builtin or entry.is_cfunction
            or entry.is_cpp_class):
                if self.entry.as_variable:
                    self.entry = self.entry.as_variable
                else:
                    error(self.pos,
                          "'%s' is not a constant, variable or function identifier" % self.name)

    def is_simple(self):
        #  If it's not a C variable, it'll be in a temp.
        return 1

    def may_be_none(self):
        if self.cf_state and self.type and (self.type.is_pyobject or
                                            self.type.is_memoryviewslice):
            # gard against infinite recursion on self-dependencies
            if getattr(self, '_none_checking', False):
                # self-dependency - either this node receives a None
                # value from *another* node, or it can not reference
                # None at this point => safe to assume "not None"
                return False
            self._none_checking = True
            # evaluate control flow state to see if there were any
            # potential None values assigned to the node so far
            may_be_none = False
            for assignment in self.cf_state:
                if assignment.rhs.may_be_none():
                    may_be_none = True
                    break
            del self._none_checking
            return may_be_none
        return super(NameNode, self).may_be_none()

    def nonlocally_immutable(self):
        if ExprNode.nonlocally_immutable(self):
            return True
        entry = self.entry
        if not entry or entry.in_closure:
            return False
        return entry.is_local or entry.is_arg or entry.is_builtin or entry.is_readonly

    def calculate_target_results(self, env):
        pass

    def check_const(self):
        entry = self.entry
        if entry is not None and not (entry.is_const or entry.is_cfunction or entry.is_builtin):
            self.not_const()
            return False
        return True

    def check_const_addr(self):
        entry = self.entry
        if not (entry.is_cglobal or entry.is_cfunction or entry.is_builtin):
            self.addr_not_const()
            return False
        return True

    def is_lvalue(self):
        return self.entry.is_variable and \
            not self.entry.type.is_array and \
            not self.entry.is_readonly

    def is_addressable(self):
        return self.entry.is_variable and not self.type.is_memoryviewslice

    def is_ephemeral(self):
        #  Name nodes are never ephemeral, even if the
        #  result is in a temporary.
        return 0

    def calculate_result_code(self):
        entry = self.entry
        if not entry:
            return "<error>" # There was an error earlier
        return entry.cname

    def generate_result_code(self, code):
        assert hasattr(self, 'entry')
        entry = self.entry
        if entry is None:
            return # There was an error earlier
        if entry.is_builtin and entry.is_const:
            return # Lookup already cached
        elif entry.is_pyclass_attr:
            assert entry.type.is_pyobject, "Python global or builtin not a Python object"
            interned_cname = code.intern_identifier(self.entry.name)
            if entry.is_builtin:
                namespace = Naming.builtins_cname
            else: # entry.is_pyglobal
                namespace = entry.scope.namespace_cname
            if not self.cf_is_null:
                code.putln(
                    '%s = PyObject_GetItem(%s, %s);' % (
                        self.result(),
                        namespace,
                        interned_cname))
                code.putln('if (unlikely(!%s)) {' % self.result())
                code.putln('PyErr_Clear();')
            code.globalstate.use_utility_code(
                UtilityCode.load_cached("GetModuleGlobalName", "ObjectHandling.c"))
            code.putln(
                '%s = __Pyx_GetModuleGlobalName(%s);' % (
                    self.result(),
                    interned_cname))
            if not self.cf_is_null:
                code.putln("}")
            code.putln(code.error_goto_if_null(self.result(), self.pos))
            code.put_gotref(self.py_result())

        elif entry.is_builtin:
            assert entry.type.is_pyobject, "Python global or builtin not a Python object"
            interned_cname = code.intern_identifier(self.entry.name)
            code.globalstate.use_utility_code(
                UtilityCode.load_cached("GetBuiltinName", "ObjectHandling.c"))
            code.putln(
                '%s = __Pyx_GetBuiltinName(%s); %s' % (
                self.result(),
                interned_cname,
                code.error_goto_if_null(self.result(), self.pos)))
            code.put_gotref(self.py_result())

        elif entry.is_pyglobal:
            assert entry.type.is_pyobject, "Python global or builtin not a Python object"
            interned_cname = code.intern_identifier(self.entry.name)
            if entry.scope.is_module_scope:
                code.globalstate.use_utility_code(
                    UtilityCode.load_cached("GetModuleGlobalName", "ObjectHandling.c"))
                code.putln(
                    '%s = __Pyx_GetModuleGlobalName(%s); %s' % (
                        self.result(),
                        interned_cname,
                        code.error_goto_if_null(self.result(), self.pos)))
            else:
                # FIXME: is_pyglobal is also used for class namespace
                code.globalstate.use_utility_code(
                    UtilityCode.load_cached("GetNameInClass", "ObjectHandling.c"))
                code.putln(
                    '%s = __Pyx_GetNameInClass(%s, %s); %s' % (
                        self.result(),
                        entry.scope.namespace_cname,
                        interned_cname,
                        code.error_goto_if_null(self.result(), self.pos)))
            code.put_gotref(self.py_result())

        elif entry.is_local or entry.in_closure or entry.from_closure or entry.type.is_memoryviewslice:
            # Raise UnboundLocalError for objects and memoryviewslices
            raise_unbound = (
                (self.cf_maybe_null or self.cf_is_null) and not self.allow_null)
            null_code = entry.type.check_for_null_code(entry.cname)

            memslice_check = entry.type.is_memoryviewslice and self.initialized_check

            if null_code and raise_unbound and (entry.type.is_pyobject or memslice_check):
                code.put_error_if_unbound(self.pos, entry, self.in_nogil_context)

    def generate_assignment_code(self, rhs, code):
        #print "NameNode.generate_assignment_code:", self.name ###
        entry = self.entry
        if entry is None:
            return # There was an error earlier

        if (self.entry.type.is_ptr and isinstance(rhs, ListNode)
            and not self.lhs_of_first_assignment and not rhs.in_module_scope):
            error(self.pos, "Literal list must be assigned to pointer at time of declaration")

        # is_pyglobal seems to be True for module level-globals only.
        # We use this to access class->tp_dict if necessary.
        if entry.is_pyglobal:
            assert entry.type.is_pyobject, "Python global or builtin not a Python object"
            interned_cname = code.intern_identifier(self.entry.name)
            namespace = self.entry.scope.namespace_cname
            if entry.is_member:
                # if the entry is a member we have to cheat: SetAttr does not work
                # on types, so we create a descriptor which is then added to tp_dict
                setter = 'PyDict_SetItem'
                namespace = '%s->tp_dict' % namespace
            elif entry.scope.is_module_scope:
                setter = 'PyDict_SetItem'
                namespace = Naming.moddict_cname
            elif entry.is_pyclass_attr:
                setter = 'PyObject_SetItem'
            else:
                assert False, repr(entry)
            code.put_error_if_neg(
                self.pos,
                '%s(%s, %s, %s)' % (
                    setter,
                    namespace,
                    interned_cname,
                    rhs.py_result()))
            if debug_disposal_code:
                print("NameNode.generate_assignment_code:")
                print("...generating disposal code for %s" % rhs)
            rhs.generate_disposal_code(code)
            rhs.free_temps(code)
            if entry.is_member:
                # in Py2.6+, we need to invalidate the method cache
                code.putln("PyType_Modified(%s);" %
                           entry.scope.parent_type.typeptr_cname)
        else:
            if self.type.is_memoryviewslice:
                self.generate_acquire_memoryviewslice(rhs, code)

            elif self.type.is_buffer:
                # Generate code for doing the buffer release/acquisition.
                # This might raise an exception in which case the assignment (done
                # below) will not happen.
                #
                # The reason this is not in a typetest-like node is because the
                # variables that the acquired buffer info is stored to is allocated
                # per entry and coupled with it.
                self.generate_acquire_buffer(rhs, code)
            assigned = False
            if self.type.is_pyobject:
                #print "NameNode.generate_assignment_code: to", self.name ###
                #print "...from", rhs ###
                #print "...LHS type", self.type, "ctype", self.ctype() ###
                #print "...RHS type", rhs.type, "ctype", rhs.ctype() ###
                if self.use_managed_ref:
                    rhs.make_owned_reference(code)
                    is_external_ref = entry.is_cglobal or self.entry.in_closure or self.entry.from_closure
                    if is_external_ref:
                        if not self.cf_is_null:
                            if self.cf_maybe_null:
                                code.put_xgotref(self.py_result())
                            else:
                                code.put_gotref(self.py_result())
                    assigned = True
                    if entry.is_cglobal:
                        code.put_decref_set(
                            self.result(), rhs.result_as(self.ctype()))
                    else:
                        if not self.cf_is_null:
                            if self.cf_maybe_null:
                                code.put_xdecref_set(
                                    self.result(), rhs.result_as(self.ctype()))
                            else:
                                code.put_decref_set(
                                    self.result(), rhs.result_as(self.ctype()))
                        else:
                            assigned = False
                    if is_external_ref:
                        code.put_giveref(rhs.py_result())
            if not self.type.is_memoryviewslice:
                if not assigned:
                    code.putln('%s = %s;' % (
                        self.result(), rhs.result_as(self.ctype())))
                if debug_disposal_code:
                    print("NameNode.generate_assignment_code:")
                    print("...generating post-assignment code for %s" % rhs)
                rhs.generate_post_assignment_code(code)
            elif rhs.result_in_temp():
                rhs.generate_post_assignment_code(code)

            rhs.free_temps(code)

    def generate_acquire_memoryviewslice(self, rhs, code):
        """
        Slices, coercions from objects, return values etc are new references.
        We have a borrowed reference in case of dst = src
        """
        import MemoryView

        MemoryView.put_acquire_memoryviewslice(
            lhs_cname=self.result(),
            lhs_type=self.type,
            lhs_pos=self.pos,
            rhs=rhs,
            code=code,
            have_gil=not self.in_nogil_context,
            first_assignment=self.cf_is_null)

    def generate_acquire_buffer(self, rhs, code):
        # rhstmp is only used in case the rhs is a complicated expression leading to
        # the object, to avoid repeating the same C expression for every reference
        # to the rhs. It does NOT hold a reference.
        pretty_rhs = isinstance(rhs, NameNode) or rhs.is_temp
        if pretty_rhs:
            rhstmp = rhs.result_as(self.ctype())
        else:
            rhstmp = code.funcstate.allocate_temp(self.entry.type, manage_ref=False)
            code.putln('%s = %s;' % (rhstmp, rhs.result_as(self.ctype())))

        import Buffer
        Buffer.put_assign_to_buffer(self.result(), rhstmp, self.entry,
                                    is_initialized=not self.lhs_of_first_assignment,
                                    pos=self.pos, code=code)

        if not pretty_rhs:
            code.putln("%s = 0;" % rhstmp)
            code.funcstate.release_temp(rhstmp)

    def generate_deletion_code(self, code, ignore_nonexisting=False):
        if self.entry is None:
            return # There was an error earlier
        elif self.entry.is_pyclass_attr:
            namespace = self.entry.scope.namespace_cname
            interned_cname = code.intern_identifier(self.entry.name)
            if ignore_nonexisting:
                key_error_code = 'PyErr_Clear(); else'
            else:
                # minor hack: fake a NameError on KeyError
                key_error_code = (
                    '{ PyErr_Clear(); PyErr_Format(PyExc_NameError, "name \'%%s\' is not defined", "%s"); }' %
                    self.entry.name)
            code.putln(
                'if (unlikely(PyObject_DelItem(%s, %s) < 0)) {'
                ' if (likely(PyErr_ExceptionMatches(PyExc_KeyError))) %s'
                ' %s '
                '}' % (namespace, interned_cname,
                       key_error_code,
                       code.error_goto(self.pos)))
        elif self.entry.is_pyglobal:
            code.globalstate.use_utility_code(
                UtilityCode.load_cached("PyObjectSetAttrStr", "ObjectHandling.c"))
            interned_cname = code.intern_identifier(self.entry.name)
            del_code = '__Pyx_PyObject_DelAttrStr(%s, %s)' % (
                Naming.module_cname, interned_cname)
            if ignore_nonexisting:
                code.putln('if (unlikely(%s < 0)) { if (likely(PyErr_ExceptionMatches(PyExc_AttributeError))) PyErr_Clear(); else %s }' % (
                    del_code,
                    code.error_goto(self.pos)))
            else:
                code.put_error_if_neg(self.pos, del_code)
        elif self.entry.type.is_pyobject or self.entry.type.is_memoryviewslice:
            if not self.cf_is_null:
                if self.cf_maybe_null and not ignore_nonexisting:
                    code.put_error_if_unbound(self.pos, self.entry)

                if self.entry.type.is_pyobject:
                    if self.entry.in_closure:
                        # generator
                        if ignore_nonexisting and self.cf_maybe_null:
                            code.put_xgotref(self.result())
                        else:
                            code.put_gotref(self.result())
                    if ignore_nonexisting and self.cf_maybe_null:
                        code.put_xdecref(self.result(), self.ctype())
                    else:
                        code.put_decref(self.result(), self.ctype())
                    code.putln('%s = NULL;' % self.result())
                else:
                    code.put_xdecref_memoryviewslice(self.entry.cname,
                                                     have_gil=not self.nogil)
        else:
            error(self.pos, "Deletion of C names not supported")

    def annotate(self, code):
        if hasattr(self, 'is_called') and self.is_called:
            pos = (self.pos[0], self.pos[1], self.pos[2] - len(self.name) - 1)
            if self.type.is_pyobject:
                style, text = 'py_call', 'python function (%s)'
            else:
                style, text = 'c_call', 'c function (%s)'
            code.annotate(pos, AnnotationItem(style, text % self.type, size=len(self.name)))

class BackquoteNode(ExprNode):
    #  `expr`
    #
    #  arg    ExprNode

    type = py_object_type

    subexprs = ['arg']

    def analyse_types(self, env):
        self.arg = self.arg.analyse_types(env)
        self.arg = self.arg.coerce_to_pyobject(env)
        self.is_temp = 1
        return self

    gil_message = "Backquote expression"

    def calculate_constant_result(self):
        self.constant_result = repr(self.arg.constant_result)

    def generate_result_code(self, code):
        code.putln(
            "%s = PyObject_Repr(%s); %s" % (
                self.result(),
                self.arg.py_result(),
                code.error_goto_if_null(self.result(), self.pos)))
        code.put_gotref(self.py_result())


class ImportNode(ExprNode):
    #  Used as part of import statement implementation.
    #  Implements result =
    #    __import__(module_name, globals(), None, name_list, level)
    #
    #  module_name   StringNode            dotted name of module. Empty module
    #                       name means importing the parent package according
    #                       to level
    #  name_list     ListNode or None      list of names to be imported
    #  level         int                   relative import level:
    #                       -1: attempt both relative import and absolute import;
    #                        0: absolute import;
    #                       >0: the number of parent directories to search
    #                           relative to the current module.
    #                     None: decide the level according to language level and
    #                           directives

    type = py_object_type

    subexprs = ['module_name', 'name_list']

    def analyse_types(self, env):
        if self.level is None:
            if (env.directives['py2_import'] or
                Future.absolute_import not in env.global_scope().context.future_directives):
                self.level = -1
            else:
                self.level = 0
        module_name = self.module_name.analyse_types(env)
        self.module_name = module_name.coerce_to_pyobject(env)
        if self.name_list:
            name_list = self.name_list.analyse_types(env)
            self.name_list = name_list.coerce_to_pyobject(env)
        self.is_temp = 1
        env.use_utility_code(UtilityCode.load_cached("Import", "ImportExport.c"))
        return self

    gil_message = "Python import"

    def generate_result_code(self, code):
        if self.name_list:
            name_list_code = self.name_list.py_result()
        else:
            name_list_code = "0"
        code.putln(
            "%s = __Pyx_Import(%s, %s, %d); %s" % (
                self.result(),
                self.module_name.py_result(),
                name_list_code,
                self.level,
                code.error_goto_if_null(self.result(), self.pos)))
        code.put_gotref(self.py_result())


class IteratorNode(ExprNode):
    #  Used as part of for statement implementation.
    #
    #  Implements result = iter(sequence)
    #
    #  sequence   ExprNode

    type = py_object_type
    iter_func_ptr = None
    counter_cname = None
    cpp_iterator_cname = None
    reversed = False      # currently only used for list/tuple types (see Optimize.py)

    subexprs = ['sequence']

    def analyse_types(self, env):
        self.sequence = self.sequence.analyse_types(env)
        if (self.sequence.type.is_array or self.sequence.type.is_ptr) and \
                not self.sequence.type.is_string:
            # C array iteration will be transformed later on
            self.type = self.sequence.type
        elif self.sequence.type.is_cpp_class:
            self.analyse_cpp_types(env)
        else:
            self.sequence = self.sequence.coerce_to_pyobject(env)
            if self.sequence.type is list_type or \
                   self.sequence.type is tuple_type:
                self.sequence = self.sequence.as_none_safe_node("'NoneType' object is not iterable")
        self.is_temp = 1
        return self

    gil_message = "Iterating over Python object"

    _func_iternext_type = PyrexTypes.CPtrType(PyrexTypes.CFuncType(
        PyrexTypes.py_object_type, [
            PyrexTypes.CFuncTypeArg("it", PyrexTypes.py_object_type, None),
            ]))

    def type_dependencies(self, env):
        return self.sequence.type_dependencies(env)

    def infer_type(self, env):
        sequence_type = self.sequence.infer_type(env)
        if sequence_type.is_array or sequence_type.is_ptr:
            return sequence_type
        elif sequence_type.is_cpp_class:
            begin = sequence_type.scope.lookup("begin")
            if begin is not None:
                return begin.type.return_type
        elif sequence_type.is_pyobject:
            return sequence_type
        return py_object_type

    def analyse_cpp_types(self, env):
        sequence_type = self.sequence.type
        if sequence_type.is_ptr:
            sequence_type = sequence_type.base_type
        begin = sequence_type.scope.lookup("begin")
        end = sequence_type.scope.lookup("end")
        if (begin is None
            or not begin.type.is_cfunction
            or begin.type.args):
            error(self.pos, "missing begin() on %s" % self.sequence.type)
            self.type = error_type
            return
        if (end is None
            or not end.type.is_cfunction
            or end.type.args):
            error(self.pos, "missing end() on %s" % self.sequence.type)
            self.type = error_type
            return
        iter_type = begin.type.return_type
        if iter_type.is_cpp_class:
            if env.lookup_operator_for_types(
                    self.pos,
                    "!=",
                    [iter_type, end.type.return_type]) is None:
                error(self.pos, "missing operator!= on result of begin() on %s" % self.sequence.type)
                self.type = error_type
                return
            if env.lookup_operator_for_types(self.pos, '++', [iter_type]) is None:
                error(self.pos, "missing operator++ on result of begin() on %s" % self.sequence.type)
                self.type = error_type
                return
            if env.lookup_operator_for_types(self.pos, '*', [iter_type]) is None:
                error(self.pos, "missing operator* on result of begin() on %s" % self.sequence.type)
                self.type = error_type
                return
            self.type = iter_type
        elif iter_type.is_ptr:
            if not (iter_type == end.type.return_type):
                error(self.pos, "incompatible types for begin() and end()")
            self.type = iter_type
        else:
            error(self.pos, "result type of begin() on %s must be a C++ class or pointer" % self.sequence.type)
            self.type = error_type
            return

    def generate_result_code(self, code):
        sequence_type = self.sequence.type
        if sequence_type.is_cpp_class:
            if self.sequence.is_name:
                # safe: C++ won't allow you to reassign to class references
                begin_func = "%s.begin" % self.sequence.result()
            else:
                sequence_type = PyrexTypes.c_ptr_type(sequence_type)
                self.cpp_iterator_cname = code.funcstate.allocate_temp(sequence_type, manage_ref=False)
                code.putln("%s = &%s;" % (self.cpp_iterator_cname, self.sequence.result()))
                begin_func = "%s->begin" % self.cpp_iterator_cname
            # TODO: Limit scope.
            code.putln("%s = %s();" % (self.result(), begin_func))
            return
        if sequence_type.is_array or sequence_type.is_ptr:
            raise InternalError("for in carray slice not transformed")
        is_builtin_sequence = sequence_type is list_type or \
                              sequence_type is tuple_type
        if not is_builtin_sequence:
            # reversed() not currently optimised (see Optimize.py)
            assert not self.reversed, "internal error: reversed() only implemented for list/tuple objects"
        self.may_be_a_sequence = not sequence_type.is_builtin_type
        if self.may_be_a_sequence:
            code.putln(
                "if (PyList_CheckExact(%s) || PyTuple_CheckExact(%s)) {" % (
                    self.sequence.py_result(),
                    self.sequence.py_result()))
        if is_builtin_sequence or self.may_be_a_sequence:
            self.counter_cname = code.funcstate.allocate_temp(
                PyrexTypes.c_py_ssize_t_type, manage_ref=False)
            if self.reversed:
                if sequence_type is list_type:
                    init_value = 'PyList_GET_SIZE(%s) - 1' % self.result()
                else:
                    init_value = 'PyTuple_GET_SIZE(%s) - 1' % self.result()
            else:
                init_value = '0'
            code.putln(
                "%s = %s; __Pyx_INCREF(%s); %s = %s;" % (
                    self.result(),
                    self.sequence.py_result(),
                    self.result(),
                    self.counter_cname,
                    init_value
                    ))
        if not is_builtin_sequence:
            self.iter_func_ptr = code.funcstate.allocate_temp(self._func_iternext_type, manage_ref=False)
            if self.may_be_a_sequence:
                code.putln("%s = NULL;" % self.iter_func_ptr)
                code.putln("} else {")
                code.put("%s = -1; " % self.counter_cname)
            code.putln("%s = PyObject_GetIter(%s); %s" % (
                    self.result(),
                    self.sequence.py_result(),
                    code.error_goto_if_null(self.result(), self.pos)))
            code.put_gotref(self.py_result())
            code.putln("%s = Py_TYPE(%s)->tp_iternext;" % (self.iter_func_ptr, self.py_result()))
        if self.may_be_a_sequence:
            code.putln("}")

    def generate_next_sequence_item(self, test_name, result_name, code):
        assert self.counter_cname, "internal error: counter_cname temp not prepared"
        final_size = 'Py%s_GET_SIZE(%s)' % (test_name, self.py_result())
        if self.sequence.is_sequence_constructor:
            item_count = len(self.sequence.args)
            if self.sequence.mult_factor is None:
                final_size = item_count
            elif isinstance(self.sequence.mult_factor.constant_result, (int, long)):
                final_size = item_count * self.sequence.mult_factor.constant_result
        code.putln("if (%s >= %s) break;" % (self.counter_cname, final_size))
        if self.reversed:
            inc_dec = '--'
        else:
            inc_dec = '++'
        code.putln("#if CYTHON_COMPILING_IN_CPYTHON")
        code.putln(
            "%s = Py%s_GET_ITEM(%s, %s); __Pyx_INCREF(%s); %s%s; %s" % (
                result_name,
                test_name,
                self.py_result(),
                self.counter_cname,
                result_name,
                self.counter_cname,
                inc_dec,
                # use the error label to avoid C compiler warnings if we only use it below
                code.error_goto_if_neg('0', self.pos)
                ))
        code.putln("#else")
        code.putln(
            "%s = PySequence_ITEM(%s, %s); %s%s; %s" % (
                result_name,
                self.py_result(),
                self.counter_cname,
                self.counter_cname,
                inc_dec,
                code.error_goto_if_null(result_name, self.pos)))
        code.putln("#endif")

    def generate_iter_next_result_code(self, result_name, code):
        sequence_type = self.sequence.type
        if self.reversed:
            code.putln("if (%s < 0) break;" % self.counter_cname)
        if sequence_type.is_cpp_class:
            if self.cpp_iterator_cname:
                end_func = "%s->end" % self.cpp_iterator_cname
            else:
                end_func = "%s.end" % self.sequence.result()
            # TODO: Cache end() call?
            code.putln("if (!(%s != %s())) break;" % (
                            self.result(),
                            end_func))
            code.putln("%s = *%s;" % (
                            result_name,
                            self.result()))
            code.putln("++%s;" % self.result())
            return
        elif sequence_type is list_type:
            self.generate_next_sequence_item('List', result_name, code)
            return
        elif sequence_type is tuple_type:
            self.generate_next_sequence_item('Tuple', result_name, code)
            return

        if self.may_be_a_sequence:
            for test_name in ('List', 'Tuple'):
                code.putln("if (!%s && Py%s_CheckExact(%s)) {" % (
                    self.iter_func_ptr, test_name, self.py_result()))
                self.generate_next_sequence_item(test_name, result_name, code)
                code.put("} else ")

        code.putln("{")
        code.putln(
            "%s = %s(%s);" % (
                result_name,
                self.iter_func_ptr,
                self.py_result()))
        code.putln("if (unlikely(!%s)) {" % result_name)
        code.putln("PyObject* exc_type = PyErr_Occurred();")
        code.putln("if (exc_type) {")
        code.putln("if (likely(exc_type == PyExc_StopIteration ||"
                   " PyErr_GivenExceptionMatches(exc_type, PyExc_StopIteration))) PyErr_Clear();")
        code.putln("else %s" % code.error_goto(self.pos))
        code.putln("}")
        code.putln("break;")
        code.putln("}")
        code.put_gotref(result_name)
        code.putln("}")

    def free_temps(self, code):
        if self.counter_cname:
            code.funcstate.release_temp(self.counter_cname)
        if self.iter_func_ptr:
            code.funcstate.release_temp(self.iter_func_ptr)
            self.iter_func_ptr = None
        if self.cpp_iterator_cname:
            code.funcstate.release_temp(self.cpp_iterator_cname)
        ExprNode.free_temps(self, code)


class NextNode(AtomicExprNode):
    #  Used as part of for statement implementation.
    #  Implements result = iterator.next()
    #  Created during analyse_types phase.
    #  The iterator is not owned by this node.
    #
    #  iterator   IteratorNode

    def __init__(self, iterator):
        AtomicExprNode.__init__(self, iterator.pos)
        self.iterator = iterator

    def type_dependencies(self, env):
        return self.iterator.type_dependencies(env)

    def infer_type(self, env, iterator_type = None):
        if iterator_type is None:
            iterator_type = self.iterator.infer_type(env)
        if iterator_type.is_ptr or iterator_type.is_array:
            return iterator_type.base_type
        elif iterator_type.is_cpp_class:
            item_type = env.lookup_operator_for_types(self.pos, "*", [iterator_type]).type.return_type
            if item_type.is_reference:
                item_type = item_type.ref_base_type
            if item_type.is_const:
                item_type = item_type.const_base_type
            return item_type
        else:
            # Avoid duplication of complicated logic.
            fake_index_node = IndexNode(
                self.pos,
                base=self.iterator.sequence,
                index=IntNode(self.pos, value='PY_SSIZE_T_MAX',
                              type=PyrexTypes.c_py_ssize_t_type))
            return fake_index_node.infer_type(env)

    def analyse_types(self, env):
        self.type = self.infer_type(env, self.iterator.type)
        self.is_temp = 1
        return self

    def generate_result_code(self, code):
        self.iterator.generate_iter_next_result_code(self.result(), code)


class WithExitCallNode(ExprNode):
    # The __exit__() call of a 'with' statement.  Used in both the
    # except and finally clauses.

    # with_stat  WithStatNode                the surrounding 'with' statement
    # args       TupleNode or ResultStatNode the exception info tuple

    subexprs = ['args']
    test_if_run = True

    def analyse_types(self, env):
        self.args = self.args.analyse_types(env)
        self.type = PyrexTypes.c_bint_type
        self.is_temp = True
        return self

    def generate_evaluation_code(self, code):
        if self.test_if_run:
            # call only if it was not already called (and decref-cleared)
            code.putln("if (%s) {" % self.with_stat.exit_var)

        self.args.generate_evaluation_code(code)
        result_var = code.funcstate.allocate_temp(py_object_type, manage_ref=False)

        code.mark_pos(self.pos)
        code.globalstate.use_utility_code(UtilityCode.load_cached(
            "PyObjectCall", "ObjectHandling.c"))
        code.putln("%s = __Pyx_PyObject_Call(%s, %s, NULL);" % (
            result_var,
            self.with_stat.exit_var,
            self.args.result()))
        code.put_decref_clear(self.with_stat.exit_var, type=py_object_type)
        self.args.generate_disposal_code(code)
        self.args.free_temps(code)

        code.putln(code.error_goto_if_null(result_var, self.pos))
        code.put_gotref(result_var)
        if self.result_is_used:
            self.allocate_temp_result(code)
            code.putln("%s = __Pyx_PyObject_IsTrue(%s);" % (self.result(), result_var))
        code.put_decref_clear(result_var, type=py_object_type)
        if self.result_is_used:
            code.put_error_if_neg(self.pos, self.result())
        code.funcstate.release_temp(result_var)
        if self.test_if_run:
            code.putln("}")


class ExcValueNode(AtomicExprNode):
    #  Node created during analyse_types phase
    #  of an ExceptClauseNode to fetch the current
    #  exception value.

    type = py_object_type

    def __init__(self, pos):
        ExprNode.__init__(self, pos)

    def set_var(self, var):
        self.var = var

    def calculate_result_code(self):
        return self.var

    def generate_result_code(self, code):
        pass

    def analyse_types(self, env):
        return self


class TempNode(ExprNode):
    # Node created during analyse_types phase
    # of some nodes to hold a temporary value.
    #
    # Note: One must call "allocate" and "release" on
    # the node during code generation to get/release the temp.
    # This is because the temp result is often used outside of
    # the regular cycle.

    subexprs = []

    def __init__(self, pos, type, env=None):
        ExprNode.__init__(self, pos)
        self.type = type
        if type.is_pyobject:
            self.result_ctype = py_object_type
        self.is_temp = 1

    def analyse_types(self, env):
        return self

    def analyse_target_declaration(self, env):
        pass

    def generate_result_code(self, code):
        pass

    def allocate(self, code):
        self.temp_cname = code.funcstate.allocate_temp(self.type, manage_ref=True)

    def release(self, code):
        code.funcstate.release_temp(self.temp_cname)
        self.temp_cname = None

    def result(self):
        try:
            return self.temp_cname
        except:
            assert False, "Remember to call allocate/release on TempNode"
            raise

    # Do not participate in normal temp alloc/dealloc:
    def allocate_temp_result(self, code):
        pass

    def release_temp_result(self, code):
        pass

class PyTempNode(TempNode):
    #  TempNode holding a Python value.

    def __init__(self, pos, env):
        TempNode.__init__(self, pos, PyrexTypes.py_object_type, env)

class RawCNameExprNode(ExprNode):
    subexprs = []

    def __init__(self, pos, type=None, cname=None):
        ExprNode.__init__(self, pos, type=type)
        if cname is not None:
            self.cname = cname

    def analyse_types(self, env):
        return self

    def set_cname(self, cname):
        self.cname = cname

    def result(self):
        return self.cname

    def generate_result_code(self, code):
        pass


#-------------------------------------------------------------------
#
#  Parallel nodes (cython.parallel.thread(savailable|id))
#
#-------------------------------------------------------------------

class ParallelThreadsAvailableNode(AtomicExprNode):
    """
    Note: this is disabled and not a valid directive at this moment

    Implements cython.parallel.threadsavailable(). If we are called from the
    sequential part of the application, we need to call omp_get_max_threads(),
    and in the parallel part we can just call omp_get_num_threads()
    """

    type = PyrexTypes.c_int_type

    def analyse_types(self, env):
        self.is_temp = True
        # env.add_include_file("omp.h")
        return self

    def generate_result_code(self, code):
        code.putln("#ifdef _OPENMP")
        code.putln("if (omp_in_parallel()) %s = omp_get_max_threads();" %
                                                            self.temp_code)
        code.putln("else %s = omp_get_num_threads();" % self.temp_code)
        code.putln("#else")
        code.putln("%s = 1;" % self.temp_code)
        code.putln("#endif")

    def result(self):
        return self.temp_code


class ParallelThreadIdNode(AtomicExprNode): #, Nodes.ParallelNode):
    """
    Implements cython.parallel.threadid()
    """

    type = PyrexTypes.c_int_type

    def analyse_types(self, env):
        self.is_temp = True
        # env.add_include_file("omp.h")
        return self

    def generate_result_code(self, code):
        code.putln("#ifdef _OPENMP")
        code.putln("%s = omp_get_thread_num();" % self.temp_code)
        code.putln("#else")
        code.putln("%s = 0;" % self.temp_code)
        code.putln("#endif")

    def result(self):
        return self.temp_code


#-------------------------------------------------------------------
#
#  Trailer nodes
#
#-------------------------------------------------------------------

class IndexNode(ExprNode):
    #  Sequence indexing.
    #
    #  base     ExprNode
    #  index    ExprNode
    #  indices  [ExprNode]
    #  type_indices  [PyrexType]
    #  is_buffer_access boolean Whether this is a buffer access.
    #
    #  indices is used on buffer access, index on non-buffer access.
    #  The former contains a clean list of index parameters, the
    #  latter whatever Python object is needed for index access.
    #
    #  is_fused_index boolean   Whether the index is used to specialize a
    #                           c(p)def function

    subexprs = ['base', 'index', 'indices']
    indices = None
    type_indices = None

    is_subscript = True
    is_fused_index = False

    # Whether we're assigning to a buffer (in that case it needs to be
    # writable)
    writable_needed = False

    # Whether we are indexing or slicing a memoryviewslice
    memslice_index = False
    memslice_slice = False
    is_memslice_copy = False
    memslice_ellipsis_noop = False
    warned_untyped_idx = False
    # set by SingleAssignmentNode after analyse_types()
    is_memslice_scalar_assignment = False

    def __init__(self, pos, index, **kw):
        ExprNode.__init__(self, pos, index=index, **kw)
        self._index = index

    def calculate_constant_result(self):
        self.constant_result = \
            self.base.constant_result[self.index.constant_result]

    def compile_time_value(self, denv):
        base = self.base.compile_time_value(denv)
        index = self.index.compile_time_value(denv)
        try:
            return base[index]
        except Exception, e:
            self.compile_time_value_error(e)

    def is_ephemeral(self):
        return self.base.is_ephemeral()

    def is_simple(self):
        if self.is_buffer_access or self.memslice_index:
            return False
        elif self.memslice_slice:
            return True

        base = self.base
        return (base.is_simple() and self.index.is_simple()
                and base.type and (base.type.is_ptr or base.type.is_array))

    def may_be_none(self):
        base_type = self.base.type
        if base_type:
            if base_type.is_string:
                return False
            if isinstance(self.index, SliceNode):
                # slicing!
                if base_type in (bytes_type, str_type, unicode_type,
                                 basestring_type, list_type, tuple_type):
                    return False
        return ExprNode.may_be_none(self)

    def analyse_target_declaration(self, env):
        pass

    def analyse_as_type(self, env):
        base_type = self.base.analyse_as_type(env)
        if base_type and not base_type.is_pyobject:
            if base_type.is_cpp_class:
                if isinstance(self.index, TupleNode):
                    template_values = self.index.args
                else:
                    template_values = [self.index]
                import Nodes
                type_node = Nodes.TemplatedTypeNode(
                    pos = self.pos,
                    positional_args = template_values,
                    keyword_args = None)
                return type_node.analyse(env, base_type = base_type)
            else:
                index = self.index.compile_time_value(env)
                if index is not None:
                    return PyrexTypes.CArrayType(base_type, int(index))
                error(self.pos, "Array size must be a compile time constant")
        return None

    def type_dependencies(self, env):
        return self.base.type_dependencies(env) + self.index.type_dependencies(env)

    def infer_type(self, env):
        base_type = self.base.infer_type(env)
        if isinstance(self.index, SliceNode):
            # slicing!
            if base_type.is_string:
                # sliced C strings must coerce to Python
                return bytes_type
            elif base_type.is_pyunicode_ptr:
                # sliced Py_UNICODE* strings must coerce to Python
                return unicode_type
            elif base_type in (unicode_type, bytes_type, str_type,
                               bytearray_type, list_type, tuple_type):
                # slicing these returns the same type
                return base_type
            else:
                # TODO: Handle buffers (hopefully without too much redundancy).
                return py_object_type

        index_type = self.index.infer_type(env)
        if index_type and index_type.is_int or isinstance(self.index, IntNode):
            # indexing!
            if base_type is unicode_type:
                # Py_UCS4 will automatically coerce to a unicode string
                # if required, so this is safe.  We only infer Py_UCS4
                # when the index is a C integer type.  Otherwise, we may
                # need to use normal Python item access, in which case
                # it's faster to return the one-char unicode string than
                # to receive it, throw it away, and potentially rebuild it
                # on a subsequent PyObject coercion.
                return PyrexTypes.c_py_ucs4_type
            elif base_type is str_type:
                # always returns str - Py2: bytes, Py3: unicode
                return base_type
            elif base_type is bytearray_type:
                return PyrexTypes.c_uchar_type
            elif isinstance(self.base, BytesNode):
                #if env.global_scope().context.language_level >= 3:
                #    # inferring 'char' can be made to work in Python 3 mode
                #    return PyrexTypes.c_char_type
                # Py2/3 return different types on indexing bytes objects
                return py_object_type
            elif base_type in (tuple_type, list_type):
                # if base is a literal, take a look at its values
                item_type = infer_sequence_item_type(
                    env, self.base, self.index, seq_type=base_type)
                if item_type is not None:
                    return item_type
            elif base_type.is_ptr or base_type.is_array:
                return base_type.base_type

        if base_type.is_cpp_class:
            class FakeOperand:
                def __init__(self, **kwds):
                    self.__dict__.update(kwds)
            operands = [
                FakeOperand(pos=self.pos, type=base_type),
                FakeOperand(pos=self.pos, type=index_type),
            ]
            index_func = env.lookup_operator('[]', operands)
            if index_func is not None:
                return index_func.type.return_type

        # may be slicing or indexing, we don't know
        if base_type in (unicode_type, str_type):
            # these types always returns their own type on Python indexing/slicing
            return base_type
        else:
            # TODO: Handle buffers (hopefully without too much redundancy).
            return py_object_type

    def analyse_types(self, env):
        return self.analyse_base_and_index_types(env, getting=True)

    def analyse_target_types(self, env):
        node = self.analyse_base_and_index_types(env, setting=True)
        if node.type.is_const:
            error(self.pos, "Assignment to const dereference")
        if not node.is_lvalue():
            error(self.pos, "Assignment to non-lvalue of type '%s'" % node.type)
        return node

    def analyse_base_and_index_types(self, env, getting=False, setting=False,
                                     analyse_base=True):
        # Note: This might be cleaned up by having IndexNode
        # parsed in a saner way and only construct the tuple if
        # needed.

        # Note that this function must leave IndexNode in a cloneable state.
        # For buffers, self.index is packed out on the initial analysis, and
        # when cloning self.indices is copied.
        self.is_buffer_access = False

        # a[...] = b
        self.is_memslice_copy = False
        # incomplete indexing, Ellipsis indexing or slicing
        self.memslice_slice = False
        # integer indexing
        self.memslice_index = False

        if analyse_base:
            self.base = self.base.analyse_types(env)

        if self.base.type.is_error:
            # Do not visit child tree if base is undeclared to avoid confusing
            # error messages
            self.type = PyrexTypes.error_type
            return self

        is_slice = isinstance(self.index, SliceNode)

        if not env.directives['wraparound']:
            if is_slice:
                check_negative_indices(self.index.start, self.index.stop)
            else:
                check_negative_indices(self.index)

        # Potentially overflowing index value.
        if not is_slice and isinstance(self.index, IntNode) and Utils.long_literal(self.index.value):
            self.index = self.index.coerce_to_pyobject(env)

        is_memslice = self.base.type.is_memoryviewslice

        # Handle the case where base is a literal char* (and we expect a string, not an int)
        if not is_memslice and (isinstance(self.base, BytesNode) or is_slice):
            if self.base.type.is_string or not (self.base.type.is_ptr or self.base.type.is_array):
                self.base = self.base.coerce_to_pyobject(env)

        skip_child_analysis = False
        buffer_access = False

        if self.indices:
            indices = self.indices
        elif isinstance(self.index, TupleNode):
            indices = self.index.args
        else:
            indices = [self.index]

        if (is_memslice and not self.indices and
                isinstance(self.index, EllipsisNode)):
            # Memoryviewslice copying
            self.is_memslice_copy = True

        elif is_memslice:
            # memoryviewslice indexing or slicing
            import MemoryView

            skip_child_analysis = True
            newaxes = [newaxis for newaxis in indices if newaxis.is_none]
            have_slices, indices = MemoryView.unellipsify(indices,
                                                          newaxes,
                                                          self.base.type.ndim)

            self.memslice_index = (not newaxes and
                                   len(indices) == self.base.type.ndim)
            axes = []

            index_type = PyrexTypes.c_py_ssize_t_type
            new_indices = []

            if len(indices) - len(newaxes) > self.base.type.ndim:
                self.type = error_type
                error(indices[self.base.type.ndim].pos,
                      "Too many indices specified for type %s" %
                      self.base.type)
                return self

            axis_idx = 0
            for i, index in enumerate(indices[:]):
                index = index.analyse_types(env)
                if not index.is_none:
                    access, packing = self.base.type.axes[axis_idx]
                    axis_idx += 1

                if isinstance(index, SliceNode):
                    self.memslice_slice = True
                    if index.step.is_none:
                        axes.append((access, packing))
                    else:
                        axes.append((access, 'strided'))

                    # Coerce start, stop and step to temps of the right type
                    for attr in ('start', 'stop', 'step'):
                        value = getattr(index, attr)
                        if not value.is_none:
                            value = value.coerce_to(index_type, env)
                            #value = value.coerce_to_temp(env)
                            setattr(index, attr, value)
                            new_indices.append(value)

                elif index.is_none:
                    self.memslice_slice = True
                    new_indices.append(index)
                    axes.append(('direct', 'strided'))

                elif index.type.is_int or index.type.is_pyobject:
                    if index.type.is_pyobject and not self.warned_untyped_idx:
                        warning(index.pos, "Index should be typed for more "
                                           "efficient access", level=2)
                        IndexNode.warned_untyped_idx = True

                    self.memslice_index = True
                    index = index.coerce_to(index_type, env)
                    indices[i] = index
                    new_indices.append(index)

                else:
                    self.type = error_type
                    error(index.pos, "Invalid index for memoryview specified")
                    return self

            self.memslice_index = self.memslice_index and not self.memslice_slice
            self.original_indices = indices
            # All indices with all start/stop/step for slices.
            # We need to keep this around
            self.indices = new_indices
            self.env = env

        elif self.base.type.is_buffer:
            # Buffer indexing
            if len(indices) == self.base.type.ndim:
                buffer_access = True
                skip_child_analysis = True
                for x in indices:
                    x = x.analyse_types(env)
                    if not x.type.is_int:
                        buffer_access = False

            if buffer_access and not self.base.type.is_memoryviewslice:
                assert hasattr(self.base, "entry") # Must be a NameNode-like node

        # On cloning, indices is cloned. Otherwise, unpack index into indices
        assert not (buffer_access and isinstance(self.index, CloneNode))

        self.nogil = env.nogil

        if buffer_access or self.memslice_index:
            #if self.base.type.is_memoryviewslice and not self.base.is_name:
            #    self.base = self.base.coerce_to_temp(env)
            self.base = self.base.coerce_to_simple(env)

            self.indices = indices
            self.index = None
            self.type = self.base.type.dtype
            self.is_buffer_access = True
            self.buffer_type = self.base.type #self.base.entry.type

            if getting and self.type.is_pyobject:
                self.is_temp = True

            if setting and self.base.type.is_memoryviewslice:
                self.base.type.writable_needed = True
            elif setting:
                if not self.base.entry.type.writable:
                    error(self.pos, "Writing to readonly buffer")
                else:
                    self.writable_needed = True
                    if self.base.type.is_buffer:
                        self.base.entry.buffer_aux.writable_needed = True

        elif self.is_memslice_copy:
            self.type = self.base.type
            if getting:
                self.memslice_ellipsis_noop = True
            else:
                self.memslice_broadcast = True

        elif self.memslice_slice:
            self.index = None
            self.is_temp = True
            self.use_managed_ref = True

            if not MemoryView.validate_axes(self.pos, axes):
                self.type = error_type
                return self

            self.type = PyrexTypes.MemoryViewSliceType(
                            self.base.type.dtype, axes)

            if (self.base.type.is_memoryviewslice and not
                    self.base.is_name and not
                    self.base.result_in_temp()):
                self.base = self.base.coerce_to_temp(env)

            if setting:
                self.memslice_broadcast = True

        else:
            base_type = self.base.type

            if not base_type.is_cfunction:
                if isinstance(self.index, TupleNode):
                    self.index = self.index.analyse_types(
                        env, skip_children=skip_child_analysis)
                elif not skip_child_analysis:
                    self.index = self.index.analyse_types(env)
                self.original_index_type = self.index.type

            if base_type.is_unicode_char:
                # we infer Py_UNICODE/Py_UCS4 for unicode strings in some
                # cases, but indexing must still work for them
                if setting:
                    warning(self.pos, "cannot assign to Unicode string index", level=1)
                elif self.index.constant_result in (0, -1):
                    # uchar[0] => uchar
                    return self.base
                self.base = self.base.coerce_to_pyobject(env)
                base_type = self.base.type
            if base_type.is_pyobject:
                if self.index.type.is_int and base_type is not dict_type:
                    if (getting
                        and (base_type in (list_type, tuple_type, bytearray_type))
                        and (not self.index.type.signed
                             or not env.directives['wraparound']
                             or (isinstance(self.index, IntNode) and
                                 self.index.has_constant_result() and self.index.constant_result >= 0))
                        and not env.directives['boundscheck']):
                        self.is_temp = 0
                    else:
                        self.is_temp = 1
                    self.index = self.index.coerce_to(PyrexTypes.c_py_ssize_t_type, env).coerce_to_simple(env)
                    self.original_index_type.create_to_py_utility_code(env)
                else:
                    self.index = self.index.coerce_to_pyobject(env)
                    self.is_temp = 1
                if self.index.type.is_int and base_type is unicode_type:
                    # Py_UNICODE/Py_UCS4 will automatically coerce to a unicode string
                    # if required, so this is fast and safe
                    self.type = PyrexTypes.c_py_ucs4_type
                elif self.index.type.is_int and base_type is bytearray_type:
                    if setting:
                        self.type = PyrexTypes.c_uchar_type
                    else:
                        # not using 'uchar' to enable fast and safe error reporting as '-1'
                        self.type = PyrexTypes.c_int_type
                elif is_slice and base_type in (bytes_type, str_type, unicode_type, list_type, tuple_type):
                    self.type = base_type
                else:
                    item_type = None
                    if base_type in (list_type, tuple_type) and self.index.type.is_int:
                        item_type = infer_sequence_item_type(
                            env, self.base, self.index, seq_type=base_type)
                    if item_type is None:
                        item_type = py_object_type
                    self.type = item_type
                    if base_type in (list_type, tuple_type, dict_type):
                        # do the None check explicitly (not in a helper) to allow optimising it away
                        self.base = self.base.as_none_safe_node("'NoneType' object is not subscriptable")
            else:
                if base_type.is_ptr or base_type.is_array:
                    self.type = base_type.base_type
                    if is_slice:
                        self.type = base_type
                    elif self.index.type.is_pyobject:
                        self.index = self.index.coerce_to(
                            PyrexTypes.c_py_ssize_t_type, env)
                    elif not self.index.type.is_int:
                        error(self.pos,
                              "Invalid index type '%s'" %
                              self.index.type)
                elif base_type.is_cpp_class:
                    function = env.lookup_operator("[]", [self.base, self.index])
                    if function is None:
                        error(self.pos, "Indexing '%s' not supported for index type '%s'" % (base_type, self.index.type))
                        self.type = PyrexTypes.error_type
                        self.result_code = "<error>"
                        return self
                    func_type = function.type
                    if func_type.is_ptr:
                        func_type = func_type.base_type
                    self.index = self.index.coerce_to(func_type.args[0].type, env)
                    self.type = func_type.return_type
                    if setting and not func_type.return_type.is_reference:
                        error(self.pos, "Can't set non-reference result '%s'" % self.type)
                elif base_type.is_cfunction:
                    if base_type.is_fused:
                        self.parse_indexed_fused_cdef(env)
                    else:
                        self.type_indices = self.parse_index_as_types(env)
                        if base_type.templates is None:
                            error(self.pos, "Can only parameterize template functions.")
                        elif len(base_type.templates) != len(self.type_indices):
                            error(self.pos, "Wrong number of template arguments: expected %s, got %s" % (
                                    (len(base_type.templates), len(self.type_indices))))
                        self.type = base_type.specialize(dict(zip(base_type.templates, self.type_indices)))
                else:
                    error(self.pos,
                          "Attempting to index non-array type '%s'" %
                          base_type)
                    self.type = PyrexTypes.error_type

        self.wrap_in_nonecheck_node(env, getting)
        return self

    def wrap_in_nonecheck_node(self, env, getting):
        if not env.directives['nonecheck'] or not self.base.may_be_none():
            return

        if self.base.type.is_memoryviewslice:
            if self.is_memslice_copy and not getting:
                msg = "Cannot assign to None memoryview slice"
            elif self.memslice_slice:
                msg = "Cannot slice None memoryview slice"
            else:
                msg = "Cannot index None memoryview slice"
        else:
            msg = "'NoneType' object is not subscriptable"

        self.base = self.base.as_none_safe_node(msg)

    def parse_index_as_types(self, env, required=True):
        if isinstance(self.index, TupleNode):
            indices = self.index.args
        else:
            indices = [self.index]
        type_indices = []
        for index in indices:
            type_indices.append(index.analyse_as_type(env))
            if type_indices[-1] is None:
                if required:
                    error(index.pos, "not parsable as a type")
                return None
        return type_indices

    def parse_indexed_fused_cdef(self, env):
        """
        Interpret fused_cdef_func[specific_type1, ...]

        Note that if this method is called, we are an indexed cdef function
        with fused argument types, and this IndexNode will be replaced by the
        NameNode with specific entry just after analysis of expressions by
        AnalyseExpressionsTransform.
        """
        self.type = PyrexTypes.error_type

        self.is_fused_index = True

        base_type = self.base.type
        specific_types = []
        positions = []

        if self.index.is_name or self.index.is_attribute:
            positions.append(self.index.pos)
        elif isinstance(self.index, TupleNode):
            for arg in self.index.args:
                positions.append(arg.pos)
        specific_types = self.parse_index_as_types(env, required=False)

        if specific_types is None:
            self.index = self.index.analyse_types(env)

            if not self.base.entry.as_variable:
                error(self.pos, "Can only index fused functions with types")
            else:
                # A cpdef function indexed with Python objects
                self.base.entry = self.entry = self.base.entry.as_variable
                self.base.type = self.type = self.entry.type

                self.base.is_temp = True
                self.is_temp = True

                self.entry.used = True

            self.is_fused_index = False
            return

        for i, type in enumerate(specific_types):
            specific_types[i] = type.specialize_fused(env)

        fused_types = base_type.get_fused_types()
        if len(specific_types) > len(fused_types):
            return error(self.pos, "Too many types specified")
        elif len(specific_types) < len(fused_types):
            t = fused_types[len(specific_types)]
            return error(self.pos, "Not enough types specified to specialize "
                                   "the function, %s is still fused" % t)

        # See if our index types form valid specializations
        for pos, specific_type, fused_type in zip(positions,
                                                  specific_types,
                                                  fused_types):
            if not Utils.any([specific_type.same_as(t)
                                  for t in fused_type.types]):
                return error(pos, "Type not in fused type")

            if specific_type is None or specific_type.is_error:
                return

        fused_to_specific = dict(zip(fused_types, specific_types))
        type = base_type.specialize(fused_to_specific)

        if type.is_fused:
            # Only partially specific, this is invalid
            error(self.pos,
                  "Index operation makes function only partially specific")
        else:
            # Fully specific, find the signature with the specialized entry
            for signature in self.base.type.get_all_specialized_function_types():
                if type.same_as(signature):
                    self.type = signature

                    if self.base.is_attribute:
                        # Pretend to be a normal attribute, for cdef extension
                        # methods
                        self.entry = signature.entry
                        self.is_attribute = True
                        self.obj = self.base.obj

                    self.type.entry.used = True
                    self.base.type = signature
                    self.base.entry = signature.entry

                    break
            else:
                # This is a bug
                raise InternalError("Couldn't find the right signature")

    gil_message = "Indexing Python object"

    def nogil_check(self, env):
        if self.is_buffer_access or self.memslice_index or self.memslice_slice:
            if not self.memslice_slice and env.directives['boundscheck']:
                # error(self.pos, "Cannot check buffer index bounds without gil; "
                #                 "use boundscheck(False) directive")
                warning(self.pos, "Use boundscheck(False) for faster access",
                        level=1)
            if self.type.is_pyobject:
                error(self.pos, "Cannot access buffer with object dtype without gil")
                return
        super(IndexNode, self).nogil_check(env)


    def check_const_addr(self):
        return self.base.check_const_addr() and self.index.check_const()

    def is_lvalue(self):
        # NOTE: references currently have both is_reference and is_ptr
        # set.  Since pointers and references have different lvalue
        # rules, we must be careful to separate the two.
        if self.type.is_reference:
            if self.type.ref_base_type.is_array:
                # fixed-sized arrays aren't l-values
                return False
        elif self.type.is_ptr:
            # non-const pointers can always be reassigned
            return True
        elif self.type.is_array:
            # fixed-sized arrays aren't l-values
            return False
        # Just about everything else returned by the index operator
        # can be an lvalue.
        return True

    def calculate_result_code(self):
        if self.is_buffer_access:
            return "(*%s)" % self.buffer_ptr_code
        elif self.is_memslice_copy:
            return self.base.result()
        elif self.base.type in (list_type, tuple_type, bytearray_type):
            if self.base.type is list_type:
                index_code = "PyList_GET_ITEM(%s, %s)"
            elif self.base.type is tuple_type:
                index_code = "PyTuple_GET_ITEM(%s, %s)"
            elif self.base.type is bytearray_type:
                index_code = "((unsigned char)(PyByteArray_AS_STRING(%s)[%s]))"
            else:
                assert False, "unexpected base type in indexing: %s" % self.base.type
        elif self.base.type.is_cfunction:
            return "%s<%s>" % (
                self.base.result(),
                ",".join([param.declaration_code("") for param in self.type_indices]))
        else:
            if (self.type.is_ptr or self.type.is_array) and self.type == self.base.type:
                error(self.pos, "Invalid use of pointer slice")
                return
            index_code = "(%s[%s])"
        return index_code % (self.base.result(), self.index.result())

    def extra_index_params(self, code):
        if self.index.type.is_int:
            is_list = self.base.type is list_type
            wraparound = (
                bool(code.globalstate.directives['wraparound']) and
                self.original_index_type.signed and
                not (isinstance(self.index.constant_result, (int, long))
                     and self.index.constant_result >= 0))
            boundscheck = bool(code.globalstate.directives['boundscheck'])
            return ", %s, %d, %s, %d, %d, %d" % (
                self.original_index_type.declaration_code(""),
                self.original_index_type.signed and 1 or 0,
                self.original_index_type.to_py_function,
                is_list, wraparound, boundscheck)
        else:
            return ""

    def generate_subexpr_evaluation_code(self, code):
        self.base.generate_evaluation_code(code)
        if self.type_indices is not None:
            pass
        elif self.indices is None:
            self.index.generate_evaluation_code(code)
        else:
            for i in self.indices:
                i.generate_evaluation_code(code)

    def generate_subexpr_disposal_code(self, code):
        self.base.generate_disposal_code(code)
        if self.type_indices is not None:
            pass
        elif self.indices is None:
            self.index.generate_disposal_code(code)
        else:
            for i in self.indices:
                i.generate_disposal_code(code)

    def free_subexpr_temps(self, code):
        self.base.free_temps(code)
        if self.indices is None:
            self.index.free_temps(code)
        else:
            for i in self.indices:
                i.free_temps(code)

    def generate_result_code(self, code):
        if self.is_buffer_access or self.memslice_index:
            buffer_entry, self.buffer_ptr_code = self.buffer_lookup_code(code)
            if self.type.is_pyobject:
                # is_temp is True, so must pull out value and incref it.
                # NOTE: object temporary results for nodes are declared
                #       as PyObject *, so we need a cast
                code.putln("%s = (PyObject *) *%s;" % (self.temp_code,
                                                       self.buffer_ptr_code))
                code.putln("__Pyx_INCREF((PyObject*)%s);" % self.temp_code)

        elif self.memslice_slice:
            self.put_memoryviewslice_slice_code(code)

        elif self.is_temp:
            if self.type.is_pyobject:
                error_value = 'NULL'
                if self.index.type.is_int:
                    if self.base.type is list_type:
                        function = "__Pyx_GetItemInt_List"
                    elif self.base.type is tuple_type:
                        function = "__Pyx_GetItemInt_Tuple"
                    else:
                        function = "__Pyx_GetItemInt"
                    code.globalstate.use_utility_code(
                        TempitaUtilityCode.load_cached("GetItemInt", "ObjectHandling.c"))
                else:
                    if self.base.type is dict_type:
                        function = "__Pyx_PyDict_GetItem"
                        code.globalstate.use_utility_code(
                            UtilityCode.load_cached("DictGetItem", "ObjectHandling.c"))
                    else:
                        function = "PyObject_GetItem"
            elif self.type.is_unicode_char and self.base.type is unicode_type:
                assert self.index.type.is_int
                function = "__Pyx_GetItemInt_Unicode"
                error_value = '(Py_UCS4)-1'
                code.globalstate.use_utility_code(
                    UtilityCode.load_cached("GetItemIntUnicode", "StringTools.c"))
            elif self.base.type is bytearray_type:
                assert self.index.type.is_int
                assert self.type.is_int
                function = "__Pyx_GetItemInt_ByteArray"
                error_value = '-1'
                code.globalstate.use_utility_code(
                    UtilityCode.load_cached("GetItemIntByteArray", "StringTools.c"))
            else:
                assert False, "unexpected type %s and base type %s for indexing" % (
                    self.type, self.base.type)

            if self.index.type.is_int:
                index_code = self.index.result()
            else:
                index_code = self.index.py_result()

            code.putln(
                "%s = %s(%s, %s%s); if (unlikely(%s == %s)) %s;" % (
                    self.result(),
                    function,
                    self.base.py_result(),
                    index_code,
                    self.extra_index_params(code),
                    self.result(),
                    error_value,
                    code.error_goto(self.pos)))
            if self.type.is_pyobject:
                code.put_gotref(self.py_result())

    def generate_setitem_code(self, value_code, code):
        if self.index.type.is_int:
            if self.base.type is bytearray_type:
                code.globalstate.use_utility_code(
                    UtilityCode.load_cached("SetItemIntByteArray", "StringTools.c"))
                function = "__Pyx_SetItemInt_ByteArray"
            else:
                code.globalstate.use_utility_code(
                    UtilityCode.load_cached("SetItemInt", "ObjectHandling.c"))
                function = "__Pyx_SetItemInt"
            index_code = self.index.result()
        else:
            index_code = self.index.py_result()
            if self.base.type is dict_type:
                function = "PyDict_SetItem"
            # It would seem that we could specialized lists/tuples, but that
            # shouldn't happen here.
            # Both PyList_SetItem() and PyTuple_SetItem() take a Py_ssize_t as
            # index instead of an object, and bad conversion here would give
            # the wrong exception. Also, tuples are supposed to be immutable,
            # and raise a TypeError when trying to set their entries
            # (PyTuple_SetItem() is for creating new tuples from scratch).
            else:
                function = "PyObject_SetItem"
        code.putln(
            "if (unlikely(%s(%s, %s, %s%s) < 0)) %s" % (
                function,
                self.base.py_result(),
                index_code,
                value_code,
                self.extra_index_params(code),
                code.error_goto(self.pos)))

    def generate_buffer_setitem_code(self, rhs, code, op=""):
        # Used from generate_assignment_code and InPlaceAssignmentNode
        buffer_entry, ptrexpr = self.buffer_lookup_code(code)

        if self.buffer_type.dtype.is_pyobject:
            # Must manage refcounts. Decref what is already there
            # and incref what we put in.
            ptr = code.funcstate.allocate_temp(buffer_entry.buf_ptr_type,
                                               manage_ref=False)
            rhs_code = rhs.result()
            code.putln("%s = %s;" % (ptr, ptrexpr))
            code.put_gotref("*%s" % ptr)
            code.putln("__Pyx_INCREF(%s); __Pyx_DECREF(*%s);" % (
                rhs_code, ptr))
            code.putln("*%s %s= %s;" % (ptr, op, rhs_code))
            code.put_giveref("*%s" % ptr)
            code.funcstate.release_temp(ptr)
        else:
            # Simple case
            code.putln("*%s %s= %s;" % (ptrexpr, op, rhs.result()))

    def generate_assignment_code(self, rhs, code):
        generate_evaluation_code = (self.is_memslice_scalar_assignment or
                                    self.memslice_slice)
        if generate_evaluation_code:
            self.generate_evaluation_code(code)
        else:
            self.generate_subexpr_evaluation_code(code)

        if self.is_buffer_access or self.memslice_index:
            self.generate_buffer_setitem_code(rhs, code)
        elif self.is_memslice_scalar_assignment:
            self.generate_memoryviewslice_assign_scalar_code(rhs, code)
        elif self.memslice_slice or self.is_memslice_copy:
            self.generate_memoryviewslice_setslice_code(rhs, code)
        elif self.type.is_pyobject:
            self.generate_setitem_code(rhs.py_result(), code)
        elif self.base.type is bytearray_type:
            value_code = self._check_byte_value(code, rhs)
            self.generate_setitem_code(value_code, code)
        else:
            code.putln(
                "%s = %s;" % (
                    self.result(), rhs.result()))

        if generate_evaluation_code:
            self.generate_disposal_code(code)
        else:
            self.generate_subexpr_disposal_code(code)
            self.free_subexpr_temps(code)

        rhs.generate_disposal_code(code)
        rhs.free_temps(code)

    def _check_byte_value(self, code, rhs):
        # TODO: should we do this generally on downcasts, or just here?
        assert rhs.type.is_int, repr(rhs.type)
        value_code = rhs.result()
        if rhs.has_constant_result():
            if 0 <= rhs.constant_result < 256:
                return value_code
            needs_cast = True  # make at least the C compiler happy
            warning(rhs.pos,
                    "value outside of range(0, 256)"
                    " when assigning to byte: %s" % rhs.constant_result,
                    level=1)
        else:
            needs_cast = rhs.type != PyrexTypes.c_uchar_type

        if not self.nogil:
            conditions = []
            if rhs.is_literal or rhs.type.signed:
                conditions.append('%s < 0' % value_code)
            if (rhs.is_literal or not
                    (rhs.is_temp and rhs.type in (
                        PyrexTypes.c_uchar_type, PyrexTypes.c_char_type,
                        PyrexTypes.c_schar_type))):
                conditions.append('%s > 255' % value_code)
            if conditions:
                code.putln("if (unlikely(%s)) {" % ' || '.join(conditions))
                code.putln(
                    'PyErr_SetString(PyExc_ValueError,'
                    ' "byte must be in range(0, 256)"); %s' %
                    code.error_goto(self.pos))
                code.putln("}")

        if needs_cast:
            value_code = '((unsigned char)%s)' % value_code
        return value_code

    def generate_deletion_code(self, code, ignore_nonexisting=False):
        self.generate_subexpr_evaluation_code(code)
        #if self.type.is_pyobject:
        if self.index.type.is_int:
            function = "__Pyx_DelItemInt"
            index_code = self.index.result()
            code.globalstate.use_utility_code(
                UtilityCode.load_cached("DelItemInt", "ObjectHandling.c"))
        else:
            index_code = self.index.py_result()
            if self.base.type is dict_type:
                function = "PyDict_DelItem"
            else:
                function = "PyObject_DelItem"
        code.putln(
            "if (%s(%s, %s%s) < 0) %s" % (
                function,
                self.base.py_result(),
                index_code,
                self.extra_index_params(code),
                code.error_goto(self.pos)))
        self.generate_subexpr_disposal_code(code)
        self.free_subexpr_temps(code)

    def buffer_entry(self):
        import Buffer, MemoryView

        base = self.base
        if self.base.is_nonecheck:
            base = base.arg

        if base.is_name:
            entry = base.entry
        else:
            # SimpleCallNode is_simple is not consistent with coerce_to_simple
            assert base.is_simple() or base.is_temp
            cname = base.result()
            entry = Symtab.Entry(cname, cname, self.base.type, self.base.pos)

        if entry.type.is_buffer:
            buffer_entry = Buffer.BufferEntry(entry)
        else:
            buffer_entry = MemoryView.MemoryViewSliceBufferEntry(entry)

        return buffer_entry

    def buffer_lookup_code(self, code):
        "ndarray[1, 2, 3] and memslice[1, 2, 3]"
        # Assign indices to temps
        index_temps = [code.funcstate.allocate_temp(i.type, manage_ref=False)
                           for i in self.indices]

        for temp, index in zip(index_temps, self.indices):
            code.putln("%s = %s;" % (temp, index.result()))

        # Generate buffer access code using these temps
        import Buffer
        buffer_entry = self.buffer_entry()
        if buffer_entry.type.is_buffer:
            negative_indices = buffer_entry.type.negative_indices
        else:
            negative_indices = Buffer.buffer_defaults['negative_indices']

        return buffer_entry, Buffer.put_buffer_lookup_code(
               entry=buffer_entry,
               index_signeds=[i.type.signed for i in self.indices],
               index_cnames=index_temps,
               directives=code.globalstate.directives,
               pos=self.pos, code=code,
               negative_indices=negative_indices,
               in_nogil_context=self.in_nogil_context)

    def put_memoryviewslice_slice_code(self, code):
        "memslice[:]"
        buffer_entry = self.buffer_entry()
        have_gil = not self.in_nogil_context

        if sys.version_info < (3,):
            def next_(it):
                return it.next()
        else:
            next_ = next

        have_slices = False
        it = iter(self.indices)
        for index in self.original_indices:
            is_slice = isinstance(index, SliceNode)
            have_slices = have_slices or is_slice
            if is_slice:
                if not index.start.is_none:
                    index.start = next_(it)
                if not index.stop.is_none:
                    index.stop = next_(it)
                if not index.step.is_none:
                    index.step = next_(it)
            else:
                next_(it)

        assert not list(it)

        buffer_entry.generate_buffer_slice_code(code, self.original_indices,
                                                self.result(),
                                                have_gil=have_gil,
                                                have_slices=have_slices,
                                                directives=code.globalstate.directives)

    def generate_memoryviewslice_setslice_code(self, rhs, code):
        "memslice1[...] = memslice2 or memslice1[:] = memslice2"
        import MemoryView
        MemoryView.copy_broadcast_memview_src_to_dst(rhs, self, code)

    def generate_memoryviewslice_assign_scalar_code(self, rhs, code):
        "memslice1[...] = 0.0 or memslice1[:] = 0.0"
        import MemoryView
        MemoryView.assign_scalar(self, rhs, code)


class SliceIndexNode(ExprNode):
    #  2-element slice indexing
    #
    #  base      ExprNode
    #  start     ExprNode or None
    #  stop      ExprNode or None
    #  slice     ExprNode or None   constant slice object

    subexprs = ['base', 'start', 'stop', 'slice']

    slice = None

    def infer_type(self, env):
        base_type = self.base.infer_type(env)
        if base_type.is_string or base_type.is_cpp_class:
            return bytes_type
        elif base_type.is_pyunicode_ptr:
            return unicode_type
        elif base_type in (bytes_type, str_type, unicode_type,
                           basestring_type, list_type, tuple_type):
            return base_type
        elif base_type.is_ptr or base_type.is_array:
            return PyrexTypes.c_array_type(base_type.base_type, None)
        return py_object_type

    def may_be_none(self):
        base_type = self.base.type
        if base_type:
            if base_type.is_string:
                return False
            if base_type in (bytes_type, str_type, unicode_type,
                             basestring_type, list_type, tuple_type):
                return False
        return ExprNode.may_be_none(self)

    def calculate_constant_result(self):
        if self.start is None:
            start = None
        else:
            start = self.start.constant_result
        if self.stop is None:
            stop = None
        else:
            stop = self.stop.constant_result
        self.constant_result = self.base.constant_result[start:stop]

    def compile_time_value(self, denv):
        base = self.base.compile_time_value(denv)
        if self.start is None:
            start = 0
        else:
            start = self.start.compile_time_value(denv)
        if self.stop is None:
            stop = None
        else:
            stop = self.stop.compile_time_value(denv)
        try:
            return base[start:stop]
        except Exception, e:
            self.compile_time_value_error(e)

    def analyse_target_declaration(self, env):
        pass

    def analyse_target_types(self, env):
        node = self.analyse_types(env, getting=False)
        # when assigning, we must accept any Python type
        if node.type.is_pyobject:
            node.type = py_object_type
        return node

    def analyse_types(self, env, getting=True):
        self.base = self.base.analyse_types(env)

        if self.base.type.is_memoryviewslice:
            none_node = NoneNode(self.pos)
            index = SliceNode(self.pos,
                              start=self.start or none_node,
                              stop=self.stop or none_node,
                              step=none_node)
            index_node = IndexNode(self.pos, index, base=self.base)
            return index_node.analyse_base_and_index_types(
                env, getting=getting, setting=not getting,
                analyse_base=False)

        if self.start:
            self.start = self.start.analyse_types(env)
        if self.stop:
            self.stop = self.stop.analyse_types(env)

        if not env.directives['wraparound']:
            check_negative_indices(self.start, self.stop)

        base_type = self.base.type
        if base_type.is_string or base_type.is_cpp_string:
            self.type = default_str_type(env)
        elif base_type.is_pyunicode_ptr:
            self.type = unicode_type
        elif base_type.is_ptr:
            self.type = base_type
        elif base_type.is_array:
            # we need a ptr type here instead of an array type, as
            # array types can result in invalid type casts in the C
            # code
            self.type = PyrexTypes.CPtrType(base_type.base_type)
        else:
            self.base = self.base.coerce_to_pyobject(env)
            self.type = py_object_type
        if base_type.is_builtin_type:
            # slicing builtin types returns something of the same type
            self.type = base_type
            self.base = self.base.as_none_safe_node("'NoneType' object is not subscriptable")

        if self.type is py_object_type:
            if (not self.start or self.start.is_literal) and \
                    (not self.stop or self.stop.is_literal):
                # cache the constant slice object, in case we need it
                none_node = NoneNode(self.pos)
                self.slice = SliceNode(
                    self.pos,
                    start=copy.deepcopy(self.start or none_node),
                    stop=copy.deepcopy(self.stop or none_node),
                    step=none_node
                ).analyse_types(env)
        else:
            c_int = PyrexTypes.c_py_ssize_t_type
            if self.start:
                self.start = self.start.coerce_to(c_int, env)
            if self.stop:
                self.stop = self.stop.coerce_to(c_int, env)
        self.is_temp = 1
        return self

    nogil_check = Node.gil_error
    gil_message = "Slicing Python object"

    get_slice_utility_code = TempitaUtilityCode.load(
        "SliceObject", "ObjectHandling.c", context={'access': 'Get'})

    set_slice_utility_code = TempitaUtilityCode.load(
        "SliceObject", "ObjectHandling.c", context={'access': 'Set'})

    def coerce_to(self, dst_type, env):
        if ((self.base.type.is_string or self.base.type.is_cpp_string)
                and dst_type in (bytes_type, bytearray_type, str_type, unicode_type)):
            if (dst_type not in (bytes_type, bytearray_type)
                    and not env.directives['c_string_encoding']):
                error(self.pos,
                    "default encoding required for conversion from '%s' to '%s'" %
                    (self.base.type, dst_type))
            self.type = dst_type
        return super(SliceIndexNode, self).coerce_to(dst_type, env)

    def generate_result_code(self, code):
        if not self.type.is_pyobject:
            error(self.pos,
                  "Slicing is not currently supported for '%s'." % self.type)
            return

        base_result = self.base.result()
        result = self.result()
        start_code = self.start_code()
        stop_code = self.stop_code()
        if self.base.type.is_string:
            base_result = self.base.result()
            if self.base.type != PyrexTypes.c_char_ptr_type:
                base_result = '((const char*)%s)' % base_result
            if self.type is bytearray_type:
                type_name = 'ByteArray'
            else:
                type_name = self.type.name.title()
            if self.stop is None:
                code.putln(
                    "%s = __Pyx_Py%s_FromString(%s + %s); %s" % (
                        result,
                        type_name,
                        base_result,
                        start_code,
                        code.error_goto_if_null(result, self.pos)))
            else:
                code.putln(
                    "%s = __Pyx_Py%s_FromStringAndSize(%s + %s, %s - %s); %s" % (
                        result,
                        type_name,
                        base_result,
                        start_code,
                        stop_code,
                        start_code,
                        code.error_goto_if_null(result, self.pos)))
        elif self.base.type.is_pyunicode_ptr:
            base_result = self.base.result()
            if self.base.type != PyrexTypes.c_py_unicode_ptr_type:
                base_result = '((const Py_UNICODE*)%s)' % base_result
            if self.stop is None:
                code.putln(
                    "%s = __Pyx_PyUnicode_FromUnicode(%s + %s); %s" % (
                        result,
                        base_result,
                        start_code,
                        code.error_goto_if_null(result, self.pos)))
            else:
                code.putln(
                    "%s = __Pyx_PyUnicode_FromUnicodeAndLength(%s + %s, %s - %s); %s" % (
                        result,
                        base_result,
                        start_code,
                        stop_code,
                        start_code,
                        code.error_goto_if_null(result, self.pos)))

        elif self.base.type is unicode_type:
            code.globalstate.use_utility_code(
                          UtilityCode.load_cached("PyUnicode_Substring", "StringTools.c"))
            code.putln(
                "%s = __Pyx_PyUnicode_Substring(%s, %s, %s); %s" % (
                    result,
                    base_result,
                    start_code,
                    stop_code,
                    code.error_goto_if_null(result, self.pos)))
        elif self.type is py_object_type:
            code.globalstate.use_utility_code(self.get_slice_utility_code)
            (has_c_start, has_c_stop, c_start, c_stop,
             py_start, py_stop, py_slice) = self.get_slice_config()
            code.putln(
                "%s = __Pyx_PyObject_GetSlice(%s, %s, %s, %s, %s, %s, %d, %d, %d); %s" % (
                    result,
                    self.base.py_result(),
                    c_start, c_stop,
                    py_start, py_stop, py_slice,
                    has_c_start, has_c_stop,
                    bool(code.globalstate.directives['wraparound']),
                    code.error_goto_if_null(result, self.pos)))
        else:
            if self.base.type is list_type:
                code.globalstate.use_utility_code(
                    TempitaUtilityCode.load_cached("SliceTupleAndList", "ObjectHandling.c"))
                cfunc = '__Pyx_PyList_GetSlice'
            elif self.base.type is tuple_type:
                code.globalstate.use_utility_code(
                    TempitaUtilityCode.load_cached("SliceTupleAndList", "ObjectHandling.c"))
                cfunc = '__Pyx_PyTuple_GetSlice'
            else:
                cfunc = '__Pyx_PySequence_GetSlice'
            code.putln(
                "%s = %s(%s, %s, %s); %s" % (
                    result,
                    cfunc,
                    self.base.py_result(),
                    start_code,
                    stop_code,
                    code.error_goto_if_null(result, self.pos)))
        code.put_gotref(self.py_result())

    def generate_assignment_code(self, rhs, code):
        self.generate_subexpr_evaluation_code(code)
        if self.type.is_pyobject:
            code.globalstate.use_utility_code(self.set_slice_utility_code)
            (has_c_start, has_c_stop, c_start, c_stop,
             py_start, py_stop, py_slice) = self.get_slice_config()
            code.put_error_if_neg(self.pos,
                "__Pyx_PyObject_SetSlice(%s, %s, %s, %s, %s, %s, %s, %d, %d, %d)" % (
                    self.base.py_result(),
                    rhs.py_result(),
                    c_start, c_stop,
                    py_start, py_stop, py_slice,
                    has_c_start, has_c_stop,
                    bool(code.globalstate.directives['wraparound'])))
        else:
            start_offset = ''
            if self.start:
                start_offset = self.start_code()
                if start_offset == '0':
                    start_offset = ''
                else:
                    start_offset += '+'
            if rhs.type.is_array:
                array_length = rhs.type.size
                self.generate_slice_guard_code(code, array_length)
            else:
                error(self.pos,
                      "Slice assignments from pointers are not yet supported.")
                # FIXME: fix the array size according to start/stop
                array_length = self.base.type.size
            for i in range(array_length):
                code.putln("%s[%s%s] = %s[%d];" % (
                        self.base.result(), start_offset, i,
                        rhs.result(), i))
        self.generate_subexpr_disposal_code(code)
        self.free_subexpr_temps(code)
        rhs.generate_disposal_code(code)
        rhs.free_temps(code)

    def generate_deletion_code(self, code, ignore_nonexisting=False):
        if not self.base.type.is_pyobject:
            error(self.pos,
                  "Deleting slices is only supported for Python types, not '%s'." % self.type)
            return
        self.generate_subexpr_evaluation_code(code)
        code.globalstate.use_utility_code(self.set_slice_utility_code)
        (has_c_start, has_c_stop, c_start, c_stop,
         py_start, py_stop, py_slice) = self.get_slice_config()
        code.put_error_if_neg(self.pos,
            "__Pyx_PyObject_DelSlice(%s, %s, %s, %s, %s, %s, %d, %d, %d)" % (
                self.base.py_result(),
                c_start, c_stop,
                py_start, py_stop, py_slice,
                has_c_start, has_c_stop,
                bool(code.globalstate.directives['wraparound'])))
        self.generate_subexpr_disposal_code(code)
        self.free_subexpr_temps(code)

    def get_slice_config(self):
        has_c_start, c_start, py_start = False, '0', 'NULL'
        if self.start:
            has_c_start = not self.start.type.is_pyobject
            if has_c_start:
                c_start = self.start.result()
            else:
                py_start = '&%s' % self.start.py_result()
        has_c_stop, c_stop, py_stop = False, '0', 'NULL'
        if self.stop:
            has_c_stop = not self.stop.type.is_pyobject
            if has_c_stop:
                c_stop = self.stop.result()
            else:
                py_stop = '&%s' % self.stop.py_result()
        py_slice = self.slice and '&%s' % self.slice.py_result() or 'NULL'
        return (has_c_start, has_c_stop, c_start, c_stop,
                py_start, py_stop, py_slice)

    def generate_slice_guard_code(self, code, target_size):
        if not self.base.type.is_array:
            return
        slice_size = self.base.type.size
        start = stop = None
        if self.stop:
            stop = self.stop.result()
            try:
                stop = int(stop)
                if stop < 0:
                    slice_size = self.base.type.size + stop
                else:
                    slice_size = stop
                stop = None
            except ValueError:
                pass
        if self.start:
            start = self.start.result()
            try:
                start = int(start)
                if start < 0:
                    start = self.base.type.size + start
                slice_size -= start
                start = None
            except ValueError:
                pass
        check = None
        if slice_size < 0:
            if target_size > 0:
                error(self.pos, "Assignment to empty slice.")
        elif start is None and stop is None:
            # we know the exact slice length
            if target_size != slice_size:
                error(self.pos, "Assignment to slice of wrong length, expected %d, got %d" % (
                        slice_size, target_size))
        elif start is not None:
            if stop is None:
                stop = slice_size
            check = "(%s)-(%s)" % (stop, start)
        else: # stop is not None:
            check = stop
        if check:
            code.putln("if (unlikely((%s) != %d)) {" % (check, target_size))
            code.putln('PyErr_Format(PyExc_ValueError, "Assignment to slice of wrong length, expected %%" CYTHON_FORMAT_SSIZE_T "d, got %%" CYTHON_FORMAT_SSIZE_T "d", (Py_ssize_t)%d, (Py_ssize_t)(%s));' % (
                        target_size, check))
            code.putln(code.error_goto(self.pos))
            code.putln("}")

    def start_code(self):
        if self.start:
            return self.start.result()
        else:
            return "0"

    def stop_code(self):
        if self.stop:
            return self.stop.result()
        elif self.base.type.is_array:
            return self.base.type.size
        else:
            return "PY_SSIZE_T_MAX"

    def calculate_result_code(self):
        # self.result() is not used, but this method must exist
        return "<unused>"


class SliceNode(ExprNode):
    #  start:stop:step in subscript list
    #
    #  start     ExprNode
    #  stop      ExprNode
    #  step      ExprNode

    subexprs = ['start', 'stop', 'step']

    type = slice_type
    is_temp = 1

    def calculate_constant_result(self):
        self.constant_result = slice(
            self.start.constant_result,
            self.stop.constant_result,
            self.step.constant_result)

    def compile_time_value(self, denv):
        start = self.start.compile_time_value(denv)
        stop = self.stop.compile_time_value(denv)
        step = self.step.compile_time_value(denv)
        try:
            return slice(start, stop, step)
        except Exception, e:
            self.compile_time_value_error(e)

    def may_be_none(self):
        return False

    def analyse_types(self, env):
        start = self.start.analyse_types(env)
        stop = self.stop.analyse_types(env)
        step = self.step.analyse_types(env)
        self.start = start.coerce_to_pyobject(env)
        self.stop = stop.coerce_to_pyobject(env)
        self.step = step.coerce_to_pyobject(env)
        if self.start.is_literal and self.stop.is_literal and self.step.is_literal:
            self.is_literal = True
            self.is_temp = False
        return self

    gil_message = "Constructing Python slice object"

    def calculate_result_code(self):
        return self.result_code

    def generate_result_code(self, code):
        if self.is_literal:
            self.result_code = code.get_py_const(py_object_type, 'slice', cleanup_level=2)
            code = code.get_cached_constants_writer()
            code.mark_pos(self.pos)

        code.putln(
            "%s = PySlice_New(%s, %s, %s); %s" % (
                self.result(),
                self.start.py_result(),
                self.stop.py_result(),
                self.step.py_result(),
                code.error_goto_if_null(self.result(), self.pos)))
        code.put_gotref(self.py_result())
        if self.is_literal:
            code.put_giveref(self.py_result())

    def __deepcopy__(self, memo):
        """
        There is a copy bug in python 2.4 for slice objects.
        """
        return SliceNode(
            self.pos,
            start=copy.deepcopy(self.start, memo),
            stop=copy.deepcopy(self.stop, memo),
            step=copy.deepcopy(self.step, memo),
            is_temp=self.is_temp,
            is_literal=self.is_literal,
            constant_result=self.constant_result)


class CallNode(ExprNode):

    # allow overriding the default 'may_be_none' behaviour
    may_return_none = None

    def infer_type(self, env):
        function = self.function
        func_type = function.infer_type(env)
        if isinstance(function, NewExprNode):
            # note: needs call to infer_type() above
            return PyrexTypes.CPtrType(function.class_type)
        if func_type is py_object_type:
            # function might have lied for safety => try to find better type
            entry = getattr(function, 'entry', None)
            if entry is not None:
                func_type = entry.type or func_type
        if func_type.is_ptr:
            func_type = func_type.base_type
        if func_type.is_cfunction:
            return func_type.return_type
        elif func_type is type_type:
            if function.is_name and function.entry and function.entry.type:
                result_type = function.entry.type
                if result_type.is_extension_type:
                    return result_type
                elif result_type.is_builtin_type:
                    if function.entry.name == 'float':
                        return PyrexTypes.c_double_type
                    elif function.entry.name in Builtin.types_that_construct_their_instance:
                        return result_type
        return py_object_type

    def type_dependencies(self, env):
        # TODO: Update when Danilo's C++ code merged in to handle the
        # the case of function overloading.
        return self.function.type_dependencies(env)

    def is_simple(self):
        # C function calls could be considered simple, but they may
        # have side-effects that may hit when multiple operations must
        # be effected in order, e.g. when constructing the argument
        # sequence for a function call or comparing values.
        return False

    def may_be_none(self):
        if self.may_return_none is not None:
            return self.may_return_none
        func_type = self.function.type
        if func_type is type_type and self.function.is_name:
            entry = self.function.entry
            if entry.type.is_extension_type:
                return False
            if (entry.type.is_builtin_type and
                    entry.name in Builtin.types_that_construct_their_instance):
                return False
        return ExprNode.may_be_none(self)

    def analyse_as_type_constructor(self, env):
        type = self.function.analyse_as_type(env)
        if type and type.is_struct_or_union:
            args, kwds = self.explicit_args_kwds()
            items = []
            for arg, member in zip(args, type.scope.var_entries):
                items.append(DictItemNode(pos=arg.pos, key=StringNode(pos=arg.pos, value=member.name), value=arg))
            if kwds:
                items += kwds.key_value_pairs
            self.key_value_pairs = items
            self.__class__ = DictNode
            self.analyse_types(env)    # FIXME
            self.coerce_to(type, env)
            return True
        elif type and type.is_cpp_class:
            self.args = [ arg.analyse_types(env) for arg in self.args ]
            constructor = type.scope.lookup("<init>")
            self.function = RawCNameExprNode(self.function.pos, constructor.type)
            self.function.entry = constructor
            self.function.set_cname(type.declaration_code(""))
            self.analyse_c_function_call(env)
            self.type = type
            return True

    def is_lvalue(self):
        return self.type.is_reference

    def nogil_check(self, env):
        func_type = self.function_type()
        if func_type.is_pyobject:
            self.gil_error()
        elif not getattr(func_type, 'nogil', False):
            self.gil_error()

    gil_message = "Calling gil-requiring function"


class SimpleCallNode(CallNode):
    #  Function call without keyword, * or ** args.
    #
    #  function       ExprNode
    #  args           [ExprNode]
    #  arg_tuple      ExprNode or None     used internally
    #  self           ExprNode or None     used internally
    #  coerced_self   ExprNode or None     used internally
    #  wrapper_call   bool                 used internally
    #  has_optional_args   bool            used internally
    #  nogil          bool                 used internally

    subexprs = ['self', 'coerced_self', 'function', 'args', 'arg_tuple']

    self = None
    coerced_self = None
    arg_tuple = None
    wrapper_call = False
    has_optional_args = False
    nogil = False
    analysed = False

    def compile_time_value(self, denv):
        function = self.function.compile_time_value(denv)
        args = [arg.compile_time_value(denv) for arg in self.args]
        try:
            return function(*args)
        except Exception, e:
            self.compile_time_value_error(e)

    def analyse_as_type(self, env):
        attr = self.function.as_cython_attribute()
        if attr == 'pointer':
            if len(self.args) != 1:
                error(self.args.pos, "only one type allowed.")
            else:
                type = self.args[0].analyse_as_type(env)
                if not type:
                    error(self.args[0].pos, "Unknown type")
                else:
                    return PyrexTypes.CPtrType(type)

    def explicit_args_kwds(self):
        return self.args, None

    def analyse_types(self, env):
        if self.analyse_as_type_constructor(env):
            return self
        if self.analysed:
            return self
        self.analysed = True
        self.function.is_called = 1
        self.function = self.function.analyse_types(env)
        function = self.function

        if function.is_attribute and function.entry and function.entry.is_cmethod:
            # Take ownership of the object from which the attribute
            # was obtained, because we need to pass it as 'self'.
            self.self = function.obj
            function.obj = CloneNode(self.self)

        func_type = self.function_type()
        if func_type.is_pyobject:
            self.arg_tuple = TupleNode(self.pos, args = self.args)
            self.arg_tuple = self.arg_tuple.analyse_types(env)
            self.args = None
            if func_type is Builtin.type_type and function.is_name and \
                   function.entry and \
                   function.entry.is_builtin and \
                   function.entry.name in Builtin.types_that_construct_their_instance:
                # calling a builtin type that returns a specific object type
                if function.entry.name == 'float':
                    # the following will come true later on in a transform
                    self.type = PyrexTypes.c_double_type
                    self.result_ctype = PyrexTypes.c_double_type
                else:
                    self.type = Builtin.builtin_types[function.entry.name]
                    self.result_ctype = py_object_type
                self.may_return_none = False
            elif function.is_name and function.type_entry:
                # We are calling an extension type constructor.  As
                # long as we do not support __new__(), the result type
                # is clear
                self.type = function.type_entry.type
                self.result_ctype = py_object_type
                self.may_return_none = False
            else:
                self.type = py_object_type
            self.is_temp = 1
        else:
            self.args = [ arg.analyse_types(env) for arg in self.args ]
            self.analyse_c_function_call(env)
        return self

    def function_type(self):
        # Return the type of the function being called, coercing a function
        # pointer to a function if necessary. If the function has fused
        # arguments, return the specific type.
        func_type = self.function.type

        if func_type.is_ptr:
            func_type = func_type.base_type

        return func_type

    def analyse_c_function_call(self, env):
        if self.function.type is error_type:
            self.type = error_type
            return

        if self.self:
            args = [self.self] + self.args
        else:
            args = self.args

        if self.function.type.is_cpp_class:
            overloaded_entry = self.function.type.scope.lookup("operator()")
            if overloaded_entry is None:
                self.type = PyrexTypes.error_type
                self.result_code = "<error>"
                return
        elif hasattr(self.function, 'entry'):
            overloaded_entry = self.function.entry
        elif (isinstance(self.function, IndexNode) and
              self.function.is_fused_index):
            overloaded_entry = self.function.type.entry
        else:
            overloaded_entry = None

        if overloaded_entry:
            if self.function.type.is_fused:
                functypes = self.function.type.get_all_specialized_function_types()
                alternatives = [f.entry for f in functypes]
            else:
                alternatives = overloaded_entry.all_alternatives()

            entry = PyrexTypes.best_match(args, alternatives, self.pos, env)

            if not entry:
                self.type = PyrexTypes.error_type
                self.result_code = "<error>"
                return

            entry.used = True
            self.function.entry = entry
            self.function.type = entry.type
            func_type = self.function_type()
        else:
            entry = None
            func_type = self.function_type()
            if not func_type.is_cfunction:
                error(self.pos, "Calling non-function type '%s'" % func_type)
                self.type = PyrexTypes.error_type
                self.result_code = "<error>"
                return

        # Check no. of args
        max_nargs = len(func_type.args)
        expected_nargs = max_nargs - func_type.optional_arg_count
        actual_nargs = len(args)
        if func_type.optional_arg_count and expected_nargs != actual_nargs:
            self.has_optional_args = 1
            self.is_temp = 1

        # check 'self' argument
        if entry and entry.is_cmethod and func_type.args:
            formal_arg = func_type.args[0]
            arg = args[0]
            if formal_arg.not_none:
                if self.self:
                    self.self = self.self.as_none_safe_node(
                        "'NoneType' object has no attribute '%s'",
                        error='PyExc_AttributeError',
                        format_args=[entry.name])
                else:
                    # unbound method
                    arg = arg.as_none_safe_node(
                        "descriptor '%s' requires a '%s' object but received a 'NoneType'",
                        format_args=[entry.name, formal_arg.type.name])
            if self.self:
                if formal_arg.accept_builtin_subtypes:
                    arg = CMethodSelfCloneNode(self.self)
                else:
                    arg = CloneNode(self.self)
                arg = self.coerced_self = arg.coerce_to(formal_arg.type, env)
            elif formal_arg.type.is_builtin_type:
                # special case: unbound methods of builtins accept subtypes
                arg = arg.coerce_to(formal_arg.type, env)
                if arg.type.is_builtin_type and isinstance(arg, PyTypeTestNode):
                    arg.exact_builtin_type = False
            args[0] = arg

        # Coerce arguments
        some_args_in_temps = False
        for i in xrange(min(max_nargs, actual_nargs)):
            formal_arg = func_type.args[i]
            formal_type = formal_arg.type
            arg = args[i].coerce_to(formal_type, env)
            if formal_arg.not_none:
                # C methods must do the None checks at *call* time
                arg = arg.as_none_safe_node(
                    "cannot pass None into a C function argument that is declared 'not None'")
            if arg.is_temp:
                if i > 0:
                    # first argument in temp doesn't impact subsequent arguments
                    some_args_in_temps = True
            elif arg.type.is_pyobject and not env.nogil:
                if i == 0 and self.self is not None:
                    # a method's cloned "self" argument is ok
                    pass
                elif arg.nonlocally_immutable():
                    # plain local variables are ok
                    pass
                else:
                    # we do not safely own the argument's reference,
                    # but we must make sure it cannot be collected
                    # before we return from the function, so we create
                    # an owned temp reference to it
                    if i > 0: # first argument doesn't matter
                        some_args_in_temps = True
                    arg = arg.coerce_to_temp(env)
            args[i] = arg

        # handle additional varargs parameters
        for i in xrange(max_nargs, actual_nargs):
            arg = args[i]
            if arg.type.is_pyobject:
                arg_ctype = arg.type.default_coerced_ctype()
                if arg_ctype is None:
                    error(self.args[i].pos,
                          "Python object cannot be passed as a varargs parameter")
                else:
                    args[i] = arg = arg.coerce_to(arg_ctype, env)
            if arg.is_temp and i > 0:
                some_args_in_temps = True

        if some_args_in_temps:
            # if some args are temps and others are not, they may get
            # constructed in the wrong order (temps first) => make
            # sure they are either all temps or all not temps (except
            # for the last argument, which is evaluated last in any
            # case)
            for i in xrange(actual_nargs-1):
                if i == 0 and self.self is not None:
                    continue # self is ok
                arg = args[i]
                if arg.nonlocally_immutable():
                    # locals, C functions, unassignable types are safe.
                    pass
                elif arg.type.is_cpp_class:
                    # Assignment has side effects, avoid.
                    pass
                elif env.nogil and arg.type.is_pyobject:
                    # can't copy a Python reference into a temp in nogil
                    # env (this is safe: a construction would fail in
                    # nogil anyway)
                    pass
                else:
                    #self.args[i] = arg.coerce_to_temp(env)
                    # instead: issue a warning
                    if i > 0 or i == 1 and self.self is not None: # skip first arg
                        warning(arg.pos, "Argument evaluation order in C function call is undefined and may not be as expected", 0)
                        break

        self.args[:] = args

        # Calc result type and code fragment
        if isinstance(self.function, NewExprNode):
            self.type = PyrexTypes.CPtrType(self.function.class_type)
        else:
            self.type = func_type.return_type

        if self.function.is_name or self.function.is_attribute:
            if self.function.entry and self.function.entry.utility_code:
                self.is_temp = 1 # currently doesn't work for self.calculate_result_code()

        if self.type.is_pyobject:
            self.result_ctype = py_object_type
            self.is_temp = 1
        elif func_type.exception_value is not None \
                 or func_type.exception_check:
            self.is_temp = 1
        elif self.type.is_memoryviewslice:
            self.is_temp = 1
            # func_type.exception_check = True

        # Called in 'nogil' context?
        self.nogil = env.nogil
        if (self.nogil and
            func_type.exception_check and
            func_type.exception_check != '+'):
            env.use_utility_code(pyerr_occurred_withgil_utility_code)
        # C++ exception handler
        if func_type.exception_check == '+':
            if func_type.exception_value is None:
                env.use_utility_code(UtilityCode.load_cached("CppExceptionConversion", "CppSupport.cpp"))

    def calculate_result_code(self):
        return self.c_call_code()

    def c_call_code(self):
        func_type = self.function_type()
        if self.type is PyrexTypes.error_type or not func_type.is_cfunction:
            return "<error>"
        formal_args = func_type.args
        arg_list_code = []
        args = list(zip(formal_args, self.args))
        max_nargs = len(func_type.args)
        expected_nargs = max_nargs - func_type.optional_arg_count
        actual_nargs = len(self.args)
        for formal_arg, actual_arg in args[:expected_nargs]:
                arg_code = actual_arg.result_as(formal_arg.type)
                arg_list_code.append(arg_code)

        if func_type.is_overridable:
            arg_list_code.append(str(int(self.wrapper_call or self.function.entry.is_unbound_cmethod)))

        if func_type.optional_arg_count:
            if expected_nargs == actual_nargs:
                optional_args = 'NULL'
            else:
                optional_args = "&%s" % self.opt_arg_struct
            arg_list_code.append(optional_args)

        for actual_arg in self.args[len(formal_args):]:
            arg_list_code.append(actual_arg.result())

        result = "%s(%s)" % (self.function.result(), ', '.join(arg_list_code))
        return result

    def generate_result_code(self, code):
        func_type = self.function_type()
        if self.function.is_name or self.function.is_attribute:
            if self.function.entry and self.function.entry.utility_code:
                code.globalstate.use_utility_code(self.function.entry.utility_code)
        if func_type.is_pyobject:
            arg_code = self.arg_tuple.py_result()
            code.globalstate.use_utility_code(UtilityCode.load_cached(
                "PyObjectCall", "ObjectHandling.c"))
            code.putln(
                "%s = __Pyx_PyObject_Call(%s, %s, NULL); %s" % (
                    self.result(),
                    self.function.py_result(),
                    arg_code,
                    code.error_goto_if_null(self.result(), self.pos)))
            code.put_gotref(self.py_result())
        elif func_type.is_cfunction:
            if self.has_optional_args:
                actual_nargs = len(self.args)
                expected_nargs = len(func_type.args) - func_type.optional_arg_count
                self.opt_arg_struct = code.funcstate.allocate_temp(
                    func_type.op_arg_struct.base_type, manage_ref=True)
                code.putln("%s.%s = %s;" % (
                        self.opt_arg_struct,
                        Naming.pyrex_prefix + "n",
                        len(self.args) - expected_nargs))
                args = list(zip(func_type.args, self.args))
                for formal_arg, actual_arg in args[expected_nargs:actual_nargs]:
                    code.putln("%s.%s = %s;" % (
                            self.opt_arg_struct,
                            func_type.opt_arg_cname(formal_arg.name),
                            actual_arg.result_as(formal_arg.type)))
            exc_checks = []
            if self.type.is_pyobject and self.is_temp:
                exc_checks.append("!%s" % self.result())
            elif self.type.is_memoryviewslice:
                assert self.is_temp
                exc_checks.append(self.type.error_condition(self.result()))
            else:
                exc_val = func_type.exception_value
                exc_check = func_type.exception_check
                if exc_val is not None:
                    exc_checks.append("%s == %s" % (self.result(), exc_val))
                if exc_check:
                    if self.nogil:
                        exc_checks.append("__Pyx_ErrOccurredWithGIL()")
                    else:
                        exc_checks.append("PyErr_Occurred()")
            if self.is_temp or exc_checks:
                rhs = self.c_call_code()
                if self.result():
                    lhs = "%s = " % self.result()
                    if self.is_temp and self.type.is_pyobject:
                        #return_type = self.type # func_type.return_type
                        #print "SimpleCallNode.generate_result_code: casting", rhs, \
                        #    "from", return_type, "to pyobject" ###
                        rhs = typecast(py_object_type, self.type, rhs)
                else:
                    lhs = ""
                if func_type.exception_check == '+':
                    if func_type.exception_value is None:
                        raise_py_exception = "__Pyx_CppExn2PyErr();"
                    elif func_type.exception_value.type.is_pyobject:
                        raise_py_exception = 'try { throw; } catch(const std::exception& exn) { PyErr_SetString(%s, exn.what()); } catch(...) { PyErr_SetNone(%s); }' % (
                            func_type.exception_value.entry.cname,
                            func_type.exception_value.entry.cname)
                    else:
                        raise_py_exception = '%s(); if (!PyErr_Occurred()) PyErr_SetString(PyExc_RuntimeError , "Error converting c++ exception.");' % func_type.exception_value.entry.cname
                    code.putln("try {")
                    code.putln("%s%s;" % (lhs, rhs))
                    code.putln("} catch(...) {")
                    if self.nogil:
                        code.put_ensure_gil(declare_gilstate=True)
                    code.putln(raise_py_exception)
                    if self.nogil:
                        code.put_release_ensured_gil()
                    code.putln(code.error_goto(self.pos))
                    code.putln("}")
                else:
                    if exc_checks:
                        goto_error = code.error_goto_if(" && ".join(exc_checks), self.pos)
                    else:
                        goto_error = ""
                    code.putln("%s%s; %s" % (lhs, rhs, goto_error))
                if self.type.is_pyobject and self.result():
                    code.put_gotref(self.py_result())
            if self.has_optional_args:
                code.funcstate.release_temp(self.opt_arg_struct)


class InlinedDefNodeCallNode(CallNode):
    #  Inline call to defnode
    #
    #  function       PyCFunctionNode
    #  function_name  NameNode
    #  args           [ExprNode]

    subexprs = ['args', 'function_name']
    is_temp = 1
    type = py_object_type
    function = None
    function_name = None

    def can_be_inlined(self):
        func_type= self.function.def_node
        if func_type.star_arg or func_type.starstar_arg:
            return False
        if len(func_type.args) != len(self.args):
            return False
        return True

    def analyse_types(self, env):
        self.function_name = self.function_name.analyse_types(env)

        self.args = [ arg.analyse_types(env) for arg in self.args ]
        func_type = self.function.def_node
        actual_nargs = len(self.args)

        # Coerce arguments
        some_args_in_temps = False
        for i in xrange(actual_nargs):
            formal_type = func_type.args[i].type
            arg = self.args[i].coerce_to(formal_type, env)
            if arg.is_temp:
                if i > 0:
                    # first argument in temp doesn't impact subsequent arguments
                    some_args_in_temps = True
            elif arg.type.is_pyobject and not env.nogil:
                if arg.nonlocally_immutable():
                    # plain local variables are ok
                    pass
                else:
                    # we do not safely own the argument's reference,
                    # but we must make sure it cannot be collected
                    # before we return from the function, so we create
                    # an owned temp reference to it
                    if i > 0: # first argument doesn't matter
                        some_args_in_temps = True
                    arg = arg.coerce_to_temp(env)
            self.args[i] = arg

        if some_args_in_temps:
            # if some args are temps and others are not, they may get
            # constructed in the wrong order (temps first) => make
            # sure they are either all temps or all not temps (except
            # for the last argument, which is evaluated last in any
            # case)
            for i in xrange(actual_nargs-1):
                arg = self.args[i]
                if arg.nonlocally_immutable():
                    # locals, C functions, unassignable types are safe.
                    pass
                elif arg.type.is_cpp_class:
                    # Assignment has side effects, avoid.
                    pass
                elif env.nogil and arg.type.is_pyobject:
                    # can't copy a Python reference into a temp in nogil
                    # env (this is safe: a construction would fail in
                    # nogil anyway)
                    pass
                else:
                    #self.args[i] = arg.coerce_to_temp(env)
                    # instead: issue a warning
                    if i > 0:
                        warning(arg.pos, "Argument evaluation order in C function call is undefined and may not be as expected", 0)
                        break
        return self

    def generate_result_code(self, code):
        arg_code = [self.function_name.py_result()]
        func_type = self.function.def_node
        for arg, proto_arg in zip(self.args, func_type.args):
            if arg.type.is_pyobject:
                arg_code.append(arg.result_as(proto_arg.type))
            else:
                arg_code.append(arg.result())
        arg_code = ', '.join(arg_code)
        code.putln(
            "%s = %s(%s); %s" % (
                self.result(),
                self.function.def_node.entry.pyfunc_cname,
                arg_code,
                code.error_goto_if_null(self.result(), self.pos)))
        code.put_gotref(self.py_result())


class PythonCapiFunctionNode(ExprNode):
    subexprs = []

    def __init__(self, pos, py_name, cname, func_type, utility_code = None):
        ExprNode.__init__(self, pos, name=py_name, cname=cname,
                          type=func_type, utility_code=utility_code)

    def analyse_types(self, env):
        return self

    def generate_result_code(self, code):
        if self.utility_code:
            code.globalstate.use_utility_code(self.utility_code)

    def calculate_result_code(self):
        return self.cname


class PythonCapiCallNode(SimpleCallNode):
    # Python C-API Function call (only created in transforms)

    # By default, we assume that the call never returns None, as this
    # is true for most C-API functions in CPython.  If this does not
    # apply to a call, set the following to True (or None to inherit
    # the default behaviour).
    may_return_none = False

    def __init__(self, pos, function_name, func_type,
                 utility_code = None, py_name=None, **kwargs):
        self.type = func_type.return_type
        self.result_ctype = self.type
        self.function = PythonCapiFunctionNode(
            pos, py_name, function_name, func_type,
            utility_code = utility_code)
        # call this last so that we can override the constructed
        # attributes above with explicit keyword arguments if required
        SimpleCallNode.__init__(self, pos, **kwargs)


class GeneralCallNode(CallNode):
    #  General Python function call, including keyword,
    #  * and ** arguments.
    #
    #  function         ExprNode
    #  positional_args  ExprNode          Tuple of positional arguments
    #  keyword_args     ExprNode or None  Dict of keyword arguments

    type = py_object_type

    subexprs = ['function', 'positional_args', 'keyword_args']

    nogil_check = Node.gil_error

    def compile_time_value(self, denv):
        function = self.function.compile_time_value(denv)
        positional_args = self.positional_args.compile_time_value(denv)
        keyword_args = self.keyword_args.compile_time_value(denv)
        try:
            return function(*positional_args, **keyword_args)
        except Exception, e:
            self.compile_time_value_error(e)

    def explicit_args_kwds(self):
        if (self.keyword_args and not isinstance(self.keyword_args, DictNode) or
            not isinstance(self.positional_args, TupleNode)):
            raise CompileError(self.pos,
                'Compile-time keyword arguments must be explicit.')
        return self.positional_args.args, self.keyword_args

    def analyse_types(self, env):
        if self.analyse_as_type_constructor(env):
            return self
        self.function = self.function.analyse_types(env)
        if not self.function.type.is_pyobject:
            if self.function.type.is_error:
                self.type = error_type
                return self
            if hasattr(self.function, 'entry'):
                node = self.map_to_simple_call_node()
                if node is not None and node is not self:
                    return node.analyse_types(env)
                elif self.function.entry.as_variable:
                    self.function = self.function.coerce_to_pyobject(env)
                elif node is self:
                    error(self.pos,
                          "Non-trivial keyword arguments and starred "
                          "arguments not allowed in cdef functions.")
                else:
                    # error was already reported
                    pass
            else:
                self.function = self.function.coerce_to_pyobject(env)
        if self.keyword_args:
            self.keyword_args = self.keyword_args.analyse_types(env)
        self.positional_args = self.positional_args.analyse_types(env)
        self.positional_args = \
            self.positional_args.coerce_to_pyobject(env)
        function = self.function
        if function.is_name and function.type_entry:
            # We are calling an extension type constructor.  As long
            # as we do not support __new__(), the result type is clear
            self.type = function.type_entry.type
            self.result_ctype = py_object_type
            self.may_return_none = False
        else:
            self.type = py_object_type
        self.is_temp = 1
        return self

    def map_to_simple_call_node(self):
        """
        Tries to map keyword arguments to declared positional arguments.
        Returns self to try a Python call, None to report an error
        or a SimpleCallNode if the mapping succeeds.
        """
        if not isinstance(self.positional_args, TupleNode):
            # has starred argument
            return self
        if not isinstance(self.keyword_args, DictNode):
            # keywords come from arbitrary expression => nothing to do here
            return self
        function = self.function
        entry = getattr(function, 'entry', None)
        if not entry:
            return self
        function_type = entry.type
        if function_type.is_ptr:
            function_type = function_type.base_type
        if not function_type.is_cfunction:
            return self

        pos_args = self.positional_args.args
        kwargs = self.keyword_args
        declared_args = function_type.args
        if entry.is_cmethod:
            declared_args = declared_args[1:] # skip 'self'

        if len(pos_args) > len(declared_args):
            error(self.pos, "function call got too many positional arguments, "
                            "expected %d, got %s" % (len(declared_args),
                                                     len(pos_args)))
            return None

        matched_args = set([ arg.name for arg in declared_args[:len(pos_args)]
                             if arg.name ])
        unmatched_args = declared_args[len(pos_args):]
        matched_kwargs_count = 0
        args = list(pos_args)

        # check for duplicate keywords
        seen = set(matched_args)
        has_errors = False
        for arg in kwargs.key_value_pairs:
            name = arg.key.value
            if name in seen:
                error(arg.pos, "argument '%s' passed twice" % name)
                has_errors = True
                # continue to report more errors if there are any
            seen.add(name)

        # match keywords that are passed in order
        for decl_arg, arg in zip(unmatched_args, kwargs.key_value_pairs):
            name = arg.key.value
            if decl_arg.name == name:
                matched_args.add(name)
                matched_kwargs_count += 1
                args.append(arg.value)
            else:
                break

        # match keyword arguments that are passed out-of-order, but keep
        # the evaluation of non-simple arguments in order by moving them
        # into temps
        from Cython.Compiler.UtilNodes import EvalWithTempExprNode, LetRefNode
        temps = []
        if len(kwargs.key_value_pairs) > matched_kwargs_count:
            unmatched_args = declared_args[len(args):]
            keywords = dict([ (arg.key.value, (i+len(pos_args), arg))
                              for i, arg in enumerate(kwargs.key_value_pairs) ])
            first_missing_keyword = None
            for decl_arg in unmatched_args:
                name = decl_arg.name
                if name not in keywords:
                    # missing keyword argument => either done or error
                    if not first_missing_keyword:
                        first_missing_keyword = name
                    continue
                elif first_missing_keyword:
                    if entry.as_variable:
                        # we might be able to convert the function to a Python
                        # object, which then allows full calling semantics
                        # with default values in gaps - currently, we only
                        # support optional arguments at the end
                        return self
                    # wasn't the last keyword => gaps are not supported
                    error(self.pos, "C function call is missing "
                                    "argument '%s'" % first_missing_keyword)
                    return None
                pos, arg = keywords[name]
                matched_args.add(name)
                matched_kwargs_count += 1
                if arg.value.is_simple():
                    args.append(arg.value)
                else:
                    temp = LetRefNode(arg.value)
                    assert temp.is_simple()
                    args.append(temp)
                    temps.append((pos, temp))

            if temps:
                # may have to move preceding non-simple args into temps
                final_args = []
                new_temps = []
                first_temp_arg = temps[0][-1]
                for arg_value in args:
                    if arg_value is first_temp_arg:
                        break  # done
                    if arg_value.is_simple():
                        final_args.append(arg_value)
                    else:
                        temp = LetRefNode(arg_value)
                        new_temps.append(temp)
                        final_args.append(temp)
                if new_temps:
                    args = final_args
                temps = new_temps + [ arg for i,arg in sorted(temps) ]

        # check for unexpected keywords
        for arg in kwargs.key_value_pairs:
            name = arg.key.value
            if name not in matched_args:
                has_errors = True
                error(arg.pos,
                      "C function got unexpected keyword argument '%s'" %
                      name)

        if has_errors:
            # error was reported already
            return None

        # all keywords mapped to positional arguments
        # if we are missing arguments, SimpleCallNode will figure it out
        node = SimpleCallNode(self.pos, function=function, args=args)
        for temp in temps[::-1]:
            node = EvalWithTempExprNode(temp, node)
        return node

    def generate_result_code(self, code):
        if self.type.is_error: return
        if self.keyword_args:
            kwargs = self.keyword_args.py_result()
        else:
            kwargs = 'NULL'
        code.globalstate.use_utility_code(UtilityCode.load_cached(
            "PyObjectCall", "ObjectHandling.c"))
        code.putln(
            "%s = __Pyx_PyObject_Call(%s, %s, %s); %s" % (
                self.result(),
                self.function.py_result(),
                self.positional_args.py_result(),
                kwargs,
                code.error_goto_if_null(self.result(), self.pos)))
        code.put_gotref(self.py_result())


class AsTupleNode(ExprNode):
    #  Convert argument to tuple. Used for normalising
    #  the * argument of a function call.
    #
    #  arg    ExprNode

    subexprs = ['arg']

    def calculate_constant_result(self):
        self.constant_result = tuple(self.arg.constant_result)

    def compile_time_value(self, denv):
        arg = self.arg.compile_time_value(denv)
        try:
            return tuple(arg)
        except Exception, e:
            self.compile_time_value_error(e)

    def analyse_types(self, env):
        self.arg = self.arg.analyse_types(env)
        self.arg = self.arg.coerce_to_pyobject(env)
        self.type = tuple_type
        self.is_temp = 1
        return self

    def may_be_none(self):
        return False

    nogil_check = Node.gil_error
    gil_message = "Constructing Python tuple"

    def generate_result_code(self, code):
        code.putln(
            "%s = PySequence_Tuple(%s); %s" % (
                self.result(),
                self.arg.py_result(),
                code.error_goto_if_null(self.result(), self.pos)))
        code.put_gotref(self.py_result())


class AttributeNode(ExprNode):
    #  obj.attribute
    #
    #  obj          ExprNode
    #  attribute    string
    #  needs_none_check boolean        Used if obj is an extension type.
    #                                  If set to True, it is known that the type is not None.
    #
    #  Used internally:
    #
    #  is_py_attr           boolean   Is a Python getattr operation
    #  member               string    C name of struct member
    #  is_called            boolean   Function call is being done on result
    #  entry                Entry     Symbol table entry of attribute

    is_attribute = 1
    subexprs = ['obj']

    type = PyrexTypes.error_type
    entry = None
    is_called = 0
    needs_none_check = True
    is_memslice_transpose = False
    is_special_lookup = False

    def as_cython_attribute(self):
        if (isinstance(self.obj, NameNode) and
                self.obj.is_cython_module and not
                self.attribute == u"parallel"):
            return self.attribute

        cy = self.obj.as_cython_attribute()
        if cy:
            return "%s.%s" % (cy, self.attribute)
        return None

    def coerce_to(self, dst_type, env):
        #  If coercing to a generic pyobject and this is a cpdef function
        #  we can create the corresponding attribute
        if dst_type is py_object_type:
            entry = self.entry
            if entry and entry.is_cfunction and entry.as_variable:
                # must be a cpdef function
                self.is_temp = 1
                self.entry = entry.as_variable
                self.analyse_as_python_attribute(env)
                return self
        return ExprNode.coerce_to(self, dst_type, env)

    def calculate_constant_result(self):
        attr = self.attribute
        if attr.startswith("__") and attr.endswith("__"):
            return
        self.constant_result = getattr(self.obj.constant_result, attr)

    def compile_time_value(self, denv):
        attr = self.attribute
        if attr.startswith("__") and attr.endswith("__"):
            error(self.pos,
                  "Invalid attribute name '%s' in compile-time expression" % attr)
            return None
        obj = self.obj.compile_time_value(denv)
        try:
            return getattr(obj, attr)
        except Exception, e:
            self.compile_time_value_error(e)

    def type_dependencies(self, env):
        return self.obj.type_dependencies(env)

    def infer_type(self, env):
        # FIXME: this is way too redundant with analyse_types()
        node = self.analyse_as_cimported_attribute_node(env, target=False)
        if node is not None:
            return node.entry.type
        node = self.analyse_as_unbound_cmethod_node(env)
        if node is not None:
            return node.entry.type
        obj_type = self.obj.infer_type(env)
        self.analyse_attribute(env, obj_type=obj_type)
        if obj_type.is_builtin_type and self.type.is_cfunction:
            # special case: C-API replacements for C methods of
            # builtin types cannot be inferred as C functions as
            # that would prevent their use as bound methods
            return py_object_type
        return self.type

    def analyse_target_declaration(self, env):
        pass

    def analyse_target_types(self, env):
        node = self.analyse_types(env, target = 1)
        if node.type.is_const:
            error(self.pos, "Assignment to const attribute '%s'" % self.attribute)
        if not node.is_lvalue():
            error(self.pos, "Assignment to non-lvalue of type '%s'" % self.type)
        return node

    def analyse_types(self, env, target = 0):
        self.initialized_check = env.directives['initializedcheck']
        node = self.analyse_as_cimported_attribute_node(env, target)
        if node is None and not target:
            node = self.analyse_as_unbound_cmethod_node(env)
        if node is None:
            node = self.analyse_as_ordinary_attribute_node(env, target)
            assert node is not None
        if node.entry:
            node.entry.used = True
        if node.is_attribute:
            node.wrap_obj_in_nonecheck(env)
        return node

    def analyse_as_cimported_attribute_node(self, env, target):
        # Try to interpret this as a reference to an imported
        # C const, type, var or function. If successful, mutates
        # this node into a NameNode and returns 1, otherwise
        # returns 0.
        module_scope = self.obj.analyse_as_module(env)
        if module_scope:
            entry = module_scope.lookup_here(self.attribute)
            if entry and (
                    entry.is_cglobal or entry.is_cfunction
                    or entry.is_type or entry.is_const):
                return self.as_name_node(env, entry, target)
        return None

    def analyse_as_unbound_cmethod_node(self, env):
        # Try to interpret this as a reference to an unbound
        # C method of an extension type or builtin type.  If successful,
        # creates a corresponding NameNode and returns it, otherwise
        # returns None.
        type = self.obj.analyse_as_extension_type(env)
        if type:
            entry = type.scope.lookup_here(self.attribute)
            if entry and entry.is_cmethod:
                if type.is_builtin_type:
                    if not self.is_called:
                        # must handle this as Python object
                        return None
                    ubcm_entry = entry
                else:
                    # Create a temporary entry describing the C method
                    # as an ordinary function.
                    ubcm_entry = Symtab.Entry(entry.name,
                        "%s->%s" % (type.vtabptr_cname, entry.cname),
                        entry.type)
                    ubcm_entry.is_cfunction = 1
                    ubcm_entry.func_cname = entry.func_cname
                    ubcm_entry.is_unbound_cmethod = 1
                return self.as_name_node(env, ubcm_entry, target=False)
        return None

    def analyse_as_type(self, env):
        module_scope = self.obj.analyse_as_module(env)
        if module_scope:
            return module_scope.lookup_type(self.attribute)
        if not self.obj.is_string_literal:
            base_type = self.obj.analyse_as_type(env)
            if base_type and hasattr(base_type, 'scope') and base_type.scope is not None:
                return base_type.scope.lookup_type(self.attribute)
        return None

    def analyse_as_extension_type(self, env):
        # Try to interpret this as a reference to an extension type
        # in a cimported module. Returns the extension type, or None.
        module_scope = self.obj.analyse_as_module(env)
        if module_scope:
            entry = module_scope.lookup_here(self.attribute)
            if entry and entry.is_type:
                if entry.type.is_extension_type or entry.type.is_builtin_type:
                    return entry.type
        return None

    def analyse_as_module(self, env):
        # Try to interpret this as a reference to a cimported module
        # in another cimported module. Returns the module scope, or None.
        module_scope = self.obj.analyse_as_module(env)
        if module_scope:
            entry = module_scope.lookup_here(self.attribute)
            if entry and entry.as_module:
                return entry.as_module
        return None

    def as_name_node(self, env, entry, target):
        # Create a corresponding NameNode from this node and complete the
        # analyse_types phase.
        node = NameNode.from_node(self, name=self.attribute, entry=entry)
        if target:
            node = node.analyse_target_types(env)
        else:
            node = node.analyse_rvalue_entry(env)
        node.entry.used = 1
        return node

    def analyse_as_ordinary_attribute_node(self, env, target):
        self.obj = self.obj.analyse_types(env)
        self.analyse_attribute(env)
        if self.entry and self.entry.is_cmethod and not self.is_called:
#            error(self.pos, "C method can only be called")
            pass
        ## Reference to C array turns into pointer to first element.
        #while self.type.is_array:
        #    self.type = self.type.element_ptr_type()
        if self.is_py_attr:
            if not target:
                self.is_temp = 1
                self.result_ctype = py_object_type
        elif target and self.obj.type.is_builtin_type:
            error(self.pos, "Assignment to an immutable object field")
        #elif self.type.is_memoryviewslice and not target:
        #    self.is_temp = True
        return self

    def analyse_attribute(self, env, obj_type = None):
        # Look up attribute and set self.type and self.member.
        immutable_obj = obj_type is not None # used during type inference
        self.is_py_attr = 0
        self.member = self.attribute
        if obj_type is None:
            if self.obj.type.is_string or self.obj.type.is_pyunicode_ptr:
                self.obj = self.obj.coerce_to_pyobject(env)
            obj_type = self.obj.type
        else:
            if obj_type.is_string or obj_type.is_pyunicode_ptr:
                obj_type = py_object_type
        if obj_type.is_ptr or obj_type.is_array:
            obj_type = obj_type.base_type
            self.op = "->"
        elif obj_type.is_extension_type or obj_type.is_builtin_type:
            self.op = "->"
        else:
            self.op = "."
        if obj_type.has_attributes:
            if obj_type.attributes_known():
                if (obj_type.is_memoryviewslice and not
                        obj_type.scope.lookup_here(self.attribute)):
                    if self.attribute == 'T':
                        self.is_memslice_transpose = True
                        self.is_temp = True
                        self.use_managed_ref = True
                        self.type = self.obj.type
                        return
                    else:
                        obj_type.declare_attribute(self.attribute, env, self.pos)
                entry = obj_type.scope.lookup_here(self.attribute)
                if entry and entry.is_member:
                    entry = None
            else:
                error(self.pos,
                    "Cannot select attribute of incomplete type '%s'"
                    % obj_type)
                self.type = PyrexTypes.error_type
                return
            self.entry = entry
            if entry:
                if obj_type.is_extension_type and entry.name == "__weakref__":
                    error(self.pos, "Illegal use of special attribute __weakref__")

                # def methods need the normal attribute lookup
                # because they do not have struct entries
                # fused function go through assignment synthesis
                # (foo = pycfunction(foo_func_obj)) and need to go through
                # regular Python lookup as well
                if (entry.is_variable and not entry.fused_cfunction) or entry.is_cmethod:
                    self.type = entry.type
                    self.member = entry.cname
                    return
                else:
                    # If it's not a variable or C method, it must be a Python
                    # method of an extension type, so we treat it like a Python
                    # attribute.
                    pass
        # If we get here, the base object is not a struct/union/extension
        # type, or it is an extension type and the attribute is either not
        # declared or is declared as a Python method. Treat it as a Python
        # attribute reference.
        self.analyse_as_python_attribute(env, obj_type, immutable_obj)

    def analyse_as_python_attribute(self, env, obj_type=None, immutable_obj=False):
        if obj_type is None:
            obj_type = self.obj.type
        # mangle private '__*' Python attributes used inside of a class
        self.attribute = env.mangle_class_private_name(self.attribute)
        self.member = self.attribute
        self.type = py_object_type
        self.is_py_attr = 1
        if not obj_type.is_pyobject and not obj_type.is_error:
            if obj_type.can_coerce_to_pyobject(env):
                if not immutable_obj:
                    self.obj = self.obj.coerce_to_pyobject(env)
            elif (obj_type.is_cfunction and (self.obj.is_name or self.obj.is_attribute)
                  and self.obj.entry.as_variable
                  and self.obj.entry.as_variable.type.is_pyobject):
                # might be an optimised builtin function => unpack it
                if not immutable_obj:
                    self.obj = self.obj.coerce_to_pyobject(env)
            else:
                error(self.pos,
                      "Object of type '%s' has no attribute '%s'" %
                      (obj_type, self.attribute))

    def wrap_obj_in_nonecheck(self, env):
        if not env.directives['nonecheck']:
            return

        msg = None
        format_args = ()
        if (self.obj.type.is_extension_type and self.needs_none_check and not
                self.is_py_attr):
            msg = "'NoneType' object has no attribute '%s'"
            format_args = (self.attribute,)
        elif self.obj.type.is_memoryviewslice:
            if self.is_memslice_transpose:
                msg = "Cannot transpose None memoryview slice"
            else:
                entry = self.obj.type.scope.lookup_here(self.attribute)
                if entry:
                    # copy/is_c_contig/shape/strides etc
                    msg = "Cannot access '%s' attribute of None memoryview slice"
                    format_args = (entry.name,)

        if msg:
            self.obj = self.obj.as_none_safe_node(msg, 'PyExc_AttributeError',
                                                  format_args=format_args)


    def nogil_check(self, env):
        if self.is_py_attr:
            self.gil_error()
        elif self.type.is_memoryviewslice:
            import MemoryView
            MemoryView.err_if_nogil_initialized_check(self.pos, env, 'attribute')

    gil_message = "Accessing Python attribute"

    def is_simple(self):
        if self.obj:
            return self.result_in_temp() or self.obj.is_simple()
        else:
            return NameNode.is_simple(self)

    def is_lvalue(self):
        if self.obj:
            return not self.type.is_array
        else:
            return NameNode.is_lvalue(self)

    def is_ephemeral(self):
        if self.obj:
            return self.obj.is_ephemeral()
        else:
            return NameNode.is_ephemeral(self)

    def calculate_result_code(self):
        #print "AttributeNode.calculate_result_code:", self.member ###
        #print "...obj node =", self.obj, "code", self.obj.result() ###
        #print "...obj type", self.obj.type, "ctype", self.obj.ctype() ###
        obj = self.obj
        obj_code = obj.result_as(obj.type)
        #print "...obj_code =", obj_code ###
        if self.entry and self.entry.is_cmethod:
            if obj.type.is_extension_type and not self.entry.is_builtin_cmethod:
                if self.entry.final_func_cname:
                    return self.entry.final_func_cname

                if self.type.from_fused:
                    # If the attribute was specialized through indexing, make
                    # sure to get the right fused name, as our entry was
                    # replaced by our parent index node
                    # (AnalyseExpressionsTransform)
                    self.member = self.entry.cname

                return "((struct %s *)%s%s%s)->%s" % (
                    obj.type.vtabstruct_cname, obj_code, self.op,
                    obj.type.vtabslot_cname, self.member)
            elif self.result_is_used:
                return self.member
            # Generating no code at all for unused access to optimised builtin
            # methods fixes the problem that some optimisations only exist as
            # macros, i.e. there is no function pointer to them, so we would
            # generate invalid C code here.
            return
        elif obj.type.is_complex:
            return "__Pyx_C%s(%s)" % (self.member.upper(), obj_code)
        else:
            if obj.type.is_builtin_type and self.entry and self.entry.is_variable:
                # accessing a field of a builtin type, need to cast better than result_as() does
                obj_code = obj.type.cast_code(obj.result(), to_object_struct = True)
            return "%s%s%s" % (obj_code, self.op, self.member)

    def generate_result_code(self, code):
        if self.is_py_attr:
            if self.is_special_lookup:
                code.globalstate.use_utility_code(
                    UtilityCode.load_cached("PyObjectLookupSpecial", "ObjectHandling.c"))
                lookup_func_name = '__Pyx_PyObject_LookupSpecial'
            else:
                code.globalstate.use_utility_code(
                    UtilityCode.load_cached("PyObjectGetAttrStr", "ObjectHandling.c"))
                lookup_func_name = '__Pyx_PyObject_GetAttrStr'
            code.putln(
                '%s = %s(%s, %s); %s' % (
                    self.result(),
                    lookup_func_name,
                    self.obj.py_result(),
                    code.intern_identifier(self.attribute),
                    code.error_goto_if_null(self.result(), self.pos)))
            code.put_gotref(self.py_result())
        elif self.type.is_memoryviewslice:
            if self.is_memslice_transpose:
                # transpose the slice
                for access, packing in self.type.axes:
                    if access == 'ptr':
                        error(self.pos, "Transposing not supported for slices "
                                        "with indirect dimensions")
                        return

                code.putln("%s = %s;" % (self.result(), self.obj.result()))
                if self.obj.is_name or (self.obj.is_attribute and
                                        self.obj.is_memslice_transpose):
                    code.put_incref_memoryviewslice(self.result(), have_gil=True)

                T = "__pyx_memslice_transpose(&%s) == 0"
                code.putln(code.error_goto_if(T % self.result(), self.pos))
            elif self.initialized_check:
                code.putln(
                    'if (unlikely(!%s.memview)) {'
                        'PyErr_SetString(PyExc_AttributeError,'
                                        '"Memoryview is not initialized");'
                        '%s'
                    '}' % (self.result(), code.error_goto(self.pos)))
        else:
            # result_code contains what is needed, but we may need to insert
            # a check and raise an exception
            if self.obj.type.is_extension_type:
                pass
            elif self.entry and self.entry.is_cmethod and self.entry.utility_code:
                # C method implemented as function call with utility code
                code.globalstate.use_utility_code(self.entry.utility_code)

    def generate_disposal_code(self, code):
        if self.is_temp and self.type.is_memoryviewslice and self.is_memslice_transpose:
            # mirror condition for putting the memview incref here:
            if self.obj.is_name or (self.obj.is_attribute and
                                    self.obj.is_memslice_transpose):
                code.put_xdecref_memoryviewslice(
                        self.result(), have_gil=True)
        else:
            ExprNode.generate_disposal_code(self, code)

    def generate_assignment_code(self, rhs, code):
        self.obj.generate_evaluation_code(code)
        if self.is_py_attr:
            code.globalstate.use_utility_code(
                UtilityCode.load_cached("PyObjectSetAttrStr", "ObjectHandling.c"))
            code.put_error_if_neg(self.pos,
                '__Pyx_PyObject_SetAttrStr(%s, %s, %s)' % (
                    self.obj.py_result(),
                    code.intern_identifier(self.attribute),
                    rhs.py_result()))
            rhs.generate_disposal_code(code)
            rhs.free_temps(code)
        elif self.obj.type.is_complex:
            code.putln("__Pyx_SET_C%s(%s, %s);" % (
                self.member.upper(),
                self.obj.result_as(self.obj.type),
                rhs.result_as(self.ctype())))
        else:
            select_code = self.result()
            if self.type.is_pyobject and self.use_managed_ref:
                rhs.make_owned_reference(code)
                code.put_giveref(rhs.py_result())
                code.put_gotref(select_code)
                code.put_decref(select_code, self.ctype())
            elif self.type.is_memoryviewslice:
                import MemoryView
                MemoryView.put_assign_to_memviewslice(
                        select_code, rhs, rhs.result(), self.type, code)

            if not self.type.is_memoryviewslice:
                code.putln(
                    "%s = %s;" % (
                        select_code,
                        rhs.result_as(self.ctype())))
                        #rhs.result()))
            rhs.generate_post_assignment_code(code)
            rhs.free_temps(code)
        self.obj.generate_disposal_code(code)
        self.obj.free_temps(code)

    def generate_deletion_code(self, code, ignore_nonexisting=False):
        self.obj.generate_evaluation_code(code)
        if self.is_py_attr or (self.entry.scope.is_property_scope
                               and u'__del__' in self.entry.scope.entries):
            code.globalstate.use_utility_code(
                UtilityCode.load_cached("PyObjectSetAttrStr", "ObjectHandling.c"))
            code.put_error_if_neg(self.pos,
                '__Pyx_PyObject_DelAttrStr(%s, %s)' % (
                    self.obj.py_result(),
                    code.intern_identifier(self.attribute)))
        else:
            error(self.pos, "Cannot delete C attribute of extension type")
        self.obj.generate_disposal_code(code)
        self.obj.free_temps(code)

    def annotate(self, code):
        if self.is_py_attr:
            style, text = 'py_attr', 'python attribute (%s)'
        else:
            style, text = 'c_attr', 'c attribute (%s)'
        code.annotate(self.pos, AnnotationItem(style, text % self.type, size=len(self.attribute)))


#-------------------------------------------------------------------
#
#  Constructor nodes
#
#-------------------------------------------------------------------

class StarredTargetNode(ExprNode):
    #  A starred expression like "*a"
    #
    #  This is only allowed in sequence assignment targets such as
    #
    #      a, *b = (1,2,3,4)    =>     a = 1 ; b = [2,3,4]
    #
    #  and will be removed during type analysis (or generate an error
    #  if it's found at unexpected places).
    #
    #  target          ExprNode

    subexprs = ['target']
    is_starred = 1
    type = py_object_type
    is_temp = 1

    def __init__(self, pos, target):
        ExprNode.__init__(self, pos)
        self.target = target

    def analyse_declarations(self, env):
        error(self.pos, "can use starred expression only as assignment target")
        self.target.analyse_declarations(env)

    def analyse_types(self, env):
        error(self.pos, "can use starred expression only as assignment target")
        self.target = self.target.analyse_types(env)
        self.type = self.target.type
        return self

    def analyse_target_declaration(self, env):
        self.target.analyse_target_declaration(env)

    def analyse_target_types(self, env):
        self.target = self.target.analyse_target_types(env)
        self.type = self.target.type
        return self

    def calculate_result_code(self):
        return ""

    def generate_result_code(self, code):
        pass


class SequenceNode(ExprNode):
    #  Base class for list and tuple constructor nodes.
    #  Contains common code for performing sequence unpacking.
    #
    #  args                    [ExprNode]
    #  unpacked_items          [ExprNode] or None
    #  coerced_unpacked_items  [ExprNode] or None
    # mult_factor              ExprNode     the integer number of content repetitions ([1,2]*3)

    subexprs = ['args', 'mult_factor']

    is_sequence_constructor = 1
    unpacked_items = None
    mult_factor = None
    slow = False  # trade speed for code size (e.g. use PyTuple_Pack())

    def compile_time_value_list(self, denv):
        return [arg.compile_time_value(denv) for arg in self.args]

    def replace_starred_target_node(self):
        # replace a starred node in the targets by the contained expression
        self.starred_assignment = False
        args = []
        for arg in self.args:
            if arg.is_starred:
                if self.starred_assignment:
                    error(arg.pos, "more than 1 starred expression in assignment")
                self.starred_assignment = True
                arg = arg.target
                arg.is_starred = True
            args.append(arg)
        self.args = args

    def analyse_target_declaration(self, env):
        self.replace_starred_target_node()
        for arg in self.args:
            arg.analyse_target_declaration(env)

    def analyse_types(self, env, skip_children=False):
        for i in range(len(self.args)):
            arg = self.args[i]
            if not skip_children: arg = arg.analyse_types(env)
            self.args[i] = arg.coerce_to_pyobject(env)
        if self.mult_factor:
            self.mult_factor = self.mult_factor.analyse_types(env)
            if not self.mult_factor.type.is_int:
                self.mult_factor = self.mult_factor.coerce_to_pyobject(env)
        self.is_temp = 1
        # not setting self.type here, subtypes do this
        return self

    def may_be_none(self):
        return False

    def analyse_target_types(self, env):
        if self.mult_factor:
            error(self.pos, "can't assign to multiplied sequence")
        self.unpacked_items = []
        self.coerced_unpacked_items = []
        self.any_coerced_items = False
        for i, arg in enumerate(self.args):
            arg = self.args[i] = arg.analyse_target_types(env)
            if arg.is_starred:
                if not arg.type.assignable_from(Builtin.list_type):
                    error(arg.pos,
                          "starred target must have Python object (list) type")
                if arg.type is py_object_type:
                    arg.type = Builtin.list_type
            unpacked_item = PyTempNode(self.pos, env)
            coerced_unpacked_item = unpacked_item.coerce_to(arg.type, env)
            if unpacked_item is not coerced_unpacked_item:
                self.any_coerced_items = True
            self.unpacked_items.append(unpacked_item)
            self.coerced_unpacked_items.append(coerced_unpacked_item)
        self.type = py_object_type
        return self

    def generate_result_code(self, code):
        self.generate_operation_code(code)

    def generate_sequence_packing_code(self, code, target=None, plain=False):
        if target is None:
            target = self.result()
        size_factor = c_mult = ''
        mult_factor = None

        if self.mult_factor and not plain:
            mult_factor = self.mult_factor
            if mult_factor.type.is_int:
                c_mult = mult_factor.result()
                if isinstance(mult_factor.constant_result, (int,long)) \
                       and mult_factor.constant_result > 0:
                    size_factor = ' * %s' % mult_factor.constant_result
                else:
                    size_factor = ' * ((%s<0) ? 0:%s)' % (c_mult, c_mult)

        if self.type is Builtin.tuple_type and (self.is_literal or self.slow) and not c_mult:
            # use PyTuple_Pack() to avoid generating huge amounts of one-time code
            code.putln('%s = PyTuple_Pack(%d, %s); %s' % (
                target,
                len(self.args),
                ', '.join([ arg.py_result() for arg in self.args ]),
                code.error_goto_if_null(target, self.pos)))
            code.put_gotref(target)
        else:
            # build the tuple/list step by step, potentially multiplying it as we go
            if self.type is Builtin.list_type:
                create_func, set_item_func = 'PyList_New', 'PyList_SET_ITEM'
            elif self.type is Builtin.tuple_type:
                create_func, set_item_func = 'PyTuple_New', 'PyTuple_SET_ITEM'
            else:
                raise InternalError("sequence packing for unexpected type %s" % self.type)
            arg_count = len(self.args)
            code.putln("%s = %s(%s%s); %s" % (
                target, create_func, arg_count, size_factor,
                code.error_goto_if_null(target, self.pos)))
            code.put_gotref(target)

            if c_mult:
                # FIXME: can't use a temp variable here as the code may
                # end up in the constant building function.  Temps
                # currently don't work there.

                #counter = code.funcstate.allocate_temp(mult_factor.type, manage_ref=False)
                counter = Naming.quick_temp_cname
                code.putln('{ Py_ssize_t %s;' % counter)
                if arg_count == 1:
                    offset = counter
                else:
                    offset = '%s * %s' % (counter, arg_count)
                code.putln('for (%s=0; %s < %s; %s++) {' % (
                    counter, counter, c_mult, counter
                    ))
            else:
                offset = ''

            for i in xrange(arg_count):
                arg = self.args[i]
                if c_mult or not arg.result_in_temp():
                    code.put_incref(arg.result(), arg.ctype())
                code.putln("%s(%s, %s, %s);" % (
                    set_item_func,
                    target,
                    (offset and i) and ('%s + %s' % (offset, i)) or (offset or i),
                    arg.py_result()))
                code.put_giveref(arg.py_result())

            if c_mult:
                code.putln('}')
                #code.funcstate.release_temp(counter)
                code.putln('}')

        if mult_factor is not None and mult_factor.type.is_pyobject:
            code.putln('{ PyObject* %s = PyNumber_InPlaceMultiply(%s, %s); %s' % (
                Naming.quick_temp_cname, target, mult_factor.py_result(),
                code.error_goto_if_null(Naming.quick_temp_cname, self.pos)
                ))
            code.put_gotref(Naming.quick_temp_cname)
            code.put_decref(target, py_object_type)
            code.putln('%s = %s;' % (target, Naming.quick_temp_cname))
            code.putln('}')

    def generate_subexpr_disposal_code(self, code):
        if self.mult_factor and self.mult_factor.type.is_int:
            super(SequenceNode, self).generate_subexpr_disposal_code(code)
        elif self.type is Builtin.tuple_type and (self.is_literal or self.slow):
            super(SequenceNode, self).generate_subexpr_disposal_code(code)
        else:
            # We call generate_post_assignment_code here instead
            # of generate_disposal_code, because values were stored
            # in the tuple using a reference-stealing operation.
            for arg in self.args:
                arg.generate_post_assignment_code(code)
                # Should NOT call free_temps -- this is invoked by the default
                # generate_evaluation_code which will do that.
            if self.mult_factor:
                self.mult_factor.generate_disposal_code(code)

    def generate_assignment_code(self, rhs, code):
        if self.starred_assignment:
            self.generate_starred_assignment_code(rhs, code)
        else:
            self.generate_parallel_assignment_code(rhs, code)

        for item in self.unpacked_items:
            item.release(code)
        rhs.free_temps(code)

    _func_iternext_type = PyrexTypes.CPtrType(PyrexTypes.CFuncType(
        PyrexTypes.py_object_type, [
            PyrexTypes.CFuncTypeArg("it", PyrexTypes.py_object_type, None),
            ]))

    def generate_parallel_assignment_code(self, rhs, code):
        # Need to work around the fact that generate_evaluation_code
        # allocates the temps in a rather hacky way -- the assignment
        # is evaluated twice, within each if-block.
        for item in self.unpacked_items:
            item.allocate(code)
        special_unpack = (rhs.type is py_object_type
                          or rhs.type in (tuple_type, list_type)
                          or not rhs.type.is_builtin_type)
        long_enough_for_a_loop = len(self.unpacked_items) > 3

        if special_unpack:
            self.generate_special_parallel_unpacking_code(
                code, rhs, use_loop=long_enough_for_a_loop)
        else:
            code.putln("{")
            self.generate_generic_parallel_unpacking_code(
                code, rhs, self.unpacked_items, use_loop=long_enough_for_a_loop)
            code.putln("}")

        for value_node in self.coerced_unpacked_items:
            value_node.generate_evaluation_code(code)
        for i in range(len(self.args)):
            self.args[i].generate_assignment_code(
                self.coerced_unpacked_items[i], code)

    def generate_special_parallel_unpacking_code(self, code, rhs, use_loop):
        sequence_type_test = '1'
        none_check = "likely(%s != Py_None)" % rhs.py_result()
        if rhs.type is list_type:
            sequence_types = ['List']
            if rhs.may_be_none():
                sequence_type_test = none_check
        elif rhs.type is tuple_type:
            sequence_types = ['Tuple']
            if rhs.may_be_none():
                sequence_type_test = none_check
        else:
            sequence_types = ['Tuple', 'List']
            tuple_check = 'likely(PyTuple_CheckExact(%s))' % rhs.py_result()
            list_check  = 'PyList_CheckExact(%s)' % rhs.py_result()
            sequence_type_test = "(%s) || (%s)" % (tuple_check, list_check)

        code.putln("if (%s) {" % sequence_type_test)
        code.putln("PyObject* sequence = %s;" % rhs.py_result())

        # list/tuple => check size
        code.putln("#if CYTHON_COMPILING_IN_CPYTHON")
        code.putln("Py_ssize_t size = Py_SIZE(sequence);")
        code.putln("#else")
        code.putln("Py_ssize_t size = PySequence_Size(sequence);")  # < 0 => exception
        code.putln("#endif")
        code.putln("if (unlikely(size != %d)) {" % len(self.args))
        code.globalstate.use_utility_code(raise_too_many_values_to_unpack)
        code.putln("if (size > %d) __Pyx_RaiseTooManyValuesError(%d);" % (
            len(self.args), len(self.args)))
        code.globalstate.use_utility_code(raise_need_more_values_to_unpack)
        code.putln("else if (size >= 0) __Pyx_RaiseNeedMoreValuesError(size);")
        code.putln(code.error_goto(self.pos))
        code.putln("}")

        code.putln("#if CYTHON_COMPILING_IN_CPYTHON")
        # unpack items from list/tuple in unrolled loop (can't fail)
        if len(sequence_types) == 2:
            code.putln("if (likely(Py%s_CheckExact(sequence))) {" % sequence_types[0])
        for i, item in enumerate(self.unpacked_items):
            code.putln("%s = Py%s_GET_ITEM(sequence, %d); " % (
                item.result(), sequence_types[0], i))
        if len(sequence_types) == 2:
            code.putln("} else {")
            for i, item in enumerate(self.unpacked_items):
                code.putln("%s = Py%s_GET_ITEM(sequence, %d); " % (
                    item.result(), sequence_types[1], i))
            code.putln("}")
        for item in self.unpacked_items:
            code.put_incref(item.result(), item.ctype())

        code.putln("#else")
        # in non-CPython, use the PySequence protocol (which can fail)
        if not use_loop:
            for i, item in enumerate(self.unpacked_items):
                code.putln("%s = PySequence_ITEM(sequence, %d); %s" % (
                    item.result(), i,
                    code.error_goto_if_null(item.result(), self.pos)))
                code.put_gotref(item.result())
        else:
            code.putln("{")
            code.putln("Py_ssize_t i;")
            code.putln("PyObject** temps[%s] = {%s};" % (
                len(self.unpacked_items),
                ','.join(['&%s' % item.result() for item in self.unpacked_items])))
            code.putln("for (i=0; i < %s; i++) {" % len(self.unpacked_items))
            code.putln("PyObject* item = PySequence_ITEM(sequence, i); %s" % (
                code.error_goto_if_null('item', self.pos)))
            code.put_gotref('item')
            code.putln("*(temps[i]) = item;")
            code.putln("}")
            code.putln("}")

        code.putln("#endif")
        rhs.generate_disposal_code(code)

        if sequence_type_test == '1':
            code.putln("}")  # all done
        elif sequence_type_test == none_check:
            # either tuple/list or None => save some code by generating the error directly
            code.putln("} else {")
            code.globalstate.use_utility_code(
                UtilityCode.load_cached("RaiseNoneIterError", "ObjectHandling.c"))
            code.putln("__Pyx_RaiseNoneNotIterableError(); %s" % code.error_goto(self.pos))
            code.putln("}")  # all done
        else:
            code.putln("} else {")  # needs iteration fallback code
            self.generate_generic_parallel_unpacking_code(
                code, rhs, self.unpacked_items, use_loop=use_loop)
            code.putln("}")

    def generate_generic_parallel_unpacking_code(self, code, rhs, unpacked_items, use_loop, terminate=True):
        code.globalstate.use_utility_code(raise_need_more_values_to_unpack)
        code.globalstate.use_utility_code(UtilityCode.load_cached("IterFinish", "ObjectHandling.c"))
        code.putln("Py_ssize_t index = -1;") # must be at the start of a C block!

        if use_loop:
            code.putln("PyObject** temps[%s] = {%s};" % (
                len(self.unpacked_items),
                ','.join(['&%s' % item.result() for item in unpacked_items])))

        iterator_temp = code.funcstate.allocate_temp(py_object_type, manage_ref=True)
        code.putln(
            "%s = PyObject_GetIter(%s); %s" % (
                iterator_temp,
                rhs.py_result(),
                code.error_goto_if_null(iterator_temp, self.pos)))
        code.put_gotref(iterator_temp)
        rhs.generate_disposal_code(code)

        iternext_func = code.funcstate.allocate_temp(self._func_iternext_type, manage_ref=False)
        code.putln("%s = Py_TYPE(%s)->tp_iternext;" % (
            iternext_func, iterator_temp))

        unpacking_error_label = code.new_label('unpacking_failed')
        unpack_code = "%s(%s)" % (iternext_func, iterator_temp)
        if use_loop:
            code.putln("for (index=0; index < %s; index++) {" % len(unpacked_items))
            code.put("PyObject* item = %s; if (unlikely(!item)) " % unpack_code)
            code.put_goto(unpacking_error_label)
            code.put_gotref("item")
            code.putln("*(temps[index]) = item;")
            code.putln("}")
        else:
            for i, item in enumerate(unpacked_items):
                code.put(
                    "index = %d; %s = %s; if (unlikely(!%s)) " % (
                        i,
                        item.result(),
                        unpack_code,
                        item.result()))
                code.put_goto(unpacking_error_label)
                code.put_gotref(item.py_result())

        if terminate:
            code.globalstate.use_utility_code(
                UtilityCode.load_cached("UnpackItemEndCheck", "ObjectHandling.c"))
            code.put_error_if_neg(self.pos, "__Pyx_IternextUnpackEndCheck(%s, %d)" % (
                unpack_code,
                len(unpacked_items)))
            code.putln("%s = NULL;" % iternext_func)
            code.put_decref_clear(iterator_temp, py_object_type)

        unpacking_done_label = code.new_label('unpacking_done')
        code.put_goto(unpacking_done_label)

        code.put_label(unpacking_error_label)
        code.put_decref_clear(iterator_temp, py_object_type)
        code.putln("%s = NULL;" % iternext_func)
        code.putln("if (__Pyx_IterFinish() == 0) __Pyx_RaiseNeedMoreValuesError(index);")
        code.putln(code.error_goto(self.pos))
        code.put_label(unpacking_done_label)

        code.funcstate.release_temp(iternext_func)
        if terminate:
            code.funcstate.release_temp(iterator_temp)
            iterator_temp = None

        return iterator_temp

    def generate_starred_assignment_code(self, rhs, code):
        for i, arg in enumerate(self.args):
            if arg.is_starred:
                starred_target = self.unpacked_items[i]
                unpacked_fixed_items_left  = self.unpacked_items[:i]
                unpacked_fixed_items_right = self.unpacked_items[i+1:]
                break
        else:
            assert False

        iterator_temp = None
        if unpacked_fixed_items_left:
            for item in unpacked_fixed_items_left:
                item.allocate(code)
            code.putln('{')
            iterator_temp = self.generate_generic_parallel_unpacking_code(
                code, rhs, unpacked_fixed_items_left,
                use_loop=True, terminate=False)
            for i, item in enumerate(unpacked_fixed_items_left):
                value_node = self.coerced_unpacked_items[i]
                value_node.generate_evaluation_code(code)
            code.putln('}')

        starred_target.allocate(code)
        target_list = starred_target.result()
        code.putln("%s = PySequence_List(%s); %s" % (
            target_list,
            iterator_temp or rhs.py_result(),
            code.error_goto_if_null(target_list, self.pos)))
        code.put_gotref(target_list)

        if iterator_temp:
            code.put_decref_clear(iterator_temp, py_object_type)
            code.funcstate.release_temp(iterator_temp)
        else:
            rhs.generate_disposal_code(code)

        if unpacked_fixed_items_right:
            code.globalstate.use_utility_code(raise_need_more_values_to_unpack)
            length_temp = code.funcstate.allocate_temp(PyrexTypes.c_py_ssize_t_type, manage_ref=False)
            code.putln('%s = PyList_GET_SIZE(%s);' % (length_temp, target_list))
            code.putln("if (unlikely(%s < %d)) {" % (length_temp, len(unpacked_fixed_items_right)))
            code.putln("__Pyx_RaiseNeedMoreValuesError(%d+%s); %s" % (
                 len(unpacked_fixed_items_left), length_temp,
                 code.error_goto(self.pos)))
            code.putln('}')

            for item in unpacked_fixed_items_right[::-1]:
                item.allocate(code)
            for i, (item, coerced_arg) in enumerate(zip(unpacked_fixed_items_right[::-1],
                                                        self.coerced_unpacked_items[::-1])):
                code.putln('#if CYTHON_COMPILING_IN_CPYTHON')
                code.putln("%s = PyList_GET_ITEM(%s, %s-%d); " % (
                    item.py_result(), target_list, length_temp, i+1))
                # resize the list the hard way
                code.putln("((PyVarObject*)%s)->ob_size--;" % target_list)
                code.putln('#else')
                code.putln("%s = PySequence_ITEM(%s, %s-%d); " % (
                    item.py_result(), target_list, length_temp, i+1))
                code.putln('#endif')
                code.put_gotref(item.py_result())
                coerced_arg.generate_evaluation_code(code)

            code.putln('#if !CYTHON_COMPILING_IN_CPYTHON')
            sublist_temp = code.funcstate.allocate_temp(py_object_type, manage_ref=True)
            code.putln('%s = PySequence_GetSlice(%s, 0, %s-%d); %s' % (
                sublist_temp, target_list, length_temp, len(unpacked_fixed_items_right),
                code.error_goto_if_null(sublist_temp, self.pos)))
            code.put_gotref(sublist_temp)
            code.funcstate.release_temp(length_temp)
            code.put_decref(target_list, py_object_type)
            code.putln('%s = %s; %s = NULL;' % (target_list, sublist_temp, sublist_temp))
            code.putln('#else')
            code.putln('%s = %s;' % (sublist_temp, sublist_temp)) # avoid warning about unused variable
            code.funcstate.release_temp(sublist_temp)
            code.putln('#endif')

        for i, arg in enumerate(self.args):
            arg.generate_assignment_code(self.coerced_unpacked_items[i], code)

    def annotate(self, code):
        for arg in self.args:
            arg.annotate(code)
        if self.unpacked_items:
            for arg in self.unpacked_items:
                arg.annotate(code)
            for arg in self.coerced_unpacked_items:
                arg.annotate(code)


class TupleNode(SequenceNode):
    #  Tuple constructor.

    type = tuple_type
    is_partly_literal = False

    gil_message = "Constructing Python tuple"

    def analyse_types(self, env, skip_children=False):
        if len(self.args) == 0:
            node = self
            node.is_temp = False
            node.is_literal = True
        else:
            node = SequenceNode.analyse_types(self, env, skip_children)
            for child in node.args:
                if not child.is_literal:
                    break
            else:
                if not node.mult_factor or node.mult_factor.is_literal and \
                       isinstance(node.mult_factor.constant_result, (int, long)):
                    node.is_temp = False
                    node.is_literal = True
                else:
                    if not node.mult_factor.type.is_pyobject:
                        node.mult_factor = node.mult_factor.coerce_to_pyobject(env)
                    node.is_temp = True
                    node.is_partly_literal = True
        return node

    def is_simple(self):
        # either temp or constant => always simple
        return True

    def nonlocally_immutable(self):
        # either temp or constant => always safe
        return True

    def calculate_result_code(self):
        if len(self.args) > 0:
            return self.result_code
        else:
            return Naming.empty_tuple

    def calculate_constant_result(self):
        self.constant_result = tuple([
                arg.constant_result for arg in self.args])

    def compile_time_value(self, denv):
        values = self.compile_time_value_list(denv)
        try:
            return tuple(values)
        except Exception, e:
            self.compile_time_value_error(e)

    def generate_operation_code(self, code):
        if len(self.args) == 0:
            # result_code is Naming.empty_tuple
            return
        if self.is_partly_literal:
            # underlying tuple is const, but factor is not
            tuple_target = code.get_py_const(py_object_type, 'tuple', cleanup_level=2)
            const_code = code.get_cached_constants_writer()
            const_code.mark_pos(self.pos)
            self.generate_sequence_packing_code(const_code, tuple_target, plain=True)
            const_code.put_giveref(tuple_target)
            code.putln('%s = PyNumber_Multiply(%s, %s); %s' % (
                self.result(), tuple_target, self.mult_factor.py_result(),
                code.error_goto_if_null(self.result(), self.pos)
                ))
            code.put_gotref(self.py_result())
        elif self.is_literal:
            # non-empty cached tuple => result is global constant,
            # creation code goes into separate code writer
            self.result_code = code.get_py_const(py_object_type, 'tuple', cleanup_level=2)
            code = code.get_cached_constants_writer()
            code.mark_pos(self.pos)
            self.generate_sequence_packing_code(code)
            code.put_giveref(self.py_result())
        else:
            self.generate_sequence_packing_code(code)


class ListNode(SequenceNode):
    #  List constructor.

    # obj_conversion_errors    [PyrexError]   used internally
    # orignial_args            [ExprNode]     used internally

    obj_conversion_errors = []
    type = list_type
    in_module_scope = False

    gil_message = "Constructing Python list"

    def type_dependencies(self, env):
        return ()

    def infer_type(self, env):
        # TOOD: Infer non-object list arrays.
        return list_type

    def analyse_expressions(self, env):
        node = SequenceNode.analyse_expressions(self, env)
        return node.coerce_to_pyobject(env)

    def analyse_types(self, env):
        hold_errors()
        self.original_args = list(self.args)
        node = SequenceNode.analyse_types(self, env)
        node.obj_conversion_errors = held_errors()
        release_errors(ignore=True)
        if env.is_module_scope:
            self.in_module_scope = True
        return node

    def coerce_to(self, dst_type, env):
        if dst_type.is_pyobject:
            for err in self.obj_conversion_errors:
                report_error(err)
            self.obj_conversion_errors = []
            if not self.type.subtype_of(dst_type):
                error(self.pos, "Cannot coerce list to type '%s'" % dst_type)
        elif self.mult_factor:
            error(self.pos, "Cannot coerce multiplied list to '%s'" % dst_type)
        elif dst_type.is_ptr and dst_type.base_type is not PyrexTypes.c_void_type:
            base_type = dst_type.base_type
            self.type = PyrexTypes.CArrayType(base_type, len(self.args))
            for i in range(len(self.original_args)):
                arg = self.args[i]
                if isinstance(arg, CoerceToPyTypeNode):
                    arg = arg.arg
                self.args[i] = arg.coerce_to(base_type, env)
        elif dst_type.is_struct:
            if len(self.args) > len(dst_type.scope.var_entries):
                error(self.pos, "Too may members for '%s'" % dst_type)
            else:
                if len(self.args) < len(dst_type.scope.var_entries):
                    warning(self.pos, "Too few members for '%s'" % dst_type, 1)
                for i, (arg, member) in enumerate(zip(self.original_args, dst_type.scope.var_entries)):
                    if isinstance(arg, CoerceToPyTypeNode):
                        arg = arg.arg
                    self.args[i] = arg.coerce_to(member.type, env)
            self.type = dst_type
        else:
            self.type = error_type
            error(self.pos, "Cannot coerce list to type '%s'" % dst_type)
        return self

    def as_tuple(self):
        t = TupleNode(self.pos, args=self.args, mult_factor=self.mult_factor)
        if isinstance(self.constant_result, list):
            t.constant_result = tuple(self.constant_result)
        return t

    def allocate_temp_result(self, code):
        if self.type.is_array and self.in_module_scope:
            self.temp_code = code.funcstate.allocate_temp(
                self.type, manage_ref=False, static=True)
        else:
            SequenceNode.allocate_temp_result(self, code)

    def release_temp_result(self, env):
        if self.type.is_array:
            # To be valid C++, we must allocate the memory on the stack
            # manually and be sure not to reuse it for something else.
            pass
        else:
            SequenceNode.release_temp_result(self, env)

    def calculate_constant_result(self):
        if self.mult_factor:
            raise ValueError() # may exceed the compile time memory
        self.constant_result = [
            arg.constant_result for arg in self.args]

    def compile_time_value(self, denv):
        l = self.compile_time_value_list(denv)
        if self.mult_factor:
            l *= self.mult_factor.compile_time_value(denv)
        return l

    def generate_operation_code(self, code):
        if self.type.is_pyobject:
            for err in self.obj_conversion_errors:
                report_error(err)
            self.generate_sequence_packing_code(code)
        elif self.type.is_array:
            for i, arg in enumerate(self.args):
                code.putln("%s[%s] = %s;" % (
                                self.result(),
                                i,
                                arg.result()))
        elif self.type.is_struct:
            for arg, member in zip(self.args, self.type.scope.var_entries):
                code.putln("%s.%s = %s;" % (
                        self.result(),
                        member.cname,
                        arg.result()))
        else:
            raise InternalError("List type never specified")


class ScopedExprNode(ExprNode):
    # Abstract base class for ExprNodes that have their own local
    # scope, such as generator expressions.
    #
    # expr_scope    Scope  the inner scope of the expression

    subexprs = []
    expr_scope = None

    # does this node really have a local scope, e.g. does it leak loop
    # variables or not?  non-leaking Py3 behaviour is default, except
    # for list comprehensions where the behaviour differs in Py2 and
    # Py3 (set in Parsing.py based on parser context)
    has_local_scope = True

    def init_scope(self, outer_scope, expr_scope=None):
        if expr_scope is not None:
            self.expr_scope = expr_scope
        elif self.has_local_scope:
            self.expr_scope = Symtab.GeneratorExpressionScope(outer_scope)
        else:
            self.expr_scope = None

    def analyse_declarations(self, env):
        self.init_scope(env)

    def analyse_scoped_declarations(self, env):
        # this is called with the expr_scope as env
        pass

    def analyse_types(self, env):
        # no recursion here, the children will be analysed separately below
        return self

    def analyse_scoped_expressions(self, env):
        # this is called with the expr_scope as env
        return self

    def generate_evaluation_code(self, code):
        # set up local variables and free their references on exit
        generate_inner_evaluation_code = super(ScopedExprNode, self).generate_evaluation_code
        if not self.has_local_scope or not self.expr_scope.var_entries:
            # no local variables => delegate, done
            generate_inner_evaluation_code(code)
            return

        code.putln('{ /* enter inner scope */')
        py_entries = []
        for entry in self.expr_scope.var_entries:
            if not entry.in_closure:
                code.put_var_declaration(entry)
                if entry.type.is_pyobject and entry.used:
                    py_entries.append(entry)
        if not py_entries:
            # no local Python references => no cleanup required
            generate_inner_evaluation_code(code)
            code.putln('} /* exit inner scope */')
            return

        # must free all local Python references at each exit point
        old_loop_labels = tuple(code.new_loop_labels())
        old_error_label = code.new_error_label()

        generate_inner_evaluation_code(code)

        # normal (non-error) exit
        for entry in py_entries:
            code.put_var_decref(entry)

        # error/loop body exit points
        exit_scope = code.new_label('exit_scope')
        code.put_goto(exit_scope)
        for label, old_label in ([(code.error_label, old_error_label)] +
                                 list(zip(code.get_loop_labels(), old_loop_labels))):
            if code.label_used(label):
                code.put_label(label)
                for entry in py_entries:
                    code.put_var_decref(entry)
                code.put_goto(old_label)
        code.put_label(exit_scope)
        code.putln('} /* exit inner scope */')

        code.set_loop_labels(old_loop_labels)
        code.error_label = old_error_label


class ComprehensionNode(ScopedExprNode):
    # A list/set/dict comprehension

    child_attrs = ["loop"]

    is_temp = True

    def infer_type(self, env):
        return self.type

    def analyse_declarations(self, env):
        self.append.target = self # this is used in the PyList_Append of the inner loop
        self.init_scope(env)

    def analyse_scoped_declarations(self, env):
        self.loop.analyse_declarations(env)

    def analyse_types(self, env):
        if not self.has_local_scope:
            self.loop = self.loop.analyse_expressions(env)
        return self

    def analyse_scoped_expressions(self, env):
        if self.has_local_scope:
            self.loop = self.loop.analyse_expressions(env)
        return self

    def may_be_none(self):
        return False

    def generate_result_code(self, code):
        self.generate_operation_code(code)

    def generate_operation_code(self, code):
        if self.type is Builtin.list_type:
            create_code = 'PyList_New(0)'
        elif self.type is Builtin.set_type:
            create_code = 'PySet_New(NULL)'
        elif self.type is Builtin.dict_type:
            create_code = 'PyDict_New()'
        else:
            raise InternalError("illegal type for comprehension: %s" % self.type)
        code.putln('%s = %s; %s' % (
            self.result(), create_code,
            code.error_goto_if_null(self.result(), self.pos)))

        code.put_gotref(self.result())
        self.loop.generate_execution_code(code)

    def annotate(self, code):
        self.loop.annotate(code)


class ComprehensionAppendNode(Node):
    # Need to be careful to avoid infinite recursion:
    # target must not be in child_attrs/subexprs

    child_attrs = ['expr']
    target = None

    type = PyrexTypes.c_int_type

    def analyse_expressions(self, env):
        self.expr = self.expr.analyse_expressions(env)
        if not self.expr.type.is_pyobject:
            self.expr = self.expr.coerce_to_pyobject(env)
        return self

    def generate_execution_code(self, code):
        if self.target.type is list_type:
            code.globalstate.use_utility_code(
                UtilityCode.load_cached("ListCompAppend", "Optimize.c"))
            function = "__Pyx_ListComp_Append"
        elif self.target.type is set_type:
            function = "PySet_Add"
        else:
            raise InternalError(
                "Invalid type for comprehension node: %s" % self.target.type)

        self.expr.generate_evaluation_code(code)
        code.putln(code.error_goto_if("%s(%s, (PyObject*)%s)" % (
            function,
            self.target.result(),
            self.expr.result()
            ), self.pos))
        self.expr.generate_disposal_code(code)
        self.expr.free_temps(code)

    def generate_function_definitions(self, env, code):
        self.expr.generate_function_definitions(env, code)

    def annotate(self, code):
        self.expr.annotate(code)

class DictComprehensionAppendNode(ComprehensionAppendNode):
    child_attrs = ['key_expr', 'value_expr']

    def analyse_expressions(self, env):
        self.key_expr = self.key_expr.analyse_expressions(env)
        if not self.key_expr.type.is_pyobject:
            self.key_expr = self.key_expr.coerce_to_pyobject(env)
        self.value_expr = self.value_expr.analyse_expressions(env)
        if not self.value_expr.type.is_pyobject:
            self.value_expr = self.value_expr.coerce_to_pyobject(env)
        return self

    def generate_execution_code(self, code):
        self.key_expr.generate_evaluation_code(code)
        self.value_expr.generate_evaluation_code(code)
        code.putln(code.error_goto_if("PyDict_SetItem(%s, (PyObject*)%s, (PyObject*)%s)" % (
            self.target.result(),
            self.key_expr.result(),
            self.value_expr.result()
            ), self.pos))
        self.key_expr.generate_disposal_code(code)
        self.key_expr.free_temps(code)
        self.value_expr.generate_disposal_code(code)
        self.value_expr.free_temps(code)

    def generate_function_definitions(self, env, code):
        self.key_expr.generate_function_definitions(env, code)
        self.value_expr.generate_function_definitions(env, code)

    def annotate(self, code):
        self.key_expr.annotate(code)
        self.value_expr.annotate(code)


class InlinedGeneratorExpressionNode(ScopedExprNode):
    # An inlined generator expression for which the result is
    # calculated inside of the loop.  This will only be created by
    # transforms when replacing builtin calls on generator
    # expressions.
    #
    # loop           ForStatNode      the for-loop, not containing any YieldExprNodes
    # result_node    ResultRefNode    the reference to the result value temp
    # orig_func      String           the name of the builtin function this node replaces

    child_attrs = ["loop"]
    loop_analysed = False
    type = py_object_type

    def analyse_scoped_declarations(self, env):
        self.loop.analyse_declarations(env)

    def may_be_none(self):
        return False

    def annotate(self, code):
        self.loop.annotate(code)

    def infer_type(self, env):
        return self.result_node.infer_type(env)

    def analyse_types(self, env):
        if not self.has_local_scope:
            self.loop_analysed = True
            self.loop = self.loop.analyse_expressions(env)
        self.type = self.result_node.type
        self.is_temp = True
        return self

    def analyse_scoped_expressions(self, env):
        self.loop_analysed = True
        if self.has_local_scope:
            self.loop = self.loop.analyse_expressions(env)
        return self

    def coerce_to(self, dst_type, env):
        if self.orig_func == 'sum' and dst_type.is_numeric and not self.loop_analysed:
            # We can optimise by dropping the aggregation variable and
            # the add operations into C.  This can only be done safely
            # before analysing the loop body, after that, the result
            # reference type will have infected expressions and
            # assignments.
            self.result_node.type = self.type = dst_type
            return self
        return super(InlinedGeneratorExpressionNode, self).coerce_to(dst_type, env)

    def generate_result_code(self, code):
        self.result_node.result_code = self.result()
        self.loop.generate_execution_code(code)


class SetNode(ExprNode):
    #  Set constructor.

    type = set_type

    subexprs = ['args']

    gil_message = "Constructing Python set"

    def analyse_types(self, env):
        for i in range(len(self.args)):
            arg = self.args[i]
            arg = arg.analyse_types(env)
            self.args[i] = arg.coerce_to_pyobject(env)
        self.type = set_type
        self.is_temp = 1
        return self

    def may_be_none(self):
        return False

    def calculate_constant_result(self):
        self.constant_result = set([
                arg.constant_result for arg in self.args])

    def compile_time_value(self, denv):
        values = [arg.compile_time_value(denv) for arg in self.args]
        try:
            return set(values)
        except Exception, e:
            self.compile_time_value_error(e)

    def generate_evaluation_code(self, code):
        code.globalstate.use_utility_code(Builtin.py_set_utility_code)
        self.allocate_temp_result(code)
        code.putln(
            "%s = PySet_New(0); %s" % (
                self.result(),
                code.error_goto_if_null(self.result(), self.pos)))
        code.put_gotref(self.py_result())
        for arg in self.args:
            arg.generate_evaluation_code(code)
            code.put_error_if_neg(
                self.pos,
                "PySet_Add(%s, %s)" % (self.result(), arg.py_result()))
            arg.generate_disposal_code(code)
            arg.free_temps(code)


class DictNode(ExprNode):
    #  Dictionary constructor.
    #
    #  key_value_pairs     [DictItemNode]
    #  exclude_null_values [boolean]          Do not add NULL values to dict
    #
    # obj_conversion_errors    [PyrexError]   used internally

    subexprs = ['key_value_pairs']
    is_temp = 1
    exclude_null_values = False
    type = dict_type

    obj_conversion_errors = []

    @classmethod
    def from_pairs(cls, pos, pairs):
        return cls(pos, key_value_pairs=[
                DictItemNode(pos, key=k, value=v) for k, v in pairs])

    def calculate_constant_result(self):
        self.constant_result = dict([
                item.constant_result for item in self.key_value_pairs])

    def compile_time_value(self, denv):
        pairs = [(item.key.compile_time_value(denv), item.value.compile_time_value(denv))
            for item in self.key_value_pairs]
        try:
            return dict(pairs)
        except Exception, e:
            self.compile_time_value_error(e)

    def type_dependencies(self, env):
        return ()

    def infer_type(self, env):
        # TOOD: Infer struct constructors.
        return dict_type

    def analyse_types(self, env):
        hold_errors()
        self.key_value_pairs = [ item.analyse_types(env)
                                 for item in self.key_value_pairs ]
        self.obj_conversion_errors = held_errors()
        release_errors(ignore=True)
        return self

    def may_be_none(self):
        return False

    def coerce_to(self, dst_type, env):
        if dst_type.is_pyobject:
            self.release_errors()
            if not self.type.subtype_of(dst_type):
                error(self.pos, "Cannot interpret dict as type '%s'" % dst_type)
        elif dst_type.is_struct_or_union:
            self.type = dst_type
            if not dst_type.is_struct and len(self.key_value_pairs) != 1:
                error(self.pos, "Exactly one field must be specified to convert to union '%s'" % dst_type)
            elif dst_type.is_struct and len(self.key_value_pairs) < len(dst_type.scope.var_entries):
                warning(self.pos, "Not all members given for struct '%s'" % dst_type, 1)
            for item in self.key_value_pairs:
                if isinstance(item.key, CoerceToPyTypeNode):
                    item.key = item.key.arg
                if not item.key.is_string_literal:
                    error(item.key.pos, "Invalid struct field identifier")
                    item.key = StringNode(item.key.pos, value="<error>")
                else:
                    key = str(item.key.value) # converts string literals to unicode in Py3
                    member = dst_type.scope.lookup_here(key)
                    if not member:
                        error(item.key.pos, "struct '%s' has no field '%s'" % (dst_type, key))
                    else:
                        value = item.value
                        if isinstance(value, CoerceToPyTypeNode):
                            value = value.arg
                        item.value = value.coerce_to(member.type, env)
        else:
            self.type = error_type
            error(self.pos, "Cannot interpret dict as type '%s'" % dst_type)
        return self

    def release_errors(self):
        for err in self.obj_conversion_errors:
            report_error(err)
        self.obj_conversion_errors = []

    gil_message = "Constructing Python dict"

    def generate_evaluation_code(self, code):
        #  Custom method used here because key-value
        #  pairs are evaluated and used one at a time.
        code.mark_pos(self.pos)
        self.allocate_temp_result(code)
        if self.type.is_pyobject:
            self.release_errors()
            code.putln(
                "%s = PyDict_New(); %s" % (
                    self.result(),
                    code.error_goto_if_null(self.result(), self.pos)))
            code.put_gotref(self.py_result())
        for item in self.key_value_pairs:
            item.generate_evaluation_code(code)
            if self.type.is_pyobject:
                if self.exclude_null_values:
                    code.putln('if (%s) {' % item.value.py_result())
                code.put_error_if_neg(self.pos,
                    "PyDict_SetItem(%s, %s, %s)" % (
                        self.result(),
                        item.key.py_result(),
                        item.value.py_result()))
                if self.exclude_null_values:
                    code.putln('}')
            else:
                code.putln("%s.%s = %s;" % (
                        self.result(),
                        item.key.value,
                        item.value.result()))
            item.generate_disposal_code(code)
            item.free_temps(code)

    def annotate(self, code):
        for item in self.key_value_pairs:
            item.annotate(code)

class DictItemNode(ExprNode):
    # Represents a single item in a DictNode
    #
    # key          ExprNode
    # value        ExprNode
    subexprs = ['key', 'value']

    nogil_check = None # Parent DictNode takes care of it

    def calculate_constant_result(self):
        self.constant_result = (
            self.key.constant_result, self.value.constant_result)

    def analyse_types(self, env):
        self.key = self.key.analyse_types(env)
        self.value = self.value.analyse_types(env)
        self.key = self.key.coerce_to_pyobject(env)
        self.value = self.value.coerce_to_pyobject(env)
        return self

    def generate_evaluation_code(self, code):
        self.key.generate_evaluation_code(code)
        self.value.generate_evaluation_code(code)

    def generate_disposal_code(self, code):
        self.key.generate_disposal_code(code)
        self.value.generate_disposal_code(code)

    def free_temps(self, code):
        self.key.free_temps(code)
        self.value.free_temps(code)

    def __iter__(self):
        return iter([self.key, self.value])


class SortedDictKeysNode(ExprNode):
    # build sorted list of dict keys, e.g. for dir()
    subexprs = ['arg']

    is_temp = True

    def __init__(self, arg):
        ExprNode.__init__(self, arg.pos, arg=arg)
        self.type = Builtin.list_type

    def analyse_types(self, env):
        arg = self.arg.analyse_types(env)
        if arg.type is Builtin.dict_type:
            arg = arg.as_none_safe_node(
                "'NoneType' object is not iterable")
        self.arg = arg
        return self

    def may_be_none(self):
        return False

    def generate_result_code(self, code):
        dict_result = self.arg.py_result()
        if self.arg.type is Builtin.dict_type:
            function = 'PyDict_Keys'
        else:
            function = 'PyMapping_Keys'
        code.putln('%s = %s(%s); %s' % (
            self.result(), function, dict_result,
            code.error_goto_if_null(self.result(), self.pos)))
        code.put_gotref(self.py_result())
        code.put_error_if_neg(
            self.pos, 'PyList_Sort(%s)' % self.py_result())


class ModuleNameMixin(object):
    def get_py_mod_name(self, code):
        return code.get_py_string_const(
            self.module_name, identifier=True)

    def get_py_qualified_name(self, code):
        return code.get_py_string_const(
            self.qualname, identifier=True)


class ClassNode(ExprNode, ModuleNameMixin):
    #  Helper class used in the implementation of Python
    #  class definitions. Constructs a class object given
    #  a name, tuple of bases and class dictionary.
    #
    #  name         EncodedString      Name of the class
    #  bases        ExprNode           Base class tuple
    #  dict         ExprNode           Class dict (not owned by this node)
    #  doc          ExprNode or None   Doc string
    #  module_name  EncodedString      Name of defining module

    subexprs = ['bases', 'doc']

    def analyse_types(self, env):
        self.bases = self.bases.analyse_types(env)
        if self.doc:
            self.doc = self.doc.analyse_types(env)
            self.doc = self.doc.coerce_to_pyobject(env)
        self.type = py_object_type
        self.is_temp = 1
        env.use_utility_code(UtilityCode.load_cached("CreateClass", "ObjectHandling.c"))
        return self

    def may_be_none(self):
        return True

    gil_message = "Constructing Python class"

    def generate_result_code(self, code):
        cname = code.intern_identifier(self.name)

        if self.doc:
            code.put_error_if_neg(self.pos,
                'PyDict_SetItem(%s, %s, %s)' % (
                    self.dict.py_result(),
                    code.intern_identifier(
                        StringEncoding.EncodedString("__doc__")),
                    self.doc.py_result()))
        py_mod_name = self.get_py_mod_name(code)
        qualname = self.get_py_qualified_name(code)
        code.putln(
            '%s = __Pyx_CreateClass(%s, %s, %s, %s, %s); %s' % (
                self.result(),
                self.bases.py_result(),
                self.dict.py_result(),
                cname,
                qualname,
                py_mod_name,
                code.error_goto_if_null(self.result(), self.pos)))
        code.put_gotref(self.py_result())


class Py3ClassNode(ExprNode):
    #  Helper class used in the implementation of Python3+
    #  class definitions. Constructs a class object given
    #  a name, tuple of bases and class dictionary.
    #
    #  name         EncodedString      Name of the class
    #  dict         ExprNode           Class dict (not owned by this node)
    #  module_name  EncodedString      Name of defining module
    #  calculate_metaclass  bool       should call CalculateMetaclass()
    #  allow_py2_metaclass  bool       should look for Py2 metaclass

    subexprs = []

    def analyse_types(self, env):
        self.type = py_object_type
        self.is_temp = 1
        return self

    def may_be_none(self):
        return True

    gil_message = "Constructing Python class"

    def generate_result_code(self, code):
        code.globalstate.use_utility_code(UtilityCode.load_cached("Py3ClassCreate", "ObjectHandling.c"))
        cname = code.intern_identifier(self.name)
        if self.mkw:
            mkw = self.mkw.py_result()
        else:
            mkw = 'NULL'
        if self.metaclass:
            metaclass = self.metaclass.result()
        else:
            metaclass = "((PyObject*)&__Pyx_DefaultClassType)"
        code.putln(
            '%s = __Pyx_Py3ClassCreate(%s, %s, %s, %s, %s, %d, %d); %s' % (
                self.result(),
                metaclass,
                cname,
                self.bases.py_result(),
                self.dict.py_result(),
                mkw,
                self.calculate_metaclass,
                self.allow_py2_metaclass,
                code.error_goto_if_null(self.result(), self.pos)))
        code.put_gotref(self.py_result())

class KeywordArgsNode(ExprNode):
    #  Helper class for keyword arguments.
    #
    #  starstar_arg      DictNode
    #  keyword_args      [DictItemNode]

    subexprs = ['starstar_arg', 'keyword_args']
    is_temp = 1
    type = dict_type

    def calculate_constant_result(self):
        result = dict(self.starstar_arg.constant_result)
        for item in self.keyword_args:
            key, value = item.constant_result
            if key in result:
                raise ValueError("duplicate keyword argument found: %s" % key)
            result[key] = value
        self.constant_result = result

    def compile_time_value(self, denv):
        result = self.starstar_arg.compile_time_value(denv)
        pairs = [ (item.key.compile_time_value(denv), item.value.compile_time_value(denv))
                  for item in self.keyword_args ]
        try:
            result = dict(result)
            for key, value in pairs:
                if key in result:
                    raise ValueError("duplicate keyword argument found: %s" % key)
                result[key] = value
        except Exception, e:
            self.compile_time_value_error(e)
        return result

    def type_dependencies(self, env):
        return ()

    def infer_type(self, env):
        return dict_type

    def analyse_types(self, env):
        arg = self.starstar_arg.analyse_types(env)
        arg = arg.coerce_to_pyobject(env)
        self.starstar_arg = arg.as_none_safe_node(
            # FIXME: CPython's error message starts with the runtime function name
            'argument after ** must be a mapping, not NoneType')
        self.keyword_args = [ item.analyse_types(env)
                              for item in self.keyword_args ]
        return self

    def may_be_none(self):
        return False

    gil_message = "Constructing Python dict"

    def generate_evaluation_code(self, code):
        code.mark_pos(self.pos)
        self.allocate_temp_result(code)
        self.starstar_arg.generate_evaluation_code(code)
        if self.starstar_arg.type is not Builtin.dict_type:
            # CPython supports calling functions with non-dicts, so do we
            code.putln('if (likely(PyDict_Check(%s))) {' %
                       self.starstar_arg.py_result())
        if self.keyword_args:
            code.putln(
                "%s = PyDict_Copy(%s); %s" % (
                    self.result(),
                    self.starstar_arg.py_result(),
                    code.error_goto_if_null(self.result(), self.pos)))
            code.put_gotref(self.py_result())
        else:
            code.putln("%s = %s;" % (
                self.result(),
                self.starstar_arg.py_result()))
            code.put_incref(self.result(), py_object_type)
        if self.starstar_arg.type is not Builtin.dict_type:
            code.putln('} else {')
            code.putln(
                "%s = PyObject_CallFunctionObjArgs("
                "(PyObject*)&PyDict_Type, %s, NULL); %s" % (
                    self.result(),
                    self.starstar_arg.py_result(),
                    code.error_goto_if_null(self.result(), self.pos)))
            code.put_gotref(self.py_result())
            code.putln('}')
        self.starstar_arg.generate_disposal_code(code)
        self.starstar_arg.free_temps(code)

        if not self.keyword_args:
            return

        code.globalstate.use_utility_code(
            UtilityCode.load_cached("RaiseDoubleKeywords", "FunctionArguments.c"))
        for item in self.keyword_args:
            item.generate_evaluation_code(code)
            code.putln("if (unlikely(PyDict_GetItem(%s, %s))) {" % (
                    self.result(),
                    item.key.py_result()))
            # FIXME: find out function name at runtime!
            code.putln('__Pyx_RaiseDoubleKeywordsError("function", %s); %s' % (
                item.key.py_result(),
                code.error_goto(self.pos)))
            code.putln("}")
            code.put_error_if_neg(self.pos,
                "PyDict_SetItem(%s, %s, %s)" % (
                    self.result(),
                    item.key.py_result(),
                    item.value.py_result()))
            item.generate_disposal_code(code)
            item.free_temps(code)

    def annotate(self, code):
        self.starstar_arg.annotate(code)
        for item in self.keyword_args:
            item.annotate(code)

class PyClassMetaclassNode(ExprNode):
    # Helper class holds Python3 metaclass object
    #
    #  bases        ExprNode           Base class tuple (not owned by this node)
    #  mkw          ExprNode           Class keyword arguments (not owned by this node)

    subexprs = []

    def analyse_types(self, env):
        self.type = py_object_type
        self.is_temp = True
        return self

    def may_be_none(self):
        return True

    def generate_result_code(self, code):
        if self.mkw:
            code.globalstate.use_utility_code(
                UtilityCode.load_cached("Py3MetaclassGet", "ObjectHandling.c"))
            call = "__Pyx_Py3MetaclassGet(%s, %s)" % (
                self.bases.result(),
                self.mkw.result())
        else:
            code.globalstate.use_utility_code(
                UtilityCode.load_cached("CalculateMetaclass", "ObjectHandling.c"))
            call = "__Pyx_CalculateMetaclass(NULL, %s)" % (
                self.bases.result())
        code.putln(
            "%s = %s; %s" % (
                self.result(), call,
                code.error_goto_if_null(self.result(), self.pos)))
        code.put_gotref(self.py_result())

class PyClassNamespaceNode(ExprNode, ModuleNameMixin):
    # Helper class holds Python3 namespace object
    #
    # All this are not owned by this node
    #  metaclass    ExprNode           Metaclass object
    #  bases        ExprNode           Base class tuple
    #  mkw          ExprNode           Class keyword arguments
    #  doc          ExprNode or None   Doc string (owned)

    subexprs = ['doc']

    def analyse_types(self, env):
        if self.doc:
            self.doc = self.doc.analyse_types(env)
            self.doc = self.doc.coerce_to_pyobject(env)
        self.type = py_object_type
        self.is_temp = 1
        return self

    def may_be_none(self):
        return True

    def generate_result_code(self, code):
        cname = code.intern_identifier(self.name)
        py_mod_name = self.get_py_mod_name(code)
        qualname = self.get_py_qualified_name(code)
        if self.doc:
            doc_code = self.doc.result()
        else:
            doc_code = '(PyObject *) NULL'
        if self.mkw:
            mkw = self.mkw.py_result()
        else:
            mkw = '(PyObject *) NULL'
        if self.metaclass:
            metaclass = self.metaclass.result()
        else:
            metaclass = "(PyObject *) NULL"
        code.putln(
            "%s = __Pyx_Py3MetaclassPrepare(%s, %s, %s, %s, %s, %s, %s); %s" % (
                self.result(),
                metaclass,
                self.bases.result(),
                cname,
                qualname,
                mkw,
                py_mod_name,
                doc_code,
                code.error_goto_if_null(self.result(), self.pos)))
        code.put_gotref(self.py_result())


class ClassCellInjectorNode(ExprNode):
    # Initialize CyFunction.func_classobj
    is_temp = True
    type = py_object_type
    subexprs = []
    is_active = False

    def analyse_expressions(self, env):
        if self.is_active:
            env.use_utility_code(
                UtilityCode.load_cached("CyFunctionClassCell", "CythonFunction.c"))
        return self

    def generate_evaluation_code(self, code):
        if self.is_active:
            self.allocate_temp_result(code)
            code.putln(
                '%s = PyList_New(0); %s' % (
                    self.result(),
                    code.error_goto_if_null(self.result(), self.pos)))
            code.put_gotref(self.result())

    def generate_injection_code(self, code, classobj_cname):
        if self.is_active:
            code.putln('__Pyx_CyFunction_InitClassCell(%s, %s);' % (
                self.result(), classobj_cname))


class ClassCellNode(ExprNode):
    # Class Cell for noargs super()
    subexprs = []
    is_temp = True
    is_generator = False
    type = py_object_type

    def analyse_types(self, env):
        return self

    def generate_result_code(self, code):
        if not self.is_generator:
            code.putln('%s = __Pyx_CyFunction_GetClassObj(%s);' % (
                self.result(),
                Naming.self_cname))
        else:
            code.putln('%s =  %s->classobj;' % (
                self.result(), Naming.generator_cname))
        code.putln(
            'if (!%s) { PyErr_SetString(PyExc_SystemError, '
            '"super(): empty __class__ cell"); %s }' % (
                self.result(),
                code.error_goto(self.pos)))
        code.put_incref(self.result(), py_object_type)


class BoundMethodNode(ExprNode):
    #  Helper class used in the implementation of Python
    #  class definitions. Constructs an bound method
    #  object from a class and a function.
    #
    #  function      ExprNode   Function object
    #  self_object   ExprNode   self object

    subexprs = ['function']

    def analyse_types(self, env):
        self.function = self.function.analyse_types(env)
        self.type = py_object_type
        self.is_temp = 1
        return self

    gil_message = "Constructing a bound method"

    def generate_result_code(self, code):
        code.putln(
            "%s = PyMethod_New(%s, %s, (PyObject*)%s->ob_type); %s" % (
                self.result(),
                self.function.py_result(),
                self.self_object.py_result(),
                self.self_object.py_result(),
                code.error_goto_if_null(self.result(), self.pos)))
        code.put_gotref(self.py_result())

class UnboundMethodNode(ExprNode):
    #  Helper class used in the implementation of Python
    #  class definitions. Constructs an unbound method
    #  object from a class and a function.
    #
    #  function      ExprNode   Function object

    type = py_object_type
    is_temp = 1

    subexprs = ['function']

    def analyse_types(self, env):
        self.function = self.function.analyse_types(env)
        return self

    def may_be_none(self):
        return False

    gil_message = "Constructing an unbound method"

    def generate_result_code(self, code):
        class_cname = code.pyclass_stack[-1].classobj.result()
        code.putln(
            "%s = PyMethod_New(%s, 0, %s); %s" % (
                self.result(),
                self.function.py_result(),
                class_cname,
                code.error_goto_if_null(self.result(), self.pos)))
        code.put_gotref(self.py_result())


class PyCFunctionNode(ExprNode, ModuleNameMixin):
    #  Helper class used in the implementation of Python
    #  functions.  Constructs a PyCFunction object
    #  from a PyMethodDef struct.
    #
    #  pymethdef_cname   string             PyMethodDef structure
    #  self_object       ExprNode or None
    #  binding           bool
    #  def_node          DefNode            the Python function node
    #  module_name       EncodedString      Name of defining module
    #  code_object       CodeObjectNode     the PyCodeObject creator node

    subexprs = ['code_object', 'defaults_tuple', 'defaults_kwdict',
                'annotations_dict']

    self_object = None
    code_object = None
    binding = False
    def_node = None
    defaults = None
    defaults_struct = None
    defaults_pyobjects = 0
    defaults_tuple = None
    defaults_kwdict = None
    annotations_dict = None

    type = py_object_type
    is_temp = 1

    specialized_cpdefs = None
    is_specialization = False

    @classmethod
    def from_defnode(cls, node, binding):
        return cls(node.pos,
                   def_node=node,
                   pymethdef_cname=node.entry.pymethdef_cname,
                   binding=binding or node.specialized_cpdefs,
                   specialized_cpdefs=node.specialized_cpdefs,
                   code_object=CodeObjectNode(node))

    def analyse_types(self, env):
        if self.binding:
            self.analyse_default_args(env)
        return self

    def analyse_default_args(self, env):
        """
        Handle non-literal function's default arguments.
        """
        nonliteral_objects = []
        nonliteral_other = []
        default_args = []
        default_kwargs = []
        annotations = []
        for arg in self.def_node.args:
            if arg.default:
                if not arg.default.is_literal:
                    arg.is_dynamic = True
                    if arg.type.is_pyobject:
                        nonliteral_objects.append(arg)
                    else:
                        nonliteral_other.append(arg)
                else:
                    arg.default = DefaultLiteralArgNode(arg.pos, arg.default)
                if arg.kw_only:
                    default_kwargs.append(arg)
                else:
                    default_args.append(arg)
            if arg.annotation:
                arg.annotation = arg.annotation.analyse_types(env)
                if not arg.annotation.type.is_pyobject:
                    arg.annotation = arg.annotation.coerce_to_pyobject(env)
                annotations.append((arg.pos, arg.name, arg.annotation))
        if self.def_node.return_type_annotation:
            annotations.append((self.def_node.return_type_annotation.pos,
                                StringEncoding.EncodedString("return"),
                                self.def_node.return_type_annotation))

        if nonliteral_objects or nonliteral_other:
            module_scope = env.global_scope()
            cname = module_scope.next_id(Naming.defaults_struct_prefix)
            scope = Symtab.StructOrUnionScope(cname)
            self.defaults = []
            for arg in nonliteral_objects:
                entry = scope.declare_var(arg.name, arg.type, None,
                                          Naming.arg_prefix + arg.name,
                                          allow_pyobject=True)
                self.defaults.append((arg, entry))
            for arg in nonliteral_other:
                entry = scope.declare_var(arg.name, arg.type, None,
                                          Naming.arg_prefix + arg.name,
                                          allow_pyobject=False)
                self.defaults.append((arg, entry))
            entry = module_scope.declare_struct_or_union(
                None, 'struct', scope, 1, None, cname=cname)
            self.defaults_struct = scope
            self.defaults_pyobjects = len(nonliteral_objects)
            for arg, entry in self.defaults:
                arg.default_value = '%s->%s' % (
                    Naming.dynamic_args_cname, entry.cname)
            self.def_node.defaults_struct = self.defaults_struct.name

        if default_args or default_kwargs:
            if self.defaults_struct is None:
                if default_args:
                    defaults_tuple = TupleNode(self.pos, args=[
                        arg.default for arg in default_args])
                    self.defaults_tuple = defaults_tuple.analyse_types(env)
                if default_kwargs:
                    defaults_kwdict = DictNode(self.pos, key_value_pairs=[
                        DictItemNode(
                            arg.pos,
                            key=IdentifierStringNode(arg.pos, value=arg.name),
                            value=arg.default)
                        for arg in default_kwargs])
                    self.defaults_kwdict = defaults_kwdict.analyse_types(env)
            else:
                if default_args:
                    defaults_tuple = DefaultsTupleNode(
                        self.pos, default_args, self.defaults_struct)
                else:
                    defaults_tuple = NoneNode(self.pos)
                if default_kwargs:
                    defaults_kwdict = DefaultsKwDictNode(
                        self.pos, default_kwargs, self.defaults_struct)
                else:
                    defaults_kwdict = NoneNode(self.pos)

                defaults_getter = Nodes.DefNode(
                    self.pos, args=[], star_arg=None, starstar_arg=None,
                    body=Nodes.ReturnStatNode(
                        self.pos, return_type=py_object_type,
                        value=TupleNode(
                            self.pos, args=[defaults_tuple, defaults_kwdict])),
                    decorators=None,
                    name=StringEncoding.EncodedString("__defaults__"))
                defaults_getter.analyse_declarations(env)
                defaults_getter = defaults_getter.analyse_expressions(env)
                defaults_getter.body = defaults_getter.body.analyse_expressions(
                    defaults_getter.local_scope)
                defaults_getter.py_wrapper_required = False
                defaults_getter.pymethdef_required = False
                self.def_node.defaults_getter = defaults_getter
        if annotations:
            annotations_dict = DictNode(self.pos, key_value_pairs=[
                DictItemNode(
                    pos, key=IdentifierStringNode(pos, value=name),
                    value=value)
                for pos, name, value in annotations])
            self.annotations_dict = annotations_dict.analyse_types(env)

    def may_be_none(self):
        return False

    gil_message = "Constructing Python function"

    def self_result_code(self):
        if self.self_object is None:
            self_result = "NULL"
        else:
            self_result = self.self_object.py_result()
        return self_result

    def generate_result_code(self, code):
        if self.binding:
            self.generate_cyfunction_code(code)
        else:
            self.generate_pycfunction_code(code)

    def generate_pycfunction_code(self, code):
        py_mod_name = self.get_py_mod_name(code)
        code.putln(
            '%s = PyCFunction_NewEx(&%s, %s, %s); %s' % (
                self.result(),
                self.pymethdef_cname,
                self.self_result_code(),
                py_mod_name,
                code.error_goto_if_null(self.result(), self.pos)))

        code.put_gotref(self.py_result())

    def generate_cyfunction_code(self, code):
        if self.specialized_cpdefs:
            def_node = self.specialized_cpdefs[0]
        else:
            def_node = self.def_node

        if self.specialized_cpdefs or self.is_specialization:
            code.globalstate.use_utility_code(
                UtilityCode.load_cached("FusedFunction", "CythonFunction.c"))
            constructor = "__pyx_FusedFunction_NewEx"
        else:
            code.globalstate.use_utility_code(
                UtilityCode.load_cached("CythonFunction", "CythonFunction.c"))
            constructor = "__Pyx_CyFunction_NewEx"

        if self.code_object:
            code_object_result = self.code_object.py_result()
        else:
            code_object_result = 'NULL'

        flags = []
        if def_node.is_staticmethod:
            flags.append('__Pyx_CYFUNCTION_STATICMETHOD')
        elif def_node.is_classmethod:
            flags.append('__Pyx_CYFUNCTION_CLASSMETHOD')

        if def_node.local_scope.parent_scope.is_c_class_scope:
            flags.append('__Pyx_CYFUNCTION_CCLASS')

        if flags:
            flags = ' | '.join(flags)
        else:
            flags = '0'

        code.putln(
            '%s = %s(&%s, %s, %s, %s, %s, %s, %s); %s' % (
                self.result(),
                constructor,
                self.pymethdef_cname,
                flags,
                self.get_py_qualified_name(code),
                self.self_result_code(),
                self.get_py_mod_name(code),
                "PyModule_GetDict(%s)" % Naming.module_cname,
                code_object_result,
                code.error_goto_if_null(self.result(), self.pos)))

        code.put_gotref(self.py_result())

        if def_node.requires_classobj:
            assert code.pyclass_stack, "pyclass_stack is empty"
            class_node = code.pyclass_stack[-1]
            code.put_incref(self.py_result(), py_object_type)
            code.putln(
                'PyList_Append(%s, %s);' % (
                    class_node.class_cell.result(),
                    self.result()))
            code.put_giveref(self.py_result())

        if self.defaults:
            code.putln(
                'if (!__Pyx_CyFunction_InitDefaults(%s, sizeof(%s), %d)) %s' % (
                    self.result(), self.defaults_struct.name,
                    self.defaults_pyobjects, code.error_goto(self.pos)))
            defaults = '__Pyx_CyFunction_Defaults(%s, %s)' % (
                self.defaults_struct.name, self.result())
            for arg, entry in self.defaults:
                arg.generate_assignment_code(code, target='%s->%s' % (
                    defaults, entry.cname))

        if self.defaults_tuple:
            code.putln('__Pyx_CyFunction_SetDefaultsTuple(%s, %s);' % (
                self.result(), self.defaults_tuple.py_result()))
        if self.defaults_kwdict:
            code.putln('__Pyx_CyFunction_SetDefaultsKwDict(%s, %s);' % (
                self.result(), self.defaults_kwdict.py_result()))
        if def_node.defaults_getter:
            code.putln('__Pyx_CyFunction_SetDefaultsGetter(%s, %s);' % (
                self.result(), def_node.defaults_getter.entry.pyfunc_cname))
        if self.annotations_dict:
            code.putln('__Pyx_CyFunction_SetAnnotationsDict(%s, %s);' % (
                self.result(), self.annotations_dict.py_result()))


class InnerFunctionNode(PyCFunctionNode):
    # Special PyCFunctionNode that depends on a closure class
    #

    binding = True
    needs_self_code = True

    def self_result_code(self):
        if self.needs_self_code:
            return "((PyObject*)%s)" % Naming.cur_scope_cname
        return "NULL"


class CodeObjectNode(ExprNode):
    # Create a PyCodeObject for a CyFunction instance.
    #
    # def_node   DefNode    the Python function node
    # varnames   TupleNode  a tuple with all local variable names

    subexprs = ['varnames']
    is_temp = False

    def __init__(self, def_node):
        ExprNode.__init__(self, def_node.pos, def_node=def_node)
        args = list(def_node.args)
        # if we have args/kwargs, then the first two in var_entries are those
        local_vars = [arg for arg in def_node.local_scope.var_entries if arg.name]
        self.varnames = TupleNode(
            def_node.pos,
            args=[IdentifierStringNode(arg.pos, value=arg.name)
                  for arg in args + local_vars],
            is_temp=0,
            is_literal=1)

    def may_be_none(self):
        return False

    def calculate_result_code(self):
        return self.result_code

    def generate_result_code(self, code):
        self.result_code = code.get_py_const(py_object_type, 'codeobj', cleanup_level=2)

        code = code.get_cached_constants_writer()
        code.mark_pos(self.pos)
        func = self.def_node
        func_name = code.get_py_string_const(
            func.name, identifier=True, is_str=False, unicode_value=func.name)
        # FIXME: better way to get the module file path at module init time? Encoding to use?
        file_path = StringEncoding.BytesLiteral(func.pos[0].get_filenametable_entry().encode('utf8'))
        file_path_const = code.get_py_string_const(file_path, identifier=False, is_str=True)

        flags = []
        if self.def_node.star_arg:
            flags.append('CO_VARARGS')
        if self.def_node.starstar_arg:
            flags.append('CO_VARKEYWORDS')

        code.putln("%s = (PyObject*)__Pyx_PyCode_New(%d, %d, %d, 0, %s, %s, %s, %s, %s, %s, %s, %s, %s, %d, %s); %s" % (
            self.result_code,
            len(func.args) - func.num_kwonly_args,  # argcount
            func.num_kwonly_args,      # kwonlyargcount (Py3 only)
            len(self.varnames.args),   # nlocals
            '|'.join(flags) or '0',    # flags
            Naming.empty_bytes,        # code
            Naming.empty_tuple,        # consts
            Naming.empty_tuple,        # names (FIXME)
            self.varnames.result(),    # varnames
            Naming.empty_tuple,        # freevars (FIXME)
            Naming.empty_tuple,        # cellvars (FIXME)
            file_path_const,           # filename
            func_name,                 # name
            self.pos[1],               # firstlineno
            Naming.empty_bytes,        # lnotab
            code.error_goto_if_null(self.result_code, self.pos),
            ))


class DefaultLiteralArgNode(ExprNode):
    # CyFunction's literal argument default value
    #
    # Evaluate literal only once.

    subexprs = []
    is_literal = True
    is_temp = False

    def __init__(self, pos, arg):
        super(DefaultLiteralArgNode, self).__init__(pos)
        self.arg = arg
        self.type = self.arg.type
        self.evaluated = False

    def analyse_types(self, env):
        return self

    def generate_result_code(self, code):
        pass

    def generate_evaluation_code(self, code):
        if not self.evaluated:
            self.arg.generate_evaluation_code(code)
            self.evaluated = True

    def result(self):
        return self.type.cast_code(self.arg.result())


class DefaultNonLiteralArgNode(ExprNode):
    # CyFunction's non-literal argument default value

    subexprs = []

    def __init__(self, pos, arg, defaults_struct):
        super(DefaultNonLiteralArgNode, self).__init__(pos)
        self.arg = arg
        self.defaults_struct = defaults_struct

    def analyse_types(self, env):
        self.type = self.arg.type
        self.is_temp = False
        return self

    def generate_result_code(self, code):
        pass

    def result(self):
        return '__Pyx_CyFunction_Defaults(%s, %s)->%s' % (
            self.defaults_struct.name, Naming.self_cname,
            self.defaults_struct.lookup(self.arg.name).cname)


class DefaultsTupleNode(TupleNode):
    # CyFunction's __defaults__ tuple

    def __init__(self, pos, defaults, defaults_struct):
        args = []
        for arg in defaults:
            if not arg.default.is_literal:
                arg = DefaultNonLiteralArgNode(pos, arg, defaults_struct)
            else:
                arg = arg.default
            args.append(arg)
        super(DefaultsTupleNode, self).__init__(pos, args=args)


class DefaultsKwDictNode(DictNode):
    # CyFunction's __kwdefaults__ dict

    def __init__(self, pos, defaults, defaults_struct):
        items = []
        for arg in defaults:
            name = IdentifierStringNode(arg.pos, value=arg.name)
            if not arg.default.is_literal:
                arg = DefaultNonLiteralArgNode(pos, arg, defaults_struct)
            else:
                arg = arg.default
            items.append(DictItemNode(arg.pos, key=name, value=arg))
        super(DefaultsKwDictNode, self).__init__(pos, key_value_pairs=items)


class LambdaNode(InnerFunctionNode):
    # Lambda expression node (only used as a function reference)
    #
    # args          [CArgDeclNode]         formal arguments
    # star_arg      PyArgDeclNode or None  * argument
    # starstar_arg  PyArgDeclNode or None  ** argument
    # lambda_name   string                 a module-globally unique lambda name
    # result_expr   ExprNode
    # def_node      DefNode                the underlying function 'def' node

    child_attrs = ['def_node']

    name = StringEncoding.EncodedString('<lambda>')

    def analyse_declarations(self, env):
        self.def_node.no_assignment_synthesis = True
        self.def_node.pymethdef_required = True
        self.def_node.analyse_declarations(env)
        self.def_node.is_cyfunction = True
        self.pymethdef_cname = self.def_node.entry.pymethdef_cname
        env.add_lambda_def(self.def_node)

    def analyse_types(self, env):
        self.def_node = self.def_node.analyse_expressions(env)
        return super(LambdaNode, self).analyse_types(env)

    def generate_result_code(self, code):
        self.def_node.generate_execution_code(code)
        super(LambdaNode, self).generate_result_code(code)


class GeneratorExpressionNode(LambdaNode):
    # A generator expression, e.g.  (i for i in range(10))
    #
    # Result is a generator.
    #
    # loop      ForStatNode   the for-loop, containing a YieldExprNode
    # def_node  DefNode       the underlying generator 'def' node

    name = StringEncoding.EncodedString('genexpr')
    binding = False

    def analyse_declarations(self, env):
        super(GeneratorExpressionNode, self).analyse_declarations(env)
        # No pymethdef required
        self.def_node.pymethdef_required = False
        self.def_node.py_wrapper_required = False
        self.def_node.is_cyfunction = False
        # Force genexpr signature
        self.def_node.entry.signature = TypeSlots.pyfunction_noargs

    def generate_result_code(self, code):
        code.putln(
            '%s = %s(%s); %s' % (
                self.result(),
                self.def_node.entry.pyfunc_cname,
                self.self_result_code(),
                code.error_goto_if_null(self.result(), self.pos)))
        code.put_gotref(self.py_result())


class YieldExprNode(ExprNode):
    # Yield expression node
    #
    # arg         ExprNode   the value to return from the generator
    # label_num   integer    yield label number
    # is_yield_from  boolean is a YieldFromExprNode to delegate to another generator

    subexprs = ['arg']
    type = py_object_type
    label_num = 0
    is_yield_from = False

    def analyse_types(self, env):
        if not self.label_num:
            error(self.pos, "'yield' not supported here")
        self.is_temp = 1
        if self.arg is not None:
            self.arg = self.arg.analyse_types(env)
            if not self.arg.type.is_pyobject:
                self.coerce_yield_argument(env)
        return self

    def coerce_yield_argument(self, env):
        self.arg = self.arg.coerce_to_pyobject(env)

    def generate_evaluation_code(self, code):
        if self.arg:
            self.arg.generate_evaluation_code(code)
            self.arg.make_owned_reference(code)
            code.putln(
                "%s = %s;" % (
                    Naming.retval_cname,
                    self.arg.result_as(py_object_type)))
            self.arg.generate_post_assignment_code(code)
            self.arg.free_temps(code)
        else:
            code.put_init_to_py_none(Naming.retval_cname, py_object_type)
        self.generate_yield_code(code)

    def generate_yield_code(self, code):
        """
        Generate the code to return the argument in 'Naming.retval_cname'
        and to continue at the yield label.
        """
        label_num, label_name = code.new_yield_label()
        code.use_label(label_name)

        saved = []
        code.funcstate.closure_temps.reset()
        for cname, type, manage_ref in code.funcstate.temps_in_use():
            save_cname = code.funcstate.closure_temps.allocate_temp(type)
            saved.append((cname, save_cname, type))
            if type.is_pyobject:
                code.put_xgiveref(cname)
            code.putln('%s->%s = %s;' % (Naming.cur_scope_cname, save_cname, cname))

        code.put_xgiveref(Naming.retval_cname)
        code.put_finish_refcount_context()
        code.putln("/* return from generator, yielding value */")
        code.putln("%s->resume_label = %d;" % (
            Naming.generator_cname, label_num))
        code.putln("return %s;" % Naming.retval_cname)

        code.put_label(label_name)
        for cname, save_cname, type in saved:
            code.putln('%s = %s->%s;' % (cname, Naming.cur_scope_cname, save_cname))
            if type.is_pyobject:
                code.putln('%s->%s = 0;' % (Naming.cur_scope_cname, save_cname))
                code.put_xgotref(cname)
        code.putln(code.error_goto_if_null(Naming.sent_value_cname, self.pos))
        if self.result_is_used:
            self.allocate_temp_result(code)
            code.put('%s = %s; ' % (self.result(), Naming.sent_value_cname))
            code.put_incref(self.result(), py_object_type)


class YieldFromExprNode(YieldExprNode):
    # "yield from GEN" expression
    is_yield_from = True

    def coerce_yield_argument(self, env):
        if not self.arg.type.is_string:
            # FIXME: support C arrays and C++ iterators?
            error(self.pos, "yielding from non-Python object not supported")
        self.arg = self.arg.coerce_to_pyobject(env)

    def generate_evaluation_code(self, code):
        code.globalstate.use_utility_code(UtilityCode.load_cached("YieldFrom", "Generator.c"))

        self.arg.generate_evaluation_code(code)
        code.putln("%s = __Pyx_Generator_Yield_From(%s, %s);" % (
            Naming.retval_cname,
            Naming.generator_cname,
            self.arg.result_as(py_object_type)))
        self.arg.generate_disposal_code(code)
        self.arg.free_temps(code)
        code.put_xgotref(Naming.retval_cname)

        code.putln("if (likely(%s)) {" % Naming.retval_cname)
        self.generate_yield_code(code)
        code.putln("} else {")
        # either error or sub-generator has normally terminated: return value => node result
        if self.result_is_used:
            # YieldExprNode has allocated the result temp for us
            code.putln("%s = NULL;" % self.result())
            code.putln("if (unlikely(__Pyx_PyGen_FetchStopIterationValue(&%s) < 0)) %s" % (
                self.result(),
                code.error_goto(self.pos)))
            code.put_gotref(self.result())
        else:
            code.putln("PyObject* exc_type = PyErr_Occurred();")
            code.putln("if (exc_type) {")
            code.putln("if (likely(exc_type == PyExc_StopIteration ||"
                       " PyErr_GivenExceptionMatches(exc_type, PyExc_StopIteration))) PyErr_Clear();")
            code.putln("else %s" % code.error_goto(self.pos))
            code.putln("}")
        code.putln("}")

class GlobalsExprNode(AtomicExprNode):
    type = dict_type
    is_temp = 1

    def analyse_types(self, env):
        env.use_utility_code(Builtin.globals_utility_code)
        return self

    gil_message = "Constructing globals dict"

    def may_be_none(self):
        return False

    def generate_result_code(self, code):
        code.putln('%s = __Pyx_Globals(); %s' % (
            self.result(),
            code.error_goto_if_null(self.result(), self.pos)))
        code.put_gotref(self.result())


class LocalsDictItemNode(DictItemNode):
    def analyse_types(self, env):
        self.key = self.key.analyse_types(env)
        self.value = self.value.analyse_types(env)
        self.key = self.key.coerce_to_pyobject(env)
        if self.value.type.can_coerce_to_pyobject(env):
            self.value = self.value.coerce_to_pyobject(env)
        else:
            self.value = None
        return self


class FuncLocalsExprNode(DictNode):
    def __init__(self, pos, env):
        local_vars = sorted([
            entry.name for entry in env.entries.values() if entry.name])
        items = [LocalsDictItemNode(
            pos, key=IdentifierStringNode(pos, value=var),
            value=NameNode(pos, name=var, allow_null=True))
                 for var in local_vars]
        DictNode.__init__(self, pos, key_value_pairs=items,
                          exclude_null_values=True)

    def analyse_types(self, env):
        node = super(FuncLocalsExprNode, self).analyse_types(env)
        node.key_value_pairs = [ i for i in node.key_value_pairs
                                 if i.value is not None ]
        return node


class PyClassLocalsExprNode(AtomicExprNode):
    def __init__(self, pos, pyclass_dict):
        AtomicExprNode.__init__(self, pos)
        self.pyclass_dict = pyclass_dict

    def analyse_types(self, env):
        self.type = self.pyclass_dict.type
        self.is_temp = False
        return self

    def may_be_none(self):
        return False

    def result(self):
        return self.pyclass_dict.result()

    def generate_result_code(self, code):
        pass


def LocalsExprNode(pos, scope_node, env):
    if env.is_module_scope:
        return GlobalsExprNode(pos)
    if env.is_py_class_scope:
        return PyClassLocalsExprNode(pos, scope_node.dict)
    return FuncLocalsExprNode(pos, env)


#-------------------------------------------------------------------
#
#  Unary operator nodes
#
#-------------------------------------------------------------------

compile_time_unary_operators = {
    'not': operator.not_,
    '~': operator.inv,
    '-': operator.neg,
    '+': operator.pos,
}

class UnopNode(ExprNode):
    #  operator     string
    #  operand      ExprNode
    #
    #  Processing during analyse_expressions phase:
    #
    #    analyse_c_operation
    #      Called when the operand is not a pyobject.
    #      - Check operand type and coerce if needed.
    #      - Determine result type and result code fragment.
    #      - Allocate temporary for result if needed.

    subexprs = ['operand']
    infix = True

    def calculate_constant_result(self):
        func = compile_time_unary_operators[self.operator]
        self.constant_result = func(self.operand.constant_result)

    def compile_time_value(self, denv):
        func = compile_time_unary_operators.get(self.operator)
        if not func:
            error(self.pos,
                "Unary '%s' not supported in compile-time expression"
                    % self.operator)
        operand = self.operand.compile_time_value(denv)
        try:
            return func(operand)
        except Exception, e:
            self.compile_time_value_error(e)

    def infer_type(self, env):
        operand_type = self.operand.infer_type(env)
        if operand_type.is_cpp_class or operand_type.is_ptr:
            cpp_type = operand_type.find_cpp_operation_type(self.operator)
            if cpp_type is not None:
                return cpp_type
        return self.infer_unop_type(env, operand_type)

    def infer_unop_type(self, env, operand_type):
        if operand_type.is_pyobject:
            return py_object_type
        else:
            return operand_type

    def may_be_none(self):
        if self.operand.type and self.operand.type.is_builtin_type:
            if self.operand.type is not type_type:
                return False
        return ExprNode.may_be_none(self)

    def analyse_types(self, env):
        self.operand = self.operand.analyse_types(env)
        if self.is_py_operation():
            self.coerce_operand_to_pyobject(env)
            self.type = py_object_type
            self.is_temp = 1
        elif self.is_cpp_operation():
            self.analyse_cpp_operation(env)
        else:
            self.analyse_c_operation(env)
        return self

    def check_const(self):
        return self.operand.check_const()

    def is_py_operation(self):
        return self.operand.type.is_pyobject

    def nogil_check(self, env):
        if self.is_py_operation():
            self.gil_error()

    def is_cpp_operation(self):
        type = self.operand.type
        return type.is_cpp_class

    def coerce_operand_to_pyobject(self, env):
        self.operand = self.operand.coerce_to_pyobject(env)

    def generate_result_code(self, code):
        if self.operand.type.is_pyobject:
            self.generate_py_operation_code(code)

    def generate_py_operation_code(self, code):
        function = self.py_operation_function()
        code.putln(
            "%s = %s(%s); %s" % (
                self.result(),
                function,
                self.operand.py_result(),
                code.error_goto_if_null(self.result(), self.pos)))
        code.put_gotref(self.py_result())

    def type_error(self):
        if not self.operand.type.is_error:
            error(self.pos, "Invalid operand type for '%s' (%s)" %
                (self.operator, self.operand.type))
        self.type = PyrexTypes.error_type

    def analyse_cpp_operation(self, env):
        cpp_type = self.operand.type.find_cpp_operation_type(self.operator)
        if cpp_type is None:
            error(self.pos, "'%s' operator not defined for %s" % (
                self.operator, type))
            self.type_error()
            return
        self.type = cpp_type


class NotNode(UnopNode):
    #  'not' operator
    #
    #  operand   ExprNode
    operator = '!'

    type = PyrexTypes.c_bint_type

    def calculate_constant_result(self):
        self.constant_result = not self.operand.constant_result

    def compile_time_value(self, denv):
        operand = self.operand.compile_time_value(denv)
        try:
            return not operand
        except Exception, e:
            self.compile_time_value_error(e)

    def infer_unop_type(self, env, operand_type):
        return PyrexTypes.c_bint_type

    def analyse_types(self, env):
        self.operand = self.operand.analyse_types(env)
        operand_type = self.operand.type
        if operand_type.is_cpp_class:
            cpp_type = operand_type.find_cpp_operation_type(self.operator)
            if not cpp_type:
                error(self.pos, "'!' operator not defined for %s" % operand_type)
                self.type = PyrexTypes.error_type
                return
            self.type = cpp_type
        else:
            self.operand = self.operand.coerce_to_boolean(env)
        return self

    def calculate_result_code(self):
        return "(!%s)" % self.operand.result()

    def generate_result_code(self, code):
        pass


class UnaryPlusNode(UnopNode):
    #  unary '+' operator

    operator = '+'

    def analyse_c_operation(self, env):
        self.type = PyrexTypes.widest_numeric_type(
            self.operand.type, PyrexTypes.c_int_type)

    def py_operation_function(self):
        return "PyNumber_Positive"

    def calculate_result_code(self):
        if self.is_cpp_operation():
            return "(+%s)" % self.operand.result()
        else:
            return self.operand.result()


class UnaryMinusNode(UnopNode):
    #  unary '-' operator

    operator = '-'

    def analyse_c_operation(self, env):
        if self.operand.type.is_numeric:
            self.type = PyrexTypes.widest_numeric_type(
                self.operand.type, PyrexTypes.c_int_type)
        elif self.operand.type.is_enum:
            self.type = PyrexTypes.c_int_type
        else:
            self.type_error()
        if self.type.is_complex:
            self.infix = False

    def py_operation_function(self):
        return "PyNumber_Negative"

    def calculate_result_code(self):
        if self.infix:
            return "(-%s)" % self.operand.result()
        else:
            return "%s(%s)" % (self.operand.type.unary_op('-'), self.operand.result())

    def get_constant_c_result_code(self):
        value = self.operand.get_constant_c_result_code()
        if value:
            return "(-%s)" % value

class TildeNode(UnopNode):
    #  unary '~' operator

    def analyse_c_operation(self, env):
        if self.operand.type.is_int:
            self.type = PyrexTypes.widest_numeric_type(
                self.operand.type, PyrexTypes.c_int_type)
        elif self.operand.type.is_enum:
            self.type = PyrexTypes.c_int_type
        else:
            self.type_error()

    def py_operation_function(self):
        return "PyNumber_Invert"

    def calculate_result_code(self):
        return "(~%s)" % self.operand.result()


class CUnopNode(UnopNode):

    def is_py_operation(self):
        return False

class DereferenceNode(CUnopNode):
    #  unary * operator

    operator = '*'

    def infer_unop_type(self, env, operand_type):
        if operand_type.is_ptr:
            return operand_type.base_type
        else:
            return PyrexTypes.error_type

    def analyse_c_operation(self, env):
        if self.operand.type.is_ptr:
            self.type = self.operand.type.base_type
        else:
            self.type_error()

    def calculate_result_code(self):
        return "(*%s)" % self.operand.result()


class DecrementIncrementNode(CUnopNode):
    #  unary ++/-- operator

    def analyse_c_operation(self, env):
        if self.operand.type.is_numeric:
            self.type = PyrexTypes.widest_numeric_type(
                self.operand.type, PyrexTypes.c_int_type)
        elif self.operand.type.is_ptr:
            self.type = self.operand.type
        else:
            self.type_error()

    def calculate_result_code(self):
        if self.is_prefix:
            return "(%s%s)" % (self.operator, self.operand.result())
        else:
            return "(%s%s)" % (self.operand.result(), self.operator)

def inc_dec_constructor(is_prefix, operator):
    return lambda pos, **kwds: DecrementIncrementNode(pos, is_prefix=is_prefix, operator=operator, **kwds)


class AmpersandNode(CUnopNode):
    #  The C address-of operator.
    #
    #  operand  ExprNode
    operator = '&'

    def infer_unop_type(self, env, operand_type):
        return PyrexTypes.c_ptr_type(operand_type)

    def analyse_types(self, env):
        self.operand = self.operand.analyse_types(env)
        argtype = self.operand.type
        if argtype.is_cpp_class:
            cpp_type = argtype.find_cpp_operation_type(self.operator)
            if cpp_type is not None:
                self.type = cpp_type
                return self
        if not (argtype.is_cfunction or argtype.is_reference or self.operand.is_addressable()):
            if argtype.is_memoryviewslice:
                self.error("Cannot take address of memoryview slice")
            else:
                self.error("Taking address of non-lvalue")
            return self
        if argtype.is_pyobject:
            self.error("Cannot take address of Python variable")
            return self
        self.type = PyrexTypes.c_ptr_type(argtype)
        return self

    def check_const(self):
        return self.operand.check_const_addr()

    def error(self, mess):
        error(self.pos, mess)
        self.type = PyrexTypes.error_type
        self.result_code = "<error>"

    def calculate_result_code(self):
        return "(&%s)" % self.operand.result()

    def generate_result_code(self, code):
        pass


unop_node_classes = {
    "+":  UnaryPlusNode,
    "-":  UnaryMinusNode,
    "~":  TildeNode,
}

def unop_node(pos, operator, operand):
    # Construct unnop node of appropriate class for
    # given operator.
    if isinstance(operand, IntNode) and operator == '-':
        return IntNode(pos = operand.pos, value = str(-Utils.str_to_number(operand.value)),
                       longness=operand.longness, unsigned=operand.unsigned)
    elif isinstance(operand, UnopNode) and operand.operator == operator in '+-':
        warning(pos, "Python has no increment/decrement operator: %s%sx == %s(%sx) == x" % ((operator,)*4), 5)
    return unop_node_classes[operator](pos,
        operator = operator,
        operand = operand)


class TypecastNode(ExprNode):
    #  C type cast
    #
    #  operand      ExprNode
    #  base_type    CBaseTypeNode
    #  declarator   CDeclaratorNode
    #  typecheck    boolean
    #
    #  If used from a transform, one can if wanted specify the attribute
    #  "type" directly and leave base_type and declarator to None

    subexprs = ['operand']
    base_type = declarator = type = None

    def type_dependencies(self, env):
        return ()

    def infer_type(self, env):
        if self.type is None:
            base_type = self.base_type.analyse(env)
            _, self.type = self.declarator.analyse(base_type, env)
        return self.type

    def analyse_types(self, env):
        if self.type is None:
            base_type = self.base_type.analyse(env)
            _, self.type = self.declarator.analyse(base_type, env)
        if self.operand.has_constant_result():
            # Must be done after self.type is resolved.
            self.calculate_constant_result()
        if self.type.is_cfunction:
            error(self.pos,
                "Cannot cast to a function type")
            self.type = PyrexTypes.error_type
        self.operand = self.operand.analyse_types(env)
        if self.type is PyrexTypes.c_bint_type:
            # short circuit this to a coercion
            return self.operand.coerce_to_boolean(env)
        to_py = self.type.is_pyobject
        from_py = self.operand.type.is_pyobject
        if from_py and not to_py and self.operand.is_ephemeral():
            if not self.type.is_numeric and not self.type.is_cpp_class:
                error(self.pos, "Casting temporary Python object to non-numeric non-Python type")
        if to_py and not from_py:
            if self.type is bytes_type and self.operand.type.is_int:
                return CoerceIntToBytesNode(self.operand, env)
            elif self.operand.type.can_coerce_to_pyobject(env):
                self.result_ctype = py_object_type
                base_type = self.base_type.analyse(env)
                self.operand = self.operand.coerce_to(base_type, env)
            else:
                if self.operand.type.is_ptr:
                    if not (self.operand.type.base_type.is_void or self.operand.type.base_type.is_struct):
                        error(self.pos, "Python objects cannot be cast from pointers of primitive types")
                else:
                    # Should this be an error?
                    warning(self.pos, "No conversion from %s to %s, python object pointer used." % (self.operand.type, self.type))
                self.operand = self.operand.coerce_to_simple(env)
        elif from_py and not to_py:
            if self.type.create_from_py_utility_code(env):
                self.operand = self.operand.coerce_to(self.type, env)
            elif self.type.is_ptr:
                if not (self.type.base_type.is_void or self.type.base_type.is_struct):
                    error(self.pos, "Python objects cannot be cast to pointers of primitive types")
            else:
                warning(self.pos, "No conversion from %s to %s, python object pointer used." % (self.type, self.operand.type))
        elif from_py and to_py:
            if self.typecheck:
                self.operand = PyTypeTestNode(self.operand, self.type, env, notnone=True)
            elif isinstance(self.operand, SliceIndexNode):
                # This cast can influence the created type of string slices.
                self.operand = self.operand.coerce_to(self.type, env)
        elif self.type.is_complex and self.operand.type.is_complex:
            self.operand = self.operand.coerce_to_simple(env)
        elif self.operand.type.is_fused:
            self.operand = self.operand.coerce_to(self.type, env)
            #self.type = self.operand.type
        return self

    def is_simple(self):
        # either temp or a C cast => no side effects other than the operand's
        return self.operand.is_simple()

    def nonlocally_immutable(self):
        return self.is_temp or self.operand.nonlocally_immutable()

    def nogil_check(self, env):
        if self.type and self.type.is_pyobject and self.is_temp:
            self.gil_error()

    def check_const(self):
        return self.operand.check_const()

    def calculate_constant_result(self):
        self.constant_result = self.calculate_result_code(self.operand.constant_result)

    def calculate_result_code(self, operand_result = None):
        if operand_result is None:
            operand_result = self.operand.result()
        if self.type.is_complex:
            operand_result = self.operand.result()
            if self.operand.type.is_complex:
                real_part = self.type.real_type.cast_code("__Pyx_CREAL(%s)" % operand_result)
                imag_part = self.type.real_type.cast_code("__Pyx_CIMAG(%s)" % operand_result)
            else:
                real_part = self.type.real_type.cast_code(operand_result)
                imag_part = "0"
            return "%s(%s, %s)" % (
                    self.type.from_parts,
                    real_part,
                    imag_part)
        else:
            return self.type.cast_code(operand_result)

    def get_constant_c_result_code(self):
        operand_result = self.operand.get_constant_c_result_code()
        if operand_result:
            return self.type.cast_code(operand_result)

    def result_as(self, type):
        if self.type.is_pyobject and not self.is_temp:
            #  Optimise away some unnecessary casting
            return self.operand.result_as(type)
        else:
            return ExprNode.result_as(self, type)

    def generate_result_code(self, code):
        if self.is_temp:
            code.putln(
                "%s = (PyObject *)%s;" % (
                    self.result(),
                    self.operand.result()))
            code.put_incref(self.result(), self.ctype())


ERR_START = "Start may not be given"
ERR_NOT_STOP = "Stop must be provided to indicate shape"
ERR_STEPS = ("Strides may only be given to indicate contiguity. "
             "Consider slicing it after conversion")
ERR_NOT_POINTER = "Can only create cython.array from pointer or array"
ERR_BASE_TYPE = "Pointer base type does not match cython.array base type"

class CythonArrayNode(ExprNode):
    """
    Used when a pointer of base_type is cast to a memoryviewslice with that
    base type. i.e.

        <int[:M:1, :N]> p

    creates a fortran-contiguous cython.array.

    We leave the type set to object so coercions to object are more efficient
    and less work. Acquiring a memoryviewslice from this will be just as
    efficient. ExprNode.coerce_to() will do the additional typecheck on
    self.compile_time_type

    This also handles <int[:, :]> my_c_array


    operand             ExprNode                 the thing we're casting
    base_type_node      MemoryViewSliceTypeNode  the cast expression node
    """

    subexprs = ['operand', 'shapes']

    shapes = None
    is_temp = True
    mode = "c"
    array_dtype = None

    shape_type = PyrexTypes.c_py_ssize_t_type

    def analyse_types(self, env):
        import MemoryView

        self.operand = self.operand.analyse_types(env)
        if self.array_dtype:
            array_dtype = self.array_dtype
        else:
            array_dtype = self.base_type_node.base_type_node.analyse(env)
        axes = self.base_type_node.axes

        MemoryView.validate_memslice_dtype(self.pos, array_dtype)

        self.type = error_type
        self.shapes = []
        ndim = len(axes)

        # Base type of the pointer or C array we are converting
        base_type = self.operand.type

        if not self.operand.type.is_ptr and not self.operand.type.is_array:
            error(self.operand.pos, ERR_NOT_POINTER)
            return self

        # Dimension sizes of C array
        array_dimension_sizes = []
        if base_type.is_array:
            while base_type.is_array:
                array_dimension_sizes.append(base_type.size)
                base_type = base_type.base_type
        elif base_type.is_ptr:
            base_type = base_type.base_type
        else:
            error(self.pos, "unexpected base type %s found" % base_type)
            return self

        if not (base_type.same_as(array_dtype) or base_type.is_void):
            error(self.operand.pos, ERR_BASE_TYPE)
            return self
        elif self.operand.type.is_array and len(array_dimension_sizes) != ndim:
            error(self.operand.pos,
                  "Expected %d dimensions, array has %d dimensions" %
                                            (ndim, len(array_dimension_sizes)))
            return self

        # Verify the start, stop and step values
        # In case of a C array, use the size of C array in each dimension to
        # get an automatic cast
        for axis_no, axis in enumerate(axes):
            if not axis.start.is_none:
                error(axis.start.pos, ERR_START)
                return self

            if axis.stop.is_none:
                if array_dimension_sizes:
                    dimsize = array_dimension_sizes[axis_no]
                    axis.stop = IntNode(self.pos, value=str(dimsize),
                                        constant_result=dimsize,
                                        type=PyrexTypes.c_int_type)
                else:
                    error(axis.pos, ERR_NOT_STOP)
                    return self

            axis.stop = axis.stop.analyse_types(env)
            shape = axis.stop.coerce_to(self.shape_type, env)
            if not shape.is_literal:
                shape.coerce_to_temp(env)

            self.shapes.append(shape)

            first_or_last = axis_no in (0, ndim - 1)
            if not axis.step.is_none and first_or_last:
                # '1' in the first or last dimension denotes F or C contiguity
                axis.step = axis.step.analyse_types(env)
                if (not axis.step.type.is_int and axis.step.is_literal and not
                        axis.step.type.is_error):
                    error(axis.step.pos, "Expected an integer literal")
                    return self

                if axis.step.compile_time_value(env) != 1:
                    error(axis.step.pos, ERR_STEPS)
                    return self

                if axis_no == 0:
                    self.mode = "fortran"

            elif not axis.step.is_none and not first_or_last:
                # step provided in some other dimension
                error(axis.step.pos, ERR_STEPS)
                return self

        if not self.operand.is_name:
            self.operand = self.operand.coerce_to_temp(env)

        axes = [('direct', 'follow')] * len(axes)
        if self.mode == "fortran":
            axes[0] = ('direct', 'contig')
        else:
            axes[-1] = ('direct', 'contig')

        self.coercion_type = PyrexTypes.MemoryViewSliceType(array_dtype, axes)
        self.type = self.get_cython_array_type(env)
        MemoryView.use_cython_array_utility_code(env)
        env.use_utility_code(MemoryView.typeinfo_to_format_code)
        return self

    def allocate_temp_result(self, code):
        if self.temp_code:
            raise RuntimeError("temp allocated mulitple times")

        self.temp_code = code.funcstate.allocate_temp(self.type, True)

    def infer_type(self, env):
        return self.get_cython_array_type(env)

    def get_cython_array_type(self, env):
        return env.global_scope().context.cython_scope.viewscope.lookup("array").type

    def generate_result_code(self, code):
        import Buffer

        shapes = [self.shape_type.cast_code(shape.result())
                      for shape in self.shapes]
        dtype = self.coercion_type.dtype

        shapes_temp = code.funcstate.allocate_temp(py_object_type, True)
        format_temp = code.funcstate.allocate_temp(py_object_type, True)

        itemsize = "sizeof(%s)" % dtype.declaration_code("")
        type_info = Buffer.get_type_information_cname(code, dtype)

        if self.operand.type.is_ptr:
            code.putln("if (!%s) {" % self.operand.result())
            code.putln(    'PyErr_SetString(PyExc_ValueError,'
                                '"Cannot create cython.array from NULL pointer");')
            code.putln(code.error_goto(self.operand.pos))
            code.putln("}")

        code.putln("%s = __pyx_format_from_typeinfo(&%s);" %
                                                (format_temp, type_info))
        buildvalue_fmt = " __PYX_BUILD_PY_SSIZE_T " * len(shapes)
        code.putln('%s = Py_BuildValue((char*) "(" %s ")", %s);' % (
            shapes_temp, buildvalue_fmt, ", ".join(shapes)))

        err = "!%s || !%s || !PyBytes_AsString(%s)" % (format_temp,
                                                       shapes_temp,
                                                       format_temp)
        code.putln(code.error_goto_if(err, self.pos))
        code.put_gotref(format_temp)
        code.put_gotref(shapes_temp)

        tup = (self.result(), shapes_temp, itemsize, format_temp,
               self.mode, self.operand.result())
        code.putln('%s = __pyx_array_new('
                            '%s, %s, PyBytes_AS_STRING(%s), '
                            '(char *) "%s", (char *) %s);' % tup)
        code.putln(code.error_goto_if_null(self.result(), self.pos))
        code.put_gotref(self.result())

        def dispose(temp):
            code.put_decref_clear(temp, py_object_type)
            code.funcstate.release_temp(temp)

        dispose(shapes_temp)
        dispose(format_temp)

    @classmethod
    def from_carray(cls, src_node, env):
        """
        Given a C array type, return a CythonArrayNode
        """
        pos = src_node.pos
        base_type = src_node.type

        none_node = NoneNode(pos)
        axes = []

        while base_type.is_array:
            axes.append(SliceNode(pos, start=none_node, stop=none_node,
                                       step=none_node))
            base_type = base_type.base_type
        axes[-1].step = IntNode(pos, value="1", is_c_literal=True)

        memslicenode = Nodes.MemoryViewSliceTypeNode(pos, axes=axes,
                                                     base_type_node=base_type)
        result = CythonArrayNode(pos, base_type_node=memslicenode,
                                 operand=src_node, array_dtype=base_type)
        result = result.analyse_types(env)
        return result

class SizeofNode(ExprNode):
    #  Abstract base class for sizeof(x) expression nodes.

    type = PyrexTypes.c_size_t_type

    def check_const(self):
        return True

    def generate_result_code(self, code):
        pass


class SizeofTypeNode(SizeofNode):
    #  C sizeof function applied to a type
    #
    #  base_type   CBaseTypeNode
    #  declarator  CDeclaratorNode

    subexprs = []
    arg_type = None

    def analyse_types(self, env):
        # we may have incorrectly interpreted a dotted name as a type rather than an attribute
        # this could be better handled by more uniformly treating types as runtime-available objects
        if 0 and self.base_type.module_path:
            path = self.base_type.module_path
            obj = env.lookup(path[0])
            if obj.as_module is None:
                operand = NameNode(pos=self.pos, name=path[0])
                for attr in path[1:]:
                    operand = AttributeNode(pos=self.pos, obj=operand, attribute=attr)
                operand = AttributeNode(pos=self.pos, obj=operand, attribute=self.base_type.name)
                self.operand = operand
                self.__class__ = SizeofVarNode
                node = self.analyse_types(env)
                return node
        if self.arg_type is None:
            base_type = self.base_type.analyse(env)
            _, arg_type = self.declarator.analyse(base_type, env)
            self.arg_type = arg_type
        self.check_type()
        return self

    def check_type(self):
        arg_type = self.arg_type
        if arg_type.is_pyobject and not arg_type.is_extension_type:
            error(self.pos, "Cannot take sizeof Python object")
        elif arg_type.is_void:
            error(self.pos, "Cannot take sizeof void")
        elif not arg_type.is_complete():
            error(self.pos, "Cannot take sizeof incomplete type '%s'" % arg_type)

    def calculate_result_code(self):
        if self.arg_type.is_extension_type:
            # the size of the pointer is boring
            # we want the size of the actual struct
            arg_code = self.arg_type.declaration_code("", deref=1)
        else:
            arg_code = self.arg_type.declaration_code("")
        return "(sizeof(%s))" % arg_code


class SizeofVarNode(SizeofNode):
    #  C sizeof function applied to a variable
    #
    #  operand   ExprNode

    subexprs = ['operand']

    def analyse_types(self, env):
        # We may actually be looking at a type rather than a variable...
        # If we are, traditional analysis would fail...
        operand_as_type = self.operand.analyse_as_type(env)
        if operand_as_type:
            self.arg_type = operand_as_type
            if self.arg_type.is_fused:
                self.arg_type = self.arg_type.specialize(env.fused_to_specific)
            self.__class__ = SizeofTypeNode
            self.check_type()
        else:
            self.operand = self.operand.analyse_types(env)
        return self

    def calculate_result_code(self):
        return "(sizeof(%s))" % self.operand.result()

    def generate_result_code(self, code):
        pass

class TypeofNode(ExprNode):
    #  Compile-time type of an expression, as a string.
    #
    #  operand   ExprNode
    #  literal   StringNode # internal

    literal = None
    type = py_object_type

    subexprs = ['literal'] # 'operand' will be ignored after type analysis!

    def analyse_types(self, env):
        self.operand = self.operand.analyse_types(env)
        value = StringEncoding.EncodedString(str(self.operand.type)) #self.operand.type.typeof_name())
        literal = StringNode(self.pos, value=value)
        literal = literal.analyse_types(env)
        self.literal = literal.coerce_to_pyobject(env)
        return self

    def may_be_none(self):
        return False

    def generate_evaluation_code(self, code):
        self.literal.generate_evaluation_code(code)

    def calculate_result_code(self):
        return self.literal.calculate_result_code()

#-------------------------------------------------------------------
#
#  Binary operator nodes
#
#-------------------------------------------------------------------

compile_time_binary_operators = {
    '<': operator.lt,
    '<=': operator.le,
    '==': operator.eq,
    '!=': operator.ne,
    '>=': operator.ge,
    '>': operator.gt,
    'is': operator.is_,
    'is_not': operator.is_not,
    '+': operator.add,
    '&': operator.and_,
    '/': operator.truediv,
    '//': operator.floordiv,
    '<<': operator.lshift,
    '%': operator.mod,
    '*': operator.mul,
    '|': operator.or_,
    '**': operator.pow,
    '>>': operator.rshift,
    '-': operator.sub,
    '^': operator.xor,
    'in': lambda x, seq: x in seq,
    'not_in': lambda x, seq: x not in seq,
}

def get_compile_time_binop(node):
    func = compile_time_binary_operators.get(node.operator)
    if not func:
        error(node.pos,
            "Binary '%s' not supported in compile-time expression"
                % node.operator)
    return func

class BinopNode(ExprNode):
    #  operator     string
    #  operand1     ExprNode
    #  operand2     ExprNode
    #
    #  Processing during analyse_expressions phase:
    #
    #    analyse_c_operation
    #      Called when neither operand is a pyobject.
    #      - Check operand types and coerce if needed.
    #      - Determine result type and result code fragment.
    #      - Allocate temporary for result if needed.

    subexprs = ['operand1', 'operand2']
    inplace = False

    def calculate_constant_result(self):
        func = compile_time_binary_operators[self.operator]
        self.constant_result = func(
            self.operand1.constant_result,
            self.operand2.constant_result)

    def compile_time_value(self, denv):
        func = get_compile_time_binop(self)
        operand1 = self.operand1.compile_time_value(denv)
        operand2 = self.operand2.compile_time_value(denv)
        try:
            return func(operand1, operand2)
        except Exception, e:
            self.compile_time_value_error(e)

    def infer_type(self, env):
        return self.result_type(self.operand1.infer_type(env),
                                self.operand2.infer_type(env))

    def analyse_types(self, env):
        self.operand1 = self.operand1.analyse_types(env)
        self.operand2 = self.operand2.analyse_types(env)
        self.analyse_operation(env)
        return self

    def analyse_operation(self, env):
        if self.is_py_operation():
            self.coerce_operands_to_pyobjects(env)
            self.type = self.result_type(self.operand1.type,
                                         self.operand2.type)
            assert self.type.is_pyobject
            self.is_temp = 1
        elif self.is_cpp_operation():
            self.analyse_cpp_operation(env)
        else:
            self.analyse_c_operation(env)

    def is_py_operation(self):
        return self.is_py_operation_types(self.operand1.type, self.operand2.type)

    def is_py_operation_types(self, type1, type2):
        return type1.is_pyobject or type2.is_pyobject

    def is_cpp_operation(self):
        return (self.operand1.type.is_cpp_class
            or self.operand2.type.is_cpp_class)

    def analyse_cpp_operation(self, env):
        entry = env.lookup_operator(self.operator, [self.operand1, self.operand2])
        if not entry:
            self.type_error()
            return
        func_type = entry.type
        if func_type.is_ptr:
            func_type = func_type.base_type
        if len(func_type.args) == 1:
            self.operand2 = self.operand2.coerce_to(func_type.args[0].type, env)
        else:
            self.operand1 = self.operand1.coerce_to(func_type.args[0].type, env)
            self.operand2 = self.operand2.coerce_to(func_type.args[1].type, env)
        self.type = func_type.return_type

    def result_type(self, type1, type2):
        if self.is_py_operation_types(type1, type2):
            if type2.is_string:
                type2 = Builtin.bytes_type
            elif type2.is_pyunicode_ptr:
                type2 = Builtin.unicode_type
            if type1.is_string:
                type1 = Builtin.bytes_type
            elif type1.is_pyunicode_ptr:
                type1 = Builtin.unicode_type
            if type1.is_builtin_type or type2.is_builtin_type:
                if type1 is type2 and self.operator in '**%+|&^':
                    # FIXME: at least these operators should be safe - others?
                    return type1
                result_type = self.infer_builtin_types_operation(type1, type2)
                if result_type is not None:
                    return result_type
            return py_object_type
        else:
            return self.compute_c_result_type(type1, type2)

    def infer_builtin_types_operation(self, type1, type2):
        return None

    def nogil_check(self, env):
        if self.is_py_operation():
            self.gil_error()

    def coerce_operands_to_pyobjects(self, env):
        self.operand1 = self.operand1.coerce_to_pyobject(env)
        self.operand2 = self.operand2.coerce_to_pyobject(env)

    def check_const(self):
        return self.operand1.check_const() and self.operand2.check_const()

    def generate_result_code(self, code):
        #print "BinopNode.generate_result_code:", self.operand1, self.operand2 ###
        if self.operand1.type.is_pyobject:
            function = self.py_operation_function()
            if self.operator == '**':
                extra_args = ", Py_None"
            else:
                extra_args = ""
            code.putln(
                "%s = %s(%s, %s%s); %s" % (
                    self.result(),
                    function,
                    self.operand1.py_result(),
                    self.operand2.py_result(),
                    extra_args,
                    code.error_goto_if_null(self.result(), self.pos)))
            code.put_gotref(self.py_result())
        elif self.is_temp:
            code.putln("%s = %s;" % (self.result(), self.calculate_result_code()))

    def type_error(self):
        if not (self.operand1.type.is_error
                or self.operand2.type.is_error):
            error(self.pos, "Invalid operand types for '%s' (%s; %s)" %
                (self.operator, self.operand1.type,
                    self.operand2.type))
        self.type = PyrexTypes.error_type


class CBinopNode(BinopNode):

    def analyse_types(self, env):
        node = BinopNode.analyse_types(self, env)
        if node.is_py_operation():
            node.type = PyrexTypes.error_type
        return node

    def py_operation_function(self):
        return ""

    def calculate_result_code(self):
        return "(%s %s %s)" % (
            self.operand1.result(),
            self.operator,
            self.operand2.result())

    def compute_c_result_type(self, type1, type2):
        cpp_type = None
        if type1.is_cpp_class or type1.is_ptr:
            cpp_type = type1.find_cpp_operation_type(self.operator, type2)
        # FIXME: handle the reversed case?
        #if cpp_type is None and (type2.is_cpp_class or type2.is_ptr):
        #    cpp_type = type2.find_cpp_operation_type(self.operator, type1)
        # FIXME: do we need to handle other cases here?
        return cpp_type


def c_binop_constructor(operator):
    def make_binop_node(pos, **operands):
        return CBinopNode(pos, operator=operator, **operands)
    return make_binop_node

class NumBinopNode(BinopNode):
    #  Binary operation taking numeric arguments.

    infix = True
    overflow_check = False
    overflow_bit_node = None

    def analyse_c_operation(self, env):
        type1 = self.operand1.type
        type2 = self.operand2.type
        self.type = self.compute_c_result_type(type1, type2)
        if not self.type:
            self.type_error()
            return
        if self.type.is_complex:
            self.infix = False
        if (self.type.is_int
                and env.directives['overflowcheck']
                and self.operator in self.overflow_op_names):
            if (self.operator in ('+', '*')
                    and self.operand1.has_constant_result()
                    and not self.operand2.has_constant_result()):
                self.operand1, self.operand2 = self.operand2, self.operand1
            self.overflow_check = True
            self.overflow_fold = env.directives['overflowcheck.fold']
            self.func = self.type.overflow_check_binop(
                self.overflow_op_names[self.operator],
                env,
                const_rhs = self.operand2.has_constant_result())
            self.is_temp = True
        if not self.infix or (type1.is_numeric and type2.is_numeric):
            self.operand1 = self.operand1.coerce_to(self.type, env)
            self.operand2 = self.operand2.coerce_to(self.type, env)

    def compute_c_result_type(self, type1, type2):
        if self.c_types_okay(type1, type2):
            widest_type = PyrexTypes.widest_numeric_type(type1, type2)
            if widest_type is PyrexTypes.c_bint_type:
                if self.operator not in '|^&':
                    # False + False == 0 # not False!
                    widest_type = PyrexTypes.c_int_type
            else:
                widest_type = PyrexTypes.widest_numeric_type(
                    widest_type, PyrexTypes.c_int_type)
            return widest_type
        else:
            return None

    def may_be_none(self):
        if self.type and self.type.is_builtin_type:
            # if we know the result type, we know the operation, so it can't be None
            return False
        type1 = self.operand1.type
        type2 = self.operand2.type
        if type1 and type1.is_builtin_type and type2 and type2.is_builtin_type:
            # XXX: I can't think of any case where a binary operation
            # on builtin types evaluates to None - add a special case
            # here if there is one.
            return False
        return super(NumBinopNode, self).may_be_none()

    def get_constant_c_result_code(self):
        value1 = self.operand1.get_constant_c_result_code()
        value2 = self.operand2.get_constant_c_result_code()
        if value1 and value2:
            return "(%s %s %s)" % (value1, self.operator, value2)
        else:
            return None

    def c_types_okay(self, type1, type2):
        #print "NumBinopNode.c_types_okay:", type1, type2 ###
        return (type1.is_numeric  or type1.is_enum) \
            and (type2.is_numeric  or type2.is_enum)

    def generate_evaluation_code(self, code):
        if self.overflow_check:
            self.overflow_bit_node = self
            self.overflow_bit = code.funcstate.allocate_temp(PyrexTypes.c_int_type, manage_ref=False)
            code.putln("%s = 0;" % self.overflow_bit)
        super(NumBinopNode, self).generate_evaluation_code(code)
        if self.overflow_check:
            code.putln("if (unlikely(%s)) {" % self.overflow_bit)
            code.putln('PyErr_SetString(PyExc_OverflowError, "value too large");')
            code.putln(code.error_goto(self.pos))
            code.putln("}")
            code.funcstate.release_temp(self.overflow_bit)

    def calculate_result_code(self):
        if self.overflow_bit_node is not None:
            return "%s(%s, %s, &%s)" % (
                self.func,
                self.operand1.result(),
                self.operand2.result(),
                self.overflow_bit_node.overflow_bit)
        elif self.infix:
            return "(%s %s %s)" % (
                self.operand1.result(),
                self.operator,
                self.operand2.result())
        else:
            func = self.type.binary_op(self.operator)
            if func is None:
                error(self.pos, "binary operator %s not supported for %s" % (self.operator, self.type))
            return "%s(%s, %s)" % (
                func,
                self.operand1.result(),
                self.operand2.result())

    def is_py_operation_types(self, type1, type2):
        return (type1.is_unicode_char or
                type2.is_unicode_char or
                BinopNode.is_py_operation_types(self, type1, type2))

    def py_operation_function(self):
        function_name = self.py_functions[self.operator]
        if self.inplace:
            function_name = function_name.replace('PyNumber_', 'PyNumber_InPlace')
        return function_name

    py_functions = {
        "|":        "PyNumber_Or",
        "^":        "PyNumber_Xor",
        "&":        "PyNumber_And",
        "<<":       "PyNumber_Lshift",
        ">>":       "PyNumber_Rshift",
        "+":        "PyNumber_Add",
        "-":        "PyNumber_Subtract",
        "*":        "PyNumber_Multiply",
        "/":        "__Pyx_PyNumber_Divide",
        "//":       "PyNumber_FloorDivide",
        "%":        "PyNumber_Remainder",
        "**":       "PyNumber_Power"
    }

    overflow_op_names = {
        "+":  "add",
        "-":  "sub",
        "*":  "mul",
        "<<":  "lshift",
    }


class IntBinopNode(NumBinopNode):
    #  Binary operation taking integer arguments.

    def c_types_okay(self, type1, type2):
        #print "IntBinopNode.c_types_okay:", type1, type2 ###
        return (type1.is_int or type1.is_enum) \
            and (type2.is_int or type2.is_enum)


class AddNode(NumBinopNode):
    #  '+' operator.

    def is_py_operation_types(self, type1, type2):
        if type1.is_string and type2.is_string or type1.is_pyunicode_ptr and type2.is_pyunicode_ptr:
            return 1
        else:
            return NumBinopNode.is_py_operation_types(self, type1, type2)

    def infer_builtin_types_operation(self, type1, type2):
        # b'abc' + 'abc' raises an exception in Py3,
        # so we can safely infer the Py2 type for bytes here
        string_types = [bytes_type, str_type, basestring_type, unicode_type]  # Py2.4 lacks tuple.index()
        if type1 in string_types and type2 in string_types:
            return string_types[max(string_types.index(type1),
                                    string_types.index(type2))]
        return None

    def compute_c_result_type(self, type1, type2):
        #print "AddNode.compute_c_result_type:", type1, self.operator, type2 ###
        if (type1.is_ptr or type1.is_array) and (type2.is_int or type2.is_enum):
            return type1
        elif (type2.is_ptr or type2.is_array) and (type1.is_int or type1.is_enum):
            return type2
        else:
            return NumBinopNode.compute_c_result_type(
                self, type1, type2)

    def py_operation_function(self):
        type1, type2 = self.operand1.type, self.operand2.type
        if type1 is unicode_type or type2 is unicode_type:
            if type1.is_builtin_type and type2.is_builtin_type:
                if self.operand1.may_be_none() or self.operand2.may_be_none():
                    return '__Pyx_PyUnicode_ConcatSafe'
                else:
                    return '__Pyx_PyUnicode_Concat'
        return super(AddNode, self).py_operation_function()


class SubNode(NumBinopNode):
    #  '-' operator.

    def compute_c_result_type(self, type1, type2):
        if (type1.is_ptr or type1.is_array) and (type2.is_int or type2.is_enum):
            return type1
        elif (type1.is_ptr or type1.is_array) and (type2.is_ptr or type2.is_array):
            return PyrexTypes.c_ptrdiff_t_type
        else:
            return NumBinopNode.compute_c_result_type(
                self, type1, type2)


class MulNode(NumBinopNode):
    #  '*' operator.

    def is_py_operation_types(self, type1, type2):
        if ((type1.is_string and type2.is_int) or
                (type2.is_string and type1.is_int)):
            return 1
        else:
            return NumBinopNode.is_py_operation_types(self, type1, type2)

    def infer_builtin_types_operation(self, type1, type2):
        # let's assume that whatever builtin type you multiply a string with
        # will either return a string of the same type or fail with an exception
        string_types = (bytes_type, str_type, basestring_type, unicode_type)
        if type1 in string_types and type2.is_builtin_type:
            return type1
        if type2 in string_types and type1.is_builtin_type:
            return type2
        # multiplication of containers/numbers with an integer value
        # always (?) returns the same type
        if type1.is_int:
            return type2
        if type2.is_int:
            return type1
        return None


class DivNode(NumBinopNode):
    #  '/' or '//' operator.

    cdivision = None
    truedivision = None   # == "unknown" if operator == '/'
    ctruedivision = False
    cdivision_warnings = False
    zerodivision_check = None

    def find_compile_time_binary_operator(self, op1, op2):
        func = compile_time_binary_operators[self.operator]
        if self.operator == '/' and self.truedivision is None:
            # => true div for floats, floor div for integers
            if isinstance(op1, (int,long)) and isinstance(op2, (int,long)):
                func = compile_time_binary_operators['//']
        return func

    def calculate_constant_result(self):
        op1 = self.operand1.constant_result
        op2 = self.operand2.constant_result
        func = self.find_compile_time_binary_operator(op1, op2)
        self.constant_result = func(
            self.operand1.constant_result,
            self.operand2.constant_result)

    def compile_time_value(self, denv):
        operand1 = self.operand1.compile_time_value(denv)
        operand2 = self.operand2.compile_time_value(denv)
        try:
            func = self.find_compile_time_binary_operator(
                operand1, operand2)
            return func(operand1, operand2)
        except Exception, e:
            self.compile_time_value_error(e)

    def analyse_operation(self, env):
        if self.cdivision or env.directives['cdivision']:
            self.ctruedivision = False
        else:
            self.ctruedivision = self.truedivision
        NumBinopNode.analyse_operation(self, env)
        if self.is_cpp_operation():
            self.cdivision = True
        if not self.type.is_pyobject:
            self.zerodivision_check = (
                self.cdivision is None and not env.directives['cdivision']
                and (not self.operand2.has_constant_result() or
                     self.operand2.constant_result == 0))
            if self.zerodivision_check or env.directives['cdivision_warnings']:
                # Need to check ahead of time to warn or raise zero division error
                self.operand1 = self.operand1.coerce_to_simple(env)
                self.operand2 = self.operand2.coerce_to_simple(env)

    def compute_c_result_type(self, type1, type2):
        if self.operator == '/' and self.ctruedivision:
            if not type1.is_float and not type2.is_float:
                widest_type = PyrexTypes.widest_numeric_type(type1, PyrexTypes.c_double_type)
                widest_type = PyrexTypes.widest_numeric_type(type2, widest_type)
                return widest_type
        return NumBinopNode.compute_c_result_type(self, type1, type2)

    def zero_division_message(self):
        if self.type.is_int:
            return "integer division or modulo by zero"
        else:
            return "float division"

    def generate_evaluation_code(self, code):
        if not self.type.is_pyobject and not self.type.is_complex:
            if self.cdivision is None:
                self.cdivision = (code.globalstate.directives['cdivision']
                                    or not self.type.signed
                                    or self.type.is_float)
            if not self.cdivision:
                code.globalstate.use_utility_code(div_int_utility_code.specialize(self.type))
        NumBinopNode.generate_evaluation_code(self, code)
        self.generate_div_warning_code(code)

    def generate_div_warning_code(self, code):
        if not self.type.is_pyobject:
            if self.zerodivision_check:
                if not self.infix:
                    zero_test = "%s(%s)" % (self.type.unary_op('zero'), self.operand2.result())
                else:
                    zero_test = "%s == 0" % self.operand2.result()
                code.putln("if (unlikely(%s)) {" % zero_test)
                code.put_ensure_gil()
                code.putln('PyErr_SetString(PyExc_ZeroDivisionError, "%s");' % self.zero_division_message())
                code.put_release_ensured_gil()
                code.putln(code.error_goto(self.pos))
                code.putln("}")
                if self.type.is_int and self.type.signed and self.operator != '%':
                    code.globalstate.use_utility_code(division_overflow_test_code)
                    if self.operand2.type.signed == 2:
                        # explicitly signed, no runtime check needed
                        minus1_check = 'unlikely(%s == -1)' % self.operand2.result()
                    else:
                        type_of_op2 = self.operand2.type.declaration_code('')
                        minus1_check = '(!(((%s)-1) > 0)) && unlikely(%s == (%s)-1)' % (
                            type_of_op2, self.operand2.result(), type_of_op2)
                    code.putln("else if (sizeof(%s) == sizeof(long) && %s "
                               " && unlikely(UNARY_NEG_WOULD_OVERFLOW(%s))) {" % (
                               self.type.declaration_code(''),
                               minus1_check,
                               self.operand1.result()))
                    code.put_ensure_gil()
                    code.putln('PyErr_SetString(PyExc_OverflowError, "value too large to perform division");')
                    code.put_release_ensured_gil()
                    code.putln(code.error_goto(self.pos))
                    code.putln("}")
            if code.globalstate.directives['cdivision_warnings'] and self.operator != '/':
                code.globalstate.use_utility_code(cdivision_warning_utility_code)
                code.putln("if (unlikely((%s < 0) ^ (%s < 0))) {" % (
                                self.operand1.result(),
                                self.operand2.result()))
                code.put_ensure_gil()
                code.putln(code.set_error_info(self.pos, used=True))
                code.putln("if (__Pyx_cdivision_warning(%(FILENAME)s, "
                                                       "%(LINENO)s)) {" % {
                    'FILENAME': Naming.filename_cname,
                    'LINENO':  Naming.lineno_cname,
                    })
                code.put_release_ensured_gil()
                code.put_goto(code.error_label)
                code.putln("}")
                code.put_release_ensured_gil()
                code.putln("}")

    def calculate_result_code(self):
        if self.type.is_complex:
            return NumBinopNode.calculate_result_code(self)
        elif self.type.is_float and self.operator == '//':
            return "floor(%s / %s)" % (
                self.operand1.result(),
                self.operand2.result())
        elif self.truedivision or self.cdivision:
            op1 = self.operand1.result()
            op2 = self.operand2.result()
            if self.truedivision:
                if self.type != self.operand1.type:
                    op1 = self.type.cast_code(op1)
                if self.type != self.operand2.type:
                    op2 = self.type.cast_code(op2)
            return "(%s / %s)" % (op1, op2)
        else:
            return "__Pyx_div_%s(%s, %s)" % (
                self.type.specialization_name(),
                self.operand1.result(),
                self.operand2.result())


class ModNode(DivNode):
    #  '%' operator.

    def is_py_operation_types(self, type1, type2):
        return (type1.is_string
                or type2.is_string
                or NumBinopNode.is_py_operation_types(self, type1, type2))

    def infer_builtin_types_operation(self, type1, type2):
        # b'%s' % xyz  raises an exception in Py3, so it's safe to infer the type for Py2
        if type1 is unicode_type:
            # None + xyz  may be implemented by RHS
            if type2.is_builtin_type or not self.operand1.may_be_none():
                return type1
        elif type1 in (bytes_type, str_type, basestring_type):
            if type2 is unicode_type:
                return type2
            elif type2.is_numeric:
                return type1
            elif type1 is bytes_type and not type2.is_builtin_type:
                return None   # RHS might implement '% operator differently in Py3
            else:
                return basestring_type  # either str or unicode, can't tell
        return None

    def zero_division_message(self):
        if self.type.is_int:
            return "integer division or modulo by zero"
        else:
            return "float divmod()"

    def analyse_operation(self, env):
        DivNode.analyse_operation(self, env)
        if not self.type.is_pyobject:
            if self.cdivision is None:
                self.cdivision = env.directives['cdivision'] or not self.type.signed
            if not self.cdivision and not self.type.is_int and not self.type.is_float:
                error(self.pos, "mod operator not supported for type '%s'" % self.type)

    def generate_evaluation_code(self, code):
        if not self.type.is_pyobject and not self.cdivision:
            if self.type.is_int:
                code.globalstate.use_utility_code(
                    mod_int_utility_code.specialize(self.type))
            else:  # float
                code.globalstate.use_utility_code(
                    mod_float_utility_code.specialize(
                        self.type, math_h_modifier=self.type.math_h_modifier))
        # note: skipping over DivNode here
        NumBinopNode.generate_evaluation_code(self, code)
        self.generate_div_warning_code(code)

    def calculate_result_code(self):
        if self.cdivision:
            if self.type.is_float:
                return "fmod%s(%s, %s)" % (
                    self.type.math_h_modifier,
                    self.operand1.result(),
                    self.operand2.result())
            else:
                return "(%s %% %s)" % (
                    self.operand1.result(),
                    self.operand2.result())
        else:
            return "__Pyx_mod_%s(%s, %s)" % (
                    self.type.specialization_name(),
                    self.operand1.result(),
                    self.operand2.result())

    def py_operation_function(self):
        if self.operand1.type is unicode_type:
            if self.operand1.may_be_none():
                return '__Pyx_PyUnicode_FormatSafe'
            else:
                return 'PyUnicode_Format'
        elif self.operand1.type is str_type:
            if self.operand1.may_be_none():
                return '__Pyx_PyString_FormatSafe'
            else:
                return '__Pyx_PyString_Format'
        return super(ModNode, self).py_operation_function()


class PowNode(NumBinopNode):
    #  '**' operator.

    def analyse_c_operation(self, env):
        NumBinopNode.analyse_c_operation(self, env)
        if self.type.is_complex:
            if self.type.real_type.is_float:
                self.operand1 = self.operand1.coerce_to(self.type, env)
                self.operand2 = self.operand2.coerce_to(self.type, env)
                self.pow_func = "__Pyx_c_pow" + self.type.real_type.math_h_modifier
            else:
                error(self.pos, "complex int powers not supported")
                self.pow_func = "<error>"
        elif self.type.is_float:
            self.pow_func = "pow" + self.type.math_h_modifier
        elif self.type.is_int:
            self.pow_func = "__Pyx_pow_%s" % self.type.declaration_code('').replace(' ', '_')
            env.use_utility_code(
                int_pow_utility_code.specialize(
                    func_name=self.pow_func,
                    type=self.type.declaration_code(''),
                    signed=self.type.signed and 1 or 0))
        elif not self.type.is_error:
            error(self.pos, "got unexpected types for C power operator: %s, %s" %
                            (self.operand1.type, self.operand2.type))

    def calculate_result_code(self):
        # Work around MSVC overloading ambiguity.
        def typecast(operand):
            if self.type == operand.type:
                return operand.result()
            else:
                return self.type.cast_code(operand.result())
        return "%s(%s, %s)" % (
            self.pow_func,
            typecast(self.operand1),
            typecast(self.operand2))


# Note: This class is temporarily "shut down" into an ineffective temp
# allocation mode.
#
# More sophisticated temp reuse was going on before, one could have a
# look at adding this again after /all/ classes are converted to the
# new temp scheme. (The temp juggling cannot work otherwise).
class BoolBinopNode(ExprNode):
    #  Short-circuiting boolean operation.
    #
    #  operator     string
    #  operand1     ExprNode
    #  operand2     ExprNode

    subexprs = ['operand1', 'operand2']

    def infer_type(self, env):
        type1 = self.operand1.infer_type(env)
        type2 = self.operand2.infer_type(env)
        return PyrexTypes.independent_spanning_type(type1, type2)

    def may_be_none(self):
        if self.operator == 'or':
            return self.operand2.may_be_none()
        else:
            return self.operand1.may_be_none() or self.operand2.may_be_none()

    def calculate_constant_result(self):
        if self.operator == 'and':
            self.constant_result = \
                self.operand1.constant_result and \
                self.operand2.constant_result
        else:
            self.constant_result = \
                self.operand1.constant_result or \
                self.operand2.constant_result

    def compile_time_value(self, denv):
        if self.operator == 'and':
            return self.operand1.compile_time_value(denv) \
                and self.operand2.compile_time_value(denv)
        else:
            return self.operand1.compile_time_value(denv) \
                or self.operand2.compile_time_value(denv)

    def coerce_to_boolean(self, env):
        return BoolBinopNode(
            self.pos,
            operator = self.operator,
            operand1 = self.operand1.coerce_to_boolean(env),
            operand2 = self.operand2.coerce_to_boolean(env),
            type = PyrexTypes.c_bint_type,
            is_temp = self.is_temp)

    def analyse_types(self, env):
        self.operand1 = self.operand1.analyse_types(env)
        self.operand2 = self.operand2.analyse_types(env)
        self.type = PyrexTypes.independent_spanning_type(self.operand1.type, self.operand2.type)
        self.operand1 = self.operand1.coerce_to(self.type, env)
        self.operand2 = self.operand2.coerce_to(self.type, env)

        # For what we're about to do, it's vital that
        # both operands be temp nodes.
        self.operand1 = self.operand1.coerce_to_simple(env)
        self.operand2 = self.operand2.coerce_to_simple(env)
        self.is_temp = 1
        return self

    gil_message = "Truth-testing Python object"

    def check_const(self):
        return self.operand1.check_const() and self.operand2.check_const()

    def generate_evaluation_code(self, code):
        code.mark_pos(self.pos)
        self.operand1.generate_evaluation_code(code)
        test_result, uses_temp = self.generate_operand1_test(code)
        if self.operator == 'and':
            sense = ""
        else:
            sense = "!"
        code.putln(
            "if (%s%s) {" % (
                sense,
                test_result))
        if uses_temp:
            code.funcstate.release_temp(test_result)
        self.operand1.generate_disposal_code(code)
        self.operand2.generate_evaluation_code(code)
        self.allocate_temp_result(code)
        self.operand2.make_owned_reference(code)
        code.putln("%s = %s;" % (self.result(), self.operand2.result()))
        self.operand2.generate_post_assignment_code(code)
        self.operand2.free_temps(code)
        code.putln("} else {")
        self.operand1.make_owned_reference(code)
        code.putln("%s = %s;" % (self.result(), self.operand1.result()))
        self.operand1.generate_post_assignment_code(code)
        self.operand1.free_temps(code)
        code.putln("}")

    def generate_operand1_test(self, code):
        #  Generate code to test the truth of the first operand.
        if self.type.is_pyobject:
            test_result = code.funcstate.allocate_temp(PyrexTypes.c_bint_type,
                                                       manage_ref=False)
            code.putln(
                "%s = __Pyx_PyObject_IsTrue(%s); %s" % (
                    test_result,
                    self.operand1.py_result(),
                    code.error_goto_if_neg(test_result, self.pos)))
        else:
            test_result = self.operand1.result()
        return (test_result, self.type.is_pyobject)


class CondExprNode(ExprNode):
    #  Short-circuiting conditional expression.
    #
    #  test        ExprNode
    #  true_val    ExprNode
    #  false_val   ExprNode

    true_val = None
    false_val = None

    subexprs = ['test', 'true_val', 'false_val']

    def type_dependencies(self, env):
        return self.true_val.type_dependencies(env) + self.false_val.type_dependencies(env)

    def infer_type(self, env):
        return PyrexTypes.independent_spanning_type(
            self.true_val.infer_type(env),
            self.false_val.infer_type(env))

    def calculate_constant_result(self):
        if self.test.constant_result:
            self.constant_result = self.true_val.constant_result
        else:
            self.constant_result = self.false_val.constant_result

    def analyse_types(self, env):
        self.test = self.test.analyse_types(env).coerce_to_boolean(env)
        self.true_val = self.true_val.analyse_types(env)
        self.false_val = self.false_val.analyse_types(env)
        self.is_temp = 1
        return self.analyse_result_type(env)

    def analyse_result_type(self, env):
        self.type = PyrexTypes.independent_spanning_type(
            self.true_val.type, self.false_val.type)
        if self.type.is_pyobject:
            self.result_ctype = py_object_type
        if self.true_val.type.is_pyobject or self.false_val.type.is_pyobject:
            self.true_val = self.true_val.coerce_to(self.type, env)
            self.false_val = self.false_val.coerce_to(self.type, env)
        if self.type == PyrexTypes.error_type:
            self.type_error()
        return self

    def coerce_to(self, dst_type, env):
        self.true_val = self.true_val.coerce_to(dst_type, env)
        self.false_val = self.false_val.coerce_to(dst_type, env)
        self.result_ctype = None
        return self.analyse_result_type(env)

    def type_error(self):
        if not (self.true_val.type.is_error or self.false_val.type.is_error):
            error(self.pos, "Incompatible types in conditional expression (%s; %s)" %
                (self.true_val.type, self.false_val.type))
        self.type = PyrexTypes.error_type

    def check_const(self):
        return (self.test.check_const()
            and self.true_val.check_const()
            and self.false_val.check_const())

    def generate_evaluation_code(self, code):
        # Because subexprs may not be evaluated we can use a more optimal
        # subexpr allocation strategy than the default, so override evaluation_code.

        code.mark_pos(self.pos)
        self.allocate_temp_result(code)
        self.test.generate_evaluation_code(code)
        code.putln("if (%s) {" % self.test.result() )
        self.eval_and_get(code, self.true_val)
        code.putln("} else {")
        self.eval_and_get(code, self.false_val)
        code.putln("}")
        self.test.generate_disposal_code(code)
        self.test.free_temps(code)

    def eval_and_get(self, code, expr):
        expr.generate_evaluation_code(code)
        expr.make_owned_reference(code)
        code.putln('%s = %s;' % (self.result(), expr.result_as(self.ctype())))
        expr.generate_post_assignment_code(code)
        expr.free_temps(code)

richcmp_constants = {
    "<" : "Py_LT",
    "<=": "Py_LE",
    "==": "Py_EQ",
    "!=": "Py_NE",
    "<>": "Py_NE",
    ">" : "Py_GT",
    ">=": "Py_GE",
    # the following are faked by special compare functions
    "in"    : "Py_EQ",
    "not_in": "Py_NE",
}

class CmpNode(object):
    #  Mixin class containing code common to PrimaryCmpNodes
    #  and CascadedCmpNodes.

    special_bool_cmp_function = None
    special_bool_cmp_utility_code = None

    def infer_type(self, env):
        # TODO: Actually implement this (after merging with -unstable).
        return py_object_type

    def calculate_cascaded_constant_result(self, operand1_result):
        func = compile_time_binary_operators[self.operator]
        operand2_result = self.operand2.constant_result
        if (isinstance(operand1_result, (bytes, unicode)) and
                isinstance(operand2_result, (bytes, unicode)) and
                type(operand1_result) != type(operand2_result)):
            # string comparison of different types isn't portable
            return

        if self.operator in ('in', 'not_in'):
            if isinstance(self.operand2, (ListNode, TupleNode, SetNode)):
                if not self.operand2.args:
                    self.constant_result = self.operator == 'not_in'
                    return
                elif isinstance(self.operand2, ListNode) and not self.cascade:
                    # tuples are more efficient to store than lists
                    self.operand2 = self.operand2.as_tuple()
            elif isinstance(self.operand2, DictNode):
                if not self.operand2.key_value_pairs:
                    self.constant_result = self.operator == 'not_in'
                    return

        self.constant_result = func(operand1_result, operand2_result)

    def cascaded_compile_time_value(self, operand1, denv):
        func = get_compile_time_binop(self)
        operand2 = self.operand2.compile_time_value(denv)
        try:
            result = func(operand1, operand2)
        except Exception, e:
            self.compile_time_value_error(e)
            result = None
        if result:
            cascade = self.cascade
            if cascade:
                result = result and cascade.cascaded_compile_time_value(operand2, denv)
        return result

    def is_cpp_comparison(self):
        return self.operand1.type.is_cpp_class or self.operand2.type.is_cpp_class

    def find_common_int_type(self, env, op, operand1, operand2):
        # type1 != type2 and at least one of the types is not a C int
        type1 = operand1.type
        type2 = operand2.type
        type1_can_be_int = False
        type2_can_be_int = False

        if operand1.is_string_literal and operand1.can_coerce_to_char_literal():
            type1_can_be_int = True
        if operand2.is_string_literal and operand2.can_coerce_to_char_literal():
            type2_can_be_int = True

        if type1.is_int:
            if type2_can_be_int:
                return type1
        elif type2.is_int:
            if type1_can_be_int:
                return type2
        elif type1_can_be_int:
            if type2_can_be_int:
                if Builtin.unicode_type in (type1, type2):
                    return PyrexTypes.c_py_ucs4_type
                else:
                    return PyrexTypes.c_uchar_type

        return None

    def find_common_type(self, env, op, operand1, common_type=None):
        operand2 = self.operand2
        type1 = operand1.type
        type2 = operand2.type

        new_common_type = None

        # catch general errors
        if type1 == str_type and (type2.is_string or type2 in (bytes_type, unicode_type)) or \
               type2 == str_type and (type1.is_string or type1 in (bytes_type, unicode_type)):
            error(self.pos, "Comparisons between bytes/unicode and str are not portable to Python 3")
            new_common_type = error_type

        # try to use numeric comparisons where possible
        elif type1.is_complex or type2.is_complex:
            if op not in ('==', '!=') \
               and (type1.is_complex or type1.is_numeric) \
               and (type2.is_complex or type2.is_numeric):
                error(self.pos, "complex types are unordered")
                new_common_type = error_type
            elif type1.is_pyobject:
                new_common_type = type1
            elif type2.is_pyobject:
                new_common_type = type2
            else:
                new_common_type = PyrexTypes.widest_numeric_type(type1, type2)
        elif type1.is_numeric and type2.is_numeric:
            new_common_type = PyrexTypes.widest_numeric_type(type1, type2)
        elif common_type is None or not common_type.is_pyobject:
            new_common_type = self.find_common_int_type(env, op, operand1, operand2)

        if new_common_type is None:
            # fall back to generic type compatibility tests
            if type1 == type2:
                new_common_type = type1
            elif type1.is_pyobject or type2.is_pyobject:
                if type2.is_numeric or type2.is_string:
                    if operand2.check_for_coercion_error(type1, env):
                        new_common_type = error_type
                    else:
                        new_common_type = py_object_type
                elif type1.is_numeric or type1.is_string:
                    if operand1.check_for_coercion_error(type2, env):
                        new_common_type = error_type
                    else:
                        new_common_type = py_object_type
                elif py_object_type.assignable_from(type1) and py_object_type.assignable_from(type2):
                    new_common_type = py_object_type
                else:
                    # one Python type and one non-Python type, not assignable
                    self.invalid_types_error(operand1, op, operand2)
                    new_common_type = error_type
            elif type1.assignable_from(type2):
                new_common_type = type1
            elif type2.assignable_from(type1):
                new_common_type = type2
            else:
                # C types that we couldn't handle up to here are an error
                self.invalid_types_error(operand1, op, operand2)
                new_common_type = error_type

        if new_common_type.is_string and (isinstance(operand1, BytesNode) or
                                          isinstance(operand2, BytesNode)):
            # special case when comparing char* to bytes literal: must
            # compare string values!
            new_common_type = bytes_type

        # recursively merge types
        if common_type is None or new_common_type.is_error:
            common_type = new_common_type
        else:
            # we could do a lot better by splitting the comparison
            # into a non-Python part and a Python part, but this is
            # safer for now
            common_type = PyrexTypes.spanning_type(common_type, new_common_type)

        if self.cascade:
            common_type = self.cascade.find_common_type(env, self.operator, operand2, common_type)

        return common_type

    def invalid_types_error(self, operand1, op, operand2):
        error(self.pos, "Invalid types for '%s' (%s, %s)" %
              (op, operand1.type, operand2.type))

    def is_python_comparison(self):
        return (not self.is_ptr_contains()
            and not self.is_c_string_contains()
            and (self.has_python_operands()
                 or (self.cascade and self.cascade.is_python_comparison())
                 or self.operator in ('in', 'not_in')))

    def coerce_operands_to(self, dst_type, env):
        operand2 = self.operand2
        if operand2.type != dst_type:
            self.operand2 = operand2.coerce_to(dst_type, env)
        if self.cascade:
            self.cascade.coerce_operands_to(dst_type, env)

    def is_python_result(self):
        return ((self.has_python_operands() and
                 self.special_bool_cmp_function is None and
                 self.operator not in ('is', 'is_not', 'in', 'not_in') and
                 not self.is_c_string_contains() and
                 not self.is_ptr_contains())
            or (self.cascade and self.cascade.is_python_result()))

    def is_c_string_contains(self):
        return self.operator in ('in', 'not_in') and \
               ((self.operand1.type.is_int
                 and (self.operand2.type.is_string or self.operand2.type is bytes_type)) or
                (self.operand1.type.is_unicode_char
                 and self.operand2.type is unicode_type))

    def is_ptr_contains(self):
        if self.operator in ('in', 'not_in'):
            container_type = self.operand2.type
            return (container_type.is_ptr or container_type.is_array) \
                and not container_type.is_string

    def find_special_bool_compare_function(self, env, operand1, result_is_bool=False):
        # note: currently operand1 must get coerced to a Python object if we succeed here!
        if self.operator in ('==', '!='):
            type1, type2 = operand1.type, self.operand2.type
            if result_is_bool or (type1.is_builtin_type and type2.is_builtin_type):
                if type1 is Builtin.unicode_type or type2 is Builtin.unicode_type:
                    self.special_bool_cmp_utility_code = UtilityCode.load_cached("UnicodeEquals", "StringTools.c")
                    self.special_bool_cmp_function = "__Pyx_PyUnicode_Equals"
                    return True
                elif type1 is Builtin.bytes_type or type2 is Builtin.bytes_type:
                    self.special_bool_cmp_utility_code = UtilityCode.load_cached("BytesEquals", "StringTools.c")
                    self.special_bool_cmp_function = "__Pyx_PyBytes_Equals"
                    return True
                elif type1 is Builtin.basestring_type or type2 is Builtin.basestring_type:
                    self.special_bool_cmp_utility_code = UtilityCode.load_cached("UnicodeEquals", "StringTools.c")
                    self.special_bool_cmp_function = "__Pyx_PyUnicode_Equals"
                    return True
                elif type1 is Builtin.str_type or type2 is Builtin.str_type:
                    self.special_bool_cmp_utility_code = UtilityCode.load_cached("StrEquals", "StringTools.c")
                    self.special_bool_cmp_function = "__Pyx_PyString_Equals"
                    return True
        elif self.operator in ('in', 'not_in'):
            if self.operand2.type is Builtin.dict_type:
                self.operand2 = self.operand2.as_none_safe_node("'NoneType' object is not iterable")
                self.special_bool_cmp_utility_code = UtilityCode.load_cached("PyDictContains", "ObjectHandling.c")
                self.special_bool_cmp_function = "__Pyx_PyDict_Contains"
                return True
            elif self.operand2.type is Builtin.unicode_type:
                self.operand2 = self.operand2.as_none_safe_node("'NoneType' object is not iterable")
                self.special_bool_cmp_utility_code = UtilityCode.load_cached("PyUnicodeContains", "StringTools.c")
                self.special_bool_cmp_function = "__Pyx_PyUnicode_Contains"
                return True
            else:
                if not self.operand2.type.is_pyobject:
                    self.operand2 = self.operand2.coerce_to_pyobject(env)
                self.special_bool_cmp_utility_code = UtilityCode.load_cached("PySequenceContains", "ObjectHandling.c")
                self.special_bool_cmp_function = "__Pyx_PySequence_Contains"
                return True
        return False

    def generate_operation_code(self, code, result_code,
            operand1, op , operand2):
        if self.type.is_pyobject:
            error_clause = code.error_goto_if_null
            got_ref = "__Pyx_XGOTREF(%s); " % result_code
            if self.special_bool_cmp_function:
                code.globalstate.use_utility_code(
                    UtilityCode.load_cached("PyBoolOrNullFromLong", "ObjectHandling.c"))
                coerce_result = "__Pyx_PyBoolOrNull_FromLong"
            else:
                coerce_result = "__Pyx_PyBool_FromLong"
        else:
            error_clause = code.error_goto_if_neg
            got_ref = ""
            coerce_result = ""

        if self.special_bool_cmp_function:
            if operand1.type.is_pyobject:
                result1 = operand1.py_result()
            else:
                result1 = operand1.result()
            if operand2.type.is_pyobject:
                result2 = operand2.py_result()
            else:
                result2 = operand2.result()
            if self.special_bool_cmp_utility_code:
                code.globalstate.use_utility_code(self.special_bool_cmp_utility_code)
            code.putln(
                "%s = %s(%s(%s, %s, %s)); %s%s" % (
                    result_code,
                    coerce_result,
                    self.special_bool_cmp_function,
                    result1, result2, richcmp_constants[op],
                    got_ref,
                    error_clause(result_code, self.pos)))

        elif operand1.type.is_pyobject and op not in ('is', 'is_not'):
            assert op not in ('in', 'not_in'), op
            code.putln("%s = PyObject_RichCompare(%s, %s, %s); %s%s" % (
                    result_code,
                    operand1.py_result(),
                    operand2.py_result(),
                    richcmp_constants[op],
                    got_ref,
                    error_clause(result_code, self.pos)))

        elif operand1.type.is_complex:
            code.putln("%s = %s(%s%s(%s, %s));" % (
                result_code,
                coerce_result,
                op == "!=" and "!" or "",
                operand1.type.unary_op('eq'),
                operand1.result(),
                operand2.result()))

        else:
            type1 = operand1.type
            type2 = operand2.type
            if (type1.is_extension_type or type2.is_extension_type) \
                    and not type1.same_as(type2):
                common_type = py_object_type
            elif type1.is_numeric:
                common_type = PyrexTypes.widest_numeric_type(type1, type2)
            else:
                common_type = type1
            code1 = operand1.result_as(common_type)
            code2 = operand2.result_as(common_type)
            code.putln("%s = %s(%s %s %s);" % (
                result_code,
                coerce_result,
                code1,
                self.c_operator(op),
                code2))

    def c_operator(self, op):
        if op == 'is':
            return "=="
        elif op == 'is_not':
            return "!="
        else:
            return op

class PrimaryCmpNode(ExprNode, CmpNode):
    #  Non-cascaded comparison or first comparison of
    #  a cascaded sequence.
    #
    #  operator      string
    #  operand1      ExprNode
    #  operand2      ExprNode
    #  cascade       CascadedCmpNode

    #  We don't use the subexprs mechanism, because
    #  things here are too complicated for it to handle.
    #  Instead, we override all the framework methods
    #  which use it.

    child_attrs = ['operand1', 'operand2', 'coerced_operand2', 'cascade']

    cascade = None
    coerced_operand2 = None
    is_memslice_nonecheck = False

    def infer_type(self, env):
        # TODO: Actually implement this (after merging with -unstable).
        return py_object_type

    def type_dependencies(self, env):
        return ()

    def calculate_constant_result(self):
        assert not self.cascade
        self.calculate_cascaded_constant_result(self.operand1.constant_result)

    def compile_time_value(self, denv):
        operand1 = self.operand1.compile_time_value(denv)
        return self.cascaded_compile_time_value(operand1, denv)

    def analyse_types(self, env):
        self.operand1 = self.operand1.analyse_types(env)
        self.operand2 = self.operand2.analyse_types(env)
        if self.is_cpp_comparison():
            self.analyse_cpp_comparison(env)
            if self.cascade:
                error(self.pos, "Cascading comparison not yet supported for cpp types.")
            return self

        if self.analyse_memoryviewslice_comparison(env):
            return self

        if self.cascade:
            self.cascade = self.cascade.analyse_types(env)

        if self.operator in ('in', 'not_in'):
            if self.is_c_string_contains():
                self.is_pycmp = False
                common_type = None
                if self.cascade:
                    error(self.pos, "Cascading comparison not yet supported for 'int_val in string'.")
                    return self
                if self.operand2.type is unicode_type:
                    env.use_utility_code(UtilityCode.load_cached("PyUCS4InUnicode", "StringTools.c"))
                else:
                    if self.operand1.type is PyrexTypes.c_uchar_type:
                        self.operand1 = self.operand1.coerce_to(PyrexTypes.c_char_type, env)
                    if self.operand2.type is not bytes_type:
                        self.operand2 = self.operand2.coerce_to(bytes_type, env)
                    env.use_utility_code(UtilityCode.load_cached("BytesContains", "StringTools.c"))
                self.operand2 = self.operand2.as_none_safe_node(
                    "argument of type 'NoneType' is not iterable")
            elif self.is_ptr_contains():
                if self.cascade:
                    error(self.pos, "Cascading comparison not supported for 'val in sliced pointer'.")
                self.type = PyrexTypes.c_bint_type
                # Will be transformed by IterationTransform
                return self
            elif self.find_special_bool_compare_function(env, self.operand1):
                if not self.operand1.type.is_pyobject:
                    self.operand1 = self.operand1.coerce_to_pyobject(env)
                common_type = None # if coercion needed, the method call above has already done it
                self.is_pycmp = False # result is bint
            else:
                common_type = py_object_type
                self.is_pycmp = True
        elif self.find_special_bool_compare_function(env, self.operand1):
            if not self.operand1.type.is_pyobject:
                self.operand1 = self.operand1.coerce_to_pyobject(env)
            common_type = None # if coercion needed, the method call above has already done it
            self.is_pycmp = False # result is bint
        else:
            common_type = self.find_common_type(env, self.operator, self.operand1)
            self.is_pycmp = common_type.is_pyobject

        if common_type is not None and not common_type.is_error:
            if self.operand1.type != common_type:
                self.operand1 = self.operand1.coerce_to(common_type, env)
            self.coerce_operands_to(common_type, env)

        if self.cascade:
            self.operand2 = self.operand2.coerce_to_simple(env)
            self.cascade.coerce_cascaded_operands_to_temp(env)
            operand2 = self.cascade.optimise_comparison(self.operand2, env)
            if operand2 is not self.operand2:
                self.coerced_operand2 = operand2
        if self.is_python_result():
            self.type = PyrexTypes.py_object_type
        else:
            self.type = PyrexTypes.c_bint_type
        cdr = self.cascade
        while cdr:
            cdr.type = self.type
            cdr = cdr.cascade
        if self.is_pycmp or self.cascade or self.special_bool_cmp_function:
            # 1) owned reference, 2) reused value, 3) potential function error return value
            self.is_temp = 1
        return self

    def analyse_cpp_comparison(self, env):
        type1 = self.operand1.type
        type2 = self.operand2.type
        entry = env.lookup_operator(self.operator, [self.operand1, self.operand2])
        if entry is None:
            error(self.pos, "Invalid types for '%s' (%s, %s)" %
                (self.operator, type1, type2))
            self.type = PyrexTypes.error_type
            self.result_code = "<error>"
            return
        func_type = entry.type
        if func_type.is_ptr:
            func_type = func_type.base_type
        if len(func_type.args) == 1:
            self.operand2 = self.operand2.coerce_to(func_type.args[0].type, env)
        else:
            self.operand1 = self.operand1.coerce_to(func_type.args[0].type, env)
            self.operand2 = self.operand2.coerce_to(func_type.args[1].type, env)
        self.is_pycmp = False
        self.type = func_type.return_type

    def analyse_memoryviewslice_comparison(self, env):
        have_none = self.operand1.is_none or self.operand2.is_none
        have_slice = (self.operand1.type.is_memoryviewslice or
                      self.operand2.type.is_memoryviewslice)
        ops = ('==', '!=', 'is', 'is_not')
        if have_slice and have_none and self.operator in ops:
            self.is_pycmp = False
            self.type = PyrexTypes.c_bint_type
            self.is_memslice_nonecheck = True
            return True

        return False

    def coerce_to_boolean(self, env):
        if self.is_pycmp:
            # coercing to bool => may allow for more efficient comparison code
            if self.find_special_bool_compare_function(
                    env, self.operand1, result_is_bool=True):
                self.is_pycmp = False
                self.type = PyrexTypes.c_bint_type
                self.is_temp = 1
                if self.cascade:
                    operand2 = self.cascade.optimise_comparison(
                        self.operand2, env, result_is_bool=True)
                    if operand2 is not self.operand2:
                        self.coerced_operand2 = operand2
                return self
        # TODO: check if we can optimise parts of the cascade here
        return ExprNode.coerce_to_boolean(self, env)

    def has_python_operands(self):
        return (self.operand1.type.is_pyobject
            or self.operand2.type.is_pyobject)

    def check_const(self):
        if self.cascade:
            self.not_const()
            return False
        else:
            return self.operand1.check_const() and self.operand2.check_const()

    def calculate_result_code(self):
        if self.operand1.type.is_complex:
            if self.operator == "!=":
                negation = "!"
            else:
                negation = ""
            return "(%s%s(%s, %s))" % (
                negation,
                self.operand1.type.binary_op('=='),
                self.operand1.result(),
                self.operand2.result())
        elif self.is_c_string_contains():
            if self.operand2.type is unicode_type:
                method = "__Pyx_UnicodeContainsUCS4"
            else:
                method = "__Pyx_BytesContains"
            if self.operator == "not_in":
                negation = "!"
            else:
                negation = ""
            return "(%s%s(%s, %s))" % (
                negation,
                method,
                self.operand2.result(),
                self.operand1.result())
        else:
            result1 = self.operand1.result()
            result2 = self.operand2.result()
            if self.is_memslice_nonecheck:
                if self.operand1.type.is_memoryviewslice:
                    result1 = "((PyObject *) %s.memview)" % result1
                else:
                    result2 = "((PyObject *) %s.memview)" % result2

            return "(%s %s %s)" % (
                result1,
                self.c_operator(self.operator),
                result2)

    def generate_evaluation_code(self, code):
        self.operand1.generate_evaluation_code(code)
        self.operand2.generate_evaluation_code(code)
        if self.is_temp:
            self.allocate_temp_result(code)
            self.generate_operation_code(code, self.result(),
                self.operand1, self.operator, self.operand2)
            if self.cascade:
                self.cascade.generate_evaluation_code(
                    code, self.result(), self.coerced_operand2 or self.operand2,
                    needs_evaluation=self.coerced_operand2 is not None)
            self.operand1.generate_disposal_code(code)
            self.operand1.free_temps(code)
            self.operand2.generate_disposal_code(code)
            self.operand2.free_temps(code)

    def generate_subexpr_disposal_code(self, code):
        #  If this is called, it is a non-cascaded cmp,
        #  so only need to dispose of the two main operands.
        self.operand1.generate_disposal_code(code)
        self.operand2.generate_disposal_code(code)

    def free_subexpr_temps(self, code):
        #  If this is called, it is a non-cascaded cmp,
        #  so only need to dispose of the two main operands.
        self.operand1.free_temps(code)
        self.operand2.free_temps(code)

    def annotate(self, code):
        self.operand1.annotate(code)
        self.operand2.annotate(code)
        if self.cascade:
            self.cascade.annotate(code)


class CascadedCmpNode(Node, CmpNode):
    #  A CascadedCmpNode is not a complete expression node. It
    #  hangs off the side of another comparison node, shares
    #  its left operand with that node, and shares its result
    #  with the PrimaryCmpNode at the head of the chain.
    #
    #  operator      string
    #  operand2      ExprNode
    #  cascade       CascadedCmpNode

    child_attrs = ['operand2', 'coerced_operand2', 'cascade']

    cascade = None
    coerced_operand2 = None
    constant_result = constant_value_not_set # FIXME: where to calculate this?

    def infer_type(self, env):
        # TODO: Actually implement this (after merging with -unstable).
        return py_object_type

    def type_dependencies(self, env):
        return ()

    def has_constant_result(self):
        return self.constant_result is not constant_value_not_set and \
               self.constant_result is not not_a_constant

    def analyse_types(self, env):
        self.operand2 = self.operand2.analyse_types(env)
        if self.cascade:
            self.cascade = self.cascade.analyse_types(env)
        return self

    def has_python_operands(self):
        return self.operand2.type.is_pyobject

    def optimise_comparison(self, operand1, env, result_is_bool=False):
        if self.find_special_bool_compare_function(env, operand1, result_is_bool):
            self.is_pycmp = False
            self.type = PyrexTypes.c_bint_type
            if not operand1.type.is_pyobject:
                operand1 = operand1.coerce_to_pyobject(env)
        if self.cascade:
            operand2 = self.cascade.optimise_comparison(self.operand2, env, result_is_bool)
            if operand2 is not self.operand2:
                self.coerced_operand2 = operand2
        return operand1

    def coerce_operands_to_pyobjects(self, env):
        self.operand2 = self.operand2.coerce_to_pyobject(env)
        if self.operand2.type is dict_type and self.operator in ('in', 'not_in'):
            self.operand2 = self.operand2.as_none_safe_node("'NoneType' object is not iterable")
        if self.cascade:
            self.cascade.coerce_operands_to_pyobjects(env)

    def coerce_cascaded_operands_to_temp(self, env):
        if self.cascade:
            #self.operand2 = self.operand2.coerce_to_temp(env) #CTT
            self.operand2 = self.operand2.coerce_to_simple(env)
            self.cascade.coerce_cascaded_operands_to_temp(env)

    def generate_evaluation_code(self, code, result, operand1, needs_evaluation=False):
        if self.type.is_pyobject:
            code.putln("if (__Pyx_PyObject_IsTrue(%s)) {" % result)
            code.put_decref(result, self.type)
        else:
            code.putln("if (%s) {" % result)
        if needs_evaluation:
            operand1.generate_evaluation_code(code)
        self.operand2.generate_evaluation_code(code)
        self.generate_operation_code(code, result,
            operand1, self.operator, self.operand2)
        if self.cascade:
            self.cascade.generate_evaluation_code(
                code, result, self.coerced_operand2 or self.operand2,
                needs_evaluation=self.coerced_operand2 is not None)
        if needs_evaluation:
            operand1.generate_disposal_code(code)
            operand1.free_temps(code)
        # Cascaded cmp result is always temp
        self.operand2.generate_disposal_code(code)
        self.operand2.free_temps(code)
        code.putln("}")

    def annotate(self, code):
        self.operand2.annotate(code)
        if self.cascade:
            self.cascade.annotate(code)


binop_node_classes = {
    "or":       BoolBinopNode,
    "and":      BoolBinopNode,
    "|":        IntBinopNode,
    "^":        IntBinopNode,
    "&":        IntBinopNode,
    "<<":       IntBinopNode,
    ">>":       IntBinopNode,
    "+":        AddNode,
    "-":        SubNode,
    "*":        MulNode,
    "/":        DivNode,
    "//":       DivNode,
    "%":        ModNode,
    "**":       PowNode
}

def binop_node(pos, operator, operand1, operand2, inplace=False):
    # Construct binop node of appropriate class for
    # given operator.
    return binop_node_classes[operator](pos,
        operator = operator,
        operand1 = operand1,
        operand2 = operand2,
        inplace = inplace)

#-------------------------------------------------------------------
#
#  Coercion nodes
#
#  Coercion nodes are special in that they are created during
#  the analyse_types phase of parse tree processing.
#  Their __init__ methods consequently incorporate some aspects
#  of that phase.
#
#-------------------------------------------------------------------

class CoercionNode(ExprNode):
    #  Abstract base class for coercion nodes.
    #
    #  arg       ExprNode       node being coerced

    subexprs = ['arg']
    constant_result = not_a_constant

    def __init__(self, arg):
        super(CoercionNode, self).__init__(arg.pos)
        self.arg = arg
        if debug_coercion:
            print("%s Coercing %s" % (self, self.arg))

    def calculate_constant_result(self):
        # constant folding can break type coercion, so this is disabled
        pass

    def annotate(self, code):
        self.arg.annotate(code)
        if self.arg.type != self.type:
            file, line, col = self.pos
            code.annotate((file, line, col-1), AnnotationItem(
                style='coerce', tag='coerce', text='[%s] to [%s]' % (self.arg.type, self.type)))

class CoerceToMemViewSliceNode(CoercionNode):
    """
    Coerce an object to a memoryview slice. This holds a new reference in
    a managed temp.
    """

    def __init__(self, arg, dst_type, env):
        assert dst_type.is_memoryviewslice
        assert not arg.type.is_memoryviewslice
        CoercionNode.__init__(self, arg)
        self.type = dst_type
        self.is_temp = 1
        self.env = env
        self.use_managed_ref = True
        self.arg = arg

    def generate_result_code(self, code):
        self.type.create_from_py_utility_code(self.env)
        code.putln("%s = %s(%s);" % (self.result(),
                                     self.type.from_py_function,
                                     self.arg.py_result()))

        error_cond = self.type.error_condition(self.result())
        code.putln(code.error_goto_if(error_cond, self.pos))


class CastNode(CoercionNode):
    #  Wrap a node in a C type cast.

    def __init__(self, arg, new_type):
        CoercionNode.__init__(self, arg)
        self.type = new_type

    def may_be_none(self):
        return self.arg.may_be_none()

    def calculate_result_code(self):
        return self.arg.result_as(self.type)

    def generate_result_code(self, code):
        self.arg.generate_result_code(code)


class PyTypeTestNode(CoercionNode):
    #  This node is used to check that a generic Python
    #  object is an instance of a particular extension type.
    #  This node borrows the result of its argument node.

    exact_builtin_type = True

    def __init__(self, arg, dst_type, env, notnone=False):
        #  The arg is know to be a Python object, and
        #  the dst_type is known to be an extension type.
        assert dst_type.is_extension_type or dst_type.is_builtin_type, "PyTypeTest on non extension type"
        CoercionNode.__init__(self, arg)
        self.type = dst_type
        self.result_ctype = arg.ctype()
        self.notnone = notnone

    nogil_check = Node.gil_error
    gil_message = "Python type test"

    def analyse_types(self, env):
        return self

    def may_be_none(self):
        if self.notnone:
            return False
        return self.arg.may_be_none()

    def is_simple(self):
        return self.arg.is_simple()

    def result_in_temp(self):
        return self.arg.result_in_temp()

    def is_ephemeral(self):
        return self.arg.is_ephemeral()

    def nonlocally_immutable(self):
        return self.arg.nonlocally_immutable()

    def calculate_constant_result(self):
        # FIXME
        pass

    def calculate_result_code(self):
        return self.arg.result()

    def generate_result_code(self, code):
        if self.type.typeobj_is_available():
            if self.type.is_builtin_type:
                type_test = self.type.type_test_code(
                    self.arg.py_result(),
                    self.notnone, exact=self.exact_builtin_type)
            else:
                type_test = self.type.type_test_code(
                    self.arg.py_result(), self.notnone)
                code.globalstate.use_utility_code(
                    UtilityCode.load_cached("ExtTypeTest", "ObjectHandling.c"))
            code.putln("if (!(%s)) %s" % (
                type_test, code.error_goto(self.pos)))
        else:
            error(self.pos, "Cannot test type of extern C class "
                "without type object name specification")

    def generate_post_assignment_code(self, code):
        self.arg.generate_post_assignment_code(code)

    def free_temps(self, code):
        self.arg.free_temps(code)


class NoneCheckNode(CoercionNode):
    # This node is used to check that a Python object is not None and
    # raises an appropriate exception (as specified by the creating
    # transform).

    is_nonecheck = True

    def __init__(self, arg, exception_type_cname, exception_message,
                 exception_format_args):
        CoercionNode.__init__(self, arg)
        self.type = arg.type
        self.result_ctype = arg.ctype()
        self.exception_type_cname = exception_type_cname
        self.exception_message = exception_message
        self.exception_format_args = tuple(exception_format_args or ())

    nogil_check = None # this node only guards an operation that would fail already

    def analyse_types(self, env):
        return self

    def may_be_none(self):
        return False

    def is_simple(self):
        return self.arg.is_simple()

    def result_in_temp(self):
        return self.arg.result_in_temp()

    def nonlocally_immutable(self):
        return self.arg.nonlocally_immutable()

    def calculate_result_code(self):
        return self.arg.result()

    def condition(self):
        if self.type.is_pyobject:
            return self.arg.py_result()
        elif self.type.is_memoryviewslice:
            return "((PyObject *) %s.memview)" % self.arg.result()
        else:
            raise Exception("unsupported type")

    def put_nonecheck(self, code):
        code.putln(
            "if (unlikely(%s == Py_None)) {" % self.condition())

        if self.in_nogil_context:
            code.put_ensure_gil()

        escape = StringEncoding.escape_byte_string
        if self.exception_format_args:
            code.putln('PyErr_Format(%s, "%s", %s);' % (
                self.exception_type_cname,
                StringEncoding.escape_byte_string(
                    self.exception_message.encode('UTF-8')),
                ', '.join([ '"%s"' % escape(str(arg).encode('UTF-8'))
                            for arg in self.exception_format_args ])))
        else:
            code.putln('PyErr_SetString(%s, "%s");' % (
                self.exception_type_cname,
                escape(self.exception_message.encode('UTF-8'))))

        if self.in_nogil_context:
            code.put_release_ensured_gil()

        code.putln(code.error_goto(self.pos))
        code.putln("}")

    def generate_result_code(self, code):
        self.put_nonecheck(code)

    def generate_post_assignment_code(self, code):
        self.arg.generate_post_assignment_code(code)

    def free_temps(self, code):
        self.arg.free_temps(code)


class CoerceToPyTypeNode(CoercionNode):
    #  This node is used to convert a C data type
    #  to a Python object.

    type = py_object_type
    is_temp = 1

    def __init__(self, arg, env, type=py_object_type):
        if not arg.type.create_to_py_utility_code(env):
            error(arg.pos, "Cannot convert '%s' to Python object" % arg.type)
        elif arg.type.is_complex:
            # special case: complex coercion is so complex that it
            # uses a macro ("__pyx_PyComplex_FromComplex()"), for
            # which the argument must be simple
            arg = arg.coerce_to_simple(env)
        CoercionNode.__init__(self, arg)
        if type is py_object_type:
            # be specific about some known types
            if arg.type.is_string or arg.type.is_cpp_string:
                self.type = default_str_type(env)
            elif arg.type.is_pyunicode_ptr or arg.type.is_unicode_char:
                self.type = unicode_type
            elif arg.type.is_complex:
                self.type = Builtin.complex_type
        elif arg.type.is_string or arg.type.is_cpp_string:
            if (type not in (bytes_type, bytearray_type)
                    and not env.directives['c_string_encoding']):
                error(arg.pos,
                    "default encoding required for conversion from '%s' to '%s'" %
                    (arg.type, type))
            self.type = type
        else:
            # FIXME: check that the target type and the resulting type are compatible
            pass

        if arg.type.is_memoryviewslice:
            # Register utility codes at this point
            arg.type.get_to_py_function(env, arg)

        self.env = env

    gil_message = "Converting to Python object"

    def may_be_none(self):
        # FIXME: is this always safe?
        return False

    def coerce_to_boolean(self, env):
        arg_type = self.arg.type
        if (arg_type == PyrexTypes.c_bint_type or
            (arg_type.is_pyobject and arg_type.name == 'bool')):
            return self.arg.coerce_to_temp(env)
        else:
            return CoerceToBooleanNode(self, env)

    def coerce_to_integer(self, env):
        # If not already some C integer type, coerce to longint.
        if self.arg.type.is_int:
            return self.arg
        else:
            return self.arg.coerce_to(PyrexTypes.c_long_type, env)

    def analyse_types(self, env):
        # The arg is always already analysed
        return self

    def generate_result_code(self, code):
        arg_type = self.arg.type
        if arg_type.is_memoryviewslice:
            funccall = arg_type.get_to_py_function(self.env, self.arg)
        else:
            func = arg_type.to_py_function
            if arg_type.is_string or arg_type.is_cpp_string:
                if self.type in (bytes_type, str_type, unicode_type):
                    func = func.replace("Object", self.type.name.title())
                elif self.type is bytearray_type:
                    func = func.replace("Object", "ByteArray")
            funccall = "%s(%s)" % (func, self.arg.result())

        code.putln('%s = %s; %s' % (
            self.result(),
            funccall,
            code.error_goto_if_null(self.result(), self.pos)))

        code.put_gotref(self.py_result())


class CoerceIntToBytesNode(CoerceToPyTypeNode):
    #  This node is used to convert a C int type to a Python bytes
    #  object.

    is_temp = 1

    def __init__(self, arg, env):
        arg = arg.coerce_to_simple(env)
        CoercionNode.__init__(self, arg)
        self.type = Builtin.bytes_type

    def generate_result_code(self, code):
        arg = self.arg
        arg_result = arg.result()
        if arg.type not in (PyrexTypes.c_char_type,
                            PyrexTypes.c_uchar_type,
                            PyrexTypes.c_schar_type):
            if arg.type.signed:
                code.putln("if ((%s < 0) || (%s > 255)) {" % (
                    arg_result, arg_result))
            else:
                code.putln("if (%s > 255) {" % arg_result)
            code.putln('PyErr_SetString(PyExc_OverflowError, '
                       '"value too large to pack into a byte"); %s' % (
                           code.error_goto(self.pos)))
            code.putln('}')
        temp = None
        if arg.type is not PyrexTypes.c_char_type:
            temp = code.funcstate.allocate_temp(PyrexTypes.c_char_type, manage_ref=False)
            code.putln("%s = (char)%s;" % (temp, arg_result))
            arg_result = temp
        code.putln('%s = PyBytes_FromStringAndSize(&%s, 1); %s' % (
            self.result(),
            arg_result,
            code.error_goto_if_null(self.result(), self.pos)))
        if temp is not None:
            code.funcstate.release_temp(temp)
        code.put_gotref(self.py_result())


class CoerceFromPyTypeNode(CoercionNode):
    #  This node is used to convert a Python object
    #  to a C data type.

    def __init__(self, result_type, arg, env):
        CoercionNode.__init__(self, arg)
        self.type = result_type
        self.is_temp = 1
        if not result_type.create_from_py_utility_code(env):
            error(arg.pos,
                  "Cannot convert Python object to '%s'" % result_type)
        if self.type.is_string or self.type.is_pyunicode_ptr:
            if self.arg.is_ephemeral():
                error(arg.pos,
                      "Obtaining '%s' from temporary Python value" % result_type)
            elif self.arg.is_name and self.arg.entry and self.arg.entry.is_pyglobal:
                warning(arg.pos,
                        "Obtaining '%s' from externally modifiable global Python value" % result_type,
                        level=1)

    def analyse_types(self, env):
        # The arg is always already analysed
        return self

    def generate_result_code(self, code):
        function = self.type.from_py_function
        operand = self.arg.py_result()
        rhs = "%s(%s)" % (function, operand)
        if self.type.is_enum:
            rhs = typecast(self.type, c_long_type, rhs)
        code.putln('%s = %s; %s' % (
            self.result(),
            rhs,
            code.error_goto_if(self.type.error_condition(self.result()), self.pos)))
        if self.type.is_pyobject:
            code.put_gotref(self.py_result())

    def nogil_check(self, env):
        error(self.pos, "Coercion from Python not allowed without the GIL")


class CoerceToBooleanNode(CoercionNode):
    #  This node is used when a result needs to be used
    #  in a boolean context.

    type = PyrexTypes.c_bint_type

    _special_builtins = {
        Builtin.list_type    : 'PyList_GET_SIZE',
        Builtin.tuple_type   : 'PyTuple_GET_SIZE',
        Builtin.bytes_type   : 'PyBytes_GET_SIZE',
        Builtin.unicode_type : 'PyUnicode_GET_SIZE',
        }

    def __init__(self, arg, env):
        CoercionNode.__init__(self, arg)
        if arg.type.is_pyobject:
            self.is_temp = 1

    def nogil_check(self, env):
        if self.arg.type.is_pyobject and self._special_builtins.get(self.arg.type) is None:
            self.gil_error()

    gil_message = "Truth-testing Python object"

    def check_const(self):
        if self.is_temp:
            self.not_const()
            return False
        return self.arg.check_const()

    def calculate_result_code(self):
        return "(%s != 0)" % self.arg.result()

    def generate_result_code(self, code):
        if not self.is_temp:
            return
        test_func = self._special_builtins.get(self.arg.type)
        if test_func is not None:
            code.putln("%s = (%s != Py_None) && (%s(%s) != 0);" % (
                       self.result(),
                       self.arg.py_result(),
                       test_func,
                       self.arg.py_result()))
        else:
            code.putln(
                "%s = __Pyx_PyObject_IsTrue(%s); %s" % (
                    self.result(),
                    self.arg.py_result(),
                    code.error_goto_if_neg(self.result(), self.pos)))

class CoerceToComplexNode(CoercionNode):

    def __init__(self, arg, dst_type, env):
        if arg.type.is_complex:
            arg = arg.coerce_to_simple(env)
        self.type = dst_type
        CoercionNode.__init__(self, arg)
        dst_type.create_declaration_utility_code(env)

    def calculate_result_code(self):
        if self.arg.type.is_complex:
            real_part = "__Pyx_CREAL(%s)" % self.arg.result()
            imag_part = "__Pyx_CIMAG(%s)" % self.arg.result()
        else:
            real_part = self.arg.result()
            imag_part = "0"
        return "%s(%s, %s)" % (
                self.type.from_parts,
                real_part,
                imag_part)

    def generate_result_code(self, code):
        pass

class CoerceToTempNode(CoercionNode):
    #  This node is used to force the result of another node
    #  to be stored in a temporary. It is only used if the
    #  argument node's result is not already in a temporary.

    def __init__(self, arg, env):
        CoercionNode.__init__(self, arg)
        self.type = self.arg.type.as_argument_type()
        self.constant_result = self.arg.constant_result
        self.is_temp = 1
        if self.type.is_pyobject:
            self.result_ctype = py_object_type

    gil_message = "Creating temporary Python reference"

    def analyse_types(self, env):
        # The arg is always already analysed
        return self

    def coerce_to_boolean(self, env):
        self.arg = self.arg.coerce_to_boolean(env)
        if self.arg.is_simple():
            return self.arg
        self.type = self.arg.type
        self.result_ctype = self.type
        return self

    def generate_result_code(self, code):
        #self.arg.generate_evaluation_code(code) # Already done
        # by generic generate_subexpr_evaluation_code!
        code.putln("%s = %s;" % (
            self.result(), self.arg.result_as(self.ctype())))
        if self.use_managed_ref:
            if self.type.is_pyobject:
                code.put_incref(self.result(), self.ctype())
            elif self.type.is_memoryviewslice:
                code.put_incref_memoryviewslice(self.result(),
                                                not self.in_nogil_context)

class ProxyNode(CoercionNode):
    """
    A node that should not be replaced by transforms or other means,
    and hence can be useful to wrap the argument to a clone node

    MyNode    -> ProxyNode -> ArgNode
    CloneNode -^
    """

    nogil_check = None

    def __init__(self, arg):
        super(ProxyNode, self).__init__(arg)
        self.constant_result = arg.constant_result
        self._proxy_type()

    def analyse_expressions(self, env):
        self.arg = self.arg.analyse_expressions(env)
        self._proxy_type()
        return self

    def _proxy_type(self):
        if hasattr(self.arg, 'type'):
            self.type = self.arg.type
            self.result_ctype = self.arg.result_ctype
        if hasattr(self.arg, 'entry'):
            self.entry = self.arg.entry

    def generate_result_code(self, code):
        self.arg.generate_result_code(code)

    def result(self):
        return self.arg.result()

    def is_simple(self):
        return self.arg.is_simple()

    def may_be_none(self):
        return self.arg.may_be_none()

    def generate_evaluation_code(self, code):
        self.arg.generate_evaluation_code(code)

    def generate_result_code(self, code):
        self.arg.generate_result_code(code)

    def generate_disposal_code(self, code):
        self.arg.generate_disposal_code(code)

    def free_temps(self, code):
        self.arg.free_temps(code)

class CloneNode(CoercionNode):
    #  This node is employed when the result of another node needs
    #  to be used multiple times. The argument node's result must
    #  be in a temporary. This node "borrows" the result from the
    #  argument node, and does not generate any evaluation or
    #  disposal code for it. The original owner of the argument
    #  node is responsible for doing those things.

    subexprs = [] # Arg is not considered a subexpr
    nogil_check = None

    def __init__(self, arg):
        CoercionNode.__init__(self, arg)
        self.constant_result = arg.constant_result
        if hasattr(arg, 'type'):
            self.type = arg.type
            self.result_ctype = arg.result_ctype
        if hasattr(arg, 'entry'):
            self.entry = arg.entry

    def result(self):
        return self.arg.result()

    def may_be_none(self):
        return self.arg.may_be_none()

    def type_dependencies(self, env):
        return self.arg.type_dependencies(env)

    def infer_type(self, env):
        return self.arg.infer_type(env)

    def analyse_types(self, env):
        self.type = self.arg.type
        self.result_ctype = self.arg.result_ctype
        self.is_temp = 1
        if hasattr(self.arg, 'entry'):
            self.entry = self.arg.entry
        return self

    def is_simple(self):
        return True # result is always in a temp (or a name)

    def generate_evaluation_code(self, code):
        pass

    def generate_result_code(self, code):
        pass

    def generate_disposal_code(self, code):
        pass

    def free_temps(self, code):
        pass


class CMethodSelfCloneNode(CloneNode):
    # Special CloneNode for the self argument of builtin C methods
    # that accepts subtypes of the builtin type.  This is safe only
    # for 'final' subtypes, as subtypes of the declared type may
    # override the C method.

    def coerce_to(self, dst_type, env):
        if dst_type.is_builtin_type and self.type.subtype_of(dst_type):
            return self
        return CloneNode.coerce_to(self, dst_type, env)


class ModuleRefNode(ExprNode):
    # Simple returns the module object

    type = py_object_type
    is_temp = False
    subexprs = []

    def analyse_types(self, env):
        return self

    def may_be_none(self):
        return False

    def calculate_result_code(self):
        return Naming.module_cname

    def generate_result_code(self, code):
        pass

class DocstringRefNode(ExprNode):
    # Extracts the docstring of the body element

    subexprs = ['body']
    type = py_object_type
    is_temp = True

    def __init__(self, pos, body):
        ExprNode.__init__(self, pos)
        assert body.type.is_pyobject
        self.body = body

    def analyse_types(self, env):
        return self

    def generate_result_code(self, code):
        code.putln('%s = __Pyx_GetAttr(%s, %s); %s' % (
            self.result(), self.body.result(),
            code.intern_identifier(StringEncoding.EncodedString("__doc__")),
            code.error_goto_if_null(self.result(), self.pos)))
        code.put_gotref(self.result())



#------------------------------------------------------------------------------------
#
#  Runtime support code
#
#------------------------------------------------------------------------------------

pyerr_occurred_withgil_utility_code= UtilityCode(
proto = """
static CYTHON_INLINE int __Pyx_ErrOccurredWithGIL(void); /* proto */
""",
impl = """
static CYTHON_INLINE int __Pyx_ErrOccurredWithGIL(void) {
  int err;
  #ifdef WITH_THREAD
  PyGILState_STATE _save = PyGILState_Ensure();
  #endif
  err = !!PyErr_Occurred();
  #ifdef WITH_THREAD
  PyGILState_Release(_save);
  #endif
  return err;
}
"""
)

#------------------------------------------------------------------------------------

raise_unbound_local_error_utility_code = UtilityCode(
proto = """
static CYTHON_INLINE void __Pyx_RaiseUnboundLocalError(const char *varname);
""",
impl = """
static CYTHON_INLINE void __Pyx_RaiseUnboundLocalError(const char *varname) {
    PyErr_Format(PyExc_UnboundLocalError, "local variable '%s' referenced before assignment", varname);
}
""")

raise_closure_name_error_utility_code = UtilityCode(
proto = """
static CYTHON_INLINE void __Pyx_RaiseClosureNameError(const char *varname);
""",
impl = """
static CYTHON_INLINE void __Pyx_RaiseClosureNameError(const char *varname) {
    PyErr_Format(PyExc_NameError, "free variable '%s' referenced before assignment in enclosing scope", varname);
}
""")

# Don't inline the function, it should really never be called in production
raise_unbound_memoryview_utility_code_nogil = UtilityCode(
proto = """
static void __Pyx_RaiseUnboundMemoryviewSliceNogil(const char *varname);
""",
impl = """
static void __Pyx_RaiseUnboundMemoryviewSliceNogil(const char *varname) {
    #ifdef WITH_THREAD
    PyGILState_STATE gilstate = PyGILState_Ensure();
    #endif
    __Pyx_RaiseUnboundLocalError(varname);
    #ifdef WITH_THREAD
    PyGILState_Release(gilstate);
    #endif
}
""",
requires = [raise_unbound_local_error_utility_code])

#------------------------------------------------------------------------------------

raise_too_many_values_to_unpack = UtilityCode.load_cached("RaiseTooManyValuesToUnpack", "ObjectHandling.c")
raise_need_more_values_to_unpack = UtilityCode.load_cached("RaiseNeedMoreValuesToUnpack", "ObjectHandling.c")
tuple_unpacking_error_code = UtilityCode.load_cached("UnpackTupleError", "ObjectHandling.c")

#------------------------------------------------------------------------------------

int_pow_utility_code = UtilityCode(
proto="""
static CYTHON_INLINE %(type)s %(func_name)s(%(type)s, %(type)s); /* proto */
""",
impl="""
static CYTHON_INLINE %(type)s %(func_name)s(%(type)s b, %(type)s e) {
    %(type)s t = b;
    switch (e) {
        case 3:
            t *= b;
        case 2:
            t *= b;
        case 1:
            return t;
        case 0:
            return 1;
    }
    #if %(signed)s
    if (unlikely(e<0)) return 0;
    #endif
    t = 1;
    while (likely(e)) {
        t *= (b * (e&1)) | ((~e)&1);    /* 1 or b */
        b *= b;
        e >>= 1;
    }
    return t;
}
""")

# ------------------------------ Division ------------------------------------

div_int_utility_code = UtilityCode(
proto="""
static CYTHON_INLINE %(type)s __Pyx_div_%(type_name)s(%(type)s, %(type)s); /* proto */
""",
impl="""
static CYTHON_INLINE %(type)s __Pyx_div_%(type_name)s(%(type)s a, %(type)s b) {
    %(type)s q = a / b;
    %(type)s r = a - q*b;
    q -= ((r != 0) & ((r ^ b) < 0));
    return q;
}
""")

mod_int_utility_code = UtilityCode(
proto="""
static CYTHON_INLINE %(type)s __Pyx_mod_%(type_name)s(%(type)s, %(type)s); /* proto */
""",
impl="""
static CYTHON_INLINE %(type)s __Pyx_mod_%(type_name)s(%(type)s a, %(type)s b) {
    %(type)s r = a %% b;
    r += ((r != 0) & ((r ^ b) < 0)) * b;
    return r;
}
""")

mod_float_utility_code = UtilityCode(
proto="""
static CYTHON_INLINE %(type)s __Pyx_mod_%(type_name)s(%(type)s, %(type)s); /* proto */
""",
impl="""
static CYTHON_INLINE %(type)s __Pyx_mod_%(type_name)s(%(type)s a, %(type)s b) {
    %(type)s r = fmod%(math_h_modifier)s(a, b);
    r += ((r != 0) & ((r < 0) ^ (b < 0))) * b;
    return r;
}
""")

cdivision_warning_utility_code = UtilityCode(
proto="""
static int __Pyx_cdivision_warning(const char *, int); /* proto */
""",
impl="""
static int __Pyx_cdivision_warning(const char *filename, int lineno) {
#if CYTHON_COMPILING_IN_PYPY
    filename++; // avoid compiler warnings
    lineno++;
    return PyErr_Warn(PyExc_RuntimeWarning,
                     "division with oppositely signed operands, C and Python semantics differ");
#else
    return PyErr_WarnExplicit(PyExc_RuntimeWarning,
                              "division with oppositely signed operands, C and Python semantics differ",
                              filename,
                              lineno,
                              __Pyx_MODULE_NAME,
                              NULL);
#endif
}
""")

# from intobject.c
division_overflow_test_code = UtilityCode(
proto="""
#define UNARY_NEG_WOULD_OVERFLOW(x)    \
        (((x) < 0) & ((unsigned long)(x) == 0-(unsigned long)(x)))
""")
