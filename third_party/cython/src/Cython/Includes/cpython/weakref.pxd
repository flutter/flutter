from cpython.ref cimport PyObject

cdef extern from "Python.h":

    bint PyWeakref_Check(object ob)
    # Return true if ob is either a reference or proxy object.

    bint PyWeakref_CheckRef(object ob)
    # Return true if ob is a reference object.

    bint PyWeakref_CheckProxy(ob)
    # Return true if *ob* is a proxy object.

    object PyWeakref_NewRef(object ob, object callback)
    # Return a weak reference object for the object ob.  This will
    # always return a new reference, but is not guaranteed to create a
    # new object; an existing reference object may be returned.  The
    # second parameter, callback, can be a callable object that
    # receives notification when ob is garbage collected; it should
    # accept a single parameter, which will be the weak reference
    # object itself. callback may also be None or NULL.  If ob is not
    # a weakly-referencable object, or if callback is not callable,
    # None, or NULL, this will return NULL and raise TypeError.

    object PyWeakref_NewProxy(object ob, object callback)
    # Return a weak reference proxy object for the object ob.  This
    # will always return a new reference, but is not guaranteed to
    # create a new object; an existing proxy object may be returned.
    # The second parameter, callback, can be a callable object that
    # receives notification when ob is garbage collected; it should
    # accept a single parameter, which will be the weak reference
    # object itself. callback may also be None or NULL.  If ob is not
    # a weakly-referencable object, or if callback is not callable,
    # None, or NULL, this will return NULL and raise TypeError.

    PyObject* PyWeakref_GetObject(object ref)
    # Return the referenced object from a weak reference, ref.  If the
    # referent is no longer live, returns None.

    PyObject* PyWeakref_GET_OBJECT(object ref)
    # Similar to PyWeakref_GetObject, but implemented as a macro that
    # does no error checking.
