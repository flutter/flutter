// Copyright 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_PROCESS_PROCESS_H_
#define BASE_PROCESS_PROCESS_H_

#include "base/base_export.h"
#include "base/basictypes.h"
#include "base/move.h"
#include "base/process/process_handle.h"
#include "base/time/time.h"
#include "build/build_config.h"

#if defined(OS_WIN)
#include "base/win/scoped_handle.h"
#endif

namespace base {

// Provides a move-only encapsulation of a process.
//
// This object is not tied to the lifetime of the underlying process: the
// process may be killed and this object may still around, and it will still
// claim to be valid. The actual behavior in that case is OS dependent like so:
//
// Windows: The underlying ProcessHandle will be valid after the process dies
// and can be used to gather some information about that process, but most
// methods will obviously fail.
//
// POSIX: The underlying PorcessHandle is not guaranteed to remain valid after
// the process dies, and it may be reused by the system, which means that it may
// end up pointing to the wrong process.
class BASE_EXPORT Process {
  MOVE_ONLY_TYPE_FOR_CPP_03(Process, RValue)

 public:
  explicit Process(ProcessHandle handle = kNullProcessHandle);

  // Move constructor for C++03 move emulation of this type.
  Process(RValue other);

  // The destructor does not terminate the process.
  ~Process();

  // Move operator= for C++03 move emulation of this type.
  Process& operator=(RValue other);

  // Returns an object for the current process.
  static Process Current();

  // Returns a Process for the given |pid|.
  static Process Open(ProcessId pid);

  // Returns a Process for the given |pid|. On Windows the handle is opened
  // with more access rights and must only be used by trusted code (can read the
  // address space and duplicate handles).
  static Process OpenWithExtraPrivileges(ProcessId pid);

#if defined(OS_WIN)
  // Returns a Process for the given |pid|, using some |desired_access|.
  // See ::OpenProcess documentation for valid |desired_access|.
  static Process OpenWithAccess(ProcessId pid, DWORD desired_access);
#endif

  // Creates an object from a |handle| owned by someone else.
  // Don't use this for new code. It is only intended to ease the migration to
  // a strict ownership model.
  // TODO(rvargas) crbug.com/417532: Remove this code.
  static Process DeprecatedGetProcessFromHandle(ProcessHandle handle);

  // Returns true if processes can be backgrounded.
  static bool CanBackgroundProcesses();

  // Returns true if this objects represents a valid process.
  bool IsValid() const;

  // Returns a handle for this process. There is no guarantee about when that
  // handle becomes invalid because this object retains ownership.
  ProcessHandle Handle() const;

  // Returns a second object that represents this process.
  Process Duplicate() const;

  // Get the PID for this process.
  ProcessId Pid() const;

  // Returns true if this process is the current process.
  bool is_current() const;

  // Close the process handle. This will not terminate the process.
  void Close();

  // Terminates the process with extreme prejudice. The given |exit_code| will
  // be the exit code of the process. If |wait| is true, this method will wait
  // for up to one minute for the process to actually terminate.
  // Returns true if the process terminates within the allowed time.
  // NOTE: On POSIX |exit_code| is ignored.
  bool Terminate(int exit_code, bool wait) const;

  // Waits for the process to exit. Returns true on success.
  // On POSIX, if the process has been signaled then |exit_code| is set to -1.
  // On Linux this must be a child process, however on Mac and Windows it can be
  // any process.
  // NOTE: |exit_code| is optional, nullptr can be passed if the exit code is
  // not required.
  bool WaitForExit(int* exit_code);

  // Same as WaitForExit() but only waits for up to |timeout|.
  // NOTE: |exit_code| is optional, nullptr can be passed if the exit code
  // is not required.
  bool WaitForExitWithTimeout(TimeDelta timeout, int* exit_code);

#if defined(OS_MACOSX)
  // The Mac needs a Mach port in order to manipulate a process's priority,
  // and there's no good way to get that from base given the pid. These Mac
  // variants of the IsProcessBackgrounded and SetProcessBackgrounded API take
  // the Mach port for this reason. See crbug.com/460102
  //
  // A process is backgrounded when its priority is lower than normal.
  // Return true if the process with mach port |task_port| is backgrounded,
  // false otherwise.
  bool IsProcessBackgrounded(mach_port_t task_port) const;

  // Set the process with the specified mach port as backgrounded. If value is
  // true, the priority of the process will be lowered. If value is false, the
  // priority of the process will be made "normal" - equivalent to default
  // process priority. Returns true if the priority was changed, false
  // otherwise.
  bool SetProcessBackgrounded(mach_port_t task_port, bool value);
#else
  // A process is backgrounded when it's priority is lower than normal.
  // Return true if this process is backgrounded, false otherwise.
  bool IsProcessBackgrounded() const;

  // Set a process as backgrounded. If value is true, the priority of the
  // process will be lowered. If value is false, the priority of the process
  // will be made "normal" - equivalent to default process priority.
  // Returns true if the priority was changed, false otherwise.
  bool SetProcessBackgrounded(bool value);
#endif  // defined(OS_MACOSX)
  // Returns an integer representing the priority of a process. The meaning
  // of this value is OS dependent.
  int GetPriority() const;

 private:
#if defined(OS_WIN)
  bool is_current_process_;
  win::ScopedHandle process_;
#else
  ProcessHandle process_;
#endif
};

}  // namespace base

#endif  // BASE_PROCESS_PROCESS_H_
