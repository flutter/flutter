import cython
cython.declare(PyrexTypes=object, Naming=object, ExprNodes=object, Nodes=object,
               Options=object, UtilNodes=object, LetNode=object,
               LetRefNode=object, TreeFragment=object, EncodedString=object,
               error=object, warning=object, copy=object)

import PyrexTypes
import Naming
import ExprNodes
import Nodes
import Options
import Builtin

from Cython.Compiler.Visitor import VisitorTransform, TreeVisitor
from Cython.Compiler.Visitor import CythonTransform, EnvTransform, ScopeTrackingTransform
from Cython.Compiler.UtilNodes import LetNode, LetRefNode, ResultRefNode
from Cython.Compiler.TreeFragment import TreeFragment
from Cython.Compiler.StringEncoding import EncodedString
from Cython.Compiler.Errors import error, warning, CompileError, InternalError
from Cython.Compiler.Code import UtilityCode

import copy


class NameNodeCollector(TreeVisitor):
    """Collect all NameNodes of a (sub-)tree in the ``name_nodes``
    attribute.
    """
    def __init__(self):
        super(NameNodeCollector, self).__init__()
        self.name_nodes = []

    def visit_NameNode(self, node):
        self.name_nodes.append(node)

    def visit_Node(self, node):
        self._visitchildren(node, None)


class SkipDeclarations(object):
    """
    Variable and function declarations can often have a deep tree structure,
    and yet most transformations don't need to descend to this depth.

    Declaration nodes are removed after AnalyseDeclarationsTransform, so there
    is no need to use this for transformations after that point.
    """
    def visit_CTypeDefNode(self, node):
        return node

    def visit_CVarDefNode(self, node):
        return node

    def visit_CDeclaratorNode(self, node):
        return node

    def visit_CBaseTypeNode(self, node):
        return node

    def visit_CEnumDefNode(self, node):
        return node

    def visit_CStructOrUnionDefNode(self, node):
        return node

class NormalizeTree(CythonTransform):
    """
    This transform fixes up a few things after parsing
    in order to make the parse tree more suitable for
    transforms.

    a) After parsing, blocks with only one statement will
    be represented by that statement, not by a StatListNode.
    When doing transforms this is annoying and inconsistent,
    as one cannot in general remove a statement in a consistent
    way and so on. This transform wraps any single statements
    in a StatListNode containing a single statement.

    b) The PassStatNode is a noop and serves no purpose beyond
    plugging such one-statement blocks; i.e., once parsed a
`    "pass" can just as well be represented using an empty
    StatListNode. This means less special cases to worry about
    in subsequent transforms (one always checks to see if a
    StatListNode has no children to see if the block is empty).
    """

    def __init__(self, context):
        super(NormalizeTree, self).__init__(context)
        self.is_in_statlist = False
        self.is_in_expr = False

    def visit_ExprNode(self, node):
        stacktmp = self.is_in_expr
        self.is_in_expr = True
        self.visitchildren(node)
        self.is_in_expr = stacktmp
        return node

    def visit_StatNode(self, node, is_listcontainer=False):
        stacktmp = self.is_in_statlist
        self.is_in_statlist = is_listcontainer
        self.visitchildren(node)
        self.is_in_statlist = stacktmp
        if not self.is_in_statlist and not self.is_in_expr:
            return Nodes.StatListNode(pos=node.pos, stats=[node])
        else:
            return node

    def visit_StatListNode(self, node):
        self.is_in_statlist = True
        self.visitchildren(node)
        self.is_in_statlist = False
        return node

    def visit_ParallelAssignmentNode(self, node):
        return self.visit_StatNode(node, True)

    def visit_CEnumDefNode(self, node):
        return self.visit_StatNode(node, True)

    def visit_CStructOrUnionDefNode(self, node):
        return self.visit_StatNode(node, True)

    def visit_PassStatNode(self, node):
        """Eliminate PassStatNode"""
        if not self.is_in_statlist:
            return Nodes.StatListNode(pos=node.pos, stats=[])
        else:
            return []

    def visit_ExprStatNode(self, node):
        """Eliminate useless string literals"""
        if node.expr.is_string_literal:
            return self.visit_PassStatNode(node)
        else:
            return self.visit_StatNode(node)

    def visit_CDeclaratorNode(self, node):
        return node


class PostParseError(CompileError): pass

# error strings checked by unit tests, so define them
ERR_CDEF_INCLASS = 'Cannot assign default value to fields in cdef classes, structs or unions'
ERR_BUF_DEFAULTS = 'Invalid buffer defaults specification (see docs)'
ERR_INVALID_SPECIALATTR_TYPE = 'Special attributes must not have a type declared'
class PostParse(ScopeTrackingTransform):
    """
    Basic interpretation of the parse tree, as well as validity
    checking that can be done on a very basic level on the parse
    tree (while still not being a problem with the basic syntax,
    as such).

    Specifically:
    - Default values to cdef assignments are turned into single
    assignments following the declaration (everywhere but in class
    bodies, where they raise a compile error)

    - Interpret some node structures into Python runtime values.
    Some nodes take compile-time arguments (currently:
    TemplatedTypeNode[args] and __cythonbufferdefaults__ = {args}),
    which should be interpreted. This happens in a general way
    and other steps should be taken to ensure validity.

    Type arguments cannot be interpreted in this way.

    - For __cythonbufferdefaults__ the arguments are checked for
    validity.

    TemplatedTypeNode has its directives interpreted:
    Any first positional argument goes into the "dtype" attribute,
    any "ndim" keyword argument goes into the "ndim" attribute and
    so on. Also it is checked that the directive combination is valid.
    - __cythonbufferdefaults__ attributes are parsed and put into the
    type information.

    Note: Currently Parsing.py does a lot of interpretation and
    reorganization that can be refactored into this transform
    if a more pure Abstract Syntax Tree is wanted.
    """

    def __init__(self, context):
        super(PostParse, self).__init__(context)
        self.specialattribute_handlers = {
            '__cythonbufferdefaults__' : self.handle_bufferdefaults
        }

    def visit_ModuleNode(self, node):
        self.lambda_counter = 1
        self.genexpr_counter = 1
        return super(PostParse, self).visit_ModuleNode(node)

    def visit_LambdaNode(self, node):
        # unpack a lambda expression into the corresponding DefNode
        lambda_id = self.lambda_counter
        self.lambda_counter += 1
        node.lambda_name = EncodedString(u'lambda%d' % lambda_id)
        collector = YieldNodeCollector()
        collector.visitchildren(node.result_expr)
        if collector.yields or isinstance(node.result_expr, ExprNodes.YieldExprNode):
            body = Nodes.ExprStatNode(
                node.result_expr.pos, expr=node.result_expr)
        else:
            body = Nodes.ReturnStatNode(
                node.result_expr.pos, value=node.result_expr)
        node.def_node = Nodes.DefNode(
            node.pos, name=node.name, lambda_name=node.lambda_name,
            args=node.args, star_arg=node.star_arg,
            starstar_arg=node.starstar_arg,
            body=body, doc=None)
        self.visitchildren(node)
        return node

    def visit_GeneratorExpressionNode(self, node):
        # unpack a generator expression into the corresponding DefNode
        genexpr_id = self.genexpr_counter
        self.genexpr_counter += 1
        node.genexpr_name = EncodedString(u'genexpr%d' % genexpr_id)

        node.def_node = Nodes.DefNode(node.pos, name=node.name,
                                      doc=None,
                                      args=[], star_arg=None,
                                      starstar_arg=None,
                                      body=node.loop)
        self.visitchildren(node)
        return node

    # cdef variables
    def handle_bufferdefaults(self, decl):
        if not isinstance(decl.default, ExprNodes.DictNode):
            raise PostParseError(decl.pos, ERR_BUF_DEFAULTS)
        self.scope_node.buffer_defaults_node = decl.default
        self.scope_node.buffer_defaults_pos = decl.pos

    def visit_CVarDefNode(self, node):
        # This assumes only plain names and pointers are assignable on
        # declaration. Also, it makes use of the fact that a cdef decl
        # must appear before the first use, so we don't have to deal with
        # "i = 3; cdef int i = i" and can simply move the nodes around.
        try:
            self.visitchildren(node)
            stats = [node]
            newdecls = []
            for decl in node.declarators:
                declbase = decl
                while isinstance(declbase, Nodes.CPtrDeclaratorNode):
                    declbase = declbase.base
                if isinstance(declbase, Nodes.CNameDeclaratorNode):
                    if declbase.default is not None:
                        if self.scope_type in ('cclass', 'pyclass', 'struct'):
                            if isinstance(self.scope_node, Nodes.CClassDefNode):
                                handler = self.specialattribute_handlers.get(decl.name)
                                if handler:
                                    if decl is not declbase:
                                        raise PostParseError(decl.pos, ERR_INVALID_SPECIALATTR_TYPE)
                                    handler(decl)
                                    continue # Remove declaration
                            raise PostParseError(decl.pos, ERR_CDEF_INCLASS)
                        first_assignment = self.scope_type != 'module'
                        stats.append(Nodes.SingleAssignmentNode(node.pos,
                            lhs=ExprNodes.NameNode(node.pos, name=declbase.name),
                            rhs=declbase.default, first=first_assignment))
                        declbase.default = None
                newdecls.append(decl)
            node.declarators = newdecls
            return stats
        except PostParseError, e:
            # An error in a cdef clause is ok, simply remove the declaration
            # and try to move on to report more errors
            self.context.nonfatal_error(e)
            return None

    # Split parallel assignments (a,b = b,a) into separate partial
    # assignments that are executed rhs-first using temps.  This
    # restructuring must be applied before type analysis so that known
    # types on rhs and lhs can be matched directly.  It is required in
    # the case that the types cannot be coerced to a Python type in
    # order to assign from a tuple.

    def visit_SingleAssignmentNode(self, node):
        self.visitchildren(node)
        return self._visit_assignment_node(node, [node.lhs, node.rhs])

    def visit_CascadedAssignmentNode(self, node):
        self.visitchildren(node)
        return self._visit_assignment_node(node, node.lhs_list + [node.rhs])

    def _visit_assignment_node(self, node, expr_list):
        """Flatten parallel assignments into separate single
        assignments or cascaded assignments.
        """
        if sum([ 1 for expr in expr_list
                 if expr.is_sequence_constructor or expr.is_string_literal ]) < 2:
            # no parallel assignments => nothing to do
            return node

        expr_list_list = []
        flatten_parallel_assignments(expr_list, expr_list_list)
        temp_refs = []
        eliminate_rhs_duplicates(expr_list_list, temp_refs)

        nodes = []
        for expr_list in expr_list_list:
            lhs_list = expr_list[:-1]
            rhs = expr_list[-1]
            if len(lhs_list) == 1:
                node = Nodes.SingleAssignmentNode(rhs.pos,
                    lhs = lhs_list[0], rhs = rhs)
            else:
                node = Nodes.CascadedAssignmentNode(rhs.pos,
                    lhs_list = lhs_list, rhs = rhs)
            nodes.append(node)

        if len(nodes) == 1:
            assign_node = nodes[0]
        else:
            assign_node = Nodes.ParallelAssignmentNode(nodes[0].pos, stats = nodes)

        if temp_refs:
            duplicates_and_temps = [ (temp.expression, temp)
                                     for temp in temp_refs ]
            sort_common_subsequences(duplicates_and_temps)
            for _, temp_ref in duplicates_and_temps[::-1]:
                assign_node = LetNode(temp_ref, assign_node)

        return assign_node

    def _flatten_sequence(self, seq, result):
        for arg in seq.args:
            if arg.is_sequence_constructor:
                self._flatten_sequence(arg, result)
            else:
                result.append(arg)
        return result

    def visit_DelStatNode(self, node):
        self.visitchildren(node)
        node.args = self._flatten_sequence(node, [])
        return node

    def visit_ExceptClauseNode(self, node):
        if node.is_except_as:
            # except-as must delete NameNode target at the end
            del_target = Nodes.DelStatNode(
                node.pos,
                args=[ExprNodes.NameNode(
                    node.target.pos, name=node.target.name)],
                ignore_nonexisting=True)
            node.body = Nodes.StatListNode(
                node.pos,
                stats=[Nodes.TryFinallyStatNode(
                    node.pos,
                    body=node.body,
                    finally_clause=Nodes.StatListNode(
                        node.pos,
                        stats=[del_target]))])
        self.visitchildren(node)
        return node


