/*************************************************************************
 *
 * $Id$
 *
 * Copyright (C) 1998 Bjorn Reese and Daniel Stenberg.
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
 *************************************************************************
 *
 * A note to trio contributors:
 *
 * Avoid heap allocation at all costs to ensure that the trio functions
 * are async-safe. The exceptions are the printf/fprintf functions, which
 * uses fputc, and the asprintf functions and the <alloc> modifier, which
 * by design are required to allocate form the heap.
 *
 ************************************************************************/

/*
 * TODO:
 *  - Scan is probably too permissive about its modifiers.
 *  - C escapes in %#[] ?
 *  - Multibyte characters (done for format parsing, except scan groups)
 *  - Complex numbers? (C99 _Complex)
 *  - Boolean values? (C99 _Bool)
 *  - C99 NaN(n-char-sequence) missing. The n-char-sequence can be used
 *    to print the mantissa, e.g. NaN(0xc000000000000000)
 *  - Should we support the GNU %a alloc modifier? GNU has an ugly hack
 *    for %a, because C99 used %a for other purposes. If specified as
 *    %as or %a[ it is interpreted as the alloc modifier, otherwise as
 *    the C99 hex-float. This means that you cannot scan %as as a hex-float
 *    immediately followed by an 's'.
 *  - Scanning of collating symbols.
 */

/*************************************************************************
 * Trio include files
 */
#include "triodef.h"
#include "trio.h"
#include "triop.h"
#include "trionan.h"
#if !defined(TRIO_MINIMAL)
# include "triostr.h"
#endif

/**************************************************************************
 *
 * Definitions
 *
 *************************************************************************/

#include <math.h>
#include <limits.h>
#include <float.h>

#if (defined(__STDC_ISO_10646__) || defined(MB_LEN_MAX) \
     || defined(USE_MULTIBYTE) || TRIO_WIDECHAR) \
    && !defined(_WIN32_WCE)
# define TRIO_COMPILER_SUPPORTS_MULTIBYTE
# if !defined(MB_LEN_MAX)
#  define MB_LEN_MAX 6
# endif
#endif

#if (defined(TRIO_COMPILER_MSVC) && (_MSC_VER >= 1100)) || defined(TRIO_COMPILER_BCB)
# define TRIO_COMPILER_SUPPORTS_MSVC_INT
#endif

#if defined(_WIN32_WCE)
#include <wincecompat.h>
#endif

/*************************************************************************
 * Generic definitions
 */

#if !(defined(DEBUG) || defined(NDEBUG))
# define NDEBUG
#endif

#include <assert.h>
#include <ctype.h>
#if !defined(TRIO_COMPILER_SUPPORTS_C99)
# define isblank(x) (((x)==32) || ((x)==9))
#endif
#if defined(TRIO_COMPILER_ANCIENT)
# include <varargs.h>
#else
# include <stdarg.h>
#endif
#include <stddef.h>

#if defined( HAVE_ERRNO_H ) || defined( __VMS )
#include <errno.h>
#endif

#ifndef NULL
# define NULL 0
#endif
#define NIL ((char)0)
#ifndef FALSE
# define FALSE (1 == 0)
# define TRUE (! FALSE)
#endif
#define BOOLEAN_T int

/* mincore() can be used for debugging purposes */
#define VALID(x) (NULL != (x))

#if TRIO_ERRORS
  /*
   * Encode the error code and the position. This is decoded
   * with TRIO_ERROR_CODE and TRIO_ERROR_POSITION.
   */
# define TRIO_ERROR_RETURN(x,y) (- ((x) + ((y) << 8)))
#else
# define TRIO_ERROR_RETURN(x,y) (-1)
#endif

#ifndef VA_LIST_IS_ARRAY
#define TRIO_VA_LIST_PTR	va_list *
#define TRIO_VA_LIST_ADDR(l)	(&(l))
#define TRIO_VA_LIST_DEREF(l)	(*(l))
#else
#define TRIO_VA_LIST_PTR	va_list
#define TRIO_VA_LIST_ADDR(l)	(l)
#define TRIO_VA_LIST_DEREF(l)	(l)
#endif

typedef unsigned long trio_flags_t;


/*************************************************************************
 * Platform specific definitions
 */
#if defined(TRIO_PLATFORM_UNIX) || defined(TRIO_PLATFORM_OS400)
# include <unistd.h>
# include <signal.h>
# include <locale.h>
# define USE_LOCALE
#endif /* TRIO_PLATFORM_UNIX */
#if defined(TRIO_PLATFORM_VMS)
# include <unistd.h>
#endif
#if defined(TRIO_PLATFORM_WIN32)
# if defined(_WIN32_WCE)
#  include <wincecompat.h>
# else
#  include <io.h>
#  define read _read
#  define write _write
# endif
#endif /* TRIO_PLATFORM_WIN32 */

#if TRIO_WIDECHAR
# if defined(TRIO_COMPILER_SUPPORTS_ISO94)
#  include <wchar.h>
#  include <wctype.h>
typedef wchar_t trio_wchar_t;
typedef wint_t trio_wint_t;
# else
typedef char trio_wchar_t;
typedef int trio_wint_t;
#  define WCONST(x) L ## x
#  define WEOF EOF
#  define iswalnum(x) isalnum(x)
#  define iswalpha(x) isalpha(x)
#  define iswblank(x) isblank(x)
#  define iswcntrl(x) iscntrl(x)
#  define iswdigit(x) isdigit(x)
#  define iswgraph(x) isgraph(x)
#  define iswlower(x) islower(x)
#  define iswprint(x) isprint(x)
#  define iswpunct(x) ispunct(x)
#  define iswspace(x) isspace(x)
#  define iswupper(x) isupper(x)
#  define iswxdigit(x) isxdigit(x)
# endif
#endif


/*************************************************************************
 * Compiler dependent definitions
 */

/* Support for long long */
#ifndef __cplusplus
# if !defined(USE_LONGLONG)
#  if defined(TRIO_COMPILER_GCC) && !defined(__STRICT_ANSI__)
#   define USE_LONGLONG
#  elif defined(TRIO_COMPILER_SUNPRO)
#   define USE_LONGLONG
#  elif defined(_LONG_LONG) || defined(_LONGLONG)
#   define USE_LONGLONG
#  endif
# endif
#endif

/* The extra long numbers */
#if defined(USE_LONGLONG)
typedef signed long long int trio_longlong_t;
typedef unsigned long long int trio_ulonglong_t;
#elif defined(TRIO_COMPILER_SUPPORTS_MSVC_INT)
typedef signed __int64 trio_longlong_t;
typedef unsigned __int64 trio_ulonglong_t;
#else
typedef TRIO_SIGNED long int trio_longlong_t;
typedef unsigned long int trio_ulonglong_t;
#endif

/* Maximal and fixed integer types */
#if defined(TRIO_COMPILER_SUPPORTS_C99) && !defined( __VMS )
# include <stdint.h>
typedef intmax_t trio_intmax_t;
typedef uintmax_t trio_uintmax_t;
typedef int8_t trio_int8_t;
typedef int16_t trio_int16_t;
typedef int32_t trio_int32_t;
typedef int64_t trio_int64_t;
#elif defined(TRIO_COMPILER_SUPPORTS_UNIX98) || defined( __VMS )
# include <inttypes.h>
#ifdef __VMS
typedef long long int          intmax_t;
typedef unsigned long long int uintmax_t;
#endif
typedef intmax_t trio_intmax_t;
typedef uintmax_t trio_uintmax_t;
typedef int8_t trio_int8_t;
typedef int16_t trio_int16_t;
typedef int32_t trio_int32_t;
typedef int64_t trio_int64_t;
#elif defined(TRIO_COMPILER_SUPPORTS_MSVC_INT)
typedef trio_longlong_t trio_intmax_t;
typedef trio_ulonglong_t trio_uintmax_t;
typedef __int8 trio_int8_t;
typedef __int16 trio_int16_t;
typedef __int32 trio_int32_t;
typedef __int64 trio_int64_t;
#else
typedef trio_longlong_t trio_intmax_t;
typedef trio_ulonglong_t trio_uintmax_t;
# if defined(TRIO_INT8_T)
typedef TRIO_INT8_T trio_int8_t;
# else
typedef TRIO_SIGNED char trio_int8_t;
# endif
# if defined(TRIO_INT16_T)
typedef TRIO_INT16_T trio_int16_t;
# else
typedef TRIO_SIGNED short trio_int16_t;
# endif
# if defined(TRIO_INT32_T)
typedef TRIO_INT32_T trio_int32_t;
# else
typedef TRIO_SIGNED int trio_int32_t;
# endif
# if defined(TRIO_INT64_T)
typedef TRIO_INT64_T trio_int64_t;
# else
typedef trio_longlong_t trio_int64_t;
# endif
#endif

#if (!(defined(TRIO_COMPILER_SUPPORTS_C99) \
 || defined(TRIO_COMPILER_SUPPORTS_UNIX01))) \
 && !defined(_WIN32_WCE)
# define floorl(x) floor((double)(x))
# define fmodl(x,y) fmod((double)(x),(double)(y))
# define powl(x,y) pow((double)(x),(double)(y))
#endif

#define TRIO_FABS(x) (((x) < 0.0) ? -(x) : (x))

/*************************************************************************
 * Internal Definitions
 */

#ifndef DECIMAL_DIG
# define DECIMAL_DIG DBL_DIG
#endif

/* Long double sizes */
#ifdef LDBL_DIG
# define MAX_MANTISSA_DIGITS LDBL_DIG
# define MAX_EXPONENT_DIGITS 4
# define MAX_DOUBLE_DIGITS LDBL_MAX_10_EXP
#else
# define MAX_MANTISSA_DIGITS DECIMAL_DIG
# define MAX_EXPONENT_DIGITS 3
# define MAX_DOUBLE_DIGITS DBL_MAX_10_EXP
#endif

#if defined(TRIO_COMPILER_ANCIENT) || !defined(LDBL_DIG)
# undef LDBL_DIG
# undef LDBL_MANT_DIG
# undef LDBL_EPSILON
# define LDBL_DIG DBL_DIG
# define LDBL_MANT_DIG DBL_MANT_DIG
# define LDBL_EPSILON DBL_EPSILON
#endif

/* The maximal number of digits is for base 2 */
#define MAX_CHARS_IN(x) (sizeof(x) * CHAR_BIT)
/* The width of a pointer. The number of bits in a hex digit is 4 */
#define POINTER_WIDTH ((sizeof("0x") - 1) + sizeof(trio_pointer_t) * CHAR_BIT / 4)

/* Infinite and Not-A-Number for floating-point */
#define INFINITE_LOWER "inf"
#define INFINITE_UPPER "INF"
#define LONG_INFINITE_LOWER "infinite"
#define LONG_INFINITE_UPPER "INFINITE"
#define NAN_LOWER "nan"
#define NAN_UPPER "NAN"

#if !defined(HAVE_ISASCII) && !defined(isascii)
#ifndef __VMS
# define isascii(x) ((unsigned int)(x) < 128)
#endif
#endif

/* Various constants */
enum {
  TYPE_PRINT = 1,
  TYPE_SCAN  = 2,

  /* Flags. FLAGS_LAST must be less than ULONG_MAX */
  FLAGS_NEW                 = 0,
  FLAGS_STICKY              = 1,
  FLAGS_SPACE               = 2 * FLAGS_STICKY,
  FLAGS_SHOWSIGN            = 2 * FLAGS_SPACE,
  FLAGS_LEFTADJUST          = 2 * FLAGS_SHOWSIGN,
  FLAGS_ALTERNATIVE         = 2 * FLAGS_LEFTADJUST,
  FLAGS_SHORT               = 2 * FLAGS_ALTERNATIVE,
  FLAGS_SHORTSHORT          = 2 * FLAGS_SHORT,
  FLAGS_LONG                = 2 * FLAGS_SHORTSHORT,
  FLAGS_QUAD                = 2 * FLAGS_LONG,
  FLAGS_LONGDOUBLE          = 2 * FLAGS_QUAD,
  FLAGS_SIZE_T              = 2 * FLAGS_LONGDOUBLE,
  FLAGS_PTRDIFF_T           = 2 * FLAGS_SIZE_T,
  FLAGS_INTMAX_T            = 2 * FLAGS_PTRDIFF_T,
  FLAGS_NILPADDING          = 2 * FLAGS_INTMAX_T,
  FLAGS_UNSIGNED            = 2 * FLAGS_NILPADDING,
  FLAGS_UPPER               = 2 * FLAGS_UNSIGNED,
  FLAGS_WIDTH               = 2 * FLAGS_UPPER,
  FLAGS_WIDTH_PARAMETER     = 2 * FLAGS_WIDTH,
  FLAGS_PRECISION           = 2 * FLAGS_WIDTH_PARAMETER,
  FLAGS_PRECISION_PARAMETER = 2 * FLAGS_PRECISION,
  FLAGS_BASE                = 2 * FLAGS_PRECISION_PARAMETER,
  FLAGS_BASE_PARAMETER      = 2 * FLAGS_BASE,
  FLAGS_FLOAT_E             = 2 * FLAGS_BASE_PARAMETER,
  FLAGS_FLOAT_G             = 2 * FLAGS_FLOAT_E,
  FLAGS_QUOTE               = 2 * FLAGS_FLOAT_G,
  FLAGS_WIDECHAR            = 2 * FLAGS_QUOTE,
  FLAGS_ALLOC               = 2 * FLAGS_WIDECHAR,
  FLAGS_IGNORE              = 2 * FLAGS_ALLOC,
  FLAGS_IGNORE_PARAMETER    = 2 * FLAGS_IGNORE,
  FLAGS_VARSIZE_PARAMETER   = 2 * FLAGS_IGNORE_PARAMETER,
  FLAGS_FIXED_SIZE          = 2 * FLAGS_VARSIZE_PARAMETER,
  FLAGS_LAST                = FLAGS_FIXED_SIZE,
  /* Reused flags */
  FLAGS_EXCLUDE             = FLAGS_SHORT,
  FLAGS_USER_DEFINED        = FLAGS_IGNORE,
  FLAGS_ROUNDING            = FLAGS_INTMAX_T,
  /* Compounded flags */
  FLAGS_ALL_VARSIZES        = FLAGS_LONG | FLAGS_QUAD | FLAGS_INTMAX_T | FLAGS_PTRDIFF_T | FLAGS_SIZE_T,
  FLAGS_ALL_SIZES           = FLAGS_ALL_VARSIZES | FLAGS_SHORTSHORT | FLAGS_SHORT,

  NO_POSITION  = -1,
  NO_WIDTH     =  0,
  NO_PRECISION = -1,
  NO_SIZE      = -1,

  /* Do not change these */
  NO_BASE      = -1,
  MIN_BASE     =  2,
  MAX_BASE     = 36,
  BASE_BINARY  =  2,
  BASE_OCTAL   =  8,
  BASE_DECIMAL = 10,
  BASE_HEX     = 16,

  /* Maximal number of allowed parameters */
  MAX_PARAMETERS = 64,
  /* Maximal number of characters in class */
  MAX_CHARACTER_CLASS = UCHAR_MAX + 1,

  /* Maximal string lengths for user-defined specifiers */
  MAX_USER_NAME = 64,
  MAX_USER_DATA = 256,

  /* Maximal length of locale separator strings */
  MAX_LOCALE_SEPARATOR_LENGTH = MB_LEN_MAX,
  /* Maximal number of integers in grouping */
  MAX_LOCALE_GROUPS = 64,

  /* Initial size of asprintf buffer */
  DYNAMIC_START_SIZE = 32
};

#define NO_GROUPING ((int)CHAR_MAX)

/* Fundamental formatting parameter types */
#define FORMAT_UNKNOWN   0
#define FORMAT_INT       1
#define FORMAT_DOUBLE    2
#define FORMAT_CHAR      3
#define FORMAT_STRING    4
#define FORMAT_POINTER   5
#define FORMAT_COUNT     6
#define FORMAT_PARAMETER 7
#define FORMAT_GROUP     8
#if TRIO_GNU
# define FORMAT_ERRNO    9
#endif
#if TRIO_EXTENSION
# define FORMAT_USER_DEFINED 10
#endif

/* Character constants */
#define CHAR_IDENTIFIER '%'
#define CHAR_BACKSLASH '\\'
#define CHAR_QUOTE '\"'
#define CHAR_ADJUST ' '

/* Character class expressions */
#define CLASS_ALNUM "[:alnum:]"
#define CLASS_ALPHA "[:alpha:]"
#define CLASS_BLANK "[:blank:]"
#define CLASS_CNTRL "[:cntrl:]"
#define CLASS_DIGIT "[:digit:]"
#define CLASS_GRAPH "[:graph:]"
#define CLASS_LOWER "[:lower:]"
#define CLASS_PRINT "[:print:]"
#define CLASS_PUNCT "[:punct:]"
#define CLASS_SPACE "[:space:]"
#define CLASS_UPPER "[:upper:]"
#define CLASS_XDIGIT "[:xdigit:]"

/*
 * SPECIFIERS:
 *
 *
 * a  Hex-float
 * A  Hex-float
 * c  Character
 * C  Widechar character (wint_t)
 * d  Decimal
 * e  Float
 * E  Float
 * F  Float
 * F  Float
 * g  Float
 * G  Float
 * i  Integer
 * m  Error message
 * n  Count
 * o  Octal
 * p  Pointer
 * s  String
 * S  Widechar string (wchar_t *)
 * u  Unsigned
 * x  Hex
 * X  Hex
 * [] Group
 * <> User-defined
 *
 * Reserved:
 *
 * D  Binary Coded Decimal %D(length,precision) (OS/390)
 */
#define SPECIFIER_CHAR 'c'
#define SPECIFIER_STRING 's'
#define SPECIFIER_DECIMAL 'd'
#define SPECIFIER_INTEGER 'i'
#define SPECIFIER_UNSIGNED 'u'
#define SPECIFIER_OCTAL 'o'
#define SPECIFIER_HEX 'x'
#define SPECIFIER_HEX_UPPER 'X'
#define SPECIFIER_FLOAT_E 'e'
#define SPECIFIER_FLOAT_E_UPPER 'E'
#define SPECIFIER_FLOAT_F 'f'
#define SPECIFIER_FLOAT_F_UPPER 'F'
#define SPECIFIER_FLOAT_G 'g'
#define SPECIFIER_FLOAT_G_UPPER 'G'
#define SPECIFIER_POINTER 'p'
#define SPECIFIER_GROUP '['
#define SPECIFIER_UNGROUP ']'
#define SPECIFIER_COUNT 'n'
#if TRIO_UNIX98
# define SPECIFIER_CHAR_UPPER 'C'
# define SPECIFIER_STRING_UPPER 'S'
#endif
#if TRIO_C99
# define SPECIFIER_HEXFLOAT 'a'
# define SPECIFIER_HEXFLOAT_UPPER 'A'
#endif
#if TRIO_GNU
# define SPECIFIER_ERRNO 'm'
#endif
#if TRIO_EXTENSION
# define SPECIFIER_BINARY 'b'
# define SPECIFIER_BINARY_UPPER 'B'
# define SPECIFIER_USER_DEFINED_BEGIN '<'
# define SPECIFIER_USER_DEFINED_END '>'
# define SPECIFIER_USER_DEFINED_SEPARATOR ':'
#endif

/*
 * QUALIFIERS:
 *
 *
 * Numbers = d,i,o,u,x,X
 * Float = a,A,e,E,f,F,g,G
 * String = s
 * Char = c
 *
 *
 * 9$ Position
 *      Use the 9th parameter. 9 can be any number between 1 and
 *      the maximal argument
 *
 * 9 Width
 *      Set width to 9. 9 can be any number, but must not be postfixed
 *      by '$'
 *
 * h  Short
 *    Numbers:
 *      (unsigned) short int
 *
 * hh Short short
 *    Numbers:
 *      (unsigned) char
 *
 * l  Long
 *    Numbers:
 *      (unsigned) long int
 *    String:
 *      as the S specifier
 *    Char:
 *      as the C specifier
 *
 * ll Long Long
 *    Numbers:
 *      (unsigned) long long int
 *
 * L  Long Double
 *    Float
 *      long double
 *
 * #  Alternative
 *    Float:
 *      Decimal-point is always present
 *    String:
 *      non-printable characters are handled as \number
 *
 *    Spacing
 *
 * +  Sign
 *
 * -  Alignment
 *
 * .  Precision
 *
 * *  Parameter
 *    print: use parameter
 *    scan: no parameter (ignore)
 *
 * q  Quad
 *
 * Z  size_t
 *
 * w  Widechar
 *
 * '  Thousands/quote
 *    Numbers:
 *      Integer part grouped in thousands
 *    Binary numbers:
 *      Number grouped in nibbles (4 bits)
 *    String:
 *      Quoted string
 *
 * j  intmax_t
 * t  prtdiff_t
 * z  size_t
 *
 * !  Sticky
 * @  Parameter (for both print and scan)
 *
 * I  n-bit Integer
 *    Numbers:
 *      The following options exists
 *        I8  = 8-bit integer
 *        I16 = 16-bit integer
 *        I32 = 32-bit integer
 *        I64 = 64-bit integer
 */
#define QUALIFIER_POSITION '$'
#define QUALIFIER_SHORT 'h'
#define QUALIFIER_LONG 'l'
#define QUALIFIER_LONG_UPPER 'L'
#define QUALIFIER_ALTERNATIVE '#'
#define QUALIFIER_SPACE ' '
#define QUALIFIER_PLUS '+'
#define QUALIFIER_MINUS '-'
#define QUALIFIER_DOT '.'
#define QUALIFIER_STAR '*'
#define QUALIFIER_CIRCUMFLEX '^' /* For scanlists */
#if TRIO_C99
# define QUALIFIER_SIZE_T 'z'
# define QUALIFIER_PTRDIFF_T 't'
# define QUALIFIER_INTMAX_T 'j'
#endif
#if TRIO_BSD || TRIO_GNU
# define QUALIFIER_QUAD 'q'
#endif
#if TRIO_GNU
# define QUALIFIER_SIZE_T_UPPER 'Z'
#endif
#if TRIO_MISC
# define QUALIFIER_WIDECHAR 'w'
#endif
#if TRIO_MICROSOFT
# define QUALIFIER_FIXED_SIZE 'I'
#endif
#if TRIO_EXTENSION
# define QUALIFIER_QUOTE '\''
# define QUALIFIER_STICKY '!'
# define QUALIFIER_VARSIZE '&' /* This should remain undocumented */
# define QUALIFIER_PARAM '@' /* Experimental */
# define QUALIFIER_COLON ':' /* For scanlists */
# define QUALIFIER_EQUAL '=' /* For scanlists */
# define QUALIFIER_ROUNDING_UPPER 'R'
#endif


/*************************************************************************
 *
 * Internal Structures
 *
 *************************************************************************/

/* Parameters */
typedef struct {
  /* An indication of which entry in the data union is used */
  int type;
  /* The flags */
  trio_flags_t flags;
  /* The width qualifier */
  int width;
  /* The precision qualifier */
  int precision;
  /* The base qualifier */
  int base;
  /* The size for the variable size qualifier */
  int varsize;
  /* The marker of the end of the specifier */
  int indexAfterSpecifier;
  /* The data from the argument list */
  union {
    char *string;
#if TRIO_WIDECHAR
    trio_wchar_t *wstring;
#endif
    trio_pointer_t pointer;
    union {
      trio_intmax_t as_signed;
      trio_uintmax_t as_unsigned;
    } number;
    double doubleNumber;
    double *doublePointer;
    trio_long_double_t longdoubleNumber;
    trio_long_double_t *longdoublePointer;
    int errorNumber;
  } data;
  /* For the user-defined specifier */
  char user_name[MAX_USER_NAME];
  char user_data[MAX_USER_DATA];
} trio_parameter_t;

/* Container for customized functions */
typedef struct {
  union {
    trio_outstream_t out;
    trio_instream_t in;
  } stream;
  trio_pointer_t closure;
} trio_custom_t;

