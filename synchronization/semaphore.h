// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SYNCHRONIZATION_SEMAPHORE_H_
#define SYNCHRONIZATION_SEMAPHORE_H_

#include <memory>

#include "lib/fxl/compiler_specific.h"
#include "lib/fxl/macros.h"
#include "lib/fxl/time/time_delta.h"

namespace flutter {

class PlatformSemaphore;

class Semaphore {
 public:
  explicit Semaphore(uint32_t count);

  ~Semaphore();

  bool IsValid() const;

  FXL_WARN_UNUSED_RESULT
  bool TryWait();

  void Signal();

 private:
  std::unique_ptr<PlatformSemaphore> _impl;

  FXL_DISALLOW_COPY_AND_ASSIGN(Semaphore);
};

}  // namespace flutter

#endif  // SYNCHRONIZATION_SEMAPHORE_H_
