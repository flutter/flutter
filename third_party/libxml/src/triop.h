/*************************************************************************
 *
 * $Id$
 *
 * Copyright (C) 2000 Bjorn Reese and Daniel Stenberg.
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
 ************************************************************************
 *
 * Private functions, types, etc. used for callback functions.
 *
 * The ref pointer is an opaque type and should remain as such.
 * Private data must only be accessible through the getter and
 * setter functions.
 *
 ************************************************************************/

#ifndef TRIO_TRIOP_H
#define TRIO_TRIOP_H

#include "triodef.h"

#include <stdlib.h>
#if defined(TRIO_COMPILER_ANCIENT)
# include <varargs.h>
#else
# include <stdarg.h>
#endif

#ifdef __cplusplus
extern "C" {
#endif

#ifndef TRIO_C99
# define TRIO_C99 1
#endif
#ifndef TRIO_BSD
# define TRIO_BSD 1
#endif
#ifndef TRIO_GNU
# define TRIO_GNU 1
#endif
#ifndef TRIO_MISC
# define TRIO_MISC 1
#endif
#ifndef TRIO_UNIX98
# define TRIO_UNIX98 1
#endif
#ifndef TRIO_MICROSOFT
# define TRIO_MICROSOFT 1
#endif
#ifndef TRIO_EXTENSION
# define TRIO_EXTENSION 1
#endif
#ifndef TRIO_WIDECHAR /* Does not work yet. Do not enable */
# define TRIO_WIDECHAR 0
#endif
#ifndef TRIO_ERRORS
# define TRIO_ERRORS 1
#endif

#ifndef TRIO_MALLOC
# define TRIO_MALLOC(n) malloc(n)
#endif
#ifndef TRIO_REALLOC
# define TRIO_REALLOC(x,n) realloc((x),(n))
#endif
#ifndef TRIO_FREE
# define TRIO_FREE(x) free(x)
#endif


/*************************************************************************
 * User-defined specifiers
 */

typedef int (*trio_callback_t) TRIO_PROTO((trio_pointer_t));

trio_pointer_t trio_register TRIO_PROTO((trio_callback_t callback, const char *name));
void trio_unregister TRIO_PROTO((trio_pointer_t handle));

TRIO_CONST char *trio_get_format TRIO_PROTO((trio_pointer_t ref));
trio_pointer_t trio_get_argument TRIO_PROTO((trio_pointer_t ref));

/* Modifiers */
int  trio_get_width TRIO_PROTO((trio_pointer_t ref));
void trio_set_width TRIO_PROTO((trio_pointer_t ref, int width));
int  trio_get_precision TRIO_PROTO((trio_pointer_t ref));
void trio_set_precision TRIO_PROTO((trio_pointer_t ref, int precision));
int  trio_get_base TRIO_PROTO((trio_pointer_t ref));
void trio_set_base TRIO_PROTO((trio_pointer_t ref, int base));
int  trio_get_padding TRIO_PROTO((trio_pointer_t ref));
void trio_set_padding TRIO_PROTO((trio_pointer_t ref, int is_padding));
int  trio_get_short TRIO_PROTO((trio_pointer_t ref)); /* h */
void trio_set_shortshort TRIO_PROTO((trio_pointer_t ref, int is_shortshort));
int  trio_get_shortshort TRIO_PROTO((trio_pointer_t ref)); /* hh */
void trio_set_short TRIO_PROTO((trio_pointer_t ref, int is_short));
int  trio_get_long TRIO_PROTO((trio_pointer_t ref)); /* l */
void trio_set_long TRIO_PROTO((trio_pointer_t ref, int is_long));
int  trio_get_longlong TRIO_PROTO((trio_pointer_t ref)); /* ll */
void trio_set_longlong TRIO_PROTO((trio_pointer_t ref, int is_longlong));
int  trio_get_longdouble TRIO_PROTO((trio_pointer_t ref)); /* L */
void trio_set_longdouble TRIO_PROTO((trio_pointer_t ref, int is_longdouble));
int  trio_get_alternative TRIO_PROTO((trio_pointer_t ref)); /* # */
void trio_set_alternative TRIO_PROTO((trio_pointer_t ref, int is_alternative));
int  trio_get_alignment TRIO_PROTO((trio_pointer_t ref)); /* - */
void trio_set_alignment TRIO_PROTO((trio_pointer_t ref, int is_leftaligned));
int  trio_get_spacing TRIO_PROTO((trio_pointer_t ref)); /*  TRIO_PROTO((space) */
void trio_set_spacing TRIO_PROTO((trio_pointer_t ref, int is_space));
int  trio_get_sign TRIO_PROTO((trio_pointer_t ref)); /* + */
void trio_set_sign TRIO_PROTO((trio_pointer_t ref, int is_showsign));
int  trio_get_quote TRIO_PROTO((trio_pointer_t ref)); /* ' */
void trio_set_quote TRIO_PROTO((trio_pointer_t ref, int is_quote));
int  trio_get_upper TRIO_PROTO((trio_pointer_t ref));
void trio_set_upper TRIO_PROTO((trio_pointer_t ref, int is_upper));
#if TRIO_C99
int  trio_get_largest TRIO_PROTO((trio_pointer_t ref)); /* j */
void trio_set_largest TRIO_PROTO((trio_pointer_t ref, int is_largest));
int  trio_get_ptrdiff TRIO_PROTO((trio_pointer_t ref)); /* t */
void trio_set_ptrdiff TRIO_PROTO((trio_pointer_t ref, int is_ptrdiff));
int  trio_get_size TRIO_PROTO((trio_pointer_t ref)); /* z / Z */
void trio_set_size TRIO_PROTO((trio_pointer_t ref, int is_size));
#endif

/* Printing */
int trio_print_ref TRIO_PROTO((trio_pointer_t ref, const char *format, ...));
int trio_vprint_ref TRIO_PROTO((trio_pointer_t ref, const char *format, va_list args));
int trio_printv_ref TRIO_PROTO((trio_pointer_t ref, const char *format, trio_pointer_t *args));

void trio_print_int TRIO_PROTO((trio_pointer_t ref, int number));
void trio_print_uint TRIO_PROTO((trio_pointer_t ref, unsigned int number));
/*  void trio_print_long TRIO_PROTO((trio_pointer_t ref, long number)); */
/*  void trio_print_ulong TRIO_PROTO((trio_pointer_t ref, unsigned long number)); */
void trio_print_double TRIO_PROTO((trio_pointer_t ref, double number));
void trio_print_string TRIO_PROTO((trio_pointer_t ref, char *string));
void trio_print_pointer TRIO_PROTO((trio_pointer_t ref, trio_pointer_t pointer));

#ifdef __cplusplus
} /* extern "C" */
#endif

#endif /* TRIO_TRIOP_H */
