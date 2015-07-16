from cpython.ref cimport PyObject

cdef extern from "Python.h":
    ctypedef struct va_list

    ############################################################################
    # 7.3.1 String Objects
    ############################################################################

    # These functions raise TypeError when expecting a string
    # parameter and are called with a non-string parameter.
    # PyStringObject
    # This subtype of PyObject represents a Python string object.
    # PyTypeObject PyString_Type
    # This instance of PyTypeObject represents the Python string type;
    # it is the same object as str and types.StringType in the Python
    # layer.

    bint PyString_Check(object o)
    # Return true if the object o is a string object or an instance of
    # a subtype of the string type.

    bint PyString_CheckExact(object o)
    # Return true if the object o is a string object, but not an instance of a subtype of the string type.

    object PyString_FromString(char *v)
    # Return value: New reference.
    # Return a new string object with the value v on success, and NULL
    # on failure. The parameter v must not be NULL; it will not be
    # checked.

    object PyString_FromStringAndSize(char *v, Py_ssize_t len)
    # Return value: New reference.
    # Return a new string object with the value v and length len on
    # success, and NULL on failure. If v is NULL, the contents of the
    # string are uninitialized.

    object PyString_FromFormat(char *format, ...)
    # Return value: New reference.
    # Take a C printf()-style format string and a variable number of
    # arguments, calculate the size of the resulting Python string and
    # return a string with the values formatted into it. The variable
    # arguments must be C types and must correspond exactly to the
    # format characters in the format string. The following format
    # characters are allowed:
    # Format Characters 	Type 	Comment
    # %% 	n/a 	The literal % character.
    # %c 	int 	A single character, represented as an C int.
    # %d 	int 	Exactly equivalent to printf("%d").
    # %u 	unsigned int 	Exactly equivalent to printf("%u").
    # %ld 	long 	Exactly equivalent to printf("%ld").
    # %lu 	unsigned long 	Exactly equivalent to printf("%lu").
    # %zd 	Py_ssize_t 	Exactly equivalent to printf("%zd").
    # %zu 	size_t 	Exactly equivalent to printf("%zu").
    # %i 	int 	Exactly equivalent to printf("%i").
    # %x 	int 	Exactly equivalent to printf("%x").
    # %s 	char* 	A null-terminated C character array.

    # %p 	void* 	The hex representation of a C pointer.
    #    Mostly equivalent to printf("%p") except that it is guaranteed to
    #    start with the literal 0x regardless of what the platform's printf
    #    yields.
    # An unrecognized format character causes all the rest of the
    # format string to be copied as-is to the result string, and any
    # extra arguments discarded.

    object PyString_FromFormatV(char *format, va_list vargs)
    # Return value: New reference.
    # Identical to PyString_FromFormat() except that it takes exactly two arguments.

    Py_ssize_t PyString_Size(object string) except -1
    # Return the length of the string in string object string.

    Py_ssize_t PyString_GET_SIZE(object string)
    # Macro form of PyString_Size() but without error checking.

    char* PyString_AsString(object string) except NULL
    # Return a NUL-terminated representation of the contents of
    # string. The pointer refers to the internal buffer of string, not
    # a copy. The data must not be modified in any way, unless the
    # string was just created using PyString_FromStringAndSize(NULL,
    # size). It must not be deallocated. If string is a Unicode
    # object, this function computes the default encoding of string
    # and operates on that. If string is not a string object at all,
    # PyString_AsString() returns NULL and raises TypeError.

    char* PyString_AS_STRING(object string)
    # Macro form of PyString_AsString() but without error
    # checking. Only string objects are supported; no Unicode objects
    # should be passed.

    int PyString_AsStringAndSize(object obj, char **buffer, Py_ssize_t *length) except -1
    # Return a NULL-terminated representation of the contents of the
    # object obj through the output variables buffer and length.
    #
    # The function accepts both string and Unicode objects as
    # input. For Unicode objects it returns the default encoded
    # version of the object. If length is NULL, the resulting buffer
    # may not contain NUL characters; if it does, the function returns
    # -1 and a TypeError is raised.

    # The buffer refers to an internal string buffer of obj, not a
    # copy. The data must not be modified in any way, unless the
    # string was just created using PyString_FromStringAndSize(NULL,
    # size). It must not be deallocated. If string is a Unicode
    # object, this function computes the default encoding of string
    # and operates on that. If string is not a string object at all,
    # PyString_AsStringAndSize() returns -1 and raises TypeError.

    void PyString_Concat(PyObject **string, object newpart)
    # Create a new string object in *string containing the contents of
    # newpart appended to string; the caller will own the new
    # reference. The reference to the old value of string will be
    # stolen. If the new string cannot be created, the old reference
    # to string will still be discarded and the value of *string will
    # be set to NULL; the appropriate exception will be set.

    void PyString_ConcatAndDel(PyObject **string, object newpart)
    # Create a new string object in *string containing the contents of
    # newpart appended to string. This version decrements the
    # reference count of newpart.

    int _PyString_Resize(PyObject **string, Py_ssize_t newsize) except -1
    # A way to resize a string object even though it is
    # ``immutable''. Only use this to build up a brand new string
    # object; don't use this if the string may already be known in
    # other parts of the code. It is an error to call this function if
    # the refcount on the input string object is not one. Pass the
    # address of an existing string object as an lvalue (it may be
    # written into), and the new size desired. On success, *string
    # holds the resized string object and 0 is returned; the address
    # in *string may differ from its input value. If the reallocation
    # fails, the original string object at *string is deallocated,
    # *string is set to NULL, a memory exception is set, and -1 is
    # returned.

    object PyString_Format(object format, object args)
    # Return value: New reference.  Return a new string object from
    # format and args. Analogous to format % args. The args argument
    # must be a tuple.

    void PyString_InternInPlace(PyObject **string)
    # Intern the argument *string in place. The argument must be the
    # address of a pointer variable pointing to a Python string
    # object. If there is an existing interned string that is the same
    # as *string, it sets *string to it (decrementing the reference
    # count of the old string object and incrementing the reference
    # count of the interned string object), otherwise it leaves
    # *string alone and interns it (incrementing its reference
    # count). (Clarification: even though there is a lot of talk about
    # reference counts, think of this function as
    # reference-count-neutral; you own the object after the call if
    # and only if you owned it before the call.)

    object PyString_InternFromString(char *v)
    # Return value: New reference.
    # A combination of PyString_FromString() and
    # PyString_InternInPlace(), returning either a new string object
    # that has been interned, or a new (``owned'') reference to an
    # earlier interned string object with the same value.

    object PyString_Decode(char *s, Py_ssize_t size, char *encoding, char *errors)
    #  Return value: New reference.
    # Create an object by decoding size bytes of the encoded buffer s
    # using the codec registered for encoding. encoding and errors
    # have the same meaning as the parameters of the same name in the
    # unicode() built-in function. The codec to be used is looked up
    # using the Python codec registry. Return NULL if an exception was
    # raised by the codec.

    object PyString_AsDecodedObject(object str, char *encoding, char *errors)
    # Return value: New reference.
    # Decode a string object by passing it to the codec registered for
    # encoding and return the result as Python object. encoding and
    # errors have the same meaning as the parameters of the same name
    # in the string encode() method. The codec to be used is looked up
    # using the Python codec registry. Return NULL if an exception was
    # raised by the codec.

    object PyString_Encode(char *s, Py_ssize_t size, char *encoding, char *errors)
    # Return value: New reference.
    # Encode the char buffer of the given size by passing it to the
    # codec registered for encoding and return a Python
    # object. encoding and errors have the same meaning as the
    # parameters of the same name in the string encode() method. The
    # codec to be used is looked up using the Python codec
    # registry. Return NULL if an exception was raised by the codec.

    object PyString_AsEncodedObject(object str, char *encoding, char *errors)
    # Return value: New reference.
    # Encode a string object using the codec registered for encoding
    # and return the result as Python object. encoding and errors have
    # the same meaning as the parameters of the same name in the
    # string encode() method. The codec to be used is looked up using
    # the Python codec registry. Return NULL if an exception was
    # raised by the codec.


