/////////////// TypeConversions.proto ///////////////

/* Type Conversion Predeclarations */

#define __Pyx_fits_Py_ssize_t(v, type, is_signed)  (    \
    (sizeof(type) < sizeof(Py_ssize_t))  ||             \
    (sizeof(type) > sizeof(Py_ssize_t) &&               \
          likely(v < (type)PY_SSIZE_T_MAX ||            \
                 v == (type)PY_SSIZE_T_MAX)  &&         \
          (!is_signed || likely(v > (type)PY_SSIZE_T_MIN ||       \
                                v == (type)PY_SSIZE_T_MIN)))  ||  \
    (sizeof(type) == sizeof(Py_ssize_t) &&              \
          (is_signed || likely(v < (type)PY_SSIZE_T_MAX ||        \
                               v == (type)PY_SSIZE_T_MAX)))  )

static CYTHON_INLINE char* __Pyx_PyObject_AsString(PyObject*);
static CYTHON_INLINE char* __Pyx_PyObject_AsStringAndSize(PyObject*, Py_ssize_t* length);

#define __Pyx_PyByteArray_FromString(s) PyByteArray_FromStringAndSize((const char*)s, strlen((const char*)s))
#define __Pyx_PyByteArray_FromStringAndSize(s, l) PyByteArray_FromStringAndSize((const char*)s, l)
#define __Pyx_PyBytes_FromString        PyBytes_FromString
#define __Pyx_PyBytes_FromStringAndSize PyBytes_FromStringAndSize
static CYTHON_INLINE PyObject* __Pyx_PyUnicode_FromString(const char*);

#if PY_MAJOR_VERSION < 3
    #define __Pyx_PyStr_FromString        __Pyx_PyBytes_FromString
    #define __Pyx_PyStr_FromStringAndSize __Pyx_PyBytes_FromStringAndSize
#else
    #define __Pyx_PyStr_FromString        __Pyx_PyUnicode_FromString
    #define __Pyx_PyStr_FromStringAndSize __Pyx_PyUnicode_FromStringAndSize
#endif

#define __Pyx_PyObject_AsSString(s)    ((signed char*) __Pyx_PyObject_AsString(s))
#define __Pyx_PyObject_AsUString(s)    ((unsigned char*) __Pyx_PyObject_AsString(s))
#define __Pyx_PyObject_FromUString(s)  __Pyx_PyObject_FromString((const char*)s)
#define __Pyx_PyBytes_FromUString(s)   __Pyx_PyBytes_FromString((const char*)s)
#define __Pyx_PyByteArray_FromUString(s)   __Pyx_PyByteArray_FromString((const char*)s)
#define __Pyx_PyStr_FromUString(s)     __Pyx_PyStr_FromString((const char*)s)
#define __Pyx_PyUnicode_FromUString(s) __Pyx_PyUnicode_FromString((const char*)s)

#if PY_MAJOR_VERSION < 3
static CYTHON_INLINE size_t __Pyx_Py_UNICODE_strlen(const Py_UNICODE *u)
{
    const Py_UNICODE *u_end = u;
    while (*u_end++) ;
    return (size_t)(u_end - u - 1);
}
#else
#define __Pyx_Py_UNICODE_strlen Py_UNICODE_strlen
#endif

#define __Pyx_PyUnicode_FromUnicode(u)       PyUnicode_FromUnicode(u, __Pyx_Py_UNICODE_strlen(u))
#define __Pyx_PyUnicode_FromUnicodeAndLength PyUnicode_FromUnicode
#define __Pyx_PyUnicode_AsUnicode            PyUnicode_AsUnicode

#define __Pyx_Owned_Py_None(b) (Py_INCREF(Py_None), Py_None)
#define __Pyx_PyBool_FromLong(b) ((b) ? (Py_INCREF(Py_True), Py_True) : (Py_INCREF(Py_False), Py_False))
static CYTHON_INLINE int __Pyx_PyObject_IsTrue(PyObject*);
static CYTHON_INLINE PyObject* __Pyx_PyNumber_Int(PyObject* x);

