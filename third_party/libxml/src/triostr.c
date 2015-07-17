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

/*************************************************************************
 * Include files
 */

#include <assert.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <math.h>
#include "triodef.h"
#include "triostr.h"

/*************************************************************************
 * Definitions
 */

#if !defined(TRIO_STRING_PUBLIC)
# define TRIO_STRING_PUBLIC TRIO_PUBLIC
#endif
#if !defined(TRIO_STRING_PRIVATE)
# define TRIO_STRING_PRIVATE TRIO_PRIVATE
#endif

#if !defined(NULL)
# define NULL 0
#endif
#if !defined(NIL)
# define NIL ((char)0)
#endif
#if !defined(FALSE)
# define FALSE (1 == 0)
# define TRUE (! FALSE)
#endif
#if !defined(BOOLEAN_T)
# define BOOLEAN_T int
#endif

#ifdef __VMS
# define USE_STRTOD
#elif defined(TRIO_COMPILER_SUPPORTS_C99)
# define USE_STRTOD
# define USE_STRTOF
#elif defined(TRIO_COMPILER_MSVC)
# define USE_STRTOD
#endif

#if defined(TRIO_PLATFORM_UNIX)
# define USE_STRCASECMP
# define USE_STRNCASECMP
# if defined(TRIO_PLATFORM_SUNOS)
#  define USE_SYS_ERRLIST
# else
#  define USE_STRERROR
# endif
# if defined(TRIO_PLATFORM_QNX)
#  define strcasecmp(x,y) stricmp(x,y)
#  define strncasecmp(x,y,n) strnicmp(x,y,n)
# endif
#elif defined(TRIO_PLATFORM_WIN32)
# define USE_STRCASECMP
# if defined(_WIN32_WCE)
#  define strcasecmp(x,y) _stricmp(x,y)
# else
#  define strcasecmp(x,y) strcmpi(x,y)
# endif
#elif defined(TRIO_PLATFORM_OS400)
# define USE_STRCASECMP
# define USE_STRNCASECMP
# include <strings.h>
#endif

#if !(defined(TRIO_PLATFORM_SUNOS))
# define USE_TOLOWER
# define USE_TOUPPER
#endif

/*************************************************************************
 * Structures
 */

struct _trio_string_t
{
  char *content;
  size_t length;
  size_t allocated;
};

/*************************************************************************
 * Constants
 */

#if !defined(TRIO_MINIMAL)
static TRIO_CONST char rcsid[] = "@(#)$Id$";
#endif

/*************************************************************************
 * Static String Functions
 */

#if defined(TRIO_DOCUMENTATION)
# include "doc/doc_static.h"
#endif
/** @addtogroup StaticStrings
    @{
*/

/**
   Create new string.

   @param size Size of new string.
   @return Pointer to string, or NULL if allocation failed.
*/
TRIO_STRING_PUBLIC char *
trio_create
TRIO_ARGS1((size),
	   size_t size)
{
  return (char *)TRIO_MALLOC(size);
}


/**
   Destroy string.

   @param string String to be freed.
*/
TRIO_STRING_PUBLIC void
trio_destroy
TRIO_ARGS1((string),
	   char *string)
{
  if (string)
    {
      TRIO_FREE(string);
    }
}


/**
   Count the number of characters in a string.

   @param string String to measure.
   @return Number of characters in @string.
*/
TRIO_STRING_PUBLIC size_t
trio_length
TRIO_ARGS1((string),
	   TRIO_CONST char *string)
{
  return strlen(string);
}


#if !defined(TRIO_MINIMAL)
/**
   Append @p source at the end of @p target.

   @param target Target string.
   @param source Source string.
   @return Boolean value indicating success or failure.

   @pre @p target must point to a memory chunk with sufficient room to
   contain the @p target string and @p source string.
   @pre No boundary checking is performed, so insufficient memory will
   result in a buffer overrun.
   @post @p target will be zero terminated.
*/
TRIO_STRING_PUBLIC int
trio_append
TRIO_ARGS2((target, source),
	   char *target,
	   TRIO_CONST char *source)
{
  assert(target);
  assert(source);

  return (strcat(target, source) != NULL);
}
#endif /* !defined(TRIO_MINIMAL) */

#if !defined(TRIO_MINIMAL)
/**
   Append at most @p max characters from @p source to @p target.

   @param target Target string.
   @param max Maximum number of characters to append.
   @param source Source string.
   @return Boolean value indicating success or failure.

   @pre @p target must point to a memory chuck with sufficient room to
   contain the @p target string and the @p source string (at most @p max
   characters).
   @pre No boundary checking is performed, so insufficient memory will
   result in a buffer overrun.
   @post @p target will be zero terminated.
*/
TRIO_STRING_PUBLIC int
trio_append_max
TRIO_ARGS3((target, max, source),
	   char *target,
	   size_t max,
	   TRIO_CONST char *source)
{
  size_t length;

  assert(target);
  assert(source);

  length = trio_length(target);

  if (max > length)
    {
      strncat(target, source, max - length - 1);
    }
  return TRUE;
}
#endif /* !defined(TRIO_MINIMAL) */


#if !defined(TRIO_MINIMAL)
/**
   Determine if a string contains a substring.

   @param string String to be searched.
   @param substring String to be found.
   @return Boolean value indicating success or failure.
*/
TRIO_STRING_PUBLIC int
trio_contains
TRIO_ARGS2((string, substring),
	   TRIO_CONST char *string,
	   TRIO_CONST char *substring)
{
  assert(string);
  assert(substring);

  return (0 != strstr(string, substring));
}
#endif /* !defined(TRIO_MINIMAL) */


