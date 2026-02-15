// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "flutter/shell/platform/darwin/common/framework/Headers/FlutterBinaryMessenger.h"
#import "flutter/shell/platform/darwin/common/framework/Headers/FlutterMacros.h"
#import "flutter/shell/platform/darwin/ios/framework/Headers/FlutterViewController.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterEngine_Internal.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterPlatformPlugin.h"
#import "flutter/shell/platform/darwin/ios/platform_view_ios.h"

FLUTTER_ASSERT_ARC

@interface FlutterPlatformPluginTest : XCTestCase
@end

@interface FlutterPlatformPlugin ()
- (BOOL)isLiveTextInputAvailable;
- (void)searchWeb:(NSString*)searchTerm;
- (void)showLookUpViewController:(NSString*)term;
- (void)showShareViewController:(NSString*)content;
- (void)playSystemSound:(NSString*)soundType;
- (void)vibrateHapticFeedback:(NSString*)feedbackType;
@end

@interface UIViewController ()
- (void)presentViewController:(UIViewController*)viewControllerToPresent
                     animated:(BOOL)flag
                   completion:(void (^)(void))completion;
@end

@implementation FlutterPlatformPluginTest

- (void)testSearchWebInvokedWithEscapedTerm {
  id mockApplication = OCMClassMock([UIApplication class]);
  OCMStub([mockApplication sharedApplication]).andReturn(mockApplication);

  FlutterEngine* engine = [[FlutterEngine alloc] initWithName:@"test" project:nil];
  [engine runWithEntrypoint:nil];

  XCTestExpectation* invokeExpectation =
      [self expectationWithDescription:@"Web search launched with escaped search term"];

  FlutterPlatformPlugin* plugin = [[FlutterPlatformPlugin alloc] initWithEngine:engine];
  FlutterPlatformPlugin* mockPlugin = OCMPartialMock(plugin);

  FlutterMethodCall* methodCall = [FlutterMethodCall methodCallWithMethodName:@"SearchWeb.invoke"
                                                                    arguments:@"Testing Word!"];

  FlutterResult result = ^(id result) {
    OCMVerify([mockPlugin searchWeb:@"Testing Word!"]);
    OCMVerify([mockApplication openURL:[NSURL URLWithString:@"x-web-search://?Testing%20Word!"]
                               options:@{}
                     completionHandler:nil]);
    [invokeExpectation fulfill];
  };

  [mockPlugin handleMethodCall:methodCall result:result];
  [self waitForExpectationsWithTimeout:1 handler:nil];
  [mockApplication stopMocking];
}

- (void)testSearchWebSkippedIfAppExtension {
  id mockBundle = OCMPartialMock([NSBundle mainBundle]);
  OCMStub([mockBundle objectForInfoDictionaryKey:@"NSExtension"]).andReturn(@{
    @"NSExtensionPointIdentifier" : @"com.apple.share-services"
  });
  id mockApplication = OCMClassMock([UIApplication class]);
  OCMStub([mockApplication sharedApplication]).andReturn(mockApplication);
  OCMReject([mockApplication openURL:OCMOCK_ANY options:OCMOCK_ANY completionHandler:OCMOCK_ANY]);
  FlutterEngine* engine = [[FlutterEngine alloc] initWithName:@"test" project:nil];
  [engine runWithEntrypoint:nil];

  XCTestExpectation* invokeExpectation =
      [self expectationWithDescription:@"Web search launched with non escaped search term"];

  FlutterPlatformPlugin* plugin = [[FlutterPlatformPlugin alloc] initWithEngine:engine];
  FlutterPlatformPlugin* mockPlugin = OCMPartialMock(plugin);

  FlutterMethodCall* methodCall = [FlutterMethodCall methodCallWithMethodName:@"SearchWeb.invoke"
                                                                    arguments:@"Test"];

  FlutterResult result = ^(id result) {
    OCMVerify([mockPlugin searchWeb:@"Test"]);

    [invokeExpectation fulfill];
  };

  [mockPlugin handleMethodCall:methodCall result:result];
  [self waitForExpectationsWithTimeout:1 handler:nil];
  [mockBundle stopMocking];
  [mockApplication stopMocking];
}

