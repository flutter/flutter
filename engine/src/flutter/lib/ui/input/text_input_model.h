// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_UI_INPUT_TEXT_INPUT_MODEL_H_
#define FLUTTER_LIB_UI_INPUT_TEXT_INPUT_MODEL_H_

#include "flutter/lib/ui/dart_wrapper.h"
#include "flutter/lib/ui/ui_dart_state.h"
#include "third_party/dart/runtime/include/dart_api.h"

namespace flutter {

class UiTextInputModel : public RefCountedDartWrappable<UiTextInputModel> {
  DEFINE_WRAPPERTYPEINFO();
  FML_FRIEND_MAKE_REF_COUNTED(UiTextInputModel);

 public:
  UiTextInputModel();

  ~UiTextInputModel() = default;

  static void Create(Dart_Handle wrapper);

  Dart_Handle getCurrentText();

  void setCurrentText(const std::string& value);

  void setUpdateCallback(Dart_Handle callback);

  void dispose();

 private:
  std::shared_ptr<TextInputConnection> connection_;
  std::unique_ptr<tonic::DartPersistentValue> update_callback_;

  UiTextInputModel(const UiTextInputModel&) = delete;
  UiTextInputModel(UiTextInputModel&&) = delete;
  UiTextInputModel& operator=(const UiTextInputModel&) = delete;
  UiTextInputModel& operator=(UiTextInputModel&&) = delete;
};

}  // namespace flutter

#endif  // FLUTTER_LIB_UI_INPUT_TEXT_INPUT_MODEL_H_
