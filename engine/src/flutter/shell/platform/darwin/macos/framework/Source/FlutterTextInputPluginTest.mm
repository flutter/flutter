// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/macos/framework/Headers/FlutterViewController.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterDartProject_Internal.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterEngine_Internal.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterTextInputPlugin.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterTextInputSemanticsObject.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterViewController_Internal.h"

#import <OCMock/OCMock.h>
#import "flutter/testing/testing.h"

@interface FlutterTextFieldMock : FlutterTextField

@property(nonatomic) NSString* lastUpdatedString;
@property(nonatomic) NSRange lastUpdatedSelection;

@end

@implementation FlutterTextFieldMock

- (void)updateString:(NSString*)string withSelection:(NSRange)selection {
  _lastUpdatedString = string;
  _lastUpdatedSelection = selection;
}

@end

@interface FlutterInputPluginTestObjc : NSObject
- (bool)testEmptyCompositionRange;
@end

@implementation FlutterInputPluginTestObjc

- (bool)testEmptyCompositionRange {
  id engineMock = OCMClassMock([FlutterEngine class]);
  id binaryMessengerMock = OCMProtocolMock(@protocol(FlutterBinaryMessenger));
  OCMStub(  // NOLINT(google-objc-avoid-throwing-exception)
      [engineMock binaryMessenger])
      .andReturn(binaryMessengerMock);

  FlutterViewController* viewController = [[FlutterViewController alloc] initWithEngine:engineMock
                                                                                nibName:@""
                                                                                 bundle:nil];

  FlutterTextInputPlugin* plugin =
      [[FlutterTextInputPlugin alloc] initWithViewController:viewController];

  [plugin handleMethodCall:[FlutterMethodCall
                               methodCallWithMethodName:@"TextInput.setClient"
                                              arguments:@[
                                                @(1), @{
                                                  @"inputAction" : @"action",
                                                  @"inputType" : @{@"name" : @"inputName"},
                                                }
                                              ]]
                    result:^(id){
                    }];

  FlutterMethodCall* call = [FlutterMethodCall methodCallWithMethodName:@"TextInput.setEditingState"
                                                              arguments:@{
                                                                @"text" : @"Text",
                                                                @"selectionBase" : @(0),
                                                                @"selectionExtent" : @(0),
                                                                @"composingBase" : @(-1),
                                                                @"composingExtent" : @(-1),
                                                              }];

  NSDictionary* expectedState = @{
    @"selectionBase" : @(0),
    @"selectionExtent" : @(0),
    @"selectionAffinity" : @"TextAffinity.upstream",
    @"selectionIsDirectional" : @(NO),
    @"composingBase" : @(-1),
    @"composingExtent" : @(-1),
    @"text" : @"Text",
  };

  NSData* updateCall = [[FlutterJSONMethodCodec sharedInstance]
      encodeMethodCall:[FlutterMethodCall
                           methodCallWithMethodName:@"TextInputClient.updateEditingState"
                                          arguments:@[ @(1), expectedState ]]];

  OCMExpect(  // NOLINT(google-objc-avoid-throwing-exception)
      [binaryMessengerMock sendOnChannel:@"flutter/textinput" message:updateCall]);

  [plugin handleMethodCall:call
                    result:^(id){
                    }];

  @try {
    OCMVerify(  // NOLINT(google-objc-avoid-throwing-exception)
        [binaryMessengerMock sendOnChannel:@"flutter/textinput" message:updateCall]);
  } @catch (...) {
    return false;
  }
  return true;
}

