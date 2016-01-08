// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/tonic/dart_class_library.h"

#include "base/logging.h"
#include "sky/engine/tonic/dart_wrapper_info.h"

namespace blink {

DartClassLibrary::DartClassLibrary() {
}

DartClassLibrary::~DartClassLibrary() {
  // Note that we don't need to delete these persistent handles because this
  // object lives as long as the isolate. The handles will get deleted when the
  // isolate dies.
}

Dart_PersistentHandle DartClassLibrary::GetClass(const DartWrapperInfo& info) {
  const auto& result = cache_.insert(std::make_pair(&info, nullptr));
  if (!result.second) {
    // Already present, return value.
    return result.first->second;
  }

  auto it = providers_.find(info.library_name);
  DCHECK(it != providers_.end());

  Dart_Handle class_handle = it->second->GetClassByName(info.interface_name);
  result.first->second = Dart_NewPersistentHandle(class_handle);
  return result.first->second;
}

}  // namespace blink
