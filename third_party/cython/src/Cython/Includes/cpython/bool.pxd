
cdef extern from "Python.h":

    ############################################################################
    # 7.2.2 Boolean Objects
    ############################################################################

    ctypedef class __builtin__.bool [object PyBoolObject]:
        pass

    # Booleans in Python are implemented as a subclass of
    # integers. There are only two booleans, Py_False and Py_True. As
    # such, the normal creation and deletion functions don't apply to
    # booleans. The following macros are available, however.

    bint PyBool_Check(object o)
    # Return true if o is of type PyBool_Type.

    #PyObject* Py_False
    # The Python False object. This object has no methods. It needs to
    # be treated just like any other object with respect to reference
    # counts.

    #PyObject* Py_True
    # The Python True object. This object has no methods. It needs to
    # be treated just like any other object with respect to reference
    # counts.

    # Py_RETURN_FALSE
    # Return Py_False from a function, properly incrementing its reference count.

    # Py_RETURN_TRUE
    # Return Py_True from a function, properly incrementing its reference count.

    object PyBool_FromLong(long v)
    # Return value: New reference.
    # Return a new reference to Py_True or Py_False depending on the truth value of v.

