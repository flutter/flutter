// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_UI_PLATFORM_PLATFORM_MESSAGE_H_
#define FLUTTER_LIB_UI_PLATFORM_PLATFORM_MESSAGE_H_

#include <string>
#include <vector>

#include "flutter/lib/ui/window/platform_message_response.h"
#include "lib/fxl/memory/ref_counted.h"
#include "lib/fxl/memory/ref_ptr.h"

namespace blink {

class PlatformMessage : public fxl::RefCountedThreadSafe<PlatformMessage> {
  FRIEND_REF_COUNTED_THREAD_SAFE(PlatformMessage);
  FRIEND_MAKE_REF_COUNTED(PlatformMessage);

 public:
  const std::string& channel() const { return channel_; }
  const std::vector<uint8_t>& data() const { return data_; }
  bool hasData() { return hasData_; }

  const fxl::RefPtr<PlatformMessageResponse>& response() const {
    return response_;
  }

 private:
  PlatformMessage(std::string name,
                  std::vector<uint8_t> data,
                  fxl::RefPtr<PlatformMessageResponse> response);
  PlatformMessage(std::string name,
                  fxl::RefPtr<PlatformMessageResponse> response);
  ~PlatformMessage();

  std::string channel_;
  std::vector<uint8_t> data_;
  bool hasData_;
  fxl::RefPtr<PlatformMessageResponse> response_;
};

}  // namespace blink

#endif  // FLUTTER_LIB_UI_PLATFORM_PLATFORM_MESSAGE_H_
