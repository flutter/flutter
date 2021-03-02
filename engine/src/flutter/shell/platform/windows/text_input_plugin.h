// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_WINDOWS_TEXT_INPUT_PLUGIN_H_
#define FLUTTER_SHELL_PLATFORM_WINDOWS_TEXT_INPUT_PLUGIN_H_

#include <array>
#include <map>
#include <memory>

#include "flutter/shell/platform/common/client_wrapper/include/flutter/binary_messenger.h"
#include "flutter/shell/platform/common/client_wrapper/include/flutter/method_channel.h"
#include "flutter/shell/platform/common/geometry.h"
#include "flutter/shell/platform/common/json_method_codec.h"
#include "flutter/shell/platform/common/text_input_model.h"
#include "flutter/shell/platform/windows/keyboard_handler_base.h"
#include "flutter/shell/platform/windows/public/flutter_windows.h"
#include "flutter/shell/platform/windows/text_input_plugin_delegate.h"

namespace flutter {

class FlutterWindowsView;

// Implements a text input plugin.
//
// Specifically handles window events within windows.
class TextInputPlugin : public KeyboardHandlerBase {
 public:
  explicit TextInputPlugin(flutter::BinaryMessenger* messenger,
                           TextInputPluginDelegate* delegate);

  virtual ~TextInputPlugin();

  // |KeyboardHandlerBase|
  bool KeyboardHook(FlutterWindowsView* view,
                    int key,
                    int scancode,
                    int action,
                    char32_t character,
                    bool extended,
                    bool was_down) override;

  // |KeyboardHandlerBase|
  void TextHook(FlutterWindowsView* view, const std::u16string& text) override;

  // |KeyboardHandlerBase|
  void ComposeBeginHook() override;

  // |KeyboardHandlerBase|
  void ComposeCommitHook() override;

  // |KeyboardHandlerBase|
  void ComposeEndHook() override;

  // |KeyboardHandlerBase|
  void ComposeChangeHook(const std::u16string& text, int cursor_pos) override;

 private:
  // Sends the current state of the given model to the Flutter engine.
  void SendStateUpdate(const TextInputModel& model);

  // Sends an action triggered by the Enter key to the Flutter engine.
  void EnterPressed(TextInputModel* model);

  // Called when a method is called on |channel_|;
  void HandleMethodCall(
      const flutter::MethodCall<rapidjson::Document>& method_call,
      std::unique_ptr<flutter::MethodResult<rapidjson::Document>> result);

  // Returns the composing rect, or if IME composing mode is not active, the
  // cursor rect in the PipelineOwner root coordinate system.
  Rect GetCursorRect() const;

  // The MethodChannel used for communication with the Flutter engine.
  std::unique_ptr<flutter::MethodChannel<rapidjson::Document>> channel_;

  // The associated |TextInputPluginDelegate|.
  TextInputPluginDelegate* delegate_;

  // The active client id.
  int client_id_;

  // The active model. nullptr if not set.
  std::unique_ptr<TextInputModel> active_model_;

  // Keyboard type of the client. See available options:
  // https://api.flutter.dev/flutter/services/TextInputType-class.html
  std::string input_type_;

  // An action requested by the user on the input client. See available options:
  // https://api.flutter.dev/flutter/services/TextInputAction-class.html
  std::string input_action_;

  // The smallest rect, in local coordinates, of the text in the composing
  // range, or of the caret in the case where there is no current composing
  // range. This value is updated via `TextInput.setMarkedTextRect` messages
  // over the text input channel.
  Rect composing_rect_;

  // A 4x4 matrix that maps from `EditableText` local coordinates to the
  // coordinate system of `PipelineOwner.rootNode`.
  std::array<std::array<double, 4>, 4> editabletext_transform_ = {
      0.0, 0.0, 0.0, 0.0,  //
      0.0, 0.0, 0.0, 0.0,  //
      0.0, 0.0, 0.0, 0.0,  //
      0.0, 0.0, 0.0, 0.0};
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_WINDOWS_TEXT_INPUT_PLUGIN_H_
