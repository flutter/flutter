# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
#
# This script should not be run directly but sourced by the other
# scripts (e.g. sysroot-creator-trusty.sh).  Its up to the parent scripts
# to define certain environment variables: e.g.
#  DISTRO=ubuntu
#  DIST=trusty
#  APT_REPO=http://archive.ubuntu.com/ubuntu
#  KEYRING_FILE=/usr/share/keyrings/ubuntu-archive-keyring.gpg
#  DEBIAN_PACKAGES="gcc libz libssl"

#@ This script builds a Debian sysroot images for building Google Chrome.
#@
#@  Generally this script is invoked as:
#@  sysroot-creator-<flavour>.sh <mode> <args>*
#@  Available modes are shown below.
#@
#@ List of modes:

######################################################################
# Config
######################################################################

set -o nounset
set -o errexit

SCRIPT_DIR=$(cd $(dirname $0) && pwd)

if [ -z "${DIST:-}" ]; then
  echo "error: DIST not defined"
  exit 1
fi

if [ -z "${APT_REPO:-}" ]; then
  echo "error: APT_REPO not defined"
  exit 1
fi

if [ -z "${KEYRING_FILE:-}" ]; then
  echo "error: KEYRING_FILE not defined"
  exit 1
fi

if [ -z "${DEBIAN_PACKAGES:-}" ]; then
  echo "error: DEBIAN_PACKAGES not defined"
  exit 1
fi

readonly REPO_BASEDIR="${APT_REPO}/dists/${DIST}"

readonly REQUIRED_TOOLS="wget"

######################################################################
# Package Config
######################################################################

readonly RELEASE_FILE="Release"
readonly RELEASE_FILE_GPG="Release.gpg"
readonly RELEASE_LIST="${REPO_BASEDIR}/${RELEASE_FILE}"
readonly RELEASE_LIST_GPG="${REPO_BASEDIR}/${RELEASE_FILE_GPG}"
readonly PACKAGE_FILE_AMD64="main/binary-amd64/Packages.bz2"
readonly PACKAGE_FILE_I386="main/binary-i386/Packages.bz2"
readonly PACKAGE_FILE_ARM="main/binary-armhf/Packages.bz2"
readonly PACKAGE_FILE_MIPS="main/binary-mipsel/Packages.bz2"
readonly PACKAGE_LIST_AMD64="${REPO_BASEDIR}/${PACKAGE_FILE_AMD64}"
readonly PACKAGE_LIST_I386="${REPO_BASEDIR}/${PACKAGE_FILE_I386}"
readonly PACKAGE_LIST_ARM="${REPO_BASEDIR}/${PACKAGE_FILE_ARM}"
readonly PACKAGE_LIST_MIPS="${REPO_BASEDIR}/${PACKAGE_FILE_MIPS}"

readonly DEBIAN_DEP_LIST_AMD64="packagelist.${DIST}.amd64"
readonly DEBIAN_DEP_LIST_I386="packagelist.${DIST}.i386"
readonly DEBIAN_DEP_LIST_ARM="packagelist.${DIST}.arm"
readonly DEBIAN_DEP_LIST_MIPS="packagelist.${DIST}.mipsel"

######################################################################
# Helper
######################################################################

Banner() {
  echo "######################################################################"
  echo $*
  echo "######################################################################"
}


SubBanner() {
  echo "----------------------------------------------------------------------"
  echo $*
  echo "----------------------------------------------------------------------"
}


Usage() {
  egrep "^#@" "${BASH_SOURCE[0]}" | cut --bytes=3-
}


DownloadOrCopy() {
  if [ -f "$2" ] ; then
    echo "$2 already in place"
    return
  fi

  HTTP=0
  echo "$1" | grep -qs ^http:// && HTTP=1
  if [ "$HTTP" = "1" ]; then
    SubBanner "downloading from $1 -> $2"
    wget "$1" -O "${2}.partial"
    mv "${2}.partial" $2
  else
    SubBanner "copying from $1"
    cp "$1" "$2"
  fi
}


SetEnvironmentVariables() {
  ARCH=""
  echo $1 | grep -qs Amd64$ && ARCH=AMD64
  if [ -z "$ARCH" ]; then
    echo $1 | grep -qs I386$ && ARCH=I386
  fi
  if [ -z "$ARCH" ]; then
    echo $1 | grep -qs Mips$ && ARCH=MIPS
  fi
  if [ -z "$ARCH" ]; then
    echo $1 | grep -qs ARM$ && ARCH=ARM
  fi
  if [ -z "${ARCH}" ]; then
    echo "ERROR: Unable to determine architecture based on: $1"
    exit 1
  fi
  ARCH_LOWER=$(echo $ARCH | tr '[:upper:]' '[:lower:]')
}


