from Cython.Compiler import TypeSlots
from Cython.Compiler.ExprNodes import not_a_constant
import cython
cython.declare(UtilityCode=object, EncodedString=object, BytesLiteral=object,
               Nodes=object, ExprNodes=object, PyrexTypes=object, Builtin=object,
               UtilNodes=object, Naming=object)

import Nodes
import ExprNodes
import PyrexTypes
import Visitor
import Builtin
import UtilNodes
import Options
import Naming

from Code import UtilityCode
from StringEncoding import EncodedString, BytesLiteral
from Errors import error
from ParseTreeTransforms import SkipDeclarations

import copy
import codecs

try:
    from __builtin__ import reduce
except ImportError:
    from functools import reduce

try:
    from __builtin__ import basestring
except ImportError:
    basestring = str # Python 3

def load_c_utility(name):
    return UtilityCode.load_cached(name, "Optimize.c")

def unwrap_coerced_node(node, coercion_nodes=(ExprNodes.CoerceToPyTypeNode, ExprNodes.CoerceFromPyTypeNode)):
    if isinstance(node, coercion_nodes):
        return node.arg
    return node

def unwrap_node(node):
    while isinstance(node, UtilNodes.ResultRefNode):
        node = node.expression
    return node

def is_common_value(a, b):
    a = unwrap_node(a)
    b = unwrap_node(b)
    if isinstance(a, ExprNodes.NameNode) and isinstance(b, ExprNodes.NameNode):
        return a.name == b.name
    if isinstance(a, ExprNodes.AttributeNode) and isinstance(b, ExprNodes.AttributeNode):
        return not a.is_py_attr and is_common_value(a.obj, b.obj) and a.attribute == b.attribute
    return False

def filter_none_node(node):
    if node is not None and node.constant_result is None:
        return None
    return node

class IterationTransform(Visitor.EnvTransform):
    """Transform some common for-in loop patterns into efficient C loops:

    - for-in-dict loop becomes a while loop calling PyDict_Next()
    - for-in-enumerate is replaced by an external counter variable
    - for-in-range loop becomes a plain C for loop
    """
    def visit_PrimaryCmpNode(self, node):
        if node.is_ptr_contains():

            # for t in operand2:
            #     if operand1 == t:
            #         res = True
            #         break
            # else:
            #     res = False

            pos = node.pos
            result_ref = UtilNodes.ResultRefNode(node)
            if isinstance(node.operand2, ExprNodes.IndexNode):
                base_type = node.operand2.base.type.base_type
            else:
                base_type = node.operand2.type.base_type
            target_handle = UtilNodes.TempHandle(base_type)
            target = target_handle.ref(pos)
            cmp_node = ExprNodes.PrimaryCmpNode(
                pos, operator=u'==', operand1=node.operand1, operand2=target)
            if_body = Nodes.StatListNode(
                pos,
                stats = [Nodes.SingleAssignmentNode(pos, lhs=result_ref, rhs=ExprNodes.BoolNode(pos, value=1)),
                         Nodes.BreakStatNode(pos)])
            if_node = Nodes.IfStatNode(
                pos,
                if_clauses=[Nodes.IfClauseNode(pos, condition=cmp_node, body=if_body)],
                else_clause=None)
            for_loop = UtilNodes.TempsBlockNode(
                pos,
                temps = [target_handle],
                body = Nodes.ForInStatNode(
                    pos,
                    target=target,
                    iterator=ExprNodes.IteratorNode(node.operand2.pos, sequence=node.operand2),
                    body=if_node,
                    else_clause=Nodes.SingleAssignmentNode(pos, lhs=result_ref, rhs=ExprNodes.BoolNode(pos, value=0))))
            for_loop = for_loop.analyse_expressions(self.current_env())
            for_loop = self.visit(for_loop)
            new_node = UtilNodes.TempResultFromStatNode(result_ref, for_loop)

            if node.operator == 'not_in':
                new_node = ExprNodes.NotNode(pos, operand=new_node)
            return new_node

        else:
            self.visitchildren(node)
            return node

    def visit_ForInStatNode(self, node):
        self.visitchildren(node)
        return self._optimise_for_loop(node, node.iterator.sequence)

    def _optimise_for_loop(self, node, iterator, reversed=False):
        if iterator.type is Builtin.dict_type:
            # like iterating over dict.keys()
            if reversed:
                # CPython raises an error here: not a sequence
                return node
            return self._transform_dict_iteration(
                node, dict_obj=iterator, method=None, keys=True, values=False)

        # C array (slice) iteration?
        if iterator.type.is_ptr or iterator.type.is_array:
            return self._transform_carray_iteration(node, iterator, reversed=reversed)
        if iterator.type is Builtin.bytes_type:
            return self._transform_bytes_iteration(node, iterator, reversed=reversed)
        if iterator.type is Builtin.unicode_type:
            return self._transform_unicode_iteration(node, iterator, reversed=reversed)

        # the rest is based on function calls
        if not isinstance(iterator, ExprNodes.SimpleCallNode):
            return node

        if iterator.args is None:
            arg_count = iterator.arg_tuple and len(iterator.arg_tuple.args) or 0
        else:
            arg_count = len(iterator.args)
            if arg_count and iterator.self is not None:
                arg_count -= 1

        function = iterator.function
        # dict iteration?
        if function.is_attribute and not reversed and not arg_count:
            base_obj = iterator.self or function.obj
            method = function.attribute
            # in Py3, items() is equivalent to Py2's iteritems()
            is_safe_iter = self.global_scope().context.language_level >= 3

            if not is_safe_iter and method in ('keys', 'values', 'items'):
                # try to reduce this to the corresponding .iter*() methods
                if isinstance(base_obj, ExprNodes.SimpleCallNode):
                    inner_function = base_obj.function
                    if (inner_function.is_name and inner_function.name == 'dict'
                            and inner_function.entry
                            and inner_function.entry.is_builtin):
                        # e.g. dict(something).items() => safe to use .iter*()
                        is_safe_iter = True

            keys = values = False
            if method == 'iterkeys' or (is_safe_iter and method == 'keys'):
                keys = True
            elif method == 'itervalues' or (is_safe_iter and method == 'values'):
                values = True
            elif method == 'iteritems' or (is_safe_iter and method == 'items'):
                keys = values = True

            if keys or values:
                return self._transform_dict_iteration(
                    node, base_obj, method, keys, values)

        # enumerate/reversed ?
        if iterator.self is None and function.is_name and \
               function.entry and function.entry.is_builtin:
            if function.name == 'enumerate':
                if reversed:
                    # CPython raises an error here: not a sequence
                    return node
                return self._transform_enumerate_iteration(node, iterator)
            elif function.name == 'reversed':
                if reversed:
                    # CPython raises an error here: not a sequence
                    return node
                return self._transform_reversed_iteration(node, iterator)

        # range() iteration?
        if Options.convert_range and node.target.type.is_int:
            if iterator.self is None and function.is_name and \
                   function.entry and function.entry.is_builtin and \
                   function.name in ('range', 'xrange'):
                return self._transform_range_iteration(node, iterator, reversed=reversed)

        return node

    def _transform_reversed_iteration(self, node, reversed_function):
        args = reversed_function.arg_tuple.args
        if len(args) == 0:
            error(reversed_function.pos,
                  "reversed() requires an iterable argument")
            return node
        elif len(args) > 1:
            error(reversed_function.pos,
                  "reversed() takes exactly 1 argument")
            return node
        arg = args[0]

        # reversed(list/tuple) ?
        if arg.type in (Builtin.tuple_type, Builtin.list_type):
            node.iterator.sequence = arg.as_none_safe_node("'NoneType' object is not iterable")
            node.iterator.reversed = True
            return node

        return self._optimise_for_loop(node, arg, reversed=True)

    PyBytes_AS_STRING_func_type = PyrexTypes.CFuncType(
        PyrexTypes.c_char_ptr_type, [
            PyrexTypes.CFuncTypeArg("s", Builtin.bytes_type, None)
            ])

    PyBytes_GET_SIZE_func_type = PyrexTypes.CFuncType(
        PyrexTypes.c_py_ssize_t_type, [
            PyrexTypes.CFuncTypeArg("s", Builtin.bytes_type, None)
            ])

    def _transform_bytes_iteration(self, node, slice_node, reversed=False):
        target_type = node.target.type
        if not target_type.is_int and target_type is not Builtin.bytes_type:
            # bytes iteration returns bytes objects in Py2, but
            # integers in Py3
            return node

        unpack_temp_node = UtilNodes.LetRefNode(
            slice_node.as_none_safe_node("'NoneType' is not iterable"))

        slice_base_node = ExprNodes.PythonCapiCallNode(
            slice_node.pos, "PyBytes_AS_STRING",
            self.PyBytes_AS_STRING_func_type,
            args = [unpack_temp_node],
            is_temp = 0,
            )
        len_node = ExprNodes.PythonCapiCallNode(
            slice_node.pos, "PyBytes_GET_SIZE",
            self.PyBytes_GET_SIZE_func_type,
            args = [unpack_temp_node],
            is_temp = 0,
            )

        return UtilNodes.LetNode(
            unpack_temp_node,
            self._transform_carray_iteration(
                node,
                ExprNodes.SliceIndexNode(
                    slice_node.pos,
                    base = slice_base_node,
                    start = None,
                    step = None,
                    stop = len_node,
                    type = slice_base_node.type,
                    is_temp = 1,
                    ),
                reversed = reversed))

    PyUnicode_READ_func_type = PyrexTypes.CFuncType(
        PyrexTypes.c_py_ucs4_type, [
            PyrexTypes.CFuncTypeArg("kind", PyrexTypes.c_int_type, None),
            PyrexTypes.CFuncTypeArg("data", PyrexTypes.c_void_ptr_type, None),
            PyrexTypes.CFuncTypeArg("index", PyrexTypes.c_py_ssize_t_type, None)
        ])

    init_unicode_iteration_func_type = PyrexTypes.CFuncType(
        PyrexTypes.c_int_type, [
            PyrexTypes.CFuncTypeArg("s", PyrexTypes.py_object_type, None),
            PyrexTypes.CFuncTypeArg("length", PyrexTypes.c_py_ssize_t_ptr_type, None),
            PyrexTypes.CFuncTypeArg("data", PyrexTypes.c_void_ptr_ptr_type, None),
            PyrexTypes.CFuncTypeArg("kind", PyrexTypes.c_int_ptr_type, None)
        ],
        exception_value = '-1')

    def _transform_unicode_iteration(self, node, slice_node, reversed=False):
        if slice_node.is_literal:
            # try to reduce to byte iteration for plain Latin-1 strings
            try:
                bytes_value = BytesLiteral(slice_node.value.encode('latin1'))
            except UnicodeEncodeError:
                pass
            else:
                bytes_slice = ExprNodes.SliceIndexNode(
                    slice_node.pos,
                    base=ExprNodes.BytesNode(
                        slice_node.pos, value=bytes_value,
                        constant_result=bytes_value,
                        type=PyrexTypes.c_char_ptr_type).coerce_to(
                            PyrexTypes.c_uchar_ptr_type, self.current_env()),
                    start=None,
                    stop=ExprNodes.IntNode(
                        slice_node.pos, value=str(len(bytes_value)),
                        constant_result=len(bytes_value),
                        type=PyrexTypes.c_py_ssize_t_type),
                    type=Builtin.unicode_type,  # hint for Python conversion
                )
                return self._transform_carray_iteration(node, bytes_slice, reversed)

        unpack_temp_node = UtilNodes.LetRefNode(
            slice_node.as_none_safe_node("'NoneType' is not iterable"))

        start_node = ExprNodes.IntNode(
            node.pos, value='0', constant_result=0, type=PyrexTypes.c_py_ssize_t_type)
        length_temp = UtilNodes.TempHandle(PyrexTypes.c_py_ssize_t_type)
        end_node = length_temp.ref(node.pos)
        if reversed:
            relation1, relation2 = '>', '>='
            start_node, end_node = end_node, start_node
        else:
            relation1, relation2 = '<=', '<'

        kind_temp = UtilNodes.TempHandle(PyrexTypes.c_int_type)
        data_temp = UtilNodes.TempHandle(PyrexTypes.c_void_ptr_type)
        counter_temp = UtilNodes.TempHandle(PyrexTypes.c_py_ssize_t_type)

        target_value = ExprNodes.PythonCapiCallNode(
            slice_node.pos, "__Pyx_PyUnicode_READ",
            self.PyUnicode_READ_func_type,
            args = [kind_temp.ref(slice_node.pos),
                    data_temp.ref(slice_node.pos),
                    counter_temp.ref(node.target.pos)],
            is_temp = False,
            )
        if target_value.type != node.target.type:
            target_value = target_value.coerce_to(node.target.type,
                                                  self.current_env())
        target_assign = Nodes.SingleAssignmentNode(
            pos = node.target.pos,
            lhs = node.target,
            rhs = target_value)
        body = Nodes.StatListNode(
            node.pos,
            stats = [target_assign, node.body])

        loop_node = Nodes.ForFromStatNode(
            node.pos,
            bound1=start_node, relation1=relation1,
            target=counter_temp.ref(node.target.pos),
            relation2=relation2, bound2=end_node,
            step=None, body=body,
            else_clause=node.else_clause,
            from_range=True)

        setup_node = Nodes.ExprStatNode(
            node.pos,
            expr = ExprNodes.PythonCapiCallNode(
                slice_node.pos, "__Pyx_init_unicode_iteration",
                self.init_unicode_iteration_func_type,
                args = [unpack_temp_node,
                        ExprNodes.AmpersandNode(slice_node.pos, operand=length_temp.ref(slice_node.pos),
                                                type=PyrexTypes.c_py_ssize_t_ptr_type),
                        ExprNodes.AmpersandNode(slice_node.pos, operand=data_temp.ref(slice_node.pos),
                                                type=PyrexTypes.c_void_ptr_ptr_type),
                        ExprNodes.AmpersandNode(slice_node.pos, operand=kind_temp.ref(slice_node.pos),
                                                type=PyrexTypes.c_int_ptr_type),
                        ],
                is_temp = True,
                result_is_used = False,
                utility_code=UtilityCode.load_cached("unicode_iter", "Optimize.c"),
                ))
        return UtilNodes.LetNode(
            unpack_temp_node,
            UtilNodes.TempsBlockNode(
                node.pos, temps=[counter_temp, length_temp, data_temp, kind_temp],
                body=Nodes.StatListNode(node.pos, stats=[setup_node, loop_node])))

    def _transform_carray_iteration(self, node, slice_node, reversed=False):
        neg_step = False
        if isinstance(slice_node, ExprNodes.SliceIndexNode):
            slice_base = slice_node.base
            start = filter_none_node(slice_node.start)
            stop = filter_none_node(slice_node.stop)
            step = None
            if not stop:
                if not slice_base.type.is_pyobject:
                    error(slice_node.pos, "C array iteration requires known end index")
                return node

        elif isinstance(slice_node, ExprNodes.IndexNode):
            assert isinstance(slice_node.index, ExprNodes.SliceNode)
            slice_base = slice_node.base
            index = slice_node.index
            start = filter_none_node(index.start)
            stop = filter_none_node(index.stop)
            step = filter_none_node(index.step)
            if step:
                if not isinstance(step.constant_result, (int,long)) \
                       or step.constant_result == 0 \
                       or step.constant_result > 0 and not stop \
                       or step.constant_result < 0 and not start:
                    if not slice_base.type.is_pyobject:
                        error(step.pos, "C array iteration requires known step size and end index")
                    return node
                else:
                    # step sign is handled internally by ForFromStatNode
                    step_value = step.constant_result
                    if reversed:
                        step_value = -step_value
                    neg_step = step_value < 0
                    step = ExprNodes.IntNode(step.pos, type=PyrexTypes.c_py_ssize_t_type,
                                             value=str(abs(step_value)),
                                             constant_result=abs(step_value))

        elif slice_node.type.is_array:
            if slice_node.type.size is None:
                error(slice_node.pos, "C array iteration requires known end index")
                return node
            slice_base = slice_node
            start = None
            stop = ExprNodes.IntNode(
                slice_node.pos, value=str(slice_node.type.size),
                type=PyrexTypes.c_py_ssize_t_type, constant_result=slice_node.type.size)
            step = None

        else:
            if not slice_node.type.is_pyobject:
                error(slice_node.pos, "C array iteration requires known end index")
            return node

        if start:
            start = start.coerce_to(PyrexTypes.c_py_ssize_t_type, self.current_env())
        if stop:
            stop = stop.coerce_to(PyrexTypes.c_py_ssize_t_type, self.current_env())
        if stop is None:
            if neg_step:
                stop = ExprNodes.IntNode(
                    slice_node.pos, value='-1', type=PyrexTypes.c_py_ssize_t_type, constant_result=-1)
            else:
                error(slice_node.pos, "C array iteration requires known step size and end index")
                return node

        if reversed:
            if not start:
                start = ExprNodes.IntNode(slice_node.pos, value="0",  constant_result=0,
                                          type=PyrexTypes.c_py_ssize_t_type)
            # if step was provided, it was already negated above
            start, stop = stop, start

        ptr_type = slice_base.type
        if ptr_type.is_array:
            ptr_type = ptr_type.element_ptr_type()
        carray_ptr = slice_base.coerce_to_simple(self.current_env())

        if start and start.constant_result != 0:
            start_ptr_node = ExprNodes.AddNode(
                start.pos,
                operand1=carray_ptr,
                operator='+',
                operand2=start,
                type=ptr_type)
        else:
            start_ptr_node = carray_ptr

        if stop and stop.constant_result != 0:
            stop_ptr_node = ExprNodes.AddNode(
                stop.pos,
                operand1=ExprNodes.CloneNode(carray_ptr),
                operator='+',
                operand2=stop,
                type=ptr_type
                ).coerce_to_simple(self.current_env())
        else:
            stop_ptr_node = ExprNodes.CloneNode(carray_ptr)

        counter = UtilNodes.TempHandle(ptr_type)
        counter_temp = counter.ref(node.target.pos)

        if slice_base.type.is_string and node.target.type.is_pyobject:
            # special case: char* -> bytes/unicode
            if slice_node.type is Builtin.unicode_type:
                target_value = ExprNodes.CastNode(
                    ExprNodes.DereferenceNode(
                        node.target.pos, operand=counter_temp,
                        type=ptr_type.base_type),
                    PyrexTypes.c_py_ucs4_type).coerce_to(
                        node.target.type, self.current_env())
            else:
                # char* -> bytes coercion requires slicing, not indexing
                target_value = ExprNodes.SliceIndexNode(
                    node.target.pos,
                    start=ExprNodes.IntNode(node.target.pos, value='0',
                                            constant_result=0,
                                            type=PyrexTypes.c_int_type),
                    stop=ExprNodes.IntNode(node.target.pos, value='1',
                                           constant_result=1,
                                           type=PyrexTypes.c_int_type),
                    base=counter_temp,
                    type=Builtin.bytes_type,
                    is_temp=1)
        elif node.target.type.is_ptr and not node.target.type.assignable_from(ptr_type.base_type):
            # Allow iteration with pointer target to avoid copy.
            target_value = counter_temp
        else:
            # TODO: can this safely be replaced with DereferenceNode() as above?
            target_value = ExprNodes.IndexNode(
                node.target.pos,
                index=ExprNodes.IntNode(node.target.pos, value='0',
                                        constant_result=0,
                                        type=PyrexTypes.c_int_type),
                base=counter_temp,
                is_buffer_access=False,
                type=ptr_type.base_type)

        if target_value.type != node.target.type:
            target_value = target_value.coerce_to(node.target.type,
                                                  self.current_env())

        target_assign = Nodes.SingleAssignmentNode(
            pos = node.target.pos,
            lhs = node.target,
            rhs = target_value)

        body = Nodes.StatListNode(
            node.pos,
            stats = [target_assign, node.body])

        relation1, relation2 = self._find_for_from_node_relations(neg_step, reversed)

        for_node = Nodes.ForFromStatNode(
            node.pos,
            bound1=start_ptr_node, relation1=relation1,
            target=counter_temp,
            relation2=relation2, bound2=stop_ptr_node,
            step=step, body=body,
            else_clause=node.else_clause,
            from_range=True)

        return UtilNodes.TempsBlockNode(
            node.pos, temps=[counter],
            body=for_node)

    def _transform_enumerate_iteration(self, node, enumerate_function):
        args = enumerate_function.arg_tuple.args
        if len(args) == 0:
            error(enumerate_function.pos,
                  "enumerate() requires an iterable argument")
            return node
        elif len(args) > 2:
            error(enumerate_function.pos,
                  "enumerate() takes at most 2 arguments")
            return node

        if not node.target.is_sequence_constructor:
            # leave this untouched for now
            return node
        targets = node.target.args
        if len(targets) != 2:
            # leave this untouched for now
            return node

        enumerate_target, iterable_target = targets
        counter_type = enumerate_target.type

        if not counter_type.is_pyobject and not counter_type.is_int:
            # nothing we can do here, I guess
            return node

        if len(args) == 2:
            start = unwrap_coerced_node(args[1]).coerce_to(counter_type, self.current_env())
        else:
            start = ExprNodes.IntNode(enumerate_function.pos,
                                      value='0',
                                      type=counter_type,
                                      constant_result=0)
        temp = UtilNodes.LetRefNode(start)

        inc_expression = ExprNodes.AddNode(
            enumerate_function.pos,
            operand1 = temp,
            operand2 = ExprNodes.IntNode(node.pos, value='1',
                                         type=counter_type,
                                         constant_result=1),
            operator = '+',
            type = counter_type,
            #inplace = True,   # not worth using in-place operation for Py ints
            is_temp = counter_type.is_pyobject
            )

        loop_body = [
            Nodes.SingleAssignmentNode(
                pos = enumerate_target.pos,
                lhs = enumerate_target,
                rhs = temp),
            Nodes.SingleAssignmentNode(
                pos = enumerate_target.pos,
                lhs = temp,
                rhs = inc_expression)
            ]

        if isinstance(node.body, Nodes.StatListNode):
            node.body.stats = loop_body + node.body.stats
        else:
            loop_body.append(node.body)
            node.body = Nodes.StatListNode(
                node.body.pos,
                stats = loop_body)

        node.target = iterable_target
        node.item = node.item.coerce_to(iterable_target.type, self.current_env())
        node.iterator.sequence = args[0]

        # recurse into loop to check for further optimisations
        return UtilNodes.LetNode(temp, self._optimise_for_loop(node, node.iterator.sequence))

    def _find_for_from_node_relations(self, neg_step_value, reversed):
        if reversed:
            if neg_step_value:
                return '<', '<='
            else:
                return '>', '>='
        else:
            if neg_step_value:
                return '>=', '>'
            else:
                return '<=', '<'

    def _transform_range_iteration(self, node, range_function, reversed=False):
        args = range_function.arg_tuple.args
        if len(args) < 3:
            step_pos = range_function.pos
            step_value = 1
            step = ExprNodes.IntNode(step_pos, value='1',
                                     constant_result=1)
        else:
            step = args[2]
            step_pos = step.pos
            if not isinstance(step.constant_result, (int, long)):
                # cannot determine step direction
                return node
            step_value = step.constant_result
            if step_value == 0:
                # will lead to an error elsewhere
                return node
            if reversed and step_value not in (1, -1):
                # FIXME: currently broken - requires calculation of the correct bounds
                return node
            if not isinstance(step, ExprNodes.IntNode):
                step = ExprNodes.IntNode(step_pos, value=str(step_value),
                                         constant_result=step_value)

        if len(args) == 1:
            bound1 = ExprNodes.IntNode(range_function.pos, value='0',
                                       constant_result=0)
            bound2 = args[0].coerce_to_integer(self.current_env())
        else:
            bound1 = args[0].coerce_to_integer(self.current_env())
            bound2 = args[1].coerce_to_integer(self.current_env())

        relation1, relation2 = self._find_for_from_node_relations(step_value < 0, reversed)

        if reversed:
            bound1, bound2 = bound2, bound1
            if step_value < 0:
                step_value = -step_value
        else:
            if step_value < 0:
                step_value = -step_value

        step.value = str(step_value)
        step.constant_result = step_value
        step = step.coerce_to_integer(self.current_env())

        if not bound2.is_literal:
            # stop bound must be immutable => keep it in a temp var
            bound2_is_temp = True
            bound2 = UtilNodes.LetRefNode(bound2)
        else:
            bound2_is_temp = False

        for_node = Nodes.ForFromStatNode(
            node.pos,
            target=node.target,
            bound1=bound1, relation1=relation1,
            relation2=relation2, bound2=bound2,
            step=step, body=node.body,
            else_clause=node.else_clause,
            from_range=True)

        if bound2_is_temp:
            for_node = UtilNodes.LetNode(bound2, for_node)

        return for_node

    def _transform_dict_iteration(self, node, dict_obj, method, keys, values):
        temps = []
        temp = UtilNodes.TempHandle(PyrexTypes.py_object_type)
        temps.append(temp)
        dict_temp = temp.ref(dict_obj.pos)
        temp = UtilNodes.TempHandle(PyrexTypes.c_py_ssize_t_type)
        temps.append(temp)
        pos_temp = temp.ref(node.pos)

        key_target = value_target = tuple_target = None
        if keys and values:
            if node.target.is_sequence_constructor:
                if len(node.target.args) == 2:
                    key_target, value_target = node.target.args
                else:
                    # unusual case that may or may not lead to an error
                    return node
            else:
                tuple_target = node.target
        elif keys:
            key_target = node.target
        else:
            value_target = node.target

        if isinstance(node.body, Nodes.StatListNode):
            body = node.body
        else:
            body = Nodes.StatListNode(pos = node.body.pos,
                                      stats = [node.body])

        # keep original length to guard against dict modification
        dict_len_temp = UtilNodes.TempHandle(PyrexTypes.c_py_ssize_t_type)
        temps.append(dict_len_temp)
        dict_len_temp_addr = ExprNodes.AmpersandNode(
            node.pos, operand=dict_len_temp.ref(dict_obj.pos),
            type=PyrexTypes.c_ptr_type(dict_len_temp.type))
        temp = UtilNodes.TempHandle(PyrexTypes.c_int_type)
        temps.append(temp)
        is_dict_temp = temp.ref(node.pos)
        is_dict_temp_addr = ExprNodes.AmpersandNode(
            node.pos, operand=is_dict_temp,
            type=PyrexTypes.c_ptr_type(temp.type))

        iter_next_node = Nodes.DictIterationNextNode(
            dict_temp, dict_len_temp.ref(dict_obj.pos), pos_temp,
            key_target, value_target, tuple_target,
            is_dict_temp)
        iter_next_node = iter_next_node.analyse_expressions(self.current_env())
        body.stats[0:0] = [iter_next_node]

        if method:
            method_node = ExprNodes.StringNode(
                dict_obj.pos, is_identifier=True, value=method)
            dict_obj = dict_obj.as_none_safe_node(
                "'NoneType' object has no attribute '%s'",
                error = "PyExc_AttributeError",
                format_args = [method])
        else:
            method_node = ExprNodes.NullNode(dict_obj.pos)
            dict_obj = dict_obj.as_none_safe_node("'NoneType' object is not iterable")

        def flag_node(value):
            value = value and 1 or 0
            return ExprNodes.IntNode(node.pos, value=str(value), constant_result=value)

        result_code = [
            Nodes.SingleAssignmentNode(
                node.pos,
                lhs = pos_temp,
                rhs = ExprNodes.IntNode(node.pos, value='0',
                                        constant_result=0)),
            Nodes.SingleAssignmentNode(
                dict_obj.pos,
                lhs = dict_temp,
                rhs = ExprNodes.PythonCapiCallNode(
                    dict_obj.pos,
                    "__Pyx_dict_iterator",
                    self.PyDict_Iterator_func_type,
                    utility_code = UtilityCode.load_cached("dict_iter", "Optimize.c"),
                    args = [dict_obj, flag_node(dict_obj.type is Builtin.dict_type),
                            method_node, dict_len_temp_addr, is_dict_temp_addr,
                            ],
                    is_temp=True,
                )),
            Nodes.WhileStatNode(
                node.pos,
                condition = None,
                body = body,
                else_clause = node.else_clause
                )
            ]

        return UtilNodes.TempsBlockNode(
            node.pos, temps=temps,
            body=Nodes.StatListNode(
                node.pos,
                stats = result_code
                ))

    PyDict_Iterator_func_type = PyrexTypes.CFuncType(
        PyrexTypes.py_object_type, [
            PyrexTypes.CFuncTypeArg("dict",  PyrexTypes.py_object_type, None),
            PyrexTypes.CFuncTypeArg("is_dict",  PyrexTypes.c_int_type, None),
            PyrexTypes.CFuncTypeArg("method_name",  PyrexTypes.py_object_type, None),
            PyrexTypes.CFuncTypeArg("p_orig_length",  PyrexTypes.c_py_ssize_t_ptr_type, None),
            PyrexTypes.CFuncTypeArg("p_is_dict",  PyrexTypes.c_int_ptr_type, None),
            ])


