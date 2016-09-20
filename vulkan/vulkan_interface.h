// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_VULKAN_VULKAN_INTERFACE_H_
#define FLUTTER_VULKAN_VULKAN_INTERFACE_H_

#define VK_NO_PROTOTYPES 1

#include "lib/ftl/build_config.h"

#if OS_ANDROID
#define VK_USE_PLATFORM_ANDROID_KHR 1
#endif  // OS_ANDROID

#include "third_party/vulkan/src/vulkan/vulkan.h"

#endif  // FLUTTER_VULKAN_VULKAN_INTERFACE_H_
