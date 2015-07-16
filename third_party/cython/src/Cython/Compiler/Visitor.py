# cython: infer_types=True

#
#   Tree visitor and transform framework
#
import inspect

from Cython.Compiler import TypeSlots
from Cython.Compiler import Builtin
from Cython.Compiler import Nodes
from Cython.Compiler import ExprNodes
from Cython.Compiler import Errors
from Cython.Compiler import DebugFlags

import cython


class TreeVisitor(object):
    """
    Base class for writing visitors for a Cython tree, contains utilities for
    recursing such trees using visitors. Each node is
    expected to have a child_attrs iterable containing the names of attributes
    containing child nodes or lists of child nodes. Lists are not considered
    part of the tree structure (i.e. contained nodes are considered direct
    children of the parent node).

    visit_children visits each of the children of a given node (see the visit_children
    documentation). When recursing the tree using visit_children, an attribute
    access_path is maintained which gives information about the current location
    in the tree as a stack of tuples: (parent_node, attrname, index), representing
    the node, attribute and optional list index that was taken in each step in the path to
    the current node.

    Example:

    >>> class SampleNode(object):
    ...     child_attrs = ["head", "body"]
    ...     def __init__(self, value, head=None, body=None):
    ...         self.value = value
    ...         self.head = head
    ...         self.body = body
    ...     def __repr__(self): return "SampleNode(%s)" % self.value
    ...
    >>> tree = SampleNode(0, SampleNode(1), [SampleNode(2), SampleNode(3)])
    >>> class MyVisitor(TreeVisitor):
    ...     def visit_SampleNode(self, node):
    ...         print "in", node.value, self.access_path
    ...         self.visitchildren(node)
    ...         print "out", node.value
    ...
    >>> MyVisitor().visit(tree)
    in 0 []
    in 1 [(SampleNode(0), 'head', None)]
    out 1
    in 2 [(SampleNode(0), 'body', 0)]
    out 2
    in 3 [(SampleNode(0), 'body', 1)]
    out 3
    out 0
    """
    def __init__(self):
        super(TreeVisitor, self).__init__()
        self.dispatch_table = {}
        self.access_path = []

    def dump_node(self, node, indent=0):
        ignored = list(node.child_attrs or []) + [u'child_attrs', u'pos',
                                            u'gil_message', u'cpp_message',
                                            u'subexprs']
        values = []
        pos = getattr(node, 'pos', None)
        if pos:
            source = pos[0]
            if source:
                import os.path
                source = os.path.basename(source.get_description())
            values.append(u'%s:%s:%s' % (source, pos[1], pos[2]))
        attribute_names = dir(node)
        attribute_names.sort()
        for attr in attribute_names:
            if attr in ignored:
                continue
            if attr.startswith(u'_') or attr.endswith(u'_'):
                continue
            try:
                value = getattr(node, attr)
            except AttributeError:
                continue
            if value is None or value == 0:
                continue
            elif isinstance(value, list):
                value = u'[...]/%d' % len(value)
            elif not isinstance(value, (str, unicode, long, int, float)):
                continue
            else:
                value = repr(value)
            values.append(u'%s = %s' % (attr, value))
        return u'%s(%s)' % (node.__class__.__name__,
                           u',\n    '.join(values))

    def _find_node_path(self, stacktrace):
        import os.path
        last_traceback = stacktrace
        nodes = []
        while hasattr(stacktrace, 'tb_frame'):
            frame = stacktrace.tb_frame
            node = frame.f_locals.get(u'self')
            if isinstance(node, Nodes.Node):
                code = frame.f_code
                method_name = code.co_name
                pos = (os.path.basename(code.co_filename),
                       frame.f_lineno)
                nodes.append((node, method_name, pos))
                last_traceback = stacktrace
            stacktrace = stacktrace.tb_next
        return (last_traceback, nodes)

    def _raise_compiler_error(self, child, e):
        import sys
        trace = ['']
        for parent, attribute, index in self.access_path:
            node = getattr(parent, attribute)
            if index is None:
                index = ''
            else:
                node = node[index]
                index = u'[%d]' % index
            trace.append(u'%s.%s%s = %s' % (
                parent.__class__.__name__, attribute, index,
                self.dump_node(node)))
        stacktrace, called_nodes = self._find_node_path(sys.exc_info()[2])
        last_node = child
        for node, method_name, pos in called_nodes:
            last_node = node
            trace.append(u"File '%s', line %d, in %s: %s" % (
                pos[0], pos[1], method_name, self.dump_node(node)))
        raise Errors.CompilerCrash(
            getattr(last_node, 'pos', None), self.__class__.__name__,
            u'\n'.join(trace), e, stacktrace)

    @cython.final
    def find_handler(self, obj):
        # to resolve, try entire hierarchy
        cls = type(obj)
        pattern = "visit_%s"
        mro = inspect.getmro(cls)
        handler_method = None
        for mro_cls in mro:
            handler_method = getattr(self, pattern % mro_cls.__name__, None)
            if handler_method is not None:
                return handler_method
        print type(self), cls
        if self.access_path:
            print self.access_path
            print self.access_path[-1][0].pos
            print self.access_path[-1][0].__dict__
        raise RuntimeError("Visitor %r does not accept object: %s" % (self, obj))

    def visit(self, obj):
        return self._visit(obj)

    @cython.final
    def _visit(self, obj):
        try:
            try:
                handler_method = self.dispatch_table[type(obj)]
            except KeyError:
                handler_method = self.find_handler(obj)
                self.dispatch_table[type(obj)] = handler_method
            return handler_method(obj)
        except Errors.CompileError:
            raise
        except Errors.AbortError:
            raise
        except Exception, e:
            if DebugFlags.debug_no_exception_intercept:
                raise
            self._raise_compiler_error(obj, e)

    @cython.final
    def _visitchild(self, child, parent, attrname, idx):
        self.access_path.append((parent, attrname, idx))
        result = self._visit(child)
        self.access_path.pop()
        return result

    def visitchildren(self, parent, attrs=None):
        return self._visitchildren(parent, attrs)

    @cython.final
    @cython.locals(idx=int)
    def _visitchildren(self, parent, attrs):
        """
        Visits the children of the given parent. If parent is None, returns
        immediately (returning None).

        The return value is a dictionary giving the results for each
        child (mapping the attribute name to either the return value
        or a list of return values (in the case of multiple children
        in an attribute)).
        """
        if parent is None: return None
        result = {}
        for attr in parent.child_attrs:
            if attrs is not None and attr not in attrs: continue
            child = getattr(parent, attr)
            if child is not None:
                if type(child) is list:
                    childretval = [self._visitchild(x, parent, attr, idx) for idx, x in enumerate(child)]
                else:
                    childretval = self._visitchild(child, parent, attr, None)
                    assert not isinstance(childretval, list), 'Cannot insert list here: %s in %r' % (attr, parent)
                result[attr] = childretval
        return result


