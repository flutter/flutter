# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import flakytests

from webkitpy.common.checkout.scm.scm_mock import MockSCM
from webkitpy.tool.commands.commandtest import CommandsTest
from webkitpy.tool.mocktool import MockTool, MockOptions


class FakeBotTestExpectations(object):
    def expectation_lines(self, only_ignore_very_flaky=False):
        return []


class FakeBotTestExpectationsFactory(object):
    def expectations_for_builder(self, builder):
        return FakeBotTestExpectations()


class ChangedExpectationsMockSCM(MockSCM):
    def changed_files(self):
        return ['tests/FlakyTests']


class FlakyTestsTest(CommandsTest):
    def test_simple(self):
        command = flakytests.FlakyTests()
        factory = FakeBotTestExpectationsFactory()
        lines = command._collect_expectation_lines(['foo'], factory)
        self.assertEqual(lines, [])

    def test_integration(self):
        command = flakytests.FlakyTests()
        tool = MockTool()
        command.expectations_factory = FakeBotTestExpectationsFactory
        options = MockOptions(upload=True)
        expected_stdout = """Updated /mock-checkout/third_party/WebKit/tests/FlakyTests
tests/FlakyTests is not changed, not uploading.
"""
        self.assert_execute_outputs(command, options=options, tool=tool, expected_stdout=expected_stdout)

        port = tool.port_factory.get()
        self.assertEqual(tool.filesystem.read_text_file(tool.filesystem.join(port.layout_tests_dir(), 'FlakyTests')), command.FLAKY_TEST_CONTENTS % '')

    def test_integration_uploads(self):
        command = flakytests.FlakyTests()
        tool = MockTool()
        tool.scm = ChangedExpectationsMockSCM
        command.expectations_factory = FakeBotTestExpectationsFactory
        reviewer = 'foo@chromium.org'
        options = MockOptions(upload=True, reviewers=reviewer)
        expected_stdout = """Updated /mock-checkout/third_party/WebKit/tests/FlakyTests
"""
        self.assert_execute_outputs(command, options=options, tool=tool, expected_stdout=expected_stdout)
        self.assertEqual(tool.executive.calls,
            [
                ['git', 'commit', '-m', command.COMMIT_MESSAGE % reviewer, '/mock-checkout/third_party/WebKit/tests/FlakyTests'],
                ['git', 'cl', 'upload', '--send-mail', '-f', '--cc', 'ojan@chromium.org,dpranke@chromium.org,eseidel@chromium.org'],
            ])

        port = tool.port_factory.get()
        self.assertEqual(tool.filesystem.read_text_file(tool.filesystem.join(port.layout_tests_dir(), 'FlakyTests')), command.FLAKY_TEST_CONTENTS % '')
