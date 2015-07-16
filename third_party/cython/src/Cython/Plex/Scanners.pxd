import cython

from Cython.Plex.Actions cimport Action

cdef class Scanner:

    cdef public lexicon
    cdef public stream
    cdef public name
    cdef public unicode buffer
    cdef public Py_ssize_t buf_start_pos
    cdef public Py_ssize_t next_pos
    cdef public Py_ssize_t cur_pos
    cdef public Py_ssize_t cur_line
    cdef public Py_ssize_t cur_line_start
    cdef public Py_ssize_t start_pos
    cdef public Py_ssize_t start_line
    cdef public Py_ssize_t start_col
    cdef public text
    cdef public initial_state # int?
    cdef public state_name
    cdef public list queue
    cdef public bint trace
    cdef public cur_char
    cdef public int input_state

    cdef public level

    @cython.locals(input_state=long)
    cdef next_char(self)
    @cython.locals(action=Action)
    cdef tuple read(self)
    cdef tuple scan_a_token(self)
    cdef tuple position(self)

    @cython.locals(cur_pos=long, cur_line=long, cur_line_start=long,
                   input_state=long, next_pos=long, state=dict,
                   buf_start_pos=long, buf_len=long, buf_index=long,
                   trace=bint, discard=long, data=unicode, buffer=unicode)
    cdef run_machine_inlined(self)

    cdef begin(self, state)
    cdef produce(self, value, text = *)
