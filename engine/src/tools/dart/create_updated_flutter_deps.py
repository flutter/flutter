#!/usr/bin/env python3
#
# Copyright 2017 The Dart project authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Usage: tools/dart/create_updated_flutter_deps.py [-d dart/DEPS] [-f flutter/DEPS]
#
# This script parses existing flutter DEPS file, identifies all 'dart_' prefixed
# dependencies, looks up revision from dart DEPS file, updates those dependencies
# and rewrites flutter DEPS file.

import argparse
import base64
import os
import re
import sys
import urllib.request

DART_SCRIPT_DIR = os.path.dirname(sys.argv[0])
OLD_DART_DEPS = os.path.realpath(os.path.join(DART_SCRIPT_DIR, '../../third_party/dart/DEPS'))
DART_DEPS = os.path.realpath(os.path.join(DART_SCRIPT_DIR, '../../flutter/third_party/dart/DEPS'))
FLUTTER_DEPS = os.path.realpath(os.path.join(DART_SCRIPT_DIR, '../../../../DEPS'))
SUPPORTS_DART2WASM_JS = os.path.realpath(
    os.path.join(
        DART_SCRIPT_DIR,
        '../../flutter/lib/web_ui/flutter_js/src/supports_dart2wasm.js',
    )
)

# Path to Dart SDK checkout within Flutter repo.
DART_SDK_ROOT = 'engine/src/flutter/third_party/dart'
DART_COMPILE_RELPATH = 'pkg/dart2wasm/lib/compile.dart'

class VarImpl(object):
  def __init__(self, local_scope):
    self._local_scope = local_scope

  def Lookup(self, var_name):
    """Implements the Var syntax."""
    if var_name in self._local_scope.get("vars", {}):
      return self._local_scope["vars"][var_name]
    if var_name == 'host_os':
      return 'linux' # assume some default value
    if var_name == 'host_cpu':
      return 'x64' # assume some default value
    raise Exception("Var is not defined: %s" % var_name)


def ParseDepsFile(deps_file):
  local_scope = {}
  var = VarImpl(local_scope)
  global_scope = {
    'Var': var.Lookup,
    'deps_os': {},
  }
  # Read the content.
  with open(deps_file, 'r') as fp:
    deps_content = fp.read()

  # Eval the content.
  exec(deps_content, global_scope, local_scope)

  return (local_scope.get('vars', {}), local_scope.get('deps', {}))

def GitHashArg(value):
  """Validates that the string is a 40-character hex string."""
  # If the argument is not passed, argparse usually handles the 'None'
  # default, but this check ensures the string matches the pattern.
  if not re.match(r"^[0-9a-f]{40}$", value):
      raise argparse.ArgumentTypeError(
          f"'{value}' is not a valid full git hash. "
          "Expected a 40-character hexadecimal string."
      )
  return value

def ParseArgs(args):
  args = args[1:]
  parser = argparse.ArgumentParser(
      description='A script to generate updated dart dependencies for flutter DEPS.')
  parser.add_argument('--dart_deps', '-d',
      type=str,
      help='Dart DEPS file.',
      default=DART_DEPS)
  parser.add_argument('--flutter_deps', '-f',
      type=str,
      help='Flutter DEPS file.',
      default=FLUTTER_DEPS)
  parser.add_argument('--dart_revision', '-r',
      type=GitHashArg,
      help='Dart revision to update to.')
  parser.add_argument('--supports_dart2wasm_js',
      type=str,
      help='Path to supports_dart2wasm.js to generate from dart2wasm.',
      default=SUPPORTS_DART2WASM_JS)
  parser.add_argument('--dart_compile_file',
      type=str,
      help='Optional path to Dart SDK pkg/dart2wasm/lib/compile.dart.',
      default=None)
  return parser.parse_args(args)

