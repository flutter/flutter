// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterTextEditingDelta.h"

#import <XCTest/XCTest.h>

#import "flutter/shell/platform/darwin/common/framework/Headers/FlutterMacros.h"

FLUTTER_ASSERT_ARC

@interface FlutterTextEditingDeltaTest : XCTestCase
@end

@implementation FlutterTextEditingDeltaTest

- (void)testTextEditingDeltaConstructor {
  // Here we are simulating inserting an "o" at the end of "hell".
  NSString* oldText = @"hell";
  NSString* replacementText = @"hello";
  NSRange range = NSMakeRange(0, 4);

  FlutterTextEditingDelta* delta = [FlutterTextEditingDelta textEditingDelta:oldText
                                                               replacedRange:range
                                                                 updatedText:replacementText];

  XCTAssertEqual(delta.oldText, oldText);
  XCTAssertEqualObjects(delta.deltaText, @"hello");
  XCTAssertEqual(delta.deltaStart, 0);
  XCTAssertEqual(delta.deltaEnd, 4);
}

- (void)testTextEditingDeltaNonTextConstructor {
  // Here we are simulating inserting an "o" at the end of "hell".
  NSString* oldText = @"hello";

  FlutterTextEditingDelta* delta = [FlutterTextEditingDelta deltaWithNonText:oldText];

  XCTAssertEqual(delta.oldText, oldText);
  XCTAssertEqualObjects(delta.deltaText, @"");
  XCTAssertEqual(delta.deltaStart, -1);
  XCTAssertEqual(delta.deltaEnd, -1);
}

@end
