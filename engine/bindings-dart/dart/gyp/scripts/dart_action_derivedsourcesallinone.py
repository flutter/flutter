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

# dart_action_derivedsourceslist.py generates a single or several cpp files
# that include all Dart bindings cpp files generated from idls.
#
# usage: dart_action_derivedsourceslist.py IDL_FILES_LIST -- OUTPUT_FILE1 OUTPUT_FILE2 ...
#
# Note that IDL_FILES_LIST is a text file containing the IDL file paths.

import os.path
import re
import sys

v8scriptPath = os.path.join(sys.path[0], '../../../../WebCore.gyp/scripts')
sys.path.append(v8scriptPath)

# FIXME: there are couple of very ugly hacks like duplication of main code and
# regexp to rewrite V8 prefix to Dart. It all can be easily solved with minimal
# modifications to action_derivedsourcesallinone.py.
import action_derivedsourcesallinone as base


def main(args):
    assert(len(args) > 3)
    inOutBreakIndex = args.index('--')
    inputFileName = args[1]
    outputFileNames = args[inOutBreakIndex + 1:]

    inputFile = open(inputFileName, 'r')
    idlFileNames = inputFile.read().split('\n')
    inputFile.close()

    filesMetaData = base.extractMetaData(idlFileNames)
    for fileName in outputFileNames:
        partition = outputFileNames.index(fileName)
        fileContents = base.generateContent(filesMetaData, partition, len(outputFileNames))
        # FIXME: ugly hack---change V8 prefix to Dart.
        fileContents = re.sub('\n#include "bindings/V8', '\n#include "bindings/Dart', fileContents)
        base.writeContent(fileContents, fileName)

    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv))