#if !defined(TRIO_MINIMAL)
/**
   Copy @p source to @p target.

   @param target Target string.
   @param source Source string.
   @return Boolean value indicating success or failure.

   @pre @p target must point to a memory chunk with sufficient room to
   contain the @p source string.
   @pre No boundary checking is performed, so insufficient memory will
   result in a buffer overrun.
   @post @p target will be zero terminated.
*/
TRIO_STRING_PUBLIC int
trio_copy
TRIO_ARGS2((target, source),
	   char *target,
	   TRIO_CONST char *source)
{
  assert(target);
  assert(source);

  (void)strcpy(target, source);
  return TRUE;
}
#endif /* !defined(TRIO_MINIMAL) */


/**
   Copy at most @p max characters from @p source to @p target.

   @param target Target string.
   @param max Maximum number of characters to append.
   @param source Source string.
   @return Boolean value indicating success or failure.

   @pre @p target must point to a memory chunk with sufficient room to
   contain the @p source string (at most @p max characters).
   @pre No boundary checking is performed, so insufficient memory will
   result in a buffer overrun.
   @post @p target will be zero terminated.
*/
TRIO_STRING_PUBLIC int
trio_copy_max
TRIO_ARGS3((target, max, source),
	   char *target,
	   size_t max,
	   TRIO_CONST char *source)
{
  assert(target);
  assert(source);
  assert(max > 0); /* Includes != 0 */

  (void)strncpy(target, source, max - 1);
  target[max - 1] = (char)0;
  return TRUE;
}


/*
 * TrioDuplicateMax
 */
TRIO_STRING_PRIVATE char *
TrioDuplicateMax
TRIO_ARGS2((source, size),
	   TRIO_CONST char *source,
	   size_t size)
{
  char *target;

  assert(source);

  /* Make room for string plus a terminating zero */
  size++;
  target = trio_create(size);
  if (target)
    {
      trio_copy_max(target, size, source);
    }
  return target;
}


/**
   Duplicate @p source.

   @param source Source string.
   @return A copy of the @p source string.

   @post @p target will be zero terminated.
*/
TRIO_STRING_PUBLIC char *
trio_duplicate
TRIO_ARGS1((source),
	   TRIO_CONST char *source)
{
  return TrioDuplicateMax(source, trio_length(source));
}


#if !defined(TRIO_MINIMAL)
/**
   Duplicate at most @p max characters of @p source.

   @param source Source string.
   @param max Maximum number of characters to duplicate.
   @return A copy of the @p source string.

   @post @p target will be zero terminated.
*/
TRIO_STRING_PUBLIC char *
trio_duplicate_max TRIO_ARGS2((source, max),
			      TRIO_CONST char *source,
			      size_t max)
{
  size_t length;

  assert(source);
  assert(max > 0);

  length = trio_length(source);
  if (length > max)
    {
      length = max;
    }
  return TrioDuplicateMax(source, length);
}
#endif /* !defined(TRIO_MINIMAL) */


/**
   Compare if two strings are equal.

   @param first First string.
   @param second Second string.
   @return Boolean indicating whether the two strings are equal or not.

   Case-insensitive comparison.
*/
TRIO_STRING_PUBLIC int
trio_equal
TRIO_ARGS2((first, second),
	   TRIO_CONST char *first,
	   TRIO_CONST char *second)
{
  assert(first);
  assert(second);

  if ((first != NULL) && (second != NULL))
    {
#if defined(USE_STRCASECMP)
      return (0 == strcasecmp(first, second));
#else
      while ((*first != NIL) && (*second != NIL))
	{
	  if (trio_to_upper(*first) != trio_to_upper(*second))
	    {
	      break;
	    }
	  first++;
	  second++;
	}
      return ((*first == NIL) && (*second == NIL));
#endif
    }
  return FALSE;
}


/**
   Compare if two strings are equal.

   @param first First string.
   @param second Second string.
   @return Boolean indicating whether the two strings are equal or not.

   Case-sensitive comparison.
*/
TRIO_STRING_PUBLIC int
trio_equal_case
TRIO_ARGS2((first, second),
	   TRIO_CONST char *first,
	   TRIO_CONST char *second)
{
  assert(first);
  assert(second);

  if ((first != NULL) && (second != NULL))
    {
      return (0 == strcmp(first, second));
    }
  return FALSE;
}


#if !defined(TRIO_MINIMAL)
/**
   Compare if two strings up until the first @p max characters are equal.

   @param first First string.
   @param max Maximum number of characters to compare.
   @param second Second string.
   @return Boolean indicating whether the two strings are equal or not.

   Case-sensitive comparison.
*/
TRIO_STRING_PUBLIC int
trio_equal_case_max
TRIO_ARGS3((first, max, second),
	   TRIO_CONST char *first,
	   size_t max,
	   TRIO_CONST char *second)
{
  assert(first);
  assert(second);

  if ((first != NULL) && (second != NULL))
    {
      return (0 == strncmp(first, second, max));
    }
  return FALSE;
}
#endif /* !defined(TRIO_MINIMAL) */


/**
   Compare if two strings are equal.

   @param first First string.
   @param second Second string.
   @return Boolean indicating whether the two strings are equal or not.

   Collating characters are considered equal.
*/
TRIO_STRING_PUBLIC int
trio_equal_locale
TRIO_ARGS2((first, second),
	   TRIO_CONST char *first,
	   TRIO_CONST char *second)
{
  assert(first);
  assert(second);

#if defined(LC_COLLATE)
  return (strcoll(first, second) == 0);
#else
  return trio_equal(first, second);
#endif
}


/**
   Compare if two strings up until the first @p max characters are equal.

   @param first First string.
   @param max Maximum number of characters to compare.
   @param second Second string.
   @return Boolean indicating whether the two strings are equal or not.

   Case-insensitive comparison.
*/
TRIO_STRING_PUBLIC int
trio_equal_max
TRIO_ARGS3((first, max, second),
	   TRIO_CONST char *first,
	   size_t max,
	   TRIO_CONST char *second)
{
  assert(first);
  assert(second);

  if ((first != NULL) && (second != NULL))
    {
#if defined(USE_STRNCASECMP)
      return (0 == strncasecmp(first, second, max));
#else
      /* Not adequately tested yet */
      size_t cnt = 0;
      while ((*first != NIL) && (*second != NIL) && (cnt <= max))
	{
	  if (trio_to_upper(*first) != trio_to_upper(*second))
	    {
	      break;
	    }
	  first++;
	  second++;
	  cnt++;
	}
      return ((cnt == max) || ((*first == NIL) && (*second == NIL)));
#endif
    }
  return FALSE;
}


