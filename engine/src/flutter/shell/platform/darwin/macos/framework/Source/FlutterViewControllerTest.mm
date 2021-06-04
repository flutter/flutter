// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/macos/framework/Headers/FlutterViewController.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterViewController_Internal.h"

#import <OCMock/OCMock.h>

#import "flutter/shell/platform/darwin/common/framework/Headers/FlutterBinaryMessenger.h"
#import "flutter/shell/platform/darwin/macos/framework/Headers/FlutterEngine.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterDartProject_Internal.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterEngine_Internal.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterViewControllerTestUtils.h"
#import "flutter/testing/testing.h"

@interface FlutterViewControllerTestObjC : NSObject
- (bool)testKeyEventsAreSentToFramework;
- (bool)testKeyEventsArePropagatedIfNotHandled;
- (bool)testKeyEventsAreNotPropagatedIfHandled;
- (bool)testFlagsChangedEventsArePropagatedIfNotHandled;
- (bool)testPerformKeyEquivalentSynthesizesKeyUp;

+ (void)respondFalseForSendEvent:(const FlutterKeyEvent&)event
                        callback:(nullable FlutterKeyEventCallback)callback
                        userData:(nullable void*)userData;
@end

namespace flutter::testing {

namespace {

// Allocates and returns an engine configured for the test fixture resource configuration.
FlutterEngine* CreateTestEngine() {
  NSString* fixtures = @(testing::GetFixturesPath());
  FlutterDartProject* project = [[FlutterDartProject alloc]
      initWithAssetsPath:fixtures
             ICUDataPath:[fixtures stringByAppendingString:@"/icudtl.dat"]];
  return [[FlutterEngine alloc] initWithName:@"test" project:project allowHeadlessExecution:true];
}

NSResponder* mockResponder() {
  NSResponder* mock = OCMStrictClassMock([NSResponder class]);
  OCMStub([mock keyDown:[OCMArg any]]).andDo(nil);
  OCMStub([mock keyUp:[OCMArg any]]).andDo(nil);
  OCMStub([mock flagsChanged:[OCMArg any]]).andDo(nil);
  return mock;
}
}  // namespace

TEST(FlutterViewController, HasStringsWhenPasteboardEmpty) {
  // Mock FlutterViewController so that it behaves like the pasteboard is empty.
  id viewControllerMock = CreateMockViewController(nil);

  // Call hasStrings and expect it to be false.
  __block bool calledAfterClear = false;
  __block bool valueAfterClear;
  FlutterResult resultAfterClear = ^(id result) {
    calledAfterClear = true;
    NSNumber* valueNumber = [result valueForKey:@"value"];
    valueAfterClear = [valueNumber boolValue];
  };
  FlutterMethodCall* methodCallAfterClear =
      [FlutterMethodCall methodCallWithMethodName:@"Clipboard.hasStrings" arguments:nil];
  [viewControllerMock handleMethodCall:methodCallAfterClear result:resultAfterClear];
  EXPECT_TRUE(calledAfterClear);
  EXPECT_FALSE(valueAfterClear);
}

TEST(FlutterViewController, HasStringsWhenPasteboardFull) {
  // Mock FlutterViewController so that it behaves like the pasteboard has a
  // valid string.
  id viewControllerMock = CreateMockViewController(@"some string");

  // Call hasStrings and expect it to be true.
  __block bool called = false;
  __block bool value;
  FlutterResult result = ^(id result) {
    called = true;
    NSNumber* valueNumber = [result valueForKey:@"value"];
    value = [valueNumber boolValue];
  };
  FlutterMethodCall* methodCall =
      [FlutterMethodCall methodCallWithMethodName:@"Clipboard.hasStrings" arguments:nil];
  [viewControllerMock handleMethodCall:methodCall result:result];
  EXPECT_TRUE(called);
  EXPECT_TRUE(value);
}

TEST(FlutterViewController, HasViewThatHidesOtherViewsInAccessibility) {
  FlutterViewController* viewControllerMock = CreateMockViewController(nil);

  [viewControllerMock loadView];
  auto subViews = [viewControllerMock.view subviews];

  EXPECT_EQ([subViews count], 1u);
  EXPECT_EQ(subViews[0], viewControllerMock.flutterView);

  NSTextField* textField = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 1, 1)];
  [viewControllerMock.view addSubview:textField];

  subViews = [viewControllerMock.view subviews];
  EXPECT_EQ([subViews count], 2u);

  auto accessibilityChildren = viewControllerMock.view.accessibilityChildren;
  // The accessibilityChildren should only contains the FlutterView.
  EXPECT_EQ([accessibilityChildren count], 1u);
  EXPECT_EQ(accessibilityChildren[0], viewControllerMock.flutterView);
}

