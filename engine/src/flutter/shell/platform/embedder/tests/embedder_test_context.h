// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_EMBEDDER_TESTS_EMBEDDER_CONTEXT_H_
#define FLUTTER_SHELL_PLATFORM_EMBEDDER_TESTS_EMBEDDER_CONTEXT_H_

#include <future>
#include <map>
#include <memory>
#include <mutex>
#include <string>
#include <vector>

#include "flutter/fml/closure.h"
#include "flutter/fml/macros.h"
#include "flutter/fml/mapping.h"
#include "flutter/shell/platform/embedder/embedder.h"
#include "flutter/shell/platform/embedder/tests/embedder_test_compositor.h"
#include "flutter/testing/elf_loader.h"
#include "flutter/testing/test_dart_native_resolver.h"
#include "third_party/skia/include/core/SkImage.h"

namespace flutter {
namespace testing {

using SemanticsNodeCallback = std::function<void(const FlutterSemanticsNode*)>;
using SemanticsActionCallback =
    std::function<void(const FlutterSemanticsCustomAction*)>;

struct AOTDataDeleter {
  void operator()(FlutterEngineAOTData aot_data) {
    if (aot_data) {
      FlutterEngineCollectAOTData(aot_data);
    }
  }
};

using UniqueAOTData = std::unique_ptr<_FlutterEngineAOTData, AOTDataDeleter>;

class EmbedderTestContext {
 public:
  EmbedderTestContext(std::string assets_path = "");

  virtual ~EmbedderTestContext();

  const std::string& GetAssetsPath() const;

  const fml::Mapping* GetVMSnapshotData() const;

  const fml::Mapping* GetVMSnapshotInstructions() const;

  const fml::Mapping* GetIsolateSnapshotData() const;

  const fml::Mapping* GetIsolateSnapshotInstructions() const;

  FlutterEngineAOTData GetAOTData() const;

  void SetRootSurfaceTransformation(SkMatrix matrix);

  void AddIsolateCreateCallback(fml::closure closure);

  void AddNativeCallback(const char* name, Dart_NativeFunction function);

  void SetSemanticsNodeCallback(
      const SemanticsNodeCallback& update_semantics_node);

  void SetSemanticsCustomActionCallback(
      const SemanticsActionCallback& semantics_custom_action);

  void SetPlatformMessageCallback(
      const std::function<void(const FlutterPlatformMessage*)>& callback);

  std::future<sk_sp<SkImage>> GetNextSceneImage();

  EmbedderTestCompositor& GetCompositor();

  virtual size_t GetSurfacePresentCount() const = 0;

  // TODO(gw280): encapsulate these properly for subclasses to use
 protected:
  // This allows the builder to access the hooks.
  friend class EmbedderConfigBuilder;

  using NextSceneCallback = std::function<void(sk_sp<SkImage> image)>;

  std::string assets_path_;
  ELFAOTSymbols aot_symbols_;
  std::unique_ptr<fml::Mapping> vm_snapshot_data_;
  std::unique_ptr<fml::Mapping> vm_snapshot_instructions_;
  std::unique_ptr<fml::Mapping> isolate_snapshot_data_;
  std::unique_ptr<fml::Mapping> isolate_snapshot_instructions_;
  UniqueAOTData aot_data_;
  std::vector<fml::closure> isolate_create_callbacks_;
  std::shared_ptr<TestDartNativeResolver> native_resolver_;
  SemanticsNodeCallback update_semantics_node_callback_;
  SemanticsActionCallback update_semantics_custom_action_callback_;
  std::function<void(const FlutterPlatformMessage*)> platform_message_callback_;
  std::unique_ptr<EmbedderTestCompositor> compositor_;
  NextSceneCallback next_scene_callback_;
  SkMatrix root_surface_transformation_;

  static VoidCallback GetIsolateCreateCallbackHook();

  static FlutterUpdateSemanticsNodeCallback
  GetUpdateSemanticsNodeCallbackHook();

  static FlutterUpdateSemanticsCustomActionCallback
  GetUpdateSemanticsCustomActionCallbackHook();

  static FlutterComputePlatformResolvedLocaleCallback
  GetComputePlatformResolvedLocaleCallbackHook();

  void SetupAOTMappingsIfNecessary();

  void SetupAOTDataIfNecessary();

  virtual void SetupCompositor() = 0;

  void FireIsolateCreateCallbacks();

  void SetNativeResolver();

  FlutterTransformation GetRootSurfaceTransformation();

  void PlatformMessageCallback(const FlutterPlatformMessage* message);

  void FireRootSurfacePresentCallbackIfPresent(
      const std::function<sk_sp<SkImage>(void)>& image_callback);

  void SetNextSceneCallback(const NextSceneCallback& next_scene_callback);

  virtual void SetupSurface(SkISize surface_size) = 0;

  FML_DISALLOW_COPY_AND_ASSIGN(EmbedderTestContext);
};

}  // namespace testing
}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_EMBEDDER_TESTS_EMBEDDER_CONTEXT_H_
