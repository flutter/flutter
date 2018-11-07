// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FML_PLATFORM_DARWIN_CF_UTILS_H_
#define FLUTTER_FML_PLATFORM_DARWIN_CF_UTILS_H_

#include <CoreFoundation/CoreFoundation.h>

#include "flutter/fml/macros.h"

namespace fml {

template <class T>
class CFRef {
 public:
  CFRef() : instance_(nullptr) {}

  CFRef(T instance) : instance_(instance) {}

  ~CFRef() {
    if (instance_ != nullptr) {
      CFRelease(instance_);
    }
    instance_ = nullptr;
  }

  void Reset(T instance) {
    if (instance_ == instance) {
      return;
    }
    if (instance_ != nullptr) {
      CFRelease(instance_);
    }

    instance_ = instance;
  }

  operator T() const { return instance_; }

  operator bool() const { return instance_ != nullptr; }

 private:
  T instance_;

  FML_DISALLOW_COPY_AND_ASSIGN(CFRef);
};

}  // namespace fml

#endif  // FLUTTER_FML_PLATFORM_DARWIN_CF_UTILS_H_
