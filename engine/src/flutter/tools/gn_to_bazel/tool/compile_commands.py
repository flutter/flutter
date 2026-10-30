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
and as a `command` string (what tools/clang_tidy reads). Paths are written
to last: a path under `external/` -- a repository's headers, the sysroot,
the compiler -- is spelled through the output base rather than the
execution root, whose `external/` symlinks Bazel replants per command for
that command's repositories alone; and two are written as the checkout
spells them: the source (`file`), so that tools/clang_tidy's own file
selection -- the files changed in git, or every file under flutter/, with
anything under a `third_party` directory skipped -- matches the entries,
as it does for GN's file; and the compiler, so that the toolchain's
`clang-tidy` is found beside it (`.../buildtools/linux-x64/clang/bin/
clang++`; the repository symlink resolved, the name kept, since the binary
is a multicall that reads its name).

A source compiled in several configurations gets the command of the one
the command line names -- the target configuration of `--config=<name>`,
whose output directory carries no transition suffix (`k8-opt`) -- before
a transition's (`k8-opt-ST-<hash>`: a wasm module's compile of a Skia
source under `module_platform_transition`, an API-26 dependency's under
gn_action's platform_deps), and either before the exec configuration's
(`k8-opt-exec-ST-<hash>`: a host tool's, built -c opt); one compiled for
the exec configuration alone (impellerc, the shader compiler, built only as
a tool) gets that. clang-tidy reads the one entry per file, and must find
the build's own compiler flags there rather than em++'s.
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


def _info(bazel, workspace):
  """`bazel info`'s execution_root and output_base."""
  result = subprocess.run([bazel, "info"],
                          cwd=workspace,
                          check=True,
                          capture_output=True,
                          text=True)
  info = dict(line.split(": ", 1) for line in result.stdout.splitlines() if ": " in line)
  return info["execution_root"], info["output_base"]


_EXTERNAL = "external/"

# Flags that take a path in the same argument; `-isystem external/...` and
# `-iquote external/...` come as two arguments, the second a bare path.
_PATH_FLAGS = ("-I", "-isystem", "-iquote", "-idirafter", "--sysroot=", "-include", "-imacros")


def _lasting_path(execution_root, output_base, relative):
  """`relative`, a path the action spells from the execution root, as a path that outlives the command.

    Bazel plants `<execution root>/external/<repository>` symlinks per
    command, for the repositories that command uses (48 of 210 after a test
    run here), so a path through them is good only until the next command;
    the repositories themselves live under `<output base>/external/`, which
    lasts. Everything else under the execution root (the main repository's
    directories, bazel-out) stays put.
    """
  if relative.startswith(_EXTERNAL):
    return os.path.join(output_base, relative)
  return os.path.join(execution_root, relative)


def _lasting_argument(argument, execution_root, output_base):
  """`argument` with a path under external/ spelled through the output base (see _lasting_path)."""
  for prefix in ("",) + _PATH_FLAGS:
    if argument.startswith(prefix + _EXTERNAL):
      return prefix + _lasting_path(execution_root, output_base, argument[len(prefix):])
  return argument


def _checkout_path(execution_root, output_base, relative):
  """`relative` (a path from the execution root) as the checkout spells it.

    Sources of the main repository and of the synced repositories are
    symlinks (the execution root's, or a repository's directory of them) to
    the checkout; generated files under bazel-out have no other spelling and
    come back absolute under the execution root.
    """
  return os.path.realpath(_lasting_path(execution_root, output_base, relative))


def _compiler_path(execution_root, output_base, compiler):
  """The compiler's path with its repository symlink resolved and its name kept.

    `external/<clang repository>/bin` is a symlink to the prebuilt's `bin`;
    inside it, `clang++` is a symlink to the `llvm` multicall binary, which
    reads its name, so only the directory is resolved.
    """
  directory, name = os.path.split(compiler)
  return os.path.join(os.path.realpath(_lasting_path(execution_root, output_base, directory)), name)


def configuration_ranks(aquery):
  """Configuration id -> 0 for the command line's own configuration, 1 for a transition's, 2 for an exec one.

    The aquery's `configuration` list names each with its output directory
    (`mnemonic`): the top-level configuration has none of the suffixes,
    a Starlark transition's carries `-ST-<hash>`, and an exec configuration
    `-exec-` (and `isTool`).
    """
  ranks = {}
  for c in aquery.get("configuration", []):
    mnemonic = c.get("mnemonic", "")
    if c.get("isTool") or "exec" in mnemonic:
      ranks[c["id"]] = 2
    elif "-ST-" in mnemonic:
      ranks[c["id"]] = 1
    else:
      ranks[c["id"]] = 0
  return ranks


def compile_commands(aquery, execution_root, output_base):
  """The compile_commands.json entries of an aquery result: source -> entry, the command line's configuration first."""
  ranks = configuration_ranks(aquery)
  best = {}
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
    # A transition's configuration before an exec one's; the command
    # line's own before both (configuration_ranks); an unlisted one last.
    rank = ranks.get(action.get("configurationId"), 3)
    source = sources[-1]
    if source in best and best[source][0] <= rank:
      continue
    arguments[0] = _compiler_path(execution_root, output_base, arguments[0])
    arguments[1:] = [_lasting_argument(a, execution_root, output_base) for a in arguments[1:]]
    best[source] = (
        rank,
        {
            "directory": execution_root,
            "file": _checkout_path(execution_root, output_base, source),
            "arguments": arguments,
            "command": shlex.join(arguments),
        },
    )
  return [best[source][1] for source in sorted(best)]


def main(argv):
  parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
  parser.add_argument(
      "--out", required=True, help="The build directory to write compile_commands.json into."
  )
  parser.add_argument("--config", help="The Bazel configuration (--config=<name>) the build uses.")
  parser.add_argument("--bazel", help="The bazel (or bazelisk) binary; default: the one on PATH.")
  parser.add_argument(
      "--workspace",
      default=os.path.normpath(
          os.path.join(os.path.dirname(os.path.abspath(__file__)), *[".."] * 6)
      ),
      help="The Bazel workspace (the checkout's root).",
  )
  parser.add_argument(
      "targets",
      nargs="*",
      default=["//engine/src/flutter/..."],
      help="The targets whose compiles to list."
  )
  args = parser.parse_args(argv)
  bazel = _bazel(args.bazel)
  aquery = _aquery(bazel, args.workspace, args.config, args.targets)
  execution_root, output_base = _info(bazel, args.workspace)
  entries = compile_commands(aquery, execution_root, output_base)
  os.makedirs(args.out, exist_ok=True)
  path = os.path.join(args.out, "compile_commands.json")
  with open(path, "w", encoding="utf-8") as f:
    json.dump(entries, f, indent=2)
    f.write("\n")
  print(f"{len(entries)} compile commands into {path}")
  return 0


if __name__ == "__main__":
  sys.exit(main(sys.argv[1:]))
