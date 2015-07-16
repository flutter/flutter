# TODO: Figure out how many of the pass-by-value copies the compiler can eliminate.


#################### string.from_py ####################

cdef extern from *:
    cdef cppclass string "std::string":
        string()
        string(char* c_str, size_t size)
    cdef char* __Pyx_PyObject_AsStringAndSize(object, Py_ssize_t*) except NULL

@cname("{{cname}}")
cdef string {{cname}}(object o) except *:
    cdef Py_ssize_t length
    cdef char* data = __Pyx_PyObject_AsStringAndSize(o, &length)
    return string(data, length)


#################### string.to_py ####################

#cimport cython
#from libcpp.string cimport string
cdef extern from *:
    cdef cppclass string "const std::string":
        char* data()
        size_t size()
    cdef object __Pyx_PyObject_FromStringAndSize(char*, size_t)

@cname("{{cname}}")
cdef object {{cname}}(string& s):
    return __Pyx_PyObject_FromStringAndSize(s.data(), s.size())


#################### vector.from_py ####################

{{template_type_declarations}}

cdef extern from *:
    cdef cppclass vector "std::vector" [T]:
        void push_back(T&)

@cname("{{cname}}")
cdef vector[X] {{cname}}(object o) except *:
    cdef vector[X] v
    for item in o:
        v.push_back(X_from_py(item))
    return v


#################### vector.to_py ####################

{{template_type_declarations}}

cdef extern from *:
    cdef cppclass vector "const std::vector" [T]:
        size_t size()
        T& operator[](size_t)

@cname("{{cname}}")
cdef object {{cname}}(vector[X]& v):
    return [X_to_py(v[i]) for i in range(v.size())]


#################### list.from_py ####################

{{template_type_declarations}}

cdef extern from *:
    cdef cppclass cpp_list "std::list" [T]:
        void push_back(T&)

@cname("{{cname}}")
cdef cpp_list[X] {{cname}}(object o) except *:
    cdef cpp_list[X] l
    for item in o:
        l.push_back(X_from_py(item))
    return l


#################### list.to_py ####################

cimport cython

{{template_type_declarations}}

cdef extern from *:
    cdef cppclass cpp_list "std::list" [T]:
        cppclass const_iterator:
            T& operator*()
            const_iterator operator++()
            bint operator!=(const_iterator)
        const_iterator begin()
        const_iterator end()
    cdef cppclass const_cpp_list "const std::list" [T] (cpp_list):
        pass

@cname("{{cname}}")
cdef object {{cname}}(const_cpp_list[X]& v):
    o = []
    cdef cpp_list[X].const_iterator iter = v.begin()
    while iter != v.end():
        o.append(X_to_py(cython.operator.dereference(iter)))
        cython.operator.preincrement(iter)
    return o


#################### set.from_py ####################

{{template_type_declarations}}

cdef extern from *:
    cdef cppclass set "std::{{maybe_unordered}}set" [T]:
        void insert(T&)

@cname("{{cname}}")
cdef set[X] {{cname}}(object o) except *:
    cdef set[X] s
    for item in o:
        s.insert(X_from_py(item))
    return s


#################### set.to_py ####################

cimport cython

{{template_type_declarations}}

cdef extern from *:
    cdef cppclass cpp_set "std::{{maybe_unordered}}set" [T]:
        cppclass const_iterator:
            T& operator*()
            const_iterator operator++()
            bint operator!=(const_iterator)
        const_iterator begin()
        const_iterator end()
    cdef cppclass const_cpp_set "const std::{{maybe_unordered}}set" [T](cpp_set):
        pass

@cname("{{cname}}")
cdef object {{cname}}(const_cpp_set[X]& s):
    o = set()
    cdef cpp_set[X].const_iterator iter = s.begin()
    while iter != s.end():
        o.add(X_to_py(cython.operator.dereference(iter)))
        cython.operator.preincrement(iter)
    return o

#################### pair.from_py ####################

{{template_type_declarations}}

cdef extern from *:
    cdef cppclass pair "std::pair" [T, U]:
        pair()
        pair(T&, U&)

@cname("{{cname}}")
cdef pair[X,Y] {{cname}}(object o) except *:
    x, y = o
    return pair[X,Y](X_from_py(x), Y_from_py(y))


#################### pair.to_py ####################

{{template_type_declarations}}

cdef extern from *:
    cdef cppclass pair "const std::pair" [T, U]:
        T first
        U second

@cname("{{cname}}")
cdef object {{cname}}(pair[X,Y]& p):
    return X_to_py(p.first), Y_to_py(p.second)


#################### map.from_py ####################

{{template_type_declarations}}

cdef extern from *:
    cdef cppclass pair "std::pair" [T, U]:
        pair(T&, U&)
    cdef cppclass map "std::{{maybe_unordered}}map" [T, U]:
        void insert(pair[T, U]&)

    cdef cppclass pair "std::pair" [T, U]:
        pass
    cdef cppclass vector "std::vector" [T]:
        pass


@cname("{{cname}}")
cdef map[X,Y] {{cname}}(object o) except *:
    cdef dict d = o
    cdef map[X,Y] m
    for key, value in d.iteritems():
        m.insert(pair[X,Y](X_from_py(key), Y_from_py(value)))
    return m


#################### map.to_py ####################
# TODO: Work out const so that this can take a const
# reference rather than pass by value.

cimport cython

{{template_type_declarations}}

cdef extern from *:
    cdef cppclass map "std::{{maybe_unordered}}map" [T, U]:
        cppclass value_type:
            T first
            U second
        cppclass iterator:
            value_type& operator*()
            iterator operator++()
            bint operator!=(iterator)
        iterator begin()
        iterator end()

@cname("{{cname}}")
cdef object {{cname}}(map[X,Y] s):
    o = {}
    cdef map[X,Y].value_type *key_value
    cdef map[X,Y].iterator iter = s.begin()
    while iter != s.end():
        key_value = &cython.operator.dereference(iter)
        o[X_to_py(key_value.first)] = Y_to_py(key_value.second)
        cython.operator.preincrement(iter)
    return o