def eliminate_rhs_duplicates(expr_list_list, ref_node_sequence):
    """Replace rhs items by LetRefNodes if they appear more than once.
    Creates a sequence of LetRefNodes that set up the required temps
    and appends them to ref_node_sequence.  The input list is modified
    in-place.
    """
    seen_nodes = set()
    ref_nodes = {}
    def find_duplicates(node):
        if node.is_literal or node.is_name:
            # no need to replace those; can't include attributes here
            # as their access is not necessarily side-effect free
            return
        if node in seen_nodes:
            if node not in ref_nodes:
                ref_node = LetRefNode(node)
                ref_nodes[node] = ref_node
                ref_node_sequence.append(ref_node)
        else:
            seen_nodes.add(node)
            if node.is_sequence_constructor:
                for item in node.args:
                    find_duplicates(item)

    for expr_list in expr_list_list:
        rhs = expr_list[-1]
        find_duplicates(rhs)
    if not ref_nodes:
        return

    def substitute_nodes(node):
        if node in ref_nodes:
            return ref_nodes[node]
        elif node.is_sequence_constructor:
            node.args = list(map(substitute_nodes, node.args))
        return node

    # replace nodes inside of the common subexpressions
    for node in ref_nodes:
        if node.is_sequence_constructor:
            node.args = list(map(substitute_nodes, node.args))

    # replace common subexpressions on all rhs items
    for expr_list in expr_list_list:
        expr_list[-1] = substitute_nodes(expr_list[-1])

def sort_common_subsequences(items):
    """Sort items/subsequences so that all items and subsequences that
    an item contains appear before the item itself.  This is needed
    because each rhs item must only be evaluated once, so its value
    must be evaluated first and then reused when packing sequences
    that contain it.

    This implies a partial order, and the sort must be stable to
    preserve the original order as much as possible, so we use a
    simple insertion sort (which is very fast for short sequences, the
    normal case in practice).
    """
    def contains(seq, x):
        for item in seq:
            if item is x:
                return True
            elif item.is_sequence_constructor and contains(item.args, x):
                return True
        return False
    def lower_than(a,b):
        return b.is_sequence_constructor and contains(b.args, a)

    for pos, item in enumerate(items):
        key = item[1] # the ResultRefNode which has already been injected into the sequences
        new_pos = pos
        for i in xrange(pos-1, -1, -1):
            if lower_than(key, items[i][0]):
                new_pos = i
        if new_pos != pos:
            for i in xrange(pos, new_pos, -1):
                items[i] = items[i-1]
            items[new_pos] = item

def unpack_string_to_character_literals(literal):
    chars = []
    pos = literal.pos
    stype = literal.__class__
    sval = literal.value
    sval_type = sval.__class__
    for char in sval:
        cval = sval_type(char)
        chars.append(stype(pos, value=cval, constant_result=cval))
    return chars

def flatten_parallel_assignments(input, output):
    #  The input is a list of expression nodes, representing the LHSs
    #  and RHS of one (possibly cascaded) assignment statement.  For
    #  sequence constructors, rearranges the matching parts of both
    #  sides into a list of equivalent assignments between the
    #  individual elements.  This transformation is applied
    #  recursively, so that nested structures get matched as well.
    rhs = input[-1]
    if (not (rhs.is_sequence_constructor or isinstance(rhs, ExprNodes.UnicodeNode))
        or not sum([lhs.is_sequence_constructor for lhs in input[:-1]])):
        output.append(input)
        return

    complete_assignments = []

    if rhs.is_sequence_constructor:
        rhs_args = rhs.args
    elif rhs.is_string_literal:
        rhs_args = unpack_string_to_character_literals(rhs)

    rhs_size = len(rhs_args)
    lhs_targets = [ [] for _ in xrange(rhs_size) ]
    starred_assignments = []
    for lhs in input[:-1]:
        if not lhs.is_sequence_constructor:
            if lhs.is_starred:
                error(lhs.pos, "starred assignment target must be in a list or tuple")
            complete_assignments.append(lhs)
            continue
        lhs_size = len(lhs.args)
        starred_targets = sum([1 for expr in lhs.args if expr.is_starred])
        if starred_targets > 1:
            error(lhs.pos, "more than 1 starred expression in assignment")
            output.append([lhs,rhs])
            continue
        elif lhs_size - starred_targets > rhs_size:
            error(lhs.pos, "need more than %d value%s to unpack"
                  % (rhs_size, (rhs_size != 1) and 's' or ''))
            output.append([lhs,rhs])
            continue
        elif starred_targets:
            map_starred_assignment(lhs_targets, starred_assignments,
                                   lhs.args, rhs_args)
        elif lhs_size < rhs_size:
            error(lhs.pos, "too many values to unpack (expected %d, got %d)"
                  % (lhs_size, rhs_size))
            output.append([lhs,rhs])
            continue
        else:
            for targets, expr in zip(lhs_targets, lhs.args):
                targets.append(expr)

    if complete_assignments:
        complete_assignments.append(rhs)
        output.append(complete_assignments)

    # recursively flatten partial assignments
    for cascade, rhs in zip(lhs_targets, rhs_args):
        if cascade:
            cascade.append(rhs)
            flatten_parallel_assignments(cascade, output)

    # recursively flatten starred assignments
    for cascade in starred_assignments:
        if cascade[0].is_sequence_constructor:
            flatten_parallel_assignments(cascade, output)
        else:
            output.append(cascade)

def map_starred_assignment(lhs_targets, starred_assignments, lhs_args, rhs_args):
    # Appends the fixed-position LHS targets to the target list that
    # appear left and right of the starred argument.
    #
    # The starred_assignments list receives a new tuple
    # (lhs_target, rhs_values_list) that maps the remaining arguments
    # (those that match the starred target) to a list.

    # left side of the starred target
    for i, (targets, expr) in enumerate(zip(lhs_targets, lhs_args)):
        if expr.is_starred:
            starred = i
            lhs_remaining = len(lhs_args) - i - 1
            break
        targets.append(expr)
    else:
        raise InternalError("no starred arg found when splitting starred assignment")

    # right side of the starred target
    for i, (targets, expr) in enumerate(zip(lhs_targets[-lhs_remaining:],
                                            lhs_args[starred + 1:])):
        targets.append(expr)

    # the starred target itself, must be assigned a (potentially empty) list
    target = lhs_args[starred].target # unpack starred node
    starred_rhs = rhs_args[starred:]
    if lhs_remaining:
        starred_rhs = starred_rhs[:-lhs_remaining]
    if starred_rhs:
        pos = starred_rhs[0].pos
    else:
        pos = target.pos
    starred_assignments.append([
        target, ExprNodes.ListNode(pos=pos, args=starred_rhs)])


class PxdPostParse(CythonTransform, SkipDeclarations):
    """
    Basic interpretation/validity checking that should only be
    done on pxd trees.

    A lot of this checking currently happens in the parser; but
    what is listed below happens here.

    - "def" functions are let through only if they fill the
    getbuffer/releasebuffer slots

    - cdef functions are let through only if they are on the
    top level and are declared "inline"
    """
    ERR_INLINE_ONLY = "function definition in pxd file must be declared 'cdef inline'"
    ERR_NOGO_WITH_INLINE = "inline function definition in pxd file cannot be '%s'"

    def __call__(self, node):
        self.scope_type = 'pxd'
        return super(PxdPostParse, self).__call__(node)

    def visit_CClassDefNode(self, node):
        old = self.scope_type
        self.scope_type = 'cclass'
        self.visitchildren(node)
        self.scope_type = old
        return node

    def visit_FuncDefNode(self, node):
        # FuncDefNode always come with an implementation (without
        # an imp they are CVarDefNodes..)
        err = self.ERR_INLINE_ONLY

        if (isinstance(node, Nodes.DefNode) and self.scope_type == 'cclass'
            and node.name in ('__getbuffer__', '__releasebuffer__')):
            err = None # allow these slots

        if isinstance(node, Nodes.CFuncDefNode):
            if (u'inline' in node.modifiers and
                self.scope_type in ('pxd', 'cclass')):
                node.inline_in_pxd = True
                if node.visibility != 'private':
                    err = self.ERR_NOGO_WITH_INLINE % node.visibility
                elif node.api:
                    err = self.ERR_NOGO_WITH_INLINE % 'api'
                else:
                    err = None # allow inline function
            else:
                err = self.ERR_INLINE_ONLY

        if err:
            self.context.nonfatal_error(PostParseError(node.pos, err))
            return None
        else:
            return node

