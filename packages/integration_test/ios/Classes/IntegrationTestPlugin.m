// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@import UIKit;

#import "IntegrationTestPlugin.h"

static NSString *const kIntegrationTestPluginChannel = @"plugins.flutter.io/integration_test";
static NSString *const kMethodTestFinished = @"allTestsFinished";
static NSString *const kMethodScreenshot = @"captureScreenshot";
static NSString *const kMethodConvertSurfaceToImage = @"convertFlutterSurfaceToImage";
static NSString *const kMethodRevertImage = @"revertFlutterImage";

@interface IntegrationTestPlugin ()

@property(nonatomic, readwrite) NSDictionary<NSString *, NSString *> *testResults;

@end

@implementation IntegrationTestPlugin {
  NSDictionary<NSString *, NSString *> *_testResults;
}

+ (IntegrationTestPlugin *)instance {
  static dispatch_once_t onceToken;
  static IntegrationTestPlugin *sInstance;
  dispatch_once(&onceToken, ^{
    sInstance = [[IntegrationTestPlugin alloc] initForRegistration];
  });
  return sInstance;
}

- (instancetype)initForRegistration {
  return [super init];
}

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
  // No initialization happens here because of the way XCTest loads the testing
  // bundles.  Setup on static variables can be disregarded when a new static
  // instance of IntegrationTestPlugin is allocated when the bundle is reloaded.
  // See also: https://github.com/flutter/plugins/pull/2465
}

- (void)setupChannels:(id<FlutterBinaryMessenger>)binaryMessenger {
  FlutterMethodChannel *channel =
  [FlutterMethodChannel methodChannelWithName:kIntegrationTestPluginChannel
                              binaryMessenger:binaryMessenger];
  [channel setMethodCallHandler:^(FlutterMethodCall *call, FlutterResult result) {
    [self handleMethodCall:call result:result];
  }];
}

- (void)handleMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result {
  if ([call.method isEqualToString:kMethodTestFinished]) {
    self.testResults = call.arguments[@"results"];
    result(nil);
  } else if ([call.method isEqualToString:kMethodScreenshot]) {
    // If running as a native Xcode test, attach to test.
    UIImage *screenshot = [self capturePngScreenshot];
    NSString *name = call.arguments[@"name"];
    [self.screenshotDelegate didTakeScreenshot:screenshot attachmentName:name];

    // Also pass back along the channel for the driver to handle.
    NSData *pngData = UIImagePNGRepresentation(screenshot);
    result([FlutterStandardTypedData typedDataWithBytes:pngData]);
  } else if ([call.method isEqualToString:kMethodConvertSurfaceToImage]
             || [call.method isEqualToString:kMethodRevertImage]) {
    // Android only, no-op on iOS.
    result(nil);
  } else {
    result(FlutterMethodNotImplemented);
  }
}

- (UIImage *)capturePngScreenshot {
  UIWindow *window = [UIApplication.sharedApplication.windows
                      filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"keyWindow = YES"]].firstObject;
  CGRect screenshotBounds = window.bounds;
  UIImage *image;

  if (@available(iOS 10, *)) {
    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithBounds:screenshotBounds];

    image = [renderer imageWithActions:^(UIGraphicsImageRendererContext *rendererContext) {
      [window drawViewHierarchyInRect:screenshotBounds afterScreenUpdates:YES];
    }];
  } else {
    UIGraphicsBeginImageContextWithOptions(screenshotBounds.size, NO, UIScreen.mainScreen.scale);
    [window drawViewHierarchyInRect:screenshotBounds afterScreenUpdates:YES];
    image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
  }

  return image;
}

@end
