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
typedef void (^AsyncKeyCallbackHandler)(FlutterAsyncKeyCallback callback);
typedef BOOL (^TextInputCallback)(NSEvent*);

// When the Vietnamese IME converts messages into "pure text" messages, their
// key codes are set to "empty".
//
// The 0 also happens to be the key code for key A.
constexpr uint16_t kKeyCodeEmpty = 0x00;

constexpr uint16_t kKeyCodeKeyO = 0x1f;
constexpr uint16_t kKeyCodeBackspace = 0x33;

// Constants used for `recordCallTypesTo:forTypes:`.
constexpr uint32_t kEmbedderCall = 0x1;
constexpr uint32_t kChannelCall = 0x2;
constexpr uint32_t kTextCall = 0x4;

NSEvent* keyDownEvent(unsigned short keyCode, NSString* chars = @"", NSString* charsUnmod = @"") {
  return [NSEvent keyEventWithType:NSEventTypeKeyDown
                          location:NSZeroPoint
                     modifierFlags:0x100
                         timestamp:0
                      windowNumber:0
                           context:nil
                        characters:chars
       charactersIgnoringModifiers:charsUnmod
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

// Set embedder calls to respond immediately with the given response.
- (void)respondEmbedderCallsWith:(BOOL)response;

// Record embedder calls to the given storage.
//
// They are not responded to until the stored callbacks are manually called.
- (void)recordEmbedderCallsTo:(nonnull NSMutableArray<FlutterAsyncKeyCallback>*)storage;

// Set channel calls to respond immediately with the given response.
- (void)respondChannelCallsWith:(BOOL)response;

// Record channel calls to the given storage.
//
// They are not responded to until the stored callbacks are manually called.
- (void)recordChannelCallsTo:(nonnull NSMutableArray<FlutterAsyncKeyCallback>*)storage;

// Set text calls to respond with the given response.
- (void)respondTextInputWith:(BOOL)response;

// At the start of any kind of call, record the call type to the given storage.
//
// Only calls that are included in `typeMask` will be added. Options are
// kEmbedderCall, kChannelCall, and kTextCall.
//
// This method does not conflict with other call settings, and the recording
// takes place before the callbacks are (or are not) invoked.
- (void)recordCallTypesTo:(nonnull NSMutableArray<NSNumber*>*)typeStorage
                 forTypes:(uint32_t)typeMask;

@property(nonatomic) FlutterKeyboardManager* manager;
@property(nonatomic) NSResponder* nextResponder;
@property(nonatomic, assign) BOOL isComposing;

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
  TextInputCallback _textCallback;

  NSMutableArray<NSNumber*>* _typeStorage;
  uint32_t _typeStorageMask;
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
  _isComposing = NO;

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
  OCMStub([viewDelegateMock isComposing]).andCall(self, @selector(isComposing));
  OCMStub([viewDelegateMock sendKeyEvent:FlutterKeyEvent {} callback:nil userData:nil])
      .ignoringNonObjectArgs()
      .andCall(self, @selector(handleEmbedderEvent:callback:userData:));

  _manager = [[FlutterKeyboardManager alloc] initWithViewDelegate:viewDelegateMock];
  return self;
}

- (void)respondEmbedderCallsWith:(BOOL)response {
  _embedderHandler = ^(FlutterAsyncKeyCallback callback) {
    callback(response);
  };
}

- (void)recordEmbedderCallsTo:(nonnull NSMutableArray<FlutterAsyncKeyCallback>*)storage {
  _embedderHandler = ^(FlutterAsyncKeyCallback callback) {
    [storage addObject:callback];
  };
}

- (void)respondChannelCallsWith:(BOOL)response {
  _channelHandler = ^(FlutterAsyncKeyCallback callback) {
    callback(response);
  };
}

- (void)recordChannelCallsTo:(nonnull NSMutableArray<FlutterAsyncKeyCallback>*)storage {
  _channelHandler = ^(FlutterAsyncKeyCallback callback) {
    [storage addObject:callback];
  };
}

- (void)respondTextInputWith:(BOOL)response {
  _textCallback = ^(NSEvent* event) {
    return response;
  };
}

- (void)recordCallTypesTo:(nonnull NSMutableArray<NSNumber*>*)typeStorage
                 forTypes:(uint32_t)typeMask {
  _typeStorage = typeStorage;
  _typeStorageMask = typeMask;
}

#pragma mark - Private

- (void)handleEmbedderEvent:(const FlutterKeyEvent&)event
                   callback:(nullable FlutterKeyEventCallback)callback
                   userData:(nullable void*)userData {
  if (_typeStorage != nil && (_typeStorageMask & kEmbedderCall) != 0) {
    [_typeStorage addObject:@(kEmbedderCall)];
  }
  if (callback != nullptr) {
    _embedderHandler(^(BOOL handled) {
      callback(handled, userData);
    });
  }
}

- (void)handleChannelMessage:(NSString*)channel
                     message:(NSData* _Nullable)message
                 binaryReply:(FlutterBinaryReply _Nullable)callback {
  if (_typeStorage != nil && (_typeStorageMask & kChannelCall) != 0) {
    [_typeStorage addObject:@(kChannelCall)];
  }
  _channelHandler(^(BOOL handled) {
    NSDictionary* result = @{
      @"handled" : @(handled),
    };
    NSData* encodedKeyEvent = [[FlutterJSONMessageCodec sharedInstance] encode:result];
    callback(encodedKeyEvent);
  });
}

- (BOOL)handleTextInputKeyEvent:(NSEvent*)event {
  if (_typeStorage != nil && (_typeStorageMask & kTextCall) != 0) {
    [_typeStorage addObject:@(kTextCall)];
  }
  return _textCallback(event);
}

@end

@interface FlutterKeyboardManagerUnittestsObjC : NSObject
- (bool)nextResponderShouldThrowOnKeyUp;
- (bool)singlePrimaryResponder;
- (bool)doublePrimaryResponder;
- (bool)textInputPlugin;
- (bool)forwardKeyEventsToSystemWhenComposing;
- (bool)emptyNextResponder;
- (bool)racingConditionBetweenKeyAndText;
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

TEST(FlutterKeyboardManagerUnittests, handlingComposingText) {
  ASSERT_TRUE([[FlutterKeyboardManagerUnittestsObjC alloc] forwardKeyEventsToSystemWhenComposing]);
}

TEST(FlutterKeyboardManagerUnittests, EmptyNextResponder) {
  ASSERT_TRUE([[FlutterKeyboardManagerUnittestsObjC alloc] emptyNextResponder]);
}

TEST(FlutterKeyboardManagerUnittests, RacingConditionBetweenKeyAndText) {
  ASSERT_TRUE([[FlutterKeyboardManagerUnittestsObjC alloc] racingConditionBetweenKeyAndText]);
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

- (bool)forwardKeyEventsToSystemWhenComposing {
  KeyboardTester* tester = OCMPartialMock([[KeyboardTester alloc] init]);

  NSMutableArray<FlutterAsyncKeyCallback>* channelCallbacks =
      [NSMutableArray<FlutterAsyncKeyCallback> array];
  NSMutableArray<FlutterAsyncKeyCallback>* embedderCallbacks =
      [NSMutableArray<FlutterAsyncKeyCallback> array];
  [tester recordEmbedderCallsTo:embedderCallbacks];
  [tester recordChannelCallsTo:channelCallbacks];
  // The event shouldn't propagate further even if TextInputPlugin does not
  // claim the event.
  [tester respondTextInputWith:NO];

  tester.isComposing = YES;
  // Send a down event with composing == YES.
  [tester.manager handleEvent:keyUpEvent(0x50)];

  // Nobody gets the event except for the text input plugin.
  EXPECT_EQ([channelCallbacks count], 0u);
  EXPECT_EQ([embedderCallbacks count], 0u);
  OCMVerify(times(1), [tester handleTextInputKeyEvent:checkKeyDownEvent(0x50)]);

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

// Regression test for https://github.com/flutter/flutter/issues/82673.
- (bool)racingConditionBetweenKeyAndText {
  KeyboardTester* tester = [[KeyboardTester alloc] init];

  // Use Vietnamese IME (GoTiengViet, Telex mode) to type "uco".

  // The events received by the framework. The engine might receive
  // a channel message "setEditingState" from the framework.
  NSMutableArray<FlutterAsyncKeyCallback>* keyCallbacks =
      [NSMutableArray<FlutterAsyncKeyCallback> array];
  [tester recordEmbedderCallsTo:keyCallbacks];

  NSMutableArray<NSNumber*>* allCalls = [NSMutableArray<NSNumber*> array];
  [tester recordCallTypesTo:allCalls forTypes:(kEmbedderCall | kTextCall)];

  // Tap key U, which is converted by IME into a pure text message "ư".

  [tester.manager handleEvent:keyDownEvent(kKeyCodeEmpty, @"ư", @"ư")];
  EXPECT_EQ([keyCallbacks count], 1u);
  EXPECT_EQ([allCalls count], 1u);
  EXPECT_EQ(allCalls[0], @(kEmbedderCall));
  keyCallbacks[0](false);
  EXPECT_EQ([keyCallbacks count], 1u);
  EXPECT_EQ([allCalls count], 2u);
  EXPECT_EQ(allCalls[1], @(kTextCall));
  [keyCallbacks removeAllObjects];
  [allCalls removeAllObjects];

  [tester.manager handleEvent:keyUpEvent(kKeyCodeEmpty)];
  EXPECT_EQ([keyCallbacks count], 1u);
  keyCallbacks[0](false);
  EXPECT_EQ([keyCallbacks count], 1u);
  EXPECT_EQ([allCalls count], 2u);
  [keyCallbacks removeAllObjects];
  [allCalls removeAllObjects];

  // Tap key O, which is converted to normal KeyO events, but the responses are
  // slow.

  [tester.manager handleEvent:keyDownEvent(kKeyCodeKeyO, @"o", @"o")];
  [tester.manager handleEvent:keyUpEvent(kKeyCodeKeyO)];
  EXPECT_EQ([keyCallbacks count], 1u);
  EXPECT_EQ([allCalls count], 1u);
  EXPECT_EQ(allCalls[0], @(kEmbedderCall));

  // Tap key C, which results in two Backspace messages first - and here they
  // arrive before the key O messages are responded.

  [tester.manager handleEvent:keyDownEvent(kKeyCodeBackspace)];
  [tester.manager handleEvent:keyUpEvent(kKeyCodeBackspace)];
  EXPECT_EQ([keyCallbacks count], 1u);
  EXPECT_EQ([allCalls count], 1u);

  // The key O down is responded, which releases a text call (for KeyO down) and
  // an embedder call (for KeyO up) immediately.
  keyCallbacks[0](false);
  EXPECT_EQ([keyCallbacks count], 2u);
  EXPECT_EQ([allCalls count], 3u);
  EXPECT_EQ(allCalls[1], @(kTextCall));  // The order is important!
  EXPECT_EQ(allCalls[2], @(kEmbedderCall));

  // The key O up is responded, which releases a text call (for KeyO up) and
  // an embedder call (for Backspace down) immediately.
  keyCallbacks[1](false);
  EXPECT_EQ([keyCallbacks count], 3u);
  EXPECT_EQ([allCalls count], 5u);
  EXPECT_EQ(allCalls[3], @(kTextCall));  // The order is important!
  EXPECT_EQ(allCalls[4], @(kEmbedderCall));

  // Finish up callbacks.
  keyCallbacks[2](false);
  keyCallbacks[3](false);

  return true;
}

@end
