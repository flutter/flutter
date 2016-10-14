// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_UI_PLATFORM_PLATFORM_MESSAGE_RESPONSE_H_
#define FLUTTER_LIB_UI_PLATFORM_PLATFORM_MESSAGE_RESPONSE_H_

#include <vector>

#include "lib/ftl/memory/ref_counted.h"
#include "lib/ftl/memory/ref_ptr.h"

namespace blink {

class PlatformMessageResponse
    : public ftl::RefCountedThreadSafe<PlatformMessageResponse> {
  FRIEND_REF_COUNTED_THREAD_SAFE(PlatformMessageResponse);

 public:
  // Callable on any thread.
  virtual void Complete(std::vector<char> data) = 0;
  // TODO(abarth): You should be able to pass data with the error.
  virtual void CompleteWithError() = 0;

  bool is_complete() const { return is_complete_; }

 protected:
  PlatformMessageResponse();
  virtual ~PlatformMessageResponse();

  bool is_complete_ = false;
};

}  // namespace blink

#endif  // FLUTTER_LIB_UI_PLATFORM_PLATFORM_MESSAGE_RESPONSE_H_
