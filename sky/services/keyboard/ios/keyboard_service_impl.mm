// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/services/keyboard/ios/keyboard_service_impl.h"
#include <UIKit/UIKit.h>

static inline UIKeyboardType ToUIKeyboardType(::keyboard::KeyboardType type) {
  switch (type) {
    case ::keyboard::KEYBOARD_TYPE_TEXT:
      return UIKeyboardTypeDefault;
    case ::keyboard::KEYBOARD_TYPE_NUMBER:
      return UIKeyboardTypeDecimalPad;
    case ::keyboard::KEYBOARD_TYPE_PHONE:
      return UIKeyboardTypePhonePad;
    default:
      break;
  }
  return UIKeyboardTypeDefault;
}

@interface KeyboardClient : UIView<UIKeyInput>

- (void)show:(::keyboard::KeyboardClientPtr)client;
- (void)hide;

@end

@implementation KeyboardClient {
  ::keyboard::KeyboardClientPtr _client;
}

@synthesize keyboardType = _keyboardType;

- (UITextAutocorrectionType)autocorrectionType {
  return UITextAutocorrectionTypeNo;
}

- (void)show:(::keyboard::KeyboardClientPtr)client {
  _client = client.Pass();

  NSAssert([UIApplication sharedApplication].keyWindow != nullptr,
           @"The application must have a key window since the keyboard client "
           @"must be part of the responder chain to function");
  [[UIApplication sharedApplication].keyWindow addSubview:self];
  [self becomeFirstResponder];
}

- (void)hide {
  [self resignFirstResponder];
  [self removeFromSuperview];
  _client = nullptr;
}

#pragma mark - UIResponder Overrides

- (BOOL)canBecomeFirstResponder {
  return YES;
}

#pragma mark - UIKey Input Overrides

- (BOOL)hasText {
  return YES;
}

- (void)insertText:(NSString*)text {
  if (_client == nullptr) {
    return;
  }

  _client->CommitText(text.UTF8String, text.length);
}

- (void)deleteBackward {
  if (_client == nullptr) {
    return;
  }

  _client->DeleteSurroundingText(1, 0);
}

@end

namespace sky {
namespace services {
namespace keyboard {

KeyboardServiceImpl::KeyboardServiceImpl(
    mojo::InterfaceRequest<::keyboard::KeyboardService> request)
    : binding_(this, request.Pass()), client_([[KeyboardClient alloc] init]) {}

KeyboardServiceImpl::~KeyboardServiceImpl() {
  [client_ release];
}

void KeyboardServiceImpl::Show(::keyboard::KeyboardClientPtr client,
                               ::keyboard::KeyboardType type) {
  client_.keyboardType = ToUIKeyboardType(type);
  [client_ show:client.Pass()];
}

void KeyboardServiceImpl::ShowByRequest() {}

void KeyboardServiceImpl::Hide() {
  [client_ hide];
}

void KeyboardServiceFactory::Create(
    mojo::ApplicationConnection* connection,
    mojo::InterfaceRequest<::keyboard::KeyboardService> request) {
  new KeyboardServiceImpl(request.Pass());
}

}  // namespace keyboard
}  // namespace services
}  // namespace sky
