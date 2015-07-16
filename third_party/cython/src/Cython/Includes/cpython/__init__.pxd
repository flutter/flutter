#####################################################################
#
# These are the Cython pxd files for (most of) the Python/C API.
#
# REFERENCE COUNTING:
#
#   JUST TO SCARE YOU:
#   If you are going to use any of the Python/C API in your Cython
#   program, you might be responsible for doing reference counting.
#   Read http://docs.python.org/api/refcounts.html which is so
#   important I've copied it below.
#
# For all the declaration below, whenver the Py_ function returns
# a *new reference* to a PyObject*, the return type is "object".
# When the function returns a borrowed reference, the return
# type is PyObject*.  When Cython sees "object" as a return type
# it doesn't increment the reference count.  When it sees PyObject*
# in order to use the result you must explicitly cast to <object>,
# and when you do that Cython increments the reference count wether
# you want it to or not, forcing you to an explicit DECREF (or leak memory).
# To avoid this we make the above convention.  Note, you can
# always locally override this convention by putting something like
#
#     cdef extern from "Python.h":
#         PyObject* PyNumber_Add(PyObject *o1, PyObject *o2)
#
# in your .pyx file or into a cimported .pxd file.  You just have to
# use the one from the right (pxd-)namespace then.
#
# Cython automatically takes care of reference counting for anything
# of type object.
#
## More precisely, I think the correct convention for
## using the Python/C API from Cython is as follows.
##
## (1) Declare all input arguments as type "object".  This way no explicit
##    <PyObject*> casting is needed, and moreover Cython doesn't generate
##    any funny reference counting.
## (2) Declare output as object if a new reference is returned.
## (3) Declare output as PyObject* if a borrowed reference is returned.
##
## This way when you call objects, no cast is needed, and if the api
## calls returns a new reference (which is about 95% of them), then
## you can just assign to a variable of type object.  With borrowed
## references if you do an explicit typecast to <object>, Cython generates an
## INCREF and DECREF so you have to be careful.  However, you got a
## borrowed reference in this case, so there's got to be another reference
## to your object, so you're OK, as long as you relealize this
## and use the result of an explicit cast to <object> as a borrowed
## reference (and you can call Py_INCREF if you want to turn it
## into another reference for some reason).
#
# "The reference count is important because today's computers have
# a finite (and often severely limited) memory size; it counts how
# many different places there are that have a reference to an
# object. Such a place could be another object, or a global (or
# static) C variable, or a local variable in some C function. When
# an object's reference count becomes zero, the object is
# deallocated. If it contains references to other objects, their
# reference count is decremented. Those other objects may be
# deallocated in turn, if this decrement makes their reference
# count become zero, and so on. (There's an obvious problem with
# objects that reference each other here; for now, the solution is
# ``don't do that.'')
#
# Reference counts are always manipulated explicitly. The normal
# way is to use the macro Py_INCREF() to increment an object's
# reference count by one, and Py_DECREF() to decrement it by
# one. The Py_DECREF() macro is considerably more complex than the
# incref one, since it must check whether the reference count
# becomes zero and then cause the object's deallocator to be
# called. The deallocator is a function pointer contained in the
# object's type structure. The type-specific deallocator takes
# care of decrementing the reference counts for other objects
# contained in the object if this is a compound object type, such
# as a list, as well as performing any additional finalization
# that's needed. There's no chance that the reference count can
# overflow; at least as many bits are used to hold the reference
# count as there are distinct memory locations in virtual memory
# (assuming sizeof(long) >= sizeof(char*)). Thus, the reference
# count increment is a simple operation.
#
# It is not necessary to increment an object's reference count for
# every local variable that contains a pointer to an object. In
# theory, the object's reference count goes up by one when the
# variable is made to point to it and it goes down by one when the
# variable goes out of scope. However, these two cancel each other
# out, so at the end the reference count hasn't changed. The only
# real reason to use the reference count is to prevent the object
# from being deallocated as long as our variable is pointing to
# it. If we know that there is at least one other reference to the
# object that lives at least as long as our variable, there is no
# need to increment the reference count temporarily. An important
# situation where this arises is in objects that are passed as
# arguments to C functions in an extension module that are called
# from Python; the call mechanism guarantees to hold a reference
# to every argument for the duration of the call.
#
# However, a common pitfall is to extract an object from a list
# and hold on to it for a while without incrementing its reference
# count. Some other operation might conceivably remove the object
# from the list, decrementing its reference count and possible
# deallocating it. The real danger is that innocent-looking
# operations may invoke arbitrary Python code which could do this;
# there is a code path which allows control to flow back to the
# user from a Py_DECREF(), so almost any operation is potentially
# dangerous.
#
# A safe approach is to always use the generic operations
# (functions whose name begins with "PyObject_", "PyNumber_",
# "PySequence_" or "PyMapping_"). These operations always
# increment the reference count of the object they return. This
# leaves the caller with the responsibility to call Py_DECREF()
# when they are done with the result; this soon becomes second
# nature.
#
# Now you should read http://docs.python.org/api/refcountDetails.html
# just to be sure you understand what is going on.
#
#################################################################



#################################################################
# BIG FAT DEPRECATION WARNING
#################################################################
# Do NOT cimport any names directly from the cpython package,
# despite of the star-imports below.  They will be removed at
# some point.
# Instead, use the correct sub-module to draw your cimports from.
#
# A direct cimport from the package will make your code depend on
# all of the existing declarations. This may have side-effects
# and reduces the portability of your code.
#################################################################
# START OF DEPRECATED SECTION
#################################################################

from cpython.version cimport *
from cpython.ref cimport *
from cpython.exc cimport *
from cpython.module cimport *
from cpython.mem cimport *
from cpython.tuple cimport *
from cpython.list cimport *
from cpython.object cimport *
from cpython.sequence cimport *
from cpython.mapping cimport *
from cpython.iterator cimport *
from cpython.type cimport *
from cpython.number cimport *
from cpython.int cimport *
from cpython.bool cimport *
from cpython.long cimport *
from cpython.float cimport *
from cpython.complex cimport *
from cpython.string cimport *
from cpython.unicode cimport *
from cpython.dict cimport *
from cpython.instance cimport *
from cpython.function cimport *
from cpython.method cimport *
from cpython.weakref cimport *
from cpython.getargs cimport *
from cpython.pythread cimport *
from cpython.pystate cimport *

# Python <= 2.x
from cpython.cobject cimport *
from cpython.oldbuffer cimport *

# Python >= 2.4
from cpython.set cimport *

# Python >= 2.6
from cpython.buffer cimport *
from cpython.bytes cimport *

# Python >= 3.0
from cpython.pycapsule cimport *

#################################################################
# END OF DEPRECATED SECTION
#################################################################
