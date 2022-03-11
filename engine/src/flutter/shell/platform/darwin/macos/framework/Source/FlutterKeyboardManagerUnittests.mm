// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>
#import <OCMock/OCMock.h>

#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterEngine_Internal.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterKeyPrimaryResponder.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterKeyboardManager.h"
#import "flutter/testing/testing.h"
#include "third_party/googletest/googletest/include/gtest/gtest.h"

namespace {

typedef BOOL (^BoolGetter)();
typedef void (^AsyncKeyCallback)(BOOL handled);
typedef void (^AsyncKeyCallbackHandler)(AsyncKeyCallback callback);

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

}  // namespace

@interface KeyboardTester : NSObject
- (nonnull instancetype)init;
- (void)respondEmbedderCallsWith:(BOOL)response;
- (void)recordEmbedderCallsTo:(nonnull NSMutableArray<FlutterAsyncKeyCallback>*)storage;
- (void)respondChannelCallsWith:(BOOL)response;
- (void)recordChannelCallsTo:(nonnull NSMutableArray<FlutterAsyncKeyCallback>*)storage;

@property(nonatomic) FlutterKeyboardManager* manager;
@property(nonatomic) NSResponder* nextResponder;

#pragma mark - Private

- (void)handleEmbedderEvent:(const FlutterKeyEvent&)event
                   callback:(nullable FlutterKeyEventCallback)callback
                   userData:(nullable void*)userData;

- (void)handleChannelMessage:(NSString*)channel
                     message:(NSData* _Nullable)message
                 binaryReply:(FlutterBinaryReply _Nullable)callback;

- (BOOL)handleTextInputKeyEvent:(NSEvent*)event;
@end

@implementation KeyboardTester {
  AsyncKeyCallbackHandler _embedderHandler;
  AsyncKeyCallbackHandler _channelHandler;
  BOOL _textInputResponse;
}

- (nonnull instancetype)init {
  self = [super init];
  if (self == nil) {
    return nil;
  }

  _nextResponder = OCMClassMock([NSResponder class]);
  [self respondChannelCallsWith:FALSE];
  [self respondEmbedderCallsWith:FALSE];
  [self respondTextInputWith:FALSE];

  id messengerMock = OCMStrictProtocolMock(@protocol(FlutterBinaryMessenger));
  OCMStub([messengerMock sendOnChannel:@"flutter/keyevent"
                               message:[OCMArg any]
                           binaryReply:[OCMArg any]])
      .andCall(self, @selector(handleChannelMessage:message:binaryReply:));

  id viewDelegateMock = OCMStrictProtocolMock(@protocol(FlutterKeyboardViewDelegate));
  OCMStub([viewDelegateMock nextResponder]).andReturn(_nextResponder);
  OCMStub([viewDelegateMock onTextInputKeyEvent:[OCMArg any]])
      .andCall(self, @selector(handleTextInputKeyEvent:));
  OCMStub([viewDelegateMock getBinaryMessenger]).andReturn(messengerMock);
  OCMStub([viewDelegateMock sendKeyEvent:FlutterKeyEvent {} callback:nil userData:nil])
      .ignoringNonObjectArgs()
      .andCall(self, @selector(handleEmbedderEvent:callback:userData:));

  _manager = [[FlutterKeyboardManager alloc] initWithViewDelegate:viewDelegateMock];
  return self;
}

- (void)respondEmbedderCallsWith:(BOOL)response {
  _embedderHandler = ^(AsyncKeyCallback callback) {
    callback(response);
  };
}

- (void)recordEmbedderCallsTo:(nonnull NSMutableArray<FlutterAsyncKeyCallback>*)storage {
  _embedderHandler = ^(AsyncKeyCallback callback) {
    [storage addObject:callback];
  };
}

- (void)respondChannelCallsWith:(BOOL)response {
  _channelHandler = ^(AsyncKeyCallback callback) {
    callback(response);
  };
}

- (void)recordChannelCallsTo:(nonnull NSMutableArray<FlutterAsyncKeyCallback>*)storage {
  _channelHandler = ^(AsyncKeyCallback callback) {
    [storage addObject:callback];
  };
}

- (void)respondTextInputWith:(BOOL)response {
  _textInputResponse = response;
}

#pragma mark - Private

