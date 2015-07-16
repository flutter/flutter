
//////////////////// IncludeStringH.proto ////////////////////

#include <string.h>

//////////////////// IncludeCppStringH.proto ////////////////////

#include <string>

//////////////////// InitStrings.proto ////////////////////

static int __Pyx_InitStrings(__Pyx_StringTabEntry *t); /*proto*/

//////////////////// InitStrings ////////////////////

static int __Pyx_InitStrings(__Pyx_StringTabEntry *t) {
    while (t->p) {
        #if PY_MAJOR_VERSION < 3
        if (t->is_unicode) {
            *t->p = PyUnicode_DecodeUTF8(t->s, t->n - 1, NULL);
        } else if (t->intern) {
            *t->p = PyString_InternFromString(t->s);
        } else {
            *t->p = PyString_FromStringAndSize(t->s, t->n - 1);
        }
        #else  /* Python 3+ has unicode identifiers */
        if (t->is_unicode | t->is_str) {
            if (t->intern) {
                *t->p = PyUnicode_InternFromString(t->s);
            } else if (t->encoding) {
                *t->p = PyUnicode_Decode(t->s, t->n - 1, t->encoding, NULL);
            } else {
                *t->p = PyUnicode_FromStringAndSize(t->s, t->n - 1);
            }
        } else {
            *t->p = PyBytes_FromStringAndSize(t->s, t->n - 1);
        }
        #endif
        if (!*t->p)
            return -1;
        ++t;
    }
    return 0;
}

//////////////////// BytesContains.proto ////////////////////

static CYTHON_INLINE int __Pyx_BytesContains(PyObject* bytes, char character); /*proto*/

//////////////////// BytesContains ////////////////////

static CYTHON_INLINE int __Pyx_BytesContains(PyObject* bytes, char character) {
    const Py_ssize_t length = PyBytes_GET_SIZE(bytes);
    char* char_start = PyBytes_AS_STRING(bytes);
    char* pos;
    for (pos=char_start; pos < char_start+length; pos++) {
        if (character == pos[0]) return 1;
    }
    return 0;
}


//////////////////// PyUCS4InUnicode.proto ////////////////////

static CYTHON_INLINE int __Pyx_UnicodeContainsUCS4(PyObject* unicode, Py_UCS4 character); /*proto*/
static CYTHON_INLINE int __Pyx_PyUnicodeBufferContainsUCS4(Py_UNICODE* buffer, Py_ssize_t length, Py_UCS4 character); /*proto*/

//////////////////// PyUCS4InUnicode ////////////////////

static CYTHON_INLINE int __Pyx_UnicodeContainsUCS4(PyObject* unicode, Py_UCS4 character) {
#if CYTHON_PEP393_ENABLED
    const int kind = PyUnicode_KIND(unicode);
    if (likely(kind != PyUnicode_WCHAR_KIND)) {
        Py_ssize_t i;
        const void* udata = PyUnicode_DATA(unicode);
        const Py_ssize_t length = PyUnicode_GET_LENGTH(unicode);
        for (i=0; i < length; i++) {
            if (unlikely(character == PyUnicode_READ(kind, udata, i))) return 1;
        }
        return 0;
    }
#endif
    return __Pyx_PyUnicodeBufferContainsUCS4(
        PyUnicode_AS_UNICODE(unicode),
        PyUnicode_GET_SIZE(unicode),
        character);
}

static CYTHON_INLINE int __Pyx_PyUnicodeBufferContainsUCS4(Py_UNICODE* buffer, Py_ssize_t length, Py_UCS4 character) {
    Py_UNICODE uchar;
    Py_UNICODE* pos;
    #if Py_UNICODE_SIZE == 2
    if (character > 65535) {
        /* handle surrogate pairs for Py_UNICODE buffers in 16bit Unicode builds */
        Py_UNICODE high_val, low_val;
        high_val = (Py_UNICODE) (0xD800 | (((character - 0x10000) >> 10) & ((1<<10)-1)));
        low_val  = (Py_UNICODE) (0xDC00 | ( (character - 0x10000)        & ((1<<10)-1)));
        for (pos=buffer; pos < buffer+length-1; pos++) {
            if (unlikely(high_val == pos[0]) & unlikely(low_val == pos[1])) return 1;
        }
        return 0;
    }
    #endif
    uchar = (Py_UNICODE) character;
    for (pos=buffer; pos < buffer+length; pos++) {
        if (unlikely(uchar == pos[0])) return 1;
    }
    return 0;
}


