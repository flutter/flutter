// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/platform_handler_winuwp.h"

#include "flutter/shell/platform/windows/flutter_windows_view.h"

namespace flutter {

// static
std::unique_ptr<PlatformHandler> PlatformHandler::Create(
    BinaryMessenger* messenger,
    FlutterWindowsView* view) {
  return std::make_unique<PlatformHandlerWinUwp>(messenger, view);
}

PlatformHandlerWinUwp::PlatformHandlerWinUwp(BinaryMessenger* messenger,
                                             FlutterWindowsView* view)
    : PlatformHandler(messenger), view_(view) {}

PlatformHandlerWinUwp::~PlatformHandlerWinUwp() = default;

void PlatformHandlerWinUwp::GetPlainText(
    std::unique_ptr<MethodResult<rapidjson::Document>> result,
    std::string_view key) {
  // TODO: Implement. See https://github.com/flutter/flutter/issues/70214.
  result->NotImplemented();
}

void PlatformHandlerWinUwp::SetPlainText(
    const std::string& text,
    std::unique_ptr<MethodResult<rapidjson::Document>> result) {
  // TODO: Implement. See https://github.com/flutter/flutter/issues/70214.
  result->NotImplemented();
}

}  // namespace flutter
