// Copyright (c) 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file contains Chromium-specific GL extensions declarations.

#ifndef GPU_GL_GLEXTCHROMIUM_H_
#define GPU_GL_GLEXTCHROMIUM_H_

#ifdef __cplusplus
extern "C" {
#endif

#ifndef GL_NVX_gpu_memory_info
#define GL_GPU_MEMORY_INFO_DEDICATED_VIDMEM_NVX 0x9047
#define GL_GPU_MEMORY_INFO_TOTAL_AVAILABLE_MEMORY_NVX 0x9048
#define GL_GPU_MEMORY_INFO_CURRENT_AVAILABLE_VIDMEM_NVX 0x9049
#define GL_GPU_MEMORY_INFO_EVICTION_COUNT_NVX 0x904A
#define GL_GPU_MEMORY_INFO_EVICTED_MEMORY_NVX 0x904B
#endif

#ifdef __cplusplus
}
#endif

#endif  // GPU_GL_GLEXTCHROMIUM_H_
