# 5.2.4.2.1 Sizes of integer types <limits.h>

cdef extern from "limits.h":

    enum: CHAR_BIT
    enum: MB_LEN_MAX

    enum:  CHAR_MIN
    enum:  CHAR_MAX

    enum: SCHAR_MIN
    enum: SCHAR_MAX
    enum: UCHAR_MAX

    enum:   SHRT_MIN
    enum:   SHRT_MAX
    enum:  USHRT_MAX

    enum:    INT_MIN
    enum:    INT_MAX
    enum:   UINT_MAX

    enum:   LONG_MIN
    enum:   LONG_MAX
    enum:  ULONG_MAX

    enum:  LLONG_MIN
    enum:  LLONG_MAX
    enum: ULLONG_MAX
