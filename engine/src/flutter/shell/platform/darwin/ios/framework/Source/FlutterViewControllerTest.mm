// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#include "flutter/fml/platform/darwin/message_loop_darwin.h"
#import "flutter/lib/ui/window/platform_configuration.h"
#include "flutter/lib/ui/window/pointer_data.h"
#import "flutter/lib/ui/window/viewport_metrics.h"
#import "flutter/shell/platform/darwin/common/framework/Headers/FlutterBinaryMessenger.h"
#import "flutter/shell/platform/darwin/common/framework/Headers/FlutterMacros.h"
#import "flutter/shell/platform/darwin/ios/framework/Headers/FlutterViewController.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterEmbedderKeyResponder.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterFakeKeyEvents.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterTextInputPlugin.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterViewController_Internal.h"
#import "flutter/shell/platform/embedder/embedder.h"
#import "flutter/third_party/spring_animation/spring_animation.h"

FLUTTER_ASSERT_ARC

@interface FlutterEngine ()
- (FlutterTextInputPlugin*)textInputPlugin;
- (void)sendKeyEvent:(const FlutterKeyEvent&)event
            callback:(nullable FlutterKeyEventCallback)callback
            userData:(nullable void*)userData;
- (fml::RefPtr<fml::TaskRunner>)uiTaskRunner;
@end

/// Sometimes we have to use a custom mock to avoid retain cycles in OCMock.
/// Used for testing low memory notification.
@interface FlutterEnginePartialMock : FlutterEngine
@property(nonatomic, strong) FlutterBasicMessageChannel* lifecycleChannel;
@property(nonatomic, strong) FlutterBasicMessageChannel* keyEventChannel;
@property(nonatomic, weak) FlutterViewController* viewController;
@property(nonatomic, strong) FlutterTextInputPlugin* textInputPlugin;
@property(nonatomic, assign) BOOL didCallNotifyLowMemory;
- (FlutterTextInputPlugin*)textInputPlugin;
- (void)sendKeyEvent:(const FlutterKeyEvent&)event
            callback:(nullable FlutterKeyEventCallback)callback
            userData:(nullable void*)userData;
@end

@implementation FlutterEnginePartialMock
@synthesize viewController;
@synthesize lifecycleChannel;
@synthesize keyEventChannel;
@synthesize textInputPlugin;

- (void)notifyLowMemory {
  _didCallNotifyLowMemory = YES;
}

- (void)sendKeyEvent:(const FlutterKeyEvent&)event
            callback:(FlutterKeyEventCallback)callback
            userData:(void*)userData API_AVAILABLE(ios(9.0)) {
  if (callback == nil)
    return;
  // NSAssert(callback != nullptr, @"Invalid callback");
  // Response is async, so we have to post it to the run loop instead of calling
  // it directly.
  CFRunLoopPerformBlock(CFRunLoopGetCurrent(), fml::MessageLoopDarwin::kMessageLoopCFRunLoopMode,
                        ^() {
                          callback(true, userData);
                        });
}
@end

@interface FlutterEngine ()
- (BOOL)createShell:(NSString*)entrypoint
         libraryURI:(NSString*)libraryURI
       initialRoute:(NSString*)initialRoute;
- (void)dispatchPointerDataPacket:(std::unique_ptr<flutter::PointerDataPacket>)packet;
- (void)updateViewportMetrics:(flutter::ViewportMetrics)viewportMetrics;
- (void)attachView;
@end

@interface FlutterEngine (TestLowMemory)
- (void)notifyLowMemory;
@end

extern NSNotificationName const FlutterViewControllerWillDealloc;

/// A simple mock class for FlutterEngine.
///
/// OCMClassMock can't be used for FlutterEngine sometimes because OCMock retains arguments to
/// invocations and since the init for FlutterViewController calls a method on the
/// FlutterEngine it creates a retain cycle that stops us from testing behaviors related to
/// deleting FlutterViewControllers.
///
/// Used for testing deallocation.
@interface MockEngine : NSObject
@property(nonatomic, strong) FlutterDartProject* project;
@end

@implementation MockEngine
- (FlutterViewController*)viewController {
  return nil;
}
- (void)setViewController:(FlutterViewController*)viewController {
  // noop
}
@end

@interface FlutterKeyboardManager (Tests)
@property(nonatomic, retain, readonly)
    NSMutableArray<id<FlutterKeyPrimaryResponder>>* primaryResponders;
@end

@interface FlutterEmbedderKeyResponder (Tests)
@property(nonatomic, copy, readonly) FlutterSendKeyEvent sendEvent;
@end

@interface FlutterViewController (Tests)

@property(nonatomic, assign) double targetViewInsetBottom;
@property(nonatomic, assign) BOOL isKeyboardInOrTransitioningFromBackground;
@property(nonatomic, assign) BOOL keyboardAnimationIsShowing;

- (void)createTouchRateCorrectionVSyncClientIfNeeded;
- (void)surfaceUpdated:(BOOL)appeared;
- (void)performOrientationUpdate:(UIInterfaceOrientationMask)new_preferences;
- (void)handlePressEvent:(FlutterUIPressProxy*)press
              nextAction:(void (^)())next API_AVAILABLE(ios(13.4));
- (void)discreteScrollEvent:(UIPanGestureRecognizer*)recognizer;
- (void)updateViewportMetricsIfNeeded;
- (void)onUserSettingsChanged:(NSNotification*)notification;
- (void)applicationWillTerminate:(NSNotification*)notification;
- (void)goToApplicationLifecycle:(nonnull NSString*)state;
- (UIScreen*)mainScreenIfViewLoaded;
- (void)handleKeyboardNotification:(NSNotification*)notification;
- (CGFloat)calculateKeyboardInset:(CGRect)keyboardFrame keyboardMode:(int)keyboardMode;
- (BOOL)shouldIgnoreKeyboardNotification:(NSNotification*)notification;
- (FlutterKeyboardMode)calculateKeyboardAttachMode:(NSNotification*)notification;
- (CGFloat)calculateMultitaskingAdjustment:(CGRect)screenRect keyboardFrame:(CGRect)keyboardFrame;
- (void)startKeyBoardAnimation:(NSTimeInterval)duration;
- (UIView*)keyboardAnimationView;
- (SpringAnimation*)keyboardSpringAnimation;
- (void)setupKeyboardSpringAnimationIfNeeded:(CAAnimation*)keyboardAnimation;
- (void)setupKeyboardAnimationVsyncClient:
    (FlutterKeyboardAnimationCallback)keyboardAnimationCallback;
- (void)ensureViewportMetricsIsCorrect;
- (void)invalidateKeyboardAnimationVSyncClient;
- (void)addInternalPlugins;
- (flutter::PointerData)generatePointerDataForFake;
- (void)sharedSetupWithProject:(nullable FlutterDartProject*)project
                  initialRoute:(nullable NSString*)initialRoute;
@end

@interface FlutterViewControllerTest : XCTestCase
@property(nonatomic, strong) id mockEngine;
@property(nonatomic, strong) id mockTextInputPlugin;
@property(nonatomic, strong) id messageSent;
- (void)sendMessage:(id _Nullable)message reply:(FlutterReply _Nullable)callback;
@end

@implementation FlutterViewControllerTest

- (void)setUp {
  self.mockEngine = OCMClassMock([FlutterEngine class]);
  self.mockTextInputPlugin = OCMClassMock([FlutterTextInputPlugin class]);
  OCMStub([self.mockEngine textInputPlugin]).andReturn(self.mockTextInputPlugin);
  self.messageSent = nil;
}

- (void)tearDown {
  // We stop mocking here to avoid retain cycles that stop
  // FlutterViewControllers from deallocing.
  [self.mockEngine stopMocking];
  self.mockEngine = nil;
  self.mockTextInputPlugin = nil;
  self.messageSent = nil;
}

- (id)setupMockMainScreenAndView:(FlutterViewController*)viewControllerMock
                       viewFrame:(CGRect)viewFrame
                  convertedFrame:(CGRect)convertedFrame {
  OCMStub([viewControllerMock mainScreenIfViewLoaded]).andReturn(UIScreen.mainScreen);
  id mockView = OCMClassMock([UIView class]);
  OCMStub([mockView frame]).andReturn(viewFrame);
  OCMStub([mockView convertRect:viewFrame toCoordinateSpace:[OCMArg any]])
      .andReturn(convertedFrame);
  OCMStub([viewControllerMock viewIfLoaded]).andReturn(mockView);

  return mockView;
}

- (void)testViewDidLoadWillInvokeCreateTouchRateCorrectionVSyncClient {
  FlutterEngine* engine = [[FlutterEngine alloc] init];
  [engine runWithEntrypoint:nil];
  FlutterViewController* viewController = [[FlutterViewController alloc] initWithEngine:engine
                                                                                nibName:nil
                                                                                 bundle:nil];
  FlutterViewController* viewControllerMock = OCMPartialMock(viewController);
  [viewControllerMock loadView];
  [viewControllerMock viewDidLoad];
  OCMVerify([viewControllerMock createTouchRateCorrectionVSyncClientIfNeeded]);
}

- (void)testStartKeyboardAnimationWillInvokeSetupKeyboardSpringAnimationIfNeeded {
  FlutterEngine* engine = [[FlutterEngine alloc] init];
  [engine runWithEntrypoint:nil];
  FlutterViewController* viewController = [[FlutterViewController alloc] initWithEngine:engine
                                                                                nibName:nil
                                                                                 bundle:nil];
  FlutterViewController* viewControllerMock = OCMPartialMock(viewController);
  viewControllerMock.targetViewInsetBottom = 100;
  [viewControllerMock startKeyBoardAnimation:0.25];

  CAAnimation* keyboardAnimation =
      [[viewControllerMock keyboardAnimationView].layer animationForKey:@"position"];

  OCMVerify([viewControllerMock setupKeyboardSpringAnimationIfNeeded:keyboardAnimation]);
}

- (void)testSetupKeyboardSpringAnimationIfNeeded {
  FlutterEngine* engine = [[FlutterEngine alloc] init];
  [engine runWithEntrypoint:nil];
  FlutterViewController* viewController = [[FlutterViewController alloc] initWithEngine:engine
                                                                                nibName:nil
                                                                                 bundle:nil];
  FlutterViewController* viewControllerMock = OCMPartialMock(viewController);
  CGRect viewFrame = UIScreen.mainScreen.bounds;
  [self setupMockMainScreenAndView:viewControllerMock viewFrame:viewFrame convertedFrame:viewFrame];

  // Null check.
  [viewControllerMock setupKeyboardSpringAnimationIfNeeded:nil];
  SpringAnimation* keyboardSpringAnimation = [viewControllerMock keyboardSpringAnimation];
  XCTAssertTrue(keyboardSpringAnimation == nil);

  // CAAnimation that is not a CASpringAnimation.
  CABasicAnimation* nonSpringAnimation = [CABasicAnimation animation];
  nonSpringAnimation.duration = 1.0;
  nonSpringAnimation.fromValue = [NSNumber numberWithFloat:0.0];
  nonSpringAnimation.toValue = [NSNumber numberWithFloat:1.0];
  nonSpringAnimation.keyPath = @"position";
  [viewControllerMock setupKeyboardSpringAnimationIfNeeded:nonSpringAnimation];
  keyboardSpringAnimation = [viewControllerMock keyboardSpringAnimation];

  XCTAssertTrue(keyboardSpringAnimation == nil);

  // CASpringAnimation.
  CASpringAnimation* springAnimation = [CASpringAnimation animation];
  springAnimation.mass = 1.0;
  springAnimation.stiffness = 100.0;
  springAnimation.damping = 10.0;
  springAnimation.keyPath = @"position";
  springAnimation.fromValue = [NSValue valueWithCGPoint:CGPointMake(0, 0)];
  springAnimation.toValue = [NSValue valueWithCGPoint:CGPointMake(100, 100)];
  [viewControllerMock setupKeyboardSpringAnimationIfNeeded:springAnimation];
  keyboardSpringAnimation = [viewControllerMock keyboardSpringAnimation];
  XCTAssertTrue(keyboardSpringAnimation != nil);
}

