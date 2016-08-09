# Copyright (c) 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Module containing utilities for apk packages."""

import os.path
import re

from pylib import cmd_helper
from pylib import constants
from pylib.sdk import aapt


_AAPT_PATH = os.path.join(constants.ANDROID_SDK_TOOLS, 'aapt')
_MANIFEST_ATTRIBUTE_RE = re.compile(
    r'\s*A: ([^\(\)= ]*)\([^\(\)= ]*\)="(.*)" \(Raw: .*\)$')
_MANIFEST_ELEMENT_RE = re.compile(r'\s*(?:E|N): (\S*) .*$')
_PACKAGE_NAME_RE = re.compile(r'package: .*name=\'(\S*)\'')
_SPLIT_NAME_RE = re.compile(r'package: .*split=\'(\S*)\'')


def GetPackageName(apk_path):
  """Returns the package name of the apk."""
  return ApkHelper(apk_path).GetPackageName()


# TODO(jbudorick): Deprecate and remove this function once callers have been
# converted to ApkHelper.GetInstrumentationName
def GetInstrumentationName(apk_path):
  """Returns the name of the Instrumentation in the apk."""
  return ApkHelper(apk_path).GetInstrumentationName()


def _ParseManifestFromApk(apk_path):
  aapt_output = aapt.Dump('xmltree', apk_path, 'AndroidManifest.xml')

  parsed_manifest = {}
  node_stack = [parsed_manifest]
  indent = '  '

  for line in aapt_output[1:]:
    if len(line) == 0:
      continue

    indent_depth = 0
    while line[(len(indent) * indent_depth):].startswith(indent):
      indent_depth += 1

    node_stack = node_stack[:indent_depth]
    node = node_stack[-1]

    m = _MANIFEST_ELEMENT_RE.match(line[len(indent) * indent_depth:])
    if m:
      if not m.group(1) in node:
        node[m.group(1)] = {}
      node_stack += [node[m.group(1)]]
      continue

    m = _MANIFEST_ATTRIBUTE_RE.match(line[len(indent) * indent_depth:])
    if m:
      if not m.group(1) in node:
        node[m.group(1)] = []
      node[m.group(1)].append(m.group(2))
      continue

  return parsed_manifest


class ApkHelper(object):
  def __init__(self, apk_path):
    self._apk_path = apk_path
    self._manifest = None
    self._package_name = None
    self._split_name = None

  def GetActivityName(self):
    """Returns the name of the Activity in the apk."""
    manifest_info = self._GetManifest()
    try:
      activity = (
          manifest_info['manifest']['application']['activity']
              ['android:name'][0])
    except KeyError:
      return None
    if '.' not in activity:
      activity = '%s.%s' % (self.GetPackageName(), activity)
    elif activity.startswith('.'):
      activity = '%s%s' % (self.GetPackageName(), activity)
    return activity

  def GetInstrumentationName(
      self, default='android.test.InstrumentationTestRunner'):
    """Returns the name of the Instrumentation in the apk."""
    manifest_info = self._GetManifest()
    try:
      return manifest_info['manifest']['instrumentation']['android:name'][0]
    except KeyError:
      return default

  def GetPackageName(self):
    """Returns the package name of the apk."""
    if self._package_name:
      return self._package_name

    aapt_output = aapt.Dump('badging', self._apk_path)
    for line in aapt_output:
      m = _PACKAGE_NAME_RE.match(line)
      if m:
        self._package_name = m.group(1)
        return self._package_name
    raise Exception('Failed to determine package name of %s' % self._apk_path)

  def GetSplitName(self):
    """Returns the name of the split of the apk."""
    if self._split_name:
      return self._split_name

    aapt_output = aapt.Dump('badging', self._apk_path)
    for line in aapt_output:
      m = _SPLIT_NAME_RE.match(line)
      if m:
        self._split_name = m.group(1)
        return self._split_name
    return None

  def _GetManifest(self):
    if not self._manifest:
      self._manifest = _ParseManifestFromApk(self._apk_path)
    return self._manifest

