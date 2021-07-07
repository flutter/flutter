// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>
#import <OCMock/OCMock.h>
#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#include <_types/_uint32_t.h>

#import "flutter/shell/platform/darwin/common/framework/Headers/FlutterMacros.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterFakeKeyEvents.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterKeyboardManager.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterUIPressProxy.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterViewController_Internal.h"

FLUTTER_ASSERT_ARC;

namespace flutter {
class PointerDataPacket {};
}

/// Sometimes we have to use a custom mock to avoid retain cycles in ocmock.
@interface FlutterEnginePartialMock : FlutterEngine
@property(nonatomic, strong) FlutterBasicMessageChannel* lifecycleChannel;
@property(nonatomic, weak) FlutterViewController* viewController;
@property(nonatomic, assign) BOOL didCallNotifyLowMemory;
@end

@interface FlutterEngine ()
- (BOOL)createShell:(NSString*)entrypoint
         libraryURI:(NSString*)libraryURI
       initialRoute:(NSString*)initialRoute;
- (void)dispatchPointerDataPacket:(std::unique_ptr<flutter::PointerDataPacket>)packet;
@end

@interface FlutterEngine (TestLowMemory)
- (void)notifyLowMemory;
@end

extern NSNotificationName const FlutterViewControllerWillDealloc;

/// A simple mock class for FlutterEngine.
///
/// OCMockClass can't be used for FlutterEngine sometimes because OCMock retains arguments to
/// invocations and since the init for FlutterViewController calls a method on the
/// FlutterEngine it creates a retain cycle that stops us from testing behaviors related to
/// deleting FlutterViewControllers.
@interface MockEngine : NSObject
@end

@interface FlutterKeyboardManagerUnittestsObjC : NSObject
- (bool)nextResponderShouldThrowOnPressesEnded;
- (bool)singlePrimaryResponder;
- (bool)doublePrimaryResponder;
- (bool)singleSecondaryResponder;
- (bool)emptyNextResponder;
@end

namespace {

typedef void (^KeyCallbackSetter)(FlutterAsyncKeyCallback callback);
typedef BOOL (^BoolGetter)();

}  // namespace

@interface FlutterKeyboardManagerTest : XCTestCase
@property(nonatomic, strong) id mockEngine;
- (FlutterViewController*)mockOwnerWithPressesBeginOnlyNext API_AVAILABLE(ios(13.4));
@end

@implementation FlutterKeyboardManagerTest

- (void)setUp {
  [super setUp];
  self.mockEngine = OCMClassMock([FlutterEngine class]);
}

- (void)tearDown {
  // We stop mocking here to avoid retain cycles that stop
  // FlutterViewControllers from deallocing.
  [self.mockEngine stopMocking];
  self.mockEngine = nil;
  [super tearDown];
}

- (id)checkKeyDownEvent:(UIKeyboardHIDUsage)keyCode API_AVAILABLE(ios(13.4)) {
  return [OCMArg checkWithBlock:^BOOL(id value) {
    if (![value isKindOfClass:[FlutterUIPressProxy class]]) {
      return NO;
    }
    FlutterUIPressProxy* press = value;
    return press.key.keyCode == keyCode;
  }];
}

- (id<FlutterKeyPrimaryResponder>)mockPrimaryResponder:(KeyCallbackSetter)callbackSetter
    API_AVAILABLE(ios(13.4)) {
  id<FlutterKeyPrimaryResponder> mock =
      OCMStrictProtocolMock(@protocol(FlutterKeyPrimaryResponder));
  OCMStub([mock handlePress:[OCMArg any] callback:[OCMArg any]])
      .andDo((^(NSInvocation* invocation) {
        FlutterAsyncKeyCallback callback;
        [invocation getArgument:&callback atIndex:3];
        CFRunLoopPerformBlock(CFRunLoopGetCurrent(), kCFRunLoopDefaultMode, ^() {
          callbackSetter(callback);
        });
      }));
  return mock;
}

- (id<FlutterKeySecondaryResponder>)mockSecondaryResponder:(BoolGetter)resultGetter
    API_AVAILABLE(ios(13.4)) {
  id<FlutterKeySecondaryResponder> mock =
      OCMStrictProtocolMock(@protocol(FlutterKeySecondaryResponder));
  OCMStub([mock handlePress:[OCMArg any]]).andDo((^(NSInvocation* invocation) {
    BOOL result = resultGetter();
    [invocation setReturnValue:&result];
  }));
  return mock;
}

- (FlutterViewController*)mockOwnerWithPressesBeginOnlyNext API_AVAILABLE(ios(13.4)) {
  // The nextResponder is a strict mock and hasn't stubbed pressesEnded.
  // An error will be thrown on pressesEnded.
  UIResponder* nextResponder = OCMStrictClassMock([UIResponder class]);
  OCMStub([nextResponder pressesBegan:[OCMArg any] withEvent:[OCMArg any]]).andDo(nil);

  FlutterViewController* viewController =
      [[FlutterViewController alloc] initWithEngine:self.mockEngine nibName:nil bundle:nil];
  FlutterViewController* owner = OCMPartialMock(viewController);
  OCMStub([owner nextResponder]).andReturn(nextResponder);
  return owner;
}

// Verify that the nextResponder returned from mockOwnerWithPressesBeginOnlyNext()
// throws exception when pressesEnded is called.
- (bool)testNextResponderShouldThrowOnPressesEnded API_AVAILABLE(ios(13.4)) {
  FlutterViewController* owner = [self mockOwnerWithPressesBeginOnlyNext];
  @try {
    [owner.nextResponder pressesEnded:[NSSet init] withEvent:[[UIPressesEvent alloc] init]];
    return false;
  } @catch (...) {
    return true;
  }
}

