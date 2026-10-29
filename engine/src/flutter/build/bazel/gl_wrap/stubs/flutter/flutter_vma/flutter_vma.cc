// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// The Vulkan Memory Allocator's implementation inside the wrapped GN build
// of the GPU test backends (BUILD.gn beside this file), for the shared
// libraries the wrap links itself: ANGLE's allocator wrapper
// (angle_vk_mem_alloc_wrapper) calls vma*, and libGLESv2.dylib on a Mac
// must carry a definition. The engine's own implementation
// (//flutter/flutter_vma/flutter_vma.cc) asserts through fml, which this
// build has not; the allocator is configured as there otherwise -- no
// Vulkan functions of its own, static or fetched: the caller hands it a
// table (ANGLE's, in vma::InitAllocator). The static facade (libangle.a)
// leaves this object out (an archive boundary), where the engine's
// implementation is linked instead.
#define VMA_STATIC_VULKAN_FUNCTIONS 0
#define VMA_DYNAMIC_VULKAN_FUNCTIONS 0
#define VMA_IMPLEMENTATION
#include "vk_mem_alloc.h"
