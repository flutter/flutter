// Copyright (c) 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gpu/config/gpu_blacklist.h"

#include "gpu/config/gpu_feature_type.h"

namespace gpu {

GpuBlacklist::GpuBlacklist()
    : GpuControlList() {
}

GpuBlacklist::~GpuBlacklist() {
}

// static
GpuBlacklist* GpuBlacklist::Create() {
  GpuBlacklist* list = new GpuBlacklist();
  list->AddSupportedFeature("accelerated_2d_canvas",
                            GPU_FEATURE_TYPE_ACCELERATED_2D_CANVAS);
  list->AddSupportedFeature("gpu_compositing",
                            GPU_FEATURE_TYPE_GPU_COMPOSITING);
  list->AddSupportedFeature("webgl",
                            GPU_FEATURE_TYPE_WEBGL);
  list->AddSupportedFeature("flash_3d",
                            GPU_FEATURE_TYPE_FLASH3D);
  list->AddSupportedFeature("flash_stage3d",
                            GPU_FEATURE_TYPE_FLASH_STAGE3D);
  list->AddSupportedFeature("flash_stage3d_baseline",
                            GPU_FEATURE_TYPE_FLASH_STAGE3D_BASELINE);
  list->AddSupportedFeature("accelerated_video_decode",
                            GPU_FEATURE_TYPE_ACCELERATED_VIDEO_DECODE);
  list->AddSupportedFeature("accelerated_video_encode",
                            GPU_FEATURE_TYPE_ACCELERATED_VIDEO_ENCODE);
  list->AddSupportedFeature("panel_fitting",
                            GPU_FEATURE_TYPE_PANEL_FITTING);
  list->AddSupportedFeature("gpu_rasterization",
                            GPU_FEATURE_TYPE_GPU_RASTERIZATION);
  list->set_supports_feature_type_all(true);
  return list;
}

}  // namespace gpu
