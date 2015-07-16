#!/usr/bin/env python

# Copyright (c) 2012 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

from third_party import asan_symbolize

import argparse
import base64
import json
import os
import platform
import re
import subprocess
import sys

class LineBuffered(object):
  """Disable buffering on a file object."""
  def __init__(self, stream):
    self.stream = stream

  def write(self, data):
    self.stream.write(data)
    if '\n' in data:
      self.stream.flush()

  def __getattr__(self, attr):
    return getattr(self.stream, attr)


def disable_buffering():
  """Makes this process and child processes stdout unbuffered."""
  if not os.environ.get('PYTHONUNBUFFERED'):
    # Since sys.stdout is a C++ object, it's impossible to do
    # sys.stdout.write = lambda...
    sys.stdout = LineBuffered(sys.stdout)
    os.environ['PYTHONUNBUFFERED'] = 'x'


def set_symbolizer_path():
  """Set the path to the llvm-symbolize binary in the Chromium source tree."""
  if not os.environ.get('LLVM_SYMBOLIZER_PATH'):
    script_dir = os.path.dirname(os.path.abspath(__file__))
    # Assume this script resides three levels below src/ (i.e.
    # src/tools/valgrind/asan/).
    src_root = os.path.join(script_dir, "..", "..", "..")
    symbolizer_path = os.path.join(src_root, 'third_party',
        'llvm-build', 'Release+Asserts', 'bin', 'llvm-symbolizer')
    assert(os.path.isfile(symbolizer_path))
    os.environ['LLVM_SYMBOLIZER_PATH'] = os.path.abspath(symbolizer_path)


def is_hash_name(name):
  match = re.match('[0-9a-f]+$', name)
  return bool(match)


def split_path(path):
  ret = []
  while True:
    head, tail = os.path.split(path)
    if head == path:
      return [head] + ret
    ret, path = [tail] + ret, head


def chrome_product_dir_path(exe_path):
  if exe_path is None:
    return None
  path_parts = split_path(exe_path)
  # Make sure the product dir path isn't empty if |exe_path| consists of
  # a single component.
  if len(path_parts) == 1:
    path_parts = ['.'] + path_parts
  for index, part in enumerate(path_parts):
    if part.endswith('.app'):
      return os.path.join(*path_parts[:index])
  # If the executable isn't an .app bundle, it's a commandline binary that
  # resides right in the product dir.
  return os.path.join(*path_parts[:-1])


inode_path_cache = {}


def find_inode_at_path(inode, path):
  if inode in inode_path_cache:
    return inode_path_cache[inode]
  cmd = ['find', path, '-inum', str(inode)]
  find_line = subprocess.check_output(cmd).rstrip()
  lines = find_line.split('\n')
  ret = None
  if lines:
    # `find` may give us several paths (e.g. 'Chromium Framework' in the
    # product dir and 'Chromium Framework' inside 'Chromium.app',
    # chrome_dsym_hints() will produce correct .dSYM path for any of them.
    ret = lines[0]
  inode_path_cache[inode] = ret
  return ret


# Create a binary name filter that works around https://crbug.com/444835.
# When running tests on OSX swarming servers, ASan sometimes prints paths to
# files in cache (ending with SHA1 filenames) instead of paths to hardlinks to
# those files in the product dir.
# For a given |binary_path| chrome_osx_binary_name_filter() returns one of the
# hardlinks to the same inode in |product_dir_path|.
def make_chrome_osx_binary_name_filter(product_dir_path=''):
  def chrome_osx_binary_name_filter(binary_path):
    basename = os.path.basename(binary_path)
    if is_hash_name(basename) and product_dir_path:
      inode = os.stat(binary_path).st_ino
      new_binary_path = find_inode_at_path(inode, product_dir_path)
      if new_binary_path:
        return new_binary_path
    return binary_path
  return chrome_osx_binary_name_filter


# Construct a path to the .dSYM bundle for the given binary.
# There are three possible cases for binary location in Chromium:
# 1. The binary is a standalone executable or dynamic library in the product
#    dir, the debug info is in "binary.dSYM" in the product dir.
# 2. The binary is a standalone framework or .app bundle, the debug info is in
#    "Framework.framework.dSYM" or "App.app.dSYM" in the product dir.
# 3. The binary is a framework or an .app bundle within another .app bundle
#    (e.g. Outer.app/Contents/Versions/1.2.3.4/Inner.app), and the debug info
#    is in Inner.app.dSYM in the product dir.
# The first case is handled by llvm-symbolizer, so we only need to construct
# .dSYM paths for .app bundles and frameworks.
# We're assuming that there're no more than two nested bundles in the binary
# path. Only one of these bundles may be a framework and frameworks cannot
# contain other bundles.
def chrome_dsym_hints(binary):
  path_parts = split_path(binary)
  app_positions = []
  framework_positions = []
  for index, part in enumerate(path_parts):
    if part.endswith('.app'):
      app_positions.append(index)
    elif part.endswith('.framework'):
      framework_positions.append(index)
  bundle_positions = app_positions + framework_positions
  bundle_positions.sort()
  assert len(bundle_positions) <= 2, \
      "The path contains more than two nested bundles: %s" % binary
  if len(bundle_positions) == 0:
    # Case 1: this is a standalone executable or dylib.
    return []
  assert (not (len(app_positions) == 1 and
               len(framework_positions) == 1 and
               app_positions[0] > framework_positions[0])), \
      "The path contains an app bundle inside a framework: %s" % binary
  # Cases 2 and 3. The outermost bundle (which is the only bundle in the case 2)
  # is located in the product dir.
  outermost_bundle = bundle_positions[0]
  product_dir = path_parts[:outermost_bundle]
  # In case 2 this is the same as |outermost_bundle|.
  innermost_bundle = bundle_positions[-1]
  dsym_path = product_dir + [path_parts[innermost_bundle]]
  result = '%s.dSYM' % os.path.join(*dsym_path)
  return [result]


