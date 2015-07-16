# NumPy static imports for Cython
#
# If any of the PyArray_* functions are called, import_array must be
# called first.
#
# This also defines backwards-compatability buffer acquisition
# code for use in Python 2.x (or Python <= 2.5 when NumPy starts
# implementing PEP-3118 directly).
#
# Because of laziness, the format string of the buffer is statically
# allocated. Increase the size if this is not enough, or submit a
# patch to do this properly.
#
# Author: Dag Sverre Seljebotn
#

DEF _buffer_format_string_len = 255

cimport cpython.buffer as pybuf
from cpython.ref cimport Py_INCREF, Py_XDECREF
from cpython.object cimport PyObject
from cpython.type cimport type
cimport libc.stdlib as stdlib
cimport libc.stdio as stdio

cdef extern from "Python.h":
    ctypedef int Py_intptr_t

cdef extern from "numpy/arrayobject.h":
    ctypedef Py_intptr_t npy_intp
    ctypedef size_t npy_uintp

    cdef enum NPY_TYPES:
        NPY_BOOL
        NPY_BYTE
        NPY_UBYTE
        NPY_SHORT
        NPY_USHORT
        NPY_INT
        NPY_UINT
        NPY_LONG
        NPY_ULONG
        NPY_LONGLONG
        NPY_ULONGLONG
        NPY_FLOAT
        NPY_DOUBLE
        NPY_LONGDOUBLE
        NPY_CFLOAT
        NPY_CDOUBLE
        NPY_CLONGDOUBLE
        NPY_OBJECT
        NPY_STRING
        NPY_UNICODE
        NPY_VOID
        NPY_NTYPES
        NPY_NOTYPE

        NPY_INT8
        NPY_INT16
        NPY_INT32
        NPY_INT64
        NPY_INT128
        NPY_INT256
        NPY_UINT8
        NPY_UINT16
        NPY_UINT32
        NPY_UINT64
        NPY_UINT128
        NPY_UINT256
        NPY_FLOAT16
        NPY_FLOAT32
        NPY_FLOAT64
        NPY_FLOAT80
        NPY_FLOAT96
        NPY_FLOAT128
        NPY_FLOAT256
        NPY_COMPLEX32
        NPY_COMPLEX64
        NPY_COMPLEX128
        NPY_COMPLEX160
        NPY_COMPLEX192
        NPY_COMPLEX256
        NPY_COMPLEX512

        NPY_INTP

    ctypedef enum NPY_ORDER:
        NPY_ANYORDER
        NPY_CORDER
        NPY_FORTRANORDER

    ctypedef enum NPY_CLIPMODE:
        NPY_CLIP
        NPY_WRAP
        NPY_RAISE

    ctypedef enum NPY_SCALARKIND:
        NPY_NOSCALAR,
        NPY_BOOL_SCALAR,
        NPY_INTPOS_SCALAR,
        NPY_INTNEG_SCALAR,
        NPY_FLOAT_SCALAR,
        NPY_COMPLEX_SCALAR,
        NPY_OBJECT_SCALAR

    ctypedef enum NPY_SORTKIND:
        NPY_QUICKSORT
        NPY_HEAPSORT
        NPY_MERGESORT

    ctypedef enum NPY_SEARCHSIDE:
        NPY_SEARCHLEFT
        NPY_SEARCHRIGHT

    enum:
        NPY_C_CONTIGUOUS
        NPY_F_CONTIGUOUS
        NPY_CONTIGUOUS
        NPY_FORTRAN
        NPY_OWNDATA
        NPY_FORCECAST
        NPY_ENSURECOPY
        NPY_ENSUREARRAY
        NPY_ELEMENTSTRIDES
        NPY_ALIGNED
        NPY_NOTSWAPPED
        NPY_WRITEABLE
        NPY_UPDATEIFCOPY
        NPY_ARR_HAS_DESCR

        NPY_BEHAVED
        NPY_BEHAVED_NS
        NPY_CARRAY
        NPY_CARRAY_RO
        NPY_FARRAY
        NPY_FARRAY_RO
        NPY_DEFAULT

        NPY_IN_ARRAY
        NPY_OUT_ARRAY
        NPY_INOUT_ARRAY
        NPY_IN_FARRAY
        NPY_OUT_FARRAY
        NPY_INOUT_FARRAY

        NPY_UPDATE_ALL

    cdef enum:
        NPY_MAXDIMS

    npy_intp NPY_MAX_ELSIZE

    ctypedef void (*PyArray_VectorUnaryFunc)(void *, void *, npy_intp, void *,  void *)

    ctypedef class numpy.dtype [object PyArray_Descr]:
        # Use PyDataType_* macros when possible, however there are no macros
        # for accessing some of the fields, so some are defined. Please
        # ask on cython-dev if you need more.
        cdef int type_num
        cdef int itemsize "elsize"
        cdef char byteorder
        cdef object fields
        cdef tuple names

    ctypedef extern class numpy.flatiter [object PyArrayIterObject]:
        # Use through macros
        pass

    ctypedef extern class numpy.broadcast [object PyArrayMultiIterObject]:
        # Use through macros
        pass

    ctypedef struct PyArrayObject:
        # For use in situations where ndarray can't replace PyArrayObject*,
        # like PyArrayObject**.
        pass

    ctypedef class numpy.ndarray [object PyArrayObject]:
        cdef __cythonbufferdefaults__ = {"mode": "strided"}

        cdef:
            # Only taking a few of the most commonly used and stable fields.
            # One should use PyArray_* macros instead to access the C fields.
            char *data
            int ndim "nd"
            npy_intp *shape "dimensions"
            npy_intp *strides
            dtype descr
            PyObject* base

        # Note: This syntax (function definition in pxd files) is an
        # experimental exception made for __getbuffer__ and __releasebuffer__
        # -- the details of this may change.
        def __getbuffer__(ndarray self, Py_buffer* info, int flags):
            # This implementation of getbuffer is geared towards Cython
            # requirements, and does not yet fullfill the PEP.
            # In particular strided access is always provided regardless
            # of flags

            if info == NULL: return

            cdef int copy_shape, i, ndim
            cdef int endian_detector = 1
            cdef bint little_endian = ((<char*>&endian_detector)[0] != 0)

            ndim = PyArray_NDIM(self)

            if sizeof(npy_intp) != sizeof(Py_ssize_t):
                copy_shape = 1
            else:
                copy_shape = 0

            if ((flags & pybuf.PyBUF_C_CONTIGUOUS == pybuf.PyBUF_C_CONTIGUOUS)
                and not PyArray_CHKFLAGS(self, NPY_C_CONTIGUOUS)):
                raise ValueError(u"ndarray is not C contiguous")

            if ((flags & pybuf.PyBUF_F_CONTIGUOUS == pybuf.PyBUF_F_CONTIGUOUS)
                and not PyArray_CHKFLAGS(self, NPY_F_CONTIGUOUS)):
                raise ValueError(u"ndarray is not Fortran contiguous")

            info.buf = PyArray_DATA(self)
            info.ndim = ndim
            if copy_shape:
                # Allocate new buffer for strides and shape info.
                # This is allocated as one block, strides first.
                info.strides = <Py_ssize_t*>stdlib.malloc(sizeof(Py_ssize_t) * <size_t>ndim * 2)
                info.shape = info.strides + ndim
                for i in range(ndim):
                    info.strides[i] = PyArray_STRIDES(self)[i]
                    info.shape[i] = PyArray_DIMS(self)[i]
            else:
                info.strides = <Py_ssize_t*>PyArray_STRIDES(self)
                info.shape = <Py_ssize_t*>PyArray_DIMS(self)
            info.suboffsets = NULL
            info.itemsize = PyArray_ITEMSIZE(self)
            info.readonly = not PyArray_ISWRITEABLE(self)

            cdef int t
            cdef char* f = NULL
            cdef dtype descr = self.descr
            cdef list stack
            cdef int offset

            cdef bint hasfields = PyDataType_HASFIELDS(descr)

            if not hasfields and not copy_shape:
                # do not call releasebuffer
                info.obj = None
            else:
                # need to call releasebuffer
                info.obj = self

            if not hasfields:
                t = descr.type_num
                if ((descr.byteorder == c'>' and little_endian) or
                    (descr.byteorder == c'<' and not little_endian)):
                    raise ValueError(u"Non-native byte order not supported")
                if   t == NPY_BYTE:        f = "b"
                elif t == NPY_UBYTE:       f = "B"
                elif t == NPY_SHORT:       f = "h"
                elif t == NPY_USHORT:      f = "H"
                elif t == NPY_INT:         f = "i"
                elif t == NPY_UINT:        f = "I"
                elif t == NPY_LONG:        f = "l"
                elif t == NPY_ULONG:       f = "L"
                elif t == NPY_LONGLONG:    f = "q"
                elif t == NPY_ULONGLONG:   f = "Q"
                elif t == NPY_FLOAT:       f = "f"
                elif t == NPY_DOUBLE:      f = "d"
                elif t == NPY_LONGDOUBLE:  f = "g"
                elif t == NPY_CFLOAT:      f = "Zf"
                elif t == NPY_CDOUBLE:     f = "Zd"
                elif t == NPY_CLONGDOUBLE: f = "Zg"
                elif t == NPY_OBJECT:      f = "O"
                else:
                    raise ValueError(u"unknown dtype code in numpy.pxd (%d)" % t)
                info.format = f
                return
            else:
                info.format = <char*>stdlib.malloc(_buffer_format_string_len)
                info.format[0] = c'^' # Native data types, manual alignment
                offset = 0
                f = _util_dtypestring(descr, info.format + 1,
                                      info.format + _buffer_format_string_len,
                                      &offset)
                f[0] = c'\0' # Terminate format string

        def __releasebuffer__(ndarray self, Py_buffer* info):
            if PyArray_HASFIELDS(self):
                stdlib.free(info.format)
            if sizeof(npy_intp) != sizeof(Py_ssize_t):
                stdlib.free(info.strides)
                # info.shape was stored after info.strides in the same block


    ctypedef unsigned char      npy_bool

    ctypedef signed char      npy_byte
    ctypedef signed short     npy_short
    ctypedef signed int       npy_int
    ctypedef signed long      npy_long
    ctypedef signed long long npy_longlong

    ctypedef unsigned char      npy_ubyte
    ctypedef unsigned short     npy_ushort
    ctypedef unsigned int       npy_uint
    ctypedef unsigned long      npy_ulong
    ctypedef unsigned long long npy_ulonglong

    ctypedef float        npy_float
    ctypedef double       npy_double
    ctypedef long double  npy_longdouble

    ctypedef signed char        npy_int8
    ctypedef signed short       npy_int16
    ctypedef signed int         npy_int32
    ctypedef signed long long   npy_int64
    ctypedef signed long long   npy_int96
    ctypedef signed long long   npy_int128

    ctypedef unsigned char      npy_uint8
    ctypedef unsigned short     npy_uint16
    ctypedef unsigned int       npy_uint32
    ctypedef unsigned long long npy_uint64
    ctypedef unsigned long long npy_uint96
    ctypedef unsigned long long npy_uint128

    ctypedef float        npy_float32
    ctypedef double       npy_float64
    ctypedef long double  npy_float80
    ctypedef long double  npy_float96
    ctypedef long double  npy_float128

    ctypedef struct npy_cfloat:
        double real
        double imag

    ctypedef struct npy_cdouble:
        double real
        double imag

    ctypedef struct npy_clongdouble:
        double real
        double imag

    ctypedef struct npy_complex64:
        double real
        double imag

    ctypedef struct npy_complex128:
        double real
        double imag

    ctypedef struct npy_complex160:
        double real
        double imag

    ctypedef struct npy_complex192:
        double real
        double imag

    ctypedef struct npy_complex256:
        double real
        double imag

    ctypedef struct PyArray_Dims:
        npy_intp *ptr
        int len

    void import_array()

    #
    # Macros from ndarrayobject.h
    #
    bint PyArray_CHKFLAGS(ndarray m, int flags)
    bint PyArray_ISCONTIGUOUS(ndarray m)
    bint PyArray_ISWRITEABLE(ndarray m)
    bint PyArray_ISALIGNED(ndarray m)

    int PyArray_NDIM(ndarray)
    bint PyArray_ISONESEGMENT(ndarray)
    bint PyArray_ISFORTRAN(ndarray)
    int PyArray_FORTRANIF(ndarray)

    void* PyArray_DATA(ndarray)
    char* PyArray_BYTES(ndarray)
    npy_intp* PyArray_DIMS(ndarray)
    npy_intp* PyArray_STRIDES(ndarray)
    npy_intp PyArray_DIM(ndarray, size_t)
    npy_intp PyArray_STRIDE(ndarray, size_t)

    # object PyArray_BASE(ndarray) wrong refcount semantics
    # dtype PyArray_DESCR(ndarray) wrong refcount semantics
    int PyArray_FLAGS(ndarray)
    npy_intp PyArray_ITEMSIZE(ndarray)
    int PyArray_TYPE(ndarray arr)

    object PyArray_GETITEM(ndarray arr, void *itemptr)
    int PyArray_SETITEM(ndarray arr, void *itemptr, object obj)

    bint PyTypeNum_ISBOOL(int)
    bint PyTypeNum_ISUNSIGNED(int)
    bint PyTypeNum_ISSIGNED(int)
    bint PyTypeNum_ISINTEGER(int)
    bint PyTypeNum_ISFLOAT(int)
    bint PyTypeNum_ISNUMBER(int)
    bint PyTypeNum_ISSTRING(int)
    bint PyTypeNum_ISCOMPLEX(int)
    bint PyTypeNum_ISPYTHON(int)
    bint PyTypeNum_ISFLEXIBLE(int)
    bint PyTypeNum_ISUSERDEF(int)
    bint PyTypeNum_ISEXTENDED(int)
    bint PyTypeNum_ISOBJECT(int)

    bint PyDataType_ISBOOL(dtype)
    bint PyDataType_ISUNSIGNED(dtype)
    bint PyDataType_ISSIGNED(dtype)
    bint PyDataType_ISINTEGER(dtype)
    bint PyDataType_ISFLOAT(dtype)
    bint PyDataType_ISNUMBER(dtype)
    bint PyDataType_ISSTRING(dtype)
    bint PyDataType_ISCOMPLEX(dtype)
    bint PyDataType_ISPYTHON(dtype)
    bint PyDataType_ISFLEXIBLE(dtype)
    bint PyDataType_ISUSERDEF(dtype)
    bint PyDataType_ISEXTENDED(dtype)
    bint PyDataType_ISOBJECT(dtype)
    bint PyDataType_HASFIELDS(dtype)

    bint PyArray_ISBOOL(ndarray)
    bint PyArray_ISUNSIGNED(ndarray)
    bint PyArray_ISSIGNED(ndarray)
    bint PyArray_ISINTEGER(ndarray)
    bint PyArray_ISFLOAT(ndarray)
    bint PyArray_ISNUMBER(ndarray)
    bint PyArray_ISSTRING(ndarray)
    bint PyArray_ISCOMPLEX(ndarray)
    bint PyArray_ISPYTHON(ndarray)
    bint PyArray_ISFLEXIBLE(ndarray)
    bint PyArray_ISUSERDEF(ndarray)
    bint PyArray_ISEXTENDED(ndarray)
    bint PyArray_ISOBJECT(ndarray)
    bint PyArray_HASFIELDS(ndarray)

    bint PyArray_ISVARIABLE(ndarray)

    bint PyArray_SAFEALIGNEDCOPY(ndarray)
    bint PyArray_ISNBO(char)              # works on ndarray.byteorder
    bint PyArray_IsNativeByteOrder(char)  # works on ndarray.byteorder
    bint PyArray_ISNOTSWAPPED(ndarray)
    bint PyArray_ISBYTESWAPPED(ndarray)

    bint PyArray_FLAGSWAP(ndarray, int)

    bint PyArray_ISCARRAY(ndarray)
    bint PyArray_ISCARRAY_RO(ndarray)
    bint PyArray_ISFARRAY(ndarray)
    bint PyArray_ISFARRAY_RO(ndarray)
    bint PyArray_ISBEHAVED(ndarray)
    bint PyArray_ISBEHAVED_RO(ndarray)


    bint PyDataType_ISNOTSWAPPED(dtype)
    bint PyDataType_ISBYTESWAPPED(dtype)

    bint PyArray_DescrCheck(object)

    bint PyArray_Check(object)
    bint PyArray_CheckExact(object)

    # Cannot be supported due to out arg:
    # bint PyArray_HasArrayInterfaceType(object, dtype, object, object&)
    # bint PyArray_HasArrayInterface(op, out)


    bint PyArray_IsZeroDim(object)
    # Cannot be supported due to ## ## in macro:
    # bint PyArray_IsScalar(object, verbatim work)
    bint PyArray_CheckScalar(object)
    bint PyArray_IsPythonNumber(object)
    bint PyArray_IsPythonScalar(object)
    bint PyArray_IsAnyScalar(object)
    bint PyArray_CheckAnyScalar(object)
    ndarray PyArray_GETCONTIGUOUS(ndarray)
    bint PyArray_SAMESHAPE(ndarray, ndarray)
    npy_intp PyArray_SIZE(ndarray)
    npy_intp PyArray_NBYTES(ndarray)

    object PyArray_FROM_O(object)
    object PyArray_FROM_OF(object m, int flags)
    object PyArray_FROM_OT(object m, int type)
    object PyArray_FROM_OTF(object m, int type, int flags)
    object PyArray_FROMANY(object m, int type, int min, int max, int flags)
    object PyArray_ZEROS(int nd, npy_intp* dims, int type, int fortran)
    object PyArray_EMPTY(int nd, npy_intp* dims, int type, int fortran)
    void PyArray_FILLWBYTE(object, int val)
    npy_intp PyArray_REFCOUNT(object)
    object PyArray_ContiguousFromAny(op, int, int min_depth, int max_depth)
    unsigned char PyArray_EquivArrTypes(ndarray a1, ndarray a2)
    bint PyArray_EquivByteorders(int b1, int b2)
    object PyArray_SimpleNew(int nd, npy_intp* dims, int typenum)
    object PyArray_SimpleNewFromData(int nd, npy_intp* dims, int typenum, void* data)
    #object PyArray_SimpleNewFromDescr(int nd, npy_intp* dims, dtype descr)
    object PyArray_ToScalar(void* data, ndarray arr)

    void* PyArray_GETPTR1(ndarray m, npy_intp i)
    void* PyArray_GETPTR2(ndarray m, npy_intp i, npy_intp j)
    void* PyArray_GETPTR3(ndarray m, npy_intp i, npy_intp j, npy_intp k)
    void* PyArray_GETPTR4(ndarray m, npy_intp i, npy_intp j, npy_intp k, npy_intp l)

    void PyArray_XDECREF_ERR(ndarray)
    # Cannot be supported due to out arg
    # void PyArray_DESCR_REPLACE(descr)


    object PyArray_Copy(ndarray)
    object PyArray_FromObject(object op, int type, int min_depth, int max_depth)
    object PyArray_ContiguousFromObject(object op, int type, int min_depth, int max_depth)
    object PyArray_CopyFromObject(object op, int type, int min_depth, int max_depth)

    object PyArray_Cast(ndarray mp, int type_num)
    object PyArray_Take(ndarray ap, object items, int axis)
    object PyArray_Put(ndarray ap, object items, object values)

    void PyArray_ITER_RESET(flatiter it) nogil
    void PyArray_ITER_NEXT(flatiter it) nogil
    void PyArray_ITER_GOTO(flatiter it, npy_intp* destination) nogil
    void PyArray_ITER_GOTO1D(flatiter it, npy_intp ind) nogil
    void* PyArray_ITER_DATA(flatiter it) nogil
    bint PyArray_ITER_NOTDONE(flatiter it) nogil

    void PyArray_MultiIter_RESET(broadcast multi) nogil
    void PyArray_MultiIter_NEXT(broadcast multi) nogil
    void PyArray_MultiIter_GOTO(broadcast multi, npy_intp dest) nogil
    void PyArray_MultiIter_GOTO1D(broadcast multi, npy_intp ind) nogil
    void* PyArray_MultiIter_DATA(broadcast multi, npy_intp i) nogil
    void PyArray_MultiIter_NEXTi(broadcast multi, npy_intp i) nogil
    bint PyArray_MultiIter_NOTDONE(broadcast multi) nogil

    # Functions from __multiarray_api.h

    # Functions taking dtype and returning object/ndarray are disabled
    # for now as they steal dtype references. I'm conservative and disable
    # more than is probably needed until it can be checked further.
    int PyArray_SetNumericOps        (object)
    object PyArray_GetNumericOps ()
    int PyArray_INCREF (ndarray)
    int PyArray_XDECREF (ndarray)
    void PyArray_SetStringFunction (object, int)
    dtype PyArray_DescrFromType (int)
    object PyArray_TypeObjectFromType (int)
    char * PyArray_Zero (ndarray)
    char * PyArray_One (ndarray)
    #object PyArray_CastToType (ndarray, dtype, int)
    int PyArray_CastTo (ndarray, ndarray)
    int PyArray_CastAnyTo (ndarray, ndarray)
    int PyArray_CanCastSafely (int, int)
    npy_bool PyArray_CanCastTo (dtype, dtype)
    int PyArray_ObjectType (object, int)
    dtype PyArray_DescrFromObject (object, dtype)
    #ndarray* PyArray_ConvertToCommonType (object, int *)
    dtype PyArray_DescrFromScalar (object)
    dtype PyArray_DescrFromTypeObject (object)
    npy_intp PyArray_Size (object)
    #object PyArray_Scalar (void *, dtype, object)
    #object PyArray_FromScalar (object, dtype)
    void PyArray_ScalarAsCtype (object, void *)
    #int PyArray_CastScalarToCtype (object, void *, dtype)
    #int PyArray_CastScalarDirect (object, dtype, void *, int)
    object PyArray_ScalarFromObject (object)
    #PyArray_VectorUnaryFunc * PyArray_GetCastFunc (dtype, int)
    object PyArray_FromDims (int, int *, int)
    #object PyArray_FromDimsAndDataAndDescr (int, int *, dtype, char *)
    #object PyArray_FromAny (object, dtype, int, int, int, object)
    object PyArray_EnsureArray (object)
    object PyArray_EnsureAnyArray (object)
    #object PyArray_FromFile (stdio.FILE *, dtype, npy_intp, char *)
    #object PyArray_FromString (char *, npy_intp, dtype, npy_intp, char *)
    #object PyArray_FromBuffer (object, dtype, npy_intp, npy_intp)
    #object PyArray_FromIter (object, dtype, npy_intp)
    object PyArray_Return (ndarray)
    #object PyArray_GetField (ndarray, dtype, int)
    #int PyArray_SetField (ndarray, dtype, int, object)
    object PyArray_Byteswap (ndarray, npy_bool)
    object PyArray_Resize (ndarray, PyArray_Dims *, int, NPY_ORDER)
    int PyArray_MoveInto (ndarray, ndarray)
    int PyArray_CopyInto (ndarray, ndarray)
    int PyArray_CopyAnyInto (ndarray, ndarray)
    int PyArray_CopyObject (ndarray, object)
    object PyArray_NewCopy (ndarray, NPY_ORDER)
    object PyArray_ToList (ndarray)
    object PyArray_ToString (ndarray, NPY_ORDER)
    int PyArray_ToFile (ndarray, stdio.FILE *, char *, char *)
    int PyArray_Dump (object, object, int)
    object PyArray_Dumps (object, int)
    int PyArray_ValidType (int)
    void PyArray_UpdateFlags (ndarray, int)
    object PyArray_New (type, int, npy_intp *, int, npy_intp *, void *, int, int, object)
    #object PyArray_NewFromDescr (type, dtype, int, npy_intp *, npy_intp *, void *, int, object)
    #dtype PyArray_DescrNew (dtype)
    dtype PyArray_DescrNewFromType (int)
    double PyArray_GetPriority (object, double)
    object PyArray_IterNew (object)
    object PyArray_MultiIterNew (int, ...)

    int PyArray_PyIntAsInt (object)
    npy_intp PyArray_PyIntAsIntp (object)
    int PyArray_Broadcast (broadcast)
    void PyArray_FillObjectArray (ndarray, object)
    int PyArray_FillWithScalar (ndarray, object)
    npy_bool PyArray_CheckStrides (int, int, npy_intp, npy_intp, npy_intp *, npy_intp *)
    dtype PyArray_DescrNewByteorder (dtype, char)
    object PyArray_IterAllButAxis (object, int *)
    #object PyArray_CheckFromAny (object, dtype, int, int, int, object)
    #object PyArray_FromArray (ndarray, dtype, int)
    object PyArray_FromInterface (object)
    object PyArray_FromStructInterface (object)
    #object PyArray_FromArrayAttr (object, dtype, object)
    #NPY_SCALARKIND PyArray_ScalarKind (int, ndarray*)
    int PyArray_CanCoerceScalar (int, int, NPY_SCALARKIND)
    object PyArray_NewFlagsObject (object)
    npy_bool PyArray_CanCastScalar (type, type)
    #int PyArray_CompareUCS4 (npy_ucs4 *, npy_ucs4 *, register size_t)
    int PyArray_RemoveSmallest (broadcast)
    int PyArray_ElementStrides (object)
    void PyArray_Item_INCREF (char *, dtype)
    void PyArray_Item_XDECREF (char *, dtype)
    object PyArray_FieldNames (object)
    object PyArray_Transpose (ndarray, PyArray_Dims *)
    object PyArray_TakeFrom (ndarray, object, int, ndarray, NPY_CLIPMODE)
    object PyArray_PutTo (ndarray, object, object, NPY_CLIPMODE)
    object PyArray_PutMask (ndarray, object, object)
    object PyArray_Repeat (ndarray, object, int)
    object PyArray_Choose (ndarray, object, ndarray, NPY_CLIPMODE)
    int PyArray_Sort (ndarray, int, NPY_SORTKIND)
    object PyArray_ArgSort (ndarray, int, NPY_SORTKIND)
    object PyArray_SearchSorted (ndarray, object, NPY_SEARCHSIDE)
    object PyArray_ArgMax (ndarray, int, ndarray)
    object PyArray_ArgMin (ndarray, int, ndarray)
    object PyArray_Reshape (ndarray, object)
    object PyArray_Newshape (ndarray, PyArray_Dims *, NPY_ORDER)
    object PyArray_Squeeze (ndarray)
    #object PyArray_View (ndarray, dtype, type)
    object PyArray_SwapAxes (ndarray, int, int)
    object PyArray_Max (ndarray, int, ndarray)
    object PyArray_Min (ndarray, int, ndarray)
    object PyArray_Ptp (ndarray, int, ndarray)
    object PyArray_Mean (ndarray, int, int, ndarray)
    object PyArray_Trace (ndarray, int, int, int, int, ndarray)
    object PyArray_Diagonal (ndarray, int, int, int)
    object PyArray_Clip (ndarray, object, object, ndarray)
    object PyArray_Conjugate (ndarray, ndarray)
    object PyArray_Nonzero (ndarray)
    object PyArray_Std (ndarray, int, int, ndarray, int)
    object PyArray_Sum (ndarray, int, int, ndarray)
    object PyArray_CumSum (ndarray, int, int, ndarray)
    object PyArray_Prod (ndarray, int, int, ndarray)
    object PyArray_CumProd (ndarray, int, int, ndarray)
    object PyArray_All (ndarray, int, ndarray)
    object PyArray_Any (ndarray, int, ndarray)
    object PyArray_Compress (ndarray, object, int, ndarray)
    object PyArray_Flatten (ndarray, NPY_ORDER)
    object PyArray_Ravel (ndarray, NPY_ORDER)
    npy_intp PyArray_MultiplyList (npy_intp *, int)
    int PyArray_MultiplyIntList (int *, int)
    void * PyArray_GetPtr (ndarray, npy_intp*)
    int PyArray_CompareLists (npy_intp *, npy_intp *, int)
    #int PyArray_AsCArray (object*, void *, npy_intp *, int, dtype)
    #int PyArray_As1D (object*, char **, int *, int)
    #int PyArray_As2D (object*, char ***, int *, int *, int)
    int PyArray_Free (object, void *)
    #int PyArray_Converter (object, object*)
    int PyArray_IntpFromSequence (object, npy_intp *, int)
    object PyArray_Concatenate (object, int)
    object PyArray_InnerProduct (object, object)
    object PyArray_MatrixProduct (object, object)
    object PyArray_CopyAndTranspose (object)
    object PyArray_Correlate (object, object, int)
    int PyArray_TypestrConvert (int, int)
    #int PyArray_DescrConverter (object, dtype*)
    #int PyArray_DescrConverter2 (object, dtype*)
    int PyArray_IntpConverter (object, PyArray_Dims *)
    #int PyArray_BufferConverter (object, chunk)
    int PyArray_AxisConverter (object, int *)
    int PyArray_BoolConverter (object, npy_bool *)
    int PyArray_ByteorderConverter (object, char *)
    int PyArray_OrderConverter (object, NPY_ORDER *)
    unsigned char PyArray_EquivTypes (dtype, dtype)
    #object PyArray_Zeros (int, npy_intp *, dtype, int)
    #object PyArray_Empty (int, npy_intp *, dtype, int)
    object PyArray_Where (object, object, object)
    object PyArray_Arange (double, double, double, int)
    #object PyArray_ArangeObj (object, object, object, dtype)
    int PyArray_SortkindConverter (object, NPY_SORTKIND *)
    object PyArray_LexSort (object, int)
    object PyArray_Round (ndarray, int, ndarray)
    unsigned char PyArray_EquivTypenums (int, int)
    int PyArray_RegisterDataType (dtype)
    int PyArray_RegisterCastFunc (dtype, int, PyArray_VectorUnaryFunc *)
    int PyArray_RegisterCanCast (dtype, int, NPY_SCALARKIND)
    #void PyArray_InitArrFuncs (PyArray_ArrFuncs *)
    object PyArray_IntTupleFromIntp (int, npy_intp *)
    int PyArray_TypeNumFromName (char *)
    int PyArray_ClipmodeConverter (object, NPY_CLIPMODE *)
    #int PyArray_OutputConverter (object, ndarray*)
    object PyArray_BroadcastToShape (object, npy_intp *, int)
    void _PyArray_SigintHandler (int)
    void* _PyArray_GetSigintBuf ()
    #int PyArray_DescrAlignConverter (object, dtype*)
    #int PyArray_DescrAlignConverter2 (object, dtype*)
    int PyArray_SearchsideConverter (object, void *)
    object PyArray_CheckAxis (ndarray, int *, int)
    npy_intp PyArray_OverflowMultiplyList (npy_intp *, int)
    int PyArray_CompareString (char *, char *, size_t)