- (void)testKeyboardAnimationIsShowingAndCompounding {
  FlutterEngine* engine = [[FlutterEngine alloc] init];
  [engine runWithEntrypoint:nil];
  FlutterViewController* viewController = [[FlutterViewController alloc] initWithEngine:engine
                                                                                nibName:nil
                                                                                 bundle:nil];
  FlutterViewController* viewControllerMock = OCMPartialMock(viewController);
  CGRect viewFrame = UIScreen.mainScreen.bounds;
  [self setupMockMainScreenAndView:viewControllerMock viewFrame:viewFrame convertedFrame:viewFrame];

  BOOL isLocal = YES;
  CGFloat screenHeight = UIScreen.mainScreen.bounds.size.height;
  CGFloat screenWidth = UIScreen.mainScreen.bounds.size.height;

  // Start show keyboard animation.
  CGRect initialShowKeyboardBeginFrame = CGRectMake(0, screenHeight, screenWidth, 250);
  CGRect initialShowKeyboardEndFrame = CGRectMake(0, screenHeight - 250, screenWidth, 500);
  NSNotification* fakeNotification = [NSNotification
      notificationWithName:UIKeyboardWillChangeFrameNotification
                    object:nil
                  userInfo:@{
                    @"UIKeyboardFrameBeginUserInfoKey" : @(initialShowKeyboardBeginFrame),
                    @"UIKeyboardFrameEndUserInfoKey" : @(initialShowKeyboardEndFrame),
                    @"UIKeyboardAnimationDurationUserInfoKey" : @(0.25),
                    @"UIKeyboardIsLocalUserInfoKey" : @(isLocal)
                  }];
  viewControllerMock.targetViewInsetBottom = 0;
  [viewControllerMock handleKeyboardNotification:fakeNotification];
  BOOL isShowingAnimation1 = viewControllerMock.keyboardAnimationIsShowing;
  XCTAssertTrue(isShowingAnimation1);

  // Start compounding show keyboard animation.
  CGRect compoundingShowKeyboardBeginFrame = CGRectMake(0, screenHeight - 250, screenWidth, 250);
  CGRect compoundingShowKeyboardEndFrame = CGRectMake(0, screenHeight - 500, screenWidth, 500);
  fakeNotification = [NSNotification
      notificationWithName:UIKeyboardWillChangeFrameNotification
                    object:nil
                  userInfo:@{
                    @"UIKeyboardFrameBeginUserInfoKey" : @(compoundingShowKeyboardBeginFrame),
                    @"UIKeyboardFrameEndUserInfoKey" : @(compoundingShowKeyboardEndFrame),
                    @"UIKeyboardAnimationDurationUserInfoKey" : @(0.25),
                    @"UIKeyboardIsLocalUserInfoKey" : @(isLocal)
                  }];

  [viewControllerMock handleKeyboardNotification:fakeNotification];
  BOOL isShowingAnimation2 = viewControllerMock.keyboardAnimationIsShowing;
  XCTAssertTrue(isShowingAnimation2);
  XCTAssertTrue(isShowingAnimation1 == isShowingAnimation2);

  // Start hide keyboard animation.
  CGRect initialHideKeyboardBeginFrame = CGRectMake(0, screenHeight - 500, screenWidth, 250);
  CGRect initialHideKeyboardEndFrame = CGRectMake(0, screenHeight - 250, screenWidth, 500);
  fakeNotification = [NSNotification
      notificationWithName:UIKeyboardWillChangeFrameNotification
                    object:nil
                  userInfo:@{
                    @"UIKeyboardFrameBeginUserInfoKey" : @(initialHideKeyboardBeginFrame),
                    @"UIKeyboardFrameEndUserInfoKey" : @(initialHideKeyboardEndFrame),
                    @"UIKeyboardAnimationDurationUserInfoKey" : @(0.25),
                    @"UIKeyboardIsLocalUserInfoKey" : @(isLocal)
                  }];

  [viewControllerMock handleKeyboardNotification:fakeNotification];
  BOOL isShowingAnimation3 = viewControllerMock.keyboardAnimationIsShowing;
  XCTAssertFalse(isShowingAnimation3);
  XCTAssertTrue(isShowingAnimation2 != isShowingAnimation3);

  // Start compounding hide keyboard animation.
  CGRect compoundingHideKeyboardBeginFrame = CGRectMake(0, screenHeight - 250, screenWidth, 250);
  CGRect compoundingHideKeyboardEndFrame = CGRectMake(0, screenHeight, screenWidth, 500);
  fakeNotification = [NSNotification
      notificationWithName:UIKeyboardWillChangeFrameNotification
                    object:nil
                  userInfo:@{
                    @"UIKeyboardFrameBeginUserInfoKey" : @(compoundingHideKeyboardBeginFrame),
                    @"UIKeyboardFrameEndUserInfoKey" : @(compoundingHideKeyboardEndFrame),
                    @"UIKeyboardAnimationDurationUserInfoKey" : @(0.25),
                    @"UIKeyboardIsLocalUserInfoKey" : @(isLocal)
                  }];

  [viewControllerMock handleKeyboardNotification:fakeNotification];
  BOOL isShowingAnimation4 = viewControllerMock.keyboardAnimationIsShowing;
  XCTAssertFalse(isShowingAnimation4);
  XCTAssertTrue(isShowingAnimation3 == isShowingAnimation4);
}

- (void)testShouldIgnoreKeyboardNotification {
  FlutterEngine* mockEngine = OCMPartialMock([[FlutterEngine alloc] init]);
  [mockEngine createShell:@"" libraryURI:@"" initialRoute:nil];
  FlutterViewController* viewController = [[FlutterViewController alloc] initWithEngine:mockEngine
                                                                                nibName:nil
                                                                                 bundle:nil];
  FlutterViewController* viewControllerMock = OCMPartialMock(viewController);
  CGRect viewFrame = UIScreen.mainScreen.bounds;
  [self setupMockMainScreenAndView:viewControllerMock viewFrame:viewFrame convertedFrame:viewFrame];

  CGFloat screenWidth = UIScreen.mainScreen.bounds.size.width;
  CGFloat screenHeight = UIScreen.mainScreen.bounds.size.height;
  CGRect emptyKeyboard = CGRectZero;
  CGRect zeroHeightKeyboard = CGRectMake(0, 0, screenWidth, 0);
  CGRect validKeyboardEndFrame = CGRectMake(0, screenHeight - 320, screenWidth, 320);
  BOOL isLocal = NO;

  // Hide notification, valid keyboard
  NSNotification* notification =
      [NSNotification notificationWithName:UIKeyboardWillHideNotification
                                    object:nil
                                  userInfo:@{
                                    @"UIKeyboardFrameEndUserInfoKey" : @(validKeyboardEndFrame),
                                    @"UIKeyboardAnimationDurationUserInfoKey" : @0.25,
                                    @"UIKeyboardIsLocalUserInfoKey" : @(isLocal)
                                  }];

  BOOL shouldIgnore = [viewControllerMock shouldIgnoreKeyboardNotification:notification];
  XCTAssertTrue(shouldIgnore == NO);

  // All zero keyboard
  isLocal = YES;
  notification = [NSNotification notificationWithName:UIKeyboardWillChangeFrameNotification
                                               object:nil
                                             userInfo:@{
                                               @"UIKeyboardFrameEndUserInfoKey" : @(emptyKeyboard),
                                               @"UIKeyboardAnimationDurationUserInfoKey" : @0.25,
                                               @"UIKeyboardIsLocalUserInfoKey" : @(isLocal)
                                             }];
  shouldIgnore = [viewControllerMock shouldIgnoreKeyboardNotification:notification];
  XCTAssertTrue(shouldIgnore == YES);

  // Zero height keyboard
  isLocal = NO;
  notification =
      [NSNotification notificationWithName:UIKeyboardWillChangeFrameNotification
                                    object:nil
                                  userInfo:@{
                                    @"UIKeyboardFrameEndUserInfoKey" : @(zeroHeightKeyboard),
                                    @"UIKeyboardAnimationDurationUserInfoKey" : @0.25,
                                    @"UIKeyboardIsLocalUserInfoKey" : @(isLocal)
                                  }];
  shouldIgnore = [viewControllerMock shouldIgnoreKeyboardNotification:notification];
  XCTAssertTrue(shouldIgnore == NO);

  // Valid keyboard, triggered from another app
  isLocal = NO;
  notification =
      [NSNotification notificationWithName:UIKeyboardWillChangeFrameNotification
                                    object:nil
                                  userInfo:@{
                                    @"UIKeyboardFrameEndUserInfoKey" : @(validKeyboardEndFrame),
                                    @"UIKeyboardAnimationDurationUserInfoKey" : @0.25,
                                    @"UIKeyboardIsLocalUserInfoKey" : @(isLocal)
                                  }];
  shouldIgnore = [viewControllerMock shouldIgnoreKeyboardNotification:notification];
  XCTAssertTrue(shouldIgnore == YES);

  // Valid keyboard
  isLocal = YES;
  notification =
      [NSNotification notificationWithName:UIKeyboardWillChangeFrameNotification
                                    object:nil
                                  userInfo:@{
                                    @"UIKeyboardFrameEndUserInfoKey" : @(validKeyboardEndFrame),
                                    @"UIKeyboardAnimationDurationUserInfoKey" : @0.25,
                                    @"UIKeyboardIsLocalUserInfoKey" : @(isLocal)
                                  }];
  shouldIgnore = [viewControllerMock shouldIgnoreKeyboardNotification:notification];
  XCTAssertTrue(shouldIgnore == NO);

  if (@available(iOS 13.0, *)) {
    // noop
  } else {
    // Valid keyboard, keyboard is in background
    OCMStub([viewControllerMock isKeyboardInOrTransitioningFromBackground]).andReturn(YES);

    isLocal = YES;
    notification =
        [NSNotification notificationWithName:UIKeyboardWillChangeFrameNotification
                                      object:nil
                                    userInfo:@{
                                      @"UIKeyboardFrameEndUserInfoKey" : @(validKeyboardEndFrame),
                                      @"UIKeyboardAnimationDurationUserInfoKey" : @0.25,
                                      @"UIKeyboardIsLocalUserInfoKey" : @(isLocal)
                                    }];
    shouldIgnore = [viewControllerMock shouldIgnoreKeyboardNotification:notification];
    XCTAssertTrue(shouldIgnore == YES);
  }
}

