// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/plugins/callback_cache.h"

#include "flutter/fml/logging.h"
#include "third_party/tonic/converter/dart_converter.h"

using tonic::ToDart;

namespace flutter {

void DartCallbackCache::SetCachePath(const std::string& path) {
  fml::CallbackCache::SetCachePath(path);
}

Dart_Handle DartCallbackCache::GetCallback(int64_t handle) {
  std::unique_ptr<DartCallbackRepresentation> info =
      fml::CallbackCache::GetCallbackInformation(handle);
  if (info != nullptr) {
    return LookupDartClosure(info->name, info->class_name, info->library_path);
  }
  return Dart_Null();
}

std::unique_ptr<DartCallbackRepresentation>
DartCallbackCache::GetCallbackInformation(int64_t handle) {
  return fml::CallbackCache::GetCallbackInformation(handle);
}

int64_t DartCallbackCache::GetCallbackHandle(const std::string& name,
                                             const std::string& class_name,
                                             const std::string& library_path) {
  return fml::CallbackCache::GetCallbackHandle(name, class_name, library_path);
}

void DartCallbackCache::LoadCacheFromDisk() {
  fml::CallbackCache::LoadCacheFromDisk();
}

Dart_Handle DartCallbackCache::LookupDartClosure(
    const std::string& name,
    const std::string& class_name,
    const std::string& library_path) {
  Dart_Handle closure_name = ToDart(name);
  if (Dart_IsError(closure_name)) {
    return closure_name;
  }
  Dart_Handle library_name =
      library_path.empty() ? Dart_RootLibrary() : ToDart(library_path);
  if (Dart_IsError(library_name)) {
    return library_name;
  }
  Dart_Handle library = library_name == Dart_RootLibrary()
                            ? library_name
                            : Dart_LookupLibrary(library_name);
  if (Dart_IsError(library)) {
    return library;
  }
  Dart_Handle closure;
  if (class_name.empty()) {
    closure = Dart_GetField(library, closure_name);
  } else {
    Dart_Handle cls_name = ToDart(class_name);
    if (Dart_IsError(cls_name)) {
      return cls_name;
    }
    Dart_Handle cls = Dart_GetClass(library, cls_name);
    if (Dart_IsError(cls)) {
      return cls;
    }
    if (Dart_IsNull(cls)) {
      return Dart_Null();
    }
    closure = Dart_GetField(cls, closure_name);
  }
  return closure;
}

}  // namespace flutter
