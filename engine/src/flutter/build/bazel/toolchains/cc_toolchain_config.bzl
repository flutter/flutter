# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""C/C++ toolchain configuration for the engine's hermetic clang toolchains.

The flags reproduce what the GN build passes for the same configuration (see
//build/config/compiler/BUILD.gn, //build/config/BUILDCONFIG.gn and the
`cxx`/`link` rules in an out directory's toolchain.ninja). Only flags GN
applies to *every* target live here; flags that GN attaches to first-party
code only (`chromium_code`, `//flutter:config`) are in copts.bzl, and
per-target flags belong in BUILD files.

Compilation modes map onto GN's as follows:

  -c dbg        --unoptimized builds (`is_debug = true`): -O0 -g2 -D_DEBUG
  -c opt        optimized builds (`is_debug = false`): -O2 -g2 -DNDEBUG
  -c fastbuild  like dbg with minimal debug info (no GN equivalent)

Tool and directory paths are derived from labels at analysis time, so the
configuration never hardcodes a repository's canonical name.
"""

load(
    "@rules_cc//cc:action_names.bzl",
    "ACTION_NAMES",
    "ALL_CC_COMPILE_ACTION_NAMES",
    "ALL_CC_LINK_ACTION_NAMES",
    "ALL_CPP_COMPILE_ACTION_NAMES",
    "CC_LINK_EXECUTABLE_ACTION_NAMES",
    "DYNAMIC_LIBRARY_LINK_ACTION_NAMES",
)
load(
    "@rules_cc//cc:cc_toolchain_config_lib.bzl",
    "action_config",
    "env_entry",
    "env_set",
    "feature",
    "feature_set",
    "flag_group",
    "flag_set",
    "tool",
)
load("@rules_cc//cc/common:cc_common.bzl", "cc_common")
load("//build_defs/cc:apple.bzl", "MACOS_DEPLOYMENT_TARGET")
load("//build_defs/cc:copts.bzl", "ANDROID_TOOLCHAIN_WARNING_FLAGS", "MACOS_TOOLCHAIN_WARNING_FLAGS", "TOOLCHAIN_WARNING_FLAGS")

# Flags GN passes to every C and C++ compile on Linux
# (//build/config/compiler:compiler, :runtime_library, //build/config/gcc,
# //build/config/clang:extra_warnings, the `default_warning_flags`).
# `__FILE__` as GN's build prints it. GN compiles from out/<config>/ and a
# source's path is `../../flutter/shell/...`, which fml's logging strips to
# `flutter/shell/...` (`[INFO:flutter/shell/...]`); Bazel compiles from the
# execution root, the repository's root, where the same source is
# `engine/src/flutter/shell/...`. The macro prefix map takes the two
# directories off, so that a log line, a check failure and anything else
# that prints `__FILE__` reads the same under both -- the devicelab's
# android_intent_parsing_test looks for `[INFO:flutter` in logcat (the
# first presubmit run of the Bazel-built Android engine, PR #195825).
# Debug info keeps the execution-root paths (GN's
# -fdebug-prefix-map=<checkout>/engine/src/= strips an absolute prefix that
# Bazel's never have).
FILE_PREFIX_FLAGS = ["-fmacro-prefix-map=engine/src/="]

_COMMON_COMPILE_FLAGS = [
    # Keep paths as spelled on the command line: clang is invoked through a
    # symlink and must report its builtin headers under that path, not under
    # the checkout's absolute path (//build/config/gcc:relative_paths).
    "-no-canonical-prefixes",
    "-fno-strict-aliasing",
    "-fstack-protector",
    "--param=ssp-buffer-size=8",
    "-pipe",
] + FILE_PREFIX_FLAGS

def _warning_compile_flags(default_warning_flags):
    return [
        "-fcolor-diagnostics",
        "-fvisibility=hidden",
        # GN's `default_warning_flags` (part of both the chromium_code and the
        # no_chromium_code config, so every target gets them), without -Werror;
        # see copts.bzl for why, and for the per-target lists that repeat them
        # after -Wall -Wextra.
    ] + default_warning_flags + [
        # //build/config/clang:extra_warnings.
        "-Wstring-conversion",
        "-Wnewline-eof",
    ]

_WARNING_COMPILE_FLAGS = _warning_compile_flags(TOOLCHAIN_WARNING_FLAGS)

# Android's: without -Wno-deprecated-literal-operator, which GN adds for
# clang on every platform but Android (copts.bzl).
_ANDROID_WARNING_COMPILE_FLAGS = _warning_compile_flags(ANDROID_TOOLCHAIN_WARNING_FLAGS)

# macOS's: with -Wunguarded-availability, and -Wno-deprecated-declarations
# as tools/gn sets allow_deprecated_api_calls on a Mac (copts.bzl).
_MAC_WARNING_COMPILE_FLAGS = _warning_compile_flags(MACOS_TOOLCHAIN_WARNING_FLAGS)

_LINUX_COMPILE_FLAGS = _COMMON_COMPILE_FLAGS + ["-pthread"] + _WARNING_COMPILE_FLAGS

# Android (//build/config/compiler:compiler under is_android): no -pthread
# (bionic has no separate libpthread), and the three flags GN adds for the
# NDK's ABI: function sections, unwind tables, full-width enums.
_ANDROID_COMPILE_FLAGS = _COMMON_COMPILE_FLAGS + [
    "-ffunction-sections",
    "-funwind-tables",
    "-fno-short-enums",
] + _ANDROID_WARNING_COMPILE_FLAGS

# macOS (//build/config/compiler:compiler under is_mac): the stack
# protector on every function rather than on the ones with buffers, and
# neither -pipe nor -pthread, which GN passes on Linux alone. Not here:
# GN's -fdebug-prefix-map=<checkout>/engine/src/=, which strips the
# checkout's absolute path from debug info; Bazel compiles with paths
# relative to the execution root already, as on Linux.
_MAC_COMPILE_FLAGS = [
    "-no-canonical-prefixes",
    "-fno-strict-aliasing",
    "-fstack-protector-all",
] + FILE_PREFIX_FLAGS + _MAC_WARNING_COMPILE_FLAGS

# iOS's (//build/config/compiler:compiler under is_ios): the Mac's without
# the stack protector, which GN gives neither iOS nor the web.
_IOS_COMPILE_FLAGS = [
    "-no-canonical-prefixes",
    "-fno-strict-aliasing",
] + FILE_PREFIX_FLAGS + _MAC_WARNING_COMPILE_FLAGS

# The architecture (//build/config/compiler:compiler), per target CPU:
# x64's `-m64 -march=x86-64`, arm64's `--target=aarch64-linux-gnu` with the
# define GN's compiler config adds beside it (the toolchain's `arch_copts`
# and `arch_linkopts`; the x64 ones are the defaults). Separate, and placed
# after a target's own flags (see `flutter_arch_flags` below): in GN the
# compiler config's cflags follow the target's, so a target's own -march
# loses to -march=x86-64 -- Skia's `ml3` opts ask for -march=haswell and
# are built for x86-64, and the engine's test goldens are of that raster
# pipeline; a build in which haswell won differs from them by a few pixels.
# (-m<feature> flags such as skcms' -mavx2 are unaffected by the order:
# clang applies them on top of whichever -march wins.)
LINUX_X64_COMPILE_FLAGS = [
    "-m64",
    "-march=x86-64",
]
LINUX_ARM64_COMPILE_FLAGS = [
    "--target=aarch64-linux-gnu",
    "-DBORINGSSL_CLANG_SUPPORTS_DOT_ARCH",
]

# macOS (//build/config/compiler:compiler under is_mac, the
# `common_mac_flags` of its compiles and links): the target triple and
# -arch, per CPU.
MACOS_ARM64_COMPILE_FLAGS = [
    "--target=arm64-apple-macos",
    "-arch",
    "arm64",
]
MACOS_X64_COMPILE_FLAGS = [
    "--target=x86_64-apple-macos",
    "-arch",
    "x86_64",
]
MACOS_ARM64_LINK_FLAGS = MACOS_ARM64_COMPILE_FLAGS
MACOS_X64_LINK_FLAGS = MACOS_X64_COMPILE_FLAGS

# iOS (the same config under is_ios): the darwin triple, for a device and
# the simulator alike -- the environment is the sysroot's and the
# deployment-target flag's (build/toolchain/mac's ios_clang_arm, _arm_sim
# and _x64_sim: -miphoneos-version-min or -mios-simulator-version-min).
IOS_ARM64_COMPILE_FLAGS = [
    "--target=arm64-apple-darwin",
    "-arch",
    "arm64",
]
IOS_X64_COMPILE_FLAGS = [
    "--target=x86_64-apple-darwin",
    "-arch",
    "x86_64",
]
IOS_ARM64_LINK_FLAGS = IOS_ARM64_COMPILE_FLAGS
IOS_X64_LINK_FLAGS = IOS_X64_COMPILE_FLAGS

# Defines GN passes to every compile on Linux (//build/config:feature_flags,
# //build/config/compiler:compiler, //build/config/gcc:symbol_visibility_hidden,
# //build/config/clang:extra_warnings, the libc++ configs).
_LINUX_DEFINES = [
    "USE_OPENSSL=1",
    "_FILE_OFFSET_BITS=64",
    "_LARGEFILE_SOURCE",
    "_LARGEFILE64_SOURCE",
    "_LIBCPP_DISABLE_AVAILABILITY=1",
    "_LIBCPP_DISABLE_VISIBILITY_ANNOTATIONS",
    "_LIBCPP_ENABLE_THREAD_SAFETY_ANNOTATIONS",
]

# macOS's: no large-file defines (Darwin's libc is 64-bit-offset
# throughout). Not here, as on Android: _FORTIFY_SOURCE=2, chromium_code's
# off Linux (copts.bzl's FLUTTER_LOCAL_DEFINES).
_MAC_DEFINES = [
    "USE_OPENSSL=1",
    "_LIBCPP_DISABLE_AVAILABILITY=1",
    "_LIBCPP_DISABLE_VISIBILITY_ANNOTATIONS",
    "_LIBCPP_ENABLE_THREAD_SAFETY_ANNOTATIONS",
]

# Android's (//build/config:feature_flags, //build/config/compiler:compiler
# and :runtime_library under is_android, the libc++ configs): no large-file
# defines (bionic is 64-bit-offset throughout), the NDK's ANDROID and
# HAVE_SYS_UIO_H, and two spellings bionic's headers expect. Not here:
# _FORTIFY_SOURCE=2, which is chromium_code's (copts.bzl's
# FLUTTER_LOCAL_DEFINES), first-party compiles' alone.
_ANDROID_DEFINES = [
    "USE_OPENSSL=1",
    "USE_OPENSSL_CERTS=1",
    "ANDROID",
    "HAVE_SYS_UIO_H",
    "__compiler_offsetof=__builtin_offsetof",
    "nan=__builtin_nan",
    "_LIBCPP_DISABLE_AVAILABILITY=1",
    "_LIBCPP_DISABLE_VISIBILITY_ANNOTATIONS",
    "_LIBCPP_ENABLE_THREAD_SAFETY_ANNOTATIONS",
]

# C-only flags (//build/config/compiler:compiler's cflags_c and
# :cxx_disable_modules).
_LINUX_C_FLAGS = [
    "-std=c11",
    "-fno-modules",
    "-Xclang",
    "-fno-cxx-modules",
]

# The C++ standard library's include directories, one file of each, in GN's
# search order: libc++abi's (//flutter/third_party/libcxxabi:libcxxabi_config's
# include_dirs), then the engine's libc++ configuration directory
# (//flutter/third_party/libcxx:libcxx_config's include_dirs: __config_site,
# which libc++'s <__config> includes, and the <format> and <version> that ban
# std::format -- they must be found before libc++'s own, which they
# #include_next), then libc++'s and libc++abi's again (the compiler config's
# `-nostdinc++ -I...` cflags_cc, which GN's tool emits after {{include_dirs}}).
# The toolchains pass this list as cxx_include_markers; the rule turns each
# file's directory into -I, in order. 10-30: the configuration directory had
# come last, which was no matter while it held __config_site alone, and left
# std::format in the Apple binaries once the ban headers arrived (the Mac's
# T66: check_forbidden_native_symbols).
CXX_INCLUDE_MARKERS = [
    "@libcxxabi//:include/cxxabi.h",
    "//engine/src/flutter/build/secondary/flutter/third_party/libcxx:config/__config_site",
    "@libcxx//:include/__config",
]

# C++-only flags (//build/config/compiler:cxx_version_default,
# :cxx_disable_modules, :no_rtti, //build/config/gcc:no_exceptions, the
# libc++/libc++abi configs). The -nostdinc++ include paths are appended by the
# rule because they depend on repository locations.
_LINUX_CXX_FLAGS = [
    "-std=c++20",
    "-fvisibility-inlines-hidden",
    "-Wno-deprecated-this-capture",
    "-fno-modules",
    "-Xclang",
    "-fno-cxx-modules",
    "-fno-rtti",
    "-fno-exceptions",
    "-nostdinc++",
]

# macOS's C++ compiles end with //build/config/mac:sdk's -stdlib=libc++
# (after the include paths; the rule appends it), and its Objective-C++
# compiles, which GN gives the C++ flags too, add
# //build/config/compiler:compiler's one Objective-C++ flag: C++ objects
# inside Objective-C ones get their constructors and destructors run.
_MAC_STDLIB_FLAGS = ["-stdlib=libc++"]
_MAC_OBJCXX_FLAGS = ["-fobjc-call-cxx-cdtors"]

# Flags GN passes to every link on Linux (//build/config/compiler:compiler,
# :runtime_library, //build/config/gcc:executable_ldconfig). The sysroot comes
# from Bazel's `sysroot` feature. -fuse-ld=lld is the toolchain's default and
# is spelled out so the choice does not depend on how clang was built.
_LINUX_LINK_FLAGS = [
    "-no-canonical-prefixes",
    "-fuse-ld=lld",
    "-Wl,--fatal-warnings",
    "-Wl,-z,noexecstack",
    "-Wl,-z,now",
    "-Wl,-z,relro",
    "-Wl,--undefined-version",
    "-Wl,--build-id=sha1",
    "-pthread",
    # The engine links its own libc++ (see `cxx_runtime` in BUILD.bazel); the
    # unwinder is the toolchain's static libunwind.
    "-nostdlib++",
    "--unwindlib=libunwind",
]

LINUX_X64_LINK_FLAGS = ["-m64"]
LINUX_ARM64_LINK_FLAGS = ["--target=aarch64-linux-gnu"]

# macOS's links (//build/config/compiler:compiler under is_mac,
# //build/config/mac:mac_dynamic_flags, which BUILDCONFIG.gn gives every
# executable and shared library): the engine's own libc++ again, and the
# rpaths of an unbundled binary and of one inside a bundle. The linker is
# the driver's default, ld64.lld from the same package (GN names none
# either); the sysroot and the deployment target come from the `sysroot`
# feature below. Not here: GN's `-L.`, the GN output directory itself.
_MAC_LINK_FLAGS = [
    "-nostdlib++",
    "-Wl,-search_paths_first",
    "-Wl,-rpath,@loader_path/.",
    "-Wl,-rpath,/usr/local/lib/.",
    "-Wl,-rpath,@loader_path/../../..",
]

# iOS's links: the engine's own libc++ again; mac_dynamic_flags and
# mac_executable_flags are the desktop's alone (BUILDCONFIG.gn gives them
# under is_mac), so no search-path or rpath flags, no -pie.
_IOS_LINK_FLAGS = ["-nostdlib++"]

# Android's links (//build/config/compiler:compiler under is_android,
# //build/config/android:runtime_library, build/toolchain/android/BUILD.gn):
# no -pthread and no unwinder flag; nothing of the C library or the C++
# runtime comes from the driver (-nostdlib -nostdlib++): the sysroot's crt
# objects and libraries and the NDK clang's compiler runtime are named one
# by one, late (see _android_link_libs), as GN's toolchain names them around
# {{libs}}; undefined symbols are errors, static archives' symbols are not
# exported, identical code is folded, and pages are 16 KB-aligned.
_ANDROID_LINK_FLAGS = [
    "-no-canonical-prefixes",
    "-fuse-ld=lld",
    "-Wl,--fatal-warnings",
    "-Wl,-z,noexecstack",
    "-Wl,-z,now",
    "-Wl,-z,relro",
    "-Wl,--undefined-version",
    "-Wl,--build-id=sha1",
    "-Wl,--exclude-libs,ALL",
    "-Wl,--icf=all",
    "-Wl,-z,max-page-size=65536",
    "-nostdlib++",
    "-nostdlib",
    "-Wl,--warn-shared-textrel",
]

# The architecture (--target with the API level, build/config/android/
# config.gni's android_api_level) for the compiles and the links.
ANDROID_ARM64_COMPILE_FLAGS = ["--target=aarch64-linux-android24"]
ANDROID_ARM64_LINK_FLAGS = ["--target=aarch64-linux-android24"]

# arm64 at API level 26 (build/toolchain/android/BUILD.gn's
# clang_arm64_apilevel26): the Vulkan validation layer's toolchain, which
# needs AHardwareBuffer_describe and the rest of API 26.
ANDROID_ARM64_API26_COMPILE_FLAGS = ["--target=aarch64-linux-android26"]
ANDROID_ARM64_API26_LINK_FLAGS = ["--target=aarch64-linux-android26"]

# x64: GN spells the triple with androideabi (build/config/compiler, the
# is_android block), and its posix block adds -m64 -march=x86-64 as for the
# host (LINUX_X64_COMPILE_FLAGS).
ANDROID_X64_COMPILE_FLAGS = ["--target=x86_64-linux-androideabi24"] + LINUX_X64_COMPILE_FLAGS
ANDROID_X64_LINK_FLAGS = ["--target=x86_64-linux-androideabi24"] + LINUX_X64_LINK_FLAGS

# arm (armv7, tools/gn's default --android-cpu): API 21
# (build/config/android/config.gni), build/config/arm.gni's arm_version 7
# defaults -- armv7-a, softfp, generic-armv7-a, Thumb, NEON (the
# compiler_arm_fpu config BUILDCONFIG.gn applies to every target).
ANDROID_ARM_COMPILE_FLAGS = [
    "--target=arm-linux-androideabi21",
    "-march=armv7-a",
    "-mfloat-abi=softfp",
    "-mtune=generic-armv7-a",
    "-mthumb",
    "-mfpu=neon",
]
ANDROID_ARM_LINK_FLAGS = ["--target=arm-linux-androideabi21"]

# riscv64: API 35 (config.gni), and build/config/compiler's
# allow_deprecated_api_calls, which is on for riscv64 alone
# (flutter/flutter#173656): deprecated API calls are not errors there.
ANDROID_RISCV64_COMPILE_FLAGS = [
    "--target=riscv64-linux-androideabi35",
    "-Wno-deprecated-declarations",
]
ANDROID_RISCV64_LINK_FLAGS = ["--target=riscv64-linux-androideabi35"]

# Every link GN performs produces a complete artifact -- an executable, or a
# shared library with all of its static dependencies linked in -- so GN can
# reject unresolved symbols in all of them (//build/config/compiler:compiler).
# Bazel additionally derives a `.so` from every cc_library (the
# cpp_link_nodeps_dynamic_library action) that by design leaves the library's
# dependencies, and with -nostdlib++ the C++ runtime, unresolved; it has no GN
# counterpart and nothing consumes it with --dynamic_mode=off, but `bazel build
# //...` still produces it, so it is excluded from this check.
_LINUX_COMPLETE_LINK_FLAGS = ["-Wl,-z,defs"]

# Android's complete links say it twice (-z defs and --no-undefined, both in
# GN's ldflags); the nodeps library is excused from both for the same reason.
_ANDROID_COMPLETE_LINK_FLAGS = ["-Wl,-z,defs", "-Wl,--no-undefined"]

_COMPLETE_LINK_ACTION_NAMES = CC_LINK_EXECUTABLE_ACTION_NAMES + [
    ACTION_NAMES.cpp_link_dynamic_library,
    ACTION_NAMES.lto_index_for_dynamic_library,
]

_LINUX_EXECUTABLE_LINK_FLAGS = [
    # //build/config/gcc:executable_ldconfig: the executable's own directory
    # is on its library search path, which is how a test finds the GPU test
    # backends (libvk_swiftshader.so, build/bazel/gl_wrap) placed next to it
    # with a bare dlopen, as in a GN build directory. Bazel's own rpath
    # entries for shared dependencies come besides.
    "-Wl,-rpath=$ORIGIN/",
    "-Wl,--disable-new-dtags",
]

_LINUX_LINK_LIBS = ["-ldl"]

# ld64 rejects undefined symbols on its own, so a Mac has no complete-link
# flag; instead the nodeps library, which has no GN counterpart and leaves
# its dependencies unresolved by design (see above), must be excused from
# ld64's default: without this the `.so` Bazel derives from every
# cc_library fails to link on a Mac, and with it `bazel build //...` and
# the Mac's T9 builds of the Metal backend and Impeller went through.
_MAC_NODEPS_DYNAMIC_LIBRARY_LINK_FLAGS = ["-Wl,-undefined,dynamic_lookup"]

# macOS's executables: //build/config/mac:mac_executable_flags, and the
# rpath build/toolchain/mac's `link` tool adds (a bundle's Frameworks
# directory). Nothing is named after the libraries (Foundation and the rest
# are a target's `frameworks`, in its linkopts).
_MAC_EXECUTABLE_LINK_FLAGS = [
    "-Wl,-pie",
    "-Xlinker",
    "-rpath",
    "-Xlinker",
    "@executable_path/Frameworks",
]

# iOS's executables: the link tool's rpath alone (mac_executable_flags is
# the desktop's).
_IOS_EXECUTABLE_LINK_FLAGS = [
    "-Xlinker",
    "-rpath",
    "-Xlinker",
    "@executable_path/Frameworks",
]

# //build/config:debug, :release, //build/config/compiler:no_optimize,
# :optimize, and the symbol configs BUILDCONFIG.gn picks by symbol_level:
# :symbols (-g2) for an unoptimized build, :no_symbols (-g0) for an
# optimized one on Linux ("Linux is slowed by having symbols as part of
# the target binary, whereas Mac and Windows have them separate, so in
# Release Linux, default them off"), so host_debug, host_profile and
# host_release all compile with -g0; a macOS toolchain would take -g2 in
# both. --copt=-g2 restores symbols for a profile.
_DBG_COMPILE_FLAGS = ["-O0", "-g2"]
_DBG_DEFINES = ["_DEBUG", "_GLIBCXX_DEBUG=1"]
_FASTBUILD_COMPILE_FLAGS = ["-O0", "-g1"]
_OPT_COMPILE_FLAGS = ["-O2", "-g0", "-fno-ident", "-fdata-sections", "-ffunction-sections"]
_OPT_DEFINES = ["NDEBUG", "NVALGRIND", "DYNAMIC_ANNOTATIONS_ENABLED=0"]
_OPT_LINK_FLAGS = ["-Wl,-O2", "-Wl,--gc-sections"]

# macOS's: //build/config:debug defines _GLIBCXX_DEBUG on Linux alone;
# symbol_level is 2 in every mode ("Mac and Windows have them separate"),
# so an optimized build compiles with -g2 -- and dead-strips at link time
# (//build/config/compiler:optimize under is_mac, which needs the symbols),
# where the Linux link has -O2 --gc-sections --as-needed.
_MAC_DBG_DEFINES = ["_DEBUG"]
_MAC_OPT_COMPILE_FLAGS = ["-O2", "-g2", "-fno-ident", "-fdata-sections", "-ffunction-sections"]
_MAC_OPT_LINK_FLAGS = ["-Wl,-dead_strip"]

# iOS's optimized compiles favor size (//build/config/compiler:optimize
# under is_ios: -Os); the rest as the Mac's.
_IOS_OPT_COMPILE_FLAGS = ["-Os", "-g2", "-fno-ident", "-fdata-sections", "-ffunction-sections"]

# ... and --as-needed, which GN leaves out under a sanitizer (functions the
# sanitizers interpose can make the linker drop a library that is needed,
# crbug.com/234010): a library nothing references is no NEEDED entry (the
# Vulkan validation layer's libdl).
_OPT_AS_NEEDED_LINK_FLAGS = ["-Wl,--as-needed"]

# Android's optimized build (//build/config/compiler:optimize under
# is_android, :symbols): for size, without frame pointers, and with full
# symbols -- symbol_level is 2 on Android, the shipped libflutter.so being
# stripped separately (symbols.zip carries the unstripped one).
_ANDROID_OPT_COMPILE_FLAGS = ["-Oz", "-fno-ident", "-fdata-sections", "-ffunction-sections", "-fomit-frame-pointer", "-g2"]

# GN's is_asan (//build/config/compiler:compiler under `using_sanitizer` and
# `is_asan`, //build/config:feature_flags' define): AddressSanitizer on every
# compile and link. In GN's command line these come before the mode's -O0
# -g2, so -gline-tables-only is overridden by -g2 there, and the feature sits
# before the mode features here for the same reason.
_ASAN_COMPILE_FLAGS = ["-fno-omit-frame-pointer", "-gline-tables-only", "-fsanitize=address"]
_ASAN_DEFINES = ["ADDRESS_SANITIZER"]
_ASAN_LINK_FLAGS = ["-fsanitize=address"]

# GN's enable_lto (//build/config/compiler:optimize, under enable_lto on
# Linux, Android, Apple, Fuchsia and wasm): -flto on the compiles and the
# link of an optimized build, -flto=thin under use_thin_lto. The `lto` and
# `thin_lto` attributes, which BUILD.bazel selects on
# //engine/src/flutter/build/bazel:lto and :thin_lto; tools/gn turns LTO
# off in unoptimized builds, so the feature requires the opt mode.
_LTO_FLAGS = ["-flto"]
_THIN_LTO_FLAGS = ["-flto=thin"]

def _defines(names):
    return ["-D" + name for name in names]

def _flag_feature(name, actions, flags, enabled = True):
    # A feature with nothing to add (an Android toolchain's executable link
    # flags) is an empty feature: flag_group refuses an empty list.
    return feature(
        name = name,
        enabled = enabled,
        flag_sets = [flag_set(actions = actions, flag_groups = [flag_group(flags = flags)])] if flags else [],
    )

def _mode_feature(name, compile_flags, link_flags = []):
    flag_sets = [flag_set(actions = ALL_CC_COMPILE_ACTION_NAMES, flag_groups = [flag_group(flags = compile_flags)])]
    if link_flags:
        flag_sets.append(flag_set(actions = ALL_CC_LINK_ACTION_NAMES, flag_groups = [flag_group(flags = link_flags)]))
    return feature(name = name, flag_sets = flag_sets)

def _android_link_libs(ctx, begin, end):
    # GN's libs section for an Android link: the crt object that opens it,
    # the C library, the dynamic loader, libm, the compiler runtime (found
    # through -L on the NDK clang's runtime directory), the crt object that
    # closes it. The -L of the API level's library directory precedes, as
    # GN's android config puts it in ldflags.
    triple_dir = ctx.file.crt_begin_so.dirname
    builtins = ctx.files.runtime_library
    if len(builtins) != 1:
        fail("%s: runtime_library should be one archive, is %s" % (ctx.label, builtins))
    name = builtins[0].basename
    if not name.startswith("lib") or not name.endswith(".a"):
        fail("%s: runtime_library should be lib<name>.a, is %s" % (ctx.label, name))
    return [
        "-L" + triple_dir,
        "-L" + builtins[0].dirname,
        begin.path,
        "-lc",
        "-ldl",
        "-lm",
        "-l" + name[len("lib"):-len(".a")],
        end.path,
    ]

def _impl(ctx):
    cxx_include_flags = []
    for header in ctx.files.cxx_include_markers:
        cxx_include_flags.append("-I" + header.dirname)

    android = ctx.attr.os == "android"
    ios = ctx.attr.os == "ios"

    # What the Apple platforms share: the SDK as -isysroot with the
    # deployment target, Objective-C, the Mach-O link forms, archives in
    # place of --start-lib.
    mac = ctx.attr.os == "mac" or ios

    # Bazel passes this as --sysroot to compile and link actions (`sysroot`
    # legacy feature; on a Mac the feature below, -isysroot) and uses it to
    # expand %sysroot% below: the directory of the marker file at the
    # sysroot's root (the Debian sysroot's BUILD file, the SDK view's .view).
    sysroot = ctx.file.sysroot_marker.dirname

    cxx_flags = _LINUX_CXX_FLAGS + cxx_include_flags
    objcxx_flags = []
    opt_link_flags = _OPT_LINK_FLAGS + ([] if ctx.attr.asan else _OPT_AS_NEEDED_LINK_FLAGS)
    lto_flags = _THIN_LTO_FLAGS if ctx.attr.thin_lto else _LTO_FLAGS
    dbg_defines = _DBG_DEFINES
    nodeps_dynamic_library_link_flags = []
    if android:
        compile_flags = _ANDROID_COMPILE_FLAGS + _defines(_ANDROID_DEFINES)
        link_flags = _ANDROID_LINK_FLAGS
        opt_compile_flags = _ANDROID_OPT_COMPILE_FLAGS
        complete_link_flags = _ANDROID_COMPLETE_LINK_FLAGS
        executable_link_flags = []
        if not ctx.file.crt_begin_so or not ctx.file.crt_end_so or not ctx.file.crt_begin_exe or not ctx.file.crt_end_exe:
            fail("%s: an Android toolchain names its four crt objects" % ctx.label)
        executable_link_libs = _android_link_libs(ctx, ctx.file.crt_begin_exe, ctx.file.crt_end_exe)
        dynamic_library_link_libs = _android_link_libs(ctx, ctx.file.crt_begin_so, ctx.file.crt_end_so)
        builtin_include_directories = [
            "%sysroot%/usr/include",
            "%sysroot%/usr/local/include",
            "%sysroot%/usr/include/" + ctx.file.crt_begin_so.dirname.split("/")[-2],
        ]
    elif mac:
        compile_flags = (_IOS_COMPILE_FLAGS if ios else _MAC_COMPILE_FLAGS) + _defines(_MAC_DEFINES)
        cxx_flags = cxx_flags + _MAC_STDLIB_FLAGS
        objcxx_flags = _MAC_OBJCXX_FLAGS
        link_flags = _IOS_LINK_FLAGS if ios else _MAC_LINK_FLAGS
        opt_compile_flags = _IOS_OPT_COMPILE_FLAGS if ios else _MAC_OPT_COMPILE_FLAGS
        opt_link_flags = _MAC_OPT_LINK_FLAGS
        dbg_defines = _MAC_DBG_DEFINES
        complete_link_flags = []
        nodeps_dynamic_library_link_flags = _MAC_NODEPS_DYNAMIC_LIBRARY_LINK_FLAGS
        executable_link_flags = _IOS_EXECUTABLE_LINK_FLAGS if ios else _MAC_EXECUTABLE_LINK_FLAGS
        executable_link_libs = []
        dynamic_library_link_libs = []

        # The SDK's headers, and its frameworks' (a framework's header is
        # found under System/Library/Frameworks/<name>.framework/Headers).
        builtin_include_directories = [
            "%sysroot%/usr/include",
            "%sysroot%/System/Library/Frameworks",
            "%sysroot%/System/Library/SubFrameworks",
        ]
    else:
        compile_flags = _LINUX_COMPILE_FLAGS + _defines(_LINUX_DEFINES)
        link_flags = _LINUX_LINK_FLAGS
        opt_compile_flags = _OPT_COMPILE_FLAGS
        complete_link_flags = _LINUX_COMPLETE_LINK_FLAGS
        executable_link_flags = _LINUX_EXECUTABLE_LINK_FLAGS
        executable_link_libs = _LINUX_LINK_LIBS
        dynamic_library_link_libs = _LINUX_LINK_LIBS
        builtin_include_directories = [
            "%sysroot%/usr/include",
            "%sysroot%/usr/local/include",
        ]

    features = [
        # Compile.
        _flag_feature(
            "flutter_compile_flags",
            ALL_CC_COMPILE_ACTION_NAMES,
            compile_flags,
        ),
        _flag_feature("flutter_c_flags", [ACTION_NAMES.c_compile, ACTION_NAMES.objc_compile], _LINUX_C_FLAGS),
        _flag_feature("flutter_cxx_flags", ALL_CPP_COMPILE_ACTION_NAMES, cxx_flags),
        _flag_feature("flutter_objcxx_flags", [ACTION_NAMES.objcpp_compile], objcxx_flags),
        # AddressSanitizer, when the build asks for it (the `asan` attribute,
        # which BUILD.bazel selects on //engine/src/flutter/build/bazel:asan).
        feature(
            name = "asan",
            enabled = ctx.attr.asan,
            flag_sets = [
                flag_set(
                    actions = ALL_CC_COMPILE_ACTION_NAMES,
                    flag_groups = [flag_group(flags = _ASAN_COMPILE_FLAGS + _defines(_ASAN_DEFINES))],
                ),
                flag_set(
                    actions = ALL_CC_LINK_ACTION_NAMES,
                    flag_groups = [flag_group(flags = _ASAN_LINK_FLAGS)],
                ),
            ],
        ),
        # Link-time optimization, when the build asks for it, in the opt mode
        # alone (as tools/gn has it): full LTO, or ThinLTO under thin_lto.
        feature(
            name = "lto",
            enabled = ctx.attr.lto,
            requires = [feature_set(features = ["opt"])],
            flag_sets = [
                flag_set(actions = ALL_CC_COMPILE_ACTION_NAMES, flag_groups = [flag_group(flags = lto_flags)]),
                flag_set(actions = ALL_CC_LINK_ACTION_NAMES, flag_groups = [flag_group(flags = lto_flags)]),
            ],
        ),
        # Compilation modes; Bazel enables exactly one of dbg/opt/fastbuild.
        _mode_feature("dbg", _DBG_COMPILE_FLAGS + _defines(dbg_defines)),
        _mode_feature("fastbuild", _FASTBUILD_COMPILE_FLAGS + _defines(dbg_defines)),
        _mode_feature(
            "opt",
            opt_compile_flags + _defines(_OPT_DEFINES),
            opt_link_flags,
        ),
        # A target's copts (Bazel's own `user_compile_flags` feature, defined
        # here so that it sits before the next one: Bazel appends the legacy
        # features it does not find to the end of this list), then the
        # architecture flags, which GN's compiler config puts after a
        # target's own cflags (see LINUX_X64_COMPILE_FLAGS).
        feature(
            name = "user_compile_flags",
            enabled = True,
            flag_sets = [
                flag_set(
                    actions = ALL_CC_COMPILE_ACTION_NAMES,
                    flag_groups = [
                        flag_group(
                            flags = ["%{user_compile_flags}"],
                            iterate_over = "user_compile_flags",
                            expand_if_available = "user_compile_flags",
                        ),
                    ],
                ),
            ],
        ),
        _flag_feature("flutter_arch_flags", ALL_CC_COMPILE_ACTION_NAMES, ctx.attr.arch_copts),
        # Link.
        _flag_feature("flutter_link_flags", ALL_CC_LINK_ACTION_NAMES, link_flags + ctx.attr.arch_linkopts),
        _flag_feature("flutter_complete_link_flags", _COMPLETE_LINK_ACTION_NAMES, complete_link_flags),
        _flag_feature(
            "flutter_nodeps_dynamic_library_link_flags",
            [ACTION_NAMES.cpp_link_nodeps_dynamic_library],
            nodeps_dynamic_library_link_flags,
        ),
        _flag_feature("flutter_executable_link_flags", CC_LINK_EXECUTABLE_ACTION_NAMES, executable_link_flags),
        # System libraries go after everything Bazel adds (user_link_flags,
        # libraries_to_link), which is why they are a separate, late feature;
        # an Android link's differ between an executable and a shared library
        # (the crt objects).
        _flag_feature("flutter_link_libs", CC_LINK_EXECUTABLE_ACTION_NAMES, executable_link_libs),
        _flag_feature("flutter_dynamic_library_link_libs", DYNAMIC_LIBRARY_LINK_ACTION_NAMES, dynamic_library_link_libs),
    ] + ([
        # The sysroot on a Mac: Bazel's own `sysroot` feature says
        # --sysroot=; Apple's driver and GN's command lines say -isysroot,
        # with the deployment target beside it (build/toolchain/mac's
        # `sysroot_flags`, the last flags of a compile and the first of a
        # link). A feature of this name replaces Bazel's.
        feature(
            name = "sysroot",
            enabled = True,
            flag_sets = [
                flag_set(
                    actions = ALL_CC_COMPILE_ACTION_NAMES + ALL_CC_LINK_ACTION_NAMES,
                    flag_groups = [
                        flag_group(
                            flags = [
                                "-isysroot",
                                "%{sysroot}",
                                ctx.attr.deployment_target_flag + ctx.attr.deployment_target,
                            ],
                            expand_if_available = "sysroot",
                        ),
                    ],
                ),
            ],
        ),
        # A target's defines on its Objective-C(++) compiles. Bazel's own
        # preprocessor_defines feature (a legacy one it appends when a
        # toolchain defines none) names the C and C++ actions alone, so an
        # .mm compiled embedder.h without FLUTTER_API_SYMBOL_PREFIX and
        # FLUTTER_FRAMEWORK (the Mac's T14). The C and C++ actions keep the
        # legacy feature, so their command lines stay as they are everywhere.
        feature(
            name = "objc_preprocessor_defines",
            enabled = True,
            flag_sets = [
                flag_set(
                    actions = [ACTION_NAMES.objc_compile, ACTION_NAMES.objcpp_compile],
                    flag_groups = [
                        flag_group(
                            flags = ["-D%{preprocessor_defines}"],
                            iterate_over = "preprocessor_defines",
                            expand_if_available = "preprocessor_defines",
                        ),
                    ],
                ),
            ],
        ),
    ] if mac else []) + [
        # Capabilities Bazel asks about.
        feature(name = "supports_pic", enabled = True),
        feature(name = "supports_dynamic_linker", enabled = True),
        # With this, a link names the object files of the libraries it links
        # instead of their archives: those of an alwayslink library (a GN
        # source_set) directly, those of any other inside --start-lib
        # ... --end-lib, which the linker treats as an archive's members. That
        # is the link line GN produces -- a source_set's objects are on it, a
        # static_library is an archive -- and the difference is visible: lld's
        # --exclude-libs,ALL (Android's links) hides every symbol an archive
        # defines, version script or not, so with archives for source_sets
        # libflutter.so would export neither JNI_OnLoad nor the ICU data.
        # ld64 has no --start-lib: on a Mac a library is its archive, and an
        # alwayslink one is -force_load'ed whole (Bazel's libraries_to_link
        # under target_libc "macosx"), which is a source_set's objects again.
        feature(name = "supports_start_end_lib", enabled = not mac),
        # Replaces Bazel's built-in include_paths feature, which passes the
        # `includes` of cc_library rules with -isystem. GN passes every include
        # directory with -I, and the difference matters: clang suppresses
        # warnings in headers found through -isystem, so with Bazel's default
        # -Werror would stop covering engine headers (all reached through
        # -I engine/src) and third-party headers alike.
        feature(
            name = "include_paths",
            enabled = True,
            flag_sets = [
                flag_set(
                    actions = ALL_CC_COMPILE_ACTION_NAMES,
                    flag_groups = [
                        flag_group(
                            flags = ["-iquote", "%{quote_include_paths}"],
                            iterate_over = "quote_include_paths",
                        ),
                        flag_group(
                            flags = ["-I%{include_paths}"],
                            iterate_over = "include_paths",
                        ),
                        flag_group(
                            flags = ["-I%{system_include_paths}"],
                            iterate_over = "system_include_paths",
                        ),
                        flag_group(
                            flags = ["-F%{framework_include_paths}"],
                            iterate_over = "framework_include_paths",
                        ),
                    ],
                ),
            ],
        ),
    ]

    # Which tool runs which action. Bazel supplies the mechanical flags (-c,
    # -o, -MD, -D, -I, @params, rcsD, ...) through its legacy features, which
    # are added automatically because `no_legacy_features` is not set. The
    # link-side ones are only activated by `implies`, so each action config
    # implies what Bazel's own action config for that action would.
    compile_implies = [
        "legacy_compile_flags",
        "user_compile_flags",
        "sysroot",
        "unfiltered_compile_flags",
        "compiler_input_flags",
        "compiler_output_flags",
    ]
    link_implies = [
        "strip_debug_symbols",
        "linkstamps",
        "output_execpath_flags",
        "runtime_library_search_directories",
        "library_search_directories",
        "libraries_to_link",
        "user_link_flags",
        "legacy_link_flags",
        "linker_param_file",
        "fission_support",
        "sysroot",
    ]
    executable_link_implies = link_implies + ["force_pic_flags"]
    dynamic_library_link_implies = link_implies + [
        "build_interface_libraries",
        "dynamic_library_linker_tool",
        "shared_flag",
    ]

    # Remote compiles of an Apple toolchain (build/bazel:apple_remote_compiles,
    # macos_toolchain.bzl): the compile actions' tool is the wrapper, which
    # runs the Mac's clang on a Mac and the Linux x64 clang on a worker,
    # finding both in the action's environment (exec-root relative paths,
    # per action kind: clang for C and assembly, clang++ for C++ and
    # Objective-C); everything else of the toolchain -- links, archives,
    # strip, objcopy -- is the Mac's binaries and must not leave the Mac
    # (no-remote-exec), whatever the strategies say.
    remote = ctx.file.remote_clang != None
    if remote and (ctx.file.remote_clangxx == None or ctx.file.compiler_wrapper == None):
        fail("%s: remote_clang needs remote_clangxx and compiler_wrapper with it" % ctx.label)
    local_only = ["no-remote-exec"] if remote else []
    c_compile_actions = [
        ACTION_NAMES.c_compile,
        ACTION_NAMES.assemble,
        ACTION_NAMES.preprocess_assemble,
    ]
    cxx_compile_actions = [
        ACTION_NAMES.cpp_compile,
        ACTION_NAMES.cpp_header_parsing,
        ACTION_NAMES.cpp_module_compile,
        ACTION_NAMES.cpp_module_codegen,
        ACTION_NAMES.linkstamp_compile,
    ]
    objc_compile_actions = [
        ACTION_NAMES.objc_compile,
        ACTION_NAMES.objcpp_compile,
    ]
    if remote:
        c_compiler = tool(tool = ctx.file.compiler_wrapper)
        cxx_compiler = c_compiler
        features.append(
            feature(
                name = "apple_remote_compiler",
                enabled = True,
                env_sets = [
                    env_set(
                        actions = c_compile_actions,
                        env_entries = [
                            env_entry(key = "FLUTTER_CLANG_HOST", value = ctx.file.clang.path),
                            env_entry(key = "FLUTTER_CLANG_REMOTE", value = ctx.file.remote_clang.path),
                        ],
                    ),
                    env_set(
                        actions = cxx_compile_actions + objc_compile_actions,
                        env_entries = [
                            env_entry(key = "FLUTTER_CLANG_HOST", value = ctx.file.clangxx.path),
                            env_entry(key = "FLUTTER_CLANG_REMOTE", value = ctx.file.remote_clangxx.path),
                        ],
                    ),
                ],
            ),
        )
    else:
        c_compiler = tool(tool = ctx.file.clang)
        cxx_compiler = tool(tool = ctx.file.clangxx)

    clang = c_compiler
    clangxx = cxx_compiler
    linker = tool(tool = ctx.file.clangxx, execution_requirements = local_only)
    action_configs = [
        action_config(action_name = name, enabled = True, tools = [clang], implies = compile_implies)
        for name in c_compile_actions
    ] + [
        action_config(action_name = name, enabled = True, tools = [clangxx], implies = compile_implies)
        for name in cxx_compile_actions
    ] + ([
        # Objective-C and Objective-C++ (objc_library's actions), through
        # clang++ as GN's `objc` and `objcxx` tools are, on a Mac alone:
        # objc_library asks whether the toolchain has the first of these,
        # and elsewhere it has not.
        action_config(action_name = name, enabled = True, tools = [clangxx], implies = compile_implies)
        for name in objc_compile_actions
    ] if mac else []) + [
        action_config(
            action_name = ACTION_NAMES.cpp_link_executable,
            enabled = True,
            tools = [linker],
            implies = executable_link_implies,
        ),
        action_config(
            action_name = ACTION_NAMES.cpp_link_dynamic_library,
            enabled = True,
            tools = [linker],
            implies = dynamic_library_link_implies,
        ),
        action_config(
            action_name = ACTION_NAMES.cpp_link_nodeps_dynamic_library,
            enabled = True,
            tools = [linker],
            implies = dynamic_library_link_implies,
        ),
        action_config(
            action_name = ACTION_NAMES.cpp_link_static_library,
            enabled = True,
            tools = [tool(tool = ctx.file.ar, execution_requirements = local_only)],
            implies = ["archiver_flags", "linker_param_file"],
        ),
        action_config(
            action_name = ACTION_NAMES.strip,
            enabled = True,
            tools = [tool(tool = ctx.file.strip, execution_requirements = local_only)],
        ),
        action_config(
            action_name = ACTION_NAMES.objcopy_embed_data,
            enabled = True,
            tools = [tool(tool = ctx.file.objcopy, execution_requirements = local_only)],
        ),
    ]

    # The builtin include directory of the worker's clang as well, when
    # there is one: the dependency files of a remote compile name its
    # headers (stddef.h, arm_neon.h), and the directory is an input through
    # the toolchain's files like the Mac clang's.
    resource_include_directories = ["%workspace%/" + ctx.file.resource_include_marker.dirname]
    if ctx.file.remote_resource_include_marker != None:
        resource_include_directories.append("%workspace%/" + ctx.file.remote_resource_include_marker.dirname)

    return cc_common.create_cc_toolchain_config_info(
        ctx = ctx,
        toolchain_identifier = ctx.attr.toolchain_identifier,
        host_system_name = "local",
        target_system_name = ctx.attr.target_system_name,
        target_cpu = ctx.attr.target_cpu,
        target_libc = ctx.attr.target_libc,
        compiler = "clang",
        abi_version = "local",
        abi_libc_version = "local",
        features = features,
        action_configs = action_configs,
        builtin_sysroot = sysroot,
        # Headers included from these directories need not be declared as
        # inputs file by file: the sysroot, the C++ standard library and
        # clang's builtin headers, which reach every compile as *directory*
        # inputs through the toolchain's files (one symlink per action in
        # the sandbox instead of ~11,000; see build/bazel/third_party/sysroot).
        # %workspace% makes an entry exec-root relative, like the paths in the
        # compiler's dependency files; a bare relative path would be taken
        # relative to this package.
        cxx_builtin_include_directories = builtin_include_directories + [
            "%workspace%/" + marker.dirname
            for marker in ctx.files.cxx_include_markers
        ] + resource_include_directories,
    )

flutter_cc_toolchain_config = rule(
    implementation = _impl,
    doc = "C/C++ toolchain configuration reproducing the GN build's flags for one of its clang toolchains (Linux, Android, macOS).",
    attrs = {
        "toolchain_identifier": attr.string(mandatory = True),
        "target_system_name": attr.string(mandatory = True, doc = "Target triple, e.g. x86_64-unknown-linux-gnu."),
        "target_cpu": attr.string(mandatory = True, doc = "Bazel's legacy CPU name, e.g. k8."),
        "target_libc": attr.string(mandatory = True, doc = "Informational, e.g. glibc_2.31 for a bullseye sysroot."),
        "clang": attr.label(mandatory = True, allow_single_file = True, doc = "The C compiler driver."),
        "clangxx": attr.label(mandatory = True, allow_single_file = True, doc = "The C++ compiler and linker driver."),
        "remote_clang": attr.label(
            allow_single_file = True,
            doc = "An Apple toolchain whose compiles may run on a Linux x64 worker: the worker's C compiler driver " +
                  "(@clang_linux_x64's, the same LLVM revision). With it the compile actions run `compiler_wrapper`, " +
                  "which picks this or `clang` by the executing machine, and the links, archives, strip and objcopy " +
                  "are marked no-remote-exec (the Mac's binaries).",
        ),
        "remote_clangxx": attr.label(allow_single_file = True, doc = "With remote_clang: the worker's C++ compiler driver."),
        "compiler_wrapper": attr.label(
            allow_single_file = True,
            doc = "With remote_clang: the script the compile actions run (apple_clang_wrapper.sh), which execs " +
                  "FLUTTER_CLANG_HOST on a Mac and FLUTTER_CLANG_REMOTE on Linux, both set by the toolchain.",
        ),
        "remote_resource_include_marker": attr.label(
            allow_single_file = True,
            doc = "With remote_clang: a file in the worker clang's builtin include directory, which becomes a " +
                  "builtin include directory as the Mac clang's is.",
        ),
        "ar": attr.label(mandatory = True, allow_single_file = True),
        "objcopy": attr.label(mandatory = True, allow_single_file = True),
        "strip": attr.label(mandatory = True, allow_single_file = True),
        "sysroot_marker": attr.label(
            mandatory = True,
            allow_single_file = True,
            doc = "A file at the root of the sysroot: the Debian sysroot repository's BUILD file (--sysroot), " +
                  "the macOS SDK view's marker (@macos_sdk//:view; -isysroot, with the deployment target).",
        ),
        "deployment_target": attr.string(
            default = MACOS_DEPLOYMENT_TARGET,
            doc = "The Apple platforms: the deployment target the sysroot feature passes with -isysroot (GN's " +
                  "mac_deployment_target, 12.0.0, or ios_deployment_target, 15.0; //build_defs/cc:apple.bzl).",
        ),
        "deployment_target_flag": attr.string(
            default = "-mmacosx-version-min=",
            values = ["-mmacosx-version-min=", "-miphoneos-version-min=", "-mios-simulator-version-min="],
            doc = "The flag that carries the deployment target: macOS's, an iOS device's or the simulator's " +
                  "(build/toolchain/mac's sysroot_flags per toolchain).",
        ),
        "cxx_include_markers": attr.label_list(
            mandatory = True,
            allow_files = True,
            doc = "One file per C++ standard library include directory (-nostdinc++ replacements), in search order; their directories are added with -I.",
        ),
        "resource_include_marker": attr.label(
            mandatory = True,
            allow_single_file = True,
            doc = "A file in clang's builtin include directory (lib/clang/<version>/include); the directory is a builtin include directory.",
        ),
        "asan": attr.bool(
            default = False,
            doc = "Whether every compile and link is instrumented with AddressSanitizer (GN's is_asan).",
        ),
        "lto": attr.bool(
            default = False,
            doc = "Whether an optimized build compiles and links with -flto (GN's enable_lto).",
        ),
        "thin_lto": attr.bool(
            default = False,
            doc = "Whether the LTO of an optimized build is ThinLTO, -flto=thin in place of -flto (GN's " +
                  "use_thin_lto); nothing without `lto`.",
        ),
        "arch_copts": attr.string_list(
            default = LINUX_X64_COMPILE_FLAGS,
            doc = "The architecture's compile flags (//build/config/compiler:compiler's cflags for the " +
                  "target CPU: LINUX_X64_COMPILE_FLAGS, LINUX_ARM64_COMPILE_FLAGS), after a target's own.",
        ),
        "arch_linkopts": attr.string_list(
            default = LINUX_X64_LINK_FLAGS,
            doc = "The architecture's link flags (LINUX_X64_LINK_FLAGS, LINUX_ARM64_LINK_FLAGS).",
        ),
        "os": attr.string(
            default = "linux",
            values = ["linux", "android", "mac", "ios"],
            doc = "The target OS, which picks GN's flag sets: linux (the host's and the arm64 cross " +
                  "build's), android (the NDK sysroot, -nostdlib with the crt objects and libraries named), " +
                  "mac (the Xcode SDK as -isysroot, Objective-C, archives in place of --start-lib) or ios " +
                  "(the Mac's less the desktop's stack protector, search paths, rpaths and -pie, -Os when " +
                  "optimized; the iPhoneOS or iPhoneSimulator SDK as -isysroot with its deployment-target flag).",
        ),
        "crt_begin_so": attr.label(
            allow_single_file = True,
            doc = "Android: the sysroot's crtbegin_so.o of the ABI's API level, which opens a shared library's " +
                  "libs section; its directory is the -L of the link and names the triple.",
        ),
        "crt_end_so": attr.label(allow_single_file = True, doc = "Android: crtend_so.o."),
        "crt_begin_exe": attr.label(allow_single_file = True, doc = "Android: crtbegin_dynamic.o, an executable's."),
        "crt_end_exe": attr.label(allow_single_file = True, doc = "Android: crtend_android.o."),
        "runtime_library": attr.label(
            allow_files = True,
            doc = "Android: the NDK clang's compiler runtime archive for the ABI " +
                  "(libclang_rt.builtins-<arch>-android.a), linked as -l<name> from its directory.",
        ),
    },
    provides = [CcToolchainConfigInfo],
)