# some sanity checks to make sure this script is run from the right place
# with the right tools
SanityCheck() {
  Banner "Sanity Checks"

  local chrome_dir=$(cd "${SCRIPT_DIR}/../../../.." && pwd)
  BUILD_DIR="${chrome_dir}/out/sysroot-build/${DIST}"
  mkdir -p ${BUILD_DIR}
  echo "Using build directory: ${BUILD_DIR}"

  for tool in ${REQUIRED_TOOLS} ; do
    if ! which ${tool} > /dev/null ; then
      echo "Required binary $tool not found."
      echo "Exiting."
      exit 1
    fi
  done

  # This is where the staging sysroot is.
  INSTALL_ROOT="${BUILD_DIR}/${DIST}_${ARCH_LOWER}_staging"
  TARBALL="${BUILD_DIR}/${DISTRO}_${DIST}_${ARCH_LOWER}_sysroot.tgz"

  if ! mkdir -p "${INSTALL_ROOT}" ; then
    echo "ERROR: ${INSTALL_ROOT} can't be created."
    exit 1
  fi
}


ChangeDirectory() {
  # Change directory to where this script is.
  cd ${SCRIPT_DIR}
}


ClearInstallDir() {
  Banner "Clearing dirs in ${INSTALL_ROOT}"
  rm -rf ${INSTALL_ROOT}/*
}


CreateTarBall() {
  Banner "Creating tarball ${TARBALL}"
  tar zcf ${TARBALL} -C ${INSTALL_ROOT} .
}

ExtractPackageBz2() {
  bzcat "$1" | egrep '^(Package:|Filename:|SHA256:) ' > "$2"
}

GeneratePackageListAmd64() {
  local output_file="$1"
  local package_list="${BUILD_DIR}/Packages.${DIST}_amd64.bz2"
  local tmp_package_list="${BUILD_DIR}/Packages.${DIST}_amd64"
  DownloadOrCopy "${PACKAGE_LIST_AMD64}" "${package_list}"
  VerifyPackageListing "${PACKAGE_FILE_AMD64}" "${package_list}"
  ExtractPackageBz2 "$package_list" "$tmp_package_list"
  GeneratePackageList "$tmp_package_list" "$output_file" "${DEBIAN_PACKAGES}
    ${DEBIAN_PACKAGES_X86}"
}

GeneratePackageListI386() {
  local output_file="$1"
  local package_list="${BUILD_DIR}/Packages.${DIST}_i386.bz2"
  local tmp_package_list="${BUILD_DIR}/Packages.${DIST}_amd64"
  DownloadOrCopy "${PACKAGE_LIST_I386}" "${package_list}"
  VerifyPackageListing "${PACKAGE_FILE_I386}" "${package_list}"
  ExtractPackageBz2 "$package_list" "$tmp_package_list"
  GeneratePackageList "$tmp_package_list" "$output_file" "${DEBIAN_PACKAGES}
    ${DEBIAN_PACKAGES_X86}"
}

GeneratePackageListARM() {
  local output_file="$1"
  local package_list="${BUILD_DIR}/Packages.${DIST}_arm.bz2"
  local tmp_package_list="${BUILD_DIR}/Packages.${DIST}_arm"
  DownloadOrCopy "${PACKAGE_LIST_ARM}" "${package_list}"
  VerifyPackageListing "${PACKAGE_FILE_ARM}" "${package_list}"
  ExtractPackageBz2 "$package_list" "$tmp_package_list"
  GeneratePackageList "$tmp_package_list" "$output_file" "${DEBIAN_PACKAGES}"
}

GeneratePackageListMips() {
  local output_file="$1"
  local package_list="${BUILD_DIR}/Packages.${DIST}_mips.bz2"
  local tmp_package_list="${BUILD_DIR}/Packages.${DIST}_mips"
  DownloadOrCopy "${PACKAGE_LIST_MIPS}" "${package_list}"
  VerifyPackageListing "${PACKAGE_FILE_MIPS}" "${package_list}"
  ExtractPackageBz2 "$package_list" "$tmp_package_list"
  GeneratePackageList "$tmp_package_list" "$output_file" "${DEBIAN_PACKAGES}"
}

StripChecksumsFromPackageList() {
  local package_file="$1"
  sed -i 's/ [a-f0-9]\{64\}$//' "$package_file"
}

VerifyPackageFilesMatch() {
  local downloaded_package_file="$1"
  local stored_package_file="$2"
  diff -u "$downloaded_package_file" "$stored_package_file"
  if [ "$?" -ne "0" ]; then
    echo "ERROR: downloaded package files does not match $2."
    echo "You may need to run UpdatePackageLists."
    exit 1
  fi
}

######################################################################
#
######################################################################

HacksAndPatchesAmd64() {
  Banner "Misc Hacks & Patches"
  # these are linker scripts with absolute pathnames in them
  # which we rewrite here
  lscripts="${INSTALL_ROOT}/usr/lib/x86_64-linux-gnu/libpthread.so \
            ${INSTALL_ROOT}/usr/lib/x86_64-linux-gnu/libc.so"

  # Rewrite linker scripts
  sed -i -e 's|/usr/lib/x86_64-linux-gnu/||g'  ${lscripts}
  sed -i -e 's|/lib/x86_64-linux-gnu/||g' ${lscripts}

  # This is for chrome's ./build/linux/pkg-config-wrapper
  # which overwrites PKG_CONFIG_PATH internally
  SubBanner "Package Configs Symlink"
  mkdir -p ${INSTALL_ROOT}/usr/share
  ln -s ../lib/x86_64-linux-gnu/pkgconfig ${INSTALL_ROOT}/usr/share/pkgconfig

  SubBanner "Adding an additional ld.conf include"
  LD_SO_HACK_CONF="${INSTALL_ROOT}/etc/ld.so.conf.d/zz_hack.conf"
  echo /usr/lib/gcc/x86_64-linux-gnu/4.6 > "$LD_SO_HACK_CONF"
  echo /usr/lib >> "$LD_SO_HACK_CONF"
}


HacksAndPatchesI386() {
  Banner "Misc Hacks & Patches"
  # these are linker scripts with absolute pathnames in them
  # which we rewrite here
  lscripts="${INSTALL_ROOT}/usr/lib/i386-linux-gnu/libpthread.so \
            ${INSTALL_ROOT}/usr/lib/i386-linux-gnu/libc.so"

  # Rewrite linker scripts
  sed -i -e 's|/usr/lib/i386-linux-gnu/||g'  ${lscripts}
  sed -i -e 's|/lib/i386-linux-gnu/||g' ${lscripts}

  # This is for chrome's ./build/linux/pkg-config-wrapper
  # which overwrites PKG_CONFIG_PATH internally
  SubBanner "Package Configs Symlink"
  mkdir -p ${INSTALL_ROOT}/usr/share
  ln -s ../lib/i386-linux-gnu/pkgconfig ${INSTALL_ROOT}/usr/share/pkgconfig

  SubBanner "Adding an additional ld.conf include"
  LD_SO_HACK_CONF="${INSTALL_ROOT}/etc/ld.so.conf.d/zz_hack.conf"
  echo /usr/lib/gcc/i486-linux-gnu/4.6 > "$LD_SO_HACK_CONF"
  echo /usr/lib >> "$LD_SO_HACK_CONF"
}


HacksAndPatchesARM() {
  Banner "Misc Hacks & Patches"
  # these are linker scripts with absolute pathnames in them
  # which we rewrite here
  lscripts="${INSTALL_ROOT}/usr/lib/arm-linux-gnueabihf/libpthread.so \
            ${INSTALL_ROOT}/usr/lib/arm-linux-gnueabihf/libc.so"

  # Rewrite linker scripts
  sed -i -e 's|/usr/lib/arm-linux-gnueabihf/||g' ${lscripts}
  sed -i -e 's|/lib/arm-linux-gnueabihf/||g' ${lscripts}

  # This is for chrome's ./build/linux/pkg-config-wrapper
  # which overwrites PKG_CONFIG_PATH internally
  SubBanner "Package Configs Symlink"
  mkdir -p ${INSTALL_ROOT}/usr/share
  ln -s ../lib/arm-linux-gnueabihf/pkgconfig ${INSTALL_ROOT}/usr/share/pkgconfig
}


HacksAndPatchesMips() {
  Banner "Misc Hacks & Patches"
  # these are linker scripts with absolute pathnames in them
  # which we rewrite here
  lscripts="${INSTALL_ROOT}/usr/lib/mipsel-linux-gnu/libpthread.so \
            ${INSTALL_ROOT}/usr/lib/mipsel-linux-gnu/libc.so"

  # Rewrite linker scripts
  sed -i -e 's|/usr/lib/mipsel-linux-gnu/||g' ${lscripts}
  sed -i -e 's|/lib/mipsel-linux-gnu/||g' ${lscripts}

  # This is for chrome's ./build/linux/pkg-config-wrapper
  # which overwrites PKG_CONFIG_PATH internally
  SubBanner "Package Configs Symlink"
  mkdir -p ${INSTALL_ROOT}/usr/share
  ln -s ../lib/mipsel-linux-gnu/pkgconfig ${INSTALL_ROOT}/usr/share/pkgconfig
}


InstallIntoSysroot() {
  Banner "Install Libs And Headers Into Jail"

  mkdir -p ${BUILD_DIR}/debian-packages
  mkdir -p ${INSTALL_ROOT}
  while (( "$#" )); do
    local file="$1"
    local package="${BUILD_DIR}/debian-packages/${file##*/}"
    shift
    local sha256sum="$1"
    shift
    if [ "${#sha256sum}" -ne "64" ]; then
      echo "Bad sha256sum from package list"
      exit 1
    fi

    Banner "Installing ${file}"
    DownloadOrCopy ${APT_REPO}/pool/${file} ${package}
    if [ ! -s "${package}" ] ; then
      echo
      echo "ERROR: bad package ${package}"
      exit 1
    fi
    echo "${sha256sum}  ${package}" | sha256sum --quiet -c

    SubBanner "Extracting to ${INSTALL_ROOT}"
    dpkg --fsys-tarfile ${package}\
      | tar -xf - --exclude=./usr/share -C ${INSTALL_ROOT}
  done
}


