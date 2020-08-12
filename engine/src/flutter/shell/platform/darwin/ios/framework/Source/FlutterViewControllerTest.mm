// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>
#import "flutter/shell/platform/darwin/common/framework/Headers/FlutterMacros.h"
#import "flutter/shell/platform/darwin/ios/framework/Headers/FlutterViewController.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterViewController_Internal.h"

#include "FlutterBinaryMessenger.h"

FLUTTER_ASSERT_ARC

@interface FlutterEngine ()
- (BOOL)createShell:(NSString*)entrypoint
         libraryURI:(NSString*)libraryURI
       initialRoute:(NSString*)initialRoute;
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
@end

@implementation FlutterViewControllerTest

- (void)testViewDidDisappearDoesntPauseEngineWhenNotTheViewController {
  id engine = OCMClassMock([FlutterEngine class]);
  id lifecycleChannel = OCMClassMock([FlutterBasicMessageChannel class]);
  OCMStub([engine lifecycleChannel]).andReturn(lifecycleChannel);
  FlutterViewController* viewControllerA = [[FlutterViewController alloc] initWithEngine:engine
                                                                                 nibName:nil
                                                                                  bundle:nil];
  FlutterViewController* viewControllerB = [[FlutterViewController alloc] initWithEngine:engine
                                                                                 nibName:nil
                                                                                  bundle:nil];
  id viewControllerMock = OCMPartialMock(viewControllerA);
  OCMStub([viewControllerMock surfaceUpdated:NO]);
  OCMStub([engine viewController]).andReturn(viewControllerB);
  [viewControllerA viewDidDisappear:NO];
  OCMReject([lifecycleChannel sendMessage:@"AppLifecycleState.paused"]);
  OCMReject([viewControllerMock surfaceUpdated:[OCMArg any]]);
}

- (void)testViewDidDisappearDoesPauseEngineWhenIsTheViewController {
  id engine = OCMClassMock([FlutterEngine class]);
  id lifecycleChannel = OCMClassMock([FlutterBasicMessageChannel class]);
  OCMStub([engine lifecycleChannel]).andReturn(lifecycleChannel);
  FlutterViewController* viewController = [[FlutterViewController alloc] initWithEngine:engine
                                                                                nibName:nil
                                                                                 bundle:nil];
  id viewControllerMock = OCMPartialMock(viewController);
  OCMStub([viewControllerMock surfaceUpdated:NO]);
  OCMStub([engine viewController]).andReturn(viewController);
  [viewController viewDidDisappear:NO];
  OCMVerify([lifecycleChannel sendMessage:@"AppLifecycleState.paused"]);
  OCMVerify([viewControllerMock surfaceUpdated:NO]);
}

- (void)testBinaryMessenger {
  id engine = OCMClassMock([FlutterEngine class]);
  FlutterViewController* vc = [[FlutterViewController alloc] initWithEngine:engine
                                                                    nibName:nil
                                                                     bundle:nil];
  XCTAssertNotNil(vc);
  id messenger = OCMProtocolMock(@protocol(FlutterBinaryMessenger));
  OCMStub([engine binaryMessenger]).andReturn(messenger);
  XCTAssertEqual(vc.binaryMessenger, messenger);
  OCMVerify([engine binaryMessenger]);
}

#pragma mark - Platform Brightness

- (void)testItReportsLightPlatformBrightnessByDefault {
  // Setup test.
  id engine = OCMClassMock([FlutterEngine class]);

  id settingsChannel = OCMClassMock([FlutterBasicMessageChannel class]);
  OCMStub([engine settingsChannel]).andReturn(settingsChannel);

  FlutterViewController* vc = [[FlutterViewController alloc] initWithEngine:engine
                                                                    nibName:nil
                                                                     bundle:nil];

  // Exercise behavior under test.
  [vc traitCollectionDidChange:nil];

  // Verify behavior.
  OCMVerify([settingsChannel sendMessage:[OCMArg checkWithBlock:^BOOL(id message) {
                               return [message[@"platformBrightness"] isEqualToString:@"light"];
                             }]]);

  // Clean up mocks
  [engine stopMocking];
  [settingsChannel stopMocking];
}

- (void)testItReportsPlatformBrightnessWhenViewWillAppear {
  // Setup test.
  id engine = OCMClassMock([FlutterEngine class]);

  id settingsChannel = OCMClassMock([FlutterBasicMessageChannel class]);
  OCMStub([engine settingsChannel]).andReturn(settingsChannel);

  FlutterViewController* vc = [[FlutterViewController alloc] initWithEngine:engine
                                                                    nibName:nil
                                                                     bundle:nil];

  // Exercise behavior under test.
  [vc viewWillAppear:false];

  // Verify behavior.
  OCMVerify([settingsChannel sendMessage:[OCMArg checkWithBlock:^BOOL(id message) {
                               return [message[@"platformBrightness"] isEqualToString:@"light"];
                             }]]);

  // Clean up mocks
  [engine stopMocking];
  [settingsChannel stopMocking];
}

