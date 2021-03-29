// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "flutter/shell/platform/darwin/common/framework/Headers/FlutterBinaryMessenger.h"
#import "flutter/shell/platform/darwin/common/framework/Headers/FlutterMacros.h"
#import "flutter/shell/platform/darwin/ios/framework/Headers/FlutterViewController.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterViewController_Internal.h"

FLUTTER_ASSERT_ARC

namespace flutter {
class PointerDataPacket {};
}

/// Sometimes we have to use a custom mock to avoid retain cycles in ocmock.
@interface FlutterEnginePartialMock : FlutterEngine
@property(nonatomic, strong) FlutterBasicMessageChannel* lifecycleChannel;
@property(nonatomic, weak) FlutterViewController* viewController;
@property(nonatomic, assign) BOOL didCallNotifyLowMemory;
@end

@implementation FlutterEnginePartialMock
@synthesize viewController;
@synthesize lifecycleChannel;

- (void)notifyLowMemory {
  _didCallNotifyLowMemory = YES;
}
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

@implementation MockEngine
- (FlutterViewController*)viewController {
  return nil;
}
- (void)setViewController:(FlutterViewController*)viewController {
  // noop
}
@end

@interface FlutterViewControllerTest : XCTestCase
@property(nonatomic, strong) id mockEngine;
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

@interface FlutterViewController (Tests)
- (void)surfaceUpdated:(BOOL)appeared;
- (void)performOrientationUpdate:(UIInterfaceOrientationMask)new_preferences;
- (void)dispatchPresses:(NSSet<UIPress*>*)presses;
- (void)scrollEvent:(UIPanGestureRecognizer*)recognizer;
@end

@implementation FlutterViewControllerTest

- (void)setUp {
  self.mockEngine = OCMClassMock([FlutterEngine class]);
}