- (void)testLookUpCallInitiated {
  FlutterEngine* engine = [[FlutterEngine alloc] initWithName:@"test" project:nil];
  [engine runWithEntrypoint:nil];

  XCTestExpectation* presentExpectation =
      [self expectationWithDescription:@"Look Up view controller presented"];

  FlutterViewController* engineViewController = [[FlutterViewController alloc] initWithEngine:engine
                                                                                      nibName:nil
                                                                                       bundle:nil];
  FlutterViewController* mockEngineViewController = OCMPartialMock(engineViewController);

  FlutterPlatformPlugin* plugin = [[FlutterPlatformPlugin alloc] initWithEngine:engine];
  FlutterPlatformPlugin* mockPlugin = OCMPartialMock(plugin);

  FlutterMethodCall* methodCall = [FlutterMethodCall methodCallWithMethodName:@"LookUp.invoke"
                                                                    arguments:@"Test"];
  FlutterResult result = ^(id result) {
    OCMVerify([mockEngineViewController
        presentViewController:[OCMArg isKindOfClass:[UIReferenceLibraryViewController class]]
                     animated:YES
                   completion:nil]);
    [presentExpectation fulfill];
  };
  [mockPlugin handleMethodCall:methodCall result:result];
  [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)testShareScreenInvoked {
  FlutterEngine* engine = [[FlutterEngine alloc] initWithName:@"test" project:nil];
  [engine runWithEntrypoint:nil];

  XCTestExpectation* presentExpectation =
      [self expectationWithDescription:@"Share view controller presented"];

  FlutterViewController* engineViewController = [[FlutterViewController alloc] initWithEngine:engine
                                                                                      nibName:nil
                                                                                       bundle:nil];
  FlutterViewController* mockEngineViewController = OCMPartialMock(engineViewController);
  OCMStub([mockEngineViewController
      presentViewController:[OCMArg isKindOfClass:[UIActivityViewController class]]
                   animated:YES
                 completion:nil]);

  FlutterPlatformPlugin* plugin = [[FlutterPlatformPlugin alloc] initWithEngine:engine];
  FlutterPlatformPlugin* mockPlugin = OCMPartialMock(plugin);

  FlutterMethodCall* methodCall = [FlutterMethodCall methodCallWithMethodName:@"Share.invoke"
                                                                    arguments:@"Test"];
  FlutterResult result = ^(id result) {
    OCMVerify([mockEngineViewController
        presentViewController:[OCMArg isKindOfClass:[UIActivityViewController class]]
                     animated:YES
                   completion:nil]);
    [presentExpectation fulfill];
  };
  [mockPlugin handleMethodCall:methodCall result:result];
  [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testShareScreenInvokedOnIPad {
  FlutterEngine* engine = [[FlutterEngine alloc] initWithName:@"test" project:nil];
  [engine runWithEntrypoint:nil];

  XCTestExpectation* presentExpectation =
      [self expectationWithDescription:@"Share view controller presented on iPad"];

  FlutterViewController* engineViewController = [[FlutterViewController alloc] initWithEngine:engine
                                                                                      nibName:nil
                                                                                       bundle:nil];
  FlutterViewController* mockEngineViewController = OCMPartialMock(engineViewController);
  OCMStub([mockEngineViewController
      presentViewController:[OCMArg isKindOfClass:[UIActivityViewController class]]
                   animated:YES
                 completion:nil]);

  id mockTraitCollection = OCMClassMock([UITraitCollection class]);
  OCMStub([mockTraitCollection userInterfaceIdiom]).andReturn(UIUserInterfaceIdiomPad);

  FlutterPlatformPlugin* plugin = [[FlutterPlatformPlugin alloc] initWithEngine:engine];
  FlutterPlatformPlugin* mockPlugin = OCMPartialMock(plugin);

  FlutterMethodCall* methodCall = [FlutterMethodCall methodCallWithMethodName:@"Share.invoke"
                                                                    arguments:@"Test"];
  FlutterResult result = ^(id result) {
    OCMVerify([mockEngineViewController
        presentViewController:[OCMArg isKindOfClass:[UIActivityViewController class]]
                     animated:YES
                   completion:nil]);
    [presentExpectation fulfill];
  };
  [mockPlugin handleMethodCall:methodCall result:result];
  [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testClipboardHasCorrectStrings {
  [UIPasteboard generalPasteboard].string = nil;
  FlutterEngine* engine = [[FlutterEngine alloc] initWithName:@"test" project:nil];
  FlutterPlatformPlugin* plugin = [[FlutterPlatformPlugin alloc] initWithEngine:engine];

  XCTestExpectation* setStringExpectation = [self expectationWithDescription:@"setString"];
  FlutterResult resultSet = ^(id result) {
    [setStringExpectation fulfill];
  };
  FlutterMethodCall* methodCallSet =
      [FlutterMethodCall methodCallWithMethodName:@"Clipboard.setData"
                                        arguments:@{@"text" : @"some string"}];
  [plugin handleMethodCall:methodCallSet result:resultSet];
  [self waitForExpectationsWithTimeout:1 handler:nil];

  XCTestExpectation* hasStringsExpectation = [self expectationWithDescription:@"hasStrings"];
  FlutterResult result = ^(id result) {
    XCTAssertTrue([result[@"value"] boolValue]);
    [hasStringsExpectation fulfill];
  };
  FlutterMethodCall* methodCall =
      [FlutterMethodCall methodCallWithMethodName:@"Clipboard.hasStrings" arguments:nil];
  [plugin handleMethodCall:methodCall result:result];
  [self waitForExpectationsWithTimeout:1 handler:nil];

  XCTestExpectation* getDataExpectation = [self expectationWithDescription:@"getData"];
  FlutterResult getDataResult = ^(id result) {
    XCTAssertEqualObjects(result[@"text"], @"some string");
    [getDataExpectation fulfill];
  };
  FlutterMethodCall* methodCallGetData =
      [FlutterMethodCall methodCallWithMethodName:@"Clipboard.getData" arguments:@"text/plain"];
  [plugin handleMethodCall:methodCallGetData result:getDataResult];
  [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testClipboardSetDataToNullDoNotCrash {
  [UIPasteboard generalPasteboard].string = nil;
  FlutterEngine* engine = [[FlutterEngine alloc] initWithName:@"test" project:nil];
  FlutterPlatformPlugin* plugin = [[FlutterPlatformPlugin alloc] initWithEngine:engine];

  XCTestExpectation* setStringExpectation = [self expectationWithDescription:@"setData"];
  FlutterResult resultSet = ^(id result) {
    [setStringExpectation fulfill];
  };
  FlutterMethodCall* methodCallSet =
      [FlutterMethodCall methodCallWithMethodName:@"Clipboard.setData"
                                        arguments:@{@"text" : [NSNull null]}];
  [plugin handleMethodCall:methodCallSet result:resultSet];

  XCTestExpectation* getDataExpectation = [self expectationWithDescription:@"getData"];
  FlutterResult result = ^(id result) {
    XCTAssertEqualObjects(result[@"text"], @"null");
    [getDataExpectation fulfill];
  };
  FlutterMethodCall* methodCall = [FlutterMethodCall methodCallWithMethodName:@"Clipboard.getData"
                                                                    arguments:@"text/plain"];
  [plugin handleMethodCall:methodCall result:result];
  [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testPopSystemNavigator {
  FlutterEngine* engine = [[FlutterEngine alloc] initWithName:@"test" project:nil];
  [engine runWithEntrypoint:nil];
  FlutterViewController* flutterViewController =
      [[FlutterViewController alloc] initWithEngine:engine nibName:nil bundle:nil];
  UINavigationController* navigationController =
      [[UINavigationController alloc] initWithRootViewController:flutterViewController];
  UITabBarController* tabBarController = [[UITabBarController alloc] init];
  tabBarController.viewControllers = @[ navigationController ];
  FlutterPlatformPlugin* plugin = [[FlutterPlatformPlugin alloc] initWithEngine:engine];

  id navigationControllerMock = OCMPartialMock(navigationController);
  OCMStub([navigationControllerMock popViewControllerAnimated:YES]);
  // Set some string to the pasteboard.
  XCTestExpectation* navigationPopCalled = [self expectationWithDescription:@"SystemNavigator.pop"];
  FlutterResult resultSet = ^(id result) {
    [navigationPopCalled fulfill];
  };
  FlutterMethodCall* methodCallSet =
      [FlutterMethodCall methodCallWithMethodName:@"SystemNavigator.pop" arguments:@(YES)];
  [plugin handleMethodCall:methodCallSet result:resultSet];
  [self waitForExpectationsWithTimeout:1 handler:nil];
  OCMVerify([navigationControllerMock popViewControllerAnimated:YES]);

  [flutterViewController deregisterNotifications];
}

- (void)testWhetherDeviceHasLiveTextInputInvokeCorrectly {
  FlutterEngine* engine = [[FlutterEngine alloc] initWithName:@"test" project:nil];
  XCTestExpectation* invokeExpectation =
      [self expectationWithDescription:@"isLiveTextInputAvailableInvoke"];
  FlutterPlatformPlugin* plugin = [[FlutterPlatformPlugin alloc] initWithEngine:engine];
  FlutterPlatformPlugin* mockPlugin = OCMPartialMock(plugin);
  FlutterMethodCall* methodCall =
      [FlutterMethodCall methodCallWithMethodName:@"LiveText.isLiveTextInputAvailable"
                                        arguments:nil];
  FlutterResult result = ^(id result) {
    OCMVerify([mockPlugin isLiveTextInputAvailable]);
    [invokeExpectation fulfill];
  };
  [mockPlugin handleMethodCall:methodCall result:result];
  [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testSystemSoundPlay {
  FlutterEngine* engine = [[FlutterEngine alloc] initWithName:@"test" project:nil];
  XCTestExpectation* invokeExpectation =
      [self expectationWithDescription:@"SystemSound.play invoked"];
  FlutterPlatformPlugin* plugin = [[FlutterPlatformPlugin alloc] initWithEngine:engine];
  FlutterPlatformPlugin* mockPlugin = OCMPartialMock(plugin);

  FlutterMethodCall* methodCall =
      [FlutterMethodCall methodCallWithMethodName:@"SystemSound.play"
                                        arguments:@"SystemSoundType.click"];
  FlutterResult result = ^(id result) {
    OCMVerify([mockPlugin playSystemSound:@"SystemSoundType.click"]);
    [invokeExpectation fulfill];
  };
  [mockPlugin handleMethodCall:methodCall result:result];
  [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testHapticFeedbackVibrate {
  FlutterEngine* engine = [[FlutterEngine alloc] initWithName:@"test" project:nil];
  XCTestExpectation* invokeExpectation =
      [self expectationWithDescription:@"HapticFeedback.vibrate invoked"];
  FlutterPlatformPlugin* plugin = [[FlutterPlatformPlugin alloc] initWithEngine:engine];
  FlutterPlatformPlugin* mockPlugin = OCMPartialMock(plugin);

  FlutterMethodCall* methodCall =
      [FlutterMethodCall methodCallWithMethodName:@"HapticFeedback.vibrate"
                                        arguments:@"HapticFeedbackType.lightImpact"];
  FlutterResult result = ^(id result) {
    OCMVerify([mockPlugin vibrateHapticFeedback:@"HapticFeedbackType.lightImpact"]);
    [invokeExpectation fulfill];
  };
  [mockPlugin handleMethodCall:methodCall result:result];
  [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testViewControllerBasedStatusBarHiddenUpdate {
  id bundleMock = OCMPartialMock([NSBundle mainBundle]);
  OCMStub([bundleMock objectForInfoDictionaryKey:@"UIViewControllerBasedStatusBarAppearance"])
      .andReturn(@YES);
  {
    // Enabling system UI overlays to update status bar.
    FlutterEngine* engine = [[FlutterEngine alloc] initWithName:@"test" project:nil];
    [engine runWithEntrypoint:nil];
    FlutterViewController* flutterViewController =
        [[FlutterViewController alloc] initWithEngine:engine nibName:nil bundle:nil];
    XCTAssertFalse(flutterViewController.prefersStatusBarHidden);

    // Update to hidden.
    FlutterPlatformPlugin* plugin = [engine platformPlugin];

    XCTestExpectation* enableSystemUIOverlaysCalled =
        [self expectationWithDescription:@"setEnabledSystemUIOverlays"];
    FlutterResult resultSet = ^(id result) {
      [enableSystemUIOverlaysCalled fulfill];
    };
    FlutterMethodCall* methodCallSet =
        [FlutterMethodCall methodCallWithMethodName:@"SystemChrome.setEnabledSystemUIOverlays"
                                          arguments:@[ @"SystemUiOverlay.bottom" ]];
    [plugin handleMethodCall:methodCallSet result:resultSet];
    [self waitForExpectationsWithTimeout:1 handler:nil];
    XCTAssertTrue(flutterViewController.prefersStatusBarHidden);

    // Update to shown.
    XCTestExpectation* enableSystemUIOverlaysCalled2 =
        [self expectationWithDescription:@"setEnabledSystemUIOverlays"];
    FlutterResult resultSet2 = ^(id result) {
      [enableSystemUIOverlaysCalled2 fulfill];
    };
    FlutterMethodCall* methodCallSet2 =
        [FlutterMethodCall methodCallWithMethodName:@"SystemChrome.setEnabledSystemUIOverlays"
                                          arguments:@[ @"SystemUiOverlay.top" ]];
    [plugin handleMethodCall:methodCallSet2 result:resultSet2];
    [self waitForExpectationsWithTimeout:1 handler:nil];
    XCTAssertFalse(flutterViewController.prefersStatusBarHidden);

    [flutterViewController deregisterNotifications];
  }
  {
    // Enable system UI mode to update status bar.
    FlutterEngine* engine = [[FlutterEngine alloc] initWithName:@"test" project:nil];
    [engine runWithEntrypoint:nil];
    FlutterViewController* flutterViewController =
        [[FlutterViewController alloc] initWithEngine:engine nibName:nil bundle:nil];
    XCTAssertFalse(flutterViewController.prefersStatusBarHidden);

    // Update to hidden.
    FlutterPlatformPlugin* plugin = [engine platformPlugin];

    XCTestExpectation* enableSystemUIModeCalled =
        [self expectationWithDescription:@"setEnabledSystemUIMode"];
    FlutterResult resultSet = ^(id result) {
      [enableSystemUIModeCalled fulfill];
    };
    FlutterMethodCall* methodCallSet =
        [FlutterMethodCall methodCallWithMethodName:@"SystemChrome.setEnabledSystemUIMode"
                                          arguments:@"SystemUiMode.immersive"];
    [plugin handleMethodCall:methodCallSet result:resultSet];
    [self waitForExpectationsWithTimeout:1 handler:nil];
    XCTAssertTrue(flutterViewController.prefersStatusBarHidden);

    // Update to shown.
    XCTestExpectation* enableSystemUIModeCalled2 =
        [self expectationWithDescription:@"setEnabledSystemUIMode"];
    FlutterResult resultSet2 = ^(id result) {
      [enableSystemUIModeCalled2 fulfill];
    };
    FlutterMethodCall* methodCallSet2 =
        [FlutterMethodCall methodCallWithMethodName:@"SystemChrome.setEnabledSystemUIMode"
                                          arguments:@"SystemUiMode.edgeToEdge"];
    [plugin handleMethodCall:methodCallSet2 result:resultSet2];
    [self waitForExpectationsWithTimeout:1 handler:nil];
    XCTAssertFalse(flutterViewController.prefersStatusBarHidden);

    [flutterViewController deregisterNotifications];
  }
  [bundleMock stopMocking];
}

- (void)testStatusBarHiddenUpdate {
  id bundleMock = OCMPartialMock([NSBundle mainBundle]);
  OCMStub([bundleMock objectForInfoDictionaryKey:@"UIViewControllerBasedStatusBarAppearance"])
      .andReturn(@NO);
  id mockApplication = OCMClassMock([UIApplication class]);
  OCMStub([mockApplication sharedApplication]).andReturn(mockApplication);

  // Enabling system UI overlays to update status bar.
  FlutterEngine* engine = [[FlutterEngine alloc] initWithName:@"test" project:nil];
  [engine runWithEntrypoint:nil];
  FlutterViewController* flutterViewController =
      [[FlutterViewController alloc] initWithEngine:engine nibName:nil bundle:nil];

  // Update the visibility of the status bar to hidden.
  FlutterPlatformPlugin* plugin = [engine platformPlugin];

  XCTestExpectation* systemOverlaysBottomExpectation =
      [self expectationWithDescription:@"setEnabledSystemUIOverlays"];
  FlutterResult systemOverlaysBottomResult = ^(id result) {
    [systemOverlaysBottomExpectation fulfill];
  };
  FlutterMethodCall* setSystemOverlaysBottomCall =
      [FlutterMethodCall methodCallWithMethodName:@"SystemChrome.setEnabledSystemUIOverlays"
                                        arguments:@[ @"SystemUiOverlay.bottom" ]];
  [plugin handleMethodCall:setSystemOverlaysBottomCall result:systemOverlaysBottomResult];
  [self waitForExpectationsWithTimeout:1 handler:nil];
  OCMVerify([mockApplication setStatusBarHidden:YES]);

  // Update the visibility of the status bar to shown.
  XCTestExpectation* systemOverlaysTopExpectation =
      [self expectationWithDescription:@"setEnabledSystemUIOverlays"];
  FlutterResult systemOverlaysTopResult = ^(id result) {
    [systemOverlaysTopExpectation fulfill];
  };
  FlutterMethodCall* setSystemOverlaysTopCall =
      [FlutterMethodCall methodCallWithMethodName:@"SystemChrome.setEnabledSystemUIOverlays"
                                        arguments:@[ @"SystemUiOverlay.top" ]];
  [plugin handleMethodCall:setSystemOverlaysTopCall result:systemOverlaysTopResult];
  [self waitForExpectationsWithTimeout:1 handler:nil];
  OCMVerify([mockApplication setStatusBarHidden:NO]);

  [flutterViewController deregisterNotifications];
  [mockApplication stopMocking];
  [bundleMock stopMocking];
}

- (void)testStatusBarHiddenNotUpdatedInAppExtension {
  id bundleMock = OCMPartialMock([NSBundle mainBundle]);
  OCMStub([bundleMock objectForInfoDictionaryKey:@"UIViewControllerBasedStatusBarAppearance"])
      .andReturn(@NO);
  OCMStub([bundleMock objectForInfoDictionaryKey:@"NSExtension"]).andReturn(@{
    @"NSExtensionPointIdentifier" : @"com.apple.share-services"
  });
  id mockApplication = OCMClassMock([UIApplication class]);
  OCMStub([mockApplication sharedApplication]).andReturn(mockApplication);
  OCMReject([mockApplication setStatusBarHidden:OCMOCK_ANY]);

  // Enabling system UI overlays to update status bar.
  FlutterEngine* engine = [[FlutterEngine alloc] initWithName:@"test" project:nil];
  [engine runWithEntrypoint:nil];
  FlutterViewController* flutterViewController =
      [[FlutterViewController alloc] initWithEngine:engine nibName:nil bundle:nil];

  // Update the visibility of the status bar to hidden does not occur with extensions.
  FlutterPlatformPlugin* plugin = [engine platformPlugin];

  XCTestExpectation* systemOverlaysBottomExpectation =
      [self expectationWithDescription:@"setEnabledSystemUIOverlays"];
  FlutterResult systemOverlaysBottomResult = ^(id result) {
    [systemOverlaysBottomExpectation fulfill];
  };
  FlutterMethodCall* setSystemOverlaysBottomCall =
      [FlutterMethodCall methodCallWithMethodName:@"SystemChrome.setEnabledSystemUIOverlays"
                                        arguments:@[ @"SystemUiOverlay.bottom" ]];
  [plugin handleMethodCall:setSystemOverlaysBottomCall result:systemOverlaysBottomResult];
  [self waitForExpectationsWithTimeout:1 handler:nil];
  OCMReject([mockApplication setStatusBarHidden:YES]);

  // Update the visibility of the status bar to shown does not occur with extensions.
  XCTestExpectation* systemOverlaysTopExpectation =
      [self expectationWithDescription:@"setEnabledSystemUIOverlays"];
  FlutterResult systemOverlaysTopResult = ^(id result) {
    [systemOverlaysTopExpectation fulfill];
  };
  FlutterMethodCall* setSystemOverlaysTopCall =
      [FlutterMethodCall methodCallWithMethodName:@"SystemChrome.setEnabledSystemUIOverlays"
                                        arguments:@[ @"SystemUiOverlay.top" ]];
  [plugin handleMethodCall:setSystemOverlaysTopCall result:systemOverlaysTopResult];
  [self waitForExpectationsWithTimeout:1 handler:nil];
  OCMReject([mockApplication setStatusBarHidden:NO]);

  [flutterViewController deregisterNotifications];
  [mockApplication stopMocking];
  [bundleMock stopMocking];
}

- (void)testStatusBarStyle {
  id bundleMock = OCMPartialMock([NSBundle mainBundle]);
  OCMStub([bundleMock objectForInfoDictionaryKey:@"UIViewControllerBasedStatusBarAppearance"])
      .andReturn(@NO);
  id mockApplication = OCMClassMock([UIApplication class]);
  OCMStub([mockApplication sharedApplication]).andReturn(mockApplication);

  FlutterEngine* engine = [[FlutterEngine alloc] initWithName:@"test" project:nil];
  [engine runWithEntrypoint:nil];
  FlutterViewController* flutterViewController =
      [[FlutterViewController alloc] initWithEngine:engine nibName:nil bundle:nil];
  XCTAssertFalse(flutterViewController.prefersStatusBarHidden);

  FlutterPlatformPlugin* plugin = [engine platformPlugin];

  XCTestExpectation* enableSystemUIModeCalled =
      [self expectationWithDescription:@"setSystemUIOverlayStyle"];
  FlutterResult resultSet = ^(id result) {
    [enableSystemUIModeCalled fulfill];
  };
  FlutterMethodCall* methodCallSet =
      [FlutterMethodCall methodCallWithMethodName:@"SystemChrome.setSystemUIOverlayStyle"
                                        arguments:@{@"statusBarBrightness" : @"Brightness.dark"}];
  [plugin handleMethodCall:methodCallSet result:resultSet];
  [self waitForExpectationsWithTimeout:1 handler:nil];

  OCMVerify([mockApplication setStatusBarStyle:UIStatusBarStyleLightContent]);

  [flutterViewController deregisterNotifications];
  [mockApplication stopMocking];
  [bundleMock stopMocking];
}

- (void)testStatusBarStyleNotUpdatedInAppExtension {
  id bundleMock = OCMPartialMock([NSBundle mainBundle]);
  OCMStub([bundleMock objectForInfoDictionaryKey:@"UIViewControllerBasedStatusBarAppearance"])
      .andReturn(@NO);
  OCMStub([bundleMock objectForInfoDictionaryKey:@"NSExtension"]).andReturn(@{
    @"NSExtensionPointIdentifier" : @"com.apple.share-services"
  });
  id mockApplication = OCMClassMock([UIApplication class]);
  OCMStub([mockApplication sharedApplication]).andReturn(mockApplication);
  OCMReject([mockApplication setStatusBarHidden:OCMOCK_ANY]);

  FlutterEngine* engine = [[FlutterEngine alloc] initWithName:@"test" project:nil];
  [engine runWithEntrypoint:nil];
  FlutterViewController* flutterViewController =
      [[FlutterViewController alloc] initWithEngine:engine nibName:nil bundle:nil];
  XCTAssertFalse(flutterViewController.prefersStatusBarHidden);

  FlutterPlatformPlugin* plugin = [engine platformPlugin];

  XCTestExpectation* enableSystemUIModeCalled =
      [self expectationWithDescription:@"setSystemUIOverlayStyle"];
  FlutterResult resultSet = ^(id result) {
    [enableSystemUIModeCalled fulfill];
  };
  FlutterMethodCall* methodCallSet =
      [FlutterMethodCall methodCallWithMethodName:@"SystemChrome.setSystemUIOverlayStyle"
                                        arguments:@{@"statusBarBrightness" : @"Brightness.dark"}];
  [plugin handleMethodCall:methodCallSet result:resultSet];
  [self waitForExpectationsWithTimeout:1 handler:nil];

  [flutterViewController deregisterNotifications];
  [mockApplication stopMocking];
  [bundleMock stopMocking];
}

@end
