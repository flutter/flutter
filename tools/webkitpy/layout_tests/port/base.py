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

"""Abstract base class of Port-specific entry points for the layout tests
test infrastructure (the Port and Driver classes)."""

import cgi
import difflib
import errno
import itertools
import logging
import math
import operator
import optparse
import os
import re
import subprocess
import sys

try:
    from collections import OrderedDict
except ImportError:
    # Needed for Python < 2.7
    from webkitpy.thirdparty.ordered_dict import OrderedDict


from webkitpy.common import find_files
from webkitpy.common import read_checksum_from_png
from webkitpy.common.memoized import memoized
from webkitpy.common.system import path
from webkitpy.common.system.executive import ScriptError
from webkitpy.common.system.path import cygpath
from webkitpy.common.system.systemhost import SystemHost
from webkitpy.common.webkit_finder import WebKitFinder
from webkitpy.layout_tests.layout_package.bot_test_expectations import BotTestExpectationsFactory
from webkitpy.layout_tests.models import test_run_results
from webkitpy.layout_tests.models.test_configuration import TestConfiguration
from webkitpy.layout_tests.port import config as port_config
from webkitpy.layout_tests.port import driver
from webkitpy.layout_tests.port import server_process
from webkitpy.layout_tests.port.factory import PortFactory
from webkitpy.layout_tests.servers import apache_http
from webkitpy.layout_tests.servers import pywebsocket

_log = logging.getLogger(__name__)


