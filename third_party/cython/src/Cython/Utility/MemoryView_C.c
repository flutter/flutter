////////// MemviewSliceStruct.proto //////////

/* memoryview slice struct */
struct {{memview_struct_name}};

typedef struct {
  struct {{memview_struct_name}} *memview;
  char *data;
  Py_ssize_t shape[{{max_dims}}];
  Py_ssize_t strides[{{max_dims}}];
  Py_ssize_t suboffsets[{{max_dims}}];
} {{memviewslice_name}};


/////////// Atomics.proto /////////////

#include <pythread.h>

#ifndef CYTHON_ATOMICS
    #define CYTHON_ATOMICS 1
#endif

#define __pyx_atomic_int_type int
// todo: Portland pgcc, maybe OS X's OSAtomicIncrement32,
//       libatomic + autotools-like distutils support? Such a pain...
#if CYTHON_ATOMICS && __GNUC__ >= 4 && (__GNUC_MINOR__ > 1 ||           \
                    (__GNUC_MINOR__ == 1 && __GNUC_PATCHLEVEL >= 2)) && \
                    !defined(__i386__)
    /* gcc >= 4.1.2 */
    #define __pyx_atomic_incr_aligned(value, lock) __sync_fetch_and_add(value, 1)
    #define __pyx_atomic_decr_aligned(value, lock) __sync_fetch_and_sub(value, 1)

    #ifdef __PYX_DEBUG_ATOMICS
        #warning "Using GNU atomics"
    #endif
#elif CYTHON_ATOMICS && MSC_VER
    /* msvc */
    #include <Windows.h>
    #define __pyx_atomic_int_type LONG
    #define __pyx_atomic_incr_aligned(value, lock) InterlockedIncrement(value)
    #define __pyx_atomic_decr_aligned(value, lock) InterlockedDecrement(value)

    #ifdef __PYX_DEBUG_ATOMICS
        #warning "Using MSVC atomics"
    #endif
#elif CYTHON_ATOMICS && (defined(__ICC) || defined(__INTEL_COMPILER)) && 0
    #define __pyx_atomic_incr_aligned(value, lock) _InterlockedIncrement(value)
    #define __pyx_atomic_decr_aligned(value, lock) _InterlockedDecrement(value)

    #ifdef __PYX_DEBUG_ATOMICS
        #warning "Using Intel atomics"
    #endif
#else
    #undef CYTHON_ATOMICS
    #define CYTHON_ATOMICS 0

    #ifdef __PYX_DEBUG_ATOMICS
        #warning "Not using atomics"
    #endif
#endif

typedef volatile __pyx_atomic_int_type __pyx_atomic_int;

#if CYTHON_ATOMICS
    #define __pyx_add_acquisition_count(memview) \
             __pyx_atomic_incr_aligned(__pyx_get_slice_count_pointer(memview), memview->lock)
    #define __pyx_sub_acquisition_count(memview) \
            __pyx_atomic_decr_aligned(__pyx_get_slice_count_pointer(memview), memview->lock)
#else
    #define __pyx_add_acquisition_count(memview) \
            __pyx_add_acquisition_count_locked(__pyx_get_slice_count_pointer(memview), memview->lock)
    #define __pyx_sub_acquisition_count(memview) \
            __pyx_sub_acquisition_count_locked(__pyx_get_slice_count_pointer(memview), memview->lock)
#endif


/////////////// ObjectToMemviewSlice.proto ///////////////

static CYTHON_INLINE {{memviewslice_name}} {{funcname}}(PyObject *);


////////// MemviewSliceInit.proto //////////

#define __Pyx_BUF_MAX_NDIMS %(BUF_MAX_NDIMS)d

#define __Pyx_MEMVIEW_DIRECT   1
#define __Pyx_MEMVIEW_PTR      2
#define __Pyx_MEMVIEW_FULL     4
#define __Pyx_MEMVIEW_CONTIG   8
#define __Pyx_MEMVIEW_STRIDED  16
#define __Pyx_MEMVIEW_FOLLOW   32

