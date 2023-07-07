// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@import path_provider_ios;
@import XCTest;

@interface PathProviderTests : XCTestCase
@end

@implementation PathProviderTests

- (void)testPlugin {
  FLTPathProviderPlugin *plugin = [[FLTPathProviderPlugin alloc] init];
  XCTAssertNotNil(plugin);
}

@end
