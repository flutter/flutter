cdef extern from "Python.h":

    ############################################################################
    # 6.5 Iterator Protocol
    ############################################################################
    bint PyIter_Check(object o)
    # Return true if the object o supports the iterator protocol.

    object PyIter_Next(object o)
    # Return value: New reference.
    # Return the next value from the iteration o. If the object is an
    # iterator, this retrieves the next value from the iteration, and
    # returns NULL with no exception set if there are no remaining
    # items. If the object is not an iterator, TypeError is raised, or
    # if there is an error in retrieving the item, returns NULL and
    # passes along the exception.

    # To write a loop which iterates over an iterator, the C code should look something like this:
    # PyObject *iterator = PyObject_GetIter(obj);
    # PyObject *item;
    # if (iterator == NULL) {
    # /* propagate error */
    # }
    # while (item = PyIter_Next(iterator)) {
    # /* do something with item */
    # ...
    # /* release reference when done */
    # Py_DECREF(item);
    # }
    # Py_DECREF(iterator);
    # if (PyErr_Occurred()) {
    # /* propagate error */
    # }
    # else {
    # /* continue doing useful work */
    # }
