# Copyright (C) 2010 Google Inc. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
#
#    * Redistributions of source code must retain the above copyright
# notice, this list of conditions and the following disclaimer.
#    * Redistributions in binary form must reproduce the above
# copyright notice, this list of conditions and the following disclaimer
# in the documentation and/or other materials provided with the
# distribution.
#    * Neither the name of Google Inc. nor the names of its
# contributors may be used to endorse or promote products derived from
# this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
# OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

import json
import unittest

from webkitpy.common.net import layouttestresults_unittest
from webkitpy.common.host_mock import MockHost
from webkitpy.layout_tests.layout_package.json_results_generator import strip_json_wrapper
from webkitpy.layout_tests.port.base import Port
from webkitpy.tool.commands.rebaselineserver import TestConfig, RebaselineServer
from webkitpy.tool.servers import rebaselineserver


class RebaselineTestTest(unittest.TestCase):
    def test_text_rebaseline_update(self):
        self._assertRebaseline(
            test_files=(
                'fast/text-expected.txt',
                'platform/mac/fast/text-expected.txt',
            ),
            results_files=(
                'fast/text-actual.txt',
            ),
            test_name='fast/text.html',
            baseline_target='mac',
            baseline_move_to='none',
            expected_success=True,
            expected_log=[
                'Rebaselining fast/text...',
                '  Updating baselines for mac',
                '    Updated text-expected.txt',
            ])

    def test_text_rebaseline_new(self):
        self._assertRebaseline(
            test_files=(
                'fast/text-expected.txt',
            ),
            results_files=(
                'fast/text-actual.txt',
            ),
            test_name='fast/text.html',
            baseline_target='mac',
            baseline_move_to='none',
            expected_success=True,
            expected_log=[
                'Rebaselining fast/text...',
                '  Updating baselines for mac',
                '    Updated text-expected.txt',
            ])

    def test_text_rebaseline_move_no_op_1(self):
        self._assertRebaseline(
            test_files=(
                'fast/text-expected.txt',
                'platform/win/fast/text-expected.txt',
            ),
            results_files=(
                'fast/text-actual.txt',
            ),
            test_name='fast/text.html',
            baseline_target='mac',
            baseline_move_to='mac-leopard',
            expected_success=True,
            expected_log=[
                'Rebaselining fast/text...',
                '  Updating baselines for mac',
                '    Updated text-expected.txt',
            ])

    def test_text_rebaseline_move_no_op_2(self):
        self._assertRebaseline(
            test_files=(
                'fast/text-expected.txt',
                'platform/mac/fast/text-expected.checksum',
            ),
            results_files=(
                'fast/text-actual.txt',
            ),
            test_name='fast/text.html',
            baseline_target='mac',
            baseline_move_to='mac-leopard',
            expected_success=True,
            expected_log=[
                'Rebaselining fast/text...',
                '  Moving current mac baselines to mac-leopard',
                '    No current baselines to move',
                '  Updating baselines for mac',
                '    Updated text-expected.txt',
            ])

    def test_text_rebaseline_move(self):
        self._assertRebaseline(
            test_files=(
                'fast/text-expected.txt',
                'platform/mac/fast/text-expected.txt',
            ),
            results_files=(
                'fast/text-actual.txt',
            ),
            test_name='fast/text.html',
            baseline_target='mac',
            baseline_move_to='mac-leopard',
            expected_success=True,
            expected_log=[
                'Rebaselining fast/text...',
                '  Moving current mac baselines to mac-leopard',
                '    Moved text-expected.txt',
                '  Updating baselines for mac',
                '    Updated text-expected.txt',
            ])

    def test_text_rebaseline_move_only_images(self):
        self._assertRebaseline(
            test_files=(
                'fast/image-expected.txt',
                'platform/mac/fast/image-expected.txt',
                'platform/mac/fast/image-expected.png',
                'platform/mac/fast/image-expected.checksum',
            ),
            results_files=(
                'fast/image-actual.png',
                'fast/image-actual.checksum',
            ),
            test_name='fast/image.html',
            baseline_target='mac',
            baseline_move_to='mac-leopard',
            expected_success=True,
            expected_log=[
                'Rebaselining fast/image...',
                '  Moving current mac baselines to mac-leopard',
                '    Moved image-expected.checksum',
                '    Moved image-expected.png',
                '  Updating baselines for mac',
                '    Updated image-expected.checksum',
                '    Updated image-expected.png',
            ])

    def test_text_rebaseline_move_already_exist(self):
        self._assertRebaseline(
            test_files=(
                'fast/text-expected.txt',
                'platform/mac-leopard/fast/text-expected.txt',
                'platform/mac/fast/text-expected.txt',
            ),
            results_files=(
                'fast/text-actual.txt',
            ),
            test_name='fast/text.html',
            baseline_target='mac',
            baseline_move_to='mac-leopard',
            expected_success=False,
            expected_log=[
                'Rebaselining fast/text...',
                '  Moving current mac baselines to mac-leopard',
                '    Already had baselines in mac-leopard, could not move existing mac ones',
            ])

    def test_image_rebaseline(self):
        self._assertRebaseline(
            test_files=(
                'fast/image-expected.txt',
                'platform/mac/fast/image-expected.png',
                'platform/mac/fast/image-expected.checksum',
            ),
            results_files=(
                'fast/image-actual.png',
                'fast/image-actual.checksum',
            ),
            test_name='fast/image.html',
            baseline_target='mac',
            baseline_move_to='none',
            expected_success=True,
            expected_log=[
                'Rebaselining fast/image...',
                '  Updating baselines for mac',
                '    Updated image-expected.checksum',
                '    Updated image-expected.png',
            ])

    def test_gather_baselines(self):
        example_json = layouttestresults_unittest.LayoutTestResultsTest.example_full_results_json
        results_json = json.loads(strip_json_wrapper(example_json))
        server = RebaselineServer()
        server._test_config = get_test_config()
        server._gather_baselines(results_json)
        self.assertEqual(results_json['tests']['svg/dynamic-updates/SVGFEDropShadowElement-dom-stdDeviation-attr.html']['state'], 'needs_rebaseline')
        self.assertNotIn('prototype-chocolate.html', results_json['tests'])

    def _assertRebaseline(self, test_files, results_files, test_name, baseline_target, baseline_move_to, expected_success, expected_log):
        log = []
        test_config = get_test_config(test_files, results_files)
        success = rebaselineserver._rebaseline_test(
            test_name,
            baseline_target,
            baseline_move_to,
            test_config,
            log=lambda l: log.append(l))
        self.assertEqual(expected_log, log)
        self.assertEqual(expected_success, success)