class SwitchTransform(Visitor.VisitorTransform):
    """
    This transformation tries to turn long if statements into C switch statements.
    The requirement is that every clause be an (or of) var == value, where the var
    is common among all clauses and both var and value are ints.
    """
    NO_MATCH = (None, None, None)

    def extract_conditions(self, cond, allow_not_in):
        while True:
            if isinstance(cond, (ExprNodes.CoerceToTempNode,
                                 ExprNodes.CoerceToBooleanNode)):
                cond = cond.arg
            elif isinstance(cond, UtilNodes.EvalWithTempExprNode):
                # this is what we get from the FlattenInListTransform
                cond = cond.subexpression
            elif isinstance(cond, ExprNodes.TypecastNode):
                cond = cond.operand
            else:
                break

        if isinstance(cond, ExprNodes.PrimaryCmpNode):
            if cond.cascade is not None:
                return self.NO_MATCH
            elif cond.is_c_string_contains() and \
                   isinstance(cond.operand2, (ExprNodes.UnicodeNode, ExprNodes.BytesNode)):
                not_in = cond.operator == 'not_in'
                if not_in and not allow_not_in:
                    return self.NO_MATCH
                if isinstance(cond.operand2, ExprNodes.UnicodeNode) and \
                       cond.operand2.contains_surrogates():
                    # dealing with surrogates leads to different
                    # behaviour on wide and narrow Unicode
                    # platforms => refuse to optimise this case
                    return self.NO_MATCH
                return not_in, cond.operand1, self.extract_in_string_conditions(cond.operand2)
            elif not cond.is_python_comparison():
                if cond.operator == '==':
                    not_in = False
                elif allow_not_in and cond.operator == '!=':
                    not_in = True
                else:
                    return self.NO_MATCH
                # this looks somewhat silly, but it does the right
                # checks for NameNode and AttributeNode
                if is_common_value(cond.operand1, cond.operand1):
                    if cond.operand2.is_literal:
                        return not_in, cond.operand1, [cond.operand2]
                    elif getattr(cond.operand2, 'entry', None) \
                             and cond.operand2.entry.is_const:
                        return not_in, cond.operand1, [cond.operand2]
                if is_common_value(cond.operand2, cond.operand2):
                    if cond.operand1.is_literal:
                        return not_in, cond.operand2, [cond.operand1]
                    elif getattr(cond.operand1, 'entry', None) \
                             and cond.operand1.entry.is_const:
                        return not_in, cond.operand2, [cond.operand1]
        elif isinstance(cond, ExprNodes.BoolBinopNode):
            if cond.operator == 'or' or (allow_not_in and cond.operator == 'and'):
                allow_not_in = (cond.operator == 'and')
                not_in_1, t1, c1 = self.extract_conditions(cond.operand1, allow_not_in)
                not_in_2, t2, c2 = self.extract_conditions(cond.operand2, allow_not_in)
                if t1 is not None and not_in_1 == not_in_2 and is_common_value(t1, t2):
                    if (not not_in_1) or allow_not_in:
                        return not_in_1, t1, c1+c2
        return self.NO_MATCH

    def extract_in_string_conditions(self, string_literal):
        if isinstance(string_literal, ExprNodes.UnicodeNode):
            charvals = list(map(ord, set(string_literal.value)))
            charvals.sort()
            return [ ExprNodes.IntNode(string_literal.pos, value=str(charval),
                                       constant_result=charval)
                     for charval in charvals ]
        else:
            # this is a bit tricky as Py3's bytes type returns
            # integers on iteration, whereas Py2 returns 1-char byte
            # strings
            characters = string_literal.value
            characters = list(set([ characters[i:i+1] for i in range(len(characters)) ]))
            characters.sort()
            return [ ExprNodes.CharNode(string_literal.pos, value=charval,
                                        constant_result=charval)
                     for charval in characters ]

    def extract_common_conditions(self, common_var, condition, allow_not_in):
        not_in, var, conditions = self.extract_conditions(condition, allow_not_in)
        if var is None:
            return self.NO_MATCH
        elif common_var is not None and not is_common_value(var, common_var):
            return self.NO_MATCH
        elif not (var.type.is_int or var.type.is_enum) or sum([not (cond.type.is_int or cond.type.is_enum) for cond in conditions]):
            return self.NO_MATCH
        return not_in, var, conditions

    def has_duplicate_values(self, condition_values):
        # duplicated values don't work in a switch statement
        seen = set()
        for value in condition_values:
            if value.has_constant_result():
                if value.constant_result in seen:
                    return True
                seen.add(value.constant_result)
            else:
                # this isn't completely safe as we don't know the
                # final C value, but this is about the best we can do
                try:
                    if value.entry.cname in seen:
                        return True
                except AttributeError:
                    return True  # play safe
                seen.add(value.entry.cname)
        return False

    def visit_IfStatNode(self, node):
        common_var = None
        cases = []
        for if_clause in node.if_clauses:
            _, common_var, conditions = self.extract_common_conditions(
                common_var, if_clause.condition, False)
            if common_var is None:
                self.visitchildren(node)
                return node
            cases.append(Nodes.SwitchCaseNode(pos = if_clause.pos,
                                              conditions = conditions,
                                              body = if_clause.body))

        condition_values = [
            cond for case in cases for cond in case.conditions]
        if len(condition_values) < 2:
            self.visitchildren(node)
            return node
        if self.has_duplicate_values(condition_values):
            self.visitchildren(node)
            return node

        common_var = unwrap_node(common_var)
        switch_node = Nodes.SwitchStatNode(pos = node.pos,
                                           test = common_var,
                                           cases = cases,
                                           else_clause = node.else_clause)
        return switch_node

    def visit_CondExprNode(self, node):
        not_in, common_var, conditions = self.extract_common_conditions(
            None, node.test, True)
        if common_var is None \
               or len(conditions) < 2 \
               or self.has_duplicate_values(conditions):
            self.visitchildren(node)
            return node
        return self.build_simple_switch_statement(
            node, common_var, conditions, not_in,
            node.true_val, node.false_val)

    def visit_BoolBinopNode(self, node):
        not_in, common_var, conditions = self.extract_common_conditions(
            None, node, True)
        if common_var is None \
               or len(conditions) < 2 \
               or self.has_duplicate_values(conditions):
            self.visitchildren(node)
            return node

        return self.build_simple_switch_statement(
            node, common_var, conditions, not_in,
            ExprNodes.BoolNode(node.pos, value=True, constant_result=True),
            ExprNodes.BoolNode(node.pos, value=False, constant_result=False))

    def visit_PrimaryCmpNode(self, node):
        not_in, common_var, conditions = self.extract_common_conditions(
            None, node, True)
        if common_var is None \
               or len(conditions) < 2 \
               or self.has_duplicate_values(conditions):
            self.visitchildren(node)
            return node

        return self.build_simple_switch_statement(
            node, common_var, conditions, not_in,
            ExprNodes.BoolNode(node.pos, value=True, constant_result=True),
            ExprNodes.BoolNode(node.pos, value=False, constant_result=False))

    def build_simple_switch_statement(self, node, common_var, conditions,
                                      not_in, true_val, false_val):
        result_ref = UtilNodes.ResultRefNode(node)
        true_body = Nodes.SingleAssignmentNode(
            node.pos,
            lhs = result_ref,
            rhs = true_val,
            first = True)
        false_body = Nodes.SingleAssignmentNode(
            node.pos,
            lhs = result_ref,
            rhs = false_val,
            first = True)

        if not_in:
            true_body, false_body = false_body, true_body

        cases = [Nodes.SwitchCaseNode(pos = node.pos,
                                      conditions = conditions,
                                      body = true_body)]

        common_var = unwrap_node(common_var)
        switch_node = Nodes.SwitchStatNode(pos = node.pos,
                                           test = common_var,
                                           cases = cases,
                                           else_clause = false_body)
        replacement = UtilNodes.TempResultFromStatNode(result_ref, switch_node)
        return replacement

    def visit_EvalWithTempExprNode(self, node):
        # drop unused expression temp from FlattenInListTransform
        orig_expr = node.subexpression
        temp_ref = node.lazy_temp
        self.visitchildren(node)
        if node.subexpression is not orig_expr:
            # node was restructured => check if temp is still used
            if not Visitor.tree_contains(node.subexpression, temp_ref):
                return node.subexpression
        return node

    visit_Node = Visitor.VisitorTransform.recurse_to_children


