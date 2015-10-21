// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/converters/ozone_drm_gpu/ozone_drm_gpu_type_converters.h"

#include "mojo/converters/geometry/geometry_type_converters.h"

namespace mojo {

// static
ui::DisplayMode_Params
TypeConverter<ui::DisplayMode_Params, DisplayModePtr>::Convert(
    const DisplayModePtr& in) {
  auto out = ui::DisplayMode_Params();
  out.size = in->size.To<gfx::Size>();
  out.is_interlaced = in->is_interlaced;
  out.refresh_rate = in->refresh_rate;
  return out;
}

// static
DisplayModePtr TypeConverter<DisplayModePtr, ui::DisplayMode_Params>::Convert(
    const ui::DisplayMode_Params& in) {
  auto out = DisplayMode::New();
  out->size = Size::From<gfx::Size>(in.size);
  out->is_interlaced = in.is_interlaced;
  out->refresh_rate = in.refresh_rate;
  return out.Pass();
}

static_assert(static_cast<int>(ui::DISPLAY_CONNECTION_TYPE_NONE) ==
                  static_cast<int>(mojo::DisplayType::NONE),
              "Enum value mismatch");
static_assert(static_cast<int>(ui::DISPLAY_CONNECTION_TYPE_UNKNOWN) ==
                  static_cast<int>(mojo::DisplayType::UNKNOWN),
              "Enum value mismatch");
static_assert(static_cast<int>(ui::DISPLAY_CONNECTION_TYPE_INTERNAL) ==
                  static_cast<int>(mojo::DisplayType::INTERNAL),
              "Enum value mismatch");
static_assert(static_cast<int>(ui::DISPLAY_CONNECTION_TYPE_VGA) ==
                  static_cast<int>(mojo::DisplayType::VGA),
              "Enum value mismatch");
static_assert(static_cast<int>(ui::DISPLAY_CONNECTION_TYPE_HDMI) ==
                  static_cast<int>(mojo::DisplayType::HDMI),
              "Enum value mismatch");
static_assert(static_cast<int>(ui::DISPLAY_CONNECTION_TYPE_DVI) ==
                  static_cast<int>(mojo::DisplayType::DVI),
              "Enum value mismatch");
static_assert(static_cast<int>(ui::DISPLAY_CONNECTION_TYPE_DISPLAYPORT) ==
                  static_cast<int>(mojo::DisplayType::DISPLAYPORT),
              "Enum value mismatch");
static_assert(static_cast<int>(ui::DISPLAY_CONNECTION_TYPE_NETWORK) ==
                  static_cast<int>(mojo::DisplayType::NETWORK),
              "Enum value mismatch");
static_assert(static_cast<int>(ui::DISPLAY_CONNECTION_TYPE_LAST) ==
                  static_cast<int>(mojo::DisplayType::LAST),
              "Enum value mismatch");

// static
ui::DisplaySnapshot_Params
TypeConverter<ui::DisplaySnapshot_Params, DisplaySnapshotPtr>::Convert(
    const DisplaySnapshotPtr& in) {
  auto out = ui::DisplaySnapshot_Params();
  out.display_id = in->display_id;
  out.origin = in->origin.To<gfx::Point>();
  out.physical_size = in->physical_size.To<gfx::Size>();
  out.type = static_cast<ui::DisplayConnectionType>(in->type);
  assert(out.type <= ui::DISPLAY_CONNECTION_TYPE_LAST);
  for (size_t i = 0; i < in->modes.size(); ++i) {
    out.modes.push_back(in->modes[i].To<ui::DisplayMode_Params>());
  }
  out.has_current_mode = in->has_current_mode;
  out.current_mode = in->current_mode.To<ui::DisplayMode_Params>();
  out.has_native_mode = in->has_native_mode;
  out.native_mode = in->native_mode.To<ui::DisplayMode_Params>();
  out.product_id = in->product_id;
  out.string_representation = in->string_representation;
  return out;
}

// static
DisplaySnapshotPtr
TypeConverter<DisplaySnapshotPtr, ui::DisplaySnapshot_Params>::Convert(
    const ui::DisplaySnapshot_Params& in) {
  auto out = DisplaySnapshot::New();
  out->display_id = in.display_id;
  out->origin = Point::From<gfx::Point>(in.origin);
  out->physical_size = Size::From<gfx::Size>(in.physical_size);
  out->type = static_cast<mojo::DisplayType>(in.type);
  assert(out->type <= mojo::DisplayType::LAST);
  auto modes = Array<DisplayModePtr>::New(in.modes.size());
  for (size_t i = 0; i < in.modes.size(); ++i) {
    auto mode = DisplayMode::From<ui::DisplayMode_Params>(in.modes[i]);
    modes[i] = mode.Pass();
  }
  out->modes = modes.Pass();
  out->has_current_mode = in.has_current_mode;
  out->current_mode =
      DisplayMode::From<ui::DisplayMode_Params>(in.current_mode);
  out->has_native_mode = in.has_native_mode;
  out->native_mode = DisplayMode::From<ui::DisplayMode_Params>(in.native_mode);
  out->product_id = in.product_id;
  out->string_representation = in.string_representation;
  return out.Pass();
}

}  // namespace mojo
