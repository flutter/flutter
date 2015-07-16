from pair cimport pair

cdef extern from "<set>" namespace "std":
    cdef cppclass set[T]:
        cppclass iterator:
            T& operator*()
            iterator operator++() nogil
            iterator operator--() nogil
            bint operator==(iterator) nogil
            bint operator!=(iterator) nogil
        cppclass reverse_iterator:
            T& operator*() nogil
            iterator operator++() nogil
            iterator operator--() nogil
            bint operator==(reverse_iterator) nogil
            bint operator!=(reverse_iterator) nogil
        #cppclass const_iterator(iterator):
        #    pass
        #cppclass const_reverse_iterator(reverse_iterator):
        #    pass
        set() nogil except +
        set(set&) nogil except +
        #set(key_compare&)
        #set& operator=(set&)
        bint operator==(set&, set&) nogil
        bint operator!=(set&, set&) nogil
        bint operator<(set&, set&) nogil
        bint operator>(set&, set&) nogil
        bint operator<=(set&, set&) nogil
        bint operator>=(set&, set&) nogil
        iterator begin() nogil
        #const_iterator begin()
        void clear() nogil
        size_t count(T&) nogil
        bint empty() nogil
        iterator end() nogil
        #const_iterator end()
        pair[iterator, iterator] equal_range(T&) nogil
        #pair[const_iterator, const_iterator] equal_range(T&)
        void erase(iterator) nogil
        void erase(iterator, iterator) nogil
        size_t erase(T&) nogil
        iterator find(T&) nogil
        #const_iterator find(T&)
        pair[iterator, bint] insert(T&) nogil
        iterator insert(iterator, T&) nogil
        #void insert(input_iterator, input_iterator)
        #key_compare key_comp()
        iterator lower_bound(T&) nogil
        #const_iterator lower_bound(T&)
        size_t max_size() nogil
        reverse_iterator rbegin() nogil
        #const_reverse_iterator rbegin()
        reverse_iterator rend() nogil
        #const_reverse_iterator rend()
        size_t size() nogil
        void swap(set&) nogil
        iterator upper_bound(T&) nogil
        #const_iterator upper_bound(T&)
        #value_compare value_comp()
