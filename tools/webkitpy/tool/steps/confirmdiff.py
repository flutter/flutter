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

import urllib

from webkitpy.tool.steps.abstractstep import AbstractStep
from webkitpy.tool.steps.options import Options
from webkitpy.common.prettypatch import PrettyPatch
from webkitpy.common.system import logutils
from webkitpy.common.system.executive import ScriptError


_log = logutils.get_logger(__file__)


class ConfirmDiff(AbstractStep):
    @classmethod
    def options(cls):
        return AbstractStep.options() + [
            Options.confirm,
        ]

    def _show_pretty_diff(self):
        if not self._tool.user.can_open_url():
            return None

        try:
            pretty_patch = PrettyPatch(self._tool.executive)
            pretty_diff_file = pretty_patch.pretty_diff_file(self.diff())
            url = "file://%s" % urllib.quote(pretty_diff_file.name)
            self._tool.user.open_url(url)
            # We return the pretty_diff_file here because we need to keep the
            # file alive until the user has had a chance to confirm the diff.
            return pretty_diff_file
        except ScriptError, e:
            _log.warning("PrettyPatch failed.  :(")
        except OSError, e:
            _log.warning("PrettyPatch unavailable.")

    def diff(self):
        changed_files = self._tool.scm().changed_files(self._options.git_commit)
        return self._tool.scm().create_patch(self._options.git_commit,
            changed_files=changed_files)

    def run(self, state):
        if not self._options.confirm:
            return
        pretty_diff_file = self._show_pretty_diff()
        diff_correct = self._tool.user.confirm("Was that diff correct?")
        if pretty_diff_file:
            pretty_diff_file.close()
        if not diff_correct:
            self._exit(1)