class VisitorTransform(TreeVisitor):
    """
    A tree transform is a base class for visitors that wants to do stream
    processing of the structure (rather than attributes etc.) of a tree.

    It implements __call__ to simply visit the argument node.

    It requires the visitor methods to return the nodes which should take
    the place of the visited node in the result tree (which can be the same
    or one or more replacement). Specifically, if the return value from
    a visitor method is:

    - [] or None; the visited node will be removed (set to None if an attribute and
    removed if in a list)
    - A single node; the visited node will be replaced by the returned node.
    - A list of nodes; the visited nodes will be replaced by all the nodes in the
    list. This will only work if the node was already a member of a list; if it
    was not, an exception will be raised. (Typically you want to ensure that you
    are within a StatListNode or similar before doing this.)
    """
    def visitchildren(self, parent, attrs=None):
        result = self._visitchildren(parent, attrs)
        for attr, newnode in result.iteritems():
            if type(newnode) is not list:
                setattr(parent, attr, newnode)
            else:
                # Flatten the list one level and remove any None
                newlist = []
                for x in newnode:
                    if x is not None:
                        if type(x) is list:
                            newlist += x
                        else:
                            newlist.append(x)
                setattr(parent, attr, newlist)
        return result

    def recurse_to_children(self, node):
        self.visitchildren(node)
        return node

    def __call__(self, root):
        return self._visit(root)

