// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_UI_PLATFORM_PLATFORM_MESSAGE_RESPONSE_DART_H_
#define FLUTTER_LIB_UI_PLATFORM_PLATFORM_MESSAGE_RESPONSE_DART_H_

#include "flutter/lib/ui/window/platform_message_response.h"
#include "lib/tonic/dart_persistent_value.h"

namespace blink {

class PlatformMessageResponseDart : public PlatformMessageResponse {
  FRIEND_MAKE_REF_COUNTED(PlatformMessageResponseDart);

 public:
  // Callable on any thread.
  void Complete(std::vector<char> data) override;
  void CompleteWithError() override;

 protected:
  explicit PlatformMessageResponseDart(tonic::DartPersistentValue callback);
  ~PlatformMessageResponseDart() override;

  tonic::DartPersistentValue callback_;
};

}  // namespace blink

#endif  // FLUTTER_LIB_UI_PLATFORM_PLATFORM_MESSAGE_RESPONSE_DART_H_
