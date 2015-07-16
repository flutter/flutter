#!/bin/bash -e

# Copyright (c) 2012 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Script to install everything needed to build chromium (well, ideally, anyway)
# See http://code.google.com/p/chromium/wiki/LinuxBuildInstructions
# and http://code.google.com/p/chromium/wiki/LinuxBuild64Bit

usage() {
  echo "Usage: $0 [--options]"
  echo "Options:"
  echo "--[no-]syms: enable or disable installation of debugging symbols"
  echo "--lib32: enable installation of 32-bit libraries, e.g. for V8 snapshot"
  echo "--[no-]arm: enable or disable installation of arm cross toolchain"
  echo "--[no-]chromeos-fonts: enable or disable installation of Chrome OS"\
       "fonts"
  echo "--[no-]nacl: enable or disable installation of prerequisites for"\
       "building standalone NaCl and all its toolchains"
  echo "--no-prompt: silently select standard options/defaults"
  echo "--quick-check: quickly try to determine if dependencies are installed"
  echo "               (this avoids interactive prompts and sudo commands,"
  echo "               so might not be 100% accurate)"
  echo "--unsupported: attempt installation even on unsupported systems"
  echo "Script will prompt interactively if options not given."
  exit 1
}

# Checks whether a particular package is available in the repos.
# USAGE: $ package_exists <package name>
package_exists() {
  apt-cache pkgnames | grep -x "$1" > /dev/null 2>&1
}

# These default to on because (some) bots need them and it keeps things
# simple for the bot setup if all bots just run the script in its default
# mode.  Developers who don't want stuff they don't need installed on their
# own workstations can pass --no-arm --no-nacl when running the script.
do_inst_arm=1
do_inst_nacl=1

while test "$1" != ""
do
  case "$1" in
  --syms)                   do_inst_syms=1;;
  --no-syms)                do_inst_syms=0;;
  --lib32)                  do_inst_lib32=1;;
  --arm)                    do_inst_arm=1;;
  --no-arm)                 do_inst_arm=0;;
  --chromeos-fonts)         do_inst_chromeos_fonts=1;;
  --no-chromeos-fonts)      do_inst_chromeos_fonts=0;;
  --nacl)                   do_inst_nacl=1;;
  --no-nacl)                do_inst_nacl=0;;
  --no-prompt)              do_default=1
                            do_quietly="-qq --assume-yes"
    ;;
  --quick-check)            do_quick_check=1;;
  --unsupported)            do_unsupported=1;;
  *) usage;;
  esac
  shift
done

if test "$do_inst_arm" = "1"; then
  do_inst_lib32=1
fi

# Check for lsb_release command in $PATH
if ! which lsb_release > /dev/null; then
  echo "ERROR: lsb_release not found in \$PATH" >&2
  exit 1;
fi

lsb_release=$(lsb_release --codename --short)
ubuntu_codenames="(precise|trusty|utopic|vivid)"
if [ 0 -eq "${do_unsupported-0}" ] && [ 0 -eq "${do_quick_check-0}" ] ; then
  if [[ ! $lsb_release =~ $ubuntu_codenames ]]; then
    echo "ERROR: Only Ubuntu 12.04 (precise), 14.04 (trusty), " \
      "14.10 (utopic) and 15.04 (vivid) are currently supported" >&2
    exit 1
  fi

  if ! uname -m | egrep -q "i686|x86_64"; then
    echo "Only x86 architectures are currently supported" >&2
    exit
  fi
fi

if [ "x$(id -u)" != x0 ] && [ 0 -eq "${do_quick_check-0}" ]; then
  echo "Running as non-root user."
  echo "You might have to enter your password one or more times for 'sudo'."
  echo
fi

# Packages needed for chromeos only
chromeos_dev_list="libbluetooth-dev libxkbcommon-dev realpath"