class CythonTransform(VisitorTransform):
    """
    Certain common conventions and utilities for Cython transforms.

     - Sets up the context of the pipeline in self.context
     - Tracks directives in effect in self.current_directives
    """
    def __init__(self, context):
        super(CythonTransform, self).__init__()
        self.context = context

    def __call__(self, node):
        import ModuleNode
        if isinstance(node, ModuleNode.ModuleNode):
            self.current_directives = node.directives
        return super(CythonTransform, self).__call__(node)

    def visit_CompilerDirectivesNode(self, node):
        old = self.current_directives
        self.current_directives = node.directives
        self.visitchildren(node)
        self.current_directives = old
        return node

    def visit_Node(self, node):
        self.visitchildren(node)
        return node

class ScopeTrackingTransform(CythonTransform):
    # Keeps track of type of scopes
    #scope_type: can be either of 'module', 'function', 'cclass', 'pyclass', 'struct'
    #scope_node: the node that owns the current scope

    def visit_ModuleNode(self, node):
        self.scope_type = 'module'
        self.scope_node = node
        self.visitchildren(node)
        return node

    def visit_scope(self, node, scope_type):
        prev = self.scope_type, self.scope_node
        self.scope_type = scope_type
        self.scope_node = node
        self.visitchildren(node)
        self.scope_type, self.scope_node = prev
        return node

    def visit_CClassDefNode(self, node):
        return self.visit_scope(node, 'cclass')

    def visit_PyClassDefNode(self, node):
        return self.visit_scope(node, 'pyclass')

    def visit_FuncDefNode(self, node):
        return self.visit_scope(node, 'function')

    def visit_CStructOrUnionDefNode(self, node):
        return self.visit_scope(node, 'struct')


class EnvTransform(CythonTransform):
    """
    This transformation keeps a stack of the environments.
    """
    def __call__(self, root):
        self.env_stack = []
        self.enter_scope(root, root.scope)
        return super(EnvTransform, self).__call__(root)

    def current_env(self):
        return self.env_stack[-1][1]

    def current_scope_node(self):
        return self.env_stack[-1][0]

    def global_scope(self):
        return self.current_env().global_scope()

    def enter_scope(self, node, scope):
        self.env_stack.append((node, scope))

    def exit_scope(self):
        self.env_stack.pop()

    def visit_FuncDefNode(self, node):
        self.enter_scope(node, node.local_scope)
        self.visitchildren(node)
        self.exit_scope()
        return node

    def visit_GeneratorBodyDefNode(self, node):
        self.visitchildren(node)
        return node

    def visit_ClassDefNode(self, node):
        self.enter_scope(node, node.scope)
        self.visitchildren(node)
        self.exit_scope()
        return node

    def visit_CStructOrUnionDefNode(self, node):
        self.enter_scope(node, node.scope)
        self.visitchildren(node)
        self.exit_scope()
        return node

    def visit_ScopedExprNode(self, node):
        if node.expr_scope:
            self.enter_scope(node, node.expr_scope)
            self.visitchildren(node)
            self.exit_scope()
        else:
            self.visitchildren(node)
        return node

    def visit_CArgDeclNode(self, node):
        # default arguments are evaluated in the outer scope
        if node.default:
            attrs = [ attr for attr in node.child_attrs if attr != 'default' ]
            self.visitchildren(node, attrs)
            self.enter_scope(node, self.current_env().outer_scope)
            self.visitchildren(node, ('default',))
            self.exit_scope()
        else:
            self.visitchildren(node)
        return node