TEST(FlutterViewController, SetsFlutterViewFirstResponderWhenAccessibilityDisabled) {
  FlutterEngine* engine = CreateTestEngine();
  NSString* fixtures = @(testing::GetFixturesPath());
  FlutterDartProject* project = [[FlutterDartProject alloc]
      initWithAssetsPath:fixtures
             ICUDataPath:[fixtures stringByAppendingString:@"/icudtl.dat"]];
  FlutterViewController* viewController = [[FlutterViewController alloc] initWithProject:project];
  [viewController loadView];
  [engine setViewController:viewController];
  // Creates a NSWindow so that sub view can be first responder.
  NSWindow* window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 800, 600)
                                                 styleMask:NSBorderlessWindowMask
                                                   backing:NSBackingStoreBuffered
                                                     defer:NO];
  window.contentView = viewController.view;
  // Attaches FlutterTextInputPlugin to the view;
  [viewController.view addSubview:viewController.textInputPlugin];
  // Makes sure the textInputPlugin can be the first responder.
  EXPECT_TRUE([window makeFirstResponder:viewController.textInputPlugin]);
  EXPECT_EQ([window firstResponder], viewController.textInputPlugin);
  // Sends a notification to turn off the accessibility.
  NSDictionary* userInfo = @{
    @"AXEnhancedUserInterface" : @(NO),
  };
  NSNotification* accessibilityOff = [NSNotification notificationWithName:@""
                                                                   object:nil
                                                                 userInfo:userInfo];
  [viewController onAccessibilityStatusChanged:accessibilityOff];
  // FlutterView becomes the first responder.
  EXPECT_EQ([window firstResponder], viewController.flutterView);
}

TEST(FlutterViewController, CanSetMouseTrackingModeBeforeViewLoaded) {
  NSString* fixtures = @(testing::GetFixturesPath());
  FlutterDartProject* project = [[FlutterDartProject alloc]
      initWithAssetsPath:fixtures
             ICUDataPath:[fixtures stringByAppendingString:@"/icudtl.dat"]];
  FlutterViewController* viewController = [[FlutterViewController alloc] initWithProject:project];
  viewController.mouseTrackingMode = FlutterMouseTrackingModeInActiveApp;
  ASSERT_EQ(viewController.mouseTrackingMode, FlutterMouseTrackingModeInActiveApp);
}

TEST(FlutterViewControllerTest, TestKeyEventsAreSentToFramework) {
  ASSERT_TRUE([[FlutterViewControllerTestObjC alloc] testKeyEventsAreSentToFramework]);
}

TEST(FlutterViewControllerTest, TestKeyEventsArePropagatedIfNotHandled) {
  ASSERT_TRUE([[FlutterViewControllerTestObjC alloc] testKeyEventsArePropagatedIfNotHandled]);
}

TEST(FlutterViewControllerTest, TestKeyEventsAreNotPropagatedIfHandled) {
  ASSERT_TRUE([[FlutterViewControllerTestObjC alloc] testKeyEventsAreNotPropagatedIfHandled]);
}

TEST(FlutterViewControllerTest, TestFlagsChangedEventsArePropagatedIfNotHandled) {
  ASSERT_TRUE(
      [[FlutterViewControllerTestObjC alloc] testFlagsChangedEventsArePropagatedIfNotHandled]);
}

TEST(FlutterViewControllerTest, TestPerformKeyEquivalentSynthesizesKeyUp) {
  ASSERT_TRUE([[FlutterViewControllerTestObjC alloc] testPerformKeyEquivalentSynthesizesKeyUp]);
}

}  // namespace flutter::testing

@implementation FlutterViewControllerTestObjC

