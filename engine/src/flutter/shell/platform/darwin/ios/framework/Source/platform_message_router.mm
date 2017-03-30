// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/darwin/ios/framework/Source/platform_message_router.h"

#include <vector>

#include "flutter/shell/platform/darwin/common/buffer_conversions.h"

namespace shell {

PlatformMessageRouter::PlatformMessageRouter() = default;

PlatformMessageRouter::~PlatformMessageRouter() = default;

void PlatformMessageRouter::HandlePlatformMessage(
    ftl::RefPtr<blink::PlatformMessage> message) {
  NSData* data = GetNSDataFromVector(message->data());

  ftl::RefPtr<blink::PlatformMessageResponse> completer = message->response();
  auto it = message_handlers_.find(message->channel());
  if (it != message_handlers_.end()) {
    FlutterBinaryMessageHandler handler = it->second;
    handler(data, ^(NSData* reply) {
      if (completer) {
        completer->Complete(GetVectorFromNSData(reply));
      }
    });
  } else {
    if (completer) {
      completer->Complete(GetVectorFromNSData(nil));
    }
  }
}

void PlatformMessageRouter::SetMessageHandler(
    const std::string& channel,
    FlutterBinaryMessageHandler handler) {
  if (handler)
    message_handlers_[channel] = [handler copy];
  else {
    auto it = message_handlers_.find(channel);
    if (it != message_handlers_.end()) {
      [it->second release];
      message_handlers_.erase(it);
    }
  }
}

}  // namespace shell
