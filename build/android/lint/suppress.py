#!/usr/bin/env python
#
# Copyright (c) 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Add all generated lint_result.xml files to suppressions.xml"""


import collections
import optparse
import os
import sys
from xml.dom import minidom

_BUILD_ANDROID_DIR = os.path.join(os.path.dirname(__file__), '..')
sys.path.append(_BUILD_ANDROID_DIR)

from pylib import constants


_THIS_FILE = os.path.abspath(__file__)
_CONFIG_PATH = os.path.join(os.path.dirname(_THIS_FILE), 'suppressions.xml')
_DOC = (
    '\nSTOP! It looks like you want to suppress some lint errors:\n'
    '- Have you tried identifing the offending patch?\n'
    '  Ask the author for a fix and/or revert the patch.\n'
    '- It is preferred to add suppressions in the code instead of\n'
    '  sweeping it under the rug here. See:\n\n'
    '    http://developer.android.com/tools/debugging/improving-w-lint.html\n'
    '\n'
    'Still reading?\n'
    '- You can edit this file manually to suppress an issue\n'
    '  globally if it is not applicable to the project.\n'
    '- You can also automatically add issues found so for in the\n'
    '  build process by running:\n\n'
    '    ' + os.path.relpath(_THIS_FILE, constants.DIR_SOURCE_ROOT) + '\n\n'
    '  which will generate this file (Comments are not preserved).\n'
    '  Note: PRODUCT_DIR will be substituted at run-time with actual\n'
    '  directory path (e.g. out/Debug)\n'
)


_Issue = collections.namedtuple('Issue', ['severity', 'paths'])


def _ParseConfigFile(config_path):
  print 'Parsing %s' % config_path
  issues_dict = {}
  dom = minidom.parse(config_path)
  for issue in dom.getElementsByTagName('issue'):
    issue_id = issue.attributes['id'].value
    severity = issue.getAttribute('severity')
    paths = set(
        [p.attributes['path'].value for p in
         issue.getElementsByTagName('ignore')])
    issues_dict[issue_id] = _Issue(severity, paths)
  return issues_dict


def _ParseAndMergeResultFile(result_path, issues_dict):
  print 'Parsing and merging %s' % result_path
  dom = minidom.parse(result_path)
  for issue in dom.getElementsByTagName('issue'):
    issue_id = issue.attributes['id'].value
    severity = issue.attributes['severity'].value
    path = issue.getElementsByTagName('location')[0].attributes['file'].value
    if issue_id not in issues_dict:
      issues_dict[issue_id] = _Issue(severity, set())
    issues_dict[issue_id].paths.add(path)


def _WriteConfigFile(config_path, issues_dict):
  new_dom = minidom.getDOMImplementation().createDocument(None, 'lint', None)
  top_element = new_dom.documentElement
  top_element.appendChild(new_dom.createComment(_DOC))
  for issue_id in sorted(issues_dict.keys()):
    severity = issues_dict[issue_id].severity
    paths = issues_dict[issue_id].paths
    issue = new_dom.createElement('issue')
    issue.attributes['id'] = issue_id
    if severity:
      issue.attributes['severity'] = severity
    if severity == 'ignore':
      print 'Warning: [%s] is suppressed globally.' % issue_id
    else:
      for path in sorted(paths):
        ignore = new_dom.createElement('ignore')
        ignore.attributes['path'] = path
        issue.appendChild(ignore)
    top_element.appendChild(issue)

  with open(config_path, 'w') as f:
    f.write(new_dom.toprettyxml(indent='  ', encoding='utf-8'))
  print 'Updated %s' % config_path


def _Suppress(config_path, result_path):
  issues_dict = _ParseConfigFile(config_path)
  _ParseAndMergeResultFile(result_path, issues_dict)
  _WriteConfigFile(config_path, issues_dict)


def main():
  parser = optparse.OptionParser(usage='%prog RESULT-FILE')
  _, args = parser.parse_args()

  if len(args) != 1 or not os.path.exists(args[0]):
    parser.error('Must provide RESULT-FILE')

  _Suppress(_CONFIG_PATH, args[0])


if __name__ == '__main__':
  main()
