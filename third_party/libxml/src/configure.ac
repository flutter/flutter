dnl Process this file with autoconf to produce a configure script.
AC_PREREQ([2.63])
AC_INIT
AC_CONFIG_SRCDIR([entities.c])
AC_CONFIG_HEADERS([config.h])
AC_CONFIG_MACRO_DIR([m4])
AC_CANONICAL_HOST

LIBXML_MAJOR_VERSION=2
LIBXML_MINOR_VERSION=9
LIBXML_MICRO_VERSION=2
LIBXML_MICRO_VERSION_SUFFIX=
LIBXML_VERSION=$LIBXML_MAJOR_VERSION.$LIBXML_MINOR_VERSION.$LIBXML_MICRO_VERSION$LIBXML_MICRO_VERSION_SUFFIX
LIBXML_VERSION_INFO=`expr $LIBXML_MAJOR_VERSION + $LIBXML_MINOR_VERSION`:$LIBXML_MICRO_VERSION:$LIBXML_MINOR_VERSION

LIBXML_VERSION_NUMBER=`expr $LIBXML_MAJOR_VERSION \* 10000 + $LIBXML_MINOR_VERSION \* 100 + $LIBXML_MICRO_VERSION`

if test -f CVS/Entries ; then
  extra=`grep ChangeLog CVS/Entries | grep -v LIBXML | sed -e s\%/ChangeLog/1\.%% -e s\%/.*$%%`
  echo extra=$extra
  if test "$extra" != ""
  then
      LIBXML_VERSION_EXTRA="-CVS$extra"
  fi
else if test -d .svn ; then
  extra=`svn info | grep Revision | sed 's+Revision: ++'`
  echo extra=$extra
  if test "$extra" != ""
  then
      LIBXML_VERSION_EXTRA="-SVN$extra"
  fi
else if test -d .git ; then
  extra=`git describe 2>/dev/null | sed 's+LIBXML[[0-9.]]*-++'`
  echo extra=$extra
  if test "$extra" != ""
  then
      LIBXML_VERSION_EXTRA="-GIT$extra"
  fi
fi
fi
fi
AC_SUBST(LIBXML_MAJOR_VERSION)
AC_SUBST(LIBXML_MINOR_VERSION)
AC_SUBST(LIBXML_MICRO_VERSION)
AC_SUBST(LIBXML_VERSION)
AC_SUBST(LIBXML_VERSION_INFO)
AC_SUBST(LIBXML_VERSION_NUMBER)
AC_SUBST(LIBXML_VERSION_EXTRA)

VERSION=${LIBXML_VERSION}

AM_INIT_AUTOMAKE(libxml2, $VERSION)

# Support silent build rules, requires at least automake-1.11. Disable
# by either passing --disable-silent-rules to configure or passing V=1
# to make
m4_ifdef([AM_SILENT_RULES], [AM_SILENT_RULES([yes])])

dnl Checks for programs.
AC_PROG_CC
AC_PROG_INSTALL
AC_PROG_LN_S
AC_PROG_MKDIR_P
AC_PROG_CPP
AC_PATH_PROG(MV, mv, /bin/mv)
AC_PATH_PROG(TAR, tar, /bin/tar)
AC_PATH_PROG(PERL, perl, /usr/bin/perl)
AC_PATH_PROG(WGET, wget, /usr/bin/wget)
AC_PATH_PROG(XMLLINT, xmllint, /usr/bin/xmllint)
AC_PATH_PROG(XSLTPROC, xsltproc, /usr/bin/xsltproc)
PKG_PROG_PKG_CONFIG

LT_INIT

dnl
dnl if the system support linker version scripts for symbol versioning
dnl then add it
dnl
VERSION_SCRIPT_FLAGS=
# lt_cv_prog_gnu_ld is from libtool 2.+
if test "$lt_cv_prog_gnu_ld" = yes; then
  VERSION_SCRIPT_FLAGS=-Wl,--version-script=
else
  case $host in
  *-*-sunos*) VERSION_SCRIPT_FLAGS="-Wl,-M -Wl,";;
  esac
fi
AC_SUBST(VERSION_SCRIPT_FLAGS)
AM_CONDITIONAL([USE_VERSION_SCRIPT], [test -n "$VERSION_SCRIPT_FLAGS"])

dnl
dnl We process the AC_ARG_WITH first so that later we can modify
dnl some of them to try to prevent impossible combinations.  This
dnl also allows up so alphabetize the choices
dnl

dnl
dnl zlib option might change flags, so we save them initially
dnl
_cppflags="${CPPFLAGS}"
_libs="${LIBS}"

AC_ARG_WITH(c14n,
[  --with-c14n             add the Canonicalization support (on)])
AC_ARG_WITH(catalog,
[  --with-catalog          add the Catalog support (on)])
AC_ARG_WITH(debug,
[  --with-debug            add the debugging module (on)])
AC_ARG_WITH(docbook,
[  --with-docbook          add Docbook SGML support (on)])
AC_ARG_WITH(fexceptions,
[  --with-fexceptions      add GCC flag -fexceptions for C++ exceptions (off)])
AC_ARG_WITH(ftp,
[  --with-ftp              add the FTP support (on)])
AC_ARG_WITH(history,
[  --with-history          add history support to xmllint shell(off)])
AC_ARG_WITH(html,
[  --with-html             add the HTML support (on)])
dnl Specific dir for HTML output ?
AC_ARG_WITH(html-dir, AS_HELP_STRING([--with-html-dir=path],
            [path to base html directory, default $datadir/doc/html]),
            [HTML_DIR=$withval], [HTML_DIR='$(datadir)/doc'])

AC_ARG_WITH(html-subdir, AS_HELP_STRING([--with-html-subdir=path],
            [directory used under html-dir, default $PACKAGE-$VERSION/html]),
            [test "x$withval" != "x" && HTML_DIR="$HTML_DIR/$withval"],
            [HTML_DIR="$HTML_DIR/\$(PACKAGE)-\$(VERSION)/html"])
AC_SUBST(HTML_DIR)
AC_ARG_WITH(http,
[  --with-http             add the HTTP support (on)])
AC_ARG_WITH(iconv,
[  --with-iconv[[=DIR]]      add ICONV support (on)])
AC_ARG_WITH(icu,
[  --with-icu                add ICU support (off)])
AC_ARG_WITH(iso8859x,
[  --with-iso8859x         add ISO8859X support if no iconv (on)])
AC_ARG_WITH(legacy,
[  --with-legacy           add deprecated APIs for compatibility (on)])
AC_ARG_WITH(mem_debug,
[  --with-mem-debug        add the memory debugging module (off)])
AC_ARG_WITH(minimum,
[  --with-minimum          build a minimally sized library (off)])
AC_ARG_WITH(output,
[  --with-output           add the serialization support (on)])
AC_ARG_WITH(pattern,
[  --with-pattern          add the xmlPattern selection interface (on)])
AC_ARG_WITH(push,
[  --with-push             add the PUSH parser interfaces (on)])
AC_ARG_WITH(python,
[  --with-python[[=DIR]]     build Python bindings if found])
AC_ARG_WITH(python_install_dir,
[  --with-python-install-dir=DIR
                          install Python bindings in DIR])
