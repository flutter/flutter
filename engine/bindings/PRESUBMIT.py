# Copyright (C) 2013 Google Inc. All rights reserved.
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

"""Blink bindings presubmit script

See http://dev.chromium.org/developers/how-tos/depottools/presubmit-scripts
for more details about the presubmit API built into gcl.
"""

# Changes to v8/ do not change generated code or tests, so exclude from
# _RunBindingsTests
BLACK_LIST = (r'.*\bv8[\\\/].*',)

def _RunBindingsTests(input_api, output_api):
    # Skip if nothing to do
    source_filter = lambda x: input_api.FilterSourceFile(
                x, black_list=input_api.DEFAULT_BLACK_LIST + BLACK_LIST)
    if not input_api.AffectedFiles(file_filter=source_filter):
        return []

    if input_api.is_committing:
        message_type = output_api.PresubmitError
    else:
        message_type = output_api.PresubmitPromptWarning

    pardir = input_api.os_path.pardir
    run_bindings_tests_path = input_api.os_path.join(input_api.PresubmitLocalPath(), pardir, pardir, 'Tools', 'Scripts', 'run-bindings-tests')
    cmd_name = 'run-bindings-tests'
    if input_api.platform == 'win32':
        # Windows needs some help.
        cmd = [input_api.python_executable, run_bindings_tests_path]
    else:
        cmd = [run_bindings_tests_path]
    test_cmd = input_api.Command(
      name=cmd_name,
      cmd=cmd,
      kwargs={},
      message=message_type)
    if input_api.verbose:
        print('Running ' + cmd_name)
    return input_api.RunTests([test_cmd])


def CheckChangeOnUpload(input_api, output_api):
    return _RunBindingsTests(input_api, output_api)


def CheckChangeOnCommit(input_api, output_api):
    return _RunBindingsTests(input_api, output_api)