# Typedefs that matches the runtime dtype objects in
# the numpy module.

# The ones that are commented out needs an IFDEF function
# in Cython to enable them only on the right systems.

ctypedef npy_int8       int8_t
ctypedef npy_int16      int16_t
ctypedef npy_int32      int32_t
ctypedef npy_int64      int64_t
#ctypedef npy_int96      int96_t
#ctypedef npy_int128     int128_t

ctypedef npy_uint8      uint8_t
ctypedef npy_uint16     uint16_t
ctypedef npy_uint32     uint32_t
ctypedef npy_uint64     uint64_t
#ctypedef npy_uint96     uint96_t
#ctypedef npy_uint128    uint128_t

ctypedef npy_float32    float32_t
ctypedef npy_float64    float64_t
#ctypedef npy_float80    float80_t
#ctypedef npy_float128   float128_t

ctypedef float complex  complex64_t
ctypedef double complex complex128_t

# The int types are mapped a bit surprising --
# numpy.int corresponds to 'l' and numpy.long to 'q'
ctypedef npy_long       int_t
ctypedef npy_longlong   long_t
ctypedef npy_longlong   longlong_t

ctypedef npy_ulong      uint_t
ctypedef npy_ulonglong  ulong_t
ctypedef npy_ulonglong  ulonglong_t