/**
   Provide a textual description of an error code (errno).

   @param error_number Error number.
   @return Textual description of @p error_number.
*/
TRIO_STRING_PUBLIC TRIO_CONST char *
trio_error
TRIO_ARGS1((error_number),
	   int error_number)
{
#if defined(USE_STRERROR)

  return strerror(error_number);

#elif defined(USE_SYS_ERRLIST)

  extern char *sys_errlist[];
  extern int sys_nerr;

  return ((error_number < 0) || (error_number >= sys_nerr))
    ? "unknown"
    : sys_errlist[error_number];

#else

  return "unknown";

#endif
}


#if !defined(TRIO_MINIMAL) && !defined(_WIN32_WCE)
/**
   Format the date/time according to @p format.

   @param target Target string.
   @param max Maximum number of characters to format.
   @param format Formatting string.
   @param datetime Date/time structure.
   @return Number of formatted characters.

   The formatting string accepts the same specifiers as the standard C
   function strftime.
*/
TRIO_STRING_PUBLIC size_t
trio_format_date_max
TRIO_ARGS4((target, max, format, datetime),
	   char *target,
	   size_t max,
	   TRIO_CONST char *format,
	   TRIO_CONST struct tm *datetime)
{
  assert(target);
  assert(format);
  assert(datetime);
  assert(max > 0);

  return strftime(target, max, format, datetime);
}
#endif /* !defined(TRIO_MINIMAL) */


#if !defined(TRIO_MINIMAL)
/**
   Calculate a hash value for a string.

   @param string String to be calculated on.
   @param type Hash function.
   @return Calculated hash value.

   @p type can be one of the following
   @li @c TRIO_HASH_PLAIN Plain hash function.
*/
TRIO_STRING_PUBLIC unsigned long
trio_hash
TRIO_ARGS2((string, type),
	   TRIO_CONST char *string,
	   int type)
{
  unsigned long value = 0L;
  char ch;

  assert(string);

  switch (type)
    {
    case TRIO_HASH_PLAIN:
      while ( (ch = *string++) != NIL )
	{
	  value *= 31;
	  value += (unsigned long)ch;
	}
      break;
    default:
      assert(FALSE);
      break;
    }
  return value;
}
#endif /* !defined(TRIO_MINIMAL) */


#if !defined(TRIO_MINIMAL)
/**
   Find first occurrence of a character in a string.

   @param string String to be searched.
   @param character Character to be found.
   @param A pointer to the found character, or NULL if character was not found.
 */
TRIO_STRING_PUBLIC char *
trio_index
TRIO_ARGS2((string, character),
	   TRIO_CONST char *string,
	   int character)
{
  assert(string);

  return strchr(string, character);
}
#endif /* !defined(TRIO_MINIMAL) */


#if !defined(TRIO_MINIMAL)
/**
   Find last occurrence of a character in a string.

   @param string String to be searched.
   @param character Character to be found.
   @param A pointer to the found character, or NULL if character was not found.
 */
TRIO_STRING_PUBLIC char *
trio_index_last
TRIO_ARGS2((string, character),
	   TRIO_CONST char *string,
	   int character)
{
  assert(string);

  return strchr(string, character);
}
#endif /* !defined(TRIO_MINIMAL) */


#if !defined(TRIO_MINIMAL)
/**
   Convert the alphabetic letters in the string to lower-case.

   @param target String to be converted.
   @return Number of processed characters (converted or not).
*/
TRIO_STRING_PUBLIC int
trio_lower
TRIO_ARGS1((target),
	   char *target)
{
  assert(target);

  return trio_span_function(target, target, trio_to_lower);
}
#endif /* !defined(TRIO_MINIMAL) */


#if !defined(TRIO_MINIMAL)
/**
   Compare two strings using wildcards.

   @param string String to be searched.
   @param pattern Pattern, including wildcards, to search for.
   @return Boolean value indicating success or failure.

   Case-insensitive comparison.

   The following wildcards can be used
   @li @c * Match any number of characters.
   @li @c ? Match a single character.
*/
TRIO_STRING_PUBLIC int
trio_match
TRIO_ARGS2((string, pattern),
	   TRIO_CONST char *string,
	   TRIO_CONST char *pattern)
{
  assert(string);
  assert(pattern);

  for (; ('*' != *pattern); ++pattern, ++string)
    {
      if (NIL == *string)
	{
	  return (NIL == *pattern);
	}
      if ((trio_to_upper((int)*string) != trio_to_upper((int)*pattern))
	  && ('?' != *pattern))
	{
	  return FALSE;
	}
    }
  /* two-line patch to prevent *too* much recursiveness: */
  while ('*' == pattern[1])
    pattern++;

  do
    {
      if ( trio_match(string, &pattern[1]) )
	{
	  return TRUE;
	}
    }
  while (*string++);

  return FALSE;
}
#endif /* !defined(TRIO_MINIMAL) */


#if !defined(TRIO_MINIMAL)
/**
   Compare two strings using wildcards.

   @param string String to be searched.
   @param pattern Pattern, including wildcards, to search for.
   @return Boolean value indicating success or failure.

   Case-sensitive comparison.

   The following wildcards can be used
   @li @c * Match any number of characters.
   @li @c ? Match a single character.
*/
TRIO_STRING_PUBLIC int
trio_match_case
TRIO_ARGS2((string, pattern),
	   TRIO_CONST char *string,
	   TRIO_CONST char *pattern)
{
  assert(string);
  assert(pattern);

  for (; ('*' != *pattern); ++pattern, ++string)
    {
      if (NIL == *string)
	{
	  return (NIL == *pattern);
	}
      if ((*string != *pattern)
	  && ('?' != *pattern))
	{
	  return FALSE;
	}
    }
  /* two-line patch to prevent *too* much recursiveness: */
  while ('*' == pattern[1])
    pattern++;

  do
    {
      if ( trio_match_case(string, &pattern[1]) )
	{
	  return TRUE;
	}
    }
  while (*string++);

  return FALSE;
}
#endif /* !defined(TRIO_MINIMAL) */


