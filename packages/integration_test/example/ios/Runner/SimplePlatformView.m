// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "SimplePlatformView.h"

@implementation SimplePlatformViewFactory {
  NSObject<FlutterBinaryMessenger>* _messenger;
}

- (instancetype _Nullable)initWithMessenger:(NSObject<FlutterBinaryMessenger>* _Nonnull)messenger {
  if (self = [super init]) {
    _messenger = messenger;
  }
  return self;
}

- (nonnull NSObject<FlutterPlatformView>*)createWithFrame:(CGRect)frame
                                           viewIdentifier:(int64_t)viewId
                                                arguments:(id _Nullable)args {
  return [[SimplePlatformView alloc] initWithFrame:frame
                                    viewIdentifier:viewId
                                         arguments:args
                                   binaryMessenger:_messenger];
}

- (NSObject<FlutterMessageCodec>*)createArgsCodec {
  return [FlutterStandardMessageCodec sharedInstance];
}

@end

@implementation SimplePlatformView {
  UIView* _view;
}

- (instancetype _Nullable)initWithFrame:(CGRect)frame
                         viewIdentifier:(int64_t)viewId
                              arguments:(id _Nullable)args
                        binaryMessenger:(NSObject<FlutterBinaryMessenger>* _Nonnull)messenger {
  if (self = [super init]) {
    _view = [[UIView alloc] initWithFrame:frame];
    _view.backgroundColor = UIColor.blueColor;
  }
  return self;
}

- (UIView* _Nonnull)view {
  return _view;
}

@end
