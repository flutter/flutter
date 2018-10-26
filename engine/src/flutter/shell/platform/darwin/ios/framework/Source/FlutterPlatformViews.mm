// Copyright 2018 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <map>
#include <memory>
#include <string>

#include "FlutterPlatformViews_Internal.h"
#include "flutter/fml/platform/darwin/scoped_nsobject.h"
#include "flutter/shell/platform/darwin/ios/framework/Headers/FlutterChannels.h"

namespace shell {

FlutterPlatformViewsController::FlutterPlatformViewsController(
    NSObject<FlutterBinaryMessenger>* messenger,
    FlutterView* flutter_view)
    : flutter_view_([flutter_view retain]) {
  channel_.reset([[FlutterMethodChannel alloc]
         initWithName:@"flutter/platform_views"
      binaryMessenger:messenger
                codec:[FlutterStandardMethodCodec sharedInstance]]);
  [channel_.get() setMethodCallHandler:^(FlutterMethodCall* call, FlutterResult result) {
    OnMethodCall(call, result);
  }];
}

void FlutterPlatformViewsController::OnMethodCall(FlutterMethodCall* call, FlutterResult& result) {
  if ([[call method] isEqualToString:@"create"]) {
    OnCreate(call, result);
  } else if ([[call method] isEqualToString:@"dispose"]) {
    OnDispose(call, result);
  } else {
    result(FlutterMethodNotImplemented);
  }
}

void FlutterPlatformViewsController::OnCreate(FlutterMethodCall* call, FlutterResult& result) {
  NSDictionary<NSString*, id>* args = [call arguments];

  long viewId = [args[@"id"] longValue];
  std::string viewType([args[@"viewType"] UTF8String]);

  if (views_[viewId] != nil) {
    result([FlutterError errorWithCode:@"recreating_view"
                               message:@"trying to create an already created view"
                               details:[NSString stringWithFormat:@"view id: '%ld'", viewId]]);
  }

  NSObject<FlutterPlatformViewFactory>* factory = factories_[viewType].get();
  if (factory == nil) {
    result([FlutterError errorWithCode:@"unregistered_view_type"
                               message:@"trying to create a view with an unregistered type"
                               details:[NSString stringWithFormat:@"unregistered view type: '%@'",
                                                                  args[@"viewType"]]]);
    return;
  }

  // TODO(amirh): decode and pass the creation args.
  views_[viewId] = fml::scoped_nsobject<UIView>([[factory createWithFrame:CGRectZero
                                                           viewIdentifier:viewId
                                                                arguments:nil] retain]);

  FlutterView* flutter_view = flutter_view_.get();
  [flutter_view addSubview:views_[viewId].get()];
  result(nil);
}

void FlutterPlatformViewsController::OnDispose(FlutterMethodCall* call, FlutterResult& result) {
  NSDictionary<NSString*, id>* args = [call arguments];
  int64_t viewId = [args[@"id"] longLongValue];

  if (views_[viewId] == nil) {
    result([FlutterError errorWithCode:@"unknown_view"
                               message:@"trying to dispose an unknown"
                               details:[NSString stringWithFormat:@"view id: '%lld'", viewId]]);
    return;
  }

  UIView* view = views_[viewId].get();
  [view removeFromSuperview];
  views_.erase(viewId);
  result(nil);
}

void FlutterPlatformViewsController::RegisterViewFactory(
    NSObject<FlutterPlatformViewFactory>* factory,
    NSString* factoryId) {
  std::string idString([factoryId UTF8String]);
  FML_CHECK(factories_.count(idString) == 0);
  factories_[idString] =
      fml::scoped_nsobject<NSObject<FlutterPlatformViewFactory>>([factory retain]);
}

void FlutterPlatformViewsController::CompositeEmbeddedView(int view_id,
                                                           const flow::EmbeddedViewParams& params) {
  // TODO(amirh): assert that this is running on the platform thread once we support the iOS
  // embedded views thread configuration.
  // TODO(amirh): do nothing if the params didn't change.
  CGFloat screenScale = [[UIScreen mainScreen] scale];
  CGRect rect =
      CGRectMake(params.offsetPixels.x() / screenScale, params.offsetPixels.y() / screenScale,
                 params.sizePoints.width(), params.sizePoints.height());

  UIView* view = views_[view_id];
  [view setFrame:rect];
}

}  // namespace shell
