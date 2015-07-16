cdef extern from "Python.h":

    ############################################################################
    # 7.2.3
    ############################################################################
    # PyFloatObject
    #
    # This subtype of PyObject represents a Python floating point object.

    # PyTypeObject PyFloat_Type
    #
    # This instance of PyTypeObject represents the Python floating
    # point type. This is the same object as float and
    # types.FloatType.

    bint PyFloat_Check(object p)
    # Return true if its argument is a PyFloatObject or a subtype of
    # PyFloatObject.

    bint PyFloat_CheckExact(object p)
    # Return true if its argument is a PyFloatObject, but not a
    # subtype of PyFloatObject.

    object PyFloat_FromString(object str, char **pend)
    # Return value: New reference.
    # Create a PyFloatObject object based on the string value in str,
    # or NULL on failure. The pend argument is ignored. It remains
    # only for backward compatibility.

    object PyFloat_FromDouble(double v)
    # Return value: New reference.
    # Create a PyFloatObject object from v, or NULL on failure.

    double PyFloat_AsDouble(object pyfloat) except? -1
    # Return a C double representation of the contents of pyfloat.

    double PyFloat_AS_DOUBLE(object pyfloat)
    # Return a C double representation of the contents of pyfloat, but
    # without error checking.
