// Copyright 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#if defined(TYPE_PROFILING)

#include <config.h>

#include <new>
#include <stddef.h>
#include <typeinfo>

#include <gperftools/type_profiler_map.h>

#include "addressmap-inl.h"
#include "base/logging.h"
#include "base/low_level_alloc.h"
#include "base/spinlock.h"
#include "tcmalloc_guard.h"

namespace {

const TCMallocGuard tcmalloc_initializer;

//----------------------------------------------------------------------
// A struct to store size and type_info of an object
//----------------------------------------------------------------------

struct ObjectInfo {
 public:
  ObjectInfo(): size(0), type(NULL) {}
  ObjectInfo(size_t size_arg, const std::type_info* type_arg)
      : size(size_arg),
        type(type_arg) {
  }

  size_t size;
  const std::type_info* type;
};

//----------------------------------------------------------------------
// Locking
//----------------------------------------------------------------------

SpinLock g_type_profiler_lock(SpinLock::LINKER_INITIALIZED);

//----------------------------------------------------------------------
// Simple allocator for type_info map's internal memory
//----------------------------------------------------------------------

LowLevelAlloc::Arena* g_type_profiler_map_memory = NULL;

void* TypeProfilerMalloc(size_t bytes) {
  return LowLevelAlloc::AllocWithArena(bytes, g_type_profiler_map_memory);
}

void TypeProfilerFree(void* p) {
  LowLevelAlloc::Free(p);
}

//----------------------------------------------------------------------
// Profiling control/state data
//----------------------------------------------------------------------

AddressMap<ObjectInfo>* g_type_profiler_map = NULL;

//----------------------------------------------------------------------
// Manage type_info map
//----------------------------------------------------------------------

void InitializeTypeProfilerMemory() {
  if (g_type_profiler_map_memory != NULL) {
    RAW_DCHECK(g_type_profiler_map != NULL, "TypeProfilerMap is NULL");
    return;
  }

  g_type_profiler_map_memory =
      LowLevelAlloc::NewArena(0, LowLevelAlloc::DefaultArena());

  g_type_profiler_map =
      new(TypeProfilerMalloc(sizeof(*g_type_profiler_map)))
          AddressMap<ObjectInfo>(TypeProfilerMalloc, TypeProfilerFree);
}

}  // namespace

void InsertType(void* address, size_t size, const std::type_info& type) {
  SpinLockHolder lock(&g_type_profiler_lock);
  InitializeTypeProfilerMemory();

  g_type_profiler_map->Insert(address, ObjectInfo(size, &type));
}

void EraseType(void* address) {
  SpinLockHolder lock(&g_type_profiler_lock);
  InitializeTypeProfilerMemory();

  ObjectInfo obj;
  g_type_profiler_map->FindAndRemove(address, &obj);
}

const std::type_info* LookupType(const void* address) {
  SpinLockHolder lock(&g_type_profiler_lock);
  InitializeTypeProfilerMemory();

  const ObjectInfo* found = g_type_profiler_map->Find(address);
  if (found == NULL)
    return NULL;
  return found->type;
}

#endif  // defined(TYPE_PROFILING)