# FIXME: This class should merge with WebKitPort now that Chromium behaves mostly like other webkit ports.
class Port(object):
    """Abstract class for Port-specific hooks for the layout_test package."""

    # Subclasses override this. This should indicate the basic implementation
    # part of the port name, e.g., 'mac', 'win', 'gtk'; there is probably (?)
    # one unique value per class.

    # FIXME: We should probably rename this to something like 'implementation_name'.
    port_name = None

    # Test names resemble unix relative paths, and use '/' as a directory separator.
    TEST_PATH_SEPARATOR = '/'

    ALL_BUILD_TYPES = ('debug', 'release')

    CONTENT_SHELL_NAME = 'content_shell'
    MOJO_SHELL_NAME = 'mojo_shell'

    # True if the port as aac and mp3 codecs built in.
    PORT_HAS_AUDIO_CODECS_BUILT_IN = False

    ALL_SYSTEMS = (
        ('snowleopard', 'x86'),
        ('lion', 'x86'),

        # FIXME: We treat Retina (High-DPI) devices as if they are running
        # a different operating system version. This isn't accurate, but will work until
        # we need to test and support baselines across multiple O/S versions.
        ('retina', 'x86'),

        ('mountainlion', 'x86'),
        ('mavericks', 'x86'),
        ('xp', 'x86'),
        ('win7', 'x86'),
        ('lucid', 'x86'),
        ('lucid', 'x86_64'),
        # FIXME: Technically this should be 'arm', but adding a third architecture type breaks TestConfigurationConverter.
        # If we need this to be 'arm' in the future, then we first have to fix TestConfigurationConverter.
        ('icecreamsandwich', 'x86'),
        )

    ALL_BASELINE_VARIANTS = [
        'mac-mavericks', 'mac-mountainlion', 'mac-retina', 'mac-lion', 'mac-snowleopard',
        'win-win7', 'win-xp',
        'linux-x86_64', 'linux-x86',
    ]

    CONFIGURATION_SPECIFIER_MACROS = {
        'mac': ['snowleopard', 'lion', 'retina', 'mountainlion', 'mavericks'],
        'win': ['xp', 'win7'],
        'linux': ['lucid'],
        'android': ['icecreamsandwich'],
    }

    DEFAULT_BUILD_DIRECTORIES = ('out',)

    # overridden in subclasses.
    FALLBACK_PATHS = {}

    SUPPORTED_VERSIONS = []

    # URL to the build requirements page.
    BUILD_REQUIREMENTS_URL = ''

    @classmethod
    def latest_platform_fallback_path(cls):
        return cls.FALLBACK_PATHS[cls.SUPPORTED_VERSIONS[-1]]

    @classmethod
    def _static_build_path(cls, filesystem, build_directory, chromium_base, configuration, comps):
        if build_directory:
            return filesystem.join(build_directory, configuration, *comps)

        hits = []
        for directory in cls.DEFAULT_BUILD_DIRECTORIES:
            base_dir = filesystem.join(chromium_base, directory, configuration)
            path = filesystem.join(base_dir, *comps)
            if filesystem.exists(path):
                hits.append((filesystem.mtime(path), path))

        if hits:
            hits.sort(reverse=True)
            return hits[0][1]  # Return the newest file found.

        # We have to default to something, so pick the last one.
        return filesystem.join(base_dir, *comps)

    @classmethod
    def determine_full_port_name(cls, host, options, port_name):
        """Return a fully-specified port name that can be used to construct objects."""
        # Subclasses will usually override this.
        assert port_name.startswith(cls.port_name)
        return port_name

    def __init__(self, host, port_name, options=None, **kwargs):

        # This value may be different from cls.port_name by having version modifiers
        # and other fields appended to it (for example, 'qt-arm' or 'mac-wk2').
        self._name = port_name

        # These are default values that should be overridden in a subclasses.
        self._version = ''
        self._architecture = 'x86'

        # FIXME: Ideally we'd have a package-wide way to get a
        # well-formed options object that had all of the necessary
        # options defined on it.
        self._options = options or optparse.Values()

        self.host = host
        self._executive = host.executive
        self._filesystem = host.filesystem
        self._webkit_finder = WebKitFinder(host.filesystem)
        self._config = port_config.Config(self._executive, self._filesystem, self.port_name)

        self._helper = None
        self._http_server = None
        self._websocket_server = None
        self._image_differ = None
        self._server_process_constructor = server_process.ServerProcess  # overridable for testing
        self._http_lock = None  # FIXME: Why does this live on the port object?
        self._dump_reader = None

        # Python's Popen has a bug that causes any pipes opened to a
        # process that can't be executed to be leaked.  Since this
        # code is specifically designed to tolerate exec failures
        # to gracefully handle cases where wdiff is not installed,
        # the bug results in a massive file descriptor leak. As a
        # workaround, if an exec failure is ever experienced for
        # wdiff, assume it's not available.  This will leak one
        # file descriptor but that's better than leaking each time
        # wdiff would be run.
        #
        # http://mail.python.org/pipermail/python-list/
        #    2008-August/505753.html
        # http://bugs.python.org/issue3210
        self._wdiff_available = None

        # FIXME: prettypatch.py knows this path, why is it copied here?
        self._pretty_patch_path = self.path_from_webkit_base("tools", "third_party", "PrettyPatch", "prettify.rb")
        self._pretty_patch_available = None

        if not hasattr(options, 'configuration') or not options.configuration:
            self.set_option_default('configuration', self.default_configuration())
        self._test_configuration = None
        self._reftest_list = {}
        self._results_directory = None

    def buildbot_archives_baselines(self):
        return True

    def additional_drt_flag(self):
        driver_name = self.driver_name()
        if driver_name == self.CONTENT_SHELL_NAME:
            return ['--dump-render-tree']
        if driver_name == self.MOJO_SHELL_NAME:
            return [
                '--args-for=mojo:native_viewport_service --use-headless-config --use-osmesa',
                '--content-handlers=text/sky,mojo:sky_viewer',
                '--url-mappings=mojo:window_manager=mojo:sky_tester',
                'mojo:window_manager',
            ]
        return []

    def supports_per_test_timeout(self):
        return False

    def default_pixel_tests(self):
        return False

    def default_smoke_test_only(self):
        return False

    def default_timeout_ms(self):
        # TODO(esprehn): Remove this hack.
        timeout_ms = 30 * 1000
        # if self.get_option('configuration') == 'Debug':
        #     # Debug is usually 2x-3x slower than Release.
        #     return 3 * timeout_ms
        return timeout_ms

    def driver_stop_timeout(self):
        """ Returns the amount of time in seconds to wait before killing the process in driver.stop()."""
        # We want to wait for at least 3 seconds, but if we are really slow, we want to be slow on cleanup as
        # well (for things like ASAN, Valgrind, etc.)
        return 3.0 * float(self.get_option('time_out_ms', '0')) / self.default_timeout_ms()

    def wdiff_available(self):
        if self._wdiff_available is None:
            self._wdiff_available = self.check_wdiff(logging=False)
        return self._wdiff_available

    def pretty_patch_available(self):
        if self._pretty_patch_available is None:
            self._pretty_patch_available = self.check_pretty_patch(logging=False)
        return self._pretty_patch_available

    def default_child_processes(self):
        """Return the number of drivers to use for this port."""
        # FIXME: See if we can reduce the denominator here without causing timeouts.
        # Maybe we need to run one sky_shell process and multiple sky_viewers
        # instead of multiple sky_shells
        return int(math.ceil(float(self._executive.cpu_count()) / 4))

    def default_max_locked_shards(self):
        """Return the number of "locked" shards to run in parallel (like the http tests)."""
        return self.default_child_processes()

    def baseline_path(self):
        """Return the absolute path to the directory to store new baselines in for this port."""
        # FIXME: remove once all callers are calling either baseline_version_dir() or baseline_platform_dir()
        return self.baseline_version_dir()

    def baseline_platform_dir(self):
        """Return the absolute path to the default (version-independent) platform-specific results."""
        return self._filesystem.join(self.layout_tests_dir(), 'platform', self.port_name)

    def baseline_version_dir(self):
        """Return the absolute path to the platform-and-version-specific results."""
        baseline_search_paths = self.baseline_search_path()
        return baseline_search_paths[0]

    def virtual_baseline_search_path(self, test_name):
        suite = self.lookup_virtual_suite(test_name)
        if not suite:
            return None
        return [self._filesystem.join(path, suite.name) for path in self.default_baseline_search_path()]

    def baseline_search_path(self):
        return self.get_option('additional_platform_directory', []) + self._compare_baseline() + self.default_baseline_search_path()

    def default_baseline_search_path(self):
        """Return a list of absolute paths to directories to search under for
        baselines. The directories are searched in order."""
        return map(self._webkit_baseline_path, self.FALLBACK_PATHS[self.version()])

    @memoized
    def _compare_baseline(self):
        factory = PortFactory(self.host)
        target_port = self.get_option('compare_port')
        if target_port:
            return factory.get(target_port).default_baseline_search_path()
        return []

    def _check_file_exists(self, path_to_file, file_description,
                           override_step=None, logging=True):
        """Verify the file is present where expected or log an error.

        Args:
            file_name: The (human friendly) name or description of the file
                you're looking for (e.g., "HTTP Server"). Used for error logging.
            override_step: An optional string to be logged if the check fails.
            logging: Whether or not log the error messages."""
        if not self._filesystem.exists(path_to_file):
            if logging:
                _log.error('Unable to find %s' % file_description)
                _log.error('    at %s' % path_to_file)
                if override_step:
                    _log.error('    %s' % override_step)
                    _log.error('')
            return False
        return True

    def check_build(self, needs_http, printer):
        result = True

        dump_render_tree_binary_path = self._path_to_driver()
        result = self._check_file_exists(dump_render_tree_binary_path,
                                         'test driver') and result
        if not result and self.get_option('build'):
            result = self._check_driver_build_up_to_date(
                self.get_option('configuration'))
        else:
            _log.error('')

        helper_path = self._path_to_helper()
        if helper_path:
            result = self._check_file_exists(helper_path,
                                             'layout test helper') and result

        if self.get_option('pixel_tests'):
            result = self.check_image_diff(
                'To override, invoke with --no-pixel-tests') and result

        # It's okay if pretty patch and wdiff aren't available, but we will at least log messages.
        self._pretty_patch_available = self.check_pretty_patch()
        self._wdiff_available = self.check_wdiff()

        if self._dump_reader:
            result = self._dump_reader.check_is_functional() and result

        if needs_http:
            result = self.check_httpd() and result

        return test_run_results.OK_EXIT_STATUS if result else test_run_results.UNEXPECTED_ERROR_EXIT_STATUS

    def _check_driver(self):
        driver_path = self._path_to_driver()
        if not self._filesystem.exists(driver_path):
            _log.error("%s was not found at %s" % (self.driver_name(), driver_path))
            return False
        return True

    def _check_port_build(self):
        # Ports can override this method to do additional checks.
        return True

    def check_sys_deps(self, needs_http):
        return test_run_results.OK_EXIT_STATUS

    def check_image_diff(self, override_step=None, logging=True):
        """This routine is used to check whether image_diff binary exists."""
        image_diff_path = self._path_to_image_diff()
        if not self._filesystem.exists(image_diff_path):
            _log.error("image_diff was not found at %s" % image_diff_path)
            return False
        return True

    def check_pretty_patch(self, logging=True):
        """Checks whether we can use the PrettyPatch ruby script."""
        try:
            _ = self._executive.run_command(['ruby', '--version'])
        except OSError, e:
            if e.errno in [errno.ENOENT, errno.EACCES, errno.ECHILD]:
                if logging:
                    _log.warning("Ruby is not installed; can't generate pretty patches.")
                    _log.warning('')
                return False

        if not self._filesystem.exists(self._pretty_patch_path):
            if logging:
                _log.warning("Unable to find %s; can't generate pretty patches." % self._pretty_patch_path)
                _log.warning('')
            return False

        return True

    def check_wdiff(self, logging=True):
        if not self._path_to_wdiff():
            # Don't need to log here since this is the port choosing not to use wdiff.
            return False

        try:
            _ = self._executive.run_command([self._path_to_wdiff(), '--help'])
        except OSError:
            if logging:
                message = self._wdiff_missing_message()
                if message:
                    for line in message.splitlines():
                        _log.warning('    ' + line)
                        _log.warning('')
            return False

        return True

    def _wdiff_missing_message(self):
        return 'wdiff is not installed; please install it to generate word-by-word diffs.'

    def check_httpd(self):
        httpd_path = self.path_to_apache()
        try:
            server_name = self._filesystem.basename(httpd_path)
            env = self.setup_environ_for_server(server_name)
            if self._executive.run_command([httpd_path, "-v"], env=env, return_exit_code=True) != 0:
                _log.error("httpd seems broken. Cannot run http tests.")
                return False
            return True
        except OSError:
            _log.error("No httpd found. Cannot run http tests.")
            return False

    def do_text_results_differ(self, expected_text, actual_text):
        return expected_text != actual_text

    def do_audio_results_differ(self, expected_audio, actual_audio):
        return expected_audio != actual_audio

    def diff_image(self, expected_contents, actual_contents):
        """Compare two images and return a tuple of an image diff, and an error string.

        If an error occurs (like image_diff isn't found, or crashes, we log an error and return True (for a diff).
        """
        # If only one of them exists, return that one.
        if not actual_contents and not expected_contents:
            return (None, None)
        if not actual_contents:
            return (expected_contents, None)
        if not expected_contents:
            return (actual_contents, None)

        tempdir = self._filesystem.mkdtemp()

        expected_filename = self._filesystem.join(str(tempdir), "expected.png")
        self._filesystem.write_binary_file(expected_filename, expected_contents)

        actual_filename = self._filesystem.join(str(tempdir), "actual.png")
        self._filesystem.write_binary_file(actual_filename, actual_contents)

        diff_filename = self._filesystem.join(str(tempdir), "diff.png")

        # image_diff needs native win paths as arguments, so we need to convert them if running under cygwin.
        native_expected_filename = self._convert_path(expected_filename)
        native_actual_filename = self._convert_path(actual_filename)
        native_diff_filename = self._convert_path(diff_filename)

        executable = self._path_to_image_diff()
        # Note that although we are handed 'old', 'new', image_diff wants 'new', 'old'.
        comand = [executable, '--diff', native_actual_filename, native_expected_filename, native_diff_filename]

        result = None
        err_str = None
        try:
            exit_code = self._executive.run_command(comand, return_exit_code=True)
            if exit_code == 0:
                # The images are the same.
                result = None
            elif exit_code == 1:
                result = self._filesystem.read_binary_file(native_diff_filename)
            else:
                err_str = "Image diff returned an exit code of %s. See http://crbug.com/278596" % exit_code
        except OSError, e:
            err_str = 'error running image diff: %s' % str(e)
        finally:
            self._filesystem.rmtree(str(tempdir))

        return (result, err_str or None)

    def diff_text(self, expected_text, actual_text, expected_filename, actual_filename):
        """Returns a string containing the diff of the two text strings
        in 'unified diff' format."""

        # The filenames show up in the diff output, make sure they're
        # raw bytes and not unicode, so that they don't trigger join()
        # trying to decode the input.
        def to_raw_bytes(string_value):
            if isinstance(string_value, unicode):
                return string_value.encode('utf-8')
            return string_value
        expected_filename = to_raw_bytes(expected_filename)
        actual_filename = to_raw_bytes(actual_filename)
        diff = difflib.unified_diff(expected_text.splitlines(True),
                                    actual_text.splitlines(True),
                                    expected_filename,
                                    actual_filename)

        # The diff generated by the difflib is incorrect if one of the files
        # does not have a newline at the end of the file and it is present in
        # the diff. Relevant Python issue: http://bugs.python.org/issue2142
        def diff_fixup(diff):
            for line in diff:
                yield line
                if not line.endswith('\n'):
                    yield '\n\ No newline at end of file\n'

        return ''.join(diff_fixup(diff))

    def driver_name(self):
        if self.get_option('driver_name'):
            return self.get_option('driver_name')
        return self.MOJO_SHELL_NAME

    def expected_baselines_by_extension(self, test_name):
        """Returns a dict mapping baseline suffix to relative path for each baseline in
        a test. For reftests, it returns ".==" or ".!=" instead of the suffix."""
        # FIXME: The name similarity between this and expected_baselines() below, is unfortunate.
        # We should probably rename them both.
        baseline_dict = {}
        reference_files = self.reference_files(test_name)
        if reference_files:
            # FIXME: How should this handle more than one type of reftest?
            baseline_dict['.' + reference_files[0][0]] = self.relative_test_filename(reference_files[0][1])

        for extension in self.baseline_extensions():
            path = self.expected_filename(test_name, extension, return_default=False)
            baseline_dict[extension] = self.relative_test_filename(path) if path else path

        return baseline_dict

    def baseline_extensions(self):
        """Returns a tuple of all of the non-reftest baseline extensions we use. The extensions include the leading '.'."""
        return ('.wav', '.txt', '.png')

    def expected_baselines(self, test_name, suffix, all_baselines=False):
        """Given a test name, finds where the baseline results are located.

        Args:
        test_name: name of test file (usually a relative path under tests/)
        suffix: file suffix of the expected results, including dot; e.g.
            '.txt' or '.png'.  This should not be None, but may be an empty
            string.
        all_baselines: If True, return an ordered list of all baseline paths
            for the given platform. If False, return only the first one.
        Returns
        a list of ( platform_dir, results_filename ), where
            platform_dir - abs path to the top of the results tree (or test
                tree)
            results_filename - relative path from top of tree to the results
                file
            (port.join() of the two gives you the full path to the file,
                unless None was returned.)
        Return values will be in the format appropriate for the current
        platform (e.g., "\\" for path separators on Windows). If the results
        file is not found, then None will be returned for the directory,
        but the expected relative pathname will still be returned.

        This routine is generic but lives here since it is used in
        conjunction with the other baseline and filename routines that are
        platform specific.
        """
        baseline_filename = self._filesystem.splitext(test_name)[0] + '-expected' + suffix
        baseline_search_path = self.baseline_search_path()

        baselines = []
        for platform_dir in baseline_search_path:
            if self._filesystem.exists(self._filesystem.join(platform_dir, baseline_filename)):
                baselines.append((platform_dir, baseline_filename))

            if not all_baselines and baselines:
                return baselines

        # If it wasn't found in a platform directory, return the expected
        # result in the test directory, even if no such file actually exists.
        platform_dir = self.layout_tests_dir()
        if self._filesystem.exists(self._filesystem.join(platform_dir, baseline_filename)):
            baselines.append((platform_dir, baseline_filename))

        if baselines:
            return baselines

        return [(None, baseline_filename)]

    def expected_filename(self, test_name, suffix, return_default=True):
        """Given a test name, returns an absolute path to its expected results.

        If no expected results are found in any of the searched directories,
        the directory in which the test itself is located will be returned.
        The return value is in the format appropriate for the platform
        (e.g., "\\" for path separators on windows).

        Args:
        test_name: name of test file (usually a relative path under tests/)
        suffix: file suffix of the expected results, including dot; e.g. '.txt'
            or '.png'.  This should not be None, but may be an empty string.
        platform: the most-specific directory name to use to build the
            search list of directories, e.g., 'win', or
            'chromium-cg-mac-leopard' (we follow the WebKit format)
        return_default: if True, returns the path to the generic expectation if nothing
            else is found; if False, returns None.

        This routine is generic but is implemented here to live alongside
        the other baseline and filename manipulation routines.
        """
        # FIXME: The [0] here is very mysterious, as is the destructured return.
        platform_dir, baseline_filename = self.expected_baselines(test_name, suffix)[0]
        if platform_dir:
            return self._filesystem.join(platform_dir, baseline_filename)

        actual_test_name = self.lookup_virtual_test_base(test_name)
        if actual_test_name:
            return self.expected_filename(actual_test_name, suffix)

        if return_default:
            return self._filesystem.join(self.layout_tests_dir(), baseline_filename)
        return None

    def expected_checksum(self, test_name):
        """Returns the checksum of the image we expect the test to produce, or None if it is a text-only test."""
        png_path = self.expected_filename(test_name, '.png')

        if self._filesystem.exists(png_path):
            with self._filesystem.open_binary_file_for_reading(png_path) as filehandle:
                return read_checksum_from_png.read_checksum(filehandle)

        return None

    def expected_image(self, test_name):
        """Returns the image we expect the test to produce."""
        baseline_path = self.expected_filename(test_name, '.png')
        if not self._filesystem.exists(baseline_path):
            return None
        return self._filesystem.read_binary_file(baseline_path)

    def expected_audio(self, test_name):
        baseline_path = self.expected_filename(test_name, '.wav')
        if not self._filesystem.exists(baseline_path):
            return None
        return self._filesystem.read_binary_file(baseline_path)

    def expected_text(self, test_name):
        """Returns the text output we expect the test to produce, or None
        if we don't expect there to be any text output.
        End-of-line characters are normalized to '\n'."""
        # FIXME: DRT output is actually utf-8, but since we don't decode the
        # output from DRT (instead treating it as a binary string), we read the
        # baselines as a binary string, too.
        baseline_path = self.expected_filename(test_name, '.txt')
        if not self._filesystem.exists(baseline_path):
            return None
        text = self._filesystem.read_binary_file(baseline_path)
        return text.replace("\r\n", "\n")

    def _get_reftest_list(self, test_name):
        dirname = self._filesystem.join(self.layout_tests_dir(), self._filesystem.dirname(test_name))
        if dirname not in self._reftest_list:
            self._reftest_list[dirname] = Port._parse_reftest_list(self._filesystem, dirname)
        return self._reftest_list[dirname]

    @staticmethod
    def _parse_reftest_list(filesystem, test_dirpath):
        reftest_list_path = filesystem.join(test_dirpath, 'reftest.list')
        if not filesystem.isfile(reftest_list_path):
            return None
        reftest_list_file = filesystem.read_text_file(reftest_list_path)

        parsed_list = {}
        for line in reftest_list_file.split('\n'):
            line = re.sub('#.+$', '', line)
            split_line = line.split()
            if len(split_line) == 4:
                # FIXME: Probably one of mozilla's extensions in the reftest.list format. Do we need to support this?
                _log.warning("unsupported reftest.list line '%s' in %s" % (line, reftest_list_path))
                continue
            if len(split_line) < 3:
                continue
            expectation_type, test_file, ref_file = split_line
            parsed_list.setdefault(filesystem.join(test_dirpath, test_file), []).append((expectation_type, filesystem.join(test_dirpath, ref_file)))
        return parsed_list

    def reference_files(self, test_name):
        """Return a list of expectation (== or !=) and filename pairs"""

        reftest_list = self._get_reftest_list(test_name)
        if not reftest_list:
            reftest_list = []
            for expectation, prefix in (('==', ''), ('!=', '-mismatch')):
                for extention in Port._supported_file_extensions:
                    path = self.expected_filename(test_name, prefix + extention)
                    if self._filesystem.exists(path):
                        reftest_list.append((expectation, path))
            return reftest_list

        return reftest_list.get(self._filesystem.join(self.layout_tests_dir(), test_name), [])  # pylint: disable=E1103

    def tests(self, paths):
        """Return the list of tests found matching paths."""
        tests = self._real_tests(paths)
        tests.extend(self._virtual_tests(paths, self.populated_virtual_test_suites()))
        return tests

    def _real_tests(self, paths):
        # When collecting test cases, skip these directories
        skipped_directories = set(['.svn', '_svn', 'platform', 'resources', 'support', 'script-tests', 'reference', 'reftest', 'conf'])
        files = find_files.find(self._filesystem, self.layout_tests_dir(), paths, skipped_directories, Port.is_test_file, self.test_key)
        return [self.relative_test_filename(f) for f in files]

    # When collecting test cases, we include any file with these extensions.
    _supported_file_extensions = set(['.sky'])

    @staticmethod
    # If any changes are made here be sure to update the isUsedInReftest method in old-run-webkit-tests as well.
    def is_reference_html_file(filesystem, dirname, filename):
        if filename.startswith('ref-') or filename.startswith('notref-'):
            return True
        filename_wihout_ext, unused = filesystem.splitext(filename)
        for suffix in ['-expected', '-expected-mismatch', '-ref', '-notref']:
            if filename_wihout_ext.endswith(suffix):
                return True
        return False

    @staticmethod
    def _has_supported_extension(filesystem, filename):
        """Return true if filename is one of the file extensions we want to run a test on."""
        extension = filesystem.splitext(filename)[1]
        return extension in Port._supported_file_extensions

    @staticmethod
    def is_test_file(filesystem, dirname, filename):
        return Port._has_supported_extension(filesystem, filename) and not Port.is_reference_html_file(filesystem, dirname, filename)

    ALL_TEST_TYPES = ['audio', 'harness', 'pixel', 'ref', 'text', 'unknown']

    def test_type(self, test_name):
        fs = self._filesystem
        if fs.exists(self.expected_filename(test_name, '.png')):
            return 'pixel'
        if fs.exists(self.expected_filename(test_name, '.wav')):
            return 'audio'
        if self.reference_files(test_name):
            return 'ref'
        txt = self.expected_text(test_name)
        if txt:
            if 'layer at (0,0) size 800x600' in txt:
                return 'pixel'
            for line in txt.splitlines():
                if line.startswith('FAIL') or line.startswith('TIMEOUT') or line.startswith('PASS'):
                    return 'harness'
            return 'text'
        return 'unknown'

    def test_key(self, test_name):
        """Turns a test name into a list with two sublists, the natural key of the
        dirname, and the natural key of the basename.

        This can be used when sorting paths so that files in a directory.
        directory are kept together rather than being mixed in with files in
        subdirectories."""
        dirname, basename = self.split_test(test_name)
        return (self._natural_sort_key(dirname + self.TEST_PATH_SEPARATOR), self._natural_sort_key(basename))

    def _natural_sort_key(self, string_to_split):
        """ Turns a string into a list of string and number chunks, i.e. "z23a" -> ["z", 23, "a"]

        This can be used to implement "natural sort" order. See:
        http://www.codinghorror.com/blog/2007/12/sorting-for-humans-natural-sort-order.html
        http://nedbatchelder.com/blog/200712.html#e20071211T054956
        """
        def tryint(val):
            try:
                return int(val)
            except ValueError:
                return val

        return [tryint(chunk) for chunk in re.split('(\d+)', string_to_split)]

    def test_dirs(self):
        """Returns the list of top-level test directories."""
        layout_tests_dir = self.layout_tests_dir()
        return filter(lambda x: self._filesystem.isdir(self._filesystem.join(layout_tests_dir, x)),
                      self._filesystem.listdir(layout_tests_dir))

    @memoized
    def test_isfile(self, test_name):
        """Return True if the test name refers to a directory of tests."""
        # Used by test_expectations.py to apply rules to whole directories.
        if self._filesystem.isfile(self.abspath_for_test(test_name)):
            return True
        base = self.lookup_virtual_test_base(test_name)
        return base and self._filesystem.isfile(self.abspath_for_test(base))

    @memoized
    def test_isdir(self, test_name):
        """Return True if the test name refers to a directory of tests."""
        # Used by test_expectations.py to apply rules to whole directories.
        if self._filesystem.isdir(self.abspath_for_test(test_name)):
            return True
        base = self.lookup_virtual_test_base(test_name)
        return base and self._filesystem.isdir(self.abspath_for_test(base))

    @memoized
    def test_exists(self, test_name):
        """Return True if the test name refers to an existing test or baseline."""
        # Used by test_expectations.py to determine if an entry refers to a
        # valid test and by printing.py to determine if baselines exist.
        return self.test_isfile(test_name) or self.test_isdir(test_name)

    def split_test(self, test_name):
        """Splits a test name into the 'directory' part and the 'basename' part."""
        index = test_name.rfind(self.TEST_PATH_SEPARATOR)
        if index < 1:
            return ('', test_name)
        return (test_name[0:index], test_name[index:])

    def normalize_test_name(self, test_name):
        """Returns a normalized version of the test name or test directory."""
        if test_name.endswith('/'):
            return test_name
        if self.test_isdir(test_name):
            return test_name + '/'
        return test_name

    def driver_cmd_line(self):
        """Prints the DRT command line that will be used."""
        driver = self.create_driver(0)
        return driver.cmd_line(self.get_option('pixel_tests'), [])

    def update_baseline(self, baseline_path, data):
        """Updates the baseline for a test.

        Args:
            baseline_path: the actual path to use for baseline, not the path to
              the test. This function is used to update either generic or
              platform-specific baselines, but we can't infer which here.
            data: contents of the baseline.
        """
        self._filesystem.write_binary_file(baseline_path, data)

    # FIXME: update callers to create a finder and call it instead of these next five routines (which should be protected).
    def webkit_base(self):
        return self._webkit_finder.webkit_base()

    def path_from_webkit_base(self, *comps):
        return self._webkit_finder.path_from_webkit_base(*comps)

    def path_from_chromium_base(self, *comps):
        return self._webkit_finder.path_from_chromium_base(*comps)

    def path_to_script(self, script_name):
        return self._webkit_finder.path_to_script(script_name)

    def layout_tests_dir(self):
        return self._webkit_finder.layout_tests_dir()

    def perf_tests_dir(self):
        return self._webkit_finder.perf_tests_dir()

    def skipped_layout_tests(self, test_list):
        """Returns tests skipped outside of the TestExpectations files."""
        return set(self._skipped_tests_for_unsupported_features(test_list))

    def _tests_from_skipped_file_contents(self, skipped_file_contents):
        tests_to_skip = []
        for line in skipped_file_contents.split('\n'):
            line = line.strip()
            line = line.rstrip('/')  # Best to normalize directory names to not include the trailing slash.
            if line.startswith('#') or not len(line):
                continue
            tests_to_skip.append(line)
        return tests_to_skip

    def _expectations_from_skipped_files(self, skipped_file_paths):
        tests_to_skip = []
        for search_path in skipped_file_paths:
            filename = self._filesystem.join(self._webkit_baseline_path(search_path), "Skipped")
            if not self._filesystem.exists(filename):
                _log.debug("Skipped does not exist: %s" % filename)
                continue
            _log.debug("Using Skipped file: %s" % filename)
            skipped_file_contents = self._filesystem.read_text_file(filename)
            tests_to_skip.extend(self._tests_from_skipped_file_contents(skipped_file_contents))
        return tests_to_skip

    @memoized
    def skipped_perf_tests(self):
        return self._expectations_from_skipped_files([self.perf_tests_dir()])

    def skips_perf_test(self, test_name):
        for test_or_category in self.skipped_perf_tests():
            if test_or_category == test_name:
                return True
            category = self._filesystem.join(self.perf_tests_dir(), test_or_category)
            if self._filesystem.isdir(category) and test_name.startswith(test_or_category):
                return True
        return False

    def is_chromium(self):
        return True

    def name(self):
        """Returns a name that uniquely identifies this particular type of port
        (e.g., "mac-snowleopard" or "linux-x86_x64" and can be passed
        to factory.get() to instantiate the port."""
        return self._name

    def operating_system(self):
        # Subclasses should override this default implementation.
        return 'mac'

    def version(self):
        """Returns a string indicating the version of a given platform, e.g.
        'leopard' or 'xp'.

        This is used to help identify the exact port when parsing test
        expectations, determining search paths, and logging information."""
        return self._version

    def architecture(self):
        return self._architecture

    def get_option(self, name, default_value=None):
        return getattr(self._options, name, default_value)

    def set_option_default(self, name, default_value):
        return self._options.ensure_value(name, default_value)

    @memoized
    def path_to_generic_test_expectations_file(self):
        return self._filesystem.join(self.layout_tests_dir(), 'TestExpectations')

    def relative_test_filename(self, filename):
        """Returns a test_name a relative unix-style path for a filename under the tests
        directory. Ports may legitimately return abspaths here if no relpath makes sense."""
        # Ports that run on windows need to override this method to deal with
        # filenames with backslashes in them.
        if filename.startswith(self.layout_tests_dir()):
            return self.host.filesystem.relpath(filename, self.layout_tests_dir())
        else:
            return self.host.filesystem.abspath(filename)

    @memoized
    def abspath_for_test(self, test_name):
        """Returns the full path to the file for a given test name. This is the
        inverse of relative_test_filename()."""
        return self._filesystem.join(self.layout_tests_dir(), test_name)

    def results_directory(self):
        """Absolute path to the place to store the test results (uses --results-directory)."""
        if not self._results_directory:
            option_val = self.get_option('results_directory') or self.default_results_directory()
            self._results_directory = self._filesystem.abspath(option_val)
        return self._results_directory

    def perf_results_directory(self):
        return self._build_path()

    def default_results_directory(self):
        """Absolute path to the default place to store the test results."""
        return self._build_path('layout-test-results')

    def setup_test_run(self):
        """Perform port-specific work at the beginning of a test run."""
        # Delete the disk cache if any to ensure a clean test run.
        dump_render_tree_binary_path = self._path_to_driver()
        cachedir = self._filesystem.dirname(dump_render_tree_binary_path)
        cachedir = self._filesystem.join(cachedir, "cache")
        if self._filesystem.exists(cachedir):
            self._filesystem.rmtree(cachedir)

        if self._dump_reader:
            self._filesystem.maybe_make_directory(self._dump_reader.crash_dumps_directory())

    def num_workers(self, requested_num_workers):
        """Returns the number of available workers (possibly less than the number requested)."""
        return requested_num_workers

    def clean_up_test_run(self):
        """Perform port-specific work at the end of a test run."""
        if self._image_differ:
            self._image_differ.stop()
            self._image_differ = None

    # FIXME: os.environ access should be moved to onto a common/system class to be more easily mockable.
    def _value_or_default_from_environ(self, name, default=None):
        if name in os.environ:
            return os.environ[name]
        return default

    def _copy_value_from_environ_if_set(self, clean_env, name):
        if name in os.environ:
            clean_env[name] = os.environ[name]

    def setup_environ_for_server(self, server_name=None):
        # We intentionally copy only a subset of os.environ when
        # launching subprocesses to ensure consistent test results.
        clean_env = {
            'LOCAL_RESOURCE_ROOT': self.layout_tests_dir(),  # FIXME: Is this used?
        }
        variables_to_copy = [
            'WEBKIT_TESTFONTS',  # FIXME: Is this still used?
            'WEBKITOUTPUTDIR',   # FIXME: Is this still used?
            'CHROME_DEVEL_SANDBOX',
            'CHROME_IPC_LOGGING',
            'ASAN_OPTIONS',
            'VALGRIND_LIB',
            'VALGRIND_LIB_INNER',
        ]
        if self.host.platform.is_linux() or self.host.platform.is_freebsd():
            variables_to_copy += [
                'XAUTHORITY',
                'HOME',
                'LANG',
                'LD_LIBRARY_PATH',
                'DBUS_SESSION_BUS_ADDRESS',
                'XDG_DATA_DIRS',
            ]
            clean_env['DISPLAY'] = self._value_or_default_from_environ('DISPLAY', ':1')
        if self.host.platform.is_mac():
            clean_env['DYLD_LIBRARY_PATH'] = self._build_path()
            clean_env['DYLD_FRAMEWORK_PATH'] = self._build_path()
            variables_to_copy += [
                'HOME',
            ]
        if self.host.platform.is_win():
            variables_to_copy += [
                'PATH',
                'GYP_DEFINES',  # Required to locate win sdk.
            ]
        if self.host.platform.is_cygwin():
            variables_to_copy += [
                'HOMEDRIVE',
                'HOMEPATH',
                '_NT_SYMBOL_PATH',
            ]

        for variable in variables_to_copy:
            self._copy_value_from_environ_if_set(clean_env, variable)

        for string_variable in self.get_option('additional_env_var', []):
            [name, value] = string_variable.split('=', 1)
            clean_env[name] = value

        return clean_env

    def show_results_html_file(self, results_filename):
        """This routine should display the HTML file pointed at by
        results_filename in a users' browser."""
        return self.host.user.open_url(path.abspath_to_uri(self.host.platform, results_filename))

    def create_driver(self, worker_number, no_timeout=False):
        """Return a newly created Driver subclass for starting/stopping the test driver."""
        return self._driver_class()(self, worker_number, pixel_tests=self.get_option('pixel_tests'), no_timeout=no_timeout)

    def start_helper(self):
        """If a port needs to reconfigure graphics settings or do other
        things to ensure a known test configuration, it should override this
        method."""
        helper_path = self._path_to_helper()
        if helper_path:
            _log.debug("Starting layout helper %s" % helper_path)
            # Note: Not thread safe: http://bugs.python.org/issue2320
            self._helper = self._executive.popen([helper_path],
                stdin=self._executive.PIPE, stdout=self._executive.PIPE, stderr=None)
            is_ready = self._helper.stdout.readline()
            if not is_ready.startswith('ready'):
                _log.error("layout_test_helper failed to be ready")

    def requires_http_server(self):
        """Does the port require an HTTP server for running tests? This could
        be the case when the tests aren't run on the host platform."""
        return True

    def start_http_server(self, additional_dirs, number_of_drivers):
        """Start a web server. Raise an error if it can't start or is already running.

        Ports can stub this out if they don't need a web server to be running."""
        assert not self._http_server, 'Already running an http server.'

        self._http_server = subprocess.Popen([
            self.path_to_script('sky_server'),
            '-t', self.get_option('configuration'),
            self.path_from_chromium_base(),
            '8000',
        ])

    def start_websocket_server(self):
        """Start a web server. Raise an error if it can't start or is already running.

        Ports can stub this out if they don't need a websocket server to be running."""
        assert not self._websocket_server, 'Already running a websocket server.'

        server = pywebsocket.PyWebSocket(self, self.results_directory())
        server.start()
        self._websocket_server = server

    def http_server_supports_ipv6(self):
        # Apache < 2.4 on win32 does not support IPv6, nor does cygwin apache.
        if self.host.platform.is_cygwin() or self.host.platform.is_win():
            return False
        return True

    def stop_helper(self):
        """Shut down the test helper if it is running. Do nothing if
        it isn't, or it isn't available. If a port overrides start_helper()
        it must override this routine as well."""
        if self._helper:
            _log.debug("Stopping layout test helper")
            try:
                self._helper.stdin.write("x\n")
                self._helper.stdin.close()
                self._helper.wait()
            except IOError, e:
                pass
            finally:
                self._helper = None

    def stop_http_server(self):
        """Shut down the http server if it is running. Do nothing if it isn't."""
        if self._http_server:
            self._http_server.terminate()
            self._http_server = None

    def stop_websocket_server(self):
        """Shut down the websocket server if it is running. Do nothing if it isn't."""
        if self._websocket_server:
            self._websocket_server.stop()
            self._websocket_server = None

    #
    # TEST EXPECTATION-RELATED METHODS
    #

    def test_configuration(self):
        """Returns the current TestConfiguration for the port."""
        if not self._test_configuration:
            self._test_configuration = TestConfiguration(self._version, self._architecture, self._options.configuration.lower())
        return self._test_configuration

    # FIXME: Belongs on a Platform object.
    @memoized
    def all_test_configurations(self):
        """Returns a list of TestConfiguration instances, representing all available
        test configurations for this port."""
        return self._generate_all_test_configurations()

    # FIXME: Belongs on a Platform object.
    def configuration_specifier_macros(self):
        """Ports may provide a way to abbreviate configuration specifiers to conveniently
        refer to them as one term or alias specific values to more generic ones. For example:

        (xp, vista, win7) -> win # Abbreviate all Windows versions into one namesake.
        (lucid) -> linux  # Change specific name of the Linux distro to a more generic term.

        Returns a dictionary, each key representing a macro term ('win', for example),
        and value being a list of valid configuration specifiers (such as ['xp', 'vista', 'win7'])."""
        return self.CONFIGURATION_SPECIFIER_MACROS

    def all_baseline_variants(self):
        """Returns a list of platform names sufficient to cover all the baselines.

        The list should be sorted so that a later platform  will reuse
        an earlier platform's baselines if they are the same (e.g.,
        'snowleopard' should precede 'leopard')."""
        return self.ALL_BASELINE_VARIANTS

    def _generate_all_test_configurations(self):
        """Returns a sequence of the TestConfigurations the port supports."""
        # By default, we assume we want to test every graphics type in
        # every configuration on every system.
        test_configurations = []
        for version, architecture in self.ALL_SYSTEMS:
            for build_type in self.ALL_BUILD_TYPES:
                test_configurations.append(TestConfiguration(version, architecture, build_type))
        return test_configurations

    try_builder_names = frozenset([
        'linux_layout',
        'mac_layout',
        'win_layout',
        'linux_layout_rel',
        'mac_layout_rel',
        'win_layout_rel',
    ])

    def warn_if_bug_missing_in_test_expectations(self):
        return True

    def _port_specific_expectations_files(self):
        return []

    def expectations_dict(self):
        """Returns an OrderedDict of name -> expectations strings.
        The names are expected to be (but not required to be) paths in the filesystem.
        If the name is a path, the file can be considered updatable for things like rebaselining,
        so don't use names that are paths if they're not paths.
        Generally speaking the ordering should be files in the filesystem in cascade order
        (TestExpectations followed by Skipped, if the port honors both formats),
        then any built-in expectations (e.g., from compile-time exclusions), then --additional-expectations options."""
        # FIXME: rename this to test_expectations() once all the callers are updated to know about the ordered dict.
        expectations = OrderedDict()

        for path in self.expectations_files():
            if self._filesystem.exists(path):
                expectations[path] = self._filesystem.read_text_file(path)

        for path in self.get_option('additional_expectations', []):
            expanded_path = self._filesystem.expanduser(path)
            if self._filesystem.exists(expanded_path):
                _log.debug("reading additional_expectations from path '%s'" % path)
                expectations[path] = self._filesystem.read_text_file(expanded_path)
            else:
                _log.warning("additional_expectations path '%s' does not exist" % path)
        return expectations

    def bot_expectations(self):
        if not self.get_option('ignore_flaky_tests'):
            return {}

        full_port_name = self.determine_full_port_name(self.host, self._options, self.port_name)
        builder_category = self.get_option('ignore_builder_category', 'layout')
        factory = BotTestExpectationsFactory()
        # FIXME: This only grabs release builder's flakiness data. If we're running debug,
        # when we should grab the debug builder's data.
        expectations = factory.expectations_for_port(full_port_name, builder_category)

        if not expectations:
            return {}

        ignore_mode = self.get_option('ignore_flaky_tests')
        if ignore_mode == 'very-flaky' or ignore_mode == 'maybe-flaky':
            return expectations.flakes_by_path(ignore_mode == 'very-flaky')
        if ignore_mode == 'unexpected':
            return expectations.unexpected_results_by_path()
        _log.warning("Unexpected ignore mode: '%s'." % ignore_mode)
        return {}

    def expectations_files(self):
        return [self.path_to_generic_test_expectations_file()] + self._port_specific_expectations_files()

    def repository_paths(self):
        """Returns a list of (repository_name, repository_path) tuples of its depending code base."""
        return [('blink', self.layout_tests_dir()),
                ('chromium', self.path_from_chromium_base('build'))]

    _WDIFF_DEL = '##WDIFF_DEL##'
    _WDIFF_ADD = '##WDIFF_ADD##'
    _WDIFF_END = '##WDIFF_END##'

    def _format_wdiff_output_as_html(self, wdiff):
        wdiff = cgi.escape(wdiff)
        wdiff = wdiff.replace(self._WDIFF_DEL, "<span class=del>")
        wdiff = wdiff.replace(self._WDIFF_ADD, "<span class=add>")
        wdiff = wdiff.replace(self._WDIFF_END, "</span>")
        html = "<head><style>.del { background: #faa; } "
        html += ".add { background: #afa; }</style></head>"
        html += "<pre>%s</pre>" % wdiff
        return html

    def _wdiff_command(self, actual_filename, expected_filename):
        executable = self._path_to_wdiff()
        return [executable,
                "--start-delete=%s" % self._WDIFF_DEL,
                "--end-delete=%s" % self._WDIFF_END,
                "--start-insert=%s" % self._WDIFF_ADD,
                "--end-insert=%s" % self._WDIFF_END,
                actual_filename,
                expected_filename]

    @staticmethod
    def _handle_wdiff_error(script_error):
        # Exit 1 means the files differed, any other exit code is an error.
        if script_error.exit_code != 1:
            raise script_error

    def _run_wdiff(self, actual_filename, expected_filename):
        """Runs wdiff and may throw exceptions.
        This is mostly a hook for unit testing."""
        # Diffs are treated as binary as they may include multiple files
        # with conflicting encodings.  Thus we do not decode the output.
        command = self._wdiff_command(actual_filename, expected_filename)
        wdiff = self._executive.run_command(command, decode_output=False,
            error_handler=self._handle_wdiff_error)
        return self._format_wdiff_output_as_html(wdiff)

    _wdiff_error_html = "Failed to run wdiff, see error log."

    def wdiff_text(self, actual_filename, expected_filename):
        """Returns a string of HTML indicating the word-level diff of the
        contents of the two filenames. Returns an empty string if word-level
        diffing isn't available."""
        if not self.wdiff_available():
            return ""
        try:
            # It's possible to raise a ScriptError we pass wdiff invalid paths.
            return self._run_wdiff(actual_filename, expected_filename)
        except OSError as e:
            if e.errno in [errno.ENOENT, errno.EACCES, errno.ECHILD]:
                # Silently ignore cases where wdiff is missing.
                self._wdiff_available = False
                return ""
            raise
        except ScriptError as e:
            _log.error("Failed to run wdiff: %s" % e)
            self._wdiff_available = False
            return self._wdiff_error_html

    # This is a class variable so we can test error output easily.
    _pretty_patch_error_html = "Failed to run PrettyPatch, see error log."

    def pretty_patch_text(self, diff_path):
        if self._pretty_patch_available is None:
            self._pretty_patch_available = self.check_pretty_patch(logging=False)
        if not self._pretty_patch_available:
            return self._pretty_patch_error_html
        command = ("ruby", "-I", self._filesystem.dirname(self._pretty_patch_path),
                   self._pretty_patch_path, diff_path)
        try:
            # Diffs are treated as binary (we pass decode_output=False) as they
            # may contain multiple files of conflicting encodings.
            return self._executive.run_command(command, decode_output=False)
        except OSError, e:
            # If the system is missing ruby log the error and stop trying.
            self._pretty_patch_available = False
            _log.error("Failed to run PrettyPatch (%s): %s" % (command, e))
            return self._pretty_patch_error_html
        except ScriptError, e:
            # If ruby failed to run for some reason, log the command
            # output and stop trying.
            self._pretty_patch_available = False
            _log.error("Failed to run PrettyPatch (%s):\n%s" % (command, e.message_with_output()))
            return self._pretty_patch_error_html

    def default_configuration(self):
        return self._config.default_configuration()

    def clobber_old_port_specific_results(self):
        pass

    # FIXME: This does not belong on the port object.
    @memoized
    def path_to_apache(self):
        """Returns the full path to the apache binary.

        This is needed only by ports that use the apache_http_server module."""
        raise NotImplementedError('Port.path_to_apache')

    def path_to_apache_config_file(self):
        """Returns the full path to the apache configuration file.

        If the WEBKIT_HTTP_SERVER_CONF_PATH environment variable is set, its
        contents will be used instead.

        This is needed only by ports that use the apache_http_server module."""
        config_file_path = os.environ.get('WEBKIT_HTTP_SERVER_CONF_PATH')
        if not config_file_path:
            config_file_name = self._apache_config_file_name_for_platform(sys.platform)
            config_file_path = self._filesystem.join(self.layout_tests_dir(), 'http', 'conf', config_file_name)
        if not self._filesystem.exists(config_file_path):
            raise IOError('%s was not found on the system' % config_file_path)
        return config_file_path

    #
    # PROTECTED ROUTINES
    #
    # The routines below should only be called by routines in this class
    # or any of its subclasses.
    #

    # FIXME: This belongs on some platform abstraction instead of Port.
    def _is_redhat_based(self):
        return self._filesystem.exists('/etc/redhat-release')

    def _is_debian_based(self):
        return self._filesystem.exists('/etc/debian_version')

    def _apache_version(self):
        config = self._executive.run_command([self.path_to_apache(), '-v'])
        return re.sub(r'(?:.|\n)*Server version: Apache/(\d+\.\d+)(?:.|\n)*', r'\1', config)

    # We pass sys_platform into this method to make it easy to unit test.
    def _apache_config_file_name_for_platform(self, sys_platform):
        if sys_platform == 'cygwin':
            return 'cygwin-httpd.conf'  # CYGWIN is the only platform to still use Apache 1.3.
        if sys_platform.startswith('linux'):
            if self._is_redhat_based():
                return 'fedora-httpd-' + self._apache_version() + '.conf'
            if self._is_debian_based():
                return 'debian-httpd-' + self._apache_version() + '.conf'
        # All platforms use apache2 except for CYGWIN (and Mac OS X Tiger and prior, which we no longer support).
        return "apache2-httpd.conf"

    def _path_to_driver(self, configuration=None):
        """Returns the full path to the test driver."""
        return self._build_path(self.driver_name())

    def _path_to_webcore_library(self):
        """Returns the full path to a built copy of WebCore."""
        return None

    def _path_to_helper(self):
        """Returns the full path to the layout_test_helper binary, which
        is used to help configure the system for the test run, or None
        if no helper is needed.

        This is likely only used by start/stop_helper()."""
        return None

    def _path_to_image_diff(self):
        """Returns the full path to the image_diff binary, or None if it is not available.

        This is likely used only by diff_image()"""
        return self._build_path('image_diff')

    @memoized
    def _path_to_wdiff(self):
        """Returns the full path to the wdiff binary, or None if it is not available.

        This is likely used only by wdiff_text()"""
        for path in ("/usr/bin/wdiff", "/usr/bin/dwdiff"):
            if self._filesystem.exists(path):
                return path
        return None

    def _webkit_baseline_path(self, platform):
        """Return the  full path to the top of the baseline tree for a
        given platform."""
        return self._filesystem.join(self.layout_tests_dir(), 'platform', platform)

    def _driver_class(self):
        """Returns the port's driver implementation."""
        return driver.Driver

    def _output_contains_sanitizer_messages(self, output):
        if not output:
            return None
        if 'AddressSanitizer' in output:
            return 'AddressSanitizer'
        if 'MemorySanitizer' in output:
            return 'MemorySanitizer'
        return None

    def _get_crash_log(self, name, pid, stdout, stderr, newer_than):
        if self._output_contains_sanitizer_messages(stderr):
            # Running the symbolizer script can take a lot of memory, so we need to
            # serialize access to it across all the concurrently running drivers.

            # FIXME: investigate using LLVM_SYMBOLIZER_PATH here to reduce the overhead.
            sanitizer_filter_path = self.path_from_chromium_base('tools', 'valgrind', 'asan', 'asan_symbolize.py')
            sanitizer_strip_path_prefix = 'Release/../../'
            if self._filesystem.exists(sanitizer_filter_path):
                stderr = self._executive.run_command(['flock', sys.executable, sanitizer_filter_path, sanitizer_strip_path_prefix], input=stderr, decode_output=False)

        name_str = name or '<unknown process name>'
        pid_str = str(pid or '<unknown>')
        stdout_lines = (stdout or '<empty>').decode('utf8', 'replace').splitlines()
        stderr_lines = (stderr or '<empty>').decode('utf8', 'replace').splitlines()
        return (stderr, 'crash log for %s (pid %s):\n%s\n%s\n' % (name_str, pid_str,
            '\n'.join(('STDOUT: ' + l) for l in stdout_lines),
            '\n'.join(('STDERR: ' + l) for l in stderr_lines)))

    def look_for_new_crash_logs(self, crashed_processes, start_time):
        pass

    def look_for_new_samples(self, unresponsive_processes, start_time):
        pass

    def sample_process(self, name, pid):
        pass

    def physical_test_suites(self):
        return [
            # For example, to turn on force-compositing-mode in the svg/ directory:
            # PhysicalTestSuite('svg',
            #                   ['--force-compositing-mode']),
            ]

    def virtual_test_suites(self):
        return [
            VirtualTestSuite('gpu',
                             'fast/canvas',
                             ['--enable-accelerated-2d-canvas']),
            VirtualTestSuite('gpu',
                             'canvas/philip',
                             ['--enable-accelerated-2d-canvas']),
            VirtualTestSuite('threaded',
                             'compositing/visibility',
                             ['--enable-threaded-compositing']),
            VirtualTestSuite('threaded',
                             'compositing/webgl',
                             ['--enable-threaded-compositing']),
            VirtualTestSuite('deferred',
                             'fast/images',
                             ['--enable-deferred-image-decoding',
                              '--enable-per-tile-painting']),
            VirtualTestSuite('deferred',
                             'inspector/timeline',
                             ['--enable-deferred-image-decoding',
                              '--enable-per-tile-painting']),
            VirtualTestSuite('deferred',
                             'inspector/tracing',
                             ['--enable-deferred-image-decoding',
                              '--enable-per-tile-painting']),
            VirtualTestSuite('gpu/compositedscrolling/overflow',
                             'compositing/overflow',
                             ['--enable-prefer-compositing-to-lcd-text'],
                             use_legacy_naming=True),
            VirtualTestSuite('gpu/compositedscrolling/scrollbars',
                             'scrollbars',
                             ['--enable-prefer-compositing-to-lcd-text'],
                             use_legacy_naming=True),
            VirtualTestSuite('threaded',
                             'animations',
                             ['--enable-threaded-compositing']),
            VirtualTestSuite('threaded',
                             'transitions',
                             ['--enable-threaded-compositing']),
            VirtualTestSuite('stable',
                             'webexposed',
                             ['--stable-release-mode']),
            VirtualTestSuite('stable',
                             'animations-unprefixed',
                             ['--stable-release-mode']),
            VirtualTestSuite('stable',
                             'media/stable',
                             ['--stable-release-mode']),
            VirtualTestSuite('android',
                             'fullscreen',
                             ['--enable-threaded-compositing',
                              '--enable-fixed-position-compositing', '--enable-prefer-compositing-to-lcd-text',
                              '--enable-composited-scrolling-for-frames', '--enable-gesture-tap-highlight', '--enable-pinch',
                              '--enable-overlay-fullscreen-video', '--enable-overlay-scrollbars', '--enable-overscroll-notifications',
                              '--enable-fixed-layout', '--enable-viewport', '--disable-canvas-aa',
                              '--disable-composited-antialiasing']),
            VirtualTestSuite('implsidepainting',
                             'inspector/timeline',
                             ['--enable-threaded-compositing', '--enable-impl-side-painting']),
            VirtualTestSuite('implsidepainting',
                             'inspector/tracing',
                             ['--enable-threaded-compositing', '--enable-impl-side-painting']),
            VirtualTestSuite('stable',
                             'fast/css3-text/css3-text-decoration/stable',
                             ['--stable-release-mode']),
            VirtualTestSuite('stable',
                             'web-animations-api',
                             ['--stable-release-mode']),
            VirtualTestSuite('linux-subpixel',
                             'platform/linux/fast/text/subpixel',
                             ['--enable-webkit-text-subpixel-positioning']),
            VirtualTestSuite('antialiasedtext',
                             'fast/text',
                             ['--enable-direct-write',
                              '--enable-font-antialiasing']),
            VirtualTestSuite('threaded',
                             'printing',
                             ['--enable-threaded-compositing']),
            VirtualTestSuite('regionbasedmulticol',
                             'fast/multicol',
                             ['--enable-region-based-columns']),
            VirtualTestSuite('regionbasedmulticol',
                             'fast/pagination',
                             ['--enable-region-based-columns']),
        ]

    @memoized
    def populated_virtual_test_suites(self):
        suites = self.virtual_test_suites()

        # Sanity-check the suites to make sure they don't point to other suites.
        suite_dirs = [suite.name for suite in suites]
        for suite in suites:
            assert suite.base not in suite_dirs

        for suite in suites:
            base_tests = self._real_tests([suite.base])
            suite.tests = {}
            for test in base_tests:
                suite.tests[test.replace(suite.base, suite.name, 1)] = test
        return suites

    def _virtual_tests(self, paths, suites):
        virtual_tests = list()
        for suite in suites:
            if paths:
                for test in suite.tests:
                    if any(test.startswith(p) for p in paths):
                        virtual_tests.append(test)
            else:
                virtual_tests.extend(suite.tests.keys())
        return virtual_tests

    def is_virtual_test(self, test_name):
        return bool(self.lookup_virtual_suite(test_name))

    def lookup_virtual_suite(self, test_name):
        for suite in self.populated_virtual_test_suites():
            if test_name.startswith(suite.name):
                return suite
        return None

    def lookup_virtual_test_base(self, test_name):
        suite = self.lookup_virtual_suite(test_name)
        if not suite:
            return None
        return test_name.replace(suite.name, suite.base, 1)

    def lookup_virtual_test_args(self, test_name):
        for suite in self.populated_virtual_test_suites():
            if test_name.startswith(suite.name):
                return suite.args
        return []

    def lookup_physical_test_args(self, test_name):
        for suite in self.physical_test_suites():
            if test_name.startswith(suite.name):
                return suite.args
        return []

    def should_run_as_pixel_test(self, test_input):
        if not self._options.pixel_tests:
            return False
        if self._options.pixel_test_directories:
            return any(test_input.test_name.startswith(directory) for directory in self._options.pixel_test_directories)
        return True

    def _modules_to_search_for_symbols(self):
        path = self._path_to_webcore_library()
        if path:
            return [path]
        return []

    def _symbols_string(self):
        symbols = ''
        for path_to_module in self._modules_to_search_for_symbols():
            try:
                symbols += self._executive.run_command(['nm', path_to_module], error_handler=self._executive.ignore_error)
            except OSError, e:
                _log.warn("Failed to run nm: %s.  Can't determine supported features correctly." % e)
        return symbols

    # Ports which use compile-time feature detection should define this method and return
    # a dictionary mapping from symbol substrings to possibly disabled test directories.
    # When the symbol substrings are not matched, the directories will be skipped.
    # If ports don't ever enable certain features, then those directories can just be
    # in the Skipped list instead of compile-time-checked here.
    def _missing_symbol_to_skipped_tests(self):
        if self.PORT_HAS_AUDIO_CODECS_BUILT_IN:
            return {}
        else:
            return {
                "ff_mp3_decoder": ["webaudio/codec-tests/mp3"],
                "ff_aac_decoder": ["webaudio/codec-tests/aac"],
            }

    def _has_test_in_directories(self, directory_lists, test_list):
        if not test_list:
            return False

        directories = itertools.chain.from_iterable(directory_lists)
        for directory, test in itertools.product(directories, test_list):
            if test.startswith(directory):
                return True
        return False

    def _skipped_tests_for_unsupported_features(self, test_list):
        # Only check the symbols of there are tests in the test_list that might get skipped.
        # This is a performance optimization to avoid the calling nm.
        # Runtime feature detection not supported, fallback to static detection:
        # Disable any tests for symbols missing from the executable or libraries.
        if self._has_test_in_directories(self._missing_symbol_to_skipped_tests().values(), test_list):
            symbols_string = self._symbols_string()
            if symbols_string is not None:
                return reduce(operator.add, [directories for symbol_substring, directories in self._missing_symbol_to_skipped_tests().items() if symbol_substring not in symbols_string], [])
        return []

    def _convert_path(self, path):
        """Handles filename conversion for subprocess command line args."""
        # See note above in diff_image() for why we need this.
        if sys.platform == 'cygwin':
            return cygpath(path)
        return path

    def gen_dir(self):
        return self._build_path("gen")

    def _build_path(self, *comps):
        return self._build_path_with_configuration(None, *comps)

    def _build_path_with_configuration(self, configuration, *comps):
        # Note that we don't do the option caching that the
        # base class does, because finding the right directory is relatively
        # fast.
        configuration = configuration or self.get_option('configuration')
        return self._static_build_path(self._filesystem, self.get_option('build_directory'),
            self.path_from_chromium_base(), configuration, comps)

    def _check_driver_build_up_to_date(self, configuration):
        if configuration in ('Debug', 'Release'):
            try:
                debug_path = self._path_to_driver('Debug')
                release_path = self._path_to_driver('Release')

                debug_mtime = self._filesystem.mtime(debug_path)
                release_mtime = self._filesystem.mtime(release_path)

                if (debug_mtime > release_mtime and configuration == 'Release' or
                    release_mtime > debug_mtime and configuration == 'Debug'):
                    most_recent_binary = 'Release' if configuration == 'Debug' else 'Debug'
                    _log.warning('You are running the %s binary. However the %s binary appears to be more recent. '
                                 'Please pass --%s.', configuration, most_recent_binary, most_recent_binary.lower())
                    _log.warning('')
            # This will fail if we don't have both a debug and release binary.
            # That's fine because, in this case, we must already be running the
            # most up-to-date one.
            except OSError:
                pass
        return True

    def _chromium_baseline_path(self, platform):
        if platform is None:
            platform = self.name()
        return self.path_from_webkit_base('tests', 'platform', platform)

class VirtualTestSuite(object):
    def __init__(self, name, base, args, use_legacy_naming=False, tests=None):
        if use_legacy_naming:
            self.name = 'virtual/' + name
        else:
            if name.find('/') != -1:
                _log.error("Virtual test suites names cannot contain /'s: %s" % name)
                return
            self.name = 'virtual/' + name + '/' + base
        self.base = base
        self.args = args
        self.tests = tests or set()

    def __repr__(self):
        return "VirtualTestSuite('%s', '%s', %s)" % (self.name, self.base, self.args)


class PhysicalTestSuite(object):
    def __init__(self, base, args):
        self.name = base
        self.base = base
        self.args = args
        self.tests = set()

    def __repr__(self):
        return "PhysicalTestSuite('%s', '%s', %s)" % (self.name, self.base, self.args)
