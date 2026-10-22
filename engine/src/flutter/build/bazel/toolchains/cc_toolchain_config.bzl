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
    "feature",
    "flag_group",
    "flag_set",
    "tool",
)
load("@rules_cc//cc/common:cc_common.bzl", "cc_common")
load("//engine/src/flutter/build/bazel:copts.bzl", "TOOLCHAIN_WARNING_FLAGS")

# Flags GN passes to every C and C++ compile on Linux
# (//build/config/compiler:compiler, :runtime_library, //build/config/gcc,
# //build/config/clang:extra_warnings, the `default_warning_flags`).
_COMMON_COMPILE_FLAGS = [
    # Keep paths as spelled on the command line: clang is invoked through a
    # symlink and must report its builtin headers under that path, not under
    # the checkout's absolute path (//build/config/gcc:relative_paths).
    "-no-canonical-prefixes",
    "-fno-strict-aliasing",
    "-fstack-protector",
    "--param=ssp-buffer-size=8",
    "-pipe",
]

_WARNING_COMPILE_FLAGS = [
    "-fcolor-diagnostics",
    "-fvisibility=hidden",
    # GN's `default_warning_flags` (part of both the chromium_code and the
    # no_chromium_code config, so every target gets them), without -Werror;
    # see copts.bzl for why, and for the per-target lists that repeat them
    # after -Wall -Wextra.
] + TOOLCHAIN_WARNING_FLAGS + [
    # //build/config/clang:extra_warnings.
    "-Wstring-conversion",
    "-Wnewline-eof",
]

_LINUX_COMPILE_FLAGS = _COMMON_COMPILE_FLAGS + ["-pthread"] + _WARNING_COMPILE_FLAGS

# Android (//build/config/compiler:compiler under is_android): no -pthread
# (bionic has no separate libpthread), and the three flags GN adds for the
# NDK's ABI: function sections, unwind tables, full-width enums.
_ANDROID_COMPILE_FLAGS = _COMMON_COMPILE_FLAGS + [
    "-ffunction-sections",
    "-funwind-tables",
    "-fno-short-enums",
] + _WARNING_COMPILE_FLAGS

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

