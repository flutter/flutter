// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_BINDINGS_NULLABLE_H_
#define SKY_ENGINE_BINDINGS_NULLABLE_H_

#include "base/logging.h"

namespace blink {

template <typename T>
class Nullable {
 public:
  Nullable() : value_(), is_null_(true) {}
  Nullable(const T& value) : value_(value), is_null_(false) {}
  Nullable(const Nullable& other)
      : value_(other.value_), is_null_(other.is_null_) {}

  Nullable& operator=(const Nullable& other) = default;

  void set(const T& value) {
    value_ = value;
    is_null_ = false;
  }

  const T& get() const {
    DCHECK(!is_null_);
    return value_;
  }
  T& get() {
    DCHECK(!is_null_);
    return value_;
  }

  bool is_null() const { return is_null_; }

  // See comment in RefPtr.h about what UnspecifiedBoolType is.
  typedef const T* UnspecifiedBoolType;
  operator UnspecifiedBoolType() const { return is_null_ ? 0 : &value_; }

  bool operator==(const Nullable& other) const {
    return (is_null_ && other.is_null_) ||
           (!is_null_ && !other.is_null_ && value_ == other.value_);
  }

 private:
  T value_;
  bool is_null_;
};

}  // namespace blink

#endif  // SKY_ENGINE_BINDINGS_NULLABLE_H_
