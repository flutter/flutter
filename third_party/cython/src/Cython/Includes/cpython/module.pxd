from cpython.ref cimport PyObject

cdef extern from "Python.h":
    ctypedef struct _inittab

    #####################################################################
    # 5.3 Importing Modules
    #####################################################################
    object PyImport_ImportModule(char *name)
    # Return value: New reference.
    # This is a simplified interface to PyImport_ImportModuleEx()
    # below, leaving the globals and locals arguments set to
    # NULL. When the name argument contains a dot (when it specifies a
    # submodule of a package), the fromlist argument is set to the
    # list ['*'] so that the return value is the named module rather
    # than the top-level package containing it as would otherwise be
    # the case. (Unfortunately, this has an additional side effect
    # when name in fact specifies a subpackage instead of a submodule:
    # the submodules specified in the package's __all__ variable are
    # loaded.) Return a new reference to the imported module, or NULL
    # with an exception set on failure.

    object PyImport_ImportModuleEx(char *name, object globals, object locals, object fromlist)
    # Return value: New reference.

    # Import a module. This is best described by referring to the
    # built-in Python function __import__(), as the standard
    # __import__() function calls this function directly.

    # The return value is a new reference to the imported module or
    # top-level package, or NULL with an exception set on failure
    # (before Python 2.4, the module may still be created in this
    # case). Like for __import__(), the return value when a submodule
    # of a package was requested is normally the top-level package,
    # unless a non-empty fromlist was given. Changed in version 2.4:
    # failing imports remove incomplete module objects.

    object PyImport_Import(object name)
    # Return value: New reference.
    # This is a higher-level interface that calls the current ``import
    # hook function''. It invokes the __import__() function from the
    # __builtins__ of the current globals. This means that the import
    # is done using whatever import hooks are installed in the current
    # environment, e.g. by rexec or ihooks.

    object PyImport_ReloadModule(object m)
    # Return value: New reference.
    # Reload a module. This is best described by referring to the
    # built-in Python function reload(), as the standard reload()
    # function calls this function directly. Return a new reference to
    # the reloaded module, or NULL with an exception set on failure
    # (the module still exists in this case).

    PyObject* PyImport_AddModule(char *name) except NULL
    # Return value: Borrowed reference.
    # Return the module object corresponding to a module name. The
    # name argument may be of the form package.module. First check the
    # modules dictionary if there's one there, and if not, create a
    # new one and insert it in the modules dictionary. Return NULL
    # with an exception set on failure. Note: This function does not
    # load or import the module; if the module wasn't already loaded,
    # you will get an empty module object. Use PyImport_ImportModule()
    # or one of its variants to import a module. Package structures
    # implied by a dotted name for name are not created if not already
    # present.

    object PyImport_ExecCodeModule(char *name, object co)
    # Return value: New reference.
    # Given a module name (possibly of the form package.module) and a
    # code object read from a Python bytecode file or obtained from
    # the built-in function compile(), load the module. Return a new
    # reference to the module object, or NULL with an exception set if
    # an error occurred. Name is removed from sys.modules in error
    # cases, and even if name was already in sys.modules on entry to
    # PyImport_ExecCodeModule(). Leaving incompletely initialized
    # modules in sys.modules is dangerous, as imports of such modules
    # have no way to know that the module object is an unknown (and
    # probably damaged with respect to the module author's intents)
    # state.
    # This function will reload the module if it was already
    # imported. See PyImport_ReloadModule() for the intended way to
    # reload a module.
    # If name points to a dotted name of the form package.module, any
    # package structures not already created will still not be
    # created.


    long PyImport_GetMagicNumber()
    # Return the magic number for Python bytecode files (a.k.a. .pyc
    # and .pyo files). The magic number should be present in the first
    # four bytes of the bytecode file, in little-endian byte order.

    PyObject* PyImport_GetModuleDict() except NULL
    # Return value: Borrowed reference.
    # Return the dictionary used for the module administration
    # (a.k.a. sys.modules). Note that this is a per-interpreter
    # variable.


    int PyImport_ImportFrozenModule(char *name) except -1
    # Load a frozen module named name. Return 1 for success, 0 if the
    # module is not found, and -1 with an exception set if the
    # initialization failed. To access the imported module on a
    # successful load, use PyImport_ImportModule(). (Note the misnomer
    # -- this function would reload the module if it was already
    # imported.)


    int PyImport_ExtendInittab(_inittab *newtab) except -1
    # Add a collection of modules to the table of built-in
    # modules. The newtab array must end with a sentinel entry which
    # contains NULL for the name field; failure to provide the
    # sentinel value can result in a memory fault. Returns 0 on
    # success or -1 if insufficient memory could be allocated to
    # extend the internal table. In the event of failure, no modules
    # are added to the internal table. This should be called before
    # Py_Initialize().

    #####################################################################
    # 7.5.5 Module Objects
    #####################################################################

    # PyTypeObject PyModule_Type
    #
    # This instance of PyTypeObject represents the Python module
    # type. This is exposed to Python programs as types.ModuleType.

    bint PyModule_Check(object p)
    # Return true if p is a module object, or a subtype of a module
    # object.

    bint PyModule_CheckExact(object p)
    # Return true if p is a module object, but not a subtype of PyModule_Type.

    object PyModule_New(char *name)
    # Return value: New reference.
    # Return a new module object with the __name__ attribute set to
    # name. Only the module's __doc__ and __name__ attributes are
    # filled in; the caller is responsible for providing a __file__
    # attribute.

    PyObject* PyModule_GetDict(object module) except NULL
    # Return value: Borrowed reference.
    # Return the dictionary object that implements module's namespace;
    # this object is the same as the __dict__ attribute of the module
    # object. This function never fails. It is recommended extensions
    # use other PyModule_*() and PyObject_*() functions rather than
    # directly manipulate a module's __dict__.

    char* PyModule_GetName(object module) except NULL
    # Return module's __name__ value. If the module does not provide
    # one, or if it is not a string, SystemError is raised and NULL is
    # returned.

    char* PyModule_GetFilename(object module) except NULL
    # Return the name of the file from which module was loaded using
    # module's __file__ attribute. If this is not defined, or if it is
    # not a string, raise SystemError and return NULL.

    int PyModule_AddObject(object module,  char *name, object value) except -1
    # Add an object to module as name. This is a convenience function
    # which can be used from the module's initialization
    # function. This steals a reference to value. Return -1 on error,
    # 0 on success.

    int PyModule_AddIntant(object module,  char *name, long value) except -1
    # Add an integer ant to module as name. This convenience
    # function can be used from the module's initialization
    # function. Return -1 on error, 0 on success.

    int PyModule_AddStringant(object module,  char *name,  char *value) except -1
    # Add a string constant to module as name. This convenience
    # function can be used from the module's initialization
    # function. The string value must be null-terminated. Return -1 on
    # error, 0 on success.
