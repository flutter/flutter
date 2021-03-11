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

@end

namespace flutter::testing {

TEST(FlutterTextInputPluginTest, TestEmptyCompositionRange) {
  ASSERT_TRUE([[FlutterInputPluginTestObjc alloc] testEmptyCompositionRange]);
}

}  // namespace flutter::testing