//////////////////// PyUnicodeContains.proto ////////////////////

static CYTHON_INLINE int __Pyx_PyUnicode_Contains(PyObject* substring, PyObject* text, int eq) {
    int result = PyUnicode_Contains(text, substring);
    return unlikely(result < 0) ? result : (result == (eq == Py_EQ));
}


//////////////////// StrEquals.proto ////////////////////
//@requires: BytesEquals
//@requires: UnicodeEquals

#if PY_MAJOR_VERSION >= 3
#define __Pyx_PyString_Equals __Pyx_PyUnicode_Equals
#else
#define __Pyx_PyString_Equals __Pyx_PyBytes_Equals
#endif


//////////////////// UnicodeEquals.proto ////////////////////

static CYTHON_INLINE int __Pyx_PyUnicode_Equals(PyObject* s1, PyObject* s2, int equals); /*proto*/

//////////////////// UnicodeEquals ////////////////////
//@requires: BytesEquals

static CYTHON_INLINE int __Pyx_PyUnicode_Equals(PyObject* s1, PyObject* s2, int equals) {
#if CYTHON_COMPILING_IN_PYPY
    return PyObject_RichCompareBool(s1, s2, equals);
#else
#if PY_MAJOR_VERSION < 3
    PyObject* owned_ref = NULL;
#endif
    int s1_is_unicode, s2_is_unicode;
    if (s1 == s2) {
        /* as done by PyObject_RichCompareBool(); also catches the (interned) empty string */
        goto return_eq;
    }
    s1_is_unicode = PyUnicode_CheckExact(s1);
    s2_is_unicode = PyUnicode_CheckExact(s2);
#if PY_MAJOR_VERSION < 3
    if ((s1_is_unicode & (!s2_is_unicode)) && PyString_CheckExact(s2)) {
        owned_ref = PyUnicode_FromObject(s2);
        if (unlikely(!owned_ref))
            return -1;
        s2 = owned_ref;
        s2_is_unicode = 1;
    } else if ((s2_is_unicode & (!s1_is_unicode)) && PyString_CheckExact(s1)) {
        owned_ref = PyUnicode_FromObject(s1);
        if (unlikely(!owned_ref))
            return -1;
        s1 = owned_ref;
        s1_is_unicode = 1;
    } else if (((!s2_is_unicode) & (!s1_is_unicode))) {
        return __Pyx_PyBytes_Equals(s1, s2, equals);
    }
#endif
    if (s1_is_unicode & s2_is_unicode) {
        Py_ssize_t length;
        int kind;
        void *data1, *data2;
        #if CYTHON_PEP393_ENABLED
        if (unlikely(PyUnicode_READY(s1) < 0) || unlikely(PyUnicode_READY(s2) < 0))
            return -1;
        #endif
        length = __Pyx_PyUnicode_GET_LENGTH(s1);
        if (length != __Pyx_PyUnicode_GET_LENGTH(s2)) {
            goto return_ne;
        }
        // len(s1) == len(s2) >= 1  (empty string is interned, and "s1 is not s2")
        kind = __Pyx_PyUnicode_KIND(s1);
        if (kind != __Pyx_PyUnicode_KIND(s2)) {
            goto return_ne;
        }
        data1 = __Pyx_PyUnicode_DATA(s1);
        data2 = __Pyx_PyUnicode_DATA(s2);
        if (__Pyx_PyUnicode_READ(kind, data1, 0) != __Pyx_PyUnicode_READ(kind, data2, 0)) {
            goto return_ne;
        } else if (length == 1) {
            goto return_eq;
        } else {
            int result = memcmp(data1, data2, (size_t)(length * kind));
            #if PY_MAJOR_VERSION < 3
            Py_XDECREF(owned_ref);
            #endif
            return (equals == Py_EQ) ? (result == 0) : (result != 0);
        }
    } else if ((s1 == Py_None) & s2_is_unicode) {
        goto return_ne;
    } else if ((s2 == Py_None) & s1_is_unicode) {
        goto return_ne;
    } else {
        int result;
        PyObject* py_result = PyObject_RichCompare(s1, s2, equals);
        if (!py_result)
            return -1;
        result = __Pyx_PyObject_IsTrue(py_result);
        Py_DECREF(py_result);
        return result;
    }
return_eq:
    #if PY_MAJOR_VERSION < 3
    Py_XDECREF(owned_ref);
    #endif
    return (equals == Py_EQ);
return_ne:
    #if PY_MAJOR_VERSION < 3
    Py_XDECREF(owned_ref);
    #endif
    return (equals == Py_NE);
#endif
}


