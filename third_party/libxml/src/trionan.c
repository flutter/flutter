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
 ************************************************************************
 *
 * Functions to handle special quantities in floating-point numbers
 * (that is, NaNs and infinity). They provide the capability to detect
 * and fabricate special quantities.
 *
 * Although written to be as portable as possible, it can never be
 * guaranteed to work on all platforms, as not all hardware supports
 * special quantities.
 *
 * The approach used here (approximately) is to:
 *
 *   1. Use C99 functionality when available.
 *   2. Use IEEE 754 bit-patterns if possible.
 *   3. Use platform-specific techniques.
 *
 ************************************************************************/

/*
 * TODO:
 *  o Put all the magic into trio_fpclassify_and_signbit(), and use this from
 *    trio_isnan() etc.
 */

/*************************************************************************
 * Include files
 */
#include "triodef.h"
#include "trionan.h"

#include <math.h>
#include <string.h>
#include <limits.h>
#include <float.h>
#if defined(TRIO_PLATFORM_UNIX)
# include <signal.h>
#endif
#if defined(TRIO_COMPILER_DECC)
#  if defined(__linux__)
#   include <cpml.h>
#  else
#   include <fp_class.h>
#  endif
#endif
#include <assert.h>

#if defined(TRIO_DOCUMENTATION)
# include "doc/doc_nan.h"
#endif
/** @addtogroup SpecialQuantities
    @{
*/

/*************************************************************************
 * Definitions
 */

#define TRIO_TRUE (1 == 1)
#define TRIO_FALSE (0 == 1)

/*
 * We must enable IEEE floating-point on Alpha
 */
#if defined(__alpha) && !defined(_IEEE_FP)
# if defined(TRIO_COMPILER_DECC)
#  if defined(TRIO_PLATFORM_VMS)
#   error "Must be compiled with option /IEEE_MODE=UNDERFLOW_TO_ZERO/FLOAT=IEEE"
#  else
#   if !defined(_CFE)
#    error "Must be compiled with option -ieee"
#   endif
#  endif
# elif defined(TRIO_COMPILER_GCC) && (defined(__osf__) || defined(__linux__))
#  error "Must be compiled with option -mieee"
# endif
#endif /* __alpha && ! _IEEE_FP */

/*
 * In ANSI/IEEE 754-1985 64-bits double format numbers have the
 * following properties (amoungst others)
 *
 *   o FLT_RADIX == 2: binary encoding
 *   o DBL_MAX_EXP == 1024: 11 bits exponent, where one bit is used
 *     to indicate special numbers (e.g. NaN and Infinity), so the
 *     maximum exponent is 10 bits wide (2^10 == 1024).
 *   o DBL_MANT_DIG == 53: The mantissa is 52 bits wide, but because
 *     numbers are normalized the initial binary 1 is represented
 *     implicitly (the so-called "hidden bit"), which leaves us with
 *     the ability to represent 53 bits wide mantissa.
 */
#if (FLT_RADIX == 2) && (DBL_MAX_EXP == 1024) && (DBL_MANT_DIG == 53)
# define USE_IEEE_754
#endif


/*************************************************************************
 * Constants
 */

static TRIO_CONST char rcsid[] = "@(#)$Id$";

#if defined(USE_IEEE_754)

/*
 * Endian-agnostic indexing macro.
 *
 * The value of internalEndianMagic, when converted into a 64-bit
 * integer, becomes 0x0706050403020100 (we could have used a 64-bit
 * integer value instead of a double, but not all platforms supports
 * that type). The value is automatically encoded with the correct
 * endianess by the compiler, which means that we can support any
 * kind of endianess. The individual bytes are then used as an index
 * for the IEEE 754 bit-patterns and masks.
 */
#define TRIO_DOUBLE_INDEX(x) (((unsigned char *)&internalEndianMagic)[7-(x)])

#if (defined(__BORLANDC__) && __BORLANDC__ >= 0x0590)
static TRIO_CONST double internalEndianMagic = 7.949928895127362e-275;
#else
static TRIO_CONST double internalEndianMagic = 7.949928895127363e-275;
#endif

/* Mask for the exponent */
static TRIO_CONST unsigned char ieee_754_exponent_mask[] = {
  0x7F, 0xF0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
};

