// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_UTIL_WEAK_PTR_INTERNAL_H_
#define MOJO_UTIL_WEAK_PTR_INTERNAL_H_

#include <assert.h>

#include "mojo/edk/util/ref_counted.h"
#include "mojo/public/cpp/system/macros.h"

namespace mojo {
namespace util {
namespace internal {

// |WeakPtr<T>|s have a reference to a |WeakPtrFlag| to determine whether they
// are valid (non-null) or not. We do not store a |T*| in this object since
// there may also be |WeakPtr<U>|s to the same object, where |U| is a superclass
// of |T|.
//
// This class in not thread-safe, though references may be released on any
// thread (allowing weak pointers to be destroyed/reset/reassigned on any
// thread).
class WeakPtrFlag : public RefCountedThreadSafe<WeakPtrFlag> {
 public:
  WeakPtrFlag();
  ~WeakPtrFlag();

  bool is_valid() const { return is_valid_; }

  void Invalidate();

 private:
  bool is_valid_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(WeakPtrFlag);
};

}  // namespace internal
}  // namespace util
}  // namespace mojo

#endif  // MOJO_UTIL_WEAK_PTR_INTERNAL_H_
