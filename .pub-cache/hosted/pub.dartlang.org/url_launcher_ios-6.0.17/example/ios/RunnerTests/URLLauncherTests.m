// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@import url_launcher_ios;
@import XCTest;

@interface URLLauncherTests : XCTestCase
@end

@implementation URLLauncherTests

- (void)testPlugin {
  FLTURLLauncherPlugin *plugin = [[FLTURLLauncherPlugin alloc] init];
  XCTAssertNotNil(plugin);
}

@end