#if !defined(TRIO_MINIMAL)
/**
   Execute a function on each character in string.

   @param target Target string.
   @param source Source string.
   @param Function Function to be executed.
   @return Number of processed characters.
*/
TRIO_STRING_PUBLIC size_t
trio_span_function
TRIO_ARGS3((target, source, Function),
	   char *target,
	   TRIO_CONST char *source,
	   int (*Function) TRIO_PROTO((int)))
{
  size_t count = 0;

  assert(target);
  assert(source);
  assert(Function);

  while (*source != NIL)
    {
      *target++ = Function(*source++);
      count++;
    }
  return count;
}
#endif /* !defined(TRIO_MINIMAL) */


#if !defined(TRIO_MINIMAL)
/**
   Search for a substring in a string.

   @param string String to be searched.
   @param substring String to be found.
   @return Pointer to first occurrence of @p substring in @p string, or NULL
   if no match was found.
*/
TRIO_STRING_PUBLIC char *
trio_substring
TRIO_ARGS2((string, substring),
	   TRIO_CONST char *string,
	   TRIO_CONST char *substring)
{
  assert(string);
  assert(substring);

  return strstr(string, substring);
}
#endif /* !defined(TRIO_MINIMAL) */


#if !defined(TRIO_MINIMAL)
/**
   Search for a substring in the first @p max characters of a string.

   @param string String to be searched.
   @param max Maximum characters to be searched.
   @param substring String to be found.
   @return Pointer to first occurrence of @p substring in @p string, or NULL
   if no match was found.
*/
TRIO_STRING_PUBLIC char *
trio_substring_max
TRIO_ARGS3((string, max, substring),
	   TRIO_CONST char *string,
	   size_t max,
	   TRIO_CONST char *substring)
{
  size_t count;
  size_t size;
  char *result = NULL;

  assert(string);
  assert(substring);

  size = trio_length(substring);
  if (size <= max)
    {
      for (count = 0; count <= max - size; count++)
	{
	  if (trio_equal_max(substring, size, &string[count]))
	    {
	      result = (char *)&string[count];
	      break;
	    }
	}
    }
  return result;
}
#endif /* !defined(TRIO_MINIMAL) */


#if !defined(TRIO_MINIMAL)
/**
   Tokenize string.

   @param string String to be tokenized.
   @param tokens String containing list of delimiting characters.
   @return Start of new token.

   @warning @p string will be destroyed.
*/
TRIO_STRING_PUBLIC char *
trio_tokenize
TRIO_ARGS2((string, delimiters),
	   char *string,
	   TRIO_CONST char *delimiters)
{
  assert(delimiters);

  return strtok(string, delimiters);
}
#endif /* !defined(TRIO_MINIMAL) */


/**
   Convert string to floating-point number.

   @param source String to be converted.
   @param endp Pointer to end of the converted string.
   @return A floating-point number.

   The following Extended Backus-Naur form is used
   @verbatim
   double        ::= [ <sign> ]
                     ( <number> |
                       <number> <decimal_point> <number> |
                       <decimal_point> <number> )
                     [ <exponential> [ <sign> ] <number> ]
   number        ::= 1*( <digit> )
   digit         ::= ( '0' | '1' | '2' | '3' | '4' | '5' | '6' | '7' | '8' | '9' )
   exponential   ::= ( 'e' | 'E' )
   sign          ::= ( '-' | '+' )
   decimal_point ::= '.'
   @endverbatim
*/
/* FIXME: Add EBNF for hex-floats */
TRIO_STRING_PUBLIC trio_long_double_t
trio_to_long_double
TRIO_ARGS2((source, endp),
	   TRIO_CONST char *source,
	   char **endp)
{
#if defined(USE_STRTOLD)
  return strtold(source, endp);
#else
  int isNegative = FALSE;
  int isExponentNegative = FALSE;
  trio_long_double_t integer = 0.0;
  trio_long_double_t fraction = 0.0;
  unsigned long exponent = 0;
  trio_long_double_t base;
  trio_long_double_t fracdiv = 1.0;
  trio_long_double_t value = 0.0;

  /* First try hex-floats */
  if ((source[0] == '0') && ((source[1] == 'x') || (source[1] == 'X')))
    {
      base = 16.0;
      source += 2;
      while (isxdigit((int)*source))
	{
	  integer *= base;
	  integer += (isdigit((int)*source)
		      ? (*source - '0')
		      : 10 + (trio_to_upper((int)*source) - 'A'));
	  source++;
	}
      if (*source == '.')
	{
	  source++;
	  while (isxdigit((int)*source))
	    {
	      fracdiv /= base;
	      fraction += fracdiv * (isdigit((int)*source)
				     ? (*source - '0')
				     : 10 + (trio_to_upper((int)*source) - 'A'));
	      source++;
	    }
	  if ((*source == 'p') || (*source == 'P'))
	    {
	      source++;
	      if ((*source == '+') || (*source == '-'))
		{
		  isExponentNegative = (*source == '-');
		  source++;
		}
	      while (isdigit((int)*source))
		{
		  exponent *= 10;
		  exponent += (*source - '0');
		  source++;
		}
	    }
	}
      /* For later use with exponent */
      base = 2.0;
    }
  else /* Then try normal decimal floats */
    {
      base = 10.0;
      isNegative = (*source == '-');
      /* Skip sign */
      if ((*source == '+') || (*source == '-'))
	source++;

      /* Integer part */
      while (isdigit((int)*source))
	{
	  integer *= base;
	  integer += (*source - '0');
	  source++;
	}

      if (*source == '.')
	{
	  source++; /* skip decimal point */
	  while (isdigit((int)*source))
	    {
	      fracdiv /= base;
	      fraction += (*source - '0') * fracdiv;
	      source++;
	    }
	}
      if ((*source == 'e')
	  || (*source == 'E')
#if TRIO_MICROSOFT
	  || (*source == 'd')
	  || (*source == 'D')
#endif
	  )
	{
	  source++; /* Skip exponential indicator */
	  isExponentNegative = (*source == '-');
	  if ((*source == '+') || (*source == '-'))
	    source++;
	  while (isdigit((int)*source))
	    {
	      exponent *= (int)base;
	      exponent += (*source - '0');
	      source++;
	    }
	}
    }

  value = integer + fraction;
  if (exponent != 0)
    {
      if (isExponentNegative)
	value /= pow(base, (double)exponent);
      else
	value *= pow(base, (double)exponent);
    }
  if (isNegative)
    value = -value;

  if (endp)
    *endp = (char *)source;
  return value;
#endif
}