AC_ARG_WITH(reader,
[  --with-reader           add the xmlReader parsing interface (on)])
AC_ARG_WITH(readline,
[  --with-readline=DIR     use readline in DIR],[
  if test "$withval" != "no" -a "$withval" != "yes"; then
    RDL_DIR=$withval
    CPPFLAGS="${CPPFLAGS} -I$withval/include"
    LIBS="${LIBS} -L$withval/lib"
  fi
])
AC_ARG_WITH(regexps,
[  --with-regexps          add Regular Expressions support (on)])
AC_ARG_WITH(run_debug,
[  --with-run-debug        add the runtime debugging module (off)])
AC_ARG_WITH(sax1,
[  --with-sax1             add the older SAX1 interface (on)])
AC_ARG_WITH(schemas,
[  --with-schemas          add Relax-NG and Schemas support (on)])
AC_ARG_WITH(schematron,
[  --with-schematron       add Schematron support (on)])
AC_ARG_WITH(threads,
[  --with-threads          add multithread support(on)])
AC_ARG_WITH(thread-alloc,
[  --with-thread-alloc     add per-thread memory(off)])
AC_ARG_WITH(tree,
[  --with-tree             add the DOM like tree manipulation APIs (on)])
AC_ARG_WITH(valid,
[  --with-valid            add the DTD validation support (on)])
AC_ARG_WITH(writer,
[  --with-writer           add the xmlWriter saving interface (on)])
AC_ARG_WITH(xinclude,
[  --with-xinclude         add the XInclude support (on)])
AC_ARG_WITH(xpath,
[  --with-xpath            add the XPATH support (on)])
AC_ARG_WITH(xptr,
[  --with-xptr             add the XPointer support (on)])
AC_ARG_WITH(modules,
[  --with-modules          add the dynamic modules support (on)])
AC_ARG_WITH(zlib,
[  --with-zlib[[=DIR]]       use libz in DIR],[
  if test "$withval" != "no" -a "$withval" != "yes"; then
    Z_DIR=$withval
    CPPFLAGS="${CPPFLAGS} -I$withval/include"
    LIBS="${LIBS} -L$withval/lib"
  fi
])
AC_ARG_WITH(lzma,
[  --with-lzma[[=DIR]]       use liblzma in DIR],[
  if test "$withval" != "no" -a "$withval" != "yes"; then
    LZMA_DIR=$withval
    CPPFLAGS="${CPPFLAGS} -I$withval/include"
    LIBS="${LIBS} -L$withval/lib"
  fi
])
AC_ARG_WITH(coverage,
[  --with-coverage         build for code coverage with GCC (off)])

AC_ARG_ENABLE(rebuild-docs,
[  --enable-rebuild-docs[[=yes/no]]  rebuild some generated docs [[default=no]]])
if test "$enable_rebuild_docs" = "yes" -a "$srcdir" != "."; then
  AC_MSG_ERROR([cannot rebuild docs when builddir != srcdir])
fi
AM_CONDITIONAL([REBUILD_DOCS], [test "$enable_rebuild_docs" = "yes" -o "$USER" = "veillard"])

dnl
dnl hard dependancies on options
dnl
if test "$with_schemas" = "yes"
then
    with_pattern=yes
    with_regexps=yes
fi
if test "$with_schematron" = "yes"
then
    with_pattern=yes
    with_tree=yes
    with_xpath=yes
fi
if test "$with_reader" = "yes"
then
    with_push=yes
fi
if test "$with_xptr" = "yes"
then
    with_xpath=yes
fi
dnl
dnl option to build a minimal libxml2 library
dnl
if test "$with_minimum" = "yes"
then
    echo "Configuring for a minimal library"
    if test "$with_c14n" = ""
    then
      with_c14n=no
    fi
    if test "$with_catalog" = ""
    then
      with_catalog=no
    fi
    echo So far so good!
    if test "$with_debug" = ""
    then
      with_debug=no
    fi
    if test "$with_docbook" = ""
    then
      with_docbook=no
    fi
    if test "$with_fexceptions" = ""
    then
      with_fexceptions=no
    fi
    if test "$with_ftp" = ""
    then
      with_ftp=no 
    fi
    if test "$with_history" = ""
    then
      with_history=no
    fi
    if test "$with_html" = ""
    then
      with_html=no
    fi
    if test "$with_http" = ""
    then
      with_http=no 
    fi
    if test "$with_iconv" = ""
    then
      with_iconv=no
    fi
    if test "$with_iso8859x" = ""
    then
      with_iso8859x=no
    fi
    if test "$with_legacy" = ""
    then
      with_legacy=no
    fi
    if test "$with_mem_debug" = ""
    then 
      with_mem_debug=no
    fi
    if test "$with_output" = ""
    then
      with_output=no
    fi
    if test "$with_pattern" = ""
    then
      with_pattern=no
    fi
    if test "$with_push" = ""
    then
      with_push=no
    fi
    if test "$with_python" = ""
    then
      with_python=no
    fi
    if test "$with_reader" = ""
    then
      with_reader=no
    fi
    if test "$with_readline" = ""
    then
      with_readline=no
    fi
    if test "$with_regexps" = ""
    then
      with_regexps=no
    fi
    if test "$with_run_debug" = ""
    then
      with_run_debug=no
    fi
    if test "$with_sax1" = ""
    then
      with_sax1=no
    fi
    if test "$with_schemas" = ""
    then
      with_schemas=no
    fi
    if test "$with_schematron" = ""
    then
      with_schematron=no
    fi
    if test "$with_threads" = ""
    then
      with_threads=no
    fi
    if test "$with_thread_alloc" = ""
    then
      with_thread_alloc=no
   fi
    if test "$with_tree" = ""
    then
      with_tree=no
    fi
    if test "$with_valid" = ""
    then
      with_valid=no
    fi
    if test "$with_writer" = ""
    then
      with_writer=no
    fi
    if test "$with_xinclude" = ""
    then
      with_xinclude=no
    fi
    if test "$with_xpath" = ""
    then
      with_xpath=no
    fi
    if test "$with_xptr" = ""
    then
      with_xptr=no
    fi
    if test "$with_zlib" = ""
    then
      with_zlib=no
    fi
    if test "$with_modules" = ""
    then
      with_modules=no
    fi
fi

echo Checking zlib

dnl Checks for zlib library.

WITH_ZLIB=0
if test "$with_zlib" = "no"; then
    echo "Disabling compression support"
else
    AC_CHECK_HEADERS(zlib.h,
        [SAVE_LDFLAGS="${LDFLAGS}"
	 LDFLAGS="-L${Z_DIR}/lib"
	AC_CHECK_LIB(z, gzread,[
	    AC_DEFINE([HAVE_LIBZ], [1], [Have compression library])
	    WITH_ZLIB=1
	    if test "x${Z_DIR}" != "x"; then
		Z_CFLAGS="-I${Z_DIR}/include"
		Z_LIBS="-L${Z_DIR}/lib -lz"
		[case ${host} in
		    *-*-solaris*)
			Z_LIBS="-L${Z_DIR}/lib -R${Z_DIR}/lib -lz"
			;;
		esac]
	    else
		Z_LIBS="-lz"
	    fi])
	 LDFLAGS="${SAVE_LDFLAGS}"])
fi

AC_SUBST(Z_CFLAGS)
AC_SUBST(Z_LIBS)
AC_SUBST(WITH_ZLIB)

echo Checking lzma

dnl Checks for lzma library.

WITH_LZMA=0
if test "$with_lzma" = "no"; then
    echo "Disabling compression support"
else
    # Try pkg-config first so that static linking works.
    # If this succeeeds, we ignore the WITH_LZMA directory.
    PKG_CHECK_MODULES([LZMA],[liblzma],
        [have_liblzma=yes],
        [have_liblzma=no])

     # If pkg-config failed, fall back to AC_CHECK_LIB. This
     # will not pick up the necessary LIBS flags for liblzma's
     # private dependencies, though, so static linking may fail.
     if test "x$have_liblzma" = "xno"; then
         AC_CHECK_HEADERS(lzma.h,
	    [SAVE_LDFLAGS="${LDFLAGS}"
	     LDFLAGS="-L${LZMA_DIR}/lib"
            AC_CHECK_LIB(lzma, lzma_code,[
                have_liblzma=yes
                if test "x${LZMA_DIR}" != "x"; then
                    LZMA_CFLAGS="-I${LZMA_DIR}/include"
                    LZMA_LIBS="-L${LZMA_DIR}/lib -llzma"
                else
                    LZMA_LIBS="-llzma"
                fi],
                [have_liblzma=no])
	     LDFLAGS="${SAVE_LDFLAGS}"])
    fi

    # Found the library via either method?
    if test "x$have_liblzma" = "xyes"; then
        AC_DEFINE([HAVE_LIBLZMA], [1], [Have compression library])
        WITH_LZMA=1
    fi
