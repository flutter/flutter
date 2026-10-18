// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Flutter/Flutter.h>
#import <XCTest/XCTest.h>

FLUTTER_ASSERT_ARC

@interface LocalizationInitializationTest : XCTestCase
@property(nonatomic, strong) XCUIApplication* application;
@end

@implementation LocalizationInitializationTest

- (void)setUp {
  [super setUp];
  self.continueAfterFailure = NO;

  self.application = [[XCUIApplication alloc] init];
  self.application.launchArguments = @[ @"--locale-initialization" ];
  [self.application launch];
}

- (void)testNoLocalePrepend {
  NSTimeInterval timeout = 10.0;

  // The locales received by dart:ui are exposed onBeginFrame via semantics label.
  // The list should consist of the default system locale(s) provided by iOS.
  //
  // The locales iOS reports are of the form `en-CA`. `dart:ui` reports locales
  // in the form `en_CA` and formats them as a list `[first, second, ...]`.
  //
  // Since this test is sensitive to device locale setup, we can't assume any
  // particular locale, or any particular number of locales.
  NSMutableArray<NSString*>* dartLocales = [NSMutableArray array];
  for (NSString* localeIdentifier in [NSLocale preferredLanguages]) {
    [dartLocales addObject:[localeIdentifier stringByReplacingOccurrencesOfString:@"-"
                                                                       withString:@"_"]];
  }
  NSString* expectedIdentifier =
      [NSString stringWithFormat:@"[%@]", [dartLocales componentsJoinedByString:@", "]];
  XCUIElement* textInputSemanticsObject =
      [self.application.textFields matchingIdentifier:expectedIdentifier].element;
  XCTAssertTrue([textInputSemanticsObject waitForExistenceWithTimeout:timeout]);

  [textInputSemanticsObject tap];
}

@end
