# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

#
# Most of this file was ported over from Blink's
# Tools/Scripts/webkitpy/layout_tests/layout_package/json_results_generator.py
# Tools/Scripts/webkitpy/common/net/file_uploader.py
#

import json
import logging
import mimetypes
import os
import time
import urllib2

_log = logging.getLogger(__name__)

_JSON_PREFIX = 'ADD_RESULTS('
_JSON_SUFFIX = ');'


def HasJSONWrapper(string):
  return string.startswith(_JSON_PREFIX) and string.endswith(_JSON_SUFFIX)


def StripJSONWrapper(json_content):
  # FIXME: Kill this code once the server returns json instead of jsonp.
  if HasJSONWrapper(json_content):
    return json_content[len(_JSON_PREFIX):len(json_content) - len(_JSON_SUFFIX)]
  return json_content


def WriteJSON(json_object, file_path, callback=None):
  # Specify separators in order to get compact encoding.
  json_string = json.dumps(json_object, separators=(',', ':'))
  if callback:
    json_string = callback + '(' + json_string + ');'
  with open(file_path, 'w') as fp:
    fp.write(json_string)


def ConvertTrieToFlatPaths(trie, prefix=None):
  """Flattens the trie of paths, prepending a prefix to each."""
  result = {}
  for name, data in trie.iteritems():
    if prefix:
      name = prefix + '/' + name

    if len(data) and not 'results' in data:
      result.update(ConvertTrieToFlatPaths(data, name))
    else:
      result[name] = data

  return result


def AddPathToTrie(path, value, trie):
  """Inserts a single path and value into a directory trie structure."""
  if not '/' in path:
    trie[path] = value
    return

  directory, _slash, rest = path.partition('/')
  if not directory in trie:
    trie[directory] = {}
  AddPathToTrie(rest, value, trie[directory])


def TestTimingsTrie(individual_test_timings):
  """Breaks a test name into dicts by directory

  foo/bar/baz.html: 1ms
  foo/bar/baz1.html: 3ms

  becomes
  foo: {
      bar: {
          baz.html: 1,
          baz1.html: 3
      }
  }
  """
  trie = {}
  for test_result in individual_test_timings:
    test = test_result.test_name

    AddPathToTrie(test, int(1000 * test_result.test_run_time), trie)

  return trie


class TestResult(object):
  """A simple class that represents a single test result."""

  # Test modifier constants.
  (NONE, FAILS, FLAKY, DISABLED) = range(4)

  def __init__(self, test, failed=False, elapsed_time=0):
    self.test_name = test
    self.failed = failed
    self.test_run_time = elapsed_time

    test_name = test
    try:
      test_name = test.split('.')[1]
    except IndexError:
      _log.warn('Invalid test name: %s.', test)

    if test_name.startswith('FAILS_'):
      self.modifier = self.FAILS
    elif test_name.startswith('FLAKY_'):
      self.modifier = self.FLAKY
    elif test_name.startswith('DISABLED_'):
      self.modifier = self.DISABLED
    else:
      self.modifier = self.NONE

  def Fixable(self):
    return self.failed or self.modifier == self.DISABLED


