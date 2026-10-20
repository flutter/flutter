#!/usr/bin/env python3
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Writes a build directory's compile_commands.json from `bazel aquery`.

GN writes `engine/src/out/<build>/compile_commands.json` on request
(`--export-compile-commands`; tools/gn passes it for the clang-tidy builder),
and tools/clang_tidy and clangd read it. Bazel has no such file; its action
graph has the same information. This tool asks `bazel aquery` for every
C/C++ compile in the dependency closure of the targets named (the engine by
default) and writes the file into the build directory `install` lays out,
in the format clang's tools read: one entry per source with the compiler
command line as the action runs it, from the execution root, so that the
paths in it -- external repositories, generated headers under bazel-out --
resolve as they do for the build.

    bazel build --config=host_debug_unopt //engine/src/flutter/...
    python3 engine/src/flutter/tools/gn_to_bazel/tool/compile_commands.py \\
        --out=engine/src/out/host_debug_unopt_bazel --config=host_debug_unopt

Each entry carries the command both as `arguments` (what clangd prefers)
and as a `command` string (what tools/clang_tidy reads). Two paths are
written as the checkout spells them rather than as the execution root does:
the source (`file`), so that tools/clang_tidy's own file selection -- the
files changed in git, or every file under flutter/, with anything under a
`third_party` directory skipped -- matches the entries, as it does for
GN's file; and the compiler, so that the toolchain's `clang-tidy` is found
beside it (`.../buildtools/linux-x64/clang/bin/clang++`; the repository
symlink resolved, the name kept, since the binary is a multicall that reads
its name).

A source compiled in both the target configuration and the exec
configuration (a host tool's, built -c opt) gets the target's command;
one compiled for the exec configuration alone (impellerc, the shader
compiler, built only as a tool) gets that.
"""

import argparse
import json
import os
import shlex
import shutil
import subprocess
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import compile_command_diff  # pylint: disable=wrong-import-position


def _bazel(option):
    if option:
        return option
    for name in ("bazelisk", "bazel"):
        found = shutil.which(name)
        if found:
            return found
    sys.exit("no bazel on PATH; pass --bazel")


def _aquery(bazel, workspace, config, targets):
    query = 'mnemonic("CppCompile", deps(%s))' % " + ".join(targets)
    command = [bazel, "aquery", "--output=jsonproto"]
    if config:
        command.append("--config=" + config)
    command.append(query)
    result = subprocess.run(command, cwd=workspace, check=True, capture_output=True, text=True)
    return json.loads(result.stdout)


def _execution_root(bazel, workspace):
    result = subprocess.run(
        [bazel, "info", "execution_root"], cwd=workspace, check=True, capture_output=True, text=True
    )
    return result.stdout.strip()


def _checkout_path(execution_root, relative):
    """`relative` (a path from the execution root) as the checkout spells it.

    Sources of the main repository and of the synced repositories are
    symlinks (the execution root's, or a repository's directory of them) to
    the checkout; generated files under bazel-out have no other spelling and
    come back absolute under the execution root.
    """
    return os.path.realpath(os.path.join(execution_root, relative))


def _compiler_path(execution_root, compiler):
    """The compiler's path with its repository symlink resolved and its name kept.

    `external/<clang repository>/bin` is a symlink to the prebuilt's `bin`;
    inside it, `clang++` is a symlink to the `llvm` multicall binary, which
    reads its name, so only the directory is resolved.
    """
    directory, name = os.path.split(compiler)
    return os.path.join(os.path.realpath(os.path.join(execution_root, directory)), name)


def compile_commands(aquery, execution_root):
    """The compile_commands.json entries of an aquery result: source -> entry, target configuration first."""
    exec_configurations = {
        c["id"] for c in aquery.get("configuration", []) if "exec" in c.get("mnemonic", "")
    }
    target_entries = {}
    exec_entries = {}
    for action in aquery.get("actions", []):
        if action.get("mnemonic") != "CppCompile":
            continue
        arguments = list(action.get("arguments", []))
        sources = [
            a for a in arguments
            if a.endswith(compile_command_diff.SOURCE_SUFFIXES) and not a.startswith("-")
        ]
        if not sources:
            continue
        arguments[0] = _compiler_path(execution_root, arguments[0])
        entry = {
            "directory": execution_root,
            "file": _checkout_path(execution_root, sources[-1]),
            "arguments": arguments,
            "command": shlex.join(arguments),
        }
        if action.get("configurationId") in exec_configurations:
            exec_entries.setdefault(sources[-1], entry)
        else:
            target_entries.setdefault(sources[-1], entry)
    entries = dict(exec_entries)
    entries.update(target_entries)
    return [entries[source] for source in sorted(entries)]


def main(argv):
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--out", required=True, help="The build directory to write compile_commands.json into.")
    parser.add_argument("--config", help="The Bazel configuration (--config=<name>) the build uses.")
    parser.add_argument("--bazel", help="The bazel (or bazelisk) binary; default: the one on PATH.")
    parser.add_argument(
        "--workspace",
        default=os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), *[".."] * 6)),
        help="The Bazel workspace (the checkout's root).",
    )
    parser.add_argument(
        "targets", nargs="*", default=["//engine/src/flutter/..."], help="The targets whose compiles to list."
    )
    args = parser.parse_args(argv)
    bazel = _bazel(args.bazel)
    aquery = _aquery(bazel, args.workspace, args.config, args.targets)
    entries = compile_commands(aquery, _execution_root(bazel, args.workspace))
    os.makedirs(args.out, exist_ok=True)
    path = os.path.join(args.out, "compile_commands.json")
    with open(path, "w", encoding="utf-8") as f:
        json.dump(entries, f, indent=2)
        f.write("\n")
    print(f"{len(entries)} compile commands into {path}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
