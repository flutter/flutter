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

@interface FlutterTextInputView ()
- (void)setTextInputState:(NSDictionary*)state;
@end

@implementation FlutterTextInputPluginTest {
  id engine;
  FlutterTextInputPlugin* textInputPlugin;
}

- (void)setUp {
  [super setUp];

  engine = OCMClassMock([FlutterEngine class]);
  textInputPlugin = [[FlutterTextInputPlugin alloc] init];
  textInputPlugin.textInputDelegate = engine;
}

- (void)tearDown {
  [engine stopMocking];
  [[[[textInputPlugin textInputView] superview] subviews]
      makeObjectsPerformSelector:@selector(removeFromSuperview)];
  [super tearDown];
}

- (void)testSecureInput {
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
}

- (void)testTextChangesTriggerUpdateEditingClient {
  FlutterTextInputView* inputView = [[FlutterTextInputView alloc] init];
  inputView.textInputDelegate = engine;

  [inputView.text setString:@"BEFORE"];
  inputView.markedTextRange = nil;
  inputView.selectedTextRange = nil;

  // Text changes trigger update.
  [inputView setTextInputState:@{@"text" : @"AFTER"}];
  OCMVerify([engine updateEditingClient:0 withState:[OCMArg isNotNil]]);

  // Don't send anything if there's nothing new.
  [inputView setTextInputState:@{@"text" : @"AFTER"}];
  OCMReject([engine updateEditingClient:0 withState:[OCMArg any]]);
}

- (void)testSelectionChangeTriggersUpdateEditingClient {
  FlutterTextInputView* inputView = [[FlutterTextInputView alloc] init];
  inputView.textInputDelegate = engine;

  [inputView.text setString:@"SELECTION"];
  inputView.markedTextRange = nil;
  inputView.selectedTextRange = nil;

  [inputView
      setTextInputState:@{@"text" : @"SELECTION", @"selectionBase" : @0, @"selectionExtent" : @3}];
  OCMVerify([engine updateEditingClient:0 withState:[OCMArg isNotNil]]);

  [inputView
      setTextInputState:@{@"text" : @"SELECTION", @"selectionBase" : @1, @"selectionExtent" : @3}];
  OCMVerify([engine updateEditingClient:0 withState:[OCMArg isNotNil]]);

  [inputView
      setTextInputState:@{@"text" : @"SELECTION", @"selectionBase" : @1, @"selectionExtent" : @2}];
  OCMVerify([engine updateEditingClient:0 withState:[OCMArg isNotNil]]);

  // Don't send anything if there's nothing new.
  [inputView
      setTextInputState:@{@"text" : @"SELECTION", @"selectionBase" : @1, @"selectionExtent" : @2}];
  OCMReject([engine updateEditingClient:0 withState:[OCMArg any]]);
}

- (void)testComposingChangeTriggersUpdateEditingClient {
  FlutterTextInputView* inputView = [[FlutterTextInputView alloc] init];
  inputView.textInputDelegate = engine;

  // Reset to test marked text.
  [inputView.text setString:@"COMPOSING"];
  inputView.markedTextRange = nil;
  inputView.selectedTextRange = nil;

  [inputView
      setTextInputState:@{@"text" : @"COMPOSING", @"composingBase" : @0, @"composingExtent" : @3}];
  OCMVerify([engine updateEditingClient:0 withState:[OCMArg isNotNil]]);

  [inputView
      setTextInputState:@{@"text" : @"COMPOSING", @"composingBase" : @1, @"composingExtent" : @3}];
  OCMVerify([engine updateEditingClient:0 withState:[OCMArg isNotNil]]);

  [inputView
      setTextInputState:@{@"text" : @"COMPOSING", @"composingBase" : @1, @"composingExtent" : @2}];
  OCMVerify([engine updateEditingClient:0 withState:[OCMArg isNotNil]]);

  // Don't send anything if there's nothing new.
  [inputView
      setTextInputState:@{@"text" : @"COMPOSING", @"composingBase" : @1, @"composingExtent" : @2}];
  OCMReject([engine updateEditingClient:0 withState:[OCMArg any]]);
}

- (void)testAutofillInputViews {
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
}

- (void)testAutocorrectionPromptRectAppears {
  FlutterTextInputView* inputView = [[FlutterTextInputView alloc] initWithFrame:CGRectZero];
  inputView.textInputDelegate = engine;
  [inputView firstRectForRange:[FlutterTextRange rangeWithNSRange:NSMakeRange(0, 1)]];

  // Verify behavior.
  OCMVerify([engine showAutocorrectionPromptRectForStart:0 end:1 withClient:0]);
}

- (void)testTextRangeFromPositionMatchesUITextViewBehavior {
  FlutterTextInputView* inputView = [[FlutterTextInputView alloc] initWithFrame:CGRectZero];
  FlutterTextPosition* fromPosition = [[FlutterTextPosition alloc] initWithIndex:2];
  FlutterTextPosition* toPosition = [[FlutterTextPosition alloc] initWithIndex:0];

  FlutterTextRange* flutterRange = (FlutterTextRange*)[inputView textRangeFromPosition:fromPosition
                                                                            toPosition:toPosition];
  NSRange range = flutterRange.range;

  XCTAssertEqual(range.location, 0);
  XCTAssertEqual(range.length, 2);
}

- (void)testUITextInputCallsUpdateEditingStateOnce {
  FlutterTextInputView* inputView = [[FlutterTextInputView alloc] init];
  inputView.textInputDelegate = engine;

  __block int updateCount = 0;
  OCMStub([engine updateEditingClient:0 withState:[OCMArg isNotNil]])
      .andDo(^(NSInvocation* invocation) {
        updateCount++;
      });

  [inputView insertText:@"text to insert"];
  // Update the framework exactly once.
  XCTAssertEqual(updateCount, 1);

  [inputView deleteBackward];
  XCTAssertEqual(updateCount, 2);

  inputView.selectedTextRange = [FlutterTextRange rangeWithNSRange:NSMakeRange(0, 1)];
  XCTAssertEqual(updateCount, 3);

  [inputView replaceRange:[FlutterTextRange rangeWithNSRange:NSMakeRange(0, 1)]
                 withText:@"replace text"];
  XCTAssertEqual(updateCount, 4);

  [inputView setMarkedText:@"marked text" selectedRange:NSMakeRange(0, 1)];
  XCTAssertEqual(updateCount, 5);

  [inputView unmarkText];
  XCTAssertEqual(updateCount, 6);
}
@end
