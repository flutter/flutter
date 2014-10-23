# Copyright (C) 2010 Google Inc. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
#
#     * Redistributions of source code must retain the above copyright
# notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above
# copyright notice, this list of conditions and the following disclaimer
# in the documentation and/or other materials provided with the
# distribution.
#     * Neither the Google name nor the names of its
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

import base64
import copy
import sys
import time

from webkitpy.layout_tests.port import DeviceFailure, Driver, DriverOutput, Port
from webkitpy.layout_tests.port.base import VirtualTestSuite
from webkitpy.layout_tests.models.test_configuration import TestConfiguration
from webkitpy.layout_tests.models import test_run_results
from webkitpy.common.system.filesystem_mock import MockFileSystem
from webkitpy.common.system.crashlogs import CrashLogs


# This sets basic expectations for a test. Each individual expectation
# can be overridden by a keyword argument in TestList.add().
class TestInstance(object):
    def __init__(self, name):
        self.name = name
        self.base = name[(name.rfind("/") + 1):name.rfind(".")]
        self.crash = False
        self.web_process_crash = False
        self.exception = False
        self.keyboard = False
        self.error = ''
        self.timeout = False
        self.is_reftest = False
        self.device_failure = False
        self.leak = False

        # The values of each field are treated as raw byte strings. They
        # will be converted to unicode strings where appropriate using
        # FileSystem.read_text_file().
        self.actual_text = self.base + '-txt'
        self.actual_checksum = self.base + '-checksum'

        # We add the '\x8a' for the image file to prevent the value from
        # being treated as UTF-8 (the character is invalid)
        self.actual_image = self.base + '\x8a' + '-png' + 'tEXtchecksum\x00' + self.actual_checksum

        self.expected_text = self.actual_text
        self.expected_image = self.actual_image

        self.actual_audio = None
        self.expected_audio = None


# This is an in-memory list of tests, what we want them to produce, and
# what we want to claim are the expected results.
class TestList(object):
    def __init__(self):
        self.tests = {}

    def add(self, name, **kwargs):
        test = TestInstance(name)
        for key, value in kwargs.items():
            test.__dict__[key] = value
        self.tests[name] = test

    def add_reftest(self, name, reference_name, same_image, crash=False):
        self.add(name, actual_checksum='xxx', actual_image='XXX', is_reftest=True, crash=crash)
        if same_image:
            self.add(reference_name, actual_checksum='xxx', actual_image='XXX', is_reftest=True)
        else:
            self.add(reference_name, actual_checksum='yyy', actual_image='YYY', is_reftest=True)

    def keys(self):
        return self.tests.keys()

    def __contains__(self, item):
        return item in self.tests

    def __getitem__(self, item):
        return self.tests[item]

#
# These numbers may need to be updated whenever we add or delete tests. This includes virtual tests.
#
TOTAL_TESTS = 113
TOTAL_SKIPS = 29

UNEXPECTED_PASSES = 1
UNEXPECTED_FAILURES = 26

