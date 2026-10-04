// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_TESTING_TEST_SWANGLE_UTILS_H_
#define FLUTTER_TESTING_TEST_SWANGLE_UTILS_H_

#include <EGL/egl.h>

namespace flutter::testing {

//------------------------------------------------------------------------------
/// @brief      Creates an EGLDisplay using ANGLE with the Vulkan backend and
///             SwiftShader as the device type.
///
/// @return     The created EGLDisplay, or EGL_NO_DISPLAY if creation fails or
///             if necessary extensions are not available.
///
EGLDisplay CreateSwangleDisplay();

}  // namespace flutter::testing

#endif  // FLUTTER_TESTING_TEST_SWANGLE_UTILS_H_
