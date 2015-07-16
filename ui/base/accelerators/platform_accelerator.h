// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_BASE_ACCELERATORS_PLATFORM_ACCELERATOR_H_
#define UI_BASE_ACCELERATORS_PLATFORM_ACCELERATOR_H_

#include "base/memory/scoped_ptr.h"

namespace ui {

// Abstract base class for platform specific accelerator keys.
class PlatformAccelerator {
 public:
  virtual ~PlatformAccelerator() {}

  virtual scoped_ptr<PlatformAccelerator> CreateCopy() const = 0;
  virtual bool Equals(const PlatformAccelerator& rhs) const = 0;
};

}  // namespace ui

#endif  // UI_BASE_ACCELERATORS_PLATFORM_ACCELERATOR_H_