#define __Pyx_IS_C_CONTIG 1
#define __Pyx_IS_F_CONTIG 2

static int __Pyx_init_memviewslice(
                struct __pyx_memoryview_obj *memview,
                int ndim,
                __Pyx_memviewslice *memviewslice,
                int memview_is_new_reference);

static CYTHON_INLINE int __pyx_add_acquisition_count_locked(
    __pyx_atomic_int *acquisition_count, PyThread_type_lock lock);
static CYTHON_INLINE int __pyx_sub_acquisition_count_locked(
    __pyx_atomic_int *acquisition_count, PyThread_type_lock lock);

#define __pyx_get_slice_count_pointer(memview) (memview->acquisition_count_aligned_p)
#define __pyx_get_slice_count(memview) (*__pyx_get_slice_count_pointer(memview))
#define __PYX_INC_MEMVIEW(slice, have_gil) __Pyx_INC_MEMVIEW(slice, have_gil, __LINE__)
#define __PYX_XDEC_MEMVIEW(slice, have_gil) __Pyx_XDEC_MEMVIEW(slice, have_gil, __LINE__)
static CYTHON_INLINE void __Pyx_INC_MEMVIEW({{memviewslice_name}} *, int, int);
static CYTHON_INLINE void __Pyx_XDEC_MEMVIEW({{memviewslice_name}} *, int, int);


/////////////// MemviewSliceIndex.proto ///////////////

static CYTHON_INLINE char *__pyx_memviewslice_index_full(
    const char *bufp, Py_ssize_t idx, Py_ssize_t stride, Py_ssize_t suboffset);


/////////////// ObjectToMemviewSlice ///////////////
//@requires: MemviewSliceValidateAndInit

static CYTHON_INLINE {{memviewslice_name}} {{funcname}}(PyObject *obj) {
    {{memviewslice_name}} result = {{memslice_init}};
    __Pyx_BufFmt_StackElem stack[{{struct_nesting_depth}}];
    int axes_specs[] = { {{axes_specs}} };
    int retcode;

    if (obj == Py_None) {
        /* We don't bother to refcount None */
        result.memview = (struct __pyx_memoryview_obj *) Py_None;
        return result;
    }

    retcode = __Pyx_ValidateAndInit_memviewslice(axes_specs, {{c_or_f_flag}},
                                                 {{buf_flag}}, {{ndim}},
                                                 &{{dtype_typeinfo}}, stack,
                                                 &result, obj);

    if (unlikely(retcode == -1))
        goto __pyx_fail;

    return result;
__pyx_fail:
    result.memview = NULL;
    result.data = NULL;
    return result;
}


/////////////// MemviewSliceValidateAndInit.proto ///////////////

static int __Pyx_ValidateAndInit_memviewslice(
                int *axes_specs,
                int c_or_f_flag,
                int buf_flags,
                int ndim,
                __Pyx_TypeInfo *dtype,
                __Pyx_BufFmt_StackElem stack[],
                __Pyx_memviewslice *memviewslice,
                PyObject *original_obj);

/////////////// MemviewSliceValidateAndInit ///////////////
//@requires: Buffer.c::TypeInfoCompare

