
# deprecated cimport for backwards compatibility:
from libc.string cimport const_char


cdef extern from "<string>" namespace "std":

    size_t npos = -1

    cdef cppclass string:
        string() nogil except +
        string(char *) nogil except +
        string(char *, size_t) nogil except +
        string(string&) nogil except +
        # as a string formed by a repetition of character c, n times.
        string(size_t, char) nogil except +

        const char* c_str() nogil
        const char* data() nogil
        size_t size() nogil
        size_t max_size() nogil
        size_t length() nogil
        void resize(size_t) nogil
        void resize(size_t, char c) nogil
        size_t capacity() nogil
        void reserve(size_t) nogil
        void clear() nogil
        bint empty() nogil

        char& at(size_t) nogil
        char& operator[](size_t) nogil
        int compare(string&) nogil

        string& append(string&) nogil
        string& append(string&, size_t, size_t) nogil
        string& append(char *) nogil
        string& append(char *, size_t) nogil
        string& append(size_t, char) nogil

        void push_back(char c) nogil

        string& assign (string&) nogil
        string& assign (string&, size_t, size_t) nogil
        string& assign (char *, size_t) nogil
        string& assign (char *) nogil
        string& assign (size_t n, char c) nogil

        string& insert(size_t, string&) nogil
        string& insert(size_t, string&, size_t, size_t) nogil
        string& insert(size_t, char* s, size_t) nogil


        string& insert(size_t, char* s) nogil
        string& insert(size_t, size_t, char c) nogil

        size_t copy(char *, size_t, size_t) nogil

        size_t find(string&) nogil
        size_t find(string&, size_t) nogil
        size_t find(char*, size_t pos, size_t) nogil
        size_t find(char*, size_t pos) nogil
        size_t find(char, size_t pos) nogil

        size_t rfind(string&, size_t) nogil
        size_t rfind(char* s, size_t, size_t) nogil
        size_t rfind(char*, size_t pos) nogil
        size_t rfind(char c, size_t) nogil
        size_t rfind(char c) nogil

        size_t find_first_of(string&, size_t) nogil
        size_t find_first_of(char* s, size_t, size_t) nogil
        size_t find_first_of(char*, size_t pos) nogil
        size_t find_first_of(char c, size_t) nogil
        size_t find_first_of(char c) nogil

        size_t find_first_not_of(string&, size_t) nogil
        size_t find_first_not_of(char* s, size_t, size_t) nogil
        size_t find_first_not_of(char*, size_t pos) nogil
        size_t find_first_not_of(char c, size_t) nogil
        size_t find_first_not_of(char c) nogil

        size_t find_last_of(string&, size_t) nogil
        size_t find_last_of(char* s, size_t, size_t) nogil
        size_t find_last_of(char*, size_t pos) nogil
        size_t find_last_of(char c, size_t) nogil
        size_t find_last_of(char c) nogil

        size_t find_last_not_of(string&, size_t) nogil
        size_t find_last_not_of(char* s, size_t, size_t) nogil
        size_t find_last_not_of(char*, size_t pos) nogil

        string substr(size_t, size_t) nogil
        string substr() nogil
        string substr(size_t) nogil

        size_t find_last_not_of(char c, size_t) nogil
        size_t find_last_not_of(char c) nogil

        #string& operator= (string&)
        #string& operator= (char*)
        #string& operator= (char)

        string operator+ (string& rhs) nogil
        string operator+ (char* rhs) nogil

        bint operator==(string&) nogil
        bint operator==(char*) nogil

        bint operator!= (string& rhs ) nogil
        bint operator!= (char* ) nogil

        bint operator< (string&) nogil
        bint operator< (char*) nogil

        bint operator> (string&) nogil
        bint operator> (char*) nogil

        bint operator<= (string&) nogil
        bint operator<= (char*) nogil

        bint operator>= (string&) nogil
        bint operator>= (char*) nogil
