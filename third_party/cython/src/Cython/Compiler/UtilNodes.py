#
# Nodes used as utilities and support for transforms etc.
# These often make up sets including both Nodes and ExprNodes
# so it is convenient to have them in a seperate module.
#

import Nodes
import ExprNodes
from Nodes import Node
from ExprNodes import AtomicExprNode
from PyrexTypes import c_ptr_type

class TempHandle(object):
    # THIS IS DEPRECATED, USE LetRefNode instead
    temp = None
    needs_xdecref = False
    def __init__(self, type, needs_cleanup=None):
        self.type = type
        if needs_cleanup is None:
            self.needs_cleanup = type.is_pyobject
        else:
            self.needs_cleanup = needs_cleanup

    def ref(self, pos):
        return TempRefNode(pos, handle=self, type=self.type)

    def cleanup_ref(self, pos):
        return CleanupTempRefNode(pos, handle=self, type=self.type)

class TempRefNode(AtomicExprNode):
    # THIS IS DEPRECATED, USE LetRefNode instead
    # handle   TempHandle

    def analyse_types(self, env):
        assert self.type == self.handle.type
        return self

    def analyse_target_types(self, env):
        assert self.type == self.handle.type
        return self

    def analyse_target_declaration(self, env):
        pass

    def calculate_result_code(self):
        result = self.handle.temp
        if result is None: result = "<error>" # might be called and overwritten
        return result

    def generate_result_code(self, code):
        pass

    def generate_assignment_code(self, rhs, code):
        if self.type.is_pyobject:
            rhs.make_owned_reference(code)
            # TODO: analyse control flow to see if this is necessary
            code.put_xdecref(self.result(), self.ctype())
        code.putln('%s = %s;' % (self.result(), rhs.result_as(self.ctype())))
        rhs.generate_post_assignment_code(code)
        rhs.free_temps(code)

class CleanupTempRefNode(TempRefNode):
    # THIS IS DEPRECATED, USE LetRefNode instead
    # handle   TempHandle

    def generate_assignment_code(self, rhs, code):
        pass

    def generate_execution_code(self, code):
        if self.type.is_pyobject:
            code.put_decref_clear(self.result(), self.type)
            self.handle.needs_cleanup = False

class TempsBlockNode(Node):
    # THIS IS DEPRECATED, USE LetNode instead

    """
    Creates a block which allocates temporary variables.
    This is used by transforms to output constructs that need
    to make use of a temporary variable. Simply pass the types
    of the needed temporaries to the constructor.

    The variables can be referred to using a TempRefNode
    (which can be constructed by calling get_ref_node).
    """

    # temps   [TempHandle]
    # body    StatNode

    child_attrs = ["body"]

    def generate_execution_code(self, code):
        for handle in self.temps:
            handle.temp = code.funcstate.allocate_temp(
                handle.type, manage_ref=handle.needs_cleanup)
        self.body.generate_execution_code(code)
        for handle in self.temps:
            if handle.needs_cleanup:
                if handle.needs_xdecref:
                    code.put_xdecref_clear(handle.temp, handle.type)
                else:
                    code.put_decref_clear(handle.temp, handle.type)
            code.funcstate.release_temp(handle.temp)

    def analyse_declarations(self, env):
        self.body.analyse_declarations(env)

    def analyse_expressions(self, env):
        self.body = self.body.analyse_expressions(env)
        return self

    def generate_function_definitions(self, env, code):
        self.body.generate_function_definitions(env, code)

    def annotate(self, code):
        self.body.annotate(code)


class ResultRefNode(AtomicExprNode):
    # A reference to the result of an expression.  The result_code
    # must be set externally (usually a temp name).

    subexprs = []
    lhs_of_first_assignment = False

    def __init__(self, expression=None, pos=None, type=None, may_hold_none=True, is_temp=False):
        self.expression = expression
        self.pos = None
        self.may_hold_none = may_hold_none
        if expression is not None:
            self.pos = expression.pos
            if hasattr(expression, "type"):
                self.type = expression.type
        if pos is not None:
            self.pos = pos
        if type is not None:
            self.type = type
        if is_temp:
            self.is_temp = True
        assert self.pos is not None

    def clone_node(self):
        # nothing to do here
        return self

    def type_dependencies(self, env):
        if self.expression:
            return self.expression.type_dependencies(env)
        else:
            return ()

    def analyse_types(self, env):
        if self.expression is not None:
            self.type = self.expression.type
        return self

    def infer_type(self, env):
        if self.type is not None:
            return self.type
        if self.expression is not None:
            if self.expression.type is not None:
                return self.expression.type
            return self.expression.infer_type(env)
        assert False, "cannot infer type of ResultRefNode"

    def may_be_none(self):
        if not self.type.is_pyobject:
            return False
        return self.may_hold_none

    def _DISABLED_may_be_none(self):
        # not sure if this is safe - the expression may not be the
        # only value that gets assigned
        if self.expression is not None:
            return self.expression.may_be_none()
        if self.type is not None:
            return self.type.is_pyobject
        return True # play safe

    def is_simple(self):
        return True

    def result(self):
        try:
            return self.result_code
        except AttributeError:
            if self.expression is not None:
                self.result_code = self.expression.result()
        return self.result_code

    def generate_evaluation_code(self, code):
        pass

    def generate_result_code(self, code):
        pass

    def generate_disposal_code(self, code):
        pass

    def generate_assignment_code(self, rhs, code):
        if self.type.is_pyobject:
            rhs.make_owned_reference(code)
            if not self.lhs_of_first_assignment:
                code.put_decref(self.result(), self.ctype())
        code.putln('%s = %s;' % (self.result(), rhs.result_as(self.ctype())))
        rhs.generate_post_assignment_code(code)
        rhs.free_temps(code)

    def allocate_temps(self, env):
        pass

    def release_temp(self, env):
        pass

    def free_temps(self, code):
        pass


