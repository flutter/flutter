// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>
#import <OCMock/OCMock.h>

#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterKeyboardManager.h"
#import "flutter/testing/testing.h"
#include "third_party/googletest/googletest/include/gtest/gtest.h"

@interface FlutterKeyboardManagerUnittestsObjC : NSObject
- (bool)nextResponderShouldThrowOnKeyUp;
- (bool)singlePrimaryResponder;
- (bool)doublePrimaryResponder;
- (bool)singleSecondaryResponder;
- (bool)emptyNextResponder;
@end

namespace flutter::testing {

namespace {

NSEvent* keyDownEvent(unsigned short keyCode) {
  return [NSEvent keyEventWithType:NSEventTypeKeyDown
                          location:NSZeroPoint
                     modifierFlags:0x100
                         timestamp:0
                      windowNumber:0
                           context:nil
                        characters:@""
       charactersIgnoringModifiers:@""
                         isARepeat:NO
                           keyCode:keyCode];
}

NSEvent* keyUpEvent(unsigned short keyCode) {
  return [NSEvent keyEventWithType:NSEventTypeKeyUp
                          location:NSZeroPoint
                     modifierFlags:0x100
                         timestamp:0
                      windowNumber:0
                           context:nil
                        characters:@""
       charactersIgnoringModifiers:@""
                         isARepeat:NO
                           keyCode:keyCode];
}

id checkKeyDownEvent(unsigned short keyCode) {
  return [OCMArg checkWithBlock:^BOOL(id value) {
    if (![value isKindOfClass:[NSEvent class]]) {
      return NO;
    }
    NSEvent* event = value;
    return event.keyCode == keyCode;
  }];
}

NSResponder* mockOwnerWithDownOnlyNext() {
  NSResponder* nextResponder = OCMStrictClassMock([NSResponder class]);
  OCMStub([nextResponder keyDown:[OCMArg any]]).andDo(nil);
  // The nextResponder is a strict mock and hasn't stubbed keyUp.
  // An error will be thrown on keyUp.

  NSResponder* owner = OCMStrictClassMock([NSResponder class]);
  OCMStub([owner nextResponder]).andReturn(nextResponder);
  return owner;
}

typedef void (^KeyCallbackSetter)(FlutterAsyncKeyCallback callback);
typedef BOOL (^BoolGetter)();

id<FlutterKeyPrimaryResponder> mockPrimaryResponder(KeyCallbackSetter callbackSetter) {
  id<FlutterKeyPrimaryResponder> mock =
      OCMStrictProtocolMock(@protocol(FlutterKeyPrimaryResponder));
  OCMStub([mock handleEvent:[OCMArg any] callback:[OCMArg any]])
      .andDo((^(NSInvocation* invocation) {
        FlutterAsyncKeyCallback callback;
        [invocation getArgument:&callback atIndex:3];
        callbackSetter(callback);
      }));
  return mock;
}

id<FlutterKeySecondaryResponder> mockSecondaryResponder(BoolGetter resultGetter) {
  id<FlutterKeySecondaryResponder> mock =
      OCMStrictProtocolMock(@protocol(FlutterKeySecondaryResponder));
  OCMStub([mock handleKeyEvent:[OCMArg any]]).andDo((^(NSInvocation* invocation) {
    BOOL result = resultGetter();
    [invocation setReturnValue:&result];
  }));
  return mock;
}

}  // namespace

TEST(FlutterKeyboardManagerUnittests, NextResponderShouldThrowOnKeyUp) {
  ASSERT_TRUE([[FlutterKeyboardManagerUnittestsObjC alloc] nextResponderShouldThrowOnKeyUp]);
}

TEST(FlutterKeyboardManagerUnittests, SinglePrimaryResponder) {
  ASSERT_TRUE([[FlutterKeyboardManagerUnittestsObjC alloc] singlePrimaryResponder]);
}

TEST(FlutterKeyboardManagerUnittests, DoublePrimaryResponder) {
  ASSERT_TRUE([[FlutterKeyboardManagerUnittestsObjC alloc] doublePrimaryResponder]);
}

TEST(FlutterKeyboardManagerUnittests, SingleFinalResponder) {
  ASSERT_TRUE([[FlutterKeyboardManagerUnittestsObjC alloc] singleSecondaryResponder]);
}

TEST(FlutterKeyboardManagerUnittests, EmptyNextResponder) {
  ASSERT_TRUE([[FlutterKeyboardManagerUnittestsObjC alloc] emptyNextResponder]);
}

}  // namespace flutter::testing

