

cdef extern from "pythread.h":

    ctypedef void *PyThread_type_lock
    ctypedef void *PyThread_type_sema

    void PyThread_init_thread()
    long PyThread_start_new_thread(void (*)(void *), void *)
    void PyThread_exit_thread()
    long PyThread_get_thread_ident()

    PyThread_type_lock PyThread_allocate_lock()
    void PyThread_free_lock(PyThread_type_lock)
    int PyThread_acquire_lock(PyThread_type_lock, int mode) nogil
    void PyThread_release_lock(PyThread_type_lock) nogil

    enum:
        # 'mode' in PyThread_acquire_lock()
        WAIT_LOCK    #   1
        NOWAIT_LOCK  #   0

    ctypedef enum PyLockStatus:
        # return values of PyThread_acquire_lock() in CPython 3.2+
        PY_LOCK_FAILURE = 0
        PY_LOCK_ACQUIRED = 1
        PY_LOCK_INTR

    size_t PyThread_get_stacksize()
    int PyThread_set_stacksize(size_t)

    # Thread Local Storage (TLS) API
    int PyThread_create_key()
    void PyThread_delete_key(int)
    int PyThread_set_key_value(int, void *)
    void * PyThread_get_key_value(int)
    void PyThread_delete_key_value(int key)

    # Cleanup after a fork
    void PyThread_ReInitTLS()
