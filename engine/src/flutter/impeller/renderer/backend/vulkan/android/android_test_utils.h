// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_RENDERER_BACKEND_VULKAN_ANDROID_ANDROID_TEST_UTILS_H_
#define FLUTTER_IMPELLER_RENDERER_BACKEND_VULKAN_ANDROID_ANDROID_TEST_UTILS_H_

#include <string>
#include <vector>

namespace impeller::android::testing {

/// A list of Vulkan device extensions that are required by Android-specific
/// services in the Impeller Vulkan back end.
/// This can be used to configure the mock Vulkan framework to simulate
/// Android's version of Vulkan.
extern const std::vector<std::string> kAndroidDeviceExtensions;

}  // namespace impeller::android::testing

#endif  // FLUTTER_IMPELLER_RENDERER_BACKEND_VULKAN_ANDROID_ANDROID_TEST_UTILS_H_