def unit_test_list():
    tests = TestList()
    tests.add('failures/expected/crash.html', crash=True)
    tests.add('failures/expected/exception.html', exception=True)
    tests.add('failures/expected/device_failure.html', device_failure=True)
    tests.add('failures/expected/timeout.html', timeout=True)
    tests.add('failures/expected/leak.html', leak=True)
    tests.add('failures/expected/missing_text.html', expected_text=None)
    tests.add('failures/expected/needsrebaseline.html', actual_text='needsrebaseline text')
    tests.add('failures/expected/needsmanualrebaseline.html', actual_text='needsmanualrebaseline text')
    tests.add('failures/expected/image.html',
              actual_image='image_fail-pngtEXtchecksum\x00checksum_fail',
              expected_image='image-pngtEXtchecksum\x00checksum-png')
    tests.add('failures/expected/image_checksum.html',
              actual_checksum='image_checksum_fail-checksum',
              actual_image='image_checksum_fail-png')
    tests.add('failures/expected/audio.html',
              actual_audio=base64.b64encode('audio_fail-wav'), expected_audio='audio-wav',
              actual_text=None, expected_text=None,
              actual_image=None, expected_image=None,
              actual_checksum=None)
    tests.add('failures/expected/keyboard.html', keyboard=True)
    tests.add('failures/expected/missing_check.html',
              expected_image='missing_check-png')
    tests.add('failures/expected/missing_image.html', expected_image=None)
    tests.add('failures/expected/missing_audio.html', expected_audio=None,
              actual_text=None, expected_text=None,
              actual_image=None, expected_image=None,
              actual_checksum=None)
    tests.add('failures/expected/missing_text.html', expected_text=None)
    tests.add('failures/expected/newlines_leading.html',
              expected_text="\nfoo\n", actual_text="foo\n")
    tests.add('failures/expected/newlines_trailing.html',
              expected_text="foo\n\n", actual_text="foo\n")
    tests.add('failures/expected/newlines_with_excess_CR.html',
              expected_text="foo\r\r\r\n", actual_text="foo\n")
    tests.add('failures/expected/text.html', actual_text='text_fail-png')
    tests.add('failures/expected/crash_then_text.html')
    tests.add('failures/expected/skip_text.html', actual_text='text diff')
    tests.add('failures/flaky/text.html')
    tests.add('failures/unexpected/missing_text.html', expected_text=None)
    tests.add('failures/unexpected/missing_check.html', expected_image='missing-check-png')
    tests.add('failures/unexpected/missing_image.html', expected_image=None)
    tests.add('failures/unexpected/missing_render_tree_dump.html', actual_text="""layer at (0,0) size 800x600
  RenderView at (0,0) size 800x600
layer at (0,0) size 800x34
  RenderBlock {HTML} at (0,0) size 800x34
    RenderBody {BODY} at (8,8) size 784x18
      RenderText {#text} at (0,0) size 133x18
        text run at (0,0) width 133: "This is an image test!"
""", expected_text=None)
    tests.add('failures/unexpected/crash.html', crash=True)
    tests.add('failures/unexpected/crash-with-stderr.html', crash=True,
              error="mock-std-error-output")
    tests.add('failures/unexpected/web-process-crash-with-stderr.html', web_process_crash=True,
              error="mock-std-error-output")
    tests.add('failures/unexpected/pass.html')
    tests.add('failures/unexpected/text-checksum.html',
              actual_text='text-checksum_fail-txt',
              actual_checksum='text-checksum_fail-checksum')
    tests.add('failures/unexpected/text-image-checksum.html',
              actual_text='text-image-checksum_fail-txt',
              actual_image='text-image-checksum_fail-pngtEXtchecksum\x00checksum_fail',
              actual_checksum='text-image-checksum_fail-checksum')
    tests.add('failures/unexpected/checksum-with-matching-image.html',
              actual_checksum='text-image-checksum_fail-checksum')
    tests.add('failures/unexpected/skip_pass.html')
    tests.add('failures/unexpected/text.html', actual_text='text_fail-txt')
    tests.add('failures/unexpected/text_then_crash.html')
    tests.add('failures/unexpected/timeout.html', timeout=True)
    tests.add('failures/unexpected/leak.html', leak=True)
    tests.add('http/tests/passes/text.html')
    tests.add('http/tests/passes/image.html')
    tests.add('http/tests/ssl/text.html')
    tests.add('passes/args.html')
    tests.add('passes/error.html', error='stuff going to stderr')
    tests.add('passes/image.html')
    tests.add('passes/audio.html',
              actual_audio=base64.b64encode('audio-wav'), expected_audio='audio-wav',
              actual_text=None, expected_text=None,
              actual_image=None, expected_image=None,
              actual_checksum=None)
    tests.add('passes/platform_image.html')
    tests.add('passes/checksum_in_image.html',
              expected_image='tEXtchecksum\x00checksum_in_image-checksum')
    tests.add('passes/skipped/skip.html')

    # Note that here the checksums don't match but the images do, so this test passes "unexpectedly".
    # See https://bugs.webkit.org/show_bug.cgi?id=69444 .
    tests.add('failures/unexpected/checksum.html', actual_checksum='checksum_fail-checksum')

    # Text output files contain "\r\n" on Windows.  This may be
    # helpfully filtered to "\r\r\n" by our Python/Cygwin tooling.
    tests.add('passes/text.html',
              expected_text='\nfoo\n\n', actual_text='\nfoo\r\n\r\r\n')

    # For reftests.
    tests.add_reftest('passes/reftest.html', 'passes/reftest-expected.html', same_image=True)

    # This adds a different virtual reference to ensure that that also works.
    tests.add('virtual/passes/reftest-expected.html', actual_checksum='xxx', actual_image='XXX', is_reftest=True)

    tests.add_reftest('passes/mismatch.html', 'passes/mismatch-expected-mismatch.html', same_image=False)
    tests.add_reftest('passes/svgreftest.svg', 'passes/svgreftest-expected.svg', same_image=True)
    tests.add_reftest('passes/xhtreftest.xht', 'passes/xhtreftest-expected.html', same_image=True)
    tests.add_reftest('passes/phpreftest.php', 'passes/phpreftest-expected-mismatch.svg', same_image=False)
    tests.add_reftest('failures/expected/reftest.html', 'failures/expected/reftest-expected.html', same_image=False)
    tests.add_reftest('failures/expected/mismatch.html', 'failures/expected/mismatch-expected-mismatch.html', same_image=True)
    tests.add_reftest('failures/unexpected/crash-reftest.html', 'failures/unexpected/crash-reftest-expected.html', same_image=True, crash=True)
    tests.add_reftest('failures/unexpected/reftest.html', 'failures/unexpected/reftest-expected.html', same_image=False)
    tests.add_reftest('failures/unexpected/mismatch.html', 'failures/unexpected/mismatch-expected-mismatch.html', same_image=True)
    tests.add('failures/unexpected/reftest-nopixel.html', actual_checksum=None, actual_image=None, is_reftest=True)
    tests.add('failures/unexpected/reftest-nopixel-expected.html', actual_checksum=None, actual_image=None, is_reftest=True)
    tests.add('reftests/foo/test.html')
    tests.add('reftests/foo/test-ref.html')

    tests.add('reftests/foo/multiple-match-success.html', actual_checksum='abc', actual_image='abc')
    tests.add('reftests/foo/multiple-match-failure.html', actual_checksum='abc', actual_image='abc')
    tests.add('reftests/foo/multiple-mismatch-success.html', actual_checksum='abc', actual_image='abc')
    tests.add('reftests/foo/multiple-mismatch-failure.html', actual_checksum='abc', actual_image='abc')
    tests.add('reftests/foo/multiple-both-success.html', actual_checksum='abc', actual_image='abc')
    tests.add('reftests/foo/multiple-both-failure.html', actual_checksum='abc', actual_image='abc')

    tests.add('reftests/foo/matching-ref.html', actual_checksum='abc', actual_image='abc')
    tests.add('reftests/foo/mismatching-ref.html', actual_checksum='def', actual_image='def')
    tests.add('reftests/foo/second-mismatching-ref.html', actual_checksum='ghi', actual_image='ghi')

    # The following files shouldn't be treated as reftests
    tests.add_reftest('reftests/foo/unlistedtest.html', 'reftests/foo/unlistedtest-expected.html', same_image=True)
    tests.add('reftests/foo/reference/bar/common.html')
    tests.add('reftests/foo/reftest/bar/shared.html')

    tests.add('websocket/tests/passes/text.html')

    # For testing that we don't run tests under platform/. Note that these don't contribute to TOTAL_TESTS.
    tests.add('platform/test-mac-leopard/http/test.html')
    tests.add('platform/test-win-win7/http/test.html')

    # For testing if perf tests are running in a locked shard.
    tests.add('perf/foo/test.html')
    tests.add('perf/foo/test-ref.html')

    # For testing --pixel-test-directories.
    tests.add('failures/unexpected/pixeldir/image_in_pixeldir.html',
        actual_image='image_in_pixeldir-pngtEXtchecksum\x00checksum_fail',
        expected_image='image_in_pixeldir-pngtEXtchecksum\x00checksum-png')
    tests.add('failures/unexpected/image_not_in_pixeldir.html',
        actual_image='image_not_in_pixeldir-pngtEXtchecksum\x00checksum_fail',
        expected_image='image_not_in_pixeldir-pngtEXtchecksum\x00checksum-png')

    # For testing that virtual test suites don't expand names containing themselves
    # See webkit.org/b/97925 and base_unittest.PortTest.test_tests().
    tests.add('passes/test-virtual-passes.html')
    tests.add('passes/passes/test-virtual-passes.html')

    return tests