# We want our output to match base::EscapeJSONString(), which produces
# doubly-escaped strings. The first escaping pass is handled by this class. The
# second pass happens when JSON data is dumped to file.
class StringEncoder(json.JSONEncoder):
  def __init__(self):
    json.JSONEncoder.__init__(self)

  def encode(self, s):
    assert(isinstance(s, basestring))
    encoded = json.JSONEncoder.encode(self, s)
    assert(len(encoded) >= 2)
    assert(encoded[0] == '"')
    assert(encoded[-1] == '"')
    encoded = encoded[1:-1]
    # Special case from base::EscapeJSONString().
    encoded = encoded.replace('<', '\u003C')
    return encoded


class JSONTestRunSymbolizer(object):
  def __init__(self, symbolization_loop):
    self.string_encoder = StringEncoder()
    self.symbolization_loop = symbolization_loop

  def symbolize_snippet(self, snippet):
    symbolized_lines = []
    for line in snippet.split('\n'):
      symbolized_lines += self.symbolization_loop.process_line(line)
    return '\n'.join(symbolized_lines)

  def symbolize(self, test_run):
    original_snippet = base64.b64decode(test_run['output_snippet_base64'])
    symbolized_snippet = self.symbolize_snippet(original_snippet)
    if symbolized_snippet == original_snippet:
      # No sanitizer reports in snippet.
      return

    test_run['original_output_snippet'] = test_run['output_snippet']
    test_run['original_output_snippet_base64'] = \
        test_run['output_snippet_base64']

    escaped_snippet = StringEncoder().encode(symbolized_snippet)
    test_run['output_snippet'] = escaped_snippet
    test_run['output_snippet_base64'] = \
        base64.b64encode(symbolized_snippet)
    test_run['snippet_processed_by'] = 'asan_symbolize.py'
    # Originally, "lossless" refers to "no Unicode data lost while encoding the
    # string". However, since we're applying another kind of transformation
    # (symbolization), it doesn't seem right to consider the snippet lossless.
    test_run['losless_snippet'] = False


def symbolize_snippets_in_json(filename, symbolization_loop):
  with open(filename, 'r') as f:
    json_data = json.load(f)

  test_run_symbolizer = JSONTestRunSymbolizer(symbolization_loop)
  for iteration_data in json_data['per_iteration_data']:
    for test_name, test_runs in iteration_data.iteritems():
      for test_run in test_runs:
        test_run_symbolizer.symbolize(test_run)

  with open(filename, 'w') as f:
    json.dump(json_data, f, indent=3, sort_keys=True)


def main():
  parser = argparse.ArgumentParser(description='Symbolize sanitizer reports.')
  parser.add_argument('--test-summary-json-file',
      help='Path to a JSON file produced by the test launcher. The script will '
           'ignore stdandard input and instead symbolize the output stnippets '
           'inside the JSON file. The result will be written back to the JSON '
           'file.')
  parser.add_argument('strip_path_prefix', nargs='*',
      help='When printing source file names, the longest prefix ending in one '
           'of these substrings will be stripped. E.g.: "Release/../../".')
  parser.add_argument('--executable-path',
      help='Path to program executable. Used on OSX swarming bots to locate '
           'dSYM bundles for associated frameworks and bundles.')
  args = parser.parse_args()

  disable_buffering()
  set_symbolizer_path()
  asan_symbolize.demangle = True
  asan_symbolize.fix_filename_patterns = args.strip_path_prefix
  # Most source paths for Chromium binaries start with
  # /path/to/src/out/Release/../../
  asan_symbolize.fix_filename_patterns.append('Release/../../')
  binary_name_filter = None
  if platform.uname()[0] == 'Darwin':
    binary_name_filter = make_chrome_osx_binary_name_filter(
        chrome_product_dir_path(args.executable_path))
  loop = asan_symbolize.SymbolizationLoop(
      binary_name_filter=binary_name_filter,
      dsym_hint_producer=chrome_dsym_hints)

  if args.test_summary_json_file:
    symbolize_snippets_in_json(args.test_summary_json_file, loop)
  else:
    # Process stdin.
    asan_symbolize.logfile = sys.stdin
    loop.process_logfile()

if __name__ == '__main__':
  main()