static int
__pyx_check_strides(Py_buffer *buf, int dim, int ndim, int spec)
{
    if (buf->shape[dim] <= 1)
        return 1;

    if (buf->strides) {
        if (spec & __Pyx_MEMVIEW_CONTIG) {
            if (spec & (__Pyx_MEMVIEW_PTR|__Pyx_MEMVIEW_FULL)) {
                if (buf->strides[dim] != sizeof(void *)) {
                    PyErr_Format(PyExc_ValueError,
                                 "Buffer is not indirectly contiguous "
                                 "in dimension %d.", dim);
                    goto fail;
                }
            } else if (buf->strides[dim] != buf->itemsize) {
                PyErr_SetString(PyExc_ValueError,
                                "Buffer and memoryview are not contiguous "
                                "in the same dimension.");
                goto fail;
            }
        }

        if (spec & __Pyx_MEMVIEW_FOLLOW) {
            Py_ssize_t stride = buf->strides[dim];
            if (stride < 0)
                stride = -stride;
            if (stride < buf->itemsize) {
                PyErr_SetString(PyExc_ValueError,
                                "Buffer and memoryview are not contiguous "
                                "in the same dimension.");
                goto fail;
            }
        }
    } else {
        if (spec & __Pyx_MEMVIEW_CONTIG && dim != ndim - 1) {
            PyErr_Format(PyExc_ValueError,
                         "C-contiguous buffer is not contiguous in "
                         "dimension %d", dim);
            goto fail;
        } else if (spec & (__Pyx_MEMVIEW_PTR)) {
            PyErr_Format(PyExc_ValueError,
                         "C-contiguous buffer is not indirect in "
                         "dimension %d", dim);
            goto fail;
        } else if (buf->suboffsets) {
            PyErr_SetString(PyExc_ValueError,
                            "Buffer exposes suboffsets but no strides");
            goto fail;
        }
    }

    return 1;
fail:
    return 0;
}

static int
__pyx_check_suboffsets(Py_buffer *buf, int dim, CYTHON_UNUSED int ndim, int spec)
{
    // Todo: without PyBUF_INDIRECT we may not have suboffset information, i.e., the
    //       ptr may not be set to NULL but may be uninitialized?
    if (spec & __Pyx_MEMVIEW_DIRECT) {
        if (buf->suboffsets && buf->suboffsets[dim] >= 0) {
            PyErr_Format(PyExc_ValueError,
                         "Buffer not compatible with direct access "
                         "in dimension %d.", dim);
            goto fail;
        }
    }

    if (spec & __Pyx_MEMVIEW_PTR) {
        if (!buf->suboffsets || (buf->suboffsets && buf->suboffsets[dim] < 0)) {
            PyErr_Format(PyExc_ValueError,
                         "Buffer is not indirectly accessible "
                         "in dimension %d.", dim);
            goto fail;
        }
    }

    return 1;
fail:
    return 0;
}

static int
__pyx_verify_contig(Py_buffer *buf, int ndim, int c_or_f_flag)
{
    int i;

    if (c_or_f_flag & __Pyx_IS_F_CONTIG) {
        Py_ssize_t stride = 1;
        for (i = 0; i < ndim; i++) {
            if (stride * buf->itemsize != buf->strides[i] &&
                    buf->shape[i] > 1)
            {
                PyErr_SetString(PyExc_ValueError,
                    "Buffer not fortran contiguous.");
                goto fail;
            }
            stride = stride * buf->shape[i];
        }
    } else if (c_or_f_flag & __Pyx_IS_C_CONTIG) {
        Py_ssize_t stride = 1;
        for (i = ndim - 1; i >- 1; i--) {
            if (stride * buf->itemsize != buf->strides[i] &&
                    buf->shape[i] > 1) {
                PyErr_SetString(PyExc_ValueError,
                    "Buffer not C contiguous.");
                goto fail;
            }
            stride = stride * buf->shape[i];
        }
    }

    return 1;
fail:
    return 0;
}

