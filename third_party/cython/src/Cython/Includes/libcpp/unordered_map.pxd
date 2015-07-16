from utility cimport pair

cdef extern from "<unordered_map>" namespace "std":
    cdef cppclass unordered_map[T, U]:
        cppclass iterator:
            pair[T, U]& operator*() nogil
            iterator operator++() nogil
            iterator operator--() nogil
            bint operator==(iterator) nogil
            bint operator!=(iterator) nogil
        cppclass reverse_iterator:
            pair[T, U]& operator*() nogil
            iterator operator++() nogil
            iterator operator--() nogil
            bint operator==(reverse_iterator) nogil
            bint operator!=(reverse_iterator) nogil
        #cppclass const_iterator(iterator):
        #    pass
        #cppclass const_reverse_iterator(reverse_iterator):
        #    pass
        unordered_map() nogil except +
        unordered_map(unordered_map&) nogil except +
        #unordered_map(key_compare&)
        U& operator[](T&) nogil
        #unordered_map& operator=(unordered_map&)
        bint operator==(unordered_map&, unordered_map&) nogil
        bint operator!=(unordered_map&, unordered_map&) nogil
        bint operator<(unordered_map&, unordered_map&) nogil
        bint operator>(unordered_map&, unordered_map&) nogil
        bint operator<=(unordered_map&, unordered_map&) nogil
        bint operator>=(unordered_map&, unordered_map&) nogil
        U& at(T&) nogil
        iterator begin() nogil
        #const_iterator begin()
        void clear() nogil
        size_t count(T&) nogil
        bint empty() nogil
        iterator end() nogil
        #const_iterator end()
        pair[iterator, iterator] equal_range(T&) nogil
        #pair[const_iterator, const_iterator] equal_range(key_type&)
        void erase(iterator) nogil
        void erase(iterator, iterator) nogil
        size_t erase(T&) nogil
        iterator find(T&) nogil
        #const_iterator find(key_type&)
        pair[iterator, bint] insert(pair[T, U]) nogil # XXX pair[T,U]&
        iterator insert(iterator, pair[T, U]) nogil # XXX pair[T,U]&
        #void insert(input_iterator, input_iterator)
        #key_compare key_comp()
        iterator lower_bound(T&) nogil
        #const_iterator lower_bound(key_type&)
        size_t max_size() nogil
        reverse_iterator rbegin() nogil
        #const_reverse_iterator rbegin()
        reverse_iterator rend() nogil
        #const_reverse_iterator rend()
        size_t size() nogil
        void swap(unordered_map&) nogil
        iterator upper_bound(T&) nogil
        #const_iterator upper_bound(key_type&)
        #value_compare value_comp()
