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

@interface FlutterTextInputViewSpy : FlutterTextInputView
@property(nonatomic, assign) UIAccessibilityNotifications receivedNotification;
@property(nonatomic, assign) id receivedNotificationTarget;
@property(nonatomic, assign) BOOL isAccessibilityFocused;

- (void)postAccessibilityNotification:(UIAccessibilityNotifications)notification target:(id)target;

@end

@implementation FlutterTextInputViewSpy {
}

- (void)postAccessibilityNotification:(UIAccessibilityNotifications)notification target:(id)target {
  self.receivedNotification = notification;
  self.receivedNotificationTarget = target;
}

- (BOOL)accessibilityElementIsFocused {
  return _isAccessibilityFocused;
}

@end

@interface FlutterSecureTextInputView : FlutterTextInputView
@property(nonatomic, strong) UITextField* textField;
@end

@interface FlutterTextInputPlugin ()
@property(nonatomic, assign) FlutterTextInputView* activeView;
@property(nonatomic, readonly)
    NSMutableDictionary<NSString*, FlutterTextInputView*>* autofillContext;

- (void)cleanUpViewHierarchy:(BOOL)includeActiveView
                   clearText:(BOOL)clearText
                delayRemoval:(BOOL)delayRemoval;
- (NSArray<UIView*>*)textInputViews;
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
  for (FlutterTextInputView* autofillView in textInputPlugin.autofillContext.allValues) {
    autofillView.textInputDelegate = nil;
  }
  engine = nil;
  [textInputPlugin.autofillContext removeAllObjects];
  [textInputPlugin cleanUpViewHierarchy:YES clearText:YES delayRemoval:NO];
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

- (void)setTextInputShow {
  FlutterMethodCall* setClientCall = [FlutterMethodCall methodCallWithMethodName:@"TextInput.show"
                                                                       arguments:@[]];
  [textInputPlugin handleMethodCall:setClientCall
                             result:^(id _Nullable result){
                             }];
}

- (void)setTextInputHide {
  FlutterMethodCall* setClientCall = [FlutterMethodCall methodCallWithMethodName:@"TextInput.hide"
                                                                       arguments:@[]];
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
  return (NSArray<FlutterTextInputView*>*)[textInputPlugin.textInputViews
      filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self isKindOfClass: %@",
                                                                   [FlutterTextInputView class]]];
}

