// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SHELL_PLATFORM_IOS_FRAMEWORK_SOURCE_ACCESSIBILITY_TEXT_ENTRY_H_
#define SHELL_PLATFORM_IOS_FRAMEWORK_SOURCE_ACCESSIBILITY_TEXT_ENTRY_H_

/**
 * An implementation of `UITextInput` used for text fields that do not currently
 * have input focus.
 *
 * This class is used by `TextInputSemanticsObject`.
 */
@interface FlutterInactiveTextInput : UIView <UITextInput>

@property(nonatomic, copy) NSString* text;
@property(nonatomic, readonly) NSMutableString* markedText;
@property(readwrite, copy) UITextRange* selectedTextRange;
@property(nonatomic, strong) UITextRange* markedTextRange;
@property(nonatomic, copy) NSDictionary* markedTextStyle;
@property(nonatomic, assign) id<UITextInputDelegate> inputDelegate;

@end

/**
 * An implementation of `SemanticsObject` specialized for expressing text
 * fields.
 *
 * Delegates to `FlutterTextInputView` when the object corresponds to a text
 * field that currently owns input focus. Delegates to
 * `FlutterInactiveTextInput` otherwise.
 */
@interface TextInputSemanticsObject : SemanticsObject <UITextInput>
@end

#endif  // SHELL_PLATFORM_IOS_FRAMEWORK_SOURCE_ACCESSIBILITY_TEXT_ENTRY_H_
