/*
 * Optional optimisations of built-in functions and methods.
 *
 * Required replacements of builtins are in Builtins.c.
 *
 * General object operations and protocols are in ObjectHandling.c.
 */

/////////////// append.proto ///////////////

static CYTHON_INLINE int __Pyx_PyObject_Append(PyObject* L, PyObject* x); /*proto*/

/////////////// append ///////////////
//@requires: ListAppend
//@requires: ObjectHandling.c::PyObjectCallMethod

static CYTHON_INLINE int __Pyx_PyObject_Append(PyObject* L, PyObject* x) {
    if (likely(PyList_CheckExact(L))) {
        if (unlikely(__Pyx_PyList_Append(L, x) < 0)) return -1;
    } else {
        PyObject* retval = __Pyx_PyObject_CallMethod1(L, PYIDENT("append"), x);
        if (unlikely(!retval))
            return -1;
        Py_DECREF(retval);
    }
    return 0;
}

/////////////// ListAppend.proto ///////////////

#if CYTHON_COMPILING_IN_CPYTHON
static CYTHON_INLINE int __Pyx_PyList_Append(PyObject* list, PyObject* x) {
    PyListObject* L = (PyListObject*) list;
    Py_ssize_t len = Py_SIZE(list);
    if (likely(L->allocated > len) & likely(len > (L->allocated >> 1))) {
        Py_INCREF(x);
        PyList_SET_ITEM(list, len, x);
        Py_SIZE(list) = len+1;
        return 0;
    }
    return PyList_Append(list, x);
}
#else
#define __Pyx_PyList_Append(L,x) PyList_Append(L,x)
#endif

/////////////// ListCompAppend.proto ///////////////

#if CYTHON_COMPILING_IN_CPYTHON
static CYTHON_INLINE int __Pyx_ListComp_Append(PyObject* list, PyObject* x) {
    PyListObject* L = (PyListObject*) list;
    Py_ssize_t len = Py_SIZE(list);
    if (likely(L->allocated > len)) {
        Py_INCREF(x);
        PyList_SET_ITEM(list, len, x);
        Py_SIZE(list) = len+1;
        return 0;
    }
    return PyList_Append(list, x);
}
#else
#define __Pyx_ListComp_Append(L,x) PyList_Append(L,x)
#endif

//////////////////// ListExtend.proto ////////////////////

static CYTHON_INLINE int __Pyx_PyList_Extend(PyObject* L, PyObject* v) {
#if CYTHON_COMPILING_IN_CPYTHON
    PyObject* none = _PyList_Extend((PyListObject*)L, v);
    if (unlikely(!none))
        return -1;
    Py_DECREF(none);
    return 0;
#else
    return PyList_SetSlice(L, PY_SSIZE_T_MAX, PY_SSIZE_T_MAX, v);
#endif
}

/////////////// pop.proto ///////////////

#define __Pyx_PyObject_Pop(L) (PyList_CheckExact(L) ? \
    __Pyx_PyList_Pop(L) : __Pyx__PyObject_Pop(L))

static CYTHON_INLINE PyObject* __Pyx_PyList_Pop(PyObject* L); /*proto*/
static CYTHON_INLINE PyObject* __Pyx__PyObject_Pop(PyObject* L); /*proto*/

/////////////// pop ///////////////
//@requires: ObjectHandling.c::PyObjectCallMethod

static CYTHON_INLINE PyObject* __Pyx__PyObject_Pop(PyObject* L) {
#if CYTHON_COMPILING_IN_CPYTHON && PY_VERSION_HEX >= 0x02050000
    if (Py_TYPE(L) == &PySet_Type) {
        return PySet_Pop(L);
    }
#endif
    return __Pyx_PyObject_CallMethod0(L, PYIDENT("pop"));
}

static CYTHON_INLINE PyObject* __Pyx_PyList_Pop(PyObject* L) {
#if CYTHON_COMPILING_IN_CPYTHON && PY_VERSION_HEX >= 0x02040000
    /* Check that both the size is positive and no reallocation shrinking needs to be done. */
    if (likely(PyList_GET_SIZE(L) > (((PyListObject*)L)->allocated >> 1))) {
        Py_SIZE(L) -= 1;
        return PyList_GET_ITEM(L, PyList_GET_SIZE(L));
    }
#endif
    return __Pyx_PyObject_CallMethod0(L, PYIDENT("pop"));
}


