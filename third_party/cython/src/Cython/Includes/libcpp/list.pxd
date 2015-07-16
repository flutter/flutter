cdef extern from "<list>" namespace "std":
    cdef cppclass list[T]:
        cppclass iterator:
            iterator()
            iterator(iterator &)
            T& operator*() nogil
            iterator operator++() nogil
            iterator operator--() nogil
            bint operator==(iterator) nogil
            bint operator!=(iterator) nogil
        cppclass reverse_iterator:
            reverse_iterator()
            reverse_iterator(iterator &)
            T& operator*() nogil
            reverse_iterator operator++() nogil
            reverse_iterator operator--() nogil
            bint operator==(reverse_iterator) nogil
            bint operator!=(reverse_iterator) nogil
        #cppclass const_iterator(iterator):
        #    pass
        #cppclass const_reverse_iterator(reverse_iterator):
        #    pass
        list() nogil except +
        list(list&) nogil except +
        list(size_t, T&) nogil except +
        #list operator=(list&)
        bint operator==(list&, list&) nogil
        bint operator!=(list&, list&) nogil
        bint operator<(list&, list&) nogil
        bint operator>(list&, list&) nogil
        bint operator<=(list&, list&) nogil
        bint operator>=(list&, list&) nogil
        void assign(size_t, T&) nogil
        T& back() nogil
        iterator begin() nogil
        #const_iterator begin()
        void clear() nogil
        bint empty() nogil
        iterator end() nogil
        #const_iterator end()
        iterator erase(iterator) nogil
        iterator erase(iterator, iterator) nogil
        T& front() nogil
        iterator insert(iterator, T&) nogil
        void insert(iterator, size_t, T&) nogil
        size_t max_size() nogil
        void merge(list&) nogil
        #void merge(list&, BinPred)
        void pop_back() nogil
        void pop_front() nogil
        void push_back(T&) nogil
        void push_front(T&) nogil
        reverse_iterator rbegin() nogil
        #const_reverse_iterator rbegin()
        void remove(T&) nogil
        #void remove_if(UnPred)
        reverse_iterator rend() nogil
        #const_reverse_iterator rend()
        void resize(size_t, T&) nogil
        void reverse() nogil
        size_t size() nogil
        void sort() nogil
        #void sort(BinPred)
        void splice(iterator, list&) nogil
        void splice(iterator, list&, iterator) nogil
        void splice(iterator, list&, iterator, iterator) nogil
        void swap(list&) nogil
        void unique() nogil
        #void unique(BinPred)
