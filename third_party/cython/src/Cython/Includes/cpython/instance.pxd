cdef extern from "Python.h":

    ############################################################################
    # 7.5.2 Instance Objects
    ############################################################################

    # PyTypeObject PyInstance_Type
    #
    # Type object for class instances.

    int PyInstance_Check(object obj)
    # Return true if obj is an instance.

    object PyInstance_New(object cls, object arg, object kw)
    # Return value: New reference.
    # Create a new instance of a specific class. The parameters arg
    # and kw are used as the positional and keyword parameters to the
    # object's constructor.

    object PyInstance_NewRaw(object cls, object dict)
    # Return value: New reference.
    # Create a new instance of a specific class without calling its
    # constructor. class is the class of new object. The dict
    # parameter will be used as the object's __dict__; if NULL, a new
    # dictionary will be created for the instance.