class FlattenInListTransform(Visitor.VisitorTransform, SkipDeclarations):
    """
    This transformation flattens "x in [val1, ..., valn]" into a sequential list
    of comparisons.
    """

    def visit_PrimaryCmpNode(self, node):
        self.visitchildren(node)
        if node.cascade is not None:
            return node
        elif node.operator == 'in':
            conjunction = 'or'
            eq_or_neq = '=='
        elif node.operator == 'not_in':
            conjunction = 'and'
            eq_or_neq = '!='
        else:
            return node

        if not isinstance(node.operand2, (ExprNodes.TupleNode,
                                          ExprNodes.ListNode,
                                          ExprNodes.SetNode)):
            return node

        args = node.operand2.args
        if len(args) == 0:
            # note: lhs may have side effects
            return node

        lhs = UtilNodes.ResultRefNode(node.operand1)

        conds = []
        temps = []
        for arg in args:
            try:
                # Trial optimisation to avoid redundant temp
                # assignments.  However, since is_simple() is meant to
                # be called after type analysis, we ignore any errors
                # and just play safe in that case.
                is_simple_arg = arg.is_simple()
            except Exception:
                is_simple_arg = False
            if not is_simple_arg:
                # must evaluate all non-simple RHS before doing the comparisons
                arg = UtilNodes.LetRefNode(arg)
                temps.append(arg)
            cond = ExprNodes.PrimaryCmpNode(
                                pos = node.pos,
                                operand1 = lhs,
                                operator = eq_or_neq,
                                operand2 = arg,
                                cascade = None)
            conds.append(ExprNodes.TypecastNode(
                                pos = node.pos,
                                operand = cond,
                                type = PyrexTypes.c_bint_type))
        def concat(left, right):
            return ExprNodes.BoolBinopNode(
                                pos = node.pos,
                                operator = conjunction,
                                operand1 = left,
                                operand2 = right)

        condition = reduce(concat, conds)
        new_node = UtilNodes.EvalWithTempExprNode(lhs, condition)
        for temp in temps[::-1]:
            new_node = UtilNodes.EvalWithTempExprNode(temp, new_node)
        return new_node

    visit_Node = Visitor.VisitorTransform.recurse_to_children


class DropRefcountingTransform(Visitor.VisitorTransform):
    """Drop ref-counting in safe places.
    """
    visit_Node = Visitor.VisitorTransform.recurse_to_children

    def visit_ParallelAssignmentNode(self, node):
        """
        Parallel swap assignments like 'a,b = b,a' are safe.
        """
        left_names, right_names = [], []
        left_indices, right_indices = [], []
        temps = []

        for stat in node.stats:
            if isinstance(stat, Nodes.SingleAssignmentNode):
                if not self._extract_operand(stat.lhs, left_names,
                                             left_indices, temps):
                    return node
                if not self._extract_operand(stat.rhs, right_names,
                                             right_indices, temps):
                    return node
            elif isinstance(stat, Nodes.CascadedAssignmentNode):
                # FIXME
                return node
            else:
                return node

        if left_names or right_names:
            # lhs/rhs names must be a non-redundant permutation
            lnames = [ path for path, n in left_names ]
            rnames = [ path for path, n in right_names ]
            if set(lnames) != set(rnames):
                return node
            if len(set(lnames)) != len(right_names):
                return node

        if left_indices or right_indices:
            # base name and index of index nodes must be a
            # non-redundant permutation
            lindices = []
            for lhs_node in left_indices:
                index_id = self._extract_index_id(lhs_node)
                if not index_id:
                    return node
                lindices.append(index_id)
            rindices = []
            for rhs_node in right_indices:
                index_id = self._extract_index_id(rhs_node)
                if not index_id:
                    return node
                rindices.append(index_id)

            if set(lindices) != set(rindices):
                return node
            if len(set(lindices)) != len(right_indices):
                return node

            # really supporting IndexNode requires support in
            # __Pyx_GetItemInt(), so let's stop short for now
            return node

        temp_args = [t.arg for t in temps]
        for temp in temps:
            temp.use_managed_ref = False

        for _, name_node in left_names + right_names:
            if name_node not in temp_args:
                name_node.use_managed_ref = False

        for index_node in left_indices + right_indices:
            index_node.use_managed_ref = False

        return node

    def _extract_operand(self, node, names, indices, temps):
        node = unwrap_node(node)
        if not node.type.is_pyobject:
            return False
        if isinstance(node, ExprNodes.CoerceToTempNode):
            temps.append(node)
            node = node.arg
        name_path = []
        obj_node = node
        while isinstance(obj_node, ExprNodes.AttributeNode):
            if obj_node.is_py_attr:
                return False
            name_path.append(obj_node.member)
            obj_node = obj_node.obj
        if isinstance(obj_node, ExprNodes.NameNode):
            name_path.append(obj_node.name)
            names.append( ('.'.join(name_path[::-1]), node) )
        elif isinstance(node, ExprNodes.IndexNode):
            if node.base.type != Builtin.list_type:
                return False
            if not node.index.type.is_int:
                return False
            if not isinstance(node.base, ExprNodes.NameNode):
                return False
            indices.append(node)
        else:
            return False
        return True

    def _extract_index_id(self, index_node):
        base = index_node.base
        index = index_node.index
        if isinstance(index, ExprNodes.NameNode):
            index_val = index.name
        elif isinstance(index, ExprNodes.ConstNode):
            # FIXME:
            return None
        else:
            return None
        return (base.name, index_val)


class EarlyReplaceBuiltinCalls(Visitor.EnvTransform):
    """Optimize some common calls to builtin types *before* the type
    analysis phase and *after* the declarations analysis phase.

    This transform cannot make use of any argument types, but it can
    restructure the tree in a way that the type analysis phase can
    respond to.

    Introducing C function calls here may not be a good idea.  Move
    them to the OptimizeBuiltinCalls transform instead, which runs
    after type analysis.
    """
    # only intercept on call nodes
    visit_Node = Visitor.VisitorTransform.recurse_to_children

    def visit_SimpleCallNode(self, node):
        self.visitchildren(node)
        function = node.function
        if not self._function_is_builtin_name(function):
            return node
        return self._dispatch_to_handler(node, function, node.args)

    def visit_GeneralCallNode(self, node):
        self.visitchildren(node)
        function = node.function
        if not self._function_is_builtin_name(function):
            return node
        arg_tuple = node.positional_args
        if not isinstance(arg_tuple, ExprNodes.TupleNode):
            return node
        args = arg_tuple.args
        return self._dispatch_to_handler(
            node, function, args, node.keyword_args)

    def _function_is_builtin_name(self, function):
        if not function.is_name:
            return False
        env = self.current_env()
        entry = env.lookup(function.name)
        if entry is not env.builtin_scope().lookup_here(function.name):
            return False
        # if entry is None, it's at least an undeclared name, so likely builtin
        return True

    def _dispatch_to_handler(self, node, function, args, kwargs=None):
        if kwargs is None:
            handler_name = '_handle_simple_function_%s' % function.name
        else:
            handler_name = '_handle_general_function_%s' % function.name
        handle_call = getattr(self, handler_name, None)
        if handle_call is not None:
            if kwargs is None:
                return handle_call(node, args)
            else:
                return handle_call(node, args, kwargs)
        return node

    def _inject_capi_function(self, node, cname, func_type, utility_code=None):
        node.function = ExprNodes.PythonCapiFunctionNode(
            node.function.pos, node.function.name, cname, func_type,
            utility_code = utility_code)

    def _error_wrong_arg_count(self, function_name, node, args, expected=None):
        if not expected: # None or 0
            arg_str = ''
        elif isinstance(expected, basestring) or expected > 1:
            arg_str = '...'
        elif expected == 1:
            arg_str = 'x'
        else:
            arg_str = ''
        if expected is not None:
            expected_str = 'expected %s, ' % expected
        else:
            expected_str = ''
        error(node.pos, "%s(%s) called with wrong number of args, %sfound %d" % (
            function_name, arg_str, expected_str, len(args)))

    # specific handlers for simple call nodes

    def _handle_simple_function_float(self, node, pos_args):
        if not pos_args:
            return ExprNodes.FloatNode(node.pos, value='0.0')
        if len(pos_args) > 1:
            self._error_wrong_arg_count('float', node, pos_args, 1)
        arg_type = getattr(pos_args[0], 'type', None)
        if arg_type in (PyrexTypes.c_double_type, Builtin.float_type):
            return pos_args[0]
        return node

    class YieldNodeCollector(Visitor.TreeVisitor):
        def __init__(self):
            Visitor.TreeVisitor.__init__(self)
            self.yield_stat_nodes = {}
            self.yield_nodes = []

        visit_Node = Visitor.TreeVisitor.visitchildren
        # XXX: disable inlining while it's not back supported
        def __visit_YieldExprNode(self, node):
            self.yield_nodes.append(node)
            self.visitchildren(node)

        def __visit_ExprStatNode(self, node):
            self.visitchildren(node)
            if node.expr in self.yield_nodes:
                self.yield_stat_nodes[node.expr] = node

        def __visit_GeneratorExpressionNode(self, node):
            # enable when we support generic generator expressions
            #
            # everything below this node is out of scope
            pass

    def _find_single_yield_expression(self, node):
        collector = self.YieldNodeCollector()
        collector.visitchildren(node)
        if len(collector.yield_nodes) != 1:
            return None, None
        yield_node = collector.yield_nodes[0]
        try:
            return (yield_node.arg, collector.yield_stat_nodes[yield_node])
        except KeyError:
            return None, None

    def _handle_simple_function_all(self, node, pos_args):
        """Transform

        _result = all(x for L in LL for x in L)

        into

        for L in LL:
            for x in L:
                if not x:
                    _result = False
                    break
            else:
                continue
            break
        else:
            _result = True
        """
        return self._transform_any_all(node, pos_args, False)

    def _handle_simple_function_any(self, node, pos_args):
        """Transform

        _result = any(x for L in LL for x in L)

        into

        for L in LL:
            for x in L:
                if x:
                    _result = True
                    break
            else:
                continue
            break
        else:
            _result = False
        """
        return self._transform_any_all(node, pos_args, True)

    def _transform_any_all(self, node, pos_args, is_any):
        if len(pos_args) != 1:
            return node
        if not isinstance(pos_args[0], ExprNodes.GeneratorExpressionNode):
            return node
        gen_expr_node = pos_args[0]
        loop_node = gen_expr_node.loop
        yield_expression, yield_stat_node = self._find_single_yield_expression(loop_node)
        if yield_expression is None:
            return node

        if is_any:
            condition = yield_expression
        else:
            condition = ExprNodes.NotNode(yield_expression.pos, operand = yield_expression)

        result_ref = UtilNodes.ResultRefNode(pos=node.pos, type=PyrexTypes.c_bint_type)
        test_node = Nodes.IfStatNode(
            yield_expression.pos,
            else_clause = None,
            if_clauses = [ Nodes.IfClauseNode(
                yield_expression.pos,
                condition = condition,
                body = Nodes.StatListNode(
                    node.pos,
                    stats = [
                        Nodes.SingleAssignmentNode(
                            node.pos,
                            lhs = result_ref,
                            rhs = ExprNodes.BoolNode(yield_expression.pos, value = is_any,
                                                     constant_result = is_any)),
                        Nodes.BreakStatNode(node.pos)
                        ])) ]
            )
        loop = loop_node
        while isinstance(loop.body, Nodes.LoopNode):
            next_loop = loop.body
            loop.body = Nodes.StatListNode(loop.body.pos, stats = [
                loop.body,
                Nodes.BreakStatNode(yield_expression.pos)
                ])
            next_loop.else_clause = Nodes.ContinueStatNode(yield_expression.pos)
            loop = next_loop
        loop_node.else_clause = Nodes.SingleAssignmentNode(
            node.pos,
            lhs = result_ref,
            rhs = ExprNodes.BoolNode(yield_expression.pos, value = not is_any,
                                     constant_result = not is_any))

        Visitor.recursively_replace_node(loop_node, yield_stat_node, test_node)

        return ExprNodes.InlinedGeneratorExpressionNode(
            gen_expr_node.pos, loop = loop_node, result_node = result_ref,
            expr_scope = gen_expr_node.expr_scope, orig_func = is_any and 'any' or 'all')

    def _handle_simple_function_sorted(self, node, pos_args):
        """Transform sorted(genexpr) and sorted([listcomp]) into
        [listcomp].sort().  CPython just reads the iterable into a
        list and calls .sort() on it.  Expanding the iterable in a
        listcomp is still faster and the result can be sorted in
        place.
        """
        if len(pos_args) != 1:
            return node
        if isinstance(pos_args[0], ExprNodes.ComprehensionNode) \
               and pos_args[0].type is Builtin.list_type:
            listcomp_node = pos_args[0]
            loop_node = listcomp_node.loop
        elif isinstance(pos_args[0], ExprNodes.GeneratorExpressionNode):
            gen_expr_node = pos_args[0]
            loop_node = gen_expr_node.loop
            yield_expression, yield_stat_node = self._find_single_yield_expression(loop_node)
            if yield_expression is None:
                return node

            append_node = ExprNodes.ComprehensionAppendNode(
                yield_expression.pos, expr = yield_expression)

            Visitor.recursively_replace_node(loop_node, yield_stat_node, append_node)

            listcomp_node = ExprNodes.ComprehensionNode(
                gen_expr_node.pos, loop = loop_node,
                append = append_node, type = Builtin.list_type,
                expr_scope = gen_expr_node.expr_scope,
                has_local_scope = True)
            append_node.target = listcomp_node
        else:
            return node

        result_node = UtilNodes.ResultRefNode(
            pos = loop_node.pos, type = Builtin.list_type, may_hold_none=False)
        listcomp_assign_node = Nodes.SingleAssignmentNode(
            node.pos, lhs = result_node, rhs = listcomp_node, first = True)

        sort_method = ExprNodes.AttributeNode(
            node.pos, obj = result_node, attribute = EncodedString('sort'),
            # entry ? type ?
            needs_none_check = False)
        sort_node = Nodes.ExprStatNode(
            node.pos, expr = ExprNodes.SimpleCallNode(
                node.pos, function = sort_method, args = []))

        sort_node.analyse_declarations(self.current_env())

        return UtilNodes.TempResultFromStatNode(
            result_node,
            Nodes.StatListNode(node.pos, stats = [ listcomp_assign_node, sort_node ]))

    def _handle_simple_function_sum(self, node, pos_args):
        """Transform sum(genexpr) into an equivalent inlined aggregation loop.
        """
        if len(pos_args) not in (1,2):
            return node
        if not isinstance(pos_args[0], (ExprNodes.GeneratorExpressionNode,
                                        ExprNodes.ComprehensionNode)):
            return node
        gen_expr_node = pos_args[0]
        loop_node = gen_expr_node.loop

        if isinstance(gen_expr_node, ExprNodes.GeneratorExpressionNode):
            yield_expression, yield_stat_node = self._find_single_yield_expression(loop_node)
            if yield_expression is None:
                return node
        else: # ComprehensionNode
            yield_stat_node = gen_expr_node.append
            yield_expression = yield_stat_node.expr
            try:
                if not yield_expression.is_literal or not yield_expression.type.is_int:
                    return node
            except AttributeError:
                return node # in case we don't have a type yet
            # special case: old Py2 backwards compatible "sum([int_const for ...])"
            # can safely be unpacked into a genexpr

        if len(pos_args) == 1:
            start = ExprNodes.IntNode(node.pos, value='0', constant_result=0)
        else:
            start = pos_args[1]

        result_ref = UtilNodes.ResultRefNode(pos=node.pos, type=PyrexTypes.py_object_type)
        add_node = Nodes.SingleAssignmentNode(
            yield_expression.pos,
            lhs = result_ref,
            rhs = ExprNodes.binop_node(node.pos, '+', result_ref, yield_expression)
            )

        Visitor.recursively_replace_node(loop_node, yield_stat_node, add_node)

        exec_code = Nodes.StatListNode(
            node.pos,
            stats = [
                Nodes.SingleAssignmentNode(
                    start.pos,
                    lhs = UtilNodes.ResultRefNode(pos=node.pos, expression=result_ref),
                    rhs = start,
                    first = True),
                loop_node
                ])

        return ExprNodes.InlinedGeneratorExpressionNode(
            gen_expr_node.pos, loop = exec_code, result_node = result_ref,
            expr_scope = gen_expr_node.expr_scope, orig_func = 'sum',
            has_local_scope = gen_expr_node.has_local_scope)

    def _handle_simple_function_min(self, node, pos_args):
        return self._optimise_min_max(node, pos_args, '<')

    def _handle_simple_function_max(self, node, pos_args):
        return self._optimise_min_max(node, pos_args, '>')

    def _optimise_min_max(self, node, args, operator):
        """Replace min(a,b,...) and max(a,b,...) by explicit comparison code.
        """
        if len(args) <= 1:
            if len(args) == 1 and args[0].is_sequence_constructor:
                args = args[0].args
            else:
                # leave this to Python
                return node

        cascaded_nodes = list(map(UtilNodes.ResultRefNode, args[1:]))

        last_result = args[0]
        for arg_node in cascaded_nodes:
            result_ref = UtilNodes.ResultRefNode(last_result)
            last_result = ExprNodes.CondExprNode(
                arg_node.pos,
                true_val = arg_node,
                false_val = result_ref,
                test = ExprNodes.PrimaryCmpNode(
                    arg_node.pos,
                    operand1 = arg_node,
                    operator = operator,
                    operand2 = result_ref,
                    )
                )
            last_result = UtilNodes.EvalWithTempExprNode(result_ref, last_result)

        for ref_node in cascaded_nodes[::-1]:
            last_result = UtilNodes.EvalWithTempExprNode(ref_node, last_result)

        return last_result

    def _DISABLED_handle_simple_function_tuple(self, node, pos_args):
        if not pos_args:
            return ExprNodes.TupleNode(node.pos, args=[], constant_result=())
        # This is a bit special - for iterables (including genexps),
        # Python actually overallocates and resizes a newly created
        # tuple incrementally while reading items, which we can't
        # easily do without explicit node support. Instead, we read
        # the items into a list and then copy them into a tuple of the
        # final size.  This takes up to twice as much memory, but will
        # have to do until we have real support for genexps.
        result = self._transform_list_set_genexpr(node, pos_args, Builtin.list_type)
        if result is not node:
            return ExprNodes.AsTupleNode(node.pos, arg=result)
        return node

    def _handle_simple_function_frozenset(self, node, pos_args):
        """Replace frozenset([...]) by frozenset((...)) as tuples are more efficient.
        """
        if len(pos_args) != 1:
            return node
        if pos_args[0].is_sequence_constructor and not pos_args[0].args:
            del pos_args[0]
        elif isinstance(pos_args[0], ExprNodes.ListNode):
            pos_args[0] = pos_args[0].as_tuple()
        return node

    def _handle_simple_function_list(self, node, pos_args):
        if not pos_args:
            return ExprNodes.ListNode(node.pos, args=[], constant_result=[])
        return self._transform_list_set_genexpr(node, pos_args, Builtin.list_type)

    def _handle_simple_function_set(self, node, pos_args):
        if not pos_args:
            return ExprNodes.SetNode(node.pos, args=[], constant_result=set())
        return self._transform_list_set_genexpr(node, pos_args, Builtin.set_type)

    def _transform_list_set_genexpr(self, node, pos_args, target_type):
        """Replace set(genexpr) and list(genexpr) by a literal comprehension.
        """
        if len(pos_args) > 1:
            return node
        if not isinstance(pos_args[0], ExprNodes.GeneratorExpressionNode):
            return node
        gen_expr_node = pos_args[0]
        loop_node = gen_expr_node.loop

        yield_expression, yield_stat_node = self._find_single_yield_expression(loop_node)
        if yield_expression is None:
            return node

        append_node = ExprNodes.ComprehensionAppendNode(
            yield_expression.pos,
            expr = yield_expression)

        Visitor.recursively_replace_node(loop_node, yield_stat_node, append_node)

        comp = ExprNodes.ComprehensionNode(
            node.pos,
            has_local_scope = True,
            expr_scope = gen_expr_node.expr_scope,
            loop = loop_node,
            append = append_node,
            type = target_type)
        append_node.target = comp
        return comp

    def _handle_simple_function_dict(self, node, pos_args):
        """Replace dict( (a,b) for ... ) by a literal { a:b for ... }.
        """
        if len(pos_args) == 0:
            return ExprNodes.DictNode(node.pos, key_value_pairs=[], constant_result={})
        if len(pos_args) > 1:
            return node
        if not isinstance(pos_args[0], ExprNodes.GeneratorExpressionNode):
            return node
        gen_expr_node = pos_args[0]
        loop_node = gen_expr_node.loop

        yield_expression, yield_stat_node = self._find_single_yield_expression(loop_node)
        if yield_expression is None:
            return node

        if not isinstance(yield_expression, ExprNodes.TupleNode):
            return node
        if len(yield_expression.args) != 2:
            return node

        append_node = ExprNodes.DictComprehensionAppendNode(
            yield_expression.pos,
            key_expr = yield_expression.args[0],
            value_expr = yield_expression.args[1])

        Visitor.recursively_replace_node(loop_node, yield_stat_node, append_node)

        dictcomp = ExprNodes.ComprehensionNode(
            node.pos,
            has_local_scope = True,
            expr_scope = gen_expr_node.expr_scope,
            loop = loop_node,
            append = append_node,
            type = Builtin.dict_type)
        append_node.target = dictcomp
        return dictcomp

    # specific handlers for general call nodes

    def _handle_general_function_dict(self, node, pos_args, kwargs):
        """Replace dict(a=b,c=d,...) by the underlying keyword dict
        construction which is done anyway.
        """
        if len(pos_args) > 0:
            return node
        if not isinstance(kwargs, ExprNodes.DictNode):
            return node
        return kwargs


