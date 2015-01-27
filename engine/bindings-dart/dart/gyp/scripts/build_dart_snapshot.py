#!/usr/bin/python
#
# Copyright (C) 2011 Google Inc. All rights reserved.
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
#
# Copyright (c) 2011 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# build_dart_snapshot.py generates two C++ files: DartSnapshot.cpp
# with a constant which is a snapshot of major DOM libs an
# DartResolver.cpp which is a resolver for dart:html library.

import os.path
import subprocess
import sys


def main(args):
    assert(len(args) >= 4)
    dartPath = args[1]
    dartSnapshotTemplateFile = args[2]
    outputFilePath = args[3]
    genSnapshotBinPath = args[4]
    snapshottedLibPaths = args[5:]

    def path(*components):
        return os.path.abspath(os.path.join(*components))

    def dartName(path):
        # Translates <dirs>/foo_dartium.dart into foo.
        return (os.path.splitext(os.path.split(path)[1])[0]
                .replace('_dartium', ''))

    snapshottedLibs = [(dartName(p), path(p))
                       for p in snapshottedLibPaths]

    # Generate a Dart script to build the snapshot from.
    snapshotScriptName = os.path.join(outputFilePath, 'snapshotScript.dart')
    with file(snapshotScriptName, 'w') as snapshotScript:
        snapshotScript.write('library snapshot;\n')
        for name, _ in snapshottedLibs:
            # Skip internal libraries - they should be indirectly imported via the public ones.
            if not name.startswith('_'):
                snapshotScript.write('import \'dart:%(name)s\' as %(name)s;\n' % {'name': name})

    binarySnapshotFile = path(outputFilePath, 'DartSnapshot.bin')

    # Build a command to generate the snapshot bin file.
    command = [
        'python',
        path(dartPath, 'runtime', 'tools', 'create_snapshot_bin.py'),
        '--executable=%s' % path(genSnapshotBinPath),
        '--output_bin=%s' % binarySnapshotFile,
        '--script=%s' % snapshotScriptName,
    ]
    command.extend(['--url_mapping=dart:%s,%s' % lib for lib in snapshottedLibs])

    pipe = subprocess.Popen(command,
                            stdout=subprocess.PIPE,
                            stderr=subprocess.PIPE)
    out, error = pipe.communicate()
    if (pipe.returncode != 0):
        raise Exception('Snapshot bin generation failed: %s/%s' % (out, error))

    # Build a command to generate the snapshot file.
    command = [
        'python',
        path(dartPath, 'runtime', 'tools', 'create_snapshot_file.py'),
        '--input_cc=%s' % dartSnapshotTemplateFile,
        '--input_bin=%s' % binarySnapshotFile,
        '--output=%s' % path(outputFilePath, 'DartSnapshot.bytes'),
    ]

    pipe = subprocess.Popen(command,
                            stdout=subprocess.PIPE,
                            stderr=subprocess.PIPE)
    out, error = pipe.communicate()
    if (pipe.returncode != 0):
        raise Exception('Snapshot file generation failed: %s/%s' % (out, error))

    snapshotSizeInBytes = os.path.getsize(binarySnapshotFile)
    productDir = os.path.dirname(genSnapshotBinPath)
    snapshotSizeOutputPath = os.path.join(productDir, 'snapshot-size.txt')
    with file(snapshotSizeOutputPath, 'w') as snapshotSizeFile:
        snapshotSizeFile.write('%d\n' % snapshotSizeInBytes)

    return 0

if __name__ == '__main__':
    sys.exit(main(sys.argv))
