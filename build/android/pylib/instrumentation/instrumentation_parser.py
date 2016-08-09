# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import logging
import re

# http://developer.android.com/reference/android/test/InstrumentationTestRunner.html
STATUS_CODE_START = 1
STATUS_CODE_OK = 0
STATUS_CODE_ERROR = -1
STATUS_CODE_FAILURE = -2

# http://developer.android.com/reference/android/app/Activity.html
RESULT_CODE_OK = -1
RESULT_CODE_CANCELED = 0

_INSTR_LINE_RE = re.compile('^\s*INSTRUMENTATION_([A-Z_]+): (.*)$')


class InstrumentationParser(object):

  def __init__(self, stream):
    """An incremental parser for the output of Android instrumentation tests.

    Example:

      stream = adb.IterShell('am instrument -r ...')
      parser = InstrumentationParser(stream)

      for code, bundle in parser.IterStatus():
        # do something with each instrumentation status
        print 'status:', code, bundle

      # do something with the final instrumentation result
      code, bundle = parser.GetResult()
      print 'result:', code, bundle

    Args:
      stream: a sequence of lines as produced by the raw output of an
        instrumentation test (e.g. by |am instrument -r| or |uiautomator|).
    """
    self._stream = stream
    self._code = None
    self._bundle = None

  def IterStatus(self):
    """Iterate over statuses as they are produced by the instrumentation test.

    Yields:
      A tuple (code, bundle) for each instrumentation status found in the
      output.
    """
    def join_bundle_values(bundle):
      for key in bundle:
        bundle[key] = '\n'.join(bundle[key])
      return bundle

    bundle = {'STATUS': {}, 'RESULT': {}}
    header = None
    key = None
    for line in self._stream:
      m = _INSTR_LINE_RE.match(line)
      if m:
        header, value = m.groups()
        key = None
        if header in ['STATUS', 'RESULT'] and '=' in value:
          key, value = value.split('=', 1)
          bundle[header][key] = [value]
        elif header == 'STATUS_CODE':
          yield int(value), join_bundle_values(bundle['STATUS'])
          bundle['STATUS'] = {}
        elif header == 'CODE':
          self._code = int(value)
        else:
          logging.warning('Unknown INSTRUMENTATION_%s line: %s', header, value)
      elif key is not None:
        bundle[header][key].append(line)

    self._bundle = join_bundle_values(bundle['RESULT'])

  def GetResult(self):
    """Return the final instrumentation result.

    Returns:
      A pair (code, bundle) with the final instrumentation result. The |code|
      may be None if no instrumentation result was found in the output.

    Raises:
      AssertionError if attempting to get the instrumentation result before
      exhausting |IterStatus| first.
    """
    assert self._bundle is not None, (
        'The IterStatus generator must be exhausted before reading the final'
        ' instrumentation result.')
    return self._code, self._bundle
