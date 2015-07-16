# Copyright 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Setup for instrumentation host-driven tests."""

import logging
import os
import sys
import types

from pylib.host_driven import test_case
from pylib.host_driven import test_info_collection
from pylib.host_driven import test_runner


def _GetPythonFiles(root, files):
  """Returns all files from |files| that end in 'Test.py'.

  Args:
    root: A directory name with python files.
    files: A list of file names.

  Returns:
    A list with all python files that match the testing naming scheme.
  """
  return [os.path.join(root, f) for f in files if f.endswith('Test.py')]


def _InferImportNameFromFile(python_file):
  """Given a file, infer the import name for that file.

  Example: /usr/foo/bar/baz.py -> baz.

  Args:
    python_file: Path to the Python file, ostensibly to import later.

  Returns:
    The module name for the given file.
  """
  return os.path.splitext(os.path.basename(python_file))[0]


def _GetTestModules(host_driven_test_root, is_official_build):
  """Retrieve a list of python modules that match the testing naming scheme.

  Walks the location of host-driven tests, imports them, and provides the list
  of imported modules to the caller.

  Args:
    host_driven_test_root: The path to walk, looking for the
        pythonDrivenTests or host_driven_tests directory
    is_official_build: Whether to run only those tests marked 'official'

  Returns:
    A list of python modules under |host_driven_test_root| which match the
    testing naming scheme. Each module should define one or more classes that
    derive from HostDrivenTestCase.
  """
  # By default run all host-driven tests under pythonDrivenTests or
  # host_driven_tests.
  host_driven_test_file_list = []
  for root, _, files in os.walk(host_driven_test_root):
    if (root.endswith('host_driven_tests') or
        root.endswith('pythonDrivenTests') or
        (is_official_build and (root.endswith('pythonDrivenTests/official') or
                                root.endswith('host_driven_tests/official')))):
      host_driven_test_file_list += _GetPythonFiles(root, files)
  host_driven_test_file_list.sort()

  test_module_list = [_GetModuleFromFile(test_file)
                      for test_file in host_driven_test_file_list]
  return test_module_list


def _GetModuleFromFile(python_file):
  """Gets the python module associated with a file by importing it.

  Args:
    python_file: File to import.

  Returns:
    The module object.
  """
  sys.path.append(os.path.dirname(python_file))
  import_name = _InferImportNameFromFile(python_file)
  return __import__(import_name)


def _GetTestsFromClass(test_case_class, **kwargs):
  """Returns one test object for each test method in |test_case_class|.

  Test methods are methods on the class which begin with 'test'.

  Args:
    test_case_class: Class derived from HostDrivenTestCase which contains zero
        or more test methods.
    kwargs: Keyword args to pass into the constructor of test cases.

  Returns:
    A list of test case objects, each initialized for a particular test method.
  """
  test_names = [m for m in dir(test_case_class)
                if _IsTestMethod(m, test_case_class)]
  return [test_case_class(name, **kwargs) for name in test_names]


def _GetTestsFromModule(test_module, **kwargs):
  """Gets a list of test objects from |test_module|.

  Args:
    test_module: Module from which to get the set of test methods.
    kwargs: Keyword args to pass into the constructor of test cases.

  Returns:
    A list of test case objects each initialized for a particular test method
    defined in |test_module|.
  """

  tests = []
  for name in dir(test_module):
    attr = getattr(test_module, name)
    if _IsTestCaseClass(attr):
      tests.extend(_GetTestsFromClass(attr, **kwargs))
  return tests


def _IsTestCaseClass(test_class):
  return (type(test_class) is types.TypeType and
          issubclass(test_class, test_case.HostDrivenTestCase) and
          test_class is not test_case.HostDrivenTestCase)


def _IsTestMethod(attrname, test_case_class):
  """Checks whether this is a valid test method.

  Args:
    attrname: The method name.
    test_case_class: The test case class.

  Returns:
    True if test_case_class.'attrname' is callable and it starts with 'test';
    False otherwise.
  """
  attr = getattr(test_case_class, attrname)
  return callable(attr) and attrname.startswith('test')


def _GetAllTests(test_root, is_official_build, **kwargs):
  """Retrieve a list of host-driven tests defined under |test_root|.

  Args:
    test_root: Path which contains host-driven test files.
    is_official_build: Whether this is an official build.
    kwargs: Keyword args to pass into the constructor of test cases.

  Returns:
    List of test case objects, one for each available test method.
  """
  if not test_root:
    return []
  all_tests = []
  test_module_list = _GetTestModules(test_root, is_official_build)
  for module in test_module_list:
    all_tests.extend(_GetTestsFromModule(module, **kwargs))
  return all_tests


def InstrumentationSetup(host_driven_test_root, official_build,
                         instrumentation_options):
  """Creates a list of host-driven instrumentation tests and a runner factory.

  Args:
    host_driven_test_root: Directory where the host-driven tests are.
    official_build: True if this is an official build.
    instrumentation_options: An InstrumentationOptions object.

  Returns:
    A tuple of (TestRunnerFactory, tests).
  """

  test_collection = test_info_collection.TestInfoCollection()
  all_tests = _GetAllTests(
      host_driven_test_root, official_build,
      instrumentation_options=instrumentation_options)
  test_collection.AddTests(all_tests)

  available_tests = test_collection.GetAvailableTests(
      instrumentation_options.annotations,
      instrumentation_options.exclude_annotations,
      instrumentation_options.test_filter)
  logging.debug('All available tests: ' + str(
      [t.tagged_name for t in available_tests]))

  def TestRunnerFactory(device, shard_index):
    return test_runner.HostDrivenTestRunner(
        device, shard_index,
        instrumentation_options.tool)

  return (TestRunnerFactory, available_tests)
