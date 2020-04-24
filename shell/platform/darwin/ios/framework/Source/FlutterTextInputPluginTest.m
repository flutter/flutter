// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <XCTest/XCTest.h>
#include "flutter/shell/platform/darwin/common/framework/Headers/FlutterMacros.h"
#import "flutter/shell/platform/darwin/ios/framework/Headers/FlutterEngine.h"
#include "flutter/shell/platform/darwin/ios/framework/Source/FlutterTextInputPlugin.h"
#import "third_party/ocmock/Source/OCMock/OCMock.h"

FLUTTER_ASSERT_ARC

@interface FlutterTextInputPluginTest : XCTestCase
@end

@implementation FlutterTextInputPluginTest
- (void)testSecureInput {
  // Setup test.
  id engine = OCMClassMock([FlutterEngine class]);
  FlutterTextInputPlugin* textInputPlugin = [[FlutterTextInputPlugin alloc] init];
  textInputPlugin.textInputDelegate = engine;

  NSDictionary* config = @{
    @"inputType" : @{@"name" : @"TextInuptType.text"},
    @"keyboardAppearance" : @"Brightness.light",
    @"obscureText" : @YES,
    @"inputAction" : @"TextInputAction.unspecified",
    @"smartDashesType" : @"0",
    @"smartQuotesType" : @"0",
    @"autocorrect" : @YES
  };

  FlutterMethodCall* setClientCall =
      [FlutterMethodCall methodCallWithMethodName:@"TextInput.setClient"
                                        arguments:@[ @123, config ]];

  [textInputPlugin handleMethodCall:setClientCall
                             result:^(id _Nullable result){
                             }];

  // Find all the FlutterTextInputViews we created.
  NSArray<FlutterTextInputView*>* inputFields = [[[[textInputPlugin textInputView] superview]
      subviews]
      filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"class == %@",
                                                                   [FlutterTextInputView class]]];

  // There are no autofill and the mock framework requested a secure entry. The first and only
  // inserted FlutterTextInputView should be a secure text entry one.
  FlutterTextInputView* inputView = inputFields[0];

  // Verify secureTextEntry is set to the correct value.
  XCTAssertTrue(inputView.secureTextEntry);

  // We should have only ever created one FlutterTextInputView.
  XCTAssertEqual(inputFields.count, 1);

  // The one FlutterTextInputView we inserted into the view hierarchy should be the text input
  // plugin's active text input view.
  XCTAssertEqual(inputView, textInputPlugin.textInputView);

  // Clean up.
  [engine stopMocking];
  [[[[textInputPlugin textInputView] superview] subviews]
      makeObjectsPerformSelector:@selector(removeFromSuperview)];
}
- (void)testAutofillInputViews {
  // Setup test.
  id engine = OCMClassMock([FlutterEngine class]);
  FlutterTextInputPlugin* textInputPlugin = [[FlutterTextInputPlugin alloc] init];
  textInputPlugin.textInputDelegate = engine;

  NSDictionary* template = @{
    @"inputType" : @{@"name" : @"TextInuptType.text"},
    @"keyboardAppearance" : @"Brightness.light",
    @"obscureText" : @NO,
    @"inputAction" : @"TextInputAction.unspecified",
    @"smartDashesType" : @"0",
    @"smartQuotesType" : @"0",
    @"autocorrect" : @YES
  };

  NSMutableDictionary* field1 = [template mutableCopy];
  [field1 setValue:@{
    @"uniqueIdentifier" : @"field1",
    @"hints" : @[ @"hint1" ],
    @"editingValue" : @{@"text" : @""}
  }
            forKey:@"autofill"];

  NSMutableDictionary* field2 = [template mutableCopy];
  [field2 setValue:@{
    @"uniqueIdentifier" : @"field2",
    @"hints" : @[ @"hint2" ],
    @"editingValue" : @{@"text" : @""}
  }
            forKey:@"autofill"];

  NSMutableDictionary* config = [field1 mutableCopy];
  [config setValue:@[ field1, field2 ] forKey:@"fields"];

  FlutterMethodCall* setClientCall =
      [FlutterMethodCall methodCallWithMethodName:@"TextInput.setClient"
                                        arguments:@[ @123, config ]];

  [textInputPlugin handleMethodCall:setClientCall
                             result:^(id _Nullable result){
                             }];

  // Find all the FlutterTextInputViews we created.
  NSArray<FlutterTextInputView*>* inputFields = [[[[textInputPlugin textInputView] superview]
      subviews]
      filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"class == %@",
                                                                   [FlutterTextInputView class]]];

  XCTAssertEqual(inputFields.count, 2);

  // Find the inactive autofillable input field.
  FlutterTextInputView* inactiveView = inputFields[1];
  [inactiveView replaceRange:[FlutterTextRange rangeWithNSRange:NSMakeRange(0, 0)]
                    withText:@"Autofilled!"];

  // Verify behavior.
  OCMVerify([engine updateEditingClient:0 withState:[OCMArg isNotNil] withTag:@"field2"]);

  // Clean up.
  [engine stopMocking];
  [[[[textInputPlugin textInputView] superview] subviews]
      makeObjectsPerformSelector:@selector(removeFromSuperview)];
}

- (void)testAutocorrectionPromptRectAppears {
  // Setup test.
  id engine = OCMClassMock([FlutterEngine class]);

  FlutterTextInputView* inputView = [[FlutterTextInputView alloc] initWithFrame:CGRectZero];
  inputView.textInputDelegate = engine;
  [inputView firstRectForRange:[FlutterTextRange rangeWithNSRange:NSMakeRange(0, 1)]];

  // Verify behavior.
  OCMVerify([engine showAutocorrectionPromptRectForStart:0 end:1 withClient:0]);

  // Clean up mocks
  [engine stopMocking];
}
@end
