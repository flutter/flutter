// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/windowing_handler.h"

#include "flutter/fml/logging.h"
#include "flutter/shell/platform/common/client_wrapper/include/flutter/standard_method_codec.h"
#include "flutter/shell/platform/common/windowing.h"

namespace {

// Name of the windowing channel.
constexpr char kChannelName[] = "flutter/windowing";

// Methods for creating different types of windows.
constexpr char kCreateWindowMethod[] = "createWindow";

// The method to destroy a window.
constexpr char kDestroyWindowMethod[] = "destroyWindow";

// Keys used in method calls.
constexpr char kMaxSizeKey[] = "maxSize";
constexpr char kMinSizeKey[] = "minSize";
constexpr char kSizeKey[] = "size";
constexpr char kStateKey[] = "state";
constexpr char kTitleKey[] = "title";
constexpr char kViewIdKey[] = "viewId";

// Error codes used for responses.
constexpr char kInvalidValueError[] = "Invalid Value";
constexpr char kUnavailableError[] = "Unavailable";

// Retrieves the value associated with |key| from |map|, ensuring it matches
// the expected type |T| or std::monostate. Returns the value if found and
// correctly typed, and std::nullopt if the value is null. An error is logged in
// |result| if |key| doesn't exist, or if it exists but is not of either type
// |T| or std::monostate.
template <typename T>
std::optional<T> GetSingleValueForKeyOrSendError(
    std::string const& key,
    flutter::EncodableMap const* map,
    flutter::MethodResult<>& result) {
  auto const it = map->find(flutter::EncodableValue(key));
  if (it == map->end()) {
    result.Error(kInvalidValueError,
                 "Map does not contain required '" + key + "' key.");
    return std::nullopt;
  }
  if (auto const* const value = std::get_if<T>(&it->second)) {
    return *value;
  }
  if (std::holds_alternative<std::monostate>(it->second)) {
    return std::nullopt;
  }

  result.Error(kInvalidValueError, "Value for '" + key +
                                       "' key must be of type '" +
                                       typeid(T).name() + "'.");
  return std::nullopt;
}

// Retrieves a list of values associated with |key| from |map|, ensuring the
// list has |Size| elements, all of type |T|. Returns the list if found and
// valid, and sts::nullopt if the value for the key is null. An error is logged
// in |result| if |key| doesn't exist, or if it exists but is not of either type
// std::vector<T> or std::monostate.
template <typename T, size_t Size>
std::optional<std::vector<T>> GetListOfValuesForKeyOrSendError(
    std::string const& key,
    flutter::EncodableMap const* map,
    flutter::MethodResult<>& result) {
  auto const it = map->find(flutter::EncodableValue(key));
  if (it == map->end()) {
    result.Error(kInvalidValueError,
                 "Map does not contain required '" + key + "' key.");
    return std::nullopt;
  }
  if (std::holds_alternative<std::monostate>(it->second)) {
    return std::nullopt;
  }
  if (auto const* const array =
          std::get_if<std::vector<flutter::EncodableValue>>(&it->second)) {
    if (array->size() != Size) {
      result.Error(kInvalidValueError, "Array for '" + key +
                                           "' key must have " +
                                           std::to_string(Size) + " values.");
      return std::nullopt;
    }
    std::vector<T> decoded_values;
    decoded_values.reserve(Size);
    for (flutter::EncodableValue const& value : *array) {
      if (std::holds_alternative<T>(value)) {
        decoded_values.push_back(std::get<T>(value));
      } else {
        result.Error(kInvalidValueError,
                     "Array for '" + key +
                         "' key must only have values of type '" +
                         typeid(T).name() + "'.");
        return std::nullopt;
      }
    }
    return decoded_values;
  }

  // If the value exists but is not a list
  result.Error(kInvalidValueError,
               "Value for key '" + key + "' key must be an array.");
  return std::nullopt;
}

}  // namespace

