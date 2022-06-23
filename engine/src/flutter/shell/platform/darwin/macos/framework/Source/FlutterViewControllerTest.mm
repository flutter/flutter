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
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterMetalRenderer.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterViewControllerTestUtils.h"
#import "flutter/testing/testing.h"

@interface FlutterViewControllerTestObjC : NSObject
- (bool)testKeyEventsAreSentToFramework;
- (bool)testKeyEventsArePropagatedIfNotHandled;
- (bool)testKeyEventsAreNotPropagatedIfHandled;
- (bool)testFlagsChangedEventsArePropagatedIfNotHandled;
- (bool)testKeyboardIsRestartedOnEngineRestart;
- (bool)testTrackpadGesturesAreSentToFramework;
- (bool)testViewWillAppearCalledMultipleTimes;

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

TEST(FlutterViewController, HasViewThatHidesOtherViewsInAccessibility) {
  FlutterViewController* viewControllerMock = CreateMockViewController();

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

TEST(FlutterViewController, FlutterViewAcceptsFirstMouse) {
  FlutterViewController* viewControllerMock = CreateMockViewController();
  [viewControllerMock loadView];
  EXPECT_EQ([viewControllerMock.flutterView acceptsFirstMouse:nil], YES);
}

TEST(FlutterViewController, ReparentsPluginWhenAccessibilityDisabled) {
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
  NSView* dummyView = [[NSView alloc] initWithFrame:CGRectZero];
  [viewController.view addSubview:dummyView];
  // Attaches FlutterTextInputPlugin to the view;
  [dummyView addSubview:viewController.textInputPlugin];
  // Makes sure the textInputPlugin can be the first responder.
  EXPECT_TRUE([window makeFirstResponder:viewController.textInputPlugin]);
  EXPECT_EQ([window firstResponder], viewController.textInputPlugin);
  EXPECT_FALSE(viewController.textInputPlugin.superview == viewController.view);
  [viewController onAccessibilityStatusChanged:NO];
  // FlutterView becomes child of view controller
  EXPECT_TRUE(viewController.textInputPlugin.superview == viewController.view);
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

TEST(FlutterViewControllerTest, TestKeyboardIsRestartedOnEngineRestart) {
  ASSERT_TRUE([[FlutterViewControllerTestObjC alloc] testKeyboardIsRestartedOnEngineRestart]);
}

TEST(FlutterViewControllerTest, TestTrackpadGesturesAreSentToFramework) {
  ASSERT_TRUE([[FlutterViewControllerTestObjC alloc] testTrackpadGesturesAreSentToFramework]);
}

TEST(FlutterViewControllerTest, testViewWillAppearCalledMultipleTimes) {
  ASSERT_TRUE([[FlutterViewControllerTestObjC alloc] testViewWillAppearCalledMultipleTimes]);
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

- (bool)testKeyboardIsRestartedOnEngineRestart {
  id engineMock = OCMClassMock([FlutterEngine class]);
  id binaryMessengerMock = OCMProtocolMock(@protocol(FlutterBinaryMessenger));
  OCMStub(  // NOLINT(google-objc-avoid-throwing-exception)
      [engineMock binaryMessenger])
      .andReturn(binaryMessengerMock);
  __block bool called = false;
  __block FlutterKeyEvent last_event;
  OCMStub([[engineMock ignoringNonObjectArgs] sendKeyEvent:FlutterKeyEvent {}
                                                  callback:nil
                                                  userData:nil])
      .andDo((^(NSInvocation* invocation) {
        FlutterKeyEvent* event;
        [invocation getArgument:&event atIndex:2];
        called = true;
        last_event = *event;
      }));

  FlutterViewController* viewController = [[FlutterViewController alloc] initWithEngine:engineMock
                                                                                nibName:@""
                                                                                 bundle:nil];
  [viewController viewWillAppear];
  NSEvent* keyADown = [NSEvent keyEventWithType:NSEventTypeKeyDown
                                       location:NSZeroPoint
                                  modifierFlags:0x100
                                      timestamp:0
                                   windowNumber:0
                                        context:nil
                                     characters:@"a"
                    charactersIgnoringModifiers:@"a"
                                      isARepeat:FALSE
                                        keyCode:0];
  const uint64_t kPhysicalKeyA = 0x70004;

  // Send KeyA key down event twice. Without restarting the keyboard during
  // onPreEngineRestart, the second event received will be an empty event with
  // physical key 0x0 because duplicate key down events are ignored.

  called = false;
  [viewController keyDown:keyADown];
  EXPECT_TRUE(called);
  EXPECT_EQ(last_event.type, kFlutterKeyEventTypeDown);
  EXPECT_EQ(last_event.physical, kPhysicalKeyA);

  [viewController onPreEngineRestart];

  called = false;
  [viewController keyDown:keyADown];
  EXPECT_TRUE(called);
  EXPECT_EQ(last_event.type, kFlutterKeyEventTypeDown);
  EXPECT_EQ(last_event.physical, kPhysicalKeyA);
  return true;
}

+ (void)respondFalseForSendEvent:(const FlutterKeyEvent&)event
                        callback:(nullable FlutterKeyEventCallback)callback
                        userData:(nullable void*)userData {
  if (callback != nullptr) {
    callback(false, userData);
  }
}

- (bool)testTrackpadGesturesAreSentToFramework {
  id engineMock = OCMClassMock([FlutterEngine class]);
  // Need to return a real renderer to allow view controller to load.
  id renderer_ = [[FlutterMetalRenderer alloc] initWithFlutterEngine:engineMock];
  OCMStub([engineMock renderer]).andReturn(renderer_);
  __block bool called = false;
  __block FlutterPointerEvent last_event;
  OCMStub([[engineMock ignoringNonObjectArgs] sendPointerEvent:FlutterPointerEvent{}])
      .andDo((^(NSInvocation* invocation) {
        FlutterPointerEvent* event;
        [invocation getArgument:&event atIndex:2];
        called = true;
        last_event = *event;
      }));

  FlutterViewController* viewController = [[FlutterViewController alloc] initWithEngine:engineMock
                                                                                nibName:@""
                                                                                 bundle:nil];
  [viewController loadView];

  // Start gesture.
  CGEventRef cgEventStart = CGEventCreateScrollWheelEvent(NULL, kCGScrollEventUnitPixel, 1, 0);
  CGEventSetType(cgEventStart, kCGEventScrollWheel);
  CGEventSetIntegerValueField(cgEventStart, kCGScrollWheelEventScrollPhase, kCGScrollPhaseBegan);
  CGEventSetIntegerValueField(cgEventStart, kCGScrollWheelEventIsContinuous, 1);

  called = false;
  [viewController scrollWheel:[NSEvent eventWithCGEvent:cgEventStart]];
  EXPECT_TRUE(called);
  EXPECT_EQ(last_event.signal_kind, kFlutterPointerSignalKindNone);
  EXPECT_EQ(last_event.phase, kPanZoomStart);
  EXPECT_EQ(last_event.device_kind, kFlutterPointerDeviceKindTrackpad);
  EXPECT_EQ(last_event.signal_kind, kFlutterPointerSignalKindNone);

  // Update gesture.
  CGEventRef cgEventUpdate = CGEventCreateCopy(cgEventStart);
  CGEventSetIntegerValueField(cgEventUpdate, kCGScrollWheelEventScrollPhase, kCGScrollPhaseChanged);
  CGEventSetIntegerValueField(cgEventUpdate, kCGScrollWheelEventDeltaAxis2, 1);  // pan_x
  CGEventSetIntegerValueField(cgEventUpdate, kCGScrollWheelEventDeltaAxis1, 2);  // pan_y

  called = false;
  [viewController scrollWheel:[NSEvent eventWithCGEvent:cgEventUpdate]];
  EXPECT_TRUE(called);
  EXPECT_EQ(last_event.signal_kind, kFlutterPointerSignalKindNone);
  EXPECT_EQ(last_event.phase, kPanZoomUpdate);
  EXPECT_EQ(last_event.device_kind, kFlutterPointerDeviceKindTrackpad);
  EXPECT_EQ(last_event.signal_kind, kFlutterPointerSignalKindNone);
  EXPECT_EQ(last_event.pan_x, 8 * viewController.flutterView.layer.contentsScale);
  EXPECT_EQ(last_event.pan_y, 16 * viewController.flutterView.layer.contentsScale);

  // Make sure the pan values accumulate.
  called = false;
  [viewController scrollWheel:[NSEvent eventWithCGEvent:cgEventUpdate]];
  EXPECT_TRUE(called);
  EXPECT_EQ(last_event.signal_kind, kFlutterPointerSignalKindNone);
  EXPECT_EQ(last_event.phase, kPanZoomUpdate);
  EXPECT_EQ(last_event.device_kind, kFlutterPointerDeviceKindTrackpad);
  EXPECT_EQ(last_event.signal_kind, kFlutterPointerSignalKindNone);
  EXPECT_EQ(last_event.pan_x, 16 * viewController.flutterView.layer.contentsScale);
  EXPECT_EQ(last_event.pan_y, 32 * viewController.flutterView.layer.contentsScale);

  // End gesture.
  CGEventRef cgEventEnd = CGEventCreateCopy(cgEventStart);
  CGEventSetIntegerValueField(cgEventEnd, kCGScrollWheelEventScrollPhase, kCGScrollPhaseEnded);

  called = false;
  [viewController scrollWheel:[NSEvent eventWithCGEvent:cgEventEnd]];
  EXPECT_TRUE(called);
  EXPECT_EQ(last_event.signal_kind, kFlutterPointerSignalKindNone);
  EXPECT_EQ(last_event.phase, kPanZoomEnd);
  EXPECT_EQ(last_event.device_kind, kFlutterPointerDeviceKindTrackpad);
  EXPECT_EQ(last_event.signal_kind, kFlutterPointerSignalKindNone);

  // May-begin and cancel are used while macOS determines which type of gesture to choose.
  CGEventRef cgEventMayBegin = CGEventCreateCopy(cgEventStart);
  CGEventSetIntegerValueField(cgEventMayBegin, kCGScrollWheelEventScrollPhase,
                              kCGScrollPhaseMayBegin);

  called = false;
  [viewController scrollWheel:[NSEvent eventWithCGEvent:cgEventMayBegin]];
  EXPECT_TRUE(called);
  EXPECT_EQ(last_event.signal_kind, kFlutterPointerSignalKindNone);
  EXPECT_EQ(last_event.phase, kPanZoomStart);
  EXPECT_EQ(last_event.device_kind, kFlutterPointerDeviceKindTrackpad);
  EXPECT_EQ(last_event.signal_kind, kFlutterPointerSignalKindNone);

  // Cancel gesture.
  CGEventRef cgEventCancel = CGEventCreateCopy(cgEventStart);
  CGEventSetIntegerValueField(cgEventCancel, kCGScrollWheelEventScrollPhase,
                              kCGScrollPhaseCancelled);

  called = false;
  [viewController scrollWheel:[NSEvent eventWithCGEvent:cgEventCancel]];
  EXPECT_TRUE(called);
  EXPECT_EQ(last_event.signal_kind, kFlutterPointerSignalKindNone);
  EXPECT_EQ(last_event.phase, kPanZoomEnd);
  EXPECT_EQ(last_event.device_kind, kFlutterPointerDeviceKindTrackpad);
  EXPECT_EQ(last_event.signal_kind, kFlutterPointerSignalKindNone);

  // A discrete scroll event should use the PointerSignal system.
  CGEventRef cgEventDiscrete = CGEventCreateScrollWheelEvent(NULL, kCGScrollEventUnitPixel, 1, 0);
  CGEventSetType(cgEventDiscrete, kCGEventScrollWheel);
  CGEventSetIntegerValueField(cgEventDiscrete, kCGScrollWheelEventIsContinuous, 0);
  CGEventSetIntegerValueField(cgEventDiscrete, kCGScrollWheelEventDeltaAxis2, 1);  // scroll_delta_x
  CGEventSetIntegerValueField(cgEventDiscrete, kCGScrollWheelEventDeltaAxis1, 2);  // scroll_delta_y

  called = false;
  [viewController scrollWheel:[NSEvent eventWithCGEvent:cgEventDiscrete]];
  EXPECT_TRUE(called);
  EXPECT_EQ(last_event.signal_kind, kFlutterPointerSignalKindScroll);
  // pixelsPerLine is 40.0 and direction is reversed.
  EXPECT_EQ(last_event.scroll_delta_x, -40 * viewController.flutterView.layer.contentsScale);
  EXPECT_EQ(last_event.scroll_delta_y, -80 * viewController.flutterView.layer.contentsScale);

  return true;
}

- (bool)testViewWillAppearCalledMultipleTimes {
  id engineMock = OCMClassMock([FlutterEngine class]);
  FlutterViewController* viewController = [[FlutterViewController alloc] initWithEngine:engineMock
                                                                                nibName:@""
                                                                                 bundle:nil];
  [viewController viewWillAppear];
  [viewController viewWillAppear];
  return true;
}

@end
