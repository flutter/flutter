#!/bin/bash -e

# Copyright (c) 2012 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# This script installs Debian-derived distributions in a chroot environment.
# It can for example be used to have an accurate 32bit build and test
# environment when otherwise working on a 64bit machine.
# N. B. it is unlikely that this script will ever work on anything other than a
# Debian-derived system.

# Older Debian based systems had both "admin" and "adm" groups, with "admin"
# apparently being used in more places. Newer distributions have standardized
# on just the "adm" group. Check /etc/group for the preferred name of the
# administrator group.
admin=$(grep '^admin:' /etc/group >&/dev/null && echo admin || echo adm)

usage() {
  echo "usage: ${0##*/} [-m mirror] [-g group,...] [-s] [-c]"
  echo "-b dir       additional directories that should be bind mounted,"
  echo '             or "NONE".'
  echo "             Default: if local filesystems present, ask user for help"
  echo "-g group,... groups that can use the chroot unauthenticated"
  echo "             Default: '${admin}' and current user's group ('$(id -gn)')"
  echo "-l           List all installed chroot environments"
  echo "-m mirror    an alternate repository mirror for package downloads"
  echo "-s           configure default deb-srcs"
  echo "-c           always copy 64bit helper binaries to 32bit chroot"
  echo "-h           this help message"
}

process_opts() {
  local OPTNAME OPTIND OPTERR OPTARG
  while getopts ":b:g:lm:sch" OPTNAME; do
    case "$OPTNAME" in
      b)
        if [ "${OPTARG}" = "NONE" -a -z "${bind_mounts}" ]; then
          bind_mounts="${OPTARG}"
        else
          if [ "${bind_mounts}" = "NONE" -o "${OPTARG}" = "${OPTARG#/}" -o \
               ! -d "${OPTARG}" ]; then
            echo "Invalid -b option(s)"
            usage
            exit 1
          fi
          bind_mounts="${bind_mounts}
${OPTARG} ${OPTARG} none rw,bind 0 0"
        fi
        ;;
      g)
        [ -n "${OPTARG}" ] &&
          chroot_groups="${chroot_groups}${chroot_groups:+,}${OPTARG}"
        ;;
      l)
        list_all_chroots
        exit
        ;;
      m)
        if [ -n "${mirror}" ]; then
          echo "You can only specify exactly one mirror location"
          usage
          exit 1
        fi
        mirror="$OPTARG"
        ;;
      s)
        add_srcs="y"
        ;;
      c)
        copy_64="y"
        ;;
      h)
        usage
        exit 0
        ;;
      \:)
        echo "'-$OPTARG' needs an argument."
        usage
        exit 1
        ;;
      *)
        echo "invalid command-line option: $OPTARG"
        usage
        exit 1
        ;;
    esac
  done

  if [ $# -ge ${OPTIND} ]; then
    eval echo "Unexpected command line argument: \${${OPTIND}}"
    usage
    exit 1
  fi
}

list_all_chroots() {
  for i in /var/lib/chroot/*; do
    i="${i##*/}"
    [ "${i}" = "*" ] && continue
    [ -x "/usr/local/bin/${i%bit}" ] || continue
    grep -qs "^\[${i%bit}\]\$" /etc/schroot/schroot.conf || continue
    [ -r "/etc/schroot/script-${i}" -a \
      -r "/etc/schroot/mount-${i}" ] || continue
    echo "${i%bit}"
  done
}

getkey() {
  (
    trap 'stty echo -iuclc icanon 2>/dev/null' EXIT INT TERM QUIT HUP
    stty -echo iuclc -icanon 2>/dev/null
    dd count=1 bs=1 2>/dev/null
  )
}

chr() {
  printf "\\$(printf '%03o' "$1")"
}

ord() {
  printf '%d' $(printf '%c' "$1" | od -tu1 -An)
}

is_network_drive() {
  stat -c %T -f "$1/" 2>/dev/null |
    egrep -qs '^nfs|cifs|smbfs'
}

# Check that we are running as a regular user
[ "$(id -nu)" = root ] && {
  echo "Run this script as a regular user and provide your \"sudo\""           \
       "password if requested" >&2
  exit 1
}

process_opts "$@"

echo "This script will help you through the process of installing a"
echo "Debian or Ubuntu distribution in a chroot environment. You will"
echo "have to provide your \"sudo\" password when requested."
echo

