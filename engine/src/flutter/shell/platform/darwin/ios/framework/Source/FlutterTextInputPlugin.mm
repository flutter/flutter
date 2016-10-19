// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/darwin/ios/framework/Source/FlutterTextInputPlugin.h"

#include <UIKit/UIKit.h>
#include <unicode/utf16.h>

#include "base/strings/sys_string_conversions.h"
#include "base/strings/utf_string_conversions.h"

static const char _kTextAffinityDownstream[] = "TextAffinity.downstream";
static const char _kTextAffinityUpstream[] = "TextAffinity.upstream";

static UIKeyboardType ToUIKeyboardType(NSString* inputType) {
  if ([inputType isEqualToString:@"TextInputType.text"])
    return UIKeyboardTypeDefault;
  if ([inputType isEqualToString:@"TextInputType.number"])
    return UIKeyboardTypeDecimalPad;
  if ([inputType isEqualToString:@"TextInputType.phone"])
    return UIKeyboardTypePhonePad;
  return UIKeyboardTypeDefault;
}

@interface FlutterTextInputView : UIView<UIKeyInput>

@property(nonatomic, assign) id<FlutterTextInputDelegate> textInputDelegate;

@end

@implementation FlutterTextInputView {
  int _textInputClient;
  int _selectionBase;
  int _selectionExtent;
  const char* _selectionAffinity;
  base::string16 _text;
}

@synthesize keyboardType = _keyboardType;

@synthesize textInputDelegate = _textInputDelegate;

- (instancetype)init {
  self = [super init];

  if (self) {
    _selectionBase = -1;
    _selectionExtent = -1;
  }

  return self;
}

- (void)setTextInputClient:(int)client {
  _textInputClient = client;
}

- (void)setTextInputState:(NSDictionary*)state {
  _selectionBase = [state[@"selectionBase"] intValue];
  _selectionExtent = [state[@"selectionExtent"] intValue];
  _selectionAffinity = _kTextAffinityDownstream;
  if ([state[@"selectionAffinity"] isEqualToString:@(_kTextAffinityUpstream)])
    _selectionAffinity = _kTextAffinityUpstream;
  _text = base::SysNSStringToUTF16(state[@"text"]);
}

- (UITextAutocorrectionType)autocorrectionType {
  return UITextAutocorrectionTypeNo;
}

#pragma mark - UIResponder Overrides

- (BOOL)canBecomeFirstResponder {
  return YES;
}

#pragma mark - UIKeyInput Overrides

- (void)updateEditingState {
  [_textInputDelegate updateEditingClient:_textInputClient
                                withState:@{
                                  @"selectionBase": @(_selectionBase),
                                  @"selectionExtent": @(_selectionExtent),
                                  @"selectionAffinity": @(_selectionAffinity),
                                  @"selectionIsDirectional": @(false),
                                  @"composingBase": @(0),
                                  @"composingExtent": @(0),
                                  @"text": base::SysUTF16ToNSString(_text),
                                }];
}

- (BOOL)hasText {
  return YES;
}

- (void)insertText:(NSString*)text {
  int start = std::max(0, std::min(_selectionBase, _selectionExtent));
  int end = std::max(0, std::max(_selectionBase, _selectionExtent));
  int len = end - start;
  _text.replace(start, len, base::SysNSStringToUTF16(text));
  int caret = start + text.length;
  _selectionBase = caret;
  _selectionExtent = caret;
  _selectionAffinity = _kTextAffinityUpstream;
  [self updateEditingState];
}

- (void)deleteBackward {
  int start = std::max(0, std::min(_selectionBase, _selectionExtent));
  int end = std::max(0, std::max(_selectionBase, _selectionExtent));
  int len = end - start;
  if (len > 0) {
    _text.erase(start, len);
  } else if (start > 0) {
    start -= 1;
    len = 1;
    if (start > 0 &&
        UTF16_IS_LEAD(_text[start - 1]) &&
        UTF16_IS_TRAIL(_text[start])) {
      start -= 1;
      len += 1;
    }
    _text.erase(start, len);
  }
  _selectionBase = start;
  _selectionExtent = start;
  _selectionAffinity = _kTextAffinityDownstream;
  [self updateEditingState];
}

@end

@implementation FlutterTextInputPlugin {
  FlutterTextInputView* _view;
}

@synthesize textInputDelegate = _textInputDelegate;

- (instancetype)init {
  self = [super init];

  if (self) {
    _view = [[FlutterTextInputView alloc] init];
  }

  return self;
}

- (void)dealloc {
  [self hideTextInput];
  [_view release];

  [super dealloc];
}

- (NSString *)messageName {
  return @"flutter/textinput";
}

- (NSDictionary*)didReceiveJSON:(NSDictionary*)message {
  NSString* method = message[@"method"];
  NSArray* args = message[@"args"];
  if (!args)
    return nil;
  if ([method isEqualToString:@"TextInput.show"]) {
    [self showTextInput];
  } else if ([method isEqualToString:@"TextInput.hide"]) {
    [self hideTextInput];
  } else if ([method isEqualToString:@"TextInput.setClient"]) {
    [self setTextInputClient:[args[0] intValue] withConfiguration:args[1]];
  } else if ([method isEqualToString:@"TextInput.setEditingState"]) {
    [self setTextInputEditingState:args.firstObject];
  } else if ([method isEqualToString:@"TextInput.clearClient"]) {
    [self clearTextInputClient];
  } else {
    // TODO(abarth): We should signal an error here that gets reported back to
    // Dart.
  }
  return nil;
}

- (void)showTextInput {
  NSAssert([UIApplication sharedApplication].keyWindow != nullptr,
           @"The application must have a key window since the keyboard client "
           @"must be part of the responder chain to function");
  _view.textInputDelegate = _textInputDelegate;
  [[UIApplication sharedApplication].keyWindow addSubview:_view];
  [_view becomeFirstResponder];
}

- (void)hideTextInput {
  [_view resignFirstResponder];
  [_view removeFromSuperview];
}

- (void)setTextInputClient:(int)client withConfiguration:(NSDictionary*)configuration {
  _view.keyboardType = ToUIKeyboardType(configuration[@"inputType"]);
  [_view setTextInputClient:client];
}

- (void)setTextInputEditingState:(NSDictionary*)state {
  [_view setTextInputState:state];
}

- (void)clearTextInputClient {
  [_view setTextInputClient:0];
}

@end
