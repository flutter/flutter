// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_RUNTIME_DART_ISOLATE_H_
#define FLUTTER_RUNTIME_DART_ISOLATE_H_

#include <memory>
#include <set>
#include <string>

#include "flutter/common/task_runners.h"
#include "flutter/fml/compiler_specific.h"
#include "flutter/fml/macros.h"
#include "flutter/fml/mapping.h"
#include "flutter/lib/ui/io_manager.h"
#include "flutter/lib/ui/ui_dart_state.h"
#include "flutter/lib/ui/window/window.h"
#include "flutter/runtime/dart_snapshot.h"
#include "third_party/dart/runtime/include/dart_api.h"
#include "third_party/tonic/dart_state.h"

namespace flutter {
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
      const Settings& settings,
      fml::RefPtr<const DartSnapshot> isolate_snapshot,
      fml::RefPtr<const DartSnapshot> shared_snapshot,
      TaskRunners task_runners,
      std::unique_ptr<Window> window,
      fml::WeakPtr<IOManager> io_manager,
      fml::WeakPtr<ImageDecoder> image_decoder,
      std::string advisory_script_uri,
      std::string advisory_script_entrypoint,
      Dart_IsolateFlags* flags,
      fml::closure isolate_create_callback,
      fml::closure isolate_shutdown_callback);

  DartIsolate(const Settings& settings,
              fml::RefPtr<const DartSnapshot> isolate_snapshot,
              fml::RefPtr<const DartSnapshot> shared_snapshot,
              TaskRunners task_runners,
              fml::WeakPtr<IOManager> io_manager,
              fml::WeakPtr<ImageDecoder> image_decoder,
              std::string advisory_script_uri,
              std::string advisory_script_entrypoint,
              ChildIsolatePreparer child_isolate_preparer,
              fml::closure isolate_create_callback,
              fml::closure isolate_shutdown_callback,
              bool is_root_isolate,
              bool is_group_root_isolate);

  ~DartIsolate() override;

  const Settings& GetSettings() const;

  Phase GetPhase() const;

  std::string GetServiceId();

  FML_WARN_UNUSED_RESULT
  bool PrepareForRunningFromPrecompiledCode();

  FML_WARN_UNUSED_RESULT
  bool PrepareForRunningFromKernel(std::shared_ptr<const fml::Mapping> kernel,
                                   bool last_piece = true);

  FML_WARN_UNUSED_RESULT
  bool PrepareForRunningFromKernels(
      std::vector<std::shared_ptr<const fml::Mapping>> kernels);

  FML_WARN_UNUSED_RESULT
  bool PrepareForRunningFromKernels(
      std::vector<std::unique_ptr<const fml::Mapping>> kernels);

  FML_WARN_UNUSED_RESULT
  bool Run(const std::string& entrypoint,
           const std::vector<std::string>& args,
           fml::closure on_run = nullptr);

  FML_WARN_UNUSED_RESULT
  bool RunFromLibrary(const std::string& library_name,
                      const std::string& entrypoint,
                      const std::vector<std::string>& args,
                      fml::closure on_run = nullptr);

  FML_WARN_UNUSED_RESULT
  bool Shutdown();

  void AddIsolateShutdownCallback(fml::closure closure);

  fml::RefPtr<const DartSnapshot> GetIsolateSnapshot() const;

  fml::RefPtr<const DartSnapshot> GetSharedSnapshot() const;

  std::weak_ptr<DartIsolate> GetWeakIsolatePtr();

  fml::RefPtr<fml::TaskRunner> GetMessageHandlingTaskRunner() const;

  // Root isolate of the VM application
  bool IsRootIsolate() const { return is_root_isolate_; }
  // Isolate that owns IsolateGroup it lives in.
  // When --no-enable-isolate-groups dart vm flag is set,
  // all child isolates will have their own IsolateGroups.
  bool IsGroupRootIsolate() const { return is_group_root_isolate_; }

 private:
  bool LoadKernel(std::shared_ptr<const fml::Mapping> mapping, bool last_piece);

  class AutoFireClosure {
   public:
    AutoFireClosure(fml::closure closure);

    ~AutoFireClosure();

   private:
    fml::closure closure_;
    FML_DISALLOW_COPY_AND_ASSIGN(AutoFireClosure);
  };
  friend class DartVM;

  Phase phase_ = Phase::Unknown;
  const Settings settings_;
  const fml::RefPtr<const DartSnapshot> isolate_snapshot_;
  const fml::RefPtr<const DartSnapshot> shared_snapshot_;
  std::vector<std::shared_ptr<const fml::Mapping>> kernel_buffers_;
  std::vector<std::unique_ptr<AutoFireClosure>> shutdown_callbacks_;
  ChildIsolatePreparer child_isolate_preparer_ = nullptr;
  fml::RefPtr<fml::TaskRunner> message_handling_task_runner_;
  const fml::closure isolate_create_callback_;
  const fml::closure isolate_shutdown_callback_;

  const bool is_root_isolate_;
  const bool is_group_root_isolate_;

  FML_WARN_UNUSED_RESULT bool Initialize(Dart_Isolate isolate);

  void SetMessageHandlingTaskRunner(fml::RefPtr<fml::TaskRunner> runner);

  FML_WARN_UNUSED_RESULT
  bool LoadLibraries();

  bool UpdateThreadPoolNames() const;

  FML_WARN_UNUSED_RESULT
  bool MarkIsolateRunnable();

  void OnShutdownCallback();

  // |Dart_IsolateGroupCreateCallback|
  static Dart_Isolate DartIsolateGroupCreateCallback(
      const char* advisory_script_uri,
      const char* advisory_script_entrypoint,
      const char* package_root,
      const char* package_config,
      Dart_IsolateFlags* flags,
      std::shared_ptr<DartIsolate>* embedder_isolate,
      char** error);

  // |Dart_IsolateInitializeCallback|
  static bool DartIsolateInitializeCallback(void** child_callback_data,
                                            char** error);

  static Dart_Isolate DartCreateAndStartServiceIsolate(
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

  static bool InitializeIsolate(std::shared_ptr<DartIsolate> embedder_isolate,
                                Dart_Isolate isolate,
                                char** error);

  // |Dart_IsolateShutdownCallback|
  static void DartIsolateShutdownCallback(
      std::shared_ptr<DartIsolate>* isolate_group_data,
      std::shared_ptr<DartIsolate>* isolate_data);

  // |Dart_IsolateCleanupCallback|
  static void DartIsolateCleanupCallback(
      std::shared_ptr<DartIsolate>* isolate_group_data,
      std::shared_ptr<DartIsolate>* isolate_data);

  // |Dart_IsolateGroupCleanupCallback|
  static void DartIsolateGroupCleanupCallback(
      std::shared_ptr<DartIsolate>* isolate_group_data);

  FML_DISALLOW_COPY_AND_ASSIGN(DartIsolate);
};

}  // namespace flutter

#endif  // FLUTTER_RUNTIME_DART_ISOLATE_H_