# Error handler
trap 'exit 1' INT TERM QUIT HUP
trap 'sudo apt-get clean; tput bel; echo; echo Failed' EXIT

# Install any missing applications that this script relies on. If these packages
# are already installed, don't force another "apt-get install". That would
# prevent them from being auto-removed, if they ever become eligible for that.
# And as this script only needs the packages once, there is no good reason to
# introduce a hard dependency on things such as dchroot and debootstrap.
dep=
for i in dchroot debootstrap libwww-perl; do
  [ -d /usr/share/doc/"$i" ] || dep="$dep $i"
done
[ -n "$dep" ] && sudo apt-get -y install $dep
sudo apt-get -y install schroot

# Create directory for chroot
sudo mkdir -p /var/lib/chroot

# Find chroot environments that can be installed with debootstrap
targets="$(cd /usr/share/debootstrap/scripts
           ls | grep '^[a-z]*$')"

# Ask user to pick one of the available targets
echo "The following targets are available to be installed in a chroot:"
j=1; for i in $targets; do
  printf '%4d: %s\n' "$j" "$i"
  j=$(($j+1))
done
while :; do
  printf "Which target would you like to install: "
  read n
  [ "$n" -gt 0 -a "$n" -lt "$j" ] >&/dev/null && break
done
j=1; for i in $targets; do
  [ "$j" -eq "$n" ] && { distname="$i"; break; }
  j=$(($j+1))
done
echo

# On x86-64, ask whether the user wants to install x86-32 or x86-64
archflag=
arch=
if [ "$(uname -m)" = x86_64 ]; then
  while :; do
    echo "You are running a 64bit kernel. This allows you to install either a"
    printf "32bit or a 64bit chroot environment. %s"                           \
           "Which one do you want (32, 64) "
    read arch
    [ "${arch}" == 32 -o "${arch}" == 64 ] && break
  done
  [ "${arch}" == 32 ] && archflag="--arch i386" || archflag="--arch amd64"
  arch="${arch}bit"
  echo
fi
target="${distname}${arch}"

# Don't accidentally overwrite an existing installation
[ -d /var/lib/chroot/"${target}" ] && {
  while :; do
    echo "This chroot already exists on your machine."
    if schroot -l --all-sessions 2>&1 |
       sed 's/^session://' |
       grep -qs "^${target%bit}-"; then
      echo "And it appears to be in active use. Terminate all programs that"
      echo "are currently using the chroot environment and then re-run this"
      echo "script."
      echo "If you still get an error message, you might have stale mounts"
      echo "that you forgot to delete. You can always clean up mounts by"
      echo "executing \"${target%bit} -c\"."
      exit 1
    fi
    echo "I can abort installation, I can overwrite the existing chroot,"
    echo "or I can delete the old one and then exit. What would you like to"
    printf "do (a/o/d)? "
    read choice
    case "${choice}" in
      a|A) exit 1;;
      o|O) sudo rm -rf "/var/lib/chroot/${target}"; break;;
      d|D) sudo rm -rf "/var/lib/chroot/${target}"      \
                       "/usr/local/bin/${target%bit}"   \
                       "/etc/schroot/mount-${target}"   \
                       "/etc/schroot/script-${target}"  \
                       "/etc/schroot/${target}"
           sudo sed -ni '/^[[]'"${target%bit}"']$/,${
                         :1;n;/^[[]/b2;b1;:2;p;n;b2};p' \
                       "/etc/schroot/schroot.conf"
           trap '' INT TERM QUIT HUP
           trap '' EXIT
           echo "Deleted!"
           exit 0;;
    esac
  done
  echo
}
sudo mkdir -p /var/lib/chroot/"${target}"

# Offer to include additional standard repositories for Ubuntu-based chroots.
alt_repos=
grep -qs ubuntu.com /usr/share/debootstrap/scripts/"${distname}" && {
  while :; do
    echo "Would you like to add ${distname}-updates and ${distname}-security "
    printf "to the chroot's sources.list (y/n)? "
    read alt_repos
    case "${alt_repos}" in
      y|Y)
        alt_repos="y"
        break
      ;;
      n|N)
        break
      ;;
    esac
  done
  echo
}