# Packages needed for development
dev_list="apache2.2-bin bison cdbs curl dpkg-dev elfutils devscripts fakeroot
          flex fonts-thai-tlwg g++ git-core git-svn gperf language-pack-da
          language-pack-fr language-pack-he language-pack-zh-hant
          libapache2-mod-php5 libasound2-dev libbrlapi-dev libav-tools
          libbz2-dev libcairo2-dev libcap-dev libcups2-dev libcurl4-gnutls-dev
          libdrm-dev libelf-dev libexif-dev libgconf2-dev libglib2.0-dev
          libglu1-mesa-dev libgnome-keyring-dev libgtk2.0-dev libkrb5-dev
          libnspr4-dev libnss3-dev libpam0g-dev libpci-dev libpulse-dev
          libsctp-dev libspeechd-dev libsqlite3-dev libssl-dev libudev-dev
          libwww-perl libxslt1-dev libxss-dev libxt-dev libxtst-dev openbox
          patch perl php5-cgi pkg-config python python-cherrypy3 python-crypto
          python-dev python-numpy python-opencv python-openssl python-psutil
          python-yaml rpm ruby subversion ttf-dejavu-core ttf-indic-fonts
          ttf-kochi-gothic ttf-kochi-mincho wdiff xfonts-mathml zip
          $chromeos_dev_list"

# 64-bit systems need a minimum set of 32-bit compat packages for the pre-built
# NaCl binaries.
if file /sbin/init | grep -q 'ELF 64-bit'; then
  dev_list="${dev_list} libc6-i386 lib32gcc1 lib32stdc++6"
fi

# Run-time libraries required by chromeos only
chromeos_lib_list="libpulse0 libbz2-1.0"

# Full list of required run-time libraries
lib_list="libatk1.0-0 libc6 libasound2 libcairo2 libcap2 libcups2 libexpat1
          libexif12 libfontconfig1 libfreetype6 libglib2.0-0 libgnome-keyring0
          libgtk2.0-0 libpam0g libpango1.0-0 libpci3 libpcre3 libpixman-1-0
          libpng12-0 libspeechd2 libstdc++6 libsqlite3-0 libx11-6
          libxau6 libxcb1 libxcomposite1 libxcursor1 libxdamage1 libxdmcp6
          libxext6 libxfixes3 libxi6 libxinerama1 libxrandr2 libxrender1
          libxtst6 zlib1g $chromeos_lib_list"

# Debugging symbols for all of the run-time libraries
dbg_list="libatk1.0-dbg libc6-dbg libcairo2-dbg libfontconfig1-dbg
          libglib2.0-0-dbg libgtk2.0-0-dbg libpango1.0-0-dbg libpcre3-dbg
          libpixman-1-0-dbg libsqlite3-0-dbg libx11-6-dbg libxau6-dbg
          libxcb1-dbg libxcomposite1-dbg libxcursor1-dbg libxdamage1-dbg
          libxdmcp6-dbg libxext6-dbg libxfixes3-dbg libxi6-dbg libxinerama1-dbg
          libxrandr2-dbg libxrender1-dbg libxtst6-dbg zlib1g-dbg"

# Find the proper version of libstdc++6-4.x-dbg.
if [ "x$lsb_release" = "xprecise" ]; then
  dbg_list="${dbg_list} libstdc++6-4.6-dbg"
elif [ "x$lsb_release" = "xtrusty" ]; then
  dbg_list="${dbg_list} libstdc++6-4.8-dbg"
else
  dbg_list="${dbg_list} libstdc++6-4.9-dbg"
fi

# 32-bit libraries needed e.g. to compile V8 snapshot for Android or armhf
lib32_list="linux-libc-dev:i386"

# arm cross toolchain packages needed to build chrome on armhf
arm_list="libc6-dev-armhf-cross
          linux-libc-dev-armhf-cross
          g++-arm-linux-gnueabihf"

# Work around for dependency issue Ubuntu/Trusty: http://crbug.com/435056
if [ "x$lsb_release" = "xtrusty" ]; then
  arm_list+=" g++-4.8-multilib-arm-linux-gnueabihf
              gcc-4.8-multilib-arm-linux-gnueabihf"
fi

