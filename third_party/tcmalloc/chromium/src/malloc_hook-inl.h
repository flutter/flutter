// Copyright (c) 2005, Google Inc.
// All rights reserved.
// 
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are
// met:
// 
//     * Redistributions of source code must retain the above copyright
// notice, this list of conditions and the following disclaimer.
//     * Redistributions in binary form must reproduce the above
// copyright notice, this list of conditions and the following disclaimer
// in the documentation and/or other materials provided with the
// distribution.
//     * Neither the name of Google Inc. nor the names of its
// contributors may be used to endorse or promote products derived from
// this software without specific prior written permission.
// 
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
// OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
// LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

// ---
// Author: Sanjay Ghemawat
//
// This has the implementation details of malloc_hook that are needed
// to use malloc-hook inside the tcmalloc system.  It does not hold
// any of the client-facing calls that are used to add new hooks.

#ifndef _MALLOC_HOOK_INL_H_
#define _MALLOC_HOOK_INL_H_

#include <stddef.h>
#include <sys/types.h>
#include "base/atomicops.h"
#include "base/basictypes.h"
#include <gperftools/malloc_hook.h>

namespace base { namespace internal {

// The following (implementation) code is DEPRECATED.
// A simple atomic pointer class that can be initialized by the linker
// when you define a namespace-scope variable as:
//
//   AtomicPtr<Foo*> my_global = { &initial_value };
//
// This isn't suitable for a general atomic<> class because of the
// public access to data_.
template<typename PtrT>
class AtomicPtr {
 public:
  COMPILE_ASSERT(sizeof(PtrT) <= sizeof(AtomicWord),
                 PtrT_should_fit_in_AtomicWord);

  PtrT Get() const {
    // Depending on the system, Acquire_Load(AtomicWord*) may have
    // been defined to return an AtomicWord, Atomic32, or Atomic64.
    // We hide that implementation detail here with an explicit cast.
    // This prevents MSVC 2005, at least, from complaining (it has to
    // do with __wp64; AtomicWord is __wp64, but Atomic32/64 aren't).
    return reinterpret_cast<PtrT>(static_cast<AtomicWord>(
      base::subtle::Acquire_Load(&data_)));
  }

  // Sets the contained value to new_val and returns the old value,
  // atomically, with acquire and release semantics.
  // This is a full-barrier instruction.
  PtrT Exchange(PtrT new_val);

  // Atomically executes:
  //      result = data_
  //      if (data_ == old_val)
  //        data_ = new_val;
  //      return result;
  // This is a full-barrier instruction.
  PtrT CompareAndSwap(PtrT old_val, PtrT new_val);

  // Not private so that the class is an aggregate and can be
  // initialized by the linker. Don't access this directly.
  AtomicWord data_;
};

// These are initialized in malloc_hook.cc
extern AtomicPtr<MallocHook::NewHook>     new_hook_;
extern AtomicPtr<MallocHook::DeleteHook>  delete_hook_;
extern AtomicPtr<MallocHook::PreMmapHook> premmap_hook_;
extern AtomicPtr<MallocHook::MmapHook>    mmap_hook_;
extern AtomicPtr<MallocHook::MunmapHook>  munmap_hook_;
extern AtomicPtr<MallocHook::MremapHook>  mremap_hook_;
extern AtomicPtr<MallocHook::PreSbrkHook> presbrk_hook_;
extern AtomicPtr<MallocHook::SbrkHook>    sbrk_hook_;
// End DEPRECATED code.

// Maximum of 7 hooks means that HookList is 8 words.
static const int kHookListMaxValues = 7;

// HookList: a class that provides synchronized insertions and removals and
// lockless traversal.  Most of the implementation is in malloc_hook.cc.
template <typename T>
struct PERFTOOLS_DLL_DECL HookList {
  COMPILE_ASSERT(sizeof(T) <= sizeof(AtomicWord), T_should_fit_in_AtomicWord);