/* Mask for the mantissa */
static TRIO_CONST unsigned char ieee_754_mantissa_mask[] = {
  0x00, 0x0F, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF
};

/* Mask for the sign bit */
static TRIO_CONST unsigned char ieee_754_sign_mask[] = {
  0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
};

/* Bit-pattern for negative zero */
static TRIO_CONST unsigned char ieee_754_negzero_array[] = {
  0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
};

/* Bit-pattern for infinity */
static TRIO_CONST unsigned char ieee_754_infinity_array[] = {
  0x7F, 0xF0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
};

/* Bit-pattern for quiet NaN */
static TRIO_CONST unsigned char ieee_754_qnan_array[] = {
  0x7F, 0xF8, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
};


/*************************************************************************
 * Functions
 */

/*
 * trio_make_double
 */
TRIO_PRIVATE double
trio_make_double
TRIO_ARGS1((values),
	   TRIO_CONST unsigned char *values)
{
  TRIO_VOLATILE double result;
  int i;

  for (i = 0; i < (int)sizeof(double); i++) {
    ((TRIO_VOLATILE unsigned char *)&result)[TRIO_DOUBLE_INDEX(i)] = values[i];
  }
  return result;
}

/*
 * trio_is_special_quantity
 */
TRIO_PRIVATE int
trio_is_special_quantity
TRIO_ARGS2((number, has_mantissa),
	   double number,
	   int *has_mantissa)
{
  unsigned int i;
  unsigned char current;
  int is_special_quantity = TRIO_TRUE;

  *has_mantissa = 0;

  for (i = 0; i < (unsigned int)sizeof(double); i++) {
    current = ((unsigned char *)&number)[TRIO_DOUBLE_INDEX(i)];
    is_special_quantity
      &= ((current & ieee_754_exponent_mask[i]) == ieee_754_exponent_mask[i]);
    *has_mantissa |= (current & ieee_754_mantissa_mask[i]);
  }
  return is_special_quantity;
}

/*
 * trio_is_negative
 */
TRIO_PRIVATE int
trio_is_negative
TRIO_ARGS1((number),
	   double number)
{
  unsigned int i;
  int is_negative = TRIO_FALSE;

  for (i = 0; i < (unsigned int)sizeof(double); i++) {
    is_negative |= (((unsigned char *)&number)[TRIO_DOUBLE_INDEX(i)]
		    & ieee_754_sign_mask[i]);
  }
  return is_negative;
}

#endif /* USE_IEEE_754 */


/**
   Generate negative zero.

   @return Floating-point representation of negative zero.
*/
TRIO_PUBLIC double
trio_nzero(TRIO_NOARGS)
{
#if defined(USE_IEEE_754)
  return trio_make_double(ieee_754_negzero_array);
#else
  TRIO_VOLATILE double zero = 0.0;

  return -zero;
#endif
}

/**
   Generate positive infinity.

   @return Floating-point representation of positive infinity.
*/
TRIO_PUBLIC double
trio_pinf(TRIO_NOARGS)
{
  /* Cache the result */
  static double result = 0.0;

  if (result == 0.0) {
    
#if defined(INFINITY) && defined(__STDC_IEC_559__)
    result = (double)INFINITY;

#elif defined(USE_IEEE_754)
    result = trio_make_double(ieee_754_infinity_array);

#else
    /*
     * If HUGE_VAL is different from DBL_MAX, then HUGE_VAL is used
     * as infinity. Otherwise we have to resort to an overflow
     * operation to generate infinity.
     */
# if defined(TRIO_PLATFORM_UNIX)
    void (*signal_handler)(int) = signal(SIGFPE, SIG_IGN);
# endif

    result = HUGE_VAL;
    if (HUGE_VAL == DBL_MAX) {
      /* Force overflow */
      result += HUGE_VAL;
    }
    
# if defined(TRIO_PLATFORM_UNIX)
    signal(SIGFPE, signal_handler);
# endif

#endif
  }
  return result;
}

/**
   Generate negative infinity.

   @return Floating-point value of negative infinity.
*/
TRIO_PUBLIC double
trio_ninf(TRIO_NOARGS)
{
  static double result = 0.0;

  if (result == 0.0) {
    /*
     * Negative infinity is calculated by negating positive infinity,
     * which can be done because it is legal to do calculations on
     * infinity (for example,  1 / infinity == 0).
     */
    result = -trio_pinf();
  }
  return result;
}