/////////////// pop_index.proto ///////////////

#define __Pyx_PyObject_PopIndex(L, ix) (PyList_CheckExact(L) ? \
    __Pyx_PyList_PopIndex(L, ix) : __Pyx__PyObject_PopIndex(L, ix))

static PyObject* __Pyx_PyList_PopIndex(PyObject* L, Py_ssize_t ix); /*proto*/
static PyObject* __Pyx__PyObject_PopIndex(PyObject* L, Py_ssize_t ix); /*proto*/

/////////////// pop_index ///////////////
//@requires: ObjectHandling.c::PyObjectCallMethod

static PyObject* __Pyx__PyObject_PopIndex(PyObject* L, Py_ssize_t ix) {
    PyObject *r, *py_ix;
    py_ix = PyInt_FromSsize_t(ix);
    if (!py_ix) return NULL;
    r = __Pyx_PyObject_CallMethod1(L, PYIDENT("pop"), py_ix);
    Py_DECREF(py_ix);
    return r;
}

static PyObject* __Pyx_PyList_PopIndex(PyObject* L, Py_ssize_t ix) {
#if CYTHON_COMPILING_IN_CPYTHON
    Py_ssize_t size = PyList_GET_SIZE(L);
    if (likely(size > (((PyListObject*)L)->allocated >> 1))) {
        Py_ssize_t cix = ix;
        if (cix < 0) {
            cix += size;
        }
        if (likely(0 <= cix && cix < size)) {
            PyObject* v = PyList_GET_ITEM(L, cix);
            Py_SIZE(L) -= 1;
            size -= 1;
            memmove(&PyList_GET_ITEM(L, cix), &PyList_GET_ITEM(L, cix+1), (size_t)(size-cix)*sizeof(PyObject*));
            return v;
        }
    }
#endif
    return __Pyx__PyObject_PopIndex(L, ix);
}


/////////////// dict_getitem_default.proto ///////////////

static PyObject* __Pyx_PyDict_GetItemDefault(PyObject* d, PyObject* key, PyObject* default_value); /*proto*/

/////////////// dict_getitem_default ///////////////

static PyObject* __Pyx_PyDict_GetItemDefault(PyObject* d, PyObject* key, PyObject* default_value) {
    PyObject* value;
#if PY_MAJOR_VERSION >= 3
    value = PyDict_GetItemWithError(d, key);
    if (unlikely(!value)) {
        if (unlikely(PyErr_Occurred()))
            return NULL;
        value = default_value;
    }
    Py_INCREF(value);
#else
    if (PyString_CheckExact(key) || PyUnicode_CheckExact(key) || PyInt_CheckExact(key)) {
        /* these presumably have safe hash functions */
        value = PyDict_GetItem(d, key);
        if (unlikely(!value)) {
            value = default_value;
        }
        Py_INCREF(value);
    } else {
        if (default_value == Py_None)
            default_value = NULL;
        value = PyObject_CallMethodObjArgs(
            d, PYIDENT("get"), key, default_value, NULL);
    }
#endif
    return value;
}


/////////////// dict_setdefault.proto ///////////////

static CYTHON_INLINE PyObject *__Pyx_PyDict_SetDefault(PyObject *d, PyObject *key, PyObject *default_value, int is_safe_type); /*proto*/

/////////////// dict_setdefault ///////////////
//@requires: ObjectHandling.c::PyObjectCallMethod

