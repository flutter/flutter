# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import json
import os
import re
import subprocess
import sys


class MockInputApi(object):
  """Mock class for the InputApi class.

  This class can be used for unittests for presubmit by initializing the files
  attribute as the list of changed files.
  """

  def __init__(self):
    self.json = json
    self.re = re
    self.os_path = os.path
    self.python_executable = sys.executable
    self.subprocess = subprocess
    self.files = []
    self.is_committing = False

  def AffectedFiles(self, file_filter=None):
    return self.files

  def PresubmitLocalPath(self):
    return os.path.dirname(__file__)

  def ReadFile(self, filename, mode='rU'):
    for file_ in self.files:
      if file_.LocalPath() == filename:
        return '\n'.join(file_.NewContents())
    # Otherwise, file is not in our mock API.
    raise IOError, "No such file or directory: '%s'" % filename


class MockOutputApi(object):
  """Mock class for the OutputApi class.

  An instance of this class can be passed to presubmit unittests for outputing
  various types of results.
  """

  class PresubmitResult(object):
    def __init__(self, message, items=None, long_text=''):
      self.message = message
      self.items = items
      self.long_text = long_text

  class PresubmitError(PresubmitResult):
    def __init__(self, message, items, long_text=''):
      MockOutputApi.PresubmitResult.__init__(self, message, items, long_text)
      self.type = 'error'

  class PresubmitPromptWarning(PresubmitResult):
    def __init__(self, message, items, long_text=''):
      MockOutputApi.PresubmitResult.__init__(self, message, items, long_text)
      self.type = 'warning'

  class PresubmitNotifyResult(PresubmitResult):
    def __init__(self, message, items, long_text=''):
      MockOutputApi.PresubmitResult.__init__(self, message, items, long_text)
      self.type = 'notify'

  class PresubmitPromptOrNotify(PresubmitResult):
    def __init__(self, message, items, long_text=''):
      MockOutputApi.PresubmitResult.__init__(self, message, items, long_text)
      self.type = 'promptOrNotify'


class MockFile(object):
  """Mock class for the File class.

  This class can be used to form the mock list of changed files in
  MockInputApi for presubmit unittests.
  """

  def __init__(self, local_path, new_contents):
    self._local_path = local_path
    self._new_contents = new_contents
    self._changed_contents = [(i + 1, l) for i, l in enumerate(new_contents)]

  def ChangedContents(self):
    return self._changed_contents

  def NewContents(self):
    return self._new_contents

  def LocalPath(self):
    return self._local_path


class MockChange(object):
  """Mock class for Change class.

  This class can be used in presubmit unittests to mock the query of the
  current change.
  """

  def __init__(self, changed_files):
    self._changed_files = changed_files

  def LocalPaths(self):
    return self._changed_files