/**
   Generate NaN.

   @return Floating-point representation of NaN.
*/
TRIO_PUBLIC double
trio_nan(TRIO_NOARGS)
{
  /* Cache the result */
  static double result = 0.0;

  if (result == 0.0) {
    
#if defined(TRIO_COMPILER_SUPPORTS_C99)
    result = nan("");

#elif defined(NAN) && defined(__STDC_IEC_559__)
    result = (double)NAN;
  
#elif defined(USE_IEEE_754)
    result = trio_make_double(ieee_754_qnan_array);

#else
    /*
     * There are several ways to generate NaN. The one used here is
     * to divide infinity by infinity. I would have preferred to add
     * negative infinity to positive infinity, but that yields wrong
     * result (infinity) on FreeBSD.
     *
     * This may fail if the hardware does not support NaN, or if
     * the Invalid Operation floating-point exception is unmasked.
     */
# if defined(TRIO_PLATFORM_UNIX)
    void (*signal_handler)(int) = signal(SIGFPE, SIG_IGN);
# endif
    
    result = trio_pinf() / trio_pinf();
    
# if defined(TRIO_PLATFORM_UNIX)
    signal(SIGFPE, signal_handler);
# endif
    
#endif
  }
  return result;
}

/**
   Check for NaN.

   @param number An arbitrary floating-point number.
   @return Boolean value indicating whether or not the number is a NaN.
*/
TRIO_PUBLIC int
trio_isnan
TRIO_ARGS1((number),
	   double number)
{
#if (defined(TRIO_COMPILER_SUPPORTS_C99) && defined(isnan)) \
 || defined(TRIO_COMPILER_SUPPORTS_UNIX95)
  /*
   * C99 defines isnan() as a macro. UNIX95 defines isnan() as a
   * function. This function was already present in XPG4, but this
   * is a bit tricky to detect with compiler defines, so we choose
   * the conservative approach and only use it for UNIX95.
   */
  return isnan(number);
  
#elif defined(TRIO_COMPILER_MSVC) || defined(TRIO_COMPILER_BCB)
  /*
   * Microsoft Visual C++ and Borland C++ Builder have an _isnan()
   * function.
   */
  return _isnan(number) ? TRIO_TRUE : TRIO_FALSE;

#elif defined(USE_IEEE_754)
  /*
   * Examine IEEE 754 bit-pattern. A NaN must have a special exponent
   * pattern, and a non-empty mantissa.
   */
  int has_mantissa;
  int is_special_quantity;

  is_special_quantity = trio_is_special_quantity(number, &has_mantissa);
  
  return (is_special_quantity && has_mantissa);
  
#else
  /*
   * Fallback solution
   */
  int status;
  double integral, fraction;
  
# if defined(TRIO_PLATFORM_UNIX)
  void (*signal_handler)(int) = signal(SIGFPE, SIG_IGN);
# endif
  
  status = (/*
	     * NaN is the only number which does not compare to itself
	     */
	    ((TRIO_VOLATILE double)number != (TRIO_VOLATILE double)number) ||
	    /*
	     * Fallback solution if NaN compares to NaN
	     */
	    ((number != 0.0) &&
	     (fraction = modf(number, &integral),
	      integral == fraction)));
  
# if defined(TRIO_PLATFORM_UNIX)
  signal(SIGFPE, signal_handler);
# endif
  
  return status;
  
#endif
}