# Check for non-standard file system mount points and ask the user whether
# they should be imported into the chroot environment
# We limit to the first 26 mount points that much some basic heuristics,
# because a) that allows us to enumerate choices with a single character,
# and b) if we find more than 26 mount points, then these are probably
# false-positives and something is very unusual about the system's
# configuration. No need to spam the user with even more information that
# is likely completely irrelevant.
if [ -z "${bind_mounts}" ]; then
  mounts="$(awk '$2 != "/" && $2 !~ "^/boot" && $2 !~ "^/home" &&
                 $2 !~ "^/media" && $2 !~ "^/run" &&
                 ($3 ~ "ext[2-4]" || $3 == "reiserfs" || $3 == "btrfs" ||
                 $3 == "xfs" || $3 == "jfs" || $3 == "u?msdos" ||
                 $3 == "v?fat" || $3 == "hfs" || $3 == "ntfs" ||
                 $3 ~ "nfs[4-9]?" || $3 == "smbfs" || $3 == "cifs") {
                   print $2
                 }' /proc/mounts |
            head -n26)"
  if [ -n "${mounts}" ]; then
    echo "You appear to have non-standard mount points that you"
    echo "might want to import into the chroot environment:"
    echo
    sel=
    while :; do
      # Print a menu, listing all non-default mounts of local or network
      # file systems.
      j=1; for m in ${mounts}; do
        c="$(printf $(printf '\\%03o' $((64+$j))))"
        echo "$sel" | grep -qs $c &&
          state="mounted in chroot" || state="$(tput el)"
        printf "   $c) %-40s${state}\n" "$m"
        j=$(($j+1))
      done
      # Allow user to interactively (de-)select any of the entries
      echo
      printf "Select mount points that you want to be included or press %s" \
             "SPACE to continue"
      c="$(getkey | tr a-z A-Z)"
      [ "$c" == " " ] && { echo; echo; break; }
      if [ -z "$c" ] ||
         [ "$c" '<' 'A' -o $(ord "$c") -gt $((64 + $(ord "$j"))) ]; then
          # Invalid input, ring the console bell
          tput bel
      else
        # Toggle the selection for the given entry
        if echo "$sel" | grep -qs $c; then
          sel="$(printf "$sel" | sed "s/$c//")"
        else
          sel="$sel$c"
        fi
      fi
      # Reposition cursor to the top of the list of entries
      tput cuu $(($j + 1))
      echo
    done
  fi
  j=1; for m in ${mounts}; do
    c="$(chr $(($j + 64)))"
    if echo "$sel" | grep -qs $c; then
      bind_mounts="${bind_mounts}$m $m none rw,bind 0 0
"
    fi
    j=$(($j+1))
  done
fi

# Remove stale entry from /etc/schroot/schroot.conf. Entries start
# with the target name in square brackets, followed by an arbitrary
# number of lines. The entry stops when either the end of file has
# been reached, or when the beginning of a new target is encountered.
# This means, we cannot easily match for a range of lines in
# "sed". Instead, we actually have to iterate over each line and check
# whether it is the beginning of a new entry.
sudo sed -ni '/^[[]'"${target%bit}"']$/,${:1;n;/^[[]/b2;b1;:2;p;n;b2};p'       \
         /etc/schroot/schroot.conf

# Download base system. This takes some time
if [ -z "${mirror}" ]; then
 grep -qs ubuntu.com /usr/share/debootstrap/scripts/"${distname}" &&
   mirror="http://archive.ubuntu.com/ubuntu" ||
   mirror="http://ftp.us.debian.org/debian"
fi

sudo ${http_proxy:+http_proxy="${http_proxy}"} debootstrap ${archflag} \
    "${distname}" "/var/lib/chroot/${target}"  "$mirror"

# Add new entry to /etc/schroot/schroot.conf
grep -qs ubuntu.com /usr/share/debootstrap/scripts/"${distname}" &&
  brand="Ubuntu" || brand="Debian"
if [ -z "${chroot_groups}" ]; then
  chroot_groups="${admin},$(id -gn)"
fi

if [ -d '/etc/schroot/default' ]; then
  new_version=1
  fstab="/etc/schroot/${target}/fstab"
else
  new_version=0
  fstab="/etc/schroot/mount-${target}"
fi

if [ "$new_version" = "1" ]; then
  sudo cp -ar /etc/schroot/default /etc/schroot/${target}

  sudo sh -c 'cat >>/etc/schroot/schroot.conf' <<EOF
[${target%bit}]
description=${brand} ${distname} ${arch}
type=directory
directory=/var/lib/chroot/${target}
users=root
groups=${chroot_groups}
root-groups=${chroot_groups}
personality=linux$([ "${arch}" != 64bit ] && echo 32)
profile=${target}

