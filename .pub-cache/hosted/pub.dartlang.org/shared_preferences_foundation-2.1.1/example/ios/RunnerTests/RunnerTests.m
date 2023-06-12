// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@import shared_preferences_foundation;
@import XCTest;

@interface SharedPreferencesTests : XCTestCase
@end

@implementation SharedPreferencesTests

- (void)testPlugin {
  SharedPreferencesPlugin *plugin = [[SharedPreferencesPlugin alloc] init];
  XCTAssertNotNil(plugin);
}

@end