fi

AC_SUBST(LZMA_CFLAGS)
AC_SUBST(LZMA_LIBS)
AC_SUBST(WITH_LZMA)

CPPFLAGS=${_cppflags}
LIBS=${_libs}

echo Checking headers

dnl Checks for header files.
AC_HEADER_DIRENT
AC_HEADER_STDC
AC_CHECK_HEADERS([fcntl.h])
AC_CHECK_HEADERS([unistd.h])
AC_CHECK_HEADERS([ctype.h])
AC_CHECK_HEADERS([dirent.h])
AC_CHECK_HEADERS([errno.h])
AC_CHECK_HEADERS([malloc.h])
AC_CHECK_HEADERS([stdarg.h])
AC_CHECK_HEADERS([sys/stat.h])
AC_CHECK_HEADERS([sys/types.h])
AC_CHECK_HEADERS([stdint.h])
AC_CHECK_HEADERS([inttypes.h])
AC_CHECK_HEADERS([time.h])
AC_CHECK_HEADERS([ansidecl.h])
AC_CHECK_HEADERS([ieeefp.h])
AC_CHECK_HEADERS([nan.h])
AC_CHECK_HEADERS([math.h])
AC_CHECK_HEADERS([limits.h])
AC_CHECK_HEADERS([fp_class.h])
AC_CHECK_HEADERS([float.h])
AC_CHECK_HEADERS([stdlib.h])
AC_CHECK_HEADERS([sys/socket.h], [], [],
[#if HAVE_SYS_TYPES_H
# include <sys/types.h>
# endif
])
AC_CHECK_HEADERS([netinet/in.h], [], [],
[#if HAVE_SYS_TYPES_H
# include <sys/types.h>
# endif
])
AC_CHECK_HEADERS([arpa/inet.h], [], [],
[#if HAVE_SYS_TYPES_H
# include <sys/types.h>
# endif
#if HAVE_ARPA_INET_H
# include <arpa/inet.h>
# endif
])
AC_CHECK_HEADERS([netdb.h])
AC_CHECK_HEADERS([sys/time.h])
AC_CHECK_HEADERS([sys/select.h])
AC_CHECK_HEADERS([poll.h])
AC_CHECK_HEADERS([sys/mman.h])
AC_CHECK_HEADERS([sys/timeb.h])
AC_CHECK_HEADERS([signal.h])
AC_CHECK_HEADERS([arpa/nameser.h], [], [],
[#if HAVE_SYS_TYPES_H
# include <sys/types.h>
# endif
])
AC_CHECK_HEADERS([resolv.h], [], [],
[#if HAVE_SYS_TYPES_H
# include <sys/types.h>
# endif
#if HAVE_NETINET_IN_H
# include <netinet/in.h>
# endif
#if HAVE_ARPA_NAMESER_H
# include <arpa/nameser.h>
# endif
])
AC_CHECK_HEADERS([dl.h])
AC_CHECK_HEADERS([dlfcn.h])


echo Checking types

AC_TYPE_UINT32_T


echo Checking libraries

dnl Checks for library functions.
AC_FUNC_STRFTIME
AC_CHECK_FUNCS(strdup strndup strerror)
AC_CHECK_FUNCS(finite isnand fp_class class fpclass)
AC_CHECK_FUNCS(strftime localtime gettimeofday ftime)
AC_CHECK_FUNCS(stat _stat signal)
AC_CHECK_FUNCS(rand rand_r srand time)
AC_CHECK_FUNCS(isascii mmap munmap putenv)