/**
   Check for infinity.

   @param number An arbitrary floating-point number.
   @return 1 if positive infinity, -1 if negative infinity, 0 otherwise.
*/
TRIO_PUBLIC int
trio_isinf
TRIO_ARGS1((number),
	   double number)
{
#if defined(TRIO_COMPILER_DECC) && !defined(__linux__)
  /*
   * DECC has an isinf() macro, but it works differently than that
   * of C99, so we use the fp_class() function instead.
   */
  return ((fp_class(number) == FP_POS_INF)
	  ? 1
	  : ((fp_class(number) == FP_NEG_INF) ? -1 : 0));

#elif defined(isinf)
  /*
   * C99 defines isinf() as a macro.
   */
  return isinf(number)
    ? ((number > 0.0) ? 1 : -1)
    : 0;
  
#elif defined(TRIO_COMPILER_MSVC) || defined(TRIO_COMPILER_BCB)
  /*
   * Microsoft Visual C++ and Borland C++ Builder have an _fpclass()
   * function that can be used to detect infinity.
   */
  return ((_fpclass(number) == _FPCLASS_PINF)
	  ? 1
	  : ((_fpclass(number) == _FPCLASS_NINF) ? -1 : 0));

#elif defined(USE_IEEE_754)
  /*
   * Examine IEEE 754 bit-pattern. Infinity must have a special exponent
   * pattern, and an empty mantissa.
   */
  int has_mantissa;
  int is_special_quantity;

  is_special_quantity = trio_is_special_quantity(number, &has_mantissa);
  
  return (is_special_quantity && !has_mantissa)
    ? ((number < 0.0) ? -1 : 1)
    : 0;

#else
  /*
   * Fallback solution.
   */
  int status;
  
# if defined(TRIO_PLATFORM_UNIX)
  void (*signal_handler)(int) = signal(SIGFPE, SIG_IGN);
# endif
  
  double infinity = trio_pinf();
  
  status = ((number == infinity)
	    ? 1
	    : ((number == -infinity) ? -1 : 0));
  
# if defined(TRIO_PLATFORM_UNIX)
  signal(SIGFPE, signal_handler);
# endif
  
  return status;
  
#endif
}

#if 0
	/* Temporary fix - this routine is not used anywhere */
/**
   Check for finity.

   @param number An arbitrary floating-point number.
   @return Boolean value indicating whether or not the number is a finite.
*/
TRIO_PUBLIC int
trio_isfinite
TRIO_ARGS1((number),
	   double number)
{
#if defined(TRIO_COMPILER_SUPPORTS_C99) && defined(isfinite)
  /*
   * C99 defines isfinite() as a macro.
   */
  return isfinite(number);
  
#elif defined(TRIO_COMPILER_MSVC) || defined(TRIO_COMPILER_BCB)
  /*
   * Microsoft Visual C++ and Borland C++ Builder use _finite().
   */
  return _finite(number);

#elif defined(USE_IEEE_754)
  /*
   * Examine IEEE 754 bit-pattern. For finity we do not care about the
   * mantissa.
   */
  int dummy;

  return (! trio_is_special_quantity(number, &dummy));

#else
  /*
   * Fallback solution.
   */
  return ((trio_isinf(number) == 0) && (trio_isnan(number) == 0));
  
#endif
}

#endif

/*
 * The sign of NaN is always false
 */