  // Adds value to the list.  Note that duplicates are allowed.  Thread-safe and
  // blocking (acquires hooklist_spinlock).  Returns true on success; false
  // otherwise (failures include invalid value and no space left).
  bool Add(T value);

  // Removes the first entry matching value from the list.  Thread-safe and
  // blocking (acquires hooklist_spinlock).  Returns true on success; false
  // otherwise (failures include invalid value and no value found).
  bool Remove(T value);

  // Store up to n values of the list in output_array, and return the number of
  // elements stored.  Thread-safe and non-blocking.  This is fast (one memory
  // access) if the list is empty.
  int Traverse(T* output_array, int n) const;

  // Fast inline implementation for fast path of Invoke*Hook.
  bool empty() const {
    return base::subtle::Acquire_Load(&priv_end) == 0;
  }

  // This internal data is not private so that the class is an aggregate and can
  // be initialized by the linker.  Don't access this directly.  Use the
  // INIT_HOOK_LIST macro in malloc_hook.cc.

  // One more than the index of the last valid element in priv_data.  During
  // 'Remove' this may be past the last valid element in priv_data, but
  // subsequent values will be 0.
  AtomicWord priv_end;
  AtomicWord priv_data[kHookListMaxValues];
};

extern HookList<MallocHook::NewHook> new_hooks_;
extern HookList<MallocHook::DeleteHook> delete_hooks_;
extern HookList<MallocHook::PreMmapHook> premmap_hooks_;
extern HookList<MallocHook::MmapHook> mmap_hooks_;
extern HookList<MallocHook::MmapReplacement> mmap_replacement_;
extern HookList<MallocHook::MunmapHook> munmap_hooks_;
extern HookList<MallocHook::MunmapReplacement> munmap_replacement_;
extern HookList<MallocHook::MremapHook> mremap_hooks_;
extern HookList<MallocHook::PreSbrkHook> presbrk_hooks_;
extern HookList<MallocHook::SbrkHook> sbrk_hooks_;

} }  // namespace base::internal

// The following method is DEPRECATED
inline MallocHook::NewHook MallocHook::GetNewHook() {
  return base::internal::new_hook_.Get();
}

inline void MallocHook::InvokeNewHook(const void* p, size_t s) {
  if (!base::internal::new_hooks_.empty()) {
    InvokeNewHookSlow(p, s);
  }
  // The following code is DEPRECATED.
  MallocHook::NewHook hook = MallocHook::GetNewHook();
  if (hook != NULL) (*hook)(p, s);
  // End DEPRECATED code.
}

// The following method is DEPRECATED
inline MallocHook::DeleteHook MallocHook::GetDeleteHook() {
  return base::internal::delete_hook_.Get();
}

inline void MallocHook::InvokeDeleteHook(const void* p) {
  if (!base::internal::delete_hooks_.empty()) {
    InvokeDeleteHookSlow(p);
  }
  // The following code is DEPRECATED.
  MallocHook::DeleteHook hook = MallocHook::GetDeleteHook();
  if (hook != NULL) (*hook)(p);
  // End DEPRECATED code.
}

// The following method is DEPRECATED
inline MallocHook::PreMmapHook MallocHook::GetPreMmapHook() {
  return base::internal::premmap_hook_.Get();
}

inline void MallocHook::InvokePreMmapHook(const void* start,
                                          size_t size,
                                          int protection,
                                          int flags,
                                          int fd,
                                          off_t offset) {
  if (!base::internal::premmap_hooks_.empty()) {
    InvokePreMmapHookSlow(start, size, protection, flags, fd, offset);
  }
  // The following code is DEPRECATED.
  MallocHook::PreMmapHook hook = MallocHook::GetPreMmapHook();
  if (hook != NULL) (*hook)(start, size,
                            protection, flags,
                            fd, offset);
  // End DEPRECATED code.
}

// The following method is DEPRECATED
inline MallocHook::MmapHook MallocHook::GetMmapHook() {
  return base::internal::mmap_hook_.Get();
}