class NodeRefCleanupMixin(object):
    """
    Clean up references to nodes that were replaced.

    NOTE: this implementation assumes that the replacement is
    done first, before hitting any further references during
    normal tree traversal.  This needs to be arranged by calling
    "self.visitchildren()" at a proper place in the transform
    and by ordering the "child_attrs" of nodes appropriately.
    """
    def __init__(self, *args):
        super(NodeRefCleanupMixin, self).__init__(*args)
        self._replacements = {}

    def visit_CloneNode(self, node):
        arg = node.arg
        if arg not in self._replacements:
            self.visitchildren(node)
            arg = node.arg
        node.arg = self._replacements.get(arg, arg)
        return node

    def visit_ResultRefNode(self, node):
        expr = node.expression
        if expr is None or expr not in self._replacements:
            self.visitchildren(node)
            expr = node.expression
        if expr is not None:
            node.expression = self._replacements.get(expr, expr)
        return node

    def replace(self, node, replacement):
        self._replacements[node] = replacement
        return replacement


find_special_method_for_binary_operator = {
    '<':  '__lt__',
    '<=': '__le__',
    '==': '__eq__',
    '!=': '__ne__',
    '>=': '__ge__',
    '>':  '__gt__',
    '+':  '__add__',
    '&':  '__and__',
    '/':  '__truediv__',
    '//': '__floordiv__',
    '<<': '__lshift__',
    '%':  '__mod__',
    '*':  '__mul__',
    '|':  '__or__',
    '**': '__pow__',
    '>>': '__rshift__',
    '-':  '__sub__',
    '^':  '__xor__',
    'in': '__contains__',
}.get


find_special_method_for_unary_operator = {
    'not': '__not__',
    '~':   '__inv__',
    '-':   '__neg__',
    '+':   '__pos__',
}.get