TRIO_PUBLIC int
trio_fpclassify_and_signbit
TRIO_ARGS2((number, is_negative),
	   double number,
	   int *is_negative)
{
#if defined(fpclassify) && defined(signbit)
  /*
   * C99 defines fpclassify() and signbit() as a macros
   */
  *is_negative = signbit(number);
  switch (fpclassify(number)) {
  case FP_NAN:
    return TRIO_FP_NAN;
  case FP_INFINITE:
    return TRIO_FP_INFINITE;
  case FP_SUBNORMAL:
    return TRIO_FP_SUBNORMAL;
  case FP_ZERO:
    return TRIO_FP_ZERO;
  default:
    return TRIO_FP_NORMAL;
  }

#else
# if defined(TRIO_COMPILER_DECC)
  /*
   * DECC has an fp_class() function.
   */
#  define TRIO_FPCLASSIFY(n) fp_class(n)
#  define TRIO_QUIET_NAN FP_QNAN
#  define TRIO_SIGNALLING_NAN FP_SNAN
#  define TRIO_POSITIVE_INFINITY FP_POS_INF
#  define TRIO_NEGATIVE_INFINITY FP_NEG_INF
#  define TRIO_POSITIVE_SUBNORMAL FP_POS_DENORM
#  define TRIO_NEGATIVE_SUBNORMAL FP_NEG_DENORM
#  define TRIO_POSITIVE_ZERO FP_POS_ZERO
#  define TRIO_NEGATIVE_ZERO FP_NEG_ZERO
#  define TRIO_POSITIVE_NORMAL FP_POS_NORM
#  define TRIO_NEGATIVE_NORMAL FP_NEG_NORM
  
# elif defined(TRIO_COMPILER_MSVC) || defined(TRIO_COMPILER_BCB)
  /*
   * Microsoft Visual C++ and Borland C++ Builder have an _fpclass()
   * function.
   */
#  define TRIO_FPCLASSIFY(n) _fpclass(n)
#  define TRIO_QUIET_NAN _FPCLASS_QNAN
#  define TRIO_SIGNALLING_NAN _FPCLASS_SNAN
#  define TRIO_POSITIVE_INFINITY _FPCLASS_PINF
#  define TRIO_NEGATIVE_INFINITY _FPCLASS_NINF
#  define TRIO_POSITIVE_SUBNORMAL _FPCLASS_PD
#  define TRIO_NEGATIVE_SUBNORMAL _FPCLASS_ND
#  define TRIO_POSITIVE_ZERO _FPCLASS_PZ
#  define TRIO_NEGATIVE_ZERO _FPCLASS_NZ
#  define TRIO_POSITIVE_NORMAL _FPCLASS_PN
#  define TRIO_NEGATIVE_NORMAL _FPCLASS_NN
  
# elif defined(FP_PLUS_NORM)
  /*
   * HP-UX 9.x and 10.x have an fpclassify() function, that is different
   * from the C99 fpclassify() macro supported on HP-UX 11.x.
   *
   * AIX has class() for C, and _class() for C++, which returns the
   * same values as the HP-UX fpclassify() function.
   */
#  if defined(TRIO_PLATFORM_AIX)
#   if defined(__cplusplus)
#    define TRIO_FPCLASSIFY(n) _class(n)
#   else
#    define TRIO_FPCLASSIFY(n) class(n)
#   endif
#  else
#   define TRIO_FPCLASSIFY(n) fpclassify(n)
#  endif
#  define TRIO_QUIET_NAN FP_QNAN
#  define TRIO_SIGNALLING_NAN FP_SNAN
#  define TRIO_POSITIVE_INFINITY FP_PLUS_INF
#  define TRIO_NEGATIVE_INFINITY FP_MINUS_INF
#  define TRIO_POSITIVE_SUBNORMAL FP_PLUS_DENORM
#  define TRIO_NEGATIVE_SUBNORMAL FP_MINUS_DENORM
#  define TRIO_POSITIVE_ZERO FP_PLUS_ZERO
#  define TRIO_NEGATIVE_ZERO FP_MINUS_ZERO
#  define TRIO_POSITIVE_NORMAL FP_PLUS_NORM
#  define TRIO_NEGATIVE_NORMAL FP_MINUS_NORM
# endif

# if defined(TRIO_FPCLASSIFY)
  switch (TRIO_FPCLASSIFY(number)) {
  case TRIO_QUIET_NAN:
  case TRIO_SIGNALLING_NAN:
    *is_negative = TRIO_FALSE; /* NaN has no sign */
    return TRIO_FP_NAN;
  case TRIO_POSITIVE_INFINITY:
    *is_negative = TRIO_FALSE;
    return TRIO_FP_INFINITE;
  case TRIO_NEGATIVE_INFINITY:
    *is_negative = TRIO_TRUE;
    return TRIO_FP_INFINITE;
  case TRIO_POSITIVE_SUBNORMAL:
    *is_negative = TRIO_FALSE;
    return TRIO_FP_SUBNORMAL;
  case TRIO_NEGATIVE_SUBNORMAL:
    *is_negative = TRIO_TRUE;
    return TRIO_FP_SUBNORMAL;
  case TRIO_POSITIVE_ZERO:
    *is_negative = TRIO_FALSE;
    return TRIO_FP_ZERO;
  case TRIO_NEGATIVE_ZERO:
    *is_negative = TRIO_TRUE;
    return TRIO_FP_ZERO;
  case TRIO_POSITIVE_NORMAL:
    *is_negative = TRIO_FALSE;
    return TRIO_FP_NORMAL;
  case TRIO_NEGATIVE_NORMAL:
    *is_negative = TRIO_TRUE;
    return TRIO_FP_NORMAL;
  default:
    /* Just in case... */
    *is_negative = (number < 0.0);
    return TRIO_FP_NORMAL;
  }
  
# else
  /*
   * Fallback solution.
   */
  int rc;
  
  if (number == 0.0) {
    /*
     * In IEEE 754 the sign of zero is ignored in comparisons, so we
     * have to handle this as a special case by examining the sign bit
     * directly.
     */
#  if defined(USE_IEEE_754)
    *is_negative = trio_is_negative(number);
#  else
    *is_negative = TRIO_FALSE; /* FIXME */
#  endif
    return TRIO_FP_ZERO;
  }
  if (trio_isnan(number)) {
    *is_negative = TRIO_FALSE;
    return TRIO_FP_NAN;
  }
  if ((rc = trio_isinf(number))) {
    *is_negative = (rc == -1);
    return TRIO_FP_INFINITE;
  }
  if ((number > 0.0) && (number < DBL_MIN)) {
    *is_negative = TRIO_FALSE;
    return TRIO_FP_SUBNORMAL;
  }
  if ((number < 0.0) && (number > -DBL_MIN)) {
    *is_negative = TRIO_TRUE;
    return TRIO_FP_SUBNORMAL;
  }
  *is_negative = (number < 0.0);
  return TRIO_FP_NORMAL;
  
# endif
#endif
}