inline void MallocHook::InvokeMmapHook(const void* result,
                                       const void* start,
                                       size_t size,
                                       int protection,
                                       int flags,
                                       int fd,
                                       off_t offset) {
  if (!base::internal::mmap_hooks_.empty()) {
    InvokeMmapHookSlow(result, start, size, protection, flags, fd, offset);
  }
  // The following code is DEPRECATED.
  MallocHook::MmapHook hook = MallocHook::GetMmapHook();
  if (hook != NULL) (*hook)(result,
                            start, size,
                            protection, flags,
                            fd, offset);
  // End DEPRECATED code.
}

inline bool MallocHook::InvokeMmapReplacement(const void* start,
                                              size_t size,
                                              int protection,
                                              int flags,
                                              int fd,
                                              off_t offset,
                                              void** result) {
  if (!base::internal::mmap_replacement_.empty()) {
    return InvokeMmapReplacementSlow(start, size,
                                     protection, flags,
                                     fd, offset,
                                     result);
  }
  return false;
}

// The following method is DEPRECATED
inline MallocHook::MunmapHook MallocHook::GetMunmapHook() {
  return base::internal::munmap_hook_.Get();
}

inline void MallocHook::InvokeMunmapHook(const void* p, size_t size) {
  if (!base::internal::munmap_hooks_.empty()) {
    InvokeMunmapHookSlow(p, size);
  }
  // The following code is DEPRECATED.
  MallocHook::MunmapHook hook = MallocHook::GetMunmapHook();
  if (hook != NULL) (*hook)(p, size);
  // End DEPRECATED code.
}

inline bool MallocHook::InvokeMunmapReplacement(
    const void* p, size_t size, int* result) {
  if (!base::internal::mmap_replacement_.empty()) {
    return InvokeMunmapReplacementSlow(p, size, result);
  }
  return false;
}

// The following method is DEPRECATED
inline MallocHook::MremapHook MallocHook::GetMremapHook() {
  return base::internal::mremap_hook_.Get();
}

inline void MallocHook::InvokeMremapHook(const void* result,
                                         const void* old_addr,
                                         size_t old_size,
                                         size_t new_size,
                                         int flags,
                                         const void* new_addr) {
  if (!base::internal::mremap_hooks_.empty()) {
    InvokeMremapHookSlow(result, old_addr, old_size, new_size, flags, new_addr);
  }
  // The following code is DEPRECATED.
  MallocHook::MremapHook hook = MallocHook::GetMremapHook();
  if (hook != NULL) (*hook)(result,
                            old_addr, old_size,
                            new_size, flags, new_addr);
  // End DEPRECATED code.
}

// The following method is DEPRECATED
inline MallocHook::PreSbrkHook MallocHook::GetPreSbrkHook() {
  return base::internal::presbrk_hook_.Get();
}

inline void MallocHook::InvokePreSbrkHook(ptrdiff_t increment) {
  if (!base::internal::presbrk_hooks_.empty() && increment != 0) {
    InvokePreSbrkHookSlow(increment);
  }
  // The following code is DEPRECATED.
  MallocHook::PreSbrkHook hook = MallocHook::GetPreSbrkHook();
  if (hook != NULL && increment != 0) (*hook)(increment);
  // End DEPRECATED code.
}

// The following method is DEPRECATED
inline MallocHook::SbrkHook MallocHook::GetSbrkHook() {
  return base::internal::sbrk_hook_.Get();
}

inline void MallocHook::InvokeSbrkHook(const void* result,
                                       ptrdiff_t increment) {
  if (!base::internal::sbrk_hooks_.empty() && increment != 0) {
    InvokeSbrkHookSlow(result, increment);
  }
  // The following code is DEPRECATED.
  MallocHook::SbrkHook hook = MallocHook::GetSbrkHook();
  if (hook != NULL && increment != 0) (*hook)(result, increment);
  // End DEPRECATED code.
}

#endif /* _MALLOC_HOOK_INL_H_ */