AH_VERBATIM([HAVE_MUNMAP_AFTER],[/* mmap() is no good without munmap() */
#if defined(HAVE_MMAP) && !defined(HAVE_MUNMAP)
#  undef /**/ HAVE_MMAP
#endif])

dnl Checking for va_copy availability
AC_MSG_CHECKING([for va_copy])
AC_LINK_IFELSE([AC_LANG_PROGRAM([[#include <stdarg.h>
va_list ap1,ap2;]], [[va_copy(ap1,ap2);]])],
have_va_copy=yes,
have_va_copy=no)
AC_MSG_RESULT($have_va_copy)
if test x"$have_va_copy" = x"yes"; then
    AC_DEFINE(HAVE_VA_COPY,1,[Whether va_copy() is available])
else
    AC_MSG_CHECKING([for __va_copy])
    AC_LINK_IFELSE([AC_LANG_PROGRAM([[#include <stdarg.h>
    va_list ap1,ap2;]], [[__va_copy(ap1,ap2);]])],
    have___va_copy=yes,
    have___va_copy=no)
    AC_MSG_RESULT($have___va_copy)
    if test x"$have___va_copy" = x"yes"; then
        AC_DEFINE(HAVE___VA_COPY,1,[Whether __va_copy() is available])
    fi
fi

dnl Checking whether va_list is an array type
AC_MSG_CHECKING([whether va_list is an array type])
AC_TRY_COMPILE2([
#include <stdarg.h>
void a(va_list * ap) {}],[
va_list ap1, ap2; a(&ap1); ap2 = (va_list) ap1],[
  AC_MSG_RESULT(no)],[
  AC_MSG_RESULT(yes)
  AC_DEFINE([VA_LIST_IS_ARRAY], [1],[Define if va_list is an array type])])

dnl Checks for inet libraries:
AC_SEARCH_LIBS(gethostent, [nsl])
AC_SEARCH_LIBS(setsockopt, [socket net network])
AC_SEARCH_LIBS(connect, [inet])

dnl Determine what socket length (socklen_t) data type is
AC_MSG_CHECKING([for type of socket length (socklen_t)])
AC_TRY_COMPILE2([
#include <stddef.h>
#include <sys/types.h>
#include <sys/socket.h>],[
(void)getsockopt (1, 1, 1, NULL, (socklen_t *)NULL)],[
  AC_MSG_RESULT(socklen_t *)
  XML_SOCKLEN_T=socklen_t],[
  AC_TRY_COMPILE2([
#include <stddef.h>
#include <sys/types.h>
#include <sys/socket.h>],[
(void)getsockopt (1, 1, 1, NULL, (size_t *)NULL)],[
    AC_MSG_RESULT(size_t *)
    XML_SOCKLEN_T=size_t],[
    AC_TRY_COMPILE2([
#include <stddef.h>
#include <sys/types.h>
#include <sys/socket.h>],[
(void)getsockopt (1, 1, 1, NULL, (int *)NULL)],[
      AC_MSG_RESULT(int *)
      XML_SOCKLEN_T=int],[
      AC_MSG_WARN(could not determine)
      XML_SOCKLEN_T="int"])])])
AC_DEFINE_UNQUOTED(XML_SOCKLEN_T, $XML_SOCKLEN_T, [Determine what socket length (socklen_t) data type is])

dnl Checking if gethostbyname() argument is const.
AC_MSG_CHECKING([for const gethostbyname() argument])
AC_LINK_IFELSE([AC_LANG_PROGRAM([[#include <netdb.h>]],
    [[(void)gethostbyname((const char *)"");]])],
have_gethostbyname_const_arg=yes,
have_gethostbyname_const_arg=no)
AC_MSG_RESULT($have_gethostbyname_const_arg)
if test x"$have_gethostbyname_const_arg" = x"yes"; then
    AC_DEFINE([GETHOSTBYNAME_ARG_CAST], [],
      [Type cast for the gethostbyname() argument])
else
    AC_DEFINE([GETHOSTBYNAME_ARG_CAST], [(char *)],
      [Type cast for the gethostbyname() argument])
fi

dnl Checking if send() second argument is const.
AC_MSG_CHECKING([for const send() second argument])
AC_LINK_IFELSE([AC_LANG_PROGRAM([[#include <sys/types.h>
#include <sys/socket.h>]],
    [[(void)send(1,(const char *)"",1,1);]])],
have_send_const_arg2=yes,
have_send_const_arg2=no)
AC_MSG_RESULT($have_send_const_arg2)
if test x"$have_send_const_arg2" = x"yes"; then
    AC_DEFINE([SEND_ARG2_CAST], [],
      [Type cast for the send() function 2nd arg])
else
    AC_DEFINE([SEND_ARG2_CAST], [(char *)],
      [Type cast for the send() function 2nd arg])
fi

dnl ***********************Checking for availability of IPv6*******************

AC_MSG_CHECKING([whether to enable IPv6])
AC_ARG_ENABLE(ipv6, [  --enable-ipv6[[=yes/no]]  enables compilation of IPv6 code [[default=yes]]],, enable_ipv6=yes)
if test "$with_minimum" = "yes"
then
    enable_ipv6=no
fi
if test $enable_ipv6 = yes; then
  have_ipv6=no
  AC_COMPILE_IFELSE([AC_LANG_PROGRAM([[
#   include <sys/types.h>
#   include <sys/socket.h>
    ]], [[
    struct sockaddr_storage ss;
    socket(AF_INET6, SOCK_STREAM, 0)
    ]])],
    have_ipv6=yes,
    have_ipv6=no
  )
  AC_MSG_RESULT($have_ipv6)

  if test $have_ipv6 = yes; then
    AC_DEFINE([SUPPORT_IP6], [], [Support for IPv6])
    have_broken_ss_family=no

    dnl *********************************************************************
    dnl on some platforms (like AIX 5L), the structure sockaddr doesn't have
    dnl a ss_family member, but rather __ss_family. Let's detect that
    dnl and define the HAVE_BROKEN_SS_FAMILY when we are on one of these
    dnl platforms.  However, we should only do this if ss_family is not
    dnl present.
    dnl ********************************************************************
    AC_MSG_CHECKING([struct sockaddr::ss_family])
    AC_COMPILE_IFELSE([AC_LANG_PROGRAM([[
#     include <sys/types.h>
#     include <sys/socket.h>
      ]], [[
      struct sockaddr_storage ss ;
      ss.ss_family = 0 ;
      ]])],
      have_ss_family=yes,
      have_ss_family=no
    )
    AC_MSG_RESULT($have_ss_family)
    if test x$have_ss_family = xno ; then
      AC_MSG_CHECKING([broken struct sockaddr::ss_family])
      AC_COMPILE_IFELSE([AC_LANG_PROGRAM([[
#       include <sys/types.h>
#       include <sys/socket.h>
        ]], [[
        struct sockaddr_storage ss ;
        ss.__ss_family = 0 ;
        ]])],
        have_broken_ss_family=yes,
        have_broken_ss_family=no
      )
      AC_MSG_RESULT($have_broken_ss_family)
      if test x$have_broken_ss_family = xyes ; then
        AC_DEFINE(HAVE_BROKEN_SS_FAMILY, [],
	  [Whether struct sockaddr::__ss_family exists]) 
        AC_DEFINE(ss_family, __ss_family,
	  [ss_family is not defined here, use __ss_family instead])
      else
        AC_MSG_WARN(ss_family and __ss_family not found)
      fi
    fi

    have_getaddrinfo=no
    AC_CHECK_FUNC(getaddrinfo, have_getaddrinfo=yes)
    if test $have_getaddrinfo != yes; then
      for lib in bsd socket inet; do
        AC_CHECK_LIB($lib, getaddrinfo, [LIBS="$LIBS -l$lib";have_getaddrinfo=yes;break])
      done
    fi

    if test $have_getaddrinfo = yes; then
      AC_DEFINE([HAVE_GETADDRINFO], [], [Define if getaddrinfo is there])
    fi
  fi
fi 

dnl ******************************End IPv6 checks******************************

dnl Checks for isnan in libm if not in libc
AC_CHECK_FUNC(isnan, AC_DEFINE([HAVE_ISNAN],[], [Define if isnan is there]) , AC_CHECK_LIB(m, isnan,
  [AC_DEFINE([HAVE_ISNAN],[], [Define if isnan is there])]))

AC_CHECK_FUNC(isinf, AC_DEFINE([HAVE_ISINF], [], [Define if isinf is there]) , AC_CHECK_LIB(m, isinf,
  [AC_DEFINE([HAVE_ISINF], [], [Define if isinf is there])]))

XML_LIBDIR='-L${libdir}'
XML_INCLUDEDIR='-I${includedir}/libxml2'

dnl
dnl Extra flags
dnl
XML_CFLAGS=""
RDL_LIBS=""

dnl
dnl Workaround for native compilers
dnl  HP  : http://bugs.gnome.org/db/31/3163.html
dnl  DEC : Enable NaN/Inf
dnl
if test "${GCC}" != "yes" ; then
    case "${host}" in
          hppa*-*-hpux* )
	       CFLAGS="${CFLAGS} -Wp,-H30000"
	       ;;
          *-dec-osf* )
               CFLAGS="${CFLAGS} -ieee"
               ;;
	  alpha*-*-linux* )
	       CFLAGS="${CFLAGS} -ieee"
	       ;;
    esac
else
    if test "$with_fexceptions" = "yes"
    then
        #
	# Not activated by default because this inflates the code size
	# Used to allow propagation of C++ exceptions through the library
	#
	CFLAGS="${CFLAGS} -fexceptions"
    fi

    # warnings we'd like to see
    CFLAGS="${CFLAGS} -pedantic -W -Wformat -Wunused -Wimplicit -Wreturn-type -Wswitch -Wcomment -Wtrigraphs -Wformat -Wchar-subscripts -Wuninitialized -Wparentheses -Wshadow -Wpointer-arith -Wcast-align -Wwrite-strings -Waggregate-return -Wstrict-prototypes -Wmissing-prototypes -Wnested-externs -Winline -Wredundant-decls"
    # warnings we'd like to supress
    CFLAGS="${CFLAGS} -Wno-long-long"
    case "${host}" in
          alpha*-*-linux* )
	       CFLAGS="${CFLAGS} -mieee"
	       ;;
	  alpha*-*-osf* )
	       CFLAGS="${CFLAGS} -mieee"
	       ;;
    esac
fi
case ${host} in
    *-*-solaris*)
        XML_LIBDIR="${XML_LIBDIR} -R${libdir}"
        ;;
    hppa*-hp-mpeix)
        NEED_TRIO=1
	;;
    *-*-mingw* | *-*-cygwin* | *-*-msvc* )
        # If the host is Windows, and shared libraries are disabled, we
        # need to add -DLIBXML_STATIC to CFLAGS in order for linking to
        # work properly (without it, xmlexports.h would force the use of
        # DLL imports, which obviously aren't present in a static
        # library).
        if test "x$enable_shared" = "xno"; then
            XML_CFLAGS="$XML_CFLAGS -DLIBXML_STATIC"
            CFLAGS="$CFLAGS -DLIBXML_STATIC"
        fi
        ;;
esac


dnl
dnl check for python
dnl

