AC_DEFUN([AC_INSTALL_PREFIX],
  [ac_cv_install_prefix="$prefix";
   if test x"$ac_cv_install_prefix" = x"NONE" ; then
     ac_cv_install_prefix="$ac_default_prefix";
   fi
   AC_DEFINE_UNQUOTED(INSTALL_PREFIX, "$ac_cv_install_prefix",
     [prefix where we look for installed files])
   ])
