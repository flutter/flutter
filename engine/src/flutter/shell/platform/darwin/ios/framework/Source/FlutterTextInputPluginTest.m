// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <XCTest/XCTest.h>
#include "flutter/shell/platform/darwin/common/framework/Headers/FlutterMacros.h"
#import "flutter/shell/platform/darwin/ios/framework/Headers/FlutterEngine.h"
#include "flutter/shell/platform/darwin/ios/framework/Source/FlutterTextInputPlugin.h"
#import "third_party/ocmock/Source/OCMock/OCMock.h"

FLUTTER_ASSERT_ARC

@interface FlutterTextInputView ()
@property(nonatomic, copy) NSString* autofillId;

- (BOOL)setTextInputState:(NSDictionary*)state;
- (void)updateEditingState;
- (BOOL)isVisibleToAutofill;
@end

@interface FlutterSecureTextInputView : FlutterTextInputView
@property(nonatomic, strong) UITextField* textField;
@end

@interface FlutterTextInputPlugin ()
@property(nonatomic, strong) FlutterTextInputView* reusableInputView;
@property(nonatomic, assign) FlutterTextInputView* activeView;
@property(nonatomic, readonly)
    NSMutableDictionary<NSString*, FlutterTextInputView*>* autofillContext;
@end

@interface FlutterTextInputPluginTest : XCTestCase
@end

@implementation FlutterTextInputPluginTest {
  NSDictionary* _template;
  NSDictionary* _passwordTemplate;
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

- (void)setClientId:(int)clientId configuration:(NSDictionary*)config {
  FlutterMethodCall* setClientCall =
      [FlutterMethodCall methodCallWithMethodName:@"TextInput.setClient"
                                        arguments:@[ [NSNumber numberWithInt:clientId], config ]];
  [textInputPlugin handleMethodCall:setClientCall
                             result:^(id _Nullable result){
                             }];
}

- (NSMutableDictionary*)mutableTemplateCopy {
  if (!_template) {
    _template = @{
      @"inputType" : @{@"name" : @"TextInuptType.text"},
      @"keyboardAppearance" : @"Brightness.light",
      @"obscureText" : @NO,
      @"inputAction" : @"TextInputAction.unspecified",
      @"smartDashesType" : @"0",
      @"smartQuotesType" : @"0",
      @"autocorrect" : @YES
    };
  }

  return [_template mutableCopy];
}

- (NSArray<FlutterTextInputView*>*)installedInputViews {
  UIWindow* keyWindow =
      [[[UIApplication sharedApplication] windows]
          filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"isKeyWindow == YES"]]
          .firstObject;

  return [keyWindow.subviews
      filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self isKindOfClass: %@",
                                                                   [FlutterTextInputView class]]];
}

#pragma mark - Tests

- (void)testSecureInput {
  NSDictionary* config = self.mutableTemplateCopy;
  [config setValue:@"YES" forKey:@"obscureText"];
  [self setClientId:123 configuration:config];

  // Find all the FlutterTextInputViews we created.
  NSArray<FlutterTextInputView*>* inputFields = self.installedInputViews;

  // There are no autofill and the mock framework requested a secure entry. The first and only
  // inserted FlutterTextInputView should be a secure text entry one.
  FlutterTextInputView* inputView = inputFields[0];

  // Verify secureTextEntry is set to the correct value.
  XCTAssertTrue(inputView.secureTextEntry);

  // Verify keyboardType is set to the default value.
  XCTAssertEqual(inputView.keyboardType, UIKeyboardTypeDefault);

  // We should have only ever created one FlutterTextInputView.
  XCTAssertEqual(inputFields.count, 1);

  // The one FlutterTextInputView we inserted into the view hierarchy should be the text input
  // plugin's active text input view.
  XCTAssertEqual(inputView, textInputPlugin.textInputView);

  // Despite not given an id in configuration, inputView has
  // an autofill id.
  XCTAssert(inputView.autofillId.length > 0);
}

