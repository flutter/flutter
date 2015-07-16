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

# A home for file logic which should sit above FileSystem, but
# below more complicated objects.

import logging
import zipfile

from webkitpy.common.system.executive import ScriptError


_log = logging.getLogger(__name__)


class Workspace(object):
    def __init__(self, filesystem, executive):
        self._filesystem = filesystem
        self._executive = executive  # FIXME: Remove if create_zip is moved to python.

    def find_unused_filename(self, directory, name, extension, search_limit=100):
        for count in range(search_limit):
            if count:
                target_name = "%s-%s.%s" % (name, count, extension)
            else:
                target_name = "%s.%s" % (name, extension)
            target_path = self._filesystem.join(directory, target_name)
            if not self._filesystem.exists(target_path):
                return target_path
        # If we can't find an unused name in search_limit tries, just give up.
        return None

    def create_zip(self, zip_path, source_path, zip_class=zipfile.ZipFile):
        # It's possible to create zips with Python:
        # zip_file = ZipFile(zip_path, 'w')
        # for root, dirs, files in os.walk(source_path):
        #     for path in files:
        #         absolute_path = os.path.join(root, path)
        #         zip_file.write(os.path.relpath(path, source_path))
        # However, getting the paths, encoding and compression correct could be non-trivial.
        # So, for now we depend on the environment having "zip" installed (likely fails on Win32)
        try:
            self._executive.run_command(['zip', '-9', '-r', zip_path, '.'], cwd=source_path)
        except ScriptError, e:
            _log.error("Workspace.create_zip failed in %s:\n%s" % (source_path, e.message_with_output()))
            return None

        return zip_class(zip_path)
