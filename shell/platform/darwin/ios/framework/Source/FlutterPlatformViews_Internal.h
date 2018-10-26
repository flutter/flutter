// Copyright 2018 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERPLATFORMVIEWS_INTERNAL_H_
#define FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERPLATFORMVIEWS_INTERNAL_H_

#include "FlutterView.h"
#include "flutter/flow/embedded_views.h"
#include "flutter/fml/platform/darwin/scoped_nsobject.h"
#include "flutter/shell/common/shell.h"
#include "flutter/shell/platform/darwin/ios/framework/Headers/FlutterBinaryMessenger.h"
#include "flutter/shell/platform/darwin/ios/framework/Headers/FlutterChannels.h"
#include "flutter/shell/platform/darwin/ios/framework/Headers/FlutterPlatformViews.h"

namespace shell {

class FlutterPlatformViewsController : public flow::ExternalViewEmbedder {
 public:
  FlutterPlatformViewsController(NSObject<FlutterBinaryMessenger>* messenger,
                                 FlutterView* flutter_view);

  void RegisterViewFactory(NSObject<FlutterPlatformViewFactory>* factory, NSString* factoryId);

  void CompositeEmbeddedView(int view_id, const flow::EmbeddedViewParams& params);

 private:
  fml::scoped_nsobject<FlutterMethodChannel> channel_;
  fml::scoped_nsobject<FlutterView> flutter_view_;
  std::map<std::string, fml::scoped_nsobject<NSObject<FlutterPlatformViewFactory>>> factories_;
  std::map<int64_t, fml::scoped_nsobject<UIView>> views_;

  void OnMethodCall(FlutterMethodCall* call, FlutterResult& result);
  void OnCreate(FlutterMethodCall* call, FlutterResult& result);
  void OnDispose(FlutterMethodCall* call, FlutterResult& result);

  FML_DISALLOW_COPY_AND_ASSIGN(FlutterPlatformViewsController);
};

}  // namespace shell

#endif  // FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERPLATFORMVIEWS_INTERNAL_H_