//////////////////// BytesEquals.proto ////////////////////

static CYTHON_INLINE int __Pyx_PyBytes_Equals(PyObject* s1, PyObject* s2, int equals); /*proto*/

//////////////////// BytesEquals ////////////////////
//@requires: IncludeStringH

static CYTHON_INLINE int __Pyx_PyBytes_Equals(PyObject* s1, PyObject* s2, int equals) {
#if CYTHON_COMPILING_IN_PYPY
    return PyObject_RichCompareBool(s1, s2, equals);
#else
    if (s1 == s2) {
        /* as done by PyObject_RichCompareBool(); also catches the (interned) empty string */
        return (equals == Py_EQ);
    } else if (PyBytes_CheckExact(s1) & PyBytes_CheckExact(s2)) {
        const char *ps1, *ps2;
        Py_ssize_t length = PyBytes_GET_SIZE(s1);
        if (length != PyBytes_GET_SIZE(s2))
            return (equals == Py_NE);
        // len(s1) == len(s2) >= 1  (empty string is interned, and "s1 is not s2")
        ps1 = PyBytes_AS_STRING(s1);
        ps2 = PyBytes_AS_STRING(s2);
        if (ps1[0] != ps2[0]) {
            return (equals == Py_NE);
        } else if (length == 1) {
            return (equals == Py_EQ);
        } else {
            int result = memcmp(ps1, ps2, (size_t)length);
            return (equals == Py_EQ) ? (result == 0) : (result != 0);
        }
    } else if ((s1 == Py_None) & PyBytes_CheckExact(s2)) {
        return (equals == Py_NE);
    } else if ((s2 == Py_None) & PyBytes_CheckExact(s1)) {
        return (equals == Py_NE);
    } else {
        int result;
        PyObject* py_result = PyObject_RichCompare(s1, s2, equals);
        if (!py_result)
            return -1;
        result = __Pyx_PyObject_IsTrue(py_result);
        Py_DECREF(py_result);
        return result;
    }
#endif
}

//////////////////// GetItemIntByteArray.proto ////////////////////

#define __Pyx_GetItemInt_ByteArray(o, i, type, is_signed, to_py_func, is_list, wraparound, boundscheck) \
    (__Pyx_fits_Py_ssize_t(i, type, is_signed) ? \
    __Pyx_GetItemInt_ByteArray_Fast(o, (Py_ssize_t)i, wraparound, boundscheck) : \
    (PyErr_SetString(PyExc_IndexError, "bytearray index out of range"), -1))

static CYTHON_INLINE int __Pyx_GetItemInt_ByteArray_Fast(PyObject* string, Py_ssize_t i,
                                                         int wraparound, int boundscheck);

//////////////////// GetItemIntByteArray ////////////////////

