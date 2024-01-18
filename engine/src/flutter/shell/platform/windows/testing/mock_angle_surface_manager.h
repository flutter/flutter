// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_WINDOWS_TESTING_MOCK_ANGLE_SURFACE_MANAGER_H_
#define FLUTTER_SHELL_PLATFORM_WINDOWS_TESTING_MOCK_ANGLE_SURFACE_MANAGER_H_

#include "flutter/fml/macros.h"
#include "flutter/shell/platform/windows/angle_surface_manager.h"
#include "gmock/gmock.h"

namespace flutter {
namespace testing {

/// Mock for the |AngleSurfaceManager| base class.
class MockAngleSurfaceManager : public AngleSurfaceManager {
 public:
  MockAngleSurfaceManager() : AngleSurfaceManager(false) {}

  MOCK_METHOD(bool, CreateSurface, (HWND, EGLint, EGLint), (override));
  MOCK_METHOD(void, ResizeSurface, (HWND, EGLint, EGLint, bool), (override));
  MOCK_METHOD(void, DestroySurface, (), (override));

  MOCK_METHOD(bool, MakeCurrent, (), (override));
  MOCK_METHOD(bool, ClearCurrent, (), (override));
  MOCK_METHOD(void, SetVSyncEnabled, (bool), (override));

  MOCK_METHOD(bool, SwapBuffers, (), (override));

 private:
  FML_DISALLOW_COPY_AND_ASSIGN(MockAngleSurfaceManager);
};

}  // namespace testing
}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_WINDOWS_TESTING_MOCK_ANGLE_SURFACE_MANAGER_H_