PYTHON_VERSION=
PYTHON_INCLUDES=
PYTHON_SITE_PACKAGES=
PYTHON_TESTS=
pythondir=
if test "$with_python" != "no" ; then
    if test -x "$with_python/bin/python"
    then
        echo Found python in $with_python/bin/python
        PYTHON="$with_python/bin/python"
    else
        if test -x "$with_python/python.exe"
        then
            echo Found python in $with_python/python.exe
            PYTHON="$with_python/python.exe"
        else
            if test -x "$with_python"
            then
                echo Found python in $with_python
                PYTHON="$with_python"
            else
                if test -x "$PYTHON"
                then
                    echo Found python in environment PYTHON=$PYTHON
                    with_python=`$PYTHON -c "import sys; print(sys.exec_prefix)"`
                else
                    AC_PATH_PROG(PYTHON, python python2.6 python2.5 python2.4 python2.3 python2.2 python2.1 python2.0 python1.6 python1.5)
		fi
	    fi
	fi
    fi
    if test "$PYTHON" != ""
    then
        PYTHON_VERSION=`$PYTHON -c "from distutils import sysconfig; print(sysconfig.get_python_version())"`
	PYTHON_INCLUDES=`$PYTHON -c "from distutils import sysconfig; print(sysconfig.get_python_inc())"`
# does not work as it produce a /usr/lib/python path instead of/usr/lib64/python
#
#	PYTHON_SITE_PACKAGES=`$PYTHON -c "from distutils import sysconfig; print(sysconfig.get_python_lib())"`
	echo Found Python version $PYTHON_VERSION
    fi
    if test "$PYTHON_VERSION" != "" -a "$PYTHON_INCLUDES" = ""
    then
	if test -r $with_python/include/python$PYTHON_VERSION/Python.h
	then
	    PYTHON_INCLUDES=$with_python/include/python$PYTHON_VERSION
	else
	    if test -r $prefix/include/python$PYTHON_VERSION/Python.h
	    then
	        PYTHON_INCLUDES=$prefix/include/python$PYTHON_VERSION
	    else
		if test -r /usr/include/python$PYTHON_VERSION/Python.h
		then
		    PYTHON_INCLUDES=/usr/include/python$PYTHON_VERSION
		else
	            if test -r $with_python/include/Python.h
	            then
	                PYTHON_INCLUDES=$with_python/include
	            else
		        echo could not find python$PYTHON_VERSION/Python.h or $with_python/include/Python.h
		    fi
		fi
	    fi
	fi
    fi
    if test "$with_python_install_dir" != ""
    then
	PYTHON_SITE_PACKAGES="$with_python_install_dir"
    fi
    if test "$PYTHON_VERSION" != "" -a "$PYTHON_SITE_PACKAGES" = ""
    then
	if test -d $libdir/python$PYTHON_VERSION/site-packages
	then
	    PYTHON_SITE_PACKAGES=$libdir/python$PYTHON_VERSION/site-packages
	else
	    if test -d $with_python/lib/site-packages
	    then
		PYTHON_SITE_PACKAGES=$with_python/lib/site-packages
	    else
		PYTHON_SITE_PACKAGES=`$PYTHON -c "from distutils import sysconfig; print(sysconfig.get_python_lib())"`
	    fi
	fi
    fi
    pythondir='$(PYTHON_SITE_PACKAGES)'
    PYTHON_LIBS=`python$PYTHON_VERSION-config --ldflags`
else
    PYTHON=
fi
AM_CONDITIONAL(WITH_PYTHON, test "$PYTHON_INCLUDES" != "")
if test "$PYTHON_INCLUDES" != ""
then
    PYTHON_SUBDIR=python
else
    PYTHON_SUBDIR=
fi
AC_SUBST(pythondir)
AC_SUBST(PYTHON_SUBDIR)
AC_SUBST(PYTHON_LIBS)

dnl check for dso support
WITH_MODULES=0
TEST_MODULES=

if test "$with_modules" != "no" ; then
 case "$host" in
  *-*-cygwin*)
  MODULE_EXTENSION=".dll"
  AC_CHECK_LIB(cygwin, dlopen, [
    WITH_MODULES=1
    MODULE_PLATFORM_LIBS=
    AC_DEFINE([HAVE_DLOPEN], [], [Have dlopen based dso])
  ])
  ;;
  *-*-mingw*)
  MODULE_EXTENSION=".dll"
  WITH_MODULES=1
  ;;
  *)
  AC_CHECK_FUNC(shl_load, libxml_have_shl_load=yes, [
    AC_CHECK_LIB(dld, shl_load, [
      MODULE_PLATFORM_LIBS="-ldld"
      libxml_have_shl_load=yes], [
      AC_CHECK_FUNC(dlopen, libxml_have_dlopen=yes, [
        AC_CHECK_LIB(dl, dlopen, [
          MODULE_PLATFORM_LIBS="-ldl"
          libxml_have_dlopen=yes])])])])

  if test "${libxml_have_shl_load}" = "yes"; then
    MODULE_EXTENSION=".sl"
    WITH_MODULES=1
    AC_DEFINE([HAVE_SHLLOAD], [], [Have shl_load based dso])
  fi
 
  if test "${libxml_have_dlopen}" = "yes"; then
    case "${host}" in
      *-*-hpux* )
	MODULE_EXTENSION=".sl"
	;;
      * )
	MODULE_EXTENSION=".so"
	;;
    esac

    WITH_MODULES=1
    AC_DEFINE([HAVE_DLOPEN], [], [Have dlopen based dso])
  fi
 ;;
 esac
fi

if test "${WITH_MODULES}" = "1"; then
  TEST_MODULES="ModuleTests"
fi  

AC_SUBST(WITH_MODULES)
AC_SUBST(MODULE_PLATFORM_LIBS)
AC_SUBST(MODULE_EXTENSION)
AC_SUBST(TEST_MODULES)

dnl
dnl Tester makes use of readline if present
dnl

dnl
dnl specific tests to setup DV and Bill's devel environments with debug etc ...
dnl (-Wunreachable-code)
dnl
if [[ "${LOGNAME}" = "veillard" -a "`pwd`" = "/u/veillard/XML" ]] || \
   [[ "${LOGNAME}" = "veillard" -a "`pwd`" = "/home/veillard/libxml2" ]] || \
   [[ "${LOGNAME}" = "bill" -a "`pwd`" = "/home/bill/gnomesvn/libxml2" ]]
   then
    if test "$with_minimum" != "yes"
    then
	if test "${with_mem_debug}" = "" ; then
	    echo Activating memory debugging
	    with_mem_debug="yes"
	    with_run_debug="yes"
	fi
	if test "${with_docbook}" = "" ; then
	    with_docbook="yes"
	fi
    fi
    if test "${GCC}" = "yes" ; then
    CFLAGS="-g -O -pedantic -W -Wformat -Wunused -Wimplicit -Wreturn-type -Wswitch -Wcomment -Wtrigraphs -Wformat -Wchar-subscripts -Wuninitialized -Wparentheses -Wshadow -Wpointer-arith -Wcast-align -Wwrite-strings -Waggregate-return -Wstrict-prototypes -Wmissing-prototypes -Wnested-externs -Winline -Wredundant-decls -Wall"
    fi
    STATIC_BINARIES="-static"
dnl -Wcast-qual -ansi
else
    STATIC_BINARIES=
fi
AC_SUBST(STATIC_BINARIES)

dnl
dnl Check for trio string functions
dnl

if test "${NEED_TRIO}" = "1" ; then
    echo Adding trio library for string functions
    WITH_TRIO=1
else    
    WITH_TRIO=0
fi
AM_CONDITIONAL(WITH_TRIO_SOURCES, test "${NEED_TRIO}" = "1")
AC_SUBST(WITH_TRIO)

dnl
dnl Allow to enable/disable various pieces
dnl
echo Checking configuration requirements

dnl
dnl Thread-related stuff
dnl
THREAD_LIBS=""
BASE_THREAD_LIBS=""
WITH_THREADS=0
THREAD_CFLAGS=""
TEST_THREADS=""
THREADS_W32=""
WITH_THREAD_ALLOC=0

if test "$with_threads" = "no" ; then
    echo Disabling multithreaded support