- (void)testKeyboardAnimationWillWaitUIThreadVsync {
  // We need to make sure the new viewport metrics get sent after the
  // begin frame event has processed. And this test is to expect that the callback
  // will sync with UI thread. So just simulate a lot of works on UI thread and
  // test the keyboard animation callback will execute until UI task completed.
  // Related issue: https://github.com/flutter/flutter/issues/120555.

  FlutterEngine* engine = [[FlutterEngine alloc] init];
  [engine runWithEntrypoint:nil];
  FlutterViewController* viewController = [[FlutterViewController alloc] initWithEngine:engine
                                                                                nibName:nil
                                                                                 bundle:nil];
  // Post a task to UI thread to block the thread.
  const int delayTime = 1;
  [engine uiTaskRunner]->PostTask([] { sleep(delayTime); });
  XCTestExpectation* expectation = [self expectationWithDescription:@"keyboard animation callback"];

  __block CFTimeInterval fulfillTime;
  FlutterKeyboardAnimationCallback callback = ^(fml::TimePoint targetTime) {
    fulfillTime = CACurrentMediaTime();
    [expectation fulfill];
  };
  CFTimeInterval startTime = CACurrentMediaTime();
  [viewController setupKeyboardAnimationVsyncClient:callback];
  [self waitForExpectationsWithTimeout:5.0 handler:nil];
  XCTAssertTrue(fulfillTime - startTime > delayTime);
}

- (void)testCalculateKeyboardAttachMode {
  FlutterEngine* mockEngine = OCMPartialMock([[FlutterEngine alloc] init]);
  [mockEngine createShell:@"" libraryURI:@"" initialRoute:nil];
  FlutterViewController* viewController = [[FlutterViewController alloc] initWithEngine:mockEngine
                                                                                nibName:nil
                                                                                 bundle:nil];

  FlutterViewController* viewControllerMock = OCMPartialMock(viewController);
  CGRect viewFrame = UIScreen.mainScreen.bounds;
  [self setupMockMainScreenAndView:viewControllerMock viewFrame:viewFrame convertedFrame:viewFrame];

  CGFloat screenWidth = UIScreen.mainScreen.bounds.size.width;
  CGFloat screenHeight = UIScreen.mainScreen.bounds.size.height;

  // hide notification
  CGRect keyboardFrame = CGRectZero;
  NSNotification* notification =
      [NSNotification notificationWithName:UIKeyboardWillHideNotification
                                    object:nil
                                  userInfo:@{
                                    @"UIKeyboardFrameEndUserInfoKey" : @(keyboardFrame),
                                    @"UIKeyboardAnimationDurationUserInfoKey" : @0.25,
                                    @"UIKeyboardIsLocalUserInfoKey" : @(YES)
                                  }];
  FlutterKeyboardMode keyboardMode = [viewControllerMock calculateKeyboardAttachMode:notification];
  XCTAssertTrue(keyboardMode == FlutterKeyboardModeHidden);

  // all zeros
  keyboardFrame = CGRectZero;
  notification = [NSNotification notificationWithName:UIKeyboardWillChangeFrameNotification
                                               object:nil
                                             userInfo:@{
                                               @"UIKeyboardFrameEndUserInfoKey" : @(keyboardFrame),
                                               @"UIKeyboardAnimationDurationUserInfoKey" : @0.25,
                                               @"UIKeyboardIsLocalUserInfoKey" : @(YES)
                                             }];
  keyboardMode = [viewControllerMock calculateKeyboardAttachMode:notification];
  XCTAssertTrue(keyboardMode == FlutterKeyboardModeFloating);

  // 0 height
  keyboardFrame = CGRectMake(0, 0, screenWidth, 0);
  notification = [NSNotification notificationWithName:UIKeyboardWillChangeFrameNotification
                                               object:nil
                                             userInfo:@{
                                               @"UIKeyboardFrameEndUserInfoKey" : @(keyboardFrame),
                                               @"UIKeyboardAnimationDurationUserInfoKey" : @0.25,
                                               @"UIKeyboardIsLocalUserInfoKey" : @(YES)
                                             }];
  keyboardMode = [viewControllerMock calculateKeyboardAttachMode:notification];
  XCTAssertTrue(keyboardMode == FlutterKeyboardModeHidden);

  // floating
  keyboardFrame = CGRectMake(0, 0, 320, 320);
  notification = [NSNotification notificationWithName:UIKeyboardWillChangeFrameNotification
                                               object:nil
                                             userInfo:@{
                                               @"UIKeyboardFrameEndUserInfoKey" : @(keyboardFrame),
                                               @"UIKeyboardAnimationDurationUserInfoKey" : @0.25,
                                               @"UIKeyboardIsLocalUserInfoKey" : @(YES)
                                             }];
  keyboardMode = [viewControllerMock calculateKeyboardAttachMode:notification];
  XCTAssertTrue(keyboardMode == FlutterKeyboardModeFloating);

  // undocked
  keyboardFrame = CGRectMake(0, 0, screenWidth, 320);
  notification = [NSNotification notificationWithName:UIKeyboardWillChangeFrameNotification
                                               object:nil
                                             userInfo:@{
                                               @"UIKeyboardFrameEndUserInfoKey" : @(keyboardFrame),
                                               @"UIKeyboardAnimationDurationUserInfoKey" : @0.25,
                                               @"UIKeyboardIsLocalUserInfoKey" : @(YES)
                                             }];
  keyboardMode = [viewControllerMock calculateKeyboardAttachMode:notification];
  XCTAssertTrue(keyboardMode == FlutterKeyboardModeFloating);

  // docked
  keyboardFrame = CGRectMake(0, screenHeight - 320, screenWidth, 320);
  notification = [NSNotification notificationWithName:UIKeyboardWillChangeFrameNotification
                                               object:nil
                                             userInfo:@{
                                               @"UIKeyboardFrameEndUserInfoKey" : @(keyboardFrame),
                                               @"UIKeyboardAnimationDurationUserInfoKey" : @0.25,
                                               @"UIKeyboardIsLocalUserInfoKey" : @(YES)
                                             }];
  keyboardMode = [viewControllerMock calculateKeyboardAttachMode:notification];
  XCTAssertTrue(keyboardMode == FlutterKeyboardModeDocked);

  // docked - rounded values
  CGFloat longDecimalHeight = 320.666666666666666;
  keyboardFrame = CGRectMake(0, screenHeight - longDecimalHeight, screenWidth, longDecimalHeight);
  notification = [NSNotification notificationWithName:UIKeyboardWillChangeFrameNotification
                                               object:nil
                                             userInfo:@{
                                               @"UIKeyboardFrameEndUserInfoKey" : @(keyboardFrame),
                                               @"UIKeyboardAnimationDurationUserInfoKey" : @0.25,
                                               @"UIKeyboardIsLocalUserInfoKey" : @(YES)
                                             }];
  keyboardMode = [viewControllerMock calculateKeyboardAttachMode:notification];
  XCTAssertTrue(keyboardMode == FlutterKeyboardModeDocked);

  // hidden - rounded values
  keyboardFrame = CGRectMake(0, screenHeight - .0000001, screenWidth, longDecimalHeight);
  notification = [NSNotification notificationWithName:UIKeyboardWillChangeFrameNotification
                                               object:nil
                                             userInfo:@{
                                               @"UIKeyboardFrameEndUserInfoKey" : @(keyboardFrame),
                                               @"UIKeyboardAnimationDurationUserInfoKey" : @0.25,
                                               @"UIKeyboardIsLocalUserInfoKey" : @(YES)
                                             }];
  keyboardMode = [viewControllerMock calculateKeyboardAttachMode:notification];
  XCTAssertTrue(keyboardMode == FlutterKeyboardModeHidden);

  // hidden
  keyboardFrame = CGRectMake(0, screenHeight, screenWidth, 320);
  notification = [NSNotification notificationWithName:UIKeyboardWillChangeFrameNotification
                                               object:nil
                                             userInfo:@{
                                               @"UIKeyboardFrameEndUserInfoKey" : @(keyboardFrame),
                                               @"UIKeyboardAnimationDurationUserInfoKey" : @0.25,
                                               @"UIKeyboardIsLocalUserInfoKey" : @(YES)
                                             }];
  keyboardMode = [viewControllerMock calculateKeyboardAttachMode:notification];
  XCTAssertTrue(keyboardMode == FlutterKeyboardModeHidden);
}

- (void)testCalculateMultitaskingAdjustment {
  FlutterEngine* mockEngine = OCMPartialMock([[FlutterEngine alloc] init]);
  [mockEngine createShell:@"" libraryURI:@"" initialRoute:nil];
  FlutterViewController* viewController = [[FlutterViewController alloc] initWithEngine:mockEngine
                                                                                nibName:nil
                                                                                 bundle:nil];
  FlutterViewController* viewControllerMock = OCMPartialMock(viewController);

  CGFloat screenWidth = UIScreen.mainScreen.bounds.size.width;
  CGFloat screenHeight = UIScreen.mainScreen.bounds.size.height;
  CGRect screenRect = UIScreen.mainScreen.bounds;
  CGRect viewOrigFrame = CGRectMake(0, 0, 320, screenHeight - 40);
  CGRect convertedViewFrame = CGRectMake(20, 20, 320, screenHeight - 40);
  CGRect keyboardFrame = CGRectMake(20, screenHeight - 320, screenWidth, 300);
  id mockView = [self setupMockMainScreenAndView:viewControllerMock
                                       viewFrame:viewOrigFrame
                                  convertedFrame:convertedViewFrame];
  id mockTraitCollection = OCMClassMock([UITraitCollection class]);
  OCMStub([mockTraitCollection userInterfaceIdiom]).andReturn(UIUserInterfaceIdiomPad);
  OCMStub([mockTraitCollection horizontalSizeClass]).andReturn(UIUserInterfaceSizeClassCompact);
  OCMStub([mockTraitCollection verticalSizeClass]).andReturn(UIUserInterfaceSizeClassRegular);
  OCMStub([mockView traitCollection]).andReturn(mockTraitCollection);

  CGFloat adjustment = [viewControllerMock calculateMultitaskingAdjustment:screenRect
                                                             keyboardFrame:keyboardFrame];
  XCTAssertTrue(adjustment == 20);
}

