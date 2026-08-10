// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "GoldenTestManager.h"
#import <XCTest/XCTest.h>

@interface GoldenTestManager ()

@property(readwrite, strong, nonatomic) GoldenImage* goldenImage;

@end

@implementation GoldenTestManager

const double kDefaultRmseThreshold = 0.5;

- (instancetype)initWithLaunchArg:(NSString*)launchArg {
  self = [super init];
  if (self) {
    // We derive the golden identifier from the launch argument:
    // * drop the leading "--"
    // * swap "-" for "_"
    // The SceneDelegate Dart scenario name is derived exactly the same way.
    _identifier = [[launchArg substringFromIndex:2] stringByReplacingOccurrencesOfString:@"-"
                                                                              withString:@"_"];

    NSString* impeller = @"impeller_";
    NSNumber* enableImpeller = [[NSBundle bundleWithIdentifier:@"dev.flutter.Scenarios"]
        objectForInfoDictionaryKey:@"FLTEnableImpeller"];
    if (enableImpeller != nil && !enableImpeller.boolValue) {
      impeller = @"";
      NSLog(@"Testing Skia: FLTEnableImpeller is NO");
    } else {
      NSLog(@"Testing Impeller");
    }

    NSString* prefix = [NSString stringWithFormat:@"golden_%@_%@", _identifier, impeller];
    _goldenImage = [[GoldenImage alloc] initWithGoldenNamePrefix:prefix];
    _launchArg = launchArg;
  }
  return self;
}

- (void)checkGoldenForTest:(XCTestCase*)test rmesThreshold:(double)rmesThreshold {
  XCUIScreenshot* screenshot = [[XCUIScreen mainScreen] screenshot];
  if (!_goldenImage.image) {
    XCTAttachment* attachment = [XCTAttachment attachmentWithScreenshot:screenshot];
    attachment.name = [_goldenImage.goldenName stringByAppendingString:@"_new.png"];
    attachment.lifetime = XCTAttachmentLifetimeKeepAlways;
    [test addAttachment:attachment];
    // Instead of XCTFail because that definition changed between Xcode 11 and 12 whereas this impl
    // is stable.
    _XCTPrimitiveFail(test,
                      @"This test will fail - no golden named %@ found. "
                      @"Follow the steps in the README to add a new golden.",
                      _goldenImage.goldenName);
  }

  if (![_goldenImage compareGoldenToImage:screenshot.image rmesThreshold:rmesThreshold]) {
    XCTAttachment* screenshotAttachment = [XCTAttachment attachmentWithImage:screenshot.image];
    screenshotAttachment.name = [_goldenImage.goldenName stringByAppendingString:@"_actual.png"];
    screenshotAttachment.lifetime = XCTAttachmentLifetimeKeepAlways;
    [test addAttachment:screenshotAttachment];

    _XCTPrimitiveFail(test,
                      @"Goldens do not match. Follow the steps in the "
                      @"README to update golden named %@ if needed.",
                      _goldenImage.goldenName);
  }
}

@end
