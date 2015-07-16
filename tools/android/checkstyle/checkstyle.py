# Copyright 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Script that is used by PRESUBMIT.py to run style checks on Java files."""

import os
import subprocess
import xml.dom.minidom


CHROMIUM_SRC = os.path.normpath(
    os.path.join(os.path.dirname(__file__),
                 os.pardir, os.pardir, os.pardir))
CHECKSTYLE_ROOT = os.path.join(CHROMIUM_SRC, 'third_party', 'checkstyle',
                               'checkstyle-6.5-all.jar')


def RunCheckstyle(input_api, output_api, style_file, black_list=None):
  if not os.path.exists(style_file):
    file_error = ('  Java checkstyle configuration file is missing: '
                  + style_file)
    return [output_api.PresubmitError(file_error)]

  # Filter out non-Java files and files that were deleted.
  java_files = [x.AbsoluteLocalPath() for x in input_api.AffectedSourceFiles(
                lambda f: input_api.FilterSourceFile(f, black_list=black_list))
                if os.path.splitext(x.LocalPath())[1] == '.java']
  if not java_files:
    return []

  # Run checkstyle
  checkstyle_env = os.environ.copy()
  checkstyle_env['JAVA_CMD'] = 'java'
  try:
    check = subprocess.Popen(['java', '-cp',
                              CHECKSTYLE_ROOT,
                              'com.puppycrawl.tools.checkstyle.Main', '-c',
                              style_file, '-f', 'xml'] + java_files,
                              stdout=subprocess.PIPE, env=checkstyle_env)
    stdout, _ = check.communicate()
  except OSError as e:
    import errno
    if e.errno == errno.ENOENT:
      install_error = ('  checkstyle is not installed. Please run '
                       'build/install-build-deps-android.sh')
      return [output_api.PresubmitPromptWarning(install_error)]

  result_errors = []
  result_warnings = []

  local_path = input_api.PresubmitLocalPath()
  root = xml.dom.minidom.parseString(stdout)
  for fileElement in root.getElementsByTagName('file'):
    fileName = fileElement.attributes['name'].value
    fileName = os.path.relpath(fileName, local_path)
    errors = fileElement.getElementsByTagName('error')
    for error in errors:
      line = error.attributes['line'].value
      column = ''
      if error.hasAttribute('column'):
        column = '%s:' % (error.attributes['column'].value)
      message = error.attributes['message'].value
      result = '  %s:%s:%s %s' % (fileName, line, column, message)

      severity = error.attributes['severity'].value
      if severity == 'error':
        result_errors.append(result)
      elif severity == 'warning':
        result_warnings.append(result)

  result = []
  if result_warnings:
    result.append(output_api.PresubmitPromptWarning('\n'.join(result_warnings)))
  if result_errors:
    result.append(output_api.PresubmitError('\n'.join(result_errors)))
  return result
