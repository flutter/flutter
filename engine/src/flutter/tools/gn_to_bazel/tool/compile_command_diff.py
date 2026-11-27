# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Compares the compile commands Bazel and GN issue for the same source files.

The oracle (gn_desc_diff.dart) checks that the converter *reads* GN the way
GN does; this checks what comes out the other end: for every source file
both systems compile, the flags of the two compiler invocations. It is how
the parity classes in the Phase 0 reports were measured.

    cd engine/src
    gn gen out/host_debug_unopt --export-compile-commands
    cd ../..
    bazel aquery --output=jsonproto -c dbg \\
        'mnemonic("CppCompile", deps(//engine/src/flutter/display_list:display_list_unittests))' \\
        > /tmp/aquery.json
    python3 engine/src/flutter/tools/gn_to_bazel/tool/compile_command_diff.py \\
        --aquery=/tmp/aquery.json \\
        --compile-commands=engine/src/out/host_debug_unopt/compile_commands.json \\
        --engine-only

A Mac's and iOS's Objective-C(++) compiles are `ObjcCompile` actions, read
like the others when the query asks for them
(`mnemonic("CppCompile|ObjcCompile", ...)`).

Both sides are normalized to a set of flags per source file (paths relative
to engine/src): output and dependency-file arguments go, include directories
become engine-relative (Bazel's bazel-out mirrors and virtual-include trees
and GN's out/gen directories are the build systems' own mechanics and are
dropped), the sysroot is a placeholder. Of a source Bazel compiles in several
configurations, the command line's compile is compared (a transition's only
when there is no other); actions of Bazel's exec configuration (host tools and
their closure, built with -c opt by design) are left out.
The report lists, per distinct difference, how many files have it and one
example. A second part is about order, which a set cannot show: for the
flags of which the last one on the command line wins (-Wx against -Wno-x,
-fx against -fno-x, -O, -g, -std=, -D), the compiles where a flag both
builds pass ends up differently. With `--warning-groups` (the group tree
tool/clang_warning_groups.py makes from clang's own list) warning flags are
applied as clang applies them, each to every group it controls, so that a
-Wextra after a -Wno-unused-parameter is seen to turn the warning back on;
without it only a flag against its own negation is seen.
`--gn-toolchain=canvaskit` compares one web variant (an aquery of
the module's target, built for its platform) with the GN toolchain of that
name; `--full` prints every class including Bazel-only include
directories, which are mostly decision 14's (a dependency's public config
reaching transitive dependents) and harmless unless header names collide.
"""

import argparse
import collections
import json
import os
import re
import shlex
import sys

# The repositories that are not synced trees of extensions.bzl's table.
# The Debian sysroot: GN's pkg_config() passes its include directories as
# -isystem relative to the source tree; the overlay's libraries as
# `includes`.
OTHER_REPOSITORIES = {
    'sysroot_linux_x64': 'build/linux/debian_bullseye_amd64-sysroot',
}


def synced_repositories():
  """Bazel's name for a synced tree -> its path under engine/src.

  Read off build_defs/repositories/extensions.bzl (`"name": struct(` and the
  `path = "engine/src/..."` under it), so that a tree added there is known
  here: a copy of the table kept by hand lacked the GPU test backends'
  trees, and no file of ANGLE's matched. A repository that is still missing
  is reported once, so that drift shows up in the output rather than as
  silently unmatched files.
  """
  repositories = dict(OTHER_REPOSITORIES)
  extensions = os.path.join(
      os.path.dirname(os.path.abspath(__file__)), *(['..'] * 6), 'build_defs', 'repositories',
      'extensions.bzl'
  )
  name = None
  try:
    with open(extensions, encoding='utf-8') as f:
      for line in f:
        match = re.match(r'\s+"([\w.+-]+)": struct\($', line.rstrip())
        if match:
          name = match.group(1)
          continue
        match = re.match(r'\s+path = "engine/src/([^"]+)",$', line.rstrip())
        if match and name:
          repositories.setdefault(name, match.group(1))
          name = None
  except OSError:
    pass
  return repositories


SYNCED_REPOSITORIES = synced_repositories()
EXTERNAL_PREFIX = 'external/+synced_deps+'
MAIN_PREFIX = 'engine/src/'
SOURCE_SUFFIXES = ('.cpp', '.cc', '.c', '.S', '.mm', '.m')
# Arguments that name outputs or vary per invocation without changing the compile.
SKIP_PREFIXES = (
    '-o', '-MF', '-MD', '-MMD', '-c', '-frandom-seed=', '-fdebug-prefix-map=', '-ffile-prefix-map=',
    '-fmacro-prefix-map=', '-fcoverage-prefix-map='
)

unknown_repositories = set()


def bazel_path(path):
  """An execroot-relative path as an engine/src-relative one."""
  if path.startswith(MAIN_PREFIX):
    return path[len(MAIN_PREFIX):]
  if path.startswith(EXTERNAL_PREFIX):
    rest = path[len(EXTERNAL_PREFIX):]
    name, _, inner = rest.partition('/')
    tree = SYNCED_REPOSITORIES.get(name)
    if tree is None:
      unknown_repositories.add(name)
      return path
    return os.path.join(tree, inner) if inner else tree
  return path


def normalize_include(path, side, out_dir):
  """An include directory as an engine/src-relative path, or None for the
  build systems' own mechanics."""
  if side == 'bazel':
    if path.startswith('bazel-out/') or '_virtual_includes' in path:
      return None
    if path == '.':
      return None  # The execroot, for quoted includes.
    return bazel_path(path.rstrip('/'))
  # GN: relative to the out directory.
  path = os.path.normpath(os.path.join(out_dir, path))
  if path == '.' or path.startswith('out/'):
    return None  # GN's default `//` include dir and gen dirs.
  return path


class Flags(frozenset):
  """The flags of a compile as a set, with the arguments in order (`ordered`)."""
  ordered = ()


def normalize(args, side, out_dir):
  """The set of flags that matter, from a compiler command line (sans compiler).

  The result also has the arguments in their order (`ordered`: outputs and
  the values of -o, -MF, -x, -I and their like left out), for the report
  on the flags of which the last one wins.
  """
  flags = set()
  ordered = []
  skip = False
  for token in args:
    token = token.strip('"').strip("'")
    if skip:
      skip = False
    elif token in ('-o', '-MF', '-c', '-x', '-I', '-isystem', '-iquote', '-include', '--em-config',
                   '-isysroot'):
      skip = token != '-c'
    else:
      ordered.append(token.replace('"', '').replace("'", ''))
  it = iter(args)
  for token in it:
    token = token.strip('"').strip("'")
    if token in ('-o', '-MF', '-c', '-x'):
      next(it, None)
      continue
    if token.startswith(SKIP_PREFIXES):
      continue
    if token.startswith(('-I', '-isystem', '-iquote')):
      for prefix in ('-isystem', '-iquote', '-I'):
        if token.startswith(prefix):
          break
      value = next(it) if token == prefix else token[len(prefix):]
      if prefix == '-iquote':
        continue  # Bazel's own: the execroot, for quoted includes.
      directory = normalize_include(value, side, out_dir)
      # The toolchains add libc++'s directories per language on their own.
      if directory is not None and 'libcxx' not in directory:
        # GN reads expat's config header from the secondary tree; @expat mirrors it.
        directory = directory.replace(
            'flutter/build/secondary/flutter/third_party/expat/expat_config',
            'flutter/third_party/expat/expat_config'
        )
        flags.add('-I ' + directory)
      continue
    # How each build points em++ at the emsdk: GN through `--em-config
    # <file>` (the .emscripten of the prebuilt), Bazel through the SDK's
    # sysroot and the resource directory of its clang. One mechanism each,
    # equivalent by construction; neither is a flag of the compile.
    if token == '--em-config':
      next(it, None)
      continue
    if token.startswith(('--sysroot=', '-resource-dir=')) and 'emsdk' in token:
      continue
    if token.startswith('--sysroot='):
      flags.add('--sysroot=<sysroot>')
      continue
    if token == '-isysroot':
      # An Apple SDK: each build names its own link to the same directory.
      next(it, None)
      flags.add('-isysroot <sdk>')
      continue
    if token.endswith(SOURCE_SUFFIXES) and not token.startswith('-'):
      continue
    if token.startswith('-D'):
      flags.add(token.replace('"', '').replace("'", ''))
      continue
    flags.add(token)
  result = Flags(flags)
  result.ordered = tuple(ordered)
  return result


def bazel_commands(aquery_path):
  """Source file -> flag set, from `bazel aquery --output=jsonproto`, the command line's configuration.

  A query over the whole tree sees a source compiled several times: in the
  configuration the command line asks for, in those the builders' targets
  and the GPU test backends transition into (`-ST-` in the mnemonic), and
  in the exec configuration of the host tools (`-exec-`, -c opt by design).
  The command line's is the one GN's build directory is to be compared
  with; a transition's stands in only for a source compiled nowhere else;
  the exec configuration's are left out.
  """
  with open(aquery_path, encoding='utf-8') as f:
    aquery = json.load(f)
  ranks = {}
  for c in aquery.get('configuration', []):
    mnemonic = c.get('mnemonic', '')
    ranks[c['id']] = 2 if 'exec' in mnemonic else 1 if '-ST-' in mnemonic else 0
  commands = {}
  chosen = {}
  for action in aquery.get('actions', []):
    if action.get('mnemonic') not in ('CppCompile', 'ObjcCompile'):
      continue
    rank = ranks.get(action.get('configurationId'), 0)
    if rank == 2:
      continue
    args = action.get('arguments', [])
    sources = [a for a in args if a.endswith(SOURCE_SUFFIXES) and not a.startswith('-')]
    if not sources:
      continue
    source = bazel_path(sources[-1])
    if source in chosen and chosen[source] < rank:
      continue
    if chosen.get(source) != rank:
      chosen[source] = rank
      commands[source] = {}
    commands[source][_bazel_target(args)] = normalize(args[1:], 'bazel', None)
    COMPILER_FAMILIES[source] = _compiler_family(args[0])
  return commands


def _bazel_target(args):
  """The name of the rule a Bazel compile belongs to, off its object's `_objs/<name>/` directory."""
  for i, arg in enumerate(args):
    if arg == '-o' and i + 1 < len(args):
      path = args[i + 1]
      marker = path.find('/_objs/')
      if marker >= 0:
        return path[marker + len('/_objs/'):].split('/')[0]
  return ''


def _gn_target(argv):
  """The name of the GN target a compile belongs to, off its object's `<target>.<source>.o` name."""
  for i, arg in enumerate(argv):
    if arg == '-o' and i + 1 < len(argv):
      base = os.path.basename(argv[i + 1])
      return base.split('.')[0] if '.' in base else ''
  return ''


def pairs(bazel_compiles, gn_compiles):
  """The compiles of one source to compare, as (bazel flags, gn flags, label).

  A source compiled once on each side pairs regardless of the targets'
  names. One compiled several times on a side (dl_benchmarks.cc for two
  benchmark binaries; ICU's cmemory.cpp for icuuc and the bidi subset) pairs
  by the compiling target's name where both sides have it, the rest by the
  likeness of their flag sets, most alike first and only when they are
  mostly alike (a renamed target; not a target one build has and the other
  does not, such as the bidi subset of ICU that Bazel's host graph carries
  and GN's host build never compiles); the label names the targets where
  it matters. Compiles left unpaired are counted in the summary.
  """
  if len(bazel_compiles) == 1 and len(gn_compiles) == 1:
    return [(next(iter(bazel_compiles.values())), next(iter(gn_compiles.values())), '')]
  result = []
  common = sorted(set(bazel_compiles) & set(gn_compiles))
  for target in common:
    result.append((bazel_compiles[target], gn_compiles[target], target))
  rest_bazel = [t for t in sorted(bazel_compiles) if t not in common]
  rest_gn = [t for t in sorted(gn_compiles) if t not in common]
  candidates = sorted(((_likeness(bazel_compiles[b], gn_compiles[g]), b, g)
                       for b in rest_bazel
                       for g in rest_gn),
                      key=lambda c: (-c[0], c[1], c[2]))
  used_bazel, used_gn = set(), set()
  for likeness, bazel_target, gn_target in candidates:
    if likeness < LIKENESS_FLOOR or bazel_target in used_bazel or gn_target in used_gn:
      continue
    used_bazel.add(bazel_target)
    used_gn.add(gn_target)
    result.append(
        (bazel_compiles[bazel_target], gn_compiles[gn_target], bazel_target + '~' + gn_target)
    )
  return result


# The least share of flags two compiles of a source must share to count as
# the same target's under two names.
LIKENESS_FLOOR = 0.75


def _likeness(a, b):
  """How alike two flag sets are: the share of their union both have."""
  union = len(a | b)
  return len(a & b) / union if union else 1.0


# Source file -> 'emscripten' or 'clang', from the Bazel compile's compiler:
# which of GN's toolchains a source's compile is to be compared with.
COMPILER_FAMILIES = {}


def _compiler_family(compiler):
  """'emscripten' for em++/emcc (and their wrappers), 'clang' otherwise."""
  name = os.path.basename(compiler)
  return 'emscripten' if name.startswith(('em++', 'emcc')) else 'clang'


def gn_commands(compile_commands_path, wanted, toolchain=None):
  """Source file -> flag set, from GN's compile_commands.json, for the files in `wanted`.

  With `toolchain`, only that secondary toolchain's compiles (objects under
  `<toolchain>/obj/`: canvaskit, skwasm, ...), for comparing one web
  variant's Bazel platform with the GN toolchain it stands for.
  """
  with open(compile_commands_path, encoding='utf-8') as f:
    entries = json.load(f)
  commands = {}
  toolchain_of = {}
  for entry in entries:
    directory = entry['directory']
    # The build directory relative to engine/src, from the absolute one:
    # out/<config>, or out/ci/<config> as the builders name theirs.
    marker = directory.rfind('/out/')
    out_dir = directory[marker + 1:] if marker >= 0 else os.path.basename(directory)
    source = os.path.normpath(os.path.join(out_dir, entry['file']))
    if source not in wanted:
      continue
    # The command is a shell line (ninja's): shlex gives the argv the compiler
    # saw, with GN's \" around a define's value read as the quote it is.
    argv = shlex.split(entry['command'])
    # A build may compile a source several times: for the target (the
    # default toolchain, its objects under obj/) and for the host tools (a
    # secondary toolchain's, under clang_x64/obj/), or for the wasm modules
    # (the wasm toolchains', under wasm_*/obj/, with em++) and the host.
    # The entry to compare is the one compiled by the same family of
    # compiler as Bazel's (em++ against em++, clang against clang) and,
    # among those, the default toolchain's -- whichever order they come in --
    # or the named toolchain's alone.
    if _compiler_family(argv[0]) != COMPILER_FAMILIES.get(source, 'clang'):
      continue
    if toolchain is not None:
      if _object_directory(argv) != toolchain + '/obj/':
        continue
    elif source in commands:
      # The default toolchain's compiles displace a secondary toolchain's;
      # a secondary toolchain's never join the default's.
      had_default = toolchain_of.get(source) == 'obj/'
      if had_default and not _default_toolchain(argv):
        continue
      if not had_default and _default_toolchain(argv):
        commands[source] = {}
    toolchain_of[source] = _object_directory(argv)
    commands.setdefault(source, {})[_gn_target(argv)] = normalize(argv[1:], 'gn', out_dir)
  return commands


def _default_toolchain(argv):
  """Whether a GN compile command is the default toolchain's (its object under obj/)."""
  return _object_directory(argv) in ('obj/', None)


def _object_directory(argv):
  """The directory of a GN compile command's object up to and including obj/ (`skwasm/obj/`), or None."""
  for i, arg in enumerate(argv):
    if arg == '-o' and i + 1 < len(argv):
      path = argv[i + 1]
      marker = path.find('obj/')
      return path[:marker + len('obj/')] if marker >= 0 else path
  return None


def by_count(counter):
  """A counter's items, the most frequent first, ties in a fixed order (two runs print the same)."""
  return sorted(counter.items(), key=lambda item: (-item[1], item[0]))


class WarningGroups:
  """clang's warning groups: what a -W option controls besides itself.

  From the file tool/clang_warning_groups.py writes (`children`: group ->
  the groups it controls; `synonym`: a name -> the name it stands for).
  Without a file every name controls itself alone.
  """

  def __init__(self, path=None):
    self._children = {}
    self._synonym = {}
    self._closures = {}
    self.unknown = set()
    self.known = path is not None
    if path is not None:
      with open(path, encoding='utf-8') as f:
        data = json.load(f)
      self._children = data['children']
      self._synonym = data['synonym']

  def controlled(self, name):
    """The groups -W<name> sets: the group itself and every group under it."""
    name = self._synonym.get(name, name)
    found = self._closures.get(name)
    if found is None:
      if self.known and name not in self._children:
        self.unknown.add(name)
      seen = set()
      stack = [name]
      while stack:
        group = stack.pop()
        group = self._synonym.get(group, group)
        if group not in seen:
          seen.add(group)
          stack.extend(self._children.get(group, ()))
      found = frozenset(seen)
      self._closures[name] = found
    return found


def effective(ordered, groups):
  """(family, name) -> the value the compile ends up with.

  Families: `W` (a warning group, on or off), `E` (a group promoted to an
  error or not), `w`, `f`, `m`, `O`, `g`, `std`, `D`. Warning options are
  applied in order, each to every group it controls, as clang applies
  them; of the others the last one wins.
  """
  state = {}

  def set_groups(family, name, value):
    if name == 'everything':
      for key in [key for key in state if key[0] == family]:
        del state[key]
      state[(family, '*')] = value
      return
    for group in groups.controlled(name):
      state[(family, group)] = value

  for token in ordered:
    if token.startswith(('-Wl,', '-Wa,', '-Wp,')):
      continue
    if token == '-w':
      state[('w', '')] = 'on'
    elif token.startswith('-Wno-error='):
      set_groups('E', token[len('-Wno-error='):], 'off')
    elif token.startswith('-Werror='):
      set_groups('E', token[len('-Werror='):], 'on')
      set_groups('W', token[len('-Werror='):], 'on')
    elif token == '-Werror':
      set_groups('E', 'everything', 'on')
    elif token == '-Wno-error':
      set_groups('E', 'everything', 'off')
    elif token.startswith('-Wno-') and len(token) > 5:
      set_groups('W', token[5:], 'off')
    elif token.startswith('-W') and len(token) > 2:
      set_groups('W', token[2:], 'on')
    elif token.startswith('-fno-') and len(token) > 5:
      state[('f', token[5:])] = 'off'
    elif token.startswith('-f') and len(token) > 2:
      name, equals, value = token[2:].partition('=')
      state[('f', name)] = value if equals else 'on'
    elif token.startswith('-mno-') and len(token) > 5:
      state[('m', token[5:])] = 'off'
    elif token.startswith('-m') and len(token) > 2:
      name, equals, value = token[2:].partition('=')
      state[('m', name)] = value if equals else 'on'
    elif token.startswith('-O'):
      state[('O', '')] = token[2:] or '1'
    elif re.fullmatch(r'-g\d?', token):
      state[('g', '')] = token[2:] or '2'
    elif token.startswith('-std='):
      state[('std', '')] = token[5:]
    elif token.startswith('-D') and len(token) > 2:
      name, equals, value = token[2:].partition('=')
      state[('D', name)] = value if equals else '1'
    elif token.startswith('-U') and len(token) > 2:
      state[('D', token[2:])] = '<undefined>'
  return state


def effective_differences(bazel_flags, gn_flags, groups):
  """The (family, name, GN's value, Bazel's value) both builds set and end differently.

  A flag only one build passes is the set comparison's business. Of the
  warning groups that differ, a group under another that differs the same
  way is left out: the outermost one names the difference.
  """
  bazel_state = effective(bazel_flags.ordered, groups)
  gn_state = effective(gn_flags.ordered, groups)
  differing = collections.defaultdict(set)
  for family, name in set(bazel_state) | set(gn_state):
    bazel_value = bazel_state.get((family, name), bazel_state.get((family, '*')))
    gn_value = gn_state.get((family, name), gn_state.get((family, '*')))
    if bazel_value is None or gn_value is None or bazel_value == gn_value:
      continue
    differing[(family, gn_value, bazel_value)].add(name)
  result = []
  for (family, gn_value, bazel_value), names in differing.items():
    for name in names:
      inner = family in ('W', 'E') and any(
          other != name and name in groups.controlled(other) for other in names
      )
      if not inner:
        result.append((family, name, gn_value, bazel_value))
  return sorted(result)


FAMILY_FLAGS = {
    'W': '-W',
    'E': '-Werror=',
    'w': '-w',
    'f': '-f',
    'm': '-m',
    'O': '-O',
    'g': '-g',
    'std': '-std=',
    'D': '-D',
}


def report_effective(compared, groups):
  """Prints where a flag both builds set ends up differently."""
  counts = collections.Counter()
  examples = {}
  sources = set()
  for source, (bazel_flags, gn_flags, target) in compared:
    if target:
      source = f'{source} ({target})'
    for difference in effective_differences(bazel_flags, gn_flags, groups):
      counts[difference] += 1
      examples.setdefault(difference, source)
      sources.add(source)
  print(
      f'compiles where a flag both builds set ends up differently: {len(sources)} of {len(compared)}'
  )
  if not groups.known:
    print(
        '  (without --warning-groups: a group flag against a member, -Wextra after '
        '-Wno-unused-parameter, is not seen)'
    )
  for (family, name, gn_value, bazel_value), count in by_count(counts):
    print(
        f'  {count:5} {FAMILY_FLAGS[family]}{name}: GN {gn_value}, Bazel {bazel_value}, '
        f'e.g. {examples[(family, name, gn_value, bazel_value)]}'
    )
  if groups.unknown:
    print(
        '  warning names not in the group tree (each taken as a group of its own):',
        ', '.join(sorted(groups.unknown))
    )


def main():
  parser = argparse.ArgumentParser(description=__doc__.split('\n', maxsplit=1)[0])
  parser.add_argument('--aquery', required=True, help='bazel aquery --output=jsonproto output')
  parser.add_argument('--compile-commands', required=True, help="GN's compile_commands.json")
  parser.add_argument(
      '--engine-only',
      action='store_true',
      help='first-party files only (under flutter/, not flutter/third_party/)'
  )
  parser.add_argument(
      '--full', action='store_true', help='every difference class, include directories included'
  )
  parser.add_argument(
      '--warning-groups',
      help="clang's warning groups as tool/clang_warning_groups.py writes them, for the "
      'report on the order of warning flags; without it a flag is compared with its own '
      'negation alone'
  )
  parser.add_argument(
      '--gn-toolchain',
      help="compare against this GN secondary toolchain's compiles only (objects under "
      '<name>/obj/): a web variant such as canvaskit or skwasm, with an aquery of the '
      "module built for that variant's platform"
  )
  options = parser.parse_args()

  bazel = bazel_commands(options.aquery)
  gn = gn_commands(options.compile_commands, bazel, toolchain=options.gn_toolchain)
  common = sorted(set(bazel) & set(gn))
  if options.engine_only:
    common = [
        f for f in common if f.startswith('flutter/') and not f.startswith('flutter/third_party/')
    ]
  compared = [(source, pair) for source in common for pair in pairs(bazel[source], gn[source])]
  unpaired_bazel = sum(len(bazel[source]) for source in common) - len(compared)
  unpaired_gn = sum(len(gn[source]) for source in common) - len(compared)
  print(
      f'bazel {sum(len(c) for c in bazel.values())} compiles of {len(bazel)} sources, '
      f'gn matched {len(gn)} sources, compared {len(compared)} compiles' + (
          f' (unpaired: {unpaired_bazel} Bazel, {unpaired_gn} GN)'
          if unpaired_bazel or unpaired_gn else ''
      )
  )
  if unknown_repositories:
    print(
        'repositories not in SYNCED_REPOSITORIES (their files did not match):',
        ', '.join(sorted(unknown_repositories))
    )

  identical = 0
  identical_modulo_includes = 0
  bazel_only_defines = collections.Counter()
  classes = collections.Counter()
  class_examples = {}
  full_classes = collections.Counter()
  full_examples = {}
  for source, (bazel_flags, gn_flags, target) in compared:
    if target:
      source = f'{source} ({target})'
    if bazel_flags == gn_flags:
      identical += 1
      identical_modulo_includes += 1
      continue
    only_bazel = bazel_flags - gn_flags
    only_gn = gn_flags - bazel_flags
    full_key = (tuple(sorted(only_bazel)), tuple(sorted(only_gn)))
    full_classes[full_key] += 1
    full_examples.setdefault(full_key, source)
    only_bazel = {x for x in only_bazel if not x.startswith('-I ')}
    if not only_bazel and not only_gn:
      identical_modulo_includes += 1
      continue
    for flag in only_bazel:
      if flag.startswith('-D'):
        bazel_only_defines[flag] += 1
    key = (tuple(sorted(x for x in only_bazel if not x.startswith('-D'))), tuple(sorted(only_gn)))
    if key != ((), ()):
      classes[key] += 1
      class_examples.setdefault(key, source)

  print(f'identical flag sets: {identical} of {len(compared)}')
  print(
      f'identical ignoring Bazel-only -I directories: {identical_modulo_includes} of {len(compared)}'
  )
  print('Bazel-only defines (files):')
  for define, count in by_count(bazel_only_defines):
    print(f'  {count:5} {define}')
  print('other differences:')
  for key, count in by_count(classes)[:25]:
    print(f'  {count} files, e.g. {class_examples[key]}')
    for flag in key[0]:
      print(f'     only Bazel: {flag}')
    for flag in key[1]:
      print(f'     only GN   : {flag}')
  report_effective(compared, WarningGroups(options.warning_groups))
  if not options.full:
    return 0
  print('\nevery difference class:')
  for key, count in by_count(full_classes):
    print(f'\n{count} files, e.g. {full_examples[key]}')
    for flag in key[0]:
      print(f'   only Bazel: {flag}')
    for flag in key[1]:
      print(f'   only GN   : {flag}')
  return 0


if __name__ == '__main__':
  sys.exit(main())
