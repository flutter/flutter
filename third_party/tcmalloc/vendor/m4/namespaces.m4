# Checks whether the compiler implements namespaces
AC_DEFUN([AC_CXX_NAMESPACES],
 [AC_CACHE_CHECK(whether the compiler implements namespaces,
                 ac_cv_cxx_namespaces,
                 [AC_LANG_SAVE
                  AC_LANG_CPLUSPLUS
                  AC_TRY_COMPILE([namespace Outer {
                                    namespace Inner { int i = 0; }}],
                                 [using namespace Outer::Inner; return i;],
                                 ac_cv_cxx_namespaces=yes,
                                 ac_cv_cxx_namespaces=no)
                  AC_LANG_RESTORE])
  if test "$ac_cv_cxx_namespaces" = yes; then
    AC_DEFINE(HAVE_NAMESPACES, 1, [define if the compiler implements namespaces])
  fi])
