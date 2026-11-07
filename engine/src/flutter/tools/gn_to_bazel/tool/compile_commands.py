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

For a build directory tools/gn --bazel wrote (bazel.json in it; see
build/bazel/bazel_ci.py), `--build-directory=<dir>` stands in for `--out`,
`--config` and `--bazel`: the `bazel info` and the aquery run as the
directory's description says -- its bazelisk and startup options,
`--config=ci`, its build options, configuration and options
(bazel_ci.described_command) -- on the same server, in the same output
base and configuration as the build itself, so that the action graph
queried is the one built (a transition's output directory is named by a
hash of its options). `--build`, with it, builds the targets whose compiles
the database lists (their labels in `compile_commands.targets` beside it),
with every C/C++ source and header among their outputs downloaded:
clang-tidy opens the generated headers a command includes, and a build
whose actions ran remotely (--config=rbe) keeps its intermediate outputs
remote by default (--remote_download_toplevel).

    python3 engine/src/flutter/tools/gn_to_bazel/tool/compile_commands.py \\
        --build-directory=engine/src/out/ci/host_debug_clang_tidy --build

With a build directory the query's universe is the root group
//engine/src/flutter:flutter -- GN's default target, what `ninja` with no
target built for the clang-tidy builders and what GN's database listed,
the platform's unittests included -- rather than every target under
//engine/src/flutter/..., which reaches targets no build of the platform
makes (a host tool configured for Android, whose compile fails under the
NDK's flags; a host-only test's).

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
the command line names -- the configuration of `--config=<name>`, whose
output directory `bazel-bin` names (`linux_x64_debug-opt`) -- before a
transition of it (`linux_x64_debug-opt-ST-<hash>`: a setting changed, the
platform kept). Any other configuration's compile -- the exec one's (a host
tool's, impellerc, under the host's flags), another platform's or runtime
mode's (the profile and release engines a debug build's install reaches,
the Android ones a host build's tests do, the wasm modules' em++ compiles
of Skia's sources) -- is left out: it belongs to that build's database, as
GN's other toolchains' compiles did to theirs; its generated headers are
not this build's to fetch; and its owner could not be built in this
build's configuration. clang-tidy reads the one entry per file, and must
find the build's own compiler flags there. A source no clang compiles --
skwasm's, and what else only a wasm module's em++.sh or emcc.sh builds --
gets no entry either: tools/clang_tidy derives clang-tidy from the
compiler's path (`clang/bin/clang++` -> `clang/bin/clang-tidy`) and has
none for those. How many are left out, and why, is printed.
"""

import argparse
import json
import os
import re
import shlex
import shutil
import subprocess
import sys

_TOOL_DIR = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, _TOOL_DIR)
import compile_command_diff  # pylint: disable=wrong-import-position

# build/bazel/bazel_ci.py: the description of a build directory tools/gn
# --bazel wrote (bazel.json) and the Bazel command lines of its build.
sys.path.insert(0, os.path.join(_TOOL_DIR, "..", "..", "..", "build", "bazel"))
import bazel_ci  # pylint: disable=wrong-import-position


def _bazel(option):
  if option:
    return option
  for name in ("bazelisk", "bazel"):
    found = shutil.which(name)
    if found:
      return found
  sys.exit("no bazel on PATH; pass --bazel")


class Bazel:
  """The Bazel commands of this run: their command lines, working directory and environment.

    Of a build directory tools/gn --bazel wrote (`--build-directory`), what
    its description (bazel.json) says: `bazelisk <startup options>
    <command> --config=ci <build options> --config=<name> <options>
    <arguments>` (bazel_ci.described_command) from the checkout, with the
    description's environment -- the server, output base and
    configuration of the build's own install and tests. Otherwise
    (`--config`, `--bazel`): `bazel <command> [--config=<name>]
    <arguments>` from the workspace.
    """

  def __init__(self, bazel=None, workspace=None, config=None, description=None):
    self._bazel = bazel
    self._workspace = workspace
    self._config = config
    self._description = description

  @classmethod
  def of_build_directory(cls, out_dir):
    """The Bazel of the build directory `out_dir`; exits unless tools/gn --bazel wrote it."""
    description = bazel_ci.read_build_directory(out_dir)
    if description is None:
      sys.exit(
          f"{out_dir} has no {bazel_ci.BAZEL_JSON}: not a build directory tools/gn --bazel wrote"
      )
    return cls(workspace=description["repo_root"], description=description)

  def command_line(self, command, arguments):
    """The command line of Bazel `command` with `arguments`."""
    if self._description is not None:
      return bazel_ci.described_command(self._description, command, arguments)
    options = ["--config=" + self._config] if self._config else []
    return [self._bazel, command] + options + list(arguments)

  def run(self, command, arguments, capture_output=False):
    """Runs Bazel `command` with `arguments`; its stdout when captured. Exits when it fails.

      stderr -- Bazel's progress and errors -- goes to this process's either
      way, for the log.
      """
    command_line = self.command_line(command, arguments)
    print(shlex.join(command_line), flush=True)
    environment = dict(os.environ)
    if self._description is not None:
      environment.update(self._description["environment"])
      bazel_ci.write_wrap_rbe_env()
    result = subprocess.run(
        command_line,
        cwd=self._workspace,
        env=environment,
        stdout=subprocess.PIPE if capture_output else None,
        text=True,
        check=False,
    )
    if result.returncode != 0:
      sys.exit(f"bazel {command} failed with exit status {result.returncode}")
    return result.stdout


def _aquery(bazel, targets):
  query = 'mnemonic("CppCompile", deps(%s))' % " + ".join(targets)
  return json.loads(bazel.run("aquery", ["--output=jsonproto", query], capture_output=True))


def _info(bazel):
  """`bazel info`'s execution_root, output_base, and the build's own output directory name.

    The last is the `<mnemonic>` of `bazel-bin`'s `bazel-out/<mnemonic>/bin`
    (`linux_x64_debug-opt`): the configuration the command line names, as
    the aquery's `configuration` list spells it.
    """
  output = bazel.run("info", [], capture_output=True)
  info = dict(line.split(": ", 1) for line in output.splitlines() if ": " in line)
  parts = info["bazel-bin"].split("/")
  mnemonic = parts[parts.index("bazel-out") + 1] if "bazel-out" in parts else ""
  return info["execution_root"], info["output_base"], mnemonic


# GN's default target, converted: the root group, whose closure under a
# configuration is what `ninja` with no target built and GN's compile
# database listed (the unittests among them, by platform).
ROOT_GROUP = "//engine/src/flutter:flutter"

# What `--build` downloads of a remote build's outputs besides the top-level
# ones (Bazel's default, --remote_download_toplevel): the generated sources
# and headers a compile command names, which clang-tidy opens on disk.
GENERATED_SOURCE_REGEX = r".*\.(h|hh|hpp|inc|ipp|def|c|cc|cpp|cxx|m|mm)$"


def _build(bazel, owners, out_dir):
  """Builds the targets whose compiles the database lists, their generated sources and headers downloaded.

  Building the owners of the compile commands (not the query's patterns:
  those reach the Dart, Java and web targets too, a whole test tree for
  nothing) runs every compile the database names, and so builds every
  generated header those compiles include; GENERATED_SOURCE_REGEX fetches
  the ones remote actions made. The labels go through a file
  (`compile_commands.targets`, beside the database), since there are
  hundreds; --build_manual_tests, since the query's `deps(...)` reaches
  the manual tests (the benchmarks) and a pattern file's wildcards would
  not; --skip_incompatible_explicit_targets, since an owner compiled under
  a transition's configuration alone (an Android library reached from a
  host build) may not be buildable in the build's own, and its entries
  stand as GN's other toolchains' did; and the compiles alone
  (--output_groups=compilation_outputs), not the links: a host-only test
  reached by an Android build's graph compiles under it and does not link
  (-lpthread), and the database has no use for the link.
  """
  pattern_file = os.path.join(out_dir, "compile_commands.targets")
  with open(pattern_file, "w", encoding="utf-8") as f:
    f.write("".join(owner + "\n" for owner in owners))
  bazel.run(
      "build",
      [
          "--remote_download_regex=" + GENERATED_SOURCE_REGEX,
          "--build_manual_tests",
          "--skip_incompatible_explicit_targets",
          "--output_groups=compilation_outputs",
          "--target_pattern_file=" + pattern_file,
      ],
  )


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


# The compilers tools/clang_tidy can lint with: a toolchain's clang or
# clang++ under its `clang/bin/`, where the tool's `_pathRegex` finds the
# compiler and `clang-tidy` beside it. Emscripten's em++.sh and emcc.sh (a
# wasm module's transition) and the Mac remote-compile wrapper are not.
_CLANG = re.compile(r"clang/bin/clang(\+\+)?$")


def configuration_ranks(aquery, own):
  """Configuration id -> 0 for the build's own configuration, 1 for a transition of it; else None.

    The aquery's `configuration` list names each with its output directory
    (`mnemonic`); `own` is the build's (_info). A transition of it carries
    `-ST-<hash>` after it (a setting changed, the platform kept). Any other
    configuration -- the exec one (the host tools: impellerc, built for the
    machine, under the host's flags), another platform's or runtime mode's
    (the profile and release engines a debug build's install reaches, the
    Android ones a host build's tests do) -- is none of these: its compiles
    belong to another build's database, as GN's other toolchains' did to
    its, its generated headers are not this build's to fetch, and its
    owners could not be built in this build's configuration (impellerc under
    the NDK's flags fails on nlohmann's literal operators).
    """
  ranks = {}
  for c in aquery.get("configuration", []):
    mnemonic = c.get("mnemonic", "")
    if c.get("isTool") or "-exec" in mnemonic:
      ranks[c["id"]] = None
    elif mnemonic == own:
      ranks[c["id"]] = 0
    elif mnemonic.startswith(own + "-ST-"):
      ranks[c["id"]] = 1
    else:
      ranks[c["id"]] = None
  return ranks


def _hoisted(arguments):
  """`arguments` with the virtual include directories searched before the external repositories' roots, for quoted includes.

    The command runs from the execution root, where every external
    repository is whole, not the sandbox's view of the action's inputs; and
    Bazel searches the repositories' roots (`-iquote external/<repo>`) before
    the `-I` directories. A quoted include of an engine-root-relative path
    (`"third_party/benchmark/include/benchmark/benchmark.h"`) that the
    sandbox resolves through a virtual include directory (the mapping a
    `cc_library` declares, `_virtual_includes/`) can, from the whole
    execution root, land in a repository that vendors a tree of that name
    (BoringSSL's third_party/benchmark) -- an older copy, or one whose own
    includes are not on the path. The virtual include directories are
    repeated as `-iquote`, ahead of the repositories' roots: what they map
    is declared, so the sandbox resolves the same way.
    """
  virtual = [a[2:] for a in arguments if a.startswith("-I") and "/_virtual_includes/" in a]
  if not virtual:
    return arguments
  for i, a in enumerate(arguments):
    if a == "-iquote" and i + 1 < len(arguments) and _EXTERNAL_ROOT.search(arguments[i + 1]):
      hoisted = [w for d in virtual for w in ("-iquote", d)]
      return arguments[:i] + hoisted + arguments[i:]
  return arguments


# An external repository's root as a quote include directory: `external/<repo>`
# (spelled through the output base, _lasting_path) or its bazel-out twin.
_EXTERNAL_ROOT = re.compile(r"(^|/)external/[^/]+$")

# An include directory inside a sysroot repository (the Linux sysroot's
# /usr/include/gtk-3.0 and the like; its bazel-out twin too).
_SYSROOT_INCLUDE = re.compile(r"(^|/)external/[^/]*sysroot[^/]*/")


def _system_includes(arguments):
  """`arguments` with the sysroot's include directories as `-isystem`, as GN's compile commands have them.

    The toolchain writes every `includes` as `-I` (the engine's own have to
    keep their order ahead of the system's), the sysroot repository's
    among them; GN's commands name the same directories, pkg-config's
    under `--sysroot`, with `-isystem`. clang-tidy keeps quiet about a
    system header's macro expanded in the engine's code (g_clear_object's
    `_pp`, cppcoreguidelines-pro-type-member-init) and says so of a `-I`
    directory's; the lint reads them as GN's did.
    """
  return [
      "-isystem" + a[2:] if a.startswith("-I") and _SYSROOT_INCLUDE.search(a[2:]) else a
      for a in arguments
  ]


def compile_commands(aquery, execution_root, output_base, own_configuration):
  """The compile_commands.json entries of an aquery result, the sources left out, the entries' owners.

    Source -> entry, the build's own configuration first (configuration_ranks;
    a compile under another platform's or mode's alone leaves the source
    out: it is another build's); of the sources whose every compile is by a
    compiler other than a clang (_CLANG), the compilers' names: those get no
    entry, since the lint tool has no clang-tidy for them; and the labels of
    the targets whose compiles the entries are, sorted (what `--build`
    builds).
    """
  ranks = configuration_ranks(aquery, own_configuration)
  labels = {t["id"]: t["label"] for t in aquery.get("targets", []) if "id" in t and "label" in t}
  best = {}
  other_compilers = {}
  other_configurations = {}
  mnemonics = {c["id"]: c.get("mnemonic", "") for c in aquery.get("configuration", [])}
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
    source = sources[-1]
    # The build's own configuration before a transition of it
    # (configuration_ranks); another configuration's not at all.
    rank = ranks.get(action.get("configurationId"))
    if rank is None:
      other_configurations.setdefault(source, set()).add(mnemonics.get(action.get("configurationId"), "?"))
      continue
    if source in best and best[source][0] <= rank:
      continue
    compiler = _compiler_path(execution_root, output_base, arguments[0])
    if not _CLANG.search(compiler):
      other_compilers[source] = os.path.basename(compiler)
      continue
    arguments[0] = compiler
    arguments[1:] = [_lasting_argument(a, execution_root, output_base) for a in arguments[1:]]
    arguments = _system_includes(_hoisted(arguments))
    best[source] = (
        rank,
        {
            "directory": execution_root,
            "file": _checkout_path(execution_root, output_base, source),
            "arguments": arguments,
            "command": shlex.join(arguments),
        },
        labels.get(action.get("targetId")),
    )
  left_out = {source: name for source, name in other_compilers.items() if source not in best}
  others = set()
  for source, names in other_configurations.items():
    if source not in best and source not in left_out:
      left_out[source] = "another configuration"
      others.update(names)
  if others:
    print(
        f"{sum(1 for v in left_out.values() if v == 'another configuration')} sources compiled "
        f"under other configurations alone ({', '.join(sorted(others))}): another build's database"
    )
  owners = sorted({best[source][2] for source in best if best[source][2]})
  return [best[source][1] for source in sorted(best)], left_out, owners


def main(argv):
  parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
  parser.add_argument(
      "--out",
      help="The build directory to write compile_commands.json into "
      "(default with --build-directory: that directory).",
  )
  parser.add_argument("--config", help="The Bazel configuration (--config=<name>) the build uses.")
  parser.add_argument("--bazel", help="The bazel (or bazelisk) binary; default: the one on PATH.")
  parser.add_argument(
      "--workspace",
      help="The Bazel workspace (the checkout's root); default: this checkout.",
  )
  parser.add_argument(
      "--build-directory",
      help="A build directory tools/gn --bazel wrote: its bazel.json says which bazelisk, "
      "options and configuration the build used, and this runs Bazel the same way. "
      "Stands in for --out, --config, --bazel and --workspace.",
  )
  parser.add_argument(
      "--build",
      action="store_true",
      help="With --build-directory: build the targets whose compiles the database lists, "
      "their generated sources and headers downloaded, so that the files the compile "
      "commands include exist.",
  )
  parser.add_argument(
      "targets",
      nargs="*",
      help="The targets whose compiles to list (default: every target under "
      "//engine/src/flutter/...; with --build-directory, the root group "
      "//engine/src/flutter:flutter -- GN's default target, what `ninja` with no target builds, "
      "which is what the builder's lint read: the wildcard reaches targets no build of the "
      "platform makes, a host tool configured for Android).",
  )
  args = parser.parse_args(argv)
  if not args.targets:
    args.targets = [ROOT_GROUP] if args.build_directory else ["//engine/src/flutter/..."]
  if args.build_directory:
    if args.config or args.bazel or args.workspace:
      parser.error(
          "--build-directory's bazel.json says what --config, --bazel and --workspace would"
      )
    out_dir = os.path.abspath(args.build_directory)
    bazel = Bazel.of_build_directory(out_dir)
    out = args.out or out_dir
  else:
    if args.build:
      parser.error("--build needs --build-directory")
    if not args.out:
      parser.error("--out is required without --build-directory")
    workspace = args.workspace or os.path.normpath(os.path.join(_TOOL_DIR, *[".."] * 6))
    bazel = Bazel(_bazel(args.bazel), workspace, args.config)
    out = args.out
  aquery = _aquery(bazel, args.targets)
  execution_root, output_base, own_configuration = _info(bazel)
  entries, left_out, owners = compile_commands(aquery, execution_root, output_base, own_configuration)
  os.makedirs(out, exist_ok=True)
  if args.build:
    _build(bazel, owners, out)
  path = os.path.join(out, "compile_commands.json")
  with open(path, "w", encoding="utf-8") as f:
    json.dump(entries, f, indent=2)
    f.write("\n")
  compilers = sorted({v for v in left_out.values() if v != "another configuration"})
  if compilers:
    print(
        f"{sum(1 for v in left_out.values() if v != 'another configuration')} sources left out, "
        f"compiled by {', '.join(compilers)} alone: tools/clang_tidy finds clang-tidy beside a "
        "clang/bin/clang++ and has none for them"
    )
  print(f"{len(entries)} compile commands into {path}")
  return 0


if __name__ == "__main__":
  sys.exit(main(sys.argv[1:]))
