# Copyright (c) 2010 Google Inc. All rights reserved.
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
#     * Neither the name of Google Inc. nor the names of its
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

import fnmatch
import os
import os.path
import BaseHTTPServer

from webkitpy.common.host import Host  # FIXME: This should not be needed!
from webkitpy.layout_tests.port.base import Port
from webkitpy.tool.servers.reflectionhandler import ReflectionHandler


STATE_NEEDS_REBASELINE = 'needs_rebaseline'
STATE_REBASELINE_FAILED = 'rebaseline_failed'
STATE_REBASELINE_SUCCEEDED = 'rebaseline_succeeded'


def _get_actual_result_files(test_file, test_config):
    test_name, _ = os.path.splitext(test_file)
    test_directory = os.path.dirname(test_file)

    test_results_directory = test_config.filesystem.join(
        test_config.results_directory, test_directory)
    actual_pattern = os.path.basename(test_name) + '-actual.*'
    actual_files = []
    for filename in test_config.filesystem.listdir(test_results_directory):
        if fnmatch.fnmatch(filename, actual_pattern):
            actual_files.append(filename)
    actual_files.sort()
    return tuple(actual_files)


def _rebaseline_test(test_file, baseline_target, baseline_move_to, test_config, log):
    test_name, _ = os.path.splitext(test_file)
    test_directory = os.path.dirname(test_name)

    log('Rebaselining %s...' % test_name)

    actual_result_files = _get_actual_result_files(test_file, test_config)
    filesystem = test_config.filesystem
    scm = test_config.scm
    layout_tests_directory = test_config.layout_tests_directory
    results_directory = test_config.results_directory
    target_expectations_directory = filesystem.join(
        layout_tests_directory, 'platform', baseline_target, test_directory)
    test_results_directory = test_config.filesystem.join(
        test_config.results_directory, test_directory)

    # If requested, move current baselines out
    current_baselines = get_test_baselines(test_file, test_config)
    if baseline_target in current_baselines and baseline_move_to != 'none':
        log('  Moving current %s baselines to %s' %
            (baseline_target, baseline_move_to))

        # See which ones we need to move (only those that are about to be
        # updated), and make sure we're not clobbering any files in the
        # destination.
        current_extensions = set(current_baselines[baseline_target].keys())
        actual_result_extensions = [
            os.path.splitext(f)[1] for f in actual_result_files]
        extensions_to_move = current_extensions.intersection(
            actual_result_extensions)

        if extensions_to_move.intersection(
            current_baselines.get(baseline_move_to, {}).keys()):
            log('    Already had baselines in %s, could not move existing '
                '%s ones' % (baseline_move_to, baseline_target))
            return False

        # Do the actual move.
        if extensions_to_move:
            if not _move_test_baselines(
                test_file,
                list(extensions_to_move),
                baseline_target,
                baseline_move_to,
                test_config,
                log):
                return False
        else:
            log('    No current baselines to move')

    log('  Updating baselines for %s' % baseline_target)
    filesystem.maybe_make_directory(target_expectations_directory)
    for source_file in actual_result_files:
        source_path = filesystem.join(test_results_directory, source_file)
        destination_file = source_file.replace('-actual', '-expected')
        destination_path = filesystem.join(
            target_expectations_directory, destination_file)
        filesystem.copyfile(source_path, destination_path)
        exit_code = scm.add(destination_path, return_exit_code=True)
        if exit_code:
            log('    Could not update %s in SCM, exit code %d' %
                (destination_file, exit_code))
            return False
        else:
            log('    Updated %s' % destination_file)

    return True


def _move_test_baselines(test_file, extensions_to_move, source_platform, destination_platform, test_config, log):
    test_file_name = os.path.splitext(os.path.basename(test_file))[0]
    test_directory = os.path.dirname(test_file)
    filesystem = test_config.filesystem

    # Want predictable output order for unit tests.
    extensions_to_move.sort()

    source_directory = os.path.join(
        test_config.layout_tests_directory,
        'platform',
        source_platform,
        test_directory)
    destination_directory = os.path.join(
        test_config.layout_tests_directory,
        'platform',
        destination_platform,
        test_directory)
    filesystem.maybe_make_directory(destination_directory)

    for extension in extensions_to_move:
        file_name = test_file_name + '-expected' + extension
        source_path = filesystem.join(source_directory, file_name)
        destination_path = filesystem.join(destination_directory, file_name)
        filesystem.copyfile(source_path, destination_path)
        exit_code = test_config.scm.add(destination_path, return_exit_code=True)
        if exit_code:
            log('    Could not update %s in SCM, exit code %d' %
                (file_name, exit_code))
            return False
        else:
            log('    Moved %s' % file_name)

    return True


