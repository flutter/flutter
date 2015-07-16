from cpython.ref cimport PyObject, PyTypeObject
from libc.stdio cimport FILE

cdef extern from "Python.h":

    #####################################################################
    # 6.1 Object Protocol
    #####################################################################
    int PyObject_Print(object o, FILE *fp, int flags) except -1
    # Print an object o, on file fp. Returns -1 on error. The flags
    # argument is used to enable certain printing options. The only
    # option currently supported is Py_PRINT_RAW; if given, the str()
    # of the object is written instead of the repr().

    bint PyObject_HasAttrString(object o, char *attr_name)
    # Returns 1 if o has the attribute attr_name, and 0
    # otherwise. This is equivalent to the Python expression
    # "hasattr(o, attr_name)". This function always succeeds.

    object PyObject_GetAttrString(object o, char *attr_name)
    # Return value: New reference.  Retrieve an attribute named
    # attr_name from object o. Returns the attribute value on success,
    # or NULL on failure. This is the equivalent of the Python
    # expression "o.attr_name".

    bint PyObject_HasAttr(object o, object attr_name)
    # Returns 1 if o has the attribute attr_name, and 0
    # otherwise. This is equivalent to the Python expression
    # "hasattr(o, attr_name)". This function always succeeds.

    object PyObject_GetAttr(object o, object attr_name)
    # Return value: New reference.  Retrieve an attribute named
    # attr_name from object o. Returns the attribute value on success,
    # or NULL on failure. This is the equivalent of the Python
    # expression "o.attr_name".

    int PyObject_SetAttrString(object o, char *attr_name, object v) except -1
    # Set the value of the attribute named attr_name, for object o, to
    # the value v. Returns -1 on failure. This is the equivalent of
    # the Python statement "o.attr_name = v".

    int PyObject_SetAttr(object o, object attr_name, object v) except -1
    # Set the value of the attribute named attr_name, for object o, to
    # the value v. Returns -1 on failure. This is the equivalent of
    # the Python statement "o.attr_name = v".

    int PyObject_DelAttrString(object o, char *attr_name) except -1
    # Delete attribute named attr_name, for object o. Returns -1 on
    # failure. This is the equivalent of the Python statement: "del
    # o.attr_name".

    int PyObject_DelAttr(object o, object attr_name) except -1
    # Delete attribute named attr_name, for object o. Returns -1 on
    # failure. This is the equivalent of the Python statement "del
    # o.attr_name".

    int Py_LT, Py_LE, Py_EQ, Py_NE, Py_GT, Py_GE

    object PyObject_RichCompare(object o1, object o2, int opid)
    # Return value: New reference.
    # Compare the values of o1 and o2 using the operation specified by
    # opid, which must be one of Py_LT, Py_LE, Py_EQ, Py_NE, Py_GT, or
    # Py_GE, corresponding to <, <=, ==, !=, >, or >=
    # respectively. This is the equivalent of the Python expression
    # "o1 op o2", where op is the operator corresponding to
    # opid. Returns the value of the comparison on success, or NULL on
    # failure.

    bint PyObject_RichCompareBool(object o1, object o2, int opid) except -1
    # Compare the values of o1 and o2 using the operation specified by
    # opid, which must be one of Py_LT, Py_LE, Py_EQ, Py_NE, Py_GT, or
    # Py_GE, corresponding to <, <=, ==, !=, >, or >=
    # respectively. Returns -1 on error, 0 if the result is false, 1
    # otherwise. This is the equivalent of the Python expression "o1
    # op o2", where op is the operator corresponding to opid.

    int PyObject_Cmp(object o1, object o2, int *result) except -1
    # Compare the values of o1 and o2 using a routine provided by o1,
    # if one exists, otherwise with a routine provided by o2. The
    # result of the comparison is returned in result. Returns -1 on
    # failure. This is the equivalent of the Python statement "result
    # = cmp(o1, o2)".

    int PyObject_Compare(object o1, object o2) except *
    # Compare the values of o1 and o2 using a routine provided by o1,
    # if one exists, otherwise with a routine provided by o2. Returns
    # the result of the comparison on success. On error, the value
    # returned is undefined; use PyErr_Occurred() to detect an
    # error. This is equivalent to the Python expression "cmp(o1,
    # o2)".

    object PyObject_Repr(object o)
    # Return value: New reference.
    # Compute a string representation of object o. Returns the string
    # representation on success, NULL on failure. This is the
    # equivalent of the Python expression "repr(o)". Called by the
    # repr() built-in function and by reverse quotes.

    object PyObject_Str(object o)
    # Return value: New reference.
    # Compute a string representation of object o. Returns the string
    # representation on success, NULL on failure. This is the
    # equivalent of the Python expression "str(o)". Called by the
    # str() built-in function and by the print statement.

    object PyObject_Unicode(object o)
    # Return value: New reference.
    # Compute a Unicode string representation of object o. Returns the
    # Unicode string representation on success, NULL on failure. This
    # is the equivalent of the Python expression "unicode(o)". Called
    # by the unicode() built-in function.

    bint PyObject_IsInstance(object inst, object cls) except -1
    # Returns 1 if inst is an instance of the class cls or a subclass
    # of cls, or 0 if not. On error, returns -1 and sets an
    # exception. If cls is a type object rather than a class object,
    # PyObject_IsInstance() returns 1 if inst is of type cls. If cls
    # is a tuple, the check will be done against every entry in
    # cls. The result will be 1 when at least one of the checks
    # returns 1, otherwise it will be 0. If inst is not a class
    # instance and cls is neither a type object, nor a class object,
    # nor a tuple, inst must have a __class__ attribute -- the class
    # relationship of the value of that attribute with cls will be
    # used to determine the result of this function.

    # Subclass determination is done in a fairly straightforward way,
    # but includes a wrinkle that implementors of extensions to the
    # class system may want to be aware of. If A and B are class
    # objects, B is a subclass of A if it inherits from A either
    # directly or indirectly. If either is not a class object, a more
    # general mechanism is used to determine the class relationship of
    # the two objects. When testing if B is a subclass of A, if A is
    # B, PyObject_IsSubclass() returns true. If A and B are different
    # objects, B's __bases__ attribute is searched in a depth-first
    # fashion for A -- the presence of the __bases__ attribute is
    # considered sufficient for this determination.

    bint PyObject_IsSubclass(object derived, object cls) except -1
    # Returns 1 if the class derived is identical to or derived from
    # the class cls, otherwise returns 0. In case of an error, returns
    # -1. If cls is a tuple, the check will be done against every
    # entry in cls. The result will be 1 when at least one of the
    # checks returns 1, otherwise it will be 0. If either derived or
    # cls is not an actual class object (or tuple), this function uses
    # the generic algorithm described above. New in version
    # 2.1. Changed in version 2.3: Older versions of Python did not
    # support a tuple as the second argument.

    bint PyCallable_Check(object o)
    # Determine if the object o is callable. Return 1 if the object is
    # callable and 0 otherwise. This function always succeeds.

    object PyObject_Call(object callable_object, object args, object kw)
    # Return value: New reference.
    # Call a callable Python object callable_object, with arguments
    # given by the tuple args, and named arguments given by the
    # dictionary kw. If no named arguments are needed, kw may be
    # NULL. args must not be NULL, use an empty tuple if no arguments
    # are needed. Returns the result of the call on success, or NULL
    # on failure. This is the equivalent of the Python expression
    # "apply(callable_object, args, kw)" or "callable_object(*args,
    # **kw)".

    object PyObject_CallObject(object callable_object, object args)
    # Return value: New reference.
    # Call a callable Python object callable_object, with arguments
    # given by the tuple args. If no arguments are needed, then args
    # may be NULL. Returns the result of the call on success, or NULL
    # on failure. This is the equivalent of the Python expression
    # "apply(callable_object, args)" or "callable_object(*args)".

    object PyObject_CallFunction(object callable, char *format, ...)
    # Return value: New reference.
    # Call a callable Python object callable, with a variable number
    # of C arguments. The C arguments are described using a
    # Py_BuildValue() style format string. The format may be NULL,
    # indicating that no arguments are provided. Returns the result of
    # the call on success, or NULL on failure. This is the equivalent
    # of the Python expression "apply(callable, args)" or
    # "callable(*args)". Note that if you only pass object  args,
    # PyObject_CallFunctionObjArgs is a faster alternative.

    object PyObject_CallMethod(object o, char *method, char *format, ...)
    # Return value: New reference.
    # Call the method named method of object o with a variable number
    # of C arguments. The C arguments are described by a
    # Py_BuildValue() format string that should produce a tuple. The
    # format may be NULL, indicating that no arguments are
    # provided. Returns the result of the call on success, or NULL on
    # failure. This is the equivalent of the Python expression
    # "o.method(args)". Note that if you only pass object  args,
    # PyObject_CallMethodObjArgs is a faster alternative.

    #object PyObject_CallFunctionObjArgs(object callable, ..., NULL)
    object PyObject_CallFunctionObjArgs(object callable, ...)
    # Return value: New reference.
    # Call a callable Python object callable, with a variable number
    # of PyObject* arguments. The arguments are provided as a variable
    # number of parameters followed by NULL. Returns the result of the
    # call on success, or NULL on failure.

    #PyObject* PyObject_CallMethodObjArgs(object o, object name, ..., NULL)
    object PyObject_CallMethodObjArgs(object o, object name, ...)
    # Return value: New reference.
    # Calls a method of the object o, where the name of the method is
    # given as a Python string object in name. It is called with a
    # variable number of PyObject* arguments. The arguments are
    # provided as a variable number of parameters followed by
    # NULL. Returns the result of the call on success, or NULL on
    # failure.

    long PyObject_Hash(object o) except? -1
    # Compute and return the hash value of an object o. On failure,
    # return -1. This is the equivalent of the Python expression
    # "hash(o)".

    bint PyObject_IsTrue(object o) except -1
    # Returns 1 if the object o is considered to be true, and 0
    # otherwise. This is equivalent to the Python expression "not not
    # o". On failure, return -1.

    bint PyObject_Not(object o) except -1
    # Returns 0 if the object o is considered to be true, and 1
    # otherwise. This is equivalent to the Python expression "not
    # o". On failure, return -1.

    object PyObject_Type(object o)
    # Return value: New reference.
    # When o is non-NULL, returns a type object corresponding to the
    # object type of object o. On failure, raises SystemError and
    # returns NULL. This is equivalent to the Python expression
    # type(o). This function increments the reference count of the
    # return value. There's really no reason to use this function
    # instead of the common expression o->ob_type, which returns a
    # pointer of type PyTypeObject*, except when the incremented
    # reference count is needed.

    bint PyObject_TypeCheck(object o, PyTypeObject *type)
    # Return true if the object o is of type type or a subtype of
    # type. Both parameters must be non-NULL.

    Py_ssize_t PyObject_Length(object o) except -1
    Py_ssize_t PyObject_Size(object o) except -1
    # Return the length of object o. If the object o provides either
    # the sequence and mapping protocols, the sequence length is
    # returned. On error, -1 is returned. This is the equivalent to
    # the Python expression "len(o)".

    object PyObject_GetItem(object o, object key)
    # Return value: New reference.
    # Return element of o corresponding to the object key or NULL on
    # failure. This is the equivalent of the Python expression
    # "o[key]".

    int PyObject_SetItem(object o, object key, object v) except -1
    # Map the object key to the value v. Returns -1 on failure. This
    # is the equivalent of the Python statement "o[key] = v".

    int PyObject_DelItem(object o, object key) except -1
    # Delete the mapping for key from o. Returns -1 on failure. This
    # is the equivalent of the Python statement "del o[key]".

    int PyObject_AsFileDescriptor(object o) except -1
    # Derives a file-descriptor from a Python object. If the object is
    # an integer or long integer, its value is returned. If not, the
    # object's fileno() method is called if it exists; the method must
    # return an integer or long integer, which is returned as the file
    # descriptor value. Returns -1 on failure.

    object PyObject_Dir(object o)
    # Return value: New reference.
    # This is equivalent to the Python expression "dir(o)", returning
    # a (possibly empty) list of strings appropriate for the object
    # argument, or NULL if there was an error. If the argument is
    # NULL, this is like the Python "dir()", returning the names of
    # the current locals; in this case, if no execution frame is
    # active then NULL is returned but PyErr_Occurred() will return
    # false.

    object PyObject_GetIter(object o)
    # Return value: New reference.
    # This is equivalent to the Python expression "iter(o)". It
    # returns a new iterator for the object argument, or the object
    # itself if the object is already an iterator. Raises TypeError
    # and returns NULL if the object cannot be iterated.

    Py_ssize_t Py_SIZE(object o)

    object PyObject_Format(object obj, object format_spec)
    # Takes an arbitrary object and returns the result of calling
    # obj.__format__(format_spec).
    # Added in Py2.6
