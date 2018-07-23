// Copyright 2018 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/plugins/callback_cache.h"
#include "lib/fxl/logging.h"
#include "third_party/tonic/converter/dart_converter.h"

using tonic::ToDart;

namespace blink {

std::mutex DartCallbackCache::mutex_;
std::map<int64_t, DartCallbackRepresentation> DartCallbackCache::cache_;

Dart_Handle DartCallbackCache::GetCallback(int64_t handle) {
  std::unique_lock<std::mutex> lock(mutex_);
  auto iterator = cache_.find(handle);
  if (iterator != cache_.end()) {
    DartCallbackRepresentation cb = iterator->second;
    return LookupDartClosure(cb.name, cb.class_name, cb.library_path);
  }
  return Dart_Null();
}

int64_t DartCallbackCache::GetCallbackHandle(const std::string& name,
                                             const std::string& class_name,
                                             const std::string& library_path) {
  std::unique_lock<std::mutex> lock(mutex_);
  std::hash<std::string> hasher;
  int64_t hash = hasher(name);
  hash += hasher(class_name);
  hash += hasher(library_path);

  if (cache_.find(hash) == cache_.end()) {
    cache_[hash] = {name, class_name, library_path};
  }
  return hash;
}

std::unique_ptr<DartCallbackRepresentation>
DartCallbackCache::GetCallbackInformation(int64_t handle) {
  std::unique_lock<std::mutex> lock(mutex_);
  auto iterator = cache_.find(handle);
  if (iterator != cache_.end()) {
    return std::make_unique<DartCallbackRepresentation>(iterator->second);
  }
  return nullptr;
}

Dart_Handle DartCallbackCache::LookupDartClosure(
    const std::string& name,
    const std::string& class_name,
    const std::string& library_path) {
  Dart_Handle closure_name = ToDart(name);
  Dart_Handle library_name =
      library_path.empty() ? Dart_Null() : ToDart(library_path);
  Dart_Handle cls_name = class_name.empty() ? Dart_Null() : ToDart(class_name);
  DART_CHECK_VALID(closure_name);
  DART_CHECK_VALID(library_name);
  DART_CHECK_VALID(cls_name);

  Dart_Handle library;
  if (library_name == Dart_Null()) {
    library = Dart_RootLibrary();
  } else {
    library = Dart_LookupLibrary(library_name);
  }
  DART_CHECK_VALID(library);

  Dart_Handle closure;
  if (Dart_IsNull(cls_name)) {
    closure = Dart_GetClosure(library, closure_name);
  } else {
    Dart_Handle cls = Dart_GetClass(library, cls_name);
    DART_CHECK_VALID(cls);
    if (Dart_IsNull(cls)) {
      closure = Dart_Null();
    } else {
      closure = Dart_GetStaticMethodClosure(library, cls, closure_name);
    }
  }
  DART_CHECK_VALID(closure);
  return closure;
}

}  // namespace blink