static CYTHON_INLINE Py_ssize_t __Pyx_PyIndex_AsSsize_t(PyObject*);
static CYTHON_INLINE PyObject * __Pyx_PyInt_FromSize_t(size_t);

#if CYTHON_COMPILING_IN_CPYTHON
#define __pyx_PyFloat_AsDouble(x) (PyFloat_CheckExact(x) ? PyFloat_AS_DOUBLE(x) : PyFloat_AsDouble(x))
#else
#define __pyx_PyFloat_AsDouble(x) PyFloat_AsDouble(x)
#endif
#define __pyx_PyFloat_AsFloat(x) ((float) __pyx_PyFloat_AsDouble(x))

#if PY_MAJOR_VERSION < 3 && __PYX_DEFAULT_STRING_ENCODING_IS_ASCII
static int __Pyx_sys_getdefaultencoding_not_ascii;
static int __Pyx_init_sys_getdefaultencoding_params(void) {
    PyObject* sys;
    PyObject* default_encoding = NULL;
    PyObject* ascii_chars_u = NULL;
    PyObject* ascii_chars_b = NULL;
    const char* default_encoding_c;
    sys = PyImport_ImportModule("sys");
    if (!sys) goto bad;
    default_encoding = PyObject_CallMethod(sys, (char*) (const char*) "getdefaultencoding", NULL);
    Py_DECREF(sys);
    if (!default_encoding) goto bad;
    default_encoding_c = PyBytes_AsString(default_encoding);
    if (!default_encoding_c) goto bad;
    if (strcmp(default_encoding_c, "ascii") == 0) {
        __Pyx_sys_getdefaultencoding_not_ascii = 0;
    } else {
        char ascii_chars[128];
        int c;
        for (c = 0; c < 128; c++) {
            ascii_chars[c] = c;
        }
        __Pyx_sys_getdefaultencoding_not_ascii = 1;
        ascii_chars_u = PyUnicode_DecodeASCII(ascii_chars, 128, NULL);
        if (!ascii_chars_u) goto bad;
        ascii_chars_b = PyUnicode_AsEncodedString(ascii_chars_u, default_encoding_c, NULL);
        if (!ascii_chars_b || !PyBytes_Check(ascii_chars_b) || memcmp(ascii_chars, PyBytes_AS_STRING(ascii_chars_b), 128) != 0) {
            PyErr_Format(
                PyExc_ValueError,
                "This module compiled with c_string_encoding=ascii, but default encoding '%.200s' is not a superset of ascii.",
                default_encoding_c);
            goto bad;
        }
        Py_DECREF(ascii_chars_u);
        Py_DECREF(ascii_chars_b);
    }
    Py_DECREF(default_encoding);
    return 0;
bad:
    Py_XDECREF(default_encoding);
    Py_XDECREF(ascii_chars_u);
    Py_XDECREF(ascii_chars_b);
    return -1;
}
#endif 

#if __PYX_DEFAULT_STRING_ENCODING_IS_DEFAULT && PY_MAJOR_VERSION >= 3
#define __Pyx_PyUnicode_FromStringAndSize(c_str, size) PyUnicode_DecodeUTF8(c_str, size, NULL)
#else
#define __Pyx_PyUnicode_FromStringAndSize(c_str, size) PyUnicode_Decode(c_str, size, __PYX_DEFAULT_STRING_ENCODING, NULL)

// __PYX_DEFAULT_STRING_ENCODING is either a user provided string constant
// or we need to look it up here
#if __PYX_DEFAULT_STRING_ENCODING_IS_DEFAULT
static char* __PYX_DEFAULT_STRING_ENCODING;

