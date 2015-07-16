#!/usr/bin/env python
# Copyright (c) 2012 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Makes sure files have the right permissions.

Some developers have broken SCM configurations that flip the executable
permission on for no good reason. Unix developers who run ls --color will then
see .cc files in green and get confused.

- For file extensions that must be executable, add it to EXECUTABLE_EXTENSIONS.
- For file extensions that must not be executable, add it to
  NOT_EXECUTABLE_EXTENSIONS.
- To ignore all the files inside a directory, add it to IGNORED_PATHS.
- For file base name with ambiguous state and that should not be checked for
  shebang, add it to IGNORED_FILENAMES.

Any file not matching the above will be opened and looked if it has a shebang
or an ELF header. If this does not match the executable bit on the file, the
file will be flagged.

Note that all directory separators must be slashes (Unix-style) and not
backslashes. All directories should be relative to the source root and all
file paths should be only lowercase.
"""

import json
import logging
import optparse
import os
import stat
import string
import subprocess
import sys

#### USER EDITABLE SECTION STARTS HERE ####

# Files with these extensions must have executable bit set.
#
# Case-sensitive.
EXECUTABLE_EXTENSIONS = (
  'bat',
  'dll',
  'dylib',
  'exe',
)

# These files must have executable bit set.
#
# Case-insensitive, lower-case only.
EXECUTABLE_PATHS = (
  'chrome/test/data/app_shim/app_shim_32_bit.app/contents/'
      'macos/app_mode_loader',
  'chrome/test/data/extensions/uitest/plugins/plugin.plugin/contents/'
      'macos/testnetscapeplugin',
  'chrome/test/data/extensions/uitest/plugins_private/plugin.plugin/contents/'
      'macos/testnetscapeplugin',
)

# These files must not have the executable bit set. This is mainly a performance
# optimization as these files are not checked for shebang. The list was
# partially generated from:
# git ls-files | grep "\\." | sed 's/.*\.//' | sort | uniq -c | sort -b -g
#
# Case-sensitive.
NON_EXECUTABLE_EXTENSIONS = (
  '1',
  '3ds',
  'S',
  'am',
  'applescript',
  'asm',
  'c',
  'cc',
  'cfg',
  'chromium',
  'cpp',
  'crx',
  'cs',
  'css',
  'cur',
  'def',
  'der',
  'expected',
  'gif',
  'grd',
  'gyp',
  'gypi',
  'h',
  'hh',
  'htm',
  'html',
  'hyph',
  'ico',
  'idl',
  'java',
  'jpg',
  'js',
  'json',
  'm',
  'm4',
  'mm',
  'mms',
  'mock-http-headers',
  'nexe',
  'nmf',
  'onc',
  'pat',
  'patch',
  'pdf',
  'pem',
  'plist',
  'png',
  'proto',
  'rc',
  'rfx',
  'rgs',
  'rules',
  'spec',
  'sql',
  'srpc',
  'svg',
  'tcl',
  'test',
  'tga',
  'txt',
  'vcproj',
  'vsprops',
  'webm',
  'word',
  'xib',
  'xml',
  'xtb',
  'zip',
)

# These files must not have executable bit set.
#
# Case-insensitive, lower-case only.
NON_EXECUTABLE_PATHS = (
  'build/android/tests/symbolize/liba.so',
  'build/android/tests/symbolize/libb.so',
  'chrome/installer/mac/sign_app.sh.in',
  'chrome/installer/mac/sign_versioned_dir.sh.in',
  'chrome/test/data/extensions/uitest/plugins/plugin32.so',
  'chrome/test/data/extensions/uitest/plugins/plugin64.so',
  'chrome/test/data/extensions/uitest/plugins_private/plugin32.so',
  'chrome/test/data/extensions/uitest/plugins_private/plugin64.so',
  'components/test/data/component_updater/ihfokbkgjpifnbbojhneepfflplebdkc/'
      'ihfokbkgjpifnbbojhneepfflplebdkc_1/a_changing_binary_file',
  'components/test/data/component_updater/ihfokbkgjpifnbbojhneepfflplebdkc/'
      'ihfokbkgjpifnbbojhneepfflplebdkc_2/a_changing_binary_file',
  'courgette/testdata/elf-32-1',
  'courgette/testdata/elf-32-2',
  'courgette/testdata/elf-64',
)

# File names that are always whitelisted.  (These are mostly autoconf spew.)
#
# Case-sensitive.
IGNORED_FILENAMES = (
  'config.guess',
  'config.sub',
  'configure',
  'depcomp',
  'install-sh',
  'missing',
  'mkinstalldirs',
  'naclsdk',
  'scons',
)

# File paths starting with one of these will be ignored as well.
# Please consider fixing your file permissions, rather than adding to this list.
#
# Case-insensitive, lower-case only.
IGNORED_PATHS = (
  'native_client_sdk/src/build_tools/sdk_tools/third_party/fancy_urllib/'
      '__init__.py',
  'out/',
  # TODO(maruel): Fix these.
  'third_party/android_testrunner/',
  'third_party/bintrees/',
  'third_party/closure_linter/',
  'third_party/devscripts/licensecheck.pl.vanilla',
  'third_party/hyphen/',
  'third_party/jemalloc/',
  'third_party/lcov-1.9/contrib/galaxy/conglomerate_functions.pl',
  'third_party/lcov-1.9/contrib/galaxy/gen_makefile.sh',
  'third_party/lcov/contrib/galaxy/conglomerate_functions.pl',
  'third_party/lcov/contrib/galaxy/gen_makefile.sh',
  'third_party/libevent/autogen.sh',
  'third_party/libevent/test/test.sh',
  'third_party/libxml/linux/xml2-config',
  'third_party/libxml/src/ltmain.sh',
  'third_party/mesa/',
  'third_party/protobuf/',
  'third_party/python_gflags/gflags.py',
  'third_party/sqlite/',
  'third_party/talloc/script/mksyms.sh',
  'third_party/tcmalloc/',
  'third_party/tlslite/setup.py',
)

#### USER EDITABLE SECTION ENDS HERE ####

assert set(EXECUTABLE_EXTENSIONS) & set(NON_EXECUTABLE_EXTENSIONS) == set()
assert set(EXECUTABLE_PATHS) & set(NON_EXECUTABLE_PATHS) == set()

VALID_CHARS = set(string.ascii_lowercase + string.digits + '/-_.')
for paths in (EXECUTABLE_PATHS, NON_EXECUTABLE_PATHS, IGNORED_PATHS):
  assert all([set(path).issubset(VALID_CHARS) for path in paths])


def capture(cmd, cwd):
  """Returns the output of a command.

  Ignores the error code or stderr.
  """
  logging.debug('%s; cwd=%s' % (' '.join(cmd), cwd))
  env = os.environ.copy()
  env['LANGUAGE'] = 'en_US.UTF-8'
  p = subprocess.Popen(
      cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, cwd=cwd, env=env)
  return p.communicate()[0]


def get_git_root(dir_path):
  """Returns the git checkout root or None."""
  root = capture(['git', 'rev-parse', '--show-toplevel'], dir_path).strip()
  if root:
    return root


def is_ignored(rel_path):
  """Returns True if rel_path is in our whitelist of files to ignore."""
  rel_path = rel_path.lower()
  return (
      os.path.basename(rel_path) in IGNORED_FILENAMES or
      rel_path.lower().startswith(IGNORED_PATHS))


def must_be_executable(rel_path):
  """The file name represents a file type that must have the executable bit
  set.
  """
  return (os.path.splitext(rel_path)[1][1:] in EXECUTABLE_EXTENSIONS or
          rel_path.lower() in EXECUTABLE_PATHS)


def must_not_be_executable(rel_path):
  """The file name represents a file type that must not have the executable
  bit set.
  """
  return (os.path.splitext(rel_path)[1][1:] in NON_EXECUTABLE_EXTENSIONS or
          rel_path.lower() in NON_EXECUTABLE_PATHS)


def has_executable_bit(full_path):
  """Returns if any executable bit is set."""
  permission = stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH
  return bool(permission & os.stat(full_path).st_mode)


def has_shebang_or_is_elf(full_path):
  """Returns if the file starts with #!/ or is an ELF binary.

  full_path is the absolute path to the file.
  """
  with open(full_path, 'rb') as f:
    data = f.read(4)
    return (data[:3] == '#!/' or data == '#! /', data == '\x7fELF')


def check_file(root_path, rel_path):
  """Checks the permissions of the file whose path is root_path + rel_path and
  returns an error if it is inconsistent. Returns None on success.

  It is assumed that the file is not ignored by is_ignored().

  If the file name is matched with must_be_executable() or
  must_not_be_executable(), only its executable bit is checked.
  Otherwise, the first few bytes of the file are read to verify if it has a
  shebang or ELF header and compares this with the executable bit on the file.
  """
  full_path = os.path.join(root_path, rel_path)
  def result_dict(error):
    return {
      'error': error,
      'full_path': full_path,
      'rel_path': rel_path,
    }
  try:
    bit = has_executable_bit(full_path)
  except OSError:
    # It's faster to catch exception than call os.path.islink(). Chromium
    # tree happens to have invalid symlinks under
    # third_party/openssl/openssl/test/.
    return None

  if must_be_executable(rel_path):
    if not bit:
      return result_dict('Must have executable bit set')
    return
  if must_not_be_executable(rel_path):
    if bit:
      return result_dict('Must not have executable bit set')
    return

  # For the others, it depends on the file header.
  (shebang, elf) = has_shebang_or_is_elf(full_path)
  if bit != (shebang or elf):
    if bit:
      return result_dict('Has executable bit but not shebang or ELF header')
    if shebang:
      return result_dict('Has shebang but not executable bit')
    return result_dict('Has ELF header but not executable bit')


def check_files(root, files):
  gen = (check_file(root, f) for f in files if not is_ignored(f))
  return filter(None, gen)


class ApiBase(object):
  def __init__(self, root_dir, bare_output):
    self.root_dir = root_dir
    self.bare_output = bare_output
    self.count = 0
    self.count_read_header = 0

  def check_file(self, rel_path):
    logging.debug('check_file(%s)' % rel_path)
    self.count += 1

    if (not must_be_executable(rel_path) and
        not must_not_be_executable(rel_path)):
      self.count_read_header += 1

    return check_file(self.root_dir, rel_path)

  def check_dir(self, rel_path):
    return self.check(rel_path)

  def check(self, start_dir):
    """Check the files in start_dir, recursively check its subdirectories."""
    errors = []
    items = self.list_dir(start_dir)
    logging.info('check(%s) -> %d' % (start_dir, len(items)))
    for item in items:
      full_path = os.path.join(self.root_dir, start_dir, item)
      rel_path = full_path[len(self.root_dir) + 1:]
      if is_ignored(rel_path):
        continue
      if os.path.isdir(full_path):
        # Depth first.
        errors.extend(self.check_dir(rel_path))
      else:
        error = self.check_file(rel_path)
        if error:
          errors.append(error)
    return errors

  def list_dir(self, start_dir):
    """Lists all the files and directory inside start_dir."""
    return sorted(
      x for x in os.listdir(os.path.join(self.root_dir, start_dir))
      if not x.startswith('.')
    )


class ApiAllFilesAtOnceBase(ApiBase):
  _files = None

  def list_dir(self, start_dir):
    """Lists all the files and directory inside start_dir."""
    if self._files is None:
      self._files = sorted(self._get_all_files())
      if not self.bare_output:
        print 'Found %s files' % len(self._files)
    start_dir = start_dir[len(self.root_dir) + 1:]
    return [
      x[len(start_dir):] for x in self._files if x.startswith(start_dir)
    ]

  def _get_all_files(self):
    """Lists all the files and directory inside self._root_dir."""
    raise NotImplementedError()


class ApiGit(ApiAllFilesAtOnceBase):
  def _get_all_files(self):
    return capture(['git', 'ls-files'], cwd=self.root_dir).splitlines()


def get_scm(dir_path, bare):
  """Returns a properly configured ApiBase instance."""
  cwd = os.getcwd()
  root = get_git_root(dir_path or cwd)
  if root:
    if not bare:
      print('Found git repository at %s' % root)
    return ApiGit(dir_path or root, bare)

  # Returns a non-scm aware checker.
  if not bare:
    print('Failed to determine the SCM for %s' % dir_path)
  return ApiBase(dir_path or cwd, bare)


def main():
  usage = """Usage: python %prog [--root <root>] [tocheck]
  tocheck  Specifies the directory, relative to root, to check. This defaults
           to "." so it checks everything.

