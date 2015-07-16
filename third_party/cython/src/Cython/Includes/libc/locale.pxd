# 7.11 Localization <locale.h>

# deprecated cimport for backwards compatibility:
from libc.string cimport const_char


cdef extern from "locale.h" nogil:

    struct lconv:
        char *decimal_point
        char *thousands_sep
        char *grouping
        char *mon_decimal_point
        char *mon_thousands_sep
        char *mon_grouping
        char *positive_sign
        char *negative_sign
        char *currency_symbol
        char frac_digits
        char p_cs_precedes
        char n_cs_precedes
        char p_sep_by_space
        char n_sep_by_space
        char p_sign_posn
        char n_sign_posn
        char *int_curr_symbol
        char int_frac_digits
        char int_p_cs_precedes
        char int_n_cs_precedes
        char int_p_sep_by_space
        char int_n_sep_by_space
        char int_p_sign_posn
        char int_n_sign_posn

    enum: LC_ALL
    enum: LC_COLLATE
    enum: LC_CTYPE
    enum: LC_MONETARY
    enum: LC_NUMERIC
    enum: LC_TIME

    # 7.11.1 Locale control
    char *setlocale (int category, const char *locale)

    # 7.11.2 Numeric formatting convention inquiry
    lconv *localeconv ()
