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

"""Starts a local HTTP server which displays layout test failures (given a test
results directory), provides comparisons of expected and actual results (both
images and text) and allows one-click rebaselining of tests."""

from webkitpy.common import system
from webkitpy.common.net.layouttestresults import for_each_test, JSONTestResult
from webkitpy.layout_tests.layout_package import json_results_generator
from webkitpy.tool.commands.abstractlocalservercommand import AbstractLocalServerCommand
from webkitpy.tool.servers.rebaselineserver import get_test_baselines, RebaselineHTTPServer, STATE_NEEDS_REBASELINE


class TestConfig(object):
    def __init__(self, test_port, layout_tests_directory, results_directory, platforms, filesystem, scm):
        self.test_port = test_port
        self.layout_tests_directory = layout_tests_directory
        self.results_directory = results_directory
        self.platforms = platforms
        self.filesystem = filesystem
        self.scm = scm


class RebaselineServer(AbstractLocalServerCommand):
    name = "rebaseline-server"
    help_text = __doc__
    show_in_main_help = True
    argument_names = "/path/to/results/directory"

    server = RebaselineHTTPServer

    def _gather_baselines(self, results_json):
        # Rebaseline server and it's associated JavaScript expected the tests subtree to
        # be key-value pairs instead of hierarchical.
        # FIXME: make the rebaseline server use the hierarchical tree.
        new_tests_subtree = {}

        def gather_baselines_for_test(test_name, result_dict):
            result = JSONTestResult(test_name, result_dict)
            if result.did_pass_or_run_as_expected():
                return
            result_dict['state'] = STATE_NEEDS_REBASELINE
            result_dict['baselines'] = get_test_baselines(test_name, self._test_config)
            new_tests_subtree[test_name] = result_dict

        for_each_test(results_json['tests'], gather_baselines_for_test)
        results_json['tests'] = new_tests_subtree

    def _prepare_config(self, options, args, tool):
        results_directory = args[0]
        filesystem = system.filesystem.FileSystem()
        scm = self._tool.scm()

        print 'Parsing full_results.json...'
        results_json_path = filesystem.join(results_directory, 'full_results.json')
        results_json = json_results_generator.load_json(filesystem, results_json_path)

        port = tool.port_factory.get()
        layout_tests_directory = port.layout_tests_dir()
        platforms = filesystem.listdir(filesystem.join(layout_tests_directory, 'platform'))
        self._test_config = TestConfig(port, layout_tests_directory, results_directory, platforms, filesystem, scm)

        print 'Gathering current baselines...'
        self._gather_baselines(results_json)

        return {
            'test_config': self._test_config,
            "results_json": results_json,
            "platforms_json": {
                'platforms': platforms,
                'defaultPlatform': port.name(),
            },
        }
