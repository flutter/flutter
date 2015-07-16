from pair cimport pair

cdef extern from "<unordered_set>" namespace "std":
    cdef cppclass unordered_set[T]:
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
        unordered_set() nogil except +
        unordered_set(unordered_set&) nogil except +
        #unordered_set(key_compare&)
        #unordered_set& operator=(unordered_set&)
        bint operator==(unordered_set&, unordered_set&) nogil
        bint operator!=(unordered_set&, unordered_set&) nogil
        bint operator<(unordered_set&, unordered_set&) nogil
        bint operator>(unordered_set&, unordered_set&) nogil
        bint operator<=(unordered_set&, unordered_set&) nogil
        bint operator>=(unordered_set&, unordered_set&) nogil
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
        void swap(unordered_set&) nogil
        iterator upper_bound(T&) nogil
        #const_iterator upper_bound(T&)
        #value_compare value_comp()
