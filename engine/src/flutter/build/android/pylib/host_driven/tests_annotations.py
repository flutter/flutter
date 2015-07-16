# Copyright (c) 2012 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Annotations for host-driven tests."""
# pylint: disable=W0212

import os


class AnnotatedFunctions(object):
  """A container for annotated methods."""
  _ANNOTATED = {}

  @staticmethod
  def _AddFunction(annotation, function):
    """Adds an annotated function to our container.

    Args:
      annotation: the annotation string.
      function: the function.
    Returns:
      The function passed in.
    """
    module_name = os.path.splitext(os.path.basename(
        function.__globals__['__file__']))[0]
    qualified_function_name = '.'.join([module_name, function.func_name])
    function_list = AnnotatedFunctions._ANNOTATED.get(annotation, [])
    function_list.append(qualified_function_name)
    AnnotatedFunctions._ANNOTATED[annotation] = function_list
    return function

  @staticmethod
  def IsAnnotated(annotation, qualified_function_name):
    """True if function name (module.function) contains the annotation.

    Args:
      annotation: the annotation string.
      qualified_function_name: the qualified function name.
    Returns:
      True if module.function contains the annotation.
    """
    return qualified_function_name in AnnotatedFunctions._ANNOTATED.get(
        annotation, [])

  @staticmethod
  def GetTestAnnotations(qualified_function_name):
    """Returns a list containing all annotations for the given function.

    Args:
      qualified_function_name: the qualified function name.
    Returns:
      List of all annotations for this function.
    """
    return [annotation
            for annotation, tests in AnnotatedFunctions._ANNOTATED.iteritems()
            if qualified_function_name in tests]


# The following functions are annotations used for the host-driven tests.
def Smoke(function):
  return AnnotatedFunctions._AddFunction('Smoke', function)


def SmallTest(function):
  return AnnotatedFunctions._AddFunction('SmallTest', function)


def MediumTest(function):
  return AnnotatedFunctions._AddFunction('MediumTest', function)


def LargeTest(function):
  return AnnotatedFunctions._AddFunction('LargeTest', function)


def EnormousTest(function):
  return AnnotatedFunctions._AddFunction('EnormousTest', function)


def FlakyTest(function):
  return AnnotatedFunctions._AddFunction('FlakyTest', function)


def DisabledTest(function):
  return AnnotatedFunctions._AddFunction('DisabledTest', function)


def Feature(feature_list):
  def _AddFeatures(function):
    for feature in feature_list:
      AnnotatedFunctions._AddFunction('Feature:%s' % feature, function)
    return AnnotatedFunctions._AddFunction('Feature', function)
  return _AddFeatures
