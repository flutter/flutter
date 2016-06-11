// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_TONIC_DART_CLASS_LIBRARY_H_
#define FLUTTER_TONIC_DART_CLASS_LIBRARY_H_

#include <memory>
#include <unordered_map>

#include "base/macros.h"
#include "dart/runtime/include/dart_api.h"
#include "flutter/tonic/dart_class_provider.h"

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
  Dart_PersistentHandle GetClass(const std::string& library_name,
                                 const std::string& interface_name);

 private:
  Dart_PersistentHandle GetAndCacheClass(const char* library_name,
                                         const char* interface_name,
                                         Dart_PersistentHandle* cache_slot);

  // TODO(abarth): Move this class somewhere more general.
  // We should also use a more reasonable hash function, such as described in
  // http://www.boost.org/doc/libs/1_35_0/doc/html/boost/hash_combine_id241013.html
  struct PairHasher {
    template <typename T, typename U>
    std::size_t operator()(const std::pair<T, U>& pair) const {
      return std::hash<T>()(pair.first) + 37 * std::hash<U>()(pair.second);
    }
  };

  std::unordered_map<std::string, std::unique_ptr<DartClassProvider>>
      providers_;
  std::unordered_map<const DartWrapperInfo*, Dart_PersistentHandle> info_cache_;
  std::unordered_map<std::pair<std::string, std::string>,
                     Dart_PersistentHandle, PairHasher> name_cache_;

  DISALLOW_COPY_AND_ASSIGN(DartClassLibrary);
};

}  // namespace blink

#endif  // FLUTTER_TONIC_DART_CLASS_LIBRARY_H_