EOF
  [ -n "${bind_mounts}" -a "${bind_mounts}" != "NONE" ] &&
    printf "${bind_mounts}" |
      sudo sh -c "cat >>${fstab}"
else
  # Older versions of schroot wanted a "priority=" line, whereas recent
  # versions deprecate "priority=" and warn if they see it. We don't have
  # a good feature test, but scanning for the string "priority=" in the
  # existing "schroot.conf" file is a good indication of what to do.
  priority=$(grep -qs 'priority=' /etc/schroot/schroot.conf &&
           echo 'priority=3' || :)
  sudo sh -c 'cat >>/etc/schroot/schroot.conf' <<EOF
[${target%bit}]
description=${brand} ${distname} ${arch}
type=directory
directory=/var/lib/chroot/${target}
users=root
groups=${chroot_groups}
root-groups=${chroot_groups}
personality=linux$([ "${arch}" != 64bit ] && echo 32)
script-config=script-${target}
${priority}

EOF

  # Set up a list of mount points that is specific to this
  # chroot environment.
  sed '/^FSTAB=/s,"[^"]*","'"${fstab}"'",' \
           /etc/schroot/script-defaults |
    sudo sh -c 'cat >/etc/schroot/script-'"${target}"
  sed '\,^/home[/[:space:]],s/\([,[:space:]]\)bind[[:space:]]/\1rbind /' \
    /etc/schroot/mount-defaults |
    sudo sh -c "cat > ${fstab}"
fi

# Add the extra mount points that the user told us about
[ -n "${bind_mounts}" -a "${bind_mounts}" != "NONE" ] &&
  printf "${bind_mounts}" |
    sudo sh -c 'cat >>'"${fstab}"

# If this system has a "/media" mountpoint, import it into the chroot
# environment. Most modern distributions use this mount point to
# automatically mount devices such as CDROMs, USB sticks, etc...
if [ -d /media ] &&
   ! grep -qs '^/media' "${fstab}"; then
  echo '/media /media none rw,rbind 0 0' |
    sudo sh -c 'cat >>'"${fstab}"
fi

# Share /dev/shm, /run and /run/shm.
grep -qs '^/dev/shm' "${fstab}" ||
  echo '/dev/shm /dev/shm none rw,bind 0 0' |
    sudo sh -c 'cat >>'"${fstab}"
if [ ! -d "/var/lib/chroot/${target}/run" ] &&
   ! grep -qs '^/run' "${fstab}"; then
  echo '/run /run none rw,bind 0 0' |
    sudo sh -c 'cat >>'"${fstab}"
fi
if ! grep -qs '^/run/shm' "${fstab}"; then
  { [ -d /run ] && echo '/run/shm /run/shm none rw,bind 0 0' ||
                   echo '/dev/shm /run/shm none rw,bind 0 0'; } |
    sudo sh -c 'cat >>'"${fstab}"
fi

# Set up a special directory that changes contents depending on the target
# that is executing.
d="$(readlink -f "${HOME}/chroot" 2>/dev/null || echo "${HOME}/chroot")"
s="${d}/.${target}"
echo "${s} ${d} none rw,bind 0 0" |
  sudo sh -c 'cat >>'"${target}"
mkdir -p "${s}"

# Install a helper script to launch commands in the chroot
sudo sh -c 'cat >/usr/local/bin/'"${target%bit}" <<'EOF'
#!/bin/bash

chroot="${0##*/}"

wrap() {
  # Word-wrap the text passed-in on stdin. Optionally, on continuation lines
  # insert the same number of spaces as the number of characters in the
  # parameter(s) passed to this function.
  # If the "fold" program cannot be found, or if the actual width of the
  # terminal cannot be determined, this function doesn't attempt to do any
  # wrapping.
  local f="$(type -P fold)"
  [ -z "${f}" ] && { cat; return; }
  local c="$(stty -a </dev/tty 2>/dev/null |
             sed 's/.*columns[[:space:]]*\([0-9]*\).*/\1/;t;d')"
  [ -z "${c}" ] && { cat; return; }
  local i="$(echo "$*"|sed 's/./ /g')"
  local j="$(printf %s "${i}"|wc -c)"
  if [ "${c}" -gt "${j}" ]; then
    dd bs=1 count="${j}" 2>/dev/null
    "${f}" -sw "$((${c}-${j}))" | sed '2,$s/^/'"${i}"'/'
  else
    "${f}" -sw "${c}"
  fi
}

