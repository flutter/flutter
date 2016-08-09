# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Defines constants for signals that should be supported on devices.

Note: Obtained by running `kill -l` on a user device.
"""


SIGHUP = 1 # Hangup
SIGINT = 2 # Interrupt
SIGQUIT = 3 # Quit
SIGILL = 4 # Illegal instruction
SIGTRAP = 5 # Trap
SIGABRT = 6 # Aborted
SIGBUS = 7 # Bus error
SIGFPE = 8 # Floating point exception
SIGKILL = 9 # Killed
SIGUSR1 = 10 # User signal 1
SIGSEGV = 11 # Segmentation fault
SIGUSR2 = 12 # User signal 2
SIGPIPE = 13 # Broken pipe
SIGALRM = 14 # Alarm clock
SIGTERM = 15 # Terminated
SIGSTKFLT = 16 # Stack fault
SIGCHLD = 17 # Child exited
SIGCONT = 18 # Continue
SIGSTOP = 19 # Stopped (signal)
SIGTSTP = 20 # Stopped
SIGTTIN = 21 # Stopped (tty input)
SIGTTOU = 22 # Stopped (tty output)
SIGURG = 23 # Urgent I/O condition
SIGXCPU = 24 # CPU time limit exceeded
SIGXFSZ = 25 # File size limit exceeded
SIGVTALRM = 26 # Virtual timer expired
SIGPROF = 27 # Profiling timer expired
SIGWINCH = 28 # Window size changed
SIGIO = 29 # I/O possible
SIGPWR = 30 # Power failure
SIGSYS = 31 # Bad system call
