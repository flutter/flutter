// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/embedder/flutter_embedder_native.h"

#if !defined(_WIN32)
#include <dlfcn.h>
#endif
#include <cstring>
#include <unordered_set>
#include <utility>

#include "flutter/fml/logging.h"
#include "flutter/fml/trace_event.h"

#if defined(__ANDROID__)
#include <EGL/egl.h>
#include <GLES2/gl2.h>
#include "flutter/fml/platform/android/jni_util.h"
#endif

namespace flutter {

namespace {

std::mutex& GetHandleRegistryMutex() {
  static std::mutex* mutex = new std::mutex();
  return *mutex;
}

std::unordered_set<FlutterEmbedderNative*>& GetActiveEmbedderHandles() {
  static auto* handles = new std::unordered_set<FlutterEmbedderNative*>();
  return *handles;
}

void RegisterEmbedderHandle(FlutterEmbedderNative* instance) {
  std::lock_guard<std::mutex> lock(GetHandleRegistryMutex());
  GetActiveEmbedderHandles().insert(instance);
}

void UnregisterEmbedderHandle(FlutterEmbedderNative* instance) {
  std::lock_guard<std::mutex> lock(GetHandleRegistryMutex());
  GetActiveEmbedderHandles().erase(instance);
}

struct OutboundResponseContext {
  std::weak_ptr<JniDelegate> jni_delegate;
  int32_t response_id;
};

#if defined(__ANDROID__)
void EnsureThreadLocalEglContext() {
  if (eglGetCurrentContext() != EGL_NO_CONTEXT) {
    return;
  }
  EGLDisplay display = eglGetDisplay(EGL_DEFAULT_DISPLAY);
  if (display == EGL_NO_DISPLAY) {
    return;
  }
  EGLint major = 0;
  EGLint minor = 0;
  if (!eglInitialize(display, &major, &minor)) {
    return;
  }
  const EGLint config_attribs[] = {
      EGL_SURFACE_TYPE,
      EGL_PBUFFER_BIT,
      EGL_RENDERABLE_TYPE,
      EGL_OPENGL_ES2_BIT,
      EGL_RED_SIZE,
      8,
      EGL_GREEN_SIZE,
      8,
      EGL_BLUE_SIZE,
      8,
      EGL_ALPHA_SIZE,
      8,
      EGL_NONE,
  };
  EGLConfig config = nullptr;
  EGLint num_configs = 0;
  if (!eglChooseConfig(display, config_attribs, &config, 1, &num_configs) ||
      num_configs < 1) {
    return;
  }
  const EGLint pbuffer_attribs[] = {
      EGL_WIDTH, 1, EGL_HEIGHT, 1, EGL_NONE,
  };
  EGLSurface surface =
      eglCreatePbufferSurface(display, config, pbuffer_attribs);
  if (surface == EGL_NO_SURFACE) {
    return;
  }
  const EGLint context_attribs[] = {
      EGL_CONTEXT_CLIENT_VERSION,
      2,
      EGL_NONE,
  };
  EGLContext context =
      eglCreateContext(display, config, EGL_NO_CONTEXT, context_attribs);
  if (context == EGL_NO_CONTEXT) {
    eglDestroySurface(display, surface);
    return;
  }
  eglMakeCurrent(display, surface, surface, context);
}
#endif

}  // namespace

bool FlutterEmbedderNative::ResolveDefaultProcTable(
    FlutterEngineProcTable* out_table) {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::ResolveDefaultProcTable");
  if (out_table == nullptr) {
    return false;
  }
  std::memset(out_table, 0, sizeof(FlutterEngineProcTable));
  out_table->struct_size = sizeof(FlutterEngineProcTable);
  return FlutterEngineGetProcAddresses(out_table) == kSuccess;
}

FlutterEmbedderNative* FlutterEmbedderNative::FromHandle(int64_t handle) {
  if (handle == 0) {
    return nullptr;
  }
  auto* candidate = reinterpret_cast<FlutterEmbedderNative*>(handle);
  std::lock_guard<std::mutex> lock(GetHandleRegistryMutex());
  auto& active = GetActiveEmbedderHandles();
  return active.find(candidate) != active.end() ? candidate : nullptr;
}

FlutterEmbedderNative::FlutterEmbedderNative(
    const Settings& settings,
    std::shared_ptr<JniDelegate> jni_delegate)
    : settings_(settings), jni_delegate_(std::move(jni_delegate)) {
  RegisterEmbedderHandle(this);
  is_valid_ = ResolveDefaultProcTable(&embedder_api_);
  surface_control_ =
      std::make_unique<AndroidSurfaceControl>(jni_delegate_, embedder_api_);
  vsync_waiter_ =
      std::make_unique<AndroidChoreographerVsync>(jni_delegate_, embedder_api_);
  external_texture_manager_ =
      std::make_unique<AndroidHardwareBufferExternalTexture>(jni_delegate_,
                                                             embedder_api_);
}

FlutterEmbedderNative::FlutterEmbedderNative(
    const Settings& settings,
    std::shared_ptr<JniDelegate> jni_delegate,
    const FlutterEngineProcTable& proc_table)
    : settings_(settings),
      jni_delegate_(std::move(jni_delegate)),
      embedder_api_(proc_table),
      surface_control_(std::make_unique<AndroidSurfaceControl>(jni_delegate_,
                                                               embedder_api_)),
      vsync_waiter_(std::make_unique<AndroidChoreographerVsync>(jni_delegate_,
                                                                embedder_api_)),
      external_texture_manager_(
          std::make_unique<AndroidHardwareBufferExternalTexture>(
              jni_delegate_,
              embedder_api_)),
      is_valid_(proc_table.Initialize != nullptr &&
                proc_table.RunInitialized != nullptr &&
                proc_table.Shutdown != nullptr) {
  RegisterEmbedderHandle(this);
}

FlutterEmbedderNative::FlutterEmbedderNative(
    const Settings& settings,
    std::shared_ptr<JniDelegate> jni_delegate,
    const FlutterEngineProcTable& proc_table,
    FLUTTER_API_SYMBOL(FlutterEngine) spawned_engine)
    : settings_(settings),
      jni_delegate_(std::move(jni_delegate)),
      embedder_api_(proc_table),
      engine_(spawned_engine),
      surface_control_(std::make_unique<AndroidSurfaceControl>(jni_delegate_,
                                                               embedder_api_)),
      vsync_waiter_(std::make_unique<AndroidChoreographerVsync>(jni_delegate_,
                                                                embedder_api_)),
      external_texture_manager_(
          std::make_unique<AndroidHardwareBufferExternalTexture>(
              jni_delegate_,
              embedder_api_)),
      is_valid_(spawned_engine != nullptr) {
  RegisterEmbedderHandle(this);
}

FlutterEmbedderNative::~FlutterEmbedderNative() {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::~FlutterEmbedderNative");
  UnregisterEmbedderHandle(this);
  if (vsync_waiter_ != nullptr) {
    vsync_waiter_->CancelPendingBatons();
  }
  if (engine_ != nullptr) {
    if (embedder_api_.Deinitialize != nullptr) {
      embedder_api_.Deinitialize(engine_);
    }
    if (embedder_api_.Shutdown != nullptr) {
      embedder_api_.Shutdown(engine_);
    }
    engine_ = nullptr;
  }
  if (aot_data_ != nullptr && embedder_api_.CollectAOTData != nullptr) {
    embedder_api_.CollectAOTData(aot_data_);
    aot_data_ = nullptr;
  }
#if defined(__ANDROID__)
  {
    std::lock_guard<std::mutex> lock(java_textures_mutex_);
    java_textures_.clear();
    attached_java_textures_.clear();
  }
#endif
}

bool FlutterEmbedderNative::Launch(
    const std::string& assets_path,
    const std::string& icu_data_path,
    const std::string& entrypoint,
    const std::string& library_url,
    const std::vector<std::string>& entrypoint_args,
    int64_t engine_id) {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::Initialize[C-API]");
  FML_LOG(IMPORTANT) << "[EMBEDDER_API_PROOF] path=C_EMBEDDER_API "
                        "proc_table=FlutterEngineInitialize shell_holder=NONE";

  if (!is_valid_ || embedder_api_.Initialize == nullptr ||
      embedder_api_.RunInitialized == nullptr) {
    FML_LOG(ERROR) << "FlutterEmbedderNative proc table is not initialized.";
    return false;
  }

  if (engine_ != nullptr) {
    FML_LOG(ERROR) << "FlutterEmbedderNative engine is already launched.";
    return false;
  }

  FlutterRendererConfig renderer_config = {};
  renderer_config.type = kSoftware;
  renderer_config.software.struct_size = sizeof(FlutterSoftwareRendererConfig);
  renderer_config.software.surface_present_callback =
      [](void* /*user_data*/, const void* /*allocation*/, size_t /*row_bytes*/,
         size_t /*height*/) -> bool { return true; };

  std::vector<const char*> dart_args_ptrs;
  dart_args_ptrs.reserve(entrypoint_args.size());
  for (const auto& arg : entrypoint_args) {
    dart_args_ptrs.push_back(arg.c_str());
  }

  FlutterProjectArgs project_args = {};
  project_args.struct_size = sizeof(FlutterProjectArgs);
  project_args.assets_path = assets_path.c_str();
  project_args.icu_data_path = icu_data_path.c_str();
  if (!entrypoint.empty()) {
    project_args.custom_dart_entrypoint = entrypoint.c_str();
  }
  project_args.dart_entrypoint_argc = static_cast<int>(dart_args_ptrs.size());
  project_args.dart_entrypoint_argv =
      dart_args_ptrs.empty() ? nullptr : dart_args_ptrs.data();
  project_args.engine_id = engine_id;
  project_args.does_handle_platform_messages_on_platform_thread = false;
  project_args.platform_message_callback2 =
      &FlutterEmbedderNative::OnPlatformMessageCallback;
  project_args.request_dart_deferred_library_callback =
      &FlutterEmbedderNative::OnRequestDartDeferredLibraryCallback;
  project_args.vsync_callback = &FlutterEmbedderNative::OnVsyncRequestCallback;

  if (embedder_api_.RunsAOTCompiledDartCode != nullptr &&
      embedder_api_.RunsAOTCompiledDartCode()) {
    for (const auto& lib_path : settings_.application_library_paths) {
      FlutterEngineAOTDataSource source = {};
      source.type = kFlutterEngineAOTDataSourceTypeElfPath;
      source.elf_path = lib_path.c_str();
      if (embedder_api_.CreateAOTData != nullptr &&
          embedder_api_.CreateAOTData(&source, &aot_data_) == kSuccess &&
          aot_data_ != nullptr) {
        break;
      }
    }
    project_args.aot_data = aot_data_;

    if (project_args.aot_data == nullptr) {
#if !defined(_WIN32)
      void* lib = ::dlopen("libapp.so", RTLD_NOW);
      if (lib == nullptr) {
        lib = ::dlopen(nullptr, RTLD_NOW);
      }
      if (lib != nullptr) {
        auto resolve_symbol = [](void* handle,
                                 const char* name) -> const uint8_t* {
          void* sym = ::dlsym(handle, name);
          if (sym == nullptr) {
            std::string underscored = std::string("_") + name;
            sym = ::dlsym(handle, underscored.c_str());
          }
          return reinterpret_cast<const uint8_t*>(sym);
        };

        const uint8_t* vm_data = resolve_symbol(lib, "kDartSnapshotData");
        if (vm_data == nullptr) {
          vm_data = resolve_symbol(lib, "kDartVmSnapshotData");
        }
        const uint8_t* vm_instrs = resolve_symbol(lib, "kDartSnapshotText");
        if (vm_instrs == nullptr) {
          vm_instrs = resolve_symbol(lib, "kDartVmSnapshotInstructions");
        }

        if (vm_data != nullptr && vm_instrs != nullptr) {
          project_args.vm_snapshot_data = vm_data;
          project_args.vm_snapshot_data_size = 0;
          project_args.vm_snapshot_instructions = vm_instrs;
          project_args.vm_snapshot_instructions_size = 0;
          project_args.isolate_snapshot_data = vm_data;
          project_args.isolate_snapshot_data_size = 0;
          project_args.isolate_snapshot_instructions = vm_instrs;
          project_args.isolate_snapshot_instructions_size = 0;
        }
      }
#endif
    }
  }

  FlutterEngineResult init_result = embedder_api_.Initialize(
      FLUTTER_ENGINE_VERSION, &renderer_config, &project_args, this, &engine_);
  if (init_result != kSuccess || engine_ == nullptr) {
    FML_LOG(ERROR) << "embedder_api_.Initialize failed with result: "
                   << init_result;
    return false;
  }

  FlutterEngineResult run_result = embedder_api_.RunInitialized(engine_);
  if (run_result != kSuccess) {
    FML_LOG(ERROR) << "embedder_api_.RunInitialized failed with result: "
                   << run_result;
    if (embedder_api_.Shutdown != nullptr) {
      embedder_api_.Shutdown(engine_);
    }
    engine_ = nullptr;
    return false;
  }

  return true;
}

std::unique_ptr<FlutterEmbedderNative> FlutterEmbedderNative::Spawn(
    std::shared_ptr<JniDelegate> child_jni_delegate,
    const std::string& entrypoint,
    const std::string& library_url,
    const std::string& initial_route,
    const std::vector<std::string>& entrypoint_args,
    int64_t engine_id) const {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::Spawn[C-API]");
  FML_LOG(IMPORTANT) << "[EMBEDDER_API_PROOF] path=C_EMBEDDER_API "
                        "proc_table=FlutterEngineSpawn shell_holder=NONE";

  if (!is_valid_ || engine_ == nullptr || embedder_api_.Spawn == nullptr) {
    return nullptr;
  }

  FlutterRendererConfig renderer_config = {};
  renderer_config.type = kSoftware;
  renderer_config.software.struct_size = sizeof(FlutterSoftwareRendererConfig);
  renderer_config.software.surface_present_callback =
      [](void* /*user_data*/, const void* /*allocation*/, size_t /*row_bytes*/,
         size_t /*height*/) -> bool { return true; };

  std::vector<const char*> dart_args_ptrs;
  dart_args_ptrs.reserve(entrypoint_args.size());
  for (const auto& arg : entrypoint_args) {
    dart_args_ptrs.push_back(arg.c_str());
  }

  FlutterProjectArgs project_args = {};
  project_args.struct_size = sizeof(FlutterProjectArgs);
  if (!entrypoint.empty()) {
    project_args.custom_dart_entrypoint = entrypoint.c_str();
  }
  project_args.dart_entrypoint_argc = static_cast<int>(dart_args_ptrs.size());
  project_args.dart_entrypoint_argv =
      dart_args_ptrs.empty() ? nullptr : dart_args_ptrs.data();
  project_args.engine_id = engine_id;
  project_args.does_handle_platform_messages_on_platform_thread = false;
  project_args.platform_message_callback2 =
      &FlutterEmbedderNative::OnPlatformMessageCallback;
  project_args.request_dart_deferred_library_callback =
      &FlutterEmbedderNative::OnRequestDartDeferredLibraryCallback;

  auto child = std::unique_ptr<FlutterEmbedderNative>(new FlutterEmbedderNative(
      settings_, std::move(child_jni_delegate), embedder_api_, nullptr));

  FlutterEngineSpawnConfig spawn_config = {};
  spawn_config.struct_size = sizeof(FlutterEngineSpawnConfig);
  spawn_config.renderer_config = &renderer_config;
  spawn_config.project_args = &project_args;
  spawn_config.entrypoint = entrypoint.empty() ? nullptr : entrypoint.c_str();
  spawn_config.library_uri =
      library_url.empty() ? nullptr : library_url.c_str();
  spawn_config.initial_route =
      initial_route.empty() ? nullptr : initial_route.c_str();
  spawn_config.entrypoint_argc = static_cast<int>(dart_args_ptrs.size());
  spawn_config.entrypoint_argv =
      dart_args_ptrs.empty() ? nullptr : dart_args_ptrs.data();
  spawn_config.user_data = child.get();

  FLUTTER_API_SYMBOL(FlutterEngine) spawned_engine = nullptr;
  FlutterEngineResult result =
      embedder_api_.Spawn(engine_, &spawn_config, &spawned_engine);
  if (result != kSuccess || spawned_engine == nullptr) {
    return nullptr;
  }

  child->engine_ = spawned_engine;
  child->is_valid_ = true;
  return child;
}

bool FlutterEmbedderNative::NotifySurfaceCreated(
    uintptr_t native_window_handle) {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::NotifySurfaceCreated");
  if (engine_ == nullptr || surface_control_ == nullptr) {
    return false;
  }
  return surface_control_->NotifySurfaceCreated(
      engine_, /*view_id=*/0, native_window_handle, /*width=*/0,
      /*height=*/0, /*pixel_ratio=*/1.0);
}

bool FlutterEmbedderNative::NotifySurfaceDestroyed() {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::NotifySurfaceDestroyed");
  if (engine_ == nullptr || surface_control_ == nullptr) {
    return false;
  }
  return surface_control_->NotifySurfaceDestroyed(engine_, /*view_id=*/0);
}

bool FlutterEmbedderNative::SetGpuAvailability(
    FlutterGpuAvailability availability) {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::SetGpuAvailability");
  if (engine_ == nullptr || embedder_api_.SetGpuAvailability == nullptr) {
    return false;
  }
  return embedder_api_.SetGpuAvailability(engine_, availability) == kSuccess;
}

bool FlutterEmbedderNative::SendWindowMetrics(size_t width,
                                              size_t height,
                                              double pixel_ratio,
                                              int64_t view_id) {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::SendWindowMetrics");
  if (engine_ == nullptr || embedder_api_.SendWindowMetricsEvent == nullptr) {
    return false;
  }
  FlutterWindowMetricsEvent event = {};
  event.struct_size = sizeof(FlutterWindowMetricsEvent);
  event.width = width;
  event.height = height;
  event.pixel_ratio = pixel_ratio;
  event.view_id = view_id;
  return embedder_api_.SendWindowMetricsEvent(engine_, &event) == kSuccess;
}

bool FlutterEmbedderNative::SendPlatformMessage(const std::string& channel,
                                                const uint8_t* bytes,
                                                size_t length,
                                                int32_t response_id) {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::SendPlatformMessage");
  if (engine_ == nullptr || embedder_api_.SendPlatformMessage == nullptr) {
    return false;
  }

  FlutterPlatformMessageResponseHandle* response_handle = nullptr;
  if (response_id != 0 &&
      embedder_api_.PlatformMessageCreateResponseHandle != nullptr &&
      jni_delegate_ != nullptr) {
    auto* context = new OutboundResponseContext{jni_delegate_, response_id};
    if (embedder_api_.PlatformMessageCreateResponseHandle(
            engine_, &FlutterEmbedderNative::OnPlatformMessageResponseCallback,
            context, &response_handle) != kSuccess) {
      delete context;
      response_handle = nullptr;
    }
  }

  FlutterPlatformMessage message = {};
  message.struct_size = sizeof(FlutterPlatformMessage);
  message.channel = channel.c_str();
  message.message = bytes;
  message.message_size = length;
  message.response_handle = response_handle;

  FlutterEngineResult result =
      embedder_api_.SendPlatformMessage(engine_, &message);

  if (response_handle != nullptr &&
      embedder_api_.PlatformMessageReleaseResponseHandle != nullptr) {
    embedder_api_.PlatformMessageReleaseResponseHandle(engine_,
                                                       response_handle);
  }
  return result == kSuccess;
}

bool FlutterEmbedderNative::RespondToPlatformMessage(int32_t response_id,
                                                     const uint8_t* bytes,
                                                     size_t length) {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::RespondToPlatformMessage");
  if (engine_ == nullptr ||
      embedder_api_.SendPlatformMessageResponse == nullptr) {
    return false;
  }

  const FlutterPlatformMessageResponseHandle* handle = nullptr;
  {
    std::lock_guard<std::mutex> lock(response_mutex_);
    auto it = pending_responses_.find(response_id);
    if (it == pending_responses_.end()) {
      return false;
    }
    handle = it->second;
    pending_responses_.erase(it);
  }

  return embedder_api_.SendPlatformMessageResponse(engine_, handle, bytes,
                                                   length) == kSuccess;
}

bool FlutterEmbedderNative::LoadDartDeferredLibrary(
    const FlutterDartDeferredLibrary* library) {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::LoadDartDeferredLibrary");
  if (engine_ == nullptr || embedder_api_.LoadDartDeferredLibrary == nullptr) {
    return false;
  }
  return embedder_api_.LoadDartDeferredLibrary(engine_, library) == kSuccess;
}

bool FlutterEmbedderNative::NotifyLowMemoryWarning() {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::NotifyLowMemoryWarning");
  if (engine_ == nullptr || embedder_api_.NotifyLowMemoryWarning == nullptr) {
    return false;
  }
  return embedder_api_.NotifyLowMemoryWarning(engine_) == kSuccess;
}

bool FlutterEmbedderNative::OnVsync(intptr_t baton,
                                    uint64_t frame_start_time_nanos,
                                    uint64_t frame_target_time_nanos) {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::OnVsync");
  if (engine_ == nullptr || vsync_waiter_ == nullptr) {
    return false;
  }
  return vsync_waiter_->OnChoreographerFrame(
      engine_, baton, frame_start_time_nanos, frame_target_time_nanos);
}

bool FlutterEmbedderNative::RegisterExternalTexture(int64_t texture_id) {
  if (engine_ == nullptr || external_texture_manager_ == nullptr) {
    return false;
  }
  return external_texture_manager_->RegisterTexture(engine_, texture_id);
}

bool FlutterEmbedderNative::UnregisterExternalTexture(int64_t texture_id) {
  if (engine_ == nullptr || external_texture_manager_ == nullptr) {
    return false;
  }
  return external_texture_manager_->UnregisterTexture(engine_, texture_id);
}

bool FlutterEmbedderNative::MarkExternalTextureFrameAvailable(
    int64_t texture_id) {
  if (engine_ == nullptr || external_texture_manager_ == nullptr) {
    return false;
  }
  return external_texture_manager_->MarkFrameAvailable(engine_, texture_id);
}

void FlutterEmbedderNative::OnVsyncRequestCallback(void* user_data,
                                                   intptr_t baton) {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::OnVsyncRequestCallback");
  if (user_data == nullptr) {
    return;
  }
  auto* embedder = static_cast<FlutterEmbedderNative*>(user_data);
  if (embedder->vsync_waiter_ != nullptr) {
    embedder->vsync_waiter_->RequestVsync(baton);
  }
}

void FlutterEmbedderNative::OnPlatformMessageCallback(
    const FlutterPlatformMessage* message,
    void* user_data) {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::OnPlatformMessageCallback");
  if (message == nullptr || user_data == nullptr) {
    return;
  }
  static_cast<FlutterEmbedderNative*>(user_data)->HandleEnginePlatformMessage(
      message);
}

void FlutterEmbedderNative::OnPlatformMessageResponseCallback(
    const uint8_t* data,
    size_t size,
    void* user_data) {
  TRACE_EVENT0("flutter",
               "FlutterEmbedderNative::OnPlatformMessageResponseCallback");
  std::unique_ptr<OutboundResponseContext> context(
      static_cast<OutboundResponseContext*>(user_data));
  if (!context) {
    return;
  }
  if (auto delegate = context->jni_delegate.lock()) {
    delegate->HandlePlatformMessageResponse(context->response_id, data, size);
  }
}

void FlutterEmbedderNative::OnRequestDartDeferredLibraryCallback(
    intptr_t loading_unit_id,
    void* user_data) {
  TRACE_EVENT0("flutter",
               "FlutterEmbedderNative::OnRequestDartDeferredLibraryCallback");
  if (user_data == nullptr) {
    return;
  }
  auto* self = static_cast<FlutterEmbedderNative*>(user_data);
  if (self->jni_delegate_ != nullptr) {
    self->jni_delegate_->RequestDartDeferredLibrary(loading_unit_id);
  }
}

void FlutterEmbedderNative::HandleEnginePlatformMessage(
    const FlutterPlatformMessage* message) {
  int32_t response_id = 0;
  if (message->response_handle != nullptr) {
    std::lock_guard<std::mutex> lock(response_mutex_);
    response_id = next_response_id_++;
    pending_responses_[response_id] = message->response_handle;
  }

  if (jni_delegate_ != nullptr) {
    jni_delegate_->HandlePlatformMessage(
        message->channel != nullptr ? message->channel : "", message->message,
        message->message_size, response_id, 0);
  } else if (message->response_handle != nullptr &&
             embedder_api_.SendPlatformMessageResponse != nullptr) {
    RespondToPlatformMessage(response_id, nullptr, 0);
  }
}

#if defined(__ANDROID__)
void FlutterEmbedderNative::RegisterJavaTexture(JNIEnv* env,
                                                int64_t texture_id,
                                                jobject texture_obj) {
  if (texture_obj == nullptr) {
    return;
  }
  std::lock_guard<std::mutex> lock(java_textures_mutex_);
  attached_java_textures_.erase(texture_id);
  java_textures_[texture_id].Reset(env, texture_obj);
}

void FlutterEmbedderNative::UnregisterJavaTexture(int64_t texture_id) {
  std::lock_guard<std::mutex> lock(java_textures_mutex_);
  java_textures_.erase(texture_id);
  attached_java_textures_.erase(texture_id);
}

void FlutterEmbedderNative::UpdateJavaTexture(JNIEnv* env, int64_t texture_id) {
  if (env == nullptr) {
    return;
  }
  fml::jni::ScopedJavaLocalFrame scoped_local_frame(env);
  fml::jni::ScopedJavaLocalRef<jobject> target_ref;
  bool is_attached = false;
  {
    std::lock_guard<std::mutex> lock(java_textures_mutex_);
    auto it = java_textures_.find(texture_id);
    if (it == java_textures_.end() || it->second.is_null()) {
      return;
    }
    target_ref.Reset(env, env->NewLocalRef(it->second.obj()));
    is_attached = attached_java_textures_.find(texture_id) !=
                  attached_java_textures_.end();
  }
  jobject target_obj = target_ref.obj();
  if (target_obj == nullptr) {
    return;
  }

  static jclass weak_ref_class = nullptr;
  static jmethodID weak_get_method = nullptr;
  if (weak_ref_class == nullptr) {
    jclass local_weak_cls = env->FindClass("java/lang/ref/WeakReference");
    if (env->ExceptionCheck()) {
      env->ExceptionClear();
      local_weak_cls = nullptr;
    }
    if (local_weak_cls != nullptr) {
      weak_ref_class =
          reinterpret_cast<jclass>(env->NewGlobalRef(local_weak_cls));
      weak_get_method =
          env->GetMethodID(weak_ref_class, "get", "()Ljava/lang/Object;");
      if (env->ExceptionCheck()) {
        env->ExceptionClear();
        weak_get_method = nullptr;
      }
      env->DeleteLocalRef(local_weak_cls);
    }
  }

  bool was_weak_ref = false;
  fml::jni::ScopedJavaLocalRef<jobject> strong_ref;
  if (weak_ref_class != nullptr && weak_get_method != nullptr &&
      env->IsInstanceOf(target_obj, weak_ref_class)) {
    was_weak_ref = true;
    jobject referent = env->CallObjectMethod(target_obj, weak_get_method);
    if (env->ExceptionCheck()) {
      env->ExceptionClear();
      return;
    }
    if (referent == nullptr) {
      return;
    }
    strong_ref.Reset(env, referent);
    target_obj = strong_ref.obj();
  }

  jclass target_cls = env->GetObjectClass(target_obj);
  if (target_cls == nullptr) {
    return;
  }

  if (!was_weak_ref) {
    jmethodID acquire_id = env->GetMethodID(target_cls, "acquireLatestImage",
                                            "()Landroid/media/Image;");
    if (env->ExceptionCheck()) {
      env->ExceptionClear();
      acquire_id = nullptr;
    }
    if (acquire_id != nullptr) {
      jobject image = env->CallObjectMethod(target_obj, acquire_id);
      if (env->ExceptionCheck()) {
        env->ExceptionClear();
        image = nullptr;
      }
      if (image != nullptr) {
        jclass image_cls = env->GetObjectClass(image);
        if (image_cls != nullptr) {
          jmethodID close_id = env->GetMethodID(image_cls, "close", "()V");
          if (env->ExceptionCheck()) {
            env->ExceptionClear();
            close_id = nullptr;
          }
          if (close_id != nullptr) {
            env->CallVoidMethod(image, close_id);
            if (env->ExceptionCheck()) {
              env->ExceptionClear();
            }
          }
        }
      }
      return;
    }
  }

  jmethodID should_update_id =
      env->GetMethodID(target_cls, "shouldUpdate", "()Z");
  if (env->ExceptionCheck()) {
    env->ExceptionClear();
    should_update_id = nullptr;
  }
  jmethodID attach_id =
      env->GetMethodID(target_cls, "attachToGLContext", "(I)V");
  if (env->ExceptionCheck()) {
    env->ExceptionClear();
    attach_id = nullptr;
  }
  jmethodID update_id = env->GetMethodID(target_cls, "updateTexImage", "()V");
  if (env->ExceptionCheck()) {
    env->ExceptionClear();
    update_id = nullptr;
  }

  if (update_id == nullptr) {
    return;
  }

  jboolean should_update = JNI_TRUE;
  if (should_update_id != nullptr) {
    should_update = env->CallBooleanMethod(target_obj, should_update_id);
    if (env->ExceptionCheck()) {
      env->ExceptionClear();
      return;
    }
  }

  if (should_update == JNI_TRUE) {
    EnsureThreadLocalEglContext();
    const jint gl_tex_id = static_cast<jint>(texture_id + 1);
    if (!is_attached && attach_id != nullptr) {
      env->CallVoidMethod(target_obj, attach_id, gl_tex_id);
      if (env->ExceptionCheck()) {
        env->ExceptionClear();
      } else {
        std::lock_guard<std::mutex> lock(java_textures_mutex_);
        attached_java_textures_.insert(texture_id);
      }
    }
    env->CallVoidMethod(target_obj, update_id);
    if (env->ExceptionCheck()) {
      env->ExceptionClear();
    }
  }
}

void FlutterEmbedderNative::UpdateAllJavaTextures() {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::UpdateAllJavaTextures");
  std::vector<int64_t> texture_ids;
  {
    std::lock_guard<std::mutex> lock(java_textures_mutex_);
    if (java_textures_.empty()) {
      return;
    }
    texture_ids.reserve(java_textures_.size());
    for (const auto& entry : java_textures_) {
      texture_ids.push_back(entry.first);
    }
  }
  JNIEnv* env = fml::jni::AttachCurrentThread();
  if (env == nullptr) {
    return;
  }
  for (int64_t texture_id : texture_ids) {
    UpdateJavaTexture(env, texture_id);
  }
}
#endif

}  // namespace flutter
