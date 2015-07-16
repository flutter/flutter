# Please see the Python header files (object.h/abstract.h) for docs

cdef extern from "Python.h":

    cdef enum:
        PyBUF_SIMPLE,
        PyBUF_WRITABLE,
        PyBUF_WRITEABLE, # backwards compatability
        PyBUF_FORMAT,
        PyBUF_ND,
        PyBUF_STRIDES,
        PyBUF_C_CONTIGUOUS,
        PyBUF_F_CONTIGUOUS,
        PyBUF_ANY_CONTIGUOUS,
        PyBUF_INDIRECT,
        PyBUF_CONTIG,
        PyBUF_CONTIG_RO,
        PyBUF_STRIDED,
        PyBUF_STRIDED_RO,
        PyBUF_RECORDS,
        PyBUF_RECORDS_RO,
        PyBUF_FULL,
        PyBUF_FULL_RO,
        PyBUF_READ,
        PyBUF_WRITE,
        PyBUF_SHADOW

    bint PyObject_CheckBuffer(object obj)
    # Return 1 if obj supports the buffer interface otherwise 0.

    int PyObject_GetBuffer(object obj, Py_buffer *view, int flags) except -1
    # Export obj into a Py_buffer, view. These arguments must never be
    # NULL. The flags argument is a bit field indicating what kind of
    # buffer the caller is prepared to deal with and therefore what
    # kind of buffer the exporter is allowed to return. The buffer
    # interface allows for complicated memory sharing possibilities,
    # but some caller may not be able to handle all the complexity but
    # may want to see if the exporter will let them take a simpler
    # view to its memory.

    # Some exporters may not be able to share memory in every possible
    # way and may need to raise errors to signal to some consumers
    # that something is just not possible. These errors should be a
    # BufferError unless there is another error that is actually
    # causing the problem. The exporter can use flags information to
    # simplify how much of the Py_buffer structure is filled in with
    # non-default values and/or raise an error if the object can’t
    # support a simpler view of its memory.

    # 0 is returned on success and -1 on error.

    void PyBuffer_Release(Py_buffer *view)
    # Release the buffer view. This should be called when the buffer
    # is no longer being used as it may free memory from it.

    void* PyBuffer_GetPointer(Py_buffer *view, Py_ssize_t *indices)
    # ??

    Py_ssize_t PyBuffer_SizeFromFormat(char *) # actually const char
    # Return the implied ~Py_buffer.itemsize from the struct-stype
    # ~Py_buffer.format

    int PyBuffer_ToContiguous(void *buf, Py_buffer *view, Py_ssize_t len, char fort)
    # ??

    int PyBuffer_FromContiguous(Py_buffer *view, void *buf, Py_ssize_t len, char fort)
    # ??

    int PyObject_CopyToObject(object obj, void *buf, Py_ssize_t len, char fortran) except -1
    # Copy len bytes of data pointed to by the contiguous chunk of
    # memory pointed to by buf into the buffer exported by obj. The
    # buffer must of course be writable. Return 0 on success and
    # return -1 and raise an error on failure. If the object does not
    # have a writable buffer, then an error is raised. If fortran is
    # 'F', then if the object is multi-dimensional, then the data will
    # be copied into the array in Fortran-style (first dimension
    # varies the fastest). If fortran is 'C', then the data will be
    # copied into the array in C-style (last dimension varies the
    # fastest). If fortran is 'A', then it does not matter and the
    # copy will be made in whatever way is more efficient.

    int PyObject_CopyData(object dest, object src) except -1
    # Copy the data from the src buffer to the buffer of destination

    bint PyBuffer_IsContiguous(Py_buffer *view, char fort)
    # Return 1 if the memory defined by the view is C-style (fortran
    # is 'C') or Fortran-style (fortran is 'F') contiguous or either
    # one (fortran is 'A'). Return 0 otherwise.

    void PyBuffer_FillContiguousStrides(int ndims,
                                        Py_ssize_t *shape,
                                        Py_ssize_t *strides,
                                        Py_ssize_t itemsize,
                                        char fort)
    # Fill the strides array with byte-strides of a contiguous
    # (Fortran-style if fort is 'F' or C-style otherwise) array of the
    # given shape with the given number of bytes per element.

    int PyBuffer_FillInfo(Py_buffer *view, object exporter, void *buf,
                          Py_ssize_t len, int readonly, int flags) except -1
    # Fill in a buffer-info structure, view, correctly for an exporter
    # that can only share a contiguous chunk of memory of “unsigned
    # bytes” of the given length. Return 0 on success and -1 (with
    # raising an error) on error.

    # DEPRECATED HERE: do not cimport from here, cimport from cpython.object instead
    object PyObject_Format(object obj, object format_spec)
    # Takes an arbitrary object and returns the result of calling
    # obj.__format__(format_spec).
