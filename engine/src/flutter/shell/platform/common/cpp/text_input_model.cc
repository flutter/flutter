// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/common/cpp/text_input_model.h"

#include <iostream>

// TODO(awdavies): Need to fix this regarding issue #47.
static constexpr char kComposingBaseKey[] = "composingBase";

static constexpr char kComposingExtentKey[] = "composingExtent";

static constexpr char kSelectionAffinityKey[] = "selectionAffinity";
static constexpr char kAffinityDownstream[] = "TextAffinity.downstream";

static constexpr char kSelectionBaseKey[] = "selectionBase";
static constexpr char kSelectionExtentKey[] = "selectionExtent";

static constexpr char kSelectionIsDirectionalKey[] = "selectionIsDirectional";

static constexpr char kTextKey[] = "text";

// Input client configuration keys.
static constexpr char kTextInputAction[] = "inputAction";
static constexpr char kTextInputType[] = "inputType";
static constexpr char kTextInputTypeName[] = "name";

namespace shell {

TextInputModel::TextInputModel(int client_id, const rapidjson::Value& config)
    : text_(""),
      client_id_(client_id),
      selection_base_(text_.begin()),
      selection_extent_(text_.begin()) {
  // TODO: Improve error handling during refactoring; this is just minimal
  // checking to avoid asserts since RapidJSON is stricter than jsoncpp.
  if (config.IsObject()) {
    auto input_action = config.FindMember(kTextInputAction);
    if (input_action != config.MemberEnd() && input_action->value.IsString()) {
      input_action_ = input_action->value.GetString();
    }
    auto input_type_info = config.FindMember(kTextInputType);
    if (input_type_info != config.MemberEnd() &&
        input_type_info->value.IsObject()) {
      auto input_type = input_type_info->value.FindMember(kTextInputTypeName);
      if (input_type != input_type_info->value.MemberEnd() &&
          input_type->value.IsString()) {
        input_type_ = input_type->value.GetString();
      }
    }
  }
}

TextInputModel::~TextInputModel() = default;

bool TextInputModel::SetEditingState(size_t selection_base,
                                     size_t selection_extent,
                                     const std::string& text) {
  if (selection_base > selection_extent) {
    return false;
  }
  // Only checks extent since it is implicitly greater-than-or-equal-to base.
  if (selection_extent > text.size()) {
    return false;
  }
  text_ = std::string(text);
  selection_base_ = text_.begin() + selection_base;
  selection_extent_ = text_.begin() + selection_extent;
  return true;
}

void TextInputModel::DeleteSelected() {
  selection_base_ = text_.erase(selection_base_, selection_extent_);
  // Moves extent back to base, so that it is a single cursor placement again.
  selection_extent_ = selection_base_;
}

void TextInputModel::AddCharacter(char c) {
  if (selection_base_ != selection_extent_) {
    DeleteSelected();
  }
  selection_extent_ = text_.insert(selection_extent_, c);
  selection_extent_++;
  selection_base_ = selection_extent_;
}

bool TextInputModel::Backspace() {
  if (selection_base_ != selection_extent_) {
    DeleteSelected();
    return true;
  }
  if (selection_base_ != text_.begin()) {
    selection_base_ = text_.erase(selection_base_ - 1, selection_base_);
    selection_extent_ = selection_base_;
    return true;
  }
  return false;  // No edits happened.
}

bool TextInputModel::Delete() {
  if (selection_base_ != selection_extent_) {
    DeleteSelected();
    return true;
  }
  if (selection_base_ != text_.end()) {
    selection_base_ = text_.erase(selection_base_, selection_base_ + 1);
    selection_extent_ = selection_base_;
    return true;
  }
  return false;
}

void TextInputModel::MoveCursorToBeginning() {
  selection_base_ = text_.begin();
  selection_extent_ = text_.begin();
}

void TextInputModel::MoveCursorToEnd() {
  selection_base_ = text_.end();
  selection_extent_ = text_.end();
}

bool TextInputModel::MoveCursorForward() {
  // If about to move set to the end of the highlight (when not selecting).
  if (selection_base_ != selection_extent_) {
    selection_base_ = selection_extent_;
    return true;
  }
  // If not at the end, move the extent forward.
  if (selection_extent_ != text_.end()) {
    selection_extent_++;
    selection_base_++;
    return true;
  }
  return false;
}

bool TextInputModel::MoveCursorBack() {
  // If about to move set to the beginning of the highlight
  // (when not selecting).
  if (selection_base_ != selection_extent_) {
    selection_extent_ = selection_base_;
    return true;
  }
  // If not at the start, move the beginning backward.
  if (selection_base_ != text_.begin()) {
    selection_base_--;
    selection_extent_--;
    return true;
  }
  return false;
}

std::unique_ptr<rapidjson::Document> TextInputModel::GetState() const {
  // TODO(stuartmorgan): Move client_id out up to the plugin so that this
  // function just returns the editing state.
  auto args = std::make_unique<rapidjson::Document>(rapidjson::kArrayType);
  auto& allocator = args->GetAllocator();
  args->PushBack(client_id_, allocator);

  rapidjson::Value editing_state(rapidjson::kObjectType);
  // TODO(awdavies): Most of these are hard-coded for now.
  editing_state.AddMember(kComposingBaseKey, -1, allocator);
  editing_state.AddMember(kComposingExtentKey, -1, allocator);
  editing_state.AddMember(kSelectionAffinityKey, kAffinityDownstream,
                          allocator);
  editing_state.AddMember(kSelectionBaseKey,
                          static_cast<int>(selection_base_ - text_.begin()),
                          allocator);
  editing_state.AddMember(kSelectionExtentKey,
                          static_cast<int>(selection_extent_ - text_.begin()),
                          allocator);
  editing_state.AddMember(kSelectionIsDirectionalKey, false, allocator);
  editing_state.AddMember(kTextKey, rapidjson::Value(text_, allocator).Move(),
                          allocator);
  args->PushBack(editing_state, allocator);
  return args;
}

}  // namespace shell
