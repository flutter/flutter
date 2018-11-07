// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/darwin/ios/framework/Source/platform_message_router.h"

#include <vector>

#include "flutter/shell/platform/darwin/common/buffer_conversions.h"

namespace shell {

PlatformMessageRouter::PlatformMessageRouter() = default;

PlatformMessageRouter::~PlatformMessageRouter() = default;

void PlatformMessageRouter::HandlePlatformMessage(
    fml::RefPtr<blink::PlatformMessage> message) const {
  fml::RefPtr<blink::PlatformMessageResponse> completer = message->response();
  auto it = message_handlers_.find(message->channel());
  if (it != message_handlers_.end()) {
    FlutterBinaryMessageHandler handler = it->second;
    NSData* data = nil;
    if (message->hasData()) {
      data = GetNSDataFromVector(message->data());
    }
    handler(data, ^(NSData* reply) {
      if (completer) {
        if (reply) {
          completer->Complete(GetMappingFromNSData(reply));
        } else {
          completer->CompleteEmpty();
        }
      }
    });
  } else {
    if (completer) {
      completer->CompleteEmpty();
    }
  }
}

void PlatformMessageRouter::SetMessageHandler(const std::string& channel,
                                              FlutterBinaryMessageHandler handler) {
  message_handlers_.erase(channel);
  if (handler) {
    message_handlers_[channel] =
        fml::ScopedBlock<FlutterBinaryMessageHandler>{handler, fml::OwnershipPolicy::Retain};
  }
}

}  // namespace shell