static CYTHON_INLINE int __Pyx_GetItemInt_ByteArray_Fast(PyObject* string, Py_ssize_t i,
                                                         int wraparound, int boundscheck) {
    Py_ssize_t length;
    if (wraparound | boundscheck) {
        length = PyByteArray_GET_SIZE(string);
        if (wraparound & unlikely(i < 0)) i += length;
        if ((!boundscheck) || likely((0 <= i) & (i < length))) {
            return (unsigned char) (PyByteArray_AS_STRING(string)[i]);
        } else {
            PyErr_SetString(PyExc_IndexError, "bytearray index out of range");
            return -1;
        }
    } else {
        return (unsigned char) (PyByteArray_AS_STRING(string)[i]);
    }
}


//////////////////// SetItemIntByteArray.proto ////////////////////

#define __Pyx_SetItemInt_ByteArray(o, i, v, type, is_signed, to_py_func, is_list, wraparound, boundscheck) \
    (__Pyx_fits_Py_ssize_t(i, type, is_signed) ? \
    __Pyx_SetItemInt_ByteArray_Fast(o, (Py_ssize_t)i, v, wraparound, boundscheck) : \
    (PyErr_SetString(PyExc_IndexError, "bytearray index out of range"), -1))

static CYTHON_INLINE int __Pyx_SetItemInt_ByteArray_Fast(PyObject* string, Py_ssize_t i, unsigned char v,
                                                         int wraparound, int boundscheck);

//////////////////// SetItemIntByteArray ////////////////////

static CYTHON_INLINE int __Pyx_SetItemInt_ByteArray_Fast(PyObject* string, Py_ssize_t i, unsigned char v,
                                                         int wraparound, int boundscheck) {
    Py_ssize_t length;
    if (wraparound | boundscheck) {
        length = PyByteArray_GET_SIZE(string);
        if (wraparound & unlikely(i < 0)) i += length;
        if ((!boundscheck) || likely((0 <= i) & (i < length))) {
            PyByteArray_AS_STRING(string)[i] = (char) v;
            return 0;
        } else {
            PyErr_SetString(PyExc_IndexError, "bytearray index out of range");
            return -1;
        }
    } else {
        PyByteArray_AS_STRING(string)[i] = (char) v;
        return 0;
    }
}


//////////////////// GetItemIntUnicode.proto ////////////////////

#define __Pyx_GetItemInt_Unicode(o, i, type, is_signed, to_py_func, is_list, wraparound, boundscheck) \
    (__Pyx_fits_Py_ssize_t(i, type, is_signed) ? \
    __Pyx_GetItemInt_Unicode_Fast(o, (Py_ssize_t)i, wraparound, boundscheck) : \
    (PyErr_SetString(PyExc_IndexError, "string index out of range"), (Py_UCS4)-1))

static CYTHON_INLINE Py_UCS4 __Pyx_GetItemInt_Unicode_Fast(PyObject* ustring, Py_ssize_t i,
                                                           int wraparound, int boundscheck);

//////////////////// GetItemIntUnicode ////////////////////

static CYTHON_INLINE Py_UCS4 __Pyx_GetItemInt_Unicode_Fast(PyObject* ustring, Py_ssize_t i,
                                                           int wraparound, int boundscheck) {
    Py_ssize_t length;
#if CYTHON_PEP393_ENABLED
    if (unlikely(__Pyx_PyUnicode_READY(ustring) < 0)) return (Py_UCS4)-1;
#endif
    if (wraparound | boundscheck) {
        length = __Pyx_PyUnicode_GET_LENGTH(ustring);
        if (wraparound & unlikely(i < 0)) i += length;
        if ((!boundscheck) || likely((0 <= i) & (i < length))) {
            return __Pyx_PyUnicode_READ_CHAR(ustring, i);
        } else {
            PyErr_SetString(PyExc_IndexError, "string index out of range");
            return (Py_UCS4)-1;
        }
    } else {
        return __Pyx_PyUnicode_READ_CHAR(ustring, i);
    }
}


