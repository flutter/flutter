// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_EMBEDDER_TESTS_EMBEDDER_CONTEXT_H_
#define FLUTTER_SHELL_PLATFORM_EMBEDDER_TESTS_EMBEDDER_CONTEXT_H_

#include <map>
#include <memory>
#include <string>
#include <vector>

#include "flutter/fml/closure.h"
#include "flutter/fml/macros.h"
#include "flutter/fml/mapping.h"
#include "flutter/shell/platform/embedder/embedder.h"
#include "flutter/shell/platform/embedder/tests/embedder_test_resolver.h"

#define CREATE_NATIVE_ENTRY(native_entry)                                   \
  ({                                                                        \
    static ::shell::testing::EmbedderContext::NativeEntry closure;          \
    static Dart_NativeFunction entrypoint = [](Dart_NativeArguments args) { \
      closure(args);                                                        \
    };                                                                      \
    closure = (native_entry);                                               \
    entrypoint;                                                             \
  })

namespace shell {
namespace testing {

class EmbedderContext {
 public:
  using NativeEntry = std::function<void(Dart_NativeArguments)>;

  EmbedderContext(std::string assets_path = "");

  ~EmbedderContext();

  const std::string& GetAssetsPath() const;

  const fml::Mapping* GetVMSnapshotData() const;

  const fml::Mapping* GetVMSnapshotInstructions() const;

  const fml::Mapping* GetIsolateSnapshotData() const;

  const fml::Mapping* GetIsolateSnapshotInstructions() const;

  void AddIsolateCreateCallback(fml::closure closure);

  void AddNativeCallback(const char* name, Dart_NativeFunction function);

 private:
  // This allows the builder to access the hooks.
  friend class EmbedderConfigBuilder;

  std::string assets_path_;
  std::unique_ptr<fml::Mapping> vm_snapshot_data_;
  std::unique_ptr<fml::Mapping> vm_snapshot_instructions_;
  std::unique_ptr<fml::Mapping> isolate_snapshot_data_;
  std::unique_ptr<fml::Mapping> isolate_snapshot_instructions_;
  std::vector<fml::closure> isolate_create_callbacks_;
  std::shared_ptr<EmbedderTestResolver> native_resolver_;

  static VoidCallback GetIsolateCreateCallbackHook();

  void FireIsolateCreateCallbacks();

  void SetNativeResolver();

  FML_DISALLOW_COPY_AND_ASSIGN(EmbedderContext);
};

}  // namespace testing
}  // namespace shell

#endif  // FLUTTER_SHELL_PLATFORM_EMBEDDER_TESTS_EMBEDDER_CONTEXT_H_