# Android's (//build/config:feature_flags, //build/config/compiler:compiler
# and :runtime_library under is_android, the libc++ configs): no large-file
# defines (bionic is 64-bit-offset throughout), the NDK's ANDROID and
# HAVE_SYS_UIO_H, fortified libc, and two spellings bionic's headers expect.
_ANDROID_DEFINES = [
    "USE_OPENSSL=1",
    "USE_OPENSSL_CERTS=1",
    "ANDROID",
    "HAVE_SYS_UIO_H",
    "_FORTIFY_SOURCE=2",
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

    # Bazel passes this as --sysroot to compile and link actions (`sysroot`
    # legacy feature) and uses it to expand %sysroot% below.
    sysroot = ctx.file.sysroot_marker.dirname

    android = ctx.attr.os == "android"
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
        _flag_feature("flutter_c_flags", [ACTION_NAMES.c_compile], _LINUX_C_FLAGS),
        _flag_feature("flutter_cxx_flags", ALL_CPP_COMPILE_ACTION_NAMES, _LINUX_CXX_FLAGS + cxx_include_flags),
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
        # Compilation modes; Bazel enables exactly one of dbg/opt/fastbuild.
        _mode_feature("dbg", _DBG_COMPILE_FLAGS + _defines(_DBG_DEFINES)),
        _mode_feature("fastbuild", _FASTBUILD_COMPILE_FLAGS + _defines(_DBG_DEFINES)),
        _mode_feature("opt", opt_compile_flags + _defines(_OPT_DEFINES), _OPT_LINK_FLAGS),
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
        _flag_feature("flutter_executable_link_flags", CC_LINK_EXECUTABLE_ACTION_NAMES, executable_link_flags),
        # System libraries go after everything Bazel adds (user_link_flags,
        # libraries_to_link), which is why they are a separate, late feature;
        # an Android link's differ between an executable and a shared library
        # (the crt objects).
        _flag_feature("flutter_link_libs", CC_LINK_EXECUTABLE_ACTION_NAMES, executable_link_libs),
        _flag_feature("flutter_dynamic_library_link_libs", DYNAMIC_LIBRARY_LINK_ACTION_NAMES, dynamic_library_link_libs),
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
        feature(name = "supports_start_end_lib", enabled = True),
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

    clang = tool(tool = ctx.file.clang)
    clangxx = tool(tool = ctx.file.clangxx)
    action_configs = [
        action_config(action_name = name, enabled = True, tools = [clang], implies = compile_implies)
        for name in [
            ACTION_NAMES.c_compile,
            ACTION_NAMES.assemble,
            ACTION_NAMES.preprocess_assemble,
        ]
    ] + [
        action_config(action_name = name, enabled = True, tools = [clangxx], implies = compile_implies)
        for name in [
            ACTION_NAMES.cpp_compile,
            ACTION_NAMES.cpp_header_parsing,
            ACTION_NAMES.cpp_module_compile,
            ACTION_NAMES.cpp_module_codegen,
            ACTION_NAMES.linkstamp_compile,
        ]
    ] + [
        action_config(
            action_name = ACTION_NAMES.cpp_link_executable,
            enabled = True,
            tools = [clangxx],
            implies = executable_link_implies,
        ),
        action_config(
            action_name = ACTION_NAMES.cpp_link_dynamic_library,
            enabled = True,
            tools = [clangxx],
            implies = dynamic_library_link_implies,
        ),
        action_config(
            action_name = ACTION_NAMES.cpp_link_nodeps_dynamic_library,
            enabled = True,
            tools = [clangxx],
            implies = dynamic_library_link_implies,
        ),
        action_config(
            action_name = ACTION_NAMES.cpp_link_static_library,
            enabled = True,
            tools = [tool(tool = ctx.file.ar)],
            implies = ["archiver_flags", "linker_param_file"],
        ),
        action_config(action_name = ACTION_NAMES.strip, enabled = True, tools = [tool(tool = ctx.file.strip)]),
        action_config(action_name = ACTION_NAMES.objcopy_embed_data, enabled = True, tools = [tool(tool = ctx.file.objcopy)]),
    ]

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
        ] + [
            "%workspace%/" + ctx.file.resource_include_marker.dirname,
        ],
    )

flutter_cc_toolchain_config = rule(
    implementation = _impl,
    doc = "C/C++ toolchain configuration reproducing the GN build's flags for a Linux clang toolchain.",
    attrs = {
        "toolchain_identifier": attr.string(mandatory = True),
        "target_system_name": attr.string(mandatory = True, doc = "Target triple, e.g. x86_64-unknown-linux-gnu."),
        "target_cpu": attr.string(mandatory = True, doc = "Bazel's legacy CPU name, e.g. k8."),
        "target_libc": attr.string(mandatory = True, doc = "Informational, e.g. glibc_2.31 for a bullseye sysroot."),
        "clang": attr.label(mandatory = True, allow_single_file = True, doc = "The C compiler driver."),
        "clangxx": attr.label(mandatory = True, allow_single_file = True, doc = "The C++ compiler and linker driver."),
        "ar": attr.label(mandatory = True, allow_single_file = True),
        "objcopy": attr.label(mandatory = True, allow_single_file = True),
        "strip": attr.label(mandatory = True, allow_single_file = True),
        "sysroot_marker": attr.label(
            mandatory = True,
            allow_single_file = True,
            doc = "A file at the root of the sysroot repository; its directory becomes --sysroot.",
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
            values = ["linux", "android"],
            doc = "The target OS, which picks GN's flag sets: linux (the host's and the arm64 cross " +
                  "build's) or android (the NDK sysroot, -nostdlib with the crt objects and libraries named).",
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
