cimport cython

from Cython.Compiler.Visitor cimport CythonTransform, TreeVisitor

cdef class ControlBlock:
     cdef public set children
     cdef public set parents
     cdef public set positions
     cdef public list stats
     cdef public dict gen
     cdef public set bounded
     cdef public dict input
     cdef public dict output

     # Big integer it bitsets
     cdef public object i_input
     cdef public object i_output
     cdef public object i_gen
     cdef public object i_kill
     cdef public object i_state

     cpdef bint empty(self)
     cpdef detach(self)
     cpdef add_child(self, block)

cdef class ExitBlock(ControlBlock):
     cpdef bint empty(self)

cdef class NameAssignment:
    cdef public bint is_arg
    cdef public bint is_deletion
    cdef public object lhs
    cdef public object rhs
    cdef public object entry
    cdef public object pos
    cdef public set refs
    cdef public object bit
    cdef public object inferred_type

cdef class AssignmentList:
    cdef public object bit
    cdef public object mask
    cdef public list stats

cdef class AssignmentCollector(TreeVisitor):
    cdef list assignments

@cython.final
cdef class ControlFlow:
     cdef public set blocks
     cdef public set entries
     cdef public list loops
     cdef public list exceptions

     cdef public ControlBlock entry_point
     cdef public ExitBlock exit_point
     cdef public ControlBlock block

     cdef public dict assmts

     cpdef newblock(self, ControlBlock parent=*)
     cpdef nextblock(self, ControlBlock parent=*)
     cpdef bint is_tracked(self, entry)
     cpdef bint is_statically_assigned(self, entry)
     cpdef mark_position(self, node)
     cpdef mark_assignment(self, lhs, rhs, entry)
     cpdef mark_argument(self, lhs, rhs, entry)
     cpdef mark_deletion(self, node, entry)
     cpdef mark_reference(self, node, entry)

     @cython.locals(block=ControlBlock, parent=ControlBlock, unreachable=set)
     cpdef normalize(self)

     @cython.locals(bit=object, assmts=AssignmentList,
                    block=ControlBlock)
     cpdef initialize(self)

     @cython.locals(assmts=AssignmentList, assmt=NameAssignment)
     cpdef set map_one(self, istate, entry)

     @cython.locals(block=ControlBlock, parent=ControlBlock)
     cdef reaching_definitions(self)

cdef class Uninitialized:
     pass

cdef class Unknown:
    pass

@cython.locals(dirty=bint, block=ControlBlock, parent=ControlBlock,
               assmt=NameAssignment)
cdef check_definitions(ControlFlow flow, dict compiler_directives)

@cython.final
cdef class ControlFlowAnalysis(CythonTransform):
    cdef object gv_ctx
    cdef set reductions
    cdef list env_stack
    cdef list stack
    cdef object env
    cdef ControlFlow flow
    cdef bint in_inplace_assignment

    cpdef mark_assignment(self, lhs, rhs=*)
    cpdef mark_position(self, node)
