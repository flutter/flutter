# -*- bazel-starlark -*-
# Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.
"""Siso configuration for C/C++ compilation with Clang."""

load("@builtin//encoding.star", "json")
load("@builtin//path.star", "path")
load("@builtin//runtime.star", "runtime")
load("@builtin//struct.star", "module")

__CLANG_DIRS = [
    "flutter/buildtools/linux-x64/clang",
    "flutter/buildtools/linux-arm64/clang",
    "flutter/buildtools/mac-x64/clang",
    "flutter/buildtools/mac-arm64/clang",
    "flutter/buildtools/win-x64/clang",
]

__NDK_DIRS = [
    "flutter/third_party/android_tools/sdk/ndk/28.2.13676358/toolchains/llvm/prebuilt/linux-x86_64",
    "flutter/third_party/android_tools/sdk/ndk/28.2.13676358/toolchains/llvm/prebuilt/darwin-x86_64",
    "flutter/third_party/android_tools/sdk/ndk/28.2.13676358/toolchains/llvm/prebuilt/windows-x86_64",
]

__LINUX_SYSROOTS = [
    "build/linux/debian_bullseye_amd64-sysroot",
    "build/linux/debian_bullseye_arm64-sysroot",
    "build/linux/debian_sid_amd64-sysroot",
    "build/linux/debian_sid_arm64-sysroot",
    "build/linux/debian_trixie_riscv64-sysroot",
]

__FUCHSIA_SYSROOTS = [
    "third_party/fuchsia-sdk/sdk/arch/x64/sysroot",
    "third_party/fuchsia-sdk/sdk/arch/arm64/sysroot",
    "third_party/fuchsia-sdk/sdk/arch/riscv64/sysroot",
    "third_party/fuchsia-sdk/sdk/obj/x64-api-31/sysroot",
    "third_party/fuchsia-sdk/sdk/obj/arm64-api-31/sysroot",
    "third_party/fuchsia-sdk/sdk/obj/riscv64-api-31/sysroot",
]

def __mac_sdk_dirs(ctx):
    toolchain_ninja = ctx.fs.canonpath("./toolchain.ninja")
    if not ctx.fs.exists(toolchain_ninja):
        return []
    dirs = {}
    for line in str(ctx.fs.read(toolchain_ninja)).splitlines():
        if "-isysroot " not in line:
            continue
        tokens = line.strip().split(" ")
        for i in range(len(tokens) - 1):
            if tokens[i] == "-isysroot":
                raw_sdk = tokens[i + 1]
                if not path.isabs(raw_sdk):
                    sdk_dir = ctx.fs.canonpath("./" + raw_sdk)
                    dirs[sdk_dir] = True
    return sorted(dirs.keys())

def __win_toolchain_data(ctx):
    if not ctx.fs.exists("build/win_toolchain.json"):
        return None
    data = json.decode(str(ctx.fs.read("build/win_toolchain.json")))
    if "path" not in data:
        return None
    toolchain_dir = ctx.fs.canonpath(data["path"])
    if not ctx.fs.exists(toolchain_dir):
        return None
    sdk_version = None
    if "win_sdk" in data:
        setenv_path = ctx.fs.canonpath(data["win_sdk"] + "/bin/SetEnv.x64.json")
        if ctx.fs.exists(setenv_path):
            setenv = json.decode(str(ctx.fs.read(setenv_path)))
            for entry in setenv.get("env", {}).get("INCLUDE", []):
                if len(entry) >= 4 and entry[0] == "Windows Kits" and entry[1] == "10" and entry[2] == "Include":
                    sdk_version = entry[3]
                    break
    return {
        "toolchain_dir": toolchain_dir,
        "sdk_version": sdk_version,
    }