- (void)handleEmbedderEvent:(const FlutterKeyEvent&)event
                   callback:(nullable FlutterKeyEventCallback)callback
                   userData:(nullable void*)userData {
  if (callback != nullptr) {
    _embedderHandler(^(BOOL handled) {
      callback(handled, userData);
    });
  }
}

- (void)handleChannelMessage:(NSString*)channel
                     message:(NSData* _Nullable)message
                 binaryReply:(FlutterBinaryReply _Nullable)callback {
  _channelHandler(^(BOOL handled) {
    NSDictionary* result = @{
      @"handled" : @(handled),
    };
    NSData* encodedKeyEvent = [[FlutterJSONMessageCodec sharedInstance] encode:result];
    callback(encodedKeyEvent);
  });
}

- (BOOL)handleTextInputKeyEvent:(NSEvent*)event {
  return _textInputResponse;
}

@end

@interface FlutterKeyboardManagerUnittestsObjC : NSObject
- (bool)nextResponderShouldThrowOnKeyUp;
- (bool)singlePrimaryResponder;
- (bool)doublePrimaryResponder;
- (bool)textInputPlugin;
- (bool)emptyNextResponder;
@end

namespace flutter::testing {
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
  ASSERT_TRUE([[FlutterKeyboardManagerUnittestsObjC alloc] textInputPlugin]);
}

TEST(FlutterKeyboardManagerUnittests, EmptyNextResponder) {
  ASSERT_TRUE([[FlutterKeyboardManagerUnittestsObjC alloc] emptyNextResponder]);
}

}  // namespace flutter::testing

@implementation FlutterKeyboardManagerUnittestsObjC

// Verify that the nextResponder returned from mockOwnerWithDownOnlyNext()
// throws exception when keyUp is called.
- (bool)nextResponderShouldThrowOnKeyUp {
  NSResponder* owner = mockOwnerWithDownOnlyNext();
  @try {
    [owner.nextResponder keyUp:keyUpEvent(0x50)];
    return false;
  } @catch (...) {
    return true;
  }
}

- (bool)singlePrimaryResponder {
  KeyboardTester* tester = [[KeyboardTester alloc] init];
  NSMutableArray<FlutterAsyncKeyCallback>* embedderCallbacks =
      [NSMutableArray<FlutterAsyncKeyCallback> array];
  [tester recordEmbedderCallsTo:embedderCallbacks];

  // Case: The responder reports FALSE
  [tester.manager handleEvent:keyDownEvent(0x50)];
  EXPECT_EQ([embedderCallbacks count], 1u);
  embedderCallbacks[0](FALSE);
  OCMVerify([tester.nextResponder keyDown:checkKeyDownEvent(0x50)]);
  [embedderCallbacks removeAllObjects];

  // Case: The responder reports TRUE
  [tester.manager handleEvent:keyUpEvent(0x50)];
  EXPECT_EQ([embedderCallbacks count], 1u);
  embedderCallbacks[0](TRUE);
  // [owner.nextResponder keyUp:] should not be called, otherwise an error will be thrown.

  return true;
}

