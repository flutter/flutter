// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/services/editing/ios/keyboard_impl.h"

#include "base/strings/sys_string_conversions.h"
#include "base/strings/utf_string_conversions.h"
#include <UIKit/UIKit.h>
#include <unicode/utf16.h>

static inline UIKeyboardType ToUIKeyboardType(::editing::KeyboardType type) {
  using Type = ::editing::KeyboardType;
  switch (type) {
    case Type::TEXT:
      return UIKeyboardTypeDefault;
    case Type::NUMBER:
      return UIKeyboardTypeDecimalPad;
    case Type::PHONE:
      return UIKeyboardTypePhonePad;
    default:
      break;
  }
  return UIKeyboardTypeDefault;
}

@interface KeyboardClient : UIView<UIKeyInput>

- (void)setClient:(::editing::KeyboardClientPtr)client;
- (void)setEditingState:(::editing::EditingStatePtr)state;
- (void)show;
- (void)hide;

@end

@implementation KeyboardClient {
  ::editing::KeyboardClientPtr _client;
  ::editing::EditingStatePtr _state;
  base::string16 _text;
}

@synthesize keyboardType = _keyboardType;

- (UITextAutocorrectionType)autocorrectionType {
  return UITextAutocorrectionTypeNo;
}

- (void)setClient:(::editing::KeyboardClientPtr)client {
  _client = client.Pass();
}

- (void)setEditingState:(::editing::EditingStatePtr)state {
  _state = state.Pass();
  _text = base::UTF8ToUTF16(_state->text.To<std::string>());
}

- (void)show {
  NSAssert([UIApplication sharedApplication].keyWindow != nullptr,
           @"The application must have a key window since the keyboard client "
           @"must be part of the responder chain to function");
  [[UIApplication sharedApplication].keyWindow addSubview:self];
  [self becomeFirstResponder];
}

- (void)hide {
  [self resignFirstResponder];
  [self removeFromSuperview];
}

#pragma mark - UIResponder Overrides

- (BOOL)canBecomeFirstResponder {
  return YES;
}

#pragma mark - UIKeyInput Overrides

// TODO(abarth): We should implement UITextInput for more features.

- (BOOL)hasText {
  return YES;
}

- (void)insertText:(NSString*)text {
  int start = std::max(0, std::min(_state->selection_base, _state->selection_extent));
  int end = std::max(0, std::max(_state->selection_base, _state->selection_extent));
  int len = end - start;
  _text.replace(start, len, base::SysNSStringToUTF16(text));
  int caret = start + text.length;
  _state->selection_base = caret;
  _state->selection_extent = caret;
  _state->selection_affinity = ::editing::TextAffinity::UPSTREAM;
  _state->selection_is_directional = false;
  _state->composing_base = 0;
  _state->composing_extent = 0;
  _state->text = base::UTF16ToUTF8(_text);
  _client->UpdateEditingState(_state.Clone());
}

- (void)deleteBackward {
  int start = std::max(0, std::min(_state->selection_base, _state->selection_extent));
  int end = std::max(0, std::max(_state->selection_base, _state->selection_extent));
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
  _state->selection_base = start;
  _state->selection_extent = start;
  _state->selection_affinity = ::editing::TextAffinity::DOWNSTREAM;
  _state->selection_is_directional = false;
  _state->composing_base = 0;
  _state->composing_extent = 0;
  _state->text = base::UTF16ToUTF8(_text);
  _client->UpdateEditingState(_state.Clone());
}

@end

namespace sky {
namespace services {
namespace editing {

KeyboardImpl::KeyboardImpl(
    mojo::InterfaceRequest<::editing::Keyboard> request)
    : binding_(this, request.Pass()), client_([[KeyboardClient alloc] init]) {}

KeyboardImpl::~KeyboardImpl() {
  [client_ hide];
  [client_ release];
}

void KeyboardImpl::SetClient(::editing::KeyboardClientPtr client,
                             ::editing::KeyboardConfigurationPtr config) {
  client_.keyboardType = ToUIKeyboardType(config->type);
  [client_ setClient:client.Pass()];
}

void KeyboardImpl::SetEditingState(::editing::EditingStatePtr state) {
  [client_ setEditingState:state.Pass()];
}

void KeyboardImpl::Show() {
  [client_ show];
}

void KeyboardImpl::Hide() {
  [client_ hide];
}

void KeyboardFactory::Create(
    mojo::ApplicationConnection* connection,
    mojo::InterfaceRequest<::editing::Keyboard> request) {
  new KeyboardImpl(request.Pass());
}

}  // namespace editing
}  // namespace services
}  // namespace sky