help() {
  echo "Usage ${0##*/} [-h|--help] [-c|--clean] [-C|--clean-all] [-l|--list] [--] args" | wrap "Usage ${0##*/} "
  echo "  help:      print this message"                                                | wrap "             "
  echo "  list:      list all known chroot environments"                                | wrap "             "
  echo "  clean:     remove all old chroot sessions for \"${chroot}\""                  | wrap "             "
  echo "  clean-all: remove all old chroot sessions for all environments"               | wrap "             "
  exit 0
}

clean() {
  local s t rc
  rc=0
  for s in $(schroot -l --all-sessions); do
    if [ -n "$1" ]; then
      t="${s#session:}"
      [ "${t#${chroot}-}" == "${t}" ] && continue
    fi
    if ls -l /proc/*/{cwd,fd} 2>/dev/null |
       fgrep -qs "/var/lib/schroot/mount/${t}"; then
      echo "Session \"${t}\" still has active users, not cleaning up" | wrap
      rc=1
      continue
    fi
    sudo schroot -c "${s}" -e || rc=1
  done
  exit ${rc}
}

list() {
  for e in $(schroot -l); do
    e="${e#chroot:}"
    [ -x "/usr/local/bin/${e}" ] || continue
    if schroot -l --all-sessions 2>/dev/null |
       sed 's/^session://' |
       grep -qs "^${e}-"; then
      echo "${e} is currently active"
    else
      echo "${e}"
    fi
  done
  exit 0
}

while [ "$#" -ne 0 ]; do
  case "$1" in
    --)             shift; break;;
    -h|--help)      shift; help;;
    -l|--list)      shift; list;;
    -c|--clean)     shift; clean "${chroot}";;
    -C|--clean-all) shift; clean;;
    *)              break;;
  esac
done

# Start a new chroot session and keep track of the session id. We inject this
# id into all processes that run inside the chroot. Unless they go out of their
# way to clear their environment, we can then later identify our child and
# grand-child processes by scanning their environment.
session="$(schroot -c "${chroot}" -b)"
export CHROOT_SESSION_ID="${session}"

# Set GOMA_TMP_DIR for better handling of goma inside chroot.
export GOMA_TMP_DIR="/tmp/goma_tmp_$CHROOT_SESSION_ID"
mkdir -p "$GOMA_TMP_DIR"

if [ $# -eq 0 ]; then
  # Run an interactive shell session
  schroot -c "${session}" -r -p
else
  # Run a command inside of the chroot environment
  p="$1"; shift
  schroot -c "${session}" -r -p "$p" -- "$@"
fi
rc=$?

# Compute the inode of the root directory inside of the chroot environment.
i=$(schroot -c "${session}" -r -p ls -- -id /proc/self/root/. |
     awk '{ print $1 }') 2>/dev/null
other_pids=
while [ -n "$i" ]; do
  # Identify processes by the inode number of their root directory. Then
  # remove all processes that we know belong to other sessions. We use
  # "sort | uniq -u" to do what amounts to a "set substraction operation".
  pids=$({ ls -id1 /proc/*/root/. 2>/dev/null |
         sed -e 's,^[^0-9]*'$i'.*/\([1-9][0-9]*\)/.*$,\1,
                 t
                 d';
         echo "${other_pids}";
         echo "${other_pids}"; } | sort | uniq -u) >/dev/null 2>&1
  # Kill all processes that are still left running in the session. This is
  # typically an assortment of daemon processes that were started
  # automatically. They result in us being unable to tear down the session
  # cleanly.
  [ -z "${pids}" ] && break
  for j in $pids; do
    # Unfortunately, the way that schroot sets up sessions has the
    # side-effect of being unable to tell one session apart from another.
    # This can result in us attempting to kill processes in other sessions.
    # We make a best-effort to avoid doing so.
    k="$( ( xargs -0 -n1 </proc/$j/environ ) 2>/dev/null |
         sed 's/^CHROOT_SESSION_ID=/x/;t1;d;:1;q')"
    if [ -n "${k}" -a "${k#x}" != "${session}" ]; then
      other_pids="${other_pids}
${j}"
      continue
    fi
    kill -9 $pids
  done