- (bool)testFirstRectForCharacterRange {
  id engineMock = OCMClassMock([FlutterEngine class]);
  id binaryMessengerMock = OCMProtocolMock(@protocol(FlutterBinaryMessenger));
  OCMStub(  // NOLINT(google-objc-avoid-throwing-exception)
      [engineMock binaryMessenger])
      .andReturn(binaryMessengerMock);
  FlutterViewController* controllerMock = OCMClassMock([FlutterViewController class]);
  OCMStub(  // NOLINT(google-objc-avoid-throwing-exception)
      [controllerMock engine])
      .andReturn(engineMock);

  id viewMock = OCMClassMock([NSView class]);
  OCMStub(  // NOLINT(google-objc-avoid-throwing-exception)
      [viewMock bounds])
      .andReturn(NSMakeRect(0, 0, 200, 200));
  OCMStub(  // NOLINT(google-objc-avoid-throwing-exception)
      controllerMock.viewLoaded)
      .andReturn(YES);
  OCMStub(  // NOLINT(google-objc-avoid-throwing-exception)
      [controllerMock flutterView])
      .andReturn(viewMock);

  id windowMock = OCMClassMock([NSWindow class]);
  OCMStub(  // NOLINT(google-objc-avoid-throwing-exception)
      [viewMock window])
      .andReturn(windowMock);

  OCMExpect(  // NOLINT(google-objc-avoid-throwing-exception)
      [viewMock convertRect:NSMakeRect(28, 10, 2, 19) toView:nil])
      .andReturn(NSMakeRect(28, 10, 2, 19));

  OCMExpect(  // NOLINT(google-objc-avoid-throwing-exception)
      [windowMock convertRectToScreen:NSMakeRect(28, 10, 2, 19)])
      .andReturn(NSMakeRect(38, 20, 2, 19));

  FlutterTextInputPlugin* plugin =
      [[FlutterTextInputPlugin alloc] initWithViewController:controllerMock];

  FlutterMethodCall* call = [FlutterMethodCall
      methodCallWithMethodName:@"TextInput.setEditableSizeAndTransform"
                     arguments:@{
                       @"height" : @(20.0),
                       @"transform" : @[
                         @(1.0), @(0.0), @(0.0), @(0.0), @(0.0), @(1.0), @(0.0), @(0.0), @(0.0),
                         @(0.0), @(1.0), @(0.0), @(20.0), @(10.0), @(0.0), @(1.0)
                       ],
                       @"width" : @(400.0),
                     }];

  [plugin handleMethodCall:call
                    result:^(id){
                    }];

  call = [FlutterMethodCall methodCallWithMethodName:@"TextInput.setCaretRect"
                                           arguments:@{
                                             @"height" : @(19.0),
                                             @"width" : @(2.0),
                                             @"x" : @(8.0),
                                             @"y" : @(0.0),
                                           }];

  [plugin handleMethodCall:call
                    result:^(id){
                    }];

  NSRect rect = [plugin firstRectForCharacterRange:NSMakeRange(0, 0) actualRange:nullptr];

  @try {
    OCMVerify(  // NOLINT(google-objc-avoid-throwing-exception)
        [windowMock convertRectToScreen:NSMakeRect(28, 10, 2, 19)]);
  } @catch (...) {
    return false;
  }

  return NSEqualRects(rect, NSMakeRect(38, 20, 2, 19));
}

@end

