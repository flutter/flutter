// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_SEQUENCED_TASK_RUNNER_HELPERS_H_
#define BASE_SEQUENCED_TASK_RUNNER_HELPERS_H_

#include "base/basictypes.h"
#include "base/debug/alias.h"

// TODO(akalin): Investigate whether it's possible to just have
// SequencedTaskRunner use these helpers (instead of MessageLoop).
// Then we can just move these to sequenced_task_runner.h.

namespace tracked_objects {
class Location;
}

namespace base {

namespace subtle {
template <class T, class R> class DeleteHelperInternal;
template <class T, class R> class ReleaseHelperInternal;
}

// Template helpers which use function indirection to erase T from the
// function signature while still remembering it so we can call the
// correct destructor/release function.
//
// We use this trick so we don't need to include bind.h in a header
// file like sequenced_task_runner.h. We also wrap the helpers in a
// templated class to make it easier for users of DeleteSoon to
// declare the helper as a friend.
template <class T>
class DeleteHelper {
 private:
  template <class T2, class R> friend class subtle::DeleteHelperInternal;

  static void DoDelete(const void* object) {
    delete reinterpret_cast<const T*>(object);
  }

  DISALLOW_COPY_AND_ASSIGN(DeleteHelper);
};

template <class T>
class ReleaseHelper {
 private:
  template <class T2, class R> friend class subtle::ReleaseHelperInternal;

  static void DoRelease(const void* object) {
    reinterpret_cast<const T*>(object)->Release();
  }

  DISALLOW_COPY_AND_ASSIGN(ReleaseHelper);
};

namespace subtle {

// An internal SequencedTaskRunner-like class helper for DeleteHelper
// and ReleaseHelper.  We don't want to expose the Do*() functions
// directly directly since the void* argument makes it possible to
// pass/ an object of the wrong type to delete.  Instead, we force
// callers to go through these internal helpers for type
// safety. SequencedTaskRunner-like classes which expose DeleteSoon or
// ReleaseSoon methods should friend the appropriate helper and
// implement a corresponding *Internal method with the following
// signature:
//
// bool(const tracked_objects::Location&,
//      void(*function)(const void*),
//      void* object)
//
// An implementation of this function should simply create a
// base::Closure from (function, object) and return the result of
// posting the task.
template <class T, class ReturnType>
class DeleteHelperInternal {
 public:
  template <class SequencedTaskRunnerType>
  static ReturnType DeleteViaSequencedTaskRunner(
      SequencedTaskRunnerType* sequenced_task_runner,
      const tracked_objects::Location& from_here,
      const T* object) {
    return sequenced_task_runner->DeleteSoonInternal(
        from_here, &DeleteHelper<T>::DoDelete, object);
  }

 private:
  DISALLOW_COPY_AND_ASSIGN(DeleteHelperInternal);
};

template <class T, class ReturnType>
class ReleaseHelperInternal {
 public:
  template <class SequencedTaskRunnerType>
  static ReturnType ReleaseViaSequencedTaskRunner(
      SequencedTaskRunnerType* sequenced_task_runner,
      const tracked_objects::Location& from_here,
      const T* object) {
    return sequenced_task_runner->ReleaseSoonInternal(
        from_here, &ReleaseHelper<T>::DoRelease, object);
  }

 private:
  DISALLOW_COPY_AND_ASSIGN(ReleaseHelperInternal);
};

}  // namespace subtle

}  // namespace base

#endif  // BASE_SEQUENCED_TASK_RUNNER_HELPERS_H_