/**
   Convert string to floating-point number.

   @param source String to be converted.
   @param endp Pointer to end of the converted string.
   @return A floating-point number.

   See @ref trio_to_long_double.
*/
TRIO_STRING_PUBLIC double
trio_to_double
TRIO_ARGS2((source, endp),
	   TRIO_CONST char *source,
	   char **endp)
{
#if defined(USE_STRTOD)
  return strtod(source, endp);
#else
  return (double)trio_to_long_double(source, endp);
#endif
}

#if !defined(TRIO_MINIMAL)
/**
   Convert string to floating-point number.

   @param source String to be converted.
   @param endp Pointer to end of the converted string.
   @return A floating-point number.

   See @ref trio_to_long_double.
*/
TRIO_STRING_PUBLIC float
trio_to_float
TRIO_ARGS2((source, endp),
	   TRIO_CONST char *source,
	   char **endp)
{
#if defined(USE_STRTOF)
  return strtof(source, endp);
#else
  return (float)trio_to_long_double(source, endp);
#endif
}
#endif /* !defined(TRIO_MINIMAL) */


/**
   Convert string to signed integer.

   @param string String to be converted.
   @param endp Pointer to end of converted string.
   @param base Radix number of number.
*/
TRIO_STRING_PUBLIC long
trio_to_long
TRIO_ARGS3((string, endp, base),
	   TRIO_CONST char *string,
	   char **endp,
	   int base)
{
  assert(string);
  assert((base >= 2) && (base <= 36));

  return strtol(string, endp, base);
}


#if !defined(TRIO_MINIMAL)
/**
   Convert one alphabetic letter to lower-case.

   @param source The letter to be converted.
   @return The converted letter.
*/
TRIO_STRING_PUBLIC int
trio_to_lower
TRIO_ARGS1((source),
	   int source)
{
#if defined(USE_TOLOWER)

  return tolower(source);

#else

  /* Does not handle locales or non-contiguous alphabetic characters */
  return ((source >= (int)'A') && (source <= (int)'Z'))
    ? source - 'A' + 'a'
    : source;

#endif
}
#endif /* !defined(TRIO_MINIMAL) */

#if !defined(TRIO_MINIMAL)
/**
   Convert string to unsigned integer.

   @param string String to be converted.
   @param endp Pointer to end of converted string.
   @param base Radix number of number.
*/
TRIO_STRING_PUBLIC unsigned long
trio_to_unsigned_long
TRIO_ARGS3((string, endp, base),
	   TRIO_CONST char *string,
	   char **endp,
	   int base)
{
  assert(string);
  assert((base >= 2) && (base <= 36));

  return strtoul(string, endp, base);
}
#endif /* !defined(TRIO_MINIMAL) */


/**
   Convert one alphabetic letter to upper-case.

   @param source The letter to be converted.
   @return The converted letter.
*/
TRIO_STRING_PUBLIC int
trio_to_upper
TRIO_ARGS1((source),
	   int source)
{
#if defined(USE_TOUPPER)

  return toupper(source);

#else

  /* Does not handle locales or non-contiguous alphabetic characters */
  return ((source >= (int)'a') && (source <= (int)'z'))
    ? source - 'a' + 'A'
    : source;

#endif
}

#if !defined(TRIO_MINIMAL)
/**
   Convert the alphabetic letters in the string to upper-case.

   @param target The string to be converted.
   @return The number of processed characters (converted or not).
*/
TRIO_STRING_PUBLIC int
trio_upper
TRIO_ARGS1((target),
	   char *target)
{
  assert(target);

  return trio_span_function(target, target, trio_to_upper);
}
#endif /* !defined(TRIO_MINIMAL) */


/** @} End of StaticStrings */


/*************************************************************************
 * Dynamic String Functions
 */

#if defined(TRIO_DOCUMENTATION)
# include "doc/doc_dynamic.h"
#endif
/** @addtogroup DynamicStrings
    @{
*/

/*
 * TrioStringAlloc
 */
TRIO_STRING_PRIVATE trio_string_t *
TrioStringAlloc(TRIO_NOARGS)
{
  trio_string_t *self;

  self = (trio_string_t *)TRIO_MALLOC(sizeof(trio_string_t));
  if (self)
    {
      self->content = NULL;
      self->length = 0;
      self->allocated = 0;
    }
  return self;
}


/*
 * TrioStringGrow
 *
 * The size of the string will be increased by 'delta' characters. If
 * 'delta' is zero, the size will be doubled.
 */
TRIO_STRING_PRIVATE BOOLEAN_T
TrioStringGrow
TRIO_ARGS2((self, delta),
	   trio_string_t *self,
	   size_t delta)
{
  BOOLEAN_T status = FALSE;
  char *new_content;
  size_t new_size;

  new_size = (delta == 0)
    ? ( (self->allocated == 0) ? 1 : self->allocated * 2 )
    : self->allocated + delta;

  new_content = (char *)TRIO_REALLOC(self->content, new_size);
  if (new_content)
    {
      self->content = new_content;
      self->allocated = new_size;
      status = TRUE;
    }
  return status;
}