/**
   Examine the sign of a number.

   @param number An arbitrary floating-point number.
   @return Boolean value indicating whether or not the number has the
   sign bit set (i.e. is negative).
*/
TRIO_PUBLIC int
trio_signbit
TRIO_ARGS1((number),
	   double number)
{
  int is_negative;
  
  (void)trio_fpclassify_and_signbit(number, &is_negative);
  return is_negative;
}

#if 0
	/* Temporary fix - this routine is not used in libxml */
/**
   Examine the class of a number.

   @param number An arbitrary floating-point number.
   @return Enumerable value indicating the class of @p number
*/
TRIO_PUBLIC int
trio_fpclassify
TRIO_ARGS1((number),
	   double number)
{
  int dummy;
  
  return trio_fpclassify_and_signbit(number, &dummy);
}

#endif

/** @} SpecialQuantities */

/*************************************************************************
 * For test purposes.
 *
 * Add the following compiler option to include this test code.
 *
 *  Unix : -DSTANDALONE
 *  VMS  : /DEFINE=(STANDALONE)
 */
#if defined(STANDALONE)
# include <stdio.h>

static TRIO_CONST char *
getClassification
TRIO_ARGS1((type),
	   int type)
{
  switch (type) {
  case TRIO_FP_INFINITE:
    return "FP_INFINITE";
  case TRIO_FP_NAN:
    return "FP_NAN";
  case TRIO_FP_NORMAL:
    return "FP_NORMAL";
  case TRIO_FP_SUBNORMAL:
    return "FP_SUBNORMAL";
  case TRIO_FP_ZERO:
    return "FP_ZERO";
  default:
    return "FP_UNKNOWN";
  }
}

static void
print_class
TRIO_ARGS2((prefix, number),
	   TRIO_CONST char *prefix,
	   double number)
{
  printf("%-6s: %s %-15s %g\n",
	 prefix,
	 trio_signbit(number) ? "-" : "+",
	 getClassification(TRIO_FPCLASSIFY(number)),
	 number);
}

