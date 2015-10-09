// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Internal implementation details for ref_counted.h.

#ifndef MOJO_EDK_SYSTEM_REF_COUNTED_INTERNAL_H_
#define MOJO_EDK_SYSTEM_REF_COUNTED_INTERNAL_H_

#include <assert.h>

#include "base/atomicops.h"
#include "mojo/public/cpp/system/macros.h"

namespace mojo {
namespace system {
namespace internal {

class RefCountedThreadSafeBase {
 public:
  void AddRef() const {
    assert(!adoption_required_);
    assert(!destruction_started_);
    base::subtle::NoBarrier_AtomicIncrement(&ref_count_, 1);
  }

  void AssertHasOneRef() const {
    assert(base::subtle::Acquire_Load(&ref_count_) == 1);
  }

 protected:
  RefCountedThreadSafeBase()
      : ref_count_(1)
#ifndef NDEBUG
        ,
        adoption_required_(true),
        destruction_started_(false)
#endif
  {
  }

  ~RefCountedThreadSafeBase() {
    assert(!adoption_required_);
    // Should only be destroyed as a result of |Release()|.
    assert(destruction_started_);
  }

  // Returns true if the object should self-delete.
  bool Release() const {
    assert(!adoption_required_);
    assert(!destruction_started_);
    assert(base::subtle::Acquire_Load(&ref_count_) != 0);
    // TODO(vtl): We could add the following:
    //     if (base::subtle::NoBarrier_Load(&ref_count_) == 1) {
    // #ifndef NDEBUG
    //       destruction_started_= true;
    // #endif
    //       return true;
    //     }
    // This would be correct. On ARM (an Nexus 4), in *single-threaded* tests,
    // this seems to make the destruction case marginally faster (barely
    // measurable), and while the non-destruction case remains about the same
    // (possibly marginally slower, but my measurements aren't good enough to
    // have any confidence in that). I should try multithreaded/multicore tests.
    if (base::subtle::Barrier_AtomicIncrement(&ref_count_, -1) == 0) {
#ifndef NDEBUG
      destruction_started_ = true;
#endif
      return true;
    }
    return false;
  }

#ifndef NDEBUG
  void Adopt() {
    assert(adoption_required_);
    adoption_required_ = false;
  }
#endif

 private:
  mutable base::subtle::Atomic32 ref_count_;

#ifndef NDEBUG
  mutable bool adoption_required_;
  mutable bool destruction_started_;
#endif

  MOJO_DISALLOW_COPY_AND_ASSIGN(RefCountedThreadSafeBase);
};

}  // namespace internal
}  // namespace system
}  // namespace mojo

#endif  // MOJO_EDK_SYSTEM_REF_COUNTED_INTERNAL_H_
