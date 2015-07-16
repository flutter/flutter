cdef extern from "<vector>" namespace std:

	cdef cppclass vector[TYPE]:
		#constructors
		__init__()
		__init__(vector&)
		__init__(int)
		__init__(int, TYPE&)
		__init__(iterator, iterator)
		#operators
		TYPE& __getitem__(int)
		TYPE& __setitem__(int, TYPE&)
		vector __new__(vector&)
		bool __eq__(vector&, vector&)
		bool __ne__(vector&, vector&)
		bool __lt__(vector&, vector&)
		bool __gt__(vector&, vector&)
		bool __le__(vector&, vector&)
		bool __ge__(vector&, vector&)
		#others
		void assign(int, TYPE)
		#void assign(iterator, iterator)
		TYPE& at(int)
		TYPE& back()
		iterator begin()
		int capacity()
		void clear()
		bool empty()
		iterator end()
		iterator erase(iterator)
		iterator erase(iterator, iterator)
		TYPE& front()
		iterator insert(iterator, TYPE&)
		void insert(iterator, int, TYPE&)
		void insert(iterator, iterator)
		int max_size()
		void pop_back()
		void push_back(TYPE&)
		iterator rbegin()
		iterator rend()
		void reserve(int)
		void resize(int)
		void resize(int, TYPE&) #void resize(size_type num, const TYPE& = TYPE())
		int size()
		void swap(container&)

cdef extern from "<deque>" namespace std:

	cdef cppclass deque[TYPE]:
		#constructors
		__init__()
		__init__(deque&)
		__init__(int)
		__init__(int, TYPE&)
		__init__(iterator, iterator)
		#operators
		TYPE& operator[]( size_type index );
		const TYPE& operator[]( size_type index ) const;
		deque __new__(deque&);
		bool __eq__(deque&, deque&);
		bool __ne__(deque&, deque&);
		bool __lt__(deque&, deque&);
		bool __gt__(deque&, deque&);
		bool __le__(deque&, deque&);
		bool __ge__(deque&, deque&);
		#others
		void assign(int, TYPE&)
		void assign(iterator, iterator)
		TYPE& at(int)
		TYPE& back()
		iterator begin()
		void clear()
		bool empty()
		iterator end()
		iterator erase(iterator)
		iterator erase(iterator, iterator)
		TYPE& front()
		iterator insert(iterator, TYPE&)
		void insert(iterator, int, TYPE&)
		void insert(iterator, iterator, iterator)
		int max_size()
		void pop_back()
		void pop_front()
		void push_back(TYPE&)
		void push_front(TYPE&)
		iterator rbegin()
		iterator rend()
		void resize(int)
		void resize(int, TYPE&)
		int size()
		void swap(container&)
