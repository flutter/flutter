// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/sky/shell/platform/ios/framework/Source/application_messages_impl.h"

#include "base/strings/sys_string_conversions.h"

namespace sky {
namespace shell {

ApplicationMessagesImpl::ApplicationMessagesImpl() : weak_factory_(this) {
}

ApplicationMessagesImpl::~ApplicationMessagesImpl() {
}

ftl::WeakPtr<ApplicationMessagesImpl> ApplicationMessagesImpl::GetWeakPtr() {
  return weak_factory_.GetWeakPtr();
}

void ApplicationMessagesImpl::AddBinding(
    mojo::InterfaceRequest<flutter::platform::ApplicationMessages> request) {
  binding_.AddBinding(this, request.Pass());
}

void ApplicationMessagesImpl::SetMessageListener(
    const std::string& message_name,
    NSObject<FlutterMessageListener>* listener) {
  if (listener)
    listeners_[message_name] = listener;
  else
    listeners_.erase(message_name);
}

void ApplicationMessagesImpl::SetAsyncMessageListener(
    const std::string& message_name,
    NSObject<FlutterAsyncMessageListener>* listener) {
  if (listener)
    async_listeners_[message_name] = listener;
  else
    async_listeners_.erase(message_name);
}

void ApplicationMessagesImpl::SendString(
    const mojo::String& message_name,
    const mojo::String& message,
    const SendStringCallback& callback) {
  std::string message_name_str = message_name;
  NSString* ns_message = base::SysUTF8ToNSString(message);

  {
    auto it = listeners_.find(message_name_str);
    if (it != listeners_.end()) {
      NSString* response = [it->second didReceiveString:ns_message];
      callback.Run(base::SysNSStringToUTF8(response));
      return;
    }
  }

  {
    auto it = async_listeners_.find(message_name_str);
    if (it != async_listeners_.end()) {
      SendStringCallback local_callback = callback;
      [it->second didReceiveString:ns_message callback:^(NSString* response){
        local_callback.Run(base::SysNSStringToUTF8(response));
      }];
    }
  }
}

}  // namespace shell
}  // namespace sky
