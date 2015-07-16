
cdef extern from "Python.h":

    ctypedef struct Py_complex:
        double imag
        double real

    ############################################################################
    # 7.2.5.2 Complex Numbers as Python Objects
    ############################################################################

    # PyComplexObject
    # This subtype of PyObject represents a Python complex number object.

    ctypedef class __builtin__.complex [object PyComplexObject]:
        cdef Py_complex cval
        # not making these available to keep them read-only:
        #cdef double imag "cval.imag"
        #cdef double real "cval.real"

    # PyTypeObject PyComplex_Type
    # This instance of PyTypeObject represents the Python complex
    # number type. It is the same object as complex and
    # types.ComplexType.

    bint PyComplex_Check(object p)
    # Return true if its argument is a PyComplexObject or a subtype of
    # PyComplexObject.

    bint PyComplex_CheckExact(object p)
    # Return true if its argument is a PyComplexObject, but not a subtype of PyComplexObject.

    object PyComplex_FromCComplex(Py_complex v)
    # Return value: New reference.
    # Create a new Python complex number object from a C Py_complex value.

    object PyComplex_FromDoubles(double real, double imag)
    # Return value: New reference.
    # Return a new PyComplexObject object from real and imag.

    double PyComplex_RealAsDouble(object op) except? -1
    # Return the real part of op as a C double.

    double PyComplex_ImagAsDouble(object op) except? -1
    # Return the imaginary part of op as a C double.

    Py_complex PyComplex_AsCComplex(object op)
    # Return the Py_complex value of the complex number op.
    #
    # Returns (-1+0i) in case of an error