ctypedef npy_intp       intp_t
ctypedef npy_uintp      uintp_t

ctypedef npy_double     float_t
ctypedef npy_double     double_t
ctypedef npy_longdouble longdouble_t

ctypedef npy_cfloat      cfloat_t
ctypedef npy_cdouble     cdouble_t
ctypedef npy_clongdouble clongdouble_t

ctypedef npy_cdouble     complex_t

cdef inline object PyArray_MultiIterNew1(a):
    return PyArray_MultiIterNew(1, <void*>a)

cdef inline object PyArray_MultiIterNew2(a, b):
    return PyArray_MultiIterNew(2, <void*>a, <void*>b)

cdef inline object PyArray_MultiIterNew3(a, b, c):
    return PyArray_MultiIterNew(3, <void*>a, <void*>b, <void*> c)

cdef inline object PyArray_MultiIterNew4(a, b, c, d):
    return PyArray_MultiIterNew(4, <void*>a, <void*>b, <void*>c, <void*> d)

cdef inline object PyArray_MultiIterNew5(a, b, c, d, e):
    return PyArray_MultiIterNew(5, <void*>a, <void*>b, <void*>c, <void*> d, <void*> e)

cdef inline char* _util_dtypestring(dtype descr, char* f, char* end, int* offset) except NULL:
    # Recursive utility function used in __getbuffer__ to get format
    # string. The new location in the format string is returned.

    cdef dtype child
    cdef int delta_offset
    cdef tuple i
    cdef int endian_detector = 1
    cdef bint little_endian = ((<char*>&endian_detector)[0] != 0)
    cdef tuple fields

    for childname in descr.names:
        fields = descr.fields[childname]
        child, new_offset = fields

        if (end - f) - <int>(new_offset - offset[0]) < 15:
            raise RuntimeError(u"Format string allocated too short, see comment in numpy.pxd")

        if ((child.byteorder == c'>' and little_endian) or
            (child.byteorder == c'<' and not little_endian)):
            raise ValueError(u"Non-native byte order not supported")
            # One could encode it in the format string and have Cython
            # complain instead, BUT: < and > in format strings also imply
            # standardized sizes for datatypes, and we rely on native in
            # order to avoid reencoding data types based on their size.
            #
            # A proper PEP 3118 exporter for other clients than Cython
            # must deal properly with this!

        # Output padding bytes
        while offset[0] < new_offset:
            f[0] = 120 # "x"; pad byte
            f += 1
            offset[0] += 1

        offset[0] += child.itemsize

        if not PyDataType_HASFIELDS(child):
            t = child.type_num
            if end - f < 5:
                raise RuntimeError(u"Format string allocated too short.")

            # Until ticket #99 is fixed, use integers to avoid warnings
            if   t == NPY_BYTE:        f[0] =  98 #"b"
            elif t == NPY_UBYTE:       f[0] =  66 #"B"
            elif t == NPY_SHORT:       f[0] = 104 #"h"
            elif t == NPY_USHORT:      f[0] =  72 #"H"
            elif t == NPY_INT:         f[0] = 105 #"i"
            elif t == NPY_UINT:        f[0] =  73 #"I"
            elif t == NPY_LONG:        f[0] = 108 #"l"
            elif t == NPY_ULONG:       f[0] = 76  #"L"
            elif t == NPY_LONGLONG:    f[0] = 113 #"q"
            elif t == NPY_ULONGLONG:   f[0] = 81  #"Q"
            elif t == NPY_FLOAT:       f[0] = 102 #"f"
            elif t == NPY_DOUBLE:      f[0] = 100 #"d"
            elif t == NPY_LONGDOUBLE:  f[0] = 103 #"g"
            elif t == NPY_CFLOAT:      f[0] = 90; f[1] = 102; f += 1 # Zf
            elif t == NPY_CDOUBLE:     f[0] = 90; f[1] = 100; f += 1 # Zd
            elif t == NPY_CLONGDOUBLE: f[0] = 90; f[1] = 103; f += 1 # Zg
            elif t == NPY_OBJECT:      f[0] = 79 #"O"
            else:
                raise ValueError(u"unknown dtype code in numpy.pxd (%d)" % t)
            f += 1
        else:
            # Cython ignores struct boundary information ("T{...}"),
            # so don't output it
            f = _util_dtypestring(child, f, end, offset)
    return f