namespace flutter::testing {

namespace {
// Allocates and returns an engine configured for the text fixture resource configuration.
FlutterEngine* CreateTestEngine() {
  NSString* fixtures = @(testing::GetFixturesPath());
  FlutterDartProject* project = [[FlutterDartProject alloc]
      initWithAssetsPath:fixtures
             ICUDataPath:[fixtures stringByAppendingString:@"/icudtl.dat"]];
  return [[FlutterEngine alloc] initWithName:@"test" project:project allowHeadlessExecution:true];
}
}  // namespace

TEST(FlutterTextInputPluginTest, TestEmptyCompositionRange) {
  ASSERT_TRUE([[FlutterInputPluginTestObjc alloc] testEmptyCompositionRange]);
}

TEST(FlutterTextInputPluginTest, TestFirstRectForCharacterRange) {
  ASSERT_TRUE([[FlutterInputPluginTestObjc alloc] testFirstRectForCharacterRange]);
}

TEST(FlutterTextInputPluginTest, CanWorkWithFlutterTextField) {
  FlutterEngine* engine = CreateTestEngine();
  NSString* fixtures = @(testing::GetFixturesPath());
  FlutterDartProject* project = [[FlutterDartProject alloc]
      initWithAssetsPath:fixtures
             ICUDataPath:[fixtures stringByAppendingString:@"/icudtl.dat"]];
  FlutterViewController* viewController = [[FlutterViewController alloc] initWithProject:project];
  [viewController loadView];
  [engine setViewController:viewController];
  // Create a NSWindow so that the native text field can become first responder.
  NSWindow* window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 800, 600)
                                                 styleMask:NSBorderlessWindowMask
                                                   backing:NSBackingStoreBuffered
                                                     defer:NO];
  window.contentView = viewController.view;

  engine.semanticsEnabled = YES;

  auto bridge = engine.accessibilityBridge.lock();
  FlutterPlatformNodeDelegateMac delegate(engine, viewController);
  ui::AXTree tree;
  ui::AXNode ax_node(&tree, nullptr, 0, 0);
  ui::AXNodeData node_data;
  node_data.SetValue("initial text");
  ax_node.SetData(node_data);
  delegate.Init(engine.accessibilityBridge, &ax_node);
  FlutterTextPlatformNode text_platform_node(&delegate, viewController);

  FlutterTextFieldMock* mockTextField =
      [[FlutterTextFieldMock alloc] initWithPlatformNode:&text_platform_node
                                             fieldEditor:viewController.textInputPlugin];
  [viewController.view addSubview:mockTextField];
  [mockTextField becomeFirstResponder];

  NSDictionary* arguments = @{
    @"inputAction" : @"action",
    @"inputType" : @{@"name" : @"inputName"},
  };
  FlutterMethodCall* methodCall = [FlutterMethodCall methodCallWithMethodName:@"TextInput.setClient"
                                                                    arguments:@[ @(1), arguments ]];
  FlutterResult result = ^(id result) {
  };
  [viewController.textInputPlugin handleMethodCall:methodCall result:result];

  arguments = @{
    @"text" : @"new text",
    @"selectionBase" : @(1),
    @"selectionExtent" : @(2),
    @"composingBase" : @(-1),
    @"composingExtent" : @(-1),
  };

  methodCall = [FlutterMethodCall methodCallWithMethodName:@"TextInput.setEditingState"
                                                 arguments:arguments];
  [viewController.textInputPlugin handleMethodCall:methodCall result:result];
  EXPECT_EQ([mockTextField.lastUpdatedString isEqualToString:@"new text"], YES);
  EXPECT_EQ(NSEqualRanges(mockTextField.lastUpdatedSelection, NSMakeRange(1, 1)), YES);
}

TEST(FlutterTextInputPluginTest, CanNotBecomeResponderIfNoViewController) {
  FlutterEngine* engine = CreateTestEngine();
  NSString* fixtures = @(testing::GetFixturesPath());
  FlutterDartProject* project = [[FlutterDartProject alloc]
      initWithAssetsPath:fixtures
             ICUDataPath:[fixtures stringByAppendingString:@"/icudtl.dat"]];
  FlutterViewController* viewController = [[FlutterViewController alloc] initWithProject:project];
  [viewController loadView];
  [engine setViewController:viewController];
  // Creates a NSWindow so that the native text field can become first responder.
  NSWindow* window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 800, 600)
                                                 styleMask:NSBorderlessWindowMask
                                                   backing:NSBackingStoreBuffered
                                                     defer:NO];
  window.contentView = viewController.view;

  engine.semanticsEnabled = YES;

  auto bridge = engine.accessibilityBridge.lock();
  FlutterPlatformNodeDelegateMac delegate(engine, viewController);
  ui::AXTree tree;
  ui::AXNode ax_node(&tree, nullptr, 0, 0);
  ui::AXNodeData node_data;
  node_data.SetValue("initial text");
  ax_node.SetData(node_data);
  delegate.Init(engine.accessibilityBridge, &ax_node);
  FlutterTextPlatformNode text_platform_node(&delegate, viewController);

  FlutterTextField* textField = text_platform_node.GetNativeViewAccessible();
  EXPECT_EQ([textField becomeFirstResponder], YES);
  // Removes view controller.
  [engine setViewController:nil];
  FlutterTextPlatformNode text_platform_node_no_controller(&delegate, nil);
  textField = text_platform_node_no_controller.GetNativeViewAccessible();
  EXPECT_EQ([textField becomeFirstResponder], NO);
}

}  // namespace flutter::testing
