// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_CONVERTERS_OZONE_DRM_GPU_OZONE_DRM_GPU_TYPE_CONVERTERS_H_
#define MOJO_CONVERTERS_OZONE_DRM_GPU_OZONE_DRM_GPU_TYPE_CONVERTERS_H_

#include "base/memory/scoped_ptr.h"
#include "mojo/services/ozone_drm_gpu/public/interfaces/ozone_drm_gpu.mojom.h"
#include "ui/ozone/common/gpu/ozone_gpu_message_params.h"

namespace mojo {

// Types from ozone_drm_gpu.mojom
template <>
struct TypeConverter<ui::DisplayMode_Params, DisplayModePtr> {
  static ui::DisplayMode_Params Convert(const DisplayModePtr& in);
};

template <>
struct TypeConverter<DisplayModePtr, ui::DisplayMode_Params> {
  static DisplayModePtr Convert(const ui::DisplayMode_Params& in);
};

template <>
struct TypeConverter<ui::DisplaySnapshot_Params, DisplaySnapshotPtr> {
  static ui::DisplaySnapshot_Params Convert(const DisplaySnapshotPtr& in);
};

template <>
struct TypeConverter<DisplaySnapshotPtr, ui::DisplaySnapshot_Params> {
  static DisplaySnapshotPtr Convert(const ui::DisplaySnapshot_Params& in);
};

}  // namespace mojo

#endif  // MOJO_CONVERTERS_OZONE_DRM_GPU_OZONE_DRM_GPU_TYPE_CONVERTERS_H_