#if !defined(TRIO_MINIMAL)
/*
 * TrioStringGrowTo
 *
 * The size of the string will be increased to 'length' plus one characters.
 * If 'length' is less than the original size, the original size will be
 * used (that is, the size of the string is never decreased).
 */
TRIO_STRING_PRIVATE BOOLEAN_T
TrioStringGrowTo
TRIO_ARGS2((self, length),
	   trio_string_t *self,
	   size_t length)
{
  length++; /* Room for terminating zero */
  return (self->allocated < length)
    ? TrioStringGrow(self, length - self->allocated)
    : TRUE;
}
#endif /* !defined(TRIO_MINIMAL) */


#if !defined(TRIO_MINIMAL)
/**
   Create a new dynamic string.

   @param initial_size Initial size of the buffer.
   @return Newly allocated dynamic string, or NULL if memory allocation failed.
*/
TRIO_STRING_PUBLIC trio_string_t *
trio_string_create
TRIO_ARGS1((initial_size),
	   int initial_size)
{
  trio_string_t *self;

  self = TrioStringAlloc();
  if (self)
    {
      if (TrioStringGrow(self,
			 (size_t)((initial_size > 0) ? initial_size : 1)))
	{
	  self->content[0] = (char)0;
	  self->allocated = initial_size;
	}
      else
	{
	  trio_string_destroy(self);
	  self = NULL;
	}
    }
  return self;
}
#endif /* !defined(TRIO_MINIMAL) */


/**
   Deallocate the dynamic string and its contents.

   @param self Dynamic string
*/
TRIO_STRING_PUBLIC void
trio_string_destroy
TRIO_ARGS1((self),
	   trio_string_t *self)
{
  assert(self);

  if (self)
    {
      trio_destroy(self->content);
      TRIO_FREE(self);
    }
}


#if !defined(TRIO_MINIMAL)
/**
   Get a pointer to the content.

   @param self Dynamic string.
   @param offset Offset into content.
   @return Pointer to the content.

   @p Offset can be zero, positive, or negative. If @p offset is zero,
   then the start of the content will be returned. If @p offset is positive,
   then a pointer to @p offset number of characters from the beginning of the
   content is returned. If @p offset is negative, then a pointer to @p offset
   number of characters from the ending of the string, starting at the
   terminating zero, is returned.
*/
TRIO_STRING_PUBLIC char *
trio_string_get
TRIO_ARGS2((self, offset),
	   trio_string_t *self,
	   int offset)
{
  char *result = NULL;

  assert(self);

  if (self->content != NULL)
    {
      if (self->length == 0)
	{
	  (void)trio_string_length(self);
	}
      if (offset >= 0)
	{
	  if (offset > (int)self->length)
	    {
	      offset = self->length;
	    }
	}
      else
	{
	  offset += self->length + 1;
	  if (offset < 0)
	    {
	      offset = 0;
	    }
	}
      result = &(self->content[offset]);
    }
  return result;
}
#endif /* !defined(TRIO_MINIMAL) */


/**
   Extract the content.

   @param self Dynamic String
   @return Content of dynamic string.

   The content is removed from the dynamic string. This enables destruction
   of the dynamic string without deallocation of the content.
*/
TRIO_STRING_PUBLIC char *
trio_string_extract
TRIO_ARGS1((self),
	   trio_string_t *self)
{
  char *result;

  assert(self);

  result = self->content;
  /* FIXME: Allocate new empty buffer? */
  self->content = NULL;
  self->length = self->allocated = 0;
  return result;
}


#if !defined(TRIO_MINIMAL)
/**
   Set the content of the dynamic string.

   @param self Dynamic String
   @param buffer The new content.

   Sets the content of the dynamic string to a copy @p buffer.
   An existing content will be deallocated first, if necessary.

   @remark
   This function will make a copy of @p buffer.
   You are responsible for deallocating @p buffer yourself.
*/
TRIO_STRING_PUBLIC void
trio_xstring_set
TRIO_ARGS2((self, buffer),
	   trio_string_t *self,
	   char *buffer)
{
  assert(self);

  trio_destroy(self->content);
  self->content = trio_duplicate(buffer);
}
#endif /* !defined(TRIO_MINIMAL) */


/*
 * trio_string_size
 */
TRIO_STRING_PUBLIC int
trio_string_size
TRIO_ARGS1((self),
	   trio_string_t *self)
{
  assert(self);

  return self->allocated;
}


/*
 * trio_string_terminate
 */
TRIO_STRING_PUBLIC void
trio_string_terminate
TRIO_ARGS1((self),
	   trio_string_t *self)
{
  trio_xstring_append_char(self, 0);
}


#if !defined(TRIO_MINIMAL)
/**
   Append the second string to the first.

   @param self Dynamic string to be modified.
   @param other Dynamic string to copy from.
   @return Boolean value indicating success or failure.
*/
TRIO_STRING_PUBLIC int
trio_string_append
TRIO_ARGS2((self, other),
	   trio_string_t *self,
	   trio_string_t *other)
{
  size_t length;

  assert(self);
  assert(other);

  length = self->length + other->length;
  if (!TrioStringGrowTo(self, length))
    goto error;
  trio_copy(&self->content[self->length], other->content);
  self->length = length;
  return TRUE;

 error:
  return FALSE;
}
#endif /* !defined(TRIO_MINIMAL) */


#if !defined(TRIO_MINIMAL)
/*
 * trio_xstring_append
 */
TRIO_STRING_PUBLIC int
trio_xstring_append
TRIO_ARGS2((self, other),
	   trio_string_t *self,
	   TRIO_CONST char *other)
{
  size_t length;

  assert(self);
  assert(other);

  length = self->length + trio_length(other);
  if (!TrioStringGrowTo(self, length))
    goto error;
  trio_copy(&self->content[self->length], other);
  self->length = length;
  return TRUE;

 error:
  return FALSE;
}
#endif /* !defined(TRIO_MINIMAL) */


