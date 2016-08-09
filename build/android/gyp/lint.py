#!/usr/bin/env python
#
# Copyright (c) 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Runs Android's lint tool."""


import optparse
import os
import sys
from xml.dom import minidom

from util import build_utils


_SRC_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__),
                                         '..', '..', '..'))


def _RunLint(lint_path, config_path, processed_config_path, manifest_path,
             result_path, product_dir, sources, jar_path, resource_dir=None):

  def _RelativizePath(path):
    """Returns relative path to top-level src dir.

    Args:
      path: A path relative to cwd.
    """
    return os.path.relpath(os.path.abspath(path), _SRC_ROOT)

  def _ProcessConfigFile():
    if not build_utils.IsTimeStale(processed_config_path, [config_path]):
      return

    with open(config_path, 'rb') as f:
      content = f.read().replace(
          'PRODUCT_DIR', _RelativizePath(product_dir))

    with open(processed_config_path, 'wb') as f:
      f.write(content)

  def _ProcessResultFile():
    with open(result_path, 'rb') as f:
      content = f.read().replace(
          _RelativizePath(product_dir), 'PRODUCT_DIR')

    with open(result_path, 'wb') as f:
      f.write(content)

  def _ParseAndShowResultFile():
    dom = minidom.parse(result_path)
    issues = dom.getElementsByTagName('issue')
    print >> sys.stderr
    for issue in issues:
      issue_id = issue.attributes['id'].value
      message = issue.attributes['message'].value
      location_elem = issue.getElementsByTagName('location')[0]
      path = location_elem.attributes['file'].value
      line = location_elem.getAttribute('line')
      if line:
        error = '%s:%s %s: %s [warning]' % (path, line, message, issue_id)
      else:
        # Issues in class files don't have a line number.
        error = '%s %s: %s [warning]' % (path, message, issue_id)
      print >> sys.stderr, error
      for attr in ['errorLine1', 'errorLine2']:
        error_line = issue.getAttribute(attr)
        if error_line:
          print >> sys.stderr, error_line
    return len(issues)

  with build_utils.TempDir() as temp_dir:
    _ProcessConfigFile()

    cmd = [
        _RelativizePath(lint_path), '-Werror', '--exitcode', '--showall',
        '--config', _RelativizePath(processed_config_path),
        '--classpath', _RelativizePath(jar_path),
        '--xml', _RelativizePath(result_path),
    ]
    if resource_dir:
      cmd.extend(['--resources', _RelativizePath(resource_dir)])

    # There may be multiple source files with the same basename (but in
    # different directories). It is difficult to determine what part of the path
    # corresponds to the java package, and so instead just link the source files
    # into temporary directories (creating a new one whenever there is a name
    # conflict).
    src_dirs = []
    def NewSourceDir():
      new_dir = os.path.join(temp_dir, str(len(src_dirs)))
      os.mkdir(new_dir)
      src_dirs.append(new_dir)
      cmd.extend(['--sources', _RelativizePath(new_dir)])
      return new_dir

    def PathInDir(d, src):
      return os.path.join(d, os.path.basename(src))

    for src in sources:
      src_dir = None
      for d in src_dirs:
        if not os.path.exists(PathInDir(d, src)):
          src_dir = d
          break
      if not src_dir:
        src_dir = NewSourceDir()
      os.symlink(os.path.abspath(src), PathInDir(src_dir, src))

    cmd.append(_RelativizePath(os.path.join(manifest_path, os.pardir)))

    if os.path.exists(result_path):
      os.remove(result_path)

    try:
      build_utils.CheckOutput(cmd, cwd=_SRC_ROOT)
    except build_utils.CalledProcessError as e:
      # There is a problem with lint usage
      if not os.path.exists(result_path):
        print 'Something is wrong:'
        print e
        return 1

      # There are actual lint issues
      else:
        try:
          num_issues = _ParseAndShowResultFile()
        except Exception:
          print 'Lint created unparseable xml file...'
          print 'File contents:'
          with open(result_path) as f:
            print f.read()
          return 1

        _ProcessResultFile()
        msg = ('\nLint found %d new issues.\n'
               ' - For full explanation refer to %s\n'
               ' - Wanna suppress these issues?\n'
               '    1. Read comment in %s\n'
               '    2. Run "python %s %s"\n' %
               (num_issues,
                _RelativizePath(result_path),
                _RelativizePath(config_path),
                _RelativizePath(os.path.join(_SRC_ROOT, 'build', 'android',
                                             'lint', 'suppress.py')),
                _RelativizePath(result_path)))
        print >> sys.stderr, msg
        return 1

  return 0


def main():
  parser = optparse.OptionParser()
  build_utils.AddDepfileOption(parser)
  parser.add_option('--lint-path', help='Path to lint executable.')
  parser.add_option('--config-path', help='Path to lint suppressions file.')
  parser.add_option('--processed-config-path',
                    help='Path to processed lint suppressions file.')
  parser.add_option('--manifest-path', help='Path to AndroidManifest.xml')
  parser.add_option('--result-path', help='Path to XML lint result file.')
  parser.add_option('--product-dir', help='Path to product dir.')
  parser.add_option('--src-dirs', help='Directories containing java files.')
  parser.add_option('--java-files', help='Paths to java files.')
  parser.add_option('--jar-path', help='Jar file containing class files.')
  parser.add_option('--resource-dir', help='Path to resource dir.')
  parser.add_option('--can-fail-build', action='store_true',
                    help='If set, script will exit with nonzero exit status'
                    ' if lint errors are present')
  parser.add_option('--stamp', help='Path to touch on success.')
  parser.add_option('--enable', action='store_true',
                    help='Run lint instead of just touching stamp.')

  options, _ = parser.parse_args()

  build_utils.CheckOptions(
      options, parser, required=['lint_path', 'config_path',
                                 'processed_config_path', 'manifest_path',
                                 'result_path', 'product_dir',
                                 'jar_path'])

  rc = 0

  if options.enable:
    sources = []
    if options.src_dirs:
      src_dirs = build_utils.ParseGypList(options.src_dirs)
      sources = build_utils.FindInDirectories(src_dirs, '*.java')
    elif options.java_files:
      sources = build_utils.ParseGypList(options.java_files)
    else:
      print 'One of --src-dirs or --java-files must be specified.'
      return 1
    rc = _RunLint(options.lint_path, options.config_path,
                  options.processed_config_path,
                  options.manifest_path, options.result_path,
                  options.product_dir, sources, options.jar_path,
                  options.resource_dir)

  if options.depfile:
    build_utils.WriteDepfile(
        options.depfile,
        build_utils.GetPythonDependencies())

  if options.stamp and not rc:
    build_utils.Touch(options.stamp)

  return rc if options.can_fail_build else 0


if __name__ == '__main__':
  sys.exit(main())