/////////////// decode_cpp_string.proto ///////////////
//@requires: IncludeCppStringH
//@requires: decode_c_bytes

static CYTHON_INLINE PyObject* __Pyx_decode_cpp_string(
         std::string cppstring, Py_ssize_t start, Py_ssize_t stop,
         const char* encoding, const char* errors,
         PyObject* (*decode_func)(const char *s, Py_ssize_t size, const char *errors)) {
    return __Pyx_decode_c_bytes(
        cppstring.data(), cppstring.size(), start, stop, encoding, errors, decode_func);
}

/////////////// decode_c_string.proto ///////////////

static CYTHON_INLINE PyObject* __Pyx_decode_c_string(
         const char* cstring, Py_ssize_t start, Py_ssize_t stop,
         const char* encoding, const char* errors,
         PyObject* (*decode_func)(const char *s, Py_ssize_t size, const char *errors));

/////////////// decode_c_string ///////////////
//@requires: IncludeStringH

/* duplicate code to avoid calling strlen() if start >= 0 and stop >= 0 */

static CYTHON_INLINE PyObject* __Pyx_decode_c_string(
         const char* cstring, Py_ssize_t start, Py_ssize_t stop,
         const char* encoding, const char* errors,
         PyObject* (*decode_func)(const char *s, Py_ssize_t size, const char *errors)) {
    Py_ssize_t length;
    if (unlikely((start < 0) | (stop < 0))) {
        length = strlen(cstring);
        if (start < 0) {
            start += length;
            if (start < 0)
                start = 0;
        }
        if (stop < 0)
            stop += length;
    }
    length = stop - start;
    if (unlikely(length <= 0))
        return PyUnicode_FromUnicode(NULL, 0);
    cstring += start;
    if (decode_func) {
        return decode_func(cstring, length, errors);
    } else {
        return PyUnicode_Decode(cstring, length, encoding, errors);
    }
}

/////////////// decode_c_bytes.proto ///////////////

static CYTHON_INLINE PyObject* __Pyx_decode_c_bytes(
         const char* cstring, Py_ssize_t length, Py_ssize_t start, Py_ssize_t stop,
         const char* encoding, const char* errors,
         PyObject* (*decode_func)(const char *s, Py_ssize_t size, const char *errors));

/////////////// decode_c_bytes ///////////////

static CYTHON_INLINE PyObject* __Pyx_decode_c_bytes(
         const char* cstring, Py_ssize_t length, Py_ssize_t start, Py_ssize_t stop,
         const char* encoding, const char* errors,
         PyObject* (*decode_func)(const char *s, Py_ssize_t size, const char *errors)) {
    if (unlikely((start < 0) | (stop < 0))) {
        if (start < 0) {
            start += length;
            if (start < 0)
                start = 0;
        }
        if (stop < 0)
            stop += length;
    }
    if (stop > length)
        stop = length;
    length = stop - start;
    if (unlikely(length <= 0))
        return PyUnicode_FromUnicode(NULL, 0);
    cstring += start;
    if (decode_func) {
        return decode_func(cstring, length, errors);
    } else {
        return PyUnicode_Decode(cstring, length, encoding, errors);
    }
}

/////////////// decode_bytes.proto ///////////////
//@requires: decode_c_bytes

static CYTHON_INLINE PyObject* __Pyx_decode_bytes(
         PyObject* string, Py_ssize_t start, Py_ssize_t stop,
         const char* encoding, const char* errors,
         PyObject* (*decode_func)(const char *s, Py_ssize_t size, const char *errors)) {
    return __Pyx_decode_c_bytes(
        PyBytes_AS_STRING(string), PyBytes_GET_SIZE(string),
        start, stop, encoding, errors, decode_func);
}

/////////////// decode_bytearray.proto ///////////////
//@requires: decode_c_bytes