- (void)testCalculateKeyboardInset {
  FlutterEngine* mockEngine = OCMPartialMock([[FlutterEngine alloc] init]);
  [mockEngine createShell:@"" libraryURI:@"" initialRoute:nil];
  FlutterViewController* viewController = [[FlutterViewController alloc] initWithEngine:mockEngine
                                                                                nibName:nil
                                                                                 bundle:nil];
  FlutterViewController* viewControllerMock = OCMPartialMock(viewController);
  OCMStub([viewControllerMock mainScreenIfViewLoaded]).andReturn(UIScreen.mainScreen);

  CGFloat screenWidth = UIScreen.mainScreen.bounds.size.width;
  CGFloat screenHeight = UIScreen.mainScreen.bounds.size.height;
  CGRect viewOrigFrame = CGRectMake(0, 0, 320, screenHeight - 40);
  CGRect convertedViewFrame = CGRectMake(20, 20, 320, screenHeight - 40);
  CGRect keyboardFrame = CGRectMake(20, screenHeight - 320, screenWidth, 300);

  [self setupMockMainScreenAndView:viewControllerMock
                         viewFrame:viewOrigFrame
                    convertedFrame:convertedViewFrame];

  CGFloat inset = [viewControllerMock calculateKeyboardInset:keyboardFrame
                                                keyboardMode:FlutterKeyboardModeDocked];
  XCTAssertTrue(inset == 300 * UIScreen.mainScreen.scale);
}

