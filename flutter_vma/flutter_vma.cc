// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifdef VMA_STATIC_VULKAN_FUNCTIONS
#undef VMA_STATIC_VULKAN_FUNCTIONS
#endif  // VMA_STATIC_VULKAN_FUNCTIONS

#ifdef VMA_DYNAMIC_VULKAN_FUNCTIONS
#undef VMA_DYNAMIC_VULKAN_FUNCTIONS
#endif  // VMA_DYNAMIC_VULKAN_FUNCTIONS

// We use our own functions pointers
#define VMA_STATIC_VULKAN_FUNCTIONS 0
#define VMA_DYNAMIC_VULKAN_FUNCTIONS 0

#define VMA_IMPLEMENTATION

#include "flutter/flutter_vma/flutter_vma.h"