- (void)testKeyboardType {
  NSDictionary* config = self.mutableTemplateCopy;
  [config setValue:@{@"name" : @"TextInputType.url"} forKey:@"inputType"];
  [self setClientId:123 configuration:config];

  // Find all the FlutterTextInputViews we created.
  NSArray<FlutterTextInputView*>* inputFields = self.installedInputViews;

  FlutterTextInputView* inputView = inputFields[0];

  // Verify keyboardType is set to the value specified in config.
  XCTAssertEqual(inputView.keyboardType, UIKeyboardTypeURL);
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

- (void)testNoZombies {
  // Regression test for https://github.com/flutter/flutter/issues/62501.
  FlutterSecureTextInputView* passwordView = [[FlutterSecureTextInputView alloc] init];

  @autoreleasepool {
    // Initialize the lazy textField.
    [passwordView.textField description];
  }
  XCTAssert([[passwordView.textField description] containsString:@"TextField"]);
}

#pragma mark - EditingState tests

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

- (void)testTextChangesTriggerUpdateEditingClient {
  FlutterTextInputView* inputView = [[FlutterTextInputView alloc] init];
  inputView.textInputDelegate = engine;

  [inputView.text setString:@"BEFORE"];
  inputView.markedTextRange = nil;
  inputView.selectedTextRange = nil;

  // Text changes trigger update.
  XCTAssertTrue([inputView setTextInputState:@{@"text" : @"AFTER"}]);

  // Don't send anything if there's nothing new.
  XCTAssertFalse([inputView setTextInputState:@{@"text" : @"AFTER"}]);
}

- (void)testSelectionChangeTriggersUpdateEditingClient {
  FlutterTextInputView* inputView = [[FlutterTextInputView alloc] init];
  inputView.textInputDelegate = engine;

  [inputView.text setString:@"SELECTION"];
  inputView.markedTextRange = nil;
  inputView.selectedTextRange = nil;

  BOOL shouldUpdate = [inputView
      setTextInputState:@{@"text" : @"SELECTION", @"selectionBase" : @0, @"selectionExtent" : @3}];
  XCTAssertTrue(shouldUpdate);

  shouldUpdate = [inputView
      setTextInputState:@{@"text" : @"SELECTION", @"selectionBase" : @1, @"selectionExtent" : @3}];
  XCTAssertTrue(shouldUpdate);

  shouldUpdate = [inputView
      setTextInputState:@{@"text" : @"SELECTION", @"selectionBase" : @1, @"selectionExtent" : @2}];
  XCTAssertTrue(shouldUpdate);

  // Don't send anything if there's nothing new.
  shouldUpdate = [inputView
      setTextInputState:@{@"text" : @"SELECTION", @"selectionBase" : @1, @"selectionExtent" : @2}];
  XCTAssertFalse(shouldUpdate);
}

- (void)testComposingChangeTriggersUpdateEditingClient {
  FlutterTextInputView* inputView = [[FlutterTextInputView alloc] init];
  inputView.textInputDelegate = engine;

  // Reset to test marked text.
  [inputView.text setString:@"COMPOSING"];
  inputView.markedTextRange = nil;
  inputView.selectedTextRange = nil;

  BOOL shouldUpdate = [inputView
      setTextInputState:@{@"text" : @"COMPOSING", @"composingBase" : @0, @"composingExtent" : @3}];
  XCTAssertTrue(shouldUpdate);

  shouldUpdate = [inputView
      setTextInputState:@{@"text" : @"COMPOSING", @"composingBase" : @1, @"composingExtent" : @3}];
  XCTAssertTrue(shouldUpdate);

  shouldUpdate = [inputView
      setTextInputState:@{@"text" : @"COMPOSING", @"composingBase" : @1, @"composingExtent" : @2}];
  XCTAssertTrue(shouldUpdate);

  // Don't send anything if there's nothing new.
  shouldUpdate = [inputView
      setTextInputState:@{@"text" : @"COMPOSING", @"composingBase" : @1, @"composingExtent" : @2}];
  XCTAssertFalse(shouldUpdate);
}

- (void)testUpdateEditingClientNegativeSelection {
  FlutterTextInputView* inputView = [[FlutterTextInputView alloc] init];
  inputView.textInputDelegate = engine;

  [inputView.text setString:@"SELECTION"];
  inputView.markedTextRange = nil;
  inputView.selectedTextRange = nil;

  [inputView setTextInputState:@{
    @"text" : @"SELECTION",
    @"selectionBase" : @-1,
    @"selectionExtent" : @-1
  }];
  [inputView updateEditingState];
  OCMVerify([engine updateEditingClient:0
                              withState:[OCMArg checkWithBlock:^BOOL(NSDictionary* state) {
                                return ([state[@"selectionBase"] intValue]) == 0 &&
                                       ([state[@"selectionExtent"] intValue] == 0);
                              }]]);

  // Returns (0, 0) when either end goes below 0.
  [inputView
      setTextInputState:@{@"text" : @"SELECTION", @"selectionBase" : @-1, @"selectionExtent" : @1}];
  [inputView updateEditingState];
  OCMVerify([engine updateEditingClient:0
                              withState:[OCMArg checkWithBlock:^BOOL(NSDictionary* state) {
                                return ([state[@"selectionBase"] intValue]) == 0 &&
                                       ([state[@"selectionExtent"] intValue] == 0);
                              }]]);

  [inputView
      setTextInputState:@{@"text" : @"SELECTION", @"selectionBase" : @1, @"selectionExtent" : @-1}];
  [inputView updateEditingState];
  OCMVerify([engine updateEditingClient:0
                              withState:[OCMArg checkWithBlock:^BOOL(NSDictionary* state) {
                                return ([state[@"selectionBase"] intValue]) == 0 &&
                                       ([state[@"selectionExtent"] intValue] == 0);
                              }]]);
}

- (void)testUpdateEditingClientSelectionClamping {
  // Regression test for https://github.com/flutter/flutter/issues/62992.
  FlutterTextInputView* inputView = [[FlutterTextInputView alloc] init];
  inputView.textInputDelegate = engine;

  [inputView.text setString:@"SELECTION"];
  inputView.markedTextRange = nil;
  inputView.selectedTextRange = nil;

  [inputView
      setTextInputState:@{@"text" : @"SELECTION", @"selectionBase" : @0, @"selectionExtent" : @0}];
  [inputView updateEditingState];
  OCMVerify([engine updateEditingClient:0
                              withState:[OCMArg checkWithBlock:^BOOL(NSDictionary* state) {
                                return ([state[@"selectionBase"] intValue]) == 0 &&
                                       ([state[@"selectionExtent"] intValue] == 0);
                              }]]);

  // Needs clamping.
  [inputView setTextInputState:@{
    @"text" : @"SELECTION",
    @"selectionBase" : @0,
    @"selectionExtent" : @9999
  }];
  [inputView updateEditingState];

  OCMVerify([engine updateEditingClient:0
                              withState:[OCMArg checkWithBlock:^BOOL(NSDictionary* state) {
                                return ([state[@"selectionBase"] intValue]) == 0 &&
                                       ([state[@"selectionExtent"] intValue] == 9);
                              }]]);

  // No clamping needed, but in reverse direction.
  [inputView
      setTextInputState:@{@"text" : @"SELECTION", @"selectionBase" : @1, @"selectionExtent" : @0}];
  [inputView updateEditingState];
  OCMVerify([engine updateEditingClient:0
                              withState:[OCMArg checkWithBlock:^BOOL(NSDictionary* state) {
                                return ([state[@"selectionBase"] intValue]) == 0 &&
                                       ([state[@"selectionExtent"] intValue] == 1);
                              }]]);

  // Both ends need clamping.
  [inputView setTextInputState:@{
    @"text" : @"SELECTION",
    @"selectionBase" : @9999,
    @"selectionExtent" : @9999
  }];
  [inputView updateEditingState];
  OCMVerify([engine updateEditingClient:0
                              withState:[OCMArg checkWithBlock:^BOOL(NSDictionary* state) {
                                return ([state[@"selectionBase"] intValue]) == 9 &&
                                       ([state[@"selectionExtent"] intValue] == 9);
                              }]]);
}

#pragma mark - Autofill - Utilities

- (NSMutableDictionary*)mutablePasswordTemplateCopy {
  if (!_passwordTemplate) {
    _passwordTemplate = @{
      @"inputType" : @{@"name" : @"TextInuptType.text"},
      @"keyboardAppearance" : @"Brightness.light",
      @"obscureText" : @YES,
      @"inputAction" : @"TextInputAction.unspecified",
      @"smartDashesType" : @"0",
      @"smartQuotesType" : @"0",
      @"autocorrect" : @YES
    };
  }

  return [_passwordTemplate mutableCopy];
}

- (NSArray<FlutterTextInputView*>*)viewsVisibleToAutofill {
  return [self.installedInputViews
      filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"isVisibleToAutofill == YES"]];
}