static int __Pyx_init_sys_getdefaultencoding_params(void) {
    PyObject* sys;
    PyObject* default_encoding = NULL;
    char* default_encoding_c;

    sys = PyImport_ImportModule("sys");
    if (!sys) goto bad;
    default_encoding = PyObject_CallMethod(sys, (char*) (const char*) "getdefaultencoding", NULL);
    Py_DECREF(sys);
    if (!default_encoding) goto bad;
    default_encoding_c = PyBytes_AsString(default_encoding);
    if (!default_encoding_c) goto bad;
    __PYX_DEFAULT_STRING_ENCODING = (char*) malloc(strlen(default_encoding_c));
    if (!__PYX_DEFAULT_STRING_ENCODING) goto bad;
    strcpy(__PYX_DEFAULT_STRING_ENCODING, default_encoding_c);
    Py_DECREF(default_encoding);
    return 0;
bad:
    Py_XDECREF(default_encoding);
    return -1;
}
#endif
#endif

/////////////// TypeConversions ///////////////

/* Type Conversion Functions */

static CYTHON_INLINE PyObject* __Pyx_PyUnicode_FromString(const char* c_str) {
    return __Pyx_PyUnicode_FromStringAndSize(c_str, (Py_ssize_t)strlen(c_str));
}

static CYTHON_INLINE char* __Pyx_PyObject_AsString(PyObject* o) {
    Py_ssize_t ignore;
    return __Pyx_PyObject_AsStringAndSize(o, &ignore);
}

static CYTHON_INLINE char* __Pyx_PyObject_AsStringAndSize(PyObject* o, Py_ssize_t *length) {
#if __PYX_DEFAULT_STRING_ENCODING_IS_ASCII || __PYX_DEFAULT_STRING_ENCODING_IS_DEFAULT
    if (
#if PY_MAJOR_VERSION < 3 && __PYX_DEFAULT_STRING_ENCODING_IS_ASCII
            __Pyx_sys_getdefaultencoding_not_ascii && 
#endif
            PyUnicode_Check(o)) {
#if PY_VERSION_HEX < 0x03030000
        char* defenc_c;
        // borrowed, cached reference
        PyObject* defenc = _PyUnicode_AsDefaultEncodedString(o, NULL);
        if (!defenc) return NULL;
        defenc_c = PyBytes_AS_STRING(defenc);
#if __PYX_DEFAULT_STRING_ENCODING_IS_ASCII
        {
            char* end = defenc_c + PyBytes_GET_SIZE(defenc);
            char* c;
            for (c = defenc_c; c < end; c++) {
                if ((unsigned char) (*c) >= 128) {
                    // raise the error
                    PyUnicode_AsASCIIString(o);
                    return NULL;
                }
            }
        }
#endif /*__PYX_DEFAULT_STRING_ENCODING_IS_ASCII*/
        *length = PyBytes_GET_SIZE(defenc);
        return defenc_c;
#else /* PY_VERSION_HEX < 0x03030000 */
        if (PyUnicode_READY(o) == -1) return NULL;
#if __PYX_DEFAULT_STRING_ENCODING_IS_ASCII
        if (PyUnicode_IS_ASCII(o)) {
            // cached for the lifetime of the object
            *length = PyUnicode_GET_LENGTH(o);
            return PyUnicode_AsUTF8(o);
        } else {
            // raise the error
            PyUnicode_AsASCIIString(o);
            return NULL;
        }
#else /* __PYX_DEFAULT_STRING_ENCODING_IS_ASCII */
        return PyUnicode_AsUTF8AndSize(o, length);
#endif /* __PYX_DEFAULT_STRING_ENCODING_IS_ASCII */
#endif /* PY_VERSION_HEX < 0x03030000 */
    } else
#endif /* __PYX_DEFAULT_STRING_ENCODING_IS_ASCII  || __PYX_DEFAULT_STRING_ENCODING_IS_DEFAULT */

#if !CYTHON_COMPILING_IN_PYPY
#if PY_VERSION_HEX >= 0x02060000
    if (PyByteArray_Check(o)) {
        *length = PyByteArray_GET_SIZE(o);
        return PyByteArray_AS_STRING(o);
    } else
#endif
#endif
    {
        char* result;
        int r = PyBytes_AsStringAndSize(o, &result, length);
        if (unlikely(r < 0)) {
            return NULL;
        } else {
            return result;
        }
    }
}