class InlineDefNodeCalls(Visitor.NodeRefCleanupMixin, Visitor.EnvTransform):
    visit_Node = Visitor.VisitorTransform.recurse_to_children

    def get_constant_value_node(self, name_node):
        if name_node.cf_state is None:
            return None
        if name_node.cf_state.cf_is_null:
            return None
        entry = self.current_env().lookup(name_node.name)
        if not entry or (not entry.cf_assignments
                         or len(entry.cf_assignments) != 1):
            # not just a single assignment in all closures
            return None
        return entry.cf_assignments[0].rhs

    def visit_SimpleCallNode(self, node):
        self.visitchildren(node)
        if not self.current_directives.get('optimize.inline_defnode_calls'):
            return node
        function_name = node.function
        if not function_name.is_name:
            return node
        function = self.get_constant_value_node(function_name)
        if not isinstance(function, ExprNodes.PyCFunctionNode):
            return node
        inlined = ExprNodes.InlinedDefNodeCallNode(
            node.pos, function_name=function_name,
            function=function, args=node.args)
        if inlined.can_be_inlined():
            return self.replace(node, inlined)
        return node


class OptimizeBuiltinCalls(Visitor.MethodDispatcherTransform):
    """Optimize some common methods calls and instantiation patterns
    for builtin types *after* the type analysis phase.

    Running after type analysis, this transform can only perform
    function replacements that do not alter the function return type
    in a way that was not anticipated by the type analysis.
    """
    ### cleanup to avoid redundant coercions to/from Python types

    def _visit_PyTypeTestNode(self, node):
        # disabled - appears to break assignments in some cases, and
        # also drops a None check, which might still be required
        """Flatten redundant type checks after tree changes.
        """
        old_arg = node.arg
        self.visitchildren(node)
        if old_arg is node.arg or node.arg.type != node.type:
            return node
        return node.arg

    def _visit_TypecastNode(self, node):
        # disabled - the user may have had a reason to put a type
        # cast, even if it looks redundant to Cython
        """
        Drop redundant type casts.
        """
        self.visitchildren(node)
        if node.type == node.operand.type:
            return node.operand
        return node

    def visit_ExprStatNode(self, node):
        """
        Drop useless coercions.
        """
        self.visitchildren(node)
        if isinstance(node.expr, ExprNodes.CoerceToPyTypeNode):
            node.expr = node.expr.arg
        return node

    def visit_CoerceToBooleanNode(self, node):
        """Drop redundant conversion nodes after tree changes.
        """
        self.visitchildren(node)
        arg = node.arg
        if isinstance(arg, ExprNodes.PyTypeTestNode):
            arg = arg.arg
        if isinstance(arg, ExprNodes.CoerceToPyTypeNode):
            if arg.type in (PyrexTypes.py_object_type, Builtin.bool_type):
                return arg.arg.coerce_to_boolean(self.current_env())
        return node

    def visit_CoerceFromPyTypeNode(self, node):
        """Drop redundant conversion nodes after tree changes.

        Also, optimise away calls to Python's builtin int() and
        float() if the result is going to be coerced back into a C
        type anyway.
        """
        self.visitchildren(node)
        arg = node.arg
        if not arg.type.is_pyobject:
            # no Python conversion left at all, just do a C coercion instead
            if node.type == arg.type:
                return arg
            else:
                return arg.coerce_to(node.type, self.current_env())
        if isinstance(arg, ExprNodes.PyTypeTestNode):
            arg = arg.arg
        if arg.is_literal:
            if (node.type.is_int and isinstance(arg, ExprNodes.IntNode) or
                    node.type.is_float and isinstance(arg, ExprNodes.FloatNode) or
                    node.type.is_int and isinstance(arg, ExprNodes.BoolNode)):
                return arg.coerce_to(node.type, self.current_env())
        elif isinstance(arg, ExprNodes.CoerceToPyTypeNode):
            if arg.type is PyrexTypes.py_object_type:
                if node.type.assignable_from(arg.arg.type):
                    # completely redundant C->Py->C coercion
                    return arg.arg.coerce_to(node.type, self.current_env())
        elif isinstance(arg, ExprNodes.SimpleCallNode):
            if node.type.is_int or node.type.is_float:
                return self._optimise_numeric_cast_call(node, arg)
        elif isinstance(arg, ExprNodes.IndexNode) and not arg.is_buffer_access:
            index_node = arg.index
            if isinstance(index_node, ExprNodes.CoerceToPyTypeNode):
                index_node = index_node.arg
            if index_node.type.is_int:
                return self._optimise_int_indexing(node, arg, index_node)
        return node

    PyBytes_GetItemInt_func_type = PyrexTypes.CFuncType(
        PyrexTypes.c_char_type, [
            PyrexTypes.CFuncTypeArg("bytes", Builtin.bytes_type, None),
            PyrexTypes.CFuncTypeArg("index", PyrexTypes.c_py_ssize_t_type, None),
            PyrexTypes.CFuncTypeArg("check_bounds", PyrexTypes.c_int_type, None),
            ],
        exception_value = "((char)-1)",
        exception_check = True)

    def _optimise_int_indexing(self, coerce_node, arg, index_node):
        env = self.current_env()
        bound_check_bool = env.directives['boundscheck'] and 1 or 0
        if arg.base.type is Builtin.bytes_type:
            if coerce_node.type in (PyrexTypes.c_char_type, PyrexTypes.c_uchar_type):
                # bytes[index] -> char
                bound_check_node = ExprNodes.IntNode(
                    coerce_node.pos, value=str(bound_check_bool),
                    constant_result=bound_check_bool)
                node = ExprNodes.PythonCapiCallNode(
                    coerce_node.pos, "__Pyx_PyBytes_GetItemInt",
                    self.PyBytes_GetItemInt_func_type,
                    args=[
                        arg.base.as_none_safe_node("'NoneType' object is not subscriptable"),
                        index_node.coerce_to(PyrexTypes.c_py_ssize_t_type, env),
                        bound_check_node,
                        ],
                    is_temp=True,
                    utility_code=UtilityCode.load_cached(
                        'bytes_index', 'StringTools.c'))
                if coerce_node.type is not PyrexTypes.c_char_type:
                    node = node.coerce_to(coerce_node.type, env)
                return node
        return coerce_node

    def _optimise_numeric_cast_call(self, node, arg):
        function = arg.function
        if not isinstance(function, ExprNodes.NameNode) \
               or not function.type.is_builtin_type \
               or not isinstance(arg.arg_tuple, ExprNodes.TupleNode):
            return node
        args = arg.arg_tuple.args
        if len(args) != 1:
            return node
        func_arg = args[0]
        if isinstance(func_arg, ExprNodes.CoerceToPyTypeNode):
            func_arg = func_arg.arg
        elif func_arg.type.is_pyobject:
            # play safe: Python conversion might work on all sorts of things
            return node
        if function.name == 'int':
            if func_arg.type.is_int or node.type.is_int:
                if func_arg.type == node.type:
                    return func_arg
                elif node.type.assignable_from(func_arg.type) or func_arg.type.is_float:
                    return ExprNodes.TypecastNode(
                        node.pos, operand=func_arg, type=node.type)
        elif function.name == 'float':
            if func_arg.type.is_float or node.type.is_float:
                if func_arg.type == node.type:
                    return func_arg
                elif node.type.assignable_from(func_arg.type) or func_arg.type.is_float:
                    return ExprNodes.TypecastNode(
                        node.pos, operand=func_arg, type=node.type)
        return node

    def _error_wrong_arg_count(self, function_name, node, args, expected=None):
        if not expected: # None or 0
            arg_str = ''
        elif isinstance(expected, basestring) or expected > 1:
            arg_str = '...'
        elif expected == 1:
            arg_str = 'x'
        else:
            arg_str = ''
        if expected is not None:
            expected_str = 'expected %s, ' % expected
        else:
            expected_str = ''
        error(node.pos, "%s(%s) called with wrong number of args, %sfound %d" % (
            function_name, arg_str, expected_str, len(args)))

    ### generic fallbacks

    def _handle_function(self, node, function_name, function, arg_list, kwargs):
        return node

    def _handle_method(self, node, type_name, attr_name, function,
                       arg_list, is_unbound_method, kwargs):
        """
        Try to inject C-API calls for unbound method calls to builtin types.
        While the method declarations in Builtin.py already handle this, we
        can additionally resolve bound and unbound methods here that were
        assigned to variables ahead of time.
        """
        if kwargs:
            return node
        if not function or not function.is_attribute or not function.obj.is_name:
            # cannot track unbound method calls over more than one indirection as
            # the names might have been reassigned in the meantime
            return node
        type_entry = self.current_env().lookup(type_name)
        if not type_entry:
            return node
        method = ExprNodes.AttributeNode(
            node.function.pos,
            obj=ExprNodes.NameNode(
                function.pos,
                name=type_name,
                entry=type_entry,
                type=type_entry.type),
            attribute=attr_name,
            is_called=True).analyse_as_unbound_cmethod_node(self.current_env())
        if method is None:
            return node
        args = node.args
        if args is None and node.arg_tuple:
            args = node.arg_tuple.args
        call_node = ExprNodes.SimpleCallNode(
            node.pos,
            function=method,
            args=args)
        if not is_unbound_method:
            call_node.self = function.obj
        call_node.analyse_c_function_call(self.current_env())
        call_node.analysed = True
        return call_node.coerce_to(node.type, self.current_env())

    ### builtin types

    PyDict_Copy_func_type = PyrexTypes.CFuncType(
        Builtin.dict_type, [
            PyrexTypes.CFuncTypeArg("dict", Builtin.dict_type, None)
            ])

    def _handle_simple_function_dict(self, node, function, pos_args):
        """Replace dict(some_dict) by PyDict_Copy(some_dict).
        """
        if len(pos_args) != 1:
            return node
        arg = pos_args[0]
        if arg.type is Builtin.dict_type:
            arg = arg.as_none_safe_node("'NoneType' is not iterable")
            return ExprNodes.PythonCapiCallNode(
                node.pos, "PyDict_Copy", self.PyDict_Copy_func_type,
                args = [arg],
                is_temp = node.is_temp
                )
        return node

    PyList_AsTuple_func_type = PyrexTypes.CFuncType(
        Builtin.tuple_type, [
            PyrexTypes.CFuncTypeArg("list", Builtin.list_type, None)
            ])

    def _handle_simple_function_tuple(self, node, function, pos_args):
        """Replace tuple([...]) by a call to PyList_AsTuple.
        """
        if len(pos_args) != 1:
            return node
        arg = pos_args[0]
        if arg.type is Builtin.tuple_type and not arg.may_be_none():
            return arg
        if arg.type is not Builtin.list_type:
            return node
        pos_args[0] = arg.as_none_safe_node(
            "'NoneType' object is not iterable")

        return ExprNodes.PythonCapiCallNode(
            node.pos, "PyList_AsTuple", self.PyList_AsTuple_func_type,
            args = pos_args,
            is_temp = node.is_temp
            )

    PySet_New_func_type = PyrexTypes.CFuncType(
        Builtin.set_type, [
            PyrexTypes.CFuncTypeArg("it", PyrexTypes.py_object_type, None)
        ])

    def _handle_simple_function_set(self, node, function, pos_args):
        if len(pos_args) != 1:
            return node
        if pos_args[0].is_sequence_constructor:
            # We can optimise set([x,y,z]) safely into a set literal,
            # but only if we create all items before adding them -
            # adding an item may raise an exception if it is not
            # hashable, but creating the later items may have
            # side-effects.
            args = []
            temps = []
            for arg in pos_args[0].args:
                if not arg.is_simple():
                    arg = UtilNodes.LetRefNode(arg)
                    temps.append(arg)
                args.append(arg)
            result = ExprNodes.SetNode(node.pos, is_temp=1, args=args)
            for temp in temps[::-1]:
                result = UtilNodes.EvalWithTempExprNode(temp, result)
            return result
        else:
            # PySet_New(it) is better than a generic Python call to set(it)
            return ExprNodes.PythonCapiCallNode(
                node.pos, "PySet_New",
                self.PySet_New_func_type,
                args=pos_args,
                is_temp=node.is_temp,
                utility_code=UtilityCode.load_cached('pyset_compat', 'Builtins.c'),
                py_name="set")

    PyFrozenSet_New_func_type = PyrexTypes.CFuncType(
        Builtin.frozenset_type, [
            PyrexTypes.CFuncTypeArg("it", PyrexTypes.py_object_type, None)
        ])

    def _handle_simple_function_frozenset(self, node, function, pos_args):
        if not pos_args:
            pos_args = [ExprNodes.NullNode(node.pos)]
        elif len(pos_args) > 1:
            return node
        elif pos_args[0].type is Builtin.frozenset_type and not pos_args[0].may_be_none():
            return pos_args[0]
        # PyFrozenSet_New(it) is better than a generic Python call to frozenset(it)
        return ExprNodes.PythonCapiCallNode(
            node.pos, "__Pyx_PyFrozenSet_New",
            self.PyFrozenSet_New_func_type,
            args=pos_args,
            is_temp=node.is_temp,
            utility_code=UtilityCode.load_cached('pyfrozenset_new', 'Builtins.c'),
            py_name="frozenset")

    PyObject_AsDouble_func_type = PyrexTypes.CFuncType(
        PyrexTypes.c_double_type, [
            PyrexTypes.CFuncTypeArg("obj", PyrexTypes.py_object_type, None),
            ],
        exception_value = "((double)-1)",
        exception_check = True)

    def _handle_simple_function_float(self, node, function, pos_args):
        """Transform float() into either a C type cast or a faster C
        function call.
        """
        # Note: this requires the float() function to be typed as
        # returning a C 'double'
        if len(pos_args) == 0:
            return ExprNodes.FloatNode(
                node, value="0.0", constant_result=0.0
                ).coerce_to(Builtin.float_type, self.current_env())
        elif len(pos_args) != 1:
            self._error_wrong_arg_count('float', node, pos_args, '0 or 1')
            return node
        func_arg = pos_args[0]
        if isinstance(func_arg, ExprNodes.CoerceToPyTypeNode):
            func_arg = func_arg.arg
        if func_arg.type is PyrexTypes.c_double_type:
            return func_arg
        elif node.type.assignable_from(func_arg.type) or func_arg.type.is_numeric:
            return ExprNodes.TypecastNode(
                node.pos, operand=func_arg, type=node.type)
        return ExprNodes.PythonCapiCallNode(
            node.pos, "__Pyx_PyObject_AsDouble",
            self.PyObject_AsDouble_func_type,
            args = pos_args,
            is_temp = node.is_temp,
            utility_code = load_c_utility('pyobject_as_double'),
            py_name = "float")

    PyNumber_Int_func_type = PyrexTypes.CFuncType(
        PyrexTypes.py_object_type, [
            PyrexTypes.CFuncTypeArg("o", PyrexTypes.py_object_type, None)
            ])

    def _handle_simple_function_int(self, node, function, pos_args):
        """Transform int() into a faster C function call.
        """
        if len(pos_args) == 0:
            return ExprNodes.IntNode(node, value="0", constant_result=0,
                                     type=PyrexTypes.py_object_type)
        elif len(pos_args) != 1:
            return node  # int(x, base)
        func_arg = pos_args[0]
        if isinstance(func_arg, ExprNodes.CoerceToPyTypeNode):
            return node  # handled in visit_CoerceFromPyTypeNode()
        if func_arg.type.is_pyobject and node.type.is_pyobject:
            return ExprNodes.PythonCapiCallNode(
                node.pos, "PyNumber_Int", self.PyNumber_Int_func_type,
                args=pos_args, is_temp=True)
        return node

    def _handle_simple_function_bool(self, node, function, pos_args):
        """Transform bool(x) into a type coercion to a boolean.
        """
        if len(pos_args) == 0:
            return ExprNodes.BoolNode(
                node.pos, value=False, constant_result=False
                ).coerce_to(Builtin.bool_type, self.current_env())
        elif len(pos_args) != 1:
            self._error_wrong_arg_count('bool', node, pos_args, '0 or 1')
            return node
        else:
            # => !!<bint>(x)  to make sure it's exactly 0 or 1
            operand = pos_args[0].coerce_to_boolean(self.current_env())
            operand = ExprNodes.NotNode(node.pos, operand = operand)
            operand = ExprNodes.NotNode(node.pos, operand = operand)
            # coerce back to Python object as that's the result we are expecting
            return operand.coerce_to_pyobject(self.current_env())

    ### builtin functions

    Pyx_strlen_func_type = PyrexTypes.CFuncType(
        PyrexTypes.c_size_t_type, [
            PyrexTypes.CFuncTypeArg("bytes", PyrexTypes.c_char_ptr_type, None)
            ])

    Pyx_Py_UNICODE_strlen_func_type = PyrexTypes.CFuncType(
        PyrexTypes.c_size_t_type, [
            PyrexTypes.CFuncTypeArg("unicode", PyrexTypes.c_py_unicode_ptr_type, None)
            ])

    PyObject_Size_func_type = PyrexTypes.CFuncType(
        PyrexTypes.c_py_ssize_t_type, [
            PyrexTypes.CFuncTypeArg("obj", PyrexTypes.py_object_type, None)
            ],
        exception_value="-1")

    _map_to_capi_len_function = {
        Builtin.unicode_type   : "__Pyx_PyUnicode_GET_LENGTH",
        Builtin.bytes_type     : "PyBytes_GET_SIZE",
        Builtin.list_type      : "PyList_GET_SIZE",
        Builtin.tuple_type     : "PyTuple_GET_SIZE",
        Builtin.dict_type      : "PyDict_Size",
        Builtin.set_type       : "PySet_Size",
        Builtin.frozenset_type : "PySet_Size",
        }.get

    _ext_types_with_pysize = set(["cpython.array.array"])

    def _handle_simple_function_len(self, node, function, pos_args):
        """Replace len(char*) by the equivalent call to strlen(),
        len(Py_UNICODE) by the equivalent Py_UNICODE_strlen() and
        len(known_builtin_type) by an equivalent C-API call.
        """
        if len(pos_args) != 1:
            self._error_wrong_arg_count('len', node, pos_args, 1)
            return node
        arg = pos_args[0]
        if isinstance(arg, ExprNodes.CoerceToPyTypeNode):
            arg = arg.arg
        if arg.type.is_string:
            new_node = ExprNodes.PythonCapiCallNode(
                node.pos, "strlen", self.Pyx_strlen_func_type,
                args = [arg],
                is_temp = node.is_temp,
                utility_code = UtilityCode.load_cached("IncludeStringH", "StringTools.c"))
        elif arg.type.is_pyunicode_ptr:
            new_node = ExprNodes.PythonCapiCallNode(
                node.pos, "__Pyx_Py_UNICODE_strlen", self.Pyx_Py_UNICODE_strlen_func_type,
                args = [arg],
                is_temp = node.is_temp)
        elif arg.type.is_pyobject:
            cfunc_name = self._map_to_capi_len_function(arg.type)
            if cfunc_name is None:
                arg_type = arg.type
                if ((arg_type.is_extension_type or arg_type.is_builtin_type)
                    and arg_type.entry.qualified_name in self._ext_types_with_pysize):
                    cfunc_name = 'Py_SIZE'
                else:
                    return node
            arg = arg.as_none_safe_node(
                "object of type 'NoneType' has no len()")
            new_node = ExprNodes.PythonCapiCallNode(
                node.pos, cfunc_name, self.PyObject_Size_func_type,
                args = [arg],
                is_temp = node.is_temp)
        elif arg.type.is_unicode_char:
            return ExprNodes.IntNode(node.pos, value='1', constant_result=1,
                                     type=node.type)
        else:
            return node
        if node.type not in (PyrexTypes.c_size_t_type, PyrexTypes.c_py_ssize_t_type):
            new_node = new_node.coerce_to(node.type, self.current_env())
        return new_node

    Pyx_Type_func_type = PyrexTypes.CFuncType(
        Builtin.type_type, [
            PyrexTypes.CFuncTypeArg("object", PyrexTypes.py_object_type, None)
            ])

    def _handle_simple_function_type(self, node, function, pos_args):
        """Replace type(o) by a macro call to Py_TYPE(o).
        """
        if len(pos_args) != 1:
            return node
        node = ExprNodes.PythonCapiCallNode(
            node.pos, "Py_TYPE", self.Pyx_Type_func_type,
            args = pos_args,
            is_temp = False)
        return ExprNodes.CastNode(node, PyrexTypes.py_object_type)

    Py_type_check_func_type = PyrexTypes.CFuncType(
        PyrexTypes.c_bint_type, [
            PyrexTypes.CFuncTypeArg("arg", PyrexTypes.py_object_type, None)
            ])

    def _handle_simple_function_isinstance(self, node, function, pos_args):
        """Replace isinstance() checks against builtin types by the
        corresponding C-API call.
        """
        if len(pos_args) != 2:
            return node
        arg, types = pos_args
        temp = None
        if isinstance(types, ExprNodes.TupleNode):
            types = types.args
            if arg.is_attribute or not arg.is_simple():
                arg = temp = UtilNodes.ResultRefNode(arg)
        elif types.type is Builtin.type_type:
            types = [types]
        else:
            return node

        tests = []
        test_nodes = []
        env = self.current_env()
        for test_type_node in types:
            builtin_type = None
            if test_type_node.is_name:
                if test_type_node.entry:
                    entry = env.lookup(test_type_node.entry.name)
                    if entry and entry.type and entry.type.is_builtin_type:
                        builtin_type = entry.type
            if builtin_type is Builtin.type_type:
                # all types have type "type", but there's only one 'type'
                if entry.name != 'type' or not (
                        entry.scope and entry.scope.is_builtin_scope):
                    builtin_type = None
            if builtin_type is not None:
                type_check_function = entry.type.type_check_function(exact=False)
                if type_check_function in tests:
                    continue
                tests.append(type_check_function)
                type_check_args = [arg]
            elif test_type_node.type is Builtin.type_type:
                type_check_function = '__Pyx_TypeCheck'
                type_check_args = [arg, test_type_node]
            else:
                return node
            test_nodes.append(
                ExprNodes.PythonCapiCallNode(
                    test_type_node.pos, type_check_function, self.Py_type_check_func_type,
                    args = type_check_args,
                    is_temp = True,
                    ))

        def join_with_or(a,b, make_binop_node=ExprNodes.binop_node):
            or_node = make_binop_node(node.pos, 'or', a, b)
            or_node.type = PyrexTypes.c_bint_type
            or_node.is_temp = True
            return or_node

        test_node = reduce(join_with_or, test_nodes).coerce_to(node.type, env)
        if temp is not None:
            test_node = UtilNodes.EvalWithTempExprNode(temp, test_node)
        return test_node

    def _handle_simple_function_ord(self, node, function, pos_args):
        """Unpack ord(Py_UNICODE) and ord('X').
        """
        if len(pos_args) != 1:
            return node
        arg = pos_args[0]
        if isinstance(arg, ExprNodes.CoerceToPyTypeNode):
            if arg.arg.type.is_unicode_char:
                return ExprNodes.TypecastNode(
                    arg.pos, operand=arg.arg, type=PyrexTypes.c_int_type
                    ).coerce_to(node.type, self.current_env())
        elif isinstance(arg, ExprNodes.UnicodeNode):
            if len(arg.value) == 1:
                return ExprNodes.IntNode(
                    arg.pos, type=PyrexTypes.c_int_type,
                    value=str(ord(arg.value)),
                    constant_result=ord(arg.value)
                    ).coerce_to(node.type, self.current_env())
        elif isinstance(arg, ExprNodes.StringNode):
            if arg.unicode_value and len(arg.unicode_value) == 1 \
                    and ord(arg.unicode_value) <= 255:  # Py2/3 portability
                return ExprNodes.IntNode(
                    arg.pos, type=PyrexTypes.c_int_type,
                    value=str(ord(arg.unicode_value)),
                    constant_result=ord(arg.unicode_value)
                    ).coerce_to(node.type, self.current_env())
        return node

    ### special methods

    Pyx_tp_new_func_type = PyrexTypes.CFuncType(
        PyrexTypes.py_object_type, [
            PyrexTypes.CFuncTypeArg("type",   PyrexTypes.py_object_type, None),
            PyrexTypes.CFuncTypeArg("args",   Builtin.tuple_type, None),
            ])

    Pyx_tp_new_kwargs_func_type = PyrexTypes.CFuncType(
        PyrexTypes.py_object_type, [
            PyrexTypes.CFuncTypeArg("type",   PyrexTypes.py_object_type, None),
            PyrexTypes.CFuncTypeArg("args",   Builtin.tuple_type, None),
            PyrexTypes.CFuncTypeArg("kwargs", Builtin.dict_type, None),
        ])

    def _handle_any_slot__new__(self, node, function, args,
                                is_unbound_method, kwargs=None):
        """Replace 'exttype.__new__(exttype, ...)' by a call to exttype->tp_new()
        """
        obj = function.obj
        if not is_unbound_method or len(args) < 1:
            return node
        type_arg = args[0]
        if not obj.is_name or not type_arg.is_name:
            # play safe
            return node
        if obj.type != Builtin.type_type or type_arg.type != Builtin.type_type:
            # not a known type, play safe
            return node
        if not type_arg.type_entry or not obj.type_entry:
            if obj.name != type_arg.name:
                return node
            # otherwise, we know it's a type and we know it's the same
            # type for both - that should do
        elif type_arg.type_entry != obj.type_entry:
            # different types - may or may not lead to an error at runtime
            return node

        args_tuple = ExprNodes.TupleNode(node.pos, args=args[1:])
        args_tuple = args_tuple.analyse_types(
            self.current_env(), skip_children=True)

        if type_arg.type_entry:
            ext_type = type_arg.type_entry.type
            if (ext_type.is_extension_type and ext_type.typeobj_cname and
                    ext_type.scope.global_scope() == self.current_env().global_scope()):
                # known type in current module
                tp_slot = TypeSlots.ConstructorSlot("tp_new", '__new__')
                slot_func_cname = TypeSlots.get_slot_function(ext_type.scope, tp_slot)
                if slot_func_cname:
                    cython_scope = self.context.cython_scope
                    PyTypeObjectPtr = PyrexTypes.CPtrType(
                        cython_scope.lookup('PyTypeObject').type)
                    pyx_tp_new_kwargs_func_type = PyrexTypes.CFuncType(
                        PyrexTypes.py_object_type, [
                            PyrexTypes.CFuncTypeArg("type",   PyTypeObjectPtr, None),
                            PyrexTypes.CFuncTypeArg("args",   PyrexTypes.py_object_type, None),
                            PyrexTypes.CFuncTypeArg("kwargs", PyrexTypes.py_object_type, None),
                            ])

                    type_arg = ExprNodes.CastNode(type_arg, PyTypeObjectPtr)
                    if not kwargs:
                        kwargs = ExprNodes.NullNode(node.pos, type=PyrexTypes.py_object_type)  # hack?
                    return ExprNodes.PythonCapiCallNode(
                        node.pos, slot_func_cname,
                        pyx_tp_new_kwargs_func_type,
                        args=[type_arg, args_tuple, kwargs],
                        is_temp=True)
        else:
            # arbitrary variable, needs a None check for safety
            type_arg = type_arg.as_none_safe_node(
                "object.__new__(X): X is not a type object (NoneType)")

        utility_code = UtilityCode.load_cached('tp_new', 'ObjectHandling.c')
        if kwargs:
            return ExprNodes.PythonCapiCallNode(
                node.pos, "__Pyx_tp_new_kwargs", self.Pyx_tp_new_kwargs_func_type,
                args=[type_arg, args_tuple, kwargs],
                utility_code=utility_code,
                is_temp=node.is_temp
                )
        else:
            return ExprNodes.PythonCapiCallNode(
                node.pos, "__Pyx_tp_new", self.Pyx_tp_new_func_type,
                args=[type_arg, args_tuple],
                utility_code=utility_code,
                is_temp=node.is_temp
            )

    ### methods of builtin types

    PyObject_Append_func_type = PyrexTypes.CFuncType(
        PyrexTypes.c_returncode_type, [
            PyrexTypes.CFuncTypeArg("list", PyrexTypes.py_object_type, None),
            PyrexTypes.CFuncTypeArg("item", PyrexTypes.py_object_type, None),
            ],
        exception_value="-1")

    def _handle_simple_method_object_append(self, node, function, args, is_unbound_method):
        """Optimistic optimisation as X.append() is almost always
        referring to a list.
        """
        if len(args) != 2 or node.result_is_used:
            return node

        return ExprNodes.PythonCapiCallNode(
            node.pos, "__Pyx_PyObject_Append", self.PyObject_Append_func_type,
            args=args,
            may_return_none=False,
            is_temp=node.is_temp,
            result_is_used=False,
            utility_code=load_c_utility('append')
        )

    PyByteArray_Append_func_type = PyrexTypes.CFuncType(
        PyrexTypes.c_returncode_type, [
            PyrexTypes.CFuncTypeArg("bytearray", PyrexTypes.py_object_type, None),
            PyrexTypes.CFuncTypeArg("value", PyrexTypes.c_int_type, None),
            ],
        exception_value="-1")

    PyByteArray_AppendObject_func_type = PyrexTypes.CFuncType(
        PyrexTypes.c_returncode_type, [
            PyrexTypes.CFuncTypeArg("bytearray", PyrexTypes.py_object_type, None),
            PyrexTypes.CFuncTypeArg("value", PyrexTypes.py_object_type, None),
            ],
        exception_value="-1")

    def _handle_simple_method_bytearray_append(self, node, function, args, is_unbound_method):
        if len(args) != 2:
            return node
        func_name = "__Pyx_PyByteArray_Append"
        func_type = self.PyByteArray_Append_func_type

        value = unwrap_coerced_node(args[1])
        if value.type.is_int or isinstance(value, ExprNodes.IntNode):
            value = value.coerce_to(PyrexTypes.c_int_type, self.current_env())
            utility_code = UtilityCode.load_cached("ByteArrayAppend", "StringTools.c")
        elif value.is_string_literal:
            if not value.can_coerce_to_char_literal():
                return node
            value = value.coerce_to(PyrexTypes.c_char_type, self.current_env())
            utility_code = UtilityCode.load_cached("ByteArrayAppend", "StringTools.c")
        elif value.type.is_pyobject:
            func_name = "__Pyx_PyByteArray_AppendObject"
            func_type = self.PyByteArray_AppendObject_func_type
            utility_code = UtilityCode.load_cached("ByteArrayAppendObject", "StringTools.c")
        else:
            return node

        new_node = ExprNodes.PythonCapiCallNode(
            node.pos, func_name, func_type,
            args=[args[0], value],
            may_return_none=False,
            is_temp=node.is_temp,
            utility_code=utility_code,
        )
        if node.result_is_used:
            new_node = new_node.coerce_to(node.type, self.current_env())
        return new_node

    PyObject_Pop_func_type = PyrexTypes.CFuncType(
        PyrexTypes.py_object_type, [
            PyrexTypes.CFuncTypeArg("list", PyrexTypes.py_object_type, None),
            ])

    PyObject_PopIndex_func_type = PyrexTypes.CFuncType(
        PyrexTypes.py_object_type, [
            PyrexTypes.CFuncTypeArg("list", PyrexTypes.py_object_type, None),
            PyrexTypes.CFuncTypeArg("index", PyrexTypes.c_long_type, None),
            ])

    def _handle_simple_method_list_pop(self, node, function, args, is_unbound_method):
        return self._handle_simple_method_object_pop(
            node, function, args, is_unbound_method, is_list=True)

    def _handle_simple_method_object_pop(self, node, function, args, is_unbound_method, is_list=False):
        """Optimistic optimisation as X.pop([n]) is almost always
        referring to a list.
        """
        if not args:
            return node
        args = args[:]
        if is_list:
            type_name = 'List'
            args[0] = args[0].as_none_safe_node(
                "'NoneType' object has no attribute '%s'",
                error="PyExc_AttributeError",
                format_args=['pop'])
        else:
            type_name = 'Object'
        if len(args) == 1:
            return ExprNodes.PythonCapiCallNode(
                node.pos, "__Pyx_Py%s_Pop" % type_name,
                self.PyObject_Pop_func_type,
                args=args,
                may_return_none=True,
                is_temp=node.is_temp,
                utility_code=load_c_utility('pop'),
            )
        elif len(args) == 2:
            index = unwrap_coerced_node(args[1])
            if is_list or isinstance(index, ExprNodes.IntNode):
                index = index.coerce_to(PyrexTypes.c_py_ssize_t_type, self.current_env())
            if index.type.is_int:
                widest = PyrexTypes.widest_numeric_type(
                    index.type, PyrexTypes.c_py_ssize_t_type)
                if widest == PyrexTypes.c_py_ssize_t_type:
                    args[1] = index
                    return ExprNodes.PythonCapiCallNode(
                        node.pos, "__Pyx_Py%s_PopIndex" % type_name,
                        self.PyObject_PopIndex_func_type,
                        args=args,
                        may_return_none=True,
                        is_temp=node.is_temp,
                        utility_code=load_c_utility("pop_index"),
                    )

        return node

    single_param_func_type = PyrexTypes.CFuncType(
        PyrexTypes.c_returncode_type, [
            PyrexTypes.CFuncTypeArg("obj", PyrexTypes.py_object_type, None),
            ],
        exception_value = "-1")

    def _handle_simple_method_list_sort(self, node, function, args, is_unbound_method):
        """Call PyList_Sort() instead of the 0-argument l.sort().
        """
        if len(args) != 1:
            return node
        return self._substitute_method_call(
            node, function, "PyList_Sort", self.single_param_func_type,
            'sort', is_unbound_method, args).coerce_to(node.type, self.current_env)

    Pyx_PyDict_GetItem_func_type = PyrexTypes.CFuncType(
        PyrexTypes.py_object_type, [
            PyrexTypes.CFuncTypeArg("dict", PyrexTypes.py_object_type, None),
            PyrexTypes.CFuncTypeArg("key", PyrexTypes.py_object_type, None),
            PyrexTypes.CFuncTypeArg("default", PyrexTypes.py_object_type, None),
            ])

    def _handle_simple_method_dict_get(self, node, function, args, is_unbound_method):
        """Replace dict.get() by a call to PyDict_GetItem().
        """
        if len(args) == 2:
            args.append(ExprNodes.NoneNode(node.pos))
        elif len(args) != 3:
            self._error_wrong_arg_count('dict.get', node, args, "2 or 3")
            return node

        return self._substitute_method_call(
            node, function,
            "__Pyx_PyDict_GetItemDefault", self.Pyx_PyDict_GetItem_func_type,
            'get', is_unbound_method, args,
            may_return_none = True,
            utility_code = load_c_utility("dict_getitem_default"))

    Pyx_PyDict_SetDefault_func_type = PyrexTypes.CFuncType(
        PyrexTypes.py_object_type, [
            PyrexTypes.CFuncTypeArg("dict", PyrexTypes.py_object_type, None),
            PyrexTypes.CFuncTypeArg("key", PyrexTypes.py_object_type, None),
            PyrexTypes.CFuncTypeArg("default", PyrexTypes.py_object_type, None),
            PyrexTypes.CFuncTypeArg("is_safe_type", PyrexTypes.c_int_type, None),
            ])

    def _handle_simple_method_dict_setdefault(self, node, function, args, is_unbound_method):
        """Replace dict.setdefault() by calls to PyDict_GetItem() and PyDict_SetItem().
        """
        if len(args) == 2:
            args.append(ExprNodes.NoneNode(node.pos))
        elif len(args) != 3:
            self._error_wrong_arg_count('dict.setdefault', node, args, "2 or 3")
            return node
        key_type = args[1].type
        if key_type.is_builtin_type:
            is_safe_type = int(key_type.name in
                               'str bytes unicode float int long bool')
        elif key_type is PyrexTypes.py_object_type:
            is_safe_type = -1  # don't know
        else:
            is_safe_type = 0   # definitely not
        args.append(ExprNodes.IntNode(
            node.pos, value=str(is_safe_type), constant_result=is_safe_type))

        return self._substitute_method_call(
            node, function,
            "__Pyx_PyDict_SetDefault", self.Pyx_PyDict_SetDefault_func_type,
            'setdefault', is_unbound_method, args,
            may_return_none=True,
            utility_code=load_c_utility('dict_setdefault'))


    ### unicode type methods

    PyUnicode_uchar_predicate_func_type = PyrexTypes.CFuncType(
        PyrexTypes.c_bint_type, [
            PyrexTypes.CFuncTypeArg("uchar", PyrexTypes.c_py_ucs4_type, None),
            ])

    def _inject_unicode_predicate(self, node, function, args, is_unbound_method):
        if is_unbound_method or len(args) != 1:
            return node
        ustring = args[0]
        if not isinstance(ustring, ExprNodes.CoerceToPyTypeNode) or \
               not ustring.arg.type.is_unicode_char:
            return node
        uchar = ustring.arg
        method_name = function.attribute
        if method_name == 'istitle':
            # istitle() doesn't directly map to Py_UNICODE_ISTITLE()
            utility_code = UtilityCode.load_cached(
                "py_unicode_istitle", "StringTools.c")
            function_name = '__Pyx_Py_UNICODE_ISTITLE'
        else:
            utility_code = None
            function_name = 'Py_UNICODE_%s' % method_name.upper()
        func_call = self._substitute_method_call(
            node, function,
            function_name, self.PyUnicode_uchar_predicate_func_type,
            method_name, is_unbound_method, [uchar],
            utility_code = utility_code)
        if node.type.is_pyobject:
            func_call = func_call.coerce_to_pyobject(self.current_env)
        return func_call

    _handle_simple_method_unicode_isalnum   = _inject_unicode_predicate
    _handle_simple_method_unicode_isalpha   = _inject_unicode_predicate
    _handle_simple_method_unicode_isdecimal = _inject_unicode_predicate
    _handle_simple_method_unicode_isdigit   = _inject_unicode_predicate
    _handle_simple_method_unicode_islower   = _inject_unicode_predicate
    _handle_simple_method_unicode_isnumeric = _inject_unicode_predicate
    _handle_simple_method_unicode_isspace   = _inject_unicode_predicate
    _handle_simple_method_unicode_istitle   = _inject_unicode_predicate
    _handle_simple_method_unicode_isupper   = _inject_unicode_predicate

    PyUnicode_uchar_conversion_func_type = PyrexTypes.CFuncType(
        PyrexTypes.c_py_ucs4_type, [
            PyrexTypes.CFuncTypeArg("uchar", PyrexTypes.c_py_ucs4_type, None),
            ])

    def _inject_unicode_character_conversion(self, node, function, args, is_unbound_method):
        if is_unbound_method or len(args) != 1:
            return node
        ustring = args[0]
        if not isinstance(ustring, ExprNodes.CoerceToPyTypeNode) or \
               not ustring.arg.type.is_unicode_char:
            return node
        uchar = ustring.arg
        method_name = function.attribute
        function_name = 'Py_UNICODE_TO%s' % method_name.upper()
        func_call = self._substitute_method_call(
            node, function,
            function_name, self.PyUnicode_uchar_conversion_func_type,
            method_name, is_unbound_method, [uchar])
        if node.type.is_pyobject:
            func_call = func_call.coerce_to_pyobject(self.current_env)
        return func_call

    _handle_simple_method_unicode_lower = _inject_unicode_character_conversion
    _handle_simple_method_unicode_upper = _inject_unicode_character_conversion
    _handle_simple_method_unicode_title = _inject_unicode_character_conversion

    PyUnicode_Splitlines_func_type = PyrexTypes.CFuncType(
        Builtin.list_type, [
            PyrexTypes.CFuncTypeArg("str", Builtin.unicode_type, None),
            PyrexTypes.CFuncTypeArg("keepends", PyrexTypes.c_bint_type, None),
            ])

    def _handle_simple_method_unicode_splitlines(self, node, function, args, is_unbound_method):
        """Replace unicode.splitlines(...) by a direct call to the
        corresponding C-API function.
        """
        if len(args) not in (1,2):
            self._error_wrong_arg_count('unicode.splitlines', node, args, "1 or 2")
            return node
        self._inject_bint_default_argument(node, args, 1, False)

        return self._substitute_method_call(
            node, function,
            "PyUnicode_Splitlines", self.PyUnicode_Splitlines_func_type,
            'splitlines', is_unbound_method, args)

    PyUnicode_Split_func_type = PyrexTypes.CFuncType(
        Builtin.list_type, [
            PyrexTypes.CFuncTypeArg("str", Builtin.unicode_type, None),
            PyrexTypes.CFuncTypeArg("sep", PyrexTypes.py_object_type, None),
            PyrexTypes.CFuncTypeArg("maxsplit", PyrexTypes.c_py_ssize_t_type, None),
            ]
        )

    def _handle_simple_method_unicode_split(self, node, function, args, is_unbound_method):
        """Replace unicode.split(...) by a direct call to the
        corresponding C-API function.
        """
        if len(args) not in (1,2,3):
            self._error_wrong_arg_count('unicode.split', node, args, "1-3")
            return node
        if len(args) < 2:
            args.append(ExprNodes.NullNode(node.pos))
        self._inject_int_default_argument(
            node, args, 2, PyrexTypes.c_py_ssize_t_type, "-1")

        return self._substitute_method_call(
            node, function,
            "PyUnicode_Split", self.PyUnicode_Split_func_type,
            'split', is_unbound_method, args)

    PyString_Tailmatch_func_type = PyrexTypes.CFuncType(
        PyrexTypes.c_bint_type, [
            PyrexTypes.CFuncTypeArg("str", PyrexTypes.py_object_type, None),  # bytes/str/unicode
            PyrexTypes.CFuncTypeArg("substring", PyrexTypes.py_object_type, None),
            PyrexTypes.CFuncTypeArg("start", PyrexTypes.c_py_ssize_t_type, None),
            PyrexTypes.CFuncTypeArg("end", PyrexTypes.c_py_ssize_t_type, None),
            PyrexTypes.CFuncTypeArg("direction", PyrexTypes.c_int_type, None),
            ],
        exception_value = '-1')

    def _handle_simple_method_unicode_endswith(self, node, function, args, is_unbound_method):
        return self._inject_tailmatch(
            node, function, args, is_unbound_method, 'unicode', 'endswith',
            unicode_tailmatch_utility_code, +1)

    def _handle_simple_method_unicode_startswith(self, node, function, args, is_unbound_method):
        return self._inject_tailmatch(
            node, function, args, is_unbound_method, 'unicode', 'startswith',
            unicode_tailmatch_utility_code, -1)

    def _inject_tailmatch(self, node, function, args, is_unbound_method, type_name,
                          method_name, utility_code, direction):
        """Replace unicode.startswith(...) and unicode.endswith(...)
        by a direct call to the corresponding C-API function.
        """
        if len(args) not in (2,3,4):
            self._error_wrong_arg_count('%s.%s' % (type_name, method_name), node, args, "2-4")
            return node
        self._inject_int_default_argument(
            node, args, 2, PyrexTypes.c_py_ssize_t_type, "0")
        self._inject_int_default_argument(
            node, args, 3, PyrexTypes.c_py_ssize_t_type, "PY_SSIZE_T_MAX")
        args.append(ExprNodes.IntNode(
            node.pos, value=str(direction), type=PyrexTypes.c_int_type))

        method_call = self._substitute_method_call(
            node, function,
            "__Pyx_Py%s_Tailmatch" % type_name.capitalize(),
            self.PyString_Tailmatch_func_type,
            method_name, is_unbound_method, args,
            utility_code = utility_code)
        return method_call.coerce_to(Builtin.bool_type, self.current_env())

    PyUnicode_Find_func_type = PyrexTypes.CFuncType(
        PyrexTypes.c_py_ssize_t_type, [
            PyrexTypes.CFuncTypeArg("str", Builtin.unicode_type, None),
            PyrexTypes.CFuncTypeArg("substring", PyrexTypes.py_object_type, None),
            PyrexTypes.CFuncTypeArg("start", PyrexTypes.c_py_ssize_t_type, None),
            PyrexTypes.CFuncTypeArg("end", PyrexTypes.c_py_ssize_t_type, None),
            PyrexTypes.CFuncTypeArg("direction", PyrexTypes.c_int_type, None),
            ],
        exception_value = '-2')

    def _handle_simple_method_unicode_find(self, node, function, args, is_unbound_method):
        return self._inject_unicode_find(
            node, function, args, is_unbound_method, 'find', +1)

    def _handle_simple_method_unicode_rfind(self, node, function, args, is_unbound_method):
        return self._inject_unicode_find(
            node, function, args, is_unbound_method, 'rfind', -1)

    def _inject_unicode_find(self, node, function, args, is_unbound_method,
                             method_name, direction):
        """Replace unicode.find(...) and unicode.rfind(...) by a
        direct call to the corresponding C-API function.
        """
        if len(args) not in (2,3,4):
            self._error_wrong_arg_count('unicode.%s' % method_name, node, args, "2-4")
            return node
        self._inject_int_default_argument(
            node, args, 2, PyrexTypes.c_py_ssize_t_type, "0")
        self._inject_int_default_argument(
            node, args, 3, PyrexTypes.c_py_ssize_t_type, "PY_SSIZE_T_MAX")
        args.append(ExprNodes.IntNode(
            node.pos, value=str(direction), type=PyrexTypes.c_int_type))

        method_call = self._substitute_method_call(
            node, function, "PyUnicode_Find", self.PyUnicode_Find_func_type,
            method_name, is_unbound_method, args)
        return method_call.coerce_to_pyobject(self.current_env())

    PyUnicode_Count_func_type = PyrexTypes.CFuncType(
        PyrexTypes.c_py_ssize_t_type, [
            PyrexTypes.CFuncTypeArg("str", Builtin.unicode_type, None),
            PyrexTypes.CFuncTypeArg("substring", PyrexTypes.py_object_type, None),
            PyrexTypes.CFuncTypeArg("start", PyrexTypes.c_py_ssize_t_type, None),
            PyrexTypes.CFuncTypeArg("end", PyrexTypes.c_py_ssize_t_type, None),
            ],
        exception_value = '-1')

    def _handle_simple_method_unicode_count(self, node, function, args, is_unbound_method):
        """Replace unicode.count(...) by a direct call to the
        corresponding C-API function.
        """
        if len(args) not in (2,3,4):
            self._error_wrong_arg_count('unicode.count', node, args, "2-4")
            return node
        self._inject_int_default_argument(
            node, args, 2, PyrexTypes.c_py_ssize_t_type, "0")
        self._inject_int_default_argument(
            node, args, 3, PyrexTypes.c_py_ssize_t_type, "PY_SSIZE_T_MAX")

        method_call = self._substitute_method_call(
            node, function, "PyUnicode_Count", self.PyUnicode_Count_func_type,
            'count', is_unbound_method, args)
        return method_call.coerce_to_pyobject(self.current_env())

    PyUnicode_Replace_func_type = PyrexTypes.CFuncType(
        Builtin.unicode_type, [
            PyrexTypes.CFuncTypeArg("str", Builtin.unicode_type, None),
            PyrexTypes.CFuncTypeArg("substring", PyrexTypes.py_object_type, None),
            PyrexTypes.CFuncTypeArg("replstr", PyrexTypes.py_object_type, None),
            PyrexTypes.CFuncTypeArg("maxcount", PyrexTypes.c_py_ssize_t_type, None),
            ])

    def _handle_simple_method_unicode_replace(self, node, function, args, is_unbound_method):
        """Replace unicode.replace(...) by a direct call to the
        corresponding C-API function.
        """
        if len(args) not in (3,4):
            self._error_wrong_arg_count('unicode.replace', node, args, "3-4")
            return node
        self._inject_int_default_argument(
            node, args, 3, PyrexTypes.c_py_ssize_t_type, "-1")

        return self._substitute_method_call(
            node, function, "PyUnicode_Replace", self.PyUnicode_Replace_func_type,
            'replace', is_unbound_method, args)

    PyUnicode_AsEncodedString_func_type = PyrexTypes.CFuncType(
        Builtin.bytes_type, [
            PyrexTypes.CFuncTypeArg("obj", Builtin.unicode_type, None),
            PyrexTypes.CFuncTypeArg("encoding", PyrexTypes.c_char_ptr_type, None),
            PyrexTypes.CFuncTypeArg("errors", PyrexTypes.c_char_ptr_type, None),
            ])

    PyUnicode_AsXyzString_func_type = PyrexTypes.CFuncType(
        Builtin.bytes_type, [
            PyrexTypes.CFuncTypeArg("obj", Builtin.unicode_type, None),
            ])

    _special_encodings = ['UTF8', 'UTF16', 'Latin1', 'ASCII',
                          'unicode_escape', 'raw_unicode_escape']

    _special_codecs = [ (name, codecs.getencoder(name))
                        for name in _special_encodings ]

    def _handle_simple_method_unicode_encode(self, node, function, args, is_unbound_method):
        """Replace unicode.encode(...) by a direct C-API call to the
        corresponding codec.
        """
        if len(args) < 1 or len(args) > 3:
            self._error_wrong_arg_count('unicode.encode', node, args, '1-3')
            return node

        string_node = args[0]

        if len(args) == 1:
            null_node = ExprNodes.NullNode(node.pos)
            return self._substitute_method_call(
                node, function, "PyUnicode_AsEncodedString",
                self.PyUnicode_AsEncodedString_func_type,
                'encode', is_unbound_method, [string_node, null_node, null_node])

        parameters = self._unpack_encoding_and_error_mode(node.pos, args)
        if parameters is None:
            return node
        encoding, encoding_node, error_handling, error_handling_node = parameters

        if encoding and isinstance(string_node, ExprNodes.UnicodeNode):
            # constant, so try to do the encoding at compile time
            try:
                value = string_node.value.encode(encoding, error_handling)
            except:
                # well, looks like we can't
                pass
            else:
                value = BytesLiteral(value)
                value.encoding = encoding
                return ExprNodes.BytesNode(
                    string_node.pos, value=value, type=Builtin.bytes_type)

        if encoding and error_handling == 'strict':
            # try to find a specific encoder function
            codec_name = self._find_special_codec_name(encoding)
            if codec_name is not None:
                encode_function = "PyUnicode_As%sString" % codec_name
                return self._substitute_method_call(
                    node, function, encode_function,
                    self.PyUnicode_AsXyzString_func_type,
                    'encode', is_unbound_method, [string_node])

        return self._substitute_method_call(
            node, function, "PyUnicode_AsEncodedString",
            self.PyUnicode_AsEncodedString_func_type,
            'encode', is_unbound_method,
            [string_node, encoding_node, error_handling_node])

    PyUnicode_DecodeXyz_func_ptr_type = PyrexTypes.CPtrType(PyrexTypes.CFuncType(
        Builtin.unicode_type, [
            PyrexTypes.CFuncTypeArg("string", PyrexTypes.c_char_ptr_type, None),
            PyrexTypes.CFuncTypeArg("size", PyrexTypes.c_py_ssize_t_type, None),
            PyrexTypes.CFuncTypeArg("errors", PyrexTypes.c_char_ptr_type, None),
            ]))

    _decode_c_string_func_type = PyrexTypes.CFuncType(
        Builtin.unicode_type, [
            PyrexTypes.CFuncTypeArg("string", PyrexTypes.c_char_ptr_type, None),
            PyrexTypes.CFuncTypeArg("start", PyrexTypes.c_py_ssize_t_type, None),
            PyrexTypes.CFuncTypeArg("stop", PyrexTypes.c_py_ssize_t_type, None),
            PyrexTypes.CFuncTypeArg("encoding", PyrexTypes.c_char_ptr_type, None),
            PyrexTypes.CFuncTypeArg("errors", PyrexTypes.c_char_ptr_type, None),
            PyrexTypes.CFuncTypeArg("decode_func", PyUnicode_DecodeXyz_func_ptr_type, None),
            ])

    _decode_bytes_func_type = PyrexTypes.CFuncType(
        Builtin.unicode_type, [
            PyrexTypes.CFuncTypeArg("string", PyrexTypes.py_object_type, None),
            PyrexTypes.CFuncTypeArg("start", PyrexTypes.c_py_ssize_t_type, None),
            PyrexTypes.CFuncTypeArg("stop", PyrexTypes.c_py_ssize_t_type, None),
            PyrexTypes.CFuncTypeArg("encoding", PyrexTypes.c_char_ptr_type, None),
            PyrexTypes.CFuncTypeArg("errors", PyrexTypes.c_char_ptr_type, None),
            PyrexTypes.CFuncTypeArg("decode_func", PyUnicode_DecodeXyz_func_ptr_type, None),
            ])

    _decode_cpp_string_func_type = None  # lazy init

    def _handle_simple_method_bytes_decode(self, node, function, args, is_unbound_method):
        """Replace char*.decode() by a direct C-API call to the
        corresponding codec, possibly resolving a slice on the char*.
        """
        if not (1 <= len(args) <= 3):
            self._error_wrong_arg_count('bytes.decode', node, args, '1-3')
            return node

        # normalise input nodes
        string_node = args[0]
        start = stop = None
        if isinstance(string_node, ExprNodes.SliceIndexNode):
            index_node = string_node
            string_node = index_node.base
            start, stop = index_node.start, index_node.stop
            if not start or start.constant_result == 0:
                start = None
        if isinstance(string_node, ExprNodes.CoerceToPyTypeNode):
            string_node = string_node.arg

        string_type = string_node.type
        if string_type in (Builtin.bytes_type, Builtin.bytearray_type):
            if is_unbound_method:
                string_node = string_node.as_none_safe_node(
                    "descriptor '%s' requires a '%s' object but received a 'NoneType'",
                    format_args=['decode', string_type.name])
            else:
                string_node = string_node.as_none_safe_node(
                    "'NoneType' object has no attribute '%s'",
                    error="PyExc_AttributeError",
                    format_args=['decode'])
        elif not string_type.is_string and not string_type.is_cpp_string:
            # nothing to optimise here
            return node

        parameters = self._unpack_encoding_and_error_mode(node.pos, args)
        if parameters is None:
            return node
        encoding, encoding_node, error_handling, error_handling_node = parameters

        if not start:
            start = ExprNodes.IntNode(node.pos, value='0', constant_result=0)
        elif not start.type.is_int:
            start = start.coerce_to(PyrexTypes.c_py_ssize_t_type, self.current_env())
        if stop and not stop.type.is_int:
            stop = stop.coerce_to(PyrexTypes.c_py_ssize_t_type, self.current_env())

        # try to find a specific encoder function
        codec_name = None
        if encoding is not None:
            codec_name = self._find_special_codec_name(encoding)
        if codec_name is not None:
            decode_function = ExprNodes.RawCNameExprNode(
                node.pos, type=self.PyUnicode_DecodeXyz_func_ptr_type,
                cname="PyUnicode_Decode%s" % codec_name)
            encoding_node = ExprNodes.NullNode(node.pos)
        else:
            decode_function = ExprNodes.NullNode(node.pos)

        # build the helper function call
        temps = []
        if string_type.is_string:
            # C string
            if not stop:
                # use strlen() to find the string length, just as CPython would
                if not string_node.is_name:
                    string_node = UtilNodes.LetRefNode(string_node) # used twice
                    temps.append(string_node)
                stop = ExprNodes.PythonCapiCallNode(
                    string_node.pos, "strlen", self.Pyx_strlen_func_type,
                    args=[string_node],
                    is_temp=False,
                    utility_code=UtilityCode.load_cached("IncludeStringH", "StringTools.c"),
                ).coerce_to(PyrexTypes.c_py_ssize_t_type, self.current_env())
            helper_func_type = self._decode_c_string_func_type
            utility_code_name = 'decode_c_string'
        elif string_type.is_cpp_string:
            # C++ std::string
            if not stop:
                stop = ExprNodes.IntNode(node.pos, value='PY_SSIZE_T_MAX',
                                         constant_result=ExprNodes.not_a_constant)
            if self._decode_cpp_string_func_type is None:
                # lazy init to reuse the C++ string type
                self._decode_cpp_string_func_type = PyrexTypes.CFuncType(
                    Builtin.unicode_type, [
                        PyrexTypes.CFuncTypeArg("string", string_type, None),
                        PyrexTypes.CFuncTypeArg("start", PyrexTypes.c_py_ssize_t_type, None),
                        PyrexTypes.CFuncTypeArg("stop", PyrexTypes.c_py_ssize_t_type, None),
                        PyrexTypes.CFuncTypeArg("encoding", PyrexTypes.c_char_ptr_type, None),
                        PyrexTypes.CFuncTypeArg("errors", PyrexTypes.c_char_ptr_type, None),
                        PyrexTypes.CFuncTypeArg("decode_func", self.PyUnicode_DecodeXyz_func_ptr_type, None),
                    ])
            helper_func_type = self._decode_cpp_string_func_type
            utility_code_name = 'decode_cpp_string'
        else:
            # Python bytes/bytearray object
            if not stop:
                stop = ExprNodes.IntNode(node.pos, value='PY_SSIZE_T_MAX',
                                         constant_result=ExprNodes.not_a_constant)
            helper_func_type = self._decode_bytes_func_type
            if string_type is Builtin.bytes_type:
                utility_code_name = 'decode_bytes'
            else:
                utility_code_name = 'decode_bytearray'

        node = ExprNodes.PythonCapiCallNode(
            node.pos, '__Pyx_%s' % utility_code_name, helper_func_type,
            args=[string_node, start, stop, encoding_node, error_handling_node, decode_function],
            is_temp=node.is_temp,
            utility_code=UtilityCode.load_cached(utility_code_name, 'StringTools.c'),
        )

        for temp in temps[::-1]:
            node = UtilNodes.EvalWithTempExprNode(temp, node)
        return node

    _handle_simple_method_bytearray_decode = _handle_simple_method_bytes_decode

    def _find_special_codec_name(self, encoding):
        try:
            requested_codec = codecs.getencoder(encoding)
        except LookupError:
            return None
        for name, codec in self._special_codecs:
            if codec == requested_codec:
                if '_' in name:
                    name = ''.join([s.capitalize()
                                    for s in name.split('_')])
                return name
        return None

    def _unpack_encoding_and_error_mode(self, pos, args):
        null_node = ExprNodes.NullNode(pos)

        if len(args) >= 2:
            encoding, encoding_node = self._unpack_string_and_cstring_node(args[1])
            if encoding_node is None:
                return None
        else:
            encoding = None
            encoding_node = null_node

        if len(args) == 3:
            error_handling, error_handling_node = self._unpack_string_and_cstring_node(args[2])
            if error_handling_node is None:
                return None
            if error_handling == 'strict':
                error_handling_node = null_node
        else:
            error_handling = 'strict'
            error_handling_node = null_node

        return (encoding, encoding_node, error_handling, error_handling_node)

    def _unpack_string_and_cstring_node(self, node):
        if isinstance(node, ExprNodes.CoerceToPyTypeNode):
            node = node.arg
        if isinstance(node, ExprNodes.UnicodeNode):
            encoding = node.value
            node = ExprNodes.BytesNode(
                node.pos, value=BytesLiteral(encoding.utf8encode()),
                type=PyrexTypes.c_char_ptr_type)
        elif isinstance(node, (ExprNodes.StringNode, ExprNodes.BytesNode)):
            encoding = node.value.decode('ISO-8859-1')
            node = ExprNodes.BytesNode(
                node.pos, value=node.value, type=PyrexTypes.c_char_ptr_type)
        elif node.type is Builtin.bytes_type:
            encoding = None
            node = node.coerce_to(PyrexTypes.c_char_ptr_type, self.current_env())
        elif node.type.is_string:
            encoding = None
        else:
            encoding = node = None
        return encoding, node

    def _handle_simple_method_str_endswith(self, node, function, args, is_unbound_method):
        return self._inject_tailmatch(
            node, function, args, is_unbound_method, 'str', 'endswith',
            str_tailmatch_utility_code, +1)

    def _handle_simple_method_str_startswith(self, node, function, args, is_unbound_method):
        return self._inject_tailmatch(
            node, function, args, is_unbound_method, 'str', 'startswith',
            str_tailmatch_utility_code, -1)

    def _handle_simple_method_bytes_endswith(self, node, function, args, is_unbound_method):
        return self._inject_tailmatch(
            node, function, args, is_unbound_method, 'bytes', 'endswith',
            bytes_tailmatch_utility_code, +1)

    def _handle_simple_method_bytes_startswith(self, node, function, args, is_unbound_method):
        return self._inject_tailmatch(
            node, function, args, is_unbound_method, 'bytes', 'startswith',
            bytes_tailmatch_utility_code, -1)

    '''   # disabled for now, enable when we consider it worth it (see StringTools.c)
    def _handle_simple_method_bytearray_endswith(self, node, function, args, is_unbound_method):
        return self._inject_tailmatch(
            node, function, args, is_unbound_method, 'bytearray', 'endswith',
            bytes_tailmatch_utility_code, +1)

    def _handle_simple_method_bytearray_startswith(self, node, function, args, is_unbound_method):
        return self._inject_tailmatch(
            node, function, args, is_unbound_method, 'bytearray', 'startswith',
            bytes_tailmatch_utility_code, -1)
    '''

    ### helpers

    def _substitute_method_call(self, node, function, name, func_type,
                                attr_name, is_unbound_method, args=(),
                                utility_code=None, is_temp=None,
                                may_return_none=ExprNodes.PythonCapiCallNode.may_return_none):
        args = list(args)
        if args and not args[0].is_literal:
            self_arg = args[0]
            if is_unbound_method:
                self_arg = self_arg.as_none_safe_node(
                    "descriptor '%s' requires a '%s' object but received a 'NoneType'",
                    format_args=[attr_name, function.obj.name])
            else:
                self_arg = self_arg.as_none_safe_node(
                    "'NoneType' object has no attribute '%s'",
                    error = "PyExc_AttributeError",
                    format_args = [attr_name])
            args[0] = self_arg
        if is_temp is None:
            is_temp = node.is_temp
        return ExprNodes.PythonCapiCallNode(
            node.pos, name, func_type,
            args = args,
            is_temp = is_temp,
            utility_code = utility_code,
            may_return_none = may_return_none,
            result_is_used = node.result_is_used,
            )

    def _inject_int_default_argument(self, node, args, arg_index, type, default_value):
        assert len(args) >= arg_index
        if len(args) == arg_index:
            args.append(ExprNodes.IntNode(node.pos, value=str(default_value),
                                          type=type, constant_result=default_value))
        else:
            args[arg_index] = args[arg_index].coerce_to(type, self.current_env())

    def _inject_bint_default_argument(self, node, args, arg_index, default_value):
        assert len(args) >= arg_index
        if len(args) == arg_index:
            default_value = bool(default_value)
            args.append(ExprNodes.BoolNode(node.pos, value=default_value,
                                           constant_result=default_value))
        else:
            args[arg_index] = args[arg_index].coerce_to_boolean(self.current_env())


