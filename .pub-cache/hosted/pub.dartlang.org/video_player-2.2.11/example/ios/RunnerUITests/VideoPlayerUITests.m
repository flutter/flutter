// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@import os.log;
@import XCTest;

@interface VideoPlayerUITests : XCTestCase
@property(nonatomic, strong) XCUIApplication* app;
@end

@implementation VideoPlayerUITests

- (void)setUp {
  self.continueAfterFailure = NO;

  self.app = [[XCUIApplication alloc] init];
  [self.app launch];
}

- (void)testPlayVideo {
  XCUIApplication* app = self.app;

  XCUIElement* remoteTab = [app.otherElements
      elementMatchingPredicate:[NSPredicate predicateWithFormat:@"selected == YES"]];
  XCTAssertTrue([remoteTab waitForExistenceWithTimeout:30.0]);
  XCTAssertTrue([remoteTab.label containsString:@"Remote"]);

  XCUIElement* playButton = app.staticTexts[@"Play"];
  XCTAssertTrue([playButton waitForExistenceWithTimeout:30.0]);
  [playButton tap];

  XCUIElement* chirpClosedCaption = app.staticTexts[@"[ Birds chirping ]"];
  XCTAssertTrue([chirpClosedCaption waitForExistenceWithTimeout:30.0]);

  XCUIElement* buzzClosedCaption = app.staticTexts[@"[ Buzzing ]"];
  XCTAssertTrue([buzzClosedCaption waitForExistenceWithTimeout:30.0]);

  XCUIElement* playbackSpeed1x = app.staticTexts[@"Playback speed\n1.0x"];
  XCTAssertTrue([playbackSpeed1x waitForExistenceWithTimeout:30.0]);
  [playbackSpeed1x tap];

  XCUIElement* playbackSpeed5xButton = app.buttons[@"5.0x"];
  XCTAssertTrue([playbackSpeed5xButton waitForExistenceWithTimeout:30.0]);
  [playbackSpeed5xButton tap];

  XCUIElement* playbackSpeed5x = app.staticTexts[@"Playback speed\n5.0x"];
  XCTAssertTrue([playbackSpeed5x waitForExistenceWithTimeout:30.0]);

  // Cycle through tabs.
  for (NSString* tabName in @[ @"Asset", @"List example" ]) {
    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"label BEGINSWITH %@", tabName];
    XCUIElement* unselectedTab = [app.staticTexts elementMatchingPredicate:predicate];
    XCTAssertTrue([unselectedTab waitForExistenceWithTimeout:30.0]);
    XCTAssertFalse(unselectedTab.isSelected);
    [unselectedTab tap];

    XCUIElement* selectedTab = [app.otherElements
        elementMatchingPredicate:[NSPredicate predicateWithFormat:@"label BEGINSWITH %@", tabName]];
    XCTAssertTrue([selectedTab waitForExistenceWithTimeout:30.0]);
    XCTAssertTrue(selectedTab.isSelected);
  }
}

@end
