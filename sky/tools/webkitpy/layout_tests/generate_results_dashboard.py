# Copyright (C) 2014 Google Inc. All rights reserved.
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

import json


class ProcessJsonData(object):

    def __init__(self, current_result_json_dict, old_failing_results_list, old_full_results_list):
        self._current_result_json_dict = current_result_json_dict
        self._old_failing_results_list = old_failing_results_list
        self._old_full_results_list = old_full_results_list
        self._final_result = []

    def _get_test_result(self, test_result_data):
        actual = test_result_data['actual']
        expected = test_result_data['expected']
        if actual == 'SKIP':
            return actual
        if actual == expected:
            return 'HASSTDERR' if test_result_data.get('has_stderr') == 'true' else 'PASS'
        else:
            return actual

    def _recurse_json_object(self, json_object, key_list):
        for key in key_list:
            try:
                json_object = json_object[key]
            except KeyError:
                return 'NOTFOUND'
        return self._get_test_result(json_object)

    def _process_previous_json_results(self, key_list):
        row = []
        length = len(self._old_failing_results_list)
        for index in range(0, length):
            result = self._recurse_json_object(self._old_failing_results_list[index]["tests"], key_list)
            if result == 'NOTFOUND':
                result = self._recurse_json_object(self._old_full_results_list[index]["tests"], key_list)
            row.append(result)
        return row

    def _add_archived_result(self, json_object, result):
        json_object['archived_results'] = result

    def _process_json_object(self, json_object, keyList):
        for key, subdict in json_object.iteritems():
            if type(subdict) == dict:
                self._process_json_object(subdict, keyList + [key])
            else:
                row = [self._get_test_result(json_object)]
                row += self._process_previous_json_results(keyList)
                json_object.clear()
                self._add_archived_result(json_object, row)
                return

    def generate_archived_result(self):
        for key in self._current_result_json_dict["tests"]:
            self._process_json_object(self._current_result_json_dict["tests"][key], [key])
        return self._current_result_json_dict


class GenerateDashBoard(object):

    def __init__(self, port):
        self._port = port
        self._filesystem = port.host.filesystem
        self._results_directory = self._port.results_directory()
        self._results_directory_path = self._filesystem.dirname(self._results_directory)
        self._current_result_json_dict = {}
        self._old_failing_results_list = []
        self._old_full_results_list = []
        self._final_result = []

    def _add_individual_result_links(self, results_directories):
        archived_results_file_list = [(file + '/results.html') for file in results_directories]
        archived_results_file_list.insert(0, 'results.html')
        self._current_result_json_dict['result_links'] = archived_results_file_list

    def _copy_dashboard_html(self):
        dashboard_file = self._filesystem.join(self._results_directory, 'dashboard.html')
        dashboard_html_file_path = self._filesystem.join(self._port.layout_tests_dir(), 'fast/harness/archived-results-dashboard.html')
        if not self._filesystem.exists(dashboard_file):
            if self._filesystem.exists(dashboard_html_file_path):
                self._filesystem.copyfile(dashboard_html_file_path, dashboard_file)

    def _initialize(self):
        file_list = self._filesystem.listdir(self._results_directory_path)
        results_directories = []
        for dir in file_list:
            if self._filesystem.isdir(self._filesystem.join(self._results_directory_path, dir)):
                results_directories.append(self._filesystem.join(self._results_directory_path, dir))
        results_directories.sort(reverse=True, key=lambda x: self._filesystem.mtime(x))
        with open(self._filesystem.join(results_directories[0], 'failing_results.json'), "r") as file:
            input_json_string = file.readline()
        input_json_string = input_json_string[12:-2]   # Remove preceeding string ADD_RESULTS( and ); at the end
        self._current_result_json_dict['tests'] = json.loads(input_json_string)['tests']
        results_directories = results_directories[1:]

        # To add hyperlink to individual results.html
        self._add_individual_result_links(results_directories)

        # Load the remaining stale layout test results Json's to create the dashboard
        for json_file in results_directories:
            with open(self._filesystem.join(json_file, 'failing_results.json'), "r") as file:
                json_string = file.readline()
            json_string = json_string[12:-2]   # Remove preceeding string ADD_RESULTS( and ); at the end
            self._old_failing_results_list.append(json.loads(json_string))

            with open(self._filesystem.join(json_file, 'full_results.json'), "r") as full_file:
                json_string_full_result = full_file.readline()
            self._old_full_results_list.append(json.loads(json_string_full_result))
        self._copy_dashboard_html()

    def generate(self):
        self._initialize()
        process_json_data = ProcessJsonData(self._current_result_json_dict, self._old_failing_results_list, self._old_full_results_list)
        self._final_result = process_json_data.generate_archived_result()
        final_json = json.dumps(self._final_result)
        final_json = 'ADD_RESULTS(' + final_json + ');'
        with open(self._filesystem.join(self._results_directory, 'archived_results.json'), "w") as file:
            file.write(final_json)