/*
 * trio_xstring_append_char
 */
TRIO_STRING_PUBLIC int
trio_xstring_append_char
TRIO_ARGS2((self, character),
	   trio_string_t *self,
	   char character)
{
  assert(self);

  if ((int)self->length >= trio_string_size(self))
    {
      if (!TrioStringGrow(self, 0))
	goto error;
    }
  self->content[self->length] = character;
  self->length++;
  return TRUE;

 error:
  return FALSE;
}


#if !defined(TRIO_MINIMAL)
/**
   Search for the first occurrence of second parameter in the first.

   @param self Dynamic string to be modified.
   @param other Dynamic string to copy from.
   @return Boolean value indicating success or failure.
*/
TRIO_STRING_PUBLIC int
trio_string_contains
TRIO_ARGS2((self, other),
	   trio_string_t *self,
	   trio_string_t *other)
{
  assert(self);
  assert(other);

  return trio_contains(self->content, other->content);
}
#endif /* !defined(TRIO_MINIMAL) */


#if !defined(TRIO_MINIMAL)
/*
 * trio_xstring_contains
 */
TRIO_STRING_PUBLIC int
trio_xstring_contains
TRIO_ARGS2((self, other),
	   trio_string_t *self,
	   TRIO_CONST char *other)
{
  assert(self);
  assert(other);

  return trio_contains(self->content, other);
}
#endif /* !defined(TRIO_MINIMAL) */


#if !defined(TRIO_MINIMAL)
/*
 * trio_string_copy
 */
TRIO_STRING_PUBLIC int
trio_string_copy
TRIO_ARGS2((self, other),
	   trio_string_t *self,
	   trio_string_t *other)
{
  assert(self);
  assert(other);

  self->length = 0;
  return trio_string_append(self, other);
}
#endif /* !defined(TRIO_MINIMAL) */


#if !defined(TRIO_MINIMAL)
/*
 * trio_xstring_copy
 */
TRIO_STRING_PUBLIC int
trio_xstring_copy
TRIO_ARGS2((self, other),
	   trio_string_t *self,
	   TRIO_CONST char *other)
{
  assert(self);
  assert(other);

  self->length = 0;
  return trio_xstring_append(self, other);
}
#endif /* !defined(TRIO_MINIMAL) */


#if !defined(TRIO_MINIMAL)
/*
 * trio_string_duplicate
 */
TRIO_STRING_PUBLIC trio_string_t *
trio_string_duplicate
TRIO_ARGS1((other),
	   trio_string_t *other)
{
  trio_string_t *self;

  assert(other);

  self = TrioStringAlloc();
  if (self)
    {
      self->content = TrioDuplicateMax(other->content, other->length);
      if (self->content)
	{
	  self->length = other->length;
	  self->allocated = self->length + 1;
	}
      else
	{
	  self->length = self->allocated = 0;
	}
    }
  return self;
}
#endif /* !defined(TRIO_MINIMAL) */


/*
 * trio_xstring_duplicate
 */
TRIO_STRING_PUBLIC trio_string_t *
trio_xstring_duplicate
TRIO_ARGS1((other),
	   TRIO_CONST char *other)
{
  trio_string_t *self;

  assert(other);

  self = TrioStringAlloc();
  if (self)
    {
      self->content = TrioDuplicateMax(other, trio_length(other));
      if (self->content)
	{
	  self->length = trio_length(self->content);
	  self->allocated = self->length + 1;
	}
      else
	{
	  self->length = self->allocated = 0;
	}
    }
  return self;
}


#if !defined(TRIO_MINIMAL)
/*
 * trio_string_equal
 */
TRIO_STRING_PUBLIC int
trio_string_equal
TRIO_ARGS2((self, other),
	   trio_string_t *self,
	   trio_string_t *other)
{
  assert(self);
  assert(other);

  return trio_equal(self->content, other->content);
}
#endif /* !defined(TRIO_MINIMAL) */


#if !defined(TRIO_MINIMAL)
/*
 * trio_xstring_equal
 */
TRIO_STRING_PUBLIC int
trio_xstring_equal
TRIO_ARGS2((self, other),
	   trio_string_t *self,
	   TRIO_CONST char *other)
{
  assert(self);
  assert(other);

  return trio_equal(self->content, other);
}
#endif /* !defined(TRIO_MINIMAL) */


#if !defined(TRIO_MINIMAL)
/*
 * trio_string_equal_max
 */
TRIO_STRING_PUBLIC int
trio_string_equal_max
TRIO_ARGS3((self, max, other),
	   trio_string_t *self,
	   size_t max,
	   trio_string_t *other)
{
  assert(self);
  assert(other);

  return trio_equal_max(self->content, max, other->content);
}
#endif /* !defined(TRIO_MINIMAL) */


#if !defined(TRIO_MINIMAL)
/*
 * trio_xstring_equal_max
 */
TRIO_STRING_PUBLIC int
trio_xstring_equal_max
TRIO_ARGS3((self, max, other),
	   trio_string_t *self,
	   size_t max,
	   TRIO_CONST char *other)
{
  assert(self);
  assert(other);

  return trio_equal_max(self->content, max, other);
}
#endif /* !defined(TRIO_MINIMAL) */


#if !defined(TRIO_MINIMAL)
/*
 * trio_string_equal_case
 */
TRIO_STRING_PUBLIC int
trio_string_equal_case
TRIO_ARGS2((self, other),
	   trio_string_t *self,
	   trio_string_t *other)
{
  assert(self);
  assert(other);

  return trio_equal_case(self->content, other->content);
}
#endif /* !defined(TRIO_MINIMAL) */


#if !defined(TRIO_MINIMAL)
/*
 * trio_xstring_equal_case
 */
