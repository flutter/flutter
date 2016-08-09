# Check for support for nanosleep.  It's defined in <time.h>, but on
# some systems, such as solaris, you need to link in a library to use it.
# We set acx_nanosleep_ok if nanosleep is supported; in that case,
# NANOSLEEP_LIBS is set to whatever libraries are needed to support
# nanosleep.

AC_DEFUN([ACX_NANOSLEEP],
[AC_MSG_CHECKING(if nanosleep requires any libraries)
 AC_LANG_SAVE
 AC_LANG_C
 acx_nanosleep_ok="no"
 NANOSLEEP_LIBS=
 # For most folks, this should just work
 AC_TRY_LINK([#include <time.h>],
             [static struct timespec ts; nanosleep(&ts, NULL);],
             [acx_nanosleep_ok=yes])
 # For solaris, we may  need -lrt
 if test "x$acx_nanosleep_ok" != "xyes"; then
   OLD_LIBS="$LIBS"
   LIBS="-lrt $LIBS"
   AC_TRY_LINK([#include <time.h>],
               [static struct timespec ts; nanosleep(&ts, NULL);],
               [acx_nanosleep_ok=yes])
   if test "x$acx_nanosleep_ok" = "xyes"; then
     NANOSLEEP_LIBS="-lrt"
   fi
   LIBS="$OLD_LIBS"
 fi
 if test "x$acx_nanosleep_ok" != "xyes"; then
   AC_MSG_ERROR([cannot find the nanosleep function])
 else
   AC_MSG_RESULT(${NANOSLEEP_LIBS:-no})
 fi
 AC_LANG_RESTORE
])
