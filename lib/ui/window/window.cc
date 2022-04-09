// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/window/window.h"

#include "third_party/tonic/converter/dart_converter.h"
#include "third_party/tonic/dart_args.h"
#include "third_party/tonic/logging/dart_invoke.h"
#include "third_party/tonic/typed_data/dart_byte_data.h"

namespace flutter {

Window::Window(int64_t window_id, ViewportMetrics metrics)
    : window_id_(window_id), viewport_metrics_(metrics) {
  library_.Set(tonic::DartState::Current(),
               Dart_LookupLibrary(tonic::ToDart("dart:ui")));
}

Window::~Window() {}

void Window::DispatchPointerDataPacket(const PointerDataPacket& packet) {
  std::shared_ptr<tonic::DartState> dart_state = library_.dart_state().lock();
  if (!dart_state) {
    return;
  }
  tonic::DartState::Scope scope(dart_state);

  const std::vector<uint8_t>& buffer = packet.data();
  Dart_Handle data_handle =
      tonic::DartByteData::Create(buffer.data(), buffer.size());
  if (Dart_IsError(data_handle)) {
    return;
  }
  tonic::CheckAndHandleError(tonic::DartInvokeField(
      library_.value(), "_dispatchPointerDataPacket", {data_handle}));
}

void Window::UpdateWindowMetrics(const ViewportMetrics& metrics) {
  viewport_metrics_ = metrics;

  std::shared_ptr<tonic::DartState> dart_state = library_.dart_state().lock();
  if (!dart_state) {
    return;
  }
  tonic::DartState::Scope scope(dart_state);
  tonic::CheckAndHandleError(tonic::DartInvokeField(
      library_.value(), "_updateWindowMetrics",
      {
          tonic::ToDart(window_id_),
          tonic::ToDart(metrics.device_pixel_ratio),
          tonic::ToDart(metrics.physical_width),
          tonic::ToDart(metrics.physical_height),
          tonic::ToDart(metrics.physical_padding_top),
          tonic::ToDart(metrics.physical_padding_right),
          tonic::ToDart(metrics.physical_padding_bottom),
          tonic::ToDart(metrics.physical_padding_left),
          tonic::ToDart(metrics.physical_view_inset_top),
          tonic::ToDart(metrics.physical_view_inset_right),
          tonic::ToDart(metrics.physical_view_inset_bottom),
          tonic::ToDart(metrics.physical_view_inset_left),
          tonic::ToDart(metrics.physical_system_gesture_inset_top),
          tonic::ToDart(metrics.physical_system_gesture_inset_right),
          tonic::ToDart(metrics.physical_system_gesture_inset_bottom),
          tonic::ToDart(metrics.physical_system_gesture_inset_left),
          tonic::ToDart(metrics.physical_touch_slop),
          tonic::ToDart(metrics.physical_display_features_bounds),
          tonic::ToDart(metrics.physical_display_features_type),
          tonic::ToDart(metrics.physical_display_features_state),
      }));
}

}  // namespace flutter
