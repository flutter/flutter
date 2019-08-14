// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/platform_handler.h"

#include <windows.h>

#include <iostream>

#include "flutter/shell/platform/common/cpp/client_wrapper/include/flutter/json_method_codec.h"

static constexpr char kChannelName[] = "flutter/platform";

static constexpr char kGetClipboardDataMethod[] = "Clipboard.getData";
static constexpr char kSetClipboardDataMethod[] = "Clipboard.setData";

static constexpr char kTextPlainFormat[] = "text/plain";
static constexpr char kTextKey[] = "text";

static constexpr char kUnknownClipboardFormatError[] =
    "Unknown clipboard format error";

namespace flutter {

PlatformHandler::PlatformHandler(flutter::BinaryMessenger* messenger,
                                 Win32FlutterWindow* window)
    : channel_(std::make_unique<flutter::MethodChannel<rapidjson::Document>>(
          messenger,
          kChannelName,
          &flutter::JsonMethodCodec::GetInstance())),
      window_(window) {
  channel_->SetMethodCallHandler(
      [this](
          const flutter::MethodCall<rapidjson::Document>& call,
          std::unique_ptr<flutter::MethodResult<rapidjson::Document>> result) {
        HandleMethodCall(call, std::move(result));
      });
}

void PlatformHandler::HandleMethodCall(
    const flutter::MethodCall<rapidjson::Document>& method_call,
    std::unique_ptr<flutter::MethodResult<rapidjson::Document>> result) {
  const std::string& method = method_call.method_name();
  if (method.compare(kGetClipboardDataMethod) == 0) {
    // Only one string argument is expected.
    const rapidjson::Value& format = method_call.arguments()[0];

    if (strcmp(format.GetString(), kTextPlainFormat) != 0) {
      result->Error(kUnknownClipboardFormatError,
                    "Windows clipboard API only supports text.");
      return;
    }

    auto clipboardData = GetClipboardString();

    if (clipboardData.empty()) {
      result->Error(kUnknownClipboardFormatError,
                    "Failed to retrieve clipboard data from win32 api.");
      return;
    }
    rapidjson::Document document;
    document.SetObject();
    rapidjson::Document::AllocatorType& allocator = document.GetAllocator();
    document.AddMember(rapidjson::Value(kTextKey, allocator),
                       rapidjson::Value(clipboardData, allocator), allocator);
    result->Success(&document);

  } else if (method.compare(kSetClipboardDataMethod) == 0) {
    const rapidjson::Value& document = *method_call.arguments();
    rapidjson::Value::ConstMemberIterator itr = document.FindMember(kTextKey);
    if (itr == document.MemberEnd()) {
      result->Error(kUnknownClipboardFormatError,
                    "Missing text to store on clipboard.");
      return;
    }
    SetClipboardString(std::string(itr->value.GetString()));
    result->Success();
  } else {
    result->NotImplemented();
  }
}

std::string PlatformHandler::GetClipboardString() {
  if (!OpenClipboard(nullptr)) {
    return nullptr;
  }

  HANDLE data = GetClipboardData(CF_TEXT);
  if (data == nullptr) {
    CloseClipboard();
    return nullptr;
  }

  const char* clipboardData = static_cast<char*>(GlobalLock(data));

  if (clipboardData == nullptr) {
    CloseClipboard();
    return nullptr;
  }

  auto result = std::string(clipboardData);
  GlobalUnlock(data);
  CloseClipboard();
  return result;
}

void PlatformHandler::SetClipboardString(std::string data) {
  if (!OpenClipboard(nullptr)) {
    return;
  }

  auto htext = GlobalAlloc(GMEM_MOVEABLE, data.size());

  memcpy(GlobalLock(htext), data.c_str(), data.size());

  SetClipboardData(CF_TEXT, htext);

  CloseClipboard();
}

}  // namespace flutter
