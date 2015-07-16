from cpython.ref cimport PyObject

cdef extern from "Python.h":

    #####################################################################
    # 3. Exception Handling
    #####################################################################

    # The functions described in this chapter will let you handle and
    # raise Python exceptions. It is important to understand some of
    # the basics of Python exception handling. It works somewhat like
    # the Unix errno variable: there is a global indicator (per
    # thread) of the last error that occurred. Most functions don't
    # clear this on success, but will set it to indicate the cause of
    # the error on failure. Most functions also return an error
    # indicator, usually NULL if they are supposed to return a
    # pointer, or -1 if they return an integer (exception: the
    # PyArg_*() functions return 1 for success and 0 for failure).

    # When a function must fail because some function it called
    # failed, it generally doesn't set the error indicator; the
    # function it called already set it. It is responsible for either
    # handling the error and clearing the exception or returning after
    # cleaning up any resources it holds (such as object references or
    # memory allocations); it should not continue normally if it is
    # not prepared to handle the error. If returning due to an error,
    # it is important to indicate to the caller that an error has been
    # set. If the error is not handled or carefully propagated,
    # additional calls into the Python/C API may not behave as
    # intended and may fail in mysterious ways.

    # The error indicator consists of three Python objects
    # corresponding to the Python variables sys.exc_type,
    # sys.exc_value and sys.exc_traceback. API functions exist to
    # interact with the error indicator in various ways. There is a
    # separate error indicator for each thread.

    void PyErr_Print()
    # Print a standard traceback to sys.stderr and clear the error
    # indicator. Call this function only when the error indicator is
    # set. (Otherwise it will cause a fatal error!)

    PyObject* PyErr_Occurred()
    # Return value: Borrowed reference.
    # Test whether the error indicator is set. If set, return the
    # exception type (the first argument to the last call to one of
    # the PyErr_Set*() functions or to PyErr_Restore()). If not set,
    # return NULL. You do not own a reference to the return value, so
    # you do not need to Py_DECREF() it. Note: Do not compare the
    # return value to a specific exception; use
    # PyErr_ExceptionMatches() instead, shown below. (The comparison
    # could easily fail since the exception may be an instance instead
    # of a class, in the case of a class exception, or it may the a
    # subclass of the expected exception.)

    bint PyErr_ExceptionMatches(object exc)
    # Equivalent to "PyErr_GivenExceptionMatches(PyErr_Occurred(),
    # exc)". This should only be called when an exception is actually
    # set; a memory access violation will occur if no exception has
    # been raised.

    bint PyErr_GivenExceptionMatches(object given, object exc)
    # Return true if the given exception matches the exception in
    # exc. If exc is a class object, this also returns true when given
    # is an instance of a subclass. If exc is a tuple, all exceptions
    # in the tuple (and recursively in subtuples) are searched for a
    # match. If given is NULL, a memory access violation will occur.

    void PyErr_NormalizeException(PyObject** exc, PyObject** val, PyObject** tb)
    # Under certain circumstances, the values returned by
    # PyErr_Fetch() below can be ``unnormalized'', meaning that *exc
    # is a class object but *val is not an instance of the same
    # class. This function can be used to instantiate the class in
    # that case. If the values are already normalized, nothing
    # happens. The delayed normalization is implemented to improve
    # performance.

    void PyErr_Clear()
    # Clear the error indicator. If the error indicator is not set, there is no effect.

    void PyErr_Fetch(PyObject** ptype, PyObject** pvalue, PyObject** ptraceback)
    # Retrieve the error indicator into three variables whose
    # addresses are passed. If the error indicator is not set, set all
    # three variables to NULL. If it is set, it will be cleared and
    # you own a reference to each object retrieved. The value and
    # traceback object may be NULL even when the type object is
    # not. Note: This function is normally only used by code that
    # needs to handle exceptions or by code that needs to save and
    # restore the error indicator temporarily.

    void PyErr_Restore(PyObject* type, PyObject* value, PyObject* traceback)
    # Set the error indicator from the three objects. If the error
    # indicator is already set, it is cleared first. If the objects
    # are NULL, the error indicator is cleared. Do not pass a NULL
    # type and non-NULL value or traceback. The exception type should
    # be a class. Do not pass an invalid exception type or
    # value. (Violating these rules will cause subtle problems later.)
    # This call takes away a reference to each object: you must own a
    # reference to each object before the call and after the call you
    # no longer own these references. (If you don't understand this,
    # don't use this function. I warned you.) Note: This function is
    # normally only used by code that needs to save and restore the
    # error indicator temporarily; use PyErr_Fetch() to save the
    # current exception state.

    void PyErr_SetString(object type, char *message)
    # This is the most common way to set the error indicator. The
    # first argument specifies the exception type; it is normally one
    # of the standard exceptions, e.g. PyExc_RuntimeError. You need
    # not increment its reference count. The second argument is an
    # error message; it is converted to a string object.

    void PyErr_SetObject(object type, object value)
    # This function is similar to PyErr_SetString() but lets you
    # specify an arbitrary Python object for the ``value'' of the
    # exception.

    PyObject* PyErr_Format(object exception, char *format, ...) except NULL
    # Return value: Always NULL.
    # This function sets the error indicator and returns
    # NULL. exception should be a Python exception (class, not an
    # instance). format should be a string, containing format codes,
    # similar to printf(). The width.precision before a format code is
    # parsed, but the width part is ignored.

    void PyErr_SetNone(object type)
    # This is a shorthand for "PyErr_SetObject(type, Py_None)".

    int PyErr_BadArgument() except 0

    # This is a shorthand for "PyErr_SetString(PyExc_TypeError,
    # message)", where message indicates that a built-in operation was
    # invoked with an illegal argument. It is mostly for internal use.

    PyObject* PyErr_NoMemory() except NULL
    # Return value: Always NULL.
    # This is a shorthand for "PyErr_SetNone(PyExc_MemoryError)"; it
    # returns NULL so an object allocation function can write "return
    # PyErr_NoMemory();" when it runs out of memory.

    PyObject* PyErr_SetFromErrno(object type) except NULL
    # Return value: Always NULL.
    # This is a convenience function to raise an exception when a C
    # library function has returned an error and set the C variable
    # errno. It constructs a tuple object whose first item is the
    # integer errno value and whose second item is the corresponding
    # error message (gotten from strerror()), and then calls
    # "PyErr_SetObject(type, object)". On Unix, when the errno value
    # is EINTR, indicating an interrupted system call, this calls
    # PyErr_CheckSignals(), and if that set the error indicator,
    # leaves it set to that. The function always returns NULL, so a
    # wrapper function around a system call can write "return
    # PyErr_SetFromErrno(type);" when the system call returns an
    # error.

    PyObject* PyErr_SetFromErrnoWithFilename(object type, char *filename) except NULL
    # Return value: Always NULL.  Similar to PyErr_SetFromErrno(),
    # with the additional behavior that if filename is not NULL, it is
    # passed to the constructor of type as a third parameter. In the
    # case of exceptions such as IOError and OSError, this is used to
    # define the filename attribute of the exception instance.

    PyObject* PyErr_SetFromWindowsErr(int ierr) except NULL
    # Return value: Always NULL.  This is a convenience function to
    # raise WindowsError. If called with ierr of 0, the error code
    # returned by a call to GetLastError() is used instead. It calls
    # the Win32 function FormatMessage() to retrieve the Windows
    # description of error code given by ierr or GetLastError(), then
    # it constructs a tuple object whose first item is the ierr value
    # and whose second item is the corresponding error message (gotten
    # from FormatMessage()), and then calls
    # "PyErr_SetObject(PyExc_WindowsError, object)". This function
    # always returns NULL. Availability: Windows.

    PyObject* PyErr_SetExcFromWindowsErr(object type, int ierr) except NULL
    # Return value: Always NULL.  Similar to
    # PyErr_SetFromWindowsErr(), with an additional parameter
    # specifying the exception type to be raised. Availability:
    # Windows. New in version 2.3.

    PyObject* PyErr_SetFromWindowsErrWithFilename(int ierr, char *filename) except NULL
    # Return value: Always NULL.  Similar to
    # PyErr_SetFromWindowsErr(), with the additional behavior that if
    # filename is not NULL, it is passed to the constructor of
    # WindowsError as a third parameter. Availability: Windows.

    PyObject* PyErr_SetExcFromWindowsErrWithFilename(object type, int ierr, char *filename) except NULL
    # Return value: Always NULL.
    # Similar to PyErr_SetFromWindowsErrWithFilename(), with an
    # additional parameter specifying the exception type to be
    # raised. Availability: Windows.

    void PyErr_BadInternalCall()
    # This is a shorthand for "PyErr_SetString(PyExc_TypeError,
    # message)", where message indicates that an internal operation
    # (e.g. a Python/C API function) was invoked with an illegal
    # argument. It is mostly for internal use.

    int PyErr_WarnEx(object category, char *message, int stacklevel) except -1
    # Issue a warning message. The category argument is a warning
    # category (see below) or NULL; the message argument is a message
    # string. stacklevel is a positive number giving a number of stack
    # frames; the warning will be issued from the currently executing
    # line of code in that stack frame. A stacklevel of 1 is the
    # function calling PyErr_WarnEx(), 2 is the function above that,
    # and so forth.

    int PyErr_WarnExplicit(object category, char *message, char *filename, int lineno, char *module, object registry) except -1
    # Issue a warning message with explicit control over all warning
    # attributes. This is a straightforward wrapper around the Python
    # function warnings.warn_explicit(), see there for more
    # information. The module and registry arguments may be set to
    # NULL to get the default effect described there.

    int PyErr_CheckSignals() except -1
    # This function interacts with Python's signal handling. It checks
    # whether a signal has been sent to the processes and if so,
    # invokes the corresponding signal handler. If the signal module
    # is supported, this can invoke a signal handler written in
    # Python. In all cases, the default effect for SIGINT is to raise
    # the KeyboardInterrupt exception. If an exception is raised the
    # error indicator is set and the function returns 1; otherwise the
    # function returns 0. The error indicator may or may not be
    # cleared if it was previously set.

    void PyErr_SetInterrupt()
    # This function simulates the effect of a SIGINT signal arriving
    # -- the next time PyErr_CheckSignals() is called,
    # KeyboardInterrupt will be raised. It may be called without
    # holding the interpreter lock.

    object PyErr_NewException(char *name, object base, object dict)
    # Return value: New reference.
    # This utility function creates and returns a new exception
    # object. The name argument must be the name of the new exception,
    # a C string of the form module.class. The base and dict arguments
    # are normally NULL. This creates a class object derived from
    # Exception (accessible in C as PyExc_Exception).

    void PyErr_WriteUnraisable(object obj)
    # This utility function prints a warning message to sys.stderr
    # when an exception has been set but it is impossible for the
    # interpreter to actually raise the exception. It is used, for
    # example, when an exception occurs in an __del__() method.
    #
    # The function is called with a single argument obj that
    # identifies the context in which the unraisable exception
    # occurred. The repr of obj will be printed in the warning
    # message.

