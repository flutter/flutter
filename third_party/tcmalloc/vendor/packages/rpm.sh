#!/bin/sh -e

# Run this from the 'packages' directory, just under rootdir

# We can only build rpm packages, if the rpm build tools are installed
if [ \! -x /usr/bin/rpmbuild ]
then
  echo "Cannot find /usr/bin/rpmbuild. Not building an rpm." 1>&2
  exit 0
fi

# Check the commandline flags
PACKAGE="$1"
VERSION="$2"
fullname="${PACKAGE}-${VERSION}"
archive=../$fullname.tar.gz

if [ -z "$1" -o -z "$2" ]
then
  echo "Usage: $0 <package name> <package version>" 1>&2
  exit 0
fi

# Double-check we're in the packages directory, just under rootdir
if [ \! -r ../Makefile -a \! -r ../INSTALL ]
then
  echo "Must run $0 in the 'packages' directory, under the root directory." 1>&2
  echo "Also, you must run \"make dist\" before running this script." 1>&2
  exit 0
fi

if [ \! -r "$archive" ]
then
  echo "Cannot find $archive. Run \"make dist\" first." 1>&2
  exit 0
fi

# Create the directory where the input lives, and where the output should live
RPM_SOURCE_DIR="/tmp/rpmsource-$fullname"
RPM_BUILD_DIR="/tmp/rpmbuild-$fullname"

trap 'rm -rf $RPM_SOURCE_DIR $RPM_BUILD_DIR; exit $?' EXIT SIGHUP SIGINT SIGTERM

rm -rf "$RPM_SOURCE_DIR" "$RPM_BUILD_DIR"
mkdir "$RPM_SOURCE_DIR"
mkdir "$RPM_BUILD_DIR"

cp "$archive" "$RPM_SOURCE_DIR"

# rpmbuild -- as far as I can tell -- asks the OS what CPU it has.
# This may differ from what kind of binaries gcc produces.  dpkg
# does a better job of this, so if we can run 'dpkg --print-architecture'
# to get the build CPU, we use that in preference of the rpmbuild
# default.
target=`dpkg --print-architecture 2>/dev/null || echo ""`
if [ -n "$target" ]
then
   target=" --target $target"
fi

rpmbuild -bb rpm/rpm.spec $target \
  --define "NAME $PACKAGE" \
  --define "VERSION $VERSION" \
  --define "_sourcedir $RPM_SOURCE_DIR" \
  --define "_builddir $RPM_BUILD_DIR" \
  --define "_rpmdir $RPM_SOURCE_DIR"

# We put the output in a directory based on what system we've built for
destdir=rpm-unknown
if [ -r /etc/issue ]
then
   grep "Red Hat.*release 7" /etc/issue >/dev/null 2>&1 && destdir=rh7
   grep "Red Hat.*release 8" /etc/issue >/dev/null 2>&1 && destdir=rh8
   grep "Red Hat.*release 9" /etc/issue >/dev/null 2>&1 && destdir=rh9
   grep "Fedora Core.*release 1" /etc/issue >/dev/null 2>&1 && destdir=fc1
   grep "Fedora Core.*release 2" /etc/issue >/dev/null 2>&1 && destdir=fc2
   grep "Fedora Core.*release 3" /etc/issue >/dev/null 2>&1 && destdir=fc3
fi

rm -rf "$destdir"
mkdir -p "$destdir"
# We want to get not only the main package but devel etc, hence the middle *
mv "$RPM_SOURCE_DIR"/*/"${PACKAGE}"-*"${VERSION}"*.rpm "$destdir"

echo
echo "The rpm package file(s) are located in $PWD/$destdir"
