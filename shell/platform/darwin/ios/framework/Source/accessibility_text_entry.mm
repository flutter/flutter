// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

#include "flutter/shell/platform/darwin/ios/framework/Source/accessibility_bridge.h"
#include "flutter/shell/platform/darwin/ios/framework/Source/accessibility_text_entry.h"

@implementation FlutterInactiveTextInput {
}

@synthesize tokenizer = _tokenizer;
@synthesize beginningOfDocument = _beginningOfDocument;
@synthesize endOfDocument = _endOfDocument;

- (instancetype)init {
  return [super init];
}

- (BOOL)hasText {
  return self.text.length > 0;
}

- (NSString*)textInRange:(UITextRange*)range {
  NSRange textRange = ((FlutterTextRange*)range).range;
  return [self.text substringWithRange:textRange];
}

- (void)replaceRange:(UITextRange*)range withText:(NSString*)text {
  // This method is required but not called by accessibility API for
  // features we are using it for. It may need to be implemented if
  // requirements change.
}

- (void)setMarkedText:(NSString*)markedText selectedRange:(NSRange)markedSelectedRange {
  // This method is required but not called by accessibility API for
  // features we are using it for. It may need to be implemented if
  // requirements change.
}

- (void)unmarkText {
  // This method is required but not called by accessibility API for
  // features we are using it for. It may need to be implemented if
  // requirements change.
}

- (UITextRange*)textRangeFromPosition:(UITextPosition*)fromPosition
                           toPosition:(UITextPosition*)toPosition {
  NSUInteger fromIndex = ((FlutterTextPosition*)fromPosition).index;
  NSUInteger toIndex = ((FlutterTextPosition*)toPosition).index;
  return [FlutterTextRange rangeWithNSRange:NSMakeRange(fromIndex, toIndex - fromIndex)];
}

- (UITextPosition*)positionFromPosition:(UITextPosition*)position offset:(NSInteger)offset {
  // This method is required but not called by accessibility API for
  // features we are using it for. It may need to be implemented if
  // requirements change.
  return nil;
}

- (UITextPosition*)positionFromPosition:(UITextPosition*)position
                            inDirection:(UITextLayoutDirection)direction
                                 offset:(NSInteger)offset {
  // This method is required but not called by accessibility API for
  // features we are using it for. It may need to be implemented if
  // requirements change.
  return nil;
}

- (NSComparisonResult)comparePosition:(UITextPosition*)position toPosition:(UITextPosition*)other {
  // This method is required but not called by accessibility API for
  // features we are using it for. It may need to be implemented if
  // requirements change.
  return NSOrderedSame;
}

- (NSInteger)offsetFromPosition:(UITextPosition*)from toPosition:(UITextPosition*)toPosition {
  // This method is required but not called by accessibility API for
  // features we are using it for. It may need to be implemented if
  // requirements change.
  return 0;
}

- (UITextPosition*)positionWithinRange:(UITextRange*)range
                   farthestInDirection:(UITextLayoutDirection)direction {
  // This method is required but not called by accessibility API for
  // features we are using it for. It may need to be implemented if
  // requirements change.
  return nil;
}

- (UITextRange*)characterRangeByExtendingPosition:(UITextPosition*)position
                                      inDirection:(UITextLayoutDirection)direction {
  // This method is required but not called by accessibility API for
  // features we are using it for. It may need to be implemented if
  // requirements change.
  return nil;
}

- (UITextWritingDirection)baseWritingDirectionForPosition:(UITextPosition*)position
                                              inDirection:(UITextStorageDirection)direction {
  // Not editable. Does not apply.
  return UITextWritingDirectionNatural;
}

- (void)setBaseWritingDirection:(UITextWritingDirection)writingDirection
                       forRange:(UITextRange*)range {
  // Not editable. Does not apply.
}

- (CGRect)firstRectForRange:(UITextRange*)range {
  // This method is required but not called by accessibility API for
  // features we are using it for. It may need to be implemented if
  // requirements change.
  return CGRectZero;
}

- (CGRect)caretRectForPosition:(UITextPosition*)position {
  // This method is required but not called by accessibility API for
  // features we are using it for. It may need to be implemented if
  // requirements change.
  return CGRectZero;
}

- (UITextPosition*)closestPositionToPoint:(CGPoint)point {
  // This method is required but not called by accessibility API for
  // features we are using it for. It may need to be implemented if
  // requirements change.
  return nil;
}

- (UITextPosition*)closestPositionToPoint:(CGPoint)point withinRange:(UITextRange*)range {
  // This method is required but not called by accessibility API for
  // features we are using it for. It may need to be implemented if
  // requirements change.
  return nil;
}