- (bool)testKeyEventsAreSentToFramework {
  id engineMock = OCMClassMock([FlutterEngine class]);
  id binaryMessengerMock = OCMProtocolMock(@protocol(FlutterBinaryMessenger));
  OCMStub(  // NOLINT(google-objc-avoid-throwing-exception)
      [engineMock binaryMessenger])
      .andReturn(binaryMessengerMock);
  OCMStub([[engineMock ignoringNonObjectArgs] sendKeyEvent:FlutterKeyEvent {}
                                                  callback:nil
                                                  userData:nil])
      .andCall([FlutterViewControllerTestObjC class],
               @selector(respondFalseForSendEvent:callback:userData:));
  FlutterViewController* viewController = [[FlutterViewController alloc] initWithEngine:engineMock
                                                                                nibName:@""
                                                                                 bundle:nil];
  NSDictionary* expectedEvent = @{
    @"keymap" : @"macos",
    @"type" : @"keydown",
    @"keyCode" : @(65),
    @"modifiers" : @(538968064),
    @"characters" : @".",
    @"charactersIgnoringModifiers" : @".",
  };
  NSData* encodedKeyEvent = [[FlutterJSONMessageCodec sharedInstance] encode:expectedEvent];
  CGEventRef cgEvent = CGEventCreateKeyboardEvent(NULL, 65, TRUE);
  NSEvent* event = [NSEvent eventWithCGEvent:cgEvent];
  [viewController viewWillAppear];  // Initializes the event channel.
  [viewController keyDown:event];
  @try {
    OCMVerify(  // NOLINT(google-objc-avoid-throwing-exception)
        [binaryMessengerMock sendOnChannel:@"flutter/keyevent"
                                   message:encodedKeyEvent
                               binaryReply:[OCMArg any]]);
  } @catch (...) {
    return false;
  }
  return true;
}

- (bool)testKeyEventsArePropagatedIfNotHandled {
  id engineMock = OCMClassMock([FlutterEngine class]);
  id binaryMessengerMock = OCMProtocolMock(@protocol(FlutterBinaryMessenger));
  OCMStub(  // NOLINT(google-objc-avoid-throwing-exception)
      [engineMock binaryMessenger])
      .andReturn(binaryMessengerMock);
  OCMStub([[engineMock ignoringNonObjectArgs] sendKeyEvent:FlutterKeyEvent {}
                                                  callback:nil
                                                  userData:nil])
      .andCall([FlutterViewControllerTestObjC class],
               @selector(respondFalseForSendEvent:callback:userData:));
  FlutterViewController* viewController = [[FlutterViewController alloc] initWithEngine:engineMock
                                                                                nibName:@""
                                                                                 bundle:nil];
  id responderMock = flutter::testing::mockResponder();
  viewController.nextResponder = responderMock;
  NSDictionary* expectedEvent = @{
    @"keymap" : @"macos",
    @"type" : @"keydown",
    @"keyCode" : @(65),
    @"modifiers" : @(538968064),
    @"characters" : @".",
    @"charactersIgnoringModifiers" : @".",
  };
  NSData* encodedKeyEvent = [[FlutterJSONMessageCodec sharedInstance] encode:expectedEvent];
  CGEventRef cgEvent = CGEventCreateKeyboardEvent(NULL, 65, TRUE);
  NSEvent* event = [NSEvent eventWithCGEvent:cgEvent];
  OCMExpect(  // NOLINT(google-objc-avoid-throwing-exception)
      [binaryMessengerMock sendOnChannel:@"flutter/keyevent"
                                 message:encodedKeyEvent
                             binaryReply:[OCMArg any]])
      .andDo((^(NSInvocation* invocation) {
        FlutterBinaryReply handler;
        [invocation getArgument:&handler atIndex:4];
        NSDictionary* reply = @{
          @"handled" : @(false),
        };
        NSData* encodedReply = [[FlutterJSONMessageCodec sharedInstance] encode:reply];
        handler(encodedReply);
      }));
  [viewController viewWillAppear];  // Initializes the event channel.
  [viewController keyDown:event];
  @try {
    OCMVerify(  // NOLINT(google-objc-avoid-throwing-exception)
        [responderMock keyDown:[OCMArg any]]);
    OCMVerify(  // NOLINT(google-objc-avoid-throwing-exception)
        [binaryMessengerMock sendOnChannel:@"flutter/keyevent"
                                   message:encodedKeyEvent
                               binaryReply:[OCMArg any]]);
  } @catch (...) {
    return false;
  }
  return true;
}

