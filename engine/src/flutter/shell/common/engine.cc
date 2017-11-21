// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/common/engine.h"

#include <dlfcn.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <unistd.h>
#include <memory>
#include <utility>

#include "flutter/assets/directory_asset_bundle.h"
#include "flutter/assets/unzipper_provider.h"
#include "flutter/assets/zip_asset_store.h"
#include "flutter/common/settings.h"
#include "flutter/common/threads.h"
#include "flutter/glue/trace_event.h"
#include "flutter/lib/snapshot/snapshot.h"
#include "flutter/lib/ui/text/font_collection.h"
#include "flutter/runtime/asset_font_selector.h"
#include "flutter/runtime/dart_controller.h"
#include "flutter/runtime/dart_init.h"
#include "flutter/runtime/runtime_init.h"
#include "flutter/runtime/test_font_selector.h"
#include "flutter/shell/common/animator.h"
#include "flutter/shell/common/platform_view.h"
#include "flutter/sky/engine/public/web/Sky.h"
#include "lib/fxl/files/eintr_wrapper.h"
#include "lib/fxl/files/file.h"
#include "lib/fxl/files/path.h"
#include "lib/fxl/files/unique_fd.h"
#include "lib/fxl/functional/make_copyable.h"
#include "third_party/rapidjson/rapidjson/document.h"
#include "third_party/skia/include/core/SkCanvas.h"
#include "third_party/skia/include/core/SkPictureRecorder.h"

