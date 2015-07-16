// Copyright (c) 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/process/kill.h"

#include <signal.h>
#include <sys/event.h>
#include <sys/types.h>
#include <sys/wait.h>

#include "base/files/file_util.h"
#include "base/files/scoped_file.h"
#include "base/logging.h"
#include "base/posix/eintr_wrapper.h"

namespace base {

namespace {

const int kWaitBeforeKillSeconds = 2;

// Reap |child| process. This call blocks until completion.
void BlockingReap(pid_t child) {
  const pid_t result = HANDLE_EINTR(waitpid(child, NULL, 0));
  if (result == -1) {
    DPLOG(ERROR) << "waitpid(" << child << ", NULL, 0)";
  }
}

// Waits for |timeout| seconds for the given |child| to exit and reap it. If
// the child doesn't exit within the time specified, kills it.
//
// This function takes two approaches: first, it tries to use kqueue to
// observe when the process exits. kevent can monitor a kqueue with a
// timeout, so this method is preferred to wait for a specified period of
// time. Once the kqueue indicates the process has exited, waitpid will reap
// the exited child. If the kqueue doesn't provide an exit event notification,
// before the timeout expires, or if the kqueue fails or misbehaves, the
// process will be mercilessly killed and reaped.
//
// A child process passed to this function may be in one of several states:
// running, terminated and not yet reaped, and (apparently, and unfortunately)
// terminated and already reaped. Normally, a process will at least have been
// asked to exit before this function is called, but this is not required.
// If a process is terminating and unreaped, there may be a window between the
// time that kqueue will no longer recognize it and when it becomes an actual
// zombie that a non-blocking (WNOHANG) waitpid can reap. This condition is
// detected when kqueue indicates that the process is not running and a
// non-blocking waitpid fails to reap the process but indicates that it is
// still running. In this event, a blocking attempt to reap the process
// collects the known-dying child, preventing zombies from congregating.
//
// In the event that the kqueue misbehaves entirely, as it might under a
// EMFILE condition ("too many open files", or out of file descriptors), this
// function will forcibly kill and reap the child without delay. This
// eliminates another potential zombie vector. (If you're out of file
// descriptors, you're probably deep into something else, but that doesn't
// mean that zombies be allowed to kick you while you're down.)
//
// The fact that this function seemingly can be called to wait on a child
// that's not only already terminated but already reaped is a bit of a
// problem: a reaped child's pid can be reclaimed and may refer to a distinct
// process in that case. The fact that this function can seemingly be called
// to wait on a process that's not even a child is also a problem: kqueue will
// work in that case, but waitpid won't, and killing a non-child might not be
// the best approach.
void WaitForChildToDie(pid_t child, int timeout) {
  DCHECK_GT(child, 0);
  DCHECK_GT(timeout, 0);

  // DON'T ADD ANY EARLY RETURNS TO THIS FUNCTION without ensuring that
  // |child| has been reaped. Specifically, even if a kqueue, kevent, or other
  // call fails, this function should fall back to the last resort of trying
  // to kill and reap the process. Not observing this rule will resurrect
  // zombies.

  int result;

  ScopedFD kq(HANDLE_EINTR(kqueue()));
  if (!kq.is_valid()) {
    DPLOG(ERROR) << "kqueue()";
  } else {
    struct kevent change = {0};
    EV_SET(&change, child, EVFILT_PROC, EV_ADD, NOTE_EXIT, 0, NULL);
    result = HANDLE_EINTR(kevent(kq.get(), &change, 1, NULL, 0, NULL));

    if (result == -1) {
      if (errno != ESRCH) {
        DPLOG(ERROR) << "kevent (setup " << child << ")";
      } else {
        // At this point, one of the following has occurred:
        // 1. The process has died but has not yet been reaped.
        // 2. The process has died and has already been reaped.
        // 3. The process is in the process of dying. It's no longer
        //    kqueueable, but it may not be waitable yet either. Mark calls
        //    this case the "zombie death race".

        result = HANDLE_EINTR(waitpid(child, NULL, WNOHANG));

        if (result != 0) {
          // A positive result indicates case 1. waitpid succeeded and reaped
          // the child. A result of -1 indicates case 2. The child has already
          // been reaped. In both of these cases, no further action is
          // necessary.
          return;
        }

        // |result| is 0, indicating case 3. The process will be waitable in
        // short order. Fall back out of the kqueue code to kill it (for good
        // measure) and reap it.
      }
    } else {
      // Keep track of the elapsed time to be able to restart kevent if it's
      // interrupted.
      TimeDelta remaining_delta = TimeDelta::FromSeconds(timeout);
      TimeTicks deadline = TimeTicks::Now() + remaining_delta;
      result = -1;
      struct kevent event = {0};
      while (remaining_delta.InMilliseconds() > 0) {
        const struct timespec remaining_timespec = remaining_delta.ToTimeSpec();
        result = kevent(kq.get(), NULL, 0, &event, 1, &remaining_timespec);
        if (result == -1 && errno == EINTR) {
          remaining_delta = deadline - TimeTicks::Now();
          result = 0;
        } else {
          break;
        }
      }

      if (result == -1) {
        DPLOG(ERROR) << "kevent (wait " << child << ")";
      } else if (result > 1) {
        DLOG(ERROR) << "kevent (wait " << child << "): unexpected result "
                    << result;
      } else if (result == 1) {
        if ((event.fflags & NOTE_EXIT) &&
            (event.ident == static_cast<uintptr_t>(child))) {
          // The process is dead or dying. This won't block for long, if at
          // all.
          BlockingReap(child);
          return;
        } else {
          DLOG(ERROR) << "kevent (wait " << child
                      << "): unexpected event: fflags=" << event.fflags
                      << ", ident=" << event.ident;
        }
      }
    }
  }

  // The child is still alive, or is very freshly dead. Be sure by sending it
  // a signal. This is safe even if it's freshly dead, because it will be a
  // zombie (or on the way to zombiedom) and kill will return 0 even if the
  // signal is not delivered to a live process.
  result = kill(child, SIGKILL);
  if (result == -1) {
    DPLOG(ERROR) << "kill(" << child << ", SIGKILL)";
  } else {
    // The child is definitely on the way out now. BlockingReap won't need to
    // wait for long, if at all.
    BlockingReap(child);
  }
}

}  // namespace

void EnsureProcessTerminated(Process process) {
  WaitForChildToDie(process.Pid(), kWaitBeforeKillSeconds);
}

}  // namespace base
