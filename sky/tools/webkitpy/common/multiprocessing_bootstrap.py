# Copyright (c) 2011 Google Inc. All rights reserved.
# Copyright (C) 2010 Chris Jerdonek (cjerdonek@webkit.org)
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

"""In order for the multiprocessing module to spawn children correctly on
Windows, we need to be running a Python module that can be imported
(which means a file in sys.path that ends in .py). In addition, we need to
ensure that sys.path / PYTHONPATH is set and propagating correctly.

This module enforces that."""

import os
import subprocess
import sys

from webkitpy.common import version_check   # 'unused import' pylint: disable=W0611


def run(*parts):
    up = os.path.dirname
    script_dir = up(up(up(os.path.abspath(__file__))))
    env = os.environ
    if 'PYTHONPATH' in env:
        if script_dir not in env['PYTHONPATH']:
            env['PYTHONPATH'] = env['PYTHONPATH'] + os.pathsep + script_dir
    else:
        env['PYTHONPATH'] = script_dir
    module_path = os.path.join(script_dir, *parts)
    cmd = [sys.executable, module_path] + sys.argv[1:]

    proc = subprocess.Popen(cmd, env=env)
    try:
        proc.wait()
    except KeyboardInterrupt:
        # We need a second wait in order to make sure the subprocess exits fully.
        # FIXME: It would be nice if we could put a timeout on this.
        proc.wait()
    sys.exit(proc.returncode)
