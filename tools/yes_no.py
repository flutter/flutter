# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import sys


def YesNo(prompt):
  """Prompts with a yes/no question, returns True if yes."""
  print prompt,
  sys.stdout.flush()
  # http://code.activestate.com/recipes/134892/
  if sys.platform == 'win32':
    import msvcrt
    ch = msvcrt.getch()
  else:
    import termios
    import tty
    fd = sys.stdin.fileno()
    old_settings = termios.tcgetattr(fd)
    ch = 'n'
    try:
      tty.setraw(sys.stdin.fileno())
      ch = sys.stdin.read(1)
    finally:
      termios.tcsetattr(fd, termios.TCSADRAIN, old_settings)
  print ch
  return ch in ('Y', 'y')
