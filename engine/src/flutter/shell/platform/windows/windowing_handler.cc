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
constexpr char kCreatePopupMethod[] = "createPopup";

// The method to destroy a window.
constexpr char kDestroyWindowMethod[] = "destroyWindow";

// Keys used in method calls.
constexpr char kAnchorRectKey[] = "anchorRect";
constexpr char kChildAnchorKey[] = "childAnchor";
constexpr char kConstraintAdjustmentKey[] = "constraintAdjustment";
constexpr char kMaxSizeKey[] = "maxSize";
constexpr char kMinSizeKey[] = "minSize";
constexpr char kOffsetKey[] = "offset";
constexpr char kParentAnchorKey[] = "parentAnchor";
constexpr char kParentViewIdKey[] = "parentViewId";
constexpr char kPositionerKey[] = "positioner";
constexpr char kRelativePositionKey[] = "relativePosition";
constexpr char kSizeKey[] = "size";
constexpr char kStateKey[] = "state";
constexpr char kTitleKey[] = "title";
constexpr char kViewIdKey[] = "viewId";

// Error codes used for responses.
constexpr char kInvalidValueError[] = "Invalid Value";
constexpr char kUnavailableError[] = "Unavailable";

// Retrieves the value associated with |key| from |map|, ensuring it matches
// the expected type |T| or std::monostate. Returns a pair where the first
// element is the value if found and correctly typed (or std::nullopt if the
// value is null), and the second element is a boolean indicating success (true)
// or error (false). If |key| doesn't exist, or if it exists but is not of
// either type |T| or std::monostate, an error is logged in |result| and the
// function returns {std::nullopt, false}.
template <typename T>
std::pair<std::optional<T>, bool> GetSingleValueForKeyOrSendError(
    std::string const& key,
    flutter::EncodableMap const* map,
    flutter::MethodResult<>& result) {
  auto const it = map->find(flutter::EncodableValue(key));
  if (it == map->end()) {
    result.Error(kInvalidValueError,
                 "Map does not contain required '" + key + "' key.");
    return {std::nullopt, false};
  }
  if (auto const* const value = std::get_if<T>(&it->second)) {
    return {*value, true};
  }
  if (std::holds_alternative<std::monostate>(it->second)) {
    return {std::nullopt, true};
  }

  result.Error(kInvalidValueError, "Value for '" + key +
                                       "' key must be of type '" +
                                       typeid(T).name() + "'.");
  return {std::nullopt, false};
}

// Retrieves a list of values associated with |key| from |map|, ensuring the
// list has only elements of type |T|. If |Size| is provided and greater than 0,
// the number of elements in the list is also checked. Returns a pair where the
// first element is the list of values and the second element is a boolean
// indicating success (true) or error (false). The first element of the pair is
// set to std::nullopt on error or if the value for the key is null. If |key|
// doesn't exist, or if it exists but is not of either type std::vector<T> or
// std::monostate, an error is logged in |result| and the function returns
// {std::nullopt, false}.
template <typename T, size_t Size = 0>
std::pair<std::optional<std::vector<T>>, bool> GetListOfValuesForKeyOrSendError(
    std::string const& key,
    flutter::EncodableMap const* map,
    flutter::MethodResult<>& result) {
  auto const it = map->find(flutter::EncodableValue(key));
  if (it == map->end()) {
    result.Error(kInvalidValueError,
                 "Map does not contain required '" + key + "' key.");
    return {std::nullopt, false};
  }
  if (std::holds_alternative<std::monostate>(it->second)) {
    return {std::nullopt, true};
  }
  if (auto const* const array =
          std::get_if<std::vector<flutter::EncodableValue>>(&it->second)) {
    if (Size && array->size() != Size) {
      result.Error(kInvalidValueError, "Array for '" + key +
                                           "' key must have " +
                                           std::to_string(Size) + " values.");
      return {std::nullopt, false};
    }
    std::vector<T> decoded_values;
    if (Size) {
      decoded_values.reserve(Size);
    }
    for (flutter::EncodableValue const& value : *array) {
      if (std::holds_alternative<T>(value)) {
        decoded_values.push_back(std::get<T>(value));
      } else {
        result.Error(kInvalidValueError,
                     "Array for '" + key +
                         "' key must only have values of type '" +
                         typeid(T).name() + "'.");
        return {std::nullopt, false};
      }
    }
    return {std::move(decoded_values), true};
  }

  result.Error(kInvalidValueError,
               "Value for key '" + key + "' key must be an array.");
  return {std::nullopt, false};
}