class InterpretCompilerDirectives(CythonTransform, SkipDeclarations):
    """
    After parsing, directives can be stored in a number of places:
    - #cython-comments at the top of the file (stored in ModuleNode)
    - Command-line arguments overriding these
    - @cython.directivename decorators
    - with cython.directivename: statements

    This transform is responsible for interpreting these various sources
    and store the directive in two ways:
    - Set the directives attribute of the ModuleNode for global directives.
    - Use a CompilerDirectivesNode to override directives for a subtree.

    (The first one is primarily to not have to modify with the tree
    structure, so that ModuleNode stay on top.)

    The directives are stored in dictionaries from name to value in effect.
    Each such dictionary is always filled in for all possible directives,
    using default values where no value is given by the user.

    The available directives are controlled in Options.py.

    Note that we have to run this prior to analysis, and so some minor
    duplication of functionality has to occur: We manually track cimports
    and which names the "cython" module may have been imported to.
    """
    unop_method_nodes = {
        'typeof': ExprNodes.TypeofNode,

        'operator.address': ExprNodes.AmpersandNode,
        'operator.dereference': ExprNodes.DereferenceNode,
        'operator.preincrement' : ExprNodes.inc_dec_constructor(True, '++'),
        'operator.predecrement' : ExprNodes.inc_dec_constructor(True, '--'),
        'operator.postincrement': ExprNodes.inc_dec_constructor(False, '++'),
        'operator.postdecrement': ExprNodes.inc_dec_constructor(False, '--'),

        # For backwards compatability.
        'address': ExprNodes.AmpersandNode,
    }

    binop_method_nodes = {
        'operator.comma'        : ExprNodes.c_binop_constructor(','),
    }

    special_methods = set(['declare', 'union', 'struct', 'typedef',
                           'sizeof', 'cast', 'pointer', 'compiled',
                           'NULL', 'fused_type', 'parallel'])
    special_methods.update(unop_method_nodes.keys())

    valid_parallel_directives = set([
        "parallel",
        "prange",
        "threadid",
#        "threadsavailable",
    ])

    def __init__(self, context, compilation_directive_defaults):
        super(InterpretCompilerDirectives, self).__init__(context)
        self.compilation_directive_defaults = {}
        for key, value in compilation_directive_defaults.items():
            self.compilation_directive_defaults[unicode(key)] = copy.deepcopy(value)
        self.cython_module_names = set()
        self.directive_names = {}
        self.parallel_directives = {}

    def check_directive_scope(self, pos, directive, scope):
        legal_scopes = Options.directive_scopes.get(directive, None)
        if legal_scopes and scope not in legal_scopes:
            self.context.nonfatal_error(PostParseError(pos, 'The %s compiler directive '
                                        'is not allowed in %s scope' % (directive, scope)))
            return False
        else:
            if (directive not in Options.directive_defaults
                    and directive not in Options.directive_types):
                error(pos, "Invalid directive: '%s'." % (directive,))
            return True

    # Set up processing and handle the cython: comments.
    def visit_ModuleNode(self, node):
        for key, value in node.directive_comments.items():
            if not self.check_directive_scope(node.pos, key, 'module'):
                self.wrong_scope_error(node.pos, key, 'module')
                del node.directive_comments[key]

        self.module_scope = node.scope

        directives = copy.deepcopy(Options.directive_defaults)
        directives.update(copy.deepcopy(self.compilation_directive_defaults))
        directives.update(node.directive_comments)
        self.directives = directives
        node.directives = directives
        node.parallel_directives = self.parallel_directives
        self.visitchildren(node)
        node.cython_module_names = self.cython_module_names
        return node

    # The following four functions track imports and cimports that
    # begin with "cython"
    def is_cython_directive(self, name):
        return (name in Options.directive_types or
                name in self.special_methods or
                PyrexTypes.parse_basic_type(name))

    def is_parallel_directive(self, full_name, pos):
        """
        Checks to see if fullname (e.g. cython.parallel.prange) is a valid
        parallel directive. If it is a star import it also updates the
        parallel_directives.
        """
        result = (full_name + ".").startswith("cython.parallel.")

        if result:
            directive = full_name.split('.')
            if full_name == u"cython.parallel":
                self.parallel_directives[u"parallel"] = u"cython.parallel"
            elif full_name == u"cython.parallel.*":
                for name in self.valid_parallel_directives:
                    self.parallel_directives[name] = u"cython.parallel.%s" % name
            elif (len(directive) != 3 or
                  directive[-1] not in self.valid_parallel_directives):
                error(pos, "No such directive: %s" % full_name)

            self.module_scope.use_utility_code(
                UtilityCode.load_cached("InitThreads", "ModuleSetupCode.c"))

        return result

    def visit_CImportStatNode(self, node):
        if node.module_name == u"cython":
            self.cython_module_names.add(node.as_name or u"cython")
        elif node.module_name.startswith(u"cython."):
            if node.module_name.startswith(u"cython.parallel."):
                error(node.pos, node.module_name + " is not a module")
            if node.module_name == u"cython.parallel":
                if node.as_name and node.as_name != u"cython":
                    self.parallel_directives[node.as_name] = node.module_name
                else:
                    self.cython_module_names.add(u"cython")
                    self.parallel_directives[
                                    u"cython.parallel"] = node.module_name
                self.module_scope.use_utility_code(
                    UtilityCode.load_cached("InitThreads", "ModuleSetupCode.c"))
            elif node.as_name:
                self.directive_names[node.as_name] = node.module_name[7:]
            else:
                self.cython_module_names.add(u"cython")
            # if this cimport was a compiler directive, we don't
            # want to leave the cimport node sitting in the tree
            return None
        return node

    def visit_FromCImportStatNode(self, node):
        if (node.module_name == u"cython") or \
               node.module_name.startswith(u"cython."):
            submodule = (node.module_name + u".")[7:]
            newimp = []

            for pos, name, as_name, kind in node.imported_names:
                full_name = submodule + name
                qualified_name = u"cython." + full_name

                if self.is_parallel_directive(qualified_name, node.pos):
                    # from cython cimport parallel, or
                    # from cython.parallel cimport parallel, prange, ...
                    self.parallel_directives[as_name or name] = qualified_name
                elif self.is_cython_directive(full_name):
                    if as_name is None:
                        as_name = full_name

                    self.directive_names[as_name] = full_name
                    if kind is not None:
                        self.context.nonfatal_error(PostParseError(pos,
                            "Compiler directive imports must be plain imports"))
                else:
                    newimp.append((pos, name, as_name, kind))

            if not newimp:
                return None

            node.imported_names = newimp
        return node

    def visit_FromImportStatNode(self, node):
        if (node.module.module_name.value == u"cython") or \
               node.module.module_name.value.startswith(u"cython."):
            submodule = (node.module.module_name.value + u".")[7:]
            newimp = []
            for name, name_node in node.items:
                full_name = submodule + name
                qualified_name = u"cython." + full_name
                if self.is_parallel_directive(qualified_name, node.pos):
                    self.parallel_directives[name_node.name] = qualified_name
                elif self.is_cython_directive(full_name):
                    self.directive_names[name_node.name] = full_name
                else:
                    newimp.append((name, name_node))
            if not newimp:
                return None
            node.items = newimp
        return node

    def visit_SingleAssignmentNode(self, node):
        if isinstance(node.rhs, ExprNodes.ImportNode):
            module_name = node.rhs.module_name.value
            is_parallel = (module_name + u".").startswith(u"cython.parallel.")

            if module_name != u"cython" and not is_parallel:
                return node

            module_name = node.rhs.module_name.value
            as_name = node.lhs.name

            node = Nodes.CImportStatNode(node.pos,
                                         module_name = module_name,
                                         as_name = as_name)
            node = self.visit_CImportStatNode(node)
        else:
            self.visitchildren(node)

        return node

    def visit_NameNode(self, node):
        if node.name in self.cython_module_names:
            node.is_cython_module = True
        else:
            node.cython_attribute = self.directive_names.get(node.name)
        return node

    def try_to_parse_directives(self, node):
        # If node is the contents of an directive (in a with statement or
        # decorator), returns a list of (directivename, value) pairs.
        # Otherwise, returns None
        if isinstance(node, ExprNodes.CallNode):
            self.visit(node.function)
            optname = node.function.as_cython_attribute()
            if optname:
                directivetype = Options.directive_types.get(optname)
                if directivetype:
                    args, kwds = node.explicit_args_kwds()
                    directives = []
                    key_value_pairs = []
                    if kwds is not None and directivetype is not dict:
                        for keyvalue in kwds.key_value_pairs:
                            key, value = keyvalue
                            sub_optname = "%s.%s" % (optname, key.value)
                            if Options.directive_types.get(sub_optname):
                                directives.append(self.try_to_parse_directive(sub_optname, [value], None, keyvalue.pos))
                            else:
                                key_value_pairs.append(keyvalue)
                        if not key_value_pairs:
                            kwds = None
                        else:
                            kwds.key_value_pairs = key_value_pairs
                        if directives and not kwds and not args:
                            return directives
                    directives.append(self.try_to_parse_directive(optname, args, kwds, node.function.pos))
                    return directives
        elif isinstance(node, (ExprNodes.AttributeNode, ExprNodes.NameNode)):
            self.visit(node)
            optname = node.as_cython_attribute()
            if optname:
                directivetype = Options.directive_types.get(optname)
                if directivetype is bool:
                    return [(optname, True)]
                elif directivetype is None:
                    return [(optname, None)]
                else:
                    raise PostParseError(
                        node.pos, "The '%s' directive should be used as a function call." % optname)
        return None

    def try_to_parse_directive(self, optname, args, kwds, pos):
        directivetype = Options.directive_types.get(optname)
        if len(args) == 1 and isinstance(args[0], ExprNodes.NoneNode):
            return optname, Options.directive_defaults[optname]
        elif directivetype is bool:
            if kwds is not None or len(args) != 1 or not isinstance(args[0], ExprNodes.BoolNode):
                raise PostParseError(pos,
                    'The %s directive takes one compile-time boolean argument' % optname)
            return (optname, args[0].value)
        elif directivetype is int:
            if kwds is not None or len(args) != 1 or not isinstance(args[0], ExprNodes.IntNode):
                raise PostParseError(pos,
                    'The %s directive takes one compile-time integer argument' % optname)
            return (optname, int(args[0].value))
        elif directivetype is str:
            if kwds is not None or len(args) != 1 or not isinstance(
                    args[0], (ExprNodes.StringNode, ExprNodes.UnicodeNode)):
                raise PostParseError(pos,
                    'The %s directive takes one compile-time string argument' % optname)
            return (optname, str(args[0].value))
        elif directivetype is type:
            if kwds is not None or len(args) != 1:
                raise PostParseError(pos,
                    'The %s directive takes one type argument' % optname)
            return (optname, args[0])
        elif directivetype is dict:
            if len(args) != 0:
                raise PostParseError(pos,
                    'The %s directive takes no prepositional arguments' % optname)
            return optname, dict([(key.value, value) for key, value in kwds.key_value_pairs])
        elif directivetype is list:
            if kwds and len(kwds) != 0:
                raise PostParseError(pos,
                    'The %s directive takes no keyword arguments' % optname)
            return optname, [ str(arg.value) for arg in args ]
        elif callable(directivetype):
            if kwds is not None or len(args) != 1 or not isinstance(
                    args[0], (ExprNodes.StringNode, ExprNodes.UnicodeNode)):
                raise PostParseError(pos,
                    'The %s directive takes one compile-time string argument' % optname)
            return (optname, directivetype(optname, str(args[0].value)))
        else:
            assert False

    def visit_with_directives(self, body, directives):
        olddirectives = self.directives
        newdirectives = copy.copy(olddirectives)
        newdirectives.update(directives)
        self.directives = newdirectives
        assert isinstance(body, Nodes.StatListNode), body
        retbody = self.visit_Node(body)
        directive = Nodes.CompilerDirectivesNode(pos=retbody.pos, body=retbody,
                                                 directives=newdirectives)
        self.directives = olddirectives
        return directive

    # Handle decorators
    def visit_FuncDefNode(self, node):
        directives = self._extract_directives(node, 'function')
        if not directives:
            return self.visit_Node(node)
        body = Nodes.StatListNode(node.pos, stats=[node])
        return self.visit_with_directives(body, directives)

    def visit_CVarDefNode(self, node):
        directives = self._extract_directives(node, 'function')
        if not directives:
            return node
        for name, value in directives.iteritems():
            if name == 'locals':
                node.directive_locals = value
            elif name != 'final':
                self.context.nonfatal_error(PostParseError(
                    node.pos,
                    "Cdef functions can only take cython.locals() "
                    "or final decorators, got %s." % name))
        body = Nodes.StatListNode(node.pos, stats=[node])
        return self.visit_with_directives(body, directives)

    def visit_CClassDefNode(self, node):
        directives = self._extract_directives(node, 'cclass')
        if not directives:
            return self.visit_Node(node)
        body = Nodes.StatListNode(node.pos, stats=[node])
        return self.visit_with_directives(body, directives)

    def visit_PyClassDefNode(self, node):
        directives = self._extract_directives(node, 'class')
        if not directives:
            return self.visit_Node(node)
        body = Nodes.StatListNode(node.pos, stats=[node])
        return self.visit_with_directives(body, directives)

    def _extract_directives(self, node, scope_name):
        if not node.decorators:
            return {}
        # Split the decorators into two lists -- real decorators and directives
        directives = []
        realdecs = []
        for dec in node.decorators:
            new_directives = self.try_to_parse_directives(dec.decorator)
            if new_directives is not None:
                for directive in new_directives:
                    if self.check_directive_scope(node.pos, directive[0], scope_name):
                        directives.append(directive)
            else:
                realdecs.append(dec)
        if realdecs and isinstance(node, (Nodes.CFuncDefNode, Nodes.CClassDefNode, Nodes.CVarDefNode)):
            raise PostParseError(realdecs[0].pos, "Cdef functions/classes cannot take arbitrary decorators.")
        else:
            node.decorators = realdecs
        # merge or override repeated directives
        optdict = {}
        directives.reverse() # Decorators coming first take precedence
        for directive in directives:
            name, value = directive
            if name in optdict:
                old_value = optdict[name]
                # keywords and arg lists can be merged, everything
                # else overrides completely
                if isinstance(old_value, dict):
                    old_value.update(value)
                elif isinstance(old_value, list):
                    old_value.extend(value)
                else:
                    optdict[name] = value
            else:
                optdict[name] = value
        return optdict

    # Handle with statements
    def visit_WithStatNode(self, node):
        directive_dict = {}
        for directive in self.try_to_parse_directives(node.manager) or []:
            if directive is not None:
                if node.target is not None:
                    self.context.nonfatal_error(
                        PostParseError(node.pos, "Compiler directive with statements cannot contain 'as'"))
                else:
                    name, value = directive
                    if name in ('nogil', 'gil'):
                        # special case: in pure mode, "with nogil" spells "with cython.nogil"
                        node = Nodes.GILStatNode(node.pos, state = name, body = node.body)
                        return self.visit_Node(node)
                    if self.check_directive_scope(node.pos, name, 'with statement'):
                        directive_dict[name] = value
        if directive_dict:
            return self.visit_with_directives(node.body, directive_dict)
        return self.visit_Node(node)