/* General trio "class" */
typedef struct _trio_class_t {
  /*
   * The function to write characters to a stream.
   */
  void (*OutStream) TRIO_PROTO((struct _trio_class_t *, int));
  /*
   * The function to read characters from a stream.
   */
  void (*InStream) TRIO_PROTO((struct _trio_class_t *, int *));
  /*
   * The current location in the stream.
   */
  trio_pointer_t location;
  /*
   * The character currently being processed.
   */
  int current;
  /*
   * The number of characters that would have been written/read
   * if there had been sufficient space.
   */
  int processed;
  /*
   * The number of characters that are actually written/read.
   * Processed and committed will only differ for the *nprintf
   * and *nscanf functions.
   */
  int committed;
  /*
   * The upper limit of characters that may be written/read.
   */
  int max;
  /*
   * The last output error that was detected.
   */
  int error;
} trio_class_t;

/* References (for user-defined callbacks) */
typedef struct _trio_reference_t {
  trio_class_t *data;
  trio_parameter_t *parameter;
} trio_reference_t;

/* Registered entries (for user-defined callbacks) */
typedef struct _trio_userdef_t {
  struct _trio_userdef_t *next;
  trio_callback_t callback;
  char *name;
} trio_userdef_t;

/*************************************************************************
 *
 * Internal Variables
 *
 *************************************************************************/

static TRIO_CONST char rcsid[] = "@(#)$Id$";

/*
 * Need this to workaround a parser bug in HP C/iX compiler that fails
 * to resolves macro definitions that includes type 'long double',
 * e.g: va_arg(arg_ptr, long double)
 */
#if defined(TRIO_PLATFORM_MPEIX)
static TRIO_CONST trio_long_double_t ___dummy_long_double = 0;
#endif

static TRIO_CONST char internalNullString[] = "(nil)";

#if defined(USE_LOCALE)
static struct lconv *internalLocaleValues = NULL;
#endif

/*
 * UNIX98 says "in a locale where the radix character is not defined,
 * the radix character defaults to a period (.)"
 */
static int internalDecimalPointLength = 1;
static int internalThousandSeparatorLength = 1;
static char internalDecimalPoint = '.';
static char internalDecimalPointString[MAX_LOCALE_SEPARATOR_LENGTH + 1] = ".";
static char internalThousandSeparator[MAX_LOCALE_SEPARATOR_LENGTH + 1] = ",";
static char internalGrouping[MAX_LOCALE_GROUPS] = { (char)NO_GROUPING };

static TRIO_CONST char internalDigitsLower[] = "0123456789abcdefghijklmnopqrstuvwxyz";
static TRIO_CONST char internalDigitsUpper[] = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ";
static BOOLEAN_T internalDigitsUnconverted = TRUE;
static int internalDigitArray[128];
#if TRIO_EXTENSION
static BOOLEAN_T internalCollationUnconverted = TRUE;
static char internalCollationArray[MAX_CHARACTER_CLASS][MAX_CHARACTER_CLASS];
#endif

#if TRIO_EXTENSION
static TRIO_VOLATILE trio_callback_t internalEnterCriticalRegion = NULL;
static TRIO_VOLATILE trio_callback_t internalLeaveCriticalRegion = NULL;
static trio_userdef_t *internalUserDef = NULL;
#endif


/*************************************************************************
 *
 * Internal Functions
 *
 ************************************************************************/

#if defined(TRIO_MINIMAL)
# define TRIO_STRING_PUBLIC static
# include "triostr.c"
#endif /* defined(TRIO_MINIMAL) */

/*************************************************************************
 * TrioIsQualifier
 *
 * Description:
 *  Remember to add all new qualifiers to this function.
 *  QUALIFIER_POSITION must not be added.
 */
TRIO_PRIVATE BOOLEAN_T
TrioIsQualifier
TRIO_ARGS1((character),
	   TRIO_CONST char character)
{
  /* QUALIFIER_POSITION is not included */
  switch (character)
    {
    case '0': case '1': case '2': case '3': case '4':
    case '5': case '6': case '7': case '8': case '9':
    case QUALIFIER_PLUS:
    case QUALIFIER_MINUS:
    case QUALIFIER_SPACE:
    case QUALIFIER_DOT:
    case QUALIFIER_STAR:
    case QUALIFIER_ALTERNATIVE:
    case QUALIFIER_SHORT:
    case QUALIFIER_LONG:
    case QUALIFIER_LONG_UPPER:
    case QUALIFIER_CIRCUMFLEX:
#if defined(QUALIFIER_SIZE_T)
    case QUALIFIER_SIZE_T:
#endif
#if defined(QUALIFIER_PTRDIFF_T)
    case QUALIFIER_PTRDIFF_T:
#endif
#if defined(QUALIFIER_INTMAX_T)
    case QUALIFIER_INTMAX_T:
#endif
#if defined(QUALIFIER_QUAD)
    case QUALIFIER_QUAD:
#endif
#if defined(QUALIFIER_SIZE_T_UPPER)
    case QUALIFIER_SIZE_T_UPPER:
#endif
#if defined(QUALIFIER_WIDECHAR)
    case QUALIFIER_WIDECHAR:
#endif
#if defined(QUALIFIER_QUOTE)
    case QUALIFIER_QUOTE:
#endif
#if defined(QUALIFIER_STICKY)
    case QUALIFIER_STICKY:
#endif
#if defined(QUALIFIER_VARSIZE)
    case QUALIFIER_VARSIZE:
#endif
#if defined(QUALIFIER_PARAM)
    case QUALIFIER_PARAM:
#endif
#if defined(QUALIFIER_FIXED_SIZE)
    case QUALIFIER_FIXED_SIZE:
#endif
#if defined(QUALIFIER_ROUNDING_UPPER)
    case QUALIFIER_ROUNDING_UPPER:
#endif
      return TRUE;
    default:
      return FALSE;
    }
}

/*************************************************************************
 * TrioSetLocale
 */
#if defined(USE_LOCALE)
TRIO_PRIVATE void
TrioSetLocale(TRIO_NOARGS)
{
  internalLocaleValues = (struct lconv *)localeconv();
  if (internalLocaleValues)
    {
      if ((internalLocaleValues->decimal_point) &&
	  (internalLocaleValues->decimal_point[0] != NIL))
	{
	  internalDecimalPointLength = trio_length(internalLocaleValues->decimal_point);
	  if (internalDecimalPointLength == 1)
	    {
	      internalDecimalPoint = internalLocaleValues->decimal_point[0];
	    }
	  else
	    {
	      internalDecimalPoint = NIL;
	      trio_copy_max(internalDecimalPointString,
			    sizeof(internalDecimalPointString),
			    internalLocaleValues->decimal_point);
	    }
	}
      if ((internalLocaleValues->thousands_sep) &&
	  (internalLocaleValues->thousands_sep[0] != NIL))
	{
	  trio_copy_max(internalThousandSeparator,
			sizeof(internalThousandSeparator),
			internalLocaleValues->thousands_sep);
	  internalThousandSeparatorLength = trio_length(internalThousandSeparator);
	}
      if ((internalLocaleValues->grouping) &&
	  (internalLocaleValues->grouping[0] != NIL))
	{
	  trio_copy_max(internalGrouping,
			sizeof(internalGrouping),
			internalLocaleValues->grouping);
	}
    }
}
#endif /* defined(USE_LOCALE) */

TRIO_PRIVATE int
TrioCalcThousandSeparatorLength
TRIO_ARGS1((digits),
	   int digits)
{
#if TRIO_EXTENSION
  int count = 0;
  int step = NO_GROUPING;
  char *groupingPointer = internalGrouping;

  while (digits > 0)
    {
      if (*groupingPointer == CHAR_MAX)
	{
	  /* Disable grouping */
	  break; /* while */
	}
      else if (*groupingPointer == 0)
	{
	  /* Repeat last group */
	  if (step == NO_GROUPING)
	    {
	      /* Error in locale */
	      break; /* while */
	    }
	}
      else
	{
	  step = *groupingPointer++;
	}
      if (digits > step)
	count += internalThousandSeparatorLength;
      digits -= step;
    }
  return count;
#else
  return 0;
#endif
}

TRIO_PRIVATE BOOLEAN_T
TrioFollowedBySeparator
TRIO_ARGS1((position),
	   int position)
{
#if TRIO_EXTENSION
  int step = 0;
  char *groupingPointer = internalGrouping;

  position--;
  if (position == 0)
    return FALSE;
  while (position > 0)
    {
      if (*groupingPointer == CHAR_MAX)
	{
	  /* Disable grouping */
	  break; /* while */
	}
      else if (*groupingPointer != 0)
	{
	  step = *groupingPointer++;
	}
      if (step == 0)
	break;
      position -= step;
    }
  return (position == 0);
#else
  return FALSE;
#endif
}

/*************************************************************************
 * TrioGetPosition
 *
 * Get the %n$ position.
 */
TRIO_PRIVATE int
TrioGetPosition
TRIO_ARGS2((format, indexPointer),
	   TRIO_CONST char *format,
	   int *indexPointer)
{
#if TRIO_UNIX98
  char *tmpformat;
  int number = 0;
  int index = *indexPointer;

  number = (int)trio_to_long(&format[index], &tmpformat, BASE_DECIMAL);
  index = (int)(tmpformat - format);
  if ((number != 0) && (QUALIFIER_POSITION == format[index++]))
    {
      *indexPointer = index;
      /*
       * number is decreased by 1, because n$ starts from 1, whereas
       * the array it is indexing starts from 0.
       */
      return number - 1;
    }
#endif
  return NO_POSITION;
}

#if TRIO_EXTENSION
/*************************************************************************
 * TrioFindNamespace
 *
 * Find registered user-defined specifier.
 * The prev argument is used for optimization only.
 */
TRIO_PRIVATE trio_userdef_t *
TrioFindNamespace
TRIO_ARGS2((name, prev),
	   TRIO_CONST char *name,
	   trio_userdef_t **prev)
{
  trio_userdef_t *def;

  if (internalEnterCriticalRegion)
    (void)internalEnterCriticalRegion(NULL);

  for (def = internalUserDef; def; def = def->next)
    {
      /* Case-sensitive string comparison */
      if (trio_equal_case(def->name, name))
	break;

      if (prev)
	*prev = def;
    }

  if (internalLeaveCriticalRegion)
    (void)internalLeaveCriticalRegion(NULL);

  return def;
}
#endif

/*************************************************************************
 * TrioPower
 *
 * Description:
 *  Calculate pow(base, exponent), where number and exponent are integers.
 */
TRIO_PRIVATE trio_long_double_t
TrioPower
TRIO_ARGS2((number, exponent),
	   int number,
	   int exponent)
{
  trio_long_double_t result;

  if (number == 10)
    {
      switch (exponent)
	{
	  /* Speed up calculation of common cases */
	case 0:
	  result = (trio_long_double_t)number * TRIO_SUFFIX_LONG(1E-1);
	  break;
	case 1:
	  result = (trio_long_double_t)number * TRIO_SUFFIX_LONG(1E+0);
	  break;
	case 2:
	  result = (trio_long_double_t)number * TRIO_SUFFIX_LONG(1E+1);
	  break;
	case 3:
	  result = (trio_long_double_t)number * TRIO_SUFFIX_LONG(1E+2);
	  break;
	case 4:
	  result = (trio_long_double_t)number * TRIO_SUFFIX_LONG(1E+3);
	  break;
	case 5:
	  result = (trio_long_double_t)number * TRIO_SUFFIX_LONG(1E+4);
	  break;
	case 6:
	  result = (trio_long_double_t)number * TRIO_SUFFIX_LONG(1E+5);
	  break;
	case 7:
	  result = (trio_long_double_t)number * TRIO_SUFFIX_LONG(1E+6);
	  break;
	case 8:
	  result = (trio_long_double_t)number * TRIO_SUFFIX_LONG(1E+7);
	  break;
	case 9:
	  result = (trio_long_double_t)number * TRIO_SUFFIX_LONG(1E+8);
	  break;
	default:
	  result = powl((trio_long_double_t)number,
			(trio_long_double_t)exponent);
	  break;
	}
    }
  else
    {
      return powl((trio_long_double_t)number, (trio_long_double_t)exponent);
    }
  return result;
}

/*************************************************************************
 * TrioLogarithm
 */
TRIO_PRIVATE double
TrioLogarithm
TRIO_ARGS2((number, base),
	   double number,
	   int base)
{
  double result;

  if (number <= 0.0)
    {
      /* xlC crashes on log(0) */
      result = (number == 0.0) ? trio_ninf() : trio_nan();
    }
  else
    {
      if (base == 10)
	{
	  result = log10(number);
	}
      else
	{
	  result = log10(number) / log10((double)base);
	}
    }
  return result;
}

/*************************************************************************
 * TrioLogarithmBase
 */
TRIO_PRIVATE double
TrioLogarithmBase
TRIO_ARGS1((base),
	   int base)
{
  switch (base)
    {
    case BASE_BINARY : return 1.0;
    case BASE_OCTAL  : return 3.0;
    case BASE_DECIMAL: return 3.321928094887362345;
    case BASE_HEX    : return 4.0;
    default          : return TrioLogarithm((double)base, 2);
    }
}

/*************************************************************************
 * TrioParse
 *
 * Description:
 *  Parse the format string
 */
