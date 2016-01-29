/*************************************************************************
 *
 * $Id$
 *
 * Copyright (C) 2001 Bjorn Reese and Daniel Stenberg.
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY EXPRESS OR IMPLIED
 * WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
 * MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE AUTHORS AND
 * CONTRIBUTORS ACCEPT NO RESPONSIBILITY IN ANY CONCEIVABLE MANNER.
 *
 ************************************************************************/

#ifndef TRIO_TRIOSTR_H
#define TRIO_TRIOSTR_H

#include <assert.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include "triodef.h"
#include "triop.h"

enum {
  TRIO_HASH_NONE = 0,
  TRIO_HASH_PLAIN,
  TRIO_HASH_TWOSIGNED
};

#if !defined(TRIO_STRING_PUBLIC)
# if !defined(TRIO_PUBLIC)
#  define TRIO_PUBLIC
# endif
# define TRIO_STRING_PUBLIC TRIO_PUBLIC
#endif

/*************************************************************************
 * String functions
 */

TRIO_STRING_PUBLIC int trio_copy_max TRIO_PROTO((char *target, size_t max, const char *source));
TRIO_STRING_PUBLIC char *trio_create TRIO_PROTO((size_t size));
TRIO_STRING_PUBLIC void trio_destroy TRIO_PROTO((char *string));
TRIO_STRING_PUBLIC char *trio_duplicate TRIO_PROTO((const char *source));
TRIO_STRING_PUBLIC int trio_equal TRIO_PROTO((const char *first, const char *second));
TRIO_STRING_PUBLIC int trio_equal_case TRIO_PROTO((const char *first, const char *second));
TRIO_STRING_PUBLIC int trio_equal_locale TRIO_PROTO((const char *first, const char *second));
TRIO_STRING_PUBLIC int trio_equal_max TRIO_PROTO((const char *first, size_t max, const char *second));
TRIO_STRING_PUBLIC TRIO_CONST char *trio_error TRIO_PROTO((int));
TRIO_STRING_PUBLIC size_t trio_length TRIO_PROTO((const char *string));
TRIO_STRING_PUBLIC double trio_to_double TRIO_PROTO((const char *source, char **endp));
TRIO_STRING_PUBLIC long trio_to_long TRIO_PROTO((const char *source, char **endp, int base));
TRIO_STRING_PUBLIC trio_long_double_t trio_to_long_double TRIO_PROTO((const char *source, char **endp));
TRIO_STRING_PUBLIC int trio_to_upper TRIO_PROTO((int source));

#if !defined(TRIO_MINIMAL)

TRIO_STRING_PUBLIC int trio_append TRIO_PROTO((char *target, const char *source));
TRIO_STRING_PUBLIC int trio_append_max TRIO_PROTO((char *target, size_t max, const char *source));
TRIO_STRING_PUBLIC int trio_contains TRIO_PROTO((const char *string, const char *substring));
TRIO_STRING_PUBLIC int trio_copy TRIO_PROTO((char *target, const char *source));
TRIO_STRING_PUBLIC char *trio_duplicate_max TRIO_PROTO((const char *source, size_t max));
TRIO_STRING_PUBLIC int trio_equal_case_max TRIO_PROTO((const char *first, size_t max, const char *second));
#if !defined(_WIN32_WCE)
TRIO_STRING_PUBLIC size_t trio_format_date_max TRIO_PROTO((char *target, size_t max, const char *format, const struct tm *datetime));
#endif
TRIO_STRING_PUBLIC unsigned long trio_hash TRIO_PROTO((const char *string, int type));
TRIO_STRING_PUBLIC char *trio_index TRIO_PROTO((const char *string, int character));
TRIO_STRING_PUBLIC char *trio_index_last TRIO_PROTO((const char *string, int character));
TRIO_STRING_PUBLIC int trio_lower TRIO_PROTO((char *target));
TRIO_STRING_PUBLIC int trio_match TRIO_PROTO((const char *string, const char *pattern));
TRIO_STRING_PUBLIC int trio_match_case TRIO_PROTO((const char *string, const char *pattern));
TRIO_STRING_PUBLIC size_t trio_span_function TRIO_PROTO((char *target, const char *source, int (*Function) TRIO_PROTO((int))));
TRIO_STRING_PUBLIC char *trio_substring TRIO_PROTO((const char *string, const char *substring));
TRIO_STRING_PUBLIC char *trio_substring_max TRIO_PROTO((const char *string, size_t max, const char *substring));
TRIO_STRING_PUBLIC float trio_to_float TRIO_PROTO((const char *source, char **endp));
TRIO_STRING_PUBLIC int trio_to_lower TRIO_PROTO((int source));
TRIO_STRING_PUBLIC unsigned long trio_to_unsigned_long TRIO_PROTO((const char *source, char **endp, int base));
TRIO_STRING_PUBLIC char *trio_tokenize TRIO_PROTO((char *string, const char *delimiters));
TRIO_STRING_PUBLIC int trio_upper TRIO_PROTO((char *target));

