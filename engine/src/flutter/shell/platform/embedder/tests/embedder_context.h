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
#include "flutter/testing/test_dart_native_resolver.h"

namespace shell {
namespace testing {

using SemanticsNodeCallback = std::function<void(const FlutterSemanticsNode*)>;
using SemanticsActionCallback =
    std::function<void(const FlutterSemanticsCustomAction*)>;

class EmbedderContext {
 public:
  EmbedderContext(std::string assets_path = "");

  ~EmbedderContext();

  const std::string& GetAssetsPath() const;

  const fml::Mapping* GetVMSnapshotData() const;

  const fml::Mapping* GetVMSnapshotInstructions() const;

  const fml::Mapping* GetIsolateSnapshotData() const;

  const fml::Mapping* GetIsolateSnapshotInstructions() const;

  void AddIsolateCreateCallback(fml::closure closure);

  void AddNativeCallback(const char* name, Dart_NativeFunction function);

  void SetSemanticsNodeCallback(SemanticsNodeCallback update_semantics_node);

  void SetSemanticsCustomActionCallback(
      SemanticsActionCallback semantics_custom_action);

 private:
  // This allows the builder to access the hooks.
  friend class EmbedderConfigBuilder;

  std::string assets_path_;
  std::unique_ptr<fml::Mapping> vm_snapshot_data_;
  std::unique_ptr<fml::Mapping> vm_snapshot_instructions_;
  std::unique_ptr<fml::Mapping> isolate_snapshot_data_;
  std::unique_ptr<fml::Mapping> isolate_snapshot_instructions_;
  std::vector<fml::closure> isolate_create_callbacks_;
  std::shared_ptr<::testing::TestDartNativeResolver> native_resolver_;
  SemanticsNodeCallback update_semantics_node_callback_;
  SemanticsActionCallback update_semantics_custom_action_callback_;

  static VoidCallback GetIsolateCreateCallbackHook();

  static FlutterUpdateSemanticsNodeCallback
  GetUpdateSemanticsNodeCallbackHook();

  static FlutterUpdateSemanticsCustomActionCallback
  GetUpdateSemanticsCustomActionCallbackHook();

  void FireIsolateCreateCallbacks();

  void SetNativeResolver();

  FML_DISALLOW_COPY_AND_ASSIGN(EmbedderContext);
};

}  // namespace testing
}  // namespace shell

#endif  // FLUTTER_SHELL_PLATFORM_EMBEDDER_TESTS_EMBEDDER_CONTEXT_H_
