// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterTextInputPlugin.h"

#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "flutter/shell/platform/darwin/common/framework/Headers/FlutterMacros.h"
#import "flutter/shell/platform/darwin/ios/framework/Headers/FlutterEngine.h"

FLUTTER_ASSERT_ARC

@interface FlutterTextInputView ()
@property(nonatomic, copy) NSString* autofillId;

- (void)setEditableTransform:(NSArray*)matrix;
- (void)setTextInputState:(NSDictionary*)state;
- (void)setMarkedRect:(CGRect)markedRect;
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

- (void)collectGarbageInputViews;
- (UIView*)textInputParentView;
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
  return [textInputPlugin.textInputParentView.subviews
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

- (void)ensureOnlyActiveViewCanBecomeFirstResponder {
  for (FlutterTextInputView* inputView in self.installedInputViews) {
    XCTAssertEqual(inputView.canBecomeFirstResponder, inputView == textInputPlugin.activeView);
  }
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

- (void)testTextChangesDoNotTriggerUpdateEditingClient {
  FlutterTextInputView* inputView = [[FlutterTextInputView alloc] init];
  inputView.textInputDelegate = engine;

  __block int updateCount = 0;
  OCMStub([engine updateEditingClient:0 withState:[OCMArg isNotNil]])
      .andDo(^(NSInvocation* invocation) {
        updateCount++;
      });

  [inputView.text setString:@"BEFORE"];
  XCTAssertEqual(updateCount, 0);

  inputView.markedTextRange = nil;
  inputView.selectedTextRange = nil;
  XCTAssertEqual(updateCount, 1);

  // Text changes don't trigger an update.
  XCTAssertEqual(updateCount, 1);
  [inputView setTextInputState:@{@"text" : @"AFTER"}];
  XCTAssertEqual(updateCount, 1);
  [inputView setTextInputState:@{@"text" : @"AFTER"}];
  XCTAssertEqual(updateCount, 1);

  // Selection changes don't trigger an update.
  [inputView
      setTextInputState:@{@"text" : @"SELECTION", @"selectionBase" : @0, @"selectionExtent" : @3}];
  XCTAssertEqual(updateCount, 1);
  [inputView
      setTextInputState:@{@"text" : @"SELECTION", @"selectionBase" : @1, @"selectionExtent" : @3}];
  XCTAssertEqual(updateCount, 1);

  // Composing region changes don't trigger an update.
  [inputView
      setTextInputState:@{@"text" : @"COMPOSING", @"composingBase" : @1, @"composingExtent" : @2}];
  XCTAssertEqual(updateCount, 1);
  [inputView
      setTextInputState:@{@"text" : @"COMPOSING", @"composingBase" : @1, @"composingExtent" : @3}];
  XCTAssertEqual(updateCount, 1);
}

- (void)testUITextInputAvoidUnnecessaryUndateEditingClientCalls {
  FlutterTextInputView* inputView = [[FlutterTextInputView alloc] init];
  inputView.textInputDelegate = engine;

  __block int updateCount = 0;
  OCMStub([engine updateEditingClient:0 withState:[OCMArg isNotNil]])
      .andDo(^(NSInvocation* invocation) {
        updateCount++;
      });

  [inputView unmarkText];
  // updateEditingClient shouldn't fire as the text is already unmarked.
  XCTAssertEqual(updateCount, 0);

  [inputView setMarkedText:@"marked text" selectedRange:NSMakeRange(0, 1)];
  // updateEditingClient fires in response to setMarkedText.
  XCTAssertEqual(updateCount, 1);

  [inputView unmarkText];
  // updateEditingClient fires in response to unmarkText.
  XCTAssertEqual(updateCount, 2);
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

#pragma mark - UITextInput methods - Tests

- (void)testUpdateFirstRectForRange {
  FlutterTextInputView* inputView = [[FlutterTextInputView alloc] init];
  [inputView
      setTextInputState:@{@"text" : @"COMPOSING", @"composingBase" : @1, @"composingExtent" : @3}];

  CGRect kInvalidFirstRect = CGRectMake(-1, -1, 9999, 9999);
  FlutterTextRange* range = [FlutterTextRange rangeWithNSRange:NSMakeRange(0, 1)];
  // yOffset = 200.
  NSArray* yOffsetMatrix = @[ @1, @0, @0, @0, @0, @1, @0, @0, @0, @0, @1, @0, @0, @200, @0, @1 ];
  NSArray* zeroMatrix = @[ @0, @0, @0, @0, @0, @0, @0, @0, @0, @0, @0, @0, @0, @0, @0, @0 ];

  // Invalid since we don't have the transform or the rect.
  XCTAssertTrue(CGRectEqualToRect(kInvalidFirstRect, [inputView firstRectForRange:range]));

  [inputView setEditableTransform:yOffsetMatrix];
  // Invalid since we don't have the rect.
  XCTAssertTrue(CGRectEqualToRect(kInvalidFirstRect, [inputView firstRectForRange:range]));

  // Valid rect and transform.
  CGRect testRect = CGRectMake(0, 0, 100, 100);
  [inputView setMarkedRect:testRect];

  CGRect finalRect = CGRectOffset(testRect, 0, 200);
  XCTAssertTrue(CGRectEqualToRect(finalRect, [inputView firstRectForRange:range]));
  // Idempotent.
  XCTAssertTrue(CGRectEqualToRect(finalRect, [inputView firstRectForRange:range]));

  // Use an invalid matrix:
  [inputView setEditableTransform:zeroMatrix];
  // Invalid matrix is invalid.
  XCTAssertTrue(CGRectEqualToRect(kInvalidFirstRect, [inputView firstRectForRange:range]));
  XCTAssertTrue(CGRectEqualToRect(kInvalidFirstRect, [inputView firstRectForRange:range]));

  // Revert the invalid matrix change.
  [inputView setEditableTransform:yOffsetMatrix];
  [inputView setMarkedRect:testRect];
  XCTAssertTrue(CGRectEqualToRect(finalRect, [inputView firstRectForRange:range]));

  // Use an invalid rect:
  [inputView setMarkedRect:kInvalidFirstRect];
  // Invalid marked rect is invalid.
  XCTAssertTrue(CGRectEqualToRect(kInvalidFirstRect, [inputView firstRectForRange:range]));
  XCTAssertTrue(CGRectEqualToRect(kInvalidFirstRect, [inputView firstRectForRange:range]));
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

  [textInputPlugin collectGarbageInputViews];
  XCTAssertEqual(self.installedInputViews.count, 2);
  XCTAssertEqual(textInputPlugin.textInputView, textInputPlugin.autofillContext[@"field1"]);
  [self ensureOnlyActiveViewCanBecomeFirstResponder];

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

  [textInputPlugin collectGarbageInputViews];
  XCTAssertEqual(self.installedInputViews.count, 3);
  XCTAssertEqual(textInputPlugin.textInputView, textInputPlugin.autofillContext[@"field1"]);
  [self ensureOnlyActiveViewCanBecomeFirstResponder];

  // Old autofill input fields are still installed and reused.
  for (NSString* key in oldContext.allKeys) {
    XCTAssertEqual(oldContext[key], textInputPlugin.autofillContext[key]);
  }

  // Switch to a password field that has no contentType and is not in an AutofillGroup.
  config = self.mutablePasswordTemplateCopy;

  oldContext = textInputPlugin.autofillContext;
  [self setClientId:124 configuration:config];
  [self ensureOnlyActiveViewCanBecomeFirstResponder];

  XCTAssertEqual(self.viewsVisibleToAutofill.count, 1);
  XCTAssertEqual(textInputPlugin.autofillContext.count, 3);

  [textInputPlugin collectGarbageInputViews];
  XCTAssertEqual(self.installedInputViews.count, 4);

  // Old autofill input fields are still installed and reused.
  for (NSString* key in oldContext.allKeys) {
    XCTAssertEqual(oldContext[key], textInputPlugin.autofillContext[key]);
  }
  // The active view should change.
  XCTAssertNotEqual(textInputPlugin.textInputView, textInputPlugin.autofillContext[@"field1"]);
  [self ensureOnlyActiveViewCanBecomeFirstResponder];

  // Switch to a similar password field, the previous field should be reused.
  oldContext = textInputPlugin.autofillContext;
  [self setClientId:200 configuration:config];

  // Reuse the input view instance from the last time.
  XCTAssertEqual(self.viewsVisibleToAutofill.count, 1);
  XCTAssertEqual(textInputPlugin.autofillContext.count, 3);

  [textInputPlugin collectGarbageInputViews];
  XCTAssertEqual(self.installedInputViews.count, 4);

  // Old autofill input fields are still installed and reused.
  for (NSString* key in oldContext.allKeys) {
    XCTAssertEqual(oldContext[key], textInputPlugin.autofillContext[key]);
  }
  XCTAssertNotEqual(textInputPlugin.textInputView, textInputPlugin.autofillContext[@"field1"]);
  [self ensureOnlyActiveViewCanBecomeFirstResponder];
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
  [self ensureOnlyActiveViewCanBecomeFirstResponder];

  [self commitAutofillContextAndVerify];
  XCTAssertNotEqual(textInputPlugin.textInputView, textInputPlugin.reusableInputView);
  [self ensureOnlyActiveViewCanBecomeFirstResponder];

  // Install the password field again.
  [self setClientId:123 configuration:config];
  // Switch to a regular autofill group.
  [self setClientId:124 configuration:field3];
  XCTAssertEqual(self.viewsVisibleToAutofill.count, 1);

  [textInputPlugin collectGarbageInputViews];
  XCTAssertEqual(self.installedInputViews.count, 3);
  XCTAssertEqual(textInputPlugin.autofillContext.count, 2);
  XCTAssertNotEqual(textInputPlugin.textInputView, nil);
  [self ensureOnlyActiveViewCanBecomeFirstResponder];

  [self commitAutofillContextAndVerify];
  XCTAssertNotEqual(textInputPlugin.textInputView, textInputPlugin.reusableInputView);
  [self ensureOnlyActiveViewCanBecomeFirstResponder];

  // Now switch to an input field that does not autofill.
  [self setClientId:125 configuration:self.mutableTemplateCopy];

  XCTAssertEqual(self.viewsVisibleToAutofill.count, 0);
  XCTAssertEqual(textInputPlugin.textInputView, textInputPlugin.reusableInputView);
  // The active view should still be installed so it doesn't get
  // deallocated.

  [textInputPlugin collectGarbageInputViews];
  XCTAssertEqual(self.installedInputViews.count, 1);
  XCTAssertEqual(textInputPlugin.autofillContext.count, 0);
  [self ensureOnlyActiveViewCanBecomeFirstResponder];

  [self commitAutofillContextAndVerify];
  XCTAssertEqual(textInputPlugin.textInputView, textInputPlugin.reusableInputView);
  [self ensureOnlyActiveViewCanBecomeFirstResponder];
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
  [self ensureOnlyActiveViewCanBecomeFirstResponder];

  // Find all the FlutterTextInputViews we created.
  NSArray<FlutterTextInputView*>* inputFields = self.installedInputViews;

  // Both fields are installed and visible because it's a password group.
  XCTAssertEqual(inputFields.count, 2);
  XCTAssertEqual(self.viewsVisibleToAutofill.count, 2);

  // Find the inactive autofillable input field.
  FlutterTextInputView* inactiveView = inputFields[1];
  [inactiveView replaceRange:[FlutterTextRange rangeWithNSRange:NSMakeRange(0, 0)]
                    withText:@"Autofilled!"];
  [self ensureOnlyActiveViewCanBecomeFirstResponder];

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

- (void)testClearAutofillContextClearsSelection {
  NSMutableDictionary* regularField = self.mutableTemplateCopy;
  NSDictionary* editingValue = @{
    @"text" : @"REGULAR_TEXT_FIELD",
    @"composingBase" : @0,
    @"composingExtent" : @3,
    @"selectionBase" : @1,
    @"selectionExtent" : @4
  };
  [regularField setValue:@{
    @"uniqueIdentifier" : @"field2",
    @"hints" : @[ @"hint2" ],
    @"editingValue" : editingValue,
  }
                  forKey:@"autofill"];
  [regularField addEntriesFromDictionary:editingValue];
  [self setClientId:123 configuration:regularField];
  [self ensureOnlyActiveViewCanBecomeFirstResponder];
  XCTAssertEqual(self.installedInputViews.count, 1);

  FlutterTextInputView* oldInputView = self.installedInputViews[0];
  XCTAssert([oldInputView.text isEqualToString:@"REGULAR_TEXT_FIELD"]);
  FlutterTextRange* selectionRange = (FlutterTextRange*)oldInputView.selectedTextRange;
  XCTAssert(NSEqualRanges(selectionRange.range, NSMakeRange(1, 3)));

  // Replace the original password field with new one. This should remove
  // the old password field, but not immediately.
  [self setClientId:124 configuration:self.mutablePasswordTemplateCopy];
  [self ensureOnlyActiveViewCanBecomeFirstResponder];

  XCTAssertEqual(self.installedInputViews.count, 2);

  [textInputPlugin collectGarbageInputViews];
  XCTAssertEqual(self.installedInputViews.count, 1);

  // Verify the old input view is properly cleaned up.
  XCTAssert([oldInputView.text isEqualToString:@""]);
  selectionRange = (FlutterTextRange*)oldInputView.selectedTextRange;
  XCTAssert(NSEqualRanges(selectionRange.range, NSMakeRange(0, 0)));
}

- (void)testGarbageInputViewsAreNotRemovedImmediately {
  // Add a password field that should autofill.
  [self setClientId:123 configuration:self.mutablePasswordTemplateCopy];
  [self ensureOnlyActiveViewCanBecomeFirstResponder];

  XCTAssertEqual(self.installedInputViews.count, 1);
  // Add an input field that doesn't autofill. This should remove the password
  // field, but not immediately.
  [self setClientId:124 configuration:self.mutableTemplateCopy];
  [self ensureOnlyActiveViewCanBecomeFirstResponder];

  XCTAssertEqual(self.installedInputViews.count, 2);

  [self commitAutofillContextAndVerify];
}

@end
