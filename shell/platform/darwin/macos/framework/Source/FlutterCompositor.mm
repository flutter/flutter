// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterCompositor.h"
#include "flutter/fml/logging.h"

namespace flutter {

FlutterCompositor::FlutterCompositor(FlutterViewController* view_controller) {
  FML_CHECK(view_controller != nullptr) << "FlutterViewController* cannot be nullptr";

  view_controller_ = view_controller;
}

void FlutterCompositor::SetPresentCallback(
    const FlutterCompositor::PresentCallback& present_callback) {
  present_callback_ = present_callback;
}

void FlutterCompositor::StartFrame() {
  // First remove all CALayers from the superlayer.
  for (auto layer : active_ca_layers_) {
    [layer removeFromSuperlayer];
  }

  // Reset active layers.
  active_ca_layers_.clear();
  SetFrameStatus(FrameStatus::kStarted);
}

bool FlutterCompositor::EndFrame(bool has_flutter_content) {
  bool status = present_callback_(has_flutter_content);
  SetFrameStatus(FrameStatus::kEnded);
  return status;
}

void FlutterCompositor::SetFrameStatus(FlutterCompositor::FrameStatus frame_status) {
  frame_status_ = frame_status;
}

FlutterCompositor::FrameStatus FlutterCompositor::GetFrameStatus() {
  return frame_status_;
}

void FlutterCompositor::InsertCALayerForIOSurface(const IOSurfaceRef& io_surface,
                                                  CATransform3D transform) {
  // FlutterCompositor manages the lifecycle of CALayers.
  CALayer* content_layer = [[CALayer alloc] init];
  content_layer.transform = transform;
  content_layer.frame = view_controller_.flutterView.layer.bounds;
  [content_layer setContents:(__bridge id)io_surface];
  [view_controller_.flutterView.layer addSublayer:content_layer];

  active_ca_layers_.push_back(content_layer);
}

}  // namespace flutter
