// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/embedder/embedder_platform_message_response.h"

#include "flutter/fml/make_copyable.h"

namespace flutter {

EmbedderPlatformMessageResponse::EmbedderPlatformMessageResponse(
    fml::RefPtr<fml::TaskRunner> runner,
    const Callback& callback)
    : runner_(std::move(runner)), callback_(callback) {}

EmbedderPlatformMessageResponse::~EmbedderPlatformMessageResponse() = default;

// |PlatformMessageResponse|
void EmbedderPlatformMessageResponse::Complete(
    std::unique_ptr<fml::Mapping> data) {
  if (!data) {
    CompleteEmpty();
    return;
  }

  if (!callback_) {
    return;
  }

  runner_->PostTask(
      // The static leak checker gets confused by the use of fml::MakeCopyable.
      // NOLINTNEXTLINE(clang-analyzer-cplusplus.NewDeleteLeaks)
      fml::MakeCopyable([data = std::move(data), callback = callback_]() {
        // Preserve a non-null pointer for 0-byte responses (where an empty
        // std::vector<uint8_t> inside fml::DataMapping returns GetMapping() ==
        // nullptr) so C-API embedders can distinguish a 0-byte ByteData(0)
        // reply from CompleteEmpty() (which passes nullptr, 0).
        static constexpr uint8_t kEmptyResponseSentinel = 0;
        const uint8_t* bytes = data->GetMapping();
        if (bytes == nullptr && data->GetSize() == 0) {
          bytes = &kEmptyResponseSentinel;
        }
        callback(bytes, data->GetSize());
      }));
}

// |PlatformMessageResponse|
void EmbedderPlatformMessageResponse::CompleteEmpty() {
  if (!callback_) {
    return;
  }

  runner_->PostTask([callback = callback_]() { callback(nullptr, 0u); });
}

}  // namespace flutter