static CYTHON_INLINE PyObject* __Pyx_decode_bytearray(
         PyObject* string, Py_ssize_t start, Py_ssize_t stop,
         const char* encoding, const char* errors,
         PyObject* (*decode_func)(const char *s, Py_ssize_t size, const char *errors)) {
    return __Pyx_decode_c_bytes(
        PyByteArray_AS_STRING(string), PyByteArray_GET_SIZE(string),
        start, stop, encoding, errors, decode_func);
}

/////////////// PyUnicode_Substring.proto ///////////////

static CYTHON_INLINE PyObject* __Pyx_PyUnicode_Substring(
            PyObject* text, Py_ssize_t start, Py_ssize_t stop);

/////////////// PyUnicode_Substring ///////////////

static CYTHON_INLINE PyObject* __Pyx_PyUnicode_Substring(
            PyObject* text, Py_ssize_t start, Py_ssize_t stop) {
    Py_ssize_t length;
#if CYTHON_PEP393_ENABLED
    if (unlikely(PyUnicode_READY(text) == -1)) return NULL;
    length = PyUnicode_GET_LENGTH(text);
#else
    length = PyUnicode_GET_SIZE(text);
#endif
    if (start < 0) {
        start += length;
        if (start < 0)
            start = 0;
    }
    if (stop < 0)
        stop += length;    
    else if (stop > length)
        stop = length;
    length = stop - start;
    if (length <= 0)
        return PyUnicode_FromUnicode(NULL, 0);
#if CYTHON_PEP393_ENABLED
    return PyUnicode_FromKindAndData(PyUnicode_KIND(text),
        PyUnicode_1BYTE_DATA(text) + start*PyUnicode_KIND(text), stop-start);
#else
    return PyUnicode_FromUnicode(PyUnicode_AS_UNICODE(text)+start, stop-start);
#endif
}


/////////////// py_unicode_istitle.proto ///////////////

// Py_UNICODE_ISTITLE() doesn't match unicode.istitle() as the latter
// additionally allows character that comply with Py_UNICODE_ISUPPER()

#if PY_VERSION_HEX < 0x030200A2
static CYTHON_INLINE int __Pyx_Py_UNICODE_ISTITLE(Py_UNICODE uchar)
#else
static CYTHON_INLINE int __Pyx_Py_UNICODE_ISTITLE(Py_UCS4 uchar)
#endif
{
    return Py_UNICODE_ISTITLE(uchar) || Py_UNICODE_ISUPPER(uchar);
}


/////////////// unicode_tailmatch.proto ///////////////

// Python's unicode.startswith() and unicode.endswith() support a
// tuple of prefixes/suffixes, whereas it's much more common to
// test for a single unicode string.

static int __Pyx_PyUnicode_Tailmatch(PyObject* s, PyObject* substr,
                                     Py_ssize_t start, Py_ssize_t end, int direction) {
    if (unlikely(PyTuple_Check(substr))) {
        Py_ssize_t i, count = PyTuple_GET_SIZE(substr);
        for (i = 0; i < count; i++) {
            int result;
#if CYTHON_COMPILING_IN_CPYTHON
            result = PyUnicode_Tailmatch(s, PyTuple_GET_ITEM(substr, i),
                                         start, end, direction);
#else
            PyObject* sub = PySequence_GetItem(substr, i);
            if (unlikely(!sub)) return -1;
            result = PyUnicode_Tailmatch(s, sub, start, end, direction);
            Py_DECREF(sub);
#endif
            if (result) {
                return result;
            }
        }
        return 0;
    }
    return PyUnicode_Tailmatch(s, substr, start, end, direction);
}


/////////////// bytes_tailmatch.proto ///////////////

