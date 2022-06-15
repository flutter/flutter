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

FLUTTER_ASSERT_ARC

@interface FlutterEngine ()
- (FlutterTextInputPlugin*)textInputPlugin;
- (void)sendKeyEvent:(const FlutterKeyEvent&)event
            callback:(nullable FlutterKeyEventCallback)callback
            userData:(nullable void*)userData;
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
@end

@implementation MockEngine
- (FlutterViewController*)viewController {
  return nil;
}
- (void)setViewController:(FlutterViewController*)viewController {
  // noop
}
@end

// The following conditional compilation defines an API 13 concept on earlier API targets so that
// a compiler compiling against API 12 or below does not blow up due to non-existent members.
#if __IPHONE_OS_VERSION_MAX_ALLOWED < 130000
typedef enum UIAccessibilityContrast : NSInteger {
  UIAccessibilityContrastUnspecified = 0,
  UIAccessibilityContrastNormal = 1,
  UIAccessibilityContrastHigh = 2
} UIAccessibilityContrast;

@interface UITraitCollection (MethodsFromNewerSDK)
- (UIAccessibilityContrast)accessibilityContrast;
@end
#endif

@interface FlutterKeyboardManager (Tests)
@property(nonatomic, retain, readonly)
    NSMutableArray<id<FlutterKeyPrimaryResponder>>* primaryResponders;
@end

@interface FlutterEmbedderKeyResponder (Tests)
@property(nonatomic, copy, readonly) FlutterSendKeyEvent sendEvent;
@end

@interface FlutterViewController (Tests)

@property(nonatomic, assign) double targetViewInsetBottom;

- (void)surfaceUpdated:(BOOL)appeared;
- (void)performOrientationUpdate:(UIInterfaceOrientationMask)new_preferences;
- (void)handlePressEvent:(FlutterUIPressProxy*)press
              nextAction:(void (^)())next API_AVAILABLE(ios(13.4));
- (void)discreteScrollEvent:(UIPanGestureRecognizer*)recognizer;
- (void)updateViewportMetrics;
- (void)onUserSettingsChanged:(NSNotification*)notification;
- (void)applicationWillTerminate:(NSNotification*)notification;
- (void)goToApplicationLifecycle:(nonnull NSString*)state;
- (void)keyboardWillChangeFrame:(NSNotification*)notification;
- (void)keyboardWillBeHidden:(NSNotification*)notification;
- (void)startKeyBoardAnimation:(NSTimeInterval)duration;
- (void)ensureViewportMetricsIsCorrect;
- (void)invalidateDisplayLink;
- (void)addInternalPlugins;
- (flutter::PointerData)generatePointerDataForFake;
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

- (void)testkeyboardWillChangeFrameWillStartKeyboardAnimation {
  FlutterEngine* mockEngine = OCMPartialMock([[FlutterEngine alloc] init]);
  [mockEngine createShell:@"" libraryURI:@"" initialRoute:nil];
  FlutterViewController* viewController = [[FlutterViewController alloc] initWithEngine:mockEngine
                                                                                nibName:nil
                                                                                 bundle:nil];

  CGFloat width = UIScreen.mainScreen.bounds.size.width;
  CGRect keyboardFrame = CGRectMake(0, 100, width, 400);
  BOOL isLocal = YES;
  NSNotification* notification = [NSNotification
      notificationWithName:@""
                    object:nil
                  userInfo:@{
                    @"UIKeyboardFrameEndUserInfoKey" : [NSValue valueWithCGRect:keyboardFrame],
                    @"UIKeyboardAnimationDurationUserInfoKey" : [NSNumber numberWithDouble:0.25],
                    @"UIKeyboardIsLocalUserInfoKey" : [NSNumber numberWithBool:isLocal]
                  }];

  XCTestExpectation* expectation = [self expectationWithDescription:@"update viewport"];
  OCMStub([mockEngine updateViewportMetrics:flutter::ViewportMetrics()])
      .ignoringNonObjectArgs()
      .andDo(^(NSInvocation* invocation) {
        [expectation fulfill];
      });
  id viewControllerMock = OCMPartialMock(viewController);
  [viewControllerMock keyboardWillChangeFrame:notification];
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
  CGRect keyboardFrame = CGRectMake(0, 0, 0, 0);
  BOOL isLocal = YES;
  NSNotification* fakeNotification = [NSNotification
      notificationWithName:@""
                    object:nil
                  userInfo:@{
                    @"UIKeyboardFrameEndUserInfoKey" : [NSValue valueWithCGRect:keyboardFrame],
                    @"UIKeyboardAnimationDurationUserInfoKey" : @(0.25),
                    @"UIKeyboardIsLocalUserInfoKey" : @(isLocal)
                  }];

  viewControllerMock.targetViewInsetBottom = 10;
  [viewControllerMock keyboardWillBeHidden:fakeNotification];
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
  OCMVerify([viewControllerMock invalidateDisplayLink]);
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

- (void)testUpdateViewportMetricsDoesntInvokeEngineWhenNotTheViewController {
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
  [viewControllerA updateViewportMetrics];
  flutter::ViewportMetrics viewportMetrics;
  OCMVerify(never(), [mockEngine updateViewportMetrics:viewportMetrics]);
}

- (void)testUpdateViewportMetricsDoesInvokeEngineWhenIsTheViewController {
  FlutterEngine* mockEngine = OCMPartialMock([[FlutterEngine alloc] init]);
  [mockEngine createShell:@"" libraryURI:@"" initialRoute:nil];
  FlutterViewController* viewController = [[FlutterViewController alloc] initWithEngine:mockEngine
                                                                                nibName:nil
                                                                                 bundle:nil];
  mockEngine.viewController = viewController;
  flutter::ViewportMetrics viewportMetrics;
  OCMExpect([mockEngine updateViewportMetrics:viewportMetrics]).ignoringNonObjectArgs();
  [viewController updateViewportMetrics];
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
  OCMVerify([mockEngine attachView]);
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
  id deviceMock = OCMPartialMock([UIDevice currentDevice]);
  if (!didChange) {
    OCMReject([deviceMock setValue:[OCMArg any] forKey:@"orientation"]);
  } else {
    OCMExpect([deviceMock setValue:@(resultingOrientation) forKey:@"orientation"]);
  }

  FlutterViewController* realVC = [[FlutterViewController alloc] initWithEngine:self.mockEngine
                                                                        nibName:nil
                                                                         bundle:nil];
  id mockApplication = OCMClassMock([UIApplication class]);
  OCMStub([mockApplication sharedApplication]).andReturn(mockApplication);
  OCMStub([mockApplication statusBarOrientation]).andReturn(currentOrientation);

  [realVC performOrientationUpdate:mask];
  OCMVerifyAll(deviceMock);
  [deviceMock stopMocking];
  [mockApplication stopMocking];
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
@end
