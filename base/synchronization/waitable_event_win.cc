// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/synchronization/waitable_event.h"

#include <windows.h>

#include "base/logging.h"
#include "base/numerics/safe_conversions.h"
#include "base/threading/thread_restrictions.h"
#include "base/time/time.h"

namespace base {

WaitableEvent::WaitableEvent(bool manual_reset, bool signaled)
    : handle_(CreateEvent(NULL, manual_reset, signaled, NULL)) {
  // We're probably going to crash anyways if this is ever NULL, so we might as
  // well make our stack reports more informative by crashing here.
  CHECK(handle_.IsValid());
}

WaitableEvent::WaitableEvent(win::ScopedHandle handle)
    : handle_(handle.Pass()) {
  CHECK(handle_.IsValid()) << "Tried to create WaitableEvent from NULL handle";
}

WaitableEvent::~WaitableEvent() {
}

void WaitableEvent::Reset() {
  ResetEvent(handle_.Get());
}

void WaitableEvent::Signal() {
  SetEvent(handle_.Get());
}

bool WaitableEvent::IsSignaled() {
  return TimedWait(TimeDelta());
}

void WaitableEvent::Wait() {
  base::ThreadRestrictions::AssertWaitAllowed();
  DWORD result = WaitForSingleObject(handle_.Get(), INFINITE);
  // It is most unexpected that this should ever fail.  Help consumers learn
  // about it if it should ever fail.
  DCHECK_EQ(WAIT_OBJECT_0, result) << "WaitForSingleObject failed";
}

bool WaitableEvent::TimedWait(const TimeDelta& max_time) {
  base::ThreadRestrictions::AssertWaitAllowed();
  DCHECK_GE(max_time, TimeDelta());
  // Truncate the timeout to milliseconds. The API specifies that this method
  // can return in less than |max_time| (when returning false), as the argument
  // is the maximum time that a caller is willing to wait.
  DWORD timeout = saturated_cast<DWORD>(max_time.InMilliseconds());

  DWORD result = WaitForSingleObject(handle_.Get(), timeout);
  switch (result) {
    case WAIT_OBJECT_0:
      return true;
    case WAIT_TIMEOUT:
      return false;
  }
  // It is most unexpected that this should ever fail.  Help consumers learn
  // about it if it should ever fail.
  NOTREACHED() << "WaitForSingleObject failed";
  return false;
}

// static
size_t WaitableEvent::WaitMany(WaitableEvent** events, size_t count) {
  base::ThreadRestrictions::AssertWaitAllowed();
  HANDLE handles[MAXIMUM_WAIT_OBJECTS];
  CHECK_LE(count, MAXIMUM_WAIT_OBJECTS)
      << "Can only wait on " << MAXIMUM_WAIT_OBJECTS << " with WaitMany";

  for (size_t i = 0; i < count; ++i)
    handles[i] = events[i]->handle();

  // The cast is safe because count is small - see the CHECK above.
  DWORD result =
      WaitForMultipleObjects(static_cast<DWORD>(count),
                             handles,
                             FALSE,      // don't wait for all the objects
                             INFINITE);  // no timeout
  if (result >= WAIT_OBJECT_0 + count) {
    DPLOG(FATAL) << "WaitForMultipleObjects failed";
    return 0;
  }

  return result - WAIT_OBJECT_0;
}

}  // namespace base
