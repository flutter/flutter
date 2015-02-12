// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_TONIC_DART_CLASS_LIBRARY_H_
#define SKY_ENGINE_TONIC_DART_CLASS_LIBRARY_H_

#include "base/macros.h"
#include "dart/runtime/include/dart_api.h"
#include "sky/engine/tonic/dart_class_provider.h"
#include "sky/engine/wtf/HashMap.h"

namespace blink {
struct DartWrapperInfo;

class DartClassLibrary {
 public:
  explicit DartClassLibrary();
  ~DartClassLibrary();

  void set_provider(DartClassProvider* provider) { provider_ = provider; }
  Dart_PersistentHandle GetClass(const DartWrapperInfo& info);

 private:
  DartClassProvider* provider_;
  HashMap<const DartWrapperInfo*, Dart_PersistentHandle> cache_;

  DISALLOW_COPY_AND_ASSIGN(DartClassLibrary);
};

}  // namespace blink

#endif  // SKY_ENGINE_TONIC_DART_CLASS_LIBRARY_H_