static int __Pyx_ValidateAndInit_memviewslice(
                int *axes_specs,
                int c_or_f_flag,
                int buf_flags,
                int ndim,
                __Pyx_TypeInfo *dtype,
                __Pyx_BufFmt_StackElem stack[],
                __Pyx_memviewslice *memviewslice,
                PyObject *original_obj)
{
    struct __pyx_memoryview_obj *memview, *new_memview;
    __Pyx_RefNannyDeclarations
    Py_buffer *buf;
    int i, spec = 0, retval = -1;
    __Pyx_BufFmt_Context ctx;
    int from_memoryview = __pyx_memoryview_check(original_obj);

    __Pyx_RefNannySetupContext("ValidateAndInit_memviewslice", 0);

    if (from_memoryview && __pyx_typeinfo_cmp(dtype, ((struct __pyx_memoryview_obj *)
                                                            original_obj)->typeinfo)) {
        /* We have a matching dtype, skip format parsing */
        memview = (struct __pyx_memoryview_obj *) original_obj;
        new_memview = NULL;
    } else {
        memview = (struct __pyx_memoryview_obj *) __pyx_memoryview_new(
                                            original_obj, buf_flags, 0, dtype);
        new_memview = memview;
        if (unlikely(!memview))
            goto fail;
    }

    buf = &memview->view;
    if (buf->ndim != ndim) {
        PyErr_Format(PyExc_ValueError,
                "Buffer has wrong number of dimensions (expected %d, got %d)",
                ndim, buf->ndim);
        goto fail;
    }

    if (new_memview) {
        __Pyx_BufFmt_Init(&ctx, stack, dtype);
        if (!__Pyx_BufFmt_CheckString(&ctx, buf->format)) goto fail;
    }

    if ((unsigned) buf->itemsize != dtype->size) {
        PyErr_Format(PyExc_ValueError,
                     "Item size of buffer (%" CYTHON_FORMAT_SSIZE_T "u byte%s) "
                     "does not match size of '%s' (%" CYTHON_FORMAT_SSIZE_T "u byte%s)",
                     buf->itemsize,
                     (buf->itemsize > 1) ? "s" : "",
                     dtype->name,
                     dtype->size,
                     (dtype->size > 1) ? "s" : "");
        goto fail;
    }

    /* Check axes */
    for (i = 0; i < ndim; i++) {
        spec = axes_specs[i];
        if (!__pyx_check_strides(buf, i, ndim, spec))
            goto fail;
        if (!__pyx_check_suboffsets(buf, i, ndim, spec))
            goto fail;
    }

    /* Check contiguity */
    if (buf->strides && !__pyx_verify_contig(buf, ndim, c_or_f_flag))
        goto fail;

    /* Initialize */
    if (unlikely(__Pyx_init_memviewslice(memview, ndim, memviewslice,
                                         new_memview != NULL) == -1)) {
        goto fail;
    }

    retval = 0;
    goto no_fail;

fail:
    Py_XDECREF(new_memview);
    retval = -1;

no_fail:
    __Pyx_RefNannyFinishContext();
    return retval;
}


////////// MemviewSliceInit //////////

static int
__Pyx_init_memviewslice(struct __pyx_memoryview_obj *memview,
                        int ndim,
                        {{memviewslice_name}} *memviewslice,
                        int memview_is_new_reference)
{
    __Pyx_RefNannyDeclarations
    int i, retval=-1;
    Py_buffer *buf = &memview->view;
    __Pyx_RefNannySetupContext("init_memviewslice", 0);

    if (!buf) {
        PyErr_SetString(PyExc_ValueError,
            "buf is NULL.");
        goto fail;
    } else if (memviewslice->memview || memviewslice->data) {
        PyErr_SetString(PyExc_ValueError,
            "memviewslice is already initialized!");
        goto fail;
    }

    if (buf->strides) {
        for (i = 0; i < ndim; i++) {
            memviewslice->strides[i] = buf->strides[i];
        }
    } else {
        Py_ssize_t stride = buf->itemsize;
        for (i = ndim - 1; i >= 0; i--) {
            memviewslice->strides[i] = stride;
            stride *= buf->shape[i];
        }
    }

    for (i = 0; i < ndim; i++) {
        memviewslice->shape[i]   = buf->shape[i];
        if (buf->suboffsets) {
            memviewslice->suboffsets[i] = buf->suboffsets[i];
        } else {
            memviewslice->suboffsets[i] = -1;
        }
    }

    memviewslice->memview = memview;
    memviewslice->data = (char *)buf->buf;
    if (__pyx_add_acquisition_count(memview) == 0 && !memview_is_new_reference) {
        Py_INCREF(memview);
    }
    retval = 0;
    goto no_fail;

fail:
    /* Don't decref, the memoryview may be borrowed. Let the caller do the cleanup */
    /* __Pyx_XDECREF(memviewslice->memview); */
    memviewslice->memview = 0;
    memviewslice->data = 0;
    retval = -1;
no_fail:
    __Pyx_RefNannyFinishContext();
    return retval;
}