unicode_tailmatch_utility_code = UtilityCode.load_cached('unicode_tailmatch', 'StringTools.c')
bytes_tailmatch_utility_code = UtilityCode.load_cached('bytes_tailmatch', 'StringTools.c')
str_tailmatch_utility_code = UtilityCode.load_cached('str_tailmatch', 'StringTools.c')


class ConstantFolding(Visitor.VisitorTransform, SkipDeclarations):
    """Calculate the result of constant expressions to store it in
    ``expr_node.constant_result``, and replace trivial cases by their
    constant result.

    General rules:

    - We calculate float constants to make them available to the
      compiler, but we do not aggregate them into a single literal
      node to prevent any loss of precision.

    - We recursively calculate constants from non-literal nodes to
      make them available to the compiler, but we only aggregate
      literal nodes at each step.  Non-literal nodes are never merged
      into a single node.
    """

    def __init__(self, reevaluate=False):
        """
        The reevaluate argument specifies whether constant values that were
        previously computed should be recomputed.
        """
        super(ConstantFolding, self).__init__()
        self.reevaluate = reevaluate

    def _calculate_const(self, node):
        if (not self.reevaluate and
                node.constant_result is not ExprNodes.constant_value_not_set):
            return

        # make sure we always set the value
        not_a_constant = ExprNodes.not_a_constant
        node.constant_result = not_a_constant

        # check if all children are constant
        children = self.visitchildren(node)
        for child_result in children.values():
            if type(child_result) is list:
                for child in child_result:
                    if getattr(child, 'constant_result', not_a_constant) is not_a_constant:
                        return
            elif getattr(child_result, 'constant_result', not_a_constant) is not_a_constant:
                return

        # now try to calculate the real constant value
        try:
            node.calculate_constant_result()
