// Copyright (c) 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/process/memory.h"

#include <new.h>
#include <psapi.h>

#include "base/logging.h"
#include "base/memory/scoped_ptr.h"

namespace base {

namespace {

#pragma warning(push)
#pragma warning(disable: 4702)

int OnNoMemory(size_t) {
  // Kill the process. This is important for security since most of code
  // does not check the result of memory allocation.
  __debugbreak();
  _exit(1);
  return 0;
}

#pragma warning(pop)

// HeapSetInformation function pointer.
typedef BOOL (WINAPI* HeapSetFn)(HANDLE, HEAP_INFORMATION_CLASS, PVOID, SIZE_T);

}  // namespace

bool EnableLowFragmentationHeap() {
  HMODULE kernel32 = GetModuleHandle(L"kernel32.dll");
  HeapSetFn heap_set = reinterpret_cast<HeapSetFn>(GetProcAddress(
      kernel32,
      "HeapSetInformation"));

  // On Windows 2000, the function is not exported. This is not a reason to
  // fail.
  if (!heap_set)
    return true;

  unsigned number_heaps = GetProcessHeaps(0, NULL);
  if (!number_heaps)
    return false;

  // Gives us some extra space in the array in case a thread is creating heaps
  // at the same time we're querying them.
  static const int MARGIN = 8;
  scoped_ptr<HANDLE[]> heaps(new HANDLE[number_heaps + MARGIN]);
  number_heaps = GetProcessHeaps(number_heaps + MARGIN, heaps.get());
  if (!number_heaps)
    return false;

  for (unsigned i = 0; i < number_heaps; ++i) {
    ULONG lfh_flag = 2;
    // Don't bother with the result code. It may fails on heaps that have the
    // HEAP_NO_SERIALIZE flag. This is expected and not a problem at all.
    heap_set(heaps[i],
             HeapCompatibilityInformation,
             &lfh_flag,
             sizeof(lfh_flag));
  }
  return true;
}

void EnableTerminationOnHeapCorruption() {
  // Ignore the result code. Supported on XP SP3 and Vista.
  HeapSetInformation(NULL, HeapEnableTerminationOnCorruption, NULL, 0);
}

void EnableTerminationOnOutOfMemory() {
  _set_new_handler(&OnNoMemory);
  _set_new_mode(1);
}

HMODULE GetModuleFromAddress(void* address) {
  HMODULE instance = NULL;
  if (!::GetModuleHandleExA(GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS |
                            GET_MODULE_HANDLE_EX_FLAG_UNCHANGED_REFCOUNT,
                            static_cast<char*>(address),
                            &instance)) {
    NOTREACHED();
  }
  return instance;
}

// TODO(b.kelemen): implement it with the required semantics. On Linux this is
// implemented with a weak symbol that is overridden by tcmalloc. This is
// neccessary because base cannot have a direct dependency on tcmalloc. Since
// weak symbols are not supported on Windows this will involve some build time
// magic, much like what is done for libcrt in order to override the allocation
// functions.
bool UncheckedMalloc(size_t size, void** result) {
  *result = malloc(size);
  return *result != NULL;
}

}  // namespace base