TRIO_PRIVATE int
TrioParse
TRIO_ARGS5((type, format, parameters, arglist, argarray),
	   int type,
	   TRIO_CONST char *format,
	   trio_parameter_t *parameters,
	   TRIO_VA_LIST_PTR arglist,
	   trio_pointer_t *argarray)
{
  /* Count the number of times a parameter is referenced */
  unsigned short usedEntries[MAX_PARAMETERS];
  /* Parameter counters */
  int parameterPosition;
  int currentParam;
  int maxParam = -1;
  /* Utility variables */
  trio_flags_t flags;
  int width;
  int precision;
  int varsize;
  int base;
  int index;  /* Index into formatting string */
  int dots;  /* Count number of dots in modifier part */
  BOOLEAN_T positional;  /* Does the specifier have a positional? */
  BOOLEAN_T gotSticky = FALSE;  /* Are there any sticky modifiers at all? */
  /*
   * indices specifies the order in which the parameters must be
   * read from the va_args (this is necessary to handle positionals)
   */
  int indices[MAX_PARAMETERS];
  int pos = 0;
  /* Various variables */
  char ch;
#if defined(TRIO_COMPILER_SUPPORTS_MULTIBYTE)
  int charlen;
#endif
  int save_errno;
  int i = -1;
  int num;
  char *tmpformat;

  /* One and only one of arglist and argarray must be used */
  assert((arglist != NULL) ^ (argarray != NULL));

  /*
   * The 'parameters' array is not initialized, but we need to
   * know which entries we have used.
   */
  memset(usedEntries, 0, sizeof(usedEntries));

  save_errno = errno;
  index = 0;
  parameterPosition = 0;
#if defined(TRIO_COMPILER_SUPPORTS_MULTIBYTE)
  (void)mblen(NULL, 0);
#endif

  while (format[index])
    {
#if defined(TRIO_COMPILER_SUPPORTS_MULTIBYTE)
      if (! isascii(format[index]))
	{
	  /*
	   * Multibyte characters cannot be legal specifiers or
	   * modifiers, so we skip over them.
	   */
	  charlen = mblen(&format[index], MB_LEN_MAX);
	  index += (charlen > 0) ? charlen : 1;
	  continue; /* while */
	}
#endif /* TRIO_COMPILER_SUPPORTS_MULTIBYTE */
      if (CHAR_IDENTIFIER == format[index++])
	{
	  if (CHAR_IDENTIFIER == format[index])
	    {
	      index++;
	      continue; /* while */
	    }

	  flags = FLAGS_NEW;
	  dots = 0;
	  currentParam = TrioGetPosition(format, &index);
	  positional = (NO_POSITION != currentParam);
	  if (!positional)
	    {
	      /* We have no positional, get the next counter */
	      currentParam = parameterPosition;
	    }
          if(currentParam >= MAX_PARAMETERS)
	    {
	      /* Bail out completely to make the error more obvious */
	      return TRIO_ERROR_RETURN(TRIO_ETOOMANY, index);
	    }

	  if (currentParam > maxParam)
	    maxParam = currentParam;

	  /* Default values */
	  width = NO_WIDTH;
	  precision = NO_PRECISION;
	  base = NO_BASE;
	  varsize = NO_SIZE;

	  while (TrioIsQualifier(format[index]))
	    {
	      ch = format[index++];

	      switch (ch)
		{
		case QUALIFIER_SPACE:
		  flags |= FLAGS_SPACE;
		  break;

		case QUALIFIER_PLUS:
		  flags |= FLAGS_SHOWSIGN;
		  break;

		case QUALIFIER_MINUS:
		  flags |= FLAGS_LEFTADJUST;
		  flags &= ~FLAGS_NILPADDING;
		  break;

		case QUALIFIER_ALTERNATIVE:
		  flags |= FLAGS_ALTERNATIVE;
		  break;

		case QUALIFIER_DOT:
		  if (dots == 0) /* Precision */
		    {
		      dots++;

		      /* Skip if no precision */
		      if (QUALIFIER_DOT == format[index])
			break;

		      /* After the first dot we have the precision */
		      flags |= FLAGS_PRECISION;
		      if ((QUALIFIER_STAR == format[index])
#if defined(QUALIFIER_PARAM)
			  || (QUALIFIER_PARAM == format[index])
#endif
			  )
			{
			  index++;
			  flags |= FLAGS_PRECISION_PARAMETER;

			  precision = TrioGetPosition(format, &index);
			  if (precision == NO_POSITION)
			    {
			      parameterPosition++;
			      if (positional)
				precision = parameterPosition;
			      else
				{
				  precision = currentParam;
				  currentParam = precision + 1;
				}
			    }
			  else
			    {
			      if (! positional)
				currentParam = precision + 1;
			      if (width > maxParam)
				maxParam = precision;
			    }
			  if (currentParam > maxParam)
			    maxParam = currentParam;
			}
		      else
			{
			  precision = trio_to_long(&format[index],
						   &tmpformat,
						   BASE_DECIMAL);
			  index = (int)(tmpformat - format);
			}
		    }
		  else if (dots == 1) /* Base */
		    {
		      dots++;

		      /* After the second dot we have the base */
		      flags |= FLAGS_BASE;
		      if ((QUALIFIER_STAR == format[index])
#if defined(QUALIFIER_PARAM)
			  || (QUALIFIER_PARAM == format[index])
#endif
			  )
			{
			  index++;
			  flags |= FLAGS_BASE_PARAMETER;
			  base = TrioGetPosition(format, &index);
			  if (base == NO_POSITION)
			    {
			      parameterPosition++;
			      if (positional)
				base = parameterPosition;
			      else
				{
				  base = currentParam;
				  currentParam = base + 1;
				}
			    }
			  else
			    {
			      if (! positional)
				currentParam = base + 1;
			      if (base > maxParam)
				maxParam = base;
			    }
			  if (currentParam > maxParam)
			    maxParam = currentParam;
			}
		      else
			{
			  base = trio_to_long(&format[index],
					      &tmpformat,
					      BASE_DECIMAL);
			  if (base > MAX_BASE)
			    return TRIO_ERROR_RETURN(TRIO_EINVAL, index);
			  index = (int)(tmpformat - format);
			}
		    }
		  else
		    {
		      return TRIO_ERROR_RETURN(TRIO_EINVAL, index);
		    }
		  break; /* QUALIFIER_DOT */

#if defined(QUALIFIER_PARAM)
		case QUALIFIER_PARAM:
		  type = TYPE_PRINT;
		  /* FALLTHROUGH */
#endif
		case QUALIFIER_STAR:
		  /* This has different meanings for print and scan */
		  if (TYPE_PRINT == type)
		    {
		      /* Read with from parameter */
		      flags |= (FLAGS_WIDTH | FLAGS_WIDTH_PARAMETER);
		      width = TrioGetPosition(format, &index);
		      if (width == NO_POSITION)
			{
			  parameterPosition++;
			  if (positional)
			    width = parameterPosition;
			  else
			    {
			      width = currentParam;
			      currentParam = width + 1;
			    }
			}
		      else
			{
			  if (! positional)
			    currentParam = width + 1;
			  if (width > maxParam)
			    maxParam = width;
			}
		      if (currentParam > maxParam)
			maxParam = currentParam;
		    }
		  else
		    {
		      /* Scan, but do not store result */
		      flags |= FLAGS_IGNORE;
		    }

		  break; /* QUALIFIER_STAR */

		case '0':
		  if (! (flags & FLAGS_LEFTADJUST))
		    flags |= FLAGS_NILPADDING;
		  /* FALLTHROUGH */
		case '1': case '2': case '3': case '4':
		case '5': case '6': case '7': case '8': case '9':
		  flags |= FLAGS_WIDTH;
		  /* &format[index - 1] is used to "rewind" the read
		   * character from format
		   */
		  width = trio_to_long(&format[index - 1],
				       &tmpformat,
				       BASE_DECIMAL);
		  index = (int)(tmpformat - format);
		  break;

		case QUALIFIER_SHORT:
		  if (flags & FLAGS_SHORTSHORT)
		    return TRIO_ERROR_RETURN(TRIO_EINVAL, index);
		  else if (flags & FLAGS_SHORT)
		    flags |= FLAGS_SHORTSHORT;
		  else
		    flags |= FLAGS_SHORT;
		  break;

		case QUALIFIER_LONG:
		  if (flags & FLAGS_QUAD)
		    return TRIO_ERROR_RETURN(TRIO_EINVAL, index);
		  else if (flags & FLAGS_LONG)
		    flags |= FLAGS_QUAD;
		  else
		    flags |= FLAGS_LONG;
		  break;

		case QUALIFIER_LONG_UPPER:
		  flags |= FLAGS_LONGDOUBLE;
		  break;

#if defined(QUALIFIER_SIZE_T)
		case QUALIFIER_SIZE_T:
		  flags |= FLAGS_SIZE_T;
		  /* Modify flags for later truncation of number */
		  if (sizeof(size_t) == sizeof(trio_ulonglong_t))
		    flags |= FLAGS_QUAD;
		  else if (sizeof(size_t) == sizeof(long))
		    flags |= FLAGS_LONG;
		  break;
#endif

#if defined(QUALIFIER_PTRDIFF_T)
		case QUALIFIER_PTRDIFF_T:
		  flags |= FLAGS_PTRDIFF_T;
		  if (sizeof(ptrdiff_t) == sizeof(trio_ulonglong_t))
		    flags |= FLAGS_QUAD;
		  else if (sizeof(ptrdiff_t) == sizeof(long))
		    flags |= FLAGS_LONG;
		  break;
#endif

#if defined(QUALIFIER_INTMAX_T)
		case QUALIFIER_INTMAX_T:
		  flags |= FLAGS_INTMAX_T;
		  if (sizeof(trio_intmax_t) == sizeof(trio_ulonglong_t))
		    flags |= FLAGS_QUAD;
		  else if (sizeof(trio_intmax_t) == sizeof(long))
		    flags |= FLAGS_LONG;
		  break;
#endif

#if defined(QUALIFIER_QUAD)
		case QUALIFIER_QUAD:
		  flags |= FLAGS_QUAD;
		  break;
#endif

#if defined(QUALIFIER_FIXED_SIZE)
		case QUALIFIER_FIXED_SIZE:
		  if (flags & FLAGS_FIXED_SIZE)
		    return TRIO_ERROR_RETURN(TRIO_EINVAL, index);

		  if (flags & (FLAGS_ALL_SIZES | FLAGS_LONGDOUBLE |
			       FLAGS_WIDECHAR | FLAGS_VARSIZE_PARAMETER))
		    return TRIO_ERROR_RETURN(TRIO_EINVAL, index);

		  if ((format[index] == '6') &&
		      (format[index + 1] == '4'))
		    {
		      varsize = sizeof(trio_int64_t);
		      index += 2;
		    }
		  else if ((format[index] == '3') &&
			   (format[index + 1] == '2'))
		    {
		      varsize = sizeof(trio_int32_t);
		      index += 2;
		    }
		  else if ((format[index] == '1') &&
			   (format[index + 1] == '6'))
		    {
		      varsize = sizeof(trio_int16_t);
		      index += 2;
		    }
		  else if (format[index] == '8')
		    {
		      varsize = sizeof(trio_int8_t);
		      index++;
		    }
		  else
		    return TRIO_ERROR_RETURN(TRIO_EINVAL, index);

		  flags |= FLAGS_FIXED_SIZE;
		  break;
#endif

#if defined(QUALIFIER_WIDECHAR)
		case QUALIFIER_WIDECHAR:
		  flags |= FLAGS_WIDECHAR;
		  break;
#endif

#if defined(QUALIFIER_SIZE_T_UPPER)
		case QUALIFIER_SIZE_T_UPPER:
		  break;
#endif

#if defined(QUALIFIER_QUOTE)
		case QUALIFIER_QUOTE:
		  flags |= FLAGS_QUOTE;
		  break;
#endif

#if defined(QUALIFIER_STICKY)
		case QUALIFIER_STICKY:
		  flags |= FLAGS_STICKY;
		  gotSticky = TRUE;
		  break;
#endif

#if defined(QUALIFIER_VARSIZE)
		case QUALIFIER_VARSIZE:
		  flags |= FLAGS_VARSIZE_PARAMETER;
		  parameterPosition++;
		  if (positional)
		    varsize = parameterPosition;
		  else
		    {
		      varsize = currentParam;
		      currentParam = varsize + 1;
		    }
		  if (currentParam > maxParam)
		    maxParam = currentParam;
		  break;
#endif

#if defined(QUALIFIER_ROUNDING_UPPER)
		case QUALIFIER_ROUNDING_UPPER:
		  flags |= FLAGS_ROUNDING;
		  break;
#endif

		default:
		  /* Bail out completely to make the error more obvious */
                  return TRIO_ERROR_RETURN(TRIO_EINVAL, index);
		}
	    } /* while qualifier */

	  /*
	   * Parameters only need the type and value. The value is
	   * read later.
	   */
	  if (flags & FLAGS_WIDTH_PARAMETER)
	    {
	      usedEntries[width] += 1;
	      parameters[pos].type = FORMAT_PARAMETER;
	      parameters[pos].flags = 0;
	      indices[width] = pos;
	      width = pos++;
	    }
	  if (flags & FLAGS_PRECISION_PARAMETER)
	    {
	      usedEntries[precision] += 1;
	      parameters[pos].type = FORMAT_PARAMETER;
	      parameters[pos].flags = 0;
	      indices[precision] = pos;
	      precision = pos++;
	    }
	  if (flags & FLAGS_BASE_PARAMETER)
	    {
	      usedEntries[base] += 1;
	      parameters[pos].type = FORMAT_PARAMETER;
	      parameters[pos].flags = 0;
	      indices[base] = pos;
	      base = pos++;
	    }
	  if (flags & FLAGS_VARSIZE_PARAMETER)
	    {
	      usedEntries[varsize] += 1;
	      parameters[pos].type = FORMAT_PARAMETER;
	      parameters[pos].flags = 0;
	      indices[varsize] = pos;
	      varsize = pos++;
	    }

	  indices[currentParam] = pos;

	  switch (format[index++])
	    {
#if defined(SPECIFIER_CHAR_UPPER)
	    case SPECIFIER_CHAR_UPPER:
	      flags |= FLAGS_WIDECHAR;
	      /* FALLTHROUGH */
#endif
	    case SPECIFIER_CHAR:
	      if (flags & FLAGS_LONG)
		flags |= FLAGS_WIDECHAR;
	      else if (flags & FLAGS_SHORT)
		flags &= ~FLAGS_WIDECHAR;
	      parameters[pos].type = FORMAT_CHAR;
	      break;

#if defined(SPECIFIER_STRING_UPPER)
	    case SPECIFIER_STRING_UPPER:
	      flags |= FLAGS_WIDECHAR;
	      /* FALLTHROUGH */
#endif
	    case SPECIFIER_STRING:
	      if (flags & FLAGS_LONG)
		flags |= FLAGS_WIDECHAR;
	      else if (flags & FLAGS_SHORT)
		flags &= ~FLAGS_WIDECHAR;
	      parameters[pos].type = FORMAT_STRING;
	      break;

	    case SPECIFIER_GROUP:
	      if (TYPE_SCAN == type)
		{
		  int depth = 1;
		  parameters[pos].type = FORMAT_GROUP;
		  if (format[index] == QUALIFIER_CIRCUMFLEX)
		    index++;
		  if (format[index] == SPECIFIER_UNGROUP)
		    index++;
		  if (format[index] == QUALIFIER_MINUS)
		    index++;
		  /* Skip nested brackets */
		  while (format[index] != NIL)
		    {
		      if (format[index] == SPECIFIER_GROUP)
			{
			  depth++;
			}
		      else if (format[index] == SPECIFIER_UNGROUP)
			{
			  if (--depth <= 0)
			    {
			      index++;
			      break;
			    }
			}
		      index++;
		    }
		}
	      break;

	    case SPECIFIER_INTEGER:
	      parameters[pos].type = FORMAT_INT;
	      break;

	    case SPECIFIER_UNSIGNED:
	      flags |= FLAGS_UNSIGNED;
	      parameters[pos].type = FORMAT_INT;
	      break;

	    case SPECIFIER_DECIMAL:
	      /* Disable base modifier */
	      flags &= ~FLAGS_BASE_PARAMETER;
	      base = BASE_DECIMAL;
	      parameters[pos].type = FORMAT_INT;
	      break;

	    case SPECIFIER_OCTAL:
	      flags |= FLAGS_UNSIGNED;
	      flags &= ~FLAGS_BASE_PARAMETER;
	      base = BASE_OCTAL;
	      parameters[pos].type = FORMAT_INT;
	      break;

#if defined(SPECIFIER_BINARY)
	    case SPECIFIER_BINARY_UPPER:
	      flags |= FLAGS_UPPER;
	      /* FALLTHROUGH */
	    case SPECIFIER_BINARY:
	      flags |= FLAGS_NILPADDING;
	      flags &= ~FLAGS_BASE_PARAMETER;
	      base = BASE_BINARY;
	      parameters[pos].type = FORMAT_INT;
	      break;
#endif

	    case SPECIFIER_HEX_UPPER:
	      flags |= FLAGS_UPPER;
	      /* FALLTHROUGH */
	    case SPECIFIER_HEX:
	      flags |= FLAGS_UNSIGNED;
	      flags &= ~FLAGS_BASE_PARAMETER;
	      base = BASE_HEX;
	      parameters[pos].type = FORMAT_INT;
	      break;

	    case SPECIFIER_FLOAT_E_UPPER:
	      flags |= FLAGS_UPPER;
	      /* FALLTHROUGH */
	    case SPECIFIER_FLOAT_E:
	      flags |= FLAGS_FLOAT_E;
	      parameters[pos].type = FORMAT_DOUBLE;
	      break;

	    case SPECIFIER_FLOAT_G_UPPER:
	      flags |= FLAGS_UPPER;
	      /* FALLTHROUGH */
	    case SPECIFIER_FLOAT_G:
	      flags |= FLAGS_FLOAT_G;
	      parameters[pos].type = FORMAT_DOUBLE;
	      break;

	    case SPECIFIER_FLOAT_F_UPPER:
	      flags |= FLAGS_UPPER;
	      /* FALLTHROUGH */
	    case SPECIFIER_FLOAT_F:
	      parameters[pos].type = FORMAT_DOUBLE;
	      break;

	    case SPECIFIER_POINTER:
	      if (sizeof(trio_pointer_t) == sizeof(trio_ulonglong_t))
		flags |= FLAGS_QUAD;
	      else if (sizeof(trio_pointer_t) == sizeof(long))
		flags |= FLAGS_LONG;
	      parameters[pos].type = FORMAT_POINTER;
	      break;

	    case SPECIFIER_COUNT:
	      parameters[pos].type = FORMAT_COUNT;
	      break;

#if defined(SPECIFIER_HEXFLOAT)
# if defined(SPECIFIER_HEXFLOAT_UPPER)
	    case SPECIFIER_HEXFLOAT_UPPER:
	      flags |= FLAGS_UPPER;
	      /* FALLTHROUGH */
# endif
	    case SPECIFIER_HEXFLOAT:
	      base = BASE_HEX;
	      parameters[pos].type = FORMAT_DOUBLE;
	      break;
#endif

#if defined(FORMAT_ERRNO)
	    case SPECIFIER_ERRNO:
	      parameters[pos].type = FORMAT_ERRNO;
	      break;
#endif

#if defined(SPECIFIER_USER_DEFINED_BEGIN)
	    case SPECIFIER_USER_DEFINED_BEGIN:
	      {
		unsigned int max;
		int without_namespace = TRUE;

		parameters[pos].type = FORMAT_USER_DEFINED;
		parameters[pos].user_name[0] = NIL;
		tmpformat = (char *)&format[index];

		while ((ch = format[index]))
		  {
		    index++;
		    if (ch == SPECIFIER_USER_DEFINED_END)
		      {
			if (without_namespace)
			  {
			    /* We must get the handle first */
			    parameters[pos].type = FORMAT_PARAMETER;
			    parameters[pos].indexAfterSpecifier = index;
			    parameters[pos].flags = FLAGS_USER_DEFINED;
			    /* Adjust parameters for insertion of new one */
			    pos++;
			    usedEntries[currentParam] += 1;
			    parameters[pos].type = FORMAT_USER_DEFINED;
			    currentParam++;
			    indices[currentParam] = pos;
			    if (currentParam > maxParam)
			      maxParam = currentParam;
			  }
			/* Copy the user data */
			max = (unsigned int)(&format[index] - tmpformat);
			if (max > MAX_USER_DATA)
			  max = MAX_USER_DATA;
			trio_copy_max(parameters[pos].user_data,
				      max,
				      tmpformat);
			break; /* while */
		      }
		    if (ch == SPECIFIER_USER_DEFINED_SEPARATOR)
		      {
			without_namespace = FALSE;
			/* Copy the namespace for later looking-up */
			max = (int)(&format[index] - tmpformat);
			if (max > MAX_USER_NAME)
			  max = MAX_USER_NAME;
			trio_copy_max(parameters[pos].user_name,
				      max,
				      tmpformat);
			tmpformat = (char *)&format[index];
		      }
		  }
		if (ch != SPECIFIER_USER_DEFINED_END)
		  return TRIO_ERROR_RETURN(TRIO_EINVAL, index);
	      }
	      break;
#endif /* defined(SPECIFIER_USER_DEFINED_BEGIN) */

	    default:
	      /* Bail out completely to make the error more obvious */
              return TRIO_ERROR_RETURN(TRIO_EINVAL, index);
	    }

	  /*  Count the number of times this entry has been used */
	  usedEntries[currentParam] += 1;

	  /* Find last sticky parameters */
	  if (gotSticky && !(flags & FLAGS_STICKY))
	    {
	      for (i = pos - 1; i >= 0; i--)
		{
		  if (parameters[i].type == FORMAT_PARAMETER)
		    continue;
		  if ((parameters[i].flags & FLAGS_STICKY) &&
		      (parameters[i].type == parameters[pos].type))
		    {
		      /* Do not overwrite current qualifiers */
		      flags |= (parameters[i].flags & (unsigned long)~FLAGS_STICKY);
		      if (width == NO_WIDTH)
			width = parameters[i].width;
		      if (precision == NO_PRECISION)
			precision = parameters[i].precision;
		      if (base == NO_BASE)
			base = parameters[i].base;
		      break;
		    }
		}
	    }

	  parameters[pos].indexAfterSpecifier = index;
	  parameters[pos].flags = flags;
	  parameters[pos].width = width;
	  parameters[pos].precision = precision;
	  parameters[pos].base = (base == NO_BASE) ? BASE_DECIMAL : base;
	  parameters[pos].varsize = varsize;
	  pos++;

	  if (! positional)
	    parameterPosition++;

	} /* if identifier */

    } /* while format characters left */

  for (num = 0; num <= maxParam; num++)
    {
      if (usedEntries[num] != 1)
	{
	  if (usedEntries[num] == 0) /* gap detected */
	    return TRIO_ERROR_RETURN(TRIO_EGAP, num);
	  else /* double references detected */
	    return TRIO_ERROR_RETURN(TRIO_EDBLREF, num);
	}

      i = indices[num];

      /*
       * FORMAT_PARAMETERS are only present if they must be read,
       * so it makes no sense to check the ignore flag (besides,
       * the flags variable is not set for that particular type)
       */
      if ((parameters[i].type != FORMAT_PARAMETER) &&
	  (parameters[i].flags & FLAGS_IGNORE))
	continue; /* for all arguments */

      /*
       * The stack arguments are read according to ANSI C89
       * default argument promotions:
       *
       *  char           = int
       *  short          = int
       *  unsigned char  = unsigned int
       *  unsigned short = unsigned int
       *  float          = double
       *
       * In addition to the ANSI C89 these types are read (the
       * default argument promotions of C99 has not been
       * considered yet)
       *
       *  long long
       *  long double
       *  size_t
       *  ptrdiff_t
       *  intmax_t
       */
      switch (parameters[i].type)
	{
	case FORMAT_GROUP:
	case FORMAT_STRING:
#if TRIO_WIDECHAR
	  if (flags & FLAGS_WIDECHAR)
	    {
	      parameters[i].data.wstring = (argarray == NULL)
		? va_arg(TRIO_VA_LIST_DEREF(arglist), trio_wchar_t *)
		: (trio_wchar_t *)(argarray[num]);
	    }
	  else
#endif
	    {
	      parameters[i].data.string = (argarray == NULL)
		? va_arg(TRIO_VA_LIST_DEREF(arglist), char *)
		: (char *)(argarray[num]);
	    }
	  break;

#if defined(FORMAT_USER_DEFINED)
	case FORMAT_USER_DEFINED:
#endif
	case FORMAT_POINTER:
	case FORMAT_COUNT:
	case FORMAT_UNKNOWN:
	  parameters[i].data.pointer = (argarray == NULL)
	    ? va_arg(TRIO_VA_LIST_DEREF(arglist), trio_pointer_t )
	    : argarray[num];
	  break;

	case FORMAT_CHAR:
	case FORMAT_INT:
	  if (TYPE_SCAN == type)
	    {
              if (argarray == NULL)
                parameters[i].data.pointer =
                  (trio_pointer_t)va_arg(TRIO_VA_LIST_DEREF(arglist), trio_pointer_t);
              else
                {
                  if (parameters[i].type == FORMAT_CHAR)
                    parameters[i].data.pointer =
                      (trio_pointer_t)((char *)argarray[num]);
                  else if (parameters[i].flags & FLAGS_SHORT)
                    parameters[i].data.pointer =
                      (trio_pointer_t)((short *)argarray[num]);
                  else
                    parameters[i].data.pointer =
                      (trio_pointer_t)((int *)argarray[num]);
                }
	    }
	  else
	    {
#if defined(QUALIFIER_VARSIZE) || defined(QUALIFIER_FIXED_SIZE)
	      if (parameters[i].flags
		  & (FLAGS_VARSIZE_PARAMETER | FLAGS_FIXED_SIZE))
		{
		  if (parameters[i].flags & FLAGS_VARSIZE_PARAMETER)
		    {
		      /*
		       * Variable sizes are mapped onto the fixed sizes, in
		       * accordance with integer promotion.
		       *
		       * Please note that this may not be portable, as we
		       * only guess the size, not the layout of the numbers.
		       * For example, if int is little-endian, and long is
		       * big-endian, then this will fail.
		       */
		      varsize = (int)parameters[parameters[i].varsize].data.number.as_unsigned;
		    }
		  else
		    {
		      /* Used for the I<bits> modifiers */
		      varsize = parameters[i].varsize;
		    }
		  parameters[i].flags &= ~FLAGS_ALL_VARSIZES;

		  if (varsize <= (int)sizeof(int))
		    ;
		  else if (varsize <= (int)sizeof(long))
		    parameters[i].flags |= FLAGS_LONG;
#if defined(QUALIFIER_INTMAX_T)
		  else if (varsize <= (int)sizeof(trio_longlong_t))
		    parameters[i].flags |= FLAGS_QUAD;
		  else
		    parameters[i].flags |= FLAGS_INTMAX_T;
#else
		  else
		    parameters[i].flags |= FLAGS_QUAD;
#endif
		}
#endif /* defined(QUALIFIER_VARSIZE) */
#if defined(QUALIFIER_SIZE_T) || defined(QUALIFIER_SIZE_T_UPPER)
	      if (parameters[i].flags & FLAGS_SIZE_T)
		parameters[i].data.number.as_unsigned = (argarray == NULL)
		  ? (trio_uintmax_t)va_arg(TRIO_VA_LIST_DEREF(arglist), size_t)
		  : (trio_uintmax_t)(*((size_t *)argarray[num]));
	      else
#endif
#if defined(QUALIFIER_PTRDIFF_T)
	      if (parameters[i].flags & FLAGS_PTRDIFF_T)
		parameters[i].data.number.as_unsigned = (argarray == NULL)
		  ? (trio_uintmax_t)va_arg(TRIO_VA_LIST_DEREF(arglist), ptrdiff_t)
		  : (trio_uintmax_t)(*((ptrdiff_t *)argarray[num]));
	      else
#endif
#if defined(QUALIFIER_INTMAX_T)
	      if (parameters[i].flags & FLAGS_INTMAX_T)
		parameters[i].data.number.as_unsigned = (argarray == NULL)
		  ? (trio_uintmax_t)va_arg(TRIO_VA_LIST_DEREF(arglist), trio_intmax_t)
		  : (trio_uintmax_t)(*((trio_intmax_t *)argarray[num]));
	      else
#endif
	      if (parameters[i].flags & FLAGS_QUAD)
		parameters[i].data.number.as_unsigned = (argarray == NULL)
		  ? (trio_uintmax_t)va_arg(TRIO_VA_LIST_DEREF(arglist), trio_ulonglong_t)
		  : (trio_uintmax_t)(*((trio_ulonglong_t *)argarray[num]));
	      else if (parameters[i].flags & FLAGS_LONG)
		parameters[i].data.number.as_unsigned = (argarray == NULL)
		  ? (trio_uintmax_t)va_arg(TRIO_VA_LIST_DEREF(arglist), long)
		  : (trio_uintmax_t)(*((long *)argarray[num]));
	      else
		{
		  if (argarray == NULL)
		    parameters[i].data.number.as_unsigned = (trio_uintmax_t)va_arg(TRIO_VA_LIST_DEREF(arglist), int);
		  else
		    {
		      if (parameters[i].type == FORMAT_CHAR)
			parameters[i].data.number.as_unsigned = (trio_uintmax_t)(*((char *)argarray[num]));
		      else if (parameters[i].flags & FLAGS_SHORT)
			parameters[i].data.number.as_unsigned = (trio_uintmax_t)(*((short *)argarray[num]));
		      else
			parameters[i].data.number.as_unsigned = (trio_uintmax_t)(*((int *)argarray[num]));
		    }
		}
	    }
	  break;

	case FORMAT_PARAMETER:
	  /*
	   * The parameter for the user-defined specifier is a pointer,
	   * whereas the rest (width, precision, base) uses an integer.
	   */
	  if (parameters[i].flags & FLAGS_USER_DEFINED)
	    parameters[i].data.pointer = (argarray == NULL)
	      ? va_arg(TRIO_VA_LIST_DEREF(arglist), trio_pointer_t )
	      : argarray[num];
	  else
	    parameters[i].data.number.as_unsigned = (argarray == NULL)
	      ? (trio_uintmax_t)va_arg(TRIO_VA_LIST_DEREF(arglist), int)
	      : (trio_uintmax_t)(*((int *)argarray[num]));
	  break;

	case FORMAT_DOUBLE:
	  if (TYPE_SCAN == type)
	    {
	      if (parameters[i].flags & FLAGS_LONGDOUBLE)
		parameters[i].data.longdoublePointer = (argarray == NULL)
		  ? va_arg(TRIO_VA_LIST_DEREF(arglist), trio_long_double_t *)
		  : (trio_long_double_t *)argarray[num];
	      else
                {
		  if (parameters[i].flags & FLAGS_LONG)
		    parameters[i].data.doublePointer = (argarray == NULL)
		      ? va_arg(TRIO_VA_LIST_DEREF(arglist), double *)
		      : (double *)argarray[num];
		  else
		    parameters[i].data.doublePointer = (argarray == NULL)
		      ? (double *)va_arg(TRIO_VA_LIST_DEREF(arglist), float *)
		      : (double *)((float *)argarray[num]);
                }
	    }
	  else
	    {
	      if (parameters[i].flags & FLAGS_LONGDOUBLE)
		parameters[i].data.longdoubleNumber = (argarray == NULL)
		  ? va_arg(TRIO_VA_LIST_DEREF(arglist), trio_long_double_t)
		  : (trio_long_double_t)(*((trio_long_double_t *)argarray[num]));
	      else
		{
		  if (argarray == NULL)
		    parameters[i].data.longdoubleNumber =
		      (trio_long_double_t)va_arg(TRIO_VA_LIST_DEREF(arglist), double);
		  else
		    {
		      if (parameters[i].flags & FLAGS_SHORT)
			parameters[i].data.longdoubleNumber =
			  (trio_long_double_t)(*((float *)argarray[num]));
		      else
			parameters[i].data.longdoubleNumber =
			  (trio_long_double_t)(*((double *)argarray[num]));
		    }
		}
	    }
	  break;

#if defined(FORMAT_ERRNO)
	case FORMAT_ERRNO:
	  parameters[i].data.errorNumber = save_errno;
	  break;
#endif

	default:
	  break;
	}
    } /* for all specifiers */
  return num;
}


/*************************************************************************
 *
 * FORMATTING
 *
 ************************************************************************/


/*************************************************************************
 * TrioWriteNumber
 *
 * Description:
 *  Output a number.
 *  The complexity of this function is a result of the complexity
 *  of the dependencies of the flags.
 */
