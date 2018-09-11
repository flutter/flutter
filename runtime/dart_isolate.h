// Copyright 2017 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_RUNTIME_DART_ISOLATE_H_
#define FLUTTER_RUNTIME_DART_ISOLATE_H_

#include <set>
#include <string>

#include "flutter/common/task_runners.h"
#include "flutter/fml/compiler_specific.h"
#include "flutter/fml/macros.h"
#include "flutter/fml/mapping.h"
#include "flutter/lib/ui/ui_dart_state.h"
#include "flutter/lib/ui/window/window.h"
#include "flutter/runtime/dart_snapshot.h"
#include "third_party/dart/runtime/include/dart_api.h"
#include "third_party/tonic/dart_state.h"

namespace blink {
class DartVM;

class DartIsolate : public UIDartState {
 public:
  enum class Phase {
    Unknown,
    Uninitialized,
    Initialized,
    LibrariesSetup,
    Ready,
    Running,
    Shutdown,
  };

  using ChildIsolatePreparer = std::function<bool(DartIsolate*)>;

  // The root isolate of a Flutter application is special because it gets Window
  // bindings. From the VM's perspective, this isolate is not special in any
  // way.
  static std::weak_ptr<DartIsolate> CreateRootIsolate(
      DartVM* vm,
      fml::RefPtr<DartSnapshot> isolate_snapshot,
      fml::RefPtr<DartSnapshot> shared_snapshot,
      TaskRunners task_runners,
      std::unique_ptr<Window> window,
      fml::WeakPtr<GrContext> resource_context,
      fml::RefPtr<flow::SkiaUnrefQueue> unref_queue,
      std::string advisory_script_uri,
      std::string advisory_script_entrypoint,
      Dart_IsolateFlags* flags = nullptr);

  DartIsolate(DartVM* vm,
              fml::RefPtr<DartSnapshot> isolate_snapshot,
              fml::RefPtr<DartSnapshot> shared_snapshot,
              TaskRunners task_runners,
              fml::WeakPtr<GrContext> resource_context,
              fml::RefPtr<flow::SkiaUnrefQueue> unref_queue,
              std::string advisory_script_uri,
              std::string advisory_script_entrypoint,
              ChildIsolatePreparer child_isolate_preparer);

  ~DartIsolate() override;

  Phase GetPhase() const;

  FML_WARN_UNUSED_RESULT
  bool PrepareForRunningFromPrecompiledCode();

  FML_WARN_UNUSED_RESULT
  bool PrepareForRunningFromKernel(std::shared_ptr<const fml::Mapping> kernel,
                                   bool last_piece = true);

  FML_WARN_UNUSED_RESULT
  bool Run(const std::string& entrypoint);

  FML_WARN_UNUSED_RESULT
  bool RunFromLibrary(const std::string& library_name,
                      const std::string& entrypoint);

  FML_WARN_UNUSED_RESULT
  bool Shutdown();

  void AddIsolateShutdownCallback(fml::closure closure);

  DartVM* GetDartVM() const;

  fml::RefPtr<DartSnapshot> GetIsolateSnapshot() const;
  fml::RefPtr<DartSnapshot> GetSharedSnapshot() const;

  std::weak_ptr<DartIsolate> GetWeakIsolatePtr();

 private:
  bool LoadKernel(std::shared_ptr<const fml::Mapping> mapping, bool last_piece);

  class AutoFireClosure {
   public:
    AutoFireClosure(fml::closure closure) : closure_(std::move(closure)) {}
    ~AutoFireClosure() {
      if (closure_) {
        closure_();
      }
    }

   private:
    fml::closure closure_;
    FML_DISALLOW_COPY_AND_ASSIGN(AutoFireClosure);
  };
  friend class DartVM;

  DartVM* const vm_ = nullptr;
  Phase phase_ = Phase::Unknown;
  const fml::RefPtr<DartSnapshot> isolate_snapshot_;
  const fml::RefPtr<DartSnapshot> shared_snapshot_;
  std::vector<std::shared_ptr<const fml::Mapping>> kernel_buffers_;
  std::vector<std::unique_ptr<AutoFireClosure>> shutdown_callbacks_;
  ChildIsolatePreparer child_isolate_preparer_;

  FML_WARN_UNUSED_RESULT
  bool Initialize(Dart_Isolate isolate, bool is_root_isolate);

  FML_WARN_UNUSED_RESULT
  bool LoadLibraries(bool is_root_isolate);

  bool UpdateThreadPoolNames() const;

  FML_WARN_UNUSED_RESULT
  bool MarkIsolateRunnable();

  // |Dart_IsolateCreateCallback|
  static Dart_Isolate DartIsolateCreateCallback(
      const char* advisory_script_uri,
      const char* advisory_script_entrypoint,
      const char* package_root,
      const char* package_config,
      Dart_IsolateFlags* flags,
      std::shared_ptr<DartIsolate>* embedder_isolate,
      char** error);

  static Dart_Isolate DartCreateAndStartServiceIsolate(
      const char* advisory_script_uri,
      const char* advisory_script_entrypoint,
      const char* package_root,
      const char* package_config,
      Dart_IsolateFlags* flags,
      char** error);

  static std::pair<Dart_Isolate /* vm */,
                   std::weak_ptr<DartIsolate> /* embedder */>
  CreateDartVMAndEmbedderObjectPair(
      const char* advisory_script_uri,
      const char* advisory_script_entrypoint,
      const char* package_root,
      const char* package_config,
      Dart_IsolateFlags* flags,
      std::shared_ptr<DartIsolate>* parent_embedder_isolate,
      bool is_root_isolate,
      char** error);

  // |Dart_IsolateShutdownCallback|
  static void DartIsolateShutdownCallback(
      std::shared_ptr<DartIsolate>* embedder_isolate);

  // |Dart_IsolateCleanupCallback|
  static void DartIsolateCleanupCallback(
      std::shared_ptr<DartIsolate>* embedder_isolate);

  FML_DISALLOW_COPY_AND_ASSIGN(DartIsolate);
};

}  // namespace blink

#endif  // FLUTTER_RUNTIME_DART_ISOLATE_H_