done
# End the chroot session. This should clean up all temporary files. But if we
# earlier failed to terminate all (daemon) processes inside of the session,
# deleting the session could fail. When that happens, the user has to manually
# clean up the stale files by invoking us with "--clean" after having killed
# all running processes.
schroot -c "${session}" -e
# Since no goma processes are running, we can remove goma directory.
rm -rf "$GOMA_TMP_DIR"
exit $rc
EOF
sudo chown root:root /usr/local/bin/"${target%bit}"
sudo chmod 755 /usr/local/bin/"${target%bit}"

# Add the standard Ubuntu update repositories if requested.
[ "${alt_repos}" = "y" -a \
  -r "/var/lib/chroot/${target}/etc/apt/sources.list" ] &&
sudo sed -i '/^deb .* [^ -]\+ main$/p
             s/^\(deb .* [^ -]\+\) main/\1-security main/
             p
             t1
             d
             :1;s/-security main/-updates main/
             t
             d' "/var/lib/chroot/${target}/etc/apt/sources.list"

# Add a few more repositories to the chroot
[ -r "/var/lib/chroot/${target}/etc/apt/sources.list" ] &&
sudo sed -i 's/ main$/ main restricted universe multiverse/' \
         "/var/lib/chroot/${target}/etc/apt/sources.list"

# Add the Ubuntu "partner" repository, if available
if [ -r "/var/lib/chroot/${target}/etc/apt/sources.list" ] &&
   HEAD "http://archive.canonical.com/ubuntu/dists/${distname}/partner" \
   >&/dev/null; then
  sudo sh -c '
    echo "deb http://archive.canonical.com/ubuntu" \
         "'"${distname}"' partner" \
      >>"/var/lib/chroot/'"${target}"'/etc/apt/sources.list"'
fi

# Add source repositories, if the user requested we do so
[ "${add_srcs}" = "y" -a \
  -r "/var/lib/chroot/${target}/etc/apt/sources.list" ] &&
sudo sed -i '/^deb[^-]/p
             s/^deb\([^-]\)/deb-src\1/' \
         "/var/lib/chroot/${target}/etc/apt/sources.list"

# Set apt proxy if host has set http_proxy
if [ -n "${http_proxy}" ]; then
  sudo sh -c '
    echo "Acquire::http::proxy \"'"${http_proxy}"'\";" \
        >>"/var/lib/chroot/'"${target}"'/etc/apt/apt.conf"'
fi

# Update packages
sudo "/usr/local/bin/${target%bit}" /bin/sh -c '
  apt-get update; apt-get -y dist-upgrade' || :

# Install a couple of missing packages
for i in debian-keyring ubuntu-keyring locales sudo; do
  [ -d "/var/lib/chroot/${target}/usr/share/doc/$i" ] ||
    sudo "/usr/local/bin/${target%bit}" apt-get -y install "$i" || :
done

# Configure locales
sudo "/usr/local/bin/${target%bit}" /bin/sh -c '
  l='"${LANG:-en_US}"'; l="${l%%.*}"
  [ -r /etc/locale.gen ] &&
    sed -i "s/^# \($l\)/\1/" /etc/locale.gen
  locale-gen $LANG en_US en_US.UTF-8' || :

# Enable multi-arch support, if available
sudo "/usr/local/bin/${target%bit}" dpkg --assert-multi-arch >&/dev/null &&
  [ -r "/var/lib/chroot/${target}/etc/apt/sources.list" ] && {
  sudo sed -i 's/ / [arch=amd64,i386] /' \
              "/var/lib/chroot/${target}/etc/apt/sources.list"
  [ -d /var/lib/chroot/${target}/etc/dpkg/dpkg.cfg.d/ ] &&
  sudo "/usr/local/bin/${target%bit}" dpkg --add-architecture \
      $([ "${arch}" = "32bit" ] && echo amd64 || echo i386) >&/dev/null ||
    echo foreign-architecture \
        $([ "${arch}" = "32bit" ] && echo amd64 || echo i386) |
      sudo sh -c \
        "cat >'/var/lib/chroot/${target}/etc/dpkg/dpkg.cfg.d/multiarch'"
}

# Configure "sudo" package
sudo "/usr/local/bin/${target%bit}" /bin/sh -c '
  egrep -qs '"'^$(id -nu) '"' /etc/sudoers ||
  echo '"'$(id -nu) ALL=(ALL) ALL'"' >>/etc/sudoers'

# Install a few more commonly used packages
sudo "/usr/local/bin/${target%bit}" apt-get -y install                         \
  autoconf automake1.9 dpkg-dev g++-multilib gcc-multilib gdb less libtool     \
  lsof strace