- (void)testHandleKeyboardNotification {
  FlutterEngine* engine = [[FlutterEngine alloc] init];
  [engine runWithEntrypoint:nil];
  FlutterViewController* viewController = [[FlutterViewController alloc] initWithEngine:engine
                                                                                nibName:nil
                                                                                 bundle:nil];
  // keyboard is empty
  CGFloat screenWidth = UIScreen.mainScreen.bounds.size.width;
  CGFloat screenHeight = UIScreen.mainScreen.bounds.size.height;
  CGRect keyboardFrame = CGRectMake(0, screenHeight - 320, screenWidth, 320);
  CGRect viewFrame = UIScreen.mainScreen.bounds;
  BOOL isLocal = YES;
  NSNotification* notification =
      [NSNotification notificationWithName:UIKeyboardWillShowNotification
                                    object:nil
                                  userInfo:@{
                                    @"UIKeyboardFrameEndUserInfoKey" : @(keyboardFrame),
                                    @"UIKeyboardAnimationDurationUserInfoKey" : @0.25,
                                    @"UIKeyboardIsLocalUserInfoKey" : @(isLocal)
                                  }];
  FlutterViewController* viewControllerMock = OCMPartialMock(viewController);
  [self setupMockMainScreenAndView:viewControllerMock viewFrame:viewFrame convertedFrame:viewFrame];
  viewControllerMock.targetViewInsetBottom = 0;
  XCTestExpectation* expectation = [self expectationWithDescription:@"update viewport"];
  OCMStub([viewControllerMock updateViewportMetricsIfNeeded]).andDo(^(NSInvocation* invocation) {
    [expectation fulfill];
  });

  [viewControllerMock handleKeyboardNotification:notification];
  XCTAssertTrue(viewControllerMock.targetViewInsetBottom == 320 * UIScreen.mainScreen.scale);
  OCMVerify([viewControllerMock startKeyBoardAnimation:0.25]);
  [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)testEnsureBottomInsetIsZeroWhenKeyboardDismissed {
  FlutterEngine* mockEngine = OCMPartialMock([[FlutterEngine alloc] init]);
  [mockEngine createShell:@"" libraryURI:@"" initialRoute:nil];
  FlutterViewController* viewController = [[FlutterViewController alloc] initWithEngine:mockEngine
                                                                                nibName:nil
                                                                                 bundle:nil];

  FlutterViewController* viewControllerMock = OCMPartialMock(viewController);
  CGRect keyboardFrame = CGRectZero;
  BOOL isLocal = YES;
  NSNotification* fakeNotification =
      [NSNotification notificationWithName:UIKeyboardWillHideNotification
                                    object:nil
                                  userInfo:@{
                                    @"UIKeyboardFrameEndUserInfoKey" : @(keyboardFrame),
                                    @"UIKeyboardAnimationDurationUserInfoKey" : @(0.25),
                                    @"UIKeyboardIsLocalUserInfoKey" : @(isLocal)
                                  }];

  viewControllerMock.targetViewInsetBottom = 10;
  [viewControllerMock handleKeyboardNotification:fakeNotification];
  XCTAssertTrue(viewControllerMock.targetViewInsetBottom == 0);
}

- (void)testEnsureViewportMetricsWillInvokeAndDisplayLinkWillInvalidateInViewDidDisappear {
  FlutterEngine* mockEngine = OCMPartialMock([[FlutterEngine alloc] init]);
  [mockEngine createShell:@"" libraryURI:@"" initialRoute:nil];
  FlutterViewController* viewController = [[FlutterViewController alloc] initWithEngine:mockEngine
                                                                                nibName:nil
                                                                                 bundle:nil];
  id viewControllerMock = OCMPartialMock(viewController);
  [viewControllerMock viewDidDisappear:YES];
  OCMVerify([viewControllerMock ensureViewportMetricsIsCorrect]);
  OCMVerify([viewControllerMock invalidateKeyboardAnimationVSyncClient]);
}

- (void)testViewDidDisappearDoesntPauseEngineWhenNotTheViewController {
  id lifecycleChannel = OCMClassMock([FlutterBasicMessageChannel class]);
  FlutterEnginePartialMock* mockEngine = [[FlutterEnginePartialMock alloc] init];
  mockEngine.lifecycleChannel = lifecycleChannel;
  FlutterViewController* viewControllerA =
      [[FlutterViewController alloc] initWithEngine:self.mockEngine nibName:nil bundle:nil];
  FlutterViewController* viewControllerB =
      [[FlutterViewController alloc] initWithEngine:self.mockEngine nibName:nil bundle:nil];
  id viewControllerMock = OCMPartialMock(viewControllerA);
  OCMStub([viewControllerMock surfaceUpdated:NO]);
  mockEngine.viewController = viewControllerB;
  [viewControllerA viewDidDisappear:NO];
  OCMReject([lifecycleChannel sendMessage:@"AppLifecycleState.paused"]);
  OCMReject([viewControllerMock surfaceUpdated:[OCMArg any]]);
}

- (void)testAppWillTerminateViewDidDestroyTheEngine {
  FlutterEngine* mockEngine = OCMPartialMock([[FlutterEngine alloc] init]);
  [mockEngine createShell:@"" libraryURI:@"" initialRoute:nil];
  FlutterViewController* viewController = [[FlutterViewController alloc] initWithEngine:mockEngine
                                                                                nibName:nil
                                                                                 bundle:nil];
  id viewControllerMock = OCMPartialMock(viewController);
  OCMStub([viewControllerMock goToApplicationLifecycle:@"AppLifecycleState.detached"]);
  OCMStub([mockEngine destroyContext]);
  [viewController applicationWillTerminate:nil];
  OCMVerify([viewControllerMock goToApplicationLifecycle:@"AppLifecycleState.detached"]);
  OCMVerify([mockEngine destroyContext]);
}

- (void)testViewDidDisappearDoesPauseEngineWhenIsTheViewController {
  id lifecycleChannel = OCMClassMock([FlutterBasicMessageChannel class]);
  FlutterEnginePartialMock* mockEngine = [[FlutterEnginePartialMock alloc] init];
  mockEngine.lifecycleChannel = lifecycleChannel;
  __weak FlutterViewController* weakViewController;
  @autoreleasepool {
    FlutterViewController* viewController = [[FlutterViewController alloc] initWithEngine:mockEngine
                                                                                  nibName:nil
                                                                                   bundle:nil];
    weakViewController = viewController;
    id viewControllerMock = OCMPartialMock(viewController);
    OCMStub([viewControllerMock surfaceUpdated:NO]);
    [viewController viewDidDisappear:NO];
    OCMVerify([lifecycleChannel sendMessage:@"AppLifecycleState.paused"]);
    OCMVerify([viewControllerMock surfaceUpdated:NO]);
  }
  XCTAssertNil(weakViewController);
}

- (void)
    testEngineConfigSyncMethodWillExecuteWhenViewControllerInEngineIsCurrentViewControllerInViewWillAppear {
  FlutterEngine* mockEngine = OCMPartialMock([[FlutterEngine alloc] init]);
  [mockEngine createShell:@"" libraryURI:@"" initialRoute:nil];
  FlutterViewController* viewController = [[FlutterViewController alloc] initWithEngine:mockEngine
                                                                                nibName:nil
                                                                                 bundle:nil];
  [viewController viewWillAppear:YES];
  OCMVerify([viewController onUserSettingsChanged:nil]);
}

- (void)
    testEngineConfigSyncMethodWillNotExecuteWhenViewControllerInEngineIsNotCurrentViewControllerInViewWillAppear {
  FlutterEngine* mockEngine = OCMPartialMock([[FlutterEngine alloc] init]);
  [mockEngine createShell:@"" libraryURI:@"" initialRoute:nil];
  FlutterViewController* viewControllerA = [[FlutterViewController alloc] initWithEngine:mockEngine
                                                                                 nibName:nil
                                                                                  bundle:nil];
  mockEngine.viewController = nil;
  FlutterViewController* viewControllerB = [[FlutterViewController alloc] initWithEngine:mockEngine
                                                                                 nibName:nil
                                                                                  bundle:nil];
  mockEngine.viewController = nil;
  mockEngine.viewController = viewControllerB;
  [viewControllerA viewWillAppear:YES];
  OCMVerify(never(), [viewControllerA onUserSettingsChanged:nil]);
}

- (void)
    testEngineConfigSyncMethodWillExecuteWhenViewControllerInEngineIsCurrentViewControllerInViewDidAppear {
  FlutterEngine* mockEngine = OCMPartialMock([[FlutterEngine alloc] init]);
  [mockEngine createShell:@"" libraryURI:@"" initialRoute:nil];
  FlutterViewController* viewController = [[FlutterViewController alloc] initWithEngine:mockEngine
                                                                                nibName:nil
                                                                                 bundle:nil];
  [viewController viewDidAppear:YES];
  OCMVerify([viewController onUserSettingsChanged:nil]);
}

- (void)
    testEngineConfigSyncMethodWillNotExecuteWhenViewControllerInEngineIsNotCurrentViewControllerInViewDidAppear {
  FlutterEngine* mockEngine = OCMPartialMock([[FlutterEngine alloc] init]);
  [mockEngine createShell:@"" libraryURI:@"" initialRoute:nil];
  FlutterViewController* viewControllerA = [[FlutterViewController alloc] initWithEngine:mockEngine
                                                                                 nibName:nil
                                                                                  bundle:nil];
  mockEngine.viewController = nil;
  FlutterViewController* viewControllerB = [[FlutterViewController alloc] initWithEngine:mockEngine
                                                                                 nibName:nil
                                                                                  bundle:nil];
  mockEngine.viewController = nil;
  mockEngine.viewController = viewControllerB;
  [viewControllerA viewDidAppear:YES];
  OCMVerify(never(), [viewControllerA onUserSettingsChanged:nil]);
}

- (void)
    testEngineConfigSyncMethodWillExecuteWhenViewControllerInEngineIsCurrentViewControllerInViewWillDisappear {
  id lifecycleChannel = OCMClassMock([FlutterBasicMessageChannel class]);
  FlutterEnginePartialMock* mockEngine = [[FlutterEnginePartialMock alloc] init];
  mockEngine.lifecycleChannel = lifecycleChannel;
  FlutterViewController* viewController = [[FlutterViewController alloc] initWithEngine:mockEngine
                                                                                nibName:nil
                                                                                 bundle:nil];
  mockEngine.viewController = viewController;
  [viewController viewWillDisappear:NO];
  OCMVerify([lifecycleChannel sendMessage:@"AppLifecycleState.inactive"]);
}

- (void)
    testEngineConfigSyncMethodWillNotExecuteWhenViewControllerInEngineIsNotCurrentViewControllerInViewWillDisappear {
  id lifecycleChannel = OCMClassMock([FlutterBasicMessageChannel class]);
  FlutterEnginePartialMock* mockEngine = [[FlutterEnginePartialMock alloc] init];
  mockEngine.lifecycleChannel = lifecycleChannel;
  FlutterViewController* viewControllerA = [[FlutterViewController alloc] initWithEngine:mockEngine
                                                                                 nibName:nil
                                                                                  bundle:nil];
  FlutterViewController* viewControllerB = [[FlutterViewController alloc] initWithEngine:mockEngine
                                                                                 nibName:nil
                                                                                  bundle:nil];
  mockEngine.viewController = viewControllerB;
  [viewControllerA viewDidDisappear:NO];
  OCMReject([lifecycleChannel sendMessage:@"AppLifecycleState.inactive"]);
}

- (void)testUpdateViewportMetricsIfNeeded_DoesntInvokeEngineWhenNotTheViewController {
  FlutterEngine* mockEngine = OCMPartialMock([[FlutterEngine alloc] init]);
  [mockEngine createShell:@"" libraryURI:@"" initialRoute:nil];
  FlutterViewController* viewControllerA = [[FlutterViewController alloc] initWithEngine:mockEngine
                                                                                 nibName:nil
                                                                                  bundle:nil];
  mockEngine.viewController = nil;
  FlutterViewController* viewControllerB = [[FlutterViewController alloc] initWithEngine:mockEngine
                                                                                 nibName:nil
                                                                                  bundle:nil];
  mockEngine.viewController = viewControllerB;
  [viewControllerA updateViewportMetricsIfNeeded];
  flutter::ViewportMetrics viewportMetrics;
  OCMVerify(never(), [mockEngine updateViewportMetrics:viewportMetrics]);
}

- (void)testUpdateViewportMetricsIfNeeded_DoesInvokeEngineWhenIsTheViewController {
  FlutterEngine* mockEngine = OCMPartialMock([[FlutterEngine alloc] init]);
  [mockEngine createShell:@"" libraryURI:@"" initialRoute:nil];
  FlutterViewController* viewController = [[FlutterViewController alloc] initWithEngine:mockEngine
                                                                                nibName:nil
                                                                                 bundle:nil];
  mockEngine.viewController = viewController;
  flutter::ViewportMetrics viewportMetrics;
  OCMExpect([mockEngine updateViewportMetrics:viewportMetrics]).ignoringNonObjectArgs();
  [viewController updateViewportMetricsIfNeeded];
  OCMVerifyAll(mockEngine);
}

- (void)testUpdateViewportMetricsIfNeeded_DoesNotInvokeEngineWhenShouldBeIgnoredDuringRotation {
  FlutterEngine* mockEngine = OCMPartialMock([[FlutterEngine alloc] init]);
  [mockEngine createShell:@"" libraryURI:@"" initialRoute:nil];
  FlutterViewController* viewController = [[FlutterViewController alloc] initWithEngine:mockEngine
                                                                                nibName:nil
                                                                                 bundle:nil];
  FlutterViewController* viewControllerMock = OCMPartialMock(viewController);
  OCMStub([viewControllerMock mainScreenIfViewLoaded]).andReturn(UIScreen.mainScreen);
  mockEngine.viewController = viewController;

  id mockCoordinator = OCMProtocolMock(@protocol(UIViewControllerTransitionCoordinator));
  OCMStub([mockCoordinator transitionDuration]).andReturn(0.5);

  // Mimic the device rotation.
  [viewController viewWillTransitionToSize:CGSizeZero withTransitionCoordinator:mockCoordinator];
  // Should not trigger the engine call when during rotation.
  [viewController updateViewportMetricsIfNeeded];

  OCMVerify(never(), [mockEngine updateViewportMetrics:flutter::ViewportMetrics()]);
}

- (void)testViewWillTransitionToSize_DoesDelayEngineCallIfNonZeroDuration {
  FlutterEngine* mockEngine = OCMPartialMock([[FlutterEngine alloc] init]);
  [mockEngine createShell:@"" libraryURI:@"" initialRoute:nil];
  FlutterViewController* viewController = [[FlutterViewController alloc] initWithEngine:mockEngine
                                                                                nibName:nil
                                                                                 bundle:nil];
  FlutterViewController* viewControllerMock = OCMPartialMock(viewController);
  OCMStub([viewControllerMock mainScreenIfViewLoaded]).andReturn(UIScreen.mainScreen);
  mockEngine.viewController = viewController;

  // Mimic the device rotation with non-zero transition duration.
  NSTimeInterval transitionDuration = 0.5;
  id mockCoordinator = OCMProtocolMock(@protocol(UIViewControllerTransitionCoordinator));
  OCMStub([mockCoordinator transitionDuration]).andReturn(transitionDuration);

  flutter::ViewportMetrics viewportMetrics;
  OCMExpect([mockEngine updateViewportMetrics:viewportMetrics]).ignoringNonObjectArgs();

  [viewController viewWillTransitionToSize:CGSizeZero withTransitionCoordinator:mockCoordinator];
  // Should not immediately call the engine (this request should be ignored).
  [viewController updateViewportMetricsIfNeeded];
  OCMVerify(never(), [mockEngine updateViewportMetrics:flutter::ViewportMetrics()]);

  // Should delay the engine call for half of the transition duration.
  // Wait for additional transitionDuration to allow updateViewportMetrics calls if any.
  XCTWaiterResult result = [XCTWaiter
      waitForExpectations:@[ [self expectationWithDescription:@"Waiting for rotation duration"] ]
                  timeout:transitionDuration];
  XCTAssertEqual(result, XCTWaiterResultTimedOut);

  OCMVerifyAll(mockEngine);
}

- (void)testViewWillTransitionToSize_DoesNotDelayEngineCallIfZeroDuration {
  FlutterEngine* mockEngine = OCMPartialMock([[FlutterEngine alloc] init]);
  [mockEngine createShell:@"" libraryURI:@"" initialRoute:nil];
  FlutterViewController* viewController = [[FlutterViewController alloc] initWithEngine:mockEngine
                                                                                nibName:nil
                                                                                 bundle:nil];
  FlutterViewController* viewControllerMock = OCMPartialMock(viewController);
  OCMStub([viewControllerMock mainScreenIfViewLoaded]).andReturn(UIScreen.mainScreen);
  mockEngine.viewController = viewController;

  // Mimic the device rotation with zero transition duration.
  id mockCoordinator = OCMProtocolMock(@protocol(UIViewControllerTransitionCoordinator));
  OCMStub([mockCoordinator transitionDuration]).andReturn(0);

  flutter::ViewportMetrics viewportMetrics;
  OCMExpect([mockEngine updateViewportMetrics:viewportMetrics]).ignoringNonObjectArgs();

  // Should immediately trigger the engine call, without delay.
  [viewController viewWillTransitionToSize:CGSizeZero withTransitionCoordinator:mockCoordinator];
  [viewController updateViewportMetricsIfNeeded];

  OCMVerifyAll(mockEngine);
}

- (void)testViewDidLoadDoesntInvokeEngineWhenNotTheViewController {
  FlutterEngine* mockEngine = OCMPartialMock([[FlutterEngine alloc] init]);
  [mockEngine createShell:@"" libraryURI:@"" initialRoute:nil];
  FlutterViewController* viewControllerA = [[FlutterViewController alloc] initWithEngine:mockEngine
                                                                                 nibName:nil
                                                                                  bundle:nil];
  mockEngine.viewController = nil;
  FlutterViewController* viewControllerB = [[FlutterViewController alloc] initWithEngine:mockEngine
                                                                                 nibName:nil
                                                                                  bundle:nil];
  mockEngine.viewController = viewControllerB;
  UIView* view = viewControllerA.view;
  XCTAssertNotNil(view);
  OCMVerify(never(), [mockEngine attachView]);
}

- (void)testViewDidLoadDoesInvokeEngineWhenIsTheViewController {
  FlutterEngine* mockEngine = OCMPartialMock([[FlutterEngine alloc] init]);
  [mockEngine createShell:@"" libraryURI:@"" initialRoute:nil];
  mockEngine.viewController = nil;
  FlutterViewController* viewController = [[FlutterViewController alloc] initWithEngine:mockEngine
                                                                                nibName:nil
                                                                                 bundle:nil];
  mockEngine.viewController = viewController;
  UIView* view = viewController.view;
  XCTAssertNotNil(view);
  OCMVerify(times(1), [mockEngine attachView]);
}

- (void)testViewDidLoadDoesntInvokeEngineAttachViewWhenEngineNeedsLaunch {
  FlutterEngine* mockEngine = OCMPartialMock([[FlutterEngine alloc] init]);
  [mockEngine createShell:@"" libraryURI:@"" initialRoute:nil];
  mockEngine.viewController = nil;
  FlutterViewController* viewController = [[FlutterViewController alloc] initWithEngine:mockEngine
                                                                                nibName:nil
                                                                                 bundle:nil];
  // sharedSetupWithProject sets the engine needs to be launched.
  [viewController sharedSetupWithProject:nil initialRoute:nil];
  mockEngine.viewController = viewController;
  UIView* view = viewController.view;
  XCTAssertNotNil(view);
  OCMVerify(never(), [mockEngine attachView]);
}

- (void)testSplashScreenViewRemoveNotCrash {
  FlutterEngine* engine = [[FlutterEngine alloc] initWithName:@"engine" project:nil];
  [engine runWithEntrypoint:nil];
  FlutterViewController* flutterViewController =
      [[FlutterViewController alloc] initWithEngine:engine nibName:nil bundle:nil];
  [flutterViewController setSplashScreenView:[[UIView alloc] init]];
  [flutterViewController setSplashScreenView:nil];
}

- (void)testInternalPluginsWeakPtrNotCrash {
  FlutterSendKeyEvent sendEvent;
  @autoreleasepool {
    FlutterViewController* vc = [[FlutterViewController alloc] initWithProject:nil
                                                                       nibName:nil
                                                                        bundle:nil];
    [vc addInternalPlugins];
    FlutterKeyboardManager* keyboardManager = vc.keyboardManager;
    FlutterEmbedderKeyResponder* keyPrimaryResponder = (FlutterEmbedderKeyResponder*)
        [(NSArray<id<FlutterKeyPrimaryResponder>>*)keyboardManager.primaryResponders firstObject];
    sendEvent = [keyPrimaryResponder sendEvent];
  }

  if (sendEvent) {
    sendEvent({}, nil, nil);
  }
}

// Regression test for https://github.com/flutter/engine/pull/32098.
- (void)testInternalPluginsInvokeInViewDidLoad {
  FlutterEngine* mockEngine = OCMPartialMock([[FlutterEngine alloc] init]);
  [mockEngine createShell:@"" libraryURI:@"" initialRoute:nil];
  FlutterViewController* viewController = [[FlutterViewController alloc] initWithEngine:mockEngine
                                                                                nibName:nil
                                                                                 bundle:nil];
  UIView* view = viewController.view;
  // The implementation in viewDidLoad requires the viewControllers.viewLoaded is true.
  // Accessing the view to make sure the view loads in the memory,
  // which makes viewControllers.viewLoaded true.
  XCTAssertNotNil(view);
  [viewController viewDidLoad];
  OCMVerify([viewController addInternalPlugins]);
}

- (void)testBinaryMessenger {
  FlutterViewController* vc = [[FlutterViewController alloc] initWithEngine:self.mockEngine
                                                                    nibName:nil
                                                                     bundle:nil];
  XCTAssertNotNil(vc);
  id messenger = OCMProtocolMock(@protocol(FlutterBinaryMessenger));
  OCMStub([self.mockEngine binaryMessenger]).andReturn(messenger);
  XCTAssertEqual(vc.binaryMessenger, messenger);
  OCMVerify([self.mockEngine binaryMessenger]);
}

#pragma mark - Platform Brightness

- (void)testItReportsLightPlatformBrightnessByDefault {
  // Setup test.
  id settingsChannel = OCMClassMock([FlutterBasicMessageChannel class]);
  OCMStub([self.mockEngine settingsChannel]).andReturn(settingsChannel);

  FlutterViewController* vc = [[FlutterViewController alloc] initWithEngine:self.mockEngine
                                                                    nibName:nil
                                                                     bundle:nil];

  // Exercise behavior under test.
  [vc traitCollectionDidChange:nil];

  // Verify behavior.
  OCMVerify([settingsChannel sendMessage:[OCMArg checkWithBlock:^BOOL(id message) {
                               return [message[@"platformBrightness"] isEqualToString:@"light"];
                             }]]);

  // Clean up mocks
  [settingsChannel stopMocking];
}

- (void)testItReportsPlatformBrightnessWhenViewWillAppear {
  // Setup test.
  id settingsChannel = OCMClassMock([FlutterBasicMessageChannel class]);
  FlutterEngine* mockEngine = OCMPartialMock([[FlutterEngine alloc] init]);
  [mockEngine createShell:@"" libraryURI:@"" initialRoute:nil];
  OCMStub([mockEngine settingsChannel]).andReturn(settingsChannel);
  FlutterViewController* vc = [[FlutterViewController alloc] initWithEngine:mockEngine
                                                                    nibName:nil
                                                                     bundle:nil];

  // Exercise behavior under test.
  [vc viewWillAppear:false];

  // Verify behavior.
  OCMVerify([settingsChannel sendMessage:[OCMArg checkWithBlock:^BOOL(id message) {
                               return [message[@"platformBrightness"] isEqualToString:@"light"];
                             }]]);

  // Clean up mocks
  [settingsChannel stopMocking];
}

- (void)testItReportsDarkPlatformBrightnessWhenTraitCollectionRequestsIt {
  if (@available(iOS 13, *)) {
    // noop
  } else {
    return;
  }

  // Setup test.
  id settingsChannel = OCMClassMock([FlutterBasicMessageChannel class]);
  OCMStub([self.mockEngine settingsChannel]).andReturn(settingsChannel);

  FlutterViewController* realVC = [[FlutterViewController alloc] initWithEngine:self.mockEngine
                                                                        nibName:nil
                                                                         bundle:nil];
  id mockTraitCollection =
      [self fakeTraitCollectionWithUserInterfaceStyle:UIUserInterfaceStyleDark];

  // We partially mock the real FlutterViewController to act as the OS and report
  // the UITraitCollection of our choice. Mocking the object under test is not
  // desirable, but given that the OS does not offer a DI approach to providing
  // our own UITraitCollection, this seems to be the least bad option.
  id partialMockVC = OCMPartialMock(realVC);
  OCMStub([partialMockVC traitCollection]).andReturn(mockTraitCollection);

  // Exercise behavior under test.
  [partialMockVC traitCollectionDidChange:nil];

  // Verify behavior.
  OCMVerify([settingsChannel sendMessage:[OCMArg checkWithBlock:^BOOL(id message) {
                               return [message[@"platformBrightness"] isEqualToString:@"dark"];
                             }]]);

  // Clean up mocks
  [partialMockVC stopMocking];
  [settingsChannel stopMocking];
  [mockTraitCollection stopMocking];
}

// Creates a mocked UITraitCollection with nil values for everything except userInterfaceStyle,
// which is set to the given "style".
- (UITraitCollection*)fakeTraitCollectionWithUserInterfaceStyle:(UIUserInterfaceStyle)style {
  id mockTraitCollection = OCMClassMock([UITraitCollection class]);
  OCMStub([mockTraitCollection userInterfaceStyle]).andReturn(style);
  return mockTraitCollection;
}

#pragma mark - Platform Contrast

- (void)testItReportsNormalPlatformContrastByDefault {
  if (@available(iOS 13, *)) {
    // noop
  } else {
    return;
  }

  // Setup test.
  id settingsChannel = OCMClassMock([FlutterBasicMessageChannel class]);
  OCMStub([self.mockEngine settingsChannel]).andReturn(settingsChannel);

  FlutterViewController* vc = [[FlutterViewController alloc] initWithEngine:self.mockEngine
                                                                    nibName:nil
                                                                     bundle:nil];

  // Exercise behavior under test.
  [vc traitCollectionDidChange:nil];

  // Verify behavior.
  OCMVerify([settingsChannel sendMessage:[OCMArg checkWithBlock:^BOOL(id message) {
                               return [message[@"platformContrast"] isEqualToString:@"normal"];
                             }]]);

  // Clean up mocks
  [settingsChannel stopMocking];
}

- (void)testItReportsPlatformContrastWhenViewWillAppear {
  if (@available(iOS 13, *)) {
    // noop
  } else {
    return;
  }
  FlutterEngine* mockEngine = OCMPartialMock([[FlutterEngine alloc] init]);
  [mockEngine createShell:@"" libraryURI:@"" initialRoute:nil];

  // Setup test.
  id settingsChannel = OCMClassMock([FlutterBasicMessageChannel class]);
  OCMStub([mockEngine settingsChannel]).andReturn(settingsChannel);
  FlutterViewController* vc = [[FlutterViewController alloc] initWithEngine:mockEngine
                                                                    nibName:nil
                                                                     bundle:nil];

  // Exercise behavior under test.
  [vc viewWillAppear:false];

  // Verify behavior.
  OCMVerify([settingsChannel sendMessage:[OCMArg checkWithBlock:^BOOL(id message) {
                               return [message[@"platformContrast"] isEqualToString:@"normal"];
                             }]]);

  // Clean up mocks
  [settingsChannel stopMocking];
}

- (void)testItReportsHighContrastWhenTraitCollectionRequestsIt {
  if (@available(iOS 13, *)) {
    // noop
  } else {
    return;
  }

  // Setup test.
  id settingsChannel = OCMClassMock([FlutterBasicMessageChannel class]);
  OCMStub([self.mockEngine settingsChannel]).andReturn(settingsChannel);

  FlutterViewController* realVC = [[FlutterViewController alloc] initWithEngine:self.mockEngine
                                                                        nibName:nil
                                                                         bundle:nil];
  id mockTraitCollection = [self fakeTraitCollectionWithContrast:UIAccessibilityContrastHigh];

  // We partially mock the real FlutterViewController to act as the OS and report
  // the UITraitCollection of our choice. Mocking the object under test is not
  // desirable, but given that the OS does not offer a DI approach to providing
  // our own UITraitCollection, this seems to be the least bad option.
  id partialMockVC = OCMPartialMock(realVC);
  OCMStub([partialMockVC traitCollection]).andReturn(mockTraitCollection);

  // Exercise behavior under test.
  [partialMockVC traitCollectionDidChange:mockTraitCollection];

  // Verify behavior.
  OCMVerify([settingsChannel sendMessage:[OCMArg checkWithBlock:^BOOL(id message) {
                               return [message[@"platformContrast"] isEqualToString:@"high"];
                             }]]);

  // Clean up mocks
  [partialMockVC stopMocking];
  [settingsChannel stopMocking];
  [mockTraitCollection stopMocking];
}

- (void)testItReportsAccessibilityOnOffSwitchLabelsFlagNotSet {
  if (@available(iOS 13, *)) {
    // noop
  } else {
    return;
  }

  // Setup test.
  FlutterViewController* viewController =
      [[FlutterViewController alloc] initWithEngine:self.mockEngine nibName:nil bundle:nil];
  id partialMockViewController = OCMPartialMock(viewController);
  OCMStub([partialMockViewController accessibilityIsOnOffSwitchLabelsEnabled]).andReturn(NO);

  // Exercise behavior under test.
  int32_t flags = [partialMockViewController accessibilityFlags];

  // Verify behavior.
  XCTAssert((flags & (int32_t)flutter::AccessibilityFeatureFlag::kOnOffSwitchLabels) == 0);
}

- (void)testItReportsAccessibilityOnOffSwitchLabelsFlagSet {
  if (@available(iOS 13, *)) {
    // noop
  } else {
    return;
  }

  // Setup test.
  FlutterViewController* viewController =
      [[FlutterViewController alloc] initWithEngine:self.mockEngine nibName:nil bundle:nil];
  id partialMockViewController = OCMPartialMock(viewController);
  OCMStub([partialMockViewController accessibilityIsOnOffSwitchLabelsEnabled]).andReturn(YES);

  // Exercise behavior under test.
  int32_t flags = [partialMockViewController accessibilityFlags];

  // Verify behavior.
  XCTAssert((flags & (int32_t)flutter::AccessibilityFeatureFlag::kOnOffSwitchLabels) != 0);
}

- (void)testPerformOrientationUpdateForcesOrientationChange {
  [self orientationTestWithOrientationUpdate:UIInterfaceOrientationMaskPortrait
                          currentOrientation:UIInterfaceOrientationLandscapeLeft
                        didChangeOrientation:YES
                        resultingOrientation:UIInterfaceOrientationPortrait];

  [self orientationTestWithOrientationUpdate:UIInterfaceOrientationMaskPortrait
                          currentOrientation:UIInterfaceOrientationLandscapeRight
                        didChangeOrientation:YES
                        resultingOrientation:UIInterfaceOrientationPortrait];

  [self orientationTestWithOrientationUpdate:UIInterfaceOrientationMaskPortrait
                          currentOrientation:UIInterfaceOrientationPortraitUpsideDown
                        didChangeOrientation:YES
                        resultingOrientation:UIInterfaceOrientationPortrait];

  [self orientationTestWithOrientationUpdate:UIInterfaceOrientationMaskPortraitUpsideDown
                          currentOrientation:UIInterfaceOrientationLandscapeLeft
                        didChangeOrientation:YES
                        resultingOrientation:UIInterfaceOrientationPortraitUpsideDown];

  [self orientationTestWithOrientationUpdate:UIInterfaceOrientationMaskPortraitUpsideDown
                          currentOrientation:UIInterfaceOrientationLandscapeRight
                        didChangeOrientation:YES
                        resultingOrientation:UIInterfaceOrientationPortraitUpsideDown];

  [self orientationTestWithOrientationUpdate:UIInterfaceOrientationMaskPortraitUpsideDown
                          currentOrientation:UIInterfaceOrientationPortrait
                        didChangeOrientation:YES
                        resultingOrientation:UIInterfaceOrientationPortraitUpsideDown];

  [self orientationTestWithOrientationUpdate:UIInterfaceOrientationMaskLandscape
                          currentOrientation:UIInterfaceOrientationPortrait
                        didChangeOrientation:YES
                        resultingOrientation:UIInterfaceOrientationLandscapeLeft];

  [self orientationTestWithOrientationUpdate:UIInterfaceOrientationMaskLandscape
                          currentOrientation:UIInterfaceOrientationPortraitUpsideDown
                        didChangeOrientation:YES
                        resultingOrientation:UIInterfaceOrientationLandscapeLeft];

  [self orientationTestWithOrientationUpdate:UIInterfaceOrientationMaskLandscapeLeft
                          currentOrientation:UIInterfaceOrientationPortrait
                        didChangeOrientation:YES
                        resultingOrientation:UIInterfaceOrientationLandscapeLeft];

  [self orientationTestWithOrientationUpdate:UIInterfaceOrientationMaskLandscapeLeft
                          currentOrientation:UIInterfaceOrientationLandscapeRight
                        didChangeOrientation:YES
                        resultingOrientation:UIInterfaceOrientationLandscapeLeft];

  [self orientationTestWithOrientationUpdate:UIInterfaceOrientationMaskLandscapeLeft
                          currentOrientation:UIInterfaceOrientationPortraitUpsideDown
                        didChangeOrientation:YES
                        resultingOrientation:UIInterfaceOrientationLandscapeLeft];

  [self orientationTestWithOrientationUpdate:UIInterfaceOrientationMaskLandscapeRight
                          currentOrientation:UIInterfaceOrientationPortrait
                        didChangeOrientation:YES
                        resultingOrientation:UIInterfaceOrientationLandscapeRight];

  [self orientationTestWithOrientationUpdate:UIInterfaceOrientationMaskLandscapeRight
                          currentOrientation:UIInterfaceOrientationLandscapeLeft
                        didChangeOrientation:YES
                        resultingOrientation:UIInterfaceOrientationLandscapeRight];

  [self orientationTestWithOrientationUpdate:UIInterfaceOrientationMaskLandscapeRight
                          currentOrientation:UIInterfaceOrientationPortraitUpsideDown
                        didChangeOrientation:YES
                        resultingOrientation:UIInterfaceOrientationLandscapeRight];

  [self orientationTestWithOrientationUpdate:UIInterfaceOrientationMaskAllButUpsideDown
                          currentOrientation:UIInterfaceOrientationPortraitUpsideDown
                        didChangeOrientation:YES
                        resultingOrientation:UIInterfaceOrientationPortrait];
}

- (void)testPerformOrientationUpdateDoesNotForceOrientationChange {
  [self orientationTestWithOrientationUpdate:UIInterfaceOrientationMaskAll
                          currentOrientation:UIInterfaceOrientationPortrait
                        didChangeOrientation:NO
                        resultingOrientation:static_cast<UIInterfaceOrientation>(0)];

  [self orientationTestWithOrientationUpdate:UIInterfaceOrientationMaskAll
                          currentOrientation:UIInterfaceOrientationPortraitUpsideDown
                        didChangeOrientation:NO
                        resultingOrientation:static_cast<UIInterfaceOrientation>(0)];

  [self orientationTestWithOrientationUpdate:UIInterfaceOrientationMaskAll
                          currentOrientation:UIInterfaceOrientationLandscapeLeft
                        didChangeOrientation:NO
                        resultingOrientation:static_cast<UIInterfaceOrientation>(0)];

  [self orientationTestWithOrientationUpdate:UIInterfaceOrientationMaskAll
                          currentOrientation:UIInterfaceOrientationLandscapeRight
                        didChangeOrientation:NO
                        resultingOrientation:static_cast<UIInterfaceOrientation>(0)];

  [self orientationTestWithOrientationUpdate:UIInterfaceOrientationMaskAllButUpsideDown
                          currentOrientation:UIInterfaceOrientationPortrait
                        didChangeOrientation:NO
                        resultingOrientation:static_cast<UIInterfaceOrientation>(0)];

  [self orientationTestWithOrientationUpdate:UIInterfaceOrientationMaskAllButUpsideDown
                          currentOrientation:UIInterfaceOrientationLandscapeLeft
                        didChangeOrientation:NO
                        resultingOrientation:static_cast<UIInterfaceOrientation>(0)];

  [self orientationTestWithOrientationUpdate:UIInterfaceOrientationMaskAllButUpsideDown
                          currentOrientation:UIInterfaceOrientationLandscapeRight
                        didChangeOrientation:NO
                        resultingOrientation:static_cast<UIInterfaceOrientation>(0)];

  [self orientationTestWithOrientationUpdate:UIInterfaceOrientationMaskPortrait
                          currentOrientation:UIInterfaceOrientationPortrait
                        didChangeOrientation:NO
                        resultingOrientation:static_cast<UIInterfaceOrientation>(0)];

  [self orientationTestWithOrientationUpdate:UIInterfaceOrientationMaskPortraitUpsideDown
                          currentOrientation:UIInterfaceOrientationPortraitUpsideDown
                        didChangeOrientation:NO
                        resultingOrientation:static_cast<UIInterfaceOrientation>(0)];

  [self orientationTestWithOrientationUpdate:UIInterfaceOrientationMaskLandscape
                          currentOrientation:UIInterfaceOrientationLandscapeLeft
                        didChangeOrientation:NO
                        resultingOrientation:static_cast<UIInterfaceOrientation>(0)];

  [self orientationTestWithOrientationUpdate:UIInterfaceOrientationMaskLandscape
                          currentOrientation:UIInterfaceOrientationLandscapeRight
                        didChangeOrientation:NO
                        resultingOrientation:static_cast<UIInterfaceOrientation>(0)];

  [self orientationTestWithOrientationUpdate:UIInterfaceOrientationMaskLandscapeLeft
                          currentOrientation:UIInterfaceOrientationLandscapeLeft
                        didChangeOrientation:NO
                        resultingOrientation:static_cast<UIInterfaceOrientation>(0)];

  [self orientationTestWithOrientationUpdate:UIInterfaceOrientationMaskLandscapeRight
                          currentOrientation:UIInterfaceOrientationLandscapeRight
                        didChangeOrientation:NO
                        resultingOrientation:static_cast<UIInterfaceOrientation>(0)];
}

// Perform an orientation update test that fails when the expected outcome
// for an orientation update is not met
- (void)orientationTestWithOrientationUpdate:(UIInterfaceOrientationMask)mask
                          currentOrientation:(UIInterfaceOrientation)currentOrientation
                        didChangeOrientation:(BOOL)didChange
                        resultingOrientation:(UIInterfaceOrientation)resultingOrientation {
  id mockApplication = OCMClassMock([UIApplication class]);
  id mockWindowScene;
  id deviceMock;
  __block __weak id weakPreferences;
  @autoreleasepool {
    FlutterViewController* realVC = [[FlutterViewController alloc] initWithEngine:self.mockEngine
                                                                          nibName:nil
                                                                           bundle:nil];
    if (@available(iOS 16.0, *)) {
      mockWindowScene = OCMClassMock([UIWindowScene class]);
      if (realVC.supportedInterfaceOrientations == mask) {
        OCMReject([mockWindowScene requestGeometryUpdateWithPreferences:[OCMArg any]
                                                           errorHandler:[OCMArg any]]);
      } else {
        // iOS 16 will decide whether to rotate based on the new preference, so always set it
        // when it changes.
        OCMExpect([mockWindowScene
            requestGeometryUpdateWithPreferences:[OCMArg checkWithBlock:^BOOL(
                                                             UIWindowSceneGeometryPreferencesIOS*
                                                                 preferences) {
              weakPreferences = preferences;
              return preferences.interfaceOrientations == mask;
            }]
                                    errorHandler:[OCMArg any]]);
      }
      OCMStub([mockApplication sharedApplication]).andReturn(mockApplication);
      OCMStub([mockApplication connectedScenes]).andReturn([NSSet setWithObject:mockWindowScene]);
    } else {
      deviceMock = OCMPartialMock([UIDevice currentDevice]);
      if (!didChange) {
        OCMReject([deviceMock setValue:[OCMArg any] forKey:@"orientation"]);
      } else {
        OCMExpect([deviceMock setValue:@(resultingOrientation) forKey:@"orientation"]);
      }

      OCMStub([mockApplication sharedApplication]).andReturn(mockApplication);
      OCMStub([mockApplication statusBarOrientation]).andReturn(currentOrientation);
    }

    [realVC performOrientationUpdate:mask];
    if (@available(iOS 16.0, *)) {
      OCMVerifyAll(mockWindowScene);
    } else {
      OCMVerifyAll(deviceMock);
    }
  }
  [mockWindowScene stopMocking];
  [deviceMock stopMocking];
  [mockApplication stopMocking];
  XCTAssertNil(weakPreferences);
}

// Creates a mocked UITraitCollection with nil values for everything except accessibilityContrast,
// which is set to the given "contrast".
- (UITraitCollection*)fakeTraitCollectionWithContrast:(UIAccessibilityContrast)contrast {
  id mockTraitCollection = OCMClassMock([UITraitCollection class]);
  OCMStub([mockTraitCollection accessibilityContrast]).andReturn(contrast);
  return mockTraitCollection;
}

- (void)testWillDeallocNotification {
  XCTestExpectation* expectation =
      [[XCTestExpectation alloc] initWithDescription:@"notification called"];
  id engine = [[MockEngine alloc] init];
  @autoreleasepool {
    FlutterViewController* realVC = [[FlutterViewController alloc] initWithEngine:engine
                                                                          nibName:nil
                                                                           bundle:nil];
    [[NSNotificationCenter defaultCenter] addObserverForName:FlutterViewControllerWillDealloc
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification* _Nonnull note) {
                                                    [expectation fulfill];
                                                  }];
    realVC = nil;
  }
  [self waitForExpectations:@[ expectation ] timeout:1.0];
}

