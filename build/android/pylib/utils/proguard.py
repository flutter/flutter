# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import os
import re
import tempfile

from pylib import constants
from pylib import cmd_helper


_PROGUARD_CLASS_RE = re.compile(r'\s*?- Program class:\s*([\S]+)$')
_PROGUARD_SUPERCLASS_RE = re.compile(r'\s*?  Superclass:\s*([\S]+)$')
_PROGUARD_SECTION_RE = re.compile(
    r'^(?:Interfaces|Constant Pool|Fields|Methods|Class file attributes) '
    r'\(count = \d+\):$')
_PROGUARD_METHOD_RE = re.compile(r'\s*?- Method:\s*(\S*)[(].*$')
_PROGUARD_ANNOTATION_RE = re.compile(r'\s*?- Annotation \[L(\S*);\]:$')
_PROGUARD_ANNOTATION_CONST_RE = (
    re.compile(r'\s*?- Constant element value.*$'))
_PROGUARD_ANNOTATION_VALUE_RE = re.compile(r'\s*?- \S+? \[(.*)\]$')

_PROGUARD_PATH_SDK = os.path.join(
    constants.ANDROID_SDK_ROOT, 'tools', 'proguard', 'lib', 'proguard.jar')
_PROGUARD_PATH_BUILT = (
    os.path.join(os.environ['ANDROID_BUILD_TOP'], 'external', 'proguard',
                 'lib', 'proguard.jar')
    if 'ANDROID_BUILD_TOP' in os.environ else None)
_PROGUARD_PATH = (
    _PROGUARD_PATH_SDK if os.path.exists(_PROGUARD_PATH_SDK)
    else _PROGUARD_PATH_BUILT)


def Dump(jar_path):
  """Dumps class and method information from a JAR into a dict via proguard.

  Args:
    jar_path: An absolute path to the JAR file to dump.
  Returns:
    A dict in the following format:
      {
        'classes': [
          {
            'class': '',
            'superclass': '',
            'annotations': {},
            'methods': [
              {
                'method': '',
                'annotations': {},
              },
              ...
            ],
          },
          ...
        ],
      }
  """

  with tempfile.NamedTemporaryFile() as proguard_output:
    cmd_helper.RunCmd(['java', '-jar',
                       _PROGUARD_PATH,
                       '-injars', jar_path,
                       '-dontshrink',
                       '-dontoptimize',
                       '-dontobfuscate',
                       '-dontpreverify',
                       '-dump', proguard_output.name])


    results = {
      'classes': [],
    }

    annotation = None
    annotation_has_value = False
    class_result = None
    method_result = None

    for line in proguard_output:
      line = line.strip('\r\n')

      m = _PROGUARD_CLASS_RE.match(line)
      if m:
        class_result = {
          'class': m.group(1).replace('/', '.'),
          'superclass': '',
          'annotations': {},
          'methods': [],
        }
        results['classes'].append(class_result)
        annotation = None
        annotation_has_value = False
        method_result = None
        continue

      if not class_result:
        continue

      m = _PROGUARD_SUPERCLASS_RE.match(line)
      if m:
        class_result['superclass'] = m.group(1).replace('/', '.')
        continue

      m = _PROGUARD_SECTION_RE.match(line)
      if m:
        annotation = None
        annotation_has_value = False
        method_result = None
        continue

      m = _PROGUARD_METHOD_RE.match(line)
      if m:
        method_result = {
          'method': m.group(1),
          'annotations': {},
        }
        class_result['methods'].append(method_result)
        annotation = None
        annotation_has_value = False
        continue

      m = _PROGUARD_ANNOTATION_RE.match(line)
      if m:
        # Ignore the annotation package.
        annotation = m.group(1).split('/')[-1]
        if method_result:
          method_result['annotations'][annotation] = None
        else:
          class_result['annotations'][annotation] = None
        continue

      if annotation:
        if not annotation_has_value:
          m = _PROGUARD_ANNOTATION_CONST_RE.match(line)
          annotation_has_value = bool(m)
        else:
          m = _PROGUARD_ANNOTATION_VALUE_RE.match(line)
          if m:
            if method_result:
              method_result['annotations'][annotation] = m.group(1)
            else:
              class_result['annotations'][annotation] = m.group(1)
          annotation_has_value = None

  return results

