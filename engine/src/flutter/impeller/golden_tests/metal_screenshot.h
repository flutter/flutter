// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <CoreFoundation/CoreFoundation.h>
#include <CoreImage/CoreImage.h>
#include <string>

#include "flutter/fml/macros.h"

namespace impeller {
namespace testing {

class MetalScreenshoter;

/// A screenshot that was produced from `MetalScreenshoter`.
class MetalScreenshot {
 public:
  ~MetalScreenshot();

  const UInt8* GetBytes() const;

  size_t GetHeight() const;

  size_t GetWidth() const;

  bool WriteToPNG(const std::string& path) const;

 private:
  friend class MetalScreenshoter;
  MetalScreenshot(CGImageRef cgImage);
  FML_DISALLOW_COPY_AND_ASSIGN(MetalScreenshot);
  CGImageRef cgImage_;
  CFDataRef pixel_data_;
};
}  // namespace testing
}  // namespace impeller
