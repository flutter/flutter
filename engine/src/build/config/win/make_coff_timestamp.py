# Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

import os
import platform
import subprocess
import sys

IS_WINDOWS = platform.system() == "Windows"
FLUTTER_DIR = os.path.abspath(os.path.join(__file__, '..', '..', '..', '..'))

def Main():
    p = subprocess.Popen(['git', 'show', '--no-patch', '--format=%ct'],
                         shell=IS_WINDOWS,
                         cwd=FLUTTER_DIR)
    p.communicate()
    return p.wait()


if __name__ == '__main__':
    sys.exit(Main())