# Here we use a non-standard location for the layout tests, to ensure that
# this works. The path contains a '.' in the name because we've seen bugs
# related to this before.

LAYOUT_TEST_DIR = '/test.checkout/tests'
PERF_TEST_DIR = '/test.checkout/PerformanceTests'


# Here we synthesize an in-memory filesystem from the test list
# in order to fully control the test output and to demonstrate that
# we don't need a real filesystem to run the tests.
def add_unit_tests_to_mock_filesystem(filesystem):
    # Add the test_expectations file.
    filesystem.maybe_make_directory('/mock-checkout/tests')
    if not filesystem.exists('/mock-checkout/tests/TestExpectations'):
        filesystem.write_text_file('/mock-checkout/tests/TestExpectations', """
Bug(test) failures/expected/crash.html [ Crash ]
Bug(test) failures/expected/crash_then_text.html [ Failure ]
Bug(test) failures/expected/image.html [ ImageOnlyFailure ]
Bug(test) failures/expected/needsrebaseline.html [ NeedsRebaseline ]
Bug(test) failures/expected/needsmanualrebaseline.html [ NeedsManualRebaseline ]
Bug(test) failures/expected/audio.html [ Failure ]
Bug(test) failures/expected/image_checksum.html [ ImageOnlyFailure ]
Bug(test) failures/expected/mismatch.html [ ImageOnlyFailure ]
Bug(test) failures/expected/missing_check.html [ Missing Pass ]
Bug(test) failures/expected/missing_image.html [ Missing Pass ]
Bug(test) failures/expected/missing_audio.html [ Missing Pass ]
Bug(test) failures/expected/missing_text.html [ Missing Pass ]
Bug(test) failures/expected/newlines_leading.html [ Failure ]
Bug(test) failures/expected/newlines_trailing.html [ Failure ]
Bug(test) failures/expected/newlines_with_excess_CR.html [ Failure ]
Bug(test) failures/expected/reftest.html [ ImageOnlyFailure ]
Bug(test) failures/expected/text.html [ Failure ]
Bug(test) failures/expected/timeout.html [ Timeout ]
Bug(test) failures/expected/keyboard.html [ WontFix ]
Bug(test) failures/expected/exception.html [ WontFix ]
Bug(test) failures/expected/device_failure.html [ WontFix ]
Bug(test) failures/expected/leak.html [ Leak ]
Bug(test) failures/unexpected/pass.html [ Failure ]
Bug(test) passes/skipped/skip.html [ Skip ]
Bug(test) passes/text.html [ Pass ]
""")

    filesystem.maybe_make_directory(LAYOUT_TEST_DIR + '/reftests/foo')
    filesystem.write_text_file(LAYOUT_TEST_DIR + '/reftests/foo/reftest.list', """
== test.html test-ref.html

== multiple-match-success.html mismatching-ref.html
== multiple-match-success.html matching-ref.html
== multiple-match-failure.html mismatching-ref.html
== multiple-match-failure.html second-mismatching-ref.html
!= multiple-mismatch-success.html mismatching-ref.html
!= multiple-mismatch-success.html second-mismatching-ref.html
!= multiple-mismatch-failure.html mismatching-ref.html
!= multiple-mismatch-failure.html matching-ref.html
== multiple-both-success.html matching-ref.html
== multiple-both-success.html mismatching-ref.html
!= multiple-both-success.html second-mismatching-ref.html
== multiple-both-failure.html matching-ref.html
!= multiple-both-failure.html second-mismatching-ref.html
!= multiple-both-failure.html matching-ref.html
""")

    # FIXME: This test was only being ignored because of missing a leading '/'.
    # Fixing the typo causes several tests to assert, so disabling the test entirely.
    # Add in a file should be ignored by port.find_test_files().
    #files[LAYOUT_TEST_DIR + '/userscripts/resources/iframe.html'] = 'iframe'

    def add_file(test, suffix, contents):
        dirname = filesystem.join(LAYOUT_TEST_DIR, test.name[0:test.name.rfind('/')])
        base = test.base
        filesystem.maybe_make_directory(dirname)
        filesystem.write_binary_file(filesystem.join(dirname, base + suffix), contents)

    # Add each test and the expected output, if any.
    test_list = unit_test_list()
    for test in test_list.tests.values():
        add_file(test, test.name[test.name.rfind('.'):], '')
        if test.is_reftest:
            continue
        if test.actual_audio:
            add_file(test, '-expected.wav', test.expected_audio)
            continue
        add_file(test, '-expected.txt', test.expected_text)
        add_file(test, '-expected.png', test.expected_image)

    filesystem.write_text_file(filesystem.join(LAYOUT_TEST_DIR, 'virtual', 'passes', 'args-expected.txt'), 'args-txt --virtual-arg')
    # Clear the list of written files so that we can watch what happens during testing.
    filesystem.clear_written_files()


