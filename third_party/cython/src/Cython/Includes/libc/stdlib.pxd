# 7.20 General utilities <stdlib.h>

# deprecated cimports for backwards compatibility:
from libc.string cimport const_char, const_void


cdef extern from "stdlib.h" nogil:

    # 7.20.1 Numeric conversion functions
    int atoi (const char *string)
    long atol (const char *string)
    long long atoll (const char *string)
    double atof (const char *string)
    long strtol (const char *string, char **tailptr, int base)
    unsigned long int strtoul (const char *string, char **tailptr, int base)
    long long int strtoll (const char *string, char **tailptr, int base)
    unsigned long long int strtoull (const char *string, char **tailptr, int base)
    float strtof (const char *string, char **tailptr)
    double strtod (const char *string, char **tailptr)
    long double strtold (const char *string, char **tailptr)

    # 7.20.2 Pseudo-random sequence generation functions
    enum: RAND_MAX
    int rand ()
    void srand (unsigned int seed)

    # 7.20.3 Memory management functions
    void *calloc (size_t count, size_t eltsize)
    void free (void *ptr)
    void *malloc (size_t size)
    void *realloc (void *ptr, size_t newsize)

    # 7.20.4 Communication with the environment
    enum: EXIT_FAILURE
    enum: EXIT_SUCCESS
    void exit (int status)
    void _exit (int status)
    int atexit (void (*function) ())
    void abort ()
    char *getenv (const char *name)
    int system (const char *command)

    #7.20.5 Searching and sorting utilities
    void *bsearch (const void *key, const void *array,
                   size_t count, size_t size,
                   int (*compare)(const void *, const void *))
    void qsort (void *array, size_t count, size_t size,
                int (*compare)(const void *, const void *))

    # 7.20.6 Integer arithmetic functions
    int abs (int number)
    long int labs (long int number)
    long long int llabs (long long int number)
    ctypedef struct div_t:
        int quot
        int rem
    div_t div (int numerator, int denominator)
    ctypedef struct ldiv_t:
        long int quot
        long int rem
    ldiv_t ldiv (long int numerator, long int denominator)
    ctypedef struct lldiv_t:
        long long int quot
        long long int rem
    lldiv_t lldiv (long long int numerator, long long int denominator)


    # 7.20.7 Multibyte/wide character conversion functions
    # XXX TODO

    # 7.20.8 Multibyte/wide string conversion functions
    # XXX TODO