namespace shell {
namespace {

constexpr char kAssetChannel[] = "flutter/assets";
constexpr char kLifecycleChannel[] = "flutter/lifecycle";
constexpr char kNavigationChannel[] = "flutter/navigation";
constexpr char kLocalizationChannel[] = "flutter/localization";
constexpr char kSettingsChannel[] = "flutter/settings";

bool PathExists(const std::string& path) {
  return access(path.c_str(), R_OK) == 0;
}

std::string FindPackagesPath(const std::string& main_dart) {
  std::string directory = files::GetDirectoryName(main_dart);
  std::string packages_path = directory + "/.packages";
  if (!PathExists(packages_path)) {
    directory = files::GetDirectoryName(directory);
    packages_path = directory + "/.packages";
    if (!PathExists(packages_path))
      packages_path = std::string();
  }
  return packages_path;
}

std::string GetScriptUriFromPath(const std::string& path) {
  return "file://" + path;
}

}  // namespace

Engine::Engine(PlatformView* platform_view)
    : platform_view_(platform_view->GetWeakPtr()),
      animator_(std::make_unique<Animator>(
          platform_view->rasterizer().GetWeakRasterizerPtr(),
          platform_view->GetVsyncWaiter(),
          this)),
      load_script_error_(tonic::kNoError),
      user_settings_data_("{}"),
      activity_running_(false),
      have_surface_(false),
      weak_factory_(this) {}

Engine::~Engine() {}

void Engine::set_rasterizer(fml::WeakPtr<Rasterizer> rasterizer) {
  animator_->set_rasterizer(rasterizer);
}

fml::WeakPtr<Engine> Engine::GetWeakPtr() {
  return weak_factory_.GetWeakPtr();
}

#if !FLUTTER_AOT
#elif OS(IOS)
#elif OS(ANDROID)
static const uint8_t* MemMapSnapshot(const std::string& aot_snapshot_path,
                                     const std::string& default_file_name,
                                     const std::string& settings_file_name,
                                     bool executable) {
  std::string asset_path;
  if (settings_file_name.empty()) {
    asset_path = aot_snapshot_path + "/" + default_file_name;
  } else {
    asset_path = aot_snapshot_path + "/" + settings_file_name;
  }

  struct stat info;
  if (stat(asset_path.c_str(), &info) < 0) {
    return nullptr;
  }
  int64_t asset_size = info.st_size;

  fxl::UniqueFD fd(HANDLE_EINTR(open(asset_path.c_str(), O_RDONLY)));
  if (fd.get() == -1) {
    return nullptr;
  }

  int mmap_flags = PROT_READ;
  if (executable)
    mmap_flags |= PROT_EXEC;

  void* symbol = mmap(NULL, asset_size, mmap_flags, MAP_PRIVATE, fd.get(), 0);
  if (symbol == MAP_FAILED) {
    return nullptr;
  }
  return reinterpret_cast<const uint8_t*>(symbol);
}
#endif

static const uint8_t* default_isolate_snapshot_data = nullptr;
static const uint8_t* default_isolate_snapshot_instr = nullptr;

void Engine::Init(const std::string& bundle_path) {
  const uint8_t* vm_snapshot_data;
  const uint8_t* vm_snapshot_instr;
#if !FLUTTER_AOT
  vm_snapshot_data = ::kDartVmSnapshotData;
  vm_snapshot_instr = ::kDartVmSnapshotInstructions;
  default_isolate_snapshot_data = ::kDartIsolateCoreSnapshotData;
  default_isolate_snapshot_instr = ::kDartIsolateCoreSnapshotInstructions;
#elif OS(IOS)
  const char* kDartApplicationLibraryPath = "App.framework/App";
  const char* application_library_path = kDartApplicationLibraryPath;
  const blink::Settings& settings = blink::Settings::Get();
  const std::string& application_library_path_setting =
      settings.application_library_path;
  if (!application_library_path_setting.empty()) {
    application_library_path = application_library_path_setting.c_str();
  }
  dlerror();  // clear previous errors on thread
  void* library_handle = dlopen(application_library_path, RTLD_NOW);
  const char* err = dlerror();
  if (err != nullptr) {
    FXL_LOG(FATAL) << "dlopen failed: " << err;
  }
  vm_snapshot_data = reinterpret_cast<const uint8_t*>(
      dlsym(library_handle, "kDartVmSnapshotData"));
  vm_snapshot_instr = reinterpret_cast<const uint8_t*>(
      dlsym(library_handle, "kDartVmSnapshotInstructions"));
  default_isolate_snapshot_data = reinterpret_cast<const uint8_t*>(
      dlsym(library_handle, "kDartIsolateSnapshotData"));
  default_isolate_snapshot_instr = reinterpret_cast<const uint8_t*>(
      dlsym(library_handle, "kDartIsolateSnapshotInstructions"));
#elif OS(ANDROID)
  const blink::Settings& settings = blink::Settings::Get();
  const std::string& aot_shared_library_path = settings.aot_shared_library_path;
  const std::string& aot_snapshot_path = settings.aot_snapshot_path;

  if (!aot_shared_library_path.empty()) {
    FXL_CHECK(aot_snapshot_path.empty());
    dlerror();  // clear previous errors on thread
    void* library_handle = dlopen(aot_shared_library_path.c_str(), RTLD_NOW);
    const char* err = dlerror();
    if (err != nullptr) {
      FXL_LOG(FATAL) << "dlopen failed: " << err;
    }
    vm_snapshot_data = reinterpret_cast<const uint8_t*>(
        dlsym(library_handle, "_kDartVmSnapshotData"));
    vm_snapshot_instr = reinterpret_cast<const uint8_t*>(
        dlsym(library_handle, "_kDartVmSnapshotInstructions"));
    default_isolate_snapshot_data = reinterpret_cast<const uint8_t*>(
        dlsym(library_handle, "_kDartIsolateSnapshotData"));
    default_isolate_snapshot_instr = reinterpret_cast<const uint8_t*>(
        dlsym(library_handle, "_kDartIsolateSnapshotInstructions"));
  } else {
    FXL_CHECK(!aot_snapshot_path.empty());
    vm_snapshot_data =
        MemMapSnapshot(aot_snapshot_path, "vm_snapshot_data",
                       settings.aot_vm_snapshot_data_filename, false);
    vm_snapshot_instr =
        MemMapSnapshot(aot_snapshot_path, "vm_snapshot_instr",
                       settings.aot_vm_snapshot_instr_filename, true);
    default_isolate_snapshot_data =
        MemMapSnapshot(aot_snapshot_path, "isolate_snapshot_data",
                       settings.aot_isolate_snapshot_data_filename, false);
    default_isolate_snapshot_instr =
        MemMapSnapshot(aot_snapshot_path, "isolate_snapshot_instr",
                       settings.aot_isolate_snapshot_instr_filename, true);
  }
#else
#error Unknown OS
#endif

  blink::InitRuntime(vm_snapshot_data, vm_snapshot_instr,
                     default_isolate_snapshot_data,
                     default_isolate_snapshot_instr, bundle_path);
}

const std::string Engine::main_entrypoint_ = "main";

void Engine::RunBundle(const std::string& bundle_path,
                       const std::string& entrypoint,
                       bool reuse_runtime_controller) {
  TRACE_EVENT0("flutter", "Engine::RunBundle");
  ConfigureAssetBundle(bundle_path);
  ConfigureRuntime(GetScriptUriFromPath(bundle_path), reuse_runtime_controller);

  if (blink::IsRunningPrecompiledCode()) {
    runtime_->dart_controller()->RunFromPrecompiledSnapshot(entrypoint);
  } else {
    std::vector<uint8_t> kernel;
    if (GetAssetAsBuffer(blink::kKernelAssetKey, &kernel)) {
      runtime_->dart_controller()->RunFromKernel(kernel, entrypoint);
      return;
    }
    std::vector<uint8_t> snapshot;
    if (!GetAssetAsBuffer(blink::kSnapshotAssetKey, &snapshot))
      return;
    runtime_->dart_controller()->RunFromScriptSnapshot(
        snapshot.data(), snapshot.size(), entrypoint);
  }
}

void Engine::RunBundleAndSnapshot(const std::string& bundle_path,
                                  const std::string& snapshot_override,
                                  const std::string& entrypoint,
                                  bool reuse_runtime_controller) {
  TRACE_EVENT0("flutter", "Engine::RunBundleAndSnapshot");
  if (snapshot_override.empty()) {
    RunBundle(bundle_path, entrypoint, reuse_runtime_controller);
    return;
  }
  ConfigureAssetBundle(bundle_path);
  ConfigureRuntime(GetScriptUriFromPath(bundle_path), reuse_runtime_controller);
  if (blink::IsRunningPrecompiledCode()) {
    runtime_->dart_controller()->RunFromPrecompiledSnapshot(entrypoint);
  } else {
    std::vector<uint8_t> snapshot;
    if (!files::ReadFileToVector(snapshot_override, &snapshot))
      return;
    runtime_->dart_controller()->RunFromScriptSnapshot(
        snapshot.data(), snapshot.size(), entrypoint);
  }
}

void Engine::RunBundleAndSource(const std::string& bundle_path,
                                const std::string& main,
                                const std::string& packages,
                                bool reuse_runtime_controller) {
  TRACE_EVENT0("flutter", "Engine::RunBundleAndSource");
  FXL_CHECK(!blink::IsRunningPrecompiledCode())
      << "Cannot run from source in a precompiled build.";
  std::string packages_path = packages;
  if (packages_path.empty())
    packages_path = FindPackagesPath(main);

  if (!bundle_path.empty())
    ConfigureAssetBundle(bundle_path);

  ConfigureRuntime(GetScriptUriFromPath(bundle_path), reuse_runtime_controller);

  if (blink::GetKernelPlatformBinary() != nullptr) {
    std::vector<uint8_t> kernel;
    if (!files::ReadFileToVector(main, &kernel)) {
      load_script_error_ = tonic::kUnknownErrorType;
    }
    load_script_error_ = runtime_->dart_controller()->RunFromKernel(kernel);
  } else {
    load_script_error_ =
        runtime_->dart_controller()->RunFromSource(main, packages_path);
  }
}

void Engine::BeginFrame(fxl::TimePoint frame_time) {
  TRACE_EVENT0("flutter", "Engine::BeginFrame");
  if (runtime_)
    runtime_->BeginFrame(frame_time);
}

void Engine::NotifyIdle(int64_t deadline) {
  TRACE_EVENT0("flutter", "Engine::NotifyIdle");
  if (runtime_)
    runtime_->NotifyIdle(deadline);
}

void Engine::RunFromSource(const std::string& main,
                           const std::string& packages,
                           const std::string& bundle_path) {
  RunBundleAndSource(bundle_path, main, packages);
}

Dart_Port Engine::GetUIIsolateMainPort() {
  if (!runtime_)
    return ILLEGAL_PORT;
  return runtime_->GetMainPort();
}

std::string Engine::GetUIIsolateName() {
  if (!runtime_) {
    return "";
  }
  return runtime_->GetIsolateName();
}

bool Engine::UIIsolateHasLivePorts() {
  if (!runtime_)
    return false;
  return runtime_->HasLivePorts();
}

tonic::DartErrorHandleType Engine::GetUIIsolateLastError() {
  if (!runtime_)
    return tonic::kNoError;
  return runtime_->GetLastError();
}

tonic::DartErrorHandleType Engine::GetLoadScriptError() {
  return load_script_error_;
}

void Engine::OnOutputSurfaceCreated(const fxl::Closure& gpu_continuation) {
  blink::Threads::Gpu()->PostTask(gpu_continuation);
  have_surface_ = true;
  StartAnimatorIfPossible();
  if (runtime_)
    ScheduleFrame();
}

void Engine::OnOutputSurfaceDestroyed(const fxl::Closure& gpu_continuation) {
  have_surface_ = false;
  StopAnimator();
  blink::Threads::Gpu()->PostTask(gpu_continuation);
}

void Engine::SetViewportMetrics(const blink::ViewportMetrics& metrics) {
  viewport_metrics_ = metrics;
  if (runtime_)
    runtime_->SetViewportMetrics(viewport_metrics_);
  if (animator_) {
    animator_->SetDimensionChangePending();
    if (have_surface_)
      ScheduleFrame();
  }
}

void Engine::DispatchPlatformMessage(
    fxl::RefPtr<blink::PlatformMessage> message) {
  if (message->channel() == kLifecycleChannel) {
    if (HandleLifecyclePlatformMessage(message.get()))
      return;
  } else if (message->channel() == kLocalizationChannel) {
    if (HandleLocalizationPlatformMessage(message.get()))
      return;
  } else if (message->channel() == kSettingsChannel) {
    HandleSettingsPlatformMessage(message.get());
    return;
  }

  if (runtime_) {
    runtime_->DispatchPlatformMessage(std::move(message));
    return;
  }

  // If there's no runtime_, we may still need to set the initial route.
  if (message->channel() == kNavigationChannel)
    HandleNavigationPlatformMessage(std::move(message));
}

bool Engine::HandleLifecyclePlatformMessage(blink::PlatformMessage* message) {
  const auto& data = message->data();
  std::string state(reinterpret_cast<const char*>(data.data()), data.size());
  if (state == "AppLifecycleState.paused" ||
      state == "AppLifecycleState.suspending") {
    activity_running_ = false;
    StopAnimator();
  } else if (state == "AppLifecycleState.resumed" ||
             state == "AppLifecycleState.inactive") {
    activity_running_ = true;
    StartAnimatorIfPossible();
  }

  // Always schedule a frame when the app does become active as per API
  // recommendation
  // https://developer.apple.com/documentation/uikit/uiapplicationdelegate/1622956-applicationdidbecomeactive?language=objc
  if (state == "AppLifecycleState.resumed" && have_surface_) {
    ScheduleFrame();
  }
  return false;
}

bool Engine::HandleNavigationPlatformMessage(
    fxl::RefPtr<blink::PlatformMessage> message) {
  FXL_DCHECK(!runtime_);
  const auto& data = message->data();

  rapidjson::Document document;
  document.Parse(reinterpret_cast<const char*>(data.data()), data.size());
  if (document.HasParseError() || !document.IsObject())
    return false;
  auto root = document.GetObject();
  auto method = root.FindMember("method");
  if (method->value != "setInitialRoute")
    return false;
  auto route = root.FindMember("args");
  initial_route_ = std::move(route->value.GetString());
  return true;
}

bool Engine::HandleLocalizationPlatformMessage(
    blink::PlatformMessage* message) {
  const auto& data = message->data();

  rapidjson::Document document;
  document.Parse(reinterpret_cast<const char*>(data.data()), data.size());
  if (document.HasParseError() || !document.IsObject())
    return false;
  auto root = document.GetObject();
  auto method = root.FindMember("method");
  if (method == root.MemberEnd() || method->value != "setLocale")
    return false;

  auto args = root.FindMember("args");
  if (args == root.MemberEnd() || !args->value.IsArray())
    return false;

  const auto& language = args->value[0];
  const auto& country = args->value[1];

  if (!language.IsString() || !country.IsString())
    return false;

  language_code_ = language.GetString();
  country_code_ = country.GetString();
  if (runtime_)
    runtime_->SetLocale(language_code_, country_code_);
  return true;
}

void Engine::HandleSettingsPlatformMessage(blink::PlatformMessage* message) {
  const auto& data = message->data();
  std::string jsonData(reinterpret_cast<const char*>(data.data()), data.size());
  user_settings_data_ = jsonData;
  if (runtime_) {
    runtime_->SetUserSettingsData(user_settings_data_);
    if (have_surface_)
      ScheduleFrame();
  }
}

void Engine::DispatchPointerDataPacket(const PointerDataPacket& packet) {
  if (runtime_)
    runtime_->DispatchPointerDataPacket(packet);
}

void Engine::DispatchSemanticsAction(int id, blink::SemanticsAction action) {
  if (runtime_)
    runtime_->DispatchSemanticsAction(id, action);
}

void Engine::SetSemanticsEnabled(bool enabled) {
  semantics_enabled_ = enabled;
  if (runtime_)
    runtime_->SetSemanticsEnabled(semantics_enabled_);
}

void Engine::ConfigureAssetBundle(const std::string& path) {
  struct stat stat_result = {};

  directory_asset_bundle_.reset();
  // TODO(abarth): We should reset asset_store_ as well, but that might break
  // custom font loading in hot reload.

  if (::stat(path.c_str(), &stat_result) != 0) {
    FXL_LOG(INFO) << "Could not configure asset bundle at path: " << path;
    return;
  }

  if (S_ISDIR(stat_result.st_mode)) {
    directory_asset_bundle_ =
        std::make_unique<blink::DirectoryAssetBundle>(path);
    return;
  }

  if (S_ISREG(stat_result.st_mode)) {
    asset_store_ = fxl::MakeRefCounted<blink::ZipAssetStore>(
        blink::GetUnzipperProviderForPath(path));
    directory_asset_bundle_ = std::make_unique<blink::DirectoryAssetBundle>(
        files::GetDirectoryName(path));
    return;
  }
}

void Engine::ConfigureRuntime(const std::string& script_uri,
                              bool reuse_runtime_controller) {
  if (runtime_ && reuse_runtime_controller) {
    return;
  }
  runtime_ = blink::RuntimeController::Create(this);
  runtime_->CreateDartController(std::move(script_uri),
                                 default_isolate_snapshot_data,
                                 default_isolate_snapshot_instr);
  runtime_->SetViewportMetrics(viewport_metrics_);
  runtime_->SetLocale(language_code_, country_code_);
  runtime_->SetUserSettingsData(user_settings_data_);
  runtime_->SetSemanticsEnabled(semantics_enabled_);
}

void Engine::DidCreateMainIsolate(Dart_Isolate isolate) {
  if (blink::Settings::Get().use_test_fonts) {
    blink::TestFontSelector::Install();
    if (!blink::Settings::Get().using_blink)
      blink::FontCollection::ForProcess().RegisterTestFonts();
  } else if (asset_store_) {
    blink::AssetFontSelector::Install(asset_store_);
    if (!blink::Settings::Get().using_blink) {
      blink::FontCollection::ForProcess().RegisterFontsFromAssetStore(
          asset_store_);
    }
  }
}

void Engine::DidCreateSecondaryIsolate(Dart_Isolate isolate) {}

void Engine::StopAnimator() {
  animator_->Stop();
}

void Engine::StartAnimatorIfPossible() {
  if (activity_running_ && have_surface_)
    animator_->Start();
}

std::string Engine::DefaultRouteName() {
  if (!initial_route_.empty()) {
    return initial_route_;
  }
  return "/";
}

void Engine::ScheduleFrame(bool regenerate_layer_tree) {
  animator_->RequestFrame(regenerate_layer_tree);
}

void Engine::Render(std::unique_ptr<flow::LayerTree> layer_tree) {
  if (!layer_tree)
    return;

  SkISize frame_size = SkISize::Make(viewport_metrics_.physical_width,
                                     viewport_metrics_.physical_height);
  if (frame_size.isEmpty())
    return;

  layer_tree->set_frame_size(frame_size);
  animator_->Render(std::move(layer_tree));
}

void Engine::UpdateSemantics(std::vector<blink::SemanticsNode> update) {
  blink::Threads::Platform()->PostTask(fxl::MakeCopyable([
    platform_view = platform_view_.lock(), update = std::move(update)
  ]() mutable {
    if (platform_view)
      platform_view->UpdateSemantics(std::move(update));
  }));
}

void Engine::HandlePlatformMessage(
    fxl::RefPtr<blink::PlatformMessage> message) {
  if (message->channel() == kAssetChannel) {
    HandleAssetPlatformMessage(std::move(message));
    return;
  }
  blink::Threads::Platform()->PostTask([
    platform_view = platform_view_.lock(), message = std::move(message)
  ]() mutable {
    if (platform_view)
      platform_view->HandlePlatformMessage(std::move(message));
  });
}

void Engine::HandleAssetPlatformMessage(
    fxl::RefPtr<blink::PlatformMessage> message) {
  fxl::RefPtr<blink::PlatformMessageResponse> response = message->response();
  if (!response)
    return;
  const auto& data = message->data();
  std::string asset_name(reinterpret_cast<const char*>(data.data()),
                         data.size());
  std::vector<uint8_t> asset_data;
  if (GetAssetAsBuffer(asset_name, &asset_data)) {
    response->Complete(std::move(asset_data));
  } else {
    response->CompleteEmpty();
  }
}

bool Engine::GetAssetAsBuffer(const std::string& name,
                              std::vector<uint8_t>* data) {
  return (directory_asset_bundle_ &&
          directory_asset_bundle_->GetAsBuffer(name, data)) ||
         (asset_store_ && asset_store_->GetAsBuffer(name, data));
}

}  // namespace shell
