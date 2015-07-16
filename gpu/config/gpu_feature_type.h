// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef GPU_CONFIG_GPU_FEATURE_TYPE_H_
#define GPU_CONFIG_GPU_FEATURE_TYPE_H_

namespace gpu {

// Provides flags indicating which gpu features are blacklisted for the system
// on which chrome is currently running.
// If a bit is set to 1, corresponding feature is blacklisted.
enum GpuFeatureType {
  GPU_FEATURE_TYPE_ACCELERATED_2D_CANVAS = 0,
  GPU_FEATURE_TYPE_GPU_COMPOSITING,
  GPU_FEATURE_TYPE_WEBGL,
  GPU_FEATURE_TYPE_FLASH3D,
  GPU_FEATURE_TYPE_FLASH_STAGE3D,
  GPU_FEATURE_TYPE_ACCELERATED_VIDEO_DECODE,
  GPU_FEATURE_TYPE_ACCELERATED_VIDEO_ENCODE,
  GPU_FEATURE_TYPE_PANEL_FITTING,
  GPU_FEATURE_TYPE_FLASH_STAGE3D_BASELINE,
  GPU_FEATURE_TYPE_GPU_RASTERIZATION,
  NUMBER_OF_GPU_FEATURE_TYPES
};

}  // namespace gpu

#endif  // GPU_CONFIG_GPU_FEATURE_TYPE_H_