class JSONResultsGeneratorBase(object):
  """A JSON results generator for generic tests."""

  MAX_NUMBER_OF_BUILD_RESULTS_TO_LOG = 750
  # Min time (seconds) that will be added to the JSON.
  MIN_TIME = 1

  # Note that in non-chromium tests those chars are used to indicate
  # test modifiers (FAILS, FLAKY, etc) but not actual test results.
  PASS_RESULT = 'P'
  SKIP_RESULT = 'X'
  FAIL_RESULT = 'F'
  FLAKY_RESULT = 'L'
  NO_DATA_RESULT = 'N'

  MODIFIER_TO_CHAR = {TestResult.NONE: PASS_RESULT,
                      TestResult.DISABLED: SKIP_RESULT,
                      TestResult.FAILS: FAIL_RESULT,
                      TestResult.FLAKY: FLAKY_RESULT}

  VERSION = 4
  VERSION_KEY = 'version'
  RESULTS = 'results'
  TIMES = 'times'
  BUILD_NUMBERS = 'buildNumbers'
  TIME = 'secondsSinceEpoch'
  TESTS = 'tests'

  FIXABLE_COUNT = 'fixableCount'
  FIXABLE = 'fixableCounts'
  ALL_FIXABLE_COUNT = 'allFixableCount'

  RESULTS_FILENAME = 'results.json'
  TIMES_MS_FILENAME = 'times_ms.json'
  INCREMENTAL_RESULTS_FILENAME = 'incremental_results.json'

  # line too long pylint: disable=line-too-long
  URL_FOR_TEST_LIST_JSON = (
      'http://%s/testfile?builder=%s&name=%s&testlistjson=1&testtype=%s&master=%s')
  # pylint: enable=line-too-long

  def __init__(self, builder_name, build_name, build_number,
               results_file_base_path, builder_base_url,
               test_results_map, svn_repositories=None,
               test_results_server=None,
               test_type='',
               master_name=''):
    """Modifies the results.json file. Grabs it off the archive directory
    if it is not found locally.

    Args
      builder_name: the builder name (e.g. Webkit).
      build_name: the build name (e.g. webkit-rel).
      build_number: the build number.
      results_file_base_path: Absolute path to the directory containing the
          results json file.
      builder_base_url: the URL where we have the archived test results.
          If this is None no archived results will be retrieved.
      test_results_map: A dictionary that maps test_name to TestResult.
      svn_repositories: A (json_field_name, svn_path) pair for SVN
          repositories that tests rely on.  The SVN revision will be
          included in the JSON with the given json_field_name.
      test_results_server: server that hosts test results json.
      test_type: test type string (e.g. 'layout-tests').
      master_name: the name of the buildbot master.
    """
    self._builder_name = builder_name
    self._build_name = build_name
    self._build_number = build_number
    self._builder_base_url = builder_base_url
    self._results_directory = results_file_base_path

    self._test_results_map = test_results_map
    self._test_results = test_results_map.values()

    self._svn_repositories = svn_repositories
    if not self._svn_repositories:
      self._svn_repositories = {}

    self._test_results_server = test_results_server
    self._test_type = test_type
    self._master_name = master_name

    self._archived_results = None

  def GenerateJSONOutput(self):
    json_object = self.GetJSON()
    if json_object:
      file_path = (
          os.path.join(
              self._results_directory,
              self.INCREMENTAL_RESULTS_FILENAME))
      WriteJSON(json_object, file_path)

  def GenerateTimesMSFile(self):
    times = TestTimingsTrie(self._test_results_map.values())
    file_path = os.path.join(self._results_directory, self.TIMES_MS_FILENAME)
    WriteJSON(times, file_path)

  def GetJSON(self):
    """Gets the results for the results.json file."""
    results_json = {}

    if not results_json:
      results_json, error = self._GetArchivedJSONResults()
      if error:
        # If there was an error don't write a results.json
        # file at all as it would lose all the information on the
        # bot.
        _log.error('Archive directory is inaccessible. Not '
                   'modifying or clobbering the results.json '
                   'file: ' + str(error))
        return None

    builder_name = self._builder_name
    if results_json and builder_name not in results_json:
      _log.debug('Builder name (%s) is not in the results.json file.'
                 % builder_name)

    self._ConvertJSONToCurrentVersion(results_json)

    if builder_name not in results_json:
      results_json[builder_name] = (
          self._CreateResultsForBuilderJSON())

    results_for_builder = results_json[builder_name]

    if builder_name:
      self._InsertGenericMetaData(results_for_builder)

    self._InsertFailureSummaries(results_for_builder)

    # Update the all failing tests with result type and time.
    tests = results_for_builder[self.TESTS]
    all_failing_tests = self._GetFailedTestNames()
    all_failing_tests.update(ConvertTrieToFlatPaths(tests))

    for test in all_failing_tests:
      self._InsertTestTimeAndResult(test, tests)

    return results_json

  def SetArchivedResults(self, archived_results):
    self._archived_results = archived_results

  def UploadJSONFiles(self, json_files):
    """Uploads the given json_files to the test_results_server (if the
    test_results_server is given)."""
    if not self._test_results_server:
      return

    if not self._master_name:
      _log.error(
          '--test-results-server was set, but --master-name was not.  Not '
          'uploading JSON files.')
      return

    _log.info('Uploading JSON files for builder: %s', self._builder_name)
    attrs = [('builder', self._builder_name),
             ('testtype', self._test_type),
             ('master', self._master_name)]

    files = [(json_file, os.path.join(self._results_directory, json_file))
             for json_file in json_files]

    url = 'http://%s/testfile/upload' % self._test_results_server
    # Set uploading timeout in case appengine server is having problems.
    # 120 seconds are more than enough to upload test results.
    uploader = _FileUploader(url, 120)
    try:
      response = uploader.UploadAsMultipartFormData(files, attrs)
      if response:
        if response.code == 200:
          _log.info('JSON uploaded.')
        else:
          _log.debug(
              "JSON upload failed, %d: '%s'" %
              (response.code, response.read()))
      else:
        _log.error('JSON upload failed; no response returned')
    except Exception, err:
      _log.error('Upload failed: %s' % err)
      return

  def _GetTestTiming(self, test_name):
    """Returns test timing data (elapsed time) in second
    for the given test_name."""
    if test_name in self._test_results_map:
      # Floor for now to get time in seconds.
      return int(self._test_results_map[test_name].test_run_time)
    return 0

  def _GetFailedTestNames(self):
    """Returns a set of failed test names."""
    return set([r.test_name for r in self._test_results if r.failed])

  def _GetModifierChar(self, test_name):
    """Returns a single char (e.g. SKIP_RESULT, FAIL_RESULT,
    PASS_RESULT, NO_DATA_RESULT, etc) that indicates the test modifier
    for the given test_name.
    """
    if test_name not in self._test_results_map:
      return self.__class__.NO_DATA_RESULT

    test_result = self._test_results_map[test_name]
    if test_result.modifier in self.MODIFIER_TO_CHAR.keys():
      return self.MODIFIER_TO_CHAR[test_result.modifier]

    return self.__class__.PASS_RESULT

  def _get_result_char(self, test_name):
    """Returns a single char (e.g. SKIP_RESULT, FAIL_RESULT,
    PASS_RESULT, NO_DATA_RESULT, etc) that indicates the test result
    for the given test_name.
    """
    if test_name not in self._test_results_map:
      return self.__class__.NO_DATA_RESULT

    test_result = self._test_results_map[test_name]
    if test_result.modifier == TestResult.DISABLED:
      return self.__class__.SKIP_RESULT

    if test_result.failed:
      return self.__class__.FAIL_RESULT

    return self.__class__.PASS_RESULT

  def _GetSVNRevision(self, in_directory):
    """Returns the svn revision for the given directory.

    Args:
      in_directory: The directory where svn is to be run.
    """
    # This is overridden in flakiness_dashboard_results_uploader.py.
    raise NotImplementedError()

  def _GetArchivedJSONResults(self):
    """Download JSON file that only contains test
    name list from test-results server. This is for generating incremental
    JSON so the file generated has info for tests that failed before but
    pass or are skipped from current run.

    Returns (archived_results, error) tuple where error is None if results
    were successfully read.
    """
    results_json = {}
    old_results = None
    error = None

    if not self._test_results_server:
      return {}, None

    results_file_url = (self.URL_FOR_TEST_LIST_JSON %
                        (urllib2.quote(self._test_results_server),
                         urllib2.quote(self._builder_name),
                         self.RESULTS_FILENAME,
                         urllib2.quote(self._test_type),
                         urllib2.quote(self._master_name)))

    try:
      # FIXME: We should talk to the network via a Host object.
      results_file = urllib2.urlopen(results_file_url)
      old_results = results_file.read()
    except urllib2.HTTPError, http_error:
      # A non-4xx status code means the bot is hosed for some reason
      # and we can't grab the results.json file off of it.
      if http_error.code < 400 and http_error.code >= 500:
        error = http_error
    except urllib2.URLError, url_error:
      error = url_error

    if old_results:
      # Strip the prefix and suffix so we can get the actual JSON object.
      old_results = StripJSONWrapper(old_results)

      try:
        results_json = json.loads(old_results)
      except Exception:
        _log.debug('results.json was not valid JSON. Clobbering.')
        # The JSON file is not valid JSON. Just clobber the results.
        results_json = {}
    else:
      _log.debug('Old JSON results do not exist. Starting fresh.')
      results_json = {}

    return results_json, error

  def _InsertFailureSummaries(self, results_for_builder):
    """Inserts aggregate pass/failure statistics into the JSON.
    This method reads self._test_results and generates
    FIXABLE, FIXABLE_COUNT and ALL_FIXABLE_COUNT entries.

    Args:
      results_for_builder: Dictionary containing the test results for a
          single builder.
    """
    # Insert the number of tests that failed or skipped.
    fixable_count = len([r for r in self._test_results if r.Fixable()])
    self._InsertItemIntoRawList(results_for_builder,
                                fixable_count, self.FIXABLE_COUNT)

    # Create a test modifiers (FAILS, FLAKY etc) summary dictionary.
    entry = {}
    for test_name in self._test_results_map.iterkeys():
      result_char = self._GetModifierChar(test_name)
      entry[result_char] = entry.get(result_char, 0) + 1

    # Insert the pass/skip/failure summary dictionary.
    self._InsertItemIntoRawList(results_for_builder, entry,
                                self.FIXABLE)

    # Insert the number of all the tests that are supposed to pass.
    all_test_count = len(self._test_results)
    self._InsertItemIntoRawList(results_for_builder,
                                all_test_count, self.ALL_FIXABLE_COUNT)

  def _InsertItemIntoRawList(self, results_for_builder, item, key):
    """Inserts the item into the list with the given key in the results for
    this builder. Creates the list if no such list exists.

    Args:
      results_for_builder: Dictionary containing the test results for a
          single builder.
      item: Number or string to insert into the list.
      key: Key in results_for_builder for the list to insert into.
    """
    if key in results_for_builder:
      raw_list = results_for_builder[key]
    else:
      raw_list = []

    raw_list.insert(0, item)
    raw_list = raw_list[:self.MAX_NUMBER_OF_BUILD_RESULTS_TO_LOG]
    results_for_builder[key] = raw_list

  def _InsertItemRunLengthEncoded(self, item, encoded_results):
    """Inserts the item into the run-length encoded results.

    Args:
      item: String or number to insert.
      encoded_results: run-length encoded results. An array of arrays, e.g.
          [[3,'A'],[1,'Q']] encodes AAAQ.
    """
    if len(encoded_results) and item == encoded_results[0][1]:
      num_results = encoded_results[0][0]
      if num_results <= self.MAX_NUMBER_OF_BUILD_RESULTS_TO_LOG:
        encoded_results[0][0] = num_results + 1
    else:
      # Use a list instead of a class for the run-length encoding since
      # we want the serialized form to be concise.
      encoded_results.insert(0, [1, item])

  def _InsertGenericMetaData(self, results_for_builder):
    """ Inserts generic metadata (such as version number, current time etc)
    into the JSON.

    Args:
      results_for_builder: Dictionary containing the test results for
          a single builder.
    """
    self._InsertItemIntoRawList(results_for_builder,
                                self._build_number, self.BUILD_NUMBERS)

    # Include SVN revisions for the given repositories.
    for (name, path) in self._svn_repositories:
      # Note: for JSON file's backward-compatibility we use 'chrome' rather
      # than 'chromium' here.
      lowercase_name = name.lower()
      if lowercase_name == 'chromium':
        lowercase_name = 'chrome'
      self._InsertItemIntoRawList(results_for_builder,
                                  self._GetSVNRevision(path),
                                  lowercase_name + 'Revision')

    self._InsertItemIntoRawList(results_for_builder,
                                int(time.time()),
                                self.TIME)

  def _InsertTestTimeAndResult(self, test_name, tests):
    """ Insert a test item with its results to the given tests dictionary.

    Args:
      tests: Dictionary containing test result entries.
    """

    result = self._get_result_char(test_name)
    test_time = self._GetTestTiming(test_name)

    this_test = tests
    for segment in test_name.split('/'):
      if segment not in this_test:
        this_test[segment] = {}
      this_test = this_test[segment]

    if not len(this_test):
      self._PopulateResultsAndTimesJSON(this_test)

    if self.RESULTS in this_test:
      self._InsertItemRunLengthEncoded(result, this_test[self.RESULTS])
    else:
      this_test[self.RESULTS] = [[1, result]]

    if self.TIMES in this_test:
      self._InsertItemRunLengthEncoded(test_time, this_test[self.TIMES])
    else:
      this_test[self.TIMES] = [[1, test_time]]

  def _ConvertJSONToCurrentVersion(self, results_json):
    """If the JSON does not match the current version, converts it to the
    current version and adds in the new version number.
    """
    if self.VERSION_KEY in results_json:
      archive_version = results_json[self.VERSION_KEY]
      if archive_version == self.VERSION:
        return
    else:
      archive_version = 3

    # version 3->4
    if archive_version == 3:
      for results in results_json.values():
        self._ConvertTestsToTrie(results)

    results_json[self.VERSION_KEY] = self.VERSION

  def _ConvertTestsToTrie(self, results):
    if not self.TESTS in results:
      return

    test_results = results[self.TESTS]
    test_results_trie = {}
    for test in test_results.iterkeys():
      single_test_result = test_results[test]
      AddPathToTrie(test, single_test_result, test_results_trie)

    results[self.TESTS] = test_results_trie

  def _PopulateResultsAndTimesJSON(self, results_and_times):
    results_and_times[self.RESULTS] = []
    results_and_times[self.TIMES] = []
    return results_and_times

  def _CreateResultsForBuilderJSON(self):
    results_for_builder = {}
    results_for_builder[self.TESTS] = {}
    return results_for_builder

  def _RemoveItemsOverMaxNumberOfBuilds(self, encoded_list):
    """Removes items from the run-length encoded list after the final
    item that exceeds the max number of builds to track.

    Args:
      encoded_results: run-length encoded results. An array of arrays, e.g.
          [[3,'A'],[1,'Q']] encodes AAAQ.
    """
    num_builds = 0
    index = 0
    for result in encoded_list:
      num_builds = num_builds + result[0]
      index = index + 1
      if num_builds > self.MAX_NUMBER_OF_BUILD_RESULTS_TO_LOG:
        return encoded_list[:index]
    return encoded_list

  def _NormalizeResultsJSON(self, test, test_name, tests):
    """ Prune tests where all runs pass or tests that no longer exist and
    truncate all results to maxNumberOfBuilds.

    Args:
      test: ResultsAndTimes object for this test.
      test_name: Name of the test.
      tests: The JSON object with all the test results for this builder.
    """
    test[self.RESULTS] = self._RemoveItemsOverMaxNumberOfBuilds(
        test[self.RESULTS])
    test[self.TIMES] = self._RemoveItemsOverMaxNumberOfBuilds(
        test[self.TIMES])

    is_all_pass = self._IsResultsAllOfType(test[self.RESULTS],
                                           self.PASS_RESULT)
    is_all_no_data = self._IsResultsAllOfType(test[self.RESULTS],
                                              self.NO_DATA_RESULT)
    max_time = max([test_time[1] for test_time in test[self.TIMES]])

    # Remove all passes/no-data from the results to reduce noise and
    # filesize. If a test passes every run, but takes > MIN_TIME to run,
    # don't throw away the data.
    if is_all_no_data or (is_all_pass and max_time <= self.MIN_TIME):
      del tests[test_name]

  # method could be a function pylint: disable=R0201
  def _IsResultsAllOfType(self, results, result_type):
    """Returns whether all the results are of the given type
    (e.g. all passes)."""
    return len(results) == 1 and results[0][1] == result_type


