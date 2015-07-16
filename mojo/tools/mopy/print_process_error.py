# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

def print_process_error(command_line, error):
  """Properly format an exception raised from a failed command execution."""

  if command_line:
    print 'Failed command: %r' % command_line
  else:
    print 'Failed command:'
  print 72 * '-'

  if hasattr(error, 'returncode'):
    print '  with exit code %d' % error.returncode
    print 72 * '-'

  if hasattr(error, 'output'):
    print error.output
  else:
    print error
  print 72 * '-'