static CYTHON_INLINE void __pyx_fatalerror(const char *fmt, ...) {
    va_list vargs;
    char msg[200];

    va_start(vargs, fmt);

#ifdef HAVE_STDARG_PROTOTYPES
    va_start(vargs, fmt);
#else
    va_start(vargs);
#endif

    vsnprintf(msg, 200, fmt, vargs);
    Py_FatalError(msg);

    va_end(vargs);
}

static CYTHON_INLINE int
__pyx_add_acquisition_count_locked(__pyx_atomic_int *acquisition_count,
                                   PyThread_type_lock lock)
{
    int result;
    PyThread_acquire_lock(lock, 1);
    result = (*acquisition_count)++;
    PyThread_release_lock(lock);
    return result;
}

static CYTHON_INLINE int
__pyx_sub_acquisition_count_locked(__pyx_atomic_int *acquisition_count,
                                   PyThread_type_lock lock)
{
    int result;
    PyThread_acquire_lock(lock, 1);
    result = (*acquisition_count)--;
    PyThread_release_lock(lock);
    return result;
}


static CYTHON_INLINE void
__Pyx_INC_MEMVIEW({{memviewslice_name}} *memslice, int have_gil, int lineno)
{
    int first_time;
    struct {{memview_struct_name}} *memview = memslice->memview;
    if (!memview || (PyObject *) memview == Py_None)
        return; /* allow uninitialized memoryview assignment */

    if (__pyx_get_slice_count(memview) < 0)
        __pyx_fatalerror("Acquisition count is %d (line %d)",
                         __pyx_get_slice_count(memview), lineno);

    first_time = __pyx_add_acquisition_count(memview) == 0;

    if (first_time) {
        if (have_gil) {
            Py_INCREF((PyObject *) memview);
        } else {
            PyGILState_STATE _gilstate = PyGILState_Ensure();
            Py_INCREF((PyObject *) memview);
            PyGILState_Release(_gilstate);
        }
    }
}

static CYTHON_INLINE void __Pyx_XDEC_MEMVIEW({{memviewslice_name}} *memslice,
                                             int have_gil, int lineno) {
    int last_time;
    struct {{memview_struct_name}} *memview = memslice->memview;

    if (!memview ) {
        return;
    } else if ((PyObject *) memview == Py_None) {
        memslice->memview = NULL;
        return;
    }

    if (__pyx_get_slice_count(memview) <= 0)
        __pyx_fatalerror("Acquisition count is %d (line %d)",
                         __pyx_get_slice_count(memview), lineno);

    last_time = __pyx_sub_acquisition_count(memview) == 1;
    memslice->data = NULL;
    if (last_time) {
        if (have_gil) {
            Py_CLEAR(memslice->memview);
        } else {
            PyGILState_STATE _gilstate = PyGILState_Ensure();
            Py_CLEAR(memslice->memview);
            PyGILState_Release(_gilstate);
        }
    } else {
        memslice->memview = NULL;
    }
}


////////// MemviewSliceCopyTemplate.proto //////////

static {{memviewslice_name}}
__pyx_memoryview_copy_new_contig(const __Pyx_memviewslice *from_mvs,
                                 const char *mode, int ndim,
                                 size_t sizeof_dtype, int contig_flag,
                                 int dtype_is_object);


////////// MemviewSliceCopyTemplate //////////

