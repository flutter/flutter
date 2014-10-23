# Copyright (C) 2009 Google Inc. All rights reserved.
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

import logging
import sys

from webkitpy.tool import steps

from webkitpy.common.system.executive import ScriptError

_log = logging.getLogger(__name__)


class StepSequenceErrorHandler():
    @classmethod
    def handle_script_error(cls, tool, patch, script_error):
        raise NotImplementedError, "subclasses must implement"

    @classmethod
    def handle_checkout_needs_update(cls, tool, state, options, error):
        raise NotImplementedError, "subclasses must implement"


class StepSequence(object):
    def __init__(self, steps):
        self._steps = steps or []

    def options(self):
        collected_options = [
            steps.Options.parent_command,
            steps.Options.quiet,
        ]
        for step in self._steps:
            collected_options = collected_options + step.options()
        # Remove duplicates.
        collected_options = sorted(set(collected_options))
        return collected_options

    def _run(self, tool, options, state):
        for step in self._steps:
            step(tool, options).run(state)

    # Child processes exit with a special code to the parent queue process can detect the error was handled.
    handled_error_code = 2

    @classmethod
    def exit_after_handled_error(cls, error):
        _log.error(error)
        sys.exit(cls.handled_error_code)

    def run_and_handle_errors(self, tool, options, state=None):
        if not state:
            state = {}
        try:
            self._run(tool, options, state)
        except ScriptError, e:
            if not options.quiet:
                _log.error(e.message_with_output())
            if options.parent_command:
                command = tool.command_by_name(options.parent_command)
                command.handle_script_error(tool, state, e)
            self.exit_after_handled_error(e)