TRIO_STRING_PUBLIC int
trio_xstring_equal_case
TRIO_ARGS2((self, other),
	   trio_string_t *self,
	   TRIO_CONST char *other)
{
  assert(self);
  assert(other);

  return trio_equal_case(self->content, other);
}
#endif /* !defined(TRIO_MINIMAL) */


#if !defined(TRIO_MINIMAL)
/*
 * trio_string_equal_case_max
 */
TRIO_STRING_PUBLIC int
trio_string_equal_case_max
TRIO_ARGS3((self, max, other),
	   trio_string_t *self,
	   size_t max,
	   trio_string_t *other)
{
  assert(self);
  assert(other);

  return trio_equal_case_max(self->content, max, other->content);
}
#endif /* !defined(TRIO_MINIMAL) */


#if !defined(TRIO_MINIMAL)
/*
 * trio_xstring_equal_case_max
 */
TRIO_STRING_PUBLIC int
trio_xstring_equal_case_max
TRIO_ARGS3((self, max, other),
	   trio_string_t *self,
	   size_t max,
	   TRIO_CONST char *other)
{
  assert(self);
  assert(other);

  return trio_equal_case_max(self->content, max, other);
}
#endif /* !defined(TRIO_MINIMAL) */


#if !defined(TRIO_MINIMAL) && !defined(_WIN32_WCE)
/*
 * trio_string_format_data_max
 */
TRIO_STRING_PUBLIC size_t
trio_string_format_date_max
TRIO_ARGS4((self, max, format, datetime),
	   trio_string_t *self,
	   size_t max,
	   TRIO_CONST char *format,
	   TRIO_CONST struct tm *datetime)
{
  assert(self);

  return trio_format_date_max(self->content, max, format, datetime);
}
#endif /* !defined(TRIO_MINIMAL) */


#if !defined(TRIO_MINIMAL)
/*
 * trio_string_index
 */
TRIO_STRING_PUBLIC char *
trio_string_index
TRIO_ARGS2((self, character),
	   trio_string_t *self,
	   int character)
{
  assert(self);

  return trio_index(self->content, character);
}
#endif /* !defined(TRIO_MINIMAL) */


#if !defined(TRIO_MINIMAL)
/*
 * trio_string_index_last
 */
TRIO_STRING_PUBLIC char *
trio_string_index_last
TRIO_ARGS2((self, character),
	   trio_string_t *self,
	   int character)
{
  assert(self);

  return trio_index_last(self->content, character);
}
#endif /* !defined(TRIO_MINIMAL) */


#if !defined(TRIO_MINIMAL)
/*
 * trio_string_length
 */
TRIO_STRING_PUBLIC int
trio_string_length
TRIO_ARGS1((self),
	   trio_string_t *self)
{
  assert(self);

  if (self->length == 0)
    {
      self->length = trio_length(self->content);
    }
  return self->length;
}
#endif /* !defined(TRIO_MINIMAL) */


#if !defined(TRIO_MINIMAL)
/*
 * trio_string_lower
 */
TRIO_STRING_PUBLIC int
trio_string_lower
TRIO_ARGS1((self),
	   trio_string_t *self)
{
  assert(self);

  return trio_lower(self->content);
}
#endif /* !defined(TRIO_MINIMAL) */


#if !defined(TRIO_MINIMAL)
/*
 * trio_string_match
 */
TRIO_STRING_PUBLIC int
trio_string_match
TRIO_ARGS2((self, other),
	   trio_string_t *self,
	   trio_string_t *other)
{
  assert(self);
  assert(other);

  return trio_match(self->content, other->content);
}
#endif /* !defined(TRIO_MINIMAL) */


#if !defined(TRIO_MINIMAL)
/*
 * trio_xstring_match
 */
TRIO_STRING_PUBLIC int
trio_xstring_match
TRIO_ARGS2((self, other),
	   trio_string_t *self,
	   TRIO_CONST char *other)
{
  assert(self);
  assert(other);

  return trio_match(self->content, other);
}
#endif /* !defined(TRIO_MINIMAL) */


#if !defined(TRIO_MINIMAL)
/*
 * trio_string_match_case
 */
TRIO_STRING_PUBLIC int
trio_string_match_case
TRIO_ARGS2((self, other),
	   trio_string_t *self,
	   trio_string_t *other)
{
  assert(self);
  assert(other);

  return trio_match_case(self->content, other->content);
}
#endif /* !defined(TRIO_MINIMAL) */


#if !defined(TRIO_MINIMAL)
/*
 * trio_xstring_match_case
 */
TRIO_STRING_PUBLIC int
trio_xstring_match_case
TRIO_ARGS2((self, other),
	   trio_string_t *self,
	   TRIO_CONST char *other)
{
  assert(self);
  assert(other);

  return trio_match_case(self->content, other);
}
#endif /* !defined(TRIO_MINIMAL) */


#if !defined(TRIO_MINIMAL)
/*
 * trio_string_substring
 */
TRIO_STRING_PUBLIC char *
trio_string_substring
TRIO_ARGS2((self, other),
	   trio_string_t *self,
	   trio_string_t *other)
{
  assert(self);
  assert(other);

  return trio_substring(self->content, other->content);
}
#endif /* !defined(TRIO_MINIMAL) */


#if !defined(TRIO_MINIMAL)
/*
 * trio_xstring_substring
 */
TRIO_STRING_PUBLIC char *
trio_xstring_substring
TRIO_ARGS2((self, other),
	   trio_string_t *self,
	   TRIO_CONST char *other)
{
  assert(self);
  assert(other);

  return trio_substring(self->content, other);
}
#endif /* !defined(TRIO_MINIMAL) */


#if !defined(TRIO_MINIMAL)
/*
 * trio_string_upper
 */
TRIO_STRING_PUBLIC int
trio_string_upper
TRIO_ARGS1((self),
	   trio_string_t *self)
{
  assert(self);

  return trio_upper(self->content);
}
#endif /* !defined(TRIO_MINIMAL) */

/** @} End of DynamicStrings */
