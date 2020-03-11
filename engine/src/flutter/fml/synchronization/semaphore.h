// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FML_SYNCHRONIZATION_SEMAPHORE_H_
#define FLUTTER_FML_SYNCHRONIZATION_SEMAPHORE_H_

#include <memory>

#include "flutter/fml/compiler_specific.h"
#include "flutter/fml/macros.h"

namespace fml {

class PlatformSemaphore;

class Semaphore {
 public:
  explicit Semaphore(uint32_t count);

  ~Semaphore();

  bool IsValid() const;

  [[nodiscard]] bool TryWait();

  void Signal();

 private:
  std::unique_ptr<PlatformSemaphore> _impl;

  FML_DISALLOW_COPY_AND_ASSIGN(Semaphore);
};

}  // namespace fml

#endif  // FLUTTER_FML_SYNCHRONIZATION_SEMAPHORE_H_
