# Copyright (C) 2011 Google Inc. All rights reserved.
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

import unittest

from webkitpy.common.checkout.baselineoptimizer import BaselineOptimizer
from webkitpy.common.checkout.scm.scm_mock import MockSCM
from webkitpy.common.host_mock import MockHost
from webkitpy.common.webkit_finder import WebKitFinder


class ExcludingMockSCM(MockSCM):
    def __init__(self, exclusion_list, filesystem=None, executive=None):
        MockSCM.__init__(self, filesystem, executive)
        self._exclusion_list = exclusion_list

    def exists(self, path):
        if path in self._exclusion_list:
            return False
        return MockSCM.exists(self, path)

    def delete(self, path):
        return self.delete_list([path])

    def delete_list(self, paths):
        for path in paths:
            if path in self._exclusion_list:
                raise Exception("File is not SCM managed: " + path)
        return MockSCM.delete_list(self, paths)

    def move(self, origin, destination):
        if origin in self._exclusion_list:
            raise Exception("File is not SCM managed: " + origin)
        return MockSCM.move(self, origin, destination)


class BaselineOptimizerTest(unittest.TestCase):
    def test_move_baselines(self):
        host = MockHost(scm=ExcludingMockSCM(['/mock-checkout/third_party/WebKit/tests/platform/mac/another/test-expected.txt']))
        host.filesystem.write_binary_file('/mock-checkout/third_party/WebKit/tests/platform/win/another/test-expected.txt', 'result A')
        host.filesystem.write_binary_file('/mock-checkout/third_party/WebKit/tests/platform/mac/another/test-expected.txt', 'result A')
        host.filesystem.write_binary_file('/mock-checkout/third_party/WebKit/tests/another/test-expected.txt', 'result B')
        baseline_optimizer = BaselineOptimizer(host, host.port_factory.all_port_names(), skip_scm_commands=False)
        baseline_optimizer._move_baselines('another/test-expected.txt', {
            '/mock-checkout/third_party/WebKit/tests/platform/win': 'aaa',
            '/mock-checkout/third_party/WebKit/tests/platform/mac': 'aaa',
            '/mock-checkout/third_party/WebKit/tests': 'bbb',
        }, {
            '/mock-checkout/third_party/WebKit/tests': 'aaa',
        })
        self.assertEqual(host.filesystem.read_binary_file('/mock-checkout/third_party/WebKit/tests/another/test-expected.txt'), 'result A')

    def test_move_baselines_skip_scm_commands(self):
        host = MockHost(scm=ExcludingMockSCM(['/mock-checkout/third_party/WebKit/tests/platform/mac/another/test-expected.txt']))
        host.filesystem.write_binary_file('/mock-checkout/third_party/WebKit/tests/platform/win/another/test-expected.txt', 'result A')
        host.filesystem.write_binary_file('/mock-checkout/third_party/WebKit/tests/platform/mac/another/test-expected.txt', 'result A')
        host.filesystem.write_binary_file('/mock-checkout/third_party/WebKit/tests/another/test-expected.txt', 'result B')
        baseline_optimizer = BaselineOptimizer(host, host.port_factory.all_port_names(), skip_scm_commands=True)
        baseline_optimizer._move_baselines('another/test-expected.txt', {
            '/mock-checkout/third_party/WebKit/tests/platform/win': 'aaa',
            '/mock-checkout/third_party/WebKit/tests/platform/mac': 'aaa',
            '/mock-checkout/third_party/WebKit/tests': 'bbb',
        }, {
            '/mock-checkout/third_party/WebKit/tests/platform/linux': 'bbb',
            '/mock-checkout/third_party/WebKit/tests': 'aaa',
        })
        self.assertEqual(host.filesystem.read_binary_file('/mock-checkout/third_party/WebKit/tests/another/test-expected.txt'), 'result A')

        self.assertEqual(baseline_optimizer._files_to_delete, [
            '/mock-checkout/third_party/WebKit/tests/platform/win/another/test-expected.txt',
        ])

        self.assertEqual(baseline_optimizer._files_to_add, [
            '/mock-checkout/third_party/WebKit/tests/another/test-expected.txt',
            '/mock-checkout/third_party/WebKit/tests/platform/linux/another/test-expected.txt',
        ])

    def _assertOptimization(self, results_by_directory, expected_new_results_by_directory, baseline_dirname='', expected_files_to_delete=None, host=None):
        if not host:
            host = MockHost()
        fs = host.filesystem
        webkit_base = WebKitFinder(fs).webkit_base()
        baseline_name = 'mock-baseline-expected.txt'

        for dirname, contents in results_by_directory.items():
            path = fs.join(webkit_base, 'tests', dirname, baseline_name)
            fs.write_binary_file(path, contents)

        baseline_optimizer = BaselineOptimizer(host, host.port_factory.all_port_names(), skip_scm_commands=expected_files_to_delete is not None)
        self.assertTrue(baseline_optimizer.optimize(fs.join(baseline_dirname, baseline_name)))

        for dirname, contents in expected_new_results_by_directory.items():
            path = fs.join(webkit_base, 'tests', dirname, baseline_name)
            if contents is None:
                self.assertTrue(not fs.exists(path) or path in baseline_optimizer._files_to_delete)
            else:
                self.assertEqual(fs.read_binary_file(path), contents)

        # Check that the files that were in the original set have been deleted where necessary.
        for dirname in results_by_directory:
            path = fs.join(webkit_base, 'tests', dirname, baseline_name)
            if not dirname in expected_new_results_by_directory:
                self.assertTrue(not fs.exists(path) or path in baseline_optimizer._files_to_delete)

        if expected_files_to_delete:
            self.assertEqual(sorted(baseline_optimizer._files_to_delete), sorted(expected_files_to_delete))

    def test_linux_redundant_with_win(self):
        self._assertOptimization({
            'platform/win': '1',
            'platform/linux': '1',
        }, {
            'platform/win': '1',
        })

    def test_covers_mac_win_linux(self):
        self._assertOptimization({
            'platform/mac': '1',
            'platform/win': '1',
            'platform/linux': '1',
            '': None,
        }, {
            '': '1',
        })

    def test_overwrites_root(self):
        self._assertOptimization({
            'platform/mac': '1',
            'platform/win': '1',
            'platform/linux': '1',
            '': '2',
        }, {
            '': '1',
        })

    def test_no_new_common_directory(self):
        self._assertOptimization({
            'platform/mac': '1',
            'platform/linux': '1',
            '': '2',
        }, {
            'platform/mac': '1',
            'platform/linux': '1',
            '': '2',
        })


    def test_local_optimization(self):
        self._assertOptimization({
            'platform/mac': '1',
            'platform/linux': '1',
            'platform/linux-x86': '1',
        }, {
            'platform/mac': '1',
            'platform/linux': '1',
        })

    def test_local_optimization_skipping_a_port_in_the_middle(self):
        self._assertOptimization({
            'platform/mac-snowleopard': '1',
            'platform/win': '1',
            'platform/linux-x86': '1',
        }, {
            'platform/mac-snowleopard': '1',
            'platform/win': '1',
        })

    def test_baseline_redundant_with_root(self):
        self._assertOptimization({
            'platform/mac': '1',
            'platform/win': '2',
            '': '2',
        }, {
            'platform/mac': '1',
            '': '2',
        })

    def test_root_baseline_unused(self):
        self._assertOptimization({
            'platform/mac': '1',
            'platform/win': '2',
            '': '3',
        }, {
            'platform/mac': '1',
            'platform/win': '2',
        })

    def test_root_baseline_unused_and_non_existant(self):
        self._assertOptimization({
            'platform/mac': '1',
            'platform/win': '2',
        }, {
            'platform/mac': '1',
            'platform/win': '2',
        })

    def test_virtual_root_redundant_with_actual_root(self):
        self._assertOptimization({
            'virtual/gpu/fast/canvas': '2',
            'fast/canvas': '2',
        }, {
            'virtual/gpu/fast/canvas': None,
            'fast/canvas': '2',
        }, baseline_dirname='virtual/gpu/fast/canvas')

    def test_virtual_root_redundant_with_ancestors(self):
        self._assertOptimization({
            'virtual/gpu/fast/canvas': '2',
            'platform/mac/fast/canvas': '2',
            'platform/win/fast/canvas': '2',
        }, {
            'virtual/gpu/fast/canvas': None,
            'fast/canvas': '2',
        }, baseline_dirname='virtual/gpu/fast/canvas')

    def test_virtual_root_redundant_with_ancestors_skip_scm_commands(self):
        self._assertOptimization({
            'virtual/gpu/fast/canvas': '2',
            'platform/mac/fast/canvas': '2',
            'platform/win/fast/canvas': '2',
        }, {
            'virtual/gpu/fast/canvas': None,
            'fast/canvas': '2',
        },
        baseline_dirname='virtual/gpu/fast/canvas',
        expected_files_to_delete=[
            '/mock-checkout/third_party/WebKit/tests/virtual/gpu/fast/canvas/mock-baseline-expected.txt',
            '/mock-checkout/third_party/WebKit/tests/platform/mac/fast/canvas/mock-baseline-expected.txt',
            '/mock-checkout/third_party/WebKit/tests/platform/win/fast/canvas/mock-baseline-expected.txt',
        ])

    def test_virtual_root_redundant_with_ancestors_skip_scm_commands_with_file_not_in_scm(self):
        self._assertOptimization({
            'virtual/gpu/fast/canvas': '2',
            'platform/mac/fast/canvas': '2',
            'platform/win/fast/canvas': '2',
        }, {
            'virtual/gpu/fast/canvas': None,
            'fast/canvas': '2',
        },
        baseline_dirname='virtual/gpu/fast/canvas',
        expected_files_to_delete=[
            '/mock-checkout/third_party/WebKit/tests/platform/mac/fast/canvas/mock-baseline-expected.txt',
            '/mock-checkout/third_party/WebKit/tests/platform/win/fast/canvas/mock-baseline-expected.txt',
        ],
        host=MockHost(scm=ExcludingMockSCM(['/mock-checkout/third_party/WebKit/tests/virtual/gpu/fast/canvas/mock-baseline-expected.txt'])))

    def test_virtual_root_not_redundant_with_ancestors(self):
        self._assertOptimization({
            'virtual/gpu/fast/canvas': '2',
            'platform/mac/fast/canvas': '1',
        }, {
            'virtual/gpu/fast/canvas': '2',
            'platform/mac/fast/canvas': '1',
        }, baseline_dirname='virtual/gpu/fast/canvas')