TRIO_PRIVATE void
TrioWriteNumber
TRIO_ARGS6((self, number, flags, width, precision, base),
	   trio_class_t *self,
	   trio_uintmax_t number,
	   trio_flags_t flags,
	   int width,
	   int precision,
	   int base)
{
  BOOLEAN_T isNegative;
  BOOLEAN_T isNumberZero;
  BOOLEAN_T isPrecisionZero;
  BOOLEAN_T ignoreNumber;
  char buffer[MAX_CHARS_IN(trio_uintmax_t) * (1 + MAX_LOCALE_SEPARATOR_LENGTH) + 1];
  char *bufferend;
  char *pointer;
  TRIO_CONST char *digits;
  int i;
  int length;
  char *p;
  int count;

  assert(VALID(self));
  assert(VALID(self->OutStream));
  assert(((base >= MIN_BASE) && (base <= MAX_BASE)) || (base == NO_BASE));

  digits = (flags & FLAGS_UPPER) ? internalDigitsUpper : internalDigitsLower;
  if (base == NO_BASE)
    base = BASE_DECIMAL;

  isNumberZero = (number == 0);
  isPrecisionZero = (precision == 0);
  ignoreNumber = (isNumberZero
		  && isPrecisionZero
		  && !((flags & FLAGS_ALTERNATIVE) && (base == BASE_OCTAL)));

  if (flags & FLAGS_UNSIGNED)
    {
      isNegative = FALSE;
      flags &= ~FLAGS_SHOWSIGN;
    }
  else
    {
      isNegative = ((trio_intmax_t)number < 0);
      if (isNegative)
	number = -((trio_intmax_t)number);
    }

  if (flags & FLAGS_QUAD)
    number &= (trio_ulonglong_t)-1;
  else if (flags & FLAGS_LONG)
    number &= (unsigned long)-1;
  else
    number &= (unsigned int)-1;

  /* Build number */
  pointer = bufferend = &buffer[sizeof(buffer) - 1];
  *pointer-- = NIL;
  for (i = 1; i < (int)sizeof(buffer); i++)
    {
      *pointer-- = digits[number % base];
      number /= base;
      if (number == 0)
	break;

      if ((flags & FLAGS_QUOTE) && TrioFollowedBySeparator(i + 1))
	{
	  /*
	   * We are building the number from the least significant
	   * to the most significant digit, so we have to copy the
	   * thousand separator backwards
	   */
	  length = internalThousandSeparatorLength;
	  if (((int)(pointer - buffer) - length) > 0)
	    {
	      p = &internalThousandSeparator[length - 1];
	      while (length-- > 0)
		*pointer-- = *p--;
	    }
	}
    }

  if (! ignoreNumber)
    {
      /* Adjust width */
      width -= (bufferend - pointer) - 1;
    }

  /* Adjust precision */
  if (NO_PRECISION != precision)
    {
      precision -= (bufferend - pointer) - 1;
      if (precision < 0)
	precision = 0;
      flags |= FLAGS_NILPADDING;
    }

  /* Calculate padding */
  count = (! ((flags & FLAGS_LEFTADJUST) || (precision == NO_PRECISION)))
    ? precision
    : 0;

  /* Adjust width further */
  if (isNegative || (flags & FLAGS_SHOWSIGN) || (flags & FLAGS_SPACE))
    width--;
  if ((flags & FLAGS_ALTERNATIVE) && !isNumberZero)
    {
      switch (base)
	{
	case BASE_BINARY:
	case BASE_HEX:
	  width -= 2;
	  break;
	case BASE_OCTAL:
	  if (!(flags & FLAGS_NILPADDING) || (count == 0))
	    width--;
	  break;
	default:
	  break;
	}
    }

  /* Output prefixes spaces if needed */
  if (! ((flags & FLAGS_LEFTADJUST) ||
	 ((flags & FLAGS_NILPADDING) && (precision == NO_PRECISION))))
    {
      while (width-- > count)
	self->OutStream(self, CHAR_ADJUST);
    }

  /* width has been adjusted for signs and alternatives */
  if (isNegative)
    self->OutStream(self, '-');
  else if (flags & FLAGS_SHOWSIGN)
    self->OutStream(self, '+');
  else if (flags & FLAGS_SPACE)
    self->OutStream(self, ' ');

  /* Prefix is not written when the value is zero */
  if ((flags & FLAGS_ALTERNATIVE) && !isNumberZero)
    {
      switch (base)
	{
	case BASE_BINARY:
	  self->OutStream(self, '0');
	  self->OutStream(self, (flags & FLAGS_UPPER) ? 'B' : 'b');
	  break;

	case BASE_OCTAL:
	  if (!(flags & FLAGS_NILPADDING) || (count == 0))
	    self->OutStream(self, '0');
	  break;

	case BASE_HEX:
	  self->OutStream(self, '0');
	  self->OutStream(self, (flags & FLAGS_UPPER) ? 'X' : 'x');
	  break;

	default:
	  break;
	} /* switch base */
    }

  /* Output prefixed zero padding if needed */
  if (flags & FLAGS_NILPADDING)
    {
      if (precision == NO_PRECISION)
	precision = width;
      while (precision-- > 0)
	{
	  self->OutStream(self, '0');
	  width--;
	}
    }

  if (! ignoreNumber)
    {
      /* Output the number itself */
      while (*(++pointer))
	{
	  self->OutStream(self, *pointer);
	}
    }

  /* Output trailing spaces if needed */
  if (flags & FLAGS_LEFTADJUST)
    {
      while (width-- > 0)
	self->OutStream(self, CHAR_ADJUST);
    }
}

/*************************************************************************
 * TrioWriteStringCharacter
 *
 * Description:
 *  Output a single character of a string
 */
TRIO_PRIVATE void
TrioWriteStringCharacter
TRIO_ARGS3((self, ch, flags),
	   trio_class_t *self,
	   int ch,
	   trio_flags_t flags)
{
  if (flags & FLAGS_ALTERNATIVE)
    {
      if (! isprint(ch))
	{
	  /*
	   * Non-printable characters are converted to C escapes or
	   * \number, if no C escape exists.
	   */
	  self->OutStream(self, CHAR_BACKSLASH);
	  switch (ch)
	    {
	    case '\007': self->OutStream(self, 'a'); break;
	    case '\b': self->OutStream(self, 'b'); break;
	    case '\f': self->OutStream(self, 'f'); break;
	    case '\n': self->OutStream(self, 'n'); break;
	    case '\r': self->OutStream(self, 'r'); break;
	    case '\t': self->OutStream(self, 't'); break;
	    case '\v': self->OutStream(self, 'v'); break;
	    case '\\': self->OutStream(self, '\\'); break;
	    default:
	      self->OutStream(self, 'x');
	      TrioWriteNumber(self, (trio_uintmax_t)ch,
			      FLAGS_UNSIGNED | FLAGS_NILPADDING,
			      2, 2, BASE_HEX);
	      break;
	    }
	}
      else if (ch == CHAR_BACKSLASH)
	{
	  self->OutStream(self, CHAR_BACKSLASH);
	  self->OutStream(self, CHAR_BACKSLASH);
	}
      else
	{
	  self->OutStream(self, ch);
	}
    }
  else
    {
      self->OutStream(self, ch);
    }
}

/*************************************************************************
 * TrioWriteString
 *
 * Description:
 *  Output a string
 */
TRIO_PRIVATE void
TrioWriteString
TRIO_ARGS5((self, string, flags, width, precision),
	   trio_class_t *self,
	   TRIO_CONST char *string,
	   trio_flags_t flags,
	   int width,
	   int precision)
{
  int length;
  int ch;

  assert(VALID(self));
  assert(VALID(self->OutStream));

  if (string == NULL)
    {
      string = internalNullString;
      length = sizeof(internalNullString) - 1;
      /* Disable quoting for the null pointer */
      flags &= (~FLAGS_QUOTE);
      width = 0;
    }
  else
    {
      length = trio_length(string);
    }
  if ((NO_PRECISION != precision) &&
      (precision < length))
    {
      length = precision;
    }
  width -= length;

  if (flags & FLAGS_QUOTE)
    self->OutStream(self, CHAR_QUOTE);

  if (! (flags & FLAGS_LEFTADJUST))
    {
      while (width-- > 0)
	self->OutStream(self, CHAR_ADJUST);
    }

  while (length-- > 0)
    {
      /* The ctype parameters must be an unsigned char (or EOF) */
      ch = (int)((unsigned char)(*string++));
      TrioWriteStringCharacter(self, ch, flags);
    }

  if (flags & FLAGS_LEFTADJUST)
    {
      while (width-- > 0)
	self->OutStream(self, CHAR_ADJUST);
    }
  if (flags & FLAGS_QUOTE)
    self->OutStream(self, CHAR_QUOTE);
}

/*************************************************************************
 * TrioWriteWideStringCharacter
 *
 * Description:
 *  Output a wide string as a multi-byte sequence
 */
#if TRIO_WIDECHAR
TRIO_PRIVATE int
TrioWriteWideStringCharacter
TRIO_ARGS4((self, wch, flags, width),
	   trio_class_t *self,
	   trio_wchar_t wch,
	   trio_flags_t flags,
	   int width)
{
  int size;
  int i;
  int ch;
  char *string;
  char buffer[MB_LEN_MAX + 1];

  if (width == NO_WIDTH)
    width = sizeof(buffer);

  size = wctomb(buffer, wch);
  if ((size <= 0) || (size > width) || (buffer[0] == NIL))
    return 0;

  string = buffer;
  i = size;
  while ((width >= i) && (width-- > 0) && (i-- > 0))
    {
      /* The ctype parameters must be an unsigned char (or EOF) */
      ch = (int)((unsigned char)(*string++));
      TrioWriteStringCharacter(self, ch, flags);
    }
  return size;
}
#endif /* TRIO_WIDECHAR */

/*************************************************************************
 * TrioWriteWideString
 *
 * Description:
 *  Output a wide character string as a multi-byte string
 */
#if TRIO_WIDECHAR
TRIO_PRIVATE void
TrioWriteWideString
TRIO_ARGS5((self, wstring, flags, width, precision),
	   trio_class_t *self,
	   TRIO_CONST trio_wchar_t *wstring,
	   trio_flags_t flags,
	   int width,
	   int precision)
{
  int length;
  int size;

  assert(VALID(self));
  assert(VALID(self->OutStream));

#if defined(TRIO_COMPILER_SUPPORTS_MULTIBYTE)
  (void)mblen(NULL, 0);
#endif

  if (wstring == NULL)
    {
      TrioWriteString(self, NULL, flags, width, precision);
      return;
    }

  if (NO_PRECISION == precision)
    {
      length = INT_MAX;
    }
  else
    {
      length = precision;
      width -= length;
    }

  if (flags & FLAGS_QUOTE)
    self->OutStream(self, CHAR_QUOTE);

  if (! (flags & FLAGS_LEFTADJUST))
    {
      while (width-- > 0)
	self->OutStream(self, CHAR_ADJUST);
    }

  while (length > 0)
    {
      size = TrioWriteWideStringCharacter(self, *wstring++, flags, length);
      if (size == 0)
	break; /* while */
      length -= size;
    }

  if (flags & FLAGS_LEFTADJUST)
    {
      while (width-- > 0)
	self->OutStream(self, CHAR_ADJUST);
    }
  if (flags & FLAGS_QUOTE)
    self->OutStream(self, CHAR_QUOTE);
}
#endif /* TRIO_WIDECHAR */

/*************************************************************************
 * TrioWriteDouble
 *
 * http://wwwold.dkuug.dk/JTC1/SC22/WG14/www/docs/dr_211.htm
 *
 * "5.2.4.2.2 paragraph #4
 *
 *  The accuracy [...] is implementation defined, as is the accuracy
 *  of the conversion between floating-point internal representations
 *  and string representations performed by the libray routine in
 *  <stdio.h>"
 */
/* FIXME: handle all instances of constant long-double number (L)
 *   and *l() math functions.
 */
TRIO_PRIVATE void
TrioWriteDouble
TRIO_ARGS6((self, number, flags, width, precision, base),
	   trio_class_t *self,
	   trio_long_double_t number,
	   trio_flags_t flags,
	   int width,
	   int precision,
	   int base)
{
  trio_long_double_t integerNumber;
  trio_long_double_t fractionNumber;
  trio_long_double_t workNumber;
  int integerDigits;
  int fractionDigits;
  int exponentDigits;
  int baseDigits;
  int integerThreshold;
  int fractionThreshold;
  int expectedWidth;
  int exponent = 0;
  unsigned int uExponent = 0;
  int exponentBase;
  trio_long_double_t dblBase;
  trio_long_double_t dblIntegerBase;
  trio_long_double_t dblFractionBase;
  trio_long_double_t integerAdjust;
  trio_long_double_t fractionAdjust;
  BOOLEAN_T isNegative;
  BOOLEAN_T isExponentNegative = FALSE;
  BOOLEAN_T requireTwoDigitExponent;
  BOOLEAN_T isHex;
  TRIO_CONST char *digits;
  char *groupingPointer;
  int i;
  int index;
  BOOLEAN_T hasOnlyZeroes;
  int zeroes = 0;
  register int trailingZeroes;
  BOOLEAN_T keepTrailingZeroes;
  BOOLEAN_T keepDecimalPoint;
  trio_long_double_t epsilon;

  assert(VALID(self));
  assert(VALID(self->OutStream));
  assert(((base >= MIN_BASE) && (base <= MAX_BASE)) || (base == NO_BASE));

  /* Determine sign and look for special quantities */
  switch (trio_fpclassify_and_signbit(number, &isNegative))
    {
    case TRIO_FP_NAN:
      TrioWriteString(self,
		      (flags & FLAGS_UPPER)
		      ? NAN_UPPER
		      : NAN_LOWER,
		      flags, width, precision);
      return;

    case TRIO_FP_INFINITE:
      if (isNegative)
	{
	  /* Negative infinity */
	  TrioWriteString(self,
			  (flags & FLAGS_UPPER)
			  ? "-" INFINITE_UPPER
			  : "-" INFINITE_LOWER,
			  flags, width, precision);
	  return;
	}
      else
	{
	  /* Positive infinity */
	  TrioWriteString(self,
			  (flags & FLAGS_UPPER)
			  ? INFINITE_UPPER
			  : INFINITE_LOWER,
			  flags, width, precision);
	  return;
	}

    default:
      /* Finitude */
      break;
    }

  /* Normal numbers */
  if (flags & FLAGS_LONGDOUBLE)
    {
      baseDigits = (base == 10)
	? LDBL_DIG
	: (int)floor(LDBL_MANT_DIG / TrioLogarithmBase(base));
      epsilon = LDBL_EPSILON;
    }
  else if (flags & FLAGS_SHORT)
    {
      baseDigits = (base == BASE_DECIMAL)
	? FLT_DIG
	: (int)floor(FLT_MANT_DIG / TrioLogarithmBase(base));
      epsilon = FLT_EPSILON;
    }
  else
    {
      baseDigits = (base == BASE_DECIMAL)
	? DBL_DIG
	: (int)floor(DBL_MANT_DIG / TrioLogarithmBase(base));
      epsilon = DBL_EPSILON;
    }

  digits = (flags & FLAGS_UPPER) ? internalDigitsUpper : internalDigitsLower;
  isHex = (base == BASE_HEX);
  if (base == NO_BASE)
    base = BASE_DECIMAL;
  dblBase = (trio_long_double_t)base;
  keepTrailingZeroes = !( (flags & FLAGS_ROUNDING) ||
			  ( (flags & FLAGS_FLOAT_G) &&
			    !(flags & FLAGS_ALTERNATIVE) ) );

  if (flags & FLAGS_ROUNDING)
    precision = baseDigits;

  if (precision == NO_PRECISION)
    {
      if (isHex)
	{
	  keepTrailingZeroes = FALSE;
	  precision = FLT_MANT_DIG;
	}
      else
	{
	  precision = FLT_DIG;
	}
    }

  if (isNegative)
    number = -number;

  if (isHex)
    flags |= FLAGS_FLOAT_E;

  if (flags & FLAGS_FLOAT_G)
    {
      if (precision == 0)
	precision = 1;

      if ((number < 1.0E-4) || (number > powl(base,
					      (trio_long_double_t)precision)))
	{
	  /* Use scientific notation */
	  flags |= FLAGS_FLOAT_E;
	}
      else if (number < 1.0)
	{
	  /*
	   * Use normal notation. If the integer part of the number is
	   * zero, then adjust the precision to include leading fractional
	   * zeros.
	   */
	  workNumber = TrioLogarithm(number, base);
	  workNumber = TRIO_FABS(workNumber);
	  if (workNumber - floorl(workNumber) < 0.001)
	    workNumber--;
	  zeroes = (int)floorl(workNumber);
	}
    }

  if (flags & FLAGS_FLOAT_E)
    {
      /* Scale the number */
      workNumber = TrioLogarithm(number, base);
      if (trio_isinf(workNumber) == -1)
	{
	  exponent = 0;
	  /* Undo setting */
	  if (flags & FLAGS_FLOAT_G)
	    flags &= ~FLAGS_FLOAT_E;
	}
      else
	{
	  exponent = (int)floorl(workNumber);
	  number /= powl(dblBase, (trio_long_double_t)exponent);
	  isExponentNegative = (exponent < 0);
	  uExponent = (isExponentNegative) ? -exponent : exponent;
	  if (isHex)
	    uExponent *= 4; /* log16(2) */
	  /* No thousand separators */
	  flags &= ~FLAGS_QUOTE;
	}
    }

  integerNumber = floorl(number);
  fractionNumber = number - integerNumber;

  /*
   * Truncated number.
   *
   * Precision is number of significant digits for FLOAT_G
   * and number of fractional digits for others.
   */
  integerDigits = (integerNumber > epsilon)
    ? 1 + (int)TrioLogarithm(integerNumber, base)
    : 1;
  fractionDigits = ((flags & FLAGS_FLOAT_G) && (zeroes == 0))
    ? precision - integerDigits
    : zeroes + precision;

  dblFractionBase = TrioPower(base, fractionDigits);

  workNumber = number + 0.5 / dblFractionBase;
  if (floorl(number) != floorl(workNumber))
    {
      if (flags & FLAGS_FLOAT_E)
	{
	  /* Adjust if number was rounded up one digit (ie. 0.99 to 1.00) */
	  exponent++;
	  isExponentNegative = (exponent < 0);
	  uExponent = (isExponentNegative) ? -exponent : exponent;
	  if (isHex)
	    uExponent *= 4; /* log16(2) */
	  workNumber = (number + 0.5 / dblFractionBase) / dblBase;
	  integerNumber = floorl(workNumber);
	  fractionNumber = workNumber - integerNumber;
	}
      else
	{
	  /* Adjust if number was rounded up one digit (ie. 99 to 100) */
	  integerNumber = floorl(number + 0.5);
	  fractionNumber = 0.0;
	  integerDigits = (integerNumber > epsilon)
	    ? 1 + (int)TrioLogarithm(integerNumber, base)
	    : 1;
	}
    }

  /* Estimate accuracy */
  integerAdjust = fractionAdjust = 0.5;
  if (flags & FLAGS_ROUNDING)
    {
      if (integerDigits > baseDigits)
	{
	  integerThreshold = baseDigits;
	  fractionDigits = 0;
	  dblFractionBase = 1.0;
	  fractionThreshold = 0;
	  precision = 0; /* Disable decimal-point */
	  integerAdjust = TrioPower(base, integerDigits - integerThreshold - 1);
	  fractionAdjust = 0.0;
	}
      else
	{
	  integerThreshold = integerDigits;
	  fractionThreshold = fractionDigits - integerThreshold;
	  fractionAdjust = 1.0;
	}
    }
  else
    {
      integerThreshold = INT_MAX;
      fractionThreshold = INT_MAX;
    }

  /*
   * Calculate expected width.
   *  sign + integer part + thousands separators + decimal point
   *  + fraction + exponent
   */
  fractionAdjust /= dblFractionBase;
  hasOnlyZeroes = (floorl((fractionNumber + fractionAdjust) * dblFractionBase) < epsilon);
  keepDecimalPoint = ( (flags & FLAGS_ALTERNATIVE) ||
		       !((precision == 0) ||
			 (!keepTrailingZeroes && hasOnlyZeroes)) );
  if (flags & FLAGS_FLOAT_E)
    {
      exponentDigits = (uExponent == 0)
	? 1
	: (int)ceil(TrioLogarithm((double)(uExponent + 1),
				  (isHex) ? 10.0 : base));
    }
  else
    exponentDigits = 0;
  requireTwoDigitExponent = ((base == BASE_DECIMAL) && (exponentDigits == 1));

  expectedWidth = integerDigits + fractionDigits
    + (keepDecimalPoint
       ? internalDecimalPointLength
       : 0)
    + ((flags & FLAGS_QUOTE)
       ? TrioCalcThousandSeparatorLength(integerDigits)
       : 0);
  if (isNegative || (flags & FLAGS_SHOWSIGN) || (flags & FLAGS_SPACE))
    expectedWidth += sizeof("-") - 1;
  if (exponentDigits > 0)
    expectedWidth += exponentDigits +
      ((requireTwoDigitExponent ? sizeof("E+0") : sizeof("E+")) - 1);
  if (isHex)
    expectedWidth += sizeof("0X") - 1;

  /* Output prefixing */
  if (flags & FLAGS_NILPADDING)
    {
      /* Leading zeros must be after sign */
      if (isNegative)
	self->OutStream(self, '-');
      else if (flags & FLAGS_SHOWSIGN)
	self->OutStream(self, '+');
      else if (flags & FLAGS_SPACE)
	self->OutStream(self, ' ');
      if (isHex)
	{
	  self->OutStream(self, '0');
	  self->OutStream(self, (flags & FLAGS_UPPER) ? 'X' : 'x');
	}
      if (!(flags & FLAGS_LEFTADJUST))
	{
	  for (i = expectedWidth; i < width; i++)
	    {
	      self->OutStream(self, '0');
	    }
	}
    }
  else
    {
      /* Leading spaces must be before sign */
      if (!(flags & FLAGS_LEFTADJUST))
	{
	  for (i = expectedWidth; i < width; i++)
	    {
	      self->OutStream(self, CHAR_ADJUST);
	    }
	}
      if (isNegative)
	self->OutStream(self, '-');
      else if (flags & FLAGS_SHOWSIGN)
	self->OutStream(self, '+');
      else if (flags & FLAGS_SPACE)
	self->OutStream(self, ' ');
      if (isHex)
	{
	  self->OutStream(self, '0');
	  self->OutStream(self, (flags & FLAGS_UPPER) ? 'X' : 'x');
	}
    }

  /* Output the integer part and thousand separators */
  dblIntegerBase = 1.0 / TrioPower(base, integerDigits - 1);
  for (i = 0; i < integerDigits; i++)
    {
      workNumber = floorl(((integerNumber + integerAdjust) * dblIntegerBase));
      if (i > integerThreshold)
	{
	  /* Beyond accuracy */
	  self->OutStream(self, digits[0]);
	}
      else
	{
	  self->OutStream(self, digits[(int)fmodl(workNumber, dblBase)]);
	}
      dblIntegerBase *= dblBase;

      if (((flags & (FLAGS_FLOAT_E | FLAGS_QUOTE)) == FLAGS_QUOTE)
	  && TrioFollowedBySeparator(integerDigits - i))
	{
	  for (groupingPointer = internalThousandSeparator;
	       *groupingPointer != NIL;
	       groupingPointer++)
	    {
	      self->OutStream(self, *groupingPointer);
	    }
	}
    }

  /* Insert decimal point and build the fraction part */
  trailingZeroes = 0;

  if (keepDecimalPoint)
    {
      if (internalDecimalPoint)
	{
	  self->OutStream(self, internalDecimalPoint);
	}
      else
	{
	  for (i = 0; i < internalDecimalPointLength; i++)
	    {
	      self->OutStream(self, internalDecimalPointString[i]);
	    }
	}
    }

  for (i = 0; i < fractionDigits; i++)
    {
      if ((integerDigits > integerThreshold) || (i > fractionThreshold))
	{
	  /* Beyond accuracy */
	  trailingZeroes++;
	}
      else
	{
	  fractionNumber *= dblBase;
	  fractionAdjust *= dblBase;
	  workNumber = floorl(fractionNumber + fractionAdjust);
	  fractionNumber -= workNumber;
	  index = (int)fmodl(workNumber, dblBase);
	  if (index == 0)
	    {
	      trailingZeroes++;
	    }
	  else
	    {
	      while (trailingZeroes > 0)
		{
		  /* Not trailing zeroes after all */
		  self->OutStream(self, digits[0]);
		  trailingZeroes--;
		}
	      self->OutStream(self, digits[index]);
	    }
	}
    }

  if (keepTrailingZeroes)
    {
      while (trailingZeroes > 0)
	{
	  self->OutStream(self, digits[0]);
	  trailingZeroes--;
	}
    }

  /* Output exponent */
  if (exponentDigits > 0)
    {
      self->OutStream(self,
		      isHex
		      ? ((flags & FLAGS_UPPER) ? 'P' : 'p')
		      : ((flags & FLAGS_UPPER) ? 'E' : 'e'));
      self->OutStream(self, (isExponentNegative) ? '-' : '+');

      /* The exponent must contain at least two digits */
      if (requireTwoDigitExponent)
        self->OutStream(self, '0');

      if (isHex)
	base = 10.0;
      exponentBase = (int)TrioPower(base, exponentDigits - 1);
      for (i = 0; i < exponentDigits; i++)
	{
	  self->OutStream(self, digits[(uExponent / exponentBase) % base]);
	  exponentBase /= base;
	}
    }
  /* Output trailing spaces */
  if (flags & FLAGS_LEFTADJUST)
    {
      for (i = expectedWidth; i < width; i++)
	{
	  self->OutStream(self, CHAR_ADJUST);
	}
    }
}

/*************************************************************************
 * TrioFormatProcess
 *
 * Description:
 *  This is the main engine for formatting output
 */