- (void)testReleasesKeyboardManagerOnDealloc {
  __weak FlutterKeyboardManager* weakKeyboardManager = nil;
  @autoreleasepool {
    FlutterViewController* viewController = [[FlutterViewController alloc] init];

    [viewController addInternalPlugins];
    weakKeyboardManager = viewController.keyboardManager;
    XCTAssertNotNil(weakKeyboardManager);
    [viewController deregisterNotifications];
    viewController = nil;
  }
  // View controller has released the keyboard manager.
  XCTAssertNil(weakKeyboardManager);
}

- (void)testDoesntLoadViewInInit {
  FlutterDartProject* project = [[FlutterDartProject alloc] init];
  FlutterEngine* engine = [[FlutterEngine alloc] initWithName:@"foobar" project:project];
  [engine createShell:@"" libraryURI:@"" initialRoute:nil];
  FlutterViewController* realVC = [[FlutterViewController alloc] initWithEngine:engine
                                                                        nibName:nil
                                                                         bundle:nil];
  XCTAssertFalse([realVC isViewLoaded], @"shouldn't have loaded since it hasn't been shown");
  engine.viewController = nil;
}

- (void)testHideOverlay {
  FlutterDartProject* project = [[FlutterDartProject alloc] init];
  FlutterEngine* engine = [[FlutterEngine alloc] initWithName:@"foobar" project:project];
  [engine createShell:@"" libraryURI:@"" initialRoute:nil];
  FlutterViewController* realVC = [[FlutterViewController alloc] initWithEngine:engine
                                                                        nibName:nil
                                                                         bundle:nil];
  XCTAssertFalse(realVC.prefersHomeIndicatorAutoHidden, @"");
  [[NSNotificationCenter defaultCenter] postNotificationName:FlutterViewControllerHideHomeIndicator
                                                      object:nil];
  XCTAssertTrue(realVC.prefersHomeIndicatorAutoHidden, @"");
  engine.viewController = nil;
}

