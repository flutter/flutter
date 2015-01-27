#!/usr/bin/python
#
# Copyright (C) 2012 Google Inc. All rights reserved.
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

import glob
import os.path
import sys
import tempfile

def main(args):
    assert(len(args) == 6)
    idlListFileName = args[1]
    dartiumScriptDir = args[2]
    dartScriptDir = args[3]
    outputFilePath = args[4]
    featureDefines = args[5]

    # Clear out any stale dart/lib/html/scripts/.pyc files that are lurking.
    for f in glob.glob(os.path.join(dartScriptDir, '*.pyc')):
      os.remove(f)

    baseDir = os.path.dirname(dartiumScriptDir)
    idlListFile = open(idlListFileName, 'r')
    idlFiles = [os.path.join(baseDir, fileName.strip()) for fileName in idlListFile]
    idlListFile.close()

    def analyse(featureDef):
      featureDef = featureDef.strip('"')
      if '=' not in featureDef: return None
      feature, status = featureDef.split('=')
      if status == '1':
        return feature
      return None

    featureDefines = filter(None, map(analyse, featureDefines.split()))

    sys.path.insert(0, dartScriptDir)
    import fremontcutbuilder
    import dartdomgenerator

    database = fremontcutbuilder.build_database(idlFiles, tempfile.mkdtemp(), feature_defines=featureDefines)
    database.Load()
    dartdomgenerator.GenerateFromDatabase(database, None, outputFilePath)
    database.Delete()

    return 0

if __name__ == '__main__':
    sys.exit(main(sys.argv))