class TestPort(Port):
    port_name = 'test'
    default_port_name = 'test-mac-leopard'

    """Test implementation of the Port interface."""
    ALL_BASELINE_VARIANTS = (
        'test-linux-x86_64',
        'test-mac-snowleopard', 'test-mac-leopard',
        'test-win-win7', 'test-win-xp',
    )

    FALLBACK_PATHS = {
        'xp':          ['test-win-win7', 'test-win-xp'],
        'win7':        ['test-win-win7'],
        'leopard':     ['test-mac-leopard', 'test-mac-snowleopard'],
        'snowleopard': ['test-mac-snowleopard'],
        'lucid':       ['test-linux-x86_64', 'test-win-win7'],
    }

    @classmethod
    def determine_full_port_name(cls, host, options, port_name):
        if port_name == 'test':
            return TestPort.default_port_name
        return port_name

    def __init__(self, host, port_name=None, **kwargs):
        Port.__init__(self, host, port_name or TestPort.default_port_name, **kwargs)
        self._tests = unit_test_list()
        self._flakes = set()

        # FIXME: crbug.com/279494. This needs to be in the "real layout tests
        # dir" in a mock filesystem, rather than outside of the checkout, so
        # that tests that want to write to a TestExpectations file can share
        # this between "test" ports and "real" ports.  This is the result of
        # rebaseline_unittest.py having tests that refer to "real" port names
        # and real builders instead of fake builders that point back to the
        # test ports. rebaseline_unittest.py needs to not mix both "real" ports
        # and "test" ports

        self._generic_expectations_path = '/mock-checkout/tests/TestExpectations'
        self._results_directory = None

        self._operating_system = 'mac'
        if self._name.startswith('test-win'):
            self._operating_system = 'win'
        elif self._name.startswith('test-linux'):
            self._operating_system = 'linux'

        version_map = {
            'test-win-xp': 'xp',
            'test-win-win7': 'win7',
            'test-mac-leopard': 'leopard',
            'test-mac-snowleopard': 'snowleopard',
            'test-linux-x86_64': 'lucid',
        }
        self._version = version_map[self._name]

    def repository_paths(self):
        """Returns a list of (repository_name, repository_path) tuples of its depending code base."""
        # FIXME: We override this just to keep the perf tests happy.
        return [('blink', self.layout_tests_dir())]

    def buildbot_archives_baselines(self):
        return self._name != 'test-win-xp'

    def default_pixel_tests(self):
        return True

    def _path_to_driver(self):
        # This routine shouldn't normally be called, but it is called by
        # the mock_drt Driver. We return something, but make sure it's useless.
        return 'MOCK _path_to_driver'

    def default_child_processes(self):
        return 1

    def check_build(self, needs_http, printer):
        return test_run_results.OK_EXIT_STATUS

    def check_sys_deps(self, needs_http):
        return test_run_results.OK_EXIT_STATUS

    def default_configuration(self):
        return 'Release'

    def diff_image(self, expected_contents, actual_contents):
        diffed = actual_contents != expected_contents
        if not actual_contents and not expected_contents:
            return (None, None)
        if not actual_contents or not expected_contents:
            return (True, None)
        if diffed:
            return ("< %s\n---\n> %s\n" % (expected_contents, actual_contents), None)
        return (None, None)

    def layout_tests_dir(self):
        return LAYOUT_TEST_DIR

    def perf_tests_dir(self):
        return PERF_TEST_DIR

    def webkit_base(self):
        return '/test.checkout'

    def _skipped_tests_for_unsupported_features(self, test_list):
        return set(['failures/expected/skip_text.html',
                    'failures/unexpected/skip_pass.html',
                    'virtual/skipped'])

    def name(self):
        return self._name

    def operating_system(self):
        return self._operating_system

    def _path_to_wdiff(self):
        return None

    def default_results_directory(self):
        return '/tmp/layout-test-results'

    def setup_test_run(self):
        pass

    def _driver_class(self):
        return TestDriver

    def start_http_server(self, additional_dirs, number_of_drivers):
        pass

    def start_websocket_server(self):
        pass

    def acquire_http_lock(self):
        pass

    def stop_http_server(self):
        pass

    def stop_websocket_server(self):
        pass

    def release_http_lock(self):
        pass

    def path_to_apache(self):
        return "/usr/sbin/httpd"

    def path_to_apache_config_file(self):
        return self._filesystem.join(self.layout_tests_dir(), 'http', 'conf', 'httpd.conf')

    def path_to_generic_test_expectations_file(self):
        return self._generic_expectations_path

    def _port_specific_expectations_files(self):
        return [self._filesystem.join(self._webkit_baseline_path(d), 'TestExpectations') for d in ['test', 'test-win-xp']]

    def all_test_configurations(self):
        """Returns a sequence of the TestConfigurations the port supports."""
        # By default, we assume we want to test every graphics type in
        # every configuration on every system.
        test_configurations = []
        for version, architecture in self._all_systems():
            for build_type in self._all_build_types():
                test_configurations.append(TestConfiguration(
                    version=version,
                    architecture=architecture,
                    build_type=build_type))
        return test_configurations

    def _all_systems(self):
        return (('leopard', 'x86'),
                ('snowleopard', 'x86'),
                ('xp', 'x86'),
                ('win7', 'x86'),
                ('lucid', 'x86'),
                ('lucid', 'x86_64'))

    def _all_build_types(self):
        return ('debug', 'release')

    def configuration_specifier_macros(self):
        """To avoid surprises when introducing new macros, these are intentionally fixed in time."""
        return {'mac': ['leopard', 'snowleopard'], 'win': ['xp', 'win7'], 'linux': ['lucid']}

    def all_baseline_variants(self):
        return self.ALL_BASELINE_VARIANTS

    def virtual_test_suites(self):
        return [
            VirtualTestSuite('passes', 'passes', ['--virtual-arg'], use_legacy_naming=True),
            VirtualTestSuite('skipped', 'failures/expected', ['--virtual-arg2'], use_legacy_naming=True),
        ]