class ParallelRangeTransform(CythonTransform, SkipDeclarations):
    """
    Transform cython.parallel stuff. The parallel_directives come from the
    module node, set there by InterpretCompilerDirectives.

        x = cython.parallel.threadavailable()   -> ParallelThreadAvailableNode
        with nogil, cython.parallel.parallel(): -> ParallelWithBlockNode
            print cython.parallel.threadid()    -> ParallelThreadIdNode
            for i in cython.parallel.prange(...):  -> ParallelRangeNode
                ...
    """

    # a list of names, maps 'cython.parallel.prange' in the code to
    # ['cython', 'parallel', 'prange']
    parallel_directive = None

    # Indicates whether a namenode in an expression is the cython module
    namenode_is_cython_module = False

    # Keep track of whether we are the context manager of a 'with' statement
    in_context_manager_section = False

    # One of 'prange' or 'with parallel'. This is used to disallow closely
    # nested 'with parallel:' blocks
    state = None

    directive_to_node = {
        u"cython.parallel.parallel": Nodes.ParallelWithBlockNode,
        # u"cython.parallel.threadsavailable": ExprNodes.ParallelThreadsAvailableNode,
        u"cython.parallel.threadid": ExprNodes.ParallelThreadIdNode,
        u"cython.parallel.prange": Nodes.ParallelRangeNode,
    }

    def node_is_parallel_directive(self, node):
        return node.name in self.parallel_directives or node.is_cython_module

    def get_directive_class_node(self, node):
        """
        Figure out which parallel directive was used and return the associated
        Node class.

        E.g. for a cython.parallel.prange() call we return ParallelRangeNode
        """
        if self.namenode_is_cython_module:
            directive = '.'.join(self.parallel_directive)
        else:
            directive = self.parallel_directives[self.parallel_directive[0]]
            directive = '%s.%s' % (directive,
                                   '.'.join(self.parallel_directive[1:]))
            directive = directive.rstrip('.')

        cls = self.directive_to_node.get(directive)
        if cls is None and not (self.namenode_is_cython_module and
                                self.parallel_directive[0] != 'parallel'):
            error(node.pos, "Invalid directive: %s" % directive)

        self.namenode_is_cython_module = False
        self.parallel_directive = None

        return cls

    def visit_ModuleNode(self, node):
        """
        If any parallel directives were imported, copy them over and visit
        the AST
        """
        if node.parallel_directives:
            self.parallel_directives = node.parallel_directives
            return self.visit_Node(node)

        # No parallel directives were imported, so they can't be used :)
        return node

    def visit_NameNode(self, node):
        if self.node_is_parallel_directive(node):
            self.parallel_directive = [node.name]
            self.namenode_is_cython_module = node.is_cython_module
        return node

    def visit_AttributeNode(self, node):
        self.visitchildren(node)
        if self.parallel_directive:
            self.parallel_directive.append(node.attribute)
        return node

    def visit_CallNode(self, node):
        self.visit(node.function)
        if not self.parallel_directive:
            return node

        # We are a parallel directive, replace this node with the
        # corresponding ParallelSomethingSomething node

        if isinstance(node, ExprNodes.GeneralCallNode):
            args = node.positional_args.args
            kwargs = node.keyword_args
        else:
            args = node.args
            kwargs = {}

        parallel_directive_class = self.get_directive_class_node(node)
        if parallel_directive_class:
            # Note: in case of a parallel() the body is set by
            # visit_WithStatNode
            node = parallel_directive_class(node.pos, args=args, kwargs=kwargs)

        return node

    def visit_WithStatNode(self, node):
        "Rewrite with cython.parallel.parallel() blocks"
        newnode = self.visit(node.manager)

        if isinstance(newnode, Nodes.ParallelWithBlockNode):
            if self.state == 'parallel with':
                error(node.manager.pos,
                      "Nested parallel with blocks are disallowed")

            self.state = 'parallel with'
            body = self.visit(node.body)
            self.state = None

            newnode.body = body
            return newnode
        elif self.parallel_directive:
            parallel_directive_class = self.get_directive_class_node(node)

            if not parallel_directive_class:
                # There was an error, stop here and now
                return None

            if parallel_directive_class is Nodes.ParallelWithBlockNode:
                error(node.pos, "The parallel directive must be called")
                return None

        node.body = self.visit(node.body)
        return node

    def visit_ForInStatNode(self, node):
        "Rewrite 'for i in cython.parallel.prange(...):'"
        self.visit(node.iterator)
        self.visit(node.target)

        in_prange = isinstance(node.iterator.sequence,
                               Nodes.ParallelRangeNode)
        previous_state = self.state

        if in_prange:
            # This will replace the entire ForInStatNode, so copy the
            # attributes
            parallel_range_node = node.iterator.sequence

            parallel_range_node.target = node.target
            parallel_range_node.body = node.body
            parallel_range_node.else_clause = node.else_clause

            node = parallel_range_node

            if not isinstance(node.target, ExprNodes.NameNode):
                error(node.target.pos,
                      "Can only iterate over an iteration variable")

            self.state = 'prange'

        self.visit(node.body)
        self.state = previous_state
        self.visit(node.else_clause)
        return node

    def visit(self, node):
        "Visit a node that may be None"
        if node is not None:
            return super(ParallelRangeTransform, self).visit(node)


class WithTransform(CythonTransform, SkipDeclarations):
    def visit_WithStatNode(self, node):
        self.visitchildren(node, 'body')
        pos = node.pos
        body, target, manager = node.body, node.target, node.manager
        node.enter_call = ExprNodes.SimpleCallNode(
            pos, function=ExprNodes.AttributeNode(
                pos, obj=ExprNodes.CloneNode(manager),
                attribute=EncodedString('__enter__'),
                is_special_lookup=True),
            args=[],
            is_temp=True)
        if target is not None:
            body = Nodes.StatListNode(
                pos, stats = [
                    Nodes.WithTargetAssignmentStatNode(
                        pos, lhs = target,
                        rhs = ResultRefNode(node.enter_call),
                        orig_rhs = node.enter_call),
                    body])

        excinfo_target = ExprNodes.TupleNode(pos, slow=True, args=[
            ExprNodes.ExcValueNode(pos) for _ in range(3)])
        except_clause = Nodes.ExceptClauseNode(
            pos, body=Nodes.IfStatNode(
                pos, if_clauses=[
                    Nodes.IfClauseNode(
                        pos, condition=ExprNodes.NotNode(
                            pos, operand=ExprNodes.WithExitCallNode(
                                pos, with_stat=node,
                                test_if_run=False,
                                args=excinfo_target)),
                        body=Nodes.ReraiseStatNode(pos),
                        ),
                    ],
                else_clause=None),
            pattern=None,
            target=None,
            excinfo_target=excinfo_target,
            )

        node.body = Nodes.TryFinallyStatNode(
            pos, body=Nodes.TryExceptStatNode(
                pos, body=body,
                except_clauses=[except_clause],
                else_clause=None,
                ),
            finally_clause=Nodes.ExprStatNode(
                pos, expr=ExprNodes.WithExitCallNode(
                    pos, with_stat=node,
                    test_if_run=True,
                    args=ExprNodes.TupleNode(
                        pos, args=[ExprNodes.NoneNode(pos) for _ in range(3)]
                        ))),
            handle_error_case=False,
            )
        return node

    def visit_ExprNode(self, node):
        # With statements are never inside expressions.
        return node


class DecoratorTransform(ScopeTrackingTransform, SkipDeclarations):
    """Originally, this was the only place where decorators were
    transformed into the corresponding calling code.  Now, this is
    done directly in DefNode and PyClassDefNode to avoid reassignments
    to the function/class name - except for cdef class methods.  For
    those, the reassignment is required as methods are originally
    defined in the PyMethodDef struct.

    The IndirectionNode allows DefNode to override the decorator
    """

    def visit_DefNode(self, func_node):
        scope_type = self.scope_type
        func_node = self.visit_FuncDefNode(func_node)
        if scope_type != 'cclass' or not func_node.decorators:
            return func_node
        return self.handle_decorators(func_node, func_node.decorators,
                                      func_node.name)

    def handle_decorators(self, node, decorators, name):
        decorator_result = ExprNodes.NameNode(node.pos, name = name)
        for decorator in decorators[::-1]:
            decorator_result = ExprNodes.SimpleCallNode(
                decorator.pos,
                function = decorator.decorator,
                args = [decorator_result])

        name_node = ExprNodes.NameNode(node.pos, name = name)
        reassignment = Nodes.SingleAssignmentNode(
            node.pos,
            lhs = name_node,
            rhs = decorator_result)

        reassignment = Nodes.IndirectionNode([reassignment])
        node.decorator_indirection = reassignment
        return [node, reassignment]

class CnameDirectivesTransform(CythonTransform, SkipDeclarations):
    """
    Only part of the CythonUtilityCode pipeline. Must be run before
    DecoratorTransform in case this is a decorator for a cdef class.
    It filters out @cname('my_cname') decorators and rewrites them to
    CnameDecoratorNodes.
    """

    def handle_function(self, node):
        if not getattr(node, 'decorators', None):
            return self.visit_Node(node)

        for i, decorator in enumerate(node.decorators):
            decorator = decorator.decorator

            if (isinstance(decorator, ExprNodes.CallNode) and
                    decorator.function.is_name and
                    decorator.function.name == 'cname'):
                args, kwargs = decorator.explicit_args_kwds()

                if kwargs:
                    raise AssertionError(
                            "cname decorator does not take keyword arguments")

                if len(args) != 1:
                    raise AssertionError(
                            "cname decorator takes exactly one argument")

                if not (args[0].is_literal and
                        args[0].type == Builtin.str_type):
                    raise AssertionError(
                            "argument to cname decorator must be a string literal")

                cname = args[0].compile_time_value(None).decode('UTF-8')
                del node.decorators[i]
                node = Nodes.CnameDecoratorNode(pos=node.pos, node=node,
                                                cname=cname)
                break

        return self.visit_Node(node)

    visit_FuncDefNode = handle_function
    visit_CClassDefNode = handle_function
    visit_CEnumDefNode = handle_function
    visit_CStructOrUnionDefNode = handle_function


class ForwardDeclareTypes(CythonTransform):

    def visit_CompilerDirectivesNode(self, node):
        env = self.module_scope
        old = env.directives
        env.directives = node.directives
        self.visitchildren(node)
        env.directives = old
        return node

    def visit_ModuleNode(self, node):
        self.module_scope = node.scope
        self.module_scope.directives = node.directives
        self.visitchildren(node)
        return node

    def visit_CDefExternNode(self, node):
        old_cinclude_flag = self.module_scope.in_cinclude
        self.module_scope.in_cinclude = 1
        self.visitchildren(node)
        self.module_scope.in_cinclude = old_cinclude_flag
        return node

    def visit_CEnumDefNode(self, node):
        node.declare(self.module_scope)
        return node

    def visit_CStructOrUnionDefNode(self, node):
        if node.name not in self.module_scope.entries:
            node.declare(self.module_scope)
        return node

    def visit_CClassDefNode(self, node):
        if node.class_name not in self.module_scope.entries:
            node.declare(self.module_scope)
        return node


