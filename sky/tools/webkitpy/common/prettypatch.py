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

import os
import tempfile


class PrettyPatch(object):
    def __init__(self, executive):
        self._executive = executive

    def pretty_diff_file(self, diff):
        # Diffs can contain multiple text files of different encodings
        # so we always deal with them as byte arrays, not unicode strings.
        assert(isinstance(diff, str))
        pretty_diff = self.pretty_diff(diff)
        diff_file = tempfile.NamedTemporaryFile(suffix=".html")
        diff_file.write(pretty_diff)
        diff_file.flush()
        return diff_file

    def pretty_diff(self, diff):
        # pretify.rb will hang forever if given no input.
        # Avoid the hang by returning an empty string.
        if not diff:
            return ""

        pretty_patch_path = os.path.join(os.path.dirname(__file__), '..', '..',
                                         'third_party', 'PrettyPatch')
        prettify_path = os.path.join(pretty_patch_path, "prettify.rb")
        args = [
            "ruby",
            "-I",
            pretty_patch_path,
            prettify_path,
        ]
        # PrettyPatch does not modify the encoding of the diff output
        # so we can't expect it to be utf-8.
        return self._executive.run_command(args, input=diff, decode_output=False)
