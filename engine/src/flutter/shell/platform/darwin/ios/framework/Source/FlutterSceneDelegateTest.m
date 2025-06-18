// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "flutter/shell/platform/darwin/ios/framework/Headers/FlutterAppDelegate.h"
#import "flutter/shell/platform/darwin/ios/framework/Headers/FlutterPluginAppLifeCycleDelegate.h"
#import "flutter/shell/platform/darwin/ios/framework/Headers/FlutterSceneDelegate.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterAppDelegate_Internal.h"

@interface FlutterSceneDelegateTest : XCTestCase
@end

@implementation FlutterSceneDelegateTest

- (void)setUp {
}

- (void)tearDown {
}

- (void)testBridgeShortcut {
  id mockApplication = OCMClassMock([UIApplication class]);
  OCMStub([mockApplication sharedApplication]).andReturn(mockApplication);
  id mockAppDelegate = OCMClassMock([FlutterAppDelegate class]);
  id mockLifecycleDelegate = OCMClassMock([FlutterPluginAppLifeCycleDelegate class]);
  OCMStub([mockApplication delegate]).andReturn(mockAppDelegate);
  OCMStub([mockAppDelegate lifeCycleDelegate]).andReturn(mockLifecycleDelegate);
  id windowScene = OCMClassMock([UIWindowScene class]);
  id shortcut = OCMClassMock([UIApplicationShortcutItem class]);

  FlutterSceneDelegate* sceneDelegate = [[FlutterSceneDelegate alloc] init];
  [sceneDelegate windowScene:windowScene
      performActionForShortcutItem:shortcut
                 completionHandler:^(BOOL succeeded){
                 }];

  OCMVerify([(FlutterPluginAppLifeCycleDelegate*)mockLifecycleDelegate application:[OCMArg any]
                                                      performActionForShortcutItem:[OCMArg any]
                                                                 completionHandler:[OCMArg any]]);
}

- (void)testOpenURL {
  id mockApplication = OCMClassMock([UIApplication class]);
  OCMStub([mockApplication sharedApplication]).andReturn(mockApplication);
  id mockAppDelegate = OCMClassMock([FlutterAppDelegate class]);
  id mockLifecycleDelegate = OCMClassMock([FlutterPluginAppLifeCycleDelegate class]);
  OCMStub([mockApplication delegate]).andReturn(mockAppDelegate);
  OCMStub([mockAppDelegate lifeCycleDelegate]).andReturn(mockLifecycleDelegate);
  id windowScene = OCMClassMock([UIWindowScene class]);
  id urlContext = OCMClassMock([UIOpenURLContext class]);
  NSURL* url = [NSURL URLWithString:@"http://example.com"];
  OCMStub([urlContext URL]).andReturn(url);

  FlutterSceneDelegate* sceneDelegate = [[FlutterSceneDelegate alloc] init];
  [sceneDelegate scene:windowScene openURLContexts:[NSSet setWithArray:@[ urlContext ]]];

  OCMVerify([(FlutterPluginAppLifeCycleDelegate*)mockLifecycleDelegate application:[OCMArg any]
                                                                           openURL:url
                                                                           options:[OCMArg any]]);
}

@end