static CYTHON_INLINE PyObject *__Pyx_PyDict_SetDefault(PyObject *d, PyObject *key, PyObject *default_value,
                                                       CYTHON_UNUSED int is_safe_type) {
    PyObject* value;
#if PY_VERSION_HEX >= 0x030400A0
    // we keep the method call at the end to avoid "unused" C compiler warnings
    if (1) {
        value = PyDict_SetDefault(d, key, default_value);
        if (unlikely(!value)) return NULL;
        Py_INCREF(value);
#else
    if (is_safe_type == 1 || (is_safe_type == -1 &&
        /* the following builtins presumably have repeatably safe and fast hash functions */
#if PY_MAJOR_VERSION >= 3
            (PyUnicode_CheckExact(key) || PyString_CheckExact(key) || PyLong_CheckExact(key)))) {
        value = PyDict_GetItemWithError(d, key);
        if (unlikely(!value)) {
            if (unlikely(PyErr_Occurred()))
                return NULL;
            if (unlikely(PyDict_SetItem(d, key, default_value) == -1))
                return NULL;
            value = default_value;
        }
        Py_INCREF(value);
#else
            (PyString_CheckExact(key) || PyUnicode_CheckExact(key) || PyInt_CheckExact(key) || PyLong_CheckExact(key)))) {
        value = PyDict_GetItem(d, key);
        if (unlikely(!value)) {
            if (unlikely(PyDict_SetItem(d, key, default_value) == -1))
                return NULL;
            value = default_value;
        }
        Py_INCREF(value);
#endif
#endif
    } else {
        value = __Pyx_PyObject_CallMethod2(d, PYIDENT("setdefault"), key, default_value);
    }
    return value;
}


/////////////// py_dict_clear.proto ///////////////

#define __Pyx_PyDict_Clear(d) (PyDict_Clear(d), 0)

/////////////// dict_iter.proto ///////////////

static CYTHON_INLINE PyObject* __Pyx_dict_iterator(PyObject* dict, int is_dict, PyObject* method_name,
                                                   Py_ssize_t* p_orig_length, int* p_is_dict);
static CYTHON_INLINE int __Pyx_dict_iter_next(PyObject* dict_or_iter, Py_ssize_t orig_length, Py_ssize_t* ppos,
                                              PyObject** pkey, PyObject** pvalue, PyObject** pitem, int is_dict);

/////////////// dict_iter ///////////////
//@requires: ObjectHandling.c::UnpackTuple2
//@requires: ObjectHandling.c::IterFinish
//@requires: ObjectHandling.c::PyObjectCallMethod

static CYTHON_INLINE PyObject* __Pyx_dict_iterator(PyObject* iterable, int is_dict, PyObject* method_name,
                                                   Py_ssize_t* p_orig_length, int* p_source_is_dict) {
    is_dict = is_dict || likely(PyDict_CheckExact(iterable));
    *p_source_is_dict = is_dict;
#if !CYTHON_COMPILING_IN_PYPY
    if (is_dict) {
        *p_orig_length = PyDict_Size(iterable);
        Py_INCREF(iterable);
        return iterable;
    }
#endif
    *p_orig_length = 0;
    if (method_name) {
        PyObject* iter;
        iterable = __Pyx_PyObject_CallMethod0(iterable, method_name);
        if (!iterable)
            return NULL;
#if !CYTHON_COMPILING_IN_PYPY
        if (PyTuple_CheckExact(iterable) || PyList_CheckExact(iterable))
            return iterable;
#endif
        iter = PyObject_GetIter(iterable);
        Py_DECREF(iterable);
        return iter;
    }
    return PyObject_GetIter(iterable);
}

static CYTHON_INLINE int __Pyx_dict_iter_next(PyObject* iter_obj, Py_ssize_t orig_length, Py_ssize_t* ppos,
                                              PyObject** pkey, PyObject** pvalue, PyObject** pitem, int source_is_dict) {
    PyObject* next_item;
#if !CYTHON_COMPILING_IN_PYPY
    if (source_is_dict) {
        PyObject *key, *value;
        if (unlikely(orig_length != PyDict_Size(iter_obj))) {
            PyErr_SetString(PyExc_RuntimeError, "dictionary changed size during iteration");
            return -1;
        }
        if (unlikely(!PyDict_Next(iter_obj, ppos, &key, &value))) {
            return 0;
        }
        if (pitem) {
            PyObject* tuple = PyTuple_New(2);
            if (unlikely(!tuple)) {
                return -1;
            }
            Py_INCREF(key);
            Py_INCREF(value);
            PyTuple_SET_ITEM(tuple, 0, key);
            PyTuple_SET_ITEM(tuple, 1, value);
            *pitem = tuple;
        } else {
            if (pkey) {
                Py_INCREF(key);
                *pkey = key;
            }
            if (pvalue) {
                Py_INCREF(value);
                *pvalue = value;
            }
        }
        return 1;
    } else if (PyTuple_CheckExact(iter_obj)) {
        Py_ssize_t pos = *ppos;
        if (unlikely(pos >= PyTuple_GET_SIZE(iter_obj))) return 0;
        *ppos = pos + 1;
        next_item = PyTuple_GET_ITEM(iter_obj, pos);
        Py_INCREF(next_item);
    } else if (PyList_CheckExact(iter_obj)) {
        Py_ssize_t pos = *ppos;
        if (unlikely(pos >= PyList_GET_SIZE(iter_obj))) return 0;
        *ppos = pos + 1;
        next_item = PyList_GET_ITEM(iter_obj, pos);
        Py_INCREF(next_item);
    } else
#endif
    {
        next_item = PyIter_Next(iter_obj);
        if (unlikely(!next_item)) {
            return __Pyx_IterFinish();
        }
    }
    if (pitem) {
        *pitem = next_item;
    } else if (pkey && pvalue) {
        if (__Pyx_unpack_tuple2(next_item, pkey, pvalue, source_is_dict, source_is_dict, 1))
            return -1;
    } else if (pkey) {
        *pkey = next_item;
    } else {
        *pvalue = next_item;
    }
    return 1;
}