- (void)testNotifyLowMemory {
  FlutterEnginePartialMock* mockEngine = [[FlutterEnginePartialMock alloc] init];
  FlutterViewController* viewController = [[FlutterViewController alloc] initWithEngine:mockEngine
                                                                                nibName:nil
                                                                                 bundle:nil];
  id viewControllerMock = OCMPartialMock(viewController);
  OCMStub([viewControllerMock surfaceUpdated:NO]);
  [viewController beginAppearanceTransition:NO animated:NO];
  [viewController endAppearanceTransition];
  XCTAssertTrue(mockEngine.didCallNotifyLowMemory);
}

- (void)sendMessage:(id _Nullable)message reply:(FlutterReply _Nullable)callback {
  NSMutableDictionary* replyMessage = [@{
    @"handled" : @YES,
  } mutableCopy];
  // Response is async, so we have to post it to the run loop instead of calling
  // it directly.
  self.messageSent = message;
  CFRunLoopPerformBlock(CFRunLoopGetCurrent(), fml::MessageLoopDarwin::kMessageLoopCFRunLoopMode,
                        ^() {
                          callback(replyMessage);
                        });
}

- (void)testValidKeyUpEvent API_AVAILABLE(ios(13.4)) {
  if (@available(iOS 13.4, *)) {
    // noop
  } else {
    return;
  }
  FlutterEnginePartialMock* mockEngine = [[FlutterEnginePartialMock alloc] init];
  mockEngine.keyEventChannel = OCMClassMock([FlutterBasicMessageChannel class]);
  OCMStub([mockEngine.keyEventChannel sendMessage:[OCMArg any] reply:[OCMArg any]])
      .andCall(self, @selector(sendMessage:reply:));
  OCMStub([self.mockTextInputPlugin handlePress:[OCMArg any]]).andReturn(YES);
  mockEngine.textInputPlugin = self.mockTextInputPlugin;

  FlutterViewController* vc = [[FlutterViewController alloc] initWithEngine:mockEngine
                                                                    nibName:nil
                                                                     bundle:nil];

  // Allocate the keyboard manager in the view controller by adding the internal
  // plugins.
  [vc addInternalPlugins];

  [vc handlePressEvent:keyUpEvent(UIKeyboardHIDUsageKeyboardA, UIKeyModifierShift, 123.0)
            nextAction:^(){
            }];

  XCTAssert(self.messageSent != nil);
  XCTAssert([self.messageSent[@"keymap"] isEqualToString:@"ios"]);
  XCTAssert([self.messageSent[@"type"] isEqualToString:@"keyup"]);
  XCTAssert([self.messageSent[@"keyCode"] isEqualToNumber:[NSNumber numberWithInt:4]]);
  XCTAssert([self.messageSent[@"modifiers"] isEqualToNumber:[NSNumber numberWithInt:0]]);
  XCTAssert([self.messageSent[@"characters"] isEqualToString:@""]);
  XCTAssert([self.messageSent[@"charactersIgnoringModifiers"] isEqualToString:@""]);
  [vc deregisterNotifications];
}