static {{memviewslice_name}}
__pyx_memoryview_copy_new_contig(const __Pyx_memviewslice *from_mvs,
                                 const char *mode, int ndim,
                                 size_t sizeof_dtype, int contig_flag,
                                 int dtype_is_object)
{
    __Pyx_RefNannyDeclarations
    int i;
    __Pyx_memviewslice new_mvs = {{memslice_init}};
    struct __pyx_memoryview_obj *from_memview = from_mvs->memview;
    Py_buffer *buf = &from_memview->view;
    PyObject *shape_tuple = NULL;
    PyObject *temp_int = NULL;
    struct __pyx_array_obj *array_obj = NULL;
    struct __pyx_memoryview_obj *memview_obj = NULL;

    __Pyx_RefNannySetupContext("__pyx_memoryview_copy_new_contig", 0);

    for (i = 0; i < ndim; i++) {
        if (from_mvs->suboffsets[i] >= 0) {
            PyErr_Format(PyExc_ValueError, "Cannot copy memoryview slice with "
                                           "indirect dimensions (axis %d)", i);
            goto fail;
        }
    }

    shape_tuple = PyTuple_New(ndim);
    if (unlikely(!shape_tuple)) {
        goto fail;
    }
    __Pyx_GOTREF(shape_tuple);


    for(i = 0; i < ndim; i++) {
        temp_int = PyInt_FromSsize_t(from_mvs->shape[i]);
        if(unlikely(!temp_int)) {
            goto fail;
        } else {
            PyTuple_SET_ITEM(shape_tuple, i, temp_int);
            temp_int = NULL;
        }
    }

    array_obj = __pyx_array_new(shape_tuple, sizeof_dtype, buf->format, (char *) mode, NULL);
    if (unlikely(!array_obj)) {
        goto fail;
    }
    __Pyx_GOTREF(array_obj);

    memview_obj = (struct __pyx_memoryview_obj *) __pyx_memoryview_new(
                                    (PyObject *) array_obj, contig_flag,
                                    dtype_is_object,
                                    from_mvs->memview->typeinfo);
    if (unlikely(!memview_obj))
        goto fail;

    /* initialize new_mvs */
    if (unlikely(__Pyx_init_memviewslice(memview_obj, ndim, &new_mvs, 1) < 0))
        goto fail;

    if (unlikely(__pyx_memoryview_copy_contents(*from_mvs, new_mvs, ndim, ndim,
                                                dtype_is_object) < 0))
        goto fail;

    goto no_fail;

fail:
    __Pyx_XDECREF(new_mvs.memview);
    new_mvs.memview = NULL;
    new_mvs.data = NULL;
no_fail:
    __Pyx_XDECREF(shape_tuple);
    __Pyx_XDECREF(temp_int);
    __Pyx_XDECREF(array_obj);
    __Pyx_RefNannyFinishContext();
    return new_mvs;
}


////////// CopyContentsUtility.proto /////////

#define {{func_cname}}(slice) \
        __pyx_memoryview_copy_new_contig(&slice, "{{mode}}", {{ndim}},            \
                                         sizeof({{dtype_decl}}), {{contig_flag}}, \
                                         {{dtype_is_object}})


////////// OverlappingSlices.proto //////////

static int __pyx_slices_overlap({{memviewslice_name}} *slice1,
                                {{memviewslice_name}} *slice2,
                                int ndim, size_t itemsize);


////////// OverlappingSlices //////////

/* Based on numpy's core/src/multiarray/array_assign.c */

/* Gets a half-open range [start, end) which contains the array data */
static void
__pyx_get_array_memory_extents({{memviewslice_name}} *slice,
                               void **out_start, void **out_end,
                               int ndim, size_t itemsize)
{
    char *start, *end;
    int i;

    start = end = slice->data;

    for (i = 0; i < ndim; i++) {
        Py_ssize_t stride = slice->strides[i];
        Py_ssize_t extent = slice->shape[i];

        if (extent == 0) {
            *out_start = *out_end = start;
            return;
        } else {
            if (stride > 0)
                end += stride * (extent - 1);
            else
                start += stride * (extent - 1);
        }
    }

    /* Return a half-open range */
    *out_start = start;
    *out_end = end + itemsize;
}

/* Returns 1 if the arrays have overlapping data, 0 otherwise */
static int
__pyx_slices_overlap({{memviewslice_name}} *slice1,
                     {{memviewslice_name}} *slice2,
                     int ndim, size_t itemsize)
{
    void *start1, *end1, *start2, *end2;

    __pyx_get_array_memory_extents(slice1, &start1, &end1, ndim, itemsize);
    __pyx_get_array_memory_extents(slice2, &start2, &end2, ndim, itemsize);

    return (start1 < end2) && (start2 < end1);
}


