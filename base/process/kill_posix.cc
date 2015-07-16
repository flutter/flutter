// Copyright (c) 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/process/kill.h"

#include <signal.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>

#include "base/files/file_util.h"
#include "base/files/scoped_file.h"
#include "base/logging.h"
#include "base/posix/eintr_wrapper.h"
#include "base/process/process_iterator.h"
#include "base/synchronization/waitable_event.h"
#include "base/threading/platform_thread.h"

namespace base {

namespace {

TerminationStatus GetTerminationStatusImpl(ProcessHandle handle,
                                           bool can_block,
                                           int* exit_code) {
  int status = 0;
  const pid_t result = HANDLE_EINTR(waitpid(handle, &status,
                                            can_block ? 0 : WNOHANG));
  if (result == -1) {
    DPLOG(ERROR) << "waitpid(" << handle << ")";
    if (exit_code)
      *exit_code = 0;
    return TERMINATION_STATUS_NORMAL_TERMINATION;
  } else if (result == 0) {
    // the child hasn't exited yet.
    if (exit_code)
      *exit_code = 0;
    return TERMINATION_STATUS_STILL_RUNNING;
  }

  if (exit_code)
    *exit_code = status;

  if (WIFSIGNALED(status)) {
    switch (WTERMSIG(status)) {
      case SIGABRT:
      case SIGBUS:
      case SIGFPE:
      case SIGILL:
      case SIGSEGV:
        return TERMINATION_STATUS_PROCESS_CRASHED;
      case SIGKILL:
#if defined(OS_CHROMEOS)
        // On ChromeOS, only way a process gets kill by SIGKILL
        // is by oom-killer.
        return TERMINATION_STATUS_PROCESS_WAS_KILLED_BY_OOM;
#endif
      case SIGINT:
      case SIGTERM:
        return TERMINATION_STATUS_PROCESS_WAS_KILLED;
      default:
        break;
    }
  }

  if (WIFEXITED(status) && WEXITSTATUS(status) != 0)
    return TERMINATION_STATUS_ABNORMAL_TERMINATION;

  return TERMINATION_STATUS_NORMAL_TERMINATION;
}

}  // namespace

#if !defined(OS_NACL_NONSFI)
bool KillProcessGroup(ProcessHandle process_group_id) {
  bool result = kill(-1 * process_group_id, SIGKILL) == 0;
  if (!result)
    DPLOG(ERROR) << "Unable to terminate process group " << process_group_id;
  return result;
}
#endif  // !defined(OS_NACL_NONSFI)

TerminationStatus GetTerminationStatus(ProcessHandle handle, int* exit_code) {
  return GetTerminationStatusImpl(handle, false /* can_block */, exit_code);
}

TerminationStatus GetKnownDeadTerminationStatus(ProcessHandle handle,
                                                int* exit_code) {
  bool result = kill(handle, SIGKILL) == 0;

  if (!result)
    DPLOG(ERROR) << "Unable to terminate process " << handle;

  return GetTerminationStatusImpl(handle, true /* can_block */, exit_code);
}

#if !defined(OS_NACL_NONSFI)
bool WaitForProcessesToExit(const FilePath::StringType& executable_name,
                            TimeDelta wait,
                            const ProcessFilter* filter) {
  bool result = false;

  // TODO(port): This is inefficient, but works if there are multiple procs.
  // TODO(port): use waitpid to avoid leaving zombies around

  TimeTicks end_time = TimeTicks::Now() + wait;
  do {
    NamedProcessIterator iter(executable_name, filter);
    if (!iter.NextProcessEntry()) {
      result = true;
      break;
    }
    PlatformThread::Sleep(TimeDelta::FromMilliseconds(100));
  } while ((end_time - TimeTicks::Now()) > TimeDelta());

  return result;
}

bool CleanupProcesses(const FilePath::StringType& executable_name,
                      TimeDelta wait,
                      int exit_code,
                      const ProcessFilter* filter) {
  bool exited_cleanly = WaitForProcessesToExit(executable_name, wait, filter);
  if (!exited_cleanly)
    KillProcesses(executable_name, exit_code, filter);
  return exited_cleanly;
}

#if !defined(OS_MACOSX)

namespace {

// Return true if the given child is dead. This will also reap the process.
// Doesn't block.
static bool IsChildDead(pid_t child) {
  const pid_t result = HANDLE_EINTR(waitpid(child, NULL, WNOHANG));
  if (result == -1) {
    DPLOG(ERROR) << "waitpid(" << child << ")";
    NOTREACHED();
  } else if (result > 0) {
    // The child has died.
    return true;
  }

  return false;
}

// A thread class which waits for the given child to exit and reaps it.
// If the child doesn't exit within a couple of seconds, kill it.
class BackgroundReaper : public PlatformThread::Delegate {
 public:
  BackgroundReaper(pid_t child, unsigned timeout)
      : child_(child),
        timeout_(timeout) {
  }

  // Overridden from PlatformThread::Delegate:
  void ThreadMain() override {
    WaitForChildToDie();
    delete this;
  }

  void WaitForChildToDie() {
    // Wait forever case.
    if (timeout_ == 0) {
      pid_t r = HANDLE_EINTR(waitpid(child_, NULL, 0));
      if (r != child_) {
        DPLOG(ERROR) << "While waiting for " << child_
                     << " to terminate, we got the following result: " << r;
      }
      return;
    }

    // There's no good way to wait for a specific child to exit in a timed
    // fashion. (No kqueue on Linux), so we just loop and sleep.

    // Wait for 2 * timeout_ 500 milliseconds intervals.
    for (unsigned i = 0; i < 2 * timeout_; ++i) {
      PlatformThread::Sleep(TimeDelta::FromMilliseconds(500));
      if (IsChildDead(child_))
        return;
    }

    if (kill(child_, SIGKILL) == 0) {
      // SIGKILL is uncatchable. Since the signal was delivered, we can
      // just wait for the process to die now in a blocking manner.
      if (HANDLE_EINTR(waitpid(child_, NULL, 0)) < 0)
        DPLOG(WARNING) << "waitpid";
    } else {
      DLOG(ERROR) << "While waiting for " << child_ << " to terminate we"
                  << " failed to deliver a SIGKILL signal (" << errno << ").";
    }
  }

 private:
  const pid_t child_;
  // Number of seconds to wait, if 0 then wait forever and do not attempt to
  // kill |child_|.
  const unsigned timeout_;

  DISALLOW_COPY_AND_ASSIGN(BackgroundReaper);
};

}  // namespace

void EnsureProcessTerminated(Process process) {
  // If the child is already dead, then there's nothing to do.
  if (IsChildDead(process.Pid()))
    return;

  const unsigned timeout = 2;  // seconds
  BackgroundReaper* reaper = new BackgroundReaper(process.Pid(), timeout);
  PlatformThread::CreateNonJoinable(0, reaper);
}

void EnsureProcessGetsReaped(ProcessId pid) {
  // If the child is already dead, then there's nothing to do.
  if (IsChildDead(pid))
    return;

  BackgroundReaper* reaper = new BackgroundReaper(pid, 0);
  PlatformThread::CreateNonJoinable(0, reaper);
}

#endif  // !defined(OS_MACOSX)
#endif  // !defined(OS_NACL_NONSFI)

}  // namespace base
