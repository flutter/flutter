from pair cimport pair

cdef extern from "<deque>" namespace "std":
    cdef cppclass deque[T]:
        cppclass iterator:
            T& operator*() nogil
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
        deque() nogil except +
        deque(deque&) nogil except +
        deque(size_t) nogil except +
        deque(size_t, T&) nogil except +
        #deque[input_iterator](input_iterator, input_iterator)
        T& operator[](size_t) nogil
        #deque& operator=(deque&)
        bint operator==(deque&, deque&) nogil
        bint operator!=(deque&, deque&) nogil
        bint operator<(deque&, deque&) nogil
        bint operator>(deque&, deque&) nogil
        bint operator<=(deque&, deque&) nogil
        bint operator>=(deque&, deque&) nogil
        void assign(size_t, T&) nogil
        void assign(input_iterator, input_iterator) nogil
        T& at(size_t) nogil
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
        void insert(iterator, input_iterator, input_iterator) nogil
        size_t max_size() nogil
        void pop_back() nogil
        void pop_front() nogil
        void push_back(T&) nogil
        void push_front(T&) nogil
        reverse_iterator rbegin() nogil
        #const_reverse_iterator rbegin()
        reverse_iterator rend() nogil
        #const_reverse_iterator rend()
        void resize(size_t) nogil
        void resize(size_t, T&) nogil
        size_t size() nogil
        void swap(deque&) nogil
