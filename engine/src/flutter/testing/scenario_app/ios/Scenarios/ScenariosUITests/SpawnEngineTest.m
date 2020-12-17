// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "SpawnEngineTest.h"
#import "GoldenImage.h"

@implementation SpawnEngineTest

- (void)setUp {
  [super setUp];
  self.continueAfterFailure = NO;

  self.application = [[XCUIApplication alloc] init];
  self.application.launchArguments = @[ @"--spawn-engine-works", @"--enable-software-rendering" ];
  [self.application launch];
}

- (void)testSpawnEngineWorks {
  NSString* prefix = @"golden_spawn_engine_works_";
  GoldenImage* golden = [[GoldenImage alloc] initWithGoldenNamePrefix:prefix];
  if (!golden.image) {
    XCTFail(@"unable to find golden image for: %@", prefix);
  }
  XCUIScreenshot* screenshot = [[XCUIScreen mainScreen] screenshot];
  if (![golden compareGoldenToImage:screenshot.image]) {
    XCTAttachment* screenshotAttachment = [XCTAttachment attachmentWithImage:screenshot.image];
    screenshotAttachment.name = [golden.goldenName stringByAppendingString:@"_actual"];
    screenshotAttachment.lifetime = XCTAttachmentLifetimeKeepAlways;
    [self addAttachment:screenshotAttachment];

    XCTFail(@"Goldens do not match. Follow the steps in the "
            @"README to update golden named %@ if needed.",
            golden.goldenName);
  }
}

@end
