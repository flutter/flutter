// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterTextInputPlugin.h"

#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "flutter/shell/platform/darwin/common/framework/Headers/FlutterMacros.h"
#import "flutter/shell/platform/darwin/ios/framework/Headers/FlutterEngine.h"
#import "flutter/shell/platform/darwin/ios/framework/Headers/FlutterViewController.h"

FLUTTER_ASSERT_ARC

@interface FlutterEngine ()
- (nonnull FlutterTextInputPlugin*)textInputPlugin;
@end

@interface FlutterTextInputView ()
@property(nonatomic, copy) NSString* autofillId;
- (void)setEditableTransform:(NSArray*)matrix;
- (void)setTextInputClient:(int)client;
- (void)setTextInputState:(NSDictionary*)state;
- (void)setMarkedRect:(CGRect)markedRect;
- (void)updateEditingState;
- (BOOL)isVisibleToAutofill;
- (id<FlutterTextInputDelegate>)textInputDelegate;
- (void)configureWithDictionary:(NSDictionary*)configuration;
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
- (UIView*)hostView;
- (void)addToInputParentViewIfNeeded:(FlutterTextInputView*)inputView;
- (void)startLiveTextInput;
@end

@interface FlutterTextInputPluginTest : XCTestCase
@end

@implementation FlutterTextInputPluginTest {
  NSDictionary* _template;
  NSDictionary* _passwordTemplate;
  id engine;
  FlutterTextInputPlugin* textInputPlugin;

  FlutterViewController* viewController;
}

- (void)setUp {
  [super setUp];
  engine = OCMClassMock([FlutterEngine class]);

  textInputPlugin = [[FlutterTextInputPlugin alloc] initWithDelegate:engine];

  viewController = [[FlutterViewController alloc] init];
  textInputPlugin.viewController = viewController;

  // Clear pasteboard between tests.
  UIPasteboard.generalPasteboard.items = @[];
}

- (void)tearDown {
  textInputPlugin = nil;
  engine = nil;
  [textInputPlugin.autofillContext removeAllObjects];
  [textInputPlugin cleanUpViewHierarchy:YES clearText:YES delayRemoval:NO];
  [[[[textInputPlugin textInputView] superview] subviews]
      makeObjectsPerformSelector:@selector(removeFromSuperview)];
  viewController = nil;
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
      @"autocorrect" : @YES,
      @"enableInteractiveSelection" : @YES,
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

- (void)updateConfig:(NSDictionary*)config {
  FlutterMethodCall* updateConfigCall =
      [FlutterMethodCall methodCallWithMethodName:@"TextInput.updateConfig" arguments:config];
  [textInputPlugin handleMethodCall:updateConfigCall
                             result:^(id _Nullable result){
                             }];
}

#pragma mark - Tests

- (void)testWillNotCrashWhenViewControllerIsNil {
  FlutterEngine* flutterEngine = [[FlutterEngine alloc] init];
  FlutterTextInputPlugin* inputPlugin =
      [[FlutterTextInputPlugin alloc] initWithDelegate:(id<FlutterTextInputDelegate>)flutterEngine];
  XCTAssertNil(inputPlugin.viewController);
  FlutterMethodCall* methodCall = [FlutterMethodCall methodCallWithMethodName:@"TextInput.show"
                                                                    arguments:nil];
  XCTestExpectation* expectation = [[XCTestExpectation alloc] initWithDescription:@"result called"];

  [inputPlugin handleMethodCall:methodCall
                         result:^(id _Nullable result) {
                           XCTAssertNil(result);
                           [expectation fulfill];
                         }];
  XCTAssertNil(inputPlugin.activeView);
  [self waitForExpectations:@[ expectation ] timeout:1.0];
}

- (void)testInvokeStartLiveTextInput {
  FlutterMethodCall* methodCall =
      [FlutterMethodCall methodCallWithMethodName:@"TextInput.startLiveTextInput" arguments:nil];
  FlutterTextInputPlugin* mockPlugin = OCMPartialMock(textInputPlugin);
  [mockPlugin handleMethodCall:methodCall
                        result:^(id _Nullable result){
                        }];
  OCMVerify([mockPlugin startLiveTextInput]);
}

- (void)testNoDanglingEnginePointer {
  __weak FlutterTextInputPlugin* weakFlutterTextInputPlugin;
  FlutterViewController* flutterViewController = [[FlutterViewController alloc] init];
  __weak FlutterEngine* weakFlutterEngine;

  FlutterTextInputView* currentView;

  // The engine instance will be deallocated after the autorelease pool is drained.
  @autoreleasepool {
    FlutterEngine* flutterEngine = OCMClassMock([FlutterEngine class]);
    weakFlutterEngine = flutterEngine;
    NSAssert(weakFlutterEngine, @"flutter engine must not be nil");
    FlutterTextInputPlugin* flutterTextInputPlugin = [[FlutterTextInputPlugin alloc]
        initWithDelegate:(id<FlutterTextInputDelegate>)flutterEngine];
    weakFlutterTextInputPlugin = flutterTextInputPlugin;
    flutterTextInputPlugin.viewController = flutterViewController;

    // Set client so the text input plugin has an active view.
    NSDictionary* config = self.mutableTemplateCopy;
    FlutterMethodCall* setClientCall =
        [FlutterMethodCall methodCallWithMethodName:@"TextInput.setClient"
                                          arguments:@[ [NSNumber numberWithInt:123], config ]];
    [flutterTextInputPlugin handleMethodCall:setClientCall
                                      result:^(id _Nullable result){
                                      }];
    currentView = flutterTextInputPlugin.activeView;
  }

  NSAssert(!weakFlutterEngine, @"flutter engine must be nil");
  NSAssert(currentView, @"current view must not be nil");

  XCTAssertNil(weakFlutterTextInputPlugin);
  // Verify that the view can no longer access the deallocated engine/text input plugin
  // instance.
  XCTAssertNil(currentView.textInputDelegate);
}

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
  FlutterTextInputView* inputView = [[FlutterTextInputView alloc] initWithOwner:textInputPlugin];
  [inputView firstRectForRange:[FlutterTextRange rangeWithNSRange:NSMakeRange(0, 1)]];

  // Verify behavior.
  OCMVerify([engine flutterTextInputView:inputView
      showAutocorrectionPromptRectForStart:0
                                       end:1
                                withClient:0]);
}

- (void)testIngoresSelectionChangeIfSelectionIsDisabled {
  FlutterTextInputView* inputView = [[FlutterTextInputView alloc] initWithOwner:textInputPlugin];
  __block int updateCount = 0;
  OCMStub([engine flutterTextInputView:inputView updateEditingClient:0 withState:[OCMArg isNotNil]])
      .andDo(^(NSInvocation* invocation) {
        updateCount++;
      });

  [inputView.text setString:@"Some initial text"];
  XCTAssertEqual(updateCount, 0);

  FlutterTextRange* textRange = [FlutterTextRange rangeWithNSRange:NSMakeRange(0, 1)];
  [inputView setSelectedTextRange:textRange];
  XCTAssertEqual(updateCount, 1);

  // Disable the interactive selection.
  NSDictionary* config = self.mutableTemplateCopy;
  [config setValue:@(NO) forKey:@"enableInteractiveSelection"];
  [config setValue:@(NO) forKey:@"obscureText"];
  [config setValue:@(NO) forKey:@"enableDeltaModel"];
  [inputView configureWithDictionary:config];

  textRange = [FlutterTextRange rangeWithNSRange:NSMakeRange(2, 3)];
  [inputView setSelectedTextRange:textRange];
  // The update count does not change.
  XCTAssertEqual(updateCount, 1);
}

- (void)testAutocorrectionPromptRectDoesNotAppearDuringScribble {
  if (@available(iOS 14.0, *)) {
    FlutterTextInputView* inputView = [[FlutterTextInputView alloc] initWithOwner:textInputPlugin];

    __block int callCount = 0;
    OCMStub([engine flutterTextInputView:inputView
                showAutocorrectionPromptRectForStart:0
                                                 end:1
                                          withClient:0])
        .andDo(^(NSInvocation* invocation) {
          callCount++;
        });

    [inputView firstRectForRange:[FlutterTextRange rangeWithNSRange:NSMakeRange(0, 1)]];
    // showAutocorrectionPromptRectForStart fires in response to firstRectForRange
    XCTAssertEqual(callCount, 1);

    UIScribbleInteraction* scribbleInteraction =
        [[UIScribbleInteraction alloc] initWithDelegate:inputView];

    [inputView scribbleInteractionWillBeginWriting:scribbleInteraction];
    [inputView firstRectForRange:[FlutterTextRange rangeWithNSRange:NSMakeRange(0, 1)]];
    // showAutocorrectionPromptRectForStart does not fire in response to setMarkedText during a
    // scribble interaction.firstRectForRange
    XCTAssertEqual(callCount, 1);

    [inputView scribbleInteractionDidFinishWriting:scribbleInteraction];
    [inputView resetScribbleInteractionStatusIfEnding];
    [inputView firstRectForRange:[FlutterTextRange rangeWithNSRange:NSMakeRange(0, 1)]];
    // showAutocorrectionPromptRectForStart fires in response to firstRectForRange.
    XCTAssertEqual(callCount, 2);

    inputView.scribbleFocusStatus = FlutterScribbleFocusStatusFocusing;
    [inputView firstRectForRange:[FlutterTextRange rangeWithNSRange:NSMakeRange(0, 1)]];
    // showAutocorrectionPromptRectForStart does not fire in response to firstRectForRange during a
    // scribble-initiated focus.
    XCTAssertEqual(callCount, 2);

    inputView.scribbleFocusStatus = FlutterScribbleFocusStatusFocused;
    [inputView firstRectForRange:[FlutterTextRange rangeWithNSRange:NSMakeRange(0, 1)]];
    // showAutocorrectionPromptRectForStart does not fire in response to firstRectForRange after a
    // scribble-initiated focus.
    XCTAssertEqual(callCount, 2);

    inputView.scribbleFocusStatus = FlutterScribbleFocusStatusUnfocused;
    [inputView firstRectForRange:[FlutterTextRange rangeWithNSRange:NSMakeRange(0, 1)]];
    // showAutocorrectionPromptRectForStart fires in response to firstRectForRange.
    XCTAssertEqual(callCount, 3);
  }
}