- (void)tearDown {
  // We stop mocking here to avoid retain cycles that stop
  // FlutterViewControllers from deallocing.
  [self.mockEngine stopMocking];
  self.mockEngine = nil;
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
  OCMStub([self.mockEngine settingsChannel]).andReturn(settingsChannel);

  FlutterViewController* vc = [[FlutterViewController alloc] initWithEngine:self.mockEngine
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

  // Setup test.
  id settingsChannel = OCMClassMock([FlutterBasicMessageChannel class]);
  OCMStub([self.mockEngine settingsChannel]).andReturn(settingsChannel);

  FlutterViewController* vc = [[FlutterViewController alloc] initWithEngine:self.mockEngine
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

- (void)testDoesntLoadViewInInit {
  FlutterDartProject* project = [[FlutterDartProject alloc] init];
  FlutterEngine* engine = [[FlutterEngine alloc] initWithName:@"foobar" project:project];
  [engine createShell:@"" libraryURI:@"" initialRoute:nil];
  FlutterViewController* realVC = [[FlutterViewController alloc] initWithEngine:engine
                                                                        nibName:nil
                                                                         bundle:nil];
  XCTAssertFalse([realVC isViewLoaded], @"shouldn't have loaded since it hasn't been shown");
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
  [viewControllerMock stopMocking];
}

- (void)testValidKeyUpEvent API_AVAILABLE(ios(13.4)) {
  if (@available(iOS 13.4, *)) {
    // noop
  } else {
    return;
  }

  id keyEventChannel = OCMClassMock([FlutterBasicMessageChannel class]);
  OCMStub([self.mockEngine keyEventChannel]).andReturn(keyEventChannel);

  FlutterViewController* vc = [[FlutterViewController alloc] initWithEngine:self.mockEngine
                                                                    nibName:nil
                                                                     bundle:nil];

  id testSet = [self fakeUiPressSetForPhase:UIPressPhaseBegan
                                    keyCode:UIKeyboardHIDUsageKeyboardA
                              modifierFlags:UIKeyModifierShift
                                 characters:@"a"
                charactersIgnoringModifiers:@"A"];

  // Exercise behavior under test.
  [vc dispatchPresses:testSet];

  // Verify behavior.
  OCMVerify([keyEventChannel
      sendMessage:[OCMArg checkWithBlock:^BOOL(id message) {
        return [message[@"keymap"] isEqualToString:@"ios"] &&
               [message[@"type"] isEqualToString:@"keydown"] &&
               [message[@"keyCode"] isEqualToNumber:[NSNumber numberWithInt:4]] &&
               [message[@"modifiers"] isEqualToNumber:[NSNumber numberWithInt:131072]] &&
               [message[@"characters"] isEqualToString:@"a"] &&
               [message[@"charactersIgnoringModifiers"] isEqualToString:@"A"];
      }]]);

  // Clean up mocks
  [keyEventChannel stopMocking];
}

- (void)testValidKeyDownEvent API_AVAILABLE(ios(13.4)) {
  if (@available(iOS 13.4, *)) {
    // noop
  } else {
    return;
  }

  id keyEventChannel = OCMClassMock([FlutterBasicMessageChannel class]);
  OCMStub([self.mockEngine keyEventChannel]).andReturn(keyEventChannel);

  FlutterViewController* vc = [[FlutterViewController alloc] initWithEngine:self.mockEngine
                                                                    nibName:nil
                                                                     bundle:nil];

  id testSet = [self fakeUiPressSetForPhase:UIPressPhaseEnded
                                    keyCode:UIKeyboardHIDUsageKeyboardA
                              modifierFlags:UIKeyModifierShift
                                 characters:@"a"
                charactersIgnoringModifiers:@"A"];

  // Exercise behavior under test.
  [vc dispatchPresses:testSet];

  // Verify behavior.
  OCMVerify([keyEventChannel
      sendMessage:[OCMArg checkWithBlock:^BOOL(id message) {
        return [message[@"keymap"] isEqualToString:@"ios"] &&
               [message[@"type"] isEqualToString:@"keyup"] &&
               [message[@"keyCode"] isEqualToNumber:[NSNumber numberWithInt:4]] &&
               [message[@"modifiers"] isEqualToNumber:[NSNumber numberWithInt:131072]] &&
               [message[@"characters"] isEqualToString:@"a"] &&
               [message[@"charactersIgnoringModifiers"] isEqualToString:@"A"];
      }]]);

  // Clean up mocks
  [keyEventChannel stopMocking];
}

- (void)testIgnoredKeyEvents API_AVAILABLE(ios(13.4)) {
  if (@available(iOS 13.4, *)) {
    // noop
  } else {
    return;
  }

  id keyEventChannel = OCMClassMock([FlutterBasicMessageChannel class]);
  OCMStub([self.mockEngine keyEventChannel]).andReturn(keyEventChannel);

  FlutterViewController* vc = [[FlutterViewController alloc] initWithEngine:self.mockEngine
                                                                    nibName:nil
                                                                     bundle:nil];

  id emptySet = [NSSet set];
  id ignoredSet = [self fakeUiPressSetForPhase:UIPressPhaseStationary
                                       keyCode:UIKeyboardHIDUsageKeyboardA
                                 modifierFlags:UIKeyModifierShift
                                    characters:@"a"
                   charactersIgnoringModifiers:@"A"];

  id mockUiPress = OCMClassMock([UIPress class]);
  OCMStub([mockUiPress phase]).andReturn(UIPressPhaseBegan);
  id emptyKeySet = [NSSet setWithArray:@[ mockUiPress ]];
  // Exercise behavior under test.
  [vc dispatchPresses:emptySet];
  [vc dispatchPresses:ignoredSet];
  [vc dispatchPresses:emptyKeySet];

  // Verify behavior.
  OCMVerify(never(), [keyEventChannel sendMessage:[OCMArg any]]);

  // Clean up mocks
  [keyEventChannel stopMocking];
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

  [vc scrollEvent:mockPanGestureRecognizer];

  [[[self.mockEngine verify] ignoringNonObjectArgs]
      dispatchPointerDataPacket:std::make_unique<flutter::PointerDataPacket>()];
}

- (NSSet<UIPress*>*)fakeUiPressSetForPhase:(UIPressPhase)phase
                                   keyCode:(UIKeyboardHIDUsage)keyCode
                             modifierFlags:(UIKeyModifierFlags)modifierFlags
                                characters:(NSString*)characters
               charactersIgnoringModifiers:(NSString*)charactersIgnoringModifiers
    API_AVAILABLE(ios(13.4)) {
  if (@available(iOS 13.4, *)) {
    // noop
  } else {
    return [NSSet set];
  }
  id mockUiPress = OCMClassMock([UIPress class]);
  OCMStub([mockUiPress phase]).andReturn(phase);

  id mockUiKey = OCMClassMock([UIKey class]);
  OCMStub([mockUiKey keyCode]).andReturn(keyCode);
  OCMStub([mockUiKey modifierFlags]).andReturn(modifierFlags);
  OCMStub([mockUiKey characters]).andReturn(characters);
  OCMStub([mockUiKey charactersIgnoringModifiers]).andReturn(charactersIgnoringModifiers);

  OCMStub([mockUiPress key]).andReturn(mockUiKey);

  return [NSSet setWithArray:@[ mockUiPress ]];
}

@end