////////// MemviewSliceIsCContig.proto //////////

#define __pyx_memviewslice_is_c_contig{{ndim}}(slice) \
        __pyx_memviewslice_is_contig(&slice, 'C', {{ndim}})


////////// MemviewSliceIsFContig.proto //////////

#define __pyx_memviewslice_is_f_contig{{ndim}}(slice) \
        __pyx_memviewslice_is_contig(&slice, 'F', {{ndim}})


////////// MemviewSliceIsContig.proto //////////

static int __pyx_memviewslice_is_contig(const {{memviewslice_name}} *mvs,
                                        char order, int ndim);


////////// MemviewSliceIsContig //////////

static int
__pyx_memviewslice_is_contig(const {{memviewslice_name}} *mvs,
                             char order, int ndim)
{
    int i, index, step, start;
    Py_ssize_t itemsize = mvs->memview->view.itemsize;

    if (order == 'F') {
        step = 1;
        start = 0;
    } else {
        step = -1;
        start = ndim - 1;
    }

    for (i = 0; i < ndim; i++) {
        index = start + step * i;
        if (mvs->suboffsets[index] >= 0 || mvs->strides[index] != itemsize)
            return 0;

        itemsize *= mvs->shape[index];
    }

    return 1;
}


/////////////// MemviewSliceIndex ///////////////

static CYTHON_INLINE char *
__pyx_memviewslice_index_full(const char *bufp, Py_ssize_t idx,
                              Py_ssize_t stride, Py_ssize_t suboffset)
{
    bufp = bufp + idx * stride;
    if (suboffset >= 0) {
        bufp = *((char **) bufp) + suboffset;
    }
    return (char *) bufp;
}


/////////////// MemviewDtypeToObject.proto ///////////////

{{if to_py_function}}
static PyObject *{{get_function}}(const char *itemp); /* proto */
{{endif}}

{{if from_py_function}}
static int {{set_function}}(const char *itemp, PyObject *obj); /* proto */
{{endif}}

/////////////// MemviewDtypeToObject ///////////////

