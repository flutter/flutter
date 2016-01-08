// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_TONIC_DART_CLASS_LIBRARY_H_
#define SKY_ENGINE_TONIC_DART_CLASS_LIBRARY_H_

#include <memory>
#include <unordered_map>

#include "base/macros.h"
#include "dart/runtime/include/dart_api.h"
#include "sky/engine/tonic/dart_class_provider.h"

namespace blink {
struct DartWrapperInfo;

class DartClassLibrary {
 public:
  explicit DartClassLibrary();
  ~DartClassLibrary();

  void add_provider(const std::string& library_name,
                    std::unique_ptr<DartClassProvider> provider) {
    providers_.insert(std::make_pair(library_name, std::move(provider)));
  }

  Dart_PersistentHandle GetClass(const DartWrapperInfo& info);

 private:
  std::unordered_map<std::string, std::unique_ptr<DartClassProvider>>
      providers_;
  std::unordered_map<const DartWrapperInfo*, Dart_PersistentHandle> cache_;

  DISALLOW_COPY_AND_ASSIGN(DartClassLibrary);
};

}  // namespace blink

#endif  // SKY_ENGINE_TONIC_DART_CLASS_LIBRARY_H_