TRIO_PRIVATE int
TrioFormatProcess
TRIO_ARGS3((data, format, parameters),
	   trio_class_t *data,
	   TRIO_CONST char *format,
	   trio_parameter_t *parameters)
{
#if defined(TRIO_COMPILER_SUPPORTS_MULTIBYTE)
  int charlen;
#endif
  int i;
  TRIO_CONST char *string;
  trio_pointer_t pointer;
  trio_flags_t flags;
  int width;
  int precision;
  int base;
  int index;

  index = 0;
  i = 0;
#if defined(TRIO_COMPILER_SUPPORTS_MULTIBYTE)
  (void)mblen(NULL, 0);
#endif

  while (format[index])
    {
#if defined(TRIO_COMPILER_SUPPORTS_MULTIBYTE)
      if (! isascii(format[index]))
	{
	  charlen = mblen(&format[index], MB_LEN_MAX);
	  /*
	   * Only valid multibyte characters are handled here. Invalid
	   * multibyte characters (charlen == -1) are handled as normal
	   * characters.
	   */
	  if (charlen != -1)
	    {
	      while (charlen-- > 0)
		{
		  data->OutStream(data, format[index++]);
		}
	      continue; /* while characters left in formatting string */
	    }
	}
#endif /* TRIO_COMPILER_SUPPORTS_MULTIBYTE */
      if (CHAR_IDENTIFIER == format[index])
	{
	  if (CHAR_IDENTIFIER == format[index + 1])
	    {
	      data->OutStream(data, CHAR_IDENTIFIER);
	      index += 2;
	    }
	  else
	    {
	      /* Skip the parameter entries */
	      while (parameters[i].type == FORMAT_PARAMETER)
		i++;

	      flags = parameters[i].flags;

	      /* Find width */
	      width = parameters[i].width;
	      if (flags & FLAGS_WIDTH_PARAMETER)
		{
		  /* Get width from parameter list */
		  width = (int)parameters[width].data.number.as_signed;
		  if (width < 0)
		    {
		      /*
		       * A negative width is the same as the - flag and
		       * a positive width.
		       */
		      flags |= FLAGS_LEFTADJUST;
		      flags &= ~FLAGS_NILPADDING;
		      width = -width;
		    }
		}

	      /* Find precision */
	      if (flags & FLAGS_PRECISION)
		{
		  precision = parameters[i].precision;
		  if (flags & FLAGS_PRECISION_PARAMETER)
		    {
		      /* Get precision from parameter list */
		      precision = (int)parameters[precision].data.number.as_signed;
		      if (precision < 0)
			{
			  /*
			   * A negative precision is the same as no
			   * precision
			   */
			  precision = NO_PRECISION;
			}
		    }
		}
	      else
		{
		  precision = NO_PRECISION;
		}

	      /* Find base */
	      base = parameters[i].base;
	      if (flags & FLAGS_BASE_PARAMETER)
		{
		  /* Get base from parameter list */
		  base = (int)parameters[base].data.number.as_signed;
		}

	      switch (parameters[i].type)
		{
		case FORMAT_CHAR:
		  if (flags & FLAGS_QUOTE)
		    data->OutStream(data, CHAR_QUOTE);
		  if (! (flags & FLAGS_LEFTADJUST))
		    {
		      while (--width > 0)
			data->OutStream(data, CHAR_ADJUST);
		    }
#if TRIO_WIDECHAR
		  if (flags & FLAGS_WIDECHAR)
		    {
		      TrioWriteWideStringCharacter(data,
						   (trio_wchar_t)parameters[i].data.number.as_signed,
						   flags,
						   NO_WIDTH);
		    }
		  else
#endif
		    {
		      TrioWriteStringCharacter(data,
					       (int)parameters[i].data.number.as_signed,
					       flags);
		    }

		  if (flags & FLAGS_LEFTADJUST)
		    {
		      while(--width > 0)
			data->OutStream(data, CHAR_ADJUST);
		    }
		  if (flags & FLAGS_QUOTE)
		    data->OutStream(data, CHAR_QUOTE);

		  break; /* FORMAT_CHAR */

		case FORMAT_INT:
		  TrioWriteNumber(data,
				  parameters[i].data.number.as_unsigned,
				  flags,
				  width,
				  precision,
				  base);

		  break; /* FORMAT_INT */

		case FORMAT_DOUBLE:
		  TrioWriteDouble(data,
				  parameters[i].data.longdoubleNumber,
				  flags,
				  width,
				  precision,
				  base);
		  break; /* FORMAT_DOUBLE */

		case FORMAT_STRING:
#if TRIO_WIDECHAR
		  if (flags & FLAGS_WIDECHAR)
		    {
		      TrioWriteWideString(data,
					  parameters[i].data.wstring,
					  flags,
					  width,
					  precision);
		    }
		  else
#endif
		    {
		      TrioWriteString(data,
				      parameters[i].data.string,
				      flags,
				      width,
				      precision);
		    }
		  break; /* FORMAT_STRING */

		case FORMAT_POINTER:
		  {
		    trio_reference_t reference;

		    reference.data = data;
		    reference.parameter = &parameters[i];
		    trio_print_pointer(&reference, parameters[i].data.pointer);
		  }
		  break; /* FORMAT_POINTER */

		case FORMAT_COUNT:
		  pointer = parameters[i].data.pointer;
		  if (NULL != pointer)
		    {
		      /*
		       * C99 paragraph 7.19.6.1.8 says "the number of
		       * characters written to the output stream so far by
		       * this call", which is data->committed
		       */
#if defined(QUALIFIER_SIZE_T) || defined(QUALIFIER_SIZE_T_UPPER)
		      if (flags & FLAGS_SIZE_T)
			*(size_t *)pointer = (size_t)data->committed;
		      else
#endif
#if defined(QUALIFIER_PTRDIFF_T)
		      if (flags & FLAGS_PTRDIFF_T)
			*(ptrdiff_t *)pointer = (ptrdiff_t)data->committed;
		      else
#endif
#if defined(QUALIFIER_INTMAX_T)
		      if (flags & FLAGS_INTMAX_T)
			*(trio_intmax_t *)pointer = (trio_intmax_t)data->committed;
		      else
#endif
		      if (flags & FLAGS_QUAD)
			{
			  *(trio_ulonglong_t *)pointer = (trio_ulonglong_t)data->committed;
			}
		      else if (flags & FLAGS_LONG)
			{
			  *(long int *)pointer = (long int)data->committed;
			}
		      else if (flags & FLAGS_SHORT)
			{
			  *(short int *)pointer = (short int)data->committed;
			}
		      else
			{
			  *(int *)pointer = (int)data->committed;
			}
		    }
		  break; /* FORMAT_COUNT */

		case FORMAT_PARAMETER:
		  break; /* FORMAT_PARAMETER */

#if defined(FORMAT_ERRNO)
		case FORMAT_ERRNO:
		  string = trio_error(parameters[i].data.errorNumber);
		  if (string)
		    {
		      TrioWriteString(data,
				      string,
				      flags,
				      width,
				      precision);
		    }
		  else
		    {
		      data->OutStream(data, '#');
		      TrioWriteNumber(data,
				      (trio_uintmax_t)parameters[i].data.errorNumber,
				      flags,
				      width,
				      precision,
				      BASE_DECIMAL);
		    }
		  break; /* FORMAT_ERRNO */
#endif /* defined(FORMAT_ERRNO) */

#if defined(FORMAT_USER_DEFINED)
		case FORMAT_USER_DEFINED:
		  {
		    trio_reference_t reference;
		    trio_userdef_t *def = NULL;

		    if (parameters[i].user_name[0] == NIL)
		      {
			/* Use handle */
			if ((i > 0) ||
			    (parameters[i - 1].type == FORMAT_PARAMETER))
			  def = (trio_userdef_t *)parameters[i - 1].data.pointer;
		      }
		    else
		      {
			/* Look up namespace */
			def = TrioFindNamespace(parameters[i].user_name, NULL);
		      }
		    if (def) {
		      reference.data = data;
		      reference.parameter = &parameters[i];
		      def->callback(&reference);
		    }
		  }
		  break;
#endif /* defined(FORMAT_USER_DEFINED) */

		default:
		  break;
		} /* switch parameter type */

	      /* Prepare for next */
	      index = parameters[i].indexAfterSpecifier;
	      i++;
	    }
	}
      else /* not identifier */
	{
	  data->OutStream(data, format[index++]);
	}
    }
  return data->processed;
}

/*************************************************************************
 * TrioFormatRef
 */
TRIO_PRIVATE int
TrioFormatRef
TRIO_ARGS4((reference, format, arglist, argarray),
	   trio_reference_t *reference,
	   TRIO_CONST char *format,
	   TRIO_VA_LIST_PTR arglist,
	   trio_pointer_t *argarray)
{
  int status;
  trio_parameter_t parameters[MAX_PARAMETERS];

  status = TrioParse(TYPE_PRINT, format, parameters, arglist, argarray);
  if (status < 0)
    return status;

  status = TrioFormatProcess(reference->data, format, parameters);
  if (reference->data->error != 0)
    {
      status = reference->data->error;
    }
  return status;
}

/*************************************************************************
 * TrioFormat
 */
TRIO_PRIVATE int
TrioFormat
TRIO_ARGS6((destination, destinationSize, OutStream, format, arglist, argarray),
	   trio_pointer_t destination,
	   size_t destinationSize,
	   void (*OutStream) TRIO_PROTO((trio_class_t *, int)),
	   TRIO_CONST char *format,
	   TRIO_VA_LIST_PTR arglist,
	   trio_pointer_t *argarray)
{
  int status;
  trio_class_t data;
  trio_parameter_t parameters[MAX_PARAMETERS];

  assert(VALID(OutStream));
  assert(VALID(format));

  memset(&data, 0, sizeof(data));
  data.OutStream = OutStream;
  data.location = destination;
  data.max = destinationSize;
  data.error = 0;

#if defined(USE_LOCALE)
  if (NULL == internalLocaleValues)
    {
      TrioSetLocale();
    }
#endif

  status = TrioParse(TYPE_PRINT, format, parameters, arglist, argarray);
  if (status < 0)
    return status;

  status = TrioFormatProcess(&data, format, parameters);
  if (data.error != 0)
    {
      status = data.error;
    }
  return status;
}

/*************************************************************************
 * TrioOutStreamFile
 */
TRIO_PRIVATE void
TrioOutStreamFile
TRIO_ARGS2((self, output),
	   trio_class_t *self,
	   int output)
{
  FILE *file;

  assert(VALID(self));
  assert(VALID(self->location));

  file = (FILE *)self->location;
  self->processed++;
  if (fputc(output, file) == EOF)
    {
      self->error = TRIO_ERROR_RETURN(TRIO_EOF, 0);
    }
  else
    {
      self->committed++;
    }
}

/*************************************************************************
 * TrioOutStreamFileDescriptor
 */
TRIO_PRIVATE void
TrioOutStreamFileDescriptor
TRIO_ARGS2((self, output),
	   trio_class_t *self,
	   int output)
{
  int fd;
  char ch;

  assert(VALID(self));

  fd = *((int *)self->location);
  ch = (char)output;
  self->processed++;
  if (write(fd, &ch, sizeof(char)) == -1)
    {
      self->error = TRIO_ERROR_RETURN(TRIO_ERRNO, 0);
    }
  else
    {
      self->committed++;
    }
}

/*************************************************************************
 * TrioOutStreamCustom
 */
TRIO_PRIVATE void
TrioOutStreamCustom
TRIO_ARGS2((self, output),
	   trio_class_t *self,
	   int output)
{
  int status;
  trio_custom_t *data;

  assert(VALID(self));
  assert(VALID(self->location));

  data = (trio_custom_t *)self->location;
  if (data->stream.out)
    {
      status = (data->stream.out)(data->closure, output);
      if (status >= 0)
	{
	  self->committed++;
	}
      else
	{
	  if (self->error == 0)
	    {
	      self->error = TRIO_ERROR_RETURN(TRIO_ECUSTOM, -status);
	    }
	}
    }
  self->processed++;
}

/*************************************************************************
 * TrioOutStreamString
 */
TRIO_PRIVATE void
TrioOutStreamString
TRIO_ARGS2((self, output),
	   trio_class_t *self,
	   int output)
{
  char **buffer;

  assert(VALID(self));
  assert(VALID(self->location));

  buffer = (char **)self->location;
  **buffer = (char)output;
  (*buffer)++;
  self->processed++;
  self->committed++;
}

/*************************************************************************
 * TrioOutStreamStringMax
 */
TRIO_PRIVATE void
TrioOutStreamStringMax
TRIO_ARGS2((self, output),
	   trio_class_t *self,
	   int output)
{
  char **buffer;

  assert(VALID(self));
  assert(VALID(self->location));

  buffer = (char **)self->location;

  if (self->processed < self->max)
    {
      **buffer = (char)output;
      (*buffer)++;
      self->committed++;
    }
  self->processed++;
}

/*************************************************************************
 * TrioOutStreamStringDynamic
 */
TRIO_PRIVATE void
TrioOutStreamStringDynamic
TRIO_ARGS2((self, output),
	   trio_class_t *self,
	   int output)
{
  assert(VALID(self));
  assert(VALID(self->location));

  if (self->error == 0)
    {
      trio_xstring_append_char((trio_string_t *)self->location,
			       (char)output);
      self->committed++;
    }
  /* The processed variable must always be increased */
  self->processed++;
}

/*************************************************************************
 *
 * Formatted printing functions
 *
 ************************************************************************/

#if defined(TRIO_DOCUMENTATION)
# include "doc/doc_printf.h"
#endif
/** @addtogroup Printf
    @{
*/

/*************************************************************************
 * printf
 */

/**
   Print to standard output stream.

   @param format Formatting string.
   @param ... Arguments.
   @return Number of printed characters.
 */
TRIO_PUBLIC int
trio_printf
TRIO_VARGS2((format, va_alist),
	    TRIO_CONST char *format,
	    TRIO_VA_DECL)
{
  int status;
  va_list args;

  assert(VALID(format));

  TRIO_VA_START(args, format);
  status = TrioFormat(stdout, 0, TrioOutStreamFile, format, TRIO_VA_LIST_ADDR(args), NULL);
  TRIO_VA_END(args);
  return status;
}

/**
   Print to standard output stream.

   @param format Formatting string.
   @param args Arguments.
   @return Number of printed characters.
 */
TRIO_PUBLIC int
trio_vprintf
TRIO_ARGS2((format, args),
	   TRIO_CONST char *format,
	   va_list args)
{
  assert(VALID(format));

  return TrioFormat(stdout, 0, TrioOutStreamFile, format, TRIO_VA_LIST_ADDR(args), NULL);
}

/**
   Print to standard output stream.

   @param format Formatting string.
   @param args Arguments.
   @return Number of printed characters.
 */
TRIO_PUBLIC int
trio_printfv
TRIO_ARGS2((format, args),
	   TRIO_CONST char *format,
	   trio_pointer_t * args)
{
  assert(VALID(format));

  return TrioFormat(stdout, 0, TrioOutStreamFile, format, NULL, args);
}

/*************************************************************************
 * fprintf
 */

/**
   Print to file.

   @param file File pointer.
   @param format Formatting string.
   @param ... Arguments.
   @return Number of printed characters.
 */
TRIO_PUBLIC int
trio_fprintf
TRIO_VARGS3((file, format, va_alist),
	    FILE *file,
	    TRIO_CONST char *format,
	    TRIO_VA_DECL)
{
  int status;
  va_list args;

  assert(VALID(file));
  assert(VALID(format));

  TRIO_VA_START(args, format);
  status = TrioFormat(file, 0, TrioOutStreamFile, format, TRIO_VA_LIST_ADDR(args), NULL);
  TRIO_VA_END(args);
  return status;
}

/**
   Print to file.

   @param file File pointer.
   @param format Formatting string.
   @param args Arguments.
   @return Number of printed characters.
 */
TRIO_PUBLIC int
trio_vfprintf
TRIO_ARGS3((file, format, args),
	   FILE *file,
	   TRIO_CONST char *format,
	   va_list args)
{
  assert(VALID(file));
  assert(VALID(format));

  return TrioFormat(file, 0, TrioOutStreamFile, format, TRIO_VA_LIST_ADDR(args), NULL);
}

/**
   Print to file.

   @param file File pointer.
   @param format Formatting string.
   @param args Arguments.
   @return Number of printed characters.
 */
TRIO_PUBLIC int
trio_fprintfv
TRIO_ARGS3((file, format, args),
	   FILE *file,
	   TRIO_CONST char *format,
	   trio_pointer_t * args)
{
  assert(VALID(file));
  assert(VALID(format));

  return TrioFormat(file, 0, TrioOutStreamFile, format, NULL, args);
}

/*************************************************************************
 * dprintf
 */

/**
   Print to file descriptor.

   @param fd File descriptor.
   @param format Formatting string.
   @param ... Arguments.
   @return Number of printed characters.
 */
TRIO_PUBLIC int
trio_dprintf
TRIO_VARGS3((fd, format, va_alist),
	    int fd,
	    TRIO_CONST char *format,
	    TRIO_VA_DECL)
{
  int status;
  va_list args;

  assert(VALID(format));

  TRIO_VA_START(args, format);
  status = TrioFormat(&fd, 0, TrioOutStreamFileDescriptor, format, TRIO_VA_LIST_ADDR(args), NULL);
  TRIO_VA_END(args);
  return status;
}

/**
   Print to file descriptor.

   @param fd File descriptor.
   @param format Formatting string.
   @param args Arguments.
   @return Number of printed characters.
 */
TRIO_PUBLIC int
trio_vdprintf
TRIO_ARGS3((fd, format, args),
	   int fd,
	   TRIO_CONST char *format,
	   va_list args)
{
  assert(VALID(format));

  return TrioFormat(&fd, 0, TrioOutStreamFileDescriptor, format, TRIO_VA_LIST_ADDR(args), NULL);
}

/**
   Print to file descriptor.

   @param fd File descriptor.
   @param format Formatting string.
   @param args Arguments.
   @return Number of printed characters.
 */
TRIO_PUBLIC int
trio_dprintfv
TRIO_ARGS3((fd, format, args),
	   int fd,
	   TRIO_CONST char *format,
	   trio_pointer_t *args)
{
  assert(VALID(format));

  return TrioFormat(&fd, 0, TrioOutStreamFileDescriptor, format, NULL, args);
}

/*************************************************************************
 * cprintf
 */
TRIO_PUBLIC int
trio_cprintf
TRIO_VARGS4((stream, closure, format, va_alist),
	    trio_outstream_t stream,
	    trio_pointer_t closure,
	    TRIO_CONST char *format,
	    TRIO_VA_DECL)
{
  int status;
  va_list args;
  trio_custom_t data;

  assert(VALID(stream));
  assert(VALID(format));

  TRIO_VA_START(args, format);
  data.stream.out = stream;
  data.closure = closure;
  status = TrioFormat(&data, 0, TrioOutStreamCustom, format, TRIO_VA_LIST_ADDR(args), NULL);
  TRIO_VA_END(args);
  return status;
}

TRIO_PUBLIC int
trio_vcprintf
TRIO_ARGS4((stream, closure, format, args),
	   trio_outstream_t stream,
	   trio_pointer_t closure,
	   TRIO_CONST char *format,
	   va_list args)
{
  trio_custom_t data;

  assert(VALID(stream));
  assert(VALID(format));

  data.stream.out = stream;
  data.closure = closure;
  return TrioFormat(&data, 0, TrioOutStreamCustom, format, TRIO_VA_LIST_ADDR(args), NULL);
}

TRIO_PUBLIC int
trio_cprintfv
TRIO_ARGS4((stream, closure, format, args),
	   trio_outstream_t stream,
	   trio_pointer_t closure,
	   TRIO_CONST char *format,
	   void **args)
{
  trio_custom_t data;

  assert(VALID(stream));
  assert(VALID(format));

  data.stream.out = stream;
  data.closure = closure;
  return TrioFormat(&data, 0, TrioOutStreamCustom, format, NULL, args);
}

/*************************************************************************
 * sprintf
 */

/**
   Print to string.

   @param buffer Output string.
   @param format Formatting string.
   @param ... Arguments.
   @return Number of printed characters.
 */
TRIO_PUBLIC int
trio_sprintf
TRIO_VARGS3((buffer, format, va_alist),
	    char *buffer,
	    TRIO_CONST char *format,
	    TRIO_VA_DECL)
{
  int status;
  va_list args;

  assert(VALID(buffer));
  assert(VALID(format));

  TRIO_VA_START(args, format);
  status = TrioFormat(&buffer, 0, TrioOutStreamString, format, TRIO_VA_LIST_ADDR(args), NULL);
  *buffer = NIL; /* Terminate with NIL character */
  TRIO_VA_END(args);
  return status;
}

/**
   Print to string.

   @param buffer Output string.
   @param format Formatting string.
   @param args Arguments.
   @return Number of printed characters.
 */
TRIO_PUBLIC int
trio_vsprintf
TRIO_ARGS3((buffer, format, args),
	   char *buffer,
	   TRIO_CONST char *format,
	   va_list args)
{
  int status;

  assert(VALID(buffer));
  assert(VALID(format));

  status = TrioFormat(&buffer, 0, TrioOutStreamString, format, TRIO_VA_LIST_ADDR(args), NULL);
  *buffer = NIL;
  return status;
}

/**
   Print to string.

   @param buffer Output string.
   @param format Formatting string.
   @param args Arguments.
   @return Number of printed characters.
 */
TRIO_PUBLIC int
trio_sprintfv
TRIO_ARGS3((buffer, format, args),
	   char *buffer,
	   TRIO_CONST char *format,
	   trio_pointer_t *args)
{
  int status;

  assert(VALID(buffer));
  assert(VALID(format));

  status = TrioFormat(&buffer, 0, TrioOutStreamString, format, NULL, args);
  *buffer = NIL;
  return status;
}

/*************************************************************************
 * snprintf
 */

/**
   Print at most @p max characters to string.

   @param buffer Output string.
   @param max Maximum number of characters to print.
   @param format Formatting string.
   @param ... Arguments.
   @return Number of printed characters.
 */
TRIO_PUBLIC int
trio_snprintf
TRIO_VARGS4((buffer, max, format, va_alist),
	    char *buffer,
	    size_t max,
	    TRIO_CONST char *format,
	    TRIO_VA_DECL)
{
  int status;
  va_list args;

  assert(VALID(buffer));
  assert(VALID(format));

  TRIO_VA_START(args, format);
  status = TrioFormat(&buffer, max > 0 ? max - 1 : 0,
		      TrioOutStreamStringMax, format, TRIO_VA_LIST_ADDR(args), NULL);
  if (max > 0)
    *buffer = NIL;
  TRIO_VA_END(args);
  return status;
}

/**
   Print at most @p max characters to string.

   @param buffer Output string.
   @param max Maximum number of characters to print.
   @param format Formatting string.
   @param args Arguments.
   @return Number of printed characters.
 */
TRIO_PUBLIC int
trio_vsnprintf
TRIO_ARGS4((buffer, max, format, args),
	   char *buffer,
	   size_t max,
	   TRIO_CONST char *format,
	   va_list args)
{
  int status;

  assert(VALID(buffer));
  assert(VALID(format));

  status = TrioFormat(&buffer, max > 0 ? max - 1 : 0,
		      TrioOutStreamStringMax, format, TRIO_VA_LIST_ADDR(args), NULL);
  if (max > 0)
    *buffer = NIL;
  return status;
}

/**
   Print at most @p max characters to string.

   @param buffer Output string.
   @param max Maximum number of characters to print.
   @param format Formatting string.
   @param args Arguments.
   @return Number of printed characters.
 */
TRIO_PUBLIC int
trio_snprintfv
TRIO_ARGS4((buffer, max, format, args),
	   char *buffer,
	   size_t max,
	   TRIO_CONST char *format,
	   trio_pointer_t *args)
{
  int status;

  assert(VALID(buffer));
  assert(VALID(format));

  status = TrioFormat(&buffer, max > 0 ? max - 1 : 0,
		      TrioOutStreamStringMax, format, NULL, args);
  if (max > 0)
    *buffer = NIL;
  return status;
}

/*************************************************************************
 * snprintfcat
 * Appends the new string to the buffer string overwriting the '\0'
 * character at the end of buffer.
 */