/* Note: __Pyx_PyObject_IsTrue is written to minimize branching. */
static CYTHON_INLINE int __Pyx_PyObject_IsTrue(PyObject* x) {
   int is_true = x == Py_True;
   if (is_true | (x == Py_False) | (x == Py_None)) return is_true;
   else return PyObject_IsTrue(x);
}

static CYTHON_INLINE PyObject* __Pyx_PyNumber_Int(PyObject* x) {
  PyNumberMethods *m;
  const char *name = NULL;
  PyObject *res = NULL;
#if PY_MAJOR_VERSION < 3
  if (PyInt_Check(x) || PyLong_Check(x))
#else
  if (PyLong_Check(x))
#endif
    return Py_INCREF(x), x;
  m = Py_TYPE(x)->tp_as_number;
#if PY_MAJOR_VERSION < 3
  if (m && m->nb_int) {
    name = "int";
    res = PyNumber_Int(x);
  }
  else if (m && m->nb_long) {
    name = "long";
    res = PyNumber_Long(x);
  }
#else
  if (m && m->nb_int) {
    name = "int";
    res = PyNumber_Long(x);
  }
#endif
  if (res) {
#if PY_MAJOR_VERSION < 3
    if (!PyInt_Check(res) && !PyLong_Check(res)) {
#else
    if (!PyLong_Check(res)) {
#endif
      PyErr_Format(PyExc_TypeError,
                   "__%.4s__ returned non-%.4s (type %.200s)",
                   name, name, Py_TYPE(res)->tp_name);
      Py_DECREF(res);
      return NULL;
    }
  }
  else if (!PyErr_Occurred()) {
    PyErr_SetString(PyExc_TypeError,
                    "an integer is required");
  }
  return res;
}

#if CYTHON_COMPILING_IN_CPYTHON && PY_MAJOR_VERSION >= 3
 #if CYTHON_USE_PYLONG_INTERNALS
  #include "longintrepr.h"
 #endif
#endif
static CYTHON_INLINE Py_ssize_t __Pyx_PyIndex_AsSsize_t(PyObject* b) {
  Py_ssize_t ival;
  PyObject *x;
#if PY_MAJOR_VERSION < 3
  if (likely(PyInt_CheckExact(b)))
      return PyInt_AS_LONG(b);
#endif
  if (likely(PyLong_CheckExact(b))) {
    #if CYTHON_COMPILING_IN_CPYTHON && PY_MAJOR_VERSION >= 3
     #if CYTHON_USE_PYLONG_INTERNALS
       switch (Py_SIZE(b)) {
       case -1: return -(sdigit)((PyLongObject*)b)->ob_digit[0];
       case  0: return 0;
       case  1: return ((PyLongObject*)b)->ob_digit[0];
       }
     #endif
    #endif
  #if PY_VERSION_HEX < 0x02060000
    return PyInt_AsSsize_t(b);
  #else
    return PyLong_AsSsize_t(b);
  #endif
  }
  x = PyNumber_Index(b);
  if (!x) return -1;
  ival = PyInt_AsSsize_t(x);
  Py_DECREF(x);
  return ival;
}

static CYTHON_INLINE PyObject * __Pyx_PyInt_FromSize_t(size_t ival) {
#if PY_VERSION_HEX < 0x02050000
   if (ival <= LONG_MAX)
       return PyInt_FromLong((long)ival);
   else {
       unsigned char *bytes = (unsigned char *) &ival;
       int one = 1; int little = (int)*(unsigned char*)&one;
       return _PyLong_FromByteArray(bytes, sizeof(size_t), little, 0);
   }
#else
   return PyInt_FromSize_t(ival);
#endif
}


/////////////// FromPyStructUtility.proto ///////////////
{{struct_type_decl}};
static {{struct_type_decl}} {{funcname}}(PyObject *);

/////////////// FromPyStructUtility ///////////////
static {{struct_type_decl}} {{funcname}}(PyObject * o) {
    {{struct_type_decl}} result;
    PyObject *value = NULL;

    if (!PyMapping_Check(o)) {
        PyErr_Format(PyExc_TypeError, "Expected %.16s, got %.200s", "a mapping", Py_TYPE(o)->tp_name);
        goto bad;
    }

    {{for member in var_entries:}}
        {{py:attr = "result." + member.cname}}

        value = PyObject_GetItem(o, PYIDENT("{{member.name}}"));
        if (!value) {
            PyErr_Format(PyExc_ValueError, \
                "No value specified for struct attribute '%.{{max(200, len(member.name))}}s'", "{{member.name}}");
            goto bad;
        }
        {{attr}} = {{member.type.from_py_function}}(value);
        if ({{member.type.error_condition(attr)}})
            goto bad;

        Py_DECREF(value);
    {{endfor}}

    return result;
bad:
    Py_XDECREF(value);
    return result;
}

/////////////// ObjectAsUCS4.proto ///////////////

static CYTHON_INLINE Py_UCS4 __Pyx_PyObject_AsPy_UCS4(PyObject*);

/////////////// ObjectAsUCS4 ///////////////

static CYTHON_INLINE Py_UCS4 __Pyx_PyObject_AsPy_UCS4(PyObject* x) {
   long ival;
   if (PyUnicode_Check(x)) {
       Py_ssize_t length;
       #if CYTHON_PEP393_ENABLED
       length = PyUnicode_GET_LENGTH(x);
       if (likely(length == 1)) {
           return PyUnicode_READ_CHAR(x, 0);
       }
       #else
       length = PyUnicode_GET_SIZE(x);
       if (likely(length == 1)) {
           return PyUnicode_AS_UNICODE(x)[0];
       }
       #if Py_UNICODE_SIZE == 2
       else if (PyUnicode_GET_SIZE(x) == 2) {
           Py_UCS4 high_val = PyUnicode_AS_UNICODE(x)[0];
           if (high_val >= 0xD800 && high_val <= 0xDBFF) {
               Py_UCS4 low_val = PyUnicode_AS_UNICODE(x)[1];
               if (low_val >= 0xDC00 && low_val <= 0xDFFF) {
                   return 0x10000 + (((high_val & ((1<<10)-1)) << 10) | (low_val & ((1<<10)-1)));
               }
           }
       }
       #endif
       #endif
       PyErr_Format(PyExc_ValueError,
                    "only single character unicode strings can be converted to Py_UCS4, "
                    "got length %" CYTHON_FORMAT_SSIZE_T "d", length);
       return (Py_UCS4)-1;
   }
   ival = __Pyx_PyInt_As_long(x);
   if (unlikely(ival < 0)) {
       if (!PyErr_Occurred())
           PyErr_SetString(PyExc_OverflowError,
                           "cannot convert negative value to Py_UCS4");
       return (Py_UCS4)-1;
   } else if (unlikely(ival > 1114111)) {
       PyErr_SetString(PyExc_OverflowError,
                       "value too large to convert to Py_UCS4");
       return (Py_UCS4)-1;
   }
   return (Py_UCS4)ival;
}

/////////////// ObjectAsPyUnicode.proto ///////////////

static CYTHON_INLINE Py_UNICODE __Pyx_PyObject_AsPy_UNICODE(PyObject*);

/////////////// ObjectAsPyUnicode ///////////////

static CYTHON_INLINE Py_UNICODE __Pyx_PyObject_AsPy_UNICODE(PyObject* x) {
    long ival;
    #if CYTHON_PEP393_ENABLED
    #if Py_UNICODE_SIZE > 2
    const long maxval = 1114111;
    #else
    const long maxval = 65535;
    #endif
    #else
    static long maxval = 0;
    #endif
    if (PyUnicode_Check(x)) {
        if (unlikely(__Pyx_PyUnicode_GET_LENGTH(x) != 1)) {
            PyErr_Format(PyExc_ValueError,
                         "only single character unicode strings can be converted to Py_UNICODE, "
                         "got length %" CYTHON_FORMAT_SSIZE_T "d", __Pyx_PyUnicode_GET_LENGTH(x));
            return (Py_UNICODE)-1;
        }
        #if CYTHON_PEP393_ENABLED
        ival = PyUnicode_READ_CHAR(x, 0);
        #else
        return PyUnicode_AS_UNICODE(x)[0];
        #endif
    } else {
        #if !CYTHON_PEP393_ENABLED
        if (unlikely(!maxval))
            maxval = (long)PyUnicode_GetMax();
        #endif
        ival = __Pyx_PyInt_As_long(x);
    }
    if (unlikely(ival < 0)) {
        if (!PyErr_Occurred())
            PyErr_SetString(PyExc_OverflowError,
                            "cannot convert negative value to Py_UNICODE");
        return (Py_UNICODE)-1;
    } else if (unlikely(ival > maxval)) {
        PyErr_SetString(PyExc_OverflowError,
                        "value too large to convert to Py_UNICODE");
        return (Py_UNICODE)-1;
    }
    return (Py_UNICODE)ival;
}


/////////////// CIntToPy.proto ///////////////

static CYTHON_INLINE PyObject* {{TO_PY_FUNCTION}}({{TYPE}} value);

/////////////// CIntToPy ///////////////

static CYTHON_INLINE PyObject* {{TO_PY_FUNCTION}}({{TYPE}} value) {
    const {{TYPE}} neg_one = ({{TYPE}}) -1, const_zero = 0;
    const int is_unsigned = neg_one > const_zero;
    if (is_unsigned) {
        if (sizeof({{TYPE}}) < sizeof(long)) {
            return PyInt_FromLong((long) value);
        } else if (sizeof({{TYPE}}) <= sizeof(unsigned long)) {
            return PyLong_FromUnsignedLong((unsigned long) value);
        } else if (sizeof({{TYPE}}) <= sizeof(unsigned long long)) {
            return PyLong_FromUnsignedLongLong((unsigned long long) value);
        }
    } else {
        if (sizeof({{TYPE}}) <= sizeof(long)) {
            return PyInt_FromLong((long) value);
        } else if (sizeof({{TYPE}}) <= sizeof(long long)) {
            return PyLong_FromLongLong((long long) value);
        }
    }
    {
        int one = 1; int little = (int)*(unsigned char *)&one;
        unsigned char *bytes = (unsigned char *)&value;
        return _PyLong_FromByteArray(bytes, sizeof({{TYPE}}),
                                     little, !is_unsigned);
    }
}


/////////////// CIntFromPyVerify ///////////////

#define __PYX_VERIFY_RETURN_INT(target_type, func_type, func)             \
    {                                                                     \
        func_type value = func(x);                                        \
        if (sizeof(target_type) < sizeof(func_type)) {                    \
            if (unlikely(value != (func_type) (target_type) value)) {     \
                func_type zero = 0;                                       \
                PyErr_SetString(PyExc_OverflowError,                      \
                    (is_unsigned && unlikely(value < zero)) ?             \
                    "can't convert negative value to " #target_type :     \
                    "value too large to convert to " #target_type);       \
                return (target_type) -1;                                  \
            }                                                             \
        }                                                                 \
        return (target_type) value;                                       \
    }


/////////////// CIntFromPy.proto ///////////////

static CYTHON_INLINE {{TYPE}} {{FROM_PY_FUNCTION}}(PyObject *);

/////////////// CIntFromPy ///////////////
//@requires: CIntFromPyVerify

#if CYTHON_COMPILING_IN_CPYTHON && PY_MAJOR_VERSION >= 3
 #if CYTHON_USE_PYLONG_INTERNALS
  #include "longintrepr.h"
 #endif
#endif
static CYTHON_INLINE {{TYPE}} {{FROM_PY_FUNCTION}}(PyObject *x) {
    const {{TYPE}} neg_one = ({{TYPE}}) -1, const_zero = 0;
    const int is_unsigned = neg_one > const_zero;
#if PY_MAJOR_VERSION < 3
    if (likely(PyInt_Check(x))) {
        if (sizeof({{TYPE}}) < sizeof(long)) {
            __PYX_VERIFY_RETURN_INT({{TYPE}}, long, PyInt_AS_LONG)
        } else {
            long val = PyInt_AS_LONG(x);
            if (is_unsigned && unlikely(val < 0)) {
                PyErr_SetString(PyExc_OverflowError,
                                "can't convert negative value to {{TYPE}}");
                return ({{TYPE}}) -1;
            }
            return ({{TYPE}}) val;
        }
    } else
#endif
    if (likely(PyLong_Check(x))) {
        if (is_unsigned) {
#if CYTHON_COMPILING_IN_CPYTHON && PY_MAJOR_VERSION >= 3
 #if CYTHON_USE_PYLONG_INTERNALS
            if (sizeof(digit) <= sizeof({{TYPE}})) {
                switch (Py_SIZE(x)) {
                    case  0: return 0;
                    case  1: return ({{TYPE}}) ((PyLongObject*)x)->ob_digit[0];
                }
            }
 #endif
#endif
            if (unlikely(Py_SIZE(x) < 0)) {
                PyErr_SetString(PyExc_OverflowError,
                                "can't convert negative value to {{TYPE}}");
                return ({{TYPE}}) -1;
            }
            if (sizeof({{TYPE}}) <= sizeof(unsigned long)) {
                __PYX_VERIFY_RETURN_INT({{TYPE}}, unsigned long, PyLong_AsUnsignedLong)
            } else if (sizeof({{TYPE}}) <= sizeof(unsigned long long)) {
                __PYX_VERIFY_RETURN_INT({{TYPE}}, unsigned long long, PyLong_AsUnsignedLongLong)
            }
        } else {
#if CYTHON_COMPILING_IN_CPYTHON && PY_MAJOR_VERSION >= 3
 #if CYTHON_USE_PYLONG_INTERNALS
            if (sizeof(digit) <= sizeof({{TYPE}})) {
                switch (Py_SIZE(x)) {
                    case  0: return 0;
                    case  1: return +({{TYPE}}) ((PyLongObject*)x)->ob_digit[0];
                    case -1: return -({{TYPE}}) ((PyLongObject*)x)->ob_digit[0];
                }
            }
 #endif
#endif
            if (sizeof({{TYPE}}) <= sizeof(long)) {
                __PYX_VERIFY_RETURN_INT({{TYPE}}, long, PyLong_AsLong)
            } else if (sizeof({{TYPE}}) <= sizeof(long long)) {
                __PYX_VERIFY_RETURN_INT({{TYPE}}, long long, PyLong_AsLongLong)
            }
        }
        {
#if CYTHON_COMPILING_IN_PYPY && !defined(_PyLong_AsByteArray)
            PyErr_SetString(PyExc_RuntimeError,
                            "_PyLong_AsByteArray() not available in PyPy, cannot convert large numbers");
#else
            {{TYPE}} val;
            PyObject *v = __Pyx_PyNumber_Int(x);
 #if PY_MAJOR_VERSION < 3
            if (likely(v) && !PyLong_Check(v)) {
                PyObject *tmp = v;
                v = PyNumber_Long(tmp);
                Py_DECREF(tmp);
            }
 #endif
            if (likely(v)) {
                int one = 1; int is_little = (int)*(unsigned char *)&one;
                unsigned char *bytes = (unsigned char *)&val;
                int ret = _PyLong_AsByteArray((PyLongObject *)v,
                                              bytes, sizeof(val),
                                              is_little, !is_unsigned);
                Py_DECREF(v);
                if (likely(!ret))
                    return val;
            }
#endif
            return ({{TYPE}}) -1;
        }
    } else {
        {{TYPE}} val;
        PyObject *tmp = __Pyx_PyNumber_Int(x);
        if (!tmp) return ({{TYPE}}) -1;
        val = {{FROM_PY_FUNCTION}}(tmp);
        Py_DECREF(tmp);
        return val;
    }
}