- (void)commitAutofillContextAndVerify {
  FlutterMethodCall* methodCall =
      [FlutterMethodCall methodCallWithMethodName:@"TextInput.finishAutofillContext"
                                        arguments:@YES];
  [textInputPlugin handleMethodCall:methodCall
                             result:^(id _Nullable result){
                             }];

  XCTAssertEqual(self.viewsVisibleToAutofill.count,
                 [textInputPlugin.activeView isVisibleToAutofill] ? 1 : 0);
  XCTAssertNotEqual(textInputPlugin.textInputView, nil);
  // The active view should still be installed so it doesn't get
  // deallocated.
  XCTAssertEqual(self.installedInputViews.count, 1);
  XCTAssertEqual(textInputPlugin.autofillContext.count, 0);
}

#pragma mark - Autofill - Tests

- (void)testAutofillContext {
  NSMutableDictionary* field1 = self.mutableTemplateCopy;

  [field1 setValue:@{
    @"uniqueIdentifier" : @"field1",
    @"hints" : @[ @"hint1" ],
    @"editingValue" : @{@"text" : @""}
  }
            forKey:@"autofill"];

  NSMutableDictionary* field2 = self.mutablePasswordTemplateCopy;
  [field2 setValue:@{
    @"uniqueIdentifier" : @"field2",
    @"hints" : @[ @"hint2" ],
    @"editingValue" : @{@"text" : @""}
  }
            forKey:@"autofill"];

  NSMutableDictionary* config = [field1 mutableCopy];
  [config setValue:@[ field1, field2 ] forKey:@"fields"];

  [self setClientId:123 configuration:config];
  XCTAssertEqual(self.viewsVisibleToAutofill.count, 2);

  XCTAssertEqual(textInputPlugin.autofillContext.count, 2);
  XCTAssertEqual(self.installedInputViews.count, 2);
  XCTAssertEqual(textInputPlugin.textInputView, textInputPlugin.autofillContext[@"field1"]);

  // The configuration changes.
  NSMutableDictionary* field3 = self.mutablePasswordTemplateCopy;
  [field3 setValue:@{
    @"uniqueIdentifier" : @"field3",
    @"hints" : @[ @"hint3" ],
    @"editingValue" : @{@"text" : @""}
  }
            forKey:@"autofill"];

  NSMutableDictionary* oldContext = textInputPlugin.autofillContext;
  // Replace field2 with field3.
  [config setValue:@[ field1, field3 ] forKey:@"fields"];

  [self setClientId:123 configuration:config];

  XCTAssertEqual(self.viewsVisibleToAutofill.count, 2);
  XCTAssertEqual(textInputPlugin.autofillContext.count, 3);
  XCTAssertEqual(self.installedInputViews.count, 3);
  XCTAssertEqual(textInputPlugin.textInputView, textInputPlugin.autofillContext[@"field1"]);

  // Old autofill input fields are still installed and reused.
  for (NSString* key in oldContext.allKeys) {
    XCTAssertEqual(oldContext[key], textInputPlugin.autofillContext[key]);
  }

  // Switch to a password field that has no contentType and is not in an AutofillGroup.
  config = self.mutablePasswordTemplateCopy;

  oldContext = textInputPlugin.autofillContext;
  [self setClientId:124 configuration:config];

  XCTAssertEqual(self.viewsVisibleToAutofill.count, 1);
  XCTAssertEqual(textInputPlugin.autofillContext.count, 3);
  XCTAssertEqual(self.installedInputViews.count, 4);

  // Old autofill input fields are still installed and reused.
  for (NSString* key in oldContext.allKeys) {
    XCTAssertEqual(oldContext[key], textInputPlugin.autofillContext[key]);
  }
  // The active view should change.
  XCTAssertNotEqual(textInputPlugin.textInputView, textInputPlugin.autofillContext[@"field1"]);

  // Switch to a similar password field, the previous field should be reused.
  oldContext = textInputPlugin.autofillContext;
  [self setClientId:200 configuration:config];

  // Reuse the input view instance from the last time.
  XCTAssertEqual(self.viewsVisibleToAutofill.count, 1);
  XCTAssertEqual(textInputPlugin.autofillContext.count, 3);
  XCTAssertEqual(self.installedInputViews.count, 4);

  // Old autofill input fields are still installed and reused.
  for (NSString* key in oldContext.allKeys) {
    XCTAssertEqual(oldContext[key], textInputPlugin.autofillContext[key]);
  }
  XCTAssertNotEqual(textInputPlugin.textInputView, textInputPlugin.autofillContext[@"field1"]);
}

