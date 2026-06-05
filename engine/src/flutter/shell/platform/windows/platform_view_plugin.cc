// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/platform_view_plugin.h"

namespace flutter {

PlatformViewPlugin::PlatformViewPlugin(BinaryMessenger* messenger,
                                       TaskRunner* task_runner)
    : PlatformViewManager(messenger), task_runner_(task_runner) {}

PlatformViewPlugin::~PlatformViewPlugin() {}

std::optional<HWND> PlatformViewPlugin::GetNativeHandleForId(
    PlatformViewId id) const {
  auto view = platform_views_.find(id);
  if (view == platform_views_.end()) {
    return std::nullopt;
  }
  return view->second;
}

void PlatformViewPlugin::RegisterPlatformViewType(
    std::string_view type_name,
    const FlutterPlatformViewTypeEntry& type) {
  if (type_name.empty() || type.factory == nullptr) {
    return;
  }
  platform_view_types_[std::string(type_name)] = type;
}

bool PlatformViewPlugin::InstantiatePlatformView(PlatformViewId id,
                                                 HWND parent_window) {
  if (platform_views_.find(id) != platform_views_.end()) {
    return true;
  }

  auto pending_view = pending_platform_views_.find(id);
  if (pending_view == pending_platform_views_.end()) {
    return false;
  }

  auto instantiate = [this, id, parent_window]() {
    if (platform_views_.find(id) != platform_views_.end()) {
      return;
    }

    auto pending_view = pending_platform_views_.find(id);
    if (pending_view == pending_platform_views_.end()) {
      return;
    }

    HWND hwnd = pending_view->second(parent_window);
    if (hwnd == nullptr) {
      return;
    }

    platform_views_[id] = hwnd;
    pending_platform_views_.erase(pending_view);
  };

  task_runner_->RunNowOrPostTask(std::move(instantiate));
  return true;
}

bool PlatformViewPlugin::AddPlatformView(PlatformViewId id,
                                         std::string_view type_name) {
  auto type = platform_view_types_.find(std::string(type_name));
  if (type == platform_view_types_.end()) {
    return false;
  }

  if (platform_views_.find(id) != platform_views_.end() ||
      pending_platform_views_.find(id) != pending_platform_views_.end()) {
    return false;
  }

  auto type_name_string = std::string(type_name);
  FlutterPlatformViewTypeEntry type_entry = type->second;
  pending_platform_views_[id] = [id,
                                 type_name_string = std::move(type_name_string),
                                 type_entry](HWND parent_window) {
    FlutterPlatformViewCreationParameters params = {};
    params.struct_size = sizeof(FlutterPlatformViewCreationParameters);
    params.parent_window = parent_window;
    params.platform_view_type = type_name_string.c_str();
    params.user_data = type_entry.user_data;
    params.platform_view_id = id;
    return type_entry.factory(&params);
  };
  return true;
}

bool PlatformViewPlugin::FocusPlatformView(PlatformViewId id,
                                           FocusChangeDirection direction,
                                           bool focus) {
  (void)direction;

  auto view = platform_views_.find(id);
  if (view == platform_views_.end()) {
    return false;
  }

  if (!focus) {
    return true;
  }

  return ::SetFocus(view->second) == view->second;
}

}  // namespace flutter
