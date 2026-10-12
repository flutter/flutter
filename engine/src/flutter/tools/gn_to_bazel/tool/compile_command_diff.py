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

Both sides are normalized to a set of flags per source file (paths relative
to engine/src): output and dependency-file arguments go, include directories
become engine-relative (Bazel's bazel-out mirrors and virtual-include trees
and GN's out/gen directories are the build systems' own mechanics and are
dropped), the sysroot is a placeholder. Actions of Bazel's exec configuration
(host tools and their closure, built with -c opt by design) are left out.
The report lists, per distinct difference, how many files have it and one
example; `--full` prints every class including Bazel-only include
directories, which are mostly decision 14's (a dependency's public config
reaching transitive dependents) and harmless unless header names collide.
"""

import argparse
import collections
import json
import os
import shlex
import sys

# Bazel's name for a synced tree -> its path under engine/src. Mirrors the
# source trees of build/bazel/extensions.bzl (the toolchains are not compiled
# code and are left out); a repository missing here is reported once, so that
# drift shows up in the output rather than as silently unmatched files.
SYNCED_REPOSITORIES = {
    'abseil-cpp': 'third_party/abseil-cpp',
    'boringssl': 'flutter/third_party/boringssl/src',
    'dart': 'flutter/third_party/dart',
    'expat': 'flutter/third_party/expat',
    'flatbuffers': 'flutter/third_party/flatbuffers',
    'freetype2': 'flutter/third_party/freetype2',
    'glslang': 'flutter/third_party/vulkan-deps/glslang/src',
    'googletest': 'flutter/third_party/googletest',
    'harfbuzz': 'flutter/third_party/harfbuzz',
    'icu': 'flutter/third_party/icu',
    'inja': 'flutter/third_party/inja',
    'json': 'flutter/third_party/json',
    'libcxx': 'flutter/third_party/libcxx',
    'libcxxabi': 'flutter/third_party/libcxxabi',
    'libjpeg-turbo': 'flutter/third_party/libjpeg-turbo',
    'libpng': 'flutter/third_party/libpng',
    'libtess2': 'flutter/third_party/libtess2',
    'libwebp': 'flutter/third_party/libwebp',
    'rapidjson': 'flutter/third_party/rapidjson',
    'llvm_libc': 'flutter/third_party/llvm_libc',
    're2': 'flutter/third_party/re2',
    'shaderc': 'flutter/third_party/shaderc',
    'skia': 'flutter/third_party/skia',
    'spirv-cross': 'flutter/third_party/vulkan-deps/spirv-cross/src',
    'spirv-headers': 'flutter/third_party/vulkan-deps/spirv-headers/src',
    'spirv-tools': 'flutter/third_party/vulkan-deps/spirv-tools/src',
    'wuffs': 'flutter/third_party/wuffs',
    'zlib': 'flutter/third_party/zlib',
}
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


def normalize(args, side, out_dir):
  """The set of flags that matter, from a compiler command line (sans compiler)."""
  flags = set()
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
    if token.startswith('--sysroot='):
      flags.add('--sysroot=<sysroot>')
      continue
    if token.endswith(SOURCE_SUFFIXES) and not token.startswith('-'):
      continue
    if token.startswith('-D'):
      flags.add(token.replace('"', '').replace("'", ''))
      continue
    flags.add(token)
  return flags


def bazel_commands(aquery_path):
  """Source file -> flag set, from `bazel aquery --output=jsonproto`, target configuration only."""
  with open(aquery_path, encoding='utf-8') as f:
    aquery = json.load(f)
  exec_configurations = {
      c['id'] for c in aquery.get('configuration', []) if 'exec' in c.get('mnemonic', '')
  }
  commands = {}
  for action in aquery.get('actions', []):
    if action.get('mnemonic') != 'CppCompile':
      continue
    if action.get('configurationId') in exec_configurations:
      continue
    args = action.get('arguments', [])
    sources = [a for a in args if a.endswith(SOURCE_SUFFIXES) and not a.startswith('-')]
    if not sources:
      continue
    commands[bazel_path(sources[-1])] = normalize(args[1:], 'bazel', None)
  return commands


def gn_commands(compile_commands_path, wanted):
  """Source file -> flag set, from GN's compile_commands.json, for the files in `wanted`."""
  with open(compile_commands_path, encoding='utf-8') as f:
    entries = json.load(f)
  commands = {}
  for entry in entries:
    directory = entry['directory']
    # out/<config>, relative to engine/src, from the absolute directory.
    out_dir = os.path.join(
        os.path.basename(os.path.dirname(directory)), os.path.basename(directory)
    )
    source = os.path.normpath(os.path.join(out_dir, entry['file']))
    if source not in wanted:
      continue
    # The command is a shell line (ninja's): shlex gives the argv the compiler
    # saw, with GN's \" around a define's value read as the quote it is.
    commands[source] = normalize(shlex.split(entry['command'])[1:], 'gn', out_dir)
  return commands


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
  options = parser.parse_args()

  bazel = bazel_commands(options.aquery)
  gn = gn_commands(options.compile_commands, bazel)
  common = sorted(set(bazel) & set(gn))
  if options.engine_only:
    common = [
        f for f in common if f.startswith('flutter/') and not f.startswith('flutter/third_party/')
    ]
  print(f'bazel {len(bazel)} compiles, gn matched {len(gn)}, compared {len(common)}')
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
  for source in common:
    if bazel[source] == gn[source]:
      identical += 1
      identical_modulo_includes += 1
      continue
    only_bazel = bazel[source] - gn[source]
    only_gn = gn[source] - bazel[source]
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

  print(f'identical flag sets: {identical} of {len(common)}')
  print(
      f'identical ignoring Bazel-only -I directories: {identical_modulo_includes} of {len(common)}'
  )
  print('Bazel-only defines (files):')
  for define, count in bazel_only_defines.most_common():
    print(f'  {count:5} {define}')
  print('other differences:')
  for key, count in classes.most_common(25):
    print(f'  {count} files, e.g. {class_examples[key]}')
    for flag in key[0]:
      print(f'     only Bazel: {flag}')
    for flag in key[1]:
      print(f'     only GN   : {flag}')
  if not options.full:
    return 0
  print('\nevery difference class:')
  for key, count in full_classes.most_common():
    print(f'\n{count} files, e.g. {full_examples[key]}')
    for flag in key[0]:
      print(f'   only Bazel: {flag}')
    for flag in key[1]:
      print(f'   only GN   : {flag}')
  return 0


if __name__ == '__main__':
  sys.exit(main())