int main(TRIO_NOARGS)
{
  double my_nan;
  double my_pinf;
  double my_ninf;
# if defined(TRIO_PLATFORM_UNIX)
  void (*signal_handler) TRIO_PROTO((int));
# endif

  my_nan = trio_nan();
  my_pinf = trio_pinf();
  my_ninf = trio_ninf();

  print_class("Nan", my_nan);
  print_class("PInf", my_pinf);
  print_class("NInf", my_ninf);
  print_class("PZero", 0.0);
  print_class("NZero", -0.0);
  print_class("PNorm", 1.0);
  print_class("NNorm", -1.0);
  print_class("PSub", 1.01e-307 - 1.00e-307);
  print_class("NSub", 1.00e-307 - 1.01e-307);
  
  printf("NaN : %4g 0x%02x%02x%02x%02x%02x%02x%02x%02x (%2d, %2d)\n",
	 my_nan,
	 ((unsigned char *)&my_nan)[0],
	 ((unsigned char *)&my_nan)[1],
	 ((unsigned char *)&my_nan)[2],
	 ((unsigned char *)&my_nan)[3],
	 ((unsigned char *)&my_nan)[4],
	 ((unsigned char *)&my_nan)[5],
	 ((unsigned char *)&my_nan)[6],
	 ((unsigned char *)&my_nan)[7],
	 trio_isnan(my_nan), trio_isinf(my_nan));
  printf("PInf: %4g 0x%02x%02x%02x%02x%02x%02x%02x%02x (%2d, %2d)\n",
	 my_pinf,
	 ((unsigned char *)&my_pinf)[0],
	 ((unsigned char *)&my_pinf)[1],
	 ((unsigned char *)&my_pinf)[2],
	 ((unsigned char *)&my_pinf)[3],
	 ((unsigned char *)&my_pinf)[4],
	 ((unsigned char *)&my_pinf)[5],
	 ((unsigned char *)&my_pinf)[6],
	 ((unsigned char *)&my_pinf)[7],
	 trio_isnan(my_pinf), trio_isinf(my_pinf));
  printf("NInf: %4g 0x%02x%02x%02x%02x%02x%02x%02x%02x (%2d, %2d)\n",
	 my_ninf,
	 ((unsigned char *)&my_ninf)[0],
	 ((unsigned char *)&my_ninf)[1],
	 ((unsigned char *)&my_ninf)[2],
	 ((unsigned char *)&my_ninf)[3],
	 ((unsigned char *)&my_ninf)[4],
	 ((unsigned char *)&my_ninf)[5],
	 ((unsigned char *)&my_ninf)[6],
	 ((unsigned char *)&my_ninf)[7],
	 trio_isnan(my_ninf), trio_isinf(my_ninf));
  
# if defined(TRIO_PLATFORM_UNIX)
  signal_handler = signal(SIGFPE, SIG_IGN);
# endif
  
  my_pinf = DBL_MAX + DBL_MAX;
  my_ninf = -my_pinf;
  my_nan = my_pinf / my_pinf;

# if defined(TRIO_PLATFORM_UNIX)
  signal(SIGFPE, signal_handler);
# endif
  
  printf("NaN : %4g 0x%02x%02x%02x%02x%02x%02x%02x%02x (%2d, %2d)\n",
	 my_nan,
	 ((unsigned char *)&my_nan)[0],
	 ((unsigned char *)&my_nan)[1],
	 ((unsigned char *)&my_nan)[2],
	 ((unsigned char *)&my_nan)[3],
	 ((unsigned char *)&my_nan)[4],
	 ((unsigned char *)&my_nan)[5],
	 ((unsigned char *)&my_nan)[6],
	 ((unsigned char *)&my_nan)[7],
	 trio_isnan(my_nan), trio_isinf(my_nan));
  printf("PInf: %4g 0x%02x%02x%02x%02x%02x%02x%02x%02x (%2d, %2d)\n",
	 my_pinf,
	 ((unsigned char *)&my_pinf)[0],
	 ((unsigned char *)&my_pinf)[1],
	 ((unsigned char *)&my_pinf)[2],
	 ((unsigned char *)&my_pinf)[3],
	 ((unsigned char *)&my_pinf)[4],
	 ((unsigned char *)&my_pinf)[5],
	 ((unsigned char *)&my_pinf)[6],
	 ((unsigned char *)&my_pinf)[7],
	 trio_isnan(my_pinf), trio_isinf(my_pinf));
  printf("NInf: %4g 0x%02x%02x%02x%02x%02x%02x%02x%02x (%2d, %2d)\n",
	 my_ninf,
	 ((unsigned char *)&my_ninf)[0],
	 ((unsigned char *)&my_ninf)[1],
	 ((unsigned char *)&my_ninf)[2],
	 ((unsigned char *)&my_ninf)[3],
	 ((unsigned char *)&my_ninf)[4],
	 ((unsigned char *)&my_ninf)[5],
	 ((unsigned char *)&my_ninf)[6],
	 ((unsigned char *)&my_ninf)[7],
	 trio_isnan(my_ninf), trio_isinf(my_ninf));
  
  return 0;
}
#endif