namespace flutter {

WindowingHandler::WindowingHandler(BinaryMessenger* messenger,
                                   FlutterHostWindowController* controller)
    : channel_(std::make_shared<MethodChannel<EncodableValue>>(
          messenger,
          kChannelName,
          &StandardMethodCodec::GetInstance())),
      controller_(controller) {
  channel_->SetMethodCallHandler(
      [this](const MethodCall<EncodableValue>& call,
             std::unique_ptr<MethodResult<EncodableValue>> result) {
        HandleMethodCall(call, std::move(result));
      });
  controller_->SetMethodChannel(channel_);
}

void WindowingHandler::HandleMethodCall(
    const MethodCall<EncodableValue>& method_call,
    std::unique_ptr<MethodResult<EncodableValue>> result) {
  const std::string& method = method_call.method_name();

  if (method == kCreateWindowMethod) {
    HandleCreateWindow(WindowArchetype::kRegular, method_call, *result);
  } else if (method == kDestroyWindowMethod) {
    HandleDestroyWindow(method_call, *result);
  } else {
    result->NotImplemented();
  }
}

void WindowingHandler::HandleCreateWindow(WindowArchetype archetype,
                                          MethodCall<> const& call,
                                          MethodResult<>& result) {
  auto const* const arguments = call.arguments();
  auto const* const map = std::get_if<EncodableMap>(arguments);
  if (!map) {
    result.Error(kInvalidValueError, "Method call argument is not a map.");
    return;
  }

  // Helper lambda to check and report invalid window size
  auto const has_valid_window_size =
      [&result](Size size, std::string_view key_name) -> bool {
    if (size.width() <= 0 || size.height() <= 0) {
      result.Error(kInvalidValueError,
                   "Values for the '" + std::string(key_name) + "' key (" +
                       std::to_string(size.width()) + ", " +
                       std::to_string(size.height()) + ") must be positive.");
      return false;
    }
    return true;
  };

  WindowCreationSettings settings;

  // Get value for the 'size' key (non-nullable)
  auto const size_list =
      GetListOfValuesForKeyOrSendError<double, 2>(kSizeKey, map, result);
  if (!size_list) {
    result.Error(kInvalidValueError, "Value for '" + std::string(kSizeKey) +
                                         "' key must not be null.");
    return;
  }
  settings.size = {size_list->at(0), size_list->at(1)};
  if (!has_valid_window_size(settings.size, kSizeKey)) {
    return;
  }

  if (archetype == WindowArchetype::kRegular) {
    // Get value for the 'minSize' key (nullable)
    if (auto const list = GetListOfValuesForKeyOrSendError<double, 2>(
            kMinSizeKey, map, result)) {
      settings.min_size = {list->at(0), list->at(1)};
      if (!has_valid_window_size(*settings.min_size, kMinSizeKey)) {
        return;
      }
    }
    // Get value for the 'maxSize' key (nullable)
    if (auto const list = GetListOfValuesForKeyOrSendError<double, 2>(
            kMaxSizeKey, map, result)) {
      settings.max_size = {list->at(0), list->at(1)};
      if (!has_valid_window_size(*settings.max_size, kMaxSizeKey)) {
        return;
      }
    }
    // Get value for the 'title' key (nullable)
    settings.title =
        GetSingleValueForKeyOrSendError<std::string>(kTitleKey, map, result);

    // Get value for the 'state' key (nullable)
    if (std::optional<std::string> state_string =
            GetSingleValueForKeyOrSendError<std::string>(kStateKey, map,
                                                         result)) {
      settings.state = StringToWindowState(*state_string);
    }
  }

  if (std::optional<WindowMetadata> const data_opt =
          controller_->CreateHostWindow(settings)) {
    WindowMetadata const& data = data_opt.value();
    EncodableMap map;

    if (archetype == WindowArchetype::kRegular) {
      map.insert({EncodableValue(kViewIdKey), EncodableValue(data.view_id)});
      map.insert(
          {EncodableValue(kSizeKey),
           EncodableValue(EncodableList{EncodableValue(data.size.width()),
                                        EncodableValue(data.size.height())})});
      assert(data.state.has_value());
      map.insert({EncodableValue(kStateKey),
                  EncodableValue(WindowStateToString(data.state.value()))});
    }

    result.Success(EncodableValue(map));
  } else {
    result.Error(kUnavailableError, "Can't create window.");
  }
}

void WindowingHandler::HandleDestroyWindow(MethodCall<> const& call,
                                           MethodResult<>& result) {
  auto const* const arguments = call.arguments();
  auto const* const map = std::get_if<EncodableMap>(arguments);
  if (!map) {
    result.Error(kInvalidValueError, "Method call argument is not a map.");
    return;
  }

  auto const view_id =
      GetSingleValueForKeyOrSendError<int>(kViewIdKey, map, result);
  if (!view_id) {
    result.Error(kInvalidValueError, "Value for '" + std::string(kViewIdKey) +
                                         "' key must not be null.");
    return;
  }
  if (view_id.value() < 0) {
    result.Error(kInvalidValueError,
                 "Value for '" + std::string(kViewIdKey) + "' (" +
                     std::to_string(view_id.value()) + ") cannot be negative.");
    return;
  }

  if (!controller_->DestroyHostWindow(view_id.value())) {
    result.Error(kInvalidValueError,
                 "Can't find window with '" + std::string(kViewIdKey) + "' (" +
                     std::to_string(view_id.value()) + ").");
    return;
  }

  result.Success();
}

}  // namespace flutter
