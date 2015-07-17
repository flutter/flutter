dnl Like AC_TRY_EVAL but also errors out if the compiler generates
dnl _any_ output. Some compilers might issue warnings which we want
dnl to catch.
AC_DEFUN([AC_TRY_EVAL2],
[{ (eval echo configure:__oline__: \"[$]$1\") 1>&AS_MESSAGE_LOG_FD; dnl
(eval [$]$1) 2>&AS_MESSAGE_LOG_FD; _out=`eval [$]$1 2>&1` && test "x$_out" = x; }])

dnl Like AC_TRY_COMPILE but calls AC_TRY_EVAL2 instead of AC_TRY_EVAL
AC_DEFUN([AC_TRY_COMPILE2],
[cat > conftest.$ac_ext <<EOF
[#]line __oline__ "configure"
#include "confdefs.h"
[$1]
int main(void) {
[$2]
; return 0; }
EOF
if AC_TRY_EVAL2(ac_compile); then
  ifelse([$3], , :, [rm -rf conftest*
  $3])
else
  echo "configure: failed program was:" >&AS_MESSAGE_LOG_FD
  cat conftest.$ac_ext >&AS_MESSAGE_LOG_FD
ifelse([$4], , , [  rm -rf conftest*
  $4
])dnl
fi
rm -f conftest*])
