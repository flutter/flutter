# Copyright (c) 2012 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

from pylib.base import base_test_result


class InstrumentationTestResult(base_test_result.BaseTestResult):
  """Result information for a single instrumentation test."""

  def __init__(self, full_name, test_type, start_date, dur, log=''):
    """Construct an InstrumentationTestResult object.

    Args:
      full_name: Full name of the test.
      test_type: Type of the test result as defined in ResultType.
      start_date: Date in milliseconds when the test began running.
      dur: Duration of the test run in milliseconds.
      log: A string listing any errors.
    """
    super(InstrumentationTestResult, self).__init__(
        full_name, test_type, dur, log)
    name_pieces = full_name.rsplit('#')
    if len(name_pieces) > 1:
      self._test_name = name_pieces[1]
      self._class_name = name_pieces[0]
    else:
      self._class_name = full_name
      self._test_name = full_name
    self._start_date = start_date
