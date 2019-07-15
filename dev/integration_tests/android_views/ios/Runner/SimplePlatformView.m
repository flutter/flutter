// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "SimplePlatformView.h"

@interface SimplePlatformView()

@property (strong, nonatomic) UIView *view;
@property (assign, nonatomic) int64_t viewId;
@property (strong, nonatomic) FlutterMethodChannel* channel;

@end

@implementation SimplePlatformView

- (instancetype)initWithFrame:(CGRect)frame
               viewIdentifier:(int64_t)viewId
                    arguments:(id _Nullable)args
                    registrar:(NSObject<FlutterPluginRegistrar>*)registrar
{
  self = [super init];
  if (self) {
    self.view = [[UIView alloc] initWithFrame:frame];
    self.view.backgroundColor = [UIColor blueColor];
    NSString* channelName =
    [NSString stringWithFormat:@"simple_view/%lld", viewId];
    self.channel = [FlutterMethodChannel methodChannelWithName:channelName
                                               binaryMessenger:registrar.messenger];
    __weak __typeof__(self) weakSelf = self;
    [self.channel setMethodCallHandler:^(FlutterMethodCall* call, FlutterResult result) {
      if (weakSelf) {
        [weakSelf onMethodCall:call result:result];
      }
    }];
  }
  return self;
}

- (UIView *)view {
  return self.view;
}

- (void)onMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
  result(FlutterMethodNotImplemented);
}

@end

@interface SimplePlatformViewFactory()

@property (weak, nonatomic) NSObject<FlutterPluginRegistrar> *registrar;

@end

@implementation SimplePlatformViewFactory

- (instancetype)initWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
  self = [super init];
  if (self) {
    self.registrar = registrar;
  }
  return self;
}

- (nonnull NSObject<FlutterPlatformView> *)createWithFrame:(CGRect)frame viewIdentifier:(int64_t)viewId arguments:(id _Nullable)args {
  SimplePlatformView *platformView = [[SimplePlatformView alloc] initWithFrame:frame viewIdentifier:viewId arguments:args registrar:self.registrar];
  return platformView;
}

@end

