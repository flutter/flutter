// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <FlutterMacOS/FlutterMacOS.h>
#import <XCTest/XCTest.h>

@interface RunnerTests : XCTestCase
@end

@implementation RunnerTests

- (void)testMenu {
  NSMenu *applicationMenu = ((FlutterAppDelegate *)NSApplication.sharedApplication.delegate).applicationMenu;
  XCTAssertEqual(applicationMenu.numberOfItems, 11);
  XCTAssertEqualObjects([applicationMenu itemAtIndex:0].title, @"About flutter_gallery");

  NSMenu *mainMenu = NSApplication.sharedApplication.mainMenu;
  XCTAssertEqual([mainMenu indexOfItemWithSubmenu:applicationMenu], 0);

  XCTAssertEqual([mainMenu itemWithTitle:@"Edit"].submenu.numberOfItems, 19);
  XCTAssertEqual([mainMenu itemWithTitle:@"View"].submenu.numberOfItems, 1);
  XCTAssertEqual([mainMenu itemWithTitle:@"Window"].submenu.numberOfItems, 6);

  XCTAssertNil(NSApplication.sharedApplication.helpMenu);
}

@end