TRIO_PUBLIC int
trio_snprintfcat
TRIO_VARGS4((buffer, max, format, va_alist),
	    char *buffer,
	    size_t max,
	    TRIO_CONST char *format,
	    TRIO_VA_DECL)
{
  int status;
  va_list args;
  size_t buf_len;

  TRIO_VA_START(args, format);

  assert(VALID(buffer));
  assert(VALID(format));

  buf_len = trio_length(buffer);
  buffer = &buffer[buf_len];

  status = TrioFormat(&buffer, max - 1 - buf_len,
		      TrioOutStreamStringMax, format, TRIO_VA_LIST_ADDR(args), NULL);
  TRIO_VA_END(args);
  *buffer = NIL;
  return status;
}

TRIO_PUBLIC int
trio_vsnprintfcat
TRIO_ARGS4((buffer, max, format, args),
	   char *buffer,
	   size_t max,
	   TRIO_CONST char *format,
	   va_list args)
{
  int status;
  size_t buf_len;

  assert(VALID(buffer));
  assert(VALID(format));

  buf_len = trio_length(buffer);
  buffer = &buffer[buf_len];
  status = TrioFormat(&buffer, max - 1 - buf_len,
		      TrioOutStreamStringMax, format, TRIO_VA_LIST_ADDR(args), NULL);
  *buffer = NIL;
  return status;
}

/*************************************************************************
 * trio_aprintf
 */

/* Deprecated */
TRIO_PUBLIC char *
trio_aprintf
TRIO_VARGS2((format, va_alist),
	    TRIO_CONST char *format,
	    TRIO_VA_DECL)
{
  va_list args;
  trio_string_t *info;
  char *result = NULL;

  assert(VALID(format));

  info = trio_xstring_duplicate("");
  if (info)
    {
      TRIO_VA_START(args, format);
      (void)TrioFormat(info, 0, TrioOutStreamStringDynamic,
		       format, TRIO_VA_LIST_ADDR(args), NULL);
      TRIO_VA_END(args);

      trio_string_terminate(info);
      result = trio_string_extract(info);
      trio_string_destroy(info);
    }
  return result;
}

/* Deprecated */
TRIO_PUBLIC char *
trio_vaprintf
TRIO_ARGS2((format, args),
	   TRIO_CONST char *format,
	   va_list args)
{
  trio_string_t *info;
  char *result = NULL;

  assert(VALID(format));

  info = trio_xstring_duplicate("");
  if (info)
    {
      (void)TrioFormat(info, 0, TrioOutStreamStringDynamic,
		       format, TRIO_VA_LIST_ADDR(args), NULL);
      trio_string_terminate(info);
      result = trio_string_extract(info);
      trio_string_destroy(info);
    }
  return result;
}

TRIO_PUBLIC int
trio_asprintf
TRIO_VARGS3((result, format, va_alist),
	    char **result,
	    TRIO_CONST char *format,
	    TRIO_VA_DECL)
{
  va_list args;
  int status;
  trio_string_t *info;

  assert(VALID(format));

  *result = NULL;

  info = trio_xstring_duplicate("");
  if (info == NULL)
    {
      status = TRIO_ERROR_RETURN(TRIO_ENOMEM, 0);
    }
  else
    {
      TRIO_VA_START(args, format);
      status = TrioFormat(info, 0, TrioOutStreamStringDynamic,
			  format, TRIO_VA_LIST_ADDR(args), NULL);
      TRIO_VA_END(args);
      if (status >= 0)
	{
	  trio_string_terminate(info);
	  *result = trio_string_extract(info);
	}
      trio_string_destroy(info);
    }
  return status;
}

TRIO_PUBLIC int
trio_vasprintf
TRIO_ARGS3((result, format, args),
	   char **result,
	   TRIO_CONST char *format,
	   va_list args)
{
  int status;
  trio_string_t *info;

  assert(VALID(format));

  *result = NULL;

  info = trio_xstring_duplicate("");
  if (info == NULL)
    {
      status = TRIO_ERROR_RETURN(TRIO_ENOMEM, 0);
    }
  else
    {
      status = TrioFormat(info, 0, TrioOutStreamStringDynamic,
			  format, TRIO_VA_LIST_ADDR(args), NULL);
      if (status >= 0)
	{
	  trio_string_terminate(info);
	  *result = trio_string_extract(info);
	}
      trio_string_destroy(info);
    }
  return status;
}

/** @} End of Printf documentation module */

/*************************************************************************
 *
 * CALLBACK
 *
 ************************************************************************/

#if defined(TRIO_DOCUMENTATION)
# include "doc/doc_register.h"
#endif
/**
   @addtogroup UserDefined
   @{
*/

#if TRIO_EXTENSION

/*************************************************************************
 * trio_register
 */

/**
   Register new user-defined specifier.

   @param callback
   @param name
   @return Handle.
 */
TRIO_PUBLIC trio_pointer_t
trio_register
TRIO_ARGS2((callback, name),
	   trio_callback_t callback,
	   TRIO_CONST char *name)
{
  trio_userdef_t *def;
  trio_userdef_t *prev = NULL;

  if (callback == NULL)
    return NULL;

  if (name)
    {
      /* Handle built-in namespaces */
      if (name[0] == ':')
	{
	  if (trio_equal(name, ":enter"))
	    {
	      internalEnterCriticalRegion = callback;
	    }
	  else if (trio_equal(name, ":leave"))
	    {
	      internalLeaveCriticalRegion = callback;
	    }
	  return NULL;
	}

      /* Bail out if namespace is too long */
      if (trio_length(name) >= MAX_USER_NAME)
	return NULL;

      /* Bail out if namespace already is registered */
      def = TrioFindNamespace(name, &prev);
      if (def)
	return NULL;
    }

  def = (trio_userdef_t *)TRIO_MALLOC(sizeof(trio_userdef_t));
  if (def)
    {
      if (internalEnterCriticalRegion)
	(void)internalEnterCriticalRegion(NULL);

      if (name)
	{
	  /* Link into internal list */
	  if (prev == NULL)
	    internalUserDef = def;
	  else
	    prev->next = def;
	}
      /* Initialize */
      def->callback = callback;
      def->name = (name == NULL)
	? NULL
	: trio_duplicate(name);
      def->next = NULL;

      if (internalLeaveCriticalRegion)
	(void)internalLeaveCriticalRegion(NULL);
    }
  return (trio_pointer_t)def;
}

/**
   Unregister an existing user-defined specifier.

   @param handle
 */
void
trio_unregister
TRIO_ARGS1((handle),
	   trio_pointer_t handle)
{
  trio_userdef_t *self = (trio_userdef_t *)handle;
  trio_userdef_t *def;
  trio_userdef_t *prev = NULL;

  assert(VALID(self));

  if (self->name)
    {
      def = TrioFindNamespace(self->name, &prev);
      if (def)
	{
	  if (internalEnterCriticalRegion)
	    (void)internalEnterCriticalRegion(NULL);

	  if (prev == NULL)
	    internalUserDef = NULL;
	  else
	    prev->next = def->next;

	  if (internalLeaveCriticalRegion)
	    (void)internalLeaveCriticalRegion(NULL);
	}
      trio_destroy(self->name);
    }
  TRIO_FREE(self);
}

/*************************************************************************
 * trio_get_format [public]
 */
TRIO_CONST char *
trio_get_format
TRIO_ARGS1((ref),
	   trio_pointer_t ref)
{
#if defined(FORMAT_USER_DEFINED)
  assert(((trio_reference_t *)ref)->parameter->type == FORMAT_USER_DEFINED);
#endif

  return (((trio_reference_t *)ref)->parameter->user_data);
}

/*************************************************************************
 * trio_get_argument [public]
 */
trio_pointer_t
trio_get_argument
TRIO_ARGS1((ref),
	   trio_pointer_t ref)
{
#if defined(FORMAT_USER_DEFINED)
  assert(((trio_reference_t *)ref)->parameter->type == FORMAT_USER_DEFINED);
#endif

  return ((trio_reference_t *)ref)->parameter->data.pointer;
}

/*************************************************************************
 * trio_get_width / trio_set_width [public]
 */
int
trio_get_width
TRIO_ARGS1((ref),
	   trio_pointer_t ref)
{
  return ((trio_reference_t *)ref)->parameter->width;
}

void
trio_set_width
TRIO_ARGS2((ref, width),
	   trio_pointer_t ref,
	   int width)
{
  ((trio_reference_t *)ref)->parameter->width = width;
}

/*************************************************************************
 * trio_get_precision / trio_set_precision [public]
 */
int
trio_get_precision
TRIO_ARGS1((ref),
	   trio_pointer_t ref)
{
  return (((trio_reference_t *)ref)->parameter->precision);
}

void
trio_set_precision
TRIO_ARGS2((ref, precision),
	   trio_pointer_t ref,
	   int precision)
{
  ((trio_reference_t *)ref)->parameter->precision = precision;
}

/*************************************************************************
 * trio_get_base / trio_set_base [public]
 */
int
trio_get_base
TRIO_ARGS1((ref),
	   trio_pointer_t ref)
{
  return (((trio_reference_t *)ref)->parameter->base);
}

void
trio_set_base
TRIO_ARGS2((ref, base),
	   trio_pointer_t ref,
	   int base)
{
  ((trio_reference_t *)ref)->parameter->base = base;
}

/*************************************************************************
 * trio_get_long / trio_set_long [public]
 */
int
trio_get_long
TRIO_ARGS1((ref),
	   trio_pointer_t ref)
{
  return (((trio_reference_t *)ref)->parameter->flags & FLAGS_LONG)
    ? TRUE
    : FALSE;
}

void
trio_set_long
TRIO_ARGS2((ref, is_long),
	   trio_pointer_t ref,
	   int is_long)
{
  if (is_long)
    ((trio_reference_t *)ref)->parameter->flags |= FLAGS_LONG;
  else
    ((trio_reference_t *)ref)->parameter->flags &= ~FLAGS_LONG;
}

/*************************************************************************
 * trio_get_longlong / trio_set_longlong [public]
 */
int
trio_get_longlong
TRIO_ARGS1((ref),
	   trio_pointer_t ref)
{
  return (((trio_reference_t *)ref)->parameter->flags & FLAGS_QUAD)
    ? TRUE
    : FALSE;
}

void
trio_set_longlong
TRIO_ARGS2((ref, is_longlong),
	   trio_pointer_t ref,
	   int is_longlong)
{
  if (is_longlong)
    ((trio_reference_t *)ref)->parameter->flags |= FLAGS_QUAD;
  else
    ((trio_reference_t *)ref)->parameter->flags &= ~FLAGS_QUAD;
}

/*************************************************************************
 * trio_get_longdouble / trio_set_longdouble [public]
 */
int
trio_get_longdouble
TRIO_ARGS1((ref),
	   trio_pointer_t ref)
{
  return (((trio_reference_t *)ref)->parameter->flags & FLAGS_LONGDOUBLE)
    ? TRUE
    : FALSE;
}

void
trio_set_longdouble
TRIO_ARGS2((ref, is_longdouble),
	   trio_pointer_t ref,
	   int is_longdouble)
{
  if (is_longdouble)
    ((trio_reference_t *)ref)->parameter->flags |= FLAGS_LONGDOUBLE;
  else
    ((trio_reference_t *)ref)->parameter->flags &= ~FLAGS_LONGDOUBLE;
}

/*************************************************************************
 * trio_get_short / trio_set_short [public]
 */
int
trio_get_short
TRIO_ARGS1((ref),
	   trio_pointer_t ref)
{
  return (((trio_reference_t *)ref)->parameter->flags & FLAGS_SHORT)
    ? TRUE
    : FALSE;
}

void
trio_set_short
TRIO_ARGS2((ref, is_short),
	   trio_pointer_t ref,
	   int is_short)
{
  if (is_short)
    ((trio_reference_t *)ref)->parameter->flags |= FLAGS_SHORT;
  else
    ((trio_reference_t *)ref)->parameter->flags &= ~FLAGS_SHORT;
}

/*************************************************************************
 * trio_get_shortshort / trio_set_shortshort [public]
 */
int
trio_get_shortshort
TRIO_ARGS1((ref),
	   trio_pointer_t ref)
{
  return (((trio_reference_t *)ref)->parameter->flags & FLAGS_SHORTSHORT)
    ? TRUE
    : FALSE;
}

void
trio_set_shortshort
TRIO_ARGS2((ref, is_shortshort),
	   trio_pointer_t ref,
	   int is_shortshort)
{
  if (is_shortshort)
    ((trio_reference_t *)ref)->parameter->flags |= FLAGS_SHORTSHORT;
  else
    ((trio_reference_t *)ref)->parameter->flags &= ~FLAGS_SHORTSHORT;
}

/*************************************************************************
 * trio_get_alternative / trio_set_alternative [public]
 */
int
trio_get_alternative
TRIO_ARGS1((ref),
	   trio_pointer_t ref)
{
  return (((trio_reference_t *)ref)->parameter->flags & FLAGS_ALTERNATIVE)
    ? TRUE
    : FALSE;
}

void
trio_set_alternative
TRIO_ARGS2((ref, is_alternative),
	   trio_pointer_t ref,
	   int is_alternative)
{
  if (is_alternative)
    ((trio_reference_t *)ref)->parameter->flags |= FLAGS_ALTERNATIVE;
  else
    ((trio_reference_t *)ref)->parameter->flags &= ~FLAGS_ALTERNATIVE;
}

/*************************************************************************
 * trio_get_alignment / trio_set_alignment [public]
 */
int
trio_get_alignment
TRIO_ARGS1((ref),
	   trio_pointer_t ref)
{
  return (((trio_reference_t *)ref)->parameter->flags & FLAGS_LEFTADJUST)
    ? TRUE
    : FALSE;
}

void
trio_set_alignment
TRIO_ARGS2((ref, is_leftaligned),
	   trio_pointer_t ref,
	   int is_leftaligned)
{
  if (is_leftaligned)
    ((trio_reference_t *)ref)->parameter->flags |= FLAGS_LEFTADJUST;
  else
    ((trio_reference_t *)ref)->parameter->flags &= ~FLAGS_LEFTADJUST;
}

/*************************************************************************
 * trio_get_spacing /trio_set_spacing [public]
 */
int
trio_get_spacing
TRIO_ARGS1((ref),
	   trio_pointer_t ref)
{
  return (((trio_reference_t *)ref)->parameter->flags & FLAGS_SPACE)
    ? TRUE
    : FALSE;
}

void
trio_set_spacing
TRIO_ARGS2((ref, is_space),
	   trio_pointer_t ref,
	   int is_space)
{
  if (is_space)
    ((trio_reference_t *)ref)->parameter->flags |= FLAGS_SPACE;
  else
    ((trio_reference_t *)ref)->parameter->flags &= ~FLAGS_SPACE;
}

/*************************************************************************
 * trio_get_sign / trio_set_sign [public]
 */
int
trio_get_sign
TRIO_ARGS1((ref),
	   trio_pointer_t ref)
{
  return (((trio_reference_t *)ref)->parameter->flags & FLAGS_SHOWSIGN)
    ? TRUE
    : FALSE;
}

void
trio_set_sign
TRIO_ARGS2((ref, is_sign),
	   trio_pointer_t ref,
	   int is_sign)
{
  if (is_sign)
    ((trio_reference_t *)ref)->parameter->flags |= FLAGS_SHOWSIGN;
  else
    ((trio_reference_t *)ref)->parameter->flags &= ~FLAGS_SHOWSIGN;
}

/*************************************************************************
 * trio_get_padding / trio_set_padding [public]
 */
int
trio_get_padding
TRIO_ARGS1((ref),
	   trio_pointer_t ref)
{
  return (((trio_reference_t *)ref)->parameter->flags & FLAGS_NILPADDING)
    ? TRUE
    : FALSE;
}

void
trio_set_padding
TRIO_ARGS2((ref, is_padding),
	   trio_pointer_t ref,
	   int is_padding)
{
  if (is_padding)
    ((trio_reference_t *)ref)->parameter->flags |= FLAGS_NILPADDING;
  else
    ((trio_reference_t *)ref)->parameter->flags &= ~FLAGS_NILPADDING;
}

/*************************************************************************
 * trio_get_quote / trio_set_quote [public]
 */
int
trio_get_quote
TRIO_ARGS1((ref),
	   trio_pointer_t ref)
{
  return (((trio_reference_t *)ref)->parameter->flags & FLAGS_QUOTE)
    ? TRUE
    : FALSE;
}

void
trio_set_quote
TRIO_ARGS2((ref, is_quote),
	   trio_pointer_t ref,
	   int is_quote)
{
  if (is_quote)
    ((trio_reference_t *)ref)->parameter->flags |= FLAGS_QUOTE;
  else
    ((trio_reference_t *)ref)->parameter->flags &= ~FLAGS_QUOTE;
}

/*************************************************************************
 * trio_get_upper / trio_set_upper [public]
 */
int
trio_get_upper
TRIO_ARGS1((ref),
	   trio_pointer_t ref)
{
  return (((trio_reference_t *)ref)->parameter->flags & FLAGS_UPPER)
    ? TRUE
    : FALSE;
}

void
trio_set_upper
TRIO_ARGS2((ref, is_upper),
	   trio_pointer_t ref,
	   int is_upper)
{
  if (is_upper)
    ((trio_reference_t *)ref)->parameter->flags |= FLAGS_UPPER;
  else
    ((trio_reference_t *)ref)->parameter->flags &= ~FLAGS_UPPER;
}

/*************************************************************************
 * trio_get_largest / trio_set_largest [public]
 */
#if TRIO_C99
int
trio_get_largest
TRIO_ARGS1((ref),
	   trio_pointer_t ref)
{
  return (((trio_reference_t *)ref)->parameter->flags & FLAGS_INTMAX_T)
    ? TRUE
    : FALSE;
}

void
trio_set_largest
TRIO_ARGS2((ref, is_largest),
	   trio_pointer_t ref,
	   int is_largest)
{
  if (is_largest)
    ((trio_reference_t *)ref)->parameter->flags |= FLAGS_INTMAX_T;
  else
    ((trio_reference_t *)ref)->parameter->flags &= ~FLAGS_INTMAX_T;
}
#endif

/*************************************************************************
 * trio_get_ptrdiff / trio_set_ptrdiff [public]
 */
int
trio_get_ptrdiff
TRIO_ARGS1((ref),
	   trio_pointer_t ref)
{
  return (((trio_reference_t *)ref)->parameter->flags & FLAGS_PTRDIFF_T)
    ? TRUE
    : FALSE;
}

void
trio_set_ptrdiff
TRIO_ARGS2((ref, is_ptrdiff),
	   trio_pointer_t ref,
	   int is_ptrdiff)
{
  if (is_ptrdiff)
    ((trio_reference_t *)ref)->parameter->flags |= FLAGS_PTRDIFF_T;
  else
    ((trio_reference_t *)ref)->parameter->flags &= ~FLAGS_PTRDIFF_T;
}

/*************************************************************************
 * trio_get_size / trio_set_size [public]
 */
#if TRIO_C99
int
trio_get_size
TRIO_ARGS1((ref),
	   trio_pointer_t ref)
{
  return (((trio_reference_t *)ref)->parameter->flags & FLAGS_SIZE_T)
    ? TRUE
    : FALSE;
}

void
trio_set_size
TRIO_ARGS2((ref, is_size),
	   trio_pointer_t ref,
	   int is_size)
{
  if (is_size)
    ((trio_reference_t *)ref)->parameter->flags |= FLAGS_SIZE_T;
  else
    ((trio_reference_t *)ref)->parameter->flags &= ~FLAGS_SIZE_T;
}
#endif

/*************************************************************************
 * trio_print_int [public]
 */
void
trio_print_int
TRIO_ARGS2((ref, number),
	   trio_pointer_t ref,
	   int number)
{
  trio_reference_t *self = (trio_reference_t *)ref;

  TrioWriteNumber(self->data,
		  (trio_uintmax_t)number,
		  self->parameter->flags,
		  self->parameter->width,
		  self->parameter->precision,
		  self->parameter->base);
}

/*************************************************************************
 * trio_print_uint [public]
 */
void
trio_print_uint
TRIO_ARGS2((ref, number),
	   trio_pointer_t ref,
	   unsigned int number)
{
  trio_reference_t *self = (trio_reference_t *)ref;

  TrioWriteNumber(self->data,
		  (trio_uintmax_t)number,
		  self->parameter->flags | FLAGS_UNSIGNED,
		  self->parameter->width,
		  self->parameter->precision,
		  self->parameter->base);
}

/*************************************************************************
 * trio_print_double [public]
 */
void
trio_print_double
TRIO_ARGS2((ref, number),
	   trio_pointer_t ref,
	   double number)
{
  trio_reference_t *self = (trio_reference_t *)ref;

  TrioWriteDouble(self->data,
		  number,
		  self->parameter->flags,
		  self->parameter->width,
		  self->parameter->precision,
		  self->parameter->base);
}

/*************************************************************************
 * trio_print_string [public]
 */
void
trio_print_string
TRIO_ARGS2((ref, string),
	   trio_pointer_t ref,
	   char *string)
{
  trio_reference_t *self = (trio_reference_t *)ref;

  TrioWriteString(self->data,
		  string,
		  self->parameter->flags,
		  self->parameter->width,
		  self->parameter->precision);
}

/*************************************************************************
 * trio_print_ref [public]
 */
int
trio_print_ref
TRIO_VARGS3((ref, format, va_alist),
	    trio_pointer_t ref,
	    TRIO_CONST char *format,
	    TRIO_VA_DECL)
{
  int status;
  va_list arglist;

  assert(VALID(format));

  TRIO_VA_START(arglist, format);
  status = TrioFormatRef((trio_reference_t *)ref, format, TRIO_VA_LIST_ADDR(arglist), NULL);
  TRIO_VA_END(arglist);
  return status;
}

/*************************************************************************
 * trio_vprint_ref [public]
 */
int
trio_vprint_ref
TRIO_ARGS3((ref, format, arglist),
	   trio_pointer_t ref,
	   TRIO_CONST char *format,
	   va_list arglist)
{
  assert(VALID(format));

  return TrioFormatRef((trio_reference_t *)ref, format, TRIO_VA_LIST_ADDR(arglist), NULL);
}

/*************************************************************************
 * trio_printv_ref [public]
 */
int
trio_printv_ref
TRIO_ARGS3((ref, format, argarray),
	   trio_pointer_t ref,
	   TRIO_CONST char *format,
	   trio_pointer_t *argarray)
{
  assert(VALID(format));

  return TrioFormatRef((trio_reference_t *)ref, format, NULL, argarray);
}

#endif /* TRIO_EXTENSION */

/*************************************************************************
 * trio_print_pointer [public]
 */
void
trio_print_pointer
TRIO_ARGS2((ref, pointer),
	   trio_pointer_t ref,
	   trio_pointer_t pointer)
{
  trio_reference_t *self = (trio_reference_t *)ref;
  trio_flags_t flags;
  trio_uintmax_t number;

  if (NULL == pointer)
    {
      TRIO_CONST char *string = internalNullString;
      while (*string)
	self->data->OutStream(self->data, *string++);
    }
  else
    {
      /*
       * The subtraction of the null pointer is a workaround
       * to avoid a compiler warning. The performance overhead
       * is negligible (and likely to be removed by an
       * optimizing compiler). The (char *) casting is done
       * to please ANSI C++.
       */
      number = (trio_uintmax_t)((char *)pointer - (char *)0);
      /* Shrink to size of pointer */
      number &= (trio_uintmax_t)-1;
      flags = self->parameter->flags;
      flags |= (FLAGS_UNSIGNED | FLAGS_ALTERNATIVE |
	        FLAGS_NILPADDING);
      TrioWriteNumber(self->data,
		      number,
		      flags,
		      POINTER_WIDTH,
		      NO_PRECISION,
		      BASE_HEX);
    }
}

/** @} End of UserDefined documentation module */

/*************************************************************************
 *
 * LOCALES
 *
 ************************************************************************/

/*************************************************************************
 * trio_locale_set_decimal_point
 *
 * Decimal point can only be one character. The input argument is a
 * string to enable multibyte characters. At most MB_LEN_MAX characters
 * will be used.
 */