# Packages to build NaCl, its toolchains, and its ports.
naclports_list="ant autoconf bison cmake gawk intltool xutils-dev xsltproc"
nacl_list="g++-mingw-w64-i686 lib32z1-dev
           libasound2:i386 libcap2:i386 libelf-dev:i386 libexif12:i386
           libfontconfig1:i386 libgconf-2-4:i386 libglib2.0-0:i386 libgpm2:i386
           libgtk2.0-0:i386 libncurses5:i386 lib32ncurses5-dev
           libnss3:i386 libpango1.0-0:i386
           libssl1.0.0:i386 libtinfo-dev libtinfo-dev:i386 libtool
           libxcomposite1:i386 libxcursor1:i386 libxdamage1:i386 libxi6:i386
           libxrandr2:i386 libxss1:i386 libxtst6:i386 texinfo xvfb
           ${naclports_list}"

# Find the proper version of libgbm-dev. We can't just install libgbm-dev as
# it depends on mesa, and only one version of mesa can exists on the system.
# Hence we must match the same version or this entire script will fail.
mesa_variant=""
for variant in "-lts-trusty" "-lts-utopic"; do
  if $(dpkg-query -Wf'${Status}' libgl1-mesa-glx${variant} 2>/dev/null | \
       grep -q " ok installed"); then
    mesa_variant="${variant}"
  fi
done
dev_list="${dev_list} libgbm-dev${mesa_variant}
          libgles2-mesa-dev${mesa_variant} libgl1-mesa-dev${mesa_variant}
          mesa-common-dev${mesa_variant}"
nacl_list="${nacl_list} libgl1-mesa-glx${mesa_variant}:i386"

# Some package names have changed over time
if package_exists ttf-mscorefonts-installer; then
  dev_list="${dev_list} ttf-mscorefonts-installer"
else
  dev_list="${dev_list} msttcorefonts"
fi
if package_exists libnspr4-dbg; then
  dbg_list="${dbg_list} libnspr4-dbg libnss3-dbg"
  lib_list="${lib_list} libnspr4 libnss3"
else
  dbg_list="${dbg_list} libnspr4-0d-dbg libnss3-1d-dbg"
  lib_list="${lib_list} libnspr4-0d libnss3-1d"
fi
if package_exists libjpeg-dev; then
  dev_list="${dev_list} libjpeg-dev"
else
  dev_list="${dev_list} libjpeg62-dev"
fi
if package_exists libudev1; then
  dev_list="${dev_list} libudev1"
  nacl_list="${nacl_list} libudev1:i386"
else
  dev_list="${dev_list} libudev0"
  nacl_list="${nacl_list} libudev0:i386"
fi
if package_exists libbrlapi0.6; then
  dev_list="${dev_list} libbrlapi0.6"
else
  dev_list="${dev_list} libbrlapi0.5"
fi


# Some packages are only needed if the distribution actually supports
# installing them.
if package_exists appmenu-gtk; then
  lib_list="$lib_list appmenu-gtk"
fi

# When cross building for arm/Android on 64-bit systems the host binaries
# that are part of v8 need to be compiled with -m32 which means
# that basic multilib support is needed.
if file /sbin/init | grep -q 'ELF 64-bit'; then
  # gcc-multilib conflicts with the arm cross compiler (at least in trusty) but
  # g++-X.Y-multilib gives us the 32-bit support that we need. Find out the
  # appropriate value of X and Y by seeing what version the current
  # distribution's g++-multilib package depends on.
  multilib_package=$(apt-cache depends g++-multilib --important | \
      grep -E --color=never --only-matching '\bg\+\+-[0-9.]+-multilib\b')
  lib32_list="$lib32_list $multilib_package"
fi

