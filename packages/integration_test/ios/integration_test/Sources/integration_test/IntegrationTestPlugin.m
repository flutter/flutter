// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "IntegrationTestPlugin.h"

@import UIKit;

static NSString *const kIntegrationTestPluginChannel = @"plugins.flutter.io/integration_test";
static NSString *const kMethodTestFinished = @"allTestsFinished";
static NSString *const kMethodScreenshot = @"captureScreenshot";
static NSString *const kMethodConvertSurfaceToImage = @"convertFlutterSurfaceToImage";
static NSString *const kMethodRevertImage = @"revertFlutterImage";

@interface IntegrationTestPlugin ()

@property(nonatomic, readwrite) NSDictionary<NSString *, NSString *> *testResults;

- (instancetype)init NS_DESIGNATED_INITIALIZER;

@end

@implementation IntegrationTestPlugin {
  NSDictionary<NSString *, NSString *> *_testResults;
  NSMutableDictionary<NSString *, UIImage *> *_capturedScreenshotsByName;
}

+ (instancetype)instance {
  static dispatch_once_t onceToken;
  static IntegrationTestPlugin *sInstance;
  dispatch_once(&onceToken, ^{
    sInstance = [[IntegrationTestPlugin alloc] initForRegistration];
  });
  return sInstance;
}

- (instancetype)initForRegistration {
  return [self init];
}

- (instancetype)init {
  self = [super init];
  _capturedScreenshotsByName = [NSMutableDictionary new];
  return self;
}

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
  FlutterMethodChannel *channel = [FlutterMethodChannel methodChannelWithName:kIntegrationTestPluginChannel
                                                              binaryMessenger:registrar.messenger];
  [registrar addMethodCallDelegate:[self instance] channel:channel];
}

/// Handle method calls from Dart code:
/// - allTestsFinished: Populate NSString* testResults property with a string summary of test run.
/// - captureScreenshot: Capture a screenshot. Populate capturedScreenshotsByName["name"] with image.
/// - convertSurfaceToImage: Android-only. Not implemented on iOS.
/// - revertFlutterImage: Android-only. Not implemented on iOS.
- (void)handleMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result {
  if ([call.method isEqualToString:kMethodTestFinished]) {
    self.testResults = call.arguments[@"results"];
    result(nil);
  } else if ([call.method isEqualToString:kMethodScreenshot]) {
    // If running as a native Xcode test, attach to test.
    UIImage *screenshot = [self capturePngScreenshot];
    NSString *name = call.arguments[@"name"];
    _capturedScreenshotsByName[name] = screenshot;

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
  // Get all windows in the app
  NSArray<UIWindow *> *windows = [UIApplication sharedApplication].windows;

  // Find the overall bounding rect for all windows
  CGRect screenBounds = [UIScreen mainScreen].bounds;

  UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithBounds:screenBounds];
  UIImage *screenshot =
      [renderer imageWithActions:^(UIGraphicsImageRendererContext *_Nonnull rendererContext) {
        for (UIWindow *window in windows) {
          if (!window.hidden) {  // Render only visible windows
            [window drawViewHierarchyInRect:window.frame afterScreenUpdates:YES];
          }
        }
      }];

  return screenshot;
}

@end