class AnalyseDeclarationsTransform(EnvTransform):

    basic_property = TreeFragment(u"""
property NAME:
    def __get__(self):
        return ATTR
    def __set__(self, value):
        ATTR = value
    """, level='c_class', pipeline=[NormalizeTree(None)])
    basic_pyobject_property = TreeFragment(u"""
property NAME:
    def __get__(self):
        return ATTR
    def __set__(self, value):
        ATTR = value
    def __del__(self):
        ATTR = None
    """, level='c_class', pipeline=[NormalizeTree(None)])
    basic_property_ro = TreeFragment(u"""
property NAME:
    def __get__(self):
        return ATTR
    """, level='c_class', pipeline=[NormalizeTree(None)])

    struct_or_union_wrapper = TreeFragment(u"""
cdef class NAME:
    cdef TYPE value
    def __init__(self, MEMBER=None):
        cdef int count
        count = 0
        INIT_ASSIGNMENTS
        if IS_UNION and count > 1:
            raise ValueError, "At most one union member should be specified."
    def __str__(self):
        return STR_FORMAT % MEMBER_TUPLE
    def __repr__(self):
        return REPR_FORMAT % MEMBER_TUPLE
    """, pipeline=[NormalizeTree(None)])

    init_assignment = TreeFragment(u"""
if VALUE is not None:
    ATTR = VALUE
    count += 1
    """, pipeline=[NormalizeTree(None)])

    fused_function = None
    in_lambda = 0

    def __call__(self, root):
        # needed to determine if a cdef var is declared after it's used.
        self.seen_vars_stack = []
        self.fused_error_funcs = set()
        super_class = super(AnalyseDeclarationsTransform, self)
        self._super_visit_FuncDefNode = super_class.visit_FuncDefNode
        return super_class.__call__(root)

    def visit_NameNode(self, node):
        self.seen_vars_stack[-1].add(node.name)
        return node

    def visit_ModuleNode(self, node):
        self.seen_vars_stack.append(set())
        node.analyse_declarations(self.current_env())
        self.visitchildren(node)
        self.seen_vars_stack.pop()
        return node

    def visit_LambdaNode(self, node):
        self.in_lambda += 1
        node.analyse_declarations(self.current_env())
        self.visitchildren(node)
        self.in_lambda -= 1
        return node

    def visit_CClassDefNode(self, node):
        node = self.visit_ClassDefNode(node)
        if node.scope and node.scope.implemented:
            stats = []
            for entry in node.scope.var_entries:
                if entry.needs_property:
                    property = self.create_Property(entry)
                    property.analyse_declarations(node.scope)
                    self.visit(property)
                    stats.append(property)
            if stats:
                node.body.stats += stats
        return node

    def _handle_fused_def_decorators(self, old_decorators, env, node):
        """
        Create function calls to the decorators and reassignments to
        the function.
        """
        # Delete staticmethod and classmethod decorators, this is
        # handled directly by the fused function object.
        decorators = []
        for decorator in old_decorators:
            func = decorator.decorator
            if (not func.is_name or
                func.name not in ('staticmethod', 'classmethod') or
                env.lookup_here(func.name)):
                # not a static or classmethod
                decorators.append(decorator)

        if decorators:
            transform = DecoratorTransform(self.context)
            def_node = node.node
            _, reassignments = transform.handle_decorators(
                def_node, decorators, def_node.name)
            reassignments.analyse_declarations(env)
            node = [node, reassignments]

        return node

    def _handle_def(self, decorators, env, node):
        "Handle def or cpdef fused functions"
        # Create PyCFunction nodes for each specialization
        node.stats.insert(0, node.py_func)
        node.py_func = self.visit(node.py_func)
        node.update_fused_defnode_entry(env)
        pycfunc = ExprNodes.PyCFunctionNode.from_defnode(node.py_func,
                                                         True)
        pycfunc = ExprNodes.ProxyNode(pycfunc.coerce_to_temp(env))
        node.resulting_fused_function = pycfunc
        # Create assignment node for our def function
        node.fused_func_assignment = self._create_assignment(
            node.py_func, ExprNodes.CloneNode(pycfunc), env)

        if decorators:
            node = self._handle_fused_def_decorators(decorators, env, node)

        return node

    def _create_fused_function(self, env, node):
        "Create a fused function for a DefNode with fused arguments"
        from Cython.Compiler import FusedNode

        if self.fused_function or self.in_lambda:
            if self.fused_function not in self.fused_error_funcs:
                if self.in_lambda:
                    error(node.pos, "Fused lambdas not allowed")
                else:
                    error(node.pos, "Cannot nest fused functions")

            self.fused_error_funcs.add(self.fused_function)

            node.body = Nodes.PassStatNode(node.pos)
            for arg in node.args:
                if arg.type.is_fused:
                    arg.type = arg.type.get_fused_types()[0]

            return node

        decorators = getattr(node, 'decorators', None)
        node = FusedNode.FusedCFuncDefNode(node, env)
        self.fused_function = node
        self.visitchildren(node)
        self.fused_function = None
        if node.py_func:
            node = self._handle_def(decorators, env, node)

        return node

    def _handle_nogil_cleanup(self, lenv, node):
        "Handle cleanup for 'with gil' blocks in nogil functions."
        if lenv.nogil and lenv.has_with_gil_block:
            # Acquire the GIL for cleanup in 'nogil' functions, by wrapping
            # the entire function body in try/finally.
            # The corresponding release will be taken care of by
            # Nodes.FuncDefNode.generate_function_definitions()
            node.body = Nodes.NogilTryFinallyStatNode(
                node.body.pos,
                body=node.body,
                finally_clause=Nodes.EnsureGILNode(node.body.pos))

    def _handle_fused(self, node):
        if node.is_generator and node.has_fused_arguments:
            node.has_fused_arguments = False
            error(node.pos, "Fused generators not supported")
            node.gbody = Nodes.StatListNode(node.pos,
                                            stats=[],
                                            body=Nodes.PassStatNode(node.pos))

        return node.has_fused_arguments

    def visit_FuncDefNode(self, node):
        """
        Analyse a function and its body, as that hasn't happend yet. Also
        analyse the directive_locals set by @cython.locals(). Then, if we are
        a function with fused arguments, replace the function (after it has
        declared itself in the symbol table!) with a FusedCFuncDefNode, and
        analyse its children (which are in turn normal functions). If we're a
        normal function, just analyse the body of the function.
        """
        env = self.current_env()

        self.seen_vars_stack.append(set())
        lenv = node.local_scope
        node.declare_arguments(lenv)

        for var, type_node in node.directive_locals.items():
            if not lenv.lookup_here(var):   # don't redeclare args
                type = type_node.analyse_as_type(lenv)
                if type:
                    lenv.declare_var(var, type, type_node.pos)
                else:
                    error(type_node.pos, "Not a type")

        if self._handle_fused(node):
            node = self._create_fused_function(env, node)
        else:
            node.body.analyse_declarations(lenv)
            self._handle_nogil_cleanup(lenv, node)
            self._super_visit_FuncDefNode(node)

        self.seen_vars_stack.pop()
        return node

    def visit_DefNode(self, node):
        node = self.visit_FuncDefNode(node)
        env = self.current_env()
        if (not isinstance(node, Nodes.DefNode) or
            node.fused_py_func or node.is_generator_body or
            not node.needs_assignment_synthesis(env)):
            return node
        return [node, self._synthesize_assignment(node, env)]

    def visit_GeneratorBodyDefNode(self, node):
        return self.visit_FuncDefNode(node)

    def _synthesize_assignment(self, node, env):
        # Synthesize assignment node and put it right after defnode
        genv = env
        while genv.is_py_class_scope or genv.is_c_class_scope:
            genv = genv.outer_scope

        if genv.is_closure_scope:
            rhs = node.py_cfunc_node = ExprNodes.InnerFunctionNode(
                node.pos, def_node=node,
                pymethdef_cname=node.entry.pymethdef_cname,
                code_object=ExprNodes.CodeObjectNode(node))
        else:
            binding = self.current_directives.get('binding')
            rhs = ExprNodes.PyCFunctionNode.from_defnode(node, binding)

        if env.is_py_class_scope:
            rhs.binding = True

        node.is_cyfunction = rhs.binding
        return self._create_assignment(node, rhs, env)

    def _create_assignment(self, def_node, rhs, env):
        if def_node.decorators:
            for decorator in def_node.decorators[::-1]:
                rhs = ExprNodes.SimpleCallNode(
                    decorator.pos,
                    function = decorator.decorator,
                    args = [rhs])
            def_node.decorators = None

        assmt = Nodes.SingleAssignmentNode(
            def_node.pos,
            lhs=ExprNodes.NameNode(def_node.pos, name=def_node.name),
            rhs=rhs)
        assmt.analyse_declarations(env)
        return assmt

    def visit_ScopedExprNode(self, node):
        env = self.current_env()
        node.analyse_declarations(env)
        # the node may or may not have a local scope
        if node.has_local_scope:
            self.seen_vars_stack.append(set(self.seen_vars_stack[-1]))
            self.enter_scope(node, node.expr_scope)
            node.analyse_scoped_declarations(node.expr_scope)
            self.visitchildren(node)
            self.exit_scope()
            self.seen_vars_stack.pop()
        else:
            node.analyse_scoped_declarations(env)
            self.visitchildren(node)
        return node

    def visit_TempResultFromStatNode(self, node):
        self.visitchildren(node)
        node.analyse_declarations(self.current_env())
        return node

    def visit_CppClassNode(self, node):
        if node.visibility == 'extern':
            return None
        else:
            return self.visit_ClassDefNode(node)
    
    def visit_CStructOrUnionDefNode(self, node):
        # Create a wrapper node if needed.
        # We want to use the struct type information (so it can't happen
        # before this phase) but also create new objects to be declared
        # (so it can't happen later).
        # Note that we don't return the original node, as it is
        # never used after this phase.
        if True: # private (default)
            return None

        self_value = ExprNodes.AttributeNode(
            pos = node.pos,
            obj = ExprNodes.NameNode(pos=node.pos, name=u"self"),
            attribute = EncodedString(u"value"))
        var_entries = node.entry.type.scope.var_entries
        attributes = []
        for entry in var_entries:
            attributes.append(ExprNodes.AttributeNode(pos = entry.pos,
                                                      obj = self_value,
                                                      attribute = entry.name))
        # __init__ assignments
        init_assignments = []
        for entry, attr in zip(var_entries, attributes):
            # TODO: branch on visibility
            init_assignments.append(self.init_assignment.substitute({
                    u"VALUE": ExprNodes.NameNode(entry.pos, name = entry.name),
                    u"ATTR": attr,
                }, pos = entry.pos))

        # create the class
        str_format = u"%s(%s)" % (node.entry.type.name, ("%s, " * len(attributes))[:-2])
        wrapper_class = self.struct_or_union_wrapper.substitute({
            u"INIT_ASSIGNMENTS": Nodes.StatListNode(node.pos, stats = init_assignments),
            u"IS_UNION": ExprNodes.BoolNode(node.pos, value = not node.entry.type.is_struct),
            u"MEMBER_TUPLE": ExprNodes.TupleNode(node.pos, args=attributes),
            u"STR_FORMAT": ExprNodes.StringNode(node.pos, value = EncodedString(str_format)),
            u"REPR_FORMAT": ExprNodes.StringNode(node.pos, value = EncodedString(str_format.replace("%s", "%r"))),
        }, pos = node.pos).stats[0]
        wrapper_class.class_name = node.name
        wrapper_class.shadow = True
        class_body = wrapper_class.body.stats

        # fix value type
        assert isinstance(class_body[0].base_type, Nodes.CSimpleBaseTypeNode)
        class_body[0].base_type.name = node.name

        # fix __init__ arguments
        init_method = class_body[1]
        assert isinstance(init_method, Nodes.DefNode) and init_method.name == '__init__'
        arg_template = init_method.args[1]
        if not node.entry.type.is_struct:
            arg_template.kw_only = True
        del init_method.args[1]
        for entry, attr in zip(var_entries, attributes):
            arg = copy.deepcopy(arg_template)
            arg.declarator.name = entry.name
            init_method.args.append(arg)

        # setters/getters
        for entry, attr in zip(var_entries, attributes):
            # TODO: branch on visibility
            if entry.type.is_pyobject:
                template = self.basic_pyobject_property
            else:
                template = self.basic_property
            property = template.substitute({
                    u"ATTR": attr,
                }, pos = entry.pos).stats[0]
            property.name = entry.name
            wrapper_class.body.stats.append(property)

        wrapper_class.analyse_declarations(self.current_env())
        return self.visit_CClassDefNode(wrapper_class)

    # Some nodes are no longer needed after declaration
    # analysis and can be dropped. The analysis was performed
    # on these nodes in a seperate recursive process from the
    # enclosing function or module, so we can simply drop them.
    def visit_CDeclaratorNode(self, node):
        # necessary to ensure that all CNameDeclaratorNodes are visited.
        self.visitchildren(node)
        return node

    def visit_CTypeDefNode(self, node):
        return node

    def visit_CBaseTypeNode(self, node):
        return None

    def visit_CEnumDefNode(self, node):
        if node.visibility == 'public':
            return node
        else:
            return None

    def visit_CNameDeclaratorNode(self, node):
        if node.name in self.seen_vars_stack[-1]:
            entry = self.current_env().lookup(node.name)
            if (entry is None or entry.visibility != 'extern'
                and not entry.scope.is_c_class_scope):
                warning(node.pos, "cdef variable '%s' declared after it is used" % node.name, 2)
        self.visitchildren(node)
        return node

    def visit_CVarDefNode(self, node):
        # to ensure all CNameDeclaratorNodes are visited.
        self.visitchildren(node)
        return None

    def visit_CnameDecoratorNode(self, node):
        child_node = self.visit(node.node)
        if not child_node:
            return None
        if type(child_node) is list: # Assignment synthesized
            node.child_node = child_node[0]
            return [node] + child_node[1:]
        node.node = child_node
        return node

    def create_Property(self, entry):
        if entry.visibility == 'public':
            if entry.type.is_pyobject:
                template = self.basic_pyobject_property
            else:
                template = self.basic_property
        elif entry.visibility == 'readonly':
            template = self.basic_property_ro
        property = template.substitute({
                u"ATTR": ExprNodes.AttributeNode(pos=entry.pos,
                                                 obj=ExprNodes.NameNode(pos=entry.pos, name="self"),
                                                 attribute=entry.name),
            }, pos=entry.pos).stats[0]
        property.name = entry.name
        property.doc = entry.doc
        return property