- (void)testSinglePrimaryResponder API_AVAILABLE(ios(13.4)) {
  FlutterKeyboardManager* manager = [[FlutterKeyboardManager alloc] init];
  __block BOOL primaryResponse = FALSE;
  __block int callbackCount = 0;
  [manager addPrimaryResponder:[self mockPrimaryResponder:^(FlutterAsyncKeyCallback callback) {
             callbackCount++;
             callback(primaryResponse);
           }]];
  constexpr UIKeyboardHIDUsage keyId = (UIKeyboardHIDUsage)0x50;
  // Case: The responder reports TRUE
  __block bool completeHandled = true;
  primaryResponse = TRUE;
  [manager handlePress:keyDownEvent(keyId)
            nextAction:^() {
              completeHandled = false;
            }];
  XCTAssertEqual(callbackCount, 1);
  XCTAssertTrue(completeHandled);
  completeHandled = true;
  callbackCount = 0;

  // Case: The responder reports FALSE
  primaryResponse = FALSE;
  [manager handlePress:keyUpEvent(keyId)
            nextAction:^() {
              completeHandled = false;
            }];
  XCTAssertEqual(callbackCount, 1);
  XCTAssertFalse(completeHandled);
}

- (void)testDoublePrimaryResponder API_AVAILABLE(ios(13.4)) {
  FlutterKeyboardManager* manager = [[FlutterKeyboardManager alloc] init];

  __block BOOL callback1Response = FALSE;
  __block int callback1Count = 0;
  [manager addPrimaryResponder:[self mockPrimaryResponder:^(FlutterAsyncKeyCallback callback) {
             callback1Count++;
             callback(callback1Response);
           }]];

  __block BOOL callback2Response = FALSE;
  __block int callback2Count = 0;
  [manager addPrimaryResponder:[self mockPrimaryResponder:^(FlutterAsyncKeyCallback callback) {
             callback2Count++;
             callback(callback2Response);
           }]];

  // Case: Both responders report TRUE.
  __block bool somethingWasHandled = true;
  constexpr UIKeyboardHIDUsage keyId = (UIKeyboardHIDUsage)0x50;
  callback1Response = TRUE;
  callback2Response = TRUE;
  [manager handlePress:keyUpEvent(keyId)
            nextAction:^() {
              somethingWasHandled = false;
            }];
  XCTAssertEqual(callback1Count, 1);
  XCTAssertEqual(callback2Count, 1);
  XCTAssertTrue(somethingWasHandled);

  somethingWasHandled = true;
  callback1Count = 0;
  callback2Count = 0;

  // Case: One responder reports TRUE.
  callback1Response = TRUE;
  callback2Response = FALSE;
  [manager handlePress:keyUpEvent(keyId)
            nextAction:^() {
              somethingWasHandled = false;
            }];
  XCTAssertEqual(callback1Count, 1);
  XCTAssertEqual(callback2Count, 1);
  XCTAssertTrue(somethingWasHandled);

  somethingWasHandled = true;
  callback1Count = 0;
  callback2Count = 0;

  // Case: Both responders report FALSE.
  callback1Response = FALSE;
  callback2Response = FALSE;
  [manager handlePress:keyDownEvent(keyId)
            nextAction:^() {
              somethingWasHandled = false;
            }];
  XCTAssertEqual(callback1Count, 1);
  XCTAssertEqual(callback2Count, 1);
  XCTAssertFalse(somethingWasHandled);
}

- (void)testSingleSecondaryResponder API_AVAILABLE(ios(13.4)) {
  FlutterKeyboardManager* manager = [[FlutterKeyboardManager alloc] init];

  __block BOOL primaryResponse = FALSE;
  __block int callbackCount = 0;
  [manager addPrimaryResponder:[self mockPrimaryResponder:^(FlutterAsyncKeyCallback callback) {
             callbackCount++;
             callback(primaryResponse);
           }]];

  __block BOOL secondaryResponse;
  [manager addSecondaryResponder:[self mockSecondaryResponder:^() {
             return secondaryResponse;
           }]];

  // Case: Primary responder responds TRUE. The event shouldn't be handled by
  // the secondary responder.
  constexpr UIKeyboardHIDUsage keyId = (UIKeyboardHIDUsage)0x50;
  secondaryResponse = FALSE;
  primaryResponse = TRUE;
  __block bool completeHandled = true;
  [manager handlePress:keyUpEvent(keyId)
            nextAction:^() {
              completeHandled = false;
            }];
  XCTAssertEqual(callbackCount, 1);
  XCTAssertTrue(completeHandled);
  completeHandled = true;
  callbackCount = 0;

  // Case: Primary responder responds FALSE. The secondary responder returns
  // TRUE.
  secondaryResponse = TRUE;
  primaryResponse = FALSE;
  [manager handlePress:keyUpEvent(keyId)
            nextAction:^() {
              completeHandled = false;
            }];
  XCTAssertEqual(callbackCount, 1);
  XCTAssertTrue(completeHandled);
  completeHandled = true;
  callbackCount = 0;

  // Case: Primary responder responds FALSE. The secondary responder returns FALSE.
  secondaryResponse = FALSE;
  primaryResponse = FALSE;
  [manager handlePress:keyDownEvent(keyId)
            nextAction:^() {
              completeHandled = false;
            }];
  XCTAssertEqual(callbackCount, 1);
  XCTAssertFalse(completeHandled);
}

@end