// Converts the string representation of |WindowPositionerAnchor| defined in the
// framework to a |flutter::WindowPositioner::Anchor|. Returns std::nullopt if
// the given string is invalid.
std::optional<flutter::WindowPositioner::Anchor> StringToWindowPositionerAnchor(
    std::string_view str) {
  if (str == "WindowPositionerAnchor.center") {
    return flutter::WindowPositioner::Anchor::kCenter;
  }
  if (str == "WindowPositionerAnchor.top") {
    return flutter::WindowPositioner::Anchor::kTop;
  }
  if (str == "WindowPositionerAnchor.bottom") {
    return flutter::WindowPositioner::Anchor::kBottom;
  }
  if (str == "WindowPositionerAnchor.left") {
    return flutter::WindowPositioner::Anchor::kLeft;
  }
  if (str == "WindowPositionerAnchor.right") {
    return flutter::WindowPositioner::Anchor::kRight;
  }
  if (str == "WindowPositionerAnchor.topLeft") {
    return flutter::WindowPositioner::Anchor::kTopLeft;
  }
  if (str == "WindowPositionerAnchor.bottomLeft") {
    return flutter::WindowPositioner::Anchor::kBottomLeft;
  }
  if (str == "WindowPositionerAnchor.topRight") {
    return flutter::WindowPositioner::Anchor::kTopRight;
  }
  if (str == "WindowPositionerAnchor.bottomRight") {
    return flutter::WindowPositioner::Anchor::kBottomRight;
  }
  return std::nullopt;
}