@implementation FlutterKeyboardManagerUnittestsObjC

// Verify that the nextResponder returned from mockOwnerWithDownOnlyNext()
// throws exception when keyUp is called.
- (bool)nextResponderShouldThrowOnKeyUp {
  NSResponder* owner = flutter::testing::mockOwnerWithDownOnlyNext();
  @try {
    [owner.nextResponder keyUp:flutter::testing::keyUpEvent(0x50)];
    return false;
  } @catch (...) {
    return true;
  }
}

- (bool)singlePrimaryResponder {
  NSResponder* owner = flutter::testing::mockOwnerWithDownOnlyNext();
  FlutterKeyboardManager* manager = [[FlutterKeyboardManager alloc] initWithOwner:owner];

  __block NSMutableArray<FlutterAsyncKeyCallback>* callbacks =
      [NSMutableArray<FlutterAsyncKeyCallback> array];
  [manager addPrimaryResponder:flutter::testing::mockPrimaryResponder(
                                   ^(FlutterAsyncKeyCallback callback) {
                                     [callbacks addObject:callback];
                                   })];

  // Case: The responder reports FALSE
  [manager handleEvent:flutter::testing::keyDownEvent(0x50)];
  EXPECT_EQ([callbacks count], 1u);
  callbacks[0](FALSE);
  OCMVerify([owner.nextResponder keyDown:flutter::testing::checkKeyDownEvent(0x50)]);
  [callbacks removeAllObjects];

  // Case: The responder reports TRUE
  [manager handleEvent:flutter::testing::keyUpEvent(0x50)];
  EXPECT_EQ([callbacks count], 1u);
  callbacks[0](TRUE);
  // [owner.nextResponder keyUp:] should not be called, otherwise an error will be thrown.

  return true;
}

- (bool)doublePrimaryResponder {
  NSResponder* owner = flutter::testing::mockOwnerWithDownOnlyNext();
  FlutterKeyboardManager* manager = [[FlutterKeyboardManager alloc] initWithOwner:owner];

  __block NSMutableArray<FlutterAsyncKeyCallback>* callbacks1 =
      [NSMutableArray<FlutterAsyncKeyCallback> array];
  [manager addPrimaryResponder:flutter::testing::mockPrimaryResponder(
                                   ^(FlutterAsyncKeyCallback callback) {
                                     [callbacks1 addObject:callback];
                                   })];

  __block NSMutableArray<FlutterAsyncKeyCallback>* callbacks2 =
      [NSMutableArray<FlutterAsyncKeyCallback> array];
  [manager addPrimaryResponder:flutter::testing::mockPrimaryResponder(
                                   ^(FlutterAsyncKeyCallback callback) {
                                     [callbacks2 addObject:callback];
                                   })];

  // Case: Both responder report TRUE.
  [manager handleEvent:flutter::testing::keyUpEvent(0x50)];
  EXPECT_EQ([callbacks1 count], 1u);
  EXPECT_EQ([callbacks2 count], 1u);
  callbacks1[0](TRUE);
  callbacks2[0](TRUE);
  EXPECT_EQ([callbacks1 count], 1u);
  EXPECT_EQ([callbacks2 count], 1u);
  // [owner.nextResponder keyUp:] should not be called, otherwise an error will be thrown.
  [callbacks1 removeAllObjects];
  [callbacks2 removeAllObjects];

  // Case: One responder reports TRUE.
  [manager handleEvent:flutter::testing::keyUpEvent(0x50)];
  EXPECT_EQ([callbacks1 count], 1u);
  EXPECT_EQ([callbacks2 count], 1u);
  callbacks1[0](FALSE);
  callbacks2[0](TRUE);
  EXPECT_EQ([callbacks1 count], 1u);
  EXPECT_EQ([callbacks2 count], 1u);
  // [owner.nextResponder keyUp:] should not be called, otherwise an error will be thrown.
  [callbacks1 removeAllObjects];
  [callbacks2 removeAllObjects];

  // Case: Both responders report FALSE.
  [manager handleEvent:flutter::testing::keyDownEvent(0x50)];
  EXPECT_EQ([callbacks1 count], 1u);
  EXPECT_EQ([callbacks2 count], 1u);
  callbacks1[0](FALSE);
  callbacks2[0](FALSE);
  EXPECT_EQ([callbacks1 count], 1u);
  EXPECT_EQ([callbacks2 count], 1u);
  OCMVerify([owner.nextResponder keyDown:flutter::testing::checkKeyDownEvent(0x50)]);
  [callbacks1 removeAllObjects];
  [callbacks2 removeAllObjects];

  return true;
}

