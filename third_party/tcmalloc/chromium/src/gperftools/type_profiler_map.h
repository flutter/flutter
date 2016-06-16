// Copyright 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef TYPE_PROFILER_MAP_H_
#define TYPE_PROFILER_MAP_H_

#if defined(TYPE_PROFILING)

#include <typeinfo>

// PERFTOOLS_DLL_DECL is unnecessary, as it is Windows specific.

void InsertType(void* address, size_t size, const std::type_info& type);
void EraseType(void* address);
const std::type_info* LookupType(const void* address);

#endif  // defined(TYPE_PROFILING)

#endif  // TYPE_PROFILER_MAP_H_