TRIO_PUBLIC void
trio_locale_set_decimal_point
TRIO_ARGS1((decimalPoint),
	   char *decimalPoint)
{
#if defined(USE_LOCALE)
  if (NULL == internalLocaleValues)
    {
      TrioSetLocale();
    }
#endif
  internalDecimalPointLength = trio_length(decimalPoint);
  if (internalDecimalPointLength == 1)
    {
      internalDecimalPoint = *decimalPoint;
    }
  else
    {
      internalDecimalPoint = NIL;
      trio_copy_max(internalDecimalPointString,
		    sizeof(internalDecimalPointString),
		    decimalPoint);
    }
}

/*************************************************************************
 * trio_locale_set_thousand_separator
 *
 * See trio_locale_set_decimal_point
 */
TRIO_PUBLIC void
trio_locale_set_thousand_separator
TRIO_ARGS1((thousandSeparator),
	   char *thousandSeparator)
{
#if defined(USE_LOCALE)
  if (NULL == internalLocaleValues)
    {
      TrioSetLocale();
    }
#endif
  trio_copy_max(internalThousandSeparator,
		sizeof(internalThousandSeparator),
		thousandSeparator);
  internalThousandSeparatorLength = trio_length(internalThousandSeparator);
}

/*************************************************************************
 * trio_locale_set_grouping
 *
 * Array of bytes. Reversed order.
 *
 *  CHAR_MAX : No further grouping
 *  0        : Repeat last group for the remaining digits (not necessary
 *             as C strings are zero-terminated)
 *  n        : Set current group to n
 *
 * Same order as the grouping attribute in LC_NUMERIC.
 */
TRIO_PUBLIC void
trio_locale_set_grouping
TRIO_ARGS1((grouping),
	   char *grouping)
{
#if defined(USE_LOCALE)
  if (NULL == internalLocaleValues)
    {
      TrioSetLocale();
    }
#endif
  trio_copy_max(internalGrouping,
		sizeof(internalGrouping),
		grouping);
}


/*************************************************************************
 *
 * SCANNING
 *
 ************************************************************************/

/*************************************************************************
 * TrioSkipWhitespaces
 */
TRIO_PRIVATE int
TrioSkipWhitespaces
TRIO_ARGS1((self),
	   trio_class_t *self)
{
  int ch;

  ch = self->current;
  while (isspace(ch))
    {
      self->InStream(self, &ch);
    }
  return ch;
}

/*************************************************************************
 * TrioGetCollation
 */
#if TRIO_EXTENSION
TRIO_PRIVATE void
TrioGetCollation(TRIO_NOARGS)
{
  int i;
  int j;
  int k;
  char first[2];
  char second[2];

  /* This is computationally expensive */
  first[1] = NIL;
  second[1] = NIL;
  for (i = 0; i < MAX_CHARACTER_CLASS; i++)
    {
      k = 0;
      first[0] = (char)i;
      for (j = 0; j < MAX_CHARACTER_CLASS; j++)
	{
	  second[0] = (char)j;
	  if (trio_equal_locale(first, second))
	    internalCollationArray[i][k++] = (char)j;
	}
      internalCollationArray[i][k] = NIL;
    }
}
#endif

/*************************************************************************
 * TrioGetCharacterClass
 *
 * FIXME:
 *  multibyte
 */
TRIO_PRIVATE int
TrioGetCharacterClass
TRIO_ARGS4((format, indexPointer, flagsPointer, characterclass),
	   TRIO_CONST char *format,
	   int *indexPointer,
	   trio_flags_t *flagsPointer,
	   int *characterclass)
{
  int index = *indexPointer;
  int i;
  char ch;
  char range_begin;
  char range_end;

  *flagsPointer &= ~FLAGS_EXCLUDE;

  if (format[index] == QUALIFIER_CIRCUMFLEX)
    {
      *flagsPointer |= FLAGS_EXCLUDE;
      index++;
    }
  /*
   * If the ungroup character is at the beginning of the scanlist,
   * it will be part of the class, and a second ungroup character
   * must follow to end the group.
   */
  if (format[index] == SPECIFIER_UNGROUP)
    {
      characterclass[(int)SPECIFIER_UNGROUP]++;
      index++;
    }
  /*
   * Minus is used to specify ranges. To include minus in the class,
   * it must be at the beginning of the list
   */
  if (format[index] == QUALIFIER_MINUS)
    {
      characterclass[(int)QUALIFIER_MINUS]++;
      index++;
    }
  /* Collect characters */
  for (ch = format[index];
       (ch != SPECIFIER_UNGROUP) && (ch != NIL);
       ch = format[++index])
    {
      switch (ch)
	{
	case QUALIFIER_MINUS: /* Scanlist ranges */

	  /*
	   * Both C99 and UNIX98 describes ranges as implementation-
	   * defined.
	   *
	   * We support the following behaviour (although this may
	   * change as we become wiser)
	   * - only increasing ranges, ie. [a-b] but not [b-a]
	   * - transitive ranges, ie. [a-b-c] == [a-c]
	   * - trailing minus, ie. [a-] is interpreted as an 'a'
	   *   and a '-'
	   * - duplicates (although we can easily convert these
	   *   into errors)
	   */
	  range_begin = format[index - 1];
	  range_end = format[++index];
	  if (range_end == SPECIFIER_UNGROUP)
	    {
	      /* Trailing minus is included */
	      characterclass[(int)ch]++;
	      ch = range_end;
	      break; /* for */
	    }
	  if (range_end == NIL)
	    return TRIO_ERROR_RETURN(TRIO_EINVAL, index);
	  if (range_begin > range_end)
	    return TRIO_ERROR_RETURN(TRIO_ERANGE, index);

	  for (i = (int)range_begin; i <= (int)range_end; i++)
	    characterclass[i]++;

	  ch = range_end;
	  break;

#if TRIO_EXTENSION

	case SPECIFIER_GROUP:

	  switch (format[index + 1])
	    {
	    case QUALIFIER_DOT: /* Collating symbol */
	      /*
	       * FIXME: This will be easier to implement when multibyte
	       * characters have been implemented. Until now, we ignore
	       * this feature.
	       */
	      for (i = index + 2; ; i++)
		{
		  if (format[i] == NIL)
		    /* Error in syntax */
		    return -1;
		  else if (format[i] == QUALIFIER_DOT)
		    break; /* for */
		}
	      if (format[++i] != SPECIFIER_UNGROUP)
		return -1;

	      index = i;
	      break;

	    case QUALIFIER_EQUAL: /* Equivalence class expressions */
	      {
		unsigned int j;
		unsigned int k;

		if (internalCollationUnconverted)
		  {
		    /* Lazy evaluation of collation array */
		    TrioGetCollation();
		    internalCollationUnconverted = FALSE;
		  }
		for (i = index + 2; ; i++)
		  {
		    if (format[i] == NIL)
		      /* Error in syntax */
		      return -1;
		    else if (format[i] == QUALIFIER_EQUAL)
		      break; /* for */
		    else
		      {
			/* Mark any equivalent character */
			k = (unsigned int)format[i];
			for (j = 0; internalCollationArray[k][j] != NIL; j++)
			  characterclass[(int)internalCollationArray[k][j]]++;
		      }
		  }
		if (format[++i] != SPECIFIER_UNGROUP)
		  return -1;

		index = i;
	      }
	      break;

	    case QUALIFIER_COLON: /* Character class expressions */

	      if (trio_equal_max(CLASS_ALNUM, sizeof(CLASS_ALNUM) - 1,
				 &format[index]))
		{
		  for (i = 0; i < MAX_CHARACTER_CLASS; i++)
		    if (isalnum(i))
		      characterclass[i]++;
		  index += sizeof(CLASS_ALNUM) - 1;
		}
	      else if (trio_equal_max(CLASS_ALPHA, sizeof(CLASS_ALPHA) - 1,
				      &format[index]))
		{
		  for (i = 0; i < MAX_CHARACTER_CLASS; i++)
		    if (isalpha(i))
		      characterclass[i]++;
		  index += sizeof(CLASS_ALPHA) - 1;
		}
	      else if (trio_equal_max(CLASS_CNTRL, sizeof(CLASS_CNTRL) - 1,
				      &format[index]))
		{
		  for (i = 0; i < MAX_CHARACTER_CLASS; i++)
		    if (iscntrl(i))
		      characterclass[i]++;
		  index += sizeof(CLASS_CNTRL) - 1;
		}
	      else if (trio_equal_max(CLASS_DIGIT, sizeof(CLASS_DIGIT) - 1,
				      &format[index]))
		{
		  for (i = 0; i < MAX_CHARACTER_CLASS; i++)
		    if (isdigit(i))
		      characterclass[i]++;
		  index += sizeof(CLASS_DIGIT) - 1;
		}
	      else if (trio_equal_max(CLASS_GRAPH, sizeof(CLASS_GRAPH) - 1,
				      &format[index]))
		{
		  for (i = 0; i < MAX_CHARACTER_CLASS; i++)
		    if (isgraph(i))
		      characterclass[i]++;
		  index += sizeof(CLASS_GRAPH) - 1;
		}
	      else if (trio_equal_max(CLASS_LOWER, sizeof(CLASS_LOWER) - 1,
				      &format[index]))
		{
		  for (i = 0; i < MAX_CHARACTER_CLASS; i++)
		    if (islower(i))
		      characterclass[i]++;
		  index += sizeof(CLASS_LOWER) - 1;
		}
	      else if (trio_equal_max(CLASS_PRINT, sizeof(CLASS_PRINT) - 1,
				      &format[index]))
		{
		  for (i = 0; i < MAX_CHARACTER_CLASS; i++)
		    if (isprint(i))
		      characterclass[i]++;
		  index += sizeof(CLASS_PRINT) - 1;
		}
	      else if (trio_equal_max(CLASS_PUNCT, sizeof(CLASS_PUNCT) - 1,
				      &format[index]))
		{
		  for (i = 0; i < MAX_CHARACTER_CLASS; i++)
		    if (ispunct(i))
		      characterclass[i]++;
		  index += sizeof(CLASS_PUNCT) - 1;
		}
	      else if (trio_equal_max(CLASS_SPACE, sizeof(CLASS_SPACE) - 1,
				      &format[index]))
		{
		  for (i = 0; i < MAX_CHARACTER_CLASS; i++)
		    if (isspace(i))
		      characterclass[i]++;
		  index += sizeof(CLASS_SPACE) - 1;
		}
	      else if (trio_equal_max(CLASS_UPPER, sizeof(CLASS_UPPER) - 1,
				      &format[index]))
		{
		  for (i = 0; i < MAX_CHARACTER_CLASS; i++)
		    if (isupper(i))
		      characterclass[i]++;
		  index += sizeof(CLASS_UPPER) - 1;
		}
	      else if (trio_equal_max(CLASS_XDIGIT, sizeof(CLASS_XDIGIT) - 1,
				      &format[index]))
		{
		  for (i = 0; i < MAX_CHARACTER_CLASS; i++)
		    if (isxdigit(i))
		      characterclass[i]++;
		  index += sizeof(CLASS_XDIGIT) - 1;
		}
	      else
		{
		  characterclass[(int)ch]++;
		}
	      break;

	    default:
	      characterclass[(int)ch]++;
	      break;
	    }
	  break;

#endif /* TRIO_EXTENSION */

	default:
	  characterclass[(int)ch]++;
	  break;
	}
    }
  return 0;
}

/*************************************************************************
 * TrioReadNumber
 *
 * We implement our own number conversion in preference of strtol and
 * strtoul, because we must handle 'long long' and thousand separators.
 */
TRIO_PRIVATE BOOLEAN_T
TrioReadNumber
TRIO_ARGS5((self, target, flags, width, base),
	   trio_class_t *self,
	   trio_uintmax_t *target,
	   trio_flags_t flags,
	   int width,
	   int base)
{
  trio_uintmax_t number = 0;
  int digit;
  int count;
  BOOLEAN_T isNegative = FALSE;
  BOOLEAN_T gotNumber = FALSE;
  int j;

  assert(VALID(self));
  assert(VALID(self->InStream));
  assert((base >= MIN_BASE && base <= MAX_BASE) || (base == NO_BASE));

  if (internalDigitsUnconverted)
    {
      /* Lazy evaluation of digits array */
      memset(internalDigitArray, -1, sizeof(internalDigitArray));
      for (j = 0; j < (int)sizeof(internalDigitsLower) - 1; j++)
	{
	  internalDigitArray[(int)internalDigitsLower[j]] = j;
	  internalDigitArray[(int)internalDigitsUpper[j]] = j;
	}
      internalDigitsUnconverted = FALSE;
    }

  TrioSkipWhitespaces(self);

  if (!(flags & FLAGS_UNSIGNED))
    {
      /* Leading sign */
      if (self->current == '+')
	{
	  self->InStream(self, NULL);
	}
      else if (self->current == '-')
	{
	  self->InStream(self, NULL);
	  isNegative = TRUE;
	}
    }

  count = self->processed;

  if (flags & FLAGS_ALTERNATIVE)
    {
      switch (base)
	{
	case NO_BASE:
	case BASE_OCTAL:
	case BASE_HEX:
	case BASE_BINARY:
	  if (self->current == '0')
	    {
	      self->InStream(self, NULL);
	      if (self->current)
		{
		  if ((base == BASE_HEX) &&
		      (trio_to_upper(self->current) == 'X'))
		    {
		      self->InStream(self, NULL);
		    }
		  else if ((base == BASE_BINARY) &&
			   (trio_to_upper(self->current) == 'B'))
		    {
		      self->InStream(self, NULL);
		    }
		}
	    }
	  else
	    return FALSE;
	  break;
	default:
	  break;
	}
    }

  while (((width == NO_WIDTH) || (self->processed - count < width)) &&
	 (! ((self->current == EOF) || isspace(self->current))))
    {
      if (isascii(self->current))
	{
	  digit = internalDigitArray[self->current];
	  /* Abort if digit is not allowed in the specified base */
	  if ((digit == -1) || (digit >= base))
	    break;
	}
      else if (flags & FLAGS_QUOTE)
	{
	  /* Compare with thousands separator */
	  for (j = 0; internalThousandSeparator[j] && self->current; j++)
	    {
	      if (internalThousandSeparator[j] != self->current)
		break;

	      self->InStream(self, NULL);
	    }
	  if (internalThousandSeparator[j])
	    break; /* Mismatch */
	  else
	    continue; /* Match */
	}
      else
	break;

      number *= base;
      number += digit;
      gotNumber = TRUE; /* we need at least one digit */

      self->InStream(self, NULL);
    }

  /* Was anything read at all? */
  if (!gotNumber)
    return FALSE;

  if (target)
    *target = (isNegative) ? -((trio_intmax_t)number) : number;
  return TRUE;
}

/*************************************************************************
 * TrioReadChar
 */
TRIO_PRIVATE int
TrioReadChar
TRIO_ARGS4((self, target, flags, width),
	   trio_class_t *self,
	   char *target,
	   trio_flags_t flags,
	   int width)
{
  int i;
  char ch;
  trio_uintmax_t number;

  assert(VALID(self));
  assert(VALID(self->InStream));

  for (i = 0;
       (self->current != EOF) && (i < width);
       i++)
    {
      ch = (char)self->current;
      self->InStream(self, NULL);
      if ((flags & FLAGS_ALTERNATIVE) && (ch == CHAR_BACKSLASH))
	{
	  switch (self->current)
	    {
	    case '\\': ch = '\\'; break;
	    case 'a': ch = '\007'; break;
	    case 'b': ch = '\b'; break;
	    case 'f': ch = '\f'; break;
	    case 'n': ch = '\n'; break;
	    case 'r': ch = '\r'; break;
	    case 't': ch = '\t'; break;
	    case 'v': ch = '\v'; break;
	    default:
	      if (isdigit(self->current))
		{
		  /* Read octal number */
		  if (!TrioReadNumber(self, &number, 0, 3, BASE_OCTAL))
		    return 0;
		  ch = (char)number;
		}
	      else if (trio_to_upper(self->current) == 'X')
		{
		  /* Read hexadecimal number */
		  self->InStream(self, NULL);
		  if (!TrioReadNumber(self, &number, 0, 2, BASE_HEX))
		    return 0;
		  ch = (char)number;
		}
	      else
		{
		  ch = (char)self->current;
		}
	      break;
	    }
	}

      if (target)
	target[i] = ch;
    }
  return i + 1;
}

/*************************************************************************
 * TrioReadString
 */
TRIO_PRIVATE BOOLEAN_T
TrioReadString
TRIO_ARGS4((self, target, flags, width),
	   trio_class_t *self,
	   char *target,
	   trio_flags_t flags,
	   int width)
{
  int i;

  assert(VALID(self));
  assert(VALID(self->InStream));

  TrioSkipWhitespaces(self);

  /*
   * Continue until end of string is reached, a whitespace is encountered,
   * or width is exceeded
   */
  for (i = 0;
       ((width == NO_WIDTH) || (i < width)) &&
       (! ((self->current == EOF) || isspace(self->current)));
       i++)
    {
      if (TrioReadChar(self, (target ? &target[i] : 0), flags, 1) == 0)
	break; /* for */
    }
  if (target)
    target[i] = NIL;
  return TRUE;
}

/*************************************************************************
 * TrioReadWideChar
 */
#if TRIO_WIDECHAR
TRIO_PRIVATE int
TrioReadWideChar
TRIO_ARGS4((self, target, flags, width),
	   trio_class_t *self,
	   trio_wchar_t *target,
	   trio_flags_t flags,
	   int width)
{
  int i;
  int j;
  int size;
  int amount = 0;
  trio_wchar_t wch;
  char buffer[MB_LEN_MAX + 1];

  assert(VALID(self));
  assert(VALID(self->InStream));

  for (i = 0;
       (self->current != EOF) && (i < width);
       i++)
    {
      if (isascii(self->current))
	{
	  if (TrioReadChar(self, buffer, flags, 1) == 0)
	    return 0;
	  buffer[1] = NIL;
	}
      else
	{
	  /*
	   * Collect a multibyte character, by enlarging buffer until
	   * it contains a fully legal multibyte character, or the
	   * buffer is full.
	   */
	  j = 0;
	  do
	    {
	      buffer[j++] = (char)self->current;
	      buffer[j] = NIL;
	      self->InStream(self, NULL);
	    }
	  while ((j < (int)sizeof(buffer)) && (mblen(buffer, (size_t)j) != j));
	}
      if (target)
	{
	  size = mbtowc(&wch, buffer, sizeof(buffer));
	  if (size > 0)
	    target[i] = wch;
	}
      amount += size;
      self->InStream(self, NULL);
    }
  return amount;
}
#endif /* TRIO_WIDECHAR */

/*************************************************************************
 * TrioReadWideString
 */
#if TRIO_WIDECHAR
TRIO_PRIVATE BOOLEAN_T
TrioReadWideString
TRIO_ARGS4((self, target, flags, width),
	   trio_class_t *self,
	   trio_wchar_t *target,
	   trio_flags_t flags,
	   int width)
{
  int i;
  int size;

  assert(VALID(self));
  assert(VALID(self->InStream));

  TrioSkipWhitespaces(self);

#if defined(TRIO_COMPILER_SUPPORTS_MULTIBYTE)
  (void)mblen(NULL, 0);
#endif

  /*
   * Continue until end of string is reached, a whitespace is encountered,
   * or width is exceeded
   */
  for (i = 0;
       ((width == NO_WIDTH) || (i < width)) &&
       (! ((self->current == EOF) || isspace(self->current)));
       )
    {
      size = TrioReadWideChar(self, &target[i], flags, 1);
      if (size == 0)
	break; /* for */

      i += size;
    }
  if (target)
    target[i] = WCONST('\0');
  return TRUE;
}
#endif /* TRIO_WIDECHAR */

/*************************************************************************
 * TrioReadGroup
 *
 * FIXME: characterclass does not work with multibyte characters
 */
TRIO_PRIVATE BOOLEAN_T
TrioReadGroup
TRIO_ARGS5((self, target, characterclass, flags, width),
	   trio_class_t *self,
	   char *target,
	   int *characterclass,
	   trio_flags_t flags,
	   int width)
{
  int ch;
  int i;

  assert(VALID(self));
  assert(VALID(self->InStream));

  ch = self->current;
  for (i = 0;
       ((width == NO_WIDTH) || (i < width)) &&
       (! ((ch == EOF) ||
	   (((flags & FLAGS_EXCLUDE) != 0) ^ (characterclass[ch] == 0))));
       i++)
    {
      if (target)
	target[i] = (char)ch;
      self->InStream(self, &ch);
    }

  if (target)
    target[i] = NIL;
  return TRUE;
}

/*************************************************************************
 * TrioReadDouble
 *
 * FIXME:
 *  add long double
 *  handle base
 */
TRIO_PRIVATE BOOLEAN_T
TrioReadDouble
TRIO_ARGS4((self, target, flags, width),
	   trio_class_t *self,
	   trio_pointer_t target,
	   trio_flags_t flags,
	   int width)
{
  int ch;
  char doubleString[512];
  int index = 0;
  int start;
  int j;
  BOOLEAN_T isHex = FALSE;

  doubleString[0] = 0;

  if ((width == NO_WIDTH) || (width > (int)sizeof(doubleString) - 1))
    width = sizeof(doubleString) - 1;

  TrioSkipWhitespaces(self);

  /*
   * Read entire double number from stream. trio_to_double requires
   * a string as input, but InStream can be anything, so we have to
   * collect all characters.
   */
  ch = self->current;
  if ((ch == '+') || (ch == '-'))
    {
      doubleString[index++] = (char)ch;
      self->InStream(self, &ch);
      width--;
    }

  start = index;
  switch (ch)
    {
    case 'n':
    case 'N':
      /* Not-a-number */
      if (index != 0)
	break;
      /* FALLTHROUGH */
    case 'i':
    case 'I':
      /* Infinity */
      while (isalpha(ch) && (index - start < width))
	{
	  doubleString[index++] = (char)ch;
	  self->InStream(self, &ch);
	}
      doubleString[index] = NIL;

      /* Case insensitive string comparison */
      if (trio_equal(&doubleString[start], INFINITE_UPPER) ||
	  trio_equal(&doubleString[start], LONG_INFINITE_UPPER))
	{
	  if (flags & FLAGS_LONGDOUBLE)
	    {
	      if ((start == 1) && (doubleString[0] == '-'))
		{
		  *((trio_long_double_t *)target) = trio_ninf();
		}
	      else
		{
		  *((trio_long_double_t *)target) = trio_pinf();
		}
	    }
	  else
	    {
	      if ((start == 1) && (doubleString[0] == '-'))
		{
		  *((double *)target) = trio_ninf();
		}
	      else
		{
		  *((double *)target) = trio_pinf();
		}
	    }
	  return TRUE;
	}
      if (trio_equal(doubleString, NAN_UPPER))
	{
	  /* NaN must not have a preceeding + nor - */
	  if (flags & FLAGS_LONGDOUBLE)
	    {
	      *((trio_long_double_t *)target) = trio_nan();
	    }
	  else
	    {
	      *((double *)target) = trio_nan();
	    }
	  return TRUE;
	}
      return FALSE;

    case '0':
      doubleString[index++] = (char)ch;
      self->InStream(self, &ch);
      if (trio_to_upper(ch) == 'X')
	{
	  isHex = TRUE;
	  doubleString[index++] = (char)ch;
	  self->InStream(self, &ch);
	}
      break;

    default:
      break;
    }

  while ((ch != EOF) && (index - start < width))
    {
      /* Integer part */
      if (isHex ? isxdigit(ch) : isdigit(ch))
	{
	  doubleString[index++] = (char)ch;
	  self->InStream(self, &ch);
	}
      else if (flags & FLAGS_QUOTE)
	{
	  /* Compare with thousands separator */
	  for (j = 0; internalThousandSeparator[j] && self->current; j++)
	    {
	      if (internalThousandSeparator[j] != self->current)
		break;

	      self->InStream(self, &ch);
	    }
	  if (internalThousandSeparator[j])
	    break; /* Mismatch */
	  else
	    continue; /* Match */
	}
      else
	break; /* while */
    }
  if (ch == '.')
    {
      /* Decimal part */
      doubleString[index++] = (char)ch;
      self->InStream(self, &ch);
      while ((isHex ? isxdigit(ch) : isdigit(ch)) &&
	     (index - start < width))
	{
	  doubleString[index++] = (char)ch;
	  self->InStream(self, &ch);
	}
      if (isHex ? (trio_to_upper(ch) == 'P') : (trio_to_upper(ch) == 'E'))
	{
	  /* Exponent */
	  doubleString[index++] = (char)ch;
	  self->InStream(self, &ch);
	  if ((ch == '+') || (ch == '-'))
	    {
	      doubleString[index++] = (char)ch;
	      self->InStream(self, &ch);
	    }
	  while (isdigit(ch) && (index - start < width))
	    {
	      doubleString[index++] = (char)ch;
	      self->InStream(self, &ch);
	    }
	}
    }

  if ((index == start) || (*doubleString == NIL))
    return FALSE;

  doubleString[index] = 0;

  if (flags & FLAGS_LONGDOUBLE)
    {
      *((trio_long_double_t *)target) = trio_to_long_double(doubleString, NULL);
    }
  else
    {
      *((double *)target) = trio_to_double(doubleString, NULL);
    }
  return TRUE;
}