def PrettifySourcePathForDEPS(flutter_vars, dep_path, source):
  """Prepare source for writing into Flutter DEPS file.

  If source is not a string then it is expected to be a dictionary defining
  a CIPD dependency. In this case it is written as is - but sorted to
  guarantee stability of the output.

  Otherwise source is a path to a repo plus version (hash or tag):

      {repo_host}/{repo_path}@{version}

  We want to convert this into one of the following:

      Var(repo_host_var) + 'repo_path' + '@' + Var(version_var)
      Var(repo_host_var) + 'repo_path@version'
      'source'

  Where repo_host_var is one of '*_git' variables and version_var is one
  of 'dart_{dep_name}_tag' or 'dart_{dep_name}_rev' variables.
  """

  # If this a CIPD dependency then keep it as-is but sort its contents
  # to ensure stable ordering.
  if not isinstance(source, str):
    return dict(sorted(source.items()))

  # Decompose source into {repo_host}/{repo_path}@{version}
  repo_host_var = None
  version_var = None
  repo_path_with_version = source
  for var_name, var_value in flutter_vars.items():
    if var_name.endswith("_git") and source.startswith(var_value):
      repo_host_var = var_name
      repo_path_with_version = source[len(var_value):]
      break

  if repo_path_with_version.find('@') == -1:
    raise ValueError(f'{dep_path} source is unversioned')

  repo_path, version = repo_path_with_version.split('@', 1)

  # Figure out the name of the dependency from its path to compute
  # corresponding version_var.
  #
  # Normally, the last component of the dep_path is the name of the dependency.
  # However some dependencies are placed in a subdirectory named "src"
  # within a directory named after the dependency.
  dep_name = os.path.basename(dep_path)
  if dep_name == 'src':
    dep_name = os.path.basename(os.path.dirname(dep_path))
  for var_name in [f'dart_{dep_name}_tag', f'dart_{dep_name}_rev']:
    if var_name in flutter_vars:
      version_var = var_name
      break

  # Format result from available individual pieces.
  result = []
  if repo_host_var is not None:
    result += [f"Var('{repo_host_var}')"]
  if version_var is not None:
    result += [f"'{repo_path}'", "'@'", f"Var('{version_var}')"]
  else:
    result += [f"'{repo_path_with_version}'"]
  return " + ".join(result)

def ComputeDartDeps(flutter_vars, flutter_deps, dart_deps):
  """Compute sources for deps nested under DART_SDK_ROOT in Flutter DEPS.

  These dependencies originate from Dart SDK, so their version are
  computed by looking them up in Dart DEPS using appropriately
  relocated paths, e.g. '{DART_SDK_ROOT}/third_party/foo' is located at
  'sdk/third_party/foo' in Dart DEPS.

  Source paths are expressed in terms of 'xyz_git' and 'dart_xyz_tag' or
  'dart_xyz_rev' variables if possible.

  If corresponding path is not found in Dart DEPS the dependency is considered
  no longer needed and is removed from Flutter DEPS.

  Returns: dictionary of dependencies
  """
  new_dart_deps = {}

  # Trailing / to avoid matching Dart SDK dependency itself.
  dart_sdk_root_dir = DART_SDK_ROOT + '/'

  # Find all dependencies which are nested inside Dart SDK and check
  # if Dart SDK still needs them. If Dart DEPS still mentions them
  # take updated version from Dart DEPS.
  for (dep_path, dep_source) in sorted(flutter_deps.items()):
    if dep_path.startswith(dart_sdk_root_dir):
      # Dart dependencies are given relative to root directory called `sdk/`.
      dart_dep_path = f'sdk/{dep_path[len(dart_sdk_root_dir):]}'
      if dart_dep_path in dart_deps:
        # Still used, add it to the result.
        new_dart_deps[dep_path] = PrettifySourcePathForDEPS(flutter_vars, dep_path, dart_deps[dart_dep_path])

  return new_dart_deps


