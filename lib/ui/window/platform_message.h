// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_UI_PLATFORM_PLATFORM_MESSAGE_H_
#define FLUTTER_LIB_UI_PLATFORM_PLATFORM_MESSAGE_H_

#include <functional>
#include <string>
#include <vector>

#include "lib/ftl/memory/ref_counted.h"
#include "lib/ftl/memory/ref_ptr.h"
#include "lib/tonic/dart_persistent_value.h"

namespace blink {

class PlatformMessage : public ftl::RefCountedThreadSafe<PlatformMessage> {
  FRIEND_REF_COUNTED_THREAD_SAFE(PlatformMessage);
  FRIEND_MAKE_REF_COUNTED(PlatformMessage);

 public:
  using Sink = std::function<void(ftl::RefPtr<PlatformMessage>)>;

  const std::string& name() const { return name_; }
  const std::vector<char>& data() const { return data_; }

  bool has_callback() const { return !callback_.is_empty(); }

  // Callable on any thread.
  void InvokeCallback(std::vector<char> data);
  void InvokeCallbackWithError();
  void ClearData();

 private:
  PlatformMessage(std::string name,
                  std::vector<char> data,
                  tonic::DartPersistentValue callback);
  ~PlatformMessage();

  std::string name_;
  std::vector<char> data_;
  tonic::DartPersistentValue callback_;
};

}  // namespace blink

#endif  // FLUTTER_LIB_UI_PLATFORM_PLATFORM_MESSAGE_H_
