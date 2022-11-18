// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <Carbon/Carbon.h>
#import <Foundation/Foundation.h>
#import <OCMock/OCMock.h>

#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterChannelKeyResponder.h"
#include "flutter/shell/platform/embedder/test_utils/key_codes.g.h"
#import "flutter/testing/testing.h"
#include "third_party/googletest/googletest/include/gtest/gtest.h"

namespace flutter::testing {

namespace {
using flutter::testing::keycodes::kLogicalKeyQ;

NSEvent* keyEvent(NSEventType type,
                  NSEventModifierFlags modifierFlags,
                  NSString* characters,
                  NSString* charactersIgnoringModifiers,
                  BOOL isARepeat,
                  unsigned short keyCode) {
  return [NSEvent keyEventWithType:type
                          location:NSZeroPoint
                     modifierFlags:modifierFlags
                         timestamp:0
                      windowNumber:0
                           context:nil
                        characters:characters
       charactersIgnoringModifiers:charactersIgnoringModifiers
                         isARepeat:isARepeat
                           keyCode:keyCode];
}
}  // namespace

TEST(FlutterChannelKeyResponderUnittests, BasicKeyEvent) {
  __block NSMutableArray<id>* messages = [[NSMutableArray<id> alloc] init];
  __block BOOL next_response = TRUE;
  __block NSMutableArray<NSNumber*>* responses = [[NSMutableArray<NSNumber*> alloc] init];

  id mockKeyEventChannel = OCMStrictClassMock([FlutterBasicMessageChannel class]);
  OCMStub([mockKeyEventChannel sendMessage:[OCMArg any] reply:[OCMArg any]])
      .andDo((^(NSInvocation* invocation) {
        [invocation retainArguments];
        NSDictionary* message;
        [invocation getArgument:&message atIndex:2];
        [messages addObject:message];

        FlutterReply callback;
        [invocation getArgument:&callback atIndex:3];
        NSDictionary* keyMessage = @{
          @"handled" : @(next_response),
        };
        callback(keyMessage);
      }));

  FlutterChannelKeyResponder* responder =
      [[FlutterChannelKeyResponder alloc] initWithChannel:mockKeyEventChannel];

  // Initial empty modifiers. This can happen when user opens window while modifier key is pressed
  // and then releases the modifier. No events should be sent, but the callback
  // should still be called.
  // Regression test for https://github.com/flutter/flutter/issues/87339.
  [responder handleEvent:keyEvent(NSEventTypeFlagsChanged, 0x100, @"", @"", FALSE, 60)
                callback:^(BOOL handled) {
                  [responses addObject:@(handled)];
                }];

  EXPECT_EQ([messages count], 0u);
  EXPECT_EQ([responses count], 1u);
  EXPECT_EQ([responses[0] boolValue], TRUE);
  [responses removeAllObjects];

  // Key down
  [responder handleEvent:keyEvent(NSEventTypeKeyDown, 0x100, @"a", @"a", FALSE, 0)
                callback:^(BOOL handled) {
                  [responses addObject:@(handled)];
                }];

  EXPECT_EQ([messages count], 1u);
  EXPECT_STREQ([[messages lastObject][@"keymap"] UTF8String], "macos");
  EXPECT_STREQ([[messages lastObject][@"type"] UTF8String], "keydown");
  EXPECT_EQ([[messages lastObject][@"keyCode"] intValue], 0);
  EXPECT_EQ([[messages lastObject][@"modifiers"] intValue], 0x0);
  EXPECT_STREQ([[messages lastObject][@"characters"] UTF8String], "a");
  EXPECT_STREQ([[messages lastObject][@"charactersIgnoringModifiers"] UTF8String], "a");

  EXPECT_EQ([responses count], 1u);
  EXPECT_EQ([[responses lastObject] boolValue], TRUE);

  [messages removeAllObjects];
  [responses removeAllObjects];

  // Key up
  next_response = FALSE;
  [responder handleEvent:keyEvent(NSEventTypeKeyUp, 0x100, @"a", @"a", FALSE, 0)
                callback:^(BOOL handled) {
                  [responses addObject:@(handled)];
                }];

  EXPECT_EQ([messages count], 1u);
  EXPECT_STREQ([[messages lastObject][@"keymap"] UTF8String], "macos");
  EXPECT_STREQ([[messages lastObject][@"type"] UTF8String], "keyup");
  EXPECT_EQ([[messages lastObject][@"keyCode"] intValue], 0);
  EXPECT_EQ([[messages lastObject][@"modifiers"] intValue], 0);
  EXPECT_STREQ([[messages lastObject][@"characters"] UTF8String], "a");
  EXPECT_STREQ([[messages lastObject][@"charactersIgnoringModifiers"] UTF8String], "a");

  EXPECT_EQ([responses count], 1u);
  EXPECT_EQ([[responses lastObject] boolValue], FALSE);

  [messages removeAllObjects];
  [responses removeAllObjects];

  // LShift down
  next_response = TRUE;
  [responder handleEvent:keyEvent(NSEventTypeFlagsChanged, 0x20102, @"", @"", FALSE, 56)
                callback:^(BOOL handled) {
                  [responses addObject:@(handled)];
                }];

  EXPECT_EQ([messages count], 1u);
  EXPECT_STREQ([[messages lastObject][@"keymap"] UTF8String], "macos");
  EXPECT_STREQ([[messages lastObject][@"type"] UTF8String], "keydown");
  EXPECT_EQ([[messages lastObject][@"keyCode"] intValue], 56);
  EXPECT_EQ([[messages lastObject][@"modifiers"] intValue], 0x20002);

  EXPECT_EQ([responses count], 1u);
  EXPECT_EQ([[responses lastObject] boolValue], TRUE);

  [messages removeAllObjects];
  [responses removeAllObjects];

  // RShift down
  next_response = false;
  [responder handleEvent:keyEvent(NSEventTypeFlagsChanged, 0x20006, @"", @"", FALSE, 60)
                callback:^(BOOL handled) {
                  [responses addObject:@(handled)];
                }];

  EXPECT_EQ([messages count], 1u);
  EXPECT_STREQ([[messages lastObject][@"keymap"] UTF8String], "macos");
  EXPECT_STREQ([[messages lastObject][@"type"] UTF8String], "keydown");
  EXPECT_EQ([[messages lastObject][@"keyCode"] intValue], 60);
  EXPECT_EQ([[messages lastObject][@"modifiers"] intValue], 0x20006);

  EXPECT_EQ([responses count], 1u);
  EXPECT_EQ([[responses lastObject] boolValue], FALSE);

  [messages removeAllObjects];
  [responses removeAllObjects];

  // LShift up
  next_response = false;
  [responder handleEvent:keyEvent(NSEventTypeFlagsChanged, 0x20104, @"", @"", FALSE, 56)
                callback:^(BOOL handled) {
                  [responses addObject:@(handled)];
                }];

  EXPECT_EQ([messages count], 1u);
  EXPECT_STREQ([[messages lastObject][@"keymap"] UTF8String], "macos");
  EXPECT_STREQ([[messages lastObject][@"type"] UTF8String], "keyup");
  EXPECT_EQ([[messages lastObject][@"keyCode"] intValue], 56);
  EXPECT_EQ([[messages lastObject][@"modifiers"] intValue], 0x20004);

  EXPECT_EQ([responses count], 1u);
  EXPECT_EQ([[responses lastObject] boolValue], FALSE);

  [messages removeAllObjects];
  [responses removeAllObjects];

  // RShift up
  next_response = false;
  [responder handleEvent:keyEvent(NSEventTypeFlagsChanged, 0, @"", @"", FALSE, 60)
                callback:^(BOOL handled) {
                  [responses addObject:@(handled)];
                }];

  EXPECT_EQ([messages count], 1u);
  EXPECT_STREQ([[messages lastObject][@"keymap"] UTF8String], "macos");
  EXPECT_STREQ([[messages lastObject][@"type"] UTF8String], "keyup");
  EXPECT_EQ([[messages lastObject][@"keyCode"] intValue], 60);
  EXPECT_EQ([[messages lastObject][@"modifiers"] intValue], 0);

  EXPECT_EQ([responses count], 1u);
  EXPECT_EQ([[responses lastObject] boolValue], FALSE);

  [messages removeAllObjects];
  [responses removeAllObjects];

  // RShift up again, should be ignored and not produce a keydown event, but the
  // callback should be called.
  next_response = false;
  [responder handleEvent:keyEvent(NSEventTypeFlagsChanged, 0x100, @"", @"", FALSE, 60)
                callback:^(BOOL handled) {
                  [responses addObject:@(handled)];
                }];

  EXPECT_EQ([messages count], 0u);
  EXPECT_EQ([responses count], 1u);
  EXPECT_EQ([responses[0] boolValue], TRUE);
}

TEST(FlutterChannelKeyResponderUnittests, EmptyResponseIsTakenAsHandled) {
  __block NSMutableArray<id>* messages = [[NSMutableArray<id> alloc] init];
  __block NSMutableArray<NSNumber*>* responses = [[NSMutableArray<NSNumber*> alloc] init];

  id mockKeyEventChannel = OCMStrictClassMock([FlutterBasicMessageChannel class]);
  OCMStub([mockKeyEventChannel sendMessage:[OCMArg any] reply:[OCMArg any]])
      .andDo((^(NSInvocation* invocation) {
        [invocation retainArguments];
        NSDictionary* message;
        [invocation getArgument:&message atIndex:2];
        [messages addObject:message];

        FlutterReply callback;
        [invocation getArgument:&callback atIndex:3];
        callback(nullptr);
      }));

  FlutterChannelKeyResponder* responder =
      [[FlutterChannelKeyResponder alloc] initWithChannel:mockKeyEventChannel];
  [responder handleEvent:keyEvent(NSEventTypeKeyDown, 0x100, @"a", @"a", FALSE, 0)
                callback:^(BOOL handled) {
                  [responses addObject:@(handled)];
                }];

  EXPECT_EQ([messages count], 1u);
  EXPECT_STREQ([[messages lastObject][@"keymap"] UTF8String], "macos");
  EXPECT_STREQ([[messages lastObject][@"type"] UTF8String], "keydown");
  EXPECT_EQ([[messages lastObject][@"keyCode"] intValue], 0);
  EXPECT_EQ([[messages lastObject][@"modifiers"] intValue], 0);
  EXPECT_STREQ([[messages lastObject][@"characters"] UTF8String], "a");
  EXPECT_STREQ([[messages lastObject][@"charactersIgnoringModifiers"] UTF8String], "a");

  EXPECT_EQ([responses count], 1u);
  EXPECT_EQ([[responses lastObject] boolValue], TRUE);
}

TEST(FlutterChannelKeyResponderUnittests, FollowsLayoutMap) {
  __block NSMutableArray<id>* messages = [[NSMutableArray<id> alloc] init];
  __block BOOL next_response = TRUE;
  __block NSMutableArray<NSNumber*>* responses = [[NSMutableArray<NSNumber*> alloc] init];

  id mockKeyEventChannel = OCMStrictClassMock([FlutterBasicMessageChannel class]);
  OCMStub([mockKeyEventChannel sendMessage:[OCMArg any] reply:[OCMArg any]])
      .andDo((^(NSInvocation* invocation) {
        [invocation retainArguments];
        NSDictionary* message;
        [invocation getArgument:&message atIndex:2];
        [messages addObject:message];

        FlutterReply callback;
        [invocation getArgument:&callback atIndex:3];
        NSDictionary* keyMessage = @{
          @"handled" : @(next_response),
        };
        callback(keyMessage);
      }));

  FlutterChannelKeyResponder* responder =
      [[FlutterChannelKeyResponder alloc] initWithChannel:mockKeyEventChannel];

  NSMutableDictionary<NSNumber*, NSNumber*>* layoutMap =
      [NSMutableDictionary<NSNumber*, NSNumber*> dictionary];
  responder.layoutMap = layoutMap;
  // French layout
  layoutMap[@(kVK_ANSI_A)] = @(kLogicalKeyQ);

  [responder handleEvent:keyEvent(NSEventTypeKeyDown, kVK_ANSI_A, @"q", @"q", FALSE, 0)
                callback:^(BOOL handled) {
                  [responses addObject:@(handled)];
                }];

  EXPECT_EQ([messages count], 1u);
  EXPECT_STREQ([[messages lastObject][@"keymap"] UTF8String], "macos");
  EXPECT_STREQ([[messages lastObject][@"type"] UTF8String], "keydown");
  EXPECT_EQ([[messages lastObject][@"keyCode"] intValue], 0);
  EXPECT_EQ([[messages lastObject][@"modifiers"] intValue], 0x0);
  EXPECT_STREQ([[messages lastObject][@"characters"] UTF8String], "q");
  EXPECT_STREQ([[messages lastObject][@"charactersIgnoringModifiers"] UTF8String], "q");
  EXPECT_EQ([messages lastObject][@"specifiedLogicalKey"], @(kLogicalKeyQ));

  EXPECT_EQ([responses count], 1u);
  EXPECT_EQ([[responses lastObject] boolValue], TRUE);

  [messages removeAllObjects];
  [responses removeAllObjects];
}

}  // namespace flutter::testing
