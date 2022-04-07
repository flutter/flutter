// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/platform_handler.h"

#include "flutter/shell/platform/common/json_method_codec.h"

static constexpr char kChannelName[] = "flutter/platform";

static constexpr char kGetClipboardDataMethod[] = "Clipboard.getData";
static constexpr char kHasStringsClipboardMethod[] = "Clipboard.hasStrings";
static constexpr char kSetClipboardDataMethod[] = "Clipboard.setData";
static constexpr char kPlaySoundMethod[] = "SystemSound.play";

static constexpr char kTextPlainFormat[] = "text/plain";
static constexpr char kTextKey[] = "text";

static constexpr char kUnknownClipboardFormatMessage[] =
    "Unknown clipboard format";

namespace flutter {

PlatformHandler::PlatformHandler(BinaryMessenger* messenger)
    : channel_(std::make_unique<MethodChannel<rapidjson::Document>>(
          messenger,
          kChannelName,
          &JsonMethodCodec::GetInstance())) {
  channel_->SetMethodCallHandler(
      [this](const MethodCall<rapidjson::Document>& call,
             std::unique_ptr<MethodResult<rapidjson::Document>> result) {
        HandleMethodCall(call, std::move(result));
      });
}

PlatformHandler::~PlatformHandler() = default;

void PlatformHandler::HandleMethodCall(
    const MethodCall<rapidjson::Document>& method_call,
    std::unique_ptr<MethodResult<rapidjson::Document>> result) {
  const std::string& method = method_call.method_name();
  if (method.compare(kGetClipboardDataMethod) == 0) {
    // Only one string argument is expected.
    const rapidjson::Value& format = method_call.arguments()[0];

    if (strcmp(format.GetString(), kTextPlainFormat) != 0) {
      result->Error(kClipboardError, kUnknownClipboardFormatMessage);
      return;
    }
    GetPlainText(std::move(result), kTextKey);
  } else if (method.compare(kHasStringsClipboardMethod) == 0) {
    // Only one string argument is expected.
    const rapidjson::Value& format = method_call.arguments()[0];

    if (strcmp(format.GetString(), kTextPlainFormat) != 0) {
      result->Error(kClipboardError, kUnknownClipboardFormatMessage);
      return;
    }
    GetHasStrings(std::move(result));
  } else if (method.compare(kSetClipboardDataMethod) == 0) {
    const rapidjson::Value& document = *method_call.arguments();
    rapidjson::Value::ConstMemberIterator itr = document.FindMember(kTextKey);
    if (itr == document.MemberEnd()) {
      result->Error(kClipboardError, kUnknownClipboardFormatMessage);
      return;
    }
    SetPlainText(itr->value.GetString(), std::move(result));
  } else if (method.compare(kPlaySoundMethod) == 0) {
    // Only one string argument is expected.
    const rapidjson::Value& sound_type = method_call.arguments()[0];

    SystemSoundPlay(sound_type.GetString(), std::move(result));
  } else {
    result->NotImplemented();
  }
}

}  // namespace flutter
