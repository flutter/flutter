/*************************************************************************
 *
 * $Id$
 *
 * Copyright (C) 2001 Bjorn Reese <breese@users.sourceforge.net>
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

#ifndef TRIO_NAN_H
#define TRIO_NAN_H

#include "triodef.h"

#ifdef __cplusplus
extern "C" {
#endif

enum {
  TRIO_FP_INFINITE,
  TRIO_FP_NAN,
  TRIO_FP_NORMAL,
  TRIO_FP_SUBNORMAL,
  TRIO_FP_ZERO
};

/*
 * Return NaN (Not-a-Number).
 */
TRIO_PUBLIC double trio_nan TRIO_PROTO((void));

/*
 * Return positive infinity.
 */
TRIO_PUBLIC double trio_pinf TRIO_PROTO((void));

/*
 * Return negative infinity.
 */
TRIO_PUBLIC double trio_ninf TRIO_PROTO((void));

/*
 * Return negative zero.
 */
TRIO_PUBLIC double trio_nzero TRIO_PROTO((TRIO_NOARGS));

/*
 * If number is a NaN return non-zero, otherwise return zero.
 */
TRIO_PUBLIC int trio_isnan TRIO_PROTO((double number));

/*
 * If number is positive infinity return 1, if number is negative
 * infinity return -1, otherwise return 0.
 */
TRIO_PUBLIC int trio_isinf TRIO_PROTO((double number));

/*
 * If number is finite return non-zero, otherwise return zero.
 */
#if 0
	/* Temporary fix - these 2 routines not used in libxml */
TRIO_PUBLIC int trio_isfinite TRIO_PROTO((double number));

TRIO_PUBLIC int trio_fpclassify TRIO_PROTO((double number));
#endif

TRIO_PUBLIC int trio_signbit TRIO_PROTO((double number));

TRIO_PUBLIC int trio_fpclassify_and_signbit TRIO_PROTO((double number, int *is_negative));

#ifdef __cplusplus
}
#endif

#endif /* TRIO_NAN_H */