else
    echo Enabling multithreaded support

    dnl Default to native threads on Win32
    case $host_os in
       *mingw32*) if test "$with_threads" != "pthread" && test "$with_threads" != "no"; then
               WITH_THREADS="1"
               THREADS_W32="1"
               THREAD_CFLAGS="$THREAD_CFLAGS -DHAVE_WIN32_THREADS"
           fi
       ;;
    esac

    dnl Use pthread by default in other cases
    if test -z "$THREADS_W32"; then
        if test "$with_threads" = "pthread" || test "$with_threads" = "" || test "$with_threads" = "yes" ; then
            AC_CHECK_HEADER(pthread.h,
                AC_CHECK_LIB(pthread, pthread_join,[
                THREAD_LIBS="-lpthread"
                AC_DEFINE([HAVE_LIBPTHREAD], [], [Define if pthread library is there (-lpthread)])
                AC_DEFINE([HAVE_PTHREAD_H], [], [Define if <pthread.h> is there])
                WITH_THREADS="1"]))
        fi
    fi

    case $host_os in
       *cygwin*) THREAD_LIBS=""
       ;;
       *beos*) WITH_THREADS="1"
	   THREAD_CFLAGS="$THREAD_CFLAGS -DHAVE_BEOS_THREADS"
       ;;
       *linux*)
           if test "${GCC}" = "yes" ; then
	       GCC_VERSION=`${CC} --version | head -1 | awk '{print $3}'`
	       GCC_MAJOR=`echo ${GCC_VERSION} | sed 's+\..*++'`
	       GCC_MEDIUM=`echo ${GCC_VERSION} | sed 's+[[0-9]]*\.++' | sed 's+\..*++'`
	       if test "${THREAD_LIBS}" = "-lpthread" ; then
	           if expr ${GCC_MEDIUM} \> 2 \& ${GCC_MAJOR} = 3 > /dev/null
		   then
		       THREAD_LIBS=""
		       BASE_THREAD_LIBS="-lpthread"
		   else
		   if expr ${GCC_MAJOR} \> 3 > /dev/null
		   then
		       THREAD_LIBS=""
		       BASE_THREAD_LIBS="-lpthread"
		   else
		       echo old GCC disabling weak symbols for pthread
		   fi
		   fi
	       fi
	   fi
       ;;
    esac
    if test "$WITH_THREADS" = "1" ; then
	THREAD_CFLAGS="$THREAD_CFLAGS -D_REENTRANT"
	TEST_THREADS="Threadtests"
    fi
fi
if test "$with_thread_alloc" = "yes" -a "$WITH_THREADS" = "1" ; then
    WITH_THREAD_ALLOC=1
fi

AC_SUBST(THREAD_LIBS)
AC_SUBST(BASE_THREAD_LIBS)
AC_SUBST(WITH_THREADS)
AC_SUBST(THREAD_CFLAGS)
AC_SUBST(TEST_THREADS)
AC_SUBST(WITH_THREAD_ALLOC)
AM_CONDITIONAL([THREADS_W32],[test -n "$THREADS_W32"])

dnl
dnl xmllint shell history
dnl
if test "$with_history" = "yes" ; then
    echo Enabling xmllint shell history
    dnl check for terminal library. this is a very cool solution
    dnl from octave's configure.in
    unset tcap
    for termlib in ncurses curses termcap terminfo termlib; do
	AC_CHECK_LIB(${termlib}, tputs, [tcap="-l$termlib"])
	test -n "$tcap" && break
    done

    AC_CHECK_HEADER(readline/history.h,
	AC_CHECK_LIB(history, append_history,[
	   RDL_LIBS="-lhistory"
	   AC_DEFINE([HAVE_LIBHISTORY], [], [Define if history library is there (-lhistory)])]))
    AC_CHECK_HEADER(readline/readline.h,
	AC_CHECK_LIB(readline, readline,[
	   RDL_LIBS="-lreadline $RDL_LIBS $tcap"
	   AC_DEFINE([HAVE_LIBREADLINE], [], [Define if readline library is there (-lreadline)])], , $tcap))
    if test -n "$RDL_DIR" -a -n "$RDL_LIBS"; then
	CPPFLAGS="$CPPFLAGS -I${RDL_DIR}/include"
	RDL_LIBS="-L${RDL_DIR}/lib $RDL_LIBS"
    fi
fi

dnl
dnl Tree functions
dnl
if test "$with_tree" = "no" ; then
    echo Disabling DOM like tree manipulation APIs
    WITH_TREE=0
else    
    WITH_TREE=1
fi
AC_SUBST(WITH_TREE)

if test "$with_ftp" = "no" ; then
    echo Disabling FTP support
    WITH_FTP=0
    FTP_OBJ=
else    
    WITH_FTP=1
    FTP_OBJ=nanoftp.o
fi
AC_SUBST(WITH_FTP)
AC_SUBST(FTP_OBJ)

if test "$with_http" = "no" ; then
    echo Disabling HTTP support
    WITH_HTTP=0
    HTTP_OBJ=
else    
    WITH_HTTP=1
    HTTP_OBJ=nanohttp.o
fi
AC_SUBST(WITH_HTTP)
AC_SUBST(HTTP_OBJ)

if test "$with_legacy" = "no" ; then
    echo Disabling deprecated APIs
    WITH_LEGACY=0
else    
    WITH_LEGACY=1
fi
AC_SUBST(WITH_LEGACY)

if test "$with_reader" = "no" ; then
    echo Disabling the xmlReader parsing interface
    WITH_READER=0
    READER_TEST=
else    
    WITH_READER=1
    READER_TEST=Readertests
    if test "$with_push" = "no" ; then
        echo xmlReader requires Push interface - enabling it
	with_push=yes
    fi
fi
AC_SUBST(WITH_READER)
AC_SUBST(READER_TEST)

if test "$with_writer" = "no" ; then
    echo Disabling the xmlWriter saving interface
    WITH_WRITER=0
#    WRITER_TEST=
else    
    WITH_WRITER=1
#    WRITER_TEST=Writertests
    if test "$with_push" = "no" ; then
        echo xmlWriter requires Push interface - enabling it
	with_push=yes
    fi
    if test "$with_output" = "no" ; then
        echo xmlWriter requires Output interface - enabling it
	with_output=yes
    fi
fi
AC_SUBST(WITH_WRITER)
#AC_SUBST(WRITER_TEST)

if test "$with_pattern" = "no" ; then
    echo Disabling the xmlPattern parsing interface
    WITH_PATTERN=0
    TEST_PATTERN=
else    
    WITH_PATTERN=1
    TEST_PATTERN=Patterntests
fi
AC_SUBST(WITH_PATTERN)
AC_SUBST(TEST_PATTERN)

if test "$with_sax1" = "no" ; then
    echo Disabling the older SAX1 interface
    WITH_SAX1=0
    TEST_SAX=
else    
    WITH_SAX1=1
    TEST_SAX=SAXtests
fi
AC_SUBST(WITH_SAX1)
AM_CONDITIONAL(WITH_SAX1_SOURCES, test "${WITH_TRIO}" = "1")
AC_SUBST(TEST_SAX)

if test "$with_push" = "no" ; then
    echo Disabling the PUSH parser interfaces
    WITH_PUSH=0
    TEST_PUSH=
else    
    WITH_PUSH=1
    TEST_PUSH="XMLPushtests"
fi
AC_SUBST(WITH_PUSH)
AC_SUBST(TEST_PUSH)

if test "$with_html" = "no" ; then
    echo Disabling HTML support
    WITH_HTML=0
    HTML_OBJ=
    TEST_HTML=
else    
    WITH_HTML=1
    HTML_OBJ="HTMLparser.o HTMLtree.o"
    TEST_HTML=HTMLtests
    if test "$with_push" != "no" ; then
        TEST_PHTML=HTMLPushtests
    else
        TEST_PHTML=
    fi
