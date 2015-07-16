cdef extern from "<utility>" namespace "std":
    cdef cppclass pair[T, U]:
        T first
        U second
        pair() nogil except +
        pair(pair&) nogil except +
        pair(T&, U&) nogil except +
        bint operator==(pair&, pair&) nogil
        bint operator!=(pair&, pair&) nogil
        bint operator<(pair&, pair&) nogil
        bint operator>(pair&, pair&) nogil
        bint operator<=(pair&, pair&) nogil
        bint operator>=(pair&, pair&) nogil