- (void)testCommitAutofillContext {
  NSMutableDictionary* field1 = self.mutableTemplateCopy;
  [field1 setValue:@{
    @"uniqueIdentifier" : @"field1",
    @"hints" : @[ @"hint1" ],
    @"editingValue" : @{@"text" : @""}
  }
            forKey:@"autofill"];

  NSMutableDictionary* field2 = self.mutablePasswordTemplateCopy;
  [field2 setValue:@{
    @"uniqueIdentifier" : @"field2",
    @"hints" : @[ @"hint2" ],
    @"editingValue" : @{@"text" : @""}
  }
            forKey:@"autofill"];

  NSMutableDictionary* field3 = self.mutableTemplateCopy;
  [field3 setValue:@{
    @"uniqueIdentifier" : @"field3",
    @"hints" : @[ @"hint3" ],
    @"editingValue" : @{@"text" : @""}
  }
            forKey:@"autofill"];

  NSMutableDictionary* config = [field1 mutableCopy];
  [config setValue:@[ field1, field2 ] forKey:@"fields"];

  [self setClientId:123 configuration:config];
  XCTAssertEqual(self.viewsVisibleToAutofill.count, 2);
  XCTAssertEqual(textInputPlugin.autofillContext.count, 2);

  [self commitAutofillContextAndVerify];
  XCTAssertNotEqual(textInputPlugin.textInputView, textInputPlugin.reusableInputView);

  // Install the password field again.
  [self setClientId:123 configuration:config];
  // Switch to a regular autofill group.
  [self setClientId:124 configuration:field3];
  XCTAssertEqual(self.viewsVisibleToAutofill.count, 1);
  XCTAssertEqual(self.installedInputViews.count, 3);
  XCTAssertEqual(textInputPlugin.autofillContext.count, 2);
  XCTAssertNotEqual(textInputPlugin.textInputView, nil);

  [self commitAutofillContextAndVerify];
  XCTAssertNotEqual(textInputPlugin.textInputView, textInputPlugin.reusableInputView);

  // Now switch to an input field that does not autofill.
  [self setClientId:125 configuration:self.mutableTemplateCopy];

  XCTAssertEqual(self.viewsVisibleToAutofill.count, 0);
  XCTAssertEqual(textInputPlugin.textInputView, textInputPlugin.reusableInputView);
  // The active view should still be installed so it doesn't get
  // deallocated.
  XCTAssertEqual(self.installedInputViews.count, 1);
  XCTAssertEqual(textInputPlugin.autofillContext.count, 0);

  [self commitAutofillContextAndVerify];
  XCTAssertEqual(textInputPlugin.textInputView, textInputPlugin.reusableInputView);
}