{{#__pyx_memview_<dtype_name>_to_object}}

/* Convert a dtype to or from a Python object */

{{if to_py_function}}
static PyObject *{{get_function}}(const char *itemp) {
    return (PyObject *) {{to_py_function}}(*({{dtype}} *) itemp);
}
{{endif}}

{{if from_py_function}}
static int {{set_function}}(const char *itemp, PyObject *obj) {
    {{dtype}} value = {{from_py_function}}(obj);
    if ({{error_condition}})
        return 0;
    *({{dtype}} *) itemp = value;
    return 1;
}
{{endif}}


/////////////// MemviewObjectToObject.proto ///////////////

/* Function callbacks (for memoryview object) for dtype object */
static PyObject *{{get_function}}(const char *itemp); /* proto */
static int {{set_function}}(const char *itemp, PyObject *obj); /* proto */


/////////////// MemviewObjectToObject ///////////////

static PyObject *{{get_function}}(const char *itemp) {
    PyObject *result = *(PyObject **) itemp;
    Py_INCREF(result);
    return result;
}

static int {{set_function}}(const char *itemp, PyObject *obj) {
    Py_INCREF(obj);
    Py_DECREF(*(PyObject **) itemp);
    *(PyObject **) itemp = obj;
    return 1;
}

/////////// ToughSlice //////////

/* Dimension is indexed with 'start:stop:step' */

if (unlikely(__pyx_memoryview_slice_memviewslice(
    &{{dst}},
    {{src}}.shape[{{dim}}], {{src}}.strides[{{dim}}], {{src}}.suboffsets[{{dim}}],
    {{dim}},
    {{new_ndim}},
    &{{suboffset_dim}},
    {{start}},
    {{stop}},
    {{step}},
    {{int(have_start)}},
    {{int(have_stop)}},
    {{int(have_step)}},
    1) < 0))
{
    {{error_goto}}
}


////////// SimpleSlice //////////

/* Dimension is indexed with ':' only */

{{dst}}.shape[{{new_ndim}}] = {{src}}.shape[{{dim}}];
{{dst}}.strides[{{new_ndim}}] = {{src}}.strides[{{dim}}];

{{if access == 'direct'}}
    {{dst}}.suboffsets[{{new_ndim}}] = -1;
{{else}}
    {{dst}}.suboffsets[{{new_ndim}}] = {{src}}.suboffsets[{{dim}}];
    if ({{src}}.suboffsets[{{dim}}] >= 0)
        {{suboffset_dim}} = {{new_ndim}};
{{endif}}


////////// SliceIndex //////////

// Dimension is indexed with an integer, we could use the ToughSlice
// approach, but this is faster

{
    Py_ssize_t __pyx_tmp_idx = {{idx}};
    Py_ssize_t __pyx_tmp_shape = {{src}}.shape[{{dim}}];
    Py_ssize_t __pyx_tmp_stride = {{src}}.strides[{{dim}}];
    if ({{wraparound}} && (__pyx_tmp_idx < 0))
        __pyx_tmp_idx += __pyx_tmp_shape;

    if ({{boundscheck}} && (__pyx_tmp_idx < 0 || __pyx_tmp_idx >= __pyx_tmp_shape)) {
        {{if not have_gil}}
            #ifdef WITH_THREAD
            PyGILState_STATE __pyx_gilstate_save = PyGILState_Ensure();
            #endif
        {{endif}}

        PyErr_SetString(PyExc_IndexError, "Index out of bounds (axis {{dim}})");

        {{if not have_gil}}
            #ifdef WITH_THREAD
            PyGILState_Release(__pyx_gilstate_save);
            #endif
        {{endif}}

        {{error_goto}}
    }

    {{if all_dimensions_direct}}
        {{dst}}.data += __pyx_tmp_idx * __pyx_tmp_stride;
    {{else}}
        if ({{suboffset_dim}} < 0) {
            {{dst}}.data += __pyx_tmp_idx * __pyx_tmp_stride;

            /* This dimension is the first dimension, or is preceded by    */
            /* direct or indirect dimensions that are indexed away.        */
            /* Hence suboffset_dim must be less than zero, and we can have */
            /* our data pointer refer to another block by dereferencing.   */
            /*   slice.data -> B -> C     becomes     slice.data -> C      */

            {{if indirect}}
              {
                Py_ssize_t __pyx_tmp_suboffset = {{src}}.suboffsets[{{dim}}];

                {{if generic}}
                    if (__pyx_tmp_suboffset >= 0)
                {{endif}}

                    {{dst}}.data = *((char **) {{dst}}.data) + __pyx_tmp_suboffset;
              }
            {{endif}}

        } else {
            {{dst}}.suboffsets[{{suboffset_dim}}] += __pyx_tmp_idx * __pyx_tmp_stride;

            /* Note: dimension can not be indirect, the compiler will have */
            /*       issued an error */
        }

    {{endif}}
}


////////// FillStrided1DScalar.proto //////////

static void
__pyx_fill_slice_{{dtype_name}}({{type_decl}} *p, Py_ssize_t extent, Py_ssize_t stride,
                                size_t itemsize, void *itemp);

////////// FillStrided1DScalar //////////

/* Fill a slice with a scalar value. The dimension is direct and strided or contiguous */
/* This can be used as a callback for the memoryview object to efficienty assign a scalar */
/* Currently unused */
static void
__pyx_fill_slice_{{dtype_name}}({{type_decl}} *p, Py_ssize_t extent, Py_ssize_t stride,
                                size_t itemsize, void *itemp)
{
    Py_ssize_t i;
    {{type_decl}} item = *(({{type_decl}} *) itemp);
    {{type_decl}} *endp;

    stride /= sizeof({{type_decl}});
    endp = p + stride * extent;

    while (p < endp) {
        *p = item;
        p += stride;
    }
}