class _FileUploader(object):

  def __init__(self, url, timeout_seconds):
    self._url = url
    self._timeout_seconds = timeout_seconds

  def UploadAsMultipartFormData(self, files, attrs):
    file_objs = []
    for filename, path in files:
      with file(path, 'rb') as fp:
        file_objs.append(('file', filename, fp.read()))

    # FIXME: We should use the same variable names for the formal and actual
    # parameters.
    content_type, data = _EncodeMultipartFormData(attrs, file_objs)
    return self._UploadData(content_type, data)

  def _UploadData(self, content_type, data):
    start = time.time()
    end = start + self._timeout_seconds
    while time.time() < end:
      try:
        request = urllib2.Request(self._url, data,
                                  {'Content-Type': content_type})
        return urllib2.urlopen(request)
      except urllib2.HTTPError as e:
        _log.warn("Received HTTP status %s loading \"%s\".  "
                  'Retrying in 10 seconds...' % (e.code, e.filename))
        time.sleep(10)


def _GetMIMEType(filename):
  return mimetypes.guess_type(filename)[0] or 'application/octet-stream'


# FIXME: Rather than taking tuples, this function should take more
# structured data.
def _EncodeMultipartFormData(fields, files):
  """Encode form fields for multipart/form-data.

  Args:
    fields: A sequence of (name, value) elements for regular form fields.
    files: A sequence of (name, filename, value) elements for data to be
           uploaded as files.
  Returns:
    (content_type, body) ready for httplib.HTTP instance.

  Source:
    http://code.google.com/p/rietveld/source/browse/trunk/upload.py
  """
  BOUNDARY = '-M-A-G-I-C---B-O-U-N-D-A-R-Y-'
  CRLF = '\r\n'
  lines = []

  for key, value in fields:
    lines.append('--' + BOUNDARY)
    lines.append('Content-Disposition: form-data; name="%s"' % key)
    lines.append('')
    if isinstance(value, unicode):
      value = value.encode('utf-8')
    lines.append(value)

  for key, filename, value in files:
    lines.append('--' + BOUNDARY)
    lines.append('Content-Disposition: form-data; name="%s"; '
                 'filename="%s"' % (key, filename))
    lines.append('Content-Type: %s' % _GetMIMEType(filename))
    lines.append('')
    if isinstance(value, unicode):
      value = value.encode('utf-8')
    lines.append(value)

  lines.append('--' + BOUNDARY + '--')
  lines.append('')
  body = CRLF.join(lines)
  content_type = 'multipart/form-data; boundary=%s' % BOUNDARY
  return content_type, body