fi
AC_SUBST(WITH_HTML)
AC_SUBST(HTML_OBJ)
AC_SUBST(TEST_HTML)
AC_SUBST(TEST_PHTML)

if test "$with_valid" = "no" ; then
    echo Disabling DTD validation support
    WITH_VALID=0
    TEST_VALID=
    TEST_VTIME=
else    
    WITH_VALID=1
    TEST_VALID=Validtests
    TEST_VTIME=VTimingtests
fi
AC_SUBST(WITH_VALID)
AC_SUBST(TEST_VALID)
AC_SUBST(TEST_VTIME)

if test "$with_catalog" = "no" ; then
    echo Disabling Catalog support
    WITH_CATALOG=0
    CATALOG_OBJ=
    TEST_CATALOG=
else    
    WITH_CATALOG=1
    CATALOG_OBJ="catalog.o"
    TEST_CATALOG=Catatests
fi
AC_SUBST(WITH_CATALOG)
AC_SUBST(CATALOG_OBJ)
AC_SUBST(TEST_CATALOG)

if test "$with_docbook" = "no" ; then
    echo Disabling Docbook support
    WITH_DOCB=0
    DOCB_OBJ=
else    
    WITH_DOCB=1
    DOCB_OBJ="DOCBparser.o"
fi
AC_SUBST(WITH_DOCB)
AC_SUBST(DOCB_OBJ)


if test "$with_xptr" = "no" ; then
    echo Disabling XPointer support
    WITH_XPTR=0
    XPTR_OBJ=
    TEST_XPTR=
else    
    WITH_XPTR=1
    XPTR_OBJ=xpointer.o
    TEST_XPTR=XPtrtests
    if test "$with_xpath" = "no" ; then
        echo XPointer requires XPath support - enabling it
	with_xpath=yes
    fi
fi
AC_SUBST(WITH_XPTR)
AC_SUBST(XPTR_OBJ)
AC_SUBST(TEST_XPTR)

if test "$with_c14n" = "no" ; then
    echo Disabling C14N support
    WITH_C14N=0
    C14N_OBJ=
    TEST_C14N=
else    
    WITH_C14N=1
    C14N_OBJ="c14n.c"
    TEST_C14N=C14Ntests
    if test "$with_xpath" = "no" ; then
        echo C14N requires XPath support - enabling it
	with_xpath=yes
    fi
fi
AC_SUBST(WITH_C14N)
AC_SUBST(C14N_OBJ)
AC_SUBST(TEST_C14N)

if test "$with_xinclude" = "no" ; then
    echo Disabling XInclude support
    WITH_XINCLUDE=0
    XINCLUDE_OBJ=
    with_xinclude="no"
    TEST_XINCLUDE=
else    
    WITH_XINCLUDE=1
    XINCLUDE_OBJ=xinclude.o
    TEST_XINCLUDE=XIncludetests
    if test "$with_xpath" = "no" ; then
        echo XInclude requires XPath support - enabling it
	with_xpath=yes
    fi
fi
AC_SUBST(WITH_XINCLUDE)
AC_SUBST(XINCLUDE_OBJ)
AC_SUBST(TEST_XINCLUDE)

if test "$with_xptr" = "" -a "$with_xpath" = "no" ; then
    with_xptr=no
fi

if test "$with_schematron" = "" -a "$with_xpath" = "no" ; then
    with_schematron=no
fi

if test "$with_schematron" = "no" ; then
    echo "Disabling Schematron support"
    WITH_SCHEMATRON=0
    TEST_SCHEMATRON=
else 
    echo "Enabled Schematron support"
    WITH_SCHEMATRON=1
    TEST_SCHEMATRON="Schematrontests"
    with_xpath=yes
    with_pattern=yes
    with_schematron=yes
fi
AC_SUBST(WITH_SCHEMATRON)
AC_SUBST(TEST_SCHEMATRON)

if test "$with_xpath" = "no" ; then
    echo Disabling XPATH support
    WITH_XPATH=0
    XPATH_OBJ=
    TEST_XPATH=
else    
    WITH_XPATH=1
    XPATH_OBJ=xpath.o
    TEST_XPATH=XPathtests
fi
AC_SUBST(WITH_XPATH)
AC_SUBST(XPATH_OBJ)
AC_SUBST(TEST_XPATH)

dnl
dnl output functions
dnl
if test "$with_output" = "no" ; then
    echo Disabling serialization/saving support
    WITH_OUTPUT=0
else    
    WITH_OUTPUT=1
fi
AC_SUBST(WITH_OUTPUT)

WITH_ICONV=0
if test "$with_iconv" = "no" ; then
    echo Disabling ICONV support
else
    if test "$with_iconv" != "yes" -a "$with_iconv" != "" ; then
	CPPFLAGS="${CPPFLAGS} -I$with_iconv/include"
	# Export this since our headers include iconv.h
	XML_INCLUDEDIR="${XML_INCLUDEDIR} -I$with_iconv/include"
	ICONV_LIBS="-L$with_iconv/lib"
    fi

    AC_CHECK_HEADER(iconv.h,
	AC_MSG_CHECKING(for iconv)
	AC_LINK_IFELSE([AC_LANG_PROGRAM([[#include <stdlib.h>
#include <iconv.h>]],[[
iconv_t cd = iconv_open ("","");
iconv (cd, NULL, NULL, NULL, NULL);]])],[
	    AC_MSG_RESULT(yes)
	    WITH_ICONV=1],[
	    AC_MSG_RESULT(no)
	    AC_MSG_CHECKING(for iconv in -liconv)

	    _ldflags="${LDFLAGS}"
	    _libs="${LIBS}"
	    LDFLAGS="${LDFLAGS} ${ICONV_LIBS}"
	    LIBS="${LIBS} -liconv"

	    AC_LINK_IFELSE([AC_LANG_PROGRAM([[#include <stdlib.h>
#include <iconv.h>]],[[
iconv_t cd = iconv_open ("","");
iconv (cd, NULL, NULL, NULL, NULL);]])],[
		AC_MSG_RESULT(yes)
		WITH_ICONV=1
		ICONV_LIBS="${ICONV_LIBS} -liconv"
		LIBS="${_libs}"
		LDFLAGS="${_ldflags}"],[
		AC_MSG_RESULT(no)
		LIBS="${_libs}"
		LDFLAGS="${_ldflags}"])]))

	if test "$WITH_ICONV" = "1" ; then
		AC_MSG_CHECKING([for iconv declaration])
		AC_CACHE_VAL(xml_cv_iconv_arg2, [
			AC_COMPILE_IFELSE([AC_LANG_PROGRAM([[#include <stdlib.h>
#include <iconv.h>
extern
#ifdef __cplusplus
"C"
#endif
#if defined(__STDC__) || defined(__cplusplus)
size_t iconv (iconv_t cd, char * *inbuf, size_t *inbytesleft, char * *outbuf, size_t *outbytesleft);
#else
size_t iconv();
#endif
]], [])], xml_cv_iconv_arg2="", xml_cv_iconv_arg2="const")])

		xml_cv_iconv_decl="extern size_t iconv (iconv_t cd, $xml_cv_iconv_arg2 char * *inbuf, size_t *inbytesleft, char * *outbuf, size_t *outbytesleft);"
		AC_MSG_RESULT([${xml_xxx:-
	}$xml_cv_iconv_decl])
		AC_DEFINE_UNQUOTED(ICONV_CONST, $xml_cv_iconv_arg2,
			[Define as const if the declaration of iconv() needs const.])
	fi
fi
case "$host" in
	*mingw*) M_LIBS=""
	;;
	*beos*) M_LIBS=""
	;;
        *haiku*) M_LIBS=""
        ;;
	*) M_LIBS="-lm"
	;;
