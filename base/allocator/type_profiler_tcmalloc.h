// Copyright 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_ALLOCATOR_TYPE_PROFILER_TCMALLOC_H_
#define BASE_ALLOCATOR_TYPE_PROFILER_TCMALLOC_H_

#if defined(TYPE_PROFILING)

#include <cstddef>  // for size_t
#include <typeinfo>  // for std::type_info

namespace base {
namespace type_profiler {

void* NewInterceptForTCMalloc(void* ptr,
                              size_t size,
                              const std::type_info& type);

void* DeleteInterceptForTCMalloc(void* ptr,
                                 size_t size,
                                 const std::type_info& type);

}  // namespace type_profiler
}  // namespace base

#endif  // defined(TYPE_PROFILING)

#endif  // BASE_ALLOCATOR_TYPE_PROFILER_TCMALLOC_H_