/*************************************************************************
 * TrioReadPointer
 */
TRIO_PRIVATE BOOLEAN_T
TrioReadPointer
TRIO_ARGS3((self, target, flags),
	   trio_class_t *self,
	   trio_pointer_t *target,
	   trio_flags_t flags)
{
  trio_uintmax_t number;
  char buffer[sizeof(internalNullString)];

  flags |= (FLAGS_UNSIGNED | FLAGS_ALTERNATIVE | FLAGS_NILPADDING);

  if (TrioReadNumber(self,
		     &number,
		     flags,
		     POINTER_WIDTH,
		     BASE_HEX))
    {
      /*
       * The strange assignment of number is a workaround for a compiler
       * warning
       */
      if (target)
	*target = (char *)0 + number;
      return TRUE;
    }
  else if (TrioReadString(self,
			  (flags & FLAGS_IGNORE)
			  ? NULL
			  : buffer,
			  0,
			  sizeof(internalNullString) - 1))
    {
      if (trio_equal_case(buffer, internalNullString))
	{
	  if (target)
	    *target = NULL;
	  return TRUE;
	}
    }
  return FALSE;
}

/*************************************************************************
 * TrioScanProcess
 */
TRIO_PRIVATE int
TrioScanProcess
TRIO_ARGS3((data, format, parameters),
	   trio_class_t *data,
	   TRIO_CONST char *format,
	   trio_parameter_t *parameters)
{
#if defined(TRIO_COMPILER_SUPPORTS_MULTIBYTE)
  int charlen;
  int cnt;
#endif
  int assignment;
  int ch;
  int index; /* Index of format string */
  int i; /* Index of current parameter */
  trio_flags_t flags;
  int width;
  int base;
  trio_pointer_t pointer;

  assignment = 0;
  i = 0;
  index = 0;
  data->InStream(data, &ch);

#if defined(TRIO_COMPILER_SUPPORTS_MULTIBYTE)
  (void)mblen(NULL, 0);
#endif

  while (format[index])
    {
#if defined(TRIO_COMPILER_SUPPORTS_MULTIBYTE)
      if (! isascii(format[index]))
	{
	  charlen = mblen(&format[index], MB_LEN_MAX);
	  if (charlen != -1)
	    {
	      /* Compare multibyte characters in format string */
	      for (cnt = 0; cnt < charlen - 1; cnt++)
		{
		  if (ch != format[index + cnt])
		    {
		      return TRIO_ERROR_RETURN(TRIO_EINVAL, index);
		    }
		  data->InStream(data, &ch);
		}
	      continue; /* while characters left in formatting string */
	    }
	}
#endif /* TRIO_COMPILER_SUPPORTS_MULTIBYTE */

      if ((EOF == ch) && (parameters[i].type != FORMAT_COUNT))
	{
	  return (assignment > 0) ? assignment : EOF;
	}

      if (CHAR_IDENTIFIER == format[index])
	{
	  if (CHAR_IDENTIFIER == format[index + 1])
	    {
	      /* Two % in format matches one % in input stream */
	      if (CHAR_IDENTIFIER == ch)
		{
		  data->InStream(data, &ch);
		  index += 2;
		  continue; /* while format chars left */
		}
	      else
		return TRIO_ERROR_RETURN(TRIO_EINVAL, index);
	    }

	  /* Skip the parameter entries */
	  while (parameters[i].type == FORMAT_PARAMETER)
	    i++;

	  flags = parameters[i].flags;
	  /* Find width */
	  width = parameters[i].width;
	  if (flags & FLAGS_WIDTH_PARAMETER)
	    {
	      /* Get width from parameter list */
	      width = (int)parameters[width].data.number.as_signed;
	    }
	  /* Find base */
	  base = parameters[i].base;
	  if (flags & FLAGS_BASE_PARAMETER)
	    {
	      /* Get base from parameter list */
	      base = (int)parameters[base].data.number.as_signed;
	    }

	  switch (parameters[i].type)
	    {
	    case FORMAT_INT:
	      {
		trio_uintmax_t number;

		if (0 == base)
		  base = BASE_DECIMAL;

		if (!TrioReadNumber(data,
				    &number,
				    flags,
				    width,
				    base))
		  return assignment;

		if (!(flags & FLAGS_IGNORE))
		  {
		    assignment++;

		    pointer = parameters[i].data.pointer;
#if defined(QUALIFIER_SIZE_T) || defined(QUALIFIER_SIZE_T_UPPER)
		    if (flags & FLAGS_SIZE_T)
		      *(size_t *)pointer = (size_t)number;
		    else
#endif
#if defined(QUALIFIER_PTRDIFF_T)
		    if (flags & FLAGS_PTRDIFF_T)
		      *(ptrdiff_t *)pointer = (ptrdiff_t)number;
		    else
#endif
#if defined(QUALIFIER_INTMAX_T)
		    if (flags & FLAGS_INTMAX_T)
		      *(trio_intmax_t *)pointer = (trio_intmax_t)number;
		    else
#endif
		    if (flags & FLAGS_QUAD)
		      *(trio_ulonglong_t *)pointer = (trio_ulonglong_t)number;
		    else if (flags & FLAGS_LONG)
		      *(long int *)pointer = (long int)number;
		    else if (flags & FLAGS_SHORT)
		      *(short int *)pointer = (short int)number;
		    else
		      *(int *)pointer = (int)number;
		  }
	      }
	      break; /* FORMAT_INT */

	    case FORMAT_STRING:
#if TRIO_WIDECHAR
	      if (flags & FLAGS_WIDECHAR)
		{
		  if (!TrioReadWideString(data,
					  (flags & FLAGS_IGNORE)
					  ? NULL
					  : parameters[i].data.wstring,
					  flags,
					  width))
		    return assignment;
		}
	      else
#endif
		{
		  if (!TrioReadString(data,
				      (flags & FLAGS_IGNORE)
				      ? NULL
				      : parameters[i].data.string,
				      flags,
				      width))
		    return assignment;
		}
	      if (!(flags & FLAGS_IGNORE))
		assignment++;
	      break; /* FORMAT_STRING */

	    case FORMAT_DOUBLE:
	      {
		trio_pointer_t pointer;

		if (flags & FLAGS_IGNORE)
		  {
		    pointer = NULL;
		  }
		else
		  {
		    pointer = (flags & FLAGS_LONGDOUBLE)
		      ? (trio_pointer_t)parameters[i].data.longdoublePointer
		      : (trio_pointer_t)parameters[i].data.doublePointer;
		  }
		if (!TrioReadDouble(data, pointer, flags, width))
		  {
		    return assignment;
		  }
		if (!(flags & FLAGS_IGNORE))
		  {
		    assignment++;
		  }
		break; /* FORMAT_DOUBLE */
	      }
	    case FORMAT_GROUP:
	      {
		int characterclass[MAX_CHARACTER_CLASS + 1];
		int rc;

		/* Skip over modifiers */
		while (format[index] != SPECIFIER_GROUP)
		  {
		    index++;
		  }
		/* Skip over group specifier */
		index++;

		memset(characterclass, 0, sizeof(characterclass));
		rc = TrioGetCharacterClass(format,
					   &index,
					   &flags,
					   characterclass);
		if (rc < 0)
		  return rc;

		if (!TrioReadGroup(data,
				   (flags & FLAGS_IGNORE)
				   ? NULL
				   : parameters[i].data.string,
				   characterclass,
				   flags,
				   parameters[i].width))
		  return assignment;
		if (!(flags & FLAGS_IGNORE))
		  assignment++;
	      }
	      break; /* FORMAT_GROUP */

	    case FORMAT_COUNT:
	      pointer = parameters[i].data.pointer;
	      if (NULL != pointer)
		{
		  int count = data->committed;
		  if (ch != EOF)
		    count--; /* a character is read, but is not consumed yet */
#if defined(QUALIFIER_SIZE_T) || defined(QUALIFIER_SIZE_T_UPPER)
		  if (flags & FLAGS_SIZE_T)
		    *(size_t *)pointer = (size_t)count;
		  else
#endif
#if defined(QUALIFIER_PTRDIFF_T)
		  if (flags & FLAGS_PTRDIFF_T)
		    *(ptrdiff_t *)pointer = (ptrdiff_t)count;
		  else
#endif
#if defined(QUALIFIER_INTMAX_T)
		  if (flags & FLAGS_INTMAX_T)
		    *(trio_intmax_t *)pointer = (trio_intmax_t)count;
		  else
#endif
		  if (flags & FLAGS_QUAD)
		    {
		      *(trio_ulonglong_t *)pointer = (trio_ulonglong_t)count;
		    }
		  else if (flags & FLAGS_LONG)
		    {
		      *(long int *)pointer = (long int)count;
		    }
		  else if (flags & FLAGS_SHORT)
		    {
		      *(short int *)pointer = (short int)count;
		    }
		  else
		    {
		      *(int *)pointer = (int)count;
		    }
		}
	      break; /* FORMAT_COUNT */

	    case FORMAT_CHAR:
#if TRIO_WIDECHAR
	      if (flags & FLAGS_WIDECHAR)
		{
		  if (TrioReadWideChar(data,
				       (flags & FLAGS_IGNORE)
				       ? NULL
				       : parameters[i].data.wstring,
				       flags,
				       (width == NO_WIDTH) ? 1 : width) == 0)
		    return assignment;
		}
	      else
#endif
		{
		  if (TrioReadChar(data,
				   (flags & FLAGS_IGNORE)
				   ? NULL
				   : parameters[i].data.string,
				   flags,
				   (width == NO_WIDTH) ? 1 : width) == 0)
		    return assignment;
		}
	      if (!(flags & FLAGS_IGNORE))
		assignment++;
	      break; /* FORMAT_CHAR */

	    case FORMAT_POINTER:
	      if (!TrioReadPointer(data,
				   (flags & FLAGS_IGNORE)
				   ? NULL
				   : (trio_pointer_t *)parameters[i].data.pointer,
				   flags))
		return assignment;
	      if (!(flags & FLAGS_IGNORE))
		assignment++;
	      break; /* FORMAT_POINTER */

	    case FORMAT_PARAMETER:
	      break; /* FORMAT_PARAMETER */

	    default:
	      return TRIO_ERROR_RETURN(TRIO_EINVAL, index);
	    }
	  ch = data->current;
	  index = parameters[i].indexAfterSpecifier;
	  i++;
	}
      else /* Not an % identifier */
	{
	  if (isspace((int)format[index]))
	    {
	      /* Whitespaces may match any amount of whitespaces */
	      ch = TrioSkipWhitespaces(data);
	    }
	  else if (ch == format[index])
	    {
	      data->InStream(data, &ch);
	    }
	  else
	    return assignment;

	  index++;
	}
    }
  return assignment;
}

/*************************************************************************
 * TrioScan
 */
TRIO_PRIVATE int
TrioScan
TRIO_ARGS6((source, sourceSize, InStream, format, arglist, argarray),
	   trio_pointer_t source,
	   size_t sourceSize,
	   void (*InStream) TRIO_PROTO((trio_class_t *, int *)),
	   TRIO_CONST char *format,
	   TRIO_VA_LIST_PTR arglist,
	   trio_pointer_t *argarray)
{
  int status;
  trio_parameter_t parameters[MAX_PARAMETERS];
  trio_class_t data;

  assert(VALID(InStream));
  assert(VALID(format));

  memset(&data, 0, sizeof(data));
  data.InStream = InStream;
  data.location = (trio_pointer_t)source;
  data.max = sourceSize;
  data.error = 0;

#if defined(USE_LOCALE)
  if (NULL == internalLocaleValues)
    {
      TrioSetLocale();
    }
#endif

  status = TrioParse(TYPE_SCAN, format, parameters, arglist, argarray);
  if (status < 0)
    return status;

  status = TrioScanProcess(&data, format, parameters);
  if (data.error != 0)
    {
      status = data.error;
    }
  return status;
}

/*************************************************************************
 * TrioInStreamFile
 */
TRIO_PRIVATE void
TrioInStreamFile
TRIO_ARGS2((self, intPointer),
	   trio_class_t *self,
	   int *intPointer)
{
  FILE *file;

  assert(VALID(self));
  assert(VALID(self->location));
  assert(VALID(file));

  file = (FILE *)self->location;

  self->current = fgetc(file);
  if (self->current == EOF)
    {
      self->error = (ferror(file))
	? TRIO_ERROR_RETURN(TRIO_ERRNO, 0)
	: TRIO_ERROR_RETURN(TRIO_EOF, 0);
    }
  else
    {
      self->processed++;
      self->committed++;
    }

  if (VALID(intPointer))
    {
      *intPointer = self->current;
    }
}

/*************************************************************************
 * TrioInStreamFileDescriptor
 */
TRIO_PRIVATE void
TrioInStreamFileDescriptor
TRIO_ARGS2((self, intPointer),
	   trio_class_t *self,
	   int *intPointer)
{
  int fd;
  int size;
  unsigned char input;

  assert(VALID(self));
  assert(VALID(self->location));

  fd = *((int *)self->location);

  size = read(fd, &input, sizeof(char));
  if (size == -1)
    {
      self->error = TRIO_ERROR_RETURN(TRIO_ERRNO, 0);
      self->current = EOF;
    }
  else
    {
      self->current = (size == 0) ? EOF : input;
    }
  if (self->current != EOF)
    {
      self->committed++;
      self->processed++;
    }

  if (VALID(intPointer))
    {
      *intPointer = self->current;
    }
}

/*************************************************************************
 * TrioInStreamCustom
 */
TRIO_PRIVATE void
TrioInStreamCustom
TRIO_ARGS2((self, intPointer),
	   trio_class_t *self,
	   int *intPointer)
{
  trio_custom_t *data;

  assert(VALID(self));
  assert(VALID(self->location));

  data = (trio_custom_t *)self->location;

  self->current = (data->stream.in == NULL)
    ? NIL
    : (data->stream.in)(data->closure);

  if (self->current == NIL)
    {
      self->current = EOF;
    }
  else
    {
      self->processed++;
      self->committed++;
    }

  if (VALID(intPointer))
    {
      *intPointer = self->current;
    }
}

/*************************************************************************
 * TrioInStreamString
 */
TRIO_PRIVATE void
TrioInStreamString
TRIO_ARGS2((self, intPointer),
	   trio_class_t *self,
	   int *intPointer)
{
  unsigned char **buffer;

  assert(VALID(self));
  assert(VALID(self->location));

  buffer = (unsigned char **)self->location;
  self->current = (*buffer)[0];
  if (self->current == NIL)
    {
      self->current = EOF;
    }
  else
    {
      (*buffer)++;
      self->processed++;
      self->committed++;
    }

  if (VALID(intPointer))
    {
      *intPointer = self->current;
    }
}

/*************************************************************************
 *
 * Formatted scanning functions
 *
 ************************************************************************/

#if defined(TRIO_DOCUMENTATION)
# include "doc/doc_scanf.h"
#endif
/** @addtogroup Scanf
    @{
*/

/*************************************************************************
 * scanf
 */

/**
   Scan characters from standard input stream.

   @param format Formatting string.
   @param ... Arguments.
   @return Number of scanned characters.
 */
TRIO_PUBLIC int
trio_scanf
TRIO_VARGS2((format, va_alist),
	    TRIO_CONST char *format,
	    TRIO_VA_DECL)
{
  int status;
  va_list args;

  assert(VALID(format));

  TRIO_VA_START(args, format);
  status = TrioScan((trio_pointer_t)stdin, 0,
		    TrioInStreamFile,
		    format, TRIO_VA_LIST_ADDR(args), NULL);
  TRIO_VA_END(args);
  return status;
}

TRIO_PUBLIC int
trio_vscanf
TRIO_ARGS2((format, args),
	   TRIO_CONST char *format,
	   va_list args)
{
  assert(VALID(format));

  return TrioScan((trio_pointer_t)stdin, 0,
		  TrioInStreamFile,
		  format, TRIO_VA_LIST_ADDR(args), NULL);
}

TRIO_PUBLIC int
trio_scanfv
TRIO_ARGS2((format, args),
	   TRIO_CONST char *format,
	   trio_pointer_t *args)
{
  assert(VALID(format));

  return TrioScan((trio_pointer_t)stdin, 0,
		  TrioInStreamFile,
		  format, NULL, args);
}

/*************************************************************************
 * fscanf
 */
TRIO_PUBLIC int
trio_fscanf
TRIO_VARGS3((file, format, va_alist),
	    FILE *file,
	    TRIO_CONST char *format,
	    TRIO_VA_DECL)
{
  int status;
  va_list args;

  assert(VALID(file));
  assert(VALID(format));

  TRIO_VA_START(args, format);
  status = TrioScan((trio_pointer_t)file, 0,
		    TrioInStreamFile,
		    format, TRIO_VA_LIST_ADDR(args), NULL);
  TRIO_VA_END(args);
  return status;
}

TRIO_PUBLIC int
trio_vfscanf
TRIO_ARGS3((file, format, args),
	   FILE *file,
	   TRIO_CONST char *format,
	   va_list args)
{
  assert(VALID(file));
  assert(VALID(format));

  return TrioScan((trio_pointer_t)file, 0,
		  TrioInStreamFile,
		  format, TRIO_VA_LIST_ADDR(args), NULL);
}

TRIO_PUBLIC int
trio_fscanfv
TRIO_ARGS3((file, format, args),
	   FILE *file,
	   TRIO_CONST char *format,
	   trio_pointer_t *args)
{
  assert(VALID(file));
  assert(VALID(format));

  return TrioScan((trio_pointer_t)file, 0,
		  TrioInStreamFile,
		  format, NULL, args);
}

/*************************************************************************
 * dscanf
 */
TRIO_PUBLIC int
trio_dscanf
TRIO_VARGS3((fd, format, va_alist),
	    int fd,
	    TRIO_CONST char *format,
	    TRIO_VA_DECL)
{
  int status;
  va_list args;

  assert(VALID(format));

  TRIO_VA_START(args, format);
  status = TrioScan((trio_pointer_t)&fd, 0,
		    TrioInStreamFileDescriptor,
		    format, TRIO_VA_LIST_ADDR(args), NULL);
  TRIO_VA_END(args);
  return status;
}

TRIO_PUBLIC int
trio_vdscanf
TRIO_ARGS3((fd, format, args),
	   int fd,
	   TRIO_CONST char *format,
	   va_list args)
{
  assert(VALID(format));

  return TrioScan((trio_pointer_t)&fd, 0,
		  TrioInStreamFileDescriptor,
		  format, TRIO_VA_LIST_ADDR(args), NULL);
}

TRIO_PUBLIC int
trio_dscanfv
TRIO_ARGS3((fd, format, args),
	   int fd,
	   TRIO_CONST char *format,
	   trio_pointer_t *args)
{
  assert(VALID(format));

  return TrioScan((trio_pointer_t)&fd, 0,
		  TrioInStreamFileDescriptor,
		  format, NULL, args);
}

/*************************************************************************
 * cscanf
 */
TRIO_PUBLIC int
trio_cscanf
TRIO_VARGS4((stream, closure, format, va_alist),
	    trio_instream_t stream,
	    trio_pointer_t closure,
	    TRIO_CONST char *format,
	    TRIO_VA_DECL)
{
  int status;
  va_list args;
  trio_custom_t data;

  assert(VALID(stream));
  assert(VALID(format));

  TRIO_VA_START(args, format);
  data.stream.in = stream;
  data.closure = closure;
  status = TrioScan(&data, 0, TrioInStreamCustom, format, TRIO_VA_LIST_ADDR(args), NULL);
  TRIO_VA_END(args);
  return status;
}

TRIO_PUBLIC int
trio_vcscanf
TRIO_ARGS4((stream, closure, format, args),
	   trio_instream_t stream,
	   trio_pointer_t closure,
	   TRIO_CONST char *format,
	   va_list args)
{
  trio_custom_t data;

  assert(VALID(stream));
  assert(VALID(format));

  data.stream.in = stream;
  data.closure = closure;
  return TrioScan(&data, 0, TrioInStreamCustom, format, TRIO_VA_LIST_ADDR(args), NULL);
}

TRIO_PUBLIC int
trio_cscanfv
TRIO_ARGS4((stream, closure, format, args),
	   trio_instream_t stream,
	   trio_pointer_t closure,
	   TRIO_CONST char *format,
	   trio_pointer_t *args)
{
  trio_custom_t data;

  assert(VALID(stream));
  assert(VALID(format));

  data.stream.in = stream;
  data.closure = closure;
  return TrioScan(&data, 0, TrioInStreamCustom, format, NULL, args);
}

/*************************************************************************
 * sscanf
 */
TRIO_PUBLIC int
trio_sscanf
TRIO_VARGS3((buffer, format, va_alist),
	    TRIO_CONST char *buffer,
	    TRIO_CONST char *format,
	    TRIO_VA_DECL)
{
  int status;
  va_list args;

  assert(VALID(buffer));
  assert(VALID(format));

  TRIO_VA_START(args, format);
  status = TrioScan((trio_pointer_t)&buffer, 0,
		    TrioInStreamString,
		    format, TRIO_VA_LIST_ADDR(args), NULL);
  TRIO_VA_END(args);
  return status;
}

TRIO_PUBLIC int
trio_vsscanf
TRIO_ARGS3((buffer, format, args),
	   TRIO_CONST char *buffer,
	   TRIO_CONST char *format,
	   va_list args)
{
  assert(VALID(buffer));
  assert(VALID(format));

  return TrioScan((trio_pointer_t)&buffer, 0,
		  TrioInStreamString,
		  format, TRIO_VA_LIST_ADDR(args), NULL);
}

TRIO_PUBLIC int
trio_sscanfv
TRIO_ARGS3((buffer, format, args),
	   TRIO_CONST char *buffer,
	   TRIO_CONST char *format,
	   trio_pointer_t *args)
{
  assert(VALID(buffer));
  assert(VALID(format));

  return TrioScan((trio_pointer_t)&buffer, 0,
		  TrioInStreamString,
		  format, NULL, args);
}

/** @} End of Scanf documentation module */

/*************************************************************************
 * trio_strerror
 */
TRIO_PUBLIC TRIO_CONST char *
trio_strerror
TRIO_ARGS1((errorcode),
	   int errorcode)
{
  /* Textual versions of the error codes */
  switch (TRIO_ERROR_CODE(errorcode))
    {
    case TRIO_EOF:
      return "End of file";
    case TRIO_EINVAL:
      return "Invalid argument";
    case TRIO_ETOOMANY:
      return "Too many arguments";
    case TRIO_EDBLREF:
      return "Double reference";
    case TRIO_EGAP:
      return "Reference gap";
    case TRIO_ENOMEM:
      return "Out of memory";
    case TRIO_ERANGE:
      return "Invalid range";
    case TRIO_ECUSTOM:
      return "Custom error";
    default:
      return "Unknown";
    }
}