- (bool)singleSecondaryResponder {
  NSResponder* owner = flutter::testing::mockOwnerWithDownOnlyNext();
  FlutterKeyboardManager* manager = [[FlutterKeyboardManager alloc] initWithOwner:owner];

  __block NSMutableArray<FlutterAsyncKeyCallback>* callbacks =
      [NSMutableArray<FlutterAsyncKeyCallback> array];
  [manager addPrimaryResponder:flutter::testing::mockPrimaryResponder(
                                   ^(FlutterAsyncKeyCallback callback) {
                                     [callbacks addObject:callback];
                                   })];

  __block BOOL nextResponse;
  [manager addSecondaryResponder:flutter::testing::mockSecondaryResponder(^() {
             return nextResponse;
           })];

  // Case: Primary responder responds TRUE. The event shouldn't be handled by
  // the secondary responder.
  nextResponse = FALSE;
  [manager handleEvent:flutter::testing::keyUpEvent(0x50)];
  EXPECT_EQ([callbacks count], 1u);
  callbacks[0](TRUE);
  // [owner.nextResponder keyUp:] should not be called, otherwise an error will be thrown.
  [callbacks removeAllObjects];

  // Case: Primary responder responds FALSE. The secondary responder returns
  // TRUE.
  nextResponse = TRUE;
  [manager handleEvent:flutter::testing::keyUpEvent(0x50)];
  EXPECT_EQ([callbacks count], 1u);
  callbacks[0](FALSE);
  // [owner.nextResponder keyUp:] should not be called, otherwise an error will be thrown.
  [callbacks removeAllObjects];

  // Case: Primary responder responds FALSE. The secondary responder returns FALSE.
  nextResponse = FALSE;
  [manager handleEvent:flutter::testing::keyDownEvent(0x50)];
  EXPECT_EQ([callbacks count], 1u);
  callbacks[0](FALSE);
  OCMVerify([owner.nextResponder keyDown:flutter::testing::checkKeyDownEvent(0x50)]);
  [callbacks removeAllObjects];

  return true;
}

- (bool)emptyNextResponder {
  NSResponder* owner = OCMStrictClassMock([NSResponder class]);
  OCMStub([owner nextResponder]).andReturn(nil);

  FlutterKeyboardManager* manager = [[FlutterKeyboardManager alloc] initWithOwner:owner];

  [manager addPrimaryResponder:flutter::testing::mockPrimaryResponder(
                                   ^(FlutterAsyncKeyCallback callback) {
                                     callback(FALSE);
                                   })];
  // Passes if no error is thrown.
  return true;
}

@end