class GetActualResultFilesTest(unittest.TestCase):
    def test(self):
        test_config = get_test_config(result_files=(
            'fast/text-actual.txt',
            'fast2/text-actual.txt',
            'fast/text2-actual.txt',
            'fast/text-notactual.txt',
        ))
        self.assertItemsEqual(
            ('text-actual.txt',),
            rebaselineserver._get_actual_result_files(
                'fast/text.html', test_config))


class GetBaselinesTest(unittest.TestCase):
    def test_no_baselines(self):
        self._assertBaselines(
            test_files=(),
            test_name='fast/missing.html',
            expected_baselines={})

    def test_text_baselines(self):
        self._assertBaselines(
            test_files=(
                'fast/text-expected.txt',
                'platform/mac/fast/text-expected.txt',
            ),
            test_name='fast/text.html',
            expected_baselines={
                'mac': {'.txt': True},
                'base': {'.txt': False},
            })

    def test_image_and_text_baselines(self):
        self._assertBaselines(
            test_files=(
                'fast/image-expected.txt',
                'platform/mac/fast/image-expected.png',
                'platform/mac/fast/image-expected.checksum',
                'platform/win/fast/image-expected.png',
                'platform/win/fast/image-expected.checksum',
            ),
            test_name='fast/image.html',
            expected_baselines={
                'base': {'.txt': True},
                'mac': {'.checksum': True, '.png': True},
                'win': {'.checksum': False, '.png': False},
            })

    def test_extra_baselines(self):
        self._assertBaselines(
            test_files=(
                'fast/text-expected.txt',
                'platform/nosuchplatform/fast/text-expected.txt',
            ),
            test_name='fast/text.html',
            expected_baselines={'base': {'.txt': True}})

    def _assertBaselines(self, test_files, test_name, expected_baselines):
        actual_baselines = rebaselineserver.get_test_baselines(test_name, get_test_config(test_files))
        self.assertEqual(expected_baselines, actual_baselines)


def get_test_config(test_files=[], result_files=[]):
    host = MockHost()
    port = host.port_factory.get()
    layout_tests_directory = port.layout_tests_dir()
    results_directory = port.results_directory()

    for file in test_files:
        host.filesystem.write_binary_file(host.filesystem.join(layout_tests_directory, file), '')
    for file in result_files:
        host.filesystem.write_binary_file(host.filesystem.join(results_directory, file), '')

    class TestMacPort(Port):
        port_name = "mac"
        FALLBACK_PATHS = {'': ['mac']}

    return TestConfig(
        TestMacPort(host, 'mac'),
        layout_tests_directory,
        results_directory,
        ('mac', 'mac-leopard', 'win', 'linux'),
        host.filesystem,
        host.scm())