/////////////// unicode_iter.proto ///////////////

static CYTHON_INLINE int __Pyx_init_unicode_iteration(
    PyObject* ustring, Py_ssize_t *length, void** data, int *kind); /* proto */

/////////////// unicode_iter ///////////////

static CYTHON_INLINE int __Pyx_init_unicode_iteration(
    PyObject* ustring, Py_ssize_t *length, void** data, int *kind) {
#if CYTHON_PEP393_ENABLED
    if (unlikely(__Pyx_PyUnicode_READY(ustring) < 0)) return -1;
    *kind   = PyUnicode_KIND(ustring);
    *length = PyUnicode_GET_LENGTH(ustring);
    *data   = PyUnicode_DATA(ustring);
#else
    *kind   = 0;
    *length = PyUnicode_GET_SIZE(ustring);
    *data   = (void*)PyUnicode_AS_UNICODE(ustring);
#endif
    return 0;
}

/////////////// pyobject_as_double.proto ///////////////

static double __Pyx__PyObject_AsDouble(PyObject* obj); /* proto */

#if CYTHON_COMPILING_IN_PYPY
#define __Pyx_PyObject_AsDouble(obj) \
(likely(PyFloat_CheckExact(obj)) ? PyFloat_AS_DOUBLE(obj) : \
 likely(PyInt_CheckExact(obj)) ? \
 PyFloat_AsDouble(obj) : __Pyx__PyObject_AsDouble(obj))
#else
#define __Pyx_PyObject_AsDouble(obj) \
((likely(PyFloat_CheckExact(obj))) ? \
 PyFloat_AS_DOUBLE(obj) : __Pyx__PyObject_AsDouble(obj))
#endif

/////////////// pyobject_as_double ///////////////

static double __Pyx__PyObject_AsDouble(PyObject* obj) {
    PyObject* float_value;
#if CYTHON_COMPILING_IN_PYPY
    float_value = PyNumber_Float(obj);
#else
    PyNumberMethods *nb = Py_TYPE(obj)->tp_as_number;
    if (likely(nb) && likely(nb->nb_float)) {
        float_value = nb->nb_float(obj);
        if (likely(float_value) && unlikely(!PyFloat_Check(float_value))) {
            PyErr_Format(PyExc_TypeError,
                "__float__ returned non-float (type %.200s)",
                Py_TYPE(float_value)->tp_name);
            Py_DECREF(float_value);
            goto bad;
        }
    } else if (PyUnicode_CheckExact(obj) || PyBytes_CheckExact(obj)) {
#if PY_MAJOR_VERSION >= 3
        float_value = PyFloat_FromString(obj);
#else
        float_value = PyFloat_FromString(obj, 0);
#endif
    } else {
        PyObject* args = PyTuple_New(1);
        if (unlikely(!args)) goto bad;
        PyTuple_SET_ITEM(args, 0, obj);
        float_value = PyObject_Call((PyObject*)&PyFloat_Type, args, 0);
        PyTuple_SET_ITEM(args, 0, 0);
        Py_DECREF(args);
    }
#endif
    if (likely(float_value)) {
        double value = PyFloat_AS_DOUBLE(float_value);
        Py_DECREF(float_value);
        return value;
    }
bad:
    return (double)-1;
}
