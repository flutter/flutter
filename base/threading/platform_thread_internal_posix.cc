// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/threading/platform_thread_internal_posix.h"

#include "base/logging.h"

namespace base {

namespace internal {

int ThreadPriorityToNiceValue(ThreadPriority priority) {
  for (const ThreadPriorityToNiceValuePair& pair :
       kThreadPriorityToNiceValueMap) {
    if (pair.priority == priority)
      return pair.nice_value;
  }
  NOTREACHED() << "Unknown ThreadPriority";
  return 0;
}

ThreadPriority NiceValueToThreadPriority(int nice_value) {
  for (const ThreadPriorityToNiceValuePair& pair :
       kThreadPriorityToNiceValueMap) {
    if (pair.nice_value == nice_value)
      return pair.priority;
  }
  NOTREACHED() << "Unknown nice value";
  return ThreadPriority::NORMAL;
}

}  // namespace internal

}  // namespace base
