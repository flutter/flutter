// Copyright 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#if defined(TYPE_PROFILING)

#include "base/allocator/type_profiler_tcmalloc.h"

#include "base/allocator/type_profiler_control.h"
#include "third_party/tcmalloc/chromium/src/gperftools/heap-profiler.h"
#include "third_party/tcmalloc/chromium/src/gperftools/type_profiler_map.h"

namespace base {
namespace type_profiler {

void* NewInterceptForTCMalloc(void* ptr,
                              size_t size,
                              const std::type_info& type) {
  if (Controller::IsProfiling())
    InsertType(ptr, size, type);

  return ptr;
}

void* DeleteInterceptForTCMalloc(void* ptr,
                                 size_t size,
                                 const std::type_info& type) {
  if (Controller::IsProfiling())
    EraseType(ptr);

  return ptr;
}

}  // namespace type_profiler
}  // namespace base

#endif  // defined(TYPE_PROFILING)
