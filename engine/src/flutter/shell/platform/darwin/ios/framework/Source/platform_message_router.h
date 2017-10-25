// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SHELL_PLATFORM_IOS_FRAMEWORK_SOURCE_PLATFORM_MESSAGE_ROUTER_H_
#define SHELL_PLATFORM_IOS_FRAMEWORK_SOURCE_PLATFORM_MESSAGE_ROUTER_H_

#include <unordered_map>

#include "flutter/lib/ui/window/platform_message.h"
#include "flutter/shell/platform/darwin/common/FlutterBinaryMessenger.h"
#include "lib/fxl/memory/weak_ptr.h"

namespace shell {

class PlatformMessageRouter {
 public:
  PlatformMessageRouter();
  ~PlatformMessageRouter();

  void HandlePlatformMessage(fxl::RefPtr<blink::PlatformMessage> message);

  void SetMessageHandler(const std::string& channel,
                         FlutterBinaryMessageHandler handler);

 private:
  std::unordered_map<std::string, FlutterBinaryMessageHandler>
      message_handlers_;

  FXL_DISALLOW_COPY_AND_ASSIGN(PlatformMessageRouter);
};

}  // namespace shell

#endif  // SHELL_PLATFORM_IOS_FRAMEWORK_SOURCE_ACCESSIBILITY_BRIDGE_H_
