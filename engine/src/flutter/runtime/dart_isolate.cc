// Copyright 2013 The Flutter Authors. All rights reserved.
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
#include "flutter/runtime/dart_vm_lifecycle.h"
#include "third_party/dart/runtime/include/dart_api.h"
#include "third_party/dart/runtime/include/dart_tools_api.h"
#include "third_party/tonic/converter/dart_converter.h"
#include "third_party/tonic/dart_class_library.h"
#include "third_party/tonic/dart_class_provider.h"
#include "third_party/tonic/dart_message_handler.h"
#include "third_party/tonic/dart_state.h"
#include "third_party/tonic/file_loader/file_loader.h"
#include "third_party/tonic/logging/dart_invoke.h"
#include "third_party/tonic/scopes/dart_api_scope.h"
#include "third_party/tonic/scopes/dart_isolate_scope.h"

namespace flutter {

std::weak_ptr<DartIsolate> DartIsolate::CreateRootIsolate(
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
    fml::closure isolate_shutdown_callback) {
  TRACE_EVENT0("flutter", "DartIsolate::CreateRootIsolate");
  Dart_Isolate vm_isolate = nullptr;
  std::weak_ptr<DartIsolate> embedder_isolate;

  char* error = nullptr;

  // Since this is the root isolate, we fake a parent embedder data object. We
  // cannot use unique_ptr here because the destructor is private (since the
  // isolate lifecycle is entirely managed by the VM).
  //
  // The child isolate preparer is null but will be set when the isolate is
  // being prepared to run.
  auto root_embedder_data = std::make_unique<std::shared_ptr<DartIsolate>>(
      std::make_shared<DartIsolate>(
          settings,                     // settings
          std::move(isolate_snapshot),  // isolate snapshot
          std::move(shared_snapshot),   // shared snapshot
          task_runners,                 // task runners
          std::move(io_manager),        // IO manager
          std::move(image_decoder),     // Image Decoder
          advisory_script_uri,          // advisory URI
          advisory_script_entrypoint,   // advisory entrypoint
          nullptr,                      // child isolate preparer
          isolate_create_callback,      // isolate create callback
          isolate_shutdown_callback,    // isolate shutdown callback,
          true,                         // is_root_isolate
          true                          // is_group_root_isolate
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

DartIsolate::DartIsolate(const Settings& settings,
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
                         bool is_group_root_isolate)
    : UIDartState(std::move(task_runners),
                  settings.task_observer_add,
                  settings.task_observer_remove,
                  std::move(io_manager),
                  std::move(image_decoder),
                  advisory_script_uri,
                  advisory_script_entrypoint,
                  settings.log_tag,
                  settings.unhandled_exception_callback,
                  DartVMRef::GetIsolateNameServer()),
      settings_(settings),
      isolate_snapshot_(std::move(isolate_snapshot)),
      shared_snapshot_(std::move(shared_snapshot)),
      child_isolate_preparer_(std::move(child_isolate_preparer)),
      isolate_create_callback_(isolate_create_callback),
      isolate_shutdown_callback_(isolate_shutdown_callback),
      is_root_isolate_(is_root_isolate),
      is_group_root_isolate_(is_group_root_isolate) {
  FML_DCHECK(isolate_snapshot_) << "Must contain a valid isolate snapshot.";
  phase_ = Phase::Uninitialized;
}

DartIsolate::~DartIsolate() = default;

const Settings& DartIsolate::GetSettings() const {
  return settings_;
}

DartIsolate::Phase DartIsolate::GetPhase() const {
  return phase_;
}

std::string DartIsolate::GetServiceId() {
  const char* service_id_buf = Dart_IsolateServiceId(isolate());
  std::string service_id(service_id_buf);
  free(const_cast<char*>(service_id_buf));
  return service_id;
}

bool DartIsolate::Initialize(Dart_Isolate dart_isolate) {
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

  // After this point, isolate scopes can be safely used.
  SetIsolate(dart_isolate);

  // We are entering a new scope (for the first time since initialization) and
  // we want to restore the current scope to null when we exit out of this
  // method. This balances the implicit Dart_EnterIsolate call made by
  // Dart_CreateIsolateGroup (which calls the Initialize).
  Dart_ExitIsolate();

  tonic::DartIsolateScope scope(isolate());

  SetMessageHandlingTaskRunner(GetTaskRunners().GetUITaskRunner());

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

fml::RefPtr<fml::TaskRunner> DartIsolate::GetMessageHandlingTaskRunner() const {
  return message_handling_task_runner_;
}

void DartIsolate::SetMessageHandlingTaskRunner(
    fml::RefPtr<fml::TaskRunner> runner) {
  if (!IsRootIsolate() || !runner) {
    return;
  }

  message_handling_task_runner_ = runner;

  message_handler().Initialize(
      [runner](std::function<void()> task) { runner->PostTask(task); });
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

bool DartIsolate::LoadLibraries() {
  TRACE_EVENT0("flutter", "DartIsolate::LoadLibraries");
  if (phase_ != Phase::Initialized) {
    return false;
  }

  tonic::DartState::Scope scope(this);

  DartIO::InitForIsolate();

  DartUI::InitForIsolate(IsRootIsolate());

  const bool is_service_isolate = Dart_IsServiceIsolate(isolate());

  DartRuntimeHooks::Install(IsRootIsolate() && !is_service_isolate,
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

  if (isolate_create_callback_) {
    isolate_create_callback_();
  }

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

  // Child isolate shares root isolate embedder_isolate (lines 691 and 693
  // below). Re-initializing child_isolate_preparer_ lambda while it is being
  // executed leads to crashes.
  if (child_isolate_preparer_ == nullptr) {
    child_isolate_preparer_ = [buffers =
                                   kernel_buffers_](DartIsolate* isolate) {
      for (unsigned long i = 0; i < buffers.size(); i++) {
        bool last_piece = i + 1 == buffers.size();
        const std::shared_ptr<const fml::Mapping>& buffer = buffers.at(i);
        if (!isolate->PrepareForRunningFromKernel(buffer, last_piece)) {
          return false;
        }
      }
      return true;
    };
  }

  if (isolate_create_callback_) {
    isolate_create_callback_();
  }

  phase_ = Phase::Ready;

  return true;
}

FML_WARN_UNUSED_RESULT
bool DartIsolate::PrepareForRunningFromKernels(
    std::vector<std::shared_ptr<const fml::Mapping>> kernels) {
  const auto count = kernels.size();
  if (count == 0) {
    return false;
  }

  for (size_t i = 0; i < count; ++i) {
    bool last = (i == (count - 1));
    if (!PrepareForRunningFromKernel(kernels[i], last)) {
      return false;
    }
  }

  return true;
}

FML_WARN_UNUSED_RESULT
bool DartIsolate::PrepareForRunningFromKernels(
    std::vector<std::unique_ptr<const fml::Mapping>> kernels) {
  std::vector<std::shared_ptr<const fml::Mapping>> shared_kernels;
  for (auto& kernel : kernels) {
    shared_kernels.emplace_back(std::move(kernel));
  }
  return PrepareForRunningFromKernels(shared_kernels);
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
static bool InvokeMainEntrypoint(Dart_Handle user_entrypoint_function,
                                 Dart_Handle args) {
  if (tonic::LogIfError(user_entrypoint_function)) {
    FML_LOG(ERROR) << "Could not resolve main entrypoint function.";
    return false;
  }

  Dart_Handle start_main_isolate_function =
      tonic::DartInvokeField(Dart_LookupLibrary(tonic::ToDart("dart:isolate")),
                             "_getStartMainIsolateFunction", {});

  if (tonic::LogIfError(start_main_isolate_function)) {
    FML_LOG(ERROR) << "Could not resolve main entrypoint trampoline.";
    return false;
  }

  if (tonic::LogIfError(tonic::DartInvokeField(
          Dart_LookupLibrary(tonic::ToDart("dart:ui")), "_runMainZoned",
          {start_main_isolate_function, user_entrypoint_function, args}))) {
    FML_LOG(ERROR) << "Could not invoke the main entrypoint.";
    return false;
  }

  return true;
}

FML_WARN_UNUSED_RESULT
bool DartIsolate::Run(const std::string& entrypoint_name,
                      const std::vector<std::string>& args,
                      fml::closure on_run) {
  TRACE_EVENT0("flutter", "DartIsolate::Run");
  if (phase_ != Phase::Ready) {
    return false;
  }

  tonic::DartState::Scope scope(this);

  auto user_entrypoint_function =
      Dart_GetField(Dart_RootLibrary(), tonic::ToDart(entrypoint_name.c_str()));

  auto entrypoint_args = tonic::ToDart(args);

  if (!InvokeMainEntrypoint(user_entrypoint_function, entrypoint_args)) {
    return false;
  }

  phase_ = Phase::Running;
  FML_DLOG(INFO) << "New isolate is in the running state.";

  if (on_run) {
    on_run();
  }
  return true;
}

FML_WARN_UNUSED_RESULT
bool DartIsolate::RunFromLibrary(const std::string& library_name,
                                 const std::string& entrypoint_name,
                                 const std::vector<std::string>& args,
                                 fml::closure on_run) {
  TRACE_EVENT0("flutter", "DartIsolate::RunFromLibrary");
  if (phase_ != Phase::Ready) {
    return false;
  }

  tonic::DartState::Scope scope(this);

  auto user_entrypoint_function =
      Dart_GetField(Dart_LookupLibrary(tonic::ToDart(library_name.c_str())),
                    tonic::ToDart(entrypoint_name.c_str()));

  auto entrypoint_args = tonic::ToDart(args);

  if (!InvokeMainEntrypoint(user_entrypoint_function, entrypoint_args)) {
    return false;
  }

  phase_ = Phase::Running;
  FML_DLOG(INFO) << "New isolate is in the running state.";

  if (on_run) {
    on_run();
  }
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
    const char* package_root,
    const char* package_config,
    Dart_IsolateFlags* flags,
    char** error) {
  auto vm_data = DartVMRef::GetVMData();

  if (!vm_data) {
    *error = strdup(
        "Could not access VM data to initialize isolates. This may be because "
        "the VM has initialized shutdown on another thread already.");
    return nullptr;
  }

  const auto& settings = vm_data->GetSettings();

  if (!settings.enable_observatory) {
    FML_DLOG(INFO) << "Observatory is disabled.";
    return nullptr;
  }

  TaskRunners null_task_runners("io.flutter." DART_VM_SERVICE_ISOLATE_NAME,
                                nullptr, nullptr, nullptr, nullptr);

  flags->load_vmservice_library = true;

  std::weak_ptr<DartIsolate> weak_service_isolate =
      DartIsolate::CreateRootIsolate(
          vm_data->GetSettings(),         // settings
          vm_data->GetIsolateSnapshot(),  // isolate snapshot
          vm_data->GetSharedSnapshot(),   // shared snapshot
          null_task_runners,              // task runners
          nullptr,                        // window
          {},                             // IO Manager
          {},                             // Image Decoder
          DART_VM_SERVICE_ISOLATE_NAME,   // script uri
          DART_VM_SERVICE_ISOLATE_NAME,   // script entrypoint
          flags,                          // flags
          nullptr,                        // isolate create callback
          nullptr                         // isolate shutdown callback
      );

  std::shared_ptr<DartIsolate> service_isolate = weak_service_isolate.lock();
  if (!service_isolate) {
    *error = strdup("Could not create the service isolate.");
    FML_DLOG(ERROR) << *error;
    return nullptr;
  }

  tonic::DartState::Scope scope(service_isolate);
  if (!DartServiceIsolate::Startup(
          settings.observatory_host,           // server IP address
          settings.observatory_port,           // server observatory port
          tonic::DartState::HandleLibraryTag,  // embedder library tag handler
          false,  //  disable websocket origin check
          settings.disable_service_auth_codes,  // disable VM service auth codes
          error                                 // error (out)
          )) {
    // Error is populated by call to startup.
    FML_DLOG(ERROR) << *error;
    return nullptr;
  }

  if (auto service_protocol = DartVMRef::GetServiceProtocol()) {
    service_protocol->ToggleHooks(true);
  } else {
    FML_DLOG(ERROR)
        << "Could not acquire the service protocol handlers. This might be "
           "because the VM has already begun teardown on another thread.";
  }

  return service_isolate->isolate();
}

// |Dart_IsolateGroupCreateCallback|
Dart_Isolate DartIsolate::DartIsolateGroupCreateCallback(
    const char* advisory_script_uri,
    const char* advisory_script_entrypoint,
    const char* package_root,
    const char* package_config,
    Dart_IsolateFlags* flags,
    std::shared_ptr<DartIsolate>* parent_embedder_isolate,
    char** error) {
  TRACE_EVENT0("flutter", "DartIsolate::DartIsolateGroupCreateCallback");
  if (parent_embedder_isolate == nullptr &&
      strcmp(advisory_script_uri, DART_VM_SERVICE_ISOLATE_NAME) == 0) {
    // The VM attempts to start the VM service for us on |Dart_Initialize|. In
    // such a case, the callback data will be null and the script URI will be
    // DART_VM_SERVICE_ISOLATE_NAME. In such cases, we just create the service
    // isolate like normal but dont hold a reference to it at all. We also start
    // this isolate since we will never again reference it from the engine.
    return DartCreateAndStartServiceIsolate(package_root,    //
                                            package_config,  //
                                            flags,           //
                                            error            //
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

// |Dart_IsolateInitializeCallback|
bool DartIsolate::DartIsolateInitializeCallback(void** child_callback_data,
                                                char** error) {
  TRACE_EVENT0("flutter", "DartIsolate::DartIsolateInitializeCallback");
  Dart_Isolate isolate = Dart_CurrentIsolate();
  if (isolate == nullptr) {
    *error = strdup("Isolate should be available in initialize callback.");
    FML_DLOG(ERROR) << *error;
    return false;
  }

  auto* root_embedder_isolate = static_cast<std::shared_ptr<DartIsolate>*>(
      Dart_CurrentIsolateGroupData());

  TaskRunners null_task_runners(
      (*root_embedder_isolate)->GetAdvisoryScriptURI(),
      /* platform= */ nullptr, /* gpu= */ nullptr,
      /* ui= */ nullptr,
      /* io= */ nullptr);

  auto embedder_isolate = std::make_unique<std::shared_ptr<DartIsolate>>(
      std::make_shared<DartIsolate>(
          (*root_embedder_isolate)->GetSettings(),         // settings
          (*root_embedder_isolate)->GetIsolateSnapshot(),  // isolate_snapshot
          (*root_embedder_isolate)->GetSharedSnapshot(),   // shared_snapshot
          null_task_runners,                               // task_runners
          fml::WeakPtr<IOManager>{},                       // io_manager
          fml::WeakPtr<ImageDecoder>{},                    // io_manager
          (*root_embedder_isolate)
              ->GetAdvisoryScriptURI(),  // advisory_script_uri
          (*root_embedder_isolate)
              ->GetAdvisoryScriptEntrypoint(),  // advisory_script_entrypoint
          (*root_embedder_isolate)->child_isolate_preparer_,     // preparer
          (*root_embedder_isolate)->isolate_create_callback_,    // on create
          (*root_embedder_isolate)->isolate_shutdown_callback_,  // on shutdown
          false,    // is_root_isolate
          false));  // is_group_root_isolate

  // root isolate should have been created via CreateRootIsolate and
  // CreateDartVMAndEmbedderObjectPair
  if (!InitializeIsolate(*embedder_isolate, isolate, error)) {
    return false;
  }

  // The ownership of the embedder object is controlled by the Dart VM. So the
  // only reference returned to the caller is weak.
  *child_callback_data = embedder_isolate.release();

  Dart_EnterIsolate(isolate);
  return true;
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

  if (embedder_isolate == nullptr) {
    *error =
        strdup("Parent isolate did not have embedder specific callback data.");
    FML_DLOG(ERROR) << *error;
    return {nullptr, {}};
  }

  if (!is_root_isolate) {
    auto* raw_embedder_isolate = embedder_isolate.release();

    TaskRunners null_task_runners(advisory_script_uri, nullptr, nullptr,
                                  nullptr, nullptr);

    // Copy most fields from the parent to the child.
    embedder_isolate = std::make_unique<std::shared_ptr<DartIsolate>>(
        std::make_shared<DartIsolate>(
            (*raw_embedder_isolate)->GetSettings(),         // settings
            (*raw_embedder_isolate)->GetIsolateSnapshot(),  // isolate_snapshot
            (*raw_embedder_isolate)->GetSharedSnapshot(),   // shared_snapshot
            null_task_runners,                              // task_runners
            fml::WeakPtr<IOManager>{},                      // io_manager
            fml::WeakPtr<ImageDecoder>{},                   // io_manager
            advisory_script_uri,         // advisory_script_uri
            advisory_script_entrypoint,  // advisory_script_entrypoint
            (*raw_embedder_isolate)->child_isolate_preparer_,     // preparer
            (*raw_embedder_isolate)->isolate_create_callback_,    // on create
            (*raw_embedder_isolate)->isolate_shutdown_callback_,  // on shutdown
            is_root_isolate,
            true));  // is_root_group_isolate
  }

  // Create the Dart VM isolate and give it the embedder object as the baton.
  Dart_Isolate isolate = Dart_CreateIsolateGroup(
      advisory_script_uri,         //
      advisory_script_entrypoint,  //
      (*embedder_isolate)->GetIsolateSnapshot()->GetDataMapping(),
      (*embedder_isolate)->GetIsolateSnapshot()->GetInstructionsMapping(),
      (*embedder_isolate)->GetSharedSnapshot()->GetDataMapping(),
      (*embedder_isolate)->GetSharedSnapshot()->GetInstructionsMapping(), flags,
      embedder_isolate.get(),  // isolate_group_data
      embedder_isolate.get(),  // isolate_group
      error);

  if (isolate == nullptr) {
    FML_DLOG(ERROR) << *error;
    return {nullptr, {}};
  }

  if (!InitializeIsolate(*embedder_isolate, isolate, error)) {
    return {nullptr, {}};
  }

  auto* isolate_data = static_cast<std::shared_ptr<DartIsolate>*>(
      Dart_IsolateGroupData(isolate));
  FML_DCHECK(isolate_data->get() == embedder_isolate->get());

  auto weak_embedder_isolate = (*embedder_isolate)->GetWeakIsolatePtr();

  // The ownership of the embedder object is controlled by the Dart VM. So the
  // only reference returned to the caller is weak.
  embedder_isolate.release();
  return {isolate, weak_embedder_isolate};
}

bool DartIsolate::InitializeIsolate(
    std::shared_ptr<DartIsolate> embedder_isolate,
    Dart_Isolate isolate,
    char** error) {
  TRACE_EVENT0("flutter", "DartIsolate::InitializeIsolate");
  if (!embedder_isolate->Initialize(isolate)) {
    *error = strdup("Embedder could not initialize the Dart isolate.");
    FML_DLOG(ERROR) << *error;
    return false;
  }

  if (!embedder_isolate->LoadLibraries()) {
    *error =
        strdup("Embedder could not load libraries in the new Dart isolate.");
    FML_DLOG(ERROR) << *error;
    return false;
  }

  // Root isolates will be setup by the engine and the service isolate (which is
  // also a root isolate) by the utility routines in the VM. However, secondary
  // isolates will be run by the VM if they are marked as runnable.
  if (!embedder_isolate->IsRootIsolate()) {
    FML_DCHECK(embedder_isolate->child_isolate_preparer_);
    if (!embedder_isolate->child_isolate_preparer_(embedder_isolate.get())) {
      *error = strdup("Could not prepare the child isolate to run.");
      FML_DLOG(ERROR) << *error;
      return false;
    }
  }

  return true;
}

// |Dart_IsolateShutdownCallback|
void DartIsolate::DartIsolateShutdownCallback(
    std::shared_ptr<DartIsolate>* isolate_group_data,
    std::shared_ptr<DartIsolate>* isolate_data) {
  TRACE_EVENT0("flutter", "DartIsolate::DartIsolateShutdownCallback");
  isolate_group_data->get()->OnShutdownCallback();
}

// |Dart_IsolateGroupCleanupCallback|
void DartIsolate::DartIsolateGroupCleanupCallback(
    std::shared_ptr<DartIsolate>* isolate_data) {
  TRACE_EVENT0("flutter", "DartIsolate::DartIsolateGroupCleanupCallback");
  FML_DLOG(INFO) << "DartIsolateGroupCleanupCallback isolate_data "
                 << isolate_data;

  delete isolate_data;
}

// |Dart_IsolateCleanupCallback|
void DartIsolate::DartIsolateCleanupCallback(
    std::shared_ptr<DartIsolate>* isolate_group_data,
    std::shared_ptr<DartIsolate>* isolate_data) {
  TRACE_EVENT0("flutter", "DartIsolate::DartIsolateCleanupCallback");

  if ((*isolate_data)->IsRootIsolate()) {
    // isolate_data will be cleaned up as part of IsolateGroup cleanup
    FML_DLOG(INFO)
        << "DartIsolateCleanupCallback no-op for root isolate isolate_data "
        << isolate_data;
    return;
  }
  if ((*isolate_data)->IsGroupRootIsolate()) {
    // Even if isolate was not a root isolate(i.e. was spawned),
    // it might have IsolateGroup created for it (when
    // --no-enable-isolate-groups dart vm flag is used).
    // Then its isolate_data will be cleaned up as part of IsolateGroup
    // cleanup as well.
    FML_DLOG(INFO) << "DartIsolateCleanupCallback no-op for group root isolate "
                      "isolate_data "
                   << isolate_data;
    return;
  }

  FML_DLOG(INFO) << "DartIsolateCleanupCallback cleaned up isolate_data "
                 << isolate_data;
  delete isolate_data;
}

fml::RefPtr<const DartSnapshot> DartIsolate::GetIsolateSnapshot() const {
  return isolate_snapshot_;
}

fml::RefPtr<const DartSnapshot> DartIsolate::GetSharedSnapshot() const {
  return shared_snapshot_;
}

std::weak_ptr<DartIsolate> DartIsolate::GetWeakIsolatePtr() {
  return std::static_pointer_cast<DartIsolate>(shared_from_this());
}

void DartIsolate::AddIsolateShutdownCallback(fml::closure closure) {
  shutdown_callbacks_.emplace_back(
      std::make_unique<AutoFireClosure>(std::move(closure)));
}

void DartIsolate::OnShutdownCallback() {
  {
    tonic::DartApiScope api_scope;
    Dart_Handle sticky_error = Dart_GetStickyError();
    if (!Dart_IsNull(sticky_error) && !Dart_IsFatalError(sticky_error)) {
      FML_LOG(ERROR) << Dart_GetError(sticky_error);
    }
  }

  shutdown_callbacks_.clear();
  if (isolate_shutdown_callback_) {
    isolate_shutdown_callback_();
  }
}

DartIsolate::AutoFireClosure::AutoFireClosure(fml::closure closure)
    : closure_(std::move(closure)) {}

DartIsolate::AutoFireClosure::~AutoFireClosure() {
  if (closure_) {
    closure_();
  }
}

}  // namespace flutter