- (NSArray*)selectionRectsForRange:(UITextRange*)range {
  // This method is required but not called by accessibility API for
  // features we are using it for. It may need to be implemented if
  // requirements change.
  return @[];
}

- (UITextRange*)characterRangeAtPoint:(CGPoint)point {
  // This method is required but not called by accessibility API for
  // features we are using it for. It may need to be implemented if
  // requirements change.
  return nil;
}

- (void)insertText:(NSString*)text {
  // This method is required but not called by accessibility API for
  // features we are using it for. It may need to be implemented if
  // requirements change.
}

- (void)deleteBackward {
  // This method is required but not called by accessibility API for
  // features we are using it for. It may need to be implemented if
  // requirements change.
}

@end

@implementation TextInputSemanticsObject {
  FlutterInactiveTextInput* _inactive_text_input;
}

- (instancetype)initWithBridge:(fml::WeakPtr<shell::AccessibilityBridge>)bridge uid:(int32_t)uid {
  self = [super initWithBridge:bridge uid:uid];

  if (self) {
    _inactive_text_input = [[FlutterInactiveTextInput alloc] init];
  }

  return self;
}

- (void)dealloc {
  [_inactive_text_input release];
  [super dealloc];
}

#pragma mark - SemanticsObject overrides

- (void)setSemanticsNode:(const blink::SemanticsNode*)node {
  [super setSemanticsNode:node];
  _inactive_text_input.text = @(node->value.data());
  if ([self node].HasFlag(blink::SemanticsFlags::kIsFocused)) {
    // The text input view must have a non-trivial size for the accessibility
    // system to send text editing events.
    [self bridge] -> textInputView().frame = CGRectMake(0.0, 0.0, 1.0, 1.0);
  }
}

#pragma mark - UIAccessibility overrides

/**
 * The UITextInput whose accessibility properties we present to UIKit as
 * substitutes for Flutter's text field properties.
 *
 * When the field is currently focused (i.e. it is being edited), we use
 * the FlutterTextInputView used by FlutterTextInputPlugin. Otherwise,
 * we use an FlutterInactiveTextInput.
 */
- (UIView<UITextInput>*)textInputSurrogate {
  if ([self node].HasFlag(blink::SemanticsFlags::kIsFocused)) {
    return [self bridge] -> textInputView();
  } else {
    return _inactive_text_input;
  }
}

- (UIView*)textInputView {
  return [self textInputSurrogate];
}

- (void)accessibilityElementDidBecomeFocused {
  [[self textInputSurrogate] accessibilityElementDidBecomeFocused];
  [super accessibilityElementDidBecomeFocused];
}

- (void)accessibilityElementDidLoseFocus {
  [[self textInputSurrogate] accessibilityElementDidLoseFocus];
  [super accessibilityElementDidLoseFocus];
}

- (BOOL)accessibilityElementIsFocused {
  return [self node].HasFlag(blink::SemanticsFlags::kIsFocused);
}

- (BOOL)accessibilityActivate {
  return [[self textInputSurrogate] accessibilityActivate];
}

- (NSString*)accessibilityLabel {
  NSString* label = [super accessibilityLabel];
  if (label != nil)
    return label;
  return [self textInputSurrogate].accessibilityLabel;
}

- (NSString*)accessibilityHint {
  NSString* hint = [super accessibilityHint];
  if (hint != nil)
    return hint;
  return [self textInputSurrogate].accessibilityHint;
}

- (NSString*)accessibilityValue {
  NSString* value = [super accessibilityValue];
  if (value != nil)
    return value;
  return [self textInputSurrogate].accessibilityValue;
}

- (UIAccessibilityTraits)accessibilityTraits {
  // Adding UIAccessibilityTraitKeyboardKey to the trait list so that iOS treats it like
  // a keyboard entry control, thus adding support for text editing features, such as
  // pinch to select text, and up/down fling to move cursor.
  return [super accessibilityTraits] | [self textInputSurrogate].accessibilityTraits |
         UIAccessibilityTraitKeyboardKey;
}

#pragma mark - UITextInput overrides

- (NSString*)textInRange:(UITextRange*)range {
  return [[self textInputSurrogate] textInRange:range];
}

- (void)replaceRange:(UITextRange*)range withText:(NSString*)text {
  return [[self textInputSurrogate] replaceRange:range withText:text];
}

- (BOOL)shouldChangeTextInRange:(UITextRange*)range replacementText:(NSString*)text {
  return [[self textInputSurrogate] shouldChangeTextInRange:range replacementText:text];
}

- (UITextRange*)selectedTextRange {
  return [[self textInputSurrogate] selectedTextRange];
}

- (void)setSelectedTextRange:(UITextRange*)range {
  [[self textInputSurrogate] setSelectedTextRange:range];
}

