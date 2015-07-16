// Copyright 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#if defined(TYPE_PROFILING)

#include "base/allocator/type_profiler.h"

#include <assert.h>

namespace {

void* NopIntercept(void* ptr, size_t size, const std::type_info& type) {
  return ptr;
}

base::type_profiler::InterceptFunction* g_new_intercept = NopIntercept;
base::type_profiler::InterceptFunction* g_delete_intercept = NopIntercept;

}

void* __op_new_intercept__(void* ptr,
                           size_t size,
                           const std::type_info& type) {
  return g_new_intercept(ptr, size, type);
}

void* __op_delete_intercept__(void* ptr,
                              size_t size,
                              const std::type_info& type) {
  return g_delete_intercept(ptr, size, type);
}

namespace base {
namespace type_profiler {

// static
void InterceptFunctions::SetFunctions(InterceptFunction* new_intercept,
                                      InterceptFunction* delete_intercept) {
  // Don't use DCHECK, as this file is injected into targets
  // that do not and should not depend on base/base.gyp:base
  assert(g_new_intercept == NopIntercept);
  assert(g_delete_intercept == NopIntercept);

  g_new_intercept = new_intercept;
  g_delete_intercept = delete_intercept;
}

// static
void InterceptFunctions::ResetFunctions() {
  g_new_intercept = NopIntercept;
  g_delete_intercept = NopIntercept;
}

// static
bool InterceptFunctions::IsAvailable() {
  return g_new_intercept != NopIntercept || g_delete_intercept != NopIntercept;
}

}  // namespace type_profiler
}  // namespace base

#endif  // defined(TYPE_PROFILING)
