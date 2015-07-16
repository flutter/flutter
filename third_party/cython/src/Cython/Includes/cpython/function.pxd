from cpython.ref cimport PyObject

cdef extern from "Python.h":

    ############################################################################
    # 7.5.3 Function Objects
    ############################################################################
    # There are a few functions specific to Python functions.

    # PyFunctionObject
    #
    # The C structure used for functions.

    # PyTypeObject PyFunction_Type
    #
    # This is an instance of PyTypeObject and represents the Python
    # function type. It is exposed to Python programmers as
    # types.FunctionType.

    bint PyFunction_Check(object o)
    # Return true if o is a function object (has type
    # PyFunction_Type). The parameter must not be NULL.

    object PyFunction_New(object code, object globals)
    # Return value: New reference.
    # Return a new function object associated with the code object
    # code. globals must be a dictionary with the global variables
    # accessible to the function.
    # The function's docstring, name and __module__ are retrieved from
    # the code object, the argument defaults and closure are set to
    # NULL.

    PyObject* PyFunction_GetCode(object op) except? NULL
    # Return value: Borrowed reference.
    # Return the code object associated with the function object op.

    PyObject* PyFunction_GetGlobals(object op) except? NULL
    # Return value: Borrowed reference.
    # Return the globals dictionary associated with the function object op.

    PyObject* PyFunction_GetModule(object op) except? NULL
    # Return value: Borrowed reference.
    # Return the __module__ attribute of the function object op. This
    # is normally a string containing the module name, but can be set
    # to any other object by Python code.

    PyObject* PyFunction_GetDefaults(object op) except? NULL
    # Return value: Borrowed reference.
    # Return the argument default values of the function object
    # op. This can be a tuple of arguments or NULL.

    int PyFunction_SetDefaults(object op, object defaults) except -1
    # Set the argument default values for the function object
    # op. defaults must be Py_None or a tuple.
    # Raises SystemError and returns -1 on failure.

    PyObject* PyFunction_GetClosure(object op) except? NULL
    # Return value: Borrowed reference.
    # Return the closure associated with the function object op. This
    # can be NULL or a tuple of cell objects.

    int PyFunction_SetClosure(object op, object closure) except -1
    # Set the closure associated with the function object op. closure
    # must be Py_None or a tuple of cell objects.
    # Raises SystemError and returns -1 on failure.
