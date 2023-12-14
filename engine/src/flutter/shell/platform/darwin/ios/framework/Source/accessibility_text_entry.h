// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_ACCESSIBILITY_TEXT_ENTRY_H_
#define FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_ACCESSIBILITY_TEXT_ENTRY_H_

/**
 * An implementation of `UITextInput` used for text fields that do not currently
 * have input focus.
 *
 * This class is used by `TextInputSemanticsObject`.
 */
@interface FlutterInactiveTextInput : UIView <UITextInput>

@property(nonatomic, copy) NSString* text;
@property(nonatomic, copy, readonly) NSMutableString* markedText;
@property(copy) UITextRange* selectedTextRange;
@property(nonatomic, strong, readonly) UITextRange* markedTextRange;
@property(nonatomic, copy) NSDictionary<NSAttributedStringKey, id>* markedTextStyle;
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

#endif  // FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_ACCESSIBILITY_TEXT_ENTRY_H_
