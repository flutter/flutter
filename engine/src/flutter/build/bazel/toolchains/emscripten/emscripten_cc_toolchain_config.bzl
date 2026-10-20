# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""C/C++ toolchain configuration for the Emscripten (wasm32) toolchain.

GN builds the web engine's modules (skwasm, CanvasKit) with
build/toolchain/wasm.gni: a gcc_toolchain whose cc/cxx/ld are the synced
SDK's `emcc`/`em++` with `--em-config`, under the compiler configuration
of //build/config/compiler/BUILD.gn as it reads with `is_wasm` (no stack
protector, no -pthread, no -fvisibility=hidden, its own warning list, no
-nostdinc++ -- emscripten brings its libc++) and the link flags of its
`is_wasm` branch (-s WASM=1 ... -s MODULARIZE=1 -s EXPORT_ES6
--emit-symbol-map). The flags here are those of out/wasm_release's
compile and link lines, in their order, minus what GN attaches per target
(the `-Werror` of chromium_code, `-Oz -flto` of skwasm's own config, the
`-s` options of a module); see the spike's targets for those.

The tools are the wrapper scripts next to this file (emcc.sh, em++.sh,
emar.sh), which run the SDK's Python drivers with the paths the
configuration puts in the action's environment -- so neither the scripts
nor the emcc configuration file name a repository or a machine.

