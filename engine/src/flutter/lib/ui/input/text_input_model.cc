
// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/input/text_input_model.h"
#include "dart_api.h"
#include "lib/ui/ui_dart_state.h"

namespace flutter {

IMPLEMENT_WRAPPERTYPEINFO(ui, UiTextInputModel);

// static
void UiTextInputModel::Create(Dart_Handle wrapper) {
  UIDartState::ThrowIfUIOperationsProhibited();
  fml::RefPtr<UiTextInputModel> res = fml::MakeRefCounted<UiTextInputModel>();
  res->AssociateWithDartWrapper(wrapper);
}

UiTextInputModel::UiTextInputModel() {
  connection_ = UIDartState::Current()
                    ->GetTextInputConnectionFactory()
                    .CreateTextInputConnection();
}

Dart_Handle UiTextInputModel::getCurrentText() {
  auto text = connection_->GetCurrentText();
  return Dart_NewStringFromUTF8(reinterpret_cast<const uint8_t*>(text.data()),
                                text.size());
}

void UiTextInputModel::setCurrentText(const std::string& value) {
  connection_->SetCurrentText(value);
}

void UiTextInputModel::setUpdateCallback(Dart_Handle callback) {
  update_callback_ = std::make_unique<tonic::DartPersistentValue>(
      tonic::DartState::Current(), callback);
  connection_->SetUpdateCallback([&] {
    UIDartState::ThrowIfUIOperationsProhibited();
    std::shared_ptr<tonic::DartState> dart_state =
        update_callback_->dart_state().lock();
    if (!dart_state) {
      return;
    }
    tonic::DartState::Scope scope(dart_state);
    tonic::DartInvoke(update_callback_->value(), {});
  });
}

void UiTextInputModel::dispose() {
  //
}

}  // namespace flutter