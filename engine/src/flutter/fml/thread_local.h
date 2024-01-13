// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FML_THREAD_LOCAL_H_
#define FLUTTER_FML_THREAD_LOCAL_H_

#include <memory>

#include "flutter/fml/build_config.h"
#include "flutter/fml/macros.h"

namespace fml {

#define FML_THREAD_LOCAL static thread_local

//------------------------------------------------------------------------------
/// @brief      A wrapper for a thread-local unique pointer. Do NOT use this
///             class in new code and instead use unique pointers with the
///             thread_local storage class directly. This was necessary for
///             pre-C++11 code.
///
/// @tparam     T     The type held in the thread local unique pointer.
///
template <typename T>
class ThreadLocalUniquePtr {
 public:
  ThreadLocalUniquePtr() = default;

  T* get() const { return ptr_.get(); }

  void reset(T* ptr) { ptr_.reset(ptr); }

 private:
  std::unique_ptr<T> ptr_;

  FML_DISALLOW_COPY_AND_ASSIGN(ThreadLocalUniquePtr);
};

}  // namespace fml

#endif  // FLUTTER_FML_THREAD_LOCAL_H_