Compilation modes: -c opt is GN's release for wasm (-O3 -g0, NDEBUG; the
modules' own configs add -Oz and LTO), -c dbg GN's debug (-O0 -g2,
_DEBUG), -c fastbuild like dbg with minimal debug info.
"""

load(
    "@rules_cc//cc:action_names.bzl",
    "ACTION_NAMES",
    "ALL_CC_COMPILE_ACTION_NAMES",
    "ALL_CC_LINK_ACTION_NAMES",
    "ALL_CPP_COMPILE_ACTION_NAMES",
    "CC_LINK_EXECUTABLE_ACTION_NAMES",
)
load(
    "@rules_cc//cc:cc_toolchain_config_lib.bzl",
    "action_config",
    "env_entry",
    "env_set",
    "feature",
    "flag_group",
    "flag_set",
    "tool",
    "with_feature_set",
)
load("@rules_cc//cc/common:cc_common.bzl", "cc_common")

# Flags GN passes to every compile of the wasm toolchain
# (//build/config/compiler:compiler, :runtime_library, :default_warnings
# under is_wasm, //build/config/clang:extra_warnings), in GN's order.
_WASM_COMPILE_FLAGS = [
    "-fno-strict-aliasing",
    "-fcolor-diagnostics",
    # default_warning_flags as the is_wasm branch has them: the Linux list
    # (copts.bzl's DEFAULT_WARNING_FLAGS, without -Werror, which is a
    # target's) plus the four the branch adds for zlib and freetype2, minus
    # the two it adds for clang on other platforms.
    "-Wendif-labels",
    "-Wno-missing-field-initializers",
    "-Wno-unused-parameter",
    "-Wno-shift-negative-value",
    "-Wno-unused-function",
    "-Wno-unused-variable",
    "-Wno-sign-conversion",
    "-Wno-unused-but-set-parameter",
    "-Wno-unused-but-set-variable",
    "-Wno-psabi",
    "-Wno-implicit-int-float-conversion",
    "-Wno-deprecated-copy",
    "-Wno-deprecated-literal-operator",
    "-Wno-non-c-typedef-for-linkage",
    "-Wno-range-loop-construct",
    "-Wstring-conversion",
    "-Wnewline-eof",
]

# Defines GN passes to every wasm compile (//build/config:feature_flags,
# the libc++ thread-safety annotations).
_WASM_DEFINES = [
    "USE_OPENSSL=1",
    "_LIBCPP_ENABLE_THREAD_SAFETY_ANNOTATIONS",
]

_WASM_C_FLAGS = [
    "-std=c11",
    "-fno-modules",
    "-Xclang",
    "-fno-cxx-modules",
]

# //build/config/compiler:cxx_version_default, :cxx_disable_modules,
# :no_rtti. No -fno-exceptions and no -nostdinc++ under is_wasm.
_WASM_CXX_FLAGS = [
    "-fvisibility-inlines-hidden",
    "-std=c++20",
    "-Wno-deprecated-this-capture",
    "-fno-modules",
    "-Xclang",
    "-fno-cxx-modules",
    "-fno-rtti",
]

# //build/config/compiler:compiler's ldflags under is_wasm, in order, after
# a target's own ldflags as GN puts them (user_link_flags come first here
# for the same reason).
_WASM_LINK_FLAGS = [
    "-Wl,--fatal-warnings",
    "-s",
    "WASM=1",
    "-s",
    "FORCE_FILESYSTEM=0",
    "-s",
    "FILESYSTEM=0",
    "-s",
    "NO_EXIT_RUNTIME=1",
    "-s",
    "STRICT=1",
    "-s",
    "ENVIRONMENT=web,worker",
    "-s",
    "MODULARIZE=1",
    "-s",
    "EXPORT_ES6",
    "--emit-symbol-map",
]

# //build/config:debug / :release, :no_optimize / :optimize and the symbol
# configs, as the wasm_release and a debug wasm build compile.
_DBG_COMPILE_FLAGS = ["-O0", "-g2"]
_DBG_DEFINES = ["_DEBUG"]
_FASTBUILD_COMPILE_FLAGS = ["-O0", "-g1"]
_OPT_COMPILE_FLAGS = ["-O3", "-g0"]
_OPT_DEFINES = ["NDEBUG", "NVALGRIND", "DYNAMIC_ANNOTATIONS_ENABLED=0"]
_OPT_LINK_FLAGS = ["-Wl,--gc-sections"]

# The `libs` GN's link rule ends with (the runtime library config's), after
# the objects; emcc places system libraries itself, so the position is
# immaterial to it.
_WASM_LINK_LIBS = ["-ldl"]

def _defines(names):
    return ["-D" + name for name in names]

def _flag_feature(name, actions, flags, enabled = True):
    return feature(
        name = name,
        enabled = enabled,
        flag_sets = [flag_set(actions = actions, flag_groups = [flag_group(flags = flags)])],
    )

def _mode_feature(name, compile_flags):
    return feature(
        name = name,
        flag_sets = [flag_set(actions = ALL_CC_COMPILE_ACTION_NAMES, flag_groups = [flag_group(flags = compile_flags)])],
    )

def _impl(ctx):
    # upstream/: the directory of the directory of emcc.py.
    emscripten_dir = ctx.file.emscripten_marker.dirname
    bin_path = emscripten_dir.rsplit("/", 1)[0]
    tool_actions = ALL_CC_COMPILE_ACTION_NAMES + ALL_CC_LINK_ACTION_NAMES + [ACTION_NAMES.cpp_link_static_library]

    # emcc finds its sysroot (the SDK's cache) and clang its resource
    # directory from the SDK's location, which it resolves to an absolute
    # path -- through the repository's symlink, to the checkout -- and
    # writes into the dependency file, where Bazel accepts only paths it
    # knows. Both are therefore named explicitly and relatively: the sysroot
    # through Bazel's sysroot feature (--sysroot, which emcc honours in
    # place of its own), the resource directory with -resource-dir. GN's
    # command line has neither; the paths are the same directories.
    sysroot = emscripten_dir + "/cache/sysroot"
    resource_dir = ctx.file.resource_include_marker.dirname.rsplit("/", 1)[0]

    features = [
        # Where the wrappers find the SDK (see emcc.sh).
        feature(
            name = "emscripten_environment",
            enabled = True,
            env_sets = [
                env_set(
                    actions = tool_actions,
                    env_entries = [
                        env_entry(key = "EM_BIN_PATH", value = bin_path),
                        env_entry(key = "EM_CONFIG_PATH", value = ctx.file.em_config.path),
                        env_entry(key = "EM_NODE", value = ctx.file.node.path),
                        env_entry(key = "EM_PYTHON3", value = ctx.file.python3.path),
                    ],
                ),
            ],
        ),
        # Compile.
        _flag_feature(
            "flutter_compile_flags",
            ALL_CC_COMPILE_ACTION_NAMES,
            ["-resource-dir=" + resource_dir] + _WASM_COMPILE_FLAGS + _defines(_WASM_DEFINES),
        ),
        # Compilation modes; Bazel enables exactly one of dbg/opt/fastbuild.
        # Before the C and C++ flags, as GN's cflags (the optimization and
        # symbol configs among them) precede its cflags_cc.
        _mode_feature("dbg", _DBG_COMPILE_FLAGS + _defines(_DBG_DEFINES)),
        _mode_feature("fastbuild", _FASTBUILD_COMPILE_FLAGS + _defines(_DBG_DEFINES)),
        _mode_feature("opt", _OPT_COMPILE_FLAGS + _defines(_OPT_DEFINES)),
        _flag_feature("flutter_c_flags", [ACTION_NAMES.c_compile], _WASM_C_FLAGS),
        _flag_feature("flutter_cxx_flags", ALL_CPP_COMPILE_ACTION_NAMES, _WASM_CXX_FLAGS),
        # A target's copts (Bazel's own feature, defined here so that it
        # comes before the link flags below, which GN puts after a target's
        # own; see the Linux configuration for the mechanics).
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
        # Link: a target's own ldflags (user_link_flags, Bazel's feature)
        # first, as GN orders them, then the compiler config's.
        feature(
            name = "user_link_flags",
            enabled = True,
            flag_sets = [
                flag_set(
                    actions = ALL_CC_LINK_ACTION_NAMES,
                    flag_groups = [
                        flag_group(
                            flags = ["%{user_link_flags}"],
                            iterate_over = "user_link_flags",
                            expand_if_available = "user_link_flags",
                        ),
                    ],
                ),
            ],
        ),
        _flag_feature("flutter_link_flags", CC_LINK_EXECUTABLE_ACTION_NAMES, _WASM_LINK_FLAGS),
        # The optimized build's link flags come after the compiler config's,
        # as GN orders its configs.
        feature(
            name = "flutter_opt_link_flags",
            enabled = True,
            flag_sets = [
                flag_set(
                    actions = CC_LINK_EXECUTABLE_ACTION_NAMES,
                    flag_groups = [flag_group(flags = _OPT_LINK_FLAGS)],
                    with_features = [with_feature_set(features = ["opt"])],
                ),
            ],
        ),
        _flag_feature("flutter_link_libs", CC_LINK_EXECUTABLE_ACTION_NAMES, _WASM_LINK_LIBS),
        # Capabilities Bazel asks about: no PIC, no dynamic linking (every
        # module is one link of static archives, as GN's wasm_lib is).
        feature(name = "supports_pic", enabled = False),
        feature(name = "supports_dynamic_linker", enabled = False),
        feature(name = "supports_start_end_lib", enabled = False),
        # -I for every include directory, as the Linux configuration (and
        # GN) do; see there for why not -isystem.
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
                    ],
                ),
            ],
        ),
    ]

    # The legacy features each action implies (see the Linux configuration);
    # emcc has no --sysroot (its sysroot is the SDK's cache) and no PIC.
    compile_implies = [
        "legacy_compile_flags",
        "user_compile_flags",
        "sysroot",
        "unfiltered_compile_flags",
        "compiler_input_flags",
        "compiler_output_flags",
    ]
    link_implies = [
        "linkstamps",
        "output_execpath_flags",
        "library_search_directories",
        "libraries_to_link",
        "user_link_flags",
        "legacy_link_flags",
        "linker_param_file",
    ]

    emcc = tool(tool = ctx.file.emcc)
    emxx = tool(tool = ctx.file.emxx)
    action_configs = [
        action_config(action_name = name, enabled = True, tools = [emcc], implies = compile_implies)
        for name in [
            ACTION_NAMES.c_compile,
            ACTION_NAMES.assemble,
            ACTION_NAMES.preprocess_assemble,
        ]
    ] + [
        action_config(action_name = name, enabled = True, tools = [emxx], implies = compile_implies)
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
            tools = [emxx],
            implies = link_implies,
        ),
        action_config(
            action_name = ACTION_NAMES.cpp_link_static_library,
            enabled = True,
            tools = [tool(tool = ctx.file.emar)],
            implies = ["archiver_flags", "linker_param_file"],
        ),
    ]

    return cc_common.create_cc_toolchain_config_info(
        ctx = ctx,
        toolchain_identifier = ctx.attr.toolchain_identifier,
        host_system_name = "local",
        target_system_name = "wasm32-unknown-emscripten",
        target_cpu = "wasm32",
        target_libc = "musl",
        compiler = "emscripten",
        abi_version = "local",
        abi_libc_version = "local",
        features = features,
        action_configs = action_configs,
        builtin_sysroot = sysroot,
        # The sysroot's headers (libc++'s, musl's compat layer, libc's) and
        # the compiler's builtin headers, all inside the SDK, which reaches
        # every action as directory inputs.
        cxx_builtin_include_directories = [
            "%sysroot%/include/c++/v1",
            "%sysroot%/include/compat",
            "%sysroot%/include",
            "%workspace%/" + resource_dir + "/include",
        ],
    )

emscripten_cc_toolchain_config = rule(
    implementation = _impl,
    doc = "C/C++ toolchain configuration reproducing the GN build's flags for the Emscripten (wasm32) toolchain.",
    attrs = {
        "toolchain_identifier": attr.string(mandatory = True),
        "emcc": attr.label(mandatory = True, allow_single_file = True, doc = "The C compiler wrapper (emcc.sh)."),
        "emxx": attr.label(mandatory = True, allow_single_file = True, doc = "The C++ compiler and linker wrapper (em++.sh)."),
        "emar": attr.label(mandatory = True, allow_single_file = True, doc = "The archiver wrapper (emar.sh)."),
        "em_config": attr.label(mandatory = True, allow_single_file = True, doc = "emcc's configuration file (emscripten_config)."),
        "emscripten_marker": attr.label(
            mandatory = True,
            allow_single_file = True,
            doc = "A file in the SDK's emscripten directory (upstream/emscripten/emcc.py); the SDK's paths derive from it.",
        ),
        "node": attr.label(mandatory = True, allow_single_file = True, doc = "The SDK's Node.js binary."),
        "resource_include_marker": attr.label(
            mandatory = True,
            allow_single_file = True,
            doc = "A file in the SDK compiler's builtin include directory (upstream/lib/clang/<version>/include).",
        ),
        "python3": attr.label(mandatory = True, allow_single_file = True, doc = "The Python the drivers run under."),
    },
    provides = [CcToolchainConfigInfo],
)