def ExtractDart2WasmSupportExpression(compile_dart_content):
  """Extracts the baseline JS expression from `_generateSupportJs` in compile.dart.

  Parses `const String <name> = '<expr>';` definitions inside `_generateSupportJs`
  and joins the unconditional entries in `final requiredFeatures = [...]` with `&&`.
  """
  fn_match = re.search(
      r'String\s+_generateSupportJs\s*\([^)]*\)\s*\{(.*?)\n\}',
      compile_dart_content,
      re.DOTALL,
  )
  if not fn_match:
    raise ValueError(
        'Could not locate `_generateSupportJs` in pkg/dart2wasm/lib/compile.dart'
    )
  fn_body = fn_match.group(1)

  feature_consts = {
      name: (single_quoted or double_quoted)
      for name, single_quoted, double_quoted in re.findall(
          r"""const\s+String\s+([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(?:'([^']+)'|"([^"]+)");""",
          fn_body,
      )
  }
  req_match = re.search(
      r'final\s+requiredFeatures\s*=\s*\[(.*?)\];', fn_body, re.DOTALL
  )
  if not req_match:
    raise ValueError(
        'Could not locate `requiredFeatures` inside `_generateSupportJs`'
    )

  required_exprs = []
  for raw_line in req_match.group(1).splitlines():
    line = raw_line.split('//', 1)[0].strip()
    if not line or line.startswith('if ') or line.startswith('if('):
      continue
    ident = line.rstrip(',').strip()
    if not re.match(r'^[A-Za-z_][A-Za-z0-9_]*$', ident):
      raise ValueError(
          f'Unrecognized entry in `requiredFeatures`: {raw_line.strip()!r}'
      )
    if ident not in feature_consts:
      raise ValueError(
          f'Feature `{ident}` in `requiredFeatures` has no `const String` definition'
      )
    required_exprs.append(feature_consts[ident])

  if not required_exprs:
    raise ValueError('No unconditional features found in `requiredFeatures`')

  return f"({'&&'.join(required_exprs)})"


def FormatSupportsDart2WasmJs(support_expr):
  """Returns the full content of the generated `supports_dart2wasm.js` file."""
  return (
      '// Copyright 2013 The Flutter Authors. All rights reserved.\n'
      '// Use of this source code is governed by a BSD-style license that can be\n'
      '// found in the LICENSE file.\n'
      '\n'
      '// GENERATED FILE. DO NOT EDIT.\n'
      '//\n'
      '// Generated by `engine/src/tools/dart/create_updated_flutter_deps.py` from\n'
      '// `pkg/dart2wasm/lib/compile.dart`.\n'
      '\n'
      'export const supportsDart2Wasm = () => {\n'
      f'  return {support_expr};\n'
      '};\n'
  )


def _FetchCompileDartFromGitiles(revision):
  """Fetches `pkg/dart2wasm/lib/compile.dart` at `revision` from dart.googlesource.com."""
  url = (
      f'https://dart.googlesource.com/sdk/+/{revision}/'
      f'{DART_COMPILE_RELPATH}?format=TEXT'
  )
  try:
    with urllib.request.urlopen(url, timeout=15) as response:
      encoded = response.read()
    return base64.b64decode(encoded).decode('utf-8')
  except Exception as exc:  # pylint: disable=broad-except
    sys.stderr.write(
        f'Warning: failed to fetch {url} ({exc}); falling back to local checkout.\n'
    )
    return None


def ResolveDartCompileFileContent(args, flutter_vars):
  """Resolves `pkg/dart2wasm/lib/compile.dart` content locally or via gitiles."""
  if getattr(args, 'dart_compile_file', None):
    with open(args.dart_compile_file, 'r', encoding='utf-8') as fp:
      return fp.read()

  # When an explicit --dart_revision (-r) is passed (e.g. in roll-dart-dependencies.yml
  # or a manual roll in a gclient checkout), fetch compile.dart at that revision first
  # so a pre-existing local third_party/dart checkout does not shadow the target hash.
  explicit_rev = getattr(args, 'dart_revision', None)
  if explicit_rev:
    fetched = _FetchCompileDartFromGitiles(explicit_rev)
    if fetched:
      return fetched

  # Check sibling of args.dart_deps (e.g., third_party/dart/DEPS or local SDK checkout).
  if getattr(args, 'dart_deps', None):
    candidate = os.path.join(
        os.path.dirname(os.path.realpath(args.dart_deps)),
        DART_COMPILE_RELPATH,
    )
    if os.path.isfile(candidate):
      with open(candidate, 'r', encoding='utf-8') as fp:
        return fp.read()

  # Fallback to flutter checkout's DART_SDK_ROOT if present on disk.
  if getattr(args, 'flutter_deps', None):
    candidate = os.path.join(
        os.path.dirname(os.path.realpath(args.flutter_deps)),
        DART_SDK_ROOT,
        DART_COMPILE_RELPATH,
    )
    if os.path.isfile(candidate):
      with open(candidate, 'r', encoding='utf-8') as fp:
        return fp.read()

  # If no local SDK checkout exists on disk (e.g. a git-only flutter/flutter worktree)
  # and --dart_revision was not passed, fall back to flutter_vars['dart_revision'].
  fallback_rev = flutter_vars.get('dart_revision') if flutter_vars else None
  if fallback_rev and fallback_rev != explicit_rev:
    return _FetchCompileDartFromGitiles(fallback_rev)

  return None


