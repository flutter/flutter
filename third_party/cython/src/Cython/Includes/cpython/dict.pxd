from cpython.ref cimport PyObject

cdef extern from "Python.h":

    ############################################################################
    # 7.4.1 Dictionary Objects
    ############################################################################

    # PyDictObject
    #
    # This subtype of PyObject represents a Python dictionary object
    # (i.e. the 'dict' type).

    # PyTypeObject PyDict_Type
    #
    # This instance of PyTypeObject represents the Python dictionary
    # type. This is exposed to Python programs as dict and
    # types.DictType.

    bint PyDict_Check(object p)
    # Return true if p is a dict object or an instance of a subtype of
    # the dict type.

    bint PyDict_CheckExact(object p)
    # Return true if p is a dict object, but not an instance of a
    # subtype of the dict type.

    object PyDict_New()
    # Return value: New reference.
    # Return a new empty dictionary, or NULL on failure.

    object PyDictProxy_New(object dict)
    # Return value: New reference.
    # Return a proxy object for a mapping which enforces read-only
    # behavior. This is normally used to create a proxy to prevent
    # modification of the dictionary for non-dynamic class types.

    void PyDict_Clear(object p)
    # Empty an existing dictionary of all key-value pairs.

    int PyDict_Contains(object p, object key) except -1
    # Determine if dictionary p contains key. If an item in p is
    # matches key, return 1, otherwise return 0. On error, return
    # -1. This is equivalent to the Python expression "key in p".

    object PyDict_Copy(object p)
    # Return value: New reference.
    # Return a new dictionary that contains the same key-value pairs as p.

    int PyDict_SetItem(object p, object key, object val) except -1
    # Insert value into the dictionary p with a key of key. key must
    # be hashable; if it isn't, TypeError will be raised. Return 0 on
    # success or -1 on failure.

    int PyDict_SetItemString(object p, char *key, object val) except -1
    # Insert value into the dictionary p using key as a key. key
    # should be a char*. The key object is created using
    # PyString_FromString(key). Return 0 on success or -1 on failure.

    int PyDict_DelItem(object p, object key) except -1
    # Remove the entry in dictionary p with key key. key must be
    # hashable; if it isn't, TypeError is raised. Return 0 on success
    # or -1 on failure.

    int PyDict_DelItemString(object p, char *key) except -1
    # Remove the entry in dictionary p which has a key specified by
    # the string key. Return 0 on success or -1 on failure.

    PyObject* PyDict_GetItem(object p, object key)
    # Return value: Borrowed reference.
    # Return the object from dictionary p which has a key key. Return
    # NULL if the key key is not present, but without setting an
    # exception.

    PyObject* PyDict_GetItemString(object p, char *key)
    # Return value: Borrowed reference.
    # This is the same as PyDict_GetItem(), but key is specified as a
    # char*, rather than a PyObject*.

    object PyDict_Items(object p)
    # Return value: New reference.
    # Return a PyListObject containing all the items from the
    # dictionary, as in the dictionary method items() (see the Python
    # Library Reference).

    object PyDict_Keys(object p)
    # Return value: New reference.
    # Return a PyListObject containing all the keys from the
    # dictionary, as in the dictionary method keys() (see the Python
    # Library Reference).

    object PyDict_Values(object p)
    # Return value: New reference.
    # Return a PyListObject containing all the values from the
    # dictionary p, as in the dictionary method values() (see the
    # Python Library Reference).

    Py_ssize_t PyDict_Size(object p) except -1
    # Return the number of items in the dictionary. This is equivalent
    # to "len(p)" on a dictionary.

    int PyDict_Next(object p, Py_ssize_t *ppos, PyObject* *pkey, PyObject* *pvalue)
    # Iterate over all key-value pairs in the dictionary p. The int
    # referred to by ppos must be initialized to 0 prior to the first
    # call to this function to start the iteration; the function
    # returns true for each pair in the dictionary, and false once all
    # pairs have been reported. The parameters pkey and pvalue should
    # either point to PyObject* variables that will be filled in with
    # each key and value, respectively, or may be NULL. Any references
    # returned through them are borrowed. ppos should not be altered
    # during iteration. Its value represents offsets within the
    # internal dictionary structure, and since the structure is
    # sparse, the offsets are not consecutive.
    # For example:
    #
    #object key, *value;
    #int pos = 0;
    #
    #while (PyDict_Next(self->dict, &pos, &key, &value)) {
    #   /* do something interesting with the values... */
    #    ...
    #}
    # The dictionary p should not be mutated during iteration. It is
    # safe (since Python 2.1) to modify the values of the keys as you
    # iterate over the dictionary, but only so long as the set of keys
    # does not change. For example:
    # object key, *value;
    # int pos = 0;
    # while (PyDict_Next(self->dict, &pos, &key, &value)) {
    #    int i = PyInt_AS_LONG(value) + 1;
    #    object o = PyInt_FromLong(i);
    #    if (o == NULL)
    #        return -1;
    #    if (PyDict_SetItem(self->dict, key, o) < 0) {
    #        Py_DECREF(o);
    #        return -1;
    #    }
    #    Py_DECREF(o);
    # }

    int PyDict_Merge(object a, object b, int override) except -1
    # Iterate over mapping object b adding key-value pairs to
    # dictionary a. b may be a dictionary, or any object supporting
    # PyMapping_Keys() and PyObject_GetItem(). If override is true,
    # existing pairs in a will be replaced if a matching key is found
    # in b, otherwise pairs will only be added if there is not a
    # matching key in a. Return 0 on success or -1 if an exception was
    # raised.

    int PyDict_Update(object a, object b) except -1
    # This is the same as PyDict_Merge(a, b, 1) in C, or a.update(b)
    # in Python. Return 0 on success or -1 if an exception was raised.

    int PyDict_MergeFromSeq2(object a, object seq2, int override) except -1
    # Update or merge into dictionary a, from the key-value pairs in
    # seq2. seq2 must be an iterable object producing iterable objects
    # of length 2, viewed as key-value pairs. In case of duplicate
    # keys, the last wins if override is true, else the first
    # wins. Return 0 on success or -1 if an exception was
    # raised. Equivalent Python (except for the return value):
    #
    #def PyDict_MergeFromSeq2(a, seq2, override):
    #    for key, value in seq2:
    #        if override or key not in a:
    #            a[key] = value
