// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/fml/logging.h"

#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterPlatformViewController.h"

@implementation FlutterPlatformViewController {
  // NSDictionary maps platform view type identifiers to FlutterPlatformViewFactories.
  NSMutableDictionary<NSString*, NSObject<FlutterPlatformViewFactory>*>* _platformViewFactories;

  // Map from platform view id to the underlying NSView.
  std::map<int, NSView*> _platformViews;

  // View ids that are going to be disposed on the next present call.
  std::unordered_set<int64_t> _platformViewsToDispose;
}

- (instancetype)init {
  self = [super init];
  if (self) {
    _platformViewFactories = [[NSMutableDictionary alloc] init];
  }
  return self;
}

- (void)onCreateWithViewID:(int64_t)viewId
                  viewType:(nonnull NSString*)viewType
                    result:(nonnull FlutterResult)result {
  if (_platformViews.count(viewId) != 0) {
    result([FlutterError errorWithCode:@"recreating_view"
                               message:@"trying to create an already created view"
                               details:[NSString stringWithFormat:@"view id: '%lld'", viewId]]);
    return;
  }

  NSObject<FlutterPlatformViewFactory>* factory = _platformViewFactories[viewType];
  if (!factory) {
    result([FlutterError
        errorWithCode:@"unregistered_view_type"
              message:[NSString stringWithFormat:@"A UIKitView widget is trying to create a "
                                                 @"PlatformView with an unregistered type: < %@ >",
                                                 viewType]
              details:@"If you are the author of the PlatformView, make sure `registerViewFactory` "
                      @"is invoked.\n"
                      @"See: "
                      @"https://docs.flutter.dev/development/platform-integration/"
                      @"platform-views#on-the-platform-side-1 for more details.\n"
                      @"If you are not the author of the PlatformView, make sure to call "
                      @"`GeneratedPluginRegistrant.register`."]);
    return;
  }

  NSView* platform_view = [factory createWithViewIdentifier:viewId arguments:nil];
  _platformViews[viewId] = platform_view;
  result(nil);
}

- (void)onDisposeWithViewID:(int64_t)viewId result:(nonnull FlutterResult)result {
  if (_platformViews.count(viewId) == 0) {
    result([FlutterError errorWithCode:@"unknown_view"
                               message:@"trying to dispose an unknown"
                               details:[NSString stringWithFormat:@"view id: '%lld'", viewId]]);
    return;
  }

  // The following disposePlatformViews call will dispose the views.
  _platformViewsToDispose.insert(viewId);
  result(nil);
}

- (void)registerViewFactory:(nonnull NSObject<FlutterPlatformViewFactory>*)factory
                     withId:(nonnull NSString*)factoryId {
  _platformViewFactories[factoryId] = factory;
}

- (nullable NSView*)platformViewWithID:(int64_t)viewId {
  if (_platformViews.count(viewId)) {
    return _platformViews[viewId];
  } else {
    return nil;
  }
}

- (void)handleMethodCall:(nonnull FlutterMethodCall*)call result:(nonnull FlutterResult)result {
  if ([[call method] isEqualToString:@"create"]) {
    NSMutableDictionary<NSString*, id>* args = [call arguments];
    if ([args objectForKey:@"id"]) {
      int64_t viewId = [args[@"id"] longValue];
      NSString* viewType = [NSString stringWithUTF8String:([args[@"viewType"] UTF8String])];
      [self onCreateWithViewID:viewId viewType:viewType result:result];
    } else {
      result([FlutterError errorWithCode:@"unknown_view"
                                 message:@"'id' argument must be passed to create a platform view."
                                 details:[NSString stringWithFormat:@"'id' not specified."]]);
    }
  } else if ([[call method] isEqualToString:@"dispose"]) {
    NSNumber* arg = [call arguments];
    int64_t viewId = [arg longValue];
    [self onDisposeWithViewID:viewId result:result];
  } else {
    result(FlutterMethodNotImplemented);
  }
}

- (void)disposePlatformViews {
  if (_platformViewsToDispose.empty()) {
    return;
  }

  FML_DCHECK([[NSThread currentThread] isMainThread])
      << "Must be on the main thread to handle disposing platform views";
  for (int64_t viewId : _platformViewsToDispose) {
    NSView* view = _platformViews[viewId];
    [view removeFromSuperview];
    _platformViews.erase(viewId);
  }
  _platformViewsToDispose.clear();
}

@end
