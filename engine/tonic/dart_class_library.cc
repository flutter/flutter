// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/tonic/dart_class_library.h"

#include "base/logging.h"
#include "sky/engine/tonic/dart_wrapper_info.h"

namespace blink {

DartClassLibrary::DartClassLibrary() : provider_(nullptr) {
}

DartClassLibrary::~DartClassLibrary() {
  // Note that we don't need to delete these persistent handles because this
  // object lives as long as the isolate. The handles will get deleted when the
  // isolate dies.
}

Dart_PersistentHandle DartClassLibrary::GetClass(const DartWrapperInfo& info) {
  DCHECK(provider_);

  const auto& result = cache_.add(&info, nullptr);
  if (!result.isNewEntry)
    return result.storedValue->value;

  Dart_Handle class_handle = provider_->GetClassByName(info.interface_name);
  result.storedValue->value = Dart_NewPersistentHandle(class_handle);
  return result.storedValue->value;
}

}  // namespace blink
