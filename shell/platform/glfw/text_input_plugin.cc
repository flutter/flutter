// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/glfw/text_input_plugin.h"

#include <cstdint>
#include <iostream>

#include "flutter/shell/platform/common/cpp/json_method_codec.h"

static constexpr char kSetEditingStateMethod[] = "TextInput.setEditingState";
static constexpr char kClearClientMethod[] = "TextInput.clearClient";
static constexpr char kSetClientMethod[] = "TextInput.setClient";
static constexpr char kShowMethod[] = "TextInput.show";
static constexpr char kHideMethod[] = "TextInput.hide";

static constexpr char kMultilineInputType[] = "TextInputType.multiline";

static constexpr char kUpdateEditingStateMethod[] =
    "TextInputClient.updateEditingState";
static constexpr char kPerformActionMethod[] = "TextInputClient.performAction";

static constexpr char kSelectionBaseKey[] = "selectionBase";
static constexpr char kSelectionExtentKey[] = "selectionExtent";

static constexpr char kTextKey[] = "text";

static constexpr char kChannelName[] = "flutter/textinput";

static constexpr char kBadArgumentError[] = "Bad Arguments";
static constexpr char kInternalConsistencyError[] =
    "Internal Consistency Error";

namespace flutter {

void TextInputPlugin::CharHook(GLFWwindow* window, unsigned int code_point) {
  if (active_model_ == nullptr) {
    return;
  }
  active_model_->AddCodePoint(code_point);
  SendStateUpdate(*active_model_);
}

void TextInputPlugin::KeyboardHook(GLFWwindow* window,
                                   int key,
                                   int scancode,
                                   int action,
                                   int mods) {
  if (active_model_ == nullptr) {
    return;
  }
  if (action == GLFW_PRESS || action == GLFW_REPEAT) {
    switch (key) {
      case GLFW_KEY_LEFT:
        if (active_model_->MoveCursorBack()) {
          SendStateUpdate(*active_model_);
        }
        break;
      case GLFW_KEY_RIGHT:
        if (active_model_->MoveCursorForward()) {
          SendStateUpdate(*active_model_);
        }
        break;
      case GLFW_KEY_END:
        active_model_->MoveCursorToEnd();
        SendStateUpdate(*active_model_);
        break;
      case GLFW_KEY_HOME:
        active_model_->MoveCursorToBeginning();
        SendStateUpdate(*active_model_);
        break;
      case GLFW_KEY_BACKSPACE:
        if (active_model_->Backspace()) {
          SendStateUpdate(*active_model_);
        }
        break;
      case GLFW_KEY_DELETE:
        if (active_model_->Delete()) {
          SendStateUpdate(*active_model_);
        }
        break;
      case GLFW_KEY_ENTER:
        EnterPressed(active_model_.get());
        break;
      default:
        break;
    }
  }
}

TextInputPlugin::TextInputPlugin(flutter::BinaryMessenger* messenger)
    : channel_(std::make_unique<flutter::MethodChannel<rapidjson::Document>>(
          messenger,
          kChannelName,
          &flutter::JsonMethodCodec::GetInstance())),
      active_model_(nullptr) {
  channel_->SetMethodCallHandler(
      [this](
          const flutter::MethodCall<rapidjson::Document>& call,
          std::unique_ptr<flutter::MethodResult<rapidjson::Document>> result) {
        HandleMethodCall(call, std::move(result));
      });
}

TextInputPlugin::~TextInputPlugin() = default;

void TextInputPlugin::HandleMethodCall(
    const flutter::MethodCall<rapidjson::Document>& method_call,
    std::unique_ptr<flutter::MethodResult<rapidjson::Document>> result) {
  const std::string& method = method_call.method_name();

  if (method.compare(kShowMethod) == 0 || method.compare(kHideMethod) == 0) {
    // These methods are no-ops.
  } else if (method.compare(kClearClientMethod) == 0) {
    active_model_ = nullptr;
  } else {
    // Every following method requires args.
    if (!method_call.arguments() || method_call.arguments()->IsNull()) {
      result->Error(kBadArgumentError, "Method invoked without args");
      return;
    }
    const rapidjson::Document& args = *method_call.arguments();

    if (method.compare(kSetClientMethod) == 0) {
      // TODO(awdavies): There's quite a wealth of arguments supplied with this
      // method, and they should be inspected/used.
      const rapidjson::Value& client_id_json = args[0];
      const rapidjson::Value& client_config = args[1];
      if (client_id_json.IsNull()) {
        result->Error(kBadArgumentError, "Could not set client, ID is null.");
        return;
      }
      if (client_config.IsNull()) {
        result->Error(kBadArgumentError,
                      "Could not set client, missing arguments.");
      }
      int client_id = client_id_json.GetInt();
      active_model_ =
          std::make_unique<TextInputModel>(client_id, client_config);
    } else if (method.compare(kSetEditingStateMethod) == 0) {
      if (active_model_ == nullptr) {
        result->Error(
            kInternalConsistencyError,
            "Set editing state has been invoked, but no client is set.");
        return;
      }
      auto text = args.FindMember(kTextKey);
      if (text == args.MemberEnd() || text->value.IsNull()) {
        result->Error(kBadArgumentError,
                      "Set editing state has been invoked, but without text.");
        return;
      }
      auto selection_base = args.FindMember(kSelectionBaseKey);
      auto selection_extent = args.FindMember(kSelectionExtentKey);
      if (selection_base == args.MemberEnd() ||
          selection_base->value.IsNull() ||
          selection_extent == args.MemberEnd() ||
          selection_extent->value.IsNull()) {
        result->Error(kInternalConsistencyError,
                      "Selection base/extent values invalid.");
        return;
      }
      active_model_->SetEditingState(selection_base->value.GetInt(),
                                     selection_extent->value.GetInt(),
                                     text->value.GetString());
    } else {
      // Unhandled method.
      result->NotImplemented();
      return;
    }
  }
  // All error conditions return early, so if nothing has gone wrong indicate
  // success.
  result->Success();
}

void TextInputPlugin::SendStateUpdate(const TextInputModel& model) {
  channel_->InvokeMethod(kUpdateEditingStateMethod, model.GetState());
}

void TextInputPlugin::EnterPressed(TextInputModel* model) {
  if (model->input_type() == kMultilineInputType) {
    model->AddCodePoint('\n');
    SendStateUpdate(*model);
  }
  auto args = std::make_unique<rapidjson::Document>(rapidjson::kArrayType);
  auto& allocator = args->GetAllocator();
  args->PushBack(model->client_id(), allocator);
  args->PushBack(rapidjson::Value(model->input_action(), allocator).Move(),
                 allocator);

  channel_->InvokeMethod(kPerformActionMethod, std::move(args));
}

}  // namespace flutter