# If running a 32bit environment on a 64bit machine, install a few binaries
# as 64bit. This is only done automatically if the chroot distro is the same as
# the host, otherwise there might be incompatibilities in build settings or
# runtime dependencies. The user can force it with the '-c' flag.
host_distro=$(grep -s DISTRIB_CODENAME /etc/lsb-release | \
  cut -d "=" -f 2)
if [ "${copy_64}" = "y" -o \
    "${host_distro}" = "${distname}" -a "${arch}" = 32bit ] && \
    file /bin/bash 2>/dev/null | grep -q x86-64; then
  readlinepkg=$(sudo "/usr/local/bin/${target%bit}" sh -c \
    'apt-cache search "lib64readline.\$" | sort | tail -n 1 | cut -d " " -f 1')
  sudo "/usr/local/bin/${target%bit}" apt-get -y install                       \
    lib64expat1 lib64ncurses5 ${readlinepkg} lib64z1 lib64stdc++6
  dep=
  for i in binutils gdb; do
    [ -d /usr/share/doc/"$i" ] || dep="$dep $i"
  done
  [ -n "$dep" ] && sudo apt-get -y install $dep
  sudo mkdir -p "/var/lib/chroot/${target}/usr/local/lib/amd64"
  for i in libbfd libpython; do
    lib="$({ ldd /usr/bin/ld; ldd /usr/bin/gdb; } |
           grep -s "$i" | awk '{ print $3 }')"
    if [ -n "$lib" -a -r "$lib" ]; then
      sudo cp "$lib" "/var/lib/chroot/${target}/usr/local/lib/amd64"
    fi
  done
  for lib in libssl libcrypt; do
    for path in /usr/lib /usr/lib/x86_64-linux-gnu; do
      sudo cp $path/$lib* \
              "/var/lib/chroot/${target}/usr/local/lib/amd64/" >&/dev/null || :
    done
  done
  for i in gdb ld; do
    sudo cp /usr/bin/$i "/var/lib/chroot/${target}/usr/local/lib/amd64/"
    sudo sh -c "cat >'/var/lib/chroot/${target}/usr/local/bin/$i'" <<EOF
#!/bin/sh
exec /lib64/ld-linux-x86-64.so.2 --library-path /usr/local/lib/amd64 \
  /usr/local/lib/amd64/$i "\$@"
EOF
    sudo chmod 755 "/var/lib/chroot/${target}/usr/local/bin/$i"
  done
fi


# If the install-build-deps.sh script can be found, offer to run it now
script="$(dirname $(readlink -f "$0"))/install-build-deps.sh"
if [ -x "${script}" ]; then
  while :; do
    echo
    echo "If you plan on building Chrome inside of the new chroot environment,"
    echo "you now have to install the build dependencies. Do you want me to"
    printf "start the script that does this for you (y/n)? "
    read install_deps
    case "${install_deps}" in
      y|Y)
        echo
        # We prefer running the script in-place, but this might not be
        # possible, if it lives on a network filesystem that denies
        # access to root.
        tmp_script=
        if ! sudo /usr/local/bin/"${target%bit}" \
            sh -c "[ -x '${script}' ]" >&/dev/null; then
          tmp_script="/tmp/${script##*/}"
          cp "${script}" "${tmp_script}"
        fi
        # Some distributions automatically start an instance of the system-
        # wide dbus daemon, cron daemon or of the logging daemon, when
        # installing the Chrome build depencies. This prevents the chroot
        # session from being closed.  So, we always try to shut down any running
        # instance of dbus and rsyslog.
        sudo /usr/local/bin/"${target%bit}" sh -c "${script};
              rc=$?;
              /etc/init.d/cron stop >/dev/null 2>&1 || :;
              /etc/init.d/rsyslog stop >/dev/null 2>&1 || :;
              /etc/init.d/dbus stop >/dev/null 2>&1 || :;
              exit $rc"
        rc=$?
        [ -n "${tmp_script}" ] && rm -f "${tmp_script}"
        [ $rc -ne 0 ] && exit $rc
        break
      ;;
      n|N)
        break
      ;;
    esac
  done
  echo
fi