- (bool)testFlagsChangedEventsArePropagatedIfNotHandled {
  id engineMock = OCMClassMock([FlutterEngine class]);
  id binaryMessengerMock = OCMProtocolMock(@protocol(FlutterBinaryMessenger));
  OCMStub(  // NOLINT(google-objc-avoid-throwing-exception)
      [engineMock binaryMessenger])
      .andReturn(binaryMessengerMock);
  OCMStub([[engineMock ignoringNonObjectArgs] sendKeyEvent:FlutterKeyEvent {}
                                                  callback:nil
                                                  userData:nil])
      .andCall([FlutterViewControllerTestObjC class],
               @selector(respondFalseForSendEvent:callback:userData:));
  FlutterViewController* viewController = [[FlutterViewController alloc] initWithEngine:engineMock
                                                                                nibName:@""
                                                                                 bundle:nil];
  id responderMock = flutter::testing::mockResponder();
  viewController.nextResponder = responderMock;
  NSDictionary* expectedEvent = @{
    @"keymap" : @"macos",
    @"type" : @"keydown",
    @"keyCode" : @(56),  // SHIFT key
    @"modifiers" : @(537001986),
  };
  NSData* encodedKeyEvent = [[FlutterJSONMessageCodec sharedInstance] encode:expectedEvent];
  CGEventRef cgEvent = CGEventCreateKeyboardEvent(NULL, 56, TRUE);  // SHIFT key
  CGEventSetType(cgEvent, kCGEventFlagsChanged);
  NSEvent* event = [NSEvent eventWithCGEvent:cgEvent];
  OCMExpect(  // NOLINT(google-objc-avoid-throwing-exception)
      [binaryMessengerMock sendOnChannel:@"flutter/keyevent"
                                 message:encodedKeyEvent
                             binaryReply:[OCMArg any]])
      .andDo((^(NSInvocation* invocation) {
        FlutterBinaryReply handler;
        [invocation getArgument:&handler atIndex:4];
        NSDictionary* reply = @{
          @"handled" : @(false),
        };
        NSData* encodedReply = [[FlutterJSONMessageCodec sharedInstance] encode:reply];
        handler(encodedReply);
      }));
  [viewController viewWillAppear];  // Initializes the event channel.
  [viewController flagsChanged:event];
  @try {
    OCMVerify(  // NOLINT(google-objc-avoid-throwing-exception)
        [binaryMessengerMock sendOnChannel:@"flutter/keyevent"
                                   message:encodedKeyEvent
                               binaryReply:[OCMArg any]]);
  } @catch (NSException* e) {
    NSLog(@"%@", e.reason);
    return false;
  }
  return true;
}

- (bool)testKeyEventsAreNotPropagatedIfHandled {
  id engineMock = OCMClassMock([FlutterEngine class]);
  id binaryMessengerMock = OCMProtocolMock(@protocol(FlutterBinaryMessenger));
  OCMStub(  // NOLINT(google-objc-avoid-throwing-exception)
      [engineMock binaryMessenger])
      .andReturn(binaryMessengerMock);
  OCMStub([[engineMock ignoringNonObjectArgs] sendKeyEvent:FlutterKeyEvent {}
                                                  callback:nil
                                                  userData:nil])
      .andCall([FlutterViewControllerTestObjC class],
               @selector(respondFalseForSendEvent:callback:userData:));
  FlutterViewController* viewController = [[FlutterViewController alloc] initWithEngine:engineMock
                                                                                nibName:@""
                                                                                 bundle:nil];
  id responderMock = flutter::testing::mockResponder();
  viewController.nextResponder = responderMock;
  NSDictionary* expectedEvent = @{
    @"keymap" : @"macos",
    @"type" : @"keydown",
    @"keyCode" : @(65),
    @"modifiers" : @(538968064),
    @"characters" : @".",
    @"charactersIgnoringModifiers" : @".",
  };
  NSData* encodedKeyEvent = [[FlutterJSONMessageCodec sharedInstance] encode:expectedEvent];
  CGEventRef cgEvent = CGEventCreateKeyboardEvent(NULL, 65, TRUE);
  NSEvent* event = [NSEvent eventWithCGEvent:cgEvent];
  OCMExpect(  // NOLINT(google-objc-avoid-throwing-exception)
      [binaryMessengerMock sendOnChannel:@"flutter/keyevent"
                                 message:encodedKeyEvent
                             binaryReply:[OCMArg any]])
      .andDo((^(NSInvocation* invocation) {
        FlutterBinaryReply handler;
        [invocation getArgument:&handler atIndex:4];
        NSDictionary* reply = @{
          @"handled" : @(true),
        };
        NSData* encodedReply = [[FlutterJSONMessageCodec sharedInstance] encode:reply];
        handler(encodedReply);
      }));
  [viewController viewWillAppear];  // Initializes the event channel.
  [viewController keyDown:event];
  @try {
    OCMVerify(  // NOLINT(google-objc-avoid-throwing-exception)
        never(), [responderMock keyDown:[OCMArg any]]);
    OCMVerify(  // NOLINT(google-objc-avoid-throwing-exception)
        [binaryMessengerMock sendOnChannel:@"flutter/keyevent"
                                   message:encodedKeyEvent
                               binaryReply:[OCMArg any]]);
  } @catch (...) {
    return false;
  }
  return true;
}

