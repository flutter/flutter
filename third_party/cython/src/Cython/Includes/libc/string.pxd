# 7.21 String handling <string.h>

cdef extern from *:
    # deprecated backwards compatibility declarations
    ctypedef const char const_char "const char"
    ctypedef const signed char const_schar "const signed char"
    ctypedef const unsigned char const_uchar "const unsigned char"
    ctypedef const void const_void "const void"

cdef extern from "string.h" nogil:

    void *memcpy  (void *pto, const void *pfrom, size_t size)
    void *memmove (void *pto, const void *pfrom, size_t size)
    void *memset  (void *block, int c, size_t size)
    int  memcmp   (const void *a1, const void *a2, size_t size)
    void *memchr  (const void *block, int c, size_t size)

    void *memchr  (const void *block, int c, size_t size)
    void *memrchr (const void *block, int c, size_t size)

    size_t strlen   (const char *s)
    char   *strcpy  (char *pto, const char *pfrom)
    char   *strncpy (char *pto, const char *pfrom, size_t size)
    char   *strdup  (const char *s)
    char   *strndup (const char *s, size_t size)
    char   *strcat  (char *pto, const char *pfrom)
    char   *strncat (char *pto, const char *pfrom, size_t size)

    int strcmp (const char *s1, const char *s2)
    int strcasecmp (const char *s1, const char *s2)
    int strncmp (const char *s1, const char *s2, size_t size)
    int strncasecmp (const char *s1, const char *s2, size_t n)

    int    strcoll (const char *s1, const char *s2)
    size_t strxfrm (char *pto, const char *pfrom, size_t size)

    char *strerror (int errnum)

    char *strchr  (const char *string, int c)
    char *strrchr (const char *string, int c)

    char *strstr     (const char *haystack, const char *needle)
    char *strcasestr (const char *haystack, const char *needle)

    size_t strcspn (const char *string, const char *stopset)
    size_t strspn  (const char *string, const char *set)
    char * strpbrk (const char *string, const char *stopset)

    char *strtok (char *newstring, const char *delimiters)
    char *strsep (char **string_ptr, const char *delimiter)