esac
XML_LIBS="-lxml2 $Z_LIBS $THREAD_LIBS $ICONV_LIBS $M_LIBS $LIBS"
XML_LIBTOOLLIBS="libxml2.la"
AC_SUBST(WITH_ICONV)

WITH_ICU=0
ICU_LIBS=""
if test "$with_icu" != "yes" ; then
    echo Disabling ICU support
else
    ICU_CONFIG=icu-config
    if ${ICU_CONFIG} --cflags >/dev/null 2>&1
    then
        ICU_LIBS=`${ICU_CONFIG} --ldflags`
        WITH_ICU=1
        echo Enabling ICU support
    else
        AC_MSG_ERROR([libicu config program icu-config not found])
    fi
fi
AC_SUBST(WITH_ICU)
AC_SUBST(ICU_LIBS)

WITH_ISO8859X=1
if test "$WITH_ICONV" != "1" ; then
if test "$with_iso8859x" = "no" ; then
    echo Disabling ISO8859X support
    WITH_ISO8859X=0
fi
fi
AC_SUBST(WITH_ISO8859X)

if test "$with_schemas" = "no" ; then
    echo "Disabling Schemas/Relax-NG support"
    WITH_SCHEMAS=0
    TEST_SCHEMAS=
else    
    echo "Enabled Schemas/Relax-NG support"
    WITH_SCHEMAS=1
    TEST_SCHEMAS="Schemastests Relaxtests"
    if test "$PYTHON_INCLUDES" != "" ; then
        PYTHON_TESTS="$PYTHON_TESTS RelaxNGPythonTests SchemasPythonTests"
    fi
    with_regexps=yes
fi
AC_SUBST(WITH_SCHEMAS)
AC_SUBST(TEST_SCHEMAS)

if test "$with_regexps" = "no" ; then
    echo Disabling Regexps support
    WITH_REGEXPS=0
    TEST_REGEXPS=
else    
    WITH_REGEXPS=1
    TEST_REGEXPS="Regexptests Automatatests"
fi
AC_SUBST(WITH_REGEXPS)
AC_SUBST(TEST_REGEXPS)

if test "$with_debug" = "no" ; then
    echo Disabling DEBUG support
    WITH_DEBUG=0
    DEBUG_OBJ=
    TEST_DEBUG=
else    
    WITH_DEBUG=1
    DEBUG_OBJ=debugXML.o
    TEST_DEBUG=Scripttests
fi
AC_SUBST(WITH_DEBUG)
AC_SUBST(DEBUG_OBJ)
AC_SUBST(TEST_DEBUG)

if test "$with_mem_debug" = "yes" ; then
    if test "$with_thread_alloc" = "yes" ; then
        echo Disabling memory debug - cannot use mem-debug with thread-alloc!
	WITH_MEM_DEBUG=0
    else
        echo Enabling memory debug support
        WITH_MEM_DEBUG=1
    fi
else    
    WITH_MEM_DEBUG=0
fi
AC_SUBST(WITH_MEM_DEBUG)

if test "$with_run_debug" = "yes" ; then
    echo Enabling runtime debug support
    WITH_RUN_DEBUG=1
else    
    WITH_RUN_DEBUG=0
fi
AC_SUBST(WITH_RUN_DEBUG)

WIN32_EXTRA_LIBADD=
WIN32_EXTRA_LDFLAGS=
CYGWIN_EXTRA_LDFLAGS=
CYGWIN_EXTRA_PYTHON_LIBADD=
WIN32_EXTRA_PYTHON_LIBADD=
case "$host" in
 *-*-mingw*)
 CPPFLAGS="$CPPFLAGS -DWIN32"
 WIN32_EXTRA_LIBADD="-lws2_32"
 WIN32_EXTRA_LDFLAGS="-no-undefined"
 AC_DEFINE([_WINSOCKAPI_],1,[Using the Win32 Socket implementation])
 if test "${PYTHON}" != ""
 then
   WIN32_EXTRA_PYTHON_LIBADD="-L${pythondir}/../../libs -lpython$(echo ${PYTHON_VERSION} | tr -d .)"
 fi
 ;;
 *-*-cygwin*)
 CYGWIN_EXTRA_LDFLAGS="-no-undefined"
 if test "${PYTHON}" != ""
 then
   CYGWIN_EXTRA_PYTHON_LIBADD="-L/usr/lib/python${PYTHON_VERSION}/config -lpython${PYTHON_VERSION}"
 fi
 ;;
esac
AC_SUBST(WIN32_EXTRA_LIBADD)
AC_SUBST(WIN32_EXTRA_LDFLAGS)
AC_SUBST(WIN32_EXTRA_PYTHON_LIBADD)
AC_SUBST(CYGWIN_EXTRA_LDFLAGS)
AC_SUBST(CYGWIN_EXTRA_PYTHON_LIBADD)

dnl Checking the standard string functions availability
dnl
dnl Note mingw* has C99 implementation that produce expected xml numbers
dnl if code use {v}snprintf functions.
dnl If you like to activate at run-time C99 compatible number output
dnl see release note for mingw runtime 3.15:
dnl  http://sourceforge.net/project/shownotes.php?release_id=24832
dnl
dnl Also *win32*config.h files redefine them for various MSC compilers.
dnl
dnl So do not redefine {v}snprintf to _{v}snprintf like follwing:
dnl  AC_DEFINE([snprintf],[_snprintf],[Win32 Std C name mangling work-around])
dnl  AC_DEFINE([vsnprintf],[_vsnprintf],[Win32 Std C name mangling work-around])
dnl and do not redefine those functions is C-source files.
dnl
AC_CHECK_FUNCS(printf sprintf fprintf snprintf vfprintf vsprintf vsnprintf sscanf,,
	NEED_TRIO=1)

if test "$with_coverage" = "yes" -a "${GCC}" = "yes"
then
    echo Enabling code coverage for GCC
    CFLAGS="$CFLAGS -fprofile-arcs -ftest-coverage"
    LDFLAGS="$LDFLAGS -fprofile-arcs -ftest-coverage"
else
    echo Disabling code coverage for GCC
fi

AC_SUBST(CPPFLAGS)
AC_SUBST(CFLAGS)
AC_SUBST(LDFLAGS)
AC_SUBST(XML_CFLAGS)

AC_SUBST(XML_LIBDIR)
AC_SUBST(XML_LIBS)
AC_SUBST(XML_LIBTOOLLIBS)
AC_SUBST(ICONV_LIBS)
AC_SUBST(XML_INCLUDEDIR)
AC_SUBST(HTML_DIR)
AC_SUBST(HAVE_ISNAN)
AC_SUBST(HAVE_ISINF)
AC_SUBST(PYTHON)
AC_SUBST(PYTHON_VERSION)
AC_SUBST(PYTHON_INCLUDES)
AC_SUBST(PYTHON_SITE_PACKAGES)

AC_SUBST(M_LIBS)
AC_SUBST(RDL_LIBS)

dnl for the spec file
RELDATE=`date +'%a %b %e %Y'`
AC_SUBST(RELDATE)
AC_SUBST(PYTHON_TESTS)

rm -f COPYING.LIB COPYING
ln -s $srcdir/Copyright COPYING

# keep on one line for cygwin c.f. #130896
AC_CONFIG_FILES([libxml2.spec:libxml.spec.in Makefile include/Makefile include/libxml/Makefile doc/Makefile doc/examples/Makefile doc/devhelp/Makefile example/Makefile python/Makefile python/tests/Makefile xstc/Makefile include/libxml/xmlversion.h libxml-2.0.pc libxml-2.0-uninstalled.pc libxml2-config.cmake])
AC_CONFIG_FILES([python/setup.py], [chmod +x python/setup.py])
AC_CONFIG_FILES([xml2-config], [chmod +x xml2-config])
AC_OUTPUT

echo Done configuring