- (UITextRange*)markedTextRange {
  return [[self textInputSurrogate] markedTextRange];
}

- (NSDictionary*)markedTextStyle {
  return [[self textInputSurrogate] markedTextStyle];
}

- (void)setMarkedTextStyle:(NSDictionary*)style {
  [[self textInputSurrogate] setMarkedTextStyle:style];
}

- (void)setMarkedText:(NSString*)markedText selectedRange:(NSRange)selectedRange {
  [[self textInputSurrogate] setMarkedText:markedText selectedRange:selectedRange];
}

- (void)unmarkText {
  [[self textInputSurrogate] unmarkText];
}

- (UITextStorageDirection)selectionAffinity {
  return [[self textInputSurrogate] selectionAffinity];
}

- (UITextPosition*)beginningOfDocument {
  return [[self textInputSurrogate] beginningOfDocument];
}

- (UITextPosition*)endOfDocument {
  return [[self textInputSurrogate] endOfDocument];
}

- (id<UITextInputDelegate>)inputDelegate {
  return [[self textInputSurrogate] inputDelegate];
}

- (void)setInputDelegate:(id<UITextInputDelegate>)delegate {
  [[self textInputSurrogate] setInputDelegate:delegate];
}

- (id<UITextInputTokenizer>)tokenizer {
  return [[self textInputSurrogate] tokenizer];
}

- (UITextRange*)textRangeFromPosition:(UITextPosition*)fromPosition
                           toPosition:(UITextPosition*)toPosition {
  return [[self textInputSurrogate] textRangeFromPosition:fromPosition toPosition:toPosition];
}

- (UITextPosition*)positionFromPosition:(UITextPosition*)position offset:(NSInteger)offset {
  return [[self textInputSurrogate] positionFromPosition:position offset:offset];
}

- (UITextPosition*)positionFromPosition:(UITextPosition*)position
                            inDirection:(UITextLayoutDirection)direction
                                 offset:(NSInteger)offset {
  return [[self textInputSurrogate] positionFromPosition:position
                                             inDirection:direction
                                                  offset:offset];
}

- (NSComparisonResult)comparePosition:(UITextPosition*)position toPosition:(UITextPosition*)other {
  return [[self textInputSurrogate] comparePosition:position toPosition:other];
}

- (NSInteger)offsetFromPosition:(UITextPosition*)from toPosition:(UITextPosition*)toPosition {
  return [[self textInputSurrogate] offsetFromPosition:from toPosition:toPosition];
}

- (UITextPosition*)positionWithinRange:(UITextRange*)range
                   farthestInDirection:(UITextLayoutDirection)direction {
  return [[self textInputSurrogate] positionWithinRange:range farthestInDirection:direction];
}

- (UITextRange*)characterRangeByExtendingPosition:(UITextPosition*)position
                                      inDirection:(UITextLayoutDirection)direction {
  return [[self textInputSurrogate] characterRangeByExtendingPosition:position
                                                          inDirection:direction];
}

- (UITextWritingDirection)baseWritingDirectionForPosition:(UITextPosition*)position
                                              inDirection:(UITextStorageDirection)direction {
  return [[self textInputSurrogate] baseWritingDirectionForPosition:position inDirection:direction];
}

- (void)setBaseWritingDirection:(UITextWritingDirection)writingDirection
                       forRange:(UITextRange*)range {
  [[self textInputSurrogate] setBaseWritingDirection:writingDirection forRange:range];
}

- (CGRect)firstRectForRange:(UITextRange*)range {
  return [[self textInputSurrogate] firstRectForRange:range];
}

- (CGRect)caretRectForPosition:(UITextPosition*)position {
  return [[self textInputSurrogate] caretRectForPosition:position];
}

- (UITextPosition*)closestPositionToPoint:(CGPoint)point {
  return [[self textInputSurrogate] closestPositionToPoint:point];
}

- (UITextPosition*)closestPositionToPoint:(CGPoint)point withinRange:(UITextRange*)range {
  return [[self textInputSurrogate] closestPositionToPoint:point withinRange:range];
}

- (NSArray*)selectionRectsForRange:(UITextRange*)range {
  return [[self textInputSurrogate] selectionRectsForRange:range];
}

- (UITextRange*)characterRangeAtPoint:(CGPoint)point {
  return [[self textInputSurrogate] characterRangeAtPoint:point];
}

- (void)insertText:(NSString*)text {
  [[self textInputSurrogate] insertText:text];
}

- (void)deleteBackward {
  [[self textInputSurrogate] deleteBackward];
}

#pragma mark - UIKeyInput overrides

- (BOOL)hasText {
  return [[self textInputSurrogate] hasText];
}

@end
