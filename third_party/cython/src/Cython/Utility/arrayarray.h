/////////////// ArrayAPI.proto ///////////////

// arrayarray.h
//
//    Artificial C-API for Python's <array.array> type,
//    used by array.pxd
//
//    last changes: 2009-05-15 rk
//                  2012-05-02 andreasvc
//                  (see revision control)
//

#ifndef _ARRAYARRAY_H
#define _ARRAYARRAY_H

// These two forward declarations are explicitly handled in the type
// declaration code, as including them here is too late for cython-defined
// types to use them.
// struct arrayobject;
// typedef struct arrayobject arrayobject;

// All possible arraydescr values are defined in the vector "descriptors"
// below.  That's defined later because the appropriate get and set
// functions aren't visible yet.
typedef struct arraydescr {
    int typecode;
    int itemsize;
    PyObject * (*getitem)(struct arrayobject *, Py_ssize_t);
    int (*setitem)(struct arrayobject *, Py_ssize_t, PyObject *);
#if PY_VERSION_HEX >= 0x03000000
    char *formats;
#endif    
} arraydescr;


struct arrayobject {
    PyObject_HEAD
    Py_ssize_t ob_size;
    union {
        char *ob_item;
        float *as_floats;
        double *as_doubles;
        int *as_ints;
        unsigned int *as_uints;
        unsigned char *as_uchars;
        signed char *as_schars;
        char *as_chars;
        unsigned long *as_ulongs;
        long *as_longs;
        short *as_shorts;
        unsigned short *as_ushorts;
        Py_UNICODE *as_pyunicodes;
        void *as_voidptr;
    } data;
    Py_ssize_t allocated;
    struct arraydescr *ob_descr;
    PyObject *weakreflist; /* List of weak references */
#if PY_VERSION_HEX >= 0x03000000
        int ob_exports;  /* Number of exported buffers */
#endif
};

#ifndef NO_NEWARRAY_INLINE
//  fast creation of a new array
static CYTHON_INLINE PyObject * newarrayobject(PyTypeObject *type, Py_ssize_t size,
    struct arraydescr *descr) {
    arrayobject *op;
    size_t nbytes;

    if (size < 0) {
        PyErr_BadInternalCall();
        return NULL;
    }

    nbytes = size * descr->itemsize;
    // Check for overflow
    if (nbytes / descr->itemsize != (size_t)size) {
        return PyErr_NoMemory();
    }
    op = (arrayobject *) type->tp_alloc(type, 0);
    if (op == NULL) {
        return NULL;
    }
    op->ob_descr = descr;
    op->allocated = size;
    op->weakreflist = NULL;
    op->ob_size = size;
    if (size <= 0) {
        op->data.ob_item = NULL;
    }
    else {
        op->data.ob_item = PyMem_NEW(char, nbytes);
        if (op->data.ob_item == NULL) {
            Py_DECREF(op);
            return PyErr_NoMemory();
        }
    }
    return (PyObject *) op;
}
#else
PyObject* newarrayobject(PyTypeObject *type, Py_ssize_t size,
    struct arraydescr *descr);
#endif /* ifndef NO_NEWARRAY_INLINE */

// fast resize (reallocation to the point)
// not designed for filing small increments (but for fast opaque array apps)
static CYTHON_INLINE int resize(arrayobject *self, Py_ssize_t n) {
    void *items = (void*) self->data.ob_item;
    PyMem_Resize(items, char, (size_t)(n * self->ob_descr->itemsize));
    if (items == NULL) {
        PyErr_NoMemory();
        return -1;
    }    
    self->data.ob_item = (char*) items;
    self->ob_size = n;
    self->allocated = n;
    return 0;
}

// suitable for small increments; over allocation 50% ;
// Remains non-smart in Python 2.3- ; but exists for compatibility
static CYTHON_INLINE int resize_smart(arrayobject *self, Py_ssize_t n) {
    void *items = (void*) self->data.ob_item;
    Py_ssize_t newsize;
    if (n < self->allocated) {
        if (n*4 > self->allocated) {
            self->ob_size = n;
            return 0;
        }
    }
    newsize = n  * 3 / 2 + 1;
    PyMem_Resize(items, char, (size_t)(newsize * self->ob_descr->itemsize));
    if (items == NULL) {
        PyErr_NoMemory();
        return -1;
    }    
    self->data.ob_item = (char*) items;
    self->ob_size = n;
    self->allocated = newsize;
    return 0;
}

#endif
/* _ARRAYARRAY_H */