# Waits for the user to press 'Y' or 'N'. Either uppercase of lowercase is
# accepted. Returns 0 for 'Y' and 1 for 'N'. If an optional parameter has
# been provided to yes_no(), the function also accepts RETURN as a user input.
# The parameter specifies the exit code that should be returned in that case.
# The function will echo the user's selection followed by a newline character.
# Users can abort the function by pressing CTRL-C. This will call "exit 1".
yes_no() {
  if [ 0 -ne "${do_default-0}" ] ; then
    [ $1 -eq 0 ] && echo "Y" || echo "N"
    return $1
  fi
  local c
  while :; do
    c="$(trap 'stty echo -iuclc icanon 2>/dev/null' EXIT INT TERM QUIT
         stty -echo iuclc -icanon 2>/dev/null
         dd count=1 bs=1 2>/dev/null | od -An -tx1)"
    case "$c" in
      " 0a") if [ -n "$1" ]; then
               [ $1 -eq 0 ] && echo "Y" || echo "N"
               return $1
             fi
             ;;
      " 79") echo "Y"
             return 0
             ;;
      " 6e") echo "N"
             return 1
             ;;
      "")    echo "Aborted" >&2
             exit 1
             ;;
      *)     # The user pressed an unrecognized key. As we are not echoing
             # any incorrect user input, alert the user by ringing the bell.
             (tput bel) 2>/dev/null
             ;;
    esac
  done
}

if test "$do_inst_syms" = "" && test 0 -eq ${do_quick_check-0}
then
  echo "This script installs all tools and libraries needed to build Chromium."
  echo ""
  echo "For most of the libraries, it can also install debugging symbols, which"
  echo "will allow you to debug code in the system libraries. Most developers"
  echo "won't need these symbols."
  echo -n "Do you want me to install them for you (y/N) "
  if yes_no 1; then
    do_inst_syms=1
  fi
fi
if test "$do_inst_syms" = "1"; then
  echo "Including debugging symbols."
else
  echo "Skipping debugging symbols."
  dbg_list=
fi

if test "$do_inst_lib32" = "1" ; then
  echo "Including 32-bit libraries for ARM/Android."
else
  echo "Skipping 32-bit libraries for ARM/Android."
  lib32_list=
fi

if test "$do_inst_arm" = "1" ; then
  echo "Including ARM cross toolchain."
else
  echo "Skipping ARM cross toolchain."
  arm_list=
fi

if test "$do_inst_nacl" = "1"; then
  echo "Including NaCl, NaCl toolchain, NaCl ports dependencies."
else
  echo "Skipping NaCl, NaCl toolchain, NaCl ports dependencies."
  nacl_list=
fi

# The `sort -r -s -t: -k2` sorts all the :i386 packages to the front, to avoid
# confusing dpkg-query (crbug.com/446172).
packages="$(
  echo "${dev_list} ${lib_list} ${dbg_list} ${lib32_list} ${arm_list}"\
       "${nacl_list}" | tr " " "\n" | sort -u | sort -r -s -t: -k2 | tr "\n" " "
)"

if [ 1 -eq "${do_quick_check-0}" ] ; then
  failed_check="$(dpkg-query -W -f '${PackageSpec}:${Status}\n' \
    ${packages} 2>&1 | grep -v "ok installed" || :)"
  if [ -n "${failed_check}" ]; then
    echo
    nomatch="$(echo "${failed_check}" | \
      sed -e "s/^No packages found matching \(.*\).$/\1/;t;d")"
    missing="$(echo "${failed_check}" | \
      sed -e "/^No packages found matching/d;s/^\(.*\):.*$/\1/")"
    if [ "$nomatch" ]; then
      # Distinguish between packages that actually aren't available to the
      # system (i.e. not in any repo) and packages that just aren't known to
      # dpkg (i.e. managed by apt).
      unknown=""
      for p in ${nomatch}; do
        if apt-cache show ${p} > /dev/null 2>&1; then
          missing="${p}\n${missing}"
        else
          unknown="${p}\n${unknown}"
        fi
      done
      if [ -n "${unknown}" ]; then
        echo "WARNING: The following packages are unknown to your system"
        echo "(maybe missing a repo or need to 'sudo apt-get update'):"
        echo -e "${unknown}" | sed -e "s/^/  /"
      fi
    fi
    if [ -n "${missing}" ]; then
      echo "WARNING: The following packages are not installed:"
      echo -e "${missing}" | sed -e "s/^/  /"
    fi
    exit 1
  fi
  exit 0