#endif /* !defined(TRIO_MINIMAL) */

/*************************************************************************
 * Dynamic string functions
 */

/*
 * Opaque type for dynamic strings
 */

typedef struct _trio_string_t trio_string_t;

TRIO_STRING_PUBLIC void trio_string_destroy TRIO_PROTO((trio_string_t *self));
TRIO_STRING_PUBLIC char *trio_string_extract TRIO_PROTO((trio_string_t *self));
TRIO_STRING_PUBLIC int trio_string_size TRIO_PROTO((trio_string_t *self));
TRIO_STRING_PUBLIC void trio_string_terminate TRIO_PROTO((trio_string_t *self));
TRIO_STRING_PUBLIC int trio_xstring_append_char TRIO_PROTO((trio_string_t *self, char character));
TRIO_STRING_PUBLIC trio_string_t *trio_xstring_duplicate TRIO_PROTO((const char *other));

#if !defined(TRIO_MINIMAL)

TRIO_STRING_PUBLIC trio_string_t *trio_string_create TRIO_PROTO((int initial_size));
TRIO_STRING_PUBLIC char *trio_string_get TRIO_PROTO((trio_string_t *self, int offset));
TRIO_STRING_PUBLIC void trio_xstring_set TRIO_PROTO((trio_string_t *self, char *buffer));

TRIO_STRING_PUBLIC int trio_string_append TRIO_PROTO((trio_string_t *self, trio_string_t *other));
TRIO_STRING_PUBLIC int trio_string_contains TRIO_PROTO((trio_string_t *self, trio_string_t *other));
TRIO_STRING_PUBLIC int trio_string_copy TRIO_PROTO((trio_string_t *self, trio_string_t *other));
TRIO_STRING_PUBLIC trio_string_t *trio_string_duplicate TRIO_PROTO((trio_string_t *other));
TRIO_STRING_PUBLIC int trio_string_equal TRIO_PROTO((trio_string_t *self, trio_string_t *other));
TRIO_STRING_PUBLIC int trio_string_equal_max TRIO_PROTO((trio_string_t *self, size_t max, trio_string_t *second));
TRIO_STRING_PUBLIC int trio_string_equal_case TRIO_PROTO((trio_string_t *self, trio_string_t *other));
TRIO_STRING_PUBLIC int trio_string_equal_case_max TRIO_PROTO((trio_string_t *self, size_t max, trio_string_t *other));
#if !defined(_WIN32_WCE)
TRIO_STRING_PUBLIC size_t trio_string_format_date_max TRIO_PROTO((trio_string_t *self, size_t max, const char *format, const struct tm *datetime));
#endif
TRIO_STRING_PUBLIC char *trio_string_index TRIO_PROTO((trio_string_t *self, int character));
TRIO_STRING_PUBLIC char *trio_string_index_last TRIO_PROTO((trio_string_t *self, int character));
TRIO_STRING_PUBLIC int trio_string_length TRIO_PROTO((trio_string_t *self));
TRIO_STRING_PUBLIC int trio_string_lower TRIO_PROTO((trio_string_t *self));
TRIO_STRING_PUBLIC int trio_string_match TRIO_PROTO((trio_string_t *self, trio_string_t *other));
TRIO_STRING_PUBLIC int trio_string_match_case TRIO_PROTO((trio_string_t *self, trio_string_t *other));
TRIO_STRING_PUBLIC char *trio_string_substring TRIO_PROTO((trio_string_t *self, trio_string_t *other));
TRIO_STRING_PUBLIC int trio_string_upper TRIO_PROTO((trio_string_t *self));

TRIO_STRING_PUBLIC int trio_xstring_append TRIO_PROTO((trio_string_t *self, const char *other));
TRIO_STRING_PUBLIC int trio_xstring_contains TRIO_PROTO((trio_string_t *self, const char *other));
TRIO_STRING_PUBLIC int trio_xstring_copy TRIO_PROTO((trio_string_t *self, const char *other));
TRIO_STRING_PUBLIC int trio_xstring_equal TRIO_PROTO((trio_string_t *self, const char *other));
TRIO_STRING_PUBLIC int trio_xstring_equal_max TRIO_PROTO((trio_string_t *self, size_t max, const char *other));
TRIO_STRING_PUBLIC int trio_xstring_equal_case TRIO_PROTO((trio_string_t *self, const char *other));
TRIO_STRING_PUBLIC int trio_xstring_equal_case_max TRIO_PROTO((trio_string_t *self, size_t max, const char *other));
TRIO_STRING_PUBLIC int trio_xstring_match TRIO_PROTO((trio_string_t *self, const char *other));
TRIO_STRING_PUBLIC int trio_xstring_match_case TRIO_PROTO((trio_string_t *self, const char *other));
TRIO_STRING_PUBLIC char *trio_xstring_substring TRIO_PROTO((trio_string_t *self, const char *other));

#endif /* !defined(TRIO_MINIMAL) */

#endif /* TRIO_TRIOSTR_H */