Examples:
  python %prog
  python %prog --root /path/to/source chrome"""

  parser = optparse.OptionParser(usage=usage)
  parser.add_option(
      '--root',
      help='Specifies the repository root. This defaults '
           'to the checkout repository root')
  parser.add_option(
      '-v', '--verbose', action='count', default=0, help='Print debug logging')
  parser.add_option(
      '--bare',
      action='store_true',
      default=False,
      help='Prints the bare filename triggering the checks')
  parser.add_option(
      '--file', action='append', dest='files',
      help='Specifics a list of files to check the permissions of. Only these '
      'files will be checked')
  parser.add_option('--json', help='Path to JSON output file')
  options, args = parser.parse_args()

  levels = [logging.ERROR, logging.INFO, logging.DEBUG]
  logging.basicConfig(level=levels[min(len(levels) - 1, options.verbose)])

  if len(args) > 1:
    parser.error('Too many arguments used')

  if options.root:
    options.root = os.path.abspath(options.root)

  if options.files:
    # --file implies --bare (for PRESUBMIT.py).
    options.bare = True

    errors = check_files(options.root, options.files)
  else:
    api = get_scm(options.root, options.bare)
    start_dir = args[0] if args else api.root_dir
    errors = api.check(start_dir)

    if not options.bare:
      print('Processed %s files, %d files where tested for shebang/ELF '
            'header' % (api.count, api.count_read_header))

  if options.json:
    with open(options.json, 'w') as f:
      json.dump(errors, f)

  if errors:
    if options.bare:
      print '\n'.join(e['full_path'] for e in errors)
    else:
      print '\nFAILED\n'
      print '\n'.join('%s: %s' % (e['full_path'], e['error']) for e in errors)
    return 1
  if not options.bare:
    print '\nSUCCESS\n'
  return 0


if '__main__' == __name__:
  sys.exit(main())
