// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/tonic/dart_exception_factory.h"

#include "flutter/tonic/dart_converter.h"

namespace blink {

// TODO(johnmccutchan): Move this into another file.
class StdStringBuilder {
 public:
  StdStringBuilder() {
  }

  void Append(const char* s, intptr_t length) {
    if (s == NULL) {
      return;
    }
    for (intptr_t i = 0; i < length; i++) {
      buffer_.push_back(s[i]);
    }
  }

  void Append(const char* s) {
    if (s == NULL) {
      return;
    }
    for (intptr_t i = 0; s[i] != '\0'; i++) {
      buffer_.push_back(s[i]);
    }
  }

  void Append(char ch) {
    buffer_.push_back(ch);
  }

  void Append(std::string s) {
    if (s.length() == 0) {
      return;
    }
    const char* c_str = s.data();
    intptr_t c_str_length = s.size();
    Append(c_str, c_str_length);
  }

  void AppendNumber(int num) {
    Append(std::to_string(num));
  }

  void Clear() {
    buffer_.resize(0);
  }

  void ShrinkToFit() {
    buffer_.shrink_to_fit();
  }

  void Reserve(intptr_t capacity) {
    buffer_.reserve(capacity);
  }

  std::string ToString() {
    return std::string(buffer_.data(), buffer_.size());
  }

  const char* data() const {
    return buffer_.data();
  }

  char* data() {
    return buffer_.data();
  }

  intptr_t size() const {
    return buffer_.size();
  }

 private:
  std::vector<char> buffer_;

  DISALLOW_COPY_AND_ASSIGN(StdStringBuilder);
};

DartExceptionFactory::DartExceptionFactory(DartState* dart_state)
    : dart_state_(dart_state) {
}

DartExceptionFactory::~DartExceptionFactory() {
}

Dart_Handle DartExceptionFactory::CreateNullArgumentException(int index) {
  StdStringBuilder builder;
  builder.Append("Argument ");
  builder.AppendNumber(index);
  builder.Append(" cannot be null.");
  Dart_Handle message_handle = Dart_NewStringFromUTF8(
      reinterpret_cast<const uint8_t*>(builder.data()), builder.size());
  return CreateException("ArgumentError", message_handle);
}

Dart_Handle DartExceptionFactory::CreateException(const std::string& class_name,
                                                  const std::string& message) {
  return CreateException(class_name, StdStringToDart(message));
}

Dart_Handle DartExceptionFactory::CreateException(const std::string& class_name,
                                                  Dart_Handle message) {
  if (core_library_.is_empty()) {
    Dart_Handle library = Dart_LookupLibrary(ToDart("dart:core"));
    core_library_.Set(dart_state_, library);
  }

  Dart_Handle exception_class = Dart_GetType(
      core_library_.value(), StdStringToDart(class_name), 0, 0);
  return Dart_New(exception_class, Dart_EmptyString(), 1, &message);
}

}  // namespace blink
