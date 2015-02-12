// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_TONIC_DART_VALUE_H_
#define SKY_ENGINE_TONIC_DART_VALUE_H_

#include "base/logging.h"
#include "dart/runtime/include/dart_api.h"
#include "sky/engine/tonic/dart_persistent_value.h"
#include "sky/engine/tonic/dart_state.h"
#include "sky/engine/wtf/RefPtr.h"

namespace blink {

// DartValue is a convience wrapper around DartPersistentValue that lets clients
// use RefPtr to keep track of the number of references to the underlying Dart
// object. Be careful when retaining RefPtr<DartValue> in the heap because the
// VM's garbage collector cannot break cycles that involve the C++ heap, which
// can lead to memory leaks.
class DartValue : public RefCounted<DartValue> {
 public:
  static PassRefPtr<DartValue> Create(DartState* dart_state,
                                      Dart_Handle value) {
    return adoptRef(new DartValue(dart_state, value));
  }

  static PassRefPtr<DartValue> Create() { return adoptRef(new DartValue()); }

  ~DartValue();

  Dart_Handle dart_value() const { return dart_value_.value(); }
  bool is_empty() const { return !dart_value(); }

  bool is_null() const {
    DCHECK(!is_empty());
    return Dart_IsNull(dart_value());
  }

  bool is_function() const {
    DCHECK(!is_empty());
    return Dart_IsClosure(dart_value());
  }

  bool Equals(DartValue* other) const;
  void Clear();

 private:
  DartValue();
  DartValue(DartState* dart_state, Dart_Handle value);

  DartPersistentValue dart_value_;

  DISALLOW_COPY_AND_ASSIGN(DartValue);
};

}  // namespace blink

#endif  // SKY_ENGINE_TONIC_DART_VALUE_H_