- (void)testAutofillInputViews {
  NSMutableDictionary* field1 = self.mutableTemplateCopy;
  [field1 setValue:@{
    @"uniqueIdentifier" : @"field1",
    @"hints" : @[ @"hint1" ],
    @"editingValue" : @{@"text" : @""}
  }
            forKey:@"autofill"];

  NSMutableDictionary* field2 = self.mutablePasswordTemplateCopy;
  [field2 setValue:@{
    @"uniqueIdentifier" : @"field2",
    @"hints" : @[ @"hint2" ],
    @"editingValue" : @{@"text" : @""}
  }
            forKey:@"autofill"];

  NSMutableDictionary* config = [field1 mutableCopy];
  [config setValue:@[ field1, field2 ] forKey:@"fields"];

  [self setClientId:123 configuration:config];

  // Find all the FlutterTextInputViews we created.
  NSArray<FlutterTextInputView*>* inputFields = self.installedInputViews;

  // Both fields are installed and visible because it's a password group.
  XCTAssertEqual(inputFields.count, 2);
  XCTAssertEqual(self.viewsVisibleToAutofill.count, 2);

  // Find the inactive autofillable input field.
  FlutterTextInputView* inactiveView = inputFields[1];
  [inactiveView replaceRange:[FlutterTextRange rangeWithNSRange:NSMakeRange(0, 0)]
                    withText:@"Autofilled!"];

  // Verify behavior.
  OCMVerify([engine updateEditingClient:0 withState:[OCMArg isNotNil] withTag:@"field2"]);
}

- (void)testPasswordAutofillHack {
  NSDictionary* config = self.mutableTemplateCopy;
  [config setValue:@"YES" forKey:@"obscureText"];
  [self setClientId:123 configuration:config];

  // Find all the FlutterTextInputViews we created.
  NSArray<FlutterTextInputView*>* inputFields = self.installedInputViews;

  FlutterTextInputView* inputView = inputFields[0];

  XCTAssert([inputView isKindOfClass:[UITextField class]]);
  // FlutterSecureTextInputView does not respond to font,
  // but it should return the default UITextField.font.
  XCTAssertNotEqual([inputView performSelector:@selector(font)], nil);
}

@end
