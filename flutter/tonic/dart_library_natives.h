// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_TONIC_DART_LIBRARY_NATIVES_H_
#define FLUTTER_TONIC_DART_LIBRARY_NATIVES_H_

#include <string>
#include <unordered_map>
#include <initializer_list>

#include "base/logging.h"
#include "dart/runtime/include/dart_api.h"

namespace blink {

class DartLibraryNatives {
 public:
  DartLibraryNatives();
  ~DartLibraryNatives();

  struct Entry {
    const char* symbol;
    Dart_NativeFunction native_function;
    int argument_count;
    bool auto_setup_scope;
  };

  void Register(std::initializer_list<Entry> entries);

  Dart_NativeFunction GetNativeFunction(Dart_Handle name,
                                        int argument_count,
                                        bool* auto_setup_scope);
  const uint8_t* GetSymbol(Dart_NativeFunction native_function);

 private:
  std::unordered_map<std::string, Entry> entries_;
  std::unordered_map<Dart_NativeFunction, const char*> symbols_;

  DISALLOW_COPY_AND_ASSIGN(DartLibraryNatives);
};

}  // namespace blink

#endif  // FLUTTER_TONIC_DART_LIBRARY_NATIVES_H_
