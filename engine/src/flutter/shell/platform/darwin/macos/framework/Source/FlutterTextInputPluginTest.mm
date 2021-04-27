// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/macos/framework/Headers/FlutterViewController.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterDartProject_Internal.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterTextInputPlugin.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterViewController_Internal.h"

#import <OCMock/OCMock.h>
#import "flutter/testing/testing.h"

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
  id controllerMock = OCMClassMock([FlutterViewController class]);
  OCMStub(  // NOLINT(google-objc-avoid-throwing-exception)
      [controllerMock engine])
      .andReturn(engineMock);

  id viewMock = OCMClassMock([NSView class]);
  OCMStub(  // NOLINT(google-objc-avoid-throwing-exception)
      [viewMock bounds])
      .andReturn(NSMakeRect(0, 0, 200, 200));
  OCMStub(  // NOLINT(google-objc-avoid-throwing-exception)
      [controllerMock view])
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

TEST(FlutterTextInputPluginTest, TestEmptyCompositionRange) {
  ASSERT_TRUE([[FlutterInputPluginTestObjc alloc] testEmptyCompositionRange]);
}

TEST(FlutterTextInputPluginTest, TestFirstRectForCharacterRange) {
  ASSERT_TRUE([[FlutterInputPluginTestObjc alloc] testFirstRectForCharacterRange]);
}

}  // namespace flutter::testing