class LetNodeMixin:
    def set_temp_expr(self, lazy_temp):
        self.lazy_temp = lazy_temp
        self.temp_expression = lazy_temp.expression

    def setup_temp_expr(self, code):
        self.temp_expression.generate_evaluation_code(code)
        self.temp_type = self.temp_expression.type
        if self.temp_type.is_array:
            self.temp_type = c_ptr_type(self.temp_type.base_type)
        self._result_in_temp = self.temp_expression.result_in_temp()
        if self._result_in_temp:
            self.temp = self.temp_expression.result()
        else:
            self.temp_expression.make_owned_reference(code)
            self.temp = code.funcstate.allocate_temp(
                self.temp_type, manage_ref=True)
            code.putln("%s = %s;" % (self.temp, self.temp_expression.result()))
            self.temp_expression.generate_disposal_code(code)
            self.temp_expression.free_temps(code)
        self.lazy_temp.result_code = self.temp

    def teardown_temp_expr(self, code):
        if self._result_in_temp:
            self.temp_expression.generate_disposal_code(code)
            self.temp_expression.free_temps(code)
        else:
            if self.temp_type.is_pyobject:
                code.put_decref_clear(self.temp, self.temp_type)
            code.funcstate.release_temp(self.temp)

class EvalWithTempExprNode(ExprNodes.ExprNode, LetNodeMixin):
    # A wrapper around a subexpression that moves an expression into a
    # temp variable and provides it to the subexpression.

    subexprs = ['temp_expression', 'subexpression']

    def __init__(self, lazy_temp, subexpression):
        self.set_temp_expr(lazy_temp)
        self.pos = subexpression.pos
        self.subexpression = subexpression
        # if called after type analysis, we already know the type here
        self.type = self.subexpression.type

    def infer_type(self, env):
        return self.subexpression.infer_type(env)

    def result(self):
        return self.subexpression.result()

    def analyse_types(self, env):
        self.temp_expression = self.temp_expression.analyse_types(env)
        self.subexpression = self.subexpression.analyse_types(env)
        self.type = self.subexpression.type
        return self

    def free_subexpr_temps(self, code):
        self.subexpression.free_temps(code)

    def generate_subexpr_disposal_code(self, code):
        self.subexpression.generate_disposal_code(code)

    def generate_evaluation_code(self, code):
        self.setup_temp_expr(code)
        self.subexpression.generate_evaluation_code(code)
        self.teardown_temp_expr(code)

LetRefNode = ResultRefNode

class LetNode(Nodes.StatNode, LetNodeMixin):
    # Implements a local temporary variable scope. Imagine this
    # syntax being present:
    # let temp = VALUE:
    #     BLOCK (can modify temp)
    #     if temp is an object, decref
    #
    # Usually used after analysis phase, but forwards analysis methods
    # to its children

    child_attrs = ['temp_expression', 'body']

    def __init__(self, lazy_temp, body):
        self.set_temp_expr(lazy_temp)
        self.pos = body.pos
        self.body = body

    def analyse_declarations(self, env):
        self.temp_expression.analyse_declarations(env)
        self.body.analyse_declarations(env)

    def analyse_expressions(self, env):
        self.temp_expression = self.temp_expression.analyse_expressions(env)
        self.body = self.body.analyse_expressions(env)
        return self

    def generate_execution_code(self, code):
        self.setup_temp_expr(code)
        self.body.generate_execution_code(code)
        self.teardown_temp_expr(code)

    def generate_function_definitions(self, env, code):
        self.temp_expression.generate_function_definitions(env, code)
        self.body.generate_function_definitions(env, code)


class TempResultFromStatNode(ExprNodes.ExprNode):
    # An ExprNode wrapper around a StatNode that executes the StatNode
    # body.  Requires a ResultRefNode that it sets up to refer to its
    # own temp result.  The StatNode must assign a value to the result
    # node, which then becomes the result of this node.

    subexprs = []
    child_attrs = ['body']

    def __init__(self, result_ref, body):
        self.result_ref = result_ref
        self.pos = body.pos
        self.body = body
        self.type = result_ref.type
        self.is_temp = 1

    def analyse_declarations(self, env):
        self.body.analyse_declarations(env)

    def analyse_types(self, env):
        self.body = self.body.analyse_expressions(env)
        return self

    def generate_result_code(self, code):
        self.result_ref.result_code = self.result()
        self.body.generate_execution_code(code)