class MethodDispatcherTransform(EnvTransform):
    """
    Base class for transformations that want to intercept on specific
    builtin functions or methods of builtin types, including special
    methods triggered by Python operators.  Must run after declaration
    analysis when entries were assigned.

    Naming pattern for handler methods is as follows:

    * builtin functions: _handle_(general|simple|any)_function_NAME

    * builtin methods: _handle_(general|simple|any)_method_TYPENAME_METHODNAME
    """
    # only visit call nodes and Python operations
    def visit_GeneralCallNode(self, node):
        self.visitchildren(node)
        function = node.function
        if not function.type.is_pyobject:
            return node
        arg_tuple = node.positional_args
        if not isinstance(arg_tuple, ExprNodes.TupleNode):
            return node
        keyword_args = node.keyword_args
        if keyword_args and not isinstance(keyword_args, ExprNodes.DictNode):
            # can't handle **kwargs
            return node
        args = arg_tuple.args
        return self._dispatch_to_handler(node, function, args, keyword_args)

    def visit_SimpleCallNode(self, node):
        self.visitchildren(node)
        function = node.function
        if function.type.is_pyobject:
            arg_tuple = node.arg_tuple
            if not isinstance(arg_tuple, ExprNodes.TupleNode):
                return node
            args = arg_tuple.args
        else:
            args = node.args
        return self._dispatch_to_handler(node, function, args, None)

    def visit_PrimaryCmpNode(self, node):
        if node.cascade:
            # not currently handled below
            self.visitchildren(node)
            return node
        return self._visit_binop_node(node)

    def visit_BinopNode(self, node):
        return self._visit_binop_node(node)

    def _visit_binop_node(self, node):
        self.visitchildren(node)
        # FIXME: could special case 'not_in'
        special_method_name = find_special_method_for_binary_operator(node.operator)
        if special_method_name:
            operand1, operand2 = node.operand1, node.operand2
            if special_method_name == '__contains__':
                operand1, operand2 = operand2, operand1
            obj_type = operand1.type
            if obj_type.is_builtin_type:
                type_name = obj_type.name
            else:
                type_name = "object"  # safety measure
            node = self._dispatch_to_method_handler(
                special_method_name, None, False, type_name,
                node, None, [operand1, operand2], None)
        return node

    def visit_UnopNode(self, node):
        self.visitchildren(node)
        special_method_name = find_special_method_for_unary_operator(node.operator)
        if special_method_name:
            operand = node.operand
            obj_type = operand.type
            if obj_type.is_builtin_type:
                type_name = obj_type.name
            else:
                type_name = "object"  # safety measure
            node = self._dispatch_to_method_handler(
                special_method_name, None, False, type_name,
                node, None, [operand], None)
        return node

    ### dispatch to specific handlers

    def _find_handler(self, match_name, has_kwargs):
        call_type = has_kwargs and 'general' or 'simple'
        handler = getattr(self, '_handle_%s_%s' % (call_type, match_name), None)
        if handler is None:
            handler = getattr(self, '_handle_any_%s' % match_name, None)
        return handler

    def _delegate_to_assigned_value(self, node, function, arg_list, kwargs):
        assignment = function.cf_state[0]
        value = assignment.rhs
        if value.is_name:
            if not value.entry or len(value.entry.cf_assignments) > 1:
                # the variable might have been reassigned => play safe
                return node
        elif value.is_attribute and value.obj.is_name:
            if not value.obj.entry or len(value.obj.entry.cf_assignments) > 1:
                # the underlying variable might have been reassigned => play safe
                return node
        else:
            return node
        return self._dispatch_to_handler(
            node, value, arg_list, kwargs)

    def _dispatch_to_handler(self, node, function, arg_list, kwargs):
        if function.is_name:
            # we only consider functions that are either builtin
            # Python functions or builtins that were already replaced
            # into a C function call (defined in the builtin scope)
            if not function.entry:
                return node
            is_builtin = (
                function.entry.is_builtin or
                function.entry is self.current_env().builtin_scope().lookup_here(function.name))
            if not is_builtin:
                if function.cf_state and function.cf_state.is_single:
                    # we know the value of the variable
                    # => see if it's usable instead
                    return self._delegate_to_assigned_value(
                        node, function, arg_list, kwargs)
                return node
            function_handler = self._find_handler(
                "function_%s" % function.name, kwargs)
            if function_handler is None:
                return self._handle_function(node, function.name, function, arg_list, kwargs)
            if kwargs:
                return function_handler(node, function, arg_list, kwargs)
            else:
                return function_handler(node, function, arg_list)
        elif function.is_attribute and function.type.is_pyobject:
            attr_name = function.attribute
            self_arg = function.obj
            obj_type = self_arg.type
            is_unbound_method = False
            if obj_type.is_builtin_type:
                if (obj_type is Builtin.type_type and self_arg.is_name and
                        arg_list and arg_list[0].type.is_pyobject):
                    # calling an unbound method like 'list.append(L,x)'
                    # (ignoring 'type.mro()' here ...)
                    type_name = self_arg.name
                    self_arg = None
                    is_unbound_method = True
                else:
                    type_name = obj_type.name
            else:
                type_name = "object"  # safety measure
            return self._dispatch_to_method_handler(
                attr_name, self_arg, is_unbound_method, type_name,
                node, function, arg_list, kwargs)
        else:
            return node

    def _dispatch_to_method_handler(self, attr_name, self_arg,
                                    is_unbound_method, type_name,
                                    node, function, arg_list, kwargs):
        method_handler = self._find_handler(
            "method_%s_%s" % (type_name, attr_name), kwargs)
        if method_handler is None:
            if (attr_name in TypeSlots.method_name_to_slot
                    or attr_name == '__new__'):
                method_handler = self._find_handler(
                    "slot%s" % attr_name, kwargs)
            if method_handler is None:
                return self._handle_method(
                    node, type_name, attr_name, function,
                    arg_list, is_unbound_method, kwargs)
        if self_arg is not None:
            arg_list = [self_arg] + list(arg_list)
        if kwargs:
            return method_handler(
                node, function, arg_list, is_unbound_method, kwargs)
        else:
            return method_handler(
                node, function, arg_list, is_unbound_method)

    def _handle_function(self, node, function_name, function, arg_list, kwargs):
        """Fallback handler"""
        return node

    def _handle_method(self, node, type_name, attr_name, function,
                       arg_list, is_unbound_method, kwargs):
        """Fallback handler"""
        return node


