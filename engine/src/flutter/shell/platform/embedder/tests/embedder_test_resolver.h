// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_EMBEDDER_TESTS_EMBEDDER_TEST_RESOLVER_H_
#define FLUTTER_SHELL_PLATFORM_EMBEDDER_TESTS_EMBEDDER_TEST_RESOLVER_H_

#include <map>
#include <memory>

#include "flutter/fml/macros.h"
#include "third_party/dart/runtime/include/dart_api.h"

namespace shell {
namespace testing {

class EmbedderTestResolver
    : public std::enable_shared_from_this<EmbedderTestResolver> {
 public:
  EmbedderTestResolver();

  ~EmbedderTestResolver();

  void AddNativeCallback(std::string name, Dart_NativeFunction callback);

 private:
  // Friend so that the context can set the native resolver.
  friend class EmbedderContext;

  std::map<std::string, Dart_NativeFunction> native_callbacks_;

  void SetNativeResolverForIsolate();

  Dart_NativeFunction ResolveCallback(std::string name) const;

  static Dart_NativeFunction DartNativeEntryResolverCallback(
      Dart_Handle dart_name,
      int num_of_arguments,
      bool* auto_setup_scope);

  FML_DISALLOW_COPY_AND_ASSIGN(EmbedderTestResolver);
};

}  // namespace testing
}  // namespace shell

#endif  // FLUTTER_SHELL_PLATFORM_EMBEDDER_TESTS_EMBEDDER_TEST_RESOLVER_H_