class CalculateQualifiedNamesTransform(EnvTransform):
    """
    Calculate and store the '__qualname__' and the global
    module name on some nodes.
    """
    def visit_ModuleNode(self, node):
        self.module_name = self.global_scope().qualified_name
        self.qualified_name = []
        _super = super(CalculateQualifiedNamesTransform, self)
        self._super_visit_FuncDefNode = _super.visit_FuncDefNode
        self._super_visit_ClassDefNode = _super.visit_ClassDefNode
        self.visitchildren(node)
        return node

    def _set_qualname(self, node, name=None):
        if name:
            qualname = self.qualified_name[:]
            qualname.append(name)
        else:
            qualname = self.qualified_name
        node.qualname = EncodedString('.'.join(qualname))
        node.module_name = self.module_name
        self.visitchildren(node)
        return node

    def _append_entry(self, entry):
        if entry.is_pyglobal and not entry.is_pyclass_attr:
            self.qualified_name = [entry.name]
        else:
            self.qualified_name.append(entry.name)

    def visit_ClassNode(self, node):
        return self._set_qualname(node, node.name)

    def visit_PyClassNamespaceNode(self, node):
        # class name was already added by parent node
        return self._set_qualname(node)

    def visit_PyCFunctionNode(self, node):
        return self._set_qualname(node, node.def_node.name)

    def visit_FuncDefNode(self, node):
        orig_qualified_name = self.qualified_name[:]
        if getattr(node, 'name', None) == '<lambda>':
            self.qualified_name.append('<lambda>')
        else:
            self._append_entry(node.entry)
        self.qualified_name.append('<locals>')
        self._super_visit_FuncDefNode(node)
        self.qualified_name = orig_qualified_name
        return node

    def visit_ClassDefNode(self, node):
        orig_qualified_name = self.qualified_name[:]
        entry = (getattr(node, 'entry', None) or             # PyClass
                 self.current_env().lookup_here(node.name))  # CClass
        self._append_entry(entry)
        self._super_visit_ClassDefNode(node)
        self.qualified_name = orig_qualified_name
        return node


class AnalyseExpressionsTransform(CythonTransform):

    def visit_ModuleNode(self, node):
        node.scope.infer_types()
        node.body = node.body.analyse_expressions(node.scope)
        self.visitchildren(node)
        return node

    def visit_FuncDefNode(self, node):
        node.local_scope.infer_types()
        node.body = node.body.analyse_expressions(node.local_scope)
        self.visitchildren(node)
        return node

    def visit_ScopedExprNode(self, node):
        if node.has_local_scope:
            node.expr_scope.infer_types()
            node = node.analyse_scoped_expressions(node.expr_scope)
        self.visitchildren(node)
        return node

    def visit_IndexNode(self, node):
        """
        Replace index nodes used to specialize cdef functions with fused
        argument types with the Attribute- or NameNode referring to the
        function. We then need to copy over the specialization properties to
        the attribute or name node.

        Because the indexing might be a Python indexing operation on a fused
        function, or (usually) a Cython indexing operation, we need to
        re-analyse the types.
        """
        self.visit_Node(node)

        if node.is_fused_index and not node.type.is_error:
            node = node.base
        elif node.memslice_ellipsis_noop:
            # memoryviewslice[...] expression, drop the IndexNode
            node = node.base

        return node


class FindInvalidUseOfFusedTypes(CythonTransform):

    def visit_FuncDefNode(self, node):
        # Errors related to use in functions with fused args will already
        # have been detected
        if not node.has_fused_arguments:
            if not node.is_generator_body and node.return_type.is_fused:
                error(node.pos, "Return type is not specified as argument type")
            else:
                self.visitchildren(node)

        return node

    def visit_ExprNode(self, node):
        if node.type and node.type.is_fused:
            error(node.pos, "Invalid use of fused types, type cannot be specialized")
        else:
            self.visitchildren(node)

        return node


class ExpandInplaceOperators(EnvTransform):

    def visit_InPlaceAssignmentNode(self, node):
        lhs = node.lhs
        rhs = node.rhs
        if lhs.type.is_cpp_class:
            # No getting around this exact operator here.
            return node
        if isinstance(lhs, ExprNodes.IndexNode) and lhs.is_buffer_access:
            # There is code to handle this case.
            return node

        env = self.current_env()
        def side_effect_free_reference(node, setting=False):
            if isinstance(node, ExprNodes.NameNode):
                return node, []
            elif node.type.is_pyobject and not setting:
                node = LetRefNode(node)
                return node, [node]
            elif isinstance(node, ExprNodes.IndexNode):
                if node.is_buffer_access:
                    raise ValueError("Buffer access")
                base, temps = side_effect_free_reference(node.base)
                index = LetRefNode(node.index)
                return ExprNodes.IndexNode(node.pos, base=base, index=index), temps + [index]
            elif isinstance(node, ExprNodes.AttributeNode):
                obj, temps = side_effect_free_reference(node.obj)
                return ExprNodes.AttributeNode(node.pos, obj=obj, attribute=node.attribute), temps
            else:
                node = LetRefNode(node)
                return node, [node]
        try:
            lhs, let_ref_nodes = side_effect_free_reference(lhs, setting=True)
        except ValueError:
            return node
        dup = lhs.__class__(**lhs.__dict__)
        binop = ExprNodes.binop_node(node.pos,
                                     operator = node.operator,
                                     operand1 = dup,
                                     operand2 = rhs,
                                     inplace=True)
        # Manually analyse types for new node.
        lhs.analyse_target_types(env)
        dup.analyse_types(env)
        binop.analyse_operation(env)
        node = Nodes.SingleAssignmentNode(
            node.pos,
            lhs = lhs,
            rhs=binop.coerce_to(lhs.type, env))
        # Use LetRefNode to avoid side effects.
        let_ref_nodes.reverse()
        for t in let_ref_nodes:
            node = LetNode(t, node)
        return node

    def visit_ExprNode(self, node):
        # In-place assignments can't happen within an expression.
        return node

class AdjustDefByDirectives(CythonTransform, SkipDeclarations):
    """
    Adjust function and class definitions by the decorator directives:

    @cython.cfunc
    @cython.cclass
    @cython.ccall
    """

    def visit_ModuleNode(self, node):
        self.directives = node.directives
        self.in_py_class = False
        self.visitchildren(node)
        return node

    def visit_CompilerDirectivesNode(self, node):
        old_directives = self.directives
        self.directives = node.directives
        self.visitchildren(node)
        self.directives = old_directives
        return node

    def visit_DefNode(self, node):
        if 'ccall' in self.directives:
            node = node.as_cfunction(overridable=True, returns=self.directives.get('returns'))
            return self.visit(node)
        if 'cfunc' in self.directives:
            if self.in_py_class:
                error(node.pos, "cfunc directive is not allowed here")
            else:
                node = node.as_cfunction(overridable=False, returns=self.directives.get('returns'))
                return self.visit(node)
        self.visitchildren(node)
        return node

    def visit_PyClassDefNode(self, node):
        if 'cclass' in self.directives:
            node = node.as_cclass()
            return self.visit(node)
        else:
            old_in_pyclass = self.in_py_class
            self.in_py_class = True
            self.visitchildren(node)
            self.in_py_class = old_in_pyclass
            return node

    def visit_CClassDefNode(self, node):
        old_in_pyclass = self.in_py_class
        self.in_py_class = False
        self.visitchildren(node)
        self.in_py_class = old_in_pyclass
        return node


class AlignFunctionDefinitions(CythonTransform):
    """
    This class takes the signatures from a .pxd file and applies them to
    the def methods in a .py file.
    """

    def visit_ModuleNode(self, node):
        self.scope = node.scope
        self.directives = node.directives
        self.imported_names = set()  # hack, see visit_FromImportStatNode()
        self.visitchildren(node)
        return node

    def visit_PyClassDefNode(self, node):
        pxd_def = self.scope.lookup(node.name)
        if pxd_def:
            if pxd_def.is_cclass:
                return self.visit_CClassDefNode(node.as_cclass(), pxd_def)
            elif not pxd_def.scope or not pxd_def.scope.is_builtin_scope:
                error(node.pos, "'%s' redeclared" % node.name)
                if pxd_def.pos:
                    error(pxd_def.pos, "previous declaration here")
                return None
        return node

    def visit_CClassDefNode(self, node, pxd_def=None):
        if pxd_def is None:
            pxd_def = self.scope.lookup(node.class_name)
        if pxd_def:
            outer_scope = self.scope
            self.scope = pxd_def.type.scope
        self.visitchildren(node)
        if pxd_def:
            self.scope = outer_scope
        return node

    def visit_DefNode(self, node):
        pxd_def = self.scope.lookup(node.name)
        if pxd_def and (not pxd_def.scope or not pxd_def.scope.is_builtin_scope):
            if not pxd_def.is_cfunction:
                error(node.pos, "'%s' redeclared" % node.name)
                if pxd_def.pos:
                    error(pxd_def.pos, "previous declaration here")
                return None
            node = node.as_cfunction(pxd_def)
        elif (self.scope.is_module_scope and self.directives['auto_cpdef']
              and not node.name in self.imported_names
              and node.is_cdef_func_compatible()):
            # FIXME: cpdef-ing should be done in analyse_declarations()
            node = node.as_cfunction(scope=self.scope)
        # Enable this when nested cdef functions are allowed.
        # self.visitchildren(node)
        return node

    def visit_FromImportStatNode(self, node):
        # hack to prevent conditional import fallback functions from
        # being cdpef-ed (global Python variables currently conflict
        # with imports)
        if self.scope.is_module_scope:
            for name, _ in node.items:
                self.imported_names.add(name)
        return node

    def visit_ExprNode(self, node):
        # ignore lambdas and everything else that appears in expressions
        return node


class RemoveUnreachableCode(CythonTransform):
    def visit_StatListNode(self, node):
        if not self.current_directives['remove_unreachable']:
            return node
        self.visitchildren(node)
        for idx, stat in enumerate(node.stats):
            idx += 1
            if stat.is_terminator:
                if idx < len(node.stats):
                    if self.current_directives['warn.unreachable']:
                        warning(node.stats[idx].pos, "Unreachable code", 2)
                    node.stats = node.stats[:idx]
                node.is_terminator = True
                break
        return node

    def visit_IfClauseNode(self, node):
        self.visitchildren(node)
        if node.body.is_terminator:
            node.is_terminator = True
        return node

    def visit_IfStatNode(self, node):
        self.visitchildren(node)
        if node.else_clause and node.else_clause.is_terminator:
            for clause in node.if_clauses:
                if not clause.is_terminator:
                    break
            else:
                node.is_terminator = True
        return node

    def visit_TryExceptStatNode(self, node):
        self.visitchildren(node)
        if node.body.is_terminator and node.else_clause:
            if self.current_directives['warn.unreachable']:
                warning(node.else_clause.pos, "Unreachable code", 2)
            node.else_clause = None
        return node


class YieldNodeCollector(TreeVisitor):

    def __init__(self):
        super(YieldNodeCollector, self).__init__()
        self.yields = []
        self.returns = []
        self.has_return_value = False

    def visit_Node(self, node):
        self.visitchildren(node)

    def visit_YieldExprNode(self, node):
        self.yields.append(node)
        self.visitchildren(node)

    def visit_ReturnStatNode(self, node):
        self.visitchildren(node)
        if node.value:
            self.has_return_value = True
        self.returns.append(node)

    def visit_ClassDefNode(self, node):
        pass

    def visit_FuncDefNode(self, node):
        pass

    def visit_LambdaNode(self, node):
        pass

    def visit_GeneratorExpressionNode(self, node):
        pass


