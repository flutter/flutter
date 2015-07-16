cdef extern from "Python.h":

    ############################################################################
    # 6.4 Mapping Protocol
    ############################################################################

    bint PyMapping_Check(object o)
    # Return 1 if the object provides mapping protocol, and 0
    # otherwise. This function always succeeds.

    Py_ssize_t PyMapping_Length(object o) except -1
    # Returns the number of keys in object o on success, and -1 on
    # failure. For objects that do not provide mapping protocol, this
    # is equivalent to the Python expression "len(o)".

    int PyMapping_DelItemString(object o, char *key) except -1
    # Remove the mapping for object key from the object o. Return -1
    # on failure. This is equivalent to the Python statement "del
    # o[key]".

    int PyMapping_DelItem(object o, object key) except -1
    # Remove the mapping for object key from the object o. Return -1
    # on failure. This is equivalent to the Python statement "del
    # o[key]".

    bint PyMapping_HasKeyString(object o, char *key)
    # On success, return 1 if the mapping object has the key key and 0
    # otherwise. This is equivalent to the Python expression
    # "o.has_key(key)". This function always succeeds.

    bint PyMapping_HasKey(object o, object key)
    # Return 1 if the mapping object has the key key and 0
    # otherwise. This is equivalent to the Python expression
    # "o.has_key(key)". This function always succeeds.

    object PyMapping_Keys(object o)
    # Return value: New reference.
    # On success, return a list of the keys in object o. On failure,
    # return NULL. This is equivalent to the Python expression
    # "o.keys()".

    object PyMapping_Values(object o)
    # Return value: New reference.
    # On success, return a list of the values in object o. On failure,
    # return NULL. This is equivalent to the Python expression
    # "o.values()".

    object PyMapping_Items(object o)
    # Return value: New reference.
    # On success, return a list of the items in object o, where each
    # item is a tuple containing a key-value pair. On failure, return
    # NULL. This is equivalent to the Python expression "o.items()".

    object PyMapping_GetItemString(object o, char *key)
    # Return value: New reference.
    # Return element of o corresponding to the object key or NULL on
    # failure. This is the equivalent of the Python expression
    # "o[key]".

    int PyMapping_SetItemString(object o, char *key, object v) except -1
    # Map the object key to the value v in object o. Returns -1 on
    # failure. This is the equivalent of the Python statement "o[key]
    # = v".

