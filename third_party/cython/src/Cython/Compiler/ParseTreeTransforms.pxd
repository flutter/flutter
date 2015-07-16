
cimport cython

from Cython.Compiler.Visitor cimport (
    CythonTransform, VisitorTransform, TreeVisitor,
    ScopeTrackingTransform, EnvTransform)

cdef class NameNodeCollector(TreeVisitor):
    cdef list name_nodes

cdef class SkipDeclarations: # (object):
    pass

cdef class NormalizeTree(CythonTransform):
    cdef bint is_in_statlist
    cdef bint is_in_expr
    cpdef visit_StatNode(self, node, is_listcontainer=*)

cdef class PostParse(ScopeTrackingTransform):
    cdef dict specialattribute_handlers
    cdef size_t lambda_counter
    cdef size_t genexpr_counter
    cdef _visit_assignment_node(self, node, list expr_list)


#def eliminate_rhs_duplicates(list expr_list_list, list ref_node_sequence)
#def sort_common_subsequences(list items)
@cython.locals(starred_targets=Py_ssize_t, lhs_size=Py_ssize_t, rhs_size=Py_ssize_t)
cdef flatten_parallel_assignments(list input, list output)
cdef map_starred_assignment(list lhs_targets, list starred_assignments, list lhs_args, list rhs_args)

#class PxdPostParse(CythonTransform, SkipDeclarations):
#class InterpretCompilerDirectives(CythonTransform, SkipDeclarations):
#class WithTransform(CythonTransform, SkipDeclarations):
#class DecoratorTransform(CythonTransform, SkipDeclarations):

#class AnalyseDeclarationsTransform(EnvTransform):

cdef class AnalyseExpressionsTransform(CythonTransform):
    pass

cdef class ExpandInplaceOperators(EnvTransform):
    pass

cdef class AlignFunctionDefinitions(CythonTransform):
    cdef dict directives
    cdef scope

cdef class YieldNodeCollector(TreeVisitor):
    cdef public list yields
    cdef public list returns
    cdef public bint has_return_value

cdef class MarkClosureVisitor(CythonTransform):
    cdef bint needs_closure

cdef class CreateClosureClasses(CythonTransform):
    cdef list path
    cdef bint in_lambda
    cdef module_scope
    cdef generator_class

cdef class GilCheck(VisitorTransform):
    cdef list env_stack
    cdef bint nogil
    cdef bint nogil_declarator_only

cdef class TransformBuiltinMethods(EnvTransform):
    cdef visit_cython_attribute(self, node)
