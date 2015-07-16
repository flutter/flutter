cdef extern from "Python.h":

    #####################################################################
    # 9.2 Memory Interface
    #####################################################################
    # You are definitely *supposed* to use these: "In most situations,
    # however, it is recommended to allocate memory from the Python
    # heap specifically because the latter is under control of the
    # Python memory manager. For example, this is required when the
    # interpreter is extended with new object types written in
    # C. Another reason for using the Python heap is the desire to
    # inform the Python memory manager about the memory needs of the
    # extension module. Even when the requested memory is used
    # exclusively for internal, highly-specific purposes, delegating
    # all memory requests to the Python memory manager causes the
    # interpreter to have a more accurate image of its memory
    # footprint as a whole. Consequently, under certain circumstances,
    # the Python memory manager may or may not trigger appropriate
    # actions, like garbage collection, memory compaction or other
    # preventive procedures. Note that by using the C library
    # allocator as shown in the previous example, the allocated memory
    # for the I/O buffer escapes completely the Python memory
    # manager."

    # The following function sets, modeled after the ANSI C standard,
    # but specifying behavior when requesting zero bytes, are
    # available for allocating and releasing memory from the Python
    # heap:

    void* PyMem_Malloc(size_t n)
    # Allocates n bytes and returns a pointer of type void* to the
    # allocated memory, or NULL if the request fails. Requesting zero
    # bytes returns a distinct non-NULL pointer if possible, as if
    # PyMem_Malloc(1) had been called instead. The memory will not
    # have been initialized in any way.

    void* PyMem_Realloc(void *p, size_t n)
    # Resizes the memory block pointed to by p to n bytes. The
    # contents will be unchanged to the minimum of the old and the new
    # sizes. If p is NULL, the call is equivalent to PyMem_Malloc(n);
    # else if n is equal to zero, the memory block is resized but is
    # not freed, and the returned pointer is non-NULL. Unless p is
    # NULL, it must have been returned by a previous call to
    # PyMem_Malloc() or PyMem_Realloc().

    void PyMem_Free(void *p)
    # Frees the memory block pointed to by p, which must have been
    # returned by a previous call to PyMem_Malloc() or
    # PyMem_Realloc(). Otherwise, or if PyMem_Free(p) has been called
    # before, undefined behavior occurs. If p is NULL, no operation is
    # performed.

    # The following type-oriented macros are provided for
    # convenience. Note that TYPE refers to any C type.

    # TYPE* PyMem_New(TYPE, size_t n)
    # Same as PyMem_Malloc(), but allocates (n * sizeof(TYPE)) bytes
    # of memory. Returns a pointer cast to TYPE*. The memory will not
    # have been initialized in any way.

    # TYPE* PyMem_Resize(void *p, TYPE, size_t n)
    # Same as PyMem_Realloc(), but the memory block is resized to (n *
    # sizeof(TYPE)) bytes. Returns a pointer cast to TYPE*.

    void PyMem_Del(void *p)
    # Same as PyMem_Free().

    # In addition, the following macro sets are provided for calling
    # the Python memory allocator directly, without involving the C
    # API functions listed above. However, note that their use does
    # not preserve binary compatibility across Python versions and is
    # therefore deprecated in extension modules.

    # PyMem_MALLOC(), PyMem_REALLOC(), PyMem_FREE().
    # PyMem_NEW(), PyMem_RESIZE(), PyMem_DEL().
