// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/window/platform_message.h"

#include <utility>

namespace blink {

PlatformMessage::PlatformMessage(std::string name,
                                 std::vector<char> data,
                                 ftl::RefPtr<PlatformMessageResponse> response)
    : name_(std::move(name)),
      data_(std::move(data)),
      response_(std::move(response)) {}

PlatformMessage::~PlatformMessage() = default;

}  // namespace blink
