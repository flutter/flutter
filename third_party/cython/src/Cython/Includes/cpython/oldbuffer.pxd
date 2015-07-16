# Legacy Python 2 buffer interface.
#
# These functions are no longer available in Python 3, use the new
# buffer interface instead.

cdef extern from "Python.h":
    cdef enum _:
        Py_END_OF_BUFFER
    #    This constant may be passed as the size parameter to
    #    PyBuffer_FromObject() or PyBuffer_FromReadWriteObject(). It
    #    indicates that the new PyBufferObject should refer to base object
    #    from the specified offset to the end of its exported
    #    buffer. Using this enables the caller to avoid querying the base
    #    object for its length.

    bint PyBuffer_Check(object p)
    #    Return true if the argument has type PyBuffer_Type.

    object PyBuffer_FromObject(object base, Py_ssize_t offset, Py_ssize_t size)
    #    Return value: New reference.
    #
    #    Return a new read-only buffer object. This raises TypeError if
    #    base doesn't support the read-only buffer protocol or doesn't
    #    provide exactly one buffer segment, or it raises ValueError if
    #    offset is less than zero. The buffer will hold a reference to the
    #    base object, and the buffer's contents will refer to the base
    #    object's buffer interface, starting as position offset and
    #    extending for size bytes. If size is Py_END_OF_BUFFER, then the
    #    new buffer's contents extend to the length of the base object's
    #    exported buffer data.

    object PyBuffer_FromReadWriteObject(object base, Py_ssize_t offset, Py_ssize_t size)
    #    Return value: New reference.
    #
    #    Return a new writable buffer object. Parameters and exceptions
    #    are similar to those for PyBuffer_FromObject(). If the base
    #    object does not export the writeable buffer protocol, then
    #    TypeError is raised.

    object PyBuffer_FromMemory(void *ptr, Py_ssize_t size)
    #    Return value: New reference.
    #
    #    Return a new read-only buffer object that reads from a specified
    #    location in memory, with a specified size. The caller is
    #    responsible for ensuring that the memory buffer, passed in as
    #    ptr, is not deallocated while the returned buffer object
    #    exists. Raises ValueError if size is less than zero. Note that
    #    Py_END_OF_BUFFER may not be passed for the size parameter;
    #    ValueError will be raised in that case.

    object PyBuffer_FromReadWriteMemory(void *ptr, Py_ssize_t size)
    #    Return value: New reference.
    #
    #    Similar to PyBuffer_FromMemory(), but the returned buffer is
    #    writable.

    object PyBuffer_New(Py_ssize_t size)
    #    Return value: New reference.
    #
    #    Return a new writable buffer object that maintains its own memory
    #    buffer of size bytes. ValueError is returned if size is not zero
    #    or positive. Note that the memory buffer (as returned by
    #    PyObject_AsWriteBuffer()) is not specifically aligned.