# Check whether ~/chroot is on a (slow) network file system and offer to
# relocate it. Also offer relocation, if the user appears to have multiple
# spindles (as indicated by "${bind_mount}" being non-empty).
# We only offer this option, if it doesn't look as if a chroot environment
# is currently active. Otherwise, relocation is unlikely to work and it
# can be difficult for the user to recover from the failed attempt to relocate
# the ~/chroot directory.
# We don't aim to solve this problem for every configuration,
# but try to help with the common cases. For more advanced configuration
# options, the user can always manually adjust things.
mkdir -p "${HOME}/chroot/"
if [ ! -h "${HOME}/chroot" ] &&
   ! egrep -qs '^[^[:space:]]*/chroot' /etc/fstab &&
   { [ -n "${bind_mounts}" -a "${bind_mounts}" != "NONE" ] ||
     is_network_drive "${HOME}/chroot"; } &&
   ! egrep -qs '/var/lib/[^/]*chroot/.*/chroot' /proc/mounts; then
  echo "${HOME}/chroot is currently located on the same device as your"
  echo "home directory."
  echo "This might not be what you want. Do you want me to move it somewhere"
  echo "else?"
  # If the computer has multiple spindles, many users configure all or part of
  # the secondary hard disk to be writable by the primary user of this machine.
  # Make some reasonable effort to detect this type of configuration and
  # then offer a good location for where to put the ~/chroot directory.
  suggest=
  for i in $(echo "${bind_mounts}"|cut -d ' ' -f 1); do
    if [ -d "$i" -a -w "$i" -a \( ! -a "$i/chroot" -o -w "$i/chroot/." \) ] &&
       ! is_network_drive "$i"; then
      suggest="$i"
    else
      for j in "$i/"*; do
        if [ -d "$j" -a -w "$j" -a \
             \( ! -a "$j/chroot" -o -w "$j/chroot/." \) ] &&
           ! is_network_drive "$j"; then
          suggest="$j"
        else
          for k in "$j/"*; do
            if [ -d "$k" -a -w "$k" -a \
                 \( ! -a "$k/chroot" -o -w "$k/chroot/." \) ] &&
               ! is_network_drive "$k"; then
              suggest="$k"
              break
            fi
          done
        fi
        [ -n "${suggest}" ] && break
      done
    fi
    [ -n "${suggest}" ] && break
  done
  def_suggest="${HOME}"
  if [ -n "${suggest}" ]; then
    # For home directories that reside on network drives, make our suggestion
    # the default option. For home directories that reside on a local drive,
    # require that the user manually enters the new location.
    if is_network_drive "${HOME}"; then
      def_suggest="${suggest}"
    else
      echo "A good location would probably be in \"${suggest}\""
    fi
  fi
  while :; do
    printf "Physical location [${def_suggest}]: "
    read dir
    [ -z "${dir}" ] && dir="${def_suggest}"
    [ "${dir%%/}" == "${HOME%%/}" ] && break
    if ! [ -d "${dir}" -a -w "${dir}" ] ||
       [ -a "${dir}/chroot" -a ! -w "${dir}/chroot/." ]; then
      echo "Cannot write to ${dir}/chroot. Please try again"
    else
      mv "${HOME}/chroot" "${dir}/chroot"
      ln -s "${dir}/chroot" "${HOME}/chroot"
      for i in $(list_all_chroots); do
        sudo "$i" mkdir -p "${dir}/chroot"
      done
      sudo sed -i "s,${HOME}/chroot,${dir}/chroot,g" /etc/schroot/mount-*
      break
    fi
  done
fi

# Clean up package files
sudo schroot -c "${target%bit}" -p -- apt-get clean
sudo apt-get clean

trap '' INT TERM QUIT HUP
trap '' EXIT

# Let the user know what we did
cat <<EOF


Successfully installed ${distname} ${arch}

You can run programs inside of the chroot by invoking the
"/usr/local/bin/${target%bit}" command.

This command can be used with arguments, in order to just run a single
program inside of the chroot environment (e.g. "${target%bit} make chrome")
or without arguments, in order to run an interactive shell session inside
of the chroot environment.

If you need to run things as "root", you can use "sudo" (e.g. try
"sudo ${target%bit} apt-get update").

Your home directory is shared between the host and the chroot. But I
configured "${HOME}/chroot" to be private to the chroot environment.
You can use it for files that need to differ between environments. This
would be a good place to store binaries that you have built from your
source files.

For Chrome, this probably means you want to make your "out" directory a
symbolic link that points somewhere inside of "${HOME}/chroot".

You still need to run "gclient runhooks" whenever you switch from building
outside of the chroot to inside of the chroot. But you will find that you
don't have to repeatedly erase and then completely rebuild all your object
and binary files.

EOF
