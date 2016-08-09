# Copyright (c) 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Helper class for instrumenation test jar."""
# pylint: disable=W0702

import logging
import os
import pickle
import re
import sys

from pylib import cmd_helper
from pylib import constants
from pylib.device import device_utils
from pylib.utils import md5sum
from pylib.utils import proguard

sys.path.insert(0,
                os.path.join(constants.DIR_SOURCE_ROOT,
                             'build', 'util', 'lib', 'common'))

import unittest_util # pylint: disable=F0401

# If you change the cached output of proguard, increment this number
PICKLE_FORMAT_VERSION = 4


class TestJar(object):
  _ANNOTATIONS = frozenset(
      ['Smoke', 'SmallTest', 'MediumTest', 'LargeTest', 'EnormousTest',
       'FlakyTest', 'DisabledTest', 'Manual', 'PerfTest', 'HostDrivenTest',
       'IntegrationTest'])
  _DEFAULT_ANNOTATION = 'SmallTest'
  _PROGUARD_CLASS_RE = re.compile(r'\s*?- Program class:\s*([\S]+)$')
  _PROGUARD_SUPERCLASS_RE = re.compile(r'\s*?  Superclass:\s*([\S]+)$')
  _PROGUARD_METHOD_RE = re.compile(r'\s*?- Method:\s*(\S*)[(].*$')
  _PROGUARD_ANNOTATION_RE = re.compile(r'\s*?- Annotation \[L(\S*);\]:$')
  _PROGUARD_ANNOTATION_CONST_RE = (
      re.compile(r'\s*?- Constant element value.*$'))
  _PROGUARD_ANNOTATION_VALUE_RE = re.compile(r'\s*?- \S+? \[(.*)\]$')

  def __init__(self, jar_path):
    if not os.path.exists(jar_path):
      raise Exception('%s not found, please build it' % jar_path)

    self._PROGUARD_PATH = os.path.join(constants.ANDROID_SDK_ROOT,
                                       'tools/proguard/lib/proguard.jar')
    if not os.path.exists(self._PROGUARD_PATH):
      self._PROGUARD_PATH = os.path.join(os.environ['ANDROID_BUILD_TOP'],
                                         'external/proguard/lib/proguard.jar')
    self._jar_path = jar_path
    self._pickled_proguard_name = self._jar_path + '-proguard.pickle'
    self._test_methods = {}
    if not self._GetCachedProguardData():
      self._GetProguardData()

  def _GetCachedProguardData(self):
    if (os.path.exists(self._pickled_proguard_name) and
        (os.path.getmtime(self._pickled_proguard_name) >
         os.path.getmtime(self._jar_path))):
      logging.info('Loading cached proguard output from %s',
                   self._pickled_proguard_name)
      try:
        with open(self._pickled_proguard_name, 'r') as r:
          d = pickle.loads(r.read())
        jar_md5 = md5sum.CalculateHostMd5Sums(
          self._jar_path)[os.path.realpath(self._jar_path)]
        if (d['JAR_MD5SUM'] == jar_md5 and
            d['VERSION'] == PICKLE_FORMAT_VERSION):
          self._test_methods = d['TEST_METHODS']
          return True
      except:
        logging.warning('PICKLE_FORMAT_VERSION has changed, ignoring cache')
    return False

  def _GetProguardData(self):
    logging.info('Retrieving test methods via proguard.')

    p = proguard.Dump(self._jar_path)

    class_lookup = dict((c['class'], c) for c in p['classes'])
    def recursive_get_annotations(c):
      s = c['superclass']
      if s in class_lookup:
        a = recursive_get_annotations(class_lookup[s])
      else:
        a = {}
      a.update(c['annotations'])
      return a

    test_classes = (c for c in p['classes']
                    if c['class'].endswith('Test'))
    for c in test_classes:
      class_annotations = recursive_get_annotations(c)
      test_methods = (m for m in c['methods']
                      if m['method'].startswith('test'))
      for m in test_methods:
        qualified_method = '%s#%s' % (c['class'], m['method'])
        annotations = dict(class_annotations)
        annotations.update(m['annotations'])
        self._test_methods[qualified_method] = m
        self._test_methods[qualified_method]['annotations'] = annotations

    logging.info('Storing proguard output to %s', self._pickled_proguard_name)
    d = {'VERSION': PICKLE_FORMAT_VERSION,
         'TEST_METHODS': self._test_methods,
         'JAR_MD5SUM':
              md5sum.CalculateHostMd5Sums(
                self._jar_path)[os.path.realpath(self._jar_path)]}
    with open(self._pickled_proguard_name, 'w') as f:
      f.write(pickle.dumps(d))

  @staticmethod
  def _IsTestMethod(test):
    class_name, method = test.split('#')
    return class_name.endswith('Test') and method.startswith('test')

  def GetTestAnnotations(self, test):
    """Returns a list of all annotations for the given |test|. May be empty."""
    if not self._IsTestMethod(test) or not test in self._test_methods:
      return []
    return self._test_methods[test]['annotations']

  @staticmethod
  def _AnnotationsMatchFilters(annotation_filter_list, annotations):
    """Checks if annotations match any of the filters."""
    if not annotation_filter_list:
      return True
    for annotation_filter in annotation_filter_list:
      filters = annotation_filter.split('=')
      if len(filters) == 2:
        key = filters[0]
        value_list = filters[1].split(',')
        for value in value_list:
          if key in annotations and value == annotations[key]:
            return True
      elif annotation_filter in annotations:
        return True
    return False

  def GetAnnotatedTests(self, annotation_filter_list):
    """Returns a list of all tests that match the given annotation filters."""
    return [test for test in self.GetTestMethods()
            if self._IsTestMethod(test) and self._AnnotationsMatchFilters(
                annotation_filter_list, self.GetTestAnnotations(test))]

  def GetTestMethods(self):
    """Returns a dict of all test methods and relevant attributes.

    Test methods are retrieved as Class#testMethod.
    """
    return self._test_methods

  def _GetTestsMissingAnnotation(self):
    """Get a list of test methods with no known annotations."""
    tests_missing_annotations = []
    for test_method in self.GetTestMethods().iterkeys():
      annotations_ = frozenset(self.GetTestAnnotations(test_method).iterkeys())
      if (annotations_.isdisjoint(self._ANNOTATIONS) and
          not self.IsHostDrivenTest(test_method)):
        tests_missing_annotations.append(test_method)
    return sorted(tests_missing_annotations)

  def _IsTestValidForSdkRange(self, test_name, attached_min_sdk_level):
    required_min_sdk_level = int(
        self.GetTestAnnotations(test_name).get('MinAndroidSdkLevel', 0))
    return (required_min_sdk_level is None or
            attached_min_sdk_level >= required_min_sdk_level)

  def GetAllMatchingTests(self, annotation_filter_list,
                          exclude_annotation_list, test_filter):
    """Get a list of tests matching any of the annotations and the filter.

    Args:
      annotation_filter_list: List of test annotations. A test must have at
        least one of these annotations. A test without any annotations is
        considered to be SmallTest.
      exclude_annotation_list: List of test annotations. A test must not have
        any of these annotations.
      test_filter: Filter used for partial matching on the test method names.

    Returns:
      List of all matching tests.
    """
    if annotation_filter_list:
      available_tests = self.GetAnnotatedTests(annotation_filter_list)
      # Include un-annotated tests in SmallTest.
      if annotation_filter_list.count(self._DEFAULT_ANNOTATION) > 0:
        for test in self._GetTestsMissingAnnotation():
          logging.warning(
              '%s has no annotations. Assuming "%s".', test,
              self._DEFAULT_ANNOTATION)
          available_tests.append(test)
    else:
      available_tests = [m for m in self.GetTestMethods()
                         if not self.IsHostDrivenTest(m)]

    if exclude_annotation_list:
      excluded_tests = self.GetAnnotatedTests(exclude_annotation_list)
      available_tests = list(set(available_tests) - set(excluded_tests))

    tests = []
    if test_filter:
      # |available_tests| are in adb instrument format: package.path.class#test.

      # Maps a 'class.test' name to each 'package.path.class#test' name.
      sanitized_test_names = dict([
          (t.split('.')[-1].replace('#', '.'), t) for t in available_tests])
      # Filters 'class.test' names and populates |tests| with the corresponding
      # 'package.path.class#test' names.
      tests = [
          sanitized_test_names[t] for t in unittest_util.FilterTestNames(
              sanitized_test_names.keys(), test_filter.replace('#', '.'))]
    else:
      tests = available_tests

    # Filter out any tests with SDK level requirements that don't match the set
    # of attached devices.
    devices = device_utils.DeviceUtils.parallel()
    min_sdk_version = min(devices.build_version_sdk.pGet(None))
    tests = [t for t in tests
             if self._IsTestValidForSdkRange(t, min_sdk_version)]

    return tests

  @staticmethod
  def IsHostDrivenTest(test):
    return 'pythonDrivenTests' in test