def SyncSupportsDart2WasmJs(args, flutter_vars):
  """Generates `supports_dart2wasm.js` from `pkg/dart2wasm/lib/compile.dart`."""
  supports_js_path = getattr(args, 'supports_dart2wasm_js', None)
  if not supports_js_path or not os.path.isdir(os.path.dirname(supports_js_path)):
    return False

  compile_dart_content = ResolveDartCompileFileContent(args, flutter_vars)
  if not compile_dart_content:
    sys.stderr.write(
        'Warning: could not resolve pkg/dart2wasm/lib/compile.dart; '
        'skipping supports_dart2wasm.js generation.\n'
    )
    return False

  support_expr = ExtractDart2WasmSupportExpression(compile_dart_content)
  updated_content = FormatSupportsDart2WasmJs(support_expr)

  original_content = None
  if os.path.isfile(supports_js_path):
    with open(supports_js_path, 'r', encoding='utf-8') as fp:
      original_content = fp.read()

  if updated_content != original_content:
    with open(supports_js_path, 'w', encoding='utf-8') as fp:
      fp.write(updated_content)
    return True
  return False


def Main(argv):
  args = ParseArgs(argv)
  if args.dart_deps == DART_DEPS and not os.path.isfile(DART_DEPS):
    args.dart_deps = OLD_DART_DEPS
  (dart_vars, dart_deps) = ParseDepsFile(args.dart_deps)
  (flutter_vars, flutter_deps) = ParseDepsFile(args.flutter_deps)

  updated_vars = {}

  # Collect updated dependencies
  for (k,v) in sorted(flutter_vars.items()):
    if k not in ('dart_revision', 'dart_git') and k.startswith('dart_'):
      dart_key = k[len('dart_'):]
      if dart_key in dart_vars:
        updated_vars[k] = dart_vars[dart_key].lstrip('@')

  new_dart_deps = ComputeDartDeps(flutter_vars, flutter_deps, dart_deps)

  # Write updated DEPS file to a side
  updatedfilename = args.flutter_deps + ".new"
  updatedfile = open(updatedfilename, "w")
  file = open(args.flutter_deps)
  lines = file.readlines()
  i = 0
  while i < len(lines):
    if lines[i].startswith("  'dart_revision':"):
      if args.dart_revision is None:
        # No dart revision supplied. Leave as-is.
        updatedfile.write(lines[i])
      else:
        updatedfile.write("  'dart_revision': '%s',\n" % args.dart_revision)

      i = i + 2
      updatedfile.writelines([
        '\n',
        '  # WARNING: DO NOT EDIT MANUALLY\n',
        '  # The lines between blank lines above and below are generated by a script. See create_updated_flutter_deps.py\n'])
      while i < len(lines) and len(lines[i].strip()) > 0:
        i = i + 1
      for (k, v) in sorted(updated_vars.items()):
        updatedfile.write("  '%s': '%s',\n" % (k, v))
      updatedfile.write('\n')

    elif lines[i].startswith("  # WARNING: Unused Dart dependencies"):
      updatedfile.write(lines[i])
      updatedfile.write('\n')
      i = i + 1
      while i < len(lines) and not lines[i].startswith("  # WARNING: end of dart dependencies"):
        i = i + 1

      for dep_path, dep_source in new_dart_deps.items():
        updatedfile.write(f"  '{dep_path}':\n   {dep_source},\n\n")

      updatedfile.write(lines[i])

    else:
      updatedfile.write(lines[i])
    i = i + 1

  updatedfile.close()
  file.close()

  # Rename updated DEPS file into a new DEPS file
  os.remove(args.flutter_deps)
  os.rename(updatedfilename, args.flutter_deps)

  SyncSupportsDart2WasmJs(args, flutter_vars)

  return 0

if __name__ == '__main__':
  sys.exit(Main(sys.argv))