- (void)testItReportsDarkPlatformBrightnessWhenTraitCollectionRequestsIt {
  if (@available(iOS 13, *)) {
    // noop
  } else {
    return;
  }

  // Setup test.
  id engine = OCMClassMock([FlutterEngine class]);

  id settingsChannel = OCMClassMock([FlutterBasicMessageChannel class]);
  OCMStub([engine settingsChannel]).andReturn(settingsChannel);

  FlutterViewController* realVC = [[FlutterViewController alloc] initWithEngine:engine
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
  [engine stopMocking];
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
  id engine = OCMClassMock([FlutterEngine class]);

  id settingsChannel = OCMClassMock([FlutterBasicMessageChannel class]);
  OCMStub([engine settingsChannel]).andReturn(settingsChannel);

  FlutterViewController* vc = [[FlutterViewController alloc] initWithEngine:engine
                                                                    nibName:nil
                                                                     bundle:nil];

  // Exercise behavior under test.
  [vc traitCollectionDidChange:nil];

  // Verify behavior.
  OCMVerify([settingsChannel sendMessage:[OCMArg checkWithBlock:^BOOL(id message) {
                               return [message[@"platformContrast"] isEqualToString:@"normal"];
                             }]]);

  // Clean up mocks
  [engine stopMocking];
  [settingsChannel stopMocking];
}

- (void)testItReportsPlatformContrastWhenViewWillAppear {
  if (@available(iOS 13, *)) {
    // noop
  } else {
    return;
  }

  // Setup test.
  id engine = OCMClassMock([FlutterEngine class]);

  id settingsChannel = OCMClassMock([FlutterBasicMessageChannel class]);
  OCMStub([engine settingsChannel]).andReturn(settingsChannel);

  FlutterViewController* vc = [[FlutterViewController alloc] initWithEngine:engine
                                                                    nibName:nil
                                                                     bundle:nil];

  // Exercise behavior under test.
  [vc viewWillAppear:false];

  // Verify behavior.
  OCMVerify([settingsChannel sendMessage:[OCMArg checkWithBlock:^BOOL(id message) {
                               return [message[@"platformContrast"] isEqualToString:@"normal"];
                             }]]);

  // Clean up mocks
  [engine stopMocking];
  [settingsChannel stopMocking];
}

- (void)testItReportsHighContrastWhenTraitCollectionRequestsIt {
  if (@available(iOS 13, *)) {
    // noop
  } else {
    return;
  }

  // Setup test.
  id engine = OCMClassMock([FlutterEngine class]);

  id settingsChannel = OCMClassMock([FlutterBasicMessageChannel class]);
  OCMStub([engine settingsChannel]).andReturn(settingsChannel);

  FlutterViewController* realVC = [[FlutterViewController alloc] initWithEngine:engine
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
  [engine stopMocking];
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
  id engine = OCMClassMock([FlutterEngine class]);

  id deviceMock = OCMPartialMock([UIDevice currentDevice]);
  if (!didChange) {
    OCMReject([deviceMock setValue:[OCMArg any] forKey:@"orientation"]);
  } else {
    OCMExpect([deviceMock setValue:@(resultingOrientation) forKey:@"orientation"]);
  }

  FlutterViewController* realVC = [[FlutterViewController alloc] initWithEngine:engine
                                                                        nibName:nil
                                                                         bundle:nil];
  id mockApplication = OCMClassMock([UIApplication class]);
  OCMStub([mockApplication sharedApplication]).andReturn(mockApplication);
  OCMStub([mockApplication statusBarOrientation]).andReturn(currentOrientation);

  [realVC performOrientationUpdate:mask];
  OCMVerifyAll(deviceMock);
  [engine stopMocking];
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
  id engine = OCMClassMock([FlutterEngine class]);
  FlutterViewController* viewController = [[FlutterViewController alloc] initWithEngine:engine
                                                                                nibName:nil
                                                                                 bundle:nil];
  OCMStub([engine viewController]).andReturn(viewController);
  id viewControllerMock = OCMPartialMock(viewController);
  OCMStub([viewControllerMock surfaceUpdated:NO]);

  [viewController beginAppearanceTransition:NO animated:NO];
  [viewController endAppearanceTransition];
  OCMVerify([engine notifyLowMemory]);
}

@end
