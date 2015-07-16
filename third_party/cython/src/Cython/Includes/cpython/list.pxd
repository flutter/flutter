from cpython.ref cimport PyObject

cdef extern from "Python.h":

    ############################################################################
    # Lists
    ############################################################################
    object PyList_New(Py_ssize_t len)
    # Return a new list of length len on success, or NULL on failure.
    #
    # Note: If length is greater than zero, the returned list object's
    # items are set to NULL. Thus you cannot use abstract API
    # functions such as PySequence_SetItem() or expose the object to
    # Python code before setting all items to a real object with
    # PyList_SetItem().

    bint PyList_Check(object p)
    # Return true if p is a list object or an instance of a subtype of
    # the list type.

    bint PyList_CheckExact(object p)
    # Return true if p is a list object, but not an instance of a
    # subtype of the list type.

    Py_ssize_t PyList_Size(object list) except -1
    # Return the length of the list object in list; this is equivalent
    # to "len(list)" on a list object.

    Py_ssize_t PyList_GET_SIZE(object list)
    # Macro form of PyList_Size() without error checking.

    PyObject* PyList_GetItem(object list, Py_ssize_t index) except NULL
    # Return value: Borrowed reference.
    # Return the object at position pos in the list pointed to by
    # p. The position must be positive, indexing from the end of the
    # list is not supported. If pos is out of bounds, return NULL and
    # set an IndexError exception.

    PyObject* PyList_GET_ITEM(object list, Py_ssize_t i)
    # Return value: Borrowed reference.
    # Macro form of PyList_GetItem() without error checking.

    int PyList_SetItem(object list, Py_ssize_t index, object item) except -1
    # Set the item at index index in list to item. Return 0 on success
    # or -1 on failure. Note: This function ``steals'' a reference to
    # item and discards a reference to an item already in the list at
    # the affected position.

    void PyList_SET_ITEM(object list, Py_ssize_t i, object o)
    # Macro form of PyList_SetItem() without error checking. This is
    # normally only used to fill in new lists where there is no
    # previous content. Note: This function ``steals'' a reference to
    # item, and, unlike PyList_SetItem(), does not discard a reference
    # to any item that it being replaced; any reference in list at
    # position i will be *leaked*.

    int PyList_Insert(object list, Py_ssize_t index, object item) except -1
    # Insert the item item into list list in front of index
    # index. Return 0 if successful; return -1 and set an exception if
    # unsuccessful. Analogous to list.insert(index, item).

    int PyList_Append(object list, object item) except -1
    # Append the object item at the end of list list. Return 0 if
    # successful; return -1 and set an exception if
    # unsuccessful. Analogous to list.append(item).

    object PyList_GetSlice(object list, Py_ssize_t low, Py_ssize_t high)
    # Return value: New reference.
    # Return a list of the objects in list containing the objects
    # between low and high. Return NULL and set an exception if
    # unsuccessful. Analogous to list[low:high].

    int PyList_SetSlice(object list, Py_ssize_t low, Py_ssize_t high, object itemlist) except -1
    # Set the slice of list between low and high to the contents of
    # itemlist. Analogous to list[low:high] = itemlist. The itemlist
    # may be NULL, indicating the assignment of an empty list (slice
    # deletion). Return 0 on success, -1 on failure.

    int PyList_Sort(object list) except -1
    # Sort the items of list in place. Return 0 on success, -1 on
    # failure. This is equivalent to "list.sort()".

    int PyList_Reverse(object list) except -1
    # Reverse the items of list in place. Return 0 on success, -1 on
    # failure. This is the equivalent of "list.reverse()".

    object PyList_AsTuple(object list)
    # Return value: New reference.
    # Return a new tuple object containing the contents of list;
    # equivalent to "tuple(list)".


