// Copyright 2017 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/runtime/dart_isolate.h"

#include <cstdlib>
#include <tuple>

#include "flutter/fml/paths.h"
#include "flutter/fml/trace_event.h"
#include "flutter/lib/io/dart_io.h"
#include "flutter/lib/ui/dart_runtime_hooks.h"
#include "flutter/lib/ui/dart_ui.h"
#include "flutter/runtime/dart_service_isolate.h"
#include "flutter/runtime/dart_vm.h"
#include "third_party/dart/runtime/include/dart_api.h"
#include "third_party/dart/runtime/include/dart_tools_api.h"
#include "third_party/tonic/converter/dart_converter.h"
#include "third_party/tonic/dart_class_library.h"
#include "third_party/tonic/dart_class_provider.h"
#include "third_party/tonic/dart_message_handler.h"
#include "third_party/tonic/dart_state.h"
#include "third_party/tonic/dart_sticky_error.h"
#include "third_party/tonic/file_loader/file_loader.h"
#include "third_party/tonic/scopes/dart_api_scope.h"
#include "third_party/tonic/scopes/dart_isolate_scope.h"

#ifdef ERROR
#undef ERROR
#endif

namespace blink {

std::weak_ptr<DartIsolate> DartIsolate::CreateRootIsolate(
    DartVM* vm,
    fml::RefPtr<DartSnapshot> isolate_snapshot,
    fml::RefPtr<DartSnapshot> shared_snapshot,
    TaskRunners task_runners,
    std::unique_ptr<Window> window,
    fml::WeakPtr<GrContext> resource_context,
    fml::RefPtr<flow::SkiaUnrefQueue> unref_queue,
    std::string advisory_script_uri,
    std::string advisory_script_entrypoint,
    Dart_IsolateFlags* flags) {
  TRACE_EVENT0("flutter", "DartIsolate::CreateRootIsolate");
  Dart_Isolate vm_isolate = nullptr;
  std::weak_ptr<DartIsolate> embedder_isolate;

  char* error = nullptr;

  // Since this is the root isolate, we fake a parent embedder data object. We
  // cannot use unique_ptr here because the destructor is private (since the
  // isolate lifecycle is entirely managed by the VM).
  auto root_embedder_data = std::make_unique<std::shared_ptr<DartIsolate>>(
      std::make_shared<DartIsolate>(
          vm,                           // VM
          std::move(isolate_snapshot),  // isolate snapshot
          std::move(shared_snapshot),   // shared snapshot
          task_runners,                 // task runners
          std::move(resource_context),  // resource context
          std::move(unref_queue),       // skia unref queue
          advisory_script_uri,          // advisory URI
          advisory_script_entrypoint,   // advisory entrypoint
          nullptr  // child isolate preparer will be set when this isolate is
                   // prepared to run
          ));

  std::tie(vm_isolate, embedder_isolate) = CreateDartVMAndEmbedderObjectPair(
      advisory_script_uri.c_str(),         // advisory script URI
      advisory_script_entrypoint.c_str(),  // advisory script entrypoint
      nullptr,                             // package root
      nullptr,                             // package config
      flags,                               // flags
      root_embedder_data.get(),            // parent embedder data
      true,                                // is root isolate
      &error                               // error (out)
  );

  if (error != nullptr) {
    free(error);
  }

  if (vm_isolate == nullptr) {
    return {};
  }

  std::shared_ptr<DartIsolate> shared_embedder_isolate =
      embedder_isolate.lock();
  if (shared_embedder_isolate) {
    // Only root isolates can interact with windows.
    shared_embedder_isolate->SetWindow(std::move(window));
  }

  root_embedder_data.release();

  return embedder_isolate;
}

DartIsolate::DartIsolate(DartVM* vm,
                         fml::RefPtr<DartSnapshot> isolate_snapshot,
                         fml::RefPtr<DartSnapshot> shared_snapshot,
                         TaskRunners task_runners,
                         fml::WeakPtr<GrContext> resource_context,
                         fml::RefPtr<flow::SkiaUnrefQueue> unref_queue,
                         std::string advisory_script_uri,
                         std::string advisory_script_entrypoint,
                         ChildIsolatePreparer child_isolate_preparer)
    : UIDartState(std::move(task_runners),
                  vm->GetSettings().task_observer_add,
                  vm->GetSettings().task_observer_remove,
                  std::move(resource_context),
                  std::move(unref_queue),
                  advisory_script_uri,
                  advisory_script_entrypoint,
                  vm->GetSettings().log_tag,
                  vm->GetIsolateNameServer()),
      vm_(vm),
      isolate_snapshot_(std::move(isolate_snapshot)),
      shared_snapshot_(std::move(shared_snapshot)),
      child_isolate_preparer_(std::move(child_isolate_preparer)) {
  FML_DCHECK(isolate_snapshot_) << "Must contain a valid isolate snapshot.";

  if (vm_ == nullptr) {
    return;
  }

  phase_ = Phase::Uninitialized;
}

DartIsolate::~DartIsolate() = default;

DartIsolate::Phase DartIsolate::GetPhase() const {
  return phase_;
}

DartVM* DartIsolate::GetDartVM() const {
  return vm_;
}

bool DartIsolate::Initialize(Dart_Isolate dart_isolate, bool is_root_isolate) {
  TRACE_EVENT0("flutter", "DartIsolate::Initialize");
  if (phase_ != Phase::Uninitialized) {
    return false;
  }

  if (dart_isolate == nullptr) {
    return false;
  }

  if (Dart_CurrentIsolate() != dart_isolate) {
    return false;
  }

  auto isolate_data = static_cast<std::shared_ptr<DartIsolate>*>(
      Dart_IsolateData(dart_isolate));
  if (isolate_data->get() != this) {
    return false;
  }

  // After this point, isolate scopes can be safely used.
  SetIsolate(dart_isolate);

  // We are entering a new scope (for the first time since initialization) and
  // we want to restore the current scope to null when we exit out of this
  // method. This balances the implicit Dart_EnterIsolate call made by
  // Dart_CreateIsolate (which calls the Initialize).
  Dart_ExitIsolate();

  tonic::DartIsolateScope scope(isolate());

  if (is_root_isolate) {
    if (auto task_runner = GetTaskRunners().GetUITaskRunner()) {
      // Isolates may not have any particular thread affinity. Only initialize
      // the task dispatcher if a task runner is explicitly specified.
      tonic::DartMessageHandler::TaskDispatcher dispatcher =
          [task_runner](std::function<void()> task) {
            task_runner->PostTask(task);
          };
      message_handler().Initialize(dispatcher);
    }
  }

  if (tonic::LogIfError(
          Dart_SetLibraryTagHandler(tonic::DartState::HandleLibraryTag))) {
    return false;
  }

  if (!UpdateThreadPoolNames()) {
    return false;
  }

  phase_ = Phase::Initialized;
  return true;
}

// Updating thread names here does not change the underlying OS thread names.
// Instead, this is just additional metadata for the Observatory to show the
// thread name of the isolate.
bool DartIsolate::UpdateThreadPoolNames() const {
  // TODO(chinmaygarde): This implementation does not account for multiple
  // shells sharing the same (or subset of) threads.
  const auto& task_runners = GetTaskRunners();

  if (auto task_runner = task_runners.GetGPUTaskRunner()) {
    task_runner->PostTask(
        [label = task_runners.GetLabel() + std::string{".gpu"}]() {
          Dart_SetThreadName(label.c_str());
        });
  }

  if (auto task_runner = task_runners.GetUITaskRunner()) {
    task_runner->PostTask(
        [label = task_runners.GetLabel() + std::string{".ui"}]() {
          Dart_SetThreadName(label.c_str());
        });
  }

  if (auto task_runner = task_runners.GetIOTaskRunner()) {
    task_runner->PostTask(
        [label = task_runners.GetLabel() + std::string{".io"}]() {
          Dart_SetThreadName(label.c_str());
        });
  }

  if (auto task_runner = task_runners.GetPlatformTaskRunner()) {
    task_runner->PostTask(
        [label = task_runners.GetLabel() + std::string{".platform"}]() {
          Dart_SetThreadName(label.c_str());
        });
  }

  return true;
}

bool DartIsolate::LoadLibraries(bool is_root_isolate) {
  TRACE_EVENT0("flutter", "DartIsolate::LoadLibraries");
  if (phase_ != Phase::Initialized) {
    return false;
  }

  tonic::DartState::Scope scope(this);

  DartIO::InitForIsolate();

  DartUI::InitForIsolate(is_root_isolate);

  const bool is_service_isolate = Dart_IsServiceIsolate(isolate());

  DartRuntimeHooks::Install(is_root_isolate && !is_service_isolate,
                            GetAdvisoryScriptURI());

  if (!is_service_isolate) {
    class_library().add_provider(
        "ui", std::make_unique<tonic::DartClassProvider>(this, "dart:ui"));
  }

  phase_ = Phase::LibrariesSetup;
  return true;
}

bool DartIsolate::PrepareForRunningFromPrecompiledCode() {
  TRACE_EVENT0("flutter", "DartIsolate::PrepareForRunningFromPrecompiledCode");
  if (phase_ != Phase::LibrariesSetup) {
    return false;
  }

  tonic::DartState::Scope scope(this);

  if (Dart_IsNull(Dart_RootLibrary())) {
    return false;
  }

  if (!MarkIsolateRunnable()) {
    return false;
  }

  child_isolate_preparer_ = [](DartIsolate* isolate) {
    return isolate->PrepareForRunningFromPrecompiledCode();
  };
  phase_ = Phase::Ready;
  return true;
}

bool DartIsolate::LoadKernel(std::shared_ptr<const fml::Mapping> mapping,
                             bool last_piece) {
  if (!Dart_IsKernel(mapping->GetMapping(), mapping->GetSize())) {
    return false;
  }

  // Mapping must be retained until isolate shutdown.
  kernel_buffers_.push_back(mapping);

  Dart_Handle library =
      Dart_LoadLibraryFromKernel(mapping->GetMapping(), mapping->GetSize());
  if (tonic::LogIfError(library)) {
    return false;
  }

  if (!last_piece) {
    // More to come.
    return true;
  }

  Dart_SetRootLibrary(library);
  if (tonic::LogIfError(Dart_FinalizeLoading(false))) {
    return false;
  }
  return true;
}

FML_WARN_UNUSED_RESULT
bool DartIsolate::PrepareForRunningFromKernel(
    std::shared_ptr<const fml::Mapping> mapping,
    bool last_piece) {
  TRACE_EVENT0("flutter", "DartIsolate::PrepareForRunningFromKernel");
  if (phase_ != Phase::LibrariesSetup) {
    return false;
  }

  if (DartVM::IsRunningPrecompiledCode()) {
    return false;
  }

  if (!mapping || mapping->GetSize() == 0) {
    return false;
  }

  tonic::DartState::Scope scope(this);

  // Use root library provided by kernel in favor of one provided by snapshot.
  Dart_SetRootLibrary(Dart_Null());

  if (!LoadKernel(mapping, last_piece)) {
    return false;
  }

  if (!last_piece) {
    // More to come.
    return true;
  }

  if (Dart_IsNull(Dart_RootLibrary())) {
    return false;
  }

  if (!MarkIsolateRunnable()) {
    return false;
  }

  child_isolate_preparer_ = [mapping](DartIsolate* isolate) {
    return isolate->PrepareForRunningFromKernel(mapping);
  };
  phase_ = Phase::Ready;
  return true;
}

bool DartIsolate::MarkIsolateRunnable() {
  TRACE_EVENT0("flutter", "DartIsolate::MarkIsolateRunnable");
  if (phase_ != Phase::LibrariesSetup) {
    return false;
  }

  // This function may only be called from an active isolate scope.
  if (Dart_CurrentIsolate() != isolate()) {
    return false;
  }

  // There must be no current isolate to mark an isolate as being runnable.
  Dart_ExitIsolate();

  char* error = Dart_IsolateMakeRunnable(isolate());
  if (error) {
    FML_DLOG(ERROR) << error;
    ::free(error);
    // Failed. Restore the isolate.
    Dart_EnterIsolate(isolate());
    return false;
  }
  // Success. Restore the isolate.
  Dart_EnterIsolate(isolate());
  return true;
}

FML_WARN_UNUSED_RESULT
bool DartIsolate::Run(const std::string& entrypoint_name) {
  TRACE_EVENT0("flutter", "DartIsolate::Run");
  if (phase_ != Phase::Ready) {
    return false;
  }

  tonic::DartState::Scope scope(this);

  Dart_Handle entrypoint =
      Dart_GetField(Dart_RootLibrary(), tonic::ToDart(entrypoint_name.c_str()));
  if (tonic::LogIfError(entrypoint)) {
    return false;
  }

  Dart_Handle isolate_lib = Dart_LookupLibrary(tonic::ToDart("dart:isolate"));
  if (tonic::LogIfError(isolate_lib)) {
    return false;
  }

  Dart_Handle isolate_args[] = {
      entrypoint,
      Dart_Null(),
  };

  if (tonic::LogIfError(Dart_Invoke(
          isolate_lib, tonic::ToDart("_startMainIsolate"),
          sizeof(isolate_args) / sizeof(isolate_args[0]), isolate_args))) {
    return false;
  }

  phase_ = Phase::Running;
  FML_DLOG(INFO) << "New isolate is in the running state.";
  return true;
}

FML_WARN_UNUSED_RESULT
bool DartIsolate::RunFromLibrary(const std::string& library_name,
                                 const std::string& entrypoint_name) {
  TRACE_EVENT0("flutter", "DartIsolate::RunFromLibrary");
  if (phase_ != Phase::Ready) {
    return false;
  }

  tonic::DartState::Scope scope(this);

  Dart_Handle library = Dart_LookupLibrary(tonic::ToDart(library_name.c_str()));
  if (tonic::LogIfError(library)) {
    return false;
  }

  Dart_Handle entrypoint =
      Dart_GetField(library, tonic::ToDart(entrypoint_name.c_str()));
  if (tonic::LogIfError(entrypoint)) {
    return false;
  }

  Dart_Handle isolate_lib = Dart_LookupLibrary(tonic::ToDart("dart:isolate"));
  if (tonic::LogIfError(isolate_lib)) {
    return false;
  }

  Dart_Handle isolate_args[] = {
      entrypoint,
      Dart_Null(),
  };

  if (tonic::LogIfError(Dart_Invoke(
          isolate_lib, tonic::ToDart("_startMainIsolate"),
          sizeof(isolate_args) / sizeof(isolate_args[0]), isolate_args))) {
    return false;
  }

  phase_ = Phase::Running;
  FML_DLOG(INFO) << "New isolate is in the running state.";
  return true;
}

bool DartIsolate::Shutdown() {
  TRACE_EVENT0("flutter", "DartIsolate::Shutdown");
  // This call may be re-entrant since Dart_ShutdownIsolate can invoke the
  // cleanup callback which deletes the embedder side object of the dart isolate
  // (a.k.a. this).
  if (phase_ == Phase::Shutdown) {
    return false;
  }
  phase_ = Phase::Shutdown;
  Dart_Isolate vm_isolate = isolate();
  // The isolate can be nullptr if this instance is the stub isolate data used
  // during root isolate creation.
  if (vm_isolate != nullptr) {
    // We need to enter the isolate because Dart_ShutdownIsolate does not take
    // the isolate to shutdown as a parameter.
    FML_DCHECK(Dart_CurrentIsolate() == nullptr);
    Dart_EnterIsolate(vm_isolate);
    Dart_ShutdownIsolate();
    FML_DCHECK(Dart_CurrentIsolate() == nullptr);
  }
  return true;
}

Dart_Isolate DartIsolate::DartCreateAndStartServiceIsolate(
    const char* advisory_script_uri,
    const char* advisory_script_entrypoint,
    const char* package_root,
    const char* package_config,
    Dart_IsolateFlags* flags,
    char** error) {
  auto vm = DartVM::ForProcessIfInitialized();

  if (!vm) {
    *error = strdup(
        "Could not resolve the VM when attempting to create the service "
        "isolate.");
    return nullptr;
  }

  const auto& settings = vm->GetSettings();

  if (!settings.enable_observatory) {
    FML_DLOG(INFO) << "Observatory is disabled.";
    return nullptr;
  }

  blink::TaskRunners null_task_runners(
      "io.flutter." DART_VM_SERVICE_ISOLATE_NAME, nullptr, nullptr, nullptr,
      nullptr);

  flags->load_vmservice_library = true;

  std::weak_ptr<DartIsolate> weak_service_isolate =
      DartIsolate::CreateRootIsolate(
          vm.get(),                  // vm
          vm->GetIsolateSnapshot(),  // isolate snapshot
          vm->GetSharedSnapshot(),   // shared snapshot
          null_task_runners,         // task runners
          nullptr,                   // window
          {},                        // resource context
          {},                        // unref queue
          advisory_script_uri == nullptr ? ""
                                         : advisory_script_uri,  // script uri
          advisory_script_entrypoint == nullptr
              ? ""
              : advisory_script_entrypoint,  // script entrypoint
          flags                              // flags
      );

  std::shared_ptr<DartIsolate> service_isolate = weak_service_isolate.lock();
  if (!service_isolate) {
    *error = strdup("Could not create the service isolate.");
    FML_DLOG(ERROR) << *error;
    return nullptr;
  }

  tonic::DartState::Scope scope(service_isolate);
  if (!DartServiceIsolate::Startup(
          settings.ipv6 ? "::1" : "127.0.0.1",  // server IP address
          settings.observatory_port,            // server observatory port
          tonic::DartState::HandleLibraryTag,   // embedder library tag handler
          false,  //  disable websocket origin check
          error   // error (out)
          )) {
    // Error is populated by call to startup.
    FML_DLOG(ERROR) << *error;
    return nullptr;
  }

  vm->GetServiceProtocol().ToggleHooks(true);

  return service_isolate->isolate();
}

// |Dart_IsolateCreateCallback|
Dart_Isolate DartIsolate::DartIsolateCreateCallback(
    const char* advisory_script_uri,
    const char* advisory_script_entrypoint,
    const char* package_root,
    const char* package_config,
    Dart_IsolateFlags* flags,
    std::shared_ptr<DartIsolate>* parent_embedder_isolate,
    char** error) {
  if (parent_embedder_isolate == nullptr &&
      strcmp(advisory_script_uri, DART_VM_SERVICE_ISOLATE_NAME) == 0) {
    // The VM attempts to start the VM service for us on |Dart_Initialize|. In
    // such a case, the callback data will be null and the script URI will be
    // DART_VM_SERVICE_ISOLATE_NAME. In such cases, we just create the service
    // isolate like normal but dont hold a reference to it at all. We also start
    // this isolate since we will never again reference it from the engine.
    return DartCreateAndStartServiceIsolate(advisory_script_uri,         //
                                            advisory_script_entrypoint,  //
                                            package_root,                //
                                            package_config,              //
                                            flags,                       //
                                            error                        //
    );
  }

  return CreateDartVMAndEmbedderObjectPair(
             advisory_script_uri,         // URI
             advisory_script_entrypoint,  // entrypoint
             package_root,                // package root
             package_config,              // package config
             flags,                       // isolate flags
             parent_embedder_isolate,     // embedder data
             false,                       // is root isolate
             error                        // error
             )
      .first;
}

std::pair<Dart_Isolate, std::weak_ptr<DartIsolate>>
DartIsolate::CreateDartVMAndEmbedderObjectPair(
    const char* advisory_script_uri,
    const char* advisory_script_entrypoint,
    const char* package_root,
    const char* package_config,
    Dart_IsolateFlags* flags,
    std::shared_ptr<DartIsolate>* p_parent_embedder_isolate,
    bool is_root_isolate,
    char** error) {
  TRACE_EVENT0("flutter", "DartIsolate::CreateDartVMAndEmbedderObjectPair");

  std::unique_ptr<std::shared_ptr<DartIsolate>> embedder_isolate(
      p_parent_embedder_isolate);

  if (embedder_isolate == nullptr ||
      (*embedder_isolate)->GetDartVM() == nullptr) {
    *error =
        strdup("Parent isolate did not have embedder specific callback data.");
    FML_DLOG(ERROR) << *error;
    return {nullptr, {}};
  }

  DartVM* const vm = (*embedder_isolate)->GetDartVM();

  if (!is_root_isolate) {
    auto raw_embedder_isolate = embedder_isolate.release();

    blink::TaskRunners null_task_runners(advisory_script_uri, nullptr, nullptr,
                                         nullptr, nullptr);

    embedder_isolate = std::make_unique<std::shared_ptr<DartIsolate>>(
        std::make_shared<DartIsolate>(
            vm,                                             // vm
            (*raw_embedder_isolate)->GetIsolateSnapshot(),  // isolate_snapshot
            (*raw_embedder_isolate)->GetSharedSnapshot(),   // shared_snapshot
            null_task_runners,                              // task_runners
            fml::WeakPtr<GrContext>{},                      // resource_context
            nullptr,                                        // unref_queue
            advisory_script_uri,         // advisory_script_uri
            advisory_script_entrypoint,  // advisory_script_entrypoint
            (*raw_embedder_isolate)->child_isolate_preparer_));
  }

  // Create the Dart VM isolate and give it the embedder object as the baton.
  Dart_Isolate isolate = Dart_CreateIsolate(
      advisory_script_uri,         //
      advisory_script_entrypoint,  //
      (*embedder_isolate)
          ->GetIsolateSnapshot()
          ->GetData()
          ->GetSnapshotPointer(),
      (*embedder_isolate)->GetIsolateSnapshot()->GetInstructionsIfPresent(),
      (*embedder_isolate)->GetSharedSnapshot()->GetDataIfPresent(),
      (*embedder_isolate)->GetSharedSnapshot()->GetInstructionsIfPresent(),
      flags, embedder_isolate.get(), error);

  if (isolate == nullptr) {
    FML_DLOG(ERROR) << *error;
    return {nullptr, {}};
  }

  if (!(*embedder_isolate)->Initialize(isolate, is_root_isolate)) {
    *error = strdup("Embedder could not initialize the Dart isolate.");
    FML_DLOG(ERROR) << *error;
    return {nullptr, {}};
  }

  if (!(*embedder_isolate)->LoadLibraries(is_root_isolate)) {
    *error =
        strdup("Embedder could not load libraries in the new Dart isolate.");
    FML_DLOG(ERROR) << *error;
    return {nullptr, {}};
  }

  auto weak_embedder_isolate = (*embedder_isolate)->GetWeakIsolatePtr();

  // Root isolates will be setup by the engine and the service isolate (which is
  // also a root isolate) by the utility routines in the VM. However, secondary
  // isolates will be run by the VM if they are marked as runnable.
  if (!is_root_isolate) {
    FML_DCHECK((*embedder_isolate)->child_isolate_preparer_);
    if (!(*embedder_isolate)
             ->child_isolate_preparer_((*embedder_isolate).get())) {
      *error = strdup("Could not prepare the child isolate to run.");
      FML_DLOG(ERROR) << *error;
      return {nullptr, {}};
    }
  }

  // The ownership of the embedder object is controlled by the Dart VM. So the
  // only reference returned to the caller is weak.
  embedder_isolate.release();
  return {isolate, weak_embedder_isolate};
}

// |Dart_IsolateShutdownCallback|
void DartIsolate::DartIsolateShutdownCallback(
    std::shared_ptr<DartIsolate>* embedder_isolate) {
  if (!tonic::DartStickyError::IsSet()) {
    return;
  }

  tonic::DartApiScope api_scope;
  Dart_Handle sticky_error = Dart_GetStickyError();
  if (!Dart_IsFatalError(sticky_error)) {
    FML_LOG(ERROR) << "Isolate " << tonic::StdStringFromDart(Dart_DebugName())
                   << " exited with an error";
    FML_CHECK(tonic::LogIfError(sticky_error));
  }
}

// |Dart_IsolateCleanupCallback|
void DartIsolate::DartIsolateCleanupCallback(
    std::shared_ptr<DartIsolate>* embedder_isolate) {
  delete embedder_isolate;
}

fml::RefPtr<DartSnapshot> DartIsolate::GetIsolateSnapshot() const {
  return isolate_snapshot_;
}

fml::RefPtr<DartSnapshot> DartIsolate::GetSharedSnapshot() const {
  return shared_snapshot_;
}

std::weak_ptr<DartIsolate> DartIsolate::GetWeakIsolatePtr() {
  return std::static_pointer_cast<DartIsolate>(shared_from_this());
}

void DartIsolate::AddIsolateShutdownCallback(fml::closure closure) {
  shutdown_callbacks_.emplace_back(
      std::make_unique<AutoFireClosure>(std::move(closure)));
}

}  // namespace blink
