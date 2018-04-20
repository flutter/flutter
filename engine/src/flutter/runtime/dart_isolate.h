// Copyright 2017 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_RUNTIME_DART_ISOLATE_H_
#define FLUTTER_RUNTIME_DART_ISOLATE_H_

#include <set>
#include <string>

#include "flutter/common/task_runners.h"
#include "flutter/fml/mapping.h"
#include "flutter/lib/ui/ui_dart_state.h"
#include "flutter/lib/ui/window/window.h"
#include "flutter/runtime/dart_snapshot.h"
#include "lib/fxl/compiler_specific.h"
#include "lib/fxl/macros.h"
#include "lib/tonic/dart_state.h"
#include "third_party/dart/runtime/include/dart_api.h"

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
  static fml::WeakPtr<DartIsolate> CreateRootIsolate(
      const DartVM* vm,
      fxl::RefPtr<DartSnapshot> isolate_snapshot,
      TaskRunners task_runners,
      std::unique_ptr<Window> window,
      fml::WeakPtr<GrContext> resource_context,
      fxl::RefPtr<flow::SkiaUnrefQueue> unref_queue,
      std::string advisory_script_uri = "main.dart",
      std::string advisory_script_entrypoint = "main",
      Dart_IsolateFlags* flags = nullptr);

  DartIsolate(const DartVM* vm,
              fxl::RefPtr<DartSnapshot> isolate_snapshot,
              TaskRunners task_runners,
              fml::WeakPtr<GrContext> resource_context,
              fxl::RefPtr<flow::SkiaUnrefQueue> unref_queue,
              std::string advisory_script_uri,
              std::string advisory_script_entrypoint,
              ChildIsolatePreparer child_isolate_preparer);

  ~DartIsolate() override;

  Phase GetPhase() const;

  FXL_WARN_UNUSED_RESULT
  bool PrepareForRunningFromPrecompiledCode();

  FXL_WARN_UNUSED_RESULT
  bool PrepareForRunningFromSnapshot(
      std::shared_ptr<const fml::Mapping> snapshot);

  FXL_WARN_UNUSED_RESULT
  bool PrepareForRunningFromSource(const std::string& main_source_file,
                                   const std::string& packages);

  FXL_WARN_UNUSED_RESULT
  bool Run(const std::string& entrypoint);

  FXL_WARN_UNUSED_RESULT
  bool Shutdown();

  void AddIsolateShutdownCallback(fxl::Closure closure);

  const DartVM* GetDartVM() const;

  fxl::RefPtr<DartSnapshot> GetIsolateSnapshot() const;

  fml::WeakPtr<DartIsolate> GetWeakIsolatePtr() const;

 private:
  class AutoFireClosure {
   public:
    AutoFireClosure(fxl::Closure closure) : closure_(std::move(closure)) {}
    ~AutoFireClosure() {
      if (closure_) {
        closure_();
      }
    }

   private:
    fxl::Closure closure_;
    FXL_DISALLOW_COPY_AND_ASSIGN(AutoFireClosure);
  };
  friend class DartVM;

  const DartVM* vm_ = nullptr;
  Phase phase_ = Phase::Unknown;
  const fxl::RefPtr<DartSnapshot> isolate_snapshot_;
  std::vector<std::unique_ptr<AutoFireClosure>> shutdown_callbacks_;
  ChildIsolatePreparer child_isolate_preparer_;
  std::unique_ptr<fml::WeakPtrFactory<DartIsolate>> weak_factory_;

  FXL_WARN_UNUSED_RESULT
  bool Initialize(Dart_Isolate isolate, bool is_root_isolate);

  FXL_WARN_UNUSED_RESULT
  bool LoadLibraries();

  bool UpdateThreadPoolNames() const;

  FXL_WARN_UNUSED_RESULT
  bool MarkIsolateRunnable();

  void ResetWeakPtrFactory();

  // |Dart_IsolateCreateCallback|
  static Dart_Isolate DartIsolateCreateCallback(
      const char* advisory_script_uri,
      const char* advisory_script_entrypoint,
      const char* package_root,
      const char* package_config,
      Dart_IsolateFlags* flags,
      DartIsolate* embedder_isolate,
      char** error);

  static Dart_Isolate DartCreateAndStartServiceIsolate(
      const char* advisory_script_uri,
      const char* advisory_script_entrypoint,
      const char* package_root,
      const char* package_config,
      Dart_IsolateFlags* flags,
      char** error);

  static std::pair<Dart_Isolate /* vm */,
                   fml::WeakPtr<DartIsolate> /* embedder */>
  CreateDartVMAndEmbedderObjectPair(const char* advisory_script_uri,
                                    const char* advisory_script_entrypoint,
                                    const char* package_root,
                                    const char* package_config,
                                    Dart_IsolateFlags* flags,
                                    DartIsolate* parent_embedder_isolate,
                                    bool is_root_isolate,
                                    char** error);

  // |Dart_IsolateShutdownCallback|
  static void DartIsolateShutdownCallback(DartIsolate* embedder_isolate);

  // |Dart_IsolateCleanupCallback|
  static void DartIsolateCleanupCallback(DartIsolate* embedder_isolate);

  FXL_DISALLOW_COPY_AND_ASSIGN(DartIsolate);
};

}  // namespace blink

#endif  // FLUTTER_RUNTIME_DART_ISOLATE_H_