class MarkClosureVisitor(CythonTransform):

    def visit_ModuleNode(self, node):
        self.needs_closure = False
        self.visitchildren(node)
        return node

    def visit_FuncDefNode(self, node):
        self.needs_closure = False
        self.visitchildren(node)
        node.needs_closure = self.needs_closure
        self.needs_closure = True

        collector = YieldNodeCollector()
        collector.visitchildren(node)

        if collector.yields:
            if isinstance(node, Nodes.CFuncDefNode):
                # Will report error later
                return node
            for i, yield_expr in enumerate(collector.yields):
                yield_expr.label_num = i + 1  # no enumerate start arg in Py2.4
            for retnode in collector.returns:
                retnode.in_generator = True

            gbody = Nodes.GeneratorBodyDefNode(
                pos=node.pos, name=node.name, body=node.body)
            generator = Nodes.GeneratorDefNode(
                pos=node.pos, name=node.name, args=node.args,
                star_arg=node.star_arg, starstar_arg=node.starstar_arg,
                doc=node.doc, decorators=node.decorators,
                gbody=gbody, lambda_name=node.lambda_name)
            return generator
        return node

    def visit_CFuncDefNode(self, node):
        self.visit_FuncDefNode(node)
        if node.needs_closure:
            error(node.pos, "closures inside cdef functions not yet supported")
        return node

    def visit_LambdaNode(self, node):
        self.needs_closure = False
        self.visitchildren(node)
        node.needs_closure = self.needs_closure
        self.needs_closure = True
        return node

    def visit_ClassDefNode(self, node):
        self.visitchildren(node)
        self.needs_closure = True
        return node

class CreateClosureClasses(CythonTransform):
    # Output closure classes in module scope for all functions
    # that really need it.

    def __init__(self, context):
        super(CreateClosureClasses, self).__init__(context)
        self.path = []
        self.in_lambda = False

    def visit_ModuleNode(self, node):
        self.module_scope = node.scope
        self.visitchildren(node)
        return node

    def find_entries_used_in_closures(self, node):
        from_closure = []
        in_closure = []
        for name, entry in node.local_scope.entries.items():
            if entry.from_closure:
                from_closure.append((name, entry))
            elif entry.in_closure:
                in_closure.append((name, entry))
        return from_closure, in_closure

    def create_class_from_scope(self, node, target_module_scope, inner_node=None):
        # move local variables into closure
        if node.is_generator:
            for entry in node.local_scope.entries.values():
                if not entry.from_closure:
                    entry.in_closure = True

        from_closure, in_closure = self.find_entries_used_in_closures(node)
        in_closure.sort()

        # Now from the begining
        node.needs_closure = False
        node.needs_outer_scope = False

        func_scope = node.local_scope
        cscope = node.entry.scope
        while cscope.is_py_class_scope or cscope.is_c_class_scope:
            cscope = cscope.outer_scope

        if not from_closure and (self.path or inner_node):
            if not inner_node:
                if not node.py_cfunc_node:
                    raise InternalError("DefNode does not have assignment node")
                inner_node = node.py_cfunc_node
            inner_node.needs_self_code = False
            node.needs_outer_scope = False

        if node.is_generator:
            pass
        elif not in_closure and not from_closure:
            return
        elif not in_closure:
            func_scope.is_passthrough = True
            func_scope.scope_class = cscope.scope_class
            node.needs_outer_scope = True
            return

        as_name = '%s_%s' % (
            target_module_scope.next_id(Naming.closure_class_prefix),
            node.entry.cname)

        entry = target_module_scope.declare_c_class(
            name=as_name, pos=node.pos, defining=True,
            implementing=True)
        entry.type.is_final_type = True

        func_scope.scope_class = entry
        class_scope = entry.type.scope
        class_scope.is_internal = True
        if Options.closure_freelist_size:
            class_scope.directives['freelist'] = Options.closure_freelist_size

        if from_closure:
            assert cscope.is_closure_scope
            class_scope.declare_var(pos=node.pos,
                                    name=Naming.outer_scope_cname,
                                    cname=Naming.outer_scope_cname,
                                    type=cscope.scope_class.type,
                                    is_cdef=True)
            node.needs_outer_scope = True
        for name, entry in in_closure:
            closure_entry = class_scope.declare_var(pos=entry.pos,
                                    name=entry.name,
                                    cname=entry.cname,
                                    type=entry.type,
                                    is_cdef=True)
            if entry.is_declared_generic:
                closure_entry.is_declared_generic = 1
        node.needs_closure = True
        # Do it here because other classes are already checked
        target_module_scope.check_c_class(func_scope.scope_class)

    def visit_LambdaNode(self, node):
        if not isinstance(node.def_node, Nodes.DefNode):
            # fused function, an error has been previously issued
            return node

        was_in_lambda = self.in_lambda
        self.in_lambda = True
        self.create_class_from_scope(node.def_node, self.module_scope, node)
        self.visitchildren(node)
        self.in_lambda = was_in_lambda
        return node

    def visit_FuncDefNode(self, node):
        if self.in_lambda:
            self.visitchildren(node)
            return node
        if node.needs_closure or self.path:
            self.create_class_from_scope(node, self.module_scope)
            self.path.append(node)
            self.visitchildren(node)
            self.path.pop()
        return node

    def visit_GeneratorBodyDefNode(self, node):
        self.visitchildren(node)
        return node

    def visit_CFuncDefNode(self, node):
        self.visitchildren(node)
        return node


class GilCheck(VisitorTransform):
    """
    Call `node.gil_check(env)` on each node to make sure we hold the
    GIL when we need it.  Raise an error when on Python operations
    inside a `nogil` environment.

    Additionally, raise exceptions for closely nested with gil or with nogil
    statements. The latter would abort Python.
    """

    def __call__(self, root):
        self.env_stack = [root.scope]
        self.nogil = False

        # True for 'cdef func() nogil:' functions, as the GIL may be held while
        # calling this function (thus contained 'nogil' blocks may be valid).
        self.nogil_declarator_only = False
        return super(GilCheck, self).__call__(root)

    def visit_FuncDefNode(self, node):
        self.env_stack.append(node.local_scope)
        was_nogil = self.nogil
        self.nogil = node.local_scope.nogil

        if self.nogil:
            self.nogil_declarator_only = True

        if self.nogil and node.nogil_check:
            node.nogil_check(node.local_scope)

        self.visitchildren(node)

        # This cannot be nested, so it doesn't need backup/restore
        self.nogil_declarator_only = False

        self.env_stack.pop()
        self.nogil = was_nogil
        return node

    def visit_GILStatNode(self, node):
        if self.nogil and node.nogil_check:
            node.nogil_check()

        was_nogil = self.nogil
        self.nogil = (node.state == 'nogil')

        if was_nogil == self.nogil and not self.nogil_declarator_only:
            if not was_nogil:
                error(node.pos, "Trying to acquire the GIL while it is "
                                "already held.")
            else:
                error(node.pos, "Trying to release the GIL while it was "
                                "previously released.")

        if isinstance(node.finally_clause, Nodes.StatListNode):
            # The finally clause of the GILStatNode is a GILExitNode,
            # which is wrapped in a StatListNode. Just unpack that.
            node.finally_clause, = node.finally_clause.stats

        self.visitchildren(node)
        self.nogil = was_nogil
        return node

    def visit_ParallelRangeNode(self, node):
        if node.nogil:
            node.nogil = False
            node = Nodes.GILStatNode(node.pos, state='nogil', body=node)
            return self.visit_GILStatNode(node)

        if not self.nogil:
            error(node.pos, "prange() can only be used without the GIL")
            # Forget about any GIL-related errors that may occur in the body
            return None

        node.nogil_check(self.env_stack[-1])
        self.visitchildren(node)
        return node

    def visit_ParallelWithBlockNode(self, node):
        if not self.nogil:
            error(node.pos, "The parallel section may only be used without "
                            "the GIL")
            return None

        if node.nogil_check:
            # It does not currently implement this, but test for it anyway to
            # avoid potential future surprises
            node.nogil_check(self.env_stack[-1])

        self.visitchildren(node)
        return node

    def visit_TryFinallyStatNode(self, node):
        """
        Take care of try/finally statements in nogil code sections.
        """
        if not self.nogil or isinstance(node, Nodes.GILStatNode):
            return self.visit_Node(node)

        node.nogil_check = None
        node.is_try_finally_in_nogil = True
        self.visitchildren(node)
        return node

    def visit_Node(self, node):
        if self.env_stack and self.nogil and node.nogil_check:
            node.nogil_check(self.env_stack[-1])
        self.visitchildren(node)
        node.in_nogil_context = self.nogil
        return node


class TransformBuiltinMethods(EnvTransform):

    def visit_SingleAssignmentNode(self, node):
        if node.declaration_only:
            return None
        else:
            self.visitchildren(node)
            return node

    def visit_AttributeNode(self, node):
        self.visitchildren(node)
        return self.visit_cython_attribute(node)

    def visit_NameNode(self, node):
        return self.visit_cython_attribute(node)

    def visit_cython_attribute(self, node):
        attribute = node.as_cython_attribute()
        if attribute:
            if attribute == u'compiled':
                node = ExprNodes.BoolNode(node.pos, value=True)
            elif attribute == u'__version__':
                import Cython
                node = ExprNodes.StringNode(node.pos, value=EncodedString(Cython.__version__))
            elif attribute == u'NULL':
                node = ExprNodes.NullNode(node.pos)
            elif attribute in (u'set', u'frozenset'):
                node = ExprNodes.NameNode(node.pos, name=EncodedString(attribute),
                                          entry=self.current_env().builtin_scope().lookup_here(attribute))
            elif PyrexTypes.parse_basic_type(attribute):
                pass
            elif self.context.cython_scope.lookup_qualified_name(attribute):
                pass
            else:
                error(node.pos, u"'%s' not a valid cython attribute or is being used incorrectly" % attribute)
        return node

    def visit_ExecStatNode(self, node):
        lenv = self.current_env()
        self.visitchildren(node)
        if len(node.args) == 1:
            node.args.append(ExprNodes.GlobalsExprNode(node.pos))
            if not lenv.is_module_scope:
                node.args.append(
                    ExprNodes.LocalsExprNode(
                        node.pos, self.current_scope_node(), lenv))
        return node

    def _inject_locals(self, node, func_name):
        # locals()/dir()/vars() builtins
        lenv = self.current_env()
        entry = lenv.lookup_here(func_name)
        if entry:
            # not the builtin
            return node
        pos = node.pos
        if func_name in ('locals', 'vars'):
            if func_name == 'locals' and len(node.args) > 0:
                error(self.pos, "Builtin 'locals()' called with wrong number of args, expected 0, got %d"
                      % len(node.args))
                return node
            elif func_name == 'vars':
                if len(node.args) > 1:
                    error(self.pos, "Builtin 'vars()' called with wrong number of args, expected 0-1, got %d"
                          % len(node.args))
                if len(node.args) > 0:
                    return node # nothing to do
            return ExprNodes.LocalsExprNode(pos, self.current_scope_node(), lenv)
        else: # dir()
            if len(node.args) > 1:
                error(self.pos, "Builtin 'dir()' called with wrong number of args, expected 0-1, got %d"
                      % len(node.args))
            if len(node.args) > 0:
                # optimised in Builtin.py
                return node
            if lenv.is_py_class_scope or lenv.is_module_scope:
                if lenv.is_py_class_scope:
                    pyclass = self.current_scope_node()
                    locals_dict = ExprNodes.CloneNode(pyclass.dict)
                else:
                    locals_dict = ExprNodes.GlobalsExprNode(pos)
                return ExprNodes.SortedDictKeysNode(locals_dict)
            local_names = [ var.name for var in lenv.entries.values() if var.name ]
            items = [ ExprNodes.IdentifierStringNode(pos, value=var)
                      for var in local_names ]
            return ExprNodes.ListNode(pos, args=items)

    def visit_PrimaryCmpNode(self, node):
        # special case: for in/not-in test, we do not need to sort locals()
        self.visitchildren(node)
        if node.operator in 'not_in':  # in/not_in
            if isinstance(node.operand2, ExprNodes.SortedDictKeysNode):
                arg = node.operand2.arg
                if isinstance(arg, ExprNodes.NoneCheckNode):
                    arg = arg.arg
                node.operand2 = arg
        return node

    def visit_CascadedCmpNode(self, node):
        return self.visit_PrimaryCmpNode(node)

    def _inject_eval(self, node, func_name):
        lenv = self.current_env()
        entry = lenv.lookup_here(func_name)
        if entry or len(node.args) != 1:
            return node
        # Inject globals and locals
        node.args.append(ExprNodes.GlobalsExprNode(node.pos))
        if not lenv.is_module_scope:
            node.args.append(
                ExprNodes.LocalsExprNode(
                    node.pos, self.current_scope_node(), lenv))
        return node

    def _inject_super(self, node, func_name):
        lenv = self.current_env()
        entry = lenv.lookup_here(func_name)
        if entry or node.args:
            return node
        # Inject no-args super
        def_node = self.current_scope_node()
        if (not isinstance(def_node, Nodes.DefNode) or not def_node.args or
            len(self.env_stack) < 2):
            return node
        class_node, class_scope = self.env_stack[-2]
        if class_scope.is_py_class_scope:
            def_node.requires_classobj = True
            class_node.class_cell.is_active = True
            node.args = [
                ExprNodes.ClassCellNode(
                    node.pos, is_generator=def_node.is_generator),
                ExprNodes.NameNode(node.pos, name=def_node.args[0].name)
                ]
        elif class_scope.is_c_class_scope:
            node.args = [
                ExprNodes.NameNode(
                    node.pos, name=class_node.scope.name,
                    entry=class_node.entry),
                ExprNodes.NameNode(node.pos, name=def_node.args[0].name)
                ]
        return node

    def visit_SimpleCallNode(self, node):
        # cython.foo
        function = node.function.as_cython_attribute()
        if function:
            if function in InterpretCompilerDirectives.unop_method_nodes:
                if len(node.args) != 1:
                    error(node.function.pos, u"%s() takes exactly one argument" % function)
                else:
                    node = InterpretCompilerDirectives.unop_method_nodes[function](node.function.pos, operand=node.args[0])
            elif function in InterpretCompilerDirectives.binop_method_nodes:
                if len(node.args) != 2:
                    error(node.function.pos, u"%s() takes exactly two arguments" % function)
                else:
                    node = InterpretCompilerDirectives.binop_method_nodes[function](node.function.pos, operand1=node.args[0], operand2=node.args[1])
            elif function == u'cast':
                if len(node.args) != 2:
                    error(node.function.pos, u"cast() takes exactly two arguments")
                else:
                    type = node.args[0].analyse_as_type(self.current_env())
                    if type:
                        node = ExprNodes.TypecastNode(node.function.pos, type=type, operand=node.args[1])
                    else:
                        error(node.args[0].pos, "Not a type")
            elif function == u'sizeof':
                if len(node.args) != 1:
                    error(node.function.pos, u"sizeof() takes exactly one argument")
                else:
                    type = node.args[0].analyse_as_type(self.current_env())
                    if type:
                        node = ExprNodes.SizeofTypeNode(node.function.pos, arg_type=type)
                    else:
                        node = ExprNodes.SizeofVarNode(node.function.pos, operand=node.args[0])
            elif function == 'cmod':
                if len(node.args) != 2:
                    error(node.function.pos, u"cmod() takes exactly two arguments")
                else:
                    node = ExprNodes.binop_node(node.function.pos, '%', node.args[0], node.args[1])
                    node.cdivision = True
            elif function == 'cdiv':
                if len(node.args) != 2:
                    error(node.function.pos, u"cdiv() takes exactly two arguments")
                else:
                    node = ExprNodes.binop_node(node.function.pos, '/', node.args[0], node.args[1])
                    node.cdivision = True
            elif function == u'set':
                node.function = ExprNodes.NameNode(node.pos, name=EncodedString('set'))
            elif self.context.cython_scope.lookup_qualified_name(function):
                pass
            else:
                error(node.function.pos,
                      u"'%s' not a valid cython language construct" % function)

        self.visitchildren(node)

        if isinstance(node, ExprNodes.SimpleCallNode) and node.function.is_name:
            func_name = node.function.name
            if func_name in ('dir', 'locals', 'vars'):
                return self._inject_locals(node, func_name)
            if func_name == 'eval':
                return self._inject_eval(node, func_name)
            if func_name == 'super':
                return self._inject_super(node, func_name)
        return node


