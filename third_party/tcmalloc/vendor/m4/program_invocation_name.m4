# We need to be careful to avoid having the reference to
# program_invocation_name optimized out.  We do that by
# returning the value.

AC_DEFUN([AC_PROGRAM_INVOCATION_NAME],
  [AC_CACHE_CHECK(
    for program_invocation_name,
    ac_cv_have_program_invocation_name,
    AC_TRY_LINK([extern char* program_invocation_name;],
	        [return *program_invocation_name;],
	        [ac_cv_have_program_invocation_name=yes],
		[ac_cv_have_program_invocation_name=no])
   )
   if test "$ac_cv_have_program_invocation_name" = "yes"; then
     AC_DEFINE(HAVE_PROGRAM_INVOCATION_NAME, 1,
               [define if libc has program_invocation_name])
   fi
   ])
   
