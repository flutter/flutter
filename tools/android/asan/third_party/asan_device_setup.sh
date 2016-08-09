#!/bin/bash
#===- lib/asan/scripts/asan_device_setup -----------------------------------===#
#
#                     The LLVM Compiler Infrastructure
#
# This file is distributed under the University of Illinois Open Source
# License. See LICENSE.TXT for details.
#
# Prepare Android device to run ASan applications.
#
#===------------------------------------------------------------------------===#

set -e

HERE="$(cd "$(dirname "$0")" && pwd)"

revert=no
extra_options=
device=
lib=

function usage {
    echo "usage: $0 [--revert] [--device device-id] [--lib path] [--extra-options options]"
    echo "  --revert: Uninstall ASan from the device."
    echo "  --lib: Path to ASan runtime library."
    echo "  --extra-options: Extra ASAN_OPTIONS."
    echo "  --device: Install to the given device. Use 'adb devices' to find"
    echo "            device-id."
    echo
    exit 1
}

function get_device_arch { # OUTVAR
    local _outvar=$1
    local _ABI=$($ADB shell getprop ro.product.cpu.abi)
    local _ARCH=
    if [[ $_ABI == x86* ]]; then
        _ARCH=i686
    elif [[ $_ABI == armeabi* ]]; then
        _ARCH=arm
    else
        echo "Unrecognized device ABI: $_ABI"
        exit 1
    fi
    eval $_outvar=\$_ARCH
}

