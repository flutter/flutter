#!/bin/bash -e

# This takes one commandline argument, the name of the package.  If no
# name is given, then we'll end up just using the name associated with
# an arbitrary .tar.gz file in the rootdir.  That's fine: there's probably
# only one.
#
# Run this from the 'packages' directory, just under rootdir

## Set LIB to lib if exporting a library, empty-string else
LIB=
#LIB=lib

PACKAGE="$1"
VERSION="$2"

# We can only build Debian packages, if the Debian build tools are installed
if [ \! -x /usr/bin/debuild ]; then
  echo "Cannot find /usr/bin/debuild. Not building Debian packages." 1>&2
  exit 0
fi

# Double-check we're in the packages directory, just under rootdir
if [ \! -r ../Makefile -a \! -r ../INSTALL ]; then
  echo "Must run $0 in the 'packages' directory, under the root directory." 1>&2
  echo "Also, you must run \"make dist\" before running this script." 1>&2
  exit 0
fi

# Find the top directory for this package
topdir="${PWD%/*}"

# Find the tar archive built by "make dist"
archive="${PACKAGE}-${VERSION}"
archive_with_underscore="${PACKAGE}_${VERSION}"
if [ -z "${archive}" ]; then
  echo "Cannot find ../$PACKAGE*.tar.gz. Run \"make dist\" first." 1>&2
  exit 0
fi

# Create a pristine directory for building the Debian package files
trap 'rm -rf '`pwd`/tmp'; exit $?' EXIT SIGHUP SIGINT SIGTERM

rm -rf tmp
mkdir -p tmp
cd tmp

# Debian has very specific requirements about the naming of build
# directories, and tar archives. It also wants to write all generated
# packages to the parent of the source directory. We accommodate these
# requirements by building directly from the tar file.
ln -s "${topdir}/${archive}.tar.gz" "${LIB}${archive}.orig.tar.gz"
# Some version of debuilder want foo.orig.tar.gz with _ between versions.
ln -s "${topdir}/${archive}.tar.gz" "${LIB}${archive_with_underscore}.orig.tar.gz"
tar zfx "${LIB}${archive}.orig.tar.gz"
[ -n "${LIB}" ] && mv "${archive}" "${LIB}${archive}"
cd "${LIB}${archive}"
# This is one of those 'specific requirements': where the deb control files live
cp -a "packages/deb" "debian"

# Now, we can call Debian's standard build tool
debuild -uc -us
cd ../..                            # get back to the original top-level dir

# We'll put the result in a subdirectory that's named after the OS version
# we've made this .deb file for.
destdir="debian-$(cat /etc/debian_version 2>/dev/null || echo UNKNOWN)"

rm -rf "$destdir"
mkdir -p "$destdir"
mv $(find tmp -mindepth 1 -maxdepth 1 -type f) "$destdir"

echo
echo "The Debian package files are located in $PWD/$destdir"
