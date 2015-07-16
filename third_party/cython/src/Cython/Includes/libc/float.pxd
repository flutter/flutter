# 5.2.4.2.2 Characteristics of floating types <float.h>

cdef extern from "float.h":

    enum: FLT_RADIX

    enum:  FLT_MANT_DIG
    enum:  DBL_MANT_DIG
    enum: LDBL_MANT_DIG

    enum: DECIMAL_DIG

    enum:  FLT_DIG
    enum:  DBL_DIG
    enum: LDBL_DIG

    enum:  FLT_MIN_EXP
    enum:  DBL_MIN_EXP
    enum: LDBL_MIN_EXP

    enum:  FLT_MIN_10_EXP
    enum:  DBL_MIN_10_EXP
    enum: LDBL_MIN_10_EXP

    enum:  FLT_MAX_EXP
    enum:  DBL_MAX_EXP
    enum: LDBL_MAX_EXP

    enum:  FLT_MAX_10_EXP
    enum:  DBL_MAX_10_EXP
    enum: LDBL_MAX_10_EXP

    enum:  FLT_MAX
    enum:  DBL_MAX
    enum: LDBL_MAX

    enum:  FLT_EPSILON
    enum:  DBL_EPSILON
    enum: LDBL_EPSILON

    enum:  FLT_MIN
    enum:  DBL_MIN
    enum: LDBL_MIN
