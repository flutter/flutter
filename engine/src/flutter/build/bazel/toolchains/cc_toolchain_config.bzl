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

# Flags GN passes to every C and C++ compile on Linux
# (//build/config/compiler:compiler, :runtime_library, //build/config/gcc,
# //build/config/clang:extra_warnings, the `default_warning_flags`).
_LINUX_COMPILE_FLAGS = [
    # Keep paths as spelled on the command line: clang is invoked through a
    # symlink and must report its builtin headers under that path, not under
    # the checkout's absolute path (//build/config/gcc:relative_paths).
    "-no-canonical-prefixes",
    "-fno-strict-aliasing",
    "-fstack-protector",
    "--param=ssp-buffer-size=8",
    "-pipe",
    "-pthread",
    "-fcolor-diagnostics",
    "-fvisibility=hidden",
    "-Wendif-labels",
    "-Wno-missing-field-initializers",
    "-Wno-unused-parameter",
    "-Wno-unused-but-set-parameter",
    "-Wno-unused-but-set-variable",
    "-Wno-psabi",
    "-Wno-implicit-int-float-conversion",
    "-Wno-deprecated-copy",
    "-Wno-deprecated-literal-operator",
    "-Wno-unqualified-std-cast-call",
    "-Wno-nontrivial-memcall",
    "-Wno-non-c-typedef-for-linkage",
    "-Wno-range-loop-construct",
    "-Wstring-conversion",
    "-Wnewline-eof",
]

_LINUX_X64_COMPILE_FLAGS = [
    "-m64",
    "-march=x86-64",
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
    "-Wl,-z,defs",
    "-Wl,--undefined-version",
    "-Wl,--build-id=sha1",
    "-pthread",
    # The engine links its own libc++ (see `cxx_runtime` in BUILD.bazel); the
    # unwinder is the toolchain's static libunwind.
    "-nostdlib++",
    "--unwindlib=libunwind",
]

_LINUX_X64_LINK_FLAGS = ["-m64"]

_LINUX_EXECUTABLE_LINK_FLAGS = [
    "-Wl,--disable-new-dtags",
]

_LINUX_LINK_LIBS = ["-ldl"]

# //build/config:debug, :release, //build/config/compiler:no_optimize,
# :optimize, :symbols.
_DBG_COMPILE_FLAGS = ["-O0", "-g2"]
_DBG_DEFINES = ["_DEBUG", "_GLIBCXX_DEBUG=1"]
_FASTBUILD_COMPILE_FLAGS = ["-O0", "-g1"]
_OPT_COMPILE_FLAGS = ["-O2", "-g2", "-fno-ident", "-fdata-sections", "-ffunction-sections"]
_OPT_DEFINES = ["NDEBUG", "NVALGRIND", "DYNAMIC_ANNOTATIONS_ENABLED=0"]
_OPT_LINK_FLAGS = ["-Wl,-O2", "-Wl,--gc-sections"]

def _defines(names):
    return ["-D" + name for name in names]

def _flag_feature(name, actions, flags, enabled = True):
    return feature(
        name = name,
        enabled = enabled,
        flag_sets = [flag_set(actions = actions, flag_groups = [flag_group(flags = flags)])],
    )

def _mode_feature(name, compile_flags, link_flags = []):
    flag_sets = [flag_set(actions = ALL_CC_COMPILE_ACTION_NAMES, flag_groups = [flag_group(flags = compile_flags)])]
    if link_flags:
        flag_sets.append(flag_set(actions = ALL_CC_LINK_ACTION_NAMES, flag_groups = [flag_group(flags = link_flags)]))
    return feature(name = name, flag_sets = flag_sets)

def _impl(ctx):
    cxx_include_flags = []
    for header in ctx.files.cxx_include_markers:
        cxx_include_flags.append("-I" + header.dirname)

    features = [
        # Compile.
        _flag_feature(
            "flutter_compile_flags",
            ALL_CC_COMPILE_ACTION_NAMES,
            _LINUX_COMPILE_FLAGS + _LINUX_X64_COMPILE_FLAGS + _defines(_LINUX_DEFINES),
        ),
        _flag_feature("flutter_cxx_flags", ALL_CPP_COMPILE_ACTION_NAMES, _LINUX_CXX_FLAGS + cxx_include_flags),
        # Compilation modes; Bazel enables exactly one of dbg/opt/fastbuild.
        _mode_feature("dbg", _DBG_COMPILE_FLAGS + _defines(_DBG_DEFINES)),
        _mode_feature("fastbuild", _FASTBUILD_COMPILE_FLAGS + _defines(_DBG_DEFINES)),
        _mode_feature("opt", _OPT_COMPILE_FLAGS + _defines(_OPT_DEFINES), _OPT_LINK_FLAGS),
        # Link.
        _flag_feature("flutter_link_flags", ALL_CC_LINK_ACTION_NAMES, _LINUX_LINK_FLAGS + _LINUX_X64_LINK_FLAGS),
        _flag_feature("flutter_executable_link_flags", CC_LINK_EXECUTABLE_ACTION_NAMES, _LINUX_EXECUTABLE_LINK_FLAGS),
        # System libraries go after everything Bazel adds (user_link_flags,
        # libraries_to_link), which is why they are a separate, late feature.
        _flag_feature(
            "flutter_link_libs",
            CC_LINK_EXECUTABLE_ACTION_NAMES + DYNAMIC_LIBRARY_LINK_ACTION_NAMES,
            _LINUX_LINK_LIBS,
        ),
        # Capabilities Bazel asks about.
        feature(name = "supports_pic", enabled = True),
        feature(name = "supports_dynamic_linker", enabled = True),
        feature(name = "supports_start_end_lib", enabled = False),
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

    # Bazel passes this as --sysroot to compile and link actions (`sysroot`
    # legacy feature) and uses it to expand %sysroot% below.
    sysroot = ctx.file.sysroot_marker.dirname

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
        # inputs. Everything else the compiler can reach (libc++, the clang
        # resource directory) is declared through the toolchain's files.
        cxx_builtin_include_directories = [
            "%sysroot%/usr/include",
            "%sysroot%/usr/local/include",
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
    },
    provides = [CcToolchainConfigInfo],
)
