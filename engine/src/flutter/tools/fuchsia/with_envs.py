#!/usr/bin/env python3
# Copyright (c) 2024, the Flutter project authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be found
# in the LICENSE file.

import os
import platform
import subprocess
import sys

sys.path.insert(
    0,
    os.path.abspath(
        os.path.join(
            os.path.dirname(__file__), '../../../fuchsia/test_scripts/test/'
        )
    )
)

from common import catch_sigterm, wait_for_sigterm


def Main():
  """
    Executes the test-scripts with required environment variables. It acts like
    /usr/bin/env, but provides some extra functionality to dynamically set up
    the environment variables.
    """
  # Ensures the signals can be correctly forwarded to the subprocesses.
  catch_sigterm()

  # Flutter uses a different repo structure and fuchsia sdk is not in the
  # third_party/, so setting the DIR_SRC_ROOT does not make sense.
  os.environ['FUCHSIA_IMAGES_ROOT'] = os.path.abspath(
      os.path.join(os.path.dirname(__file__), '../../../fuchsia/images/')
  )

  assert platform.system() == 'Linux', 'Unsupported OS ' + platform.system()
  os.environ['FUCHSIA_SDK_ROOT'] = os.path.abspath(
      os.path.join(os.path.dirname(__file__), '../../../fuchsia/sdk/linux')
  )

  with subprocess.Popen(sys.argv[1:]) as proc:
    try:
      proc.wait()
    except:
      # Use terminate / SIGTERM to allow the subprocess exiting cleanly.
      proc.terminate()
    return proc.returncode


if __name__ == '__main__':
  sys.exit(Main())
