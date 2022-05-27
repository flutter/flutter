// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Foundation/NSString.h>
#import <OCMock/OCMock.h>

#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterDartProject_Internal.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterViewController_Internal.h"
#import "flutter/testing/testing.h"

namespace flutter::testing {

// Returns a mock FlutterViewController.
id CreateMockViewController();

}  // namespace flutter::testing