// Converts the string representation of |WindowPositionerConstraintAdjustment|
// defined in the framework to a
// |flutter::WindowPositioner::ConstraintAdjustment|. Returns std::nullopt if
// the given string is invalid.
std::optional<flutter::WindowPositioner::ConstraintAdjustment>
StringToWindowPositionerConstraintAdjustment(std::string_view str) {
  if (str == "WindowPositionerConstraintAdjustment.slideX") {
    return flutter::WindowPositioner::ConstraintAdjustment::kSlideX;
  }
  if (str == "WindowPositionerConstraintAdjustment.slideY") {
    return flutter::WindowPositioner::ConstraintAdjustment::kSlideY;
  }
  if (str == "WindowPositionerConstraintAdjustment.flipX") {
    return flutter::WindowPositioner::ConstraintAdjustment::kFlipX;
  }
  if (str == "WindowPositionerConstraintAdjustment.flipY") {
    return flutter::WindowPositioner::ConstraintAdjustment::kFlipY;
  }
  if (str == "WindowPositionerConstraintAdjustment.resizeX") {
    return flutter::WindowPositioner::ConstraintAdjustment::kResizeX;
  }
  if (str == "WindowPositionerConstraintAdjustment.resizeY") {
    return flutter::WindowPositioner::ConstraintAdjustment::kResizeY;
  }
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
  } else if (method == kCreatePopupMethod) {
    HandleCreateWindow(WindowArchetype::kPopup, method_call, *result);
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

  WindowCreationSettings settings;
  settings.archetype = archetype;

  // Get value for the 'size' key (non-nullable).
  if (auto const [size_list, success] =
          GetListOfValuesForKeyOrSendError<double, 2>(kSizeKey, map, result);
      success) {
    if (!size_list.has_value()) {
      result.Error(kInvalidValueError, "Value for the '" +
                                           std::string(kSizeKey) +
                                           "' key must not be null.");
      return;
    }
    settings.size = {size_list->at(0), size_list->at(1)};
  } else {
    return;
  }

  if (archetype == WindowArchetype::kPopup) {
    // Get value for the 'parentViewId' key (non-nullable)
    if (auto const [parent_view_id, success] =
            GetSingleValueForKeyOrSendError<int>(kParentViewIdKey, map, result);
        success) {
      if (!parent_view_id.has_value()) {
        result.Error(kInvalidValueError, "Value for the '" +
                                             std::string(kParentViewIdKey) +
                                             "' key must not be null.");
        return;
      }
      if (*parent_view_id < 0) {
        result.Error(kInvalidValueError,
                     "Value for '" + std::string(kParentViewIdKey) + "' (" +
                         std::to_string(settings.parent_view_id.value()) +
                         ") must be equal or greater than zero.");
        return;
      }
      settings.parent_view_id = parent_view_id;
    } else {
      return;
    }

    // Get value for the 'positioner' key (non-nullable)
    if (auto const [positioner_map, success] =
            GetSingleValueForKeyOrSendError<EncodableMap>(kPositionerKey, map,
                                                          result);
        success) {
      if (!positioner_map.has_value()) {
        result.Error(kInvalidValueError, "Value for the '" +
                                             std::string(kPositionerKey) +
                                             "' key must not be null.");
        return;
      }

      WindowPositioner positioner;

      // Get value for the 'anchorRect' key (nullable)
      if (auto const [anchor_rect, success] =
              GetListOfValuesForKeyOrSendError<double, 4>(
                  kAnchorRectKey, &positioner_map.value(), result);
          success) {
        if (anchor_rect.has_value()) {
          positioner.anchor_rect = {{anchor_rect->at(0), anchor_rect->at(1)},
                                    {anchor_rect->at(2) - anchor_rect->at(0),
                                     anchor_rect->at(3) - anchor_rect->at(1)}};
        }
      } else {
        return;
      }

      // Get value for the 'parentAnchor' key (non-nullable)
      if (auto const [parent_anchor, success] =
              GetSingleValueForKeyOrSendError<std::string>(
                  kParentAnchorKey, &positioner_map.value(), result);
          success) {
        if (!parent_anchor.has_value()) {
          result.Error(kInvalidValueError, "Value for the '" +
                                               std::string(kParentAnchorKey) +
                                               "' key must not be null.");
          return;
        }
        auto const anchor_opt = StringToWindowPositionerAnchor(*parent_anchor);
        if (!anchor_opt.has_value()) {
          result.Error(kInvalidValueError,
                       "Value for the '" + std::string(kParentAnchorKey) +
                           "' key is not a valid string representation of "
                           "WindowPositionerAnchor.");
          return;
        }
        positioner.parent_anchor = *anchor_opt;
      } else {
        return;
      }

      // Get value for the 'childAnchor' key (non-nullable)
      if (auto const [child_anchor, success] =
              GetSingleValueForKeyOrSendError<std::string>(
                  kChildAnchorKey, &positioner_map.value(), result);
          success) {
        if (!child_anchor.has_value()) {
          result.Error(kInvalidValueError, "Value for the '" +
                                               std::string(kChildAnchorKey) +
                                               "' key must not be null.");
          return;
        }
        auto const anchor_opt = StringToWindowPositionerAnchor(*child_anchor);
        if (!anchor_opt.has_value()) {
          result.Error(kInvalidValueError,
                       "Value for the '" + std::string(kChildAnchorKey) +
                           "' key is not a valid string representation of "
                           "WindowPositionerAnchor.");
          return;
        }
        positioner.child_anchor = *anchor_opt;
      } else {
        return;
      }

      // Get value for the 'offset' key (non-nullable)
      if (auto const [offset, success] =
              GetListOfValuesForKeyOrSendError<double, 2>(
                  kOffsetKey, &positioner_map.value(), result);
          success) {
        if (!offset.has_value()) {
          result.Error(kInvalidValueError, "Value for the '" +
                                               std::string(kOffsetKey) +
                                               "' key must not be null.");
          return;
        }
        positioner.offset = {offset->at(0), offset->at(1)};
      } else {
        return;
      }

      // Get value for the 'constraintAdjustment' key (non-nullable)
      if (auto const [constraint_adjustments, success] =
              GetListOfValuesForKeyOrSendError<std::string>(
                  kConstraintAdjustmentKey, &positioner_map.value(), result);
          success) {
        if (!constraint_adjustments.has_value()) {
          result.Error(kInvalidValueError,
                       "Value for the '" +
                           std::string(kConstraintAdjustmentKey) +
                           "' key must not be null.");
          return;
        }
        for (auto const& adjustment_str : *constraint_adjustments) {
          auto const adjustment_opt =
              StringToWindowPositionerConstraintAdjustment(adjustment_str);
          if (!adjustment_opt) {
            result.Error(kInvalidValueError,
                         "Value in the array of the '" +
                             std::string(kConstraintAdjustmentKey) +
                             "' key is not a valid string representation of "
                             "WindowPositionerConstraintAdjustment.");
            return;
          }
          positioner.constraint_adjustment =
              static_cast<WindowPositioner::ConstraintAdjustment>(
                  static_cast<size_t>(positioner.constraint_adjustment) |
                  static_cast<size_t>(*adjustment_opt));
        }
      } else {
        return;
      }

      settings.positioner = positioner;
    } else {
      return;
    }
  }

  if (archetype == WindowArchetype::kRegular ||
      archetype == WindowArchetype::kPopup) {
    // Get value for the 'minSize' key (nullable).
    if (auto const [list, success] =
            GetListOfValuesForKeyOrSendError<double, 2>(kMinSizeKey, map,
                                                        result);
        success) {
      if (list.has_value()) {
        settings.min_size = {list->at(0), list->at(1)};
      }
    } else {
      return;
    }
    // Get value for the 'maxSize' key (nullable).
    if (auto const [list, success] =
            GetListOfValuesForKeyOrSendError<double, 2>(kMaxSizeKey, map,
                                                        result);
        success) {
      if (list.has_value()) {
        settings.max_size = {list->at(0), list->at(1)};
      }
    } else {
      return;
    }
  }

  if (archetype == WindowArchetype::kRegular) {
    // Get value for the 'title' key (nullable).
    if (auto const [title, success] =
            GetSingleValueForKeyOrSendError<std::string>(kTitleKey, map,
                                                         result);
        success) {
      settings.title = title;
    } else {
      return;
    }

    // Get value for the 'state' key (nullable).
    if (auto const [state, success] =
            GetSingleValueForKeyOrSendError<std::string>(kStateKey, map,
                                                         result);
        success) {
      if (state) {
        settings.state = StringToWindowState(*state);
      }
    } else {
      return;
    }
  }

  if (std::optional<WindowMetadata> const data_opt =
          controller_->CreateHostWindow(settings)) {
    WindowMetadata const& data = data_opt.value();
    EncodableMap map;

    map.insert({EncodableValue(kViewIdKey), EncodableValue(data.view_id)});
    map.insert(
        {EncodableValue(kSizeKey),
         EncodableValue(EncodableList{EncodableValue(data.size.width()),
                                      EncodableValue(data.size.height())})});
    if (archetype == WindowArchetype::kRegular) {
      assert(data.state.has_value());
      map.insert({EncodableValue(kStateKey),
                  EncodableValue(WindowStateToString(data.state.value()))});
    } else if (archetype == WindowArchetype::kPopup) {
      assert(data.parent_id.has_value());
      map.insert({EncodableValue(kParentViewIdKey),
                  EncodableValue(data.parent_id.value())});

      assert(data.relative_position.has_value());
      map.insert({EncodableValue(kRelativePositionKey),
                  EncodableValue(EncodableList{
                      EncodableValue(data.relative_position->x()),
                      EncodableValue(data.relative_position->y())})});
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

  // Get value for the 'viewId' key (non-nullable).
  if (auto const [view_id_opt, success] =
          GetSingleValueForKeyOrSendError<int>(kViewIdKey, map, result);
      success) {
    if (!view_id_opt.has_value()) {
      result.Error(kInvalidValueError, "Value for the '" +
                                           std::string(kViewIdKey) +
                                           "' key must not be null.");
      return;
    }
    if (*view_id_opt < 0) {
      result.Error(kInvalidValueError,
                   "Value for '" + std::string(kViewIdKey) + "' (" +
                       std::to_string(*view_id_opt) + ") cannot be negative.");
      return;
    }
    if (!controller_->DestroyHostWindow(*view_id_opt)) {
      result.Error(kInvalidValueError, "Can't find window with view ID " +
                                           std::to_string(*view_id_opt) + ".");
      return;
    }
    result.Success();
  } else {
    return;
  }
}

}  // namespace flutter