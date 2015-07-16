from cpython.ref cimport PyObject

cdef extern from "Python.h":
    #####################################################################
    # 5.5 Parsing arguments and building values
    #####################################################################
    ctypedef struct va_list
    int PyArg_ParseTuple(object args, char *format, ...) except 0
    int PyArg_VaParse(object args, char *format, va_list vargs) except 0
    int PyArg_ParseTupleAndKeywords(object args, object kw, char *format, char *keywords[], ...) except 0
    int PyArg_VaParseTupleAndKeywords(object args, object kw, char *format, char *keywords[], va_list vargs) except 0
    int PyArg_Parse(object args, char *format, ...) except 0
    int PyArg_UnpackTuple(object args, char *name, Py_ssize_t min, Py_ssize_t max, ...) except 0
