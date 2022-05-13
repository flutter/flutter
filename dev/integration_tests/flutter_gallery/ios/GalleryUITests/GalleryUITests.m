// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <XCTest/XCTest.h>

@interface GalleryUITests : XCTestCase
@property (strong) XCUIApplication *app;
@end

@implementation GalleryUITests

- (void)setUp {
    self.continueAfterFailure = NO;

    XCUIApplication *app = [[XCUIApplication alloc] init];
    [app launch];
    self.app = app;
}

- (void)testLaunch {
    // Basic smoke test that the app launched and any element was loaded.
    XCTAssertTrue([self.app.otherElements.firstMatch waitForExistenceWithTimeout:60.0]);
}

@end
