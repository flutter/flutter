# Thread and interpreter state structures and their interfaces

from cpython.ref cimport PyObject

cdef extern from "Python.h":

    # We make these an opague types. If the user wants specific attributes,
    # they can be declared manually.

    ctypedef struct PyInterpreterState:
        pass

    ctypedef struct PyThreadState:
        pass

    ctypedef struct PyFrameObject:
        pass

    # This is not actually a struct, but make sure it can never be coerced to
    # an int or used in arithmetic expressions
    ctypedef struct PyGILState_STATE

    # The type of the trace function registered using PyEval_SetProfile() and
    # PyEval_SetTrace().
    # Py_tracefunc return -1 when raising an exception, or 0 for success.
    ctypedef int (*Py_tracefunc)(PyObject *, PyFrameObject *, int, PyObject *)

    # The following values are used for 'what' for tracefunc functions
    enum:
        PyTrace_CALL
        PyTrace_EXCEPTION
        PyTrace_LINE
        PyTrace_RETURN
        PyTrace_C_CALL
        PyTrace_C_EXCEPTION
        PyTrace_C_RETURN


    PyInterpreterState * PyInterpreterState_New()
    void PyInterpreterState_Clear(PyInterpreterState *)
    void PyInterpreterState_Delete(PyInterpreterState *)

    PyThreadState * PyThreadState_New(PyInterpreterState *)
    void PyThreadState_Clear(PyThreadState *)
    void PyThreadState_Delete(PyThreadState *)

    PyThreadState * PyThreadState_Get()
    PyThreadState * PyThreadState_Swap(PyThreadState *)
    PyObject * PyThreadState_GetDict()
    int PyThreadState_SetAsyncExc(long, PyObject *)

    # Ensure that the current thread is ready to call the Python
    # C API, regardless of the current state of Python, or of its
    # thread lock.  This may be called as many times as desired
    # by a thread so long as each call is matched with a call to
    # PyGILState_Release().  In general, other thread-state APIs may
    # be used between _Ensure() and _Release() calls, so long as the
    # thread-state is restored to its previous state before the Release().
    # For example, normal use of the Py_BEGIN_ALLOW_THREADS/
    # Py_END_ALLOW_THREADS macros are acceptable.

    # The return value is an opaque "handle" to the thread state when
    # PyGILState_Ensure() was called, and must be passed to
    # PyGILState_Release() to ensure Python is left in the same state. Even
    # though recursive calls are allowed, these handles can *not* be shared -
    # each unique call to PyGILState_Ensure must save the handle for its
    # call to PyGILState_Release.

    # When the function returns, the current thread will hold the GIL.

    # Failure is a fatal error.
    PyGILState_STATE PyGILState_Ensure()

    # Release any resources previously acquired.  After this call, Python's
    # state will be the same as it was prior to the corresponding
    # PyGILState_Ensure() call (but generally this state will be unknown to
    # the caller, hence the use of the GILState API.)

    # Every call to PyGILState_Ensure must be matched by a call to
    # PyGILState_Release on the same thread.
    void PyGILState_Release(PyGILState_STATE)

    # Routines for advanced debuggers, requested by David Beazley.
    # Don't use unless you know what you are doing!
    PyInterpreterState * PyInterpreterState_Head()
    PyInterpreterState * PyInterpreterState_Next(PyInterpreterState *)
    PyThreadState * PyInterpreterState_ThreadHead(PyInterpreterState *)
    PyThreadState * PyThreadState_Next(PyThreadState *)
