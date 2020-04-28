// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "TextSemanticsFocusTest.h"

FLUTTER_ASSERT_ARC

@interface XCUIElement (ftr_waitForNonExistence)
/// Keeps waiting until the element doesn't exist.  Returns NO if the timeout is
/// reached before it doesn't exist.
- (BOOL)ftr_waitForNonExistenceWithTimeout:(NSTimeInterval)timeout;
/// Waits the full duration to ensure something doesn't exist for that duration.
/// Returns NO if at some point the element exists during the duration.
- (BOOL)ftr_waitForNonExistenceForDuration:(NSTimeInterval)duration;
@end

@implementation XCUIElement (ftr_waitForNonExistence)
- (BOOL)ftr_waitForNonExistenceWithTimeout:(NSTimeInterval)timeout {
  NSTimeInterval delta = 0.5;
  while (timeout > 0.0) {
    if (!self.exists) {
      return YES;
    }
    usleep(delta * 1000000);
    timeout -= delta;
  }
  return NO;
}

- (BOOL)ftr_waitForNonExistenceForDuration:(NSTimeInterval)duration {
  return ![self waitForExistenceWithTimeout:duration];
}

@end

@implementation TextSemanticsFocusTest

- (void)setUp {
  [super setUp];
  self.continueAfterFailure = NO;

  self.application = [[XCUIApplication alloc] init];
  self.application.launchArguments = @[ @"--text-semantics-focus" ];
  [self.application launch];
}

- (void)skip_testAccessibilityFocusOnTextSemanticsProducesCorrectIosViews {
  NSTimeInterval timeout = 10.0;
  // Find the initial TextInputSemanticsObject which was sent from the mock framework on first
  // frame.
  XCUIElement* textInputSemanticsObject =
      [[[self.application textFields] matchingIdentifier:@"flutter textfield"] element];
  XCTAssertTrue([textInputSemanticsObject waitForExistenceWithTimeout:timeout]);
  XCTAssertEqualObjects([textInputSemanticsObject valueForKey:@"hasKeyboardFocus"], @(NO));

  // Since the first mock framework text field isn't focused on, it shouldn't produce a UITextInput
  // in the view hierarchy.
  XCUIElement* delegateTextInput = [[self.application textViews] element];
  XCTAssertTrue([delegateTextInput ftr_waitForNonExistenceWithTimeout:timeout]);

  // Nor should there be a keyboard for text entry.
  XCUIElement* keyboard = [[self.application keyboards] element];
  XCTAssertTrue([keyboard ftr_waitForNonExistenceWithTimeout:timeout]);

  // The tap location doesn't matter. The mock framework just sends a focused text field on tap.
  [textInputSemanticsObject tap];

  // The new TextInputSemanticsObject now has keyboard focus (the only trait accessible through
  // UI tests on a XCUIElement).
  textInputSemanticsObject =
      [[[self.application textFields] matchingIdentifier:@"focused flutter textfield"] element];
  XCTAssertTrue([textInputSemanticsObject waitForExistenceWithTimeout:timeout]);
  XCTAssertEqualObjects([textInputSemanticsObject valueForKey:@"hasKeyboardFocus"], @(YES));

  // The delegate UITextInput is also inserted on the window but we make only the
  // TextInputSemanticsObject visible and not the FlutterTextInputView to avoid confusing
  // accessibility, it shouldn't be visible to the UI test either.
  delegateTextInput = [[self.application textViews] element];
  XCTAssertTrue([delegateTextInput ftr_waitForNonExistenceForDuration:3.0]);

  // But since there is focus, the soft keyboard is visible on the simulator.
  keyboard = [[self.application keyboards] element];
  XCTAssertTrue([keyboard waitForExistenceWithTimeout:timeout]);
}

@end
