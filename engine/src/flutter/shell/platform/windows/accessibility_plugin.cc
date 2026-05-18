// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/accessibility_plugin.h"

#include <variant>

#include "flutter/fml/logging.h"
#include "flutter/fml/platform/win/wstring_conversion.h"
#include "flutter/shell/platform/common/client_wrapper/include/flutter/standard_message_codec.h"
#include "flutter/shell/platform/windows/flutter_windows_engine.h"
#include "flutter/shell/platform/windows/flutter_windows_view.h"

namespace flutter {

namespace {

static constexpr char kAccessibilityChannelName[] = "flutter/accessibility";
static constexpr char kTypeKey[] = "type";
static constexpr char kDataKey[] = "data";
static constexpr char kMessageKey[] = "message";
static constexpr char kViewIdKey[] = "viewId";
static constexpr char kAnnounceValue[] = "announce";

// Handles messages like:
// {"type": "announce", "data": {"message": "Hello"}}
void HandleMessage(AccessibilityPlugin* plugin, const EncodableValue& message) {
  const auto* map = std::get_if<EncodableMap>(&message);
  if (!map) {
    FML_LOG(ERROR) << "Accessibility message must be a map.";
    return;
  }
  const auto& type_itr = map->find(EncodableValue{kTypeKey});
  const auto& data_itr = map->find(EncodableValue{kDataKey});
  if (type_itr == map->end()) {
    FML_LOG(ERROR) << "Accessibility message must have a 'type' property.";
    return;
  }
  if (data_itr == map->end()) {
    FML_LOG(ERROR) << "Accessibility message must have a 'data' property.";
    return;
  }
  const auto* type = std::get_if<std::string>(&type_itr->second);
  const auto* data = std::get_if<EncodableMap>(&data_itr->second);
  if (!type) {
    FML_LOG(ERROR) << "Accessibility message 'type' property must be a string.";
    return;
  }
  if (!data) {
    FML_LOG(ERROR) << "Accessibility message 'data' property must be a map.";
    return;
  }

  if (type->compare(kAnnounceValue) == 0) {
    const auto& message_itr = data->find(EncodableValue{kMessageKey});
    if (message_itr == data->end()) {
      return;
    }
    const auto* message = std::get_if<std::string>(&message_itr->second);
    if (!message) {
      return;
    }

    const auto& view_itr = data->find(EncodableValue{kViewIdKey});
    if (view_itr == data->end()) {
      FML_LOG(ERROR) << "Announce message 'viewId' property is missing.";
      return;
    }

    // The viewId may be encoded as either a 32-bit or 64-bit integer.
    auto const view_id = view_itr->second.TryGetLongValue();
    if (!view_id) {
      FML_LOG(ERROR)
          << "Announce message 'viewId' property must be a FlutterViewId.";
      return;
    }

    plugin->Announce(*view_id, *message);
  } else {
    FML_LOG(WARNING) << "Accessibility message type '" << *type
                     << "' is not supported.";
  }
}

}  // namespace

AccessibilityPlugin::AccessibilityPlugin(FlutterWindowsEngine* engine)
    : engine_(engine) {}

void AccessibilityPlugin::SetUp(BinaryMessenger* binary_messenger,
                                AccessibilityPlugin* plugin) {
  BasicMessageChannel<> channel{binary_messenger, kAccessibilityChannelName,
                                &StandardMessageCodec::GetInstance()};

  channel.SetMessageHandler(
      [plugin](const EncodableValue& message,
               const MessageReply<EncodableValue>& reply) {
        HandleMessage(plugin, message);

        // The accessibility channel does not support error handling.
        // Always return an empty response even on failure.
        reply(EncodableValue{std::monostate{}});
      });
}

void AccessibilityPlugin::Announce(const FlutterViewId view_id,
                                   const std::string_view message) {
  if (!engine_->semantics_enabled()) {
    return;
  }

  auto view = engine_->view(view_id);
  if (!view) {
    return;
  }

  std::wstring wide_text = fml::Utf8ToWideString(message);
  view->AnnounceAlert(wide_text);
}

}  // namespace flutter
