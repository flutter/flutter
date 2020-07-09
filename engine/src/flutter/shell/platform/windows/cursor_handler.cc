// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/cursor_handler.h"

#include <windows.h>

#include "flutter/shell/platform/common/cpp/client_wrapper/include/flutter/standard_method_codec.h"

static constexpr char kChannelName[] = "flutter/mousecursor";

static constexpr char kActivateSystemCursorMethod[] = "activateSystemCursor";

static constexpr char kKindKey[] = "kind";

namespace flutter {

CursorHandler::CursorHandler(flutter::BinaryMessenger* messenger,
                             WindowBindingHandler* delegate)
    : channel_(std::make_unique<flutter::MethodChannel<EncodableValue>>(
          messenger,
          kChannelName,
          &flutter::StandardMethodCodec::GetInstance())),
      delegate_(delegate) {
  channel_->SetMethodCallHandler(
      [this](const flutter::MethodCall<EncodableValue>& call,
             std::unique_ptr<flutter::MethodResult<EncodableValue>> result) {
        HandleMethodCall(call, std::move(result));
      });
}

void CursorHandler::HandleMethodCall(
    const flutter::MethodCall<EncodableValue>& method_call,
    std::unique_ptr<flutter::MethodResult<EncodableValue>> result) {
  const std::string& method = method_call.method_name();
  if (method.compare(kActivateSystemCursorMethod) == 0) {
    const flutter::EncodableMap& arguments =
        method_call.arguments()->MapValue();
    auto kind_iter = arguments.find(EncodableValue(kKindKey));
    if (kind_iter == arguments.end()) {
      result->Error("Argument error",
                    "Missing argument while trying to activate system cursor");
    }
    const std::string& kind = kind_iter->second.StringValue();
    delegate_->UpdateFlutterCursor(kind);
    result->Success();
  } else {
    result->NotImplemented();
  }
}

}  // namespace flutter