def __filegroups(ctx):
    fg = {}
    if ctx.fs.exists("flutter/third_party/libcxx/include"):
        fg["flutter/third_party/libcxx/include:headers"] = {
            "type": "glob",
            "includes": ["*"],
        }
    if ctx.fs.exists("flutter/third_party/libcxxabi/include"):
        fg["flutter/third_party/libcxxabi/include:headers"] = {
            "type": "glob",
            "includes": ["*.h"],
        }

    for clang_dir in __CLANG_DIRS:
        if ctx.fs.exists(clang_dir):
            fg[clang_dir + "/include:headers"] = {
                "type": "glob",
                "includes": ["*"],
            }
            fg[clang_dir + "/lib/clang:headers"] = {
                "type": "glob",
                "includes": [
                    "*.h",
                    "*.inc",
                    "*.modulemap",
                    "*/include/*",
                    "*/include/*/*",
                    "*/include/*/*/*",
                    "*/share/*",
                ],
            }
            fg[clang_dir + "/share:headers"] = {
                "type": "glob",
                "includes": ["*"],
            }

    for ndk_dir in __NDK_DIRS:
        if ctx.fs.exists(ndk_dir):
            fg[ndk_dir + "/sysroot/usr/include:headers"] = {
                "type": "glob",
                "includes": ["*"],
            }
            if ctx.fs.exists(ndk_dir + "/lib/clang"):
                fg[ndk_dir + "/lib/clang:headers"] = {
                    "type": "glob",
                    "includes": [
                        "*.h",
                        "*.inc",
                        "*.modulemap",
                        "*/include/*",
                        "*/include/*/*",
                        "*/include/*/*/*",
                        "*/share/*",
                    ],
                }
            if ctx.fs.exists(ndk_dir + "/lib64/clang"):
                fg[ndk_dir + "/lib64/clang:headers"] = {
                    "type": "glob",
                    "includes": [
                        "*.h",
                        "*.inc",
                        "*.modulemap",
                        "*/include/*",
                        "*/include/*/*",
                        "*/include/*/*/*",
                        "*/share/*",
                    ],
                }

    for sysroot in __LINUX_SYSROOTS:
        if ctx.fs.exists(sysroot + "/usr/include"):
            fg[sysroot + "/usr/include:headers"] = {
                "type": "glob",
                "includes": ["*"],
            }
        if ctx.fs.exists(sysroot + "/usr/lib"):
            fg[sysroot + "/usr/lib:headers"] = {
                "type": "glob",
                "includes": ["*"],
            }

    for sysroot in __FUCHSIA_SYSROOTS:
        if ctx.fs.exists(sysroot + "/include"):
            fg[sysroot + "/include:headers"] = {
                "type": "glob",
                "includes": ["*"],
            }

    for sdk_dir in __mac_sdk_dirs(ctx):
        fg[sdk_dir + ":headers"] = {
            "type": "glob",
            "includes": [
                "*.framework",
                "*.h",
                "*.json",
                "*.modulemap",
                "Current",
                "Frameworks",
                "Headers",
                "Modules",
                "crt*.o",
                "usr/include/*",
                "usr/include/c++/v1/*",
                "usr/include/c++/v1/*/*",
            ],
        }

    win_data = __win_toolchain_data(ctx)
    if win_data:
        win_toolchain_dir = win_data["toolchain_dir"]
        fg[win_toolchain_dir + ":headers-ci"] = {
            "type": "glob",
            "includes": [
                "*.h",
                "*.inl",
                "*.H",
                "*.Hxx",
                "*.hxx",
                "*.hpp",
                "VC/Tools/MSVC/*/include/*",
                "VC/Tools/MSVC/*/include/*/*",
            ],
        }

    return fg