fi

if test "$do_inst_lib32" = "1" || test "$do_inst_nacl" = "1"; then
  if [[ ! $lsb_release =~ (precise) ]]; then
    sudo dpkg --add-architecture i386
  fi
fi
sudo apt-get update

# We initially run "apt-get" with the --reinstall option and parse its output.
# This way, we can find all the packages that need to be newly installed
# without accidentally promoting any packages from "auto" to "manual".
# We then re-run "apt-get" with just the list of missing packages.
echo "Finding missing packages..."
# Intentionally leaving $packages unquoted so it's more readable.
echo "Packages required: " $packages
echo
new_list_cmd="sudo apt-get install --reinstall $(echo $packages)"
if new_list="$(yes n | LANGUAGE=en LANG=C $new_list_cmd)"; then
  # We probably never hit this following line.
  echo "No missing packages, and the packages are up-to-date."
elif [ $? -eq 1 ]; then
  # We expect apt-get to have exit status of 1.
  # This indicates that we cancelled the install with "yes n|".
  new_list=$(echo "$new_list" |
    sed -e '1,/The following NEW packages will be installed:/d;s/^  //;t;d')
  new_list=$(echo "$new_list" | sed 's/ *$//')
  if [ -z "$new_list" ] ; then
    echo "No missing packages, and the packages are up-to-date."
  else
    echo "Installing missing packages: $new_list."
    sudo apt-get install ${do_quietly-} ${new_list}
  fi
  echo
else
  # An apt-get exit status of 100 indicates that a real error has occurred.

  # I am intentionally leaving out the '"'s around new_list_cmd,
  # as this makes it easier to cut and paste the output
  echo "The following command failed: " ${new_list_cmd}
  echo
  echo "It produces the following output:"
  yes n | $new_list_cmd || true
  echo
  echo "You will have to install the above packages yourself."
  echo
  exit 100
fi

# Install the Chrome OS default fonts. This must go after running
# apt-get, since install-chromeos-fonts depends on curl.
if test "$do_inst_chromeos_fonts" != "0"; then
  echo
  echo "Installing Chrome OS fonts."
  dir=`echo $0 | sed -r -e 's/\/[^/]+$//'`
  if ! sudo $dir/linux/install-chromeos-fonts.py; then
    echo "ERROR: The installation of the Chrome OS default fonts failed."
    if [ `stat -f -c %T $dir` == "nfs" ]; then
      echo "The reason is that your repo is installed on a remote file system."
    else
      echo "This is expected if your repo is installed on a remote file system."
    fi
    echo "It is recommended to install your repo on a local file system."
    echo "You can skip the installation of the Chrome OS default founts with"
    echo "the command line option: --no-chromeos-fonts."
    exit 1
  fi
else
  echo "Skipping installation of Chrome OS fonts."
fi

# $1 - target name
# $2 - link name
create_library_symlink() {
  target=$1
  linkname=$2
  if [ -L $linkname ]; then
    if [ "$(basename $(readlink $linkname))" != "$(basename $target)" ]; then
      sudo rm $linkname
    fi
  fi
  if [ ! -r $linkname ]; then
    echo "Creating link: $linkname"
    sudo ln -fs $target $linkname
  fi
}

if test "$do_inst_nacl" = "1"; then
  echo "Installing symbolic links for NaCl."
  # naclports needs to cross build python for i386, but libssl1.0.0:i386
  # only contains libcrypto.so.1.0.0 and not the symlink needed for
  # linking (libcrypto.so).
  create_library_symlink /lib/i386-linux-gnu/libcrypto.so.1.0.0 \
      /usr/lib/i386-linux-gnu/libcrypto.so

  create_library_symlink /lib/i386-linux-gnu/libssl.so.1.0.0 \
      /usr/lib/i386-linux-gnu/libssl.so
else
  echo "Skipping symbolic links for NaCl."
fi