static int __Pyx_PyBytes_SingleTailmatch(PyObject* self, PyObject* arg, Py_ssize_t start,
                                         Py_ssize_t end, int direction)
{
    const char* self_ptr = PyBytes_AS_STRING(self);
    Py_ssize_t self_len = PyBytes_GET_SIZE(self);
    const char* sub_ptr;
    Py_ssize_t sub_len;
    int retval;

#if PY_VERSION_HEX >= 0x02060000
    Py_buffer view;
    view.obj = NULL;
#endif

    if ( PyBytes_Check(arg) ) {
        sub_ptr = PyBytes_AS_STRING(arg);
        sub_len = PyBytes_GET_SIZE(arg);
    }
#if PY_MAJOR_VERSION < 3
    // Python 2.x allows mixing unicode and str
    else if ( PyUnicode_Check(arg) ) {
        return PyUnicode_Tailmatch(self, arg, start, end, direction);
    }
#endif
    else {
#if PY_VERSION_HEX < 0x02060000
        if (unlikely(PyObject_AsCharBuffer(arg, &sub_ptr, &sub_len)))
            return -1;
#else
        if (unlikely(PyObject_GetBuffer(self, &view, PyBUF_SIMPLE) == -1))
            return -1;
        sub_ptr = (const char*) view.buf;
        sub_len = view.len;
#endif
    }

    if (end > self_len)
        end = self_len;
    else if (end < 0)
        end += self_len;
    if (end < 0)
        end = 0;
    if (start < 0)
        start += self_len;
    if (start < 0)
        start = 0;

    if (direction > 0) {
        /* endswith */
        if (end-sub_len > start)
            start = end - sub_len;
    }

    if (start + sub_len <= end)
        retval = !memcmp(self_ptr+start, sub_ptr, (size_t)sub_len);
    else
        retval = 0;

#if PY_VERSION_HEX >= 0x02060000
    if (view.obj)
        PyBuffer_Release(&view);
#endif

    return retval;
}

static int __Pyx_PyBytes_Tailmatch(PyObject* self, PyObject* substr, Py_ssize_t start,
                                   Py_ssize_t end, int direction)
{
    if (unlikely(PyTuple_Check(substr))) {
        Py_ssize_t i, count = PyTuple_GET_SIZE(substr);
        for (i = 0; i < count; i++) {
            int result;
#if CYTHON_COMPILING_IN_CPYTHON
            result = __Pyx_PyBytes_SingleTailmatch(self, PyTuple_GET_ITEM(substr, i),
                                                   start, end, direction);
#else
            PyObject* sub = PySequence_GetItem(substr, i);
            if (unlikely(!sub)) return -1;
            result = __Pyx_PyBytes_SingleTailmatch(self, sub, start, end, direction);
            Py_DECREF(sub);
#endif
            if (result) {
                return result;
            }
        }
        return 0;
    }

    return __Pyx_PyBytes_SingleTailmatch(self, substr, start, end, direction);
}


/////////////// str_tailmatch.proto ///////////////

static CYTHON_INLINE int __Pyx_PyStr_Tailmatch(PyObject* self, PyObject* arg, Py_ssize_t start,
                                               Py_ssize_t end, int direction);

/////////////// str_tailmatch ///////////////
//@requires: bytes_tailmatch
//@requires: unicode_tailmatch

static CYTHON_INLINE int __Pyx_PyStr_Tailmatch(PyObject* self, PyObject* arg, Py_ssize_t start,
                                               Py_ssize_t end, int direction)
{
    // We do not use a C compiler macro here to avoid "unused function"
    // warnings for the *_Tailmatch() function that is not being used in
    // the specific CPython version.  The C compiler will generate the same
    // code anyway, and will usually just remove the unused function.
    if (PY_MAJOR_VERSION < 3)
        return __Pyx_PyBytes_Tailmatch(self, arg, start, end, direction);
    else
        return __Pyx_PyUnicode_Tailmatch(self, arg, start, end, direction);
}


/////////////// bytes_index.proto ///////////////

static CYTHON_INLINE char __Pyx_PyBytes_GetItemInt(PyObject* bytes, Py_ssize_t index, int check_bounds) {
    if (check_bounds) {
        Py_ssize_t size = PyBytes_GET_SIZE(bytes);
        if (unlikely(index >= size) | ((index < 0) & unlikely(index < -size))) {
            PyErr_SetString(PyExc_IndexError, "string index out of range");
            return -1;
        }
    }
    if (index < 0)
        index += PyBytes_GET_SIZE(bytes);
    return PyBytes_AS_STRING(bytes)[index];
}