#            if node.constant_result is not ExprNodes.not_a_constant:
#                print node.__class__.__name__, node.constant_result
        except (ValueError, TypeError, KeyError, IndexError, AttributeError, ArithmeticError):
            # ignore all 'normal' errors here => no constant result
            pass
        except Exception:
            # this looks like a real error
            import traceback, sys
            traceback.print_exc(file=sys.stdout)

    NODE_TYPE_ORDER = [ExprNodes.BoolNode, ExprNodes.CharNode,
                       ExprNodes.IntNode, ExprNodes.FloatNode]

    def _widest_node_class(self, *nodes):
        try:
            return self.NODE_TYPE_ORDER[
                max(map(self.NODE_TYPE_ORDER.index, map(type, nodes)))]
        except ValueError:
            return None

    def _bool_node(self, node, value):
        value = bool(value)
        return ExprNodes.BoolNode(node.pos, value=value, constant_result=value)

    def visit_ExprNode(self, node):
        self._calculate_const(node)
        return node

    def visit_UnopNode(self, node):
        self._calculate_const(node)
        if not node.has_constant_result():
            if node.operator == '!':
                return self._handle_NotNode(node)
            return node
        if not node.operand.is_literal:
            return node
        if node.operator == '!':
            return self._bool_node(node, node.constant_result)
        elif isinstance(node.operand, ExprNodes.BoolNode):
            return ExprNodes.IntNode(node.pos, value=str(int(node.constant_result)),
                                     type=PyrexTypes.c_int_type,
                                     constant_result=int(node.constant_result))
        elif node.operator == '+':
            return self._handle_UnaryPlusNode(node)
        elif node.operator == '-':
            return self._handle_UnaryMinusNode(node)
        return node

    _negate_operator = {
        'in': 'not_in',
        'not_in': 'in',
        'is': 'is_not',
        'is_not': 'is'
    }.get

    def _handle_NotNode(self, node):
        operand = node.operand
        if isinstance(operand, ExprNodes.PrimaryCmpNode):
            operator = self._negate_operator(operand.operator)
            if operator:
                node = copy.copy(operand)
                node.operator = operator
                node = self.visit_PrimaryCmpNode(node)
        return node

    def _handle_UnaryMinusNode(self, node):
        def _negate(value):
            if value.startswith('-'):
                value = value[1:]
            else:
                value = '-' + value
            return value

        node_type = node.operand.type
        if isinstance(node.operand, ExprNodes.FloatNode):
            # this is a safe operation
            return ExprNodes.FloatNode(node.pos, value=_negate(node.operand.value),
                                       type=node_type,
                                       constant_result=node.constant_result)
        if node_type.is_int and node_type.signed or \
                isinstance(node.operand, ExprNodes.IntNode) and node_type.is_pyobject:
            return ExprNodes.IntNode(node.pos, value=_negate(node.operand.value),
                                     type=node_type,
                                     longness=node.operand.longness,
                                     constant_result=node.constant_result)
        return node

    def _handle_UnaryPlusNode(self, node):
        if (node.operand.has_constant_result() and
                    node.constant_result == node.operand.constant_result):
            return node.operand
        return node

    def visit_BoolBinopNode(self, node):
        self._calculate_const(node)
        if not node.operand1.has_constant_result():
            return node
        if node.operand1.constant_result:
            if node.operator == 'and':
                return node.operand2
            else:
                return node.operand1
        else:
            if node.operator == 'and':
                return node.operand1
            else:
                return node.operand2

    def visit_BinopNode(self, node):
        self._calculate_const(node)
        if node.constant_result is ExprNodes.not_a_constant:
            return node
        if isinstance(node.constant_result, float):
            return node
        operand1, operand2 = node.operand1, node.operand2
        if not operand1.is_literal or not operand2.is_literal:
            return node

        # now inject a new constant node with the calculated value
        try:
            type1, type2 = operand1.type, operand2.type
            if type1 is None or type2 is None:
                return node
        except AttributeError:
            return node

        if type1.is_numeric and type2.is_numeric:
            widest_type = PyrexTypes.widest_numeric_type(type1, type2)
        else:
            widest_type = PyrexTypes.py_object_type

        target_class = self._widest_node_class(operand1, operand2)
        if target_class is None:
            return node
        elif target_class is ExprNodes.BoolNode and node.operator in '+-//<<%**>>':
            # C arithmetic results in at least an int type
            target_class = ExprNodes.IntNode
        elif target_class is ExprNodes.CharNode and node.operator in '+-//<<%**>>&|^':
            # C arithmetic results in at least an int type
            target_class = ExprNodes.IntNode

        if target_class is ExprNodes.IntNode:
            unsigned = getattr(operand1, 'unsigned', '') and \
                       getattr(operand2, 'unsigned', '')
            longness = "LL"[:max(len(getattr(operand1, 'longness', '')),
                                 len(getattr(operand2, 'longness', '')))]
            new_node = ExprNodes.IntNode(pos=node.pos,
                                         unsigned=unsigned, longness=longness,
                                         value=str(int(node.constant_result)),
                                         constant_result=int(node.constant_result))
            # IntNode is smart about the type it chooses, so we just
            # make sure we were not smarter this time
            if widest_type.is_pyobject or new_node.type.is_pyobject:
                new_node.type = PyrexTypes.py_object_type
            else:
                new_node.type = PyrexTypes.widest_numeric_type(widest_type, new_node.type)
        else:
            if target_class is ExprNodes.BoolNode:
                node_value = node.constant_result
            else:
                node_value = str(node.constant_result)
            new_node = target_class(pos=node.pos, type = widest_type,
                                    value = node_value,
                                    constant_result = node.constant_result)
        return new_node

    def visit_MulNode(self, node):
        self._calculate_const(node)
        if node.operand1.is_sequence_constructor:
            return self._calculate_constant_seq(node, node.operand1, node.operand2)
        if isinstance(node.operand1, ExprNodes.IntNode) and \
                node.operand2.is_sequence_constructor:
            return self._calculate_constant_seq(node, node.operand2, node.operand1)
        return self.visit_BinopNode(node)

    def _calculate_constant_seq(self, node, sequence_node, factor):
        if factor.constant_result != 1 and sequence_node.args:
            if isinstance(factor.constant_result, (int, long)) and factor.constant_result <= 0:
                del sequence_node.args[:]
                sequence_node.mult_factor = None
            elif sequence_node.mult_factor is not None:
                if (isinstance(factor.constant_result, (int, long)) and
                        isinstance(sequence_node.mult_factor.constant_result, (int, long))):
                    value = sequence_node.mult_factor.constant_result * factor.constant_result
                    sequence_node.mult_factor = ExprNodes.IntNode(
                        sequence_node.mult_factor.pos,
                        value=str(value), constant_result=value)
                else:
                    # don't know if we can combine the factors, so don't
                    return self.visit_BinopNode(node)
            else:
                sequence_node.mult_factor = factor
        return sequence_node

    def visit_PrimaryCmpNode(self, node):
        # calculate constant partial results in the comparison cascade
        self.visitchildren(node, ['operand1'])
        left_node = node.operand1
        cmp_node = node
        while cmp_node is not None:
            self.visitchildren(cmp_node, ['operand2'])
            right_node = cmp_node.operand2
            cmp_node.constant_result = not_a_constant
            if left_node.has_constant_result() and right_node.has_constant_result():
                try:
                    cmp_node.calculate_cascaded_constant_result(left_node.constant_result)
                except (ValueError, TypeError, KeyError, IndexError, AttributeError, ArithmeticError):
                    pass  # ignore all 'normal' errors here => no constant result
            left_node = right_node
            cmp_node = cmp_node.cascade

        if not node.cascade:
            if node.has_constant_result():
                return self._bool_node(node, node.constant_result)
            return node

        # collect partial cascades: [[value, CmpNode...], [value, CmpNode, ...], ...]
        cascades = [[node.operand1]]
        final_false_result = []

        def split_cascades(cmp_node):
            if cmp_node.has_constant_result():
                if not cmp_node.constant_result:
                    # False => short-circuit
                    final_false_result.append(self._bool_node(cmp_node, False))
                    return
                else:
                    # True => discard and start new cascade
                    cascades.append([cmp_node.operand2])
            else:
                # not constant => append to current cascade
                cascades[-1].append(cmp_node)
            if cmp_node.cascade:
                split_cascades(cmp_node.cascade)

        split_cascades(node)

        cmp_nodes = []
        for cascade in cascades:
            if len(cascade) < 2:
                continue
            cmp_node = cascade[1]
            pcmp_node = ExprNodes.PrimaryCmpNode(
                cmp_node.pos,
                operand1=cascade[0],
                operator=cmp_node.operator,
                operand2=cmp_node.operand2,
                constant_result=not_a_constant)
            cmp_nodes.append(pcmp_node)

            last_cmp_node = pcmp_node
            for cmp_node in cascade[2:]:
                last_cmp_node.cascade = cmp_node
                last_cmp_node = cmp_node
            last_cmp_node.cascade = None

        if final_false_result:
            # last cascade was constant False
            cmp_nodes.append(final_false_result[0])
        elif not cmp_nodes:
            # only constants, but no False result
            return self._bool_node(node, True)
        node = cmp_nodes[0]
        if len(cmp_nodes) == 1:
            if node.has_constant_result():
                return self._bool_node(node, node.constant_result)
        else:
            for cmp_node in cmp_nodes[1:]:
                node = ExprNodes.BoolBinopNode(
                    node.pos,
                    operand1=node,
                    operator='and',
                    operand2=cmp_node,
                    constant_result=not_a_constant)
        return node

    def visit_CondExprNode(self, node):
        self._calculate_const(node)
        if not node.test.has_constant_result():
            return node
        if node.test.constant_result:
            return node.true_val
        else:
            return node.false_val

    def visit_IfStatNode(self, node):
        self.visitchildren(node)
        # eliminate dead code based on constant condition results
        if_clauses = []
        for if_clause in node.if_clauses:
            condition = if_clause.condition
            if condition.has_constant_result():
                if condition.constant_result:
                    # always true => subsequent clauses can safely be dropped
                    node.else_clause = if_clause.body
                    break
                # else: false => drop clause
            else:
                # unknown result => normal runtime evaluation
                if_clauses.append(if_clause)
        if if_clauses:
            node.if_clauses = if_clauses
            return node
        elif node.else_clause:
            return node.else_clause
        else:
            return Nodes.StatListNode(node.pos, stats=[])

    def visit_SliceIndexNode(self, node):
        self._calculate_const(node)
        # normalise start/stop values
        if node.start is None or node.start.constant_result is None:
            start = node.start = None
        else:
            start = node.start.constant_result
        if node.stop is None or node.stop.constant_result is None:
            stop = node.stop = None
        else:
            stop = node.stop.constant_result
        # cut down sliced constant sequences
        if node.constant_result is not not_a_constant:
            base = node.base
            if base.is_sequence_constructor and base.mult_factor is None:
                base.args = base.args[start:stop]
                return base
            elif base.is_string_literal:
                base = base.as_sliced_node(start, stop)
                if base is not None:
                    return base
        return node

    def visit_ComprehensionNode(self, node):
        self.visitchildren(node)
        if isinstance(node.loop, Nodes.StatListNode) and not node.loop.stats:
            # loop was pruned already => transform into literal
            if node.type is Builtin.list_type:
                return ExprNodes.ListNode(
                    node.pos, args=[], constant_result=[])
            elif node.type is Builtin.set_type:
                return ExprNodes.SetNode(
                    node.pos, args=[], constant_result=set())
            elif node.type is Builtin.dict_type:
                return ExprNodes.DictNode(
                    node.pos, key_value_pairs=[], constant_result={})
        return node

    def visit_ForInStatNode(self, node):
        self.visitchildren(node)
        sequence = node.iterator.sequence
        if isinstance(sequence, ExprNodes.SequenceNode):
            if not sequence.args:
                if node.else_clause:
                    return node.else_clause
                else:
                    # don't break list comprehensions
                    return Nodes.StatListNode(node.pos, stats=[])
            # iterating over a list literal? => tuples are more efficient
            if isinstance(sequence, ExprNodes.ListNode):
                node.iterator.sequence = sequence.as_tuple()
        return node

    def visit_WhileStatNode(self, node):
        self.visitchildren(node)
        if node.condition and node.condition.has_constant_result():
            if node.condition.constant_result:
                node.condition = None
                node.else_clause = None
            else:
                return node.else_clause
        return node

    def visit_ExprStatNode(self, node):
        self.visitchildren(node)
        if not isinstance(node.expr, ExprNodes.ExprNode):
            # ParallelRangeTransform does this ...
            return node
        # drop unused constant expressions
        if node.expr.has_constant_result():
            return None
        return node

    # in the future, other nodes can have their own handler method here
    # that can replace them with a constant result node

    visit_Node = Visitor.VisitorTransform.recurse_to_children