def get_test_baselines(test_file, test_config):
    # FIXME: This seems like a hack. This only seems used to access the Port.expected_baselines logic.
    class AllPlatformsPort(Port):
        def __init__(self, host):
            super(AllPlatformsPort, self).__init__(host, 'mac')
            self._platforms_by_directory = dict([(self._webkit_baseline_path(p), p) for p in test_config.platforms])

        def baseline_search_path(self):
            return self._platforms_by_directory.keys()

        def platform_from_directory(self, directory):
            return self._platforms_by_directory[directory]

    test_path = test_config.filesystem.join(test_config.layout_tests_directory, test_file)

    # FIXME: This should get the Host from the test_config to be mockable!
    host = Host()
    host.initialize_scm()
    host.filesystem = test_config.filesystem
    all_platforms_port = AllPlatformsPort(host)

    all_test_baselines = {}
    for baseline_extension in ('.txt', '.checksum', '.png'):
        test_baselines = test_config.test_port.expected_baselines(test_file, baseline_extension)
        baselines = all_platforms_port.expected_baselines(test_file, baseline_extension, all_baselines=True)
        for platform_directory, expected_filename in baselines:
            if not platform_directory:
                continue
            if platform_directory == test_config.layout_tests_directory:
                platform = 'base'
            else:
                platform = all_platforms_port.platform_from_directory(platform_directory)
            platform_baselines = all_test_baselines.setdefault(platform, {})
            was_used_for_test = (platform_directory, expected_filename) in test_baselines
            platform_baselines[baseline_extension] = was_used_for_test

    return all_test_baselines


class RebaselineHTTPServer(BaseHTTPServer.HTTPServer):
    def __init__(self, httpd_port, config):
        server_name = ""
        BaseHTTPServer.HTTPServer.__init__(self, (server_name, httpd_port), RebaselineHTTPRequestHandler)
        self.test_config = config['test_config']
        self.results_json = config['results_json']
        self.platforms_json = config['platforms_json']


class RebaselineHTTPRequestHandler(ReflectionHandler):
    STATIC_FILE_NAMES = frozenset([
        "index.html",
        "loupe.js",
        "main.js",
        "main.css",
        "queue.js",
        "util.js",
    ])

    STATIC_FILE_DIRECTORY = os.path.join(os.path.dirname(__file__), "data", "rebaselineserver")

    def results_json(self):
        self._serve_json(self.server.results_json)

    def test_config(self):
        self._serve_json(self.server.test_config)

    def platforms_json(self):
        self._serve_json(self.server.platforms_json)

    def rebaseline(self):
        test = self.query['test'][0]
        baseline_target = self.query['baseline-target'][0]
        baseline_move_to = self.query['baseline-move-to'][0]
        test_json = self.server.results_json['tests'][test]

        if test_json['state'] != STATE_NEEDS_REBASELINE:
            self.send_error(400, "Test %s is in unexpected state: %s" % (test, test_json["state"]))
            return

        log = []
        success = _rebaseline_test(
            test,
            baseline_target,
            baseline_move_to,
            self.server.test_config,
            log=lambda l: log.append(l))

        if success:
            test_json['state'] = STATE_REBASELINE_SUCCEEDED
            self.send_response(200)
        else:
            test_json['state'] = STATE_REBASELINE_FAILED
            self.send_response(500)

        self.send_header('Content-type', 'text/plain')
        self.end_headers()
        self.wfile.write('\n'.join(log))

    def test_result(self):
        test_name, _ = os.path.splitext(self.query['test'][0])
        mode = self.query['mode'][0]
        if mode == 'expected-image':
            file_name = test_name + '-expected.png'
        elif mode == 'actual-image':
            file_name = test_name + '-actual.png'
        if mode == 'expected-checksum':
            file_name = test_name + '-expected.checksum'
        elif mode == 'actual-checksum':
            file_name = test_name + '-actual.checksum'
        elif mode == 'diff-image':
            file_name = test_name + '-diff.png'
        if mode == 'expected-text':
            file_name = test_name + '-expected.txt'
        elif mode == 'actual-text':
            file_name = test_name + '-actual.txt'
        elif mode == 'diff-text':
            file_name = test_name + '-diff.txt'
        elif mode == 'diff-text-pretty':
            file_name = test_name + '-pretty-diff.html'

        file_path = os.path.join(self.server.test_config.results_directory, file_name)

        # Let results be cached for 60 seconds, so that they can be pre-fetched
        # by the UI
        self._serve_file(file_path, cacheable_seconds=60)
