// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_DARWIN_IOS_IOS_TEXT_INPUT_H_
#define FLUTTER_SHELL_PLATFORM_DARWIN_IOS_IOS_TEXT_INPUT_H_

#include <memory>

#include "flutter/common/input/text_input_connection.h"
#include "flutter/fml/closure.h"
#include "flutter/fml/logging.h"

namespace flutter {

class IOSTextInputConnection : public TextInputConnection {
 public:
  IOSTextInputConnection() = default;

  std::string GetCurrentText() override { return current_text_; }

  void SetCurrentText(std::string_view text) override {
    auto old_text = current_text_;
    current_text_ = text;
    if (old_text != text && callback_) {
      callback_();
    }
  }

  void SetUpdateCallback(fml::closure callback) override {
    callback_ = callback;
  }

 private:
  std::string current_text_ = "";
  fml::closure callback_;
};

class IOSTextInputConnectionFactory : public TextInputConnectionFactory {
 public:
  IOSTextInputConnectionFactory() = default;

  std::shared_ptr<TextInputConnection> CreateTextInputConnection() override {
    return std::make_shared<IOSTextInputConnection>();
  }
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_DARWIN_IOS_IOS_TEXT_INPUT_H_
