from cpython.ref cimport PyObject

cdef extern from "Python.h":

    ############################################################################
    # Tuples
    ############################################################################

    bint PyTuple_Check(object  p)
    # Return true if p is a tuple object or an instance of a subtype
    # of the tuple type.

    bint PyTuple_CheckExact(object  p)
    # Return true if p is a tuple object, but not an instance of a subtype of the tuple type.

    tuple PyTuple_New(Py_ssize_t len)
    # Return value: New reference.
    # Return a new tuple object of size len, or NULL on failure.

    tuple PyTuple_Pack(Py_ssize_t n, ...)
    # Return value: New reference.
    # Return a new tuple object of size n, or NULL on failure. The
    # tuple values are initialized to the subsequent n C arguments
    # pointing to Python objects. "PyTuple_Pack(2, a, b)" is
    # equivalent to "Py_BuildValue("(OO)", a, b)".

    Py_ssize_t PyTuple_Size(object  p) except -1
    # Take a pointer to a tuple object, and return the size of that tuple.

    Py_ssize_t PyTuple_GET_SIZE(object  p)
    # Return the size of the tuple p, which must be non-NULL and point
    # to a tuple; no error checking is performed.

    PyObject* PyTuple_GetItem(object  p, Py_ssize_t pos) except NULL
    # Return value: Borrowed reference.
    # Return the object at position pos in the tuple pointed to by
    # p. If pos is out of bounds, return NULL and sets an IndexError
    # exception.

    PyObject* PyTuple_GET_ITEM(object  p, Py_ssize_t pos)
    # Return value: Borrowed reference.
    # Like PyTuple_GetItem(), but does no checking of its arguments.

    tuple PyTuple_GetSlice(object  p, Py_ssize_t low, Py_ssize_t high)
    # Return value: New reference.
    # Take a slice of the tuple pointed to by p from low to high and return it as a new tuple.

    int PyTuple_SetItem(object  p, Py_ssize_t pos, object  o)
    # Insert a reference to object o at position pos of the tuple
    # pointed to by p. Return 0 on success. Note: This function
    # ``steals'' a reference to o.

    void PyTuple_SET_ITEM(object  p, Py_ssize_t pos, object  o)
    # Like PyTuple_SetItem(), but does no error checking, and should
    # only be used to fill in brand new tuples. Note: This function
    # ``steals'' a reference to o.

    int _PyTuple_Resize(PyObject **p, Py_ssize_t newsize) except -1
    # Can be used to resize a tuple. newsize will be the new length of
    # the tuple. Because tuples are supposed to be immutable, this
    # should only be used if there is only one reference to the
    # object. Do not use this if the tuple may already be known to
    # some other part of the code. The tuple will always grow or
    # shrink at the end. Think of this as destroying the old tuple and
    # creating a new one, only more efficiently. Returns 0 on
    # success. Client code should never assume that the resulting
    # value of *p will be the same as before calling this function. If
    # the object referenced by *p is replaced, the original *p is
    # destroyed. On failure, returns -1 and sets *p to NULL, and
    # raises MemoryError or SystemError.

