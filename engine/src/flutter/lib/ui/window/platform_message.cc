// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/window/platform_message.h"

#include <utility>

namespace blink {

PlatformMessage::PlatformMessage(std::string channel,
                                 std::vector<uint8_t> data,
                                 fxl::RefPtr<PlatformMessageResponse> response)
    : channel_(std::move(channel)),
      data_(std::move(data)),
      hasData_(true),
      response_(std::move(response)) {}
PlatformMessage::PlatformMessage(std::string channel,
                                 fxl::RefPtr<PlatformMessageResponse> response)
    : channel_(std::move(channel)),
      data_(),
      hasData_(false),
      response_(std::move(response)) {}

PlatformMessage::~PlatformMessage() = default;

}  // namespace blink
