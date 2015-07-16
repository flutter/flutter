#!/bin/sh
LIBTOOLIZE=libtoolize
SYSNAME=`uname`
if [ "x$SYSNAME" = "xDarwin" ] ; then
  LIBTOOLIZE=glibtoolize
fi
aclocal && \
	autoheader && \
	$LIBTOOLIZE && \
	autoconf && \
	automake --add-missing --copy
