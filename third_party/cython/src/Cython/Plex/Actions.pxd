
cdef class Action:
  cdef perform(self, token_stream, text)
  cpdef same_as(self, other)

cdef class Return(Action):
  cdef object value
  cdef perform(self, token_stream, text)
  cpdef same_as(self, other)

cdef class Call(Action):
  cdef object function
  cdef perform(self, token_stream, text)
  cpdef same_as(self, other)

cdef class Begin(Action):
  cdef object state_name
  cdef perform(self, token_stream, text)
  cpdef same_as(self, other)

cdef class Ignore(Action):
  cdef perform(self, token_stream, text)

cdef class Text(Action):
  cdef perform(self, token_stream, text)