//////////////////// StringJoin.proto ////////////////////

#if PY_MAJOR_VERSION < 3
#define __Pyx_PyString_Join __Pyx_PyBytes_Join
#define __Pyx_PyBaseString_Join(s, v) (PyUnicode_CheckExact(s) ? PyUnicode_Join(s, v) : __Pyx_PyBytes_Join(s, v))
#else
#define __Pyx_PyString_Join PyUnicode_Join
#define __Pyx_PyBaseString_Join PyUnicode_Join
#endif

#if CYTHON_COMPILING_IN_CPYTHON
    #if PY_MAJOR_VERSION < 3
    #define __Pyx_PyBytes_Join _PyString_Join
    #else
    #define __Pyx_PyBytes_Join _PyBytes_Join
    #endif
#else
static CYTHON_INLINE PyObject* __Pyx_PyBytes_Join(PyObject* sep, PyObject* values); /*proto*/
#endif


//////////////////// StringJoin ////////////////////

#if !CYTHON_COMPILING_IN_CPYTHON
static CYTHON_INLINE PyObject* __Pyx_PyBytes_Join(PyObject* sep, PyObject* values) {
    return PyObject_CallMethodObjArgs(sep, PYIDENT("join"), values, NULL);
}
#endif


//////////////////// ByteArrayAppendObject.proto ////////////////////

static CYTHON_INLINE int __Pyx_PyByteArray_AppendObject(PyObject* bytearray, PyObject* value);

//////////////////// ByteArrayAppendObject ////////////////////
//@requires: ByteArrayAppend

static CYTHON_INLINE int __Pyx_PyByteArray_AppendObject(PyObject* bytearray, PyObject* value) {
    Py_ssize_t ival;
#if PY_MAJOR_VERSION < 3
    if (unlikely(PyString_Check(value))) {
        if (unlikely(PyString_GET_SIZE(value) != 1)) {
            PyErr_SetString(PyExc_ValueError, "string must be of size 1");
            return -1;
        }
        ival = (unsigned char) (PyString_AS_STRING(value)[0]);
    } else
#endif
    {
        // CPython calls PyNumber_Index() internally
        ival = __Pyx_PyIndex_AsSsize_t(value);
        if (unlikely((ival < 0) | (ival > 255))) {
            if (ival == -1 && PyErr_Occurred())
                return -1;
            PyErr_SetString(PyExc_ValueError, "byte must be in range(0, 256)");
            return -1;
        }
    }
    return __Pyx_PyByteArray_Append(bytearray, ival);
}

//////////////////// ByteArrayAppend.proto ////////////////////

static CYTHON_INLINE int __Pyx_PyByteArray_Append(PyObject* bytearray, int value);

//////////////////// ByteArrayAppend ////////////////////
//@requires: ObjectHandling.c::PyObjectCallMethod

static CYTHON_INLINE int __Pyx_PyByteArray_Append(PyObject* bytearray, int value) {
    PyObject *pyval, *retval;
#if CYTHON_COMPILING_IN_CPYTHON
    if (likely((value >= 0) & (value <= 255))) {
        Py_ssize_t n = Py_SIZE(bytearray);
        if (likely(n != PY_SSIZE_T_MAX)) {
            if (unlikely(PyByteArray_Resize(bytearray, n + 1) < 0))
                return -1;
            PyByteArray_AS_STRING(bytearray)[n] = value;
            return 0;
        }
    } else {
        PyErr_SetString(PyExc_ValueError, "byte must be in range(0, 256)");
        return -1;
    }
#endif
    pyval = PyInt_FromLong(value);
    if (unlikely(!pyval))
        return -1;
    retval = __Pyx_PyObject_CallMethod1(bytearray, PYIDENT("append"), pyval);
    Py_DECREF(pyval);
    if (unlikely(!retval))
        return -1;
    Py_DECREF(retval);
    return 0;
}