CleanupJailSymlinks() {
  Banner "Jail symlink cleanup"

  SAVEDPWD=$(pwd)
  cd ${INSTALL_ROOT}
  local libdirs="lib usr/lib"
  if [ "${ARCH}" != "MIPS" ]; then
    libdirs+=" lib64"
  fi
  find $libdirs -type l -printf '%p %l\n' | while read link target; do
    # skip links with non-absolute paths
    echo "${target}" | grep -qs ^/ || continue
    echo "${link}: ${target}"
    case "${link}" in
      usr/lib/gcc/x86_64-linux-gnu/4.*/* | usr/lib/gcc/i486-linux-gnu/4.*/* | \
      usr/lib/gcc/arm-linux-gnueabihf/4.*/* | \
      usr/lib/gcc/mipsel-linux-gnu/4.*/*)
        # Relativize the symlink.
        ln -snfv "../../../../..${target}" "${link}"
        ;;
      usr/lib/x86_64-linux-gnu/* | usr/lib/i386-linux-gnu/* | \
      usr/lib/arm-linux-gnueabihf/* | usr/lib/mipsel-linux-gnu/* )
        # Relativize the symlink.
        ln -snfv "../../..${target}" "${link}"
        ;;
      usr/lib/*)
        # Relativize the symlink.
        ln -snfv "../..${target}" "${link}"
        ;;
      lib64/* | lib/*)
        # Relativize the symlink.
        ln -snfv "..${target}" "${link}"
        ;;
    esac
  done

  find $libdirs -type l -printf '%p %l\n' | while read link target; do
    # Make sure we catch new bad links.
    if [ ! -r "${link}" ]; then
      echo "ERROR: FOUND BAD LINK ${link}"
      ls -l ${link}
      exit 1
    fi
  done
  cd "$SAVEDPWD"
}

#@
#@ BuildSysrootAmd64
#@
#@    Build everything and package it
BuildSysrootAmd64() {
  ClearInstallDir
  local package_file="$BUILD_DIR/package_with_sha256sum_amd64"
  GeneratePackageListAmd64 "$package_file"
  local files_and_sha256sums="$(cat ${package_file})"
  StripChecksumsFromPackageList "$package_file"
  VerifyPackageFilesMatch "$package_file" "$DEBIAN_DEP_LIST_AMD64"
  InstallIntoSysroot ${files_and_sha256sums}
  CleanupJailSymlinks
  HacksAndPatchesAmd64
  CreateTarBall
}

#@
#@ BuildSysrootI386
#@
#@    Build everything and package it
BuildSysrootI386() {
  ClearInstallDir
  local package_file="$BUILD_DIR/package_with_sha256sum_i386"
  GeneratePackageListI386 "$package_file"
  local files_and_sha256sums="$(cat ${package_file})"
  StripChecksumsFromPackageList "$package_file"
  VerifyPackageFilesMatch "$package_file" "$DEBIAN_DEP_LIST_I386"
  InstallIntoSysroot ${files_and_sha256sums}
  CleanupJailSymlinks
  HacksAndPatchesI386
  CreateTarBall
}

#@
#@ BuildSysrootARM
#@
#@    Build everything and package it
BuildSysrootARM() {
  ClearInstallDir
  local package_file="$BUILD_DIR/package_with_sha256sum_arm"
  GeneratePackageListARM "$package_file"
  local files_and_sha256sums="$(cat ${package_file})"
  StripChecksumsFromPackageList "$package_file"
  VerifyPackageFilesMatch "$package_file" "$DEBIAN_DEP_LIST_ARM"
  APT_REPO=${APR_REPO_ARM:=$APT_REPO}
  InstallIntoSysroot ${files_and_sha256sums}
  CleanupJailSymlinks
  HacksAndPatchesARM
  CreateTarBall
}

#@
#@ BuildSysrootMips
#@
#@    Build everything and package it
BuildSysrootMips() {
  ClearInstallDir
  local package_file="$BUILD_DIR/package_with_sha256sum_arm"
  GeneratePackageListMips "$package_file"
  local files_and_sha256sums="$(cat ${package_file})"
  StripChecksumsFromPackageList "$package_file"
  VerifyPackageFilesMatch "$package_file" "$DEBIAN_DEP_LIST_MIPS"
  APT_REPO=${APR_REPO_MIPS:=$APT_REPO}
  InstallIntoSysroot ${files_and_sha256sums}
  CleanupJailSymlinks
  HacksAndPatchesMips
  CreateTarBall
}

#@
#@ BuildSysrootAll
#@
#@    Build sysroot images for all architectures
BuildSysrootAll() {
  RunCommand BuildSysrootAmd64
  RunCommand BuildSysrootI386
  RunCommand BuildSysrootARM
  RunCommand BuildSysrootMips
}

UploadSysroot() {
  local rev=$1
  if [ -z "${rev}" ]; then
    echo "Please specify a revision to upload at."
    exit 1
  fi
  set -x
  gsutil cp -a public-read "${TARBALL}" \
      "gs://chrome-linux-sysroot/toolchain/$rev/"
  set +x
}

#@
#@ UploadSysrootAmd64 <revision>
#@
UploadSysrootAmd64() {
  UploadSysroot "$@"
}

#@
#@ UploadSysrootI386 <revision>
#@
UploadSysrootI386() {
  UploadSysroot "$@"
}

#@
#@ UploadSysrootARM <revision>
#@
UploadSysrootARM() {
  UploadSysroot "$@"
}

#@
#@ UploadSysrootMips <revision>
#@
UploadSysrootMips() {
  UploadSysroot "$@"
}

#@
#@ UploadSysrootAll <revision>
#@
#@    Upload sysroot image for all architectures
UploadSysrootAll() {
  RunCommand UploadSysrootAmd64 "$@"
  RunCommand UploadSysrootI386 "$@"
  RunCommand UploadSysrootARM "$@"
  RunCommand UploadSysrootMips "$@"
}

#
# CheckForDebianGPGKeyring
#
#     Make sure the Debian GPG keys exist. Otherwise print a helpful message.
#
CheckForDebianGPGKeyring() {
  if [ ! -e "$KEYRING_FILE" ]; then
    echo "Debian GPG keys missing. Install the debian-archive-keyring package."
    exit 1
  fi
}

#
# VerifyPackageListing
#
#     Verifies the downloaded Packages.bz2 file has the right checksums.
#
VerifyPackageListing() {
  local file_path=$1
  local output_file=$2
  local release_file="${BUILD_DIR}/${RELEASE_FILE}"
  local release_file_gpg="${BUILD_DIR}/${RELEASE_FILE_GPG}"
  local tmp_keyring_file="${BUILD_DIR}/keyring.gpg"

  CheckForDebianGPGKeyring

  DownloadOrCopy ${RELEASE_LIST} ${release_file}
  DownloadOrCopy ${RELEASE_LIST_GPG} ${release_file_gpg}
  echo "Verifying: ${release_file} with ${release_file_gpg}"
  cp "${KEYRING_FILE}" "${tmp_keyring_file}"
  gpg --primary-keyring "${tmp_keyring_file}" --recv-keys 2B90D010
  gpgv --keyring "${tmp_keyring_file}" "${release_file_gpg}" "${release_file}"

  echo "Verifying: ${output_file}"
  local checksums=$(grep ${file_path} ${release_file} | cut -d " " -f 2)
  local sha256sum=$(echo ${checksums} | cut -d " " -f 3)

  if [ "${#sha256sum}" -ne "64" ]; then
    echo "Bad sha256sum from ${RELEASE_LIST}"
    exit 1
  fi

  echo "${sha256sum}  ${output_file}" | sha256sum --quiet -c
}

#
# GeneratePackageList
#
#     Looks up package names in ${BUILD_DIR}/Packages and write list of URLs
#     to output file.
#
GeneratePackageList() {
  local input_file="$1"
  local output_file="$2"
  echo "Updating: ${output_file} from ${input_file}"
  /bin/rm -f "${output_file}"
  shift
  shift
  for pkg in $@ ; do
    local pkg_full=$(grep -A 1 " ${pkg}\$" "$input_file" | \
      egrep -o "pool/.*")
    if [ -z "${pkg_full}" ]; then
        echo "ERROR: missing package: $pkg"
        exit 1
    fi
    local pkg_nopool=$(echo "$pkg_full" | sed "s/^pool\///")
    local sha256sum=$(grep -A 4 " ${pkg}\$" "$input_file" | \
      grep ^SHA256: | sed 's/^SHA256: //')
    if [ "${#sha256sum}" -ne "64" ]; then
      echo "Bad sha256sum from Packages"
      exit 1
    fi
    echo $pkg_nopool $sha256sum >> "$output_file"
  done
  # sort -o does an in-place sort of this file
  sort "$output_file" -o "$output_file"
}

#@
#@ UpdatePackageListsAmd64
#@
#@     Regenerate the package lists such that they contain an up-to-date
#@     list of URLs within the Debian archive. (For amd64)
UpdatePackageListsAmd64() {
  GeneratePackageListAmd64 "$DEBIAN_DEP_LIST_AMD64"
  StripChecksumsFromPackageList "$DEBIAN_DEP_LIST_AMD64"
}

#@
#@ UpdatePackageListsI386
#@
#@     Regenerate the package lists such that they contain an up-to-date
#@     list of URLs within the Debian archive. (For i386)
UpdatePackageListsI386() {
  GeneratePackageListI386 "$DEBIAN_DEP_LIST_I386"
  StripChecksumsFromPackageList "$DEBIAN_DEP_LIST_I386"
}

#@
#@ UpdatePackageListsARM
#@
#@     Regenerate the package lists such that they contain an up-to-date
#@     list of URLs within the Debian archive. (For arm)
UpdatePackageListsARM() {
  GeneratePackageListARM "$DEBIAN_DEP_LIST_ARM"
  StripChecksumsFromPackageList "$DEBIAN_DEP_LIST_ARM"
}

#@
#@ UpdatePackageListsMips
#@
#@     Regenerate the package lists such that they contain an up-to-date
#@     list of URLs within the Debian archive. (For arm)
UpdatePackageListsMips() {
  GeneratePackageListMips "$DEBIAN_DEP_LIST_MIPS"
  StripChecksumsFromPackageList "$DEBIAN_DEP_LIST_MIPS"
}

#@
#@ UpdatePackageListsAll
#@
#@    Regenerate the package lists for all architectures.
UpdatePackageListsAll() {
  RunCommand UpdatePackageListsAmd64
  RunCommand UpdatePackageListsI386
  RunCommand UpdatePackageListsARM
  RunCommand UpdatePackageListsMips
}

RunCommand() {
  SetEnvironmentVariables "$1"
  SanityCheck
  "$@"
}

if [ $# -eq 0 ] ; then
  echo "ERROR: you must specify a mode on the commandline"
  echo
  Usage
  exit 1
elif [ "$(type -t $1)" != "function" ]; then
  echo "ERROR: unknown function '$1'." >&2
  echo "For help, try:"
  echo "    $0 help"
  exit 1
else
  ChangeDirectory
  if echo $1 | grep -qs "All$"; then
    "$@"
  else
    RunCommand "$@"
  fi
fi