while [[ $# > 0 ]]; do
  case $1 in
    --revert)
      revert=yes
      ;;
    --extra-options)
      shift
      if [[ $# == 0 ]]; then
        echo "--extra-options requires an argument."
        exit 1
      fi
      extra_options="$1"
      ;;
    --lib)
      shift
      if [[ $# == 0 ]]; then
        echo "--lib requires an argument."
        exit 1
      fi
      lib="$1"
      ;;
    --device)
      shift
      if [[ $# == 0 ]]; then
        echo "--device requires an argument."
        exit 1
      fi
      device="$1"
      ;;
    *)
      usage
      ;;
  esac
  shift
done

ADB=${ADB:-adb}
if [[ x$device != x ]]; then
    ADB="$ADB -s $device"
fi

echo '>> Remounting /system rw'
$ADB root
$ADB wait-for-device
$ADB remount
$ADB wait-for-device

get_device_arch ARCH
echo "Target architecture: $ARCH"
ASAN_RT="libclang_rt.asan-$ARCH-android.so"

if [[ x$revert == xyes ]]; then
    echo '>> Uninstalling ASan'

    if ! $ADB shell readlink /system/bin/app_process | grep 'app_process' >&/dev/null; then
        echo '>> Pre-L device detected.'
        $ADB shell mv /system/bin/app_process.real /system/bin/app_process
        $ADB shell rm /system/bin/asanwrapper
        $ADB shell rm /system/lib/$ASAN_RT
    else
        $ADB shell rm /system/bin/app_process.wrap
        $ADB shell rm /system/bin/asanwrapper
        $ADB shell rm /system/lib/$ASAN_RT
        $ADB shell rm /system/bin/app_process
        $ADB shell ln -s /system/bin/app_process32 /system/bin/app_process
    fi

    echo '>> Restarting shell'
    $ADB shell stop
    $ADB shell start

    echo '>> Done'
    exit 0
fi

if [[ -d "$lib" ]]; then
    ASAN_RT_PATH="$lib"
elif [[ -f "$lib" && "$lib" == *"$ASAN_RT" ]]; then
    ASAN_RT_PATH=$(dirname "$lib")
elif [[ -f "$HERE/$ASAN_RT" ]]; then
    ASAN_RT_PATH="$HERE"
elif [[ $(basename "$HERE") == "bin" ]]; then
    # We could be in the toolchain's base directory.
    # Consider ../lib, ../lib/asan, ../lib/linux and ../lib/clang/$VERSION/lib/linux.
    P=$(ls "$HERE"/../lib/"$ASAN_RT" "$HERE"/../lib/asan/"$ASAN_RT" "$HERE"/../lib/linux/"$ASAN_RT" "$HERE"/../lib/clang/*/lib/linux/"$ASAN_RT" 2>/dev/null | sort | tail -1)
    if [[ -n "$P" ]]; then
        ASAN_RT_PATH="$(dirname "$P")"
    fi
fi

if [[ -z "$ASAN_RT_PATH" || ! -f "$ASAN_RT_PATH/$ASAN_RT" ]]; then
    echo ">> ASan runtime library not found"
    exit 1
fi

TMPDIRBASE=$(mktemp -d)
TMPDIROLD="$TMPDIRBASE/old"
TMPDIR="$TMPDIRBASE/new"
mkdir "$TMPDIROLD"

RELEASE=$($ADB shell getprop ro.build.version.release)
PRE_L=0
if echo "$RELEASE" | grep '^4\.' >&/dev/null; then
    PRE_L=1
fi

if ! $ADB shell readlink /system/bin/app_process | grep 'app_process' >&/dev/null; then

    if $ADB pull /system/bin/app_process.real /dev/null >&/dev/null; then
        echo '>> Old-style ASan installation detected. Reverting.'
        $ADB shell mv /system/bin/app_process.real /system/bin/app_process
    fi

    echo '>> Pre-L device detected. Setting up app_process symlink.'
    $ADB shell mv /system/bin/app_process /system/bin/app_process32
    $ADB shell ln -s /system/bin/app_process32 /system/bin/app_process
fi

echo '>> Copying files from the device'
$ADB pull /system/bin/app_process.wrap "$TMPDIROLD" || true
$ADB pull /system/bin/asanwrapper "$TMPDIROLD" || true
$ADB pull /system/lib/"$ASAN_RT" "$TMPDIROLD" || true
cp -r "$TMPDIROLD" "$TMPDIR"

if [[ -f "$TMPDIR/app_process.wrap" ]]; then
    echo ">> Previous installation detected"
else
    echo ">> New installation"
fi

echo '>> Generating wrappers'

cp "$ASAN_RT_PATH/$ASAN_RT" "$TMPDIR/"

# FIXME: alloc_dealloc_mismatch=0 prevents a failure in libdvm startup,
# which may or may not be a real bug (probably not).
ASAN_OPTIONS=start_deactivated=1,alloc_dealloc_mismatch=0

# On Android-L not allowing user segv handler breaks some applications.
if [[ PRE_L -eq 0 ]]; then
    ASAN_OPTIONS="$ASAN_OPTIONS,allow_user_segv_handler=1"
fi

if [[ x$extra_options != x ]] ; then
    ASAN_OPTIONS="$ASAN_OPTIONS,$extra_options"
fi

# Zygote wrapper.
cat <<EOF >"$TMPDIR/app_process.wrap"
#!/system/bin/sh-from-zygote
ASAN_OPTIONS=$ASAN_OPTIONS \\
LD_PRELOAD=\$LD_PRELOAD:$ASAN_RT \\
exec /system/bin/app_process32 \$@

EOF

# General command-line tool wrapper (use for anything that's not started as
# zygote).
cat <<EOF >"$TMPDIR/asanwrapper"
#!/system/bin/sh
LD_PRELOAD=$ASAN_RT \\
exec \$@

EOF

if ! ( cd "$TMPDIRBASE" && diff -qr old/ new/ ) ; then
    echo '>> Pushing files to the device'
    $ADB push "$TMPDIR/$ASAN_RT" /system/lib/
    $ADB push "$TMPDIR/app_process.wrap" /system/bin/app_process.wrap
    $ADB push "$TMPDIR/asanwrapper" /system/bin/asanwrapper

    $ADB shell rm /system/bin/app_process
    $ADB shell ln -s /system/bin/app_process.wrap /system/bin/app_process

    $ADB shell chown root.shell \
        /system/lib/"$ASAN_RT" \
        /system/bin/app_process.wrap \
        /system/bin/asanwrapper
    $ADB shell chmod 644 \
        /system/lib/"$ASAN_RT"
    $ADB shell chmod 755 \
        /system/bin/app_process.wrap \
        /system/bin/asanwrapper

    # Make SELinux happy by keeping app_process wrapper and the shell
    # it runs on in zygote domain.
    ENFORCING=0
    if $ADB shell getenforce | grep Enforcing >/dev/null; then
        # Sometimes shell is not allowed to change file contexts.
        # Temporarily switch to permissive.
        ENFORCING=1
        $ADB shell setenforce 0
    fi

    $ADB shell cp /system/bin/sh /system/bin/sh-from-zygote

    if [[ PRE_L -eq 1 ]]; then
        CTX=u:object_r:system_file:s0
    else
        CTX=u:object_r:zygote_exec:s0
    fi
    $ADB shell chcon $CTX \
        /system/bin/sh-from-zygote \
        /system/bin/app_process.wrap \
        /system/bin/app_process32

    if [ $ENFORCING == 1 ]; then
        $ADB shell setenforce 1
    fi

    echo '>> Restarting shell (asynchronous)'
    $ADB shell stop
    $ADB shell start

    echo '>> Please wait until the device restarts'
else
    echo '>> Device is up to date'
fi

rm -r "$TMPDIRBASE"