#
# ufunc API
#

cdef extern from "numpy/ufuncobject.h":

    ctypedef void (*PyUFuncGenericFunction) (char **, npy_intp *, npy_intp *, void *)

    ctypedef extern class numpy.ufunc [object PyUFuncObject]:
        cdef:
            int nin, nout, nargs
            int identity
            PyUFuncGenericFunction *functions
            void **data
            int ntypes
            int check_return
            char *name
            char *types
            char *doc
            void *ptr
            PyObject *obj
            PyObject *userloops

    cdef enum:
        PyUFunc_Zero
        PyUFunc_One
        PyUFunc_None
        UFUNC_ERR_IGNORE
        UFUNC_ERR_WARN
        UFUNC_ERR_RAISE
        UFUNC_ERR_CALL
        UFUNC_ERR_PRINT
        UFUNC_ERR_LOG
        UFUNC_MASK_DIVIDEBYZERO
        UFUNC_MASK_OVERFLOW
        UFUNC_MASK_UNDERFLOW
        UFUNC_MASK_INVALID
        UFUNC_SHIFT_DIVIDEBYZERO
        UFUNC_SHIFT_OVERFLOW
        UFUNC_SHIFT_UNDERFLOW
        UFUNC_SHIFT_INVALID
        UFUNC_FPE_DIVIDEBYZERO
        UFUNC_FPE_OVERFLOW
        UFUNC_FPE_UNDERFLOW
        UFUNC_FPE_INVALID
        UFUNC_ERR_DEFAULT
        UFUNC_ERR_DEFAULT2

    object PyUFunc_FromFuncAndData(PyUFuncGenericFunction *,
          void **, char *, int, int, int, int, char *, char *, int)
    int PyUFunc_RegisterLoopForType(ufunc, int,
                                    PyUFuncGenericFunction, int *, void *)
    int PyUFunc_GenericFunction \
        (ufunc, PyObject *, PyObject *, PyArrayObject **)
    void PyUFunc_f_f_As_d_d \
         (char **, npy_intp *, npy_intp *, void *)
    void PyUFunc_d_d \
         (char **, npy_intp *, npy_intp *, void *)
    void PyUFunc_f_f \
         (char **, npy_intp *, npy_intp *, void *)
    void PyUFunc_g_g \
         (char **, npy_intp *, npy_intp *, void *)
    void PyUFunc_F_F_As_D_D \
         (char **, npy_intp *, npy_intp *, void *)
    void PyUFunc_F_F \
         (char **, npy_intp *, npy_intp *, void *)
    void PyUFunc_D_D \
         (char **, npy_intp *, npy_intp *, void *)
    void PyUFunc_G_G \
         (char **, npy_intp *, npy_intp *, void *)
    void PyUFunc_O_O \
         (char **, npy_intp *, npy_intp *, void *)
    void PyUFunc_ff_f_As_dd_d \
         (char **, npy_intp *, npy_intp *, void *)
    void PyUFunc_ff_f \
         (char **, npy_intp *, npy_intp *, void *)
    void PyUFunc_dd_d \
         (char **, npy_intp *, npy_intp *, void *)
    void PyUFunc_gg_g \
         (char **, npy_intp *, npy_intp *, void *)
    void PyUFunc_FF_F_As_DD_D \
         (char **, npy_intp *, npy_intp *, void *)
    void PyUFunc_DD_D \
         (char **, npy_intp *, npy_intp *, void *)
    void PyUFunc_FF_F \
         (char **, npy_intp *, npy_intp *, void *)
    void PyUFunc_GG_G \
         (char **, npy_intp *, npy_intp *, void *)
    void PyUFunc_OO_O \
         (char **, npy_intp *, npy_intp *, void *)
    void PyUFunc_O_O_method \
         (char **, npy_intp *, npy_intp *, void *)
    void PyUFunc_OO_O_method \
         (char **, npy_intp *, npy_intp *, void *)
    void PyUFunc_On_Om \
         (char **, npy_intp *, npy_intp *, void *)
    int PyUFunc_GetPyValues \
        (char *, int *, int *, PyObject **)
    int PyUFunc_checkfperr \
           (int, PyObject *, int *)
    void PyUFunc_clearfperr()
    int PyUFunc_getfperr()
    int PyUFunc_handlefperr \
        (int, PyObject *, int, int *)
    int PyUFunc_ReplaceLoopBySignature \
        (ufunc, PyUFuncGenericFunction, int *, PyUFuncGenericFunction *)
    object PyUFunc_FromFuncAndDataAndSignature \
             (PyUFuncGenericFunction *, void **, char *, int, int, int,
              int, char *, char *, int, char *)

    void import_ufunc()


cdef inline void set_array_base(ndarray arr, object base):
     cdef PyObject* baseptr
     if base is None:
         baseptr = NULL
     else:
         Py_INCREF(base) # important to do this before decref below!
         baseptr = <PyObject*>base
     Py_XDECREF(arr.base)
     arr.base = baseptr

cdef inline object get_array_base(ndarray arr):
    if arr.base is NULL:
        return None
    else:
        return <object>arr.base