- (void)testTextRangeFromPositionMatchesUITextViewBehavior {
  FlutterTextInputView* inputView = [[FlutterTextInputView alloc] initWithOwner:textInputPlugin];
  FlutterTextPosition* fromPosition = [FlutterTextPosition positionWithIndex:2];
  FlutterTextPosition* toPosition = [FlutterTextPosition positionWithIndex:0];

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

- (void)testStandardEditActions {
  NSDictionary* config = self.mutableTemplateCopy;
  [self setClientId:123 configuration:config];
  NSArray<FlutterTextInputView*>* inputFields = self.installedInputViews;
  FlutterTextInputView* inputView = inputFields[0];

  [inputView insertText:@"aaaa"];
  [inputView selectAll:nil];
  [inputView cut:nil];
  [inputView insertText:@"bbbb"];
  XCTAssertTrue([inputView canPerformAction:@selector(paste:) withSender:nil]);
  [inputView paste:nil];
  [inputView selectAll:nil];
  [inputView copy:nil];
  [inputView paste:nil];
  [inputView selectAll:nil];
  [inputView delete:nil];
  [inputView paste:nil];
  [inputView paste:nil];

  UITextRange* range = [FlutterTextRange rangeWithNSRange:NSMakeRange(0, 30)];
  NSString* substring = [inputView textInRange:range];
  XCTAssertEqualObjects(substring, @"bbbbaaaabbbbaaaa");
}

- (void)testDeletingBackward {
  NSDictionary* config = self.mutableTemplateCopy;
  [self setClientId:123 configuration:config];
  NSArray<FlutterTextInputView*>* inputFields = self.installedInputViews;
  FlutterTextInputView* inputView = inputFields[0];

  [inputView insertText:@"ឹ😀 text 🥰👨‍👩‍👧‍👦🇺🇳ดี "];
  [inputView deleteBackward];
  [inputView deleteBackward];

  // Thai vowel is removed.
  XCTAssertEqualObjects(inputView.text, @"ឹ😀 text 🥰👨‍👩‍👧‍👦🇺🇳ด");
  [inputView deleteBackward];
  XCTAssertEqualObjects(inputView.text, @"ឹ😀 text 🥰👨‍👩‍👧‍👦🇺🇳");
  [inputView deleteBackward];
  XCTAssertEqualObjects(inputView.text, @"ឹ😀 text 🥰👨‍👩‍👧‍👦");
  [inputView deleteBackward];
  XCTAssertEqualObjects(inputView.text, @"ឹ😀 text 🥰");
  [inputView deleteBackward];

  XCTAssertEqualObjects(inputView.text, @"ឹ😀 text ");
  [inputView deleteBackward];
  [inputView deleteBackward];
  [inputView deleteBackward];
  [inputView deleteBackward];
  [inputView deleteBackward];
  [inputView deleteBackward];

  XCTAssertEqualObjects(inputView.text, @"ឹ😀");
  [inputView deleteBackward];
  XCTAssertEqualObjects(inputView.text, @"ឹ");
  [inputView deleteBackward];
  XCTAssertEqualObjects(inputView.text, @"");
}

// This tests the workaround to fix an iOS 16 bug
// See: https://github.com/flutter/flutter/issues/111494
- (void)testSystemOnlyAddingPartialComposedCharacter {
  NSDictionary* config = self.mutableTemplateCopy;
  [self setClientId:123 configuration:config];
  NSArray<FlutterTextInputView*>* inputFields = self.installedInputViews;
  FlutterTextInputView* inputView = inputFields[0];

  [inputView insertText:@"👨‍👩‍👧‍👦"];
  [inputView deleteBackward];

  // Insert the first unichar in the emoji.
  [inputView insertText:[@"👨‍👩‍👧‍👦" substringWithRange:NSMakeRange(0, 1)]];
  [inputView insertText:@"아"];

  XCTAssertEqualObjects(inputView.text, @"👨‍👩‍👧‍👦아");

  // Deleting 아.
  [inputView deleteBackward];
  // 👨‍👩‍👧‍👦 should be the current string.

  [inputView insertText:@"😀"];
  [inputView deleteBackward];
  // Insert the first unichar in the emoji.
  [inputView insertText:[@"😀" substringWithRange:NSMakeRange(0, 1)]];
  [inputView insertText:@"아"];
  XCTAssertEqualObjects(inputView.text, @"👨‍👩‍👧‍👦😀아");

  // Deleting 아.
  [inputView deleteBackward];
  // 👨‍👩‍👧‍👦😀 should be the current string.

  [inputView deleteBackward];
  // Insert the first unichar in the emoji.
  [inputView insertText:[@"😀" substringWithRange:NSMakeRange(0, 1)]];
  [inputView insertText:@"아"];

  XCTAssertEqualObjects(inputView.text, @"👨‍👩‍👧‍👦😀아");
}

- (void)testCachedComposedCharacterClearedAtKeyboardInteraction {
  NSDictionary* config = self.mutableTemplateCopy;
  [self setClientId:123 configuration:config];
  NSArray<FlutterTextInputView*>* inputFields = self.installedInputViews;
  FlutterTextInputView* inputView = inputFields[0];

  [inputView insertText:@"👨‍👩‍👧‍👦"];
  [inputView deleteBackward];
  [inputView shouldChangeTextInRange:OCMClassMock([UITextRange class]) replacementText:@""];

  // Insert the first unichar in the emoji.
  NSString* brokenEmoji = [@"👨‍👩‍👧‍👦" substringWithRange:NSMakeRange(0, 1)];
  [inputView insertText:brokenEmoji];
  [inputView insertText:@"아"];

  NSString* finalText = [NSString stringWithFormat:@"%@아", brokenEmoji];
  XCTAssertEqualObjects(inputView.text, finalText);
}

- (void)testPastingNonTextDisallowed {
  NSDictionary* config = self.mutableTemplateCopy;
  [self setClientId:123 configuration:config];
  NSArray<FlutterTextInputView*>* inputFields = self.installedInputViews;
  FlutterTextInputView* inputView = inputFields[0];

  UIPasteboard.generalPasteboard.color = UIColor.redColor;
  XCTAssertNil(UIPasteboard.generalPasteboard.string);
  XCTAssertFalse([inputView canPerformAction:@selector(paste:) withSender:nil]);
  [inputView paste:nil];

  XCTAssertEqualObjects(inputView.text, @"");
}

- (void)testNoZombies {
  // Regression test for https://github.com/flutter/flutter/issues/62501.
  FlutterSecureTextInputView* passwordView =
      [[FlutterSecureTextInputView alloc] initWithOwner:textInputPlugin];

  @autoreleasepool {
    // Initialize the lazy textField.
    [passwordView.textField description];
  }
  XCTAssert([[passwordView.textField description] containsString:@"TextField"]);
}

- (void)testInputViewCrash {
  FlutterTextInputView* activeView = nil;
  @autoreleasepool {
    FlutterEngine* flutterEngine = [[FlutterEngine alloc] init];
    FlutterTextInputPlugin* inputPlugin = [[FlutterTextInputPlugin alloc]
        initWithDelegate:(id<FlutterTextInputDelegate>)flutterEngine];
    activeView = inputPlugin.activeView;
  }
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

- (void)ensureOnlyActiveViewCanBecomeFirstResponder {
  for (FlutterTextInputView* inputView in self.installedInputViews) {
    XCTAssertEqual(inputView.canBecomeFirstResponder, inputView == textInputPlugin.activeView);
  }
}

- (void)testPropagatePressEventsToViewController {
  FlutterViewController* mockViewController = OCMPartialMock(viewController);
  OCMStub([mockViewController pressesBegan:[OCMArg isNotNil] withEvent:[OCMArg isNotNil]]);
  OCMStub([mockViewController pressesEnded:[OCMArg isNotNil] withEvent:[OCMArg isNotNil]]);

  textInputPlugin.viewController = mockViewController;

  NSDictionary* config = self.mutableTemplateCopy;
  [self setClientId:123 configuration:config];
  FlutterTextInputView* currentView = textInputPlugin.activeView;
  [self setTextInputShow];

  [currentView pressesBegan:[NSSet setWithObjects:OCMClassMock([UIPress class]), nil]
                  withEvent:OCMClassMock([UIPressesEvent class])];

  OCMVerify(times(1), [mockViewController pressesBegan:[OCMArg isNotNil]
                                             withEvent:[OCMArg isNotNil]]);
  OCMVerify(times(0), [mockViewController pressesEnded:[OCMArg isNotNil]
                                             withEvent:[OCMArg isNotNil]]);

  [currentView pressesEnded:[NSSet setWithObjects:OCMClassMock([UIPress class]), nil]
                  withEvent:OCMClassMock([UIPressesEvent class])];

  OCMVerify(times(1), [mockViewController pressesBegan:[OCMArg isNotNil]
                                             withEvent:[OCMArg isNotNil]]);
  OCMVerify(times(1), [mockViewController pressesEnded:[OCMArg isNotNil]
                                             withEvent:[OCMArg isNotNil]]);
}

- (void)testPropagatePressEventsToViewController2 {
  FlutterViewController* mockViewController = OCMPartialMock(viewController);
  OCMStub([mockViewController pressesBegan:[OCMArg isNotNil] withEvent:[OCMArg isNotNil]]);
  OCMStub([mockViewController pressesEnded:[OCMArg isNotNil] withEvent:[OCMArg isNotNil]]);

  textInputPlugin.viewController = mockViewController;

  NSDictionary* config = self.mutableTemplateCopy;
  [self setClientId:123 configuration:config];
  [self setTextInputShow];
  FlutterTextInputView* currentView = textInputPlugin.activeView;

  [currentView pressesBegan:[NSSet setWithObjects:OCMClassMock([UIPress class]), nil]
                  withEvent:OCMClassMock([UIPressesEvent class])];

  OCMVerify(times(1), [mockViewController pressesBegan:[OCMArg isNotNil]
                                             withEvent:[OCMArg isNotNil]]);
  OCMVerify(times(0), [mockViewController pressesEnded:[OCMArg isNotNil]
                                             withEvent:[OCMArg isNotNil]]);

  // Switch focus to a different view.
  [self setClientId:321 configuration:config];
  [self setTextInputShow];
  NSAssert(textInputPlugin.activeView, @"active view must not be nil");
  NSAssert(textInputPlugin.activeView != currentView, @"active view must change");
  currentView = textInputPlugin.activeView;
  [currentView pressesEnded:[NSSet setWithObjects:OCMClassMock([UIPress class]), nil]
                  withEvent:OCMClassMock([UIPressesEvent class])];

  OCMVerify(times(1), [mockViewController pressesBegan:[OCMArg isNotNil]
                                             withEvent:[OCMArg isNotNil]]);
  OCMVerify(times(1), [mockViewController pressesEnded:[OCMArg isNotNil]
                                             withEvent:[OCMArg isNotNil]]);
}

- (void)testUpdateSecureTextEntry {
  NSDictionary* config = self.mutableTemplateCopy;
  [config setValue:@"YES" forKey:@"obscureText"];
  [self setClientId:123 configuration:config];

  NSArray<FlutterTextInputView*>* inputFields = self.installedInputViews;
  FlutterTextInputView* inputView = OCMPartialMock(inputFields[0]);

  __block int callCount = 0;
  OCMStub([inputView reloadInputViews]).andDo(^(NSInvocation* invocation) {
    callCount++;
  });

  XCTAssertTrue(inputView.isSecureTextEntry);

  config = self.mutableTemplateCopy;
  [config setValue:@"NO" forKey:@"obscureText"];
  [self updateConfig:config];

  XCTAssertEqual(callCount, 1);
  XCTAssertFalse(inputView.isSecureTextEntry);
}

#pragma mark - TextEditingDelta tests
- (void)testTextEditingDeltasAreGeneratedOnTextInput {
  FlutterTextInputView* inputView = [[FlutterTextInputView alloc] initWithOwner:textInputPlugin];
  inputView.enableDeltaModel = YES;

  __block int updateCount = 0;
  OCMStub([engine flutterTextInputView:inputView updateEditingClient:0 withDelta:[OCMArg isNotNil]])
      .andDo(^(NSInvocation* invocation) {
        updateCount++;
      });

  [inputView insertText:@"text to insert"];
  // Update the framework exactly once.
  XCTAssertEqual(updateCount, 1);

  // Verify correct delta is generated.
  OCMVerify([engine
      flutterTextInputView:inputView
       updateEditingClient:0
                 withDelta:[OCMArg checkWithBlock:^BOOL(NSDictionary* state) {
                   return ([[state[@"deltas"] objectAtIndex:0][@"oldText"] isEqualToString:@""]) &&
                          ([[state[@"deltas"] objectAtIndex:0][@"deltaText"]
                              isEqualToString:@"text to insert"]) &&
                          ([[state[@"deltas"] objectAtIndex:0][@"deltaStart"] intValue] == 0) &&
                          ([[state[@"deltas"] objectAtIndex:0][@"deltaEnd"] intValue] == 0);
                 }]]);

  [inputView deleteBackward];
  XCTAssertEqual(updateCount, 2);

  OCMVerify([engine
      flutterTextInputView:inputView
       updateEditingClient:0
                 withDelta:[OCMArg checkWithBlock:^BOOL(NSDictionary* state) {
                   return ([[state[@"deltas"] objectAtIndex:0][@"oldText"]
                              isEqualToString:@"text to insert"]) &&
                          ([[state[@"deltas"] objectAtIndex:0][@"deltaText"]
                              isEqualToString:@""]) &&
                          ([[state[@"deltas"] objectAtIndex:0][@"deltaStart"] intValue] == 13) &&
                          ([[state[@"deltas"] objectAtIndex:0][@"deltaEnd"] intValue] == 14);
                 }]]);

  inputView.selectedTextRange = [FlutterTextRange rangeWithNSRange:NSMakeRange(0, 1)];
  XCTAssertEqual(updateCount, 3);

  OCMVerify([engine
      flutterTextInputView:inputView
       updateEditingClient:0
                 withDelta:[OCMArg checkWithBlock:^BOOL(NSDictionary* state) {
                   return ([[state[@"deltas"] objectAtIndex:0][@"oldText"]
                              isEqualToString:@"text to inser"]) &&
                          ([[state[@"deltas"] objectAtIndex:0][@"deltaText"]
                              isEqualToString:@""]) &&
                          ([[state[@"deltas"] objectAtIndex:0][@"deltaStart"] intValue] == -1) &&
                          ([[state[@"deltas"] objectAtIndex:0][@"deltaEnd"] intValue] == -1);
                 }]]);

  [inputView replaceRange:[FlutterTextRange rangeWithNSRange:NSMakeRange(0, 1)]
                 withText:@"replace text"];
  XCTAssertEqual(updateCount, 4);

  OCMVerify([engine
      flutterTextInputView:inputView
       updateEditingClient:0
                 withDelta:[OCMArg checkWithBlock:^BOOL(NSDictionary* state) {
                   return ([[state[@"deltas"] objectAtIndex:0][@"oldText"]
                              isEqualToString:@"text to inser"]) &&
                          ([[state[@"deltas"] objectAtIndex:0][@"deltaText"]
                              isEqualToString:@"replace text"]) &&
                          ([[state[@"deltas"] objectAtIndex:0][@"deltaStart"] intValue] == 0) &&
                          ([[state[@"deltas"] objectAtIndex:0][@"deltaEnd"] intValue] == 1);
                 }]]);

  [inputView setMarkedText:@"marked text" selectedRange:NSMakeRange(0, 1)];
  XCTAssertEqual(updateCount, 5);

  OCMVerify([engine
      flutterTextInputView:inputView
       updateEditingClient:0
                 withDelta:[OCMArg checkWithBlock:^BOOL(NSDictionary* state) {
                   return ([[state[@"deltas"] objectAtIndex:0][@"oldText"]
                              isEqualToString:@"replace textext to inser"]) &&
                          ([[state[@"deltas"] objectAtIndex:0][@"deltaText"]
                              isEqualToString:@"marked text"]) &&
                          ([[state[@"deltas"] objectAtIndex:0][@"deltaStart"] intValue] == 12) &&
                          ([[state[@"deltas"] objectAtIndex:0][@"deltaEnd"] intValue] == 12);
                 }]]);

  [inputView unmarkText];
  XCTAssertEqual(updateCount, 6);

  OCMVerify([engine
      flutterTextInputView:inputView
       updateEditingClient:0
                 withDelta:[OCMArg checkWithBlock:^BOOL(NSDictionary* state) {
                   return ([[state[@"deltas"] objectAtIndex:0][@"oldText"]
                              isEqualToString:@"replace textmarked textext to inser"]) &&
                          ([[state[@"deltas"] objectAtIndex:0][@"deltaText"]
                              isEqualToString:@""]) &&
                          ([[state[@"deltas"] objectAtIndex:0][@"deltaStart"] intValue] == -1) &&
                          ([[state[@"deltas"] objectAtIndex:0][@"deltaEnd"] intValue] == -1);
                 }]]);
}

- (void)testTextEditingDeltasAreGeneratedOnSetMarkedTextReplacement {
  FlutterTextInputView* inputView = [[FlutterTextInputView alloc] initWithOwner:textInputPlugin];
  inputView.enableDeltaModel = YES;

  __block int updateCount = 0;
  OCMStub([engine flutterTextInputView:inputView updateEditingClient:0 withDelta:[OCMArg isNotNil]])
      .andDo(^(NSInvocation* invocation) {
        updateCount++;
      });

  [inputView.text setString:@"Some initial text"];
  XCTAssertEqual(updateCount, 0);

  UITextRange* range = [FlutterTextRange rangeWithNSRange:NSMakeRange(13, 4)];
  inputView.markedTextRange = range;
  inputView.selectedTextRange = nil;
  XCTAssertEqual(updateCount, 1);

  [inputView setMarkedText:@"new marked text." selectedRange:NSMakeRange(0, 1)];
  XCTAssertEqual(updateCount, 2);

  OCMVerify([engine
      flutterTextInputView:inputView
       updateEditingClient:0
                 withDelta:[OCMArg checkWithBlock:^BOOL(NSDictionary* state) {
                   return ([[state[@"deltas"] objectAtIndex:0][@"oldText"]
                              isEqualToString:@"Some initial text"]) &&
                          ([[state[@"deltas"] objectAtIndex:0][@"deltaText"]
                              isEqualToString:@"new marked text."]) &&
                          ([[state[@"deltas"] objectAtIndex:0][@"deltaStart"] intValue] == 13) &&
                          ([[state[@"deltas"] objectAtIndex:0][@"deltaEnd"] intValue] == 17);
                 }]]);
}

- (void)testTextEditingDeltasAreGeneratedOnSetMarkedTextInsertion {
  FlutterTextInputView* inputView = [[FlutterTextInputView alloc] initWithOwner:textInputPlugin];
  inputView.enableDeltaModel = YES;

  __block int updateCount = 0;
  OCMStub([engine flutterTextInputView:inputView updateEditingClient:0 withDelta:[OCMArg isNotNil]])
      .andDo(^(NSInvocation* invocation) {
        updateCount++;
      });

  [inputView.text setString:@"Some initial text"];
  XCTAssertEqual(updateCount, 0);

  UITextRange* range = [FlutterTextRange rangeWithNSRange:NSMakeRange(13, 4)];
  inputView.markedTextRange = range;
  inputView.selectedTextRange = nil;
  XCTAssertEqual(updateCount, 1);

  [inputView setMarkedText:@"text." selectedRange:NSMakeRange(0, 1)];
  XCTAssertEqual(updateCount, 2);

  OCMVerify([engine
      flutterTextInputView:inputView
       updateEditingClient:0
                 withDelta:[OCMArg checkWithBlock:^BOOL(NSDictionary* state) {
                   return ([[state[@"deltas"] objectAtIndex:0][@"oldText"]
                              isEqualToString:@"Some initial text"]) &&
                          ([[state[@"deltas"] objectAtIndex:0][@"deltaText"]
                              isEqualToString:@"text."]) &&
                          ([[state[@"deltas"] objectAtIndex:0][@"deltaStart"] intValue] == 13) &&
                          ([[state[@"deltas"] objectAtIndex:0][@"deltaEnd"] intValue] == 17);
                 }]]);
}

- (void)testTextEditingDeltasAreGeneratedOnSetMarkedTextDeletion {
  FlutterTextInputView* inputView = [[FlutterTextInputView alloc] initWithOwner:textInputPlugin];
  inputView.enableDeltaModel = YES;

  __block int updateCount = 0;
  OCMStub([engine flutterTextInputView:inputView updateEditingClient:0 withDelta:[OCMArg isNotNil]])
      .andDo(^(NSInvocation* invocation) {
        updateCount++;
      });

  [inputView.text setString:@"Some initial text"];
  XCTAssertEqual(updateCount, 0);

  UITextRange* range = [FlutterTextRange rangeWithNSRange:NSMakeRange(13, 4)];
  inputView.markedTextRange = range;
  inputView.selectedTextRange = nil;
  XCTAssertEqual(updateCount, 1);

  [inputView setMarkedText:@"tex" selectedRange:NSMakeRange(0, 1)];
  XCTAssertEqual(updateCount, 2);

  OCMVerify([engine
      flutterTextInputView:inputView
       updateEditingClient:0
                 withDelta:[OCMArg checkWithBlock:^BOOL(NSDictionary* state) {
                   return ([[state[@"deltas"] objectAtIndex:0][@"oldText"]
                              isEqualToString:@"Some initial text"]) &&
                          ([[state[@"deltas"] objectAtIndex:0][@"deltaText"]
                              isEqualToString:@"tex"]) &&
                          ([[state[@"deltas"] objectAtIndex:0][@"deltaStart"] intValue] == 13) &&
                          ([[state[@"deltas"] objectAtIndex:0][@"deltaEnd"] intValue] == 17);
                 }]]);
}

#pragma mark - EditingState tests

- (void)testUITextInputCallsUpdateEditingStateOnce {
  FlutterTextInputView* inputView = [[FlutterTextInputView alloc] initWithOwner:textInputPlugin];

  __block int updateCount = 0;
  OCMStub([engine flutterTextInputView:inputView updateEditingClient:0 withState:[OCMArg isNotNil]])
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

- (void)testUITextInputCallsUpdateEditingStateWithDeltaOnce {
  FlutterTextInputView* inputView = [[FlutterTextInputView alloc] initWithOwner:textInputPlugin];
  inputView.enableDeltaModel = YES;

  __block int updateCount = 0;
  OCMStub([engine flutterTextInputView:inputView updateEditingClient:0 withDelta:[OCMArg isNotNil]])
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
  FlutterTextInputView* inputView = [[FlutterTextInputView alloc] initWithOwner:textInputPlugin];

  __block int updateCount = 0;
  OCMStub([engine flutterTextInputView:inputView updateEditingClient:0 withState:[OCMArg isNotNil]])
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

- (void)testTextChangesDoNotTriggerUpdateEditingClientWithDelta {
  FlutterTextInputView* inputView = [[FlutterTextInputView alloc] initWithOwner:textInputPlugin];
  inputView.enableDeltaModel = YES;

  __block int updateCount = 0;
  OCMStub([engine flutterTextInputView:inputView updateEditingClient:0 withDelta:[OCMArg isNotNil]])
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
  FlutterTextInputView* inputView = [[FlutterTextInputView alloc] initWithOwner:textInputPlugin];

  __block int updateCount = 0;
  OCMStub([engine flutterTextInputView:inputView updateEditingClient:0 withState:[OCMArg isNotNil]])
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

- (void)testCanCopyPasteWithScribbleEnabled {
  if (@available(iOS 14.0, *)) {
    NSDictionary* config = self.mutableTemplateCopy;
    [self setClientId:123 configuration:config];
    NSArray<FlutterTextInputView*>* inputFields = self.installedInputViews;
    FlutterTextInputView* inputView = inputFields[0];

    FlutterTextInputView* mockInputView = OCMPartialMock(inputView);
    OCMStub([mockInputView isScribbleAvailable]).andReturn(YES);

    [mockInputView insertText:@"aaaa"];
    [mockInputView selectAll:nil];

    XCTAssertFalse([mockInputView canPerformAction:@selector(copy:) withSender:NULL]);
    XCTAssertTrue([mockInputView canPerformAction:@selector(copy:) withSender:@"sender"]);
    XCTAssertFalse([mockInputView canPerformAction:@selector(paste:) withSender:NULL]);
    XCTAssertFalse([mockInputView canPerformAction:@selector(paste:) withSender:@"sender"]);

    [mockInputView copy:NULL];
    XCTAssertFalse([mockInputView canPerformAction:@selector(copy:) withSender:NULL]);
    XCTAssertTrue([mockInputView canPerformAction:@selector(copy:) withSender:@"sender"]);
    XCTAssertFalse([mockInputView canPerformAction:@selector(paste:) withSender:NULL]);
    XCTAssertTrue([mockInputView canPerformAction:@selector(paste:) withSender:@"sender"]);
  }
}

- (void)testSetMarkedTextDuringScribbleDoesNotTriggerUpdateEditingClient {
  if (@available(iOS 14.0, *)) {
    FlutterTextInputView* inputView = [[FlutterTextInputView alloc] initWithOwner:textInputPlugin];

    __block int updateCount = 0;
    OCMStub([engine flutterTextInputView:inputView
                     updateEditingClient:0
                               withState:[OCMArg isNotNil]])
        .andDo(^(NSInvocation* invocation) {
          updateCount++;
        });

    [inputView setMarkedText:@"marked text" selectedRange:NSMakeRange(0, 1)];
    // updateEditingClient fires in response to setMarkedText.
    XCTAssertEqual(updateCount, 1);

    UIScribbleInteraction* scribbleInteraction =
        [[UIScribbleInteraction alloc] initWithDelegate:inputView];

    [inputView scribbleInteractionWillBeginWriting:scribbleInteraction];
    [inputView setMarkedText:@"during writing" selectedRange:NSMakeRange(1, 2)];
    // updateEditingClient does not fire in response to setMarkedText during a scribble interaction.
    XCTAssertEqual(updateCount, 1);

    [inputView scribbleInteractionDidFinishWriting:scribbleInteraction];
    [inputView resetScribbleInteractionStatusIfEnding];
    [inputView setMarkedText:@"marked text" selectedRange:NSMakeRange(0, 1)];
    // updateEditingClient fires in response to setMarkedText.
    XCTAssertEqual(updateCount, 2);

    inputView.scribbleFocusStatus = FlutterScribbleFocusStatusFocusing;
    [inputView setMarkedText:@"during focus" selectedRange:NSMakeRange(1, 2)];
    // updateEditingClient does not fire in response to setMarkedText during a scribble-initiated
    // focus.
    XCTAssertEqual(updateCount, 2);

    inputView.scribbleFocusStatus = FlutterScribbleFocusStatusFocused;
    [inputView setMarkedText:@"after focus" selectedRange:NSMakeRange(2, 3)];
    // updateEditingClient does not fire in response to setMarkedText after a scribble-initiated
    // focus.
    XCTAssertEqual(updateCount, 2);

    inputView.scribbleFocusStatus = FlutterScribbleFocusStatusUnfocused;
    [inputView setMarkedText:@"marked text" selectedRange:NSMakeRange(0, 1)];
    // updateEditingClient fires in response to setMarkedText.
    XCTAssertEqual(updateCount, 3);
  }
}

- (void)testUpdateEditingClientNegativeSelection {
  FlutterTextInputView* inputView = [[FlutterTextInputView alloc] initWithOwner:textInputPlugin];

  [inputView.text setString:@"SELECTION"];
  inputView.markedTextRange = nil;
  inputView.selectedTextRange = nil;

  [inputView setTextInputState:@{
    @"text" : @"SELECTION",
    @"selectionBase" : @-1,
    @"selectionExtent" : @-1
  }];
  [inputView updateEditingState];
  OCMVerify([engine flutterTextInputView:inputView
                     updateEditingClient:0
                               withState:[OCMArg checkWithBlock:^BOOL(NSDictionary* state) {
                                 return ([state[@"selectionBase"] intValue]) == 0 &&
                                        ([state[@"selectionExtent"] intValue] == 0);
                               }]]);

  // Returns (0, 0) when either end goes below 0.
  [inputView
      setTextInputState:@{@"text" : @"SELECTION", @"selectionBase" : @-1, @"selectionExtent" : @1}];
  [inputView updateEditingState];
  OCMVerify([engine flutterTextInputView:inputView
                     updateEditingClient:0
                               withState:[OCMArg checkWithBlock:^BOOL(NSDictionary* state) {
                                 return ([state[@"selectionBase"] intValue]) == 0 &&
                                        ([state[@"selectionExtent"] intValue] == 0);
                               }]]);

  [inputView
      setTextInputState:@{@"text" : @"SELECTION", @"selectionBase" : @1, @"selectionExtent" : @-1}];
  [inputView updateEditingState];
  OCMVerify([engine flutterTextInputView:inputView
                     updateEditingClient:0
                               withState:[OCMArg checkWithBlock:^BOOL(NSDictionary* state) {
                                 return ([state[@"selectionBase"] intValue]) == 0 &&
                                        ([state[@"selectionExtent"] intValue] == 0);
                               }]]);
}

- (void)testUpdateEditingClientSelectionClamping {
  // Regression test for https://github.com/flutter/flutter/issues/62992.
  FlutterTextInputView* inputView = [[FlutterTextInputView alloc] initWithOwner:textInputPlugin];

  [inputView.text setString:@"SELECTION"];
  inputView.markedTextRange = nil;
  inputView.selectedTextRange = nil;

  [inputView
      setTextInputState:@{@"text" : @"SELECTION", @"selectionBase" : @0, @"selectionExtent" : @0}];
  [inputView updateEditingState];
  OCMVerify([engine flutterTextInputView:inputView
                     updateEditingClient:0
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

  OCMVerify([engine flutterTextInputView:inputView
                     updateEditingClient:0
                               withState:[OCMArg checkWithBlock:^BOOL(NSDictionary* state) {
                                 return ([state[@"selectionBase"] intValue]) == 0 &&
                                        ([state[@"selectionExtent"] intValue] == 9);
                               }]]);

  // No clamping needed, but in reverse direction.
  [inputView
      setTextInputState:@{@"text" : @"SELECTION", @"selectionBase" : @1, @"selectionExtent" : @0}];
  [inputView updateEditingState];
  OCMVerify([engine flutterTextInputView:inputView
                     updateEditingClient:0
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
  OCMVerify([engine flutterTextInputView:inputView
                     updateEditingClient:0
                               withState:[OCMArg checkWithBlock:^BOOL(NSDictionary* state) {
                                 return ([state[@"selectionBase"] intValue]) == 9 &&
                                        ([state[@"selectionExtent"] intValue] == 9);
                               }]]);
}

- (void)testInputViewsHasNonNilInputDelegate {
  if (@available(iOS 13.0, *)) {
    FlutterTextInputView* inputView = [[FlutterTextInputView alloc] initWithOwner:textInputPlugin];
    [UIApplication.sharedApplication.keyWindow addSubview:inputView];

    [inputView setTextInputClient:123];
    [inputView reloadInputViews];
    [inputView becomeFirstResponder];
    NSAssert(inputView.isFirstResponder, @"inputView is not first responder");
    inputView.inputDelegate = nil;

    FlutterTextInputView* mockInputView = OCMPartialMock(inputView);
    [mockInputView setTextInputState:@{
      @"text" : @"COMPOSING",
      @"composingBase" : @1,
      @"composingExtent" : @3
    }];
    OCMVerify([mockInputView setInputDelegate:[OCMArg isNotNil]]);
    [inputView removeFromSuperview];
  }
}

- (void)testInputViewsDoNotHaveUITextInteractions {
  if (@available(iOS 13.0, *)) {
    FlutterTextInputView* inputView = [[FlutterTextInputView alloc] initWithOwner:textInputPlugin];
    BOOL hasTextInteraction = NO;
    for (id interaction in inputView.interactions) {
      hasTextInteraction = [interaction isKindOfClass:[UITextInteraction class]];
      if (hasTextInteraction) {
        break;
      }
    }
    XCTAssertFalse(hasTextInteraction);
  }
}

#pragma mark - UITextInput methods - Tests

- (void)testUpdateFirstRectForRange {
  [self setClientId:123 configuration:self.mutableTemplateCopy];

  FlutterTextInputView* inputView = textInputPlugin.activeView;
  textInputPlugin.viewController.view.frame = CGRectMake(0, 0, 0, 0);

  [inputView
      setTextInputState:@{@"text" : @"COMPOSING", @"composingBase" : @1, @"composingExtent" : @3}];

  CGRect kInvalidFirstRect = CGRectMake(-1, -1, 9999, 9999);
  FlutterTextRange* range = [FlutterTextRange rangeWithNSRange:NSMakeRange(0, 1)];
  // yOffset = 200.
  NSArray* yOffsetMatrix = @[ @1, @0, @0, @0, @0, @1, @0, @0, @0, @0, @1, @0, @0, @200, @0, @1 ];
  NSArray* zeroMatrix = @[ @0, @0, @0, @0, @0, @0, @0, @0, @0, @0, @0, @0, @0, @0, @0, @0 ];
  // This matrix can be generated by running this dart code snippet:
  // Matrix4.identity()..scale(3.0)..rotateZ(math.pi/2)..translate(1.0, 2.0,
  // 3.0);
  NSArray* affineMatrix = @[
    @(0.0), @(3.0), @(0.0), @(0.0), @(-3.0), @(0.0), @(0.0), @(0.0), @(0.0), @(0.0), @(3.0), @(0.0),
    @(-6.0), @(3.0), @(9.0), @(1.0)
  ];

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

  // Use a 3d affine transform that does 3d-scaling, z-index rotating and 3d translation.
  [inputView setEditableTransform:affineMatrix];
  [inputView setMarkedRect:testRect];
  XCTAssertTrue(
      CGRectEqualToRect(CGRectMake(-306, 3, 300, 300), [inputView firstRectForRange:range]));

  NSAssert(inputView.superview, @"inputView is not in the view hierarchy!");
  const CGPoint offset = CGPointMake(113, 119);
  CGRect currentFrame = inputView.frame;
  currentFrame.origin = offset;
  inputView.frame = currentFrame;
  // Moving the input view within the FlutterView shouldn't affect the coordinates,
  // since the framework sends us global coordinates.
  XCTAssertTrue(CGRectEqualToRect(CGRectMake(-306 - 113, 3 - 119, 300, 300),
                                  [inputView firstRectForRange:range]));
}

- (void)testFirstRectForRangeReturnsCorrectSelectionRect {
  FlutterTextInputView* inputView = [[FlutterTextInputView alloc] initWithOwner:textInputPlugin];
  [inputView setTextInputState:@{@"text" : @"COMPOSING"}];

  FlutterTextRange* range = [FlutterTextRange rangeWithNSRange:NSMakeRange(1, 1)];
  CGRect testRect = CGRectMake(100, 100, 100, 100);
  [inputView setSelectionRects:@[
    [FlutterTextSelectionRect selectionRectWithRect:CGRectMake(0, 0, 100, 100) position:0U],
    [FlutterTextSelectionRect selectionRectWithRect:testRect position:1U],
    [FlutterTextSelectionRect selectionRectWithRect:CGRectMake(200, 200, 100, 100) position:2U],
  ]];
  XCTAssertTrue(CGRectEqualToRect(testRect, [inputView firstRectForRange:range]));

  [inputView setTextInputState:@{@"text" : @"COM"}];
  FlutterTextRange* rangeOutsideBounds = [FlutterTextRange rangeWithNSRange:NSMakeRange(3, 1)];
  XCTAssertTrue(CGRectEqualToRect(CGRectZero, [inputView firstRectForRange:rangeOutsideBounds]));
}

- (void)testClosestPositionToPoint {
  FlutterTextInputView* inputView = [[FlutterTextInputView alloc] initWithOwner:textInputPlugin];
  [inputView setTextInputState:@{@"text" : @"COMPOSING"}];

  // Minimize the vertical distance from the center of the rects first
  [inputView setSelectionRects:@[
    [FlutterTextSelectionRect selectionRectWithRect:CGRectMake(0, 0, 100, 100) position:0U],
    [FlutterTextSelectionRect selectionRectWithRect:CGRectMake(0, 100, 100, 100) position:1U],
    [FlutterTextSelectionRect selectionRectWithRect:CGRectMake(0, 200, 100, 100) position:2U],
  ]];
  CGPoint point = CGPointMake(150, 150);
  XCTAssertEqual(2U, ((FlutterTextPosition*)[inputView closestPositionToPoint:point]).index);
  XCTAssertEqual(UITextStorageDirectionBackward,
                 ((FlutterTextPosition*)[inputView closestPositionToPoint:point]).affinity);

  // Then, if the point is above the bottom of the closest rects vertically, get the closest x
  // origin
  [inputView setSelectionRects:@[
    [FlutterTextSelectionRect selectionRectWithRect:CGRectMake(0, 0, 100, 100) position:0U],
    [FlutterTextSelectionRect selectionRectWithRect:CGRectMake(0, 100, 100, 100) position:1U],
    [FlutterTextSelectionRect selectionRectWithRect:CGRectMake(100, 100, 100, 100) position:2U],
    [FlutterTextSelectionRect selectionRectWithRect:CGRectMake(200, 100, 100, 100) position:3U],
    [FlutterTextSelectionRect selectionRectWithRect:CGRectMake(0, 200, 100, 100) position:4U],
  ]];
  point = CGPointMake(125, 150);
  XCTAssertEqual(2U, ((FlutterTextPosition*)[inputView closestPositionToPoint:point]).index);
  XCTAssertEqual(UITextStorageDirectionForward,
                 ((FlutterTextPosition*)[inputView closestPositionToPoint:point]).affinity);

  // However, if the point is below the bottom of the closest rects vertically, get the position
  // farthest to the right
  [inputView setSelectionRects:@[
    [FlutterTextSelectionRect selectionRectWithRect:CGRectMake(0, 0, 100, 100) position:0U],
    [FlutterTextSelectionRect selectionRectWithRect:CGRectMake(0, 100, 100, 100) position:1U],
    [FlutterTextSelectionRect selectionRectWithRect:CGRectMake(100, 100, 100, 100) position:2U],
    [FlutterTextSelectionRect selectionRectWithRect:CGRectMake(200, 100, 100, 100) position:3U],
    [FlutterTextSelectionRect selectionRectWithRect:CGRectMake(0, 300, 100, 100) position:4U],
  ]];
  point = CGPointMake(125, 201);
  XCTAssertEqual(4U, ((FlutterTextPosition*)[inputView closestPositionToPoint:point]).index);
  XCTAssertEqual(UITextStorageDirectionBackward,
                 ((FlutterTextPosition*)[inputView closestPositionToPoint:point]).affinity);

  // Also check a point at the right edge of the last selection rect
  [inputView setSelectionRects:@[
    [FlutterTextSelectionRect selectionRectWithRect:CGRectMake(0, 0, 100, 100) position:0U],
    [FlutterTextSelectionRect selectionRectWithRect:CGRectMake(0, 100, 100, 100) position:1U],
    [FlutterTextSelectionRect selectionRectWithRect:CGRectMake(100, 100, 100, 100) position:2U],
    [FlutterTextSelectionRect selectionRectWithRect:CGRectMake(200, 100, 100, 100) position:3U],
  ]];
  point = CGPointMake(125, 250);
  XCTAssertEqual(4U, ((FlutterTextPosition*)[inputView closestPositionToPoint:point]).index);
  XCTAssertEqual(UITextStorageDirectionBackward,
                 ((FlutterTextPosition*)[inputView closestPositionToPoint:point]).affinity);

  // Minimize vertical distance if the difference is more than 1 point.
  [inputView setSelectionRects:@[
    [FlutterTextSelectionRect selectionRectWithRect:CGRectMake(0, 2, 100, 100) position:0U],
    [FlutterTextSelectionRect selectionRectWithRect:CGRectMake(100, 2, 100, 100) position:1U],
    [FlutterTextSelectionRect selectionRectWithRect:CGRectMake(200, 0, 100, 100) position:2U],
  ]];
  point = CGPointMake(110, 50);
  XCTAssertEqual(2U, ((FlutterTextPosition*)[inputView closestPositionToPoint:point]).index);
  XCTAssertEqual(UITextStorageDirectionForward,
                 ((FlutterTextPosition*)[inputView closestPositionToPoint:point]).affinity);

  // In floating cursor mode, the vertical difference is allowed to be 10 points.
  // The closest horizontal position will now win.
  [inputView beginFloatingCursorAtPoint:CGPointZero];
  XCTAssertEqual(1U, ((FlutterTextPosition*)[inputView closestPositionToPoint:point]).index);
  XCTAssertEqual(UITextStorageDirectionForward,
                 ((FlutterTextPosition*)[inputView closestPositionToPoint:point]).affinity);
  [inputView endFloatingCursor];
}

- (void)testClosestPositionToPointRTL {
  FlutterTextInputView* inputView = [[FlutterTextInputView alloc] initWithOwner:textInputPlugin];
  [inputView setTextInputState:@{@"text" : @"COMPOSING"}];

  [inputView setSelectionRects:@[
    [FlutterTextSelectionRect selectionRectWithRect:CGRectMake(200, 0, 100, 100)
                                           position:0U
                                   writingDirection:NSWritingDirectionRightToLeft],
    [FlutterTextSelectionRect selectionRectWithRect:CGRectMake(100, 0, 100, 100)
                                           position:1U
                                   writingDirection:NSWritingDirectionRightToLeft],
    [FlutterTextSelectionRect selectionRectWithRect:CGRectMake(0, 0, 100, 100)
                                           position:2U
                                   writingDirection:NSWritingDirectionRightToLeft],
    [FlutterTextSelectionRect selectionRectWithRect:CGRectMake(0, 100, 100, 100)
                                           position:3U
                                   writingDirection:NSWritingDirectionRightToLeft],
  ]];
  FlutterTextPosition* position =
      (FlutterTextPosition*)[inputView closestPositionToPoint:CGPointMake(275, 50)];
  XCTAssertEqual(0U, position.index);
  XCTAssertEqual(UITextStorageDirectionForward, position.affinity);
  position = (FlutterTextPosition*)[inputView closestPositionToPoint:CGPointMake(225, 50)];
  XCTAssertEqual(1U, position.index);
  XCTAssertEqual(UITextStorageDirectionBackward, position.affinity);
  position = (FlutterTextPosition*)[inputView closestPositionToPoint:CGPointMake(175, 50)];
  XCTAssertEqual(1U, position.index);
  XCTAssertEqual(UITextStorageDirectionForward, position.affinity);
  position = (FlutterTextPosition*)[inputView closestPositionToPoint:CGPointMake(125, 50)];
  XCTAssertEqual(2U, position.index);
  XCTAssertEqual(UITextStorageDirectionBackward, position.affinity);
  position = (FlutterTextPosition*)[inputView closestPositionToPoint:CGPointMake(75, 50)];
  XCTAssertEqual(2U, position.index);
  XCTAssertEqual(UITextStorageDirectionForward, position.affinity);
  position = (FlutterTextPosition*)[inputView closestPositionToPoint:CGPointMake(25, 50)];
  XCTAssertEqual(3U, position.index);
  XCTAssertEqual(UITextStorageDirectionBackward, position.affinity);
  position = (FlutterTextPosition*)[inputView closestPositionToPoint:CGPointMake(-25, 50)];
  XCTAssertEqual(3U, position.index);
  XCTAssertEqual(UITextStorageDirectionBackward, position.affinity);
}

- (void)testSelectionRectsForRange {
  FlutterTextInputView* inputView = [[FlutterTextInputView alloc] initWithOwner:textInputPlugin];
  [inputView setTextInputState:@{@"text" : @"COMPOSING"}];

  CGRect testRect0 = CGRectMake(100, 100, 100, 100);
  CGRect testRect1 = CGRectMake(200, 200, 100, 100);
  [inputView setSelectionRects:@[
    [FlutterTextSelectionRect selectionRectWithRect:CGRectMake(0, 0, 100, 100) position:0U],
    [FlutterTextSelectionRect selectionRectWithRect:testRect0 position:1U],
    [FlutterTextSelectionRect selectionRectWithRect:testRect1 position:2U],
    [FlutterTextSelectionRect selectionRectWithRect:CGRectMake(300, 300, 100, 100) position:3U],
  ]];

  // Returns the matching rects within a range
  FlutterTextRange* range = [FlutterTextRange rangeWithNSRange:NSMakeRange(1, 2)];
  XCTAssertTrue(CGRectEqualToRect(testRect0, [inputView selectionRectsForRange:range][0].rect));
  XCTAssertTrue(CGRectEqualToRect(testRect1, [inputView selectionRectsForRange:range][1].rect));
  XCTAssertEqual(2U, [[inputView selectionRectsForRange:range] count]);

  // Returns a 0 width rect for a 0-length range
  range = [FlutterTextRange rangeWithNSRange:NSMakeRange(1, 0)];
  XCTAssertEqual(1U, [[inputView selectionRectsForRange:range] count]);
  XCTAssertTrue(CGRectEqualToRect(
      CGRectMake(testRect0.origin.x, testRect0.origin.y, 0, testRect0.size.height),
      [inputView selectionRectsForRange:range][0].rect));
}

- (void)testClosestPositionToPointWithinRange {
  FlutterTextInputView* inputView = [[FlutterTextInputView alloc] initWithOwner:textInputPlugin];
  [inputView setTextInputState:@{@"text" : @"COMPOSING"}];

  // Do not return a position before the start of the range
  [inputView setSelectionRects:@[
    [FlutterTextSelectionRect selectionRectWithRect:CGRectMake(0, 0, 100, 100) position:0U],
    [FlutterTextSelectionRect selectionRectWithRect:CGRectMake(0, 100, 100, 100) position:1U],
    [FlutterTextSelectionRect selectionRectWithRect:CGRectMake(100, 100, 100, 100) position:2U],
    [FlutterTextSelectionRect selectionRectWithRect:CGRectMake(200, 100, 100, 100) position:3U],
    [FlutterTextSelectionRect selectionRectWithRect:CGRectMake(0, 200, 100, 100) position:4U],
  ]];
  CGPoint point = CGPointMake(125, 150);
  FlutterTextRange* range = [[FlutterTextRange rangeWithNSRange:NSMakeRange(3, 2)] copy];
  XCTAssertEqual(
      3U, ((FlutterTextPosition*)[inputView closestPositionToPoint:point withinRange:range]).index);
  XCTAssertEqual(
      UITextStorageDirectionForward,
      ((FlutterTextPosition*)[inputView closestPositionToPoint:point withinRange:range]).affinity);

  // Do not return a position after the end of the range
  [inputView setSelectionRects:@[
    [FlutterTextSelectionRect selectionRectWithRect:CGRectMake(0, 0, 100, 100) position:0U],
    [FlutterTextSelectionRect selectionRectWithRect:CGRectMake(0, 100, 100, 100) position:1U],
    [FlutterTextSelectionRect selectionRectWithRect:CGRectMake(100, 100, 100, 100) position:2U],
    [FlutterTextSelectionRect selectionRectWithRect:CGRectMake(200, 100, 100, 100) position:3U],
    [FlutterTextSelectionRect selectionRectWithRect:CGRectMake(0, 200, 100, 100) position:4U],
  ]];
  point = CGPointMake(125, 150);
  range = [[FlutterTextRange rangeWithNSRange:NSMakeRange(0, 1)] copy];
  XCTAssertEqual(
      1U, ((FlutterTextPosition*)[inputView closestPositionToPoint:point withinRange:range]).index);
  XCTAssertEqual(
      UITextStorageDirectionForward,
      ((FlutterTextPosition*)[inputView closestPositionToPoint:point withinRange:range]).affinity);
}

#pragma mark - Floating Cursor - Tests

- (void)testFloatingCursorDoesNotThrow {
  // The keyboard implementation may send unbalanced calls to the input view.
  FlutterTextInputView* inputView = [[FlutterTextInputView alloc] initWithOwner:textInputPlugin];
  [inputView beginFloatingCursorAtPoint:CGPointMake(123, 321)];
  [inputView beginFloatingCursorAtPoint:CGPointMake(123, 321)];
  [inputView endFloatingCursor];
  [inputView beginFloatingCursorAtPoint:CGPointMake(123, 321)];
  [inputView endFloatingCursor];
}

- (void)testFloatingCursor {
  FlutterTextInputView* inputView = [[FlutterTextInputView alloc] initWithOwner:textInputPlugin];
  [inputView setTextInputState:@{
    @"text" : @"test",
    @"selectionBase" : @1,
    @"selectionExtent" : @1,
  }];

  FlutterTextSelectionRect* first =
      [FlutterTextSelectionRect selectionRectWithRect:CGRectMake(0, 0, 100, 100) position:0U];
  FlutterTextSelectionRect* second =
      [FlutterTextSelectionRect selectionRectWithRect:CGRectMake(100, 100, 100, 100) position:1U];
  FlutterTextSelectionRect* third =
      [FlutterTextSelectionRect selectionRectWithRect:CGRectMake(200, 200, 100, 100) position:2U];
  FlutterTextSelectionRect* fourth =
      [FlutterTextSelectionRect selectionRectWithRect:CGRectMake(300, 300, 100, 100) position:3U];
  [inputView setSelectionRects:@[ first, second, third, fourth ]];

  // Verify zeroth caret rect is based on left edge of first character.
  XCTAssertTrue(CGRectEqualToRect(
      [inputView caretRectForPosition:[FlutterTextPosition
                                          positionWithIndex:0
                                                   affinity:UITextStorageDirectionForward]],
      CGRectMake(0, 0, 0, 100)));
  // Since the textAffinity is downstream, the caret rect will be based on the
  // left edge of the succeeding character.
  XCTAssertTrue(CGRectEqualToRect(
      [inputView caretRectForPosition:[FlutterTextPosition
                                          positionWithIndex:1
                                                   affinity:UITextStorageDirectionForward]],
      CGRectMake(100, 100, 0, 100)));
  XCTAssertTrue(CGRectEqualToRect(
      [inputView caretRectForPosition:[FlutterTextPosition
                                          positionWithIndex:2
                                                   affinity:UITextStorageDirectionForward]],
      CGRectMake(200, 200, 0, 100)));
  XCTAssertTrue(CGRectEqualToRect(
      [inputView caretRectForPosition:[FlutterTextPosition
                                          positionWithIndex:3
                                                   affinity:UITextStorageDirectionForward]],
      CGRectMake(300, 300, 0, 100)));
  // There is no subsequent character for the last position, so the caret rect
  // will be based on the right edge of the preceding character.
  XCTAssertTrue(CGRectEqualToRect(
      [inputView caretRectForPosition:[FlutterTextPosition
                                          positionWithIndex:4
                                                   affinity:UITextStorageDirectionForward]],
      CGRectMake(400, 300, 0, 100)));
  // Verify no caret rect for out-of-range character.
  XCTAssertTrue(CGRectEqualToRect(
      [inputView caretRectForPosition:[FlutterTextPosition
                                          positionWithIndex:5
                                                   affinity:UITextStorageDirectionForward]],
      CGRectZero));

  // Check caret rects again again when text affinity is upstream.
  [inputView setTextInputState:@{
    @"text" : @"test",
    @"selectionBase" : @2,
    @"selectionExtent" : @2,
  }];
  // Verify zeroth caret rect is based on left edge of first character.
  XCTAssertTrue(CGRectEqualToRect(
      [inputView caretRectForPosition:[FlutterTextPosition
                                          positionWithIndex:0
                                                   affinity:UITextStorageDirectionBackward]],
      CGRectMake(0, 0, 0, 100)));
  // Since the textAffinity is upstream, all below caret rects will be based on
  // the right edge of the preceding character.
  XCTAssertTrue(CGRectEqualToRect(
      [inputView caretRectForPosition:[FlutterTextPosition
                                          positionWithIndex:1
                                                   affinity:UITextStorageDirectionBackward]],
      CGRectMake(100, 0, 0, 100)));
  XCTAssertTrue(CGRectEqualToRect(
      [inputView caretRectForPosition:[FlutterTextPosition
                                          positionWithIndex:2
                                                   affinity:UITextStorageDirectionBackward]],
      CGRectMake(200, 100, 0, 100)));
  XCTAssertTrue(CGRectEqualToRect(
      [inputView caretRectForPosition:[FlutterTextPosition
                                          positionWithIndex:3
                                                   affinity:UITextStorageDirectionBackward]],
      CGRectMake(300, 200, 0, 100)));
  XCTAssertTrue(CGRectEqualToRect(
      [inputView caretRectForPosition:[FlutterTextPosition
                                          positionWithIndex:4
                                                   affinity:UITextStorageDirectionBackward]],
      CGRectMake(400, 300, 0, 100)));
  // Verify no caret rect for out-of-range character.
  XCTAssertTrue(CGRectEqualToRect(
      [inputView caretRectForPosition:[FlutterTextPosition
                                          positionWithIndex:5
                                                   affinity:UITextStorageDirectionBackward]],
      CGRectZero));

  // Verify floating cursor updates are relative to original position, and that there is no bounds
  // change.
  CGRect initialBounds = inputView.bounds;
  [inputView beginFloatingCursorAtPoint:CGPointMake(123, 321)];
  XCTAssertTrue(CGRectEqualToRect(initialBounds, inputView.bounds));
  OCMVerify([engine flutterTextInputView:inputView
                    updateFloatingCursor:FlutterFloatingCursorDragStateStart
                              withClient:0
                            withPosition:[OCMArg checkWithBlock:^BOOL(NSDictionary* state) {
                              return ([state[@"X"] isEqualToNumber:@(0)]) &&
                                     ([state[@"Y"] isEqualToNumber:@(0)]);
                            }]]);

  [inputView updateFloatingCursorAtPoint:CGPointMake(456, 654)];
  XCTAssertTrue(CGRectEqualToRect(initialBounds, inputView.bounds));
  OCMVerify([engine flutterTextInputView:inputView
                    updateFloatingCursor:FlutterFloatingCursorDragStateUpdate
                              withClient:0
                            withPosition:[OCMArg checkWithBlock:^BOOL(NSDictionary* state) {
                              return ([state[@"X"] isEqualToNumber:@(333)]) &&
                                     ([state[@"Y"] isEqualToNumber:@(333)]);
                            }]]);

  [inputView endFloatingCursor];
  XCTAssertTrue(CGRectEqualToRect(initialBounds, inputView.bounds));
  OCMVerify([engine flutterTextInputView:inputView
                    updateFloatingCursor:FlutterFloatingCursorDragStateEnd
                              withClient:0
                            withPosition:[OCMArg checkWithBlock:^BOOL(NSDictionary* state) {
                              return ([state[@"X"] isEqualToNumber:@(0)]) &&
                                     ([state[@"Y"] isEqualToNumber:@(0)]);
                            }]]);
}

#pragma mark - UIKeyInput Overrides - Tests

- (void)testInsertTextAddsPlaceholderSelectionRects {
  FlutterTextInputView* inputView = [[FlutterTextInputView alloc] initWithOwner:textInputPlugin];
  [inputView
      setTextInputState:@{@"text" : @"test", @"selectionBase" : @1, @"selectionExtent" : @1}];

  FlutterTextSelectionRect* first =
      [FlutterTextSelectionRect selectionRectWithRect:CGRectMake(0, 0, 100, 100) position:0U];
  FlutterTextSelectionRect* second =
      [FlutterTextSelectionRect selectionRectWithRect:CGRectMake(100, 100, 100, 100) position:1U];
  FlutterTextSelectionRect* third =
      [FlutterTextSelectionRect selectionRectWithRect:CGRectMake(200, 200, 100, 100) position:2U];
  FlutterTextSelectionRect* fourth =
      [FlutterTextSelectionRect selectionRectWithRect:CGRectMake(300, 300, 100, 100) position:3U];
  [inputView setSelectionRects:@[ first, second, third, fourth ]];

  // Inserts additional selection rects at the selection start
  [inputView insertText:@"in"];
  NSArray* selectionRects =
      [inputView selectionRectsForRange:[FlutterTextRange rangeWithNSRange:NSMakeRange(0, 6)]];
  XCTAssertEqual(6U, [selectionRects count]);

  XCTAssertEqual(first.position, ((FlutterTextSelectionRect*)selectionRects[0]).position);
  XCTAssertTrue(CGRectEqualToRect(first.rect, ((FlutterTextSelectionRect*)selectionRects[0]).rect));

  XCTAssertEqual(second.position, ((FlutterTextSelectionRect*)selectionRects[1]).position);
  XCTAssertTrue(
      CGRectEqualToRect(second.rect, ((FlutterTextSelectionRect*)selectionRects[1]).rect));

  XCTAssertEqual(second.position + 1, ((FlutterTextSelectionRect*)selectionRects[2]).position);
  XCTAssertTrue(
      CGRectEqualToRect(second.rect, ((FlutterTextSelectionRect*)selectionRects[2]).rect));

  XCTAssertEqual(second.position + 2, ((FlutterTextSelectionRect*)selectionRects[3]).position);
  XCTAssertTrue(
      CGRectEqualToRect(second.rect, ((FlutterTextSelectionRect*)selectionRects[3]).rect));

  XCTAssertEqual(third.position + 2, ((FlutterTextSelectionRect*)selectionRects[4]).position);
  XCTAssertTrue(CGRectEqualToRect(third.rect, ((FlutterTextSelectionRect*)selectionRects[4]).rect));

  XCTAssertEqual(fourth.position + 2, ((FlutterTextSelectionRect*)selectionRects[5]).position);
  XCTAssertTrue(
      CGRectEqualToRect(fourth.rect, ((FlutterTextSelectionRect*)selectionRects[5]).rect));
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

- (void)testDisablingAutofillOnInputClient {
  NSDictionary* config = self.mutableTemplateCopy;
  [config setValue:@"YES" forKey:@"obscureText"];

  [self setClientId:123 configuration:config];

  FlutterTextInputView* inputView = self.installedInputViews[0];
  XCTAssertEqualObjects(inputView.textContentType, @"");
}

- (void)testAutofillEnabledByDefault {
  NSDictionary* config = self.mutableTemplateCopy;
  [config setValue:@"NO" forKey:@"obscureText"];
  [config setValue:@{@"uniqueIdentifier" : @"field1", @"editingValue" : @{@"text" : @""}}
            forKey:@"autofill"];

  [self setClientId:123 configuration:config];

  FlutterTextInputView* inputView = self.installedInputViews[0];
  XCTAssertNil(inputView.textContentType);
}

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
  OCMVerify([engine flutterTextInputView:inactiveView
                     updateEditingClient:0
                               withState:[OCMArg isNotNil]
                                 withTag:@"field2"]);
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

- (void)testScribbleSetSelectionRects {
  NSMutableDictionary* regularField = self.mutableTemplateCopy;
  NSDictionary* editingValue = @{
    @"text" : @"REGULAR_TEXT_FIELD",
    @"composingBase" : @0,
    @"composingExtent" : @3,
    @"selectionBase" : @1,
    @"selectionExtent" : @4
  };
  [regularField setValue:@{
    @"uniqueIdentifier" : @"field1",
    @"hints" : @[ @"hint2" ],
    @"editingValue" : editingValue,
  }
                  forKey:@"autofill"];
  [regularField addEntriesFromDictionary:editingValue];
  [self setClientId:123 configuration:regularField];
  XCTAssertEqual(self.installedInputViews.count, 1ul);
  XCTAssertEqual([textInputPlugin.activeView.selectionRects count], 0u);

  NSArray<NSNumber*>* selectionRect = [NSArray arrayWithObjects:@0, @0, @100, @100, @0, @1, nil];
  NSArray* selectionRects = [NSArray arrayWithObjects:selectionRect, nil];
  FlutterMethodCall* methodCall =
      [FlutterMethodCall methodCallWithMethodName:@"Scribble.setSelectionRects"
                                        arguments:selectionRects];
  [textInputPlugin handleMethodCall:methodCall
                             result:^(id _Nullable result){
                             }];

  XCTAssertEqual([textInputPlugin.activeView.selectionRects count], 1u);
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
  // Before the framework sends the first text input configuration,
  // the dummy "activeView" we use should never have access to
  // its textInputDelegate.
  XCTAssertNil(textInputPlugin.activeView.textInputDelegate);
}

#pragma mark - Accessibility - Tests

- (void)testUITextInputAccessibilityNotHiddenWhenShowed {
  [self setClientId:123 configuration:self.mutableTemplateCopy];

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
  FlutterTextInputViewSpy* inputView =
      [[FlutterTextInputViewSpy alloc] initWithOwner:textInputPlugin];
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
  FlutterTextInputView* inputView = [[FlutterTextInputView alloc] initWithOwner:textInputPlugin];
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
  FlutterViewController* flutterViewController = [[FlutterViewController alloc] init];
  FlutterTextInputPlugin* myInputPlugin = [[FlutterTextInputPlugin alloc] initWithDelegate:engine];
  myInputPlugin.viewController = flutterViewController;

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

- (void)testFlutterTextInputPluginHostViewNilCrash {
  FlutterTextInputPlugin* myInputPlugin = [[FlutterTextInputPlugin alloc] initWithDelegate:engine];
  myInputPlugin.viewController = nil;
  XCTAssertThrows([myInputPlugin hostView], @"Throws exception if host view is nil");
}

- (void)testFlutterTextInputPluginHostViewNotNil {
  FlutterViewController* flutterViewController = [[FlutterViewController alloc] init];
  FlutterEngine* flutterEngine = [[FlutterEngine alloc] init];
  [flutterEngine runWithEntrypoint:nil];
  flutterEngine.viewController = flutterViewController;
  XCTAssertNotNil(flutterEngine.textInputPlugin.viewController);
  XCTAssertNotNil([flutterEngine.textInputPlugin hostView]);
}

- (void)testSetPlatformViewClient {
  FlutterViewController* flutterViewController = [[FlutterViewController alloc] init];
  FlutterTextInputPlugin* myInputPlugin = [[FlutterTextInputPlugin alloc] initWithDelegate:engine];
  myInputPlugin.viewController = flutterViewController;

  FlutterMethodCall* setClientCall = [FlutterMethodCall
      methodCallWithMethodName:@"TextInput.setClient"
                     arguments:@[ [NSNumber numberWithInt:123], self.mutablePasswordTemplateCopy ]];
  [myInputPlugin handleMethodCall:setClientCall
                           result:^(id _Nullable result){
                           }];
  UIView* activeView = myInputPlugin.textInputView;
  XCTAssertNotNil(activeView.superview, @"activeView must be added to the view hierarchy.");
  FlutterMethodCall* setPlatformViewClientCall = [FlutterMethodCall
      methodCallWithMethodName:@"TextInput.setPlatformViewClient"
                     arguments:@{@"platformViewId" : [NSNumber numberWithLong:456]}];
  [myInputPlugin handleMethodCall:setPlatformViewClientCall
                           result:^(id _Nullable result){
                           }];
  XCTAssertNil(activeView.superview, @"activeView must be removed from view hierarchy.");
}

@end
