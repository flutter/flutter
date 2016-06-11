// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_TONIC_DART_PERSISTENT_VALUE_H_
#define FLUTTER_TONIC_DART_PERSISTENT_VALUE_H_

#include "base/macros.h"
#include "base/memory/weak_ptr.h"
#include "dart/runtime/include/dart_api.h"

namespace blink {
class DartState;

// DartPersistentValue is a bookkeeping class to help pair calls to
// Dart_NewPersistentHandle with Dart_DeletePersistentHandle. Consider using
// this class instead of holding a Dart_PersistentHandle directly so that you
// don't leak the Dart_PersistentHandle.
class DartPersistentValue {
 public:
  DartPersistentValue();
  DartPersistentValue(DartPersistentValue&& other);
  DartPersistentValue(DartState* dart_state, Dart_Handle value);
  ~DartPersistentValue();

  Dart_PersistentHandle value() const { return value_; }
  bool is_empty() const { return !value_; }

  void Set(DartState* dart_state, Dart_Handle value);
  void Clear();
  Dart_Handle Release();

  const base::WeakPtr<DartState>& dart_state() const { return dart_state_; }

 private:
  base::WeakPtr<DartState> dart_state_;
  Dart_PersistentHandle value_;

  DISALLOW_COPY_AND_ASSIGN(DartPersistentValue);
};

}  // namespace blink

#endif  // FLUTTER_TONIC_DART_PERSISTENT_VALUE_H_
