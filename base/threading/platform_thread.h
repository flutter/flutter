// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// WARNING: You should *NOT* be using this class directly.  PlatformThread is
// the low-level platform-specific abstraction to the OS's threading interface.
// You should instead be using a message-loop driven Thread, see thread.h.

#ifndef BASE_THREADING_PLATFORM_THREAD_H_
#define BASE_THREADING_PLATFORM_THREAD_H_

#include "base/base_export.h"
#include "base/basictypes.h"
#include "base/time/time.h"
#include "build/build_config.h"

#if defined(OS_WIN)
#include <windows.h>
#elif defined(OS_POSIX)
#include <pthread.h>
#include <unistd.h>
#endif

namespace base {

// Used for logging. Always an integer value.
#if defined(OS_WIN)
typedef DWORD PlatformThreadId;
#elif defined(OS_POSIX)
typedef pid_t PlatformThreadId;
#endif

// Used for thread checking and debugging.
// Meant to be as fast as possible.
// These are produced by PlatformThread::CurrentRef(), and used to later
// check if we are on the same thread or not by using ==. These are safe
// to copy between threads, but can't be copied to another process as they
// have no meaning there. Also, the internal identifier can be re-used
// after a thread dies, so a PlatformThreadRef cannot be reliably used
// to distinguish a new thread from an old, dead thread.
class PlatformThreadRef {
 public:
#if defined(OS_WIN)
  typedef DWORD RefType;
#elif defined(OS_POSIX)
  typedef pthread_t RefType;
#endif
  PlatformThreadRef()
      : id_(0) {
  }

  explicit PlatformThreadRef(RefType id)
      : id_(id) {
  }

  bool operator==(PlatformThreadRef other) const {
    return id_ == other.id_;
  }

  bool is_null() const {
    return id_ == 0;
  }
 private:
  RefType id_;
};

// Used to operate on threads.
class PlatformThreadHandle {
 public:
#if defined(OS_WIN)
  typedef void* Handle;
#elif defined(OS_POSIX)
  typedef pthread_t Handle;
#endif

  PlatformThreadHandle()
      : handle_(0),
        id_(0) {
  }

  explicit PlatformThreadHandle(Handle handle)
      : handle_(handle),
        id_(0) {
  }

  PlatformThreadHandle(Handle handle,
                       PlatformThreadId id)
      : handle_(handle),
        id_(id) {
  }

  PlatformThreadId id() const {
    return id_;
  }

  bool is_equal(const PlatformThreadHandle& other) const {
    return handle_ == other.handle_;
  }

  bool is_null() const {
    return !handle_;
  }

  Handle platform_handle() const {
    return handle_;
  }

 private:
  Handle handle_;
  PlatformThreadId id_;
};

const PlatformThreadId kInvalidThreadId(0);

// Valid values for SetThreadPriority(), listed in increasing order of
// importance.
enum class ThreadPriority {
  // Suitable for threads that shouldn't disrupt high priority work.
  BACKGROUND,
  // Default priority level.
  NORMAL,
  // Suitable for threads which generate data for the display (at ~60Hz).
  DISPLAY,
  // Suitable for low-latency, glitch-resistant audio.
  REALTIME_AUDIO,
};

// A namespace for low-level thread functions.
class BASE_EXPORT PlatformThread {
 public:
  // Implement this interface to run code on a background thread.  Your
  // ThreadMain method will be called on the newly created thread.
  class BASE_EXPORT Delegate {
   public:
    virtual void ThreadMain() = 0;

   protected:
    virtual ~Delegate() {}
  };

  // Gets the current thread id, which may be useful for logging purposes.
  static PlatformThreadId CurrentId();

  // Gets the current thread reference, which can be used to check if
  // we're on the right thread quickly.
  static PlatformThreadRef CurrentRef();

  // Get the handle representing the current thread. On Windows, this is a
  // pseudo handle constant which will always represent the thread using it and
  // hence should not be shared with other threads nor be used to differentiate
  // the current thread from another.
  static PlatformThreadHandle CurrentHandle();

  // Yield the current thread so another thread can be scheduled.
  static void YieldCurrentThread();

  // Sleeps for the specified duration.
  static void Sleep(base::TimeDelta duration);

  // Sets the thread name visible to debuggers/tools. This has no effect
  // otherwise.
  static void SetName(const std::string& name);

  // Gets the thread name, if previously set by SetName.
  static const char* GetName();

  // Creates a new thread.  The |stack_size| parameter can be 0 to indicate
  // that the default stack size should be used.  Upon success,
  // |*thread_handle| will be assigned a handle to the newly created thread,
  // and |delegate|'s ThreadMain method will be executed on the newly created
  // thread.
  // NOTE: When you are done with the thread handle, you must call Join to
  // release system resources associated with the thread.  You must ensure that
  // the Delegate object outlives the thread.
  static bool Create(size_t stack_size, Delegate* delegate,
                     PlatformThreadHandle* thread_handle);

  // CreateWithPriority() does the same thing as Create() except the priority of
  // the thread is set based on |priority|.  Can be used in place of Create()
  // followed by SetThreadPriority().
  static bool CreateWithPriority(size_t stack_size, Delegate* delegate,
                                 PlatformThreadHandle* thread_handle,
                                 ThreadPriority priority);

  // CreateNonJoinable() does the same thing as Create() except the thread
  // cannot be Join()'d.  Therefore, it also does not output a
  // PlatformThreadHandle.
  static bool CreateNonJoinable(size_t stack_size, Delegate* delegate);

  // Joins with a thread created via the Create function.  This function blocks
  // the caller until the designated thread exits.  This will invalidate
  // |thread_handle|.
  static void Join(PlatformThreadHandle thread_handle);

  // Toggles the target thread's priority at runtime.  Prefer
  // CreateWithPriority() to set the thread's initial priority.
  // NOTE: The call may fail if the caller thread is not the same as the
  // target thread on POSIX.  For example, seccomp-bpf blocks it by default
  // in the sandbox.
  static void SetThreadPriority(PlatformThreadHandle handle,
                                ThreadPriority priority);

  static ThreadPriority GetThreadPriority(PlatformThreadHandle handle);

 private:
  DISALLOW_IMPLICIT_CONSTRUCTORS(PlatformThread);
};

}  // namespace base

#endif  // BASE_THREADING_PLATFORM_THREAD_H_