class TestDriver(Driver):
    """Test/Dummy implementation of the driver interface."""
    next_pid = 1

    def __init__(self, *args, **kwargs):
        super(TestDriver, self).__init__(*args, **kwargs)
        self.started = False
        self.pid = 0

    def cmd_line(self, pixel_tests, per_test_args):
        pixel_tests_flag = '-p' if pixel_tests else ''
        return [self._port._path_to_driver()] + [pixel_tests_flag] + self._port.get_option('additional_drt_flag', []) + per_test_args

    def run_test(self, driver_input, stop_when_done):
        if not self.started:
            self.started = True
            self.pid = TestDriver.next_pid
            TestDriver.next_pid += 1

        start_time = time.time()
        test_name = driver_input.test_name
        test_args = driver_input.args or []
        test = self._port._tests[test_name]
        if test.keyboard:
            raise KeyboardInterrupt
        if test.exception:
            raise ValueError('exception from ' + test_name)
        if test.device_failure:
            raise DeviceFailure('device failure in ' + test_name)

        audio = None
        actual_text = test.actual_text
        crash = test.crash
        web_process_crash = test.web_process_crash

        if 'flaky/text.html' in test_name and not test_name in self._port._flakes:
            self._port._flakes.add(test_name)
            actual_text = 'flaky text failure'

        if 'crash_then_text.html' in test_name:
            if test_name in self._port._flakes:
                actual_text = 'text failure'
            else:
                self._port._flakes.add(test_name)
                crashed_process_name = self._port.driver_name()
                crashed_pid = 1
                crash = True

        if 'text_then_crash.html' in test_name:
            if test_name in self._port._flakes:
                crashed_process_name = self._port.driver_name()
                crashed_pid = 1
                crash = True
            else:
                self._port._flakes.add(test_name)
                actual_text = 'text failure'

        if actual_text and test_args and test_name == 'passes/args.html':
            actual_text = actual_text + ' ' + ' '.join(test_args)

        if test.actual_audio:
            audio = base64.b64decode(test.actual_audio)
        crashed_process_name = None
        crashed_pid = None
        if crash:
            crashed_process_name = self._port.driver_name()
            crashed_pid = 1
        elif web_process_crash:
            crashed_process_name = 'WebProcess'
            crashed_pid = 2

        crash_log = ''
        if crashed_process_name:
            crash_logs = CrashLogs(self._port.host)
            crash_log = crash_logs.find_newest_log(crashed_process_name, None) or ''

        if stop_when_done:
            self.stop()

        if test.actual_checksum == driver_input.image_hash:
            image = None
        else:
            image = test.actual_image
        return DriverOutput(actual_text, image, test.actual_checksum, audio,
            crash=(crash or web_process_crash), crashed_process_name=crashed_process_name,
            crashed_pid=crashed_pid, crash_log=crash_log,
            test_time=time.time() - start_time, timeout=test.timeout, error=test.error, pid=self.pid,
            leak=test.leak)

    def stop(self):
        self.started = False