def __step_config(ctx, step_config):
    input_deps = step_config["input_deps"]

    libcxx_deps = []
    for p in [
        "flutter/build/secondary/flutter/third_party/libcxx/config/__assertion_handler",
        "flutter/build/secondary/flutter/third_party/libcxx/config/__config_site",
        "flutter/third_party/libcxxabi/include:headers",
    ]:
        if ctx.fs.exists(p.split(":")[0]):
            libcxx_deps.append(p)

    for clang_dir in __CLANG_DIRS:
        if ctx.fs.exists(clang_dir):
            deps = [
                clang_dir + "/include:headers",
                clang_dir + "/lib/clang:headers",
                clang_dir + "/share:headers",
            ]
            for b in ["clang", "clang++", "clang-cl", "clang.exe", "clang++.exe", "clang-cl.exe", "llvm", "llvm.exe"]:
                p = clang_dir + "/bin/" + b
                if ctx.fs.exists(p):
                    deps.append(p)
            input_deps[clang_dir + ":headers"] = deps

    for ndk_dir in __NDK_DIRS:
        if ctx.fs.exists(ndk_dir):
            input_deps[ndk_dir + "/sysroot:headers"] = [
                ndk_dir + "/sysroot/usr/include:headers",
            ]
            ndk_deps = [
                ndk_dir + "/sysroot:headers",
            ]
            if ctx.fs.exists(ndk_dir + "/lib/clang"):
                ndk_deps.append(ndk_dir + "/lib/clang:headers")
            if ctx.fs.exists(ndk_dir + "/lib64/clang"):
                ndk_deps.append(ndk_dir + "/lib64/clang:headers")
            for b in ["clang", "clang++", "clang.exe", "clang++.exe"]:
                p = ndk_dir + "/bin/" + b
                if ctx.fs.exists(p):
                    ndk_deps.append(p)
            input_deps[ndk_dir + ":headers"] = ndk_deps

    for sysroot in __LINUX_SYSROOTS:
        if ctx.fs.exists(sysroot + "/usr/include"):
            input_deps[sysroot + ":headers"] = [
                sysroot + "/usr/include:headers",
                sysroot + "/usr/lib:headers",
            ]

    for sysroot in __FUCHSIA_SYSROOTS:
        if ctx.fs.exists(sysroot + "/include"):
            input_deps[sysroot + ":headers"] = [
                sysroot + "/include:headers",
            ]

    for sdk_dir in __mac_sdk_dirs(ctx):
        input_deps[sdk_dir + ":headers"] = [
            sdk_dir + ":headers",
        ]

    win_data = __win_toolchain_data(ctx)
    if win_data:
        win_toolchain_dir = win_data["toolchain_dir"]
        win_headers = [
            win_toolchain_dir + ":headers-ci",
        ]
        sdk_version = win_data["sdk_version"]
        if sdk_version:
            case_sensitive_headers = [
                "um/aclapi.h",
                "um/combaseapi.h",
                "um/dbghelp.h",
                "um/iphlpapi.h",
                "um/lm.h",
                "um/memoryapi.h",
                "um/mswsock.h",
                "um/ole2.h",
                "um/pathcch.h",
                "um/processthreadsapi.h",
                "um/psapi.h",
                "um/shellapi.h",
                "um/shlobj.h",
                "um/shlwapi.h",
                "um/tlhelp32.h",
                "um/userenv.h",
                "um/versionhelpers.h",
                "um/wbemidl.h",
                "um/wincrypt.h",
                "um/windows.h",
                "um/winioctl.h",
                "um/winsock2.h",
                "um/ws2tcpip.h",
                "um/werapi.h",
                "shared/afunix.h",
                "shared/bcrypt.h",
                "shared/rpc.h",
                "shared/WinError.h",
                "shared/winerror.h",
            ]
            for rel in case_sensitive_headers:
                p = path.join(win_toolchain_dir, "Windows Kits/10/Include", sdk_version, rel)
                if ctx.fs.exists(p):
                    win_headers.append(p)
        input_deps[win_toolchain_dir + ":headers"] = win_headers

    need_remote_wrapper = runtime.os != "linux" or runtime.arch != "amd64"
    remote_wrapper = "../../../build/rbe/llvm.sh" if need_remote_wrapper else ""
    extra_inputs = list(libcxx_deps)
    if need_remote_wrapper:
        wrapper_inputs = [
            "build/rbe/llvm.sh",
            "flutter/buildtools/linux-x64/clang/bin/llvm",
        ]
        extra_inputs.extend(wrapper_inputs)
        executables = step_config.setdefault("executables", [])
        for exe in wrapper_inputs:
            if exe not in executables:
                executables.append(exe)

    rules = step_config["rules"]
    for prefix_name, cmd_prefix in [
        ("clang", "../../../flutter/buildtools/"),
        ("clang-ndk", "../../third_party/android_tools/ndk/toolchains/llvm/prebuilt/"),
    ]:
        for action in ["cc", "cxx", "objc", "objcxx"]:
            rule = {
                "name": "%s/%s" % (prefix_name, action),
                "action": "(.*_)?%s" % action,
                "command_prefix": cmd_prefix,
                "exclude_input_patterns": ["*.stamp"],
                "remote": True,
                "timeout": "2m",
            }
            if extra_inputs:
                rule["inputs"] = extra_inputs
            if remote_wrapper:
                rule["remote_wrapper"] = remote_wrapper
            rules.append(rule)

    return step_config

clang = module(
    "clang",
    step_config = __step_config,
    filegroups = __filegroups,
    handlers = {},
)
