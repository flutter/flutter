// Copyright 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_ALLOCATOR_TYPE_PROFILER_H_
#define BASE_ALLOCATOR_TYPE_PROFILER_H_

#if defined(TYPE_PROFILING)

#include <stddef.h>  // for size_t
#include <typeinfo>  // for std::typeinfo

namespace base {
namespace type_profiler {

typedef void* InterceptFunction(void*, size_t, const std::type_info&);

class InterceptFunctions {
 public:
  // It must be called only once in a process while it is in single-thread.
  // For now, ContentMainRunnerImpl::Initialize is the only supposed caller
  // of this function except for single-threaded unit tests.
  static void SetFunctions(InterceptFunction* new_intercept,
                           InterceptFunction* delete_intercept);

 private:
  friend class TypeProfilerTest;

  // These functions are not thread safe.
  // They must be used only from single-threaded unit tests.
  static void ResetFunctions();
  static bool IsAvailable();
};

}  // namespace type_profiler
}  // namespace base

#endif  // defined(TYPE_PROFILING)

#endif  // BASE_ALLOCATOR_TYPE_PROFILER_H_