class ReplaceFusedTypeChecks(VisitorTransform):
    """
    This is not a transform in the pipeline. It is invoked on the specific
    versions of a cdef function with fused argument types. It filters out any
    type branches that don't match. e.g.

        if fused_t is mytype:
            ...
        elif fused_t in other_fused_type:
            ...
    """
    def __init__(self, local_scope):
        super(ReplaceFusedTypeChecks, self).__init__()
        self.local_scope = local_scope
        # defer the import until now to avoid circular import time dependencies
        from Cython.Compiler import Optimize
        self.transform = Optimize.ConstantFolding(reevaluate=True)

    def visit_IfStatNode(self, node):
        """
        Filters out any if clauses with false compile time type check
        expression.
        """
        self.visitchildren(node)
        return self.transform(node)

    def visit_PrimaryCmpNode(self, node):
        type1 = node.operand1.analyse_as_type(self.local_scope)
        type2 = node.operand2.analyse_as_type(self.local_scope)

        if type1 and type2:
            false_node = ExprNodes.BoolNode(node.pos, value=False)
            true_node = ExprNodes.BoolNode(node.pos, value=True)

            type1 = self.specialize_type(type1, node.operand1.pos)
            op = node.operator

            if op in ('is', 'is_not', '==', '!='):
                type2 = self.specialize_type(type2, node.operand2.pos)

                is_same = type1.same_as(type2)
                eq = op in ('is', '==')

                if (is_same and eq) or (not is_same and not eq):
                    return true_node

            elif op in ('in', 'not_in'):
                # We have to do an instance check directly, as operand2
                # needs to be a fused type and not a type with a subtype
                # that is fused. First unpack the typedef
                if isinstance(type2, PyrexTypes.CTypedefType):
                    type2 = type2.typedef_base_type

                if type1.is_fused:
                    error(node.operand1.pos, "Type is fused")
                elif not type2.is_fused:
                    error(node.operand2.pos,
                          "Can only use 'in' or 'not in' on a fused type")
                else:
                    types = PyrexTypes.get_specialized_types(type2)

                    for specialized_type in types:
                        if type1.same_as(specialized_type):
                            if op == 'in':
                                return true_node
                            else:
                                return false_node

                    if op == 'not_in':
                        return true_node

            return false_node

        return node

    def specialize_type(self, type, pos):
        try:
            return type.specialize(self.local_scope.fused_to_specific)
        except KeyError:
            error(pos, "Type is not specific")
            return type

    def visit_Node(self, node):
        self.visitchildren(node)
        return node


class DebugTransform(CythonTransform):
    """
    Write debug information for this Cython module.
    """

    def __init__(self, context, options, result):
        super(DebugTransform, self).__init__(context)
        self.visited = set()
        # our treebuilder and debug output writer
        # (see Cython.Debugger.debug_output.CythonDebugWriter)
        self.tb = self.context.gdb_debug_outputwriter
        #self.c_output_file = options.output_file
        self.c_output_file = result.c_file

        # Closure support, basically treat nested functions as if the AST were
        # never nested
        self.nested_funcdefs = []

        # tells visit_NameNode whether it should register step-into functions
        self.register_stepinto = False

    def visit_ModuleNode(self, node):
        self.tb.module_name = node.full_module_name
        attrs = dict(
            module_name=node.full_module_name,
            filename=node.pos[0].filename,
            c_filename=self.c_output_file)

        self.tb.start('Module', attrs)

        # serialize functions
        self.tb.start('Functions')
        # First, serialize functions normally...
        self.visitchildren(node)

        # ... then, serialize nested functions
        for nested_funcdef in self.nested_funcdefs:
            self.visit_FuncDefNode(nested_funcdef)

        self.register_stepinto = True
        self.serialize_modulenode_as_function(node)
        self.register_stepinto = False
        self.tb.end('Functions')

        # 2.3 compatibility. Serialize global variables
        self.tb.start('Globals')
        entries = {}

        for k, v in node.scope.entries.iteritems():
            if (v.qualified_name not in self.visited and not
                v.name.startswith('__pyx_') and not
                v.type.is_cfunction and not
                v.type.is_extension_type):
                entries[k]= v

        self.serialize_local_variables(entries)
        self.tb.end('Globals')
        # self.tb.end('Module') # end Module after the line number mapping in
        # Cython.Compiler.ModuleNode.ModuleNode._serialize_lineno_map
        return node

    def visit_FuncDefNode(self, node):
        self.visited.add(node.local_scope.qualified_name)

        if getattr(node, 'is_wrapper', False):
            return node

        if self.register_stepinto:
            self.nested_funcdefs.append(node)
            return node

        # node.entry.visibility = 'extern'
        if node.py_func is None:
            pf_cname = ''
        else:
            pf_cname = node.py_func.entry.func_cname

        attrs = dict(
            name=node.entry.name or getattr(node, 'name', '<unknown>'),
            cname=node.entry.func_cname,
            pf_cname=pf_cname,
            qualified_name=node.local_scope.qualified_name,
            lineno=str(node.pos[1]))

        self.tb.start('Function', attrs=attrs)

        self.tb.start('Locals')
        self.serialize_local_variables(node.local_scope.entries)
        self.tb.end('Locals')

        self.tb.start('Arguments')
        for arg in node.local_scope.arg_entries:
            self.tb.start(arg.name)
            self.tb.end(arg.name)
        self.tb.end('Arguments')

        self.tb.start('StepIntoFunctions')
        self.register_stepinto = True
        self.visitchildren(node)
        self.register_stepinto = False
        self.tb.end('StepIntoFunctions')
        self.tb.end('Function')

        return node

    def visit_NameNode(self, node):
        if (self.register_stepinto and
            node.type.is_cfunction and
            getattr(node, 'is_called', False) and
            node.entry.func_cname is not None):
            # don't check node.entry.in_cinclude, as 'cdef extern: ...'
            # declared functions are not 'in_cinclude'.
            # This means we will list called 'cdef' functions as
            # "step into functions", but this is not an issue as they will be
            # recognized as Cython functions anyway.
            attrs = dict(name=node.entry.func_cname)
            self.tb.start('StepIntoFunction', attrs=attrs)
            self.tb.end('StepIntoFunction')

        self.visitchildren(node)
        return node

    def serialize_modulenode_as_function(self, node):
        """
        Serialize the module-level code as a function so the debugger will know
        it's a "relevant frame" and it will know where to set the breakpoint
        for 'break modulename'.
        """
        name = node.full_module_name.rpartition('.')[-1]

        cname_py2 = 'init' + name
        cname_py3 = 'PyInit_' + name

        py2_attrs = dict(
            name=name,
            cname=cname_py2,
            pf_cname='',
            # Ignore the qualified_name, breakpoints should be set using
            # `cy break modulename:lineno` for module-level breakpoints.
            qualified_name='',
            lineno='1',
            is_initmodule_function="True",
        )

        py3_attrs = dict(py2_attrs, cname=cname_py3)

        self._serialize_modulenode_as_function(node, py2_attrs)
        self._serialize_modulenode_as_function(node, py3_attrs)

    def _serialize_modulenode_as_function(self, node, attrs):
        self.tb.start('Function', attrs=attrs)

        self.tb.start('Locals')
        self.serialize_local_variables(node.scope.entries)
        self.tb.end('Locals')

        self.tb.start('Arguments')
        self.tb.end('Arguments')

        self.tb.start('StepIntoFunctions')
        self.register_stepinto = True
        self.visitchildren(node)
        self.register_stepinto = False
        self.tb.end('StepIntoFunctions')

        self.tb.end('Function')

    def serialize_local_variables(self, entries):
        for entry in entries.values():
            if not entry.cname:
                # not a local variable
                continue
            if entry.type.is_pyobject:
                vartype = 'PythonObject'
            else:
                vartype = 'CObject'

            if entry.from_closure:
                # We're dealing with a closure where a variable from an outer
                # scope is accessed, get it from the scope object.
                cname = '%s->%s' % (Naming.cur_scope_cname,
                                    entry.outer_entry.cname)

                qname = '%s.%s.%s' % (entry.scope.outer_scope.qualified_name,
                                      entry.scope.name,
                                      entry.name)
            elif entry.in_closure:
                cname = '%s->%s' % (Naming.cur_scope_cname,
                                    entry.cname)
                qname = entry.qualified_name
            else:
                cname = entry.cname
                qname = entry.qualified_name

            if not entry.pos:
                # this happens for variables that are not in the user's code,
                # e.g. for the global __builtins__, __doc__, etc. We can just
                # set the lineno to 0 for those.
                lineno = '0'
            else:
                lineno = str(entry.pos[1])

            attrs = dict(
                name=entry.name,
                cname=cname,
                qualified_name=qname,
                type=vartype,
                lineno=lineno)

            self.tb.start('LocalVar', attrs)
            self.tb.end('LocalVar')
