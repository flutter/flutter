// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_COMMON_INPUT_TEXT_INPUT_CONNECTION_H_
#define FLUTTER_COMMON_INPUT_TEXT_INPUT_CONNECTION_H_

#include <string>
#include "fml/closure.h"

namespace flutter {

class TextInputConnection {
 public:
  TextInputConnection() = default;

  virtual ~TextInputConnection() {}

  virtual std::string GetCurrentText() = 0;

  virtual void SetCurrentText(std::string_view text) = 0;

  virtual void SetUpdateCallback(fml::closure callback) {}

  TextInputConnection(const TextInputConnection&) = delete;
  TextInputConnection& operator=(const TextInputConnection&) = delete;
};

class TextInputConnectionFactory {
 public:
  TextInputConnectionFactory() = default;

  virtual ~TextInputConnectionFactory() {}

  virtual std::shared_ptr<TextInputConnection> CreateTextInputConnection() = 0;

  TextInputConnectionFactory(const TextInputConnectionFactory&) = delete;
  TextInputConnectionFactory& operator=(const TextInputConnectionFactory&) =
      delete;
};

}  // namespace flutter

#endif  // FLUTTER_COMMON_INPUT_TEXT_INPUT_CONNECTION_H_