class FinalOptimizePhase(Visitor.CythonTransform):
    """
    This visitor handles several commuting optimizations, and is run
    just before the C code generation phase.

    The optimizations currently implemented in this class are:
        - eliminate None assignment and refcounting for first assignment.
        - isinstance -> typecheck for cdef types
        - eliminate checks for None and/or types that became redundant after tree changes
    """
    def visit_SingleAssignmentNode(self, node):
        """Avoid redundant initialisation of local variables before their
        first assignment.
        """
        self.visitchildren(node)
        if node.first:
            lhs = node.lhs
            lhs.lhs_of_first_assignment = True
        return node

    def visit_SimpleCallNode(self, node):
        """Replace generic calls to isinstance(x, type) by a more efficient
        type check.
        """
        self.visitchildren(node)
        if node.function.type.is_cfunction and isinstance(node.function, ExprNodes.NameNode):
            if node.function.name == 'isinstance' and len(node.args) == 2:
                type_arg = node.args[1]
                if type_arg.type.is_builtin_type and type_arg.type.name == 'type':
                    cython_scope = self.context.cython_scope
                    node.function.entry = cython_scope.lookup('PyObject_TypeCheck')
                    node.function.type = node.function.entry.type
                    PyTypeObjectPtr = PyrexTypes.CPtrType(cython_scope.lookup('PyTypeObject').type)
                    node.args[1] = ExprNodes.CastNode(node.args[1], PyTypeObjectPtr)
        return node

    def visit_PyTypeTestNode(self, node):
        """Remove tests for alternatively allowed None values from
        type tests when we know that the argument cannot be None
        anyway.
        """
        self.visitchildren(node)
        if not node.notnone:
            if not node.arg.may_be_none():
                node.notnone = True
        return node

    def visit_NoneCheckNode(self, node):
        """Remove None checks from expressions that definitely do not
        carry a None value.
        """
        self.visitchildren(node)
        if not node.arg.may_be_none():
            return node.arg
        return node

class ConsolidateOverflowCheck(Visitor.CythonTransform):
    """
    This class facilitates the sharing of overflow checking among all nodes
    of a nested arithmetic expression.  For example, given the expression
    a*b + c, where a, b, and x are all possibly overflowing ints, the entire
    sequence will be evaluated and the overflow bit checked only at the end.
    """
    overflow_bit_node = None
    
    def visit_Node(self, node):
        if self.overflow_bit_node is not None:
            saved = self.overflow_bit_node
            self.overflow_bit_node = None
            self.visitchildren(node)
            self.overflow_bit_node = saved
        else:
            self.visitchildren(node)
        return node
    
    def visit_NumBinopNode(self, node):
        if node.overflow_check and node.overflow_fold:
            top_level_overflow = self.overflow_bit_node is None
            if top_level_overflow:
                self.overflow_bit_node = node
            else:
                node.overflow_bit_node = self.overflow_bit_node
                node.overflow_check = False
            self.visitchildren(node)
            if top_level_overflow:
                self.overflow_bit_node = None
        else:
            self.visitchildren(node)
        return node
