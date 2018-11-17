// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <mutex>

namespace fml {

template <typename T>
class AtomicObject {
 public:
  AtomicObject() = default;
  AtomicObject(T object) : object_(object) {}

  T Load() const {
    std::lock_guard<std::mutex> lock(mutex_);
    return object_;
  }

  void Store(const T& object) {
    std::lock_guard<std::mutex> lock(mutex_);
    object_ = object;
  }

 private:
  mutable std::mutex mutex_;
  T object_;
};

}  // namespace fml