class RecursiveNodeReplacer(VisitorTransform):
    """
    Recursively replace all occurrences of a node in a subtree by
    another node.
    """
    def __init__(self, orig_node, new_node):
        super(RecursiveNodeReplacer, self).__init__()
        self.orig_node, self.new_node = orig_node, new_node

    def visit_Node(self, node):
        self.visitchildren(node)
        if node is self.orig_node:
            return self.new_node
        else:
            return node

def recursively_replace_node(tree, old_node, new_node):
    replace_in = RecursiveNodeReplacer(old_node, new_node)
    replace_in(tree)


class NodeFinder(TreeVisitor):
    """
    Find out if a node appears in a subtree.
    """
    def __init__(self, node):
        super(NodeFinder, self).__init__()
        self.node = node
        self.found = False

    def visit_Node(self, node):
        if self.found:
            pass  # short-circuit
        elif node is self.node:
            self.found = True
        else:
            self._visitchildren(node, None)

def tree_contains(tree, node):
    finder = NodeFinder(node)
    finder.visit(tree)
    return finder.found


# Utils
def replace_node(ptr, value):
    """Replaces a node. ptr is of the form used on the access path stack
    (parent, attrname, listidx|None)
    """
    parent, attrname, listidx = ptr
    if listidx is None:
        setattr(parent, attrname, value)
    else:
        getattr(parent, attrname)[listidx] = value

class PrintTree(TreeVisitor):
    """Prints a representation of the tree to standard output.
    Subclass and override repr_of to provide more information
    about nodes. """
    def __init__(self):
        TreeVisitor.__init__(self)
        self._indent = ""

    def indent(self):
        self._indent += "  "
    def unindent(self):
        self._indent = self._indent[:-2]

    def __call__(self, tree, phase=None):
        print("Parse tree dump at phase '%s'" % phase)
        self.visit(tree)
        return tree

    # Don't do anything about process_list, the defaults gives
    # nice-looking name[idx] nodes which will visually appear
    # under the parent-node, not displaying the list itself in
    # the hierarchy.
    def visit_Node(self, node):
        if len(self.access_path) == 0:
            name = "(root)"
        else:
            parent, attr, idx = self.access_path[-1]
            if idx is not None:
                name = "%s[%d]" % (attr, idx)
            else:
                name = attr
        print("%s- %s: %s" % (self._indent, name, self.repr_of(node)))
        self.indent()
        self.visitchildren(node)
        self.unindent()
        return node

    def repr_of(self, node):
        if node is None:
            return "(none)"
        else:
            result = node.__class__.__name__
            if isinstance(node, ExprNodes.NameNode):
                result += "(type=%s, name=\"%s\")" % (repr(node.type), node.name)
            elif isinstance(node, Nodes.DefNode):
                result += "(name=\"%s\")" % node.name
            elif isinstance(node, ExprNodes.ExprNode):
                t = node.type
                result += "(type=%s)" % repr(t)
            elif node.pos:
                pos = node.pos
                path = pos[0].get_description()
                if '/' in path:
                    path = path.split('/')[-1]
                if '\\' in path:
                    path = path.split('\\')[-1]
                result += "(pos=(%s:%s:%s))" % (path, pos[1], pos[2])

            return result

if __name__ == "__main__":
    import doctest
    doctest.testmod()