- (bool)doublePrimaryResponder {
  KeyboardTester* tester = [[KeyboardTester alloc] init];

  // Send a down event first so we can send an up event later.
  [tester respondEmbedderCallsWith:false];
  [tester respondChannelCallsWith:false];
  [tester.manager handleEvent:keyDownEvent(0x50)];

  NSMutableArray<FlutterAsyncKeyCallback>* embedderCallbacks =
      [NSMutableArray<FlutterAsyncKeyCallback> array];
  NSMutableArray<FlutterAsyncKeyCallback>* channelCallbacks =
      [NSMutableArray<FlutterAsyncKeyCallback> array];
  [tester recordEmbedderCallsTo:embedderCallbacks];
  [tester recordChannelCallsTo:channelCallbacks];

  // Case: Both responders report TRUE.
  [tester.manager handleEvent:keyUpEvent(0x50)];
  EXPECT_EQ([embedderCallbacks count], 1u);
  EXPECT_EQ([channelCallbacks count], 1u);
  embedderCallbacks[0](TRUE);
  channelCallbacks[0](TRUE);
  EXPECT_EQ([embedderCallbacks count], 1u);
  EXPECT_EQ([channelCallbacks count], 1u);
  // [tester.nextResponder keyUp:] should not be called, otherwise an error will be thrown.
  [embedderCallbacks removeAllObjects];
  [channelCallbacks removeAllObjects];

  // Case: One responder reports TRUE.
  [tester respondEmbedderCallsWith:false];
  [tester respondChannelCallsWith:false];
  [tester.manager handleEvent:keyDownEvent(0x50)];

  [tester recordEmbedderCallsTo:embedderCallbacks];
  [tester recordChannelCallsTo:channelCallbacks];
  [tester.manager handleEvent:keyUpEvent(0x50)];
  EXPECT_EQ([embedderCallbacks count], 1u);
  EXPECT_EQ([channelCallbacks count], 1u);
  embedderCallbacks[0](FALSE);
  channelCallbacks[0](TRUE);
  EXPECT_EQ([embedderCallbacks count], 1u);
  EXPECT_EQ([channelCallbacks count], 1u);
  // [tester.nextResponder keyUp:] should not be called, otherwise an error will be thrown.
  [embedderCallbacks removeAllObjects];
  [channelCallbacks removeAllObjects];

  // Case: Both responders report FALSE.
  [tester.manager handleEvent:keyDownEvent(0x53)];
  EXPECT_EQ([embedderCallbacks count], 1u);
  EXPECT_EQ([channelCallbacks count], 1u);
  embedderCallbacks[0](FALSE);
  channelCallbacks[0](FALSE);
  EXPECT_EQ([embedderCallbacks count], 1u);
  EXPECT_EQ([channelCallbacks count], 1u);
  OCMVerify([tester.nextResponder keyDown:checkKeyDownEvent(0x53)]);
  [embedderCallbacks removeAllObjects];
  [channelCallbacks removeAllObjects];

  return true;
}

- (bool)textInputPlugin {
  KeyboardTester* tester = [[KeyboardTester alloc] init];

  // Send a down event first so we can send an up event later.
  [tester respondEmbedderCallsWith:false];
  [tester respondChannelCallsWith:false];
  [tester.manager handleEvent:keyDownEvent(0x50)];

  NSMutableArray<FlutterAsyncKeyCallback>* callbacks =
      [NSMutableArray<FlutterAsyncKeyCallback> array];
  [tester recordEmbedderCallsTo:callbacks];

  // Case: Primary responder responds TRUE. The event shouldn't be handled by
  // the secondary responder.
  [tester respondTextInputWith:FALSE];
  [tester.manager handleEvent:keyUpEvent(0x50)];
  EXPECT_EQ([callbacks count], 1u);
  callbacks[0](TRUE);
  // [owner.nextResponder keyUp:] should not be called, otherwise an error will be thrown.
  [callbacks removeAllObjects];

  // Send a down event first so we can send an up event later.
  [tester respondEmbedderCallsWith:false];
  [tester.manager handleEvent:keyDownEvent(0x50)];

  // Case: Primary responder responds FALSE. The secondary responder returns
  // TRUE.
  [tester recordEmbedderCallsTo:callbacks];
  [tester respondTextInputWith:TRUE];
  [tester.manager handleEvent:keyUpEvent(0x50)];
  EXPECT_EQ([callbacks count], 1u);
  callbacks[0](FALSE);
  // [owner.nextResponder keyUp:] should not be called, otherwise an error will be thrown.
  [callbacks removeAllObjects];

  // Case: Primary responder responds FALSE. The secondary responder returns FALSE.
  [tester respondTextInputWith:FALSE];
  [tester.manager handleEvent:keyDownEvent(0x50)];
  EXPECT_EQ([callbacks count], 1u);
  callbacks[0](FALSE);
  OCMVerify([tester.nextResponder keyDown:checkKeyDownEvent(0x50)]);
  [callbacks removeAllObjects];

  return true;
}

- (bool)emptyNextResponder {
  KeyboardTester* tester = [[KeyboardTester alloc] init];
  tester.nextResponder = nil;

  [tester respondEmbedderCallsWith:false];
  [tester respondChannelCallsWith:false];
  [tester respondTextInputWith:false];
  [tester.manager handleEvent:keyDownEvent(0x50)];

  // Passes if no error is thrown.
  return true;
}

@end
