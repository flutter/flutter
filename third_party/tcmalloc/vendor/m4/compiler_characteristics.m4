# Check compiler characteristics (e.g. type sizes, PRIxx macros, ...)

# If types $1 and $2 are compatible, perform action $3
AC_DEFUN([AC_TYPES_COMPATIBLE],
  [AC_TRY_COMPILE([#include <stddef.h>], [$1 v1 = 0; $2 v2 = 0; return (&v1 - &v2)], $3)])

define(AC_PRIUS_COMMENT, [printf format code for printing a size_t and ssize_t])

AC_DEFUN([AC_COMPILER_CHARACTERISTICS],
  [AC_CACHE_CHECK(AC_PRIUS_COMMENT, ac_cv_formatting_prius_prefix,
    [AC_TYPES_COMPATIBLE(unsigned int, size_t, 
	                 ac_cv_formatting_prius_prefix=; ac_cv_prius_defined=1)
     AC_TYPES_COMPATIBLE(unsigned long, size_t,
	                 ac_cv_formatting_prius_prefix=l; ac_cv_prius_defined=1)
     AC_TYPES_COMPATIBLE(unsigned long long, size_t,
                         ac_cv_formatting_prius_prefix=ll; ac_cv_prius_defined=1
     )])
   if test -z "$ac_cv_prius_defined"; then 
      ac_cv_formatting_prius_prefix=z;
   fi
   AC_DEFINE_UNQUOTED(PRIuS, "${ac_cv_formatting_prius_prefix}u", AC_PRIUS_COMMENT)
   AC_DEFINE_UNQUOTED(PRIxS, "${ac_cv_formatting_prius_prefix}x", AC_PRIUS_COMMENT)
   AC_DEFINE_UNQUOTED(PRIdS, "${ac_cv_formatting_prius_prefix}d", AC_PRIUS_COMMENT)
])