- (bool)testPerformKeyEquivalentSynthesizesKeyUp {
  id engineMock = OCMClassMock([FlutterEngine class]);
  id binaryMessengerMock = OCMProtocolMock(@protocol(FlutterBinaryMessenger));
  OCMStub(  // NOLINT(google-objc-avoid-throwing-exception)
      [engineMock binaryMessenger])
      .andReturn(binaryMessengerMock);
  OCMStub([[engineMock ignoringNonObjectArgs] sendKeyEvent:FlutterKeyEvent {}
                                                  callback:nil
                                                  userData:nil])
      .andCall([FlutterViewControllerTestObjC class],
               @selector(respondFalseForSendEvent:callback:userData:));
  FlutterViewController* viewController = [[FlutterViewController alloc] initWithEngine:engineMock
                                                                                nibName:@""
                                                                                 bundle:nil];
  id responderMock = flutter::testing::mockResponder();
  viewController.nextResponder = responderMock;
  NSDictionary* expectedKeyDownEvent = @{
    @"keymap" : @"macos",
    @"type" : @"keydown",
    @"keyCode" : @(65),
    @"modifiers" : @(538968064),
    @"characters" : @".",
    @"charactersIgnoringModifiers" : @".",
  };
  NSData* encodedKeyDownEvent =
      [[FlutterJSONMessageCodec sharedInstance] encode:expectedKeyDownEvent];
  NSDictionary* expectedKeyUpEvent = @{
    @"keymap" : @"macos",
    @"type" : @"keyup",
    @"keyCode" : @(65),
    @"modifiers" : @(538968064),
    @"characters" : @".",
    @"charactersIgnoringModifiers" : @".",
  };
  NSData* encodedKeyUpEvent = [[FlutterJSONMessageCodec sharedInstance] encode:expectedKeyUpEvent];
  CGEventRef cgEvent = CGEventCreateKeyboardEvent(NULL, 65, TRUE);
  NSEvent* event = [NSEvent eventWithCGEvent:cgEvent];
  OCMExpect(  // NOLINT(google-objc-avoid-throwing-exception)
      [binaryMessengerMock sendOnChannel:@"flutter/keyevent"
                                 message:encodedKeyDownEvent
                             binaryReply:[OCMArg any]])
      .andDo((^(NSInvocation* invocation) {
        FlutterBinaryReply handler;
        [invocation getArgument:&handler atIndex:4];
        NSDictionary* reply = @{
          @"handled" : @(true),
        };
        NSData* encodedReply = [[FlutterJSONMessageCodec sharedInstance] encode:reply];
        handler(encodedReply);
      }));
  OCMExpect(  // NOLINT(google-objc-avoid-throwing-exception)
      [binaryMessengerMock sendOnChannel:@"flutter/keyevent"
                                 message:encodedKeyUpEvent
                             binaryReply:[OCMArg any]])
      .andDo((^(NSInvocation* invocation) {
        FlutterBinaryReply handler;
        [invocation getArgument:&handler atIndex:4];
        NSDictionary* reply = @{
          @"handled" : @(true),
        };
        NSData* encodedReply = [[FlutterJSONMessageCodec sharedInstance] encode:reply];
        handler(encodedReply);
      }));
  [viewController viewWillAppear];  // Initializes the event channel.
  [viewController performKeyEquivalent:event];
  @try {
    OCMVerify(  // NOLINT(google-objc-avoid-throwing-exception)
        [binaryMessengerMock sendOnChannel:@"flutter/keyevent"
                                   message:encodedKeyDownEvent
                               binaryReply:[OCMArg any]]);
    OCMVerify(  // NOLINT(google-objc-avoid-throwing-exception)
        [binaryMessengerMock sendOnChannel:@"flutter/keyevent"
                                   message:encodedKeyUpEvent
                               binaryReply:[OCMArg any]]);
  } @catch (...) {
    return false;
  }
  return true;
}

+ (void)respondFalseForSendEvent:(const FlutterKeyEvent&)event
                        callback:(nullable FlutterKeyEventCallback)callback
                        userData:(nullable void*)userData {
  if (callback != nullptr)
    callback(false, userData);
}

@end
