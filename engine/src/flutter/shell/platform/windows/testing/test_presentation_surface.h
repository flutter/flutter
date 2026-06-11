// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_WINDOWS_TESTING_TEST_PRESENTATION_SURFACE_H_
#define FLUTTER_SHELL_PLATFORM_WINDOWS_TESTING_TEST_PRESENTATION_SURFACE_H_

#include <windows.h>

#include "flutter/fml/macros.h"
#include "flutter/shell/platform/windows/presentation_surface.h"

namespace flutter {
namespace testing {

class TestPresentationSurface : public PresentationSurface {
 public:
  TestPresentationSurface(size_t width, size_t height)
      : PresentationSurface(width, height) {}

  ~TestPresentationSurface() override = default;

  bool IsValid() const override { return is_valid_; }

  void SetValid(bool is_valid) { is_valid_ = is_valid; }

  bool Resize(size_t width, size_t height) override {
    if (width == 0 || height == 0) {
      return false;
    }
    width_ = width;
    height_ = height;
    return true;
  }

  bool MakeCurrent() override { return true; }

  bool Present() override { return true; }

 private:
  bool is_valid_ = true;

  FML_DISALLOW_COPY_AND_ASSIGN(TestPresentationSurface);
};

}  // namespace testing
}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_WINDOWS_TESTING_TEST_PRESENTATION_SURFACE_H_