- (FlutterTextRange*)getLineRangeFromTokenizer:(id<UITextInputTokenizer>)tokenizer
                                       atIndex:(NSInteger)index {
  UITextRange* range =
      [tokenizer rangeEnclosingPosition:[FlutterTextPosition positionWithIndex:index]
                        withGranularity:UITextGranularityLine
                            inDirection:UITextLayoutDirectionRight];
  XCTAssertTrue([range isKindOfClass:[FlutterTextRange class]]);
  return (FlutterTextRange*)range;
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
  XCTAssertEqual(inputFields.count, 1ul);

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

- (void)testSettingKeyboardTypeNoneDisablesSystemKeyboard {
  NSDictionary* config = self.mutableTemplateCopy;
  [config setValue:@{@"name" : @"TextInputType.none"} forKey:@"inputType"];
  [self setClientId:123 configuration:config];

  // Verify the view's inputViewController is not nil;
  XCTAssertNotNil(textInputPlugin.activeView.inputViewController);

  [config setValue:@{@"name" : @"TextInputType.url"} forKey:@"inputType"];
  [self setClientId:124 configuration:config];
  XCTAssertNotNil(textInputPlugin.activeView);
  XCTAssertNil(textInputPlugin.activeView.inputViewController);
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

  XCTAssertEqual(range.location, 0ul);
  XCTAssertEqual(range.length, 2ul);
}

- (void)testTextInRange {
  NSDictionary* config = self.mutableTemplateCopy;
  [config setValue:@{@"name" : @"TextInputType.url"} forKey:@"inputType"];
  [self setClientId:123 configuration:config];
  NSArray<FlutterTextInputView*>* inputFields = self.installedInputViews;
  FlutterTextInputView* inputView = inputFields[0];

  [inputView insertText:@"test"];

  UITextRange* range = [FlutterTextRange rangeWithNSRange:NSMakeRange(0, 20)];
  NSString* substring = [inputView textInRange:range];
  XCTAssertEqual(substring.length, 4ul);

  range = [FlutterTextRange rangeWithNSRange:NSMakeRange(10, 20)];
  substring = [inputView textInRange:range];
  XCTAssertEqual(substring.length, 0ul);
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

- (void)testInputViewCrash {
  FlutterTextInputView* activeView = nil;
  @autoreleasepool {
    FlutterTextInputPlugin* inputPlugin = [[FlutterTextInputPlugin alloc] init];
    activeView = inputPlugin.activeView;
    FlutterEngine* flutterEngine = [[FlutterEngine alloc] init];
    activeView.textInputDelegate = (id<FlutterTextInputDelegate>)flutterEngine;
  }
  XCTAssert(!activeView.textInputDelegate);
  [activeView updateEditingState];
}

- (void)testDoNotReuseInputViews {
  NSDictionary* config = self.mutableTemplateCopy;
  [self setClientId:123 configuration:config];
  FlutterTextInputView* currentView = textInputPlugin.activeView;
  [self setClientId:456 configuration:config];

  XCTAssertNotNil(currentView);
  XCTAssertNotNil(textInputPlugin.activeView);
  XCTAssertNotEqual(currentView, textInputPlugin.activeView);
}

- (void)testNoDanglingEnginePointer {
  NSDictionary* config = self.mutableTemplateCopy;
  [self setClientId:123 configuration:config];

  // We'll hold onto the current view and try to access the engine
  // after changing the active view.
  FlutterTextInputView* currentView = textInputPlugin.activeView;
  [self setClientId:456 configuration:config];
  XCTAssertNotNil(currentView);
  XCTAssertNotNil(textInputPlugin.activeView);
  XCTAssertNotEqual(currentView, textInputPlugin.activeView);

  // Verify that the view can no longer access the engine
  // instance.
  XCTAssertNil(currentView.textInputDelegate);
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

#pragma mark - Floating Cursor - Tests

- (void)testInputViewsHaveUIInteractions {
  if (@available(iOS 13.0, *)) {
    FlutterTextInputView* inputView = [[FlutterTextInputView alloc] init];
    XCTAssertGreaterThan(inputView.interactions.count, 0ul);
  }
}

- (void)testBoundsForFloatingCursor {
  FlutterTextInputView* inputView = [[FlutterTextInputView alloc] init];

  CGRect initialBounds = inputView.bounds;
  // Make sure the initial bounds.size is not as large.
  XCTAssertLessThan(inputView.bounds.size.width, 100);
  XCTAssertLessThan(inputView.bounds.size.height, 100);

  [inputView beginFloatingCursorAtPoint:CGPointMake(123, 321)];
  CGRect bounds = inputView.bounds;
  XCTAssertGreaterThan(bounds.size.width, 1000);
  XCTAssertGreaterThan(bounds.size.height, 1000);

  // Verify the caret is centered.
  XCTAssertEqual(
      CGRectGetMidX(bounds),
      CGRectGetMidX([inputView caretRectForPosition:[FlutterTextPosition positionWithIndex:1235]]));
  XCTAssertEqual(
      CGRectGetMidY(bounds),
      CGRectGetMidY([inputView caretRectForPosition:[FlutterTextPosition positionWithIndex:4567]]));

  [inputView updateFloatingCursorAtPoint:CGPointMake(456, 654)];
  bounds = inputView.bounds;
  XCTAssertGreaterThan(bounds.size.width, 1000);
  XCTAssertGreaterThan(bounds.size.height, 1000);

  // Verify the caret is centered.
  XCTAssertEqual(
      CGRectGetMidX(bounds),
      CGRectGetMidX([inputView caretRectForPosition:[FlutterTextPosition positionWithIndex:21]]));
  XCTAssertEqual(
      CGRectGetMidY(bounds),
      CGRectGetMidY([inputView caretRectForPosition:[FlutterTextPosition positionWithIndex:42]]));

  [inputView endFloatingCursor];
  XCTAssertTrue(CGRectEqualToRect(initialBounds, inputView.bounds));
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
                 [textInputPlugin.activeView isVisibleToAutofill] ? 1ul : 0ul);
  XCTAssertNotEqual(textInputPlugin.textInputView, nil);
  // The active view should still be installed so it doesn't get
  // deallocated.
  XCTAssertEqual(self.installedInputViews.count, 1ul);
  XCTAssertEqual(textInputPlugin.autofillContext.count, 0ul);
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
  XCTAssertEqual(self.viewsVisibleToAutofill.count, 2ul);

  XCTAssertEqual(textInputPlugin.autofillContext.count, 2ul);

  [textInputPlugin cleanUpViewHierarchy:NO clearText:YES delayRemoval:NO];
  XCTAssertEqual(self.installedInputViews.count, 2ul);
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

  XCTAssertEqual(self.viewsVisibleToAutofill.count, 2ul);
  XCTAssertEqual(textInputPlugin.autofillContext.count, 3ul);

  [textInputPlugin cleanUpViewHierarchy:NO clearText:YES delayRemoval:NO];
  XCTAssertEqual(self.installedInputViews.count, 3ul);
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

  XCTAssertEqual(self.viewsVisibleToAutofill.count, 1ul);
  XCTAssertEqual(textInputPlugin.autofillContext.count, 3ul);

  [textInputPlugin cleanUpViewHierarchy:NO clearText:YES delayRemoval:NO];
  XCTAssertEqual(self.installedInputViews.count, 4ul);

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
  XCTAssertEqual(self.viewsVisibleToAutofill.count, 1ul);
  XCTAssertEqual(textInputPlugin.autofillContext.count, 3ul);

  [textInputPlugin cleanUpViewHierarchy:NO clearText:YES delayRemoval:NO];
  XCTAssertEqual(self.installedInputViews.count, 4ul);

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
  XCTAssertEqual(self.viewsVisibleToAutofill.count, 2ul);
  XCTAssertEqual(textInputPlugin.autofillContext.count, 2ul);
  [self ensureOnlyActiveViewCanBecomeFirstResponder];

  [self commitAutofillContextAndVerify];
  [self ensureOnlyActiveViewCanBecomeFirstResponder];

  // Install the password field again.
  [self setClientId:123 configuration:config];
  // Switch to a regular autofill group.
  [self setClientId:124 configuration:field3];
  XCTAssertEqual(self.viewsVisibleToAutofill.count, 1ul);

  [textInputPlugin cleanUpViewHierarchy:NO clearText:YES delayRemoval:NO];
  XCTAssertEqual(self.installedInputViews.count, 3ul);
  XCTAssertEqual(textInputPlugin.autofillContext.count, 2ul);
  XCTAssertNotEqual(textInputPlugin.textInputView, nil);
  [self ensureOnlyActiveViewCanBecomeFirstResponder];

  [self commitAutofillContextAndVerify];
  [self ensureOnlyActiveViewCanBecomeFirstResponder];

  // Now switch to an input field that does not autofill.
  [self setClientId:125 configuration:self.mutableTemplateCopy];

  XCTAssertEqual(self.viewsVisibleToAutofill.count, 0ul);
  // The active view should still be installed so it doesn't get
  // deallocated.

  [textInputPlugin cleanUpViewHierarchy:NO clearText:YES delayRemoval:NO];
  XCTAssertEqual(self.installedInputViews.count, 1ul);
  XCTAssertEqual(textInputPlugin.autofillContext.count, 0ul);
  [self ensureOnlyActiveViewCanBecomeFirstResponder];

  [self commitAutofillContextAndVerify];
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
  XCTAssertEqual(inputFields.count, 2ul);
  XCTAssertEqual(self.viewsVisibleToAutofill.count, 2ul);

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
  XCTAssertEqual(self.installedInputViews.count, 1ul);

  FlutterTextInputView* oldInputView = self.installedInputViews[0];
  XCTAssert([oldInputView.text isEqualToString:@"REGULAR_TEXT_FIELD"]);
  FlutterTextRange* selectionRange = (FlutterTextRange*)oldInputView.selectedTextRange;
  XCTAssert(NSEqualRanges(selectionRange.range, NSMakeRange(1, 3)));

  // Replace the original password field with new one. This should remove
  // the old password field, but not immediately.
  [self setClientId:124 configuration:self.mutablePasswordTemplateCopy];
  [self ensureOnlyActiveViewCanBecomeFirstResponder];

  XCTAssertEqual(self.installedInputViews.count, 2ul);

  [textInputPlugin cleanUpViewHierarchy:NO clearText:YES delayRemoval:NO];
  XCTAssertEqual(self.installedInputViews.count, 1ul);

  // Verify the old input view is properly cleaned up.
  XCTAssert([oldInputView.text isEqualToString:@""]);
  selectionRange = (FlutterTextRange*)oldInputView.selectedTextRange;
  XCTAssert(NSEqualRanges(selectionRange.range, NSMakeRange(0, 0)));
}

- (void)testGarbageInputViewsAreNotRemovedImmediately {
  // Add a password field that should autofill.
  [self setClientId:123 configuration:self.mutablePasswordTemplateCopy];
  [self ensureOnlyActiveViewCanBecomeFirstResponder];

  XCTAssertEqual(self.installedInputViews.count, 1ul);
  // Add an input field that doesn't autofill. This should remove the password
  // field, but not immediately.
  [self setClientId:124 configuration:self.mutableTemplateCopy];
  [self ensureOnlyActiveViewCanBecomeFirstResponder];

  XCTAssertEqual(self.installedInputViews.count, 2ul);

  [self commitAutofillContextAndVerify];
}

- (void)testDecommissionedViewAreNotReusedByAutofill {
  // Regression test for https://github.com/flutter/flutter/issues/84407.
  NSMutableDictionary* configuration = self.mutableTemplateCopy;
  [configuration setValue:@{
    @"uniqueIdentifier" : @"field1",
    @"hints" : @[ UITextContentTypePassword ],
    @"editingValue" : @{@"text" : @""}
  }
                   forKey:@"autofill"];
  [configuration setValue:@[ [configuration copy] ] forKey:@"fields"];

  [self setClientId:123 configuration:configuration];

  [self setTextInputHide];
  UIView* previousActiveView = textInputPlugin.activeView;

  [self setClientId:124 configuration:configuration];

  // Make sure the autofillable view is reused.
  XCTAssertEqual(previousActiveView, textInputPlugin.activeView);
  XCTAssertNotNil(previousActiveView);
  // Does not crash.
}

- (void)testInitialActiveViewCantAccessTextInputDelegate {
  textInputPlugin.activeView.textInputDelegate = engine;
  // Before the framework sends the first text input configuration,
  // the dummy "activeView" we use should never have access to
  // its textInputDelegate.
  XCTAssertNil(textInputPlugin.activeView.textInputDelegate);
}

#pragma mark - Accessibility - Tests

- (void)testUITextInputAccessibilityNotHiddenWhenShowed {
  // Send show text input method call.
  [self setTextInputShow];
  // Find all the FlutterTextInputViews we created.
  NSArray<FlutterTextInputView*>* inputFields = self.installedInputViews;

  // The input view should not be hidden.
  XCTAssertEqual([inputFields count], 1u);

  // Send hide text input method call.
  [self setTextInputHide];

  inputFields = self.installedInputViews;

  // The input view should be hidden.
  XCTAssertEqual([inputFields count], 0u);
}

- (void)testFlutterTextInputViewDirectFocusToBackingTextInput {
  FlutterTextInputViewSpy* inputView = [[FlutterTextInputViewSpy alloc] init];
  inputView.textInputDelegate = engine;
  UIView* container = [[UIView alloc] init];
  UIAccessibilityElement* backing =
      [[UIAccessibilityElement alloc] initWithAccessibilityContainer:container];
  inputView.backingTextInputAccessibilityObject = backing;
  // Simulate accessibility focus.
  inputView.isAccessibilityFocused = YES;
  [inputView accessibilityElementDidBecomeFocused];

  XCTAssertEqual(inputView.receivedNotification, UIAccessibilityScreenChangedNotification);
  XCTAssertEqual(inputView.receivedNotificationTarget, backing);
}

- (void)testFlutterTokenizerCanParseLines {
  FlutterTextInputView* inputView = [[FlutterTextInputView alloc] init];
  inputView.textInputDelegate = engine;
  id<UITextInputTokenizer> tokenizer = [inputView tokenizer];

  // The tokenizer returns zero range When text is empty.
  FlutterTextRange* range = [self getLineRangeFromTokenizer:tokenizer atIndex:0];
  XCTAssertEqual(range.range.location, 0u);
  XCTAssertEqual(range.range.length, 0u);

  [inputView insertText:@"how are you\nI am fine, Thank you"];

  range = [self getLineRangeFromTokenizer:tokenizer atIndex:0];
  XCTAssertEqual(range.range.location, 0u);
  XCTAssertEqual(range.range.length, 11u);

  range = [self getLineRangeFromTokenizer:tokenizer atIndex:2];
  XCTAssertEqual(range.range.location, 0u);
  XCTAssertEqual(range.range.length, 11u);

  range = [self getLineRangeFromTokenizer:tokenizer atIndex:11];
  XCTAssertEqual(range.range.location, 0u);
  XCTAssertEqual(range.range.length, 11u);

  range = [self getLineRangeFromTokenizer:tokenizer atIndex:12];
  XCTAssertEqual(range.range.location, 12u);
  XCTAssertEqual(range.range.length, 20u);

  range = [self getLineRangeFromTokenizer:tokenizer atIndex:15];
  XCTAssertEqual(range.range.location, 12u);
  XCTAssertEqual(range.range.length, 20u);

  range = [self getLineRangeFromTokenizer:tokenizer atIndex:32];
  XCTAssertEqual(range.range.location, 12u);
  XCTAssertEqual(range.range.length, 20u);
}

- (void)testFlutterTextInputPluginRetainsFlutterTextInputView {
  FlutterTextInputPlugin* myInputPlugin = [[FlutterTextInputPlugin alloc] init];
  myInputPlugin.textInputDelegate = engine;
  __weak UIView* activeView;
  @autoreleasepool {
    FlutterMethodCall* setClientCall = [FlutterMethodCall
        methodCallWithMethodName:@"TextInput.setClient"
                       arguments:@[
                         [NSNumber numberWithInt:123], self.mutablePasswordTemplateCopy
                       ]];
    [myInputPlugin handleMethodCall:setClientCall
                             result:^(id _Nullable result){
                             }];
    activeView = myInputPlugin.textInputView;
    FlutterMethodCall* hideCall = [FlutterMethodCall methodCallWithMethodName:@"TextInput.hide"
                                                                    arguments:@[]];
    [myInputPlugin handleMethodCall:hideCall
                             result:^(id _Nullable result){
                             }];
    XCTAssertNotNil(activeView);
  }
  // This assert proves the myInputPlugin.textInputView is not deallocated.
  XCTAssertNotNil(activeView);
}

@end