- (void)testValidKeyDownEvent API_AVAILABLE(ios(13.4)) {
  if (@available(iOS 13.4, *)) {
    // noop
  } else {
    return;
  }

  FlutterEnginePartialMock* mockEngine = [[FlutterEnginePartialMock alloc] init];
  mockEngine.keyEventChannel = OCMClassMock([FlutterBasicMessageChannel class]);
  OCMStub([mockEngine.keyEventChannel sendMessage:[OCMArg any] reply:[OCMArg any]])
      .andCall(self, @selector(sendMessage:reply:));
  OCMStub([self.mockTextInputPlugin handlePress:[OCMArg any]]).andReturn(YES);
  mockEngine.textInputPlugin = self.mockTextInputPlugin;

  __strong FlutterViewController* vc = [[FlutterViewController alloc] initWithEngine:mockEngine
                                                                             nibName:nil
                                                                              bundle:nil];
  // Allocate the keyboard manager in the view controller by adding the internal
  // plugins.
  [vc addInternalPlugins];

  [vc handlePressEvent:keyDownEvent(UIKeyboardHIDUsageKeyboardA, UIKeyModifierShift, 123.0f, "A",
                                    "a")
            nextAction:^(){
            }];

  XCTAssert(self.messageSent != nil);
  XCTAssert([self.messageSent[@"keymap"] isEqualToString:@"ios"]);
  XCTAssert([self.messageSent[@"type"] isEqualToString:@"keydown"]);
  XCTAssert([self.messageSent[@"keyCode"] isEqualToNumber:[NSNumber numberWithInt:4]]);
  XCTAssert([self.messageSent[@"modifiers"] isEqualToNumber:[NSNumber numberWithInt:0]]);
  XCTAssert([self.messageSent[@"characters"] isEqualToString:@"A"]);
  XCTAssert([self.messageSent[@"charactersIgnoringModifiers"] isEqualToString:@"a"]);
  [vc deregisterNotifications];
  vc = nil;
}

- (void)testIgnoredKeyEvents API_AVAILABLE(ios(13.4)) {
  if (@available(iOS 13.4, *)) {
    // noop
  } else {
    return;
  }
  id keyEventChannel = OCMClassMock([FlutterBasicMessageChannel class]);
  OCMStub([keyEventChannel sendMessage:[OCMArg any] reply:[OCMArg any]])
      .andCall(self, @selector(sendMessage:reply:));
  OCMStub([self.mockTextInputPlugin handlePress:[OCMArg any]]).andReturn(YES);
  OCMStub([self.mockEngine keyEventChannel]).andReturn(keyEventChannel);

  FlutterViewController* vc = [[FlutterViewController alloc] initWithEngine:self.mockEngine
                                                                    nibName:nil
                                                                     bundle:nil];

  // Allocate the keyboard manager in the view controller by adding the internal
  // plugins.
  [vc addInternalPlugins];

  [vc handlePressEvent:keyEventWithPhase(UIPressPhaseStationary, UIKeyboardHIDUsageKeyboardA,
                                         UIKeyModifierShift, 123.0)
            nextAction:^(){
            }];
  [vc handlePressEvent:keyEventWithPhase(UIPressPhaseCancelled, UIKeyboardHIDUsageKeyboardA,
                                         UIKeyModifierShift, 123.0)
            nextAction:^(){
            }];
  [vc handlePressEvent:keyEventWithPhase(UIPressPhaseChanged, UIKeyboardHIDUsageKeyboardA,
                                         UIKeyModifierShift, 123.0)
            nextAction:^(){
            }];

  XCTAssert(self.messageSent == nil);
  OCMVerify(never(), [keyEventChannel sendMessage:[OCMArg any]]);
  [vc deregisterNotifications];
}

- (void)testPanGestureRecognizer API_AVAILABLE(ios(13.4)) {
  if (@available(iOS 13.4, *)) {
    // noop
  } else {
    return;
  }

  FlutterViewController* vc = [[FlutterViewController alloc] initWithEngine:self.mockEngine
                                                                    nibName:nil
                                                                     bundle:nil];
  XCTAssertNotNil(vc);
  UIView* view = vc.view;
  XCTAssertNotNil(view);
  NSArray* gestureRecognizers = view.gestureRecognizers;
  XCTAssertNotNil(gestureRecognizers);

  BOOL found = NO;
  for (id gesture in gestureRecognizers) {
    if ([gesture isKindOfClass:[UIPanGestureRecognizer class]]) {
      found = YES;
      break;
    }
  }
  XCTAssertTrue(found);
}

- (void)testMouseSupport API_AVAILABLE(ios(13.4)) {
  if (@available(iOS 13.4, *)) {
    // noop
  } else {
    return;
  }

  FlutterViewController* vc = [[FlutterViewController alloc] initWithEngine:self.mockEngine
                                                                    nibName:nil
                                                                     bundle:nil];
  XCTAssertNotNil(vc);

  id mockPanGestureRecognizer = OCMClassMock([UIPanGestureRecognizer class]);
  XCTAssertNotNil(mockPanGestureRecognizer);

  [vc discreteScrollEvent:mockPanGestureRecognizer];

  [[[self.mockEngine verify] ignoringNonObjectArgs]
      dispatchPointerDataPacket:std::make_unique<flutter::PointerDataPacket>(0)];
}

- (void)testFakeEventTimeStamp {
  FlutterViewController* vc = [[FlutterViewController alloc] initWithEngine:self.mockEngine
                                                                    nibName:nil
                                                                     bundle:nil];
  XCTAssertNotNil(vc);

  flutter::PointerData pointer_data = [vc generatePointerDataForFake];
  int64_t current_micros = [[NSProcessInfo processInfo] systemUptime] * 1000 * 1000;
  int64_t interval_micros = current_micros - pointer_data.time_stamp;
  const int64_t tolerance_millis = 2;
  XCTAssertTrue(interval_micros / 1000 < tolerance_millis,
                @"PointerData.time_stamp should be equal to NSProcessInfo.systemUptime");
}

- (void)testSplashScreenViewCanSetNil {
  FlutterViewController* flutterViewController =
      [[FlutterViewController alloc] initWithProject:nil nibName:nil bundle:nil];
  [flutterViewController setSplashScreenView:nil];
}

@end
