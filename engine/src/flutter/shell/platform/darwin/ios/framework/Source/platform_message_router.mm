// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/darwin/ios/framework/Source/platform_message_router.h"

#include <vector>

#include "base/strings/sys_string_conversions.h"
#include "flutter/shell/platform/darwin/common/string_conversions.h"

namespace shell {

PlatformMessageRouter::PlatformMessageRouter() = default;

PlatformMessageRouter::~PlatformMessageRouter() = default;

void PlatformMessageRouter::HandlePlatformMessage(
    ftl::RefPtr<blink::PlatformMessage> message) {
  NSString* string = GetNSStringFromVector(message->data());

  ftl::RefPtr<blink::PlatformMessageResponse> completer = message->response();
  {
    auto it = listeners_.find(message->channel());
    if (it != listeners_.end()) {
      NSString* response = [it->second didReceiveString:string];
      if (completer)
        completer->Complete(GetVectorFromNSString(response));
      return;
    }
  }

  {
    auto it = async_listeners_.find(message->channel());
    if (it != async_listeners_.end()) {
      [it->second
          didReceiveString:string
                  callback:^(NSString* response) {
                    if (completer)
                      completer->Complete(GetVectorFromNSString(response));
                  }];
    }
  }
}

void PlatformMessageRouter::SetMessageListener(
    const std::string& channel,
    NSObject<FlutterMessageListener>* listener) {
  if (listener)
    listeners_[channel] = listener;
  else
    listeners_.erase(channel);
}

void PlatformMessageRouter::SetAsyncMessageListener(
    const std::string& channel,
    NSObject<FlutterAsyncMessageListener>* listener) {
  if (listener)
    async_listeners_[channel] = listener;
  else
    async_listeners_.erase(channel);
}

}  // namespace shell
