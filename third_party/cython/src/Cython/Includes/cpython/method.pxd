cdef extern from "Python.h":
    ctypedef void PyObject
    ############################################################################
    # 7.5.4 Method Objects
    ############################################################################

    # There are some useful functions that are useful for working with method objects.
    # PyTypeObject PyMethod_Type
    # This instance of PyTypeObject represents the Python method type. This is exposed to Python programs as types.MethodType.

    bint PyMethod_Check(object o)
    # Return true if o is a method object (has type
    # PyMethod_Type). The parameter must not be NULL.

    object PyMethod_New(object func, object self, object cls)
    # Return value: New reference.
    # Return a new method object, with func being any callable object;
    # this is the function that will be called when the method is
    # called. If this method should be bound to an instance, self
    # should be the instance and class should be the class of self,
    # otherwise self should be NULL and class should be the class
    # which provides the unbound method..

    PyObject* PyMethod_Class(object meth) except NULL
    # Return value: Borrowed reference.
    # Return the class object from which the method meth was created;
    # if this was created from an instance, it will be the class of
    # the instance.

    PyObject* PyMethod_GET_CLASS(object meth)
    # Return value: Borrowed reference.
    # Macro version of PyMethod_Class() which avoids error checking.

    PyObject* PyMethod_Function(object meth) except NULL
    # Return value: Borrowed reference.
    # Return the function object associated with the method meth.

    PyObject* PyMethod_GET_FUNCTION(object meth)
    # Return value: Borrowed reference.
    # Macro version of PyMethod_Function() which avoids error checking.

    PyObject* PyMethod_Self(object meth) except? NULL
    # Return value: Borrowed reference.
    # Return the instance associated with the method meth if it is bound, otherwise return NULL.

    PyObject* PyMethod_GET_SELF(object meth)
    # Return value: Borrowed reference.
    # Macro version of PyMethod_Self() which avoids error checking.
