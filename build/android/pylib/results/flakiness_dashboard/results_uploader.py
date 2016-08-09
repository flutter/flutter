# Copyright (c) 2012 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Uploads the results to the flakiness dashboard server."""
# pylint: disable=E1002,R0201

import logging
import os
import shutil
import tempfile
import xml


from pylib import cmd_helper
from pylib import constants
from pylib.results.flakiness_dashboard import json_results_generator
from pylib.utils import repo_utils



class JSONResultsGenerator(json_results_generator.JSONResultsGeneratorBase):
  """Writes test results to a JSON file and handles uploading that file to
  the test results server.
  """
  def __init__(self, builder_name, build_name, build_number, tmp_folder,
               test_results_map, test_results_server, test_type, master_name):
    super(JSONResultsGenerator, self).__init__(
        builder_name=builder_name,
        build_name=build_name,
        build_number=build_number,
        results_file_base_path=tmp_folder,
        builder_base_url=None,
        test_results_map=test_results_map,
        svn_repositories=(('webkit', 'third_party/WebKit'),
                          ('chrome', '.')),
        test_results_server=test_results_server,
        test_type=test_type,
        master_name=master_name)

  #override
  def _GetModifierChar(self, test_name):
    if test_name not in self._test_results_map:
      return self.__class__.NO_DATA_RESULT

    return self._test_results_map[test_name].modifier

  #override
  def _GetSVNRevision(self, in_directory):
    """Returns the git/svn revision for the given directory.

    Args:
      in_directory: The directory relative to src.
    """
    def _is_git_directory(in_directory):
      """Returns true if the given directory is in a git repository.

      Args:
        in_directory: The directory path to be tested.
      """
      if os.path.exists(os.path.join(in_directory, '.git')):
        return True
      parent = os.path.dirname(in_directory)
      if parent == constants.DIR_SOURCE_ROOT or parent == in_directory:
        return False
      return _is_git_directory(parent)

    in_directory = os.path.join(constants.DIR_SOURCE_ROOT, in_directory)

    if not os.path.exists(os.path.join(in_directory, '.svn')):
      if _is_git_directory(in_directory):
        return repo_utils.GetGitHeadSHA1(in_directory)
      else:
        return ''

    output = cmd_helper.GetCmdOutput(['svn', 'info', '--xml'], cwd=in_directory)
    try:
      dom = xml.dom.minidom.parseString(output)
      return dom.getElementsByTagName('entry')[0].getAttribute('revision')
    except xml.parsers.expat.ExpatError:
      return ''
    return ''


class ResultsUploader(object):
  """Handles uploading buildbot tests results to the flakiness dashboard."""
  def __init__(self, tests_type):
    self._build_number = os.environ.get('BUILDBOT_BUILDNUMBER')
    self._builder_name = os.environ.get('BUILDBOT_BUILDERNAME')
    self._tests_type = tests_type

    if not self._build_number or not self._builder_name:
      raise Exception('You should not be uploading tests results to the server'
                      'from your local machine.')

    upstream = (tests_type != 'Chromium_Android_Instrumentation')
    if upstream:
      # TODO(frankf): Use factory properties (see buildbot/bb_device_steps.py)
      # This requires passing the actual master name (e.g. 'ChromiumFYI' not
      # 'chromium.fyi').
      from slave import slave_utils # pylint: disable=F0401
      self._build_name = slave_utils.SlaveBuildName(constants.DIR_SOURCE_ROOT)
      self._master_name = slave_utils.GetActiveMaster()
    else:
      self._build_name = 'chromium-android'
      buildbot_branch = os.environ.get('BUILDBOT_BRANCH')
      if not buildbot_branch:
        buildbot_branch = 'master'
      else:
        # Ensure there's no leading "origin/"
        buildbot_branch = buildbot_branch[buildbot_branch.find('/') + 1:]
      self._master_name = '%s-%s' % (self._build_name, buildbot_branch)

    self._test_results_map = {}

  def AddResults(self, test_results):
    # TODO(frankf): Differentiate between fail/crash/timeouts.
    conversion_map = [
        (test_results.GetPass(), False,
            json_results_generator.JSONResultsGeneratorBase.PASS_RESULT),
        (test_results.GetFail(), True,
            json_results_generator.JSONResultsGeneratorBase.FAIL_RESULT),
        (test_results.GetCrash(), True,
            json_results_generator.JSONResultsGeneratorBase.FAIL_RESULT),
        (test_results.GetTimeout(), True,
            json_results_generator.JSONResultsGeneratorBase.FAIL_RESULT),
        (test_results.GetUnknown(), True,
            json_results_generator.JSONResultsGeneratorBase.NO_DATA_RESULT),
        ]

    for results_list, failed, modifier in conversion_map:
      for single_test_result in results_list:
        test_result = json_results_generator.TestResult(
            test=single_test_result.GetName(),
            failed=failed,
            elapsed_time=single_test_result.GetDuration() / 1000)
        # The WebKit TestResult object sets the modifier it based on test name.
        # Since we don't use the same test naming convention as WebKit the
        # modifier will be wrong, so we need to overwrite it.
        test_result.modifier = modifier

        self._test_results_map[single_test_result.GetName()] = test_result

  def Upload(self, test_results_server):
    if not self._test_results_map:
      return

    tmp_folder = tempfile.mkdtemp()

    try:
      results_generator = JSONResultsGenerator(
          builder_name=self._builder_name,
          build_name=self._build_name,
          build_number=self._build_number,
          tmp_folder=tmp_folder,
          test_results_map=self._test_results_map,
          test_results_server=test_results_server,
          test_type=self._tests_type,
          master_name=self._master_name)

      json_files = ["incremental_results.json", "times_ms.json"]
      results_generator.GenerateJSONOutput()
      results_generator.GenerateTimesMSFile()
      results_generator.UploadJSONFiles(json_files)
    except Exception as e:
      logging.error("Uploading results to test server failed: %s." % e)
    finally:
      shutil.rmtree(tmp_folder)


def Upload(results, flakiness_dashboard_server, test_type):
  """Reports test results to the flakiness dashboard for Chrome for Android.

  Args:
    results: test results.
    flakiness_dashboard_server: the server to upload the results to.
    test_type: the type of the tests (as displayed by the flakiness dashboard).
  """
  uploader = ResultsUploader(test_type)
  uploader.AddResults(results)
  uploader.Upload(flakiness_dashboard_server)
