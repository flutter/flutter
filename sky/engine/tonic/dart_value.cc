// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/tonic/dart_value.h"

namespace blink {

DartValue::DartValue() {
}

DartValue::DartValue(DartState* dart_state, Dart_Handle value)
    : dart_value_(dart_state, value) {
}

DartValue::~DartValue() {
}

bool DartValue::Equals(DartValue* other) const {
  DCHECK(other);
  if (is_empty())
    return other->is_empty();
  if (other->is_empty())
    return false;
  return Dart_IdentityEquals(dart_value(), other->dart_value());
}

void DartValue::Clear() {
  dart_value_.Clear();
}

}  // namespace blink
