// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_CRITICAL_CLOSURE_H_
#define BASE_CRITICAL_CLOSURE_H_

#include "base/callback.h"

#if defined(OS_IOS)
#include "base/bind.h"
#include "base/ios/scoped_critical_action.h"
#endif

namespace base {

namespace internal {

#if defined(OS_IOS)
// Returns true if multi-tasking is supported on this iOS device.
bool IsMultiTaskingSupported();

// This class wraps a closure so it can continue to run for a period of time
// when the application goes to the background by using
// |ios::ScopedCriticalAction|.
template <typename R>
class CriticalClosure {
 public:
  explicit CriticalClosure(const Callback<R(void)>& closure)
      : closure_(closure) {}

  ~CriticalClosure() {}

  R Run() {
    return closure_.Run();
  }

 private:
  ios::ScopedCriticalAction critical_action_;
  Callback<R(void)> closure_;

  DISALLOW_COPY_AND_ASSIGN(CriticalClosure);
};
#endif  // defined(OS_IOS)

}  // namespace internal

// Returns a closure (which may return a result, but must not require any extra
// arguments) that will continue to run for a period of time when the
// application goes to the background if possible on platforms where
// applications don't execute while backgrounded, otherwise the original task is
// returned.
//
// Example:
//   file_task_runner_->PostTask(
//       FROM_HERE,
//       MakeCriticalClosure(base::Bind(&WriteToDiskTask, path_, data)));
//
// Note new closures might be posted in this closure. If the new closures need
// background running time, |MakeCriticalClosure| should be applied on them
// before posting.
#if defined(OS_IOS)
template <typename R>
Callback<R(void)> MakeCriticalClosure(const Callback<R(void)>& closure) {
  DCHECK(internal::IsMultiTaskingSupported());
  return base::Bind(&internal::CriticalClosure<R>::Run,
                    Owned(new internal::CriticalClosure<R>(closure)));
}
#else  // defined(OS_IOS)
template <typename R>
inline Callback<R(void)> MakeCriticalClosure(const Callback<R(void)>& closure) {
  // No-op for platforms where the application does not need to acquire
  // background time for closures to finish when it goes into the background.
  return closure;
}
#endif  // defined(OS_IOS)

}  // namespace base

#endif  // BASE_CRITICAL_CLOSURE_H_
