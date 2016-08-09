#!/bin/sh

# Before using, you should figure out all the .m4 macros that your
# configure.m4 script needs and make sure they exist in the m4/
# directory.
#
# These are the files that this script might edit:
#    aclocal.m4 configure Makefile.in src/config.h.in \
#    depcomp config.guess config.sub install-sh missing mkinstalldirs \
#    ltmain.sh
#
# Here's a command you can run to see what files aclocal will import:
#  aclocal -I ../autoconf --output=- | sed -n 's/^m4_include..\([^]]*\).*/\1/p'

set -ex
rm -rf autom4te.cache

trap 'rm -f aclocal.m4.tmp' EXIT

# Returns the first binary in $* that exists, or the last arg, if none exists.
WhichOf() {
  for candidate in "$@"; do
    if "$candidate" --version >/dev/null 2>&1; then
      echo "$candidate"
      return
    fi
  done
  echo "$candidate"   # the last one in $@
}

# Use version 1.9 of aclocal and automake if available.
ACLOCAL=`WhichOf aclocal-1.9 aclocal`
AUTOMAKE=`WhichOf automake-1.9 automake`
LIBTOOLIZE=`WhichOf glibtoolize libtoolize15 libtoolize14 libtoolize`

# aclocal tries to overwrite aclocal.m4 even if the contents haven't
# changed, which is annoying when the file is not open for edit (in
# p4).  We work around this by writing to a temp file and just
# updating the timestamp if the file hasn't change.
"$ACLOCAL" --force -I m4 --output=aclocal.m4.tmp
if cmp aclocal.m4.tmp aclocal.m4; then
  touch aclocal.m4               # pretend that we regenerated the file
  rm -f aclocal.m4.tmp
else
  mv aclocal.m4.tmp aclocal.m4   # we did set -e above, so we die if this fails
fi

grep -q '^[^#]*AC_PROG_LIBTOOL' configure.ac && "$LIBTOOLIZE" -c -f
autoconf -f -W all,no-obsolete
autoheader -f -W all
"$AUTOMAKE" -a -c -f -W all

rm -rf autom4te.cache
exit 0
