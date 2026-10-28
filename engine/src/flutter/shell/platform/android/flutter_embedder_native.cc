// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#define FML_USED_ON_EMBEDDER

#include "flutter/shell/platform/android/flutter_embedder_native.h"

#include <algorithm>
#include <cstring>
#include <utility>

#include "flutter/fml/logging.h"
#include "flutter/fml/mapping.h"
#include "flutter/fml/message_loop.h"
#include "flutter/fml/native_library.h"
#include "flutter/fml/time/time_delta.h"
#include "flutter/fml/time/time_point.h"
#include "flutter/fml/trace_event.h"
#include "flutter/shell/platform/android/android_engine_group.h"
#include "flutter/shell/platform/android/android_hardware_buffer.h"
#include "flutter/shell/platform/android/android_vm_init.h"
#include "flutter/shell/platform/android/android_vsync_waiter.h"
#include "flutter/shell/platform/android/android_vulkan_external_texture.h"
#include "flutter/shell/platform/android/apk_asset_provider.h"
#include "flutter/shell/platform/android/jni_router.h"

#if __has_include("flutter/shell/platform/android/android_semantics_mapper.h")
#include "flutter/shell/platform/android/android_semantics_mapper.h"
#define FLUTTER_HAS_ANDROID_SEMANTICS_MAPPER 1
#else
#define FLUTTER_HAS_ANDROID_SEMANTICS_MAPPER 0
#endif

#if __has_include( \
    "flutter/shell/platform/android/android_window_metrics_mapper.h")
#include "flutter/shell/platform/android/android_window_metrics_mapper.h"
#define FLUTTER_HAS_ANDROID_WINDOW_METRICS_MAPPER 1
#else
#define FLUTTER_HAS_ANDROID_WINDOW_METRICS_MAPPER 0
#endif

#if __has_include("flutter/shell/platform/android/android_mutators_mapper.h")
#include "flutter/shell/platform/android/android_mutators_mapper.h"
#define FLUTTER_HAS_ANDROID_MUTATORS_MAPPER 1
#else
#define FLUTTER_HAS_ANDROID_MUTATORS_MAPPER 0
#endif

#if __has_include( \
    "flutter/shell/platform/android/android_platform_views_controller.h")
#include "flutter/shell/platform/android/android_platform_views_controller.h"
#define FLUTTER_HAS_ANDROID_PLATFORM_VIEWS_CONTROLLER 1
#else
#define FLUTTER_HAS_ANDROID_PLATFORM_VIEWS_CONTROLLER 0
namespace flutter {
class AndroidPlatformViewsController {};
}  // namespace flutter
#endif

#if __has_include("flutter/shell/platform/android/android_surface_control.h")
#include "flutter/shell/platform/android/android_surface_control.h"
#define FLUTTER_HAS_ANDROID_SURFACE_CONTROL 1
#else
#define FLUTTER_HAS_ANDROID_SURFACE_CONTROL 0
namespace flutter {
class AndroidSurfaceControl {};
}  // namespace flutter
#endif

#if FML_OS_ANDROID
#include <EGL/egl.h>
#include <EGL/eglext.h>
#include <GLES2/gl2.h>
#include <GLES2/gl2ext.h>
#include <android/api-level.h>
#include <android/log.h>
#include <android/native_window_jni.h>
#include <dlfcn.h>
#include <sys/system_properties.h>
#include <unistd.h>
#endif

#if defined(__ELF__)
extern "C" __attribute__((weak)) FlutterEngineResult
FlutterEngineGetProcAddresses(FlutterEngineProcTable* table);
#endif

namespace flutter {

namespace {

using GetProcAddressesFn = FlutterEngineResult (*)(FlutterEngineProcTable*);

std::mutex g_proc_table_override_mutex;
std::optional<FlutterEngineProcTable> g_proc_table_override;
std::atomic<FlutterEmbedderNative*> g_active_embedder_instance{nullptr};

bool HasGlobalProcTableOverride() {
  std::scoped_lock lock(g_proc_table_override_mutex);
  return g_proc_table_override.has_value();
}

// Non-null sentinel byte used to preserve 0-byte platform message payloads
// across JNI and the C-API boundary (distinguishing an empty ByteBuffer from
// a null payload).
constexpr uint8_t kEmptyByte = 0;

// Bytes per RGBA8888 pixel for backing store allocations.
constexpr size_t kBytesPerRgbaPixel = 4;

// Default identifier for the custom platform task runner.
constexpr size_t kPlatformTaskRunnerIdentifier = 1;

// Default Android API level assumed on host builds when not overridden.
constexpr int kDefaultHostApiLevel = 34;

// Default refresh rate in Hz used when display refresh rate is not yet
// reported.
constexpr double kFallbackRefreshRateHz = 60.0;

// Vulkan API 1.1 version packed per VK_MAKE_API_VERSION(0, 1, 1, 0).
constexpr uint32_t kDefaultVulkanApiVersion = (1U << 22) | (1U << 12);

// Offset added to overlay_surface_id when mapping Hybrid Composition overlay
// surfaces into per-view entries in AndroidSurfaceControl.
constexpr FlutterViewId kOverlayVulkanViewIdOffset = 100000;

#if FLUTTER_HAS_ANDROID_PLATFORM_VIEWS_CONTROLLER
class EmbedderCompositorRenderDelegate final
    : public AndroidCompositorRenderDelegate {
 public:
  using BindOnscreenFn = std::function<bool(FlutterViewId,
                                            ANativeWindow*,
                                            size_t,
                                            size_t,
                                            FlutterBackingStore*)>;
  using BindOverlayFn = std::function<bool(FlutterViewId,
                                           int32_t,
                                           ANativeWindow*,
                                           size_t,
                                           size_t,
                                           FlutterBackingStore*)>;
  using PresentOnscreenFn =
      std::function<bool(FlutterViewId, const FlutterBackingStore*)>;
  using PresentOverlayFn =
      std::function<bool(FlutterViewId, int32_t, const FlutterBackingStore*)>;
  using ClearAndPresentOnscreenFn = std::function<bool(FlutterViewId)>;
  using PrepareCrossThreadFn = std::function<void()>;

  EmbedderCompositorRenderDelegate(
      BindOnscreenFn bind_onscreen,
      BindOverlayFn bind_overlay,
      PresentOnscreenFn present_onscreen,
      PresentOverlayFn present_overlay,
      ClearAndPresentOnscreenFn clear_and_present_onscreen = nullptr,
      PrepareCrossThreadFn prepare_cross_thread = nullptr)
      : bind_onscreen_(std::move(bind_onscreen)),
        bind_overlay_(std::move(bind_overlay)),
        present_onscreen_(std::move(present_onscreen)),
        present_overlay_(std::move(present_overlay)),
        clear_and_present_onscreen_(std::move(clear_and_present_onscreen)),
        prepare_cross_thread_(std::move(prepare_cross_thread)) {}

  bool BindAndResizeOnscreenSurface(
      FlutterViewId view_id,
      ANativeWindow* onscreen_window,
      size_t width,
      size_t height,
      FlutterBackingStore* backing_store_out) override {
    return bind_onscreen_ && bind_onscreen_(view_id, onscreen_window, width,
                                            height, backing_store_out);
  }

  bool BindAndResizeOverlaySurface(
      FlutterViewId view_id,
      int32_t overlay_surface_id,
      ANativeWindow* overlay_window,
      size_t width,
      size_t height,
      FlutterBackingStore* backing_store_out) override {
    return bind_overlay_ &&
           bind_overlay_(view_id, overlay_surface_id, overlay_window, width,
                         height, backing_store_out);
  }

  bool PresentOnscreenSurface(
      FlutterViewId view_id,
      const FlutterBackingStore* backing_store) override {
    return present_onscreen_ && present_onscreen_(view_id, backing_store);
  }

  bool PresentOverlaySurface(
      FlutterViewId view_id,
      int32_t overlay_surface_id,
      const FlutterBackingStore* backing_store) override {
    return present_overlay_ &&
           present_overlay_(view_id, overlay_surface_id, backing_store);
  }

  bool ClearAndPresentOnscreenSurface(FlutterViewId view_id) override {
    return !clear_and_present_onscreen_ || clear_and_present_onscreen_(view_id);
  }

  void PrepareForCrossThreadPresentation() override {
    if (prepare_cross_thread_) {
      prepare_cross_thread_();
    }
  }

 private:
  BindOnscreenFn bind_onscreen_;
  BindOverlayFn bind_overlay_;
  PresentOnscreenFn present_onscreen_;
  PresentOverlayFn present_overlay_;
  ClearAndPresentOnscreenFn clear_and_present_onscreen_;
  PrepareCrossThreadFn prepare_cross_thread_;
};
#endif

#if FML_OS_ANDROID
// 8 bits per color channel for RGBA8888 EGL configurations.
constexpr EGLint kEglChannelBits = 8;

// 24-bit depth buffer size for Impeller OpenGL ES onscreen/offscreen configs.
constexpr EGLint kEglDepthBits = 24;

// 8-bit stencil buffer size for Impeller OpenGL ES clip/stencil operations.
constexpr EGLint kEglStencilBits = 8;

// 1 MSAA sample buffer enabled for 4x MSAA EGL configurations.
constexpr EGLint kEglMsaaSampleBuffers = 1;

// 4x MSAA sample count for Impeller OpenGL ES onscreen/offscreen configs.
constexpr EGLint kEglMsaaSamples4 = 4;

// Single sample count fallback when 4x MSAA is unsupported.
constexpr EGLint kEglSingleSample = 1;

// EGL_OPENGL_ES3_BIT (0x00000040) renderable type bitmask from <EGL/eglext.h>.
constexpr EGLint kEglOpenGlEs3Bit = 0x00000040;

// OpenGL ES 3.0 context client version attribute value.
constexpr EGLint kEglClientVersion3 = 3;

// OpenGL ES 2.0 context client version attribute value.
constexpr EGLint kEglClientVersion2 = 2;

// 1x1 pixel dimension for offscreen Pbuffer surfaces.
constexpr EGLint kEglPbufferDimension = 1;

// Minimum valid non-negative dimension/stride clamp for software surface copy.
constexpr int32_t kMinSurfaceDimension = 0;

// Return code 0 indicating ANativeWindow_lock succeeded.
constexpr int32_t kANativeWindowSuccess = 0;
#endif

FlutterEngineProcTable ResolveProcTable(
    const FlutterEngineProcTable* explicit_table) {
  if (explicit_table != nullptr) {
    return *explicit_table;
  }
  {
    std::scoped_lock lock(g_proc_table_override_mutex);
    if (g_proc_table_override.has_value()) {
      return g_proc_table_override.value();
    }
  }
  FlutterEngineProcTable table{};
  table.struct_size = sizeof(FlutterEngineProcTable);
#if defined(__ELF__)
  if (&FlutterEngineGetProcAddresses != nullptr) {
    if (FlutterEngineGetProcAddresses(&table) == kSuccess &&
        table.Initialize != nullptr) {
      return table;
    }
  }
#endif
  auto self_lib = fml::NativeLibrary::CreateForCurrentProcess();
  if (self_lib) {
    auto get_procs = self_lib->ResolveFunction<GetProcAddressesFn>(
        "FlutterEngineGetProcAddresses");
    if (get_procs.has_value() && get_procs.value()) {
      get_procs.value()(&table);
    }
  }
  return table;
}

int ResolveEffectiveApiLevel(const std::optional<AndroidVMArgs>& vm_args) {
  if (vm_args.has_value() && vm_args->api_level > 0) {
    return vm_args->api_level;
  }
#if FML_OS_ANDROID
  int device_api = android_get_device_api_level();
  if (device_api > 0) {
    return device_api;
  }
#endif
  return kDefaultHostApiLevel;
}

#if FLUTTER_HAS_ANDROID_SURFACE_CONTROL
android::AndroidSystemPropertiesForVulkan BuildSystemPropertiesForVulkan(
    int api_level,
    const AndroidVMArgs& vm_args,
    AndroidRenderingAPI rendering_api) {
  DeviceProperties dev_props = ReadDeviceProperties();
  android::AndroidSystemPropertiesForVulkan sys_props;
  sys_props.api_level = api_level;
  sys_props.impeller_enabled = vm_args.enable_impeller;
  sys_props.force_opengles =
      (rendering_api == AndroidRenderingAPI::kImpellerOpenGLES ||
       rendering_api == AndroidRenderingAPI::kSkiaOpenGLES);
  sys_props.ro_hardware = dev_props.hardware;
  sys_props.ro_product_model = dev_props.model;
  sys_props.vendor_api_level = api_level;
#if FML_OS_ANDROID
  auto read_sys_prop = [](const char* key) -> std::string {
    char buf[PROP_VALUE_MAX] = {};
    int len = __system_property_get(key, buf);
    return len > 0 ? std::string(buf, static_cast<size_t>(len)) : std::string();
  };
  if (sys_props.ro_hardware.empty()) {
    sys_props.ro_hardware = read_sys_prop("ro.hardware");
  }
  if (sys_props.ro_product_model.empty()) {
    sys_props.ro_product_model = read_sys_prop("ro.product.model");
  }
  sys_props.ro_clientidbase = read_sys_prop("ro.com.google.clientidbase");
  sys_props.ro_mediatek_platform = read_sys_prop("ro.vendor.mediatek.platform");
  sys_props.ro_product_board = read_sys_prop("ro.product.board");
  std::string vendor_sdk = read_sys_prop("ro.vendor.build.version.sdk");
  if (!vendor_sdk.empty()) {
    int parsed = std::atoi(vendor_sdk.c_str());
    if (parsed > 0) {
      sys_props.vendor_api_level = parsed;
    }
  }
  sys_props.has_qemu_pipe = (::access("/dev/qemu_pipe", F_OK) == 0);
#endif
  return sys_props;
}
#endif

bool NoOpMakeCurrent(void* user_data) {
  (void)user_data;
  return true;
}

bool NoOpClearCurrent(void* user_data) {
  (void)user_data;
  return true;
}

bool NoOpPresent(void* user_data) {
  (void)user_data;
  return true;
}

uint32_t NoOpFboCallback(void* user_data) {
  (void)user_data;
  return 0;
}

void PlatformMessageResponseCallbackTrampoline(const uint8_t* data,
                                               size_t size,
                                               void* user_data) {
  std::unique_ptr<FlutterEmbedderNative::ResponsePayload> payload(
      static_cast<FlutterEmbedderNative::ResponsePayload*>(user_data));
  if (payload && payload->callback) {
    payload->callback(data, size);
  }
}

struct DeferredLibraryMappingHolder {
  std::unique_ptr<fml::Mapping> data_mapping;
  std::unique_ptr<fml::Mapping> instructions_mapping;
};

void DestroyDeferredLibraryMappingHolder(void* user_data) {
  delete static_cast<DeferredLibraryMappingHolder*>(user_data);
}

void* ResolveAndroidGLProcAddress(void* user_data, const char* name) {
  (void)user_data;
  if (name == nullptr) {
    return nullptr;
  }
#if FML_OS_ANDROID
  auto proc = eglGetProcAddress(name);
  if (proc != nullptr) {
    return reinterpret_cast<void*>(proc);
  }
  static fml::RefPtr<fml::NativeLibrary> gles3_lib =
      fml::NativeLibrary::Create("libGLESv3.so");
  if (gles3_lib) {
    auto sym = gles3_lib->ResolveSymbol(name);
    if (sym != nullptr) {
      return const_cast<void*>(reinterpret_cast<const void*>(sym));
    }
  }
  static fml::RefPtr<fml::NativeLibrary> gles2_lib =
      fml::NativeLibrary::Create("libGLESv2.so");
  if (gles2_lib) {
    auto sym = gles2_lib->ResolveSymbol(name);
    if (sym != nullptr) {
      return const_cast<void*>(reinterpret_cast<const void*>(sym));
    }
  }
#endif
  return nullptr;
}

std::optional<std::string> ExtractInitialRouteFromNavigationJson(
    const uint8_t* data,
    size_t size) {
  if (data == nullptr || size == 0) {
    return std::nullopt;
  }
  std::string_view json(reinterpret_cast<const char*>(data), size);
  if (json.find("\"setInitialRoute\"") == std::string_view::npos) {
    return std::nullopt;
  }
  constexpr std::string_view kArgsKey = "\"args\"";
  size_t args_pos = json.find(kArgsKey);
  if (args_pos == std::string_view::npos) {
    return std::nullopt;
  }
  size_t colon_pos = json.find(':', args_pos + kArgsKey.size());
  if (colon_pos == std::string_view::npos) {
    return std::nullopt;
  }
  size_t first_quote = json.find('"', colon_pos + 1);
  if (first_quote == std::string_view::npos) {
    return std::nullopt;
  }
  size_t second_quote = json.find('"', first_quote + 1);
  if (second_quote == std::string_view::npos) {
    return std::nullopt;
  }
  return std::string(
      json.substr(first_quote + 1, second_quote - first_quote - 1));
}

}  // namespace

// =============================================================================
// AndroidTaskRunners Implementation
// =============================================================================

AndroidTaskRunners::AndroidTaskRunners() : AndroidTaskRunners(nullptr, false) {}

AndroidTaskRunners::AndroidTaskRunners(
    fml::RefPtr<fml::TaskRunner> platform_task_runner,
    bool use_engine_owned_platform_and_render_runners)
    : platform_task_runner_(std::move(platform_task_runner)),
      use_engine_owned_platform_and_render_runners_(
          use_engine_owned_platform_and_render_runners) {
  if (!platform_task_runner_ &&
      !use_engine_owned_platform_and_render_runners_) {
    fallback_thread_ =
        std::make_unique<fml::Thread>("android_embedder_platform_runner");
    platform_task_runner_ = fallback_thread_->GetTaskRunner();
  }
  InitializeRunnerStructs();
}

AndroidTaskRunners::~AndroidTaskRunners() = default;

void AndroidTaskRunners::InitializeRunnerStructs() {
  platform_runner_description_ = {};
  platform_runner_description_.struct_size =
      sizeof(FlutterTaskRunnerDescription);
  platform_runner_description_.user_data = this;
  platform_runner_description_.runs_task_on_current_thread_callback =
      &AndroidTaskRunners::RunsTasksOnCurrentThreadCallback;
  platform_runner_description_.post_task_callback =
      &AndroidTaskRunners::PostTaskCallback;
  platform_runner_description_.identifier = kPlatformTaskRunnerIdentifier;

  custom_task_runners_ = {};
  custom_task_runners_.struct_size = sizeof(FlutterCustomTaskRunners);
  if (use_engine_owned_platform_and_render_runners_) {
    // Leave platform_task_runner and render_task_runner null so the engine
    // uses its fml::MessageLoopAndroid-backed task queues with valid
    // TaskQueueIds for RasterThreadMerger.
    custom_task_runners_.platform_task_runner = nullptr;
    custom_task_runners_.render_task_runner = nullptr;
  } else {
    custom_task_runners_.platform_task_runner = &platform_runner_description_;
    custom_task_runners_.render_task_runner = nullptr;
  }
}

bool AndroidTaskRunners::RunsTasksOnCurrentThreadCallback(void* user_data) {
  if (!user_data) {
    return false;
  }
  return static_cast<AndroidTaskRunners*>(user_data)
      ->RunsTasksOnCurrentThread();
}

void AndroidTaskRunners::PostTaskCallback(FlutterTask task,
                                          uint64_t target_time_nanos,
                                          void* user_data) {
  if (!user_data) {
    return;
  }
  static_cast<AndroidTaskRunners*>(user_data)->PostTask(task,
                                                        target_time_nanos);
}

bool AndroidTaskRunners::RunsTasksOnCurrentThread() const {
  if (platform_task_runner_) {
    return platform_task_runner_->RunsTasksOnCurrentThread();
  }
  return true;
}

void AndroidTaskRunners::PostTask(FlutterTask task,
                                  uint64_t target_time_nanos) {
  auto invoke_task = [this, task]() {
    std::function<void(FlutterTask)> cb;
    {
      std::lock_guard<std::mutex> lock(callback_mutex_);
      cb = execute_callback_;
    }
    if (cb) {
      cb(task);
    }
  };

  if (!platform_task_runner_) {
    invoke_task();
    return;
  }

  uint64_t now_nanos = static_cast<uint64_t>(
      fml::TimePoint::Now().ToEpochDelta().ToNanoseconds());
  if (target_time_nanos <= now_nanos) {
    platform_task_runner_->PostTask(invoke_task);
  } else {
    fml::TimeDelta delay = fml::TimeDelta::FromNanoseconds(
        static_cast<int64_t>(target_time_nanos - now_nanos));
    platform_task_runner_->PostDelayedTask(invoke_task, delay);
  }
}

// =============================================================================
// AndroidCompositor Implementation
// =============================================================================

AndroidCompositor::AndroidCompositor(
    AndroidCompositorPlatformViewDelegate* delegate,
    bool enable_surface_control,
    int api_level)
    : delegate_(delegate) {
  compositor_ = {};
  compositor_.struct_size = sizeof(FlutterCompositor);
  compositor_.user_data = this;
  compositor_.create_backing_store_callback =
      &AndroidCompositor::CreateBackingStoreCallback;
  compositor_.collect_backing_store_callback =
      &AndroidCompositor::CollectBackingStoreCallback;
  compositor_.present_layers_callback =
      &AndroidCompositor::PresentLayersCallback;
  compositor_.avoid_backing_store_cache = true;
  ConfigureForPlatform(enable_surface_control, api_level);
}

AndroidCompositor::~AndroidCompositor() = default;

void AndroidCompositor::ConfigureForPlatform(bool enable_surface_control,
                                             int api_level) {
  compositor_.avoid_backing_store_cache = true;
  compositor_.merge_raster_thread_on_platform_views = !enable_surface_control;
  compositor_.coalesce_overlay_layers = enable_surface_control;
  compositor_.platform_view_mutation_capabilities =
      (api_level >= android::kMinimumAndroidApiLevelForSurfaceControl)
          ? kFlutterPlatformViewMutationCapabilityPathConics
          : kFlutterPlatformViewMutationCapabilityDefault;
}

bool AndroidCompositor::CreateBackingStoreCallback(
    const FlutterBackingStoreConfig* config,
    FlutterBackingStore* backing_store_out,
    void* user_data) {
  if (!user_data) {
    return false;
  }
  return static_cast<AndroidCompositor*>(user_data)->OnCreateBackingStore(
      config, backing_store_out);
}

bool AndroidCompositor::CollectBackingStoreCallback(
    const FlutterBackingStore* renderer,
    void* user_data) {
  if (!user_data) {
    return false;
  }
  return static_cast<AndroidCompositor*>(user_data)->OnCollectBackingStore(
      renderer);
}

bool AndroidCompositor::PresentLayersCallback(const FlutterLayer** layers,
                                              size_t layers_count,
                                              void* user_data) {
  if (!user_data) {
    return false;
  }
  return static_cast<AndroidCompositor*>(user_data)->OnPresentLayers(
      layers, layers_count);
}

bool AndroidCompositor::OnCreateBackingStore(
    const FlutterBackingStoreConfig* config,
    FlutterBackingStore* backing_store_out) {
  if (!config || !backing_store_out) {
    return false;
  }
  std::lock_guard<std::mutex> lock(mutex_);
  auto store = std::make_unique<BackingStoreData>();
  store->id = next_store_id_++;
  store->width = static_cast<size_t>(config->size.width);
  store->height = static_cast<size_t>(config->size.height);
  size_t byte_size = store->width * store->height * kBytesPerRgbaPixel;
  store->pixels.resize(byte_size, 0);

  *backing_store_out = {};
  backing_store_out->struct_size = sizeof(FlutterBackingStore);
  backing_store_out->user_data = store.get();
  backing_store_out->type = kFlutterBackingStoreTypeSoftware;
  backing_store_out->software.allocation = store->pixels.data();
  backing_store_out->software.row_bytes = store->width * kBytesPerRgbaPixel;
  backing_store_out->software.height = store->height;
  backing_store_out->software.user_data = store.get();
  backing_store_out->software.destruction_callback = [](void*) {};

  allocated_stores_[store->id] = std::move(store);
  return true;
}

bool AndroidCompositor::OnCollectBackingStore(
    const FlutterBackingStore* renderer) {
  if (!renderer || !renderer->user_data) {
    return false;
  }
  std::lock_guard<std::mutex> lock(mutex_);
  auto* store = static_cast<BackingStoreData*>(renderer->user_data);
  allocated_stores_.erase(store->id);
  return true;
}

bool AndroidCompositor::OnPresentLayers(const FlutterLayer** layers,
                                        size_t layers_count) {
  {
    std::lock_guard<std::mutex> lock(mutex_);
    present_count_++;
  }
  if (delegate_) {
    delegate_->OnBeginFrame();
  }
  if (layers != nullptr) {
    for (size_t i = 0; i < layers_count; ++i) {
      const FlutterLayer* layer = layers[i];
      if (!layer) {
        continue;
      }
      if (layer->type == kFlutterLayerContentTypePlatformView &&
          layer->platform_view != nullptr && delegate_ != nullptr) {
        delegate_->OnDisplayPlatformView(
            layer->platform_view->identifier, layer->offset.x, layer->offset.y,
            layer->size.width, layer->size.height, layer->platform_view);
      }
    }
  }
  if (delegate_) {
    delegate_->OnEndFrame();
  }
  return true;
}

// =============================================================================
// FlutterEmbedderNative Implementation
// =============================================================================

bool FlutterEmbedderNative::RegisterJni(JNIEnv* env) {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::RegisterJni");
  const bool ok = JniRouter::RegisterJniMethods(env);
#if FLUTTER_HAS_ANDROID_MUTATORS_MAPPER
  if (ok && env != nullptr && env->functions != nullptr &&
      env->functions->GetJavaVM != nullptr) {
    AndroidMutatorsMapper::RegisterJNI(env);
    if (env->ExceptionCheck() == JNI_TRUE) {
      env->ExceptionClear();
    }
  }
#endif
  return ok;
}

void FlutterEmbedderNative::SetGlobalProcTableForTesting(
    const FlutterEngineProcTable* proc_table) {
  std::scoped_lock lock(g_proc_table_override_mutex);
  if (proc_table != nullptr) {
    g_proc_table_override = *proc_table;
  } else {
    g_proc_table_override.reset();
  }
}

FlutterEmbedderNative* FlutterEmbedderNative::GetActiveInstance() {
  return g_active_embedder_instance.load();
}

FlutterEmbedderNative::FlutterEmbedderNative(
    const FlutterEngineProcTable* proc_table,
    bool use_engine_owned_task_runners)
    : proc_table_(ResolveProcTable(proc_table)),
      use_engine_owned_task_runners_(use_engine_owned_task_runners),
      is_using_mock_proc_table_(proc_table != nullptr ||
                                HasGlobalProcTableOverride()),
      jvm_invoker_(std::make_shared<JvmInvoker>()),
      compositor_(std::make_unique<AndroidCompositor>()),
      asset_provider_(
          is_using_mock_proc_table_
              ? std::make_unique<APKAssetProvider>()
              : std::make_unique<APKAssetProvider>(nullptr, nullptr, "")),
      engine_group_(std::make_unique<AndroidEngineGroup>(nullptr,
                                                         nullptr,
                                                         &proc_table_)) {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::FlutterEmbedderNative");

  auto initial_vm_args = AndroidVMInit::GetGlobalVMArgs();
  if (initial_vm_args.has_value()) {
    AndroidVMArgs vm_args = initial_vm_args.value();
    vm_args.api_level = ResolveEffectiveApiLevel(initial_vm_args);
    AndroidRenderingAPI rendering_api = SelectRenderingAPI(vm_args);
    enable_surface_control_ =
        ShouldEnableSurfaceControl(vm_args, rendering_api);
  }

  fml::RefPtr<fml::TaskRunner> platform_runner = nullptr;
#if FML_OS_ANDROID
  if (!is_using_mock_proc_table_) {
    fml::MessageLoop::EnsureInitializedForCurrentThread();
    platform_runner = fml::MessageLoop::GetCurrent().GetTaskRunner();
  }
#endif
  task_runners_ = std::make_unique<AndroidTaskRunners>(
      platform_runner, use_engine_owned_task_runners);
  vsync_waiter_ =
      std::make_unique<AndroidVsyncWaiter>(nullptr, jvm_invoker_, &proc_table_);
#if FLUTTER_HAS_ANDROID_SURFACE_CONTROL
  surface_control_ = std::make_unique<AndroidSurfaceControl>();
#endif
  ahb_provider_ = std::make_shared<DefaultAndroidHardwareBufferProvider>();
  vk_texture_provider_ =
      std::make_shared<DefaultAndroidVulkanTextureProvider>();
  surface_texture_blitter_ = std::make_unique<SurfaceTextureGlToAhbBlitter>(
      ahb_provider_, vk_texture_provider_);
#if FLUTTER_HAS_ANDROID_PLATFORM_VIEWS_CONTROLLER
  platform_views_controller_ = std::make_unique<AndroidPlatformViewsController>(
      jvm_invoker_.get(), task_runners_->GetPlatformTaskRunner());
  platform_views_controller_->SetRenderDelegate(
      std::make_shared<EmbedderCompositorRenderDelegate>(
          [this](FlutterViewId view_id, ANativeWindow* onscreen_window,
                 size_t width, size_t height,
                 FlutterBackingStore* backing_store_out) -> bool {
            if (backing_store_out == nullptr) {
              return false;
            }
#if FLUTTER_HAS_ANDROID_SURFACE_CONTROL
            if (surface_control_ &&
                surface_control_->ResolvedRendererType() == kVulkan &&
                surface_control_->GetVulkanDevice() != nullptr) {
              if (onscreen_window != nullptr &&
                  surface_control_->GetNativeWindow(view_id) !=
                      onscreen_window) {
                surface_control_->SurfaceCreated(view_id, onscreen_window,
                                                 nullptr,
                                                 static_cast<uint32_t>(width),
                                                 static_cast<uint32_t>(height));
              } else if (surface_control_->GetSurfaceWidth(view_id) !=
                             static_cast<uint32_t>(width) ||
                         surface_control_->GetSurfaceHeight(view_id) !=
                             static_cast<uint32_t>(height)) {
                surface_control_->SurfaceChanged(view_id,
                                                 static_cast<uint32_t>(width),
                                                 static_cast<uint32_t>(height));
              }
              FlutterBackingStoreConfig config{};
              config.struct_size = sizeof(FlutterBackingStoreConfig);
              config.size.width = static_cast<double>(width);
              config.size.height = static_cast<double>(height);
              config.view_id = view_id;
              return surface_control_->CreateBackingStore(&config,
                                                          backing_store_out);
            }
#endif
            (void)view_id;
            if (onscreen_window != nullptr && egl_window_surface_ == nullptr) {
              CreateOrUpdateAndroidWindowSurface(onscreen_window);
            }
            *backing_store_out = {};
            backing_store_out->struct_size = sizeof(FlutterBackingStore);
            backing_store_out->type = kFlutterBackingStoreTypeOpenGL;
            backing_store_out->open_gl.type = kFlutterOpenGLTargetTypeSurface;
            backing_store_out->open_gl.surface.struct_size =
                sizeof(FlutterOpenGLSurface);
            backing_store_out->open_gl.surface.user_data = this;
            backing_store_out->open_gl.surface.make_current_callback =
                [](void* user_data, bool* state_changed) -> bool {
              if (state_changed) {
                *state_changed = true;
              }
              return user_data != nullptr &&
                     static_cast<FlutterEmbedderNative*>(user_data)
                         ->MakeAndroidEGLCurrent();
            };
            backing_store_out->open_gl.surface.clear_current_callback =
                [](void* user_data, bool* state_changed) -> bool {
              if (state_changed) {
                *state_changed = false;
              }
              (void)user_data;
              return true;
            };
            backing_store_out->open_gl.surface.destruction_callback =
                [](void*) {};
            // Standard RGBA8888 Sized Internal Format (GL_RGBA8 = 0x8058).
            constexpr uint32_t kGlRgba8Format = 0x8058;
            backing_store_out->open_gl.surface.format = kGlRgba8Format;
            return true;
          },
          [this](FlutterViewId view_id, int32_t overlay_surface_id,
                 ANativeWindow* overlay_window, size_t width, size_t height,
                 FlutterBackingStore* backing_store_out) -> bool {
            (void)view_id;
            if (backing_store_out == nullptr || overlay_window == nullptr) {
              return false;
            }
#if FLUTTER_HAS_ANDROID_SURFACE_CONTROL
            if (surface_control_ &&
                surface_control_->ResolvedRendererType() == kVulkan &&
                surface_control_->GetVulkanDevice() != nullptr) {
              FlutterViewId overlay_view_id =
                  kOverlayVulkanViewIdOffset +
                  static_cast<FlutterViewId>(overlay_surface_id);
              if (surface_control_->GetNativeWindow(overlay_view_id) !=
                  overlay_window) {
                surface_control_->SurfaceCreated(overlay_view_id,
                                                 overlay_window, nullptr,
                                                 static_cast<uint32_t>(width),
                                                 static_cast<uint32_t>(height));
              } else if (surface_control_->GetSurfaceWidth(overlay_view_id) !=
                             static_cast<uint32_t>(width) ||
                         surface_control_->GetSurfaceHeight(overlay_view_id) !=
                             static_cast<uint32_t>(height)) {
                surface_control_->SurfaceChanged(overlay_view_id,
                                                 static_cast<uint32_t>(width),
                                                 static_cast<uint32_t>(height));
              }
              FlutterBackingStoreConfig config{};
              config.struct_size = sizeof(FlutterBackingStoreConfig);
              config.size.width = static_cast<double>(width);
              config.size.height = static_cast<double>(height);
              config.view_id = overlay_view_id;
              return surface_control_->CreateBackingStore(&config,
                                                          backing_store_out);
            }
#endif
            return BindAndroidOverlayEGLSurface(
                overlay_surface_id, overlay_window, backing_store_out);
          },
          [this](FlutterViewId view_id,
                 const FlutterBackingStore* backing_store) -> bool {
            if (backing_store != nullptr &&
                backing_store->type == kFlutterBackingStoreTypeVulkan) {
#if FLUTTER_HAS_ANDROID_SURFACE_CONTROL
              if (surface_control_) {
                bool ok = surface_control_->PresentImageForView(
                    view_id, backing_store->vulkan.image);
                if (ok) {
                  NotifyFirstFramePresented();
                }
                return ok;
              }
#endif
              return false;
            }
            return PresentAndroidEGL();
          },
          [this](FlutterViewId view_id, int32_t overlay_surface_id,
                 const FlutterBackingStore* backing_store) -> bool {
            (void)view_id;
            if (backing_store != nullptr &&
                backing_store->type == kFlutterBackingStoreTypeVulkan) {
#if FLUTTER_HAS_ANDROID_SURFACE_CONTROL
              if (surface_control_) {
                FlutterViewId overlay_view_id =
                    kOverlayVulkanViewIdOffset +
                    static_cast<FlutterViewId>(overlay_surface_id);
                bool ok = surface_control_->PresentImageForView(
                    overlay_view_id, backing_store->vulkan.image);
                if (ok) {
                  NotifyFirstFramePresented();
                }
                return ok;
              }
#endif
              return false;
            }
            return PresentAndroidOverlayEGL(overlay_surface_id);
          },
          [this](FlutterViewId /*view_id*/) -> bool {
            return ClearAndPresentAndroidEGL();
          },
          [this]() { ClearAndroidEGLCurrent(); }));
  platform_views_controller_->SetFramePresentedCallback(
      [this](FlutterViewId /*view_id*/) { NotifyFirstFramePresented(); });
#endif

  task_runners_->SetTaskExecutionCallback([this](FlutterTask task) {
    if (engine_ != nullptr && proc_table_.RunTask != nullptr) {
      proc_table_.RunTask(engine_, &task);
    }
  });

  AndroidSurfaceManager::Callbacks surface_callbacks;
  surface_callbacks.on_window_created = [this](void* window) {
    void* old_window = nullptr;
    {
      std::lock_guard<std::mutex> window_lock(native_window_mutex_);
      old_window = native_window_;
      native_window_ = window;
    }
    if (!is_using_mock_proc_table_ && old_window != nullptr &&
        old_window != window) {
      DestroyAndroidWindowSurface();
#if FML_OS_ANDROID
      ANativeWindow_release(static_cast<ANativeWindow*>(old_window));
#endif
    }
    if (!is_using_mock_proc_table_ && window != nullptr) {
#if FLUTTER_HAS_ANDROID_SURFACE_CONTROL
      if (surface_control_) {
        surface_control_->SurfaceCreated(
            0, window, nullptr, static_cast<uint32_t>(surface_width_),
            static_cast<uint32_t>(surface_height_));
      }
#endif
#if FLUTTER_HAS_ANDROID_PLATFORM_VIEWS_CONTROLLER
      if (platform_views_controller_) {
        platform_views_controller_->SetOnscreenWindow(
            0, static_cast<ANativeWindow*>(window), surface_width_,
            surface_height_);
      }
#endif
      auto vm_args = AndroidVMInit::GetGlobalVMArgs().value_or(AndroidVMArgs{});
      AndroidRenderingAPI api = SelectRenderingAPI(vm_args);
      if (!vm_args.enable_software_rendering &&
          (api == AndroidRenderingAPI::kImpellerOpenGLES ||
           egl_display_ != nullptr)) {
        CreateOrUpdateAndroidWindowSurface(window);
      }
    }
    ScheduleFrame();
  };
  surface_callbacks.on_window_changed = [this](void* window) {
    // Zero width and height passed when clearing the detached onscreen window.
    constexpr int32_t kDetachedWindowDimension = 0;
    void* old_window = nullptr;
    {
      std::lock_guard<std::mutex> window_lock(native_window_mutex_);
      old_window = native_window_;
      native_window_ = window;
    }
    if (!is_using_mock_proc_table_) {
      if (window != nullptr) {
#if FLUTTER_HAS_ANDROID_SURFACE_CONTROL
        if (surface_control_) {
          surface_control_->SurfaceCreated(
              kAndroidImplicitViewId, window, nullptr,
              static_cast<uint32_t>(surface_width_),
              static_cast<uint32_t>(surface_height_));
        }
#endif
#if FLUTTER_HAS_ANDROID_PLATFORM_VIEWS_CONTROLLER
        if (platform_views_controller_) {
          platform_views_controller_->SetOnscreenWindow(
              kAndroidImplicitViewId, static_cast<ANativeWindow*>(window),
              surface_width_, surface_height_);
        }
#endif
        auto vm_args =
            AndroidVMInit::GetGlobalVMArgs().value_or(AndroidVMArgs{});
        AndroidRenderingAPI api = SelectRenderingAPI(vm_args);
        if (!vm_args.enable_software_rendering &&
            (api == AndroidRenderingAPI::kImpellerOpenGLES ||
             egl_display_ != nullptr)) {
          CreateOrUpdateAndroidWindowSurface(window);
        }
      } else {
#if FLUTTER_HAS_ANDROID_PLATFORM_VIEWS_CONTROLLER
        if (platform_views_controller_) {
          platform_views_controller_->SetOnscreenWindow(
              kAndroidImplicitViewId, nullptr, kDetachedWindowDimension,
              kDetachedWindowDimension);
        }
#endif
#if FLUTTER_HAS_ANDROID_SURFACE_CONTROL
        if (surface_control_) {
          surface_control_->SurfaceDestroyed(kAndroidImplicitViewId);
        }
#endif
        DestroyAndroidWindowSurface();
      }
#if FML_OS_ANDROID
      if (old_window != nullptr && old_window != window) {
        ANativeWindow_release(static_cast<ANativeWindow*>(old_window));
      }
#else
      (void)old_window;
#endif
    }
    if (window != nullptr) {
      ScheduleFrame();
    }
  };
  surface_callbacks.on_window_destroyed = [this]() {
    void* old_window = nullptr;
    {
      std::lock_guard<std::mutex> window_lock(native_window_mutex_);
      old_window = native_window_;
      native_window_ = nullptr;
    }
    if (!is_using_mock_proc_table_) {
#if FLUTTER_HAS_ANDROID_PLATFORM_VIEWS_CONTROLLER
      if (platform_views_controller_) {
        platform_views_controller_->SetOnscreenWindow(0, nullptr, 0, 0);
      }
#endif
#if FLUTTER_HAS_ANDROID_SURFACE_CONTROL
      if (surface_control_) {
        surface_control_->SurfaceDestroyed(0);
      }
#endif
      DestroyAndroidOverlayEGLSurfaces();
      DestroyAndroidWindowSurface();
#if FML_OS_ANDROID
      if (old_window != nullptr) {
        ANativeWindow_release(static_cast<ANativeWindow*>(old_window));
      }
#else
      (void)old_window;
#endif
    }
    NotifyLowMemoryWarning();
  };
  surface_callbacks.on_metrics_changed = [this](size_t width, size_t height) {
    surface_width_ = width;
    surface_height_ = height;
    if (!is_using_mock_proc_table_) {
#if FLUTTER_HAS_ANDROID_SURFACE_CONTROL
      if (surface_control_ && (surface_control_->GetSurfaceWidth(0) !=
                                   static_cast<uint32_t>(width) ||
                               surface_control_->GetSurfaceHeight(0) !=
                                   static_cast<uint32_t>(height))) {
        surface_control_->SurfaceChanged(0, static_cast<uint32_t>(width),
                                         static_cast<uint32_t>(height));
      }
#endif
#if FLUTTER_HAS_ANDROID_PLATFORM_VIEWS_CONTROLLER
      if (platform_views_controller_) {
        void* current_window = nullptr;
        {
          std::lock_guard<std::mutex> window_lock(native_window_mutex_);
          current_window = native_window_;
        }
        platform_views_controller_->SetOnscreenWindow(
            kAndroidImplicitViewId, static_cast<ANativeWindow*>(current_window),
            width, height);
      }
#endif
    }
    if (is_using_mock_proc_table_ && engine_ != nullptr &&
        proc_table_.SendWindowMetricsEvent != nullptr) {
      FlutterWindowMetricsEvent event{};
      event.struct_size = sizeof(FlutterWindowMetricsEvent);
      event.width = width;
      event.height = height;
      event.pixel_ratio = last_pixel_ratio_;
      event.display_id = static_cast<FlutterEngineDisplayId>(last_display_id_);
      event.physical_touch_slop =
          static_cast<double>(kUnsetCornerRadiusSentinel);
      proc_table_.SendWindowMetricsEvent(engine_, &event);
    }
  };
  surface_manager_ =
      std::make_unique<AndroidSurfaceManager>(std::move(surface_callbacks));

  g_active_embedder_instance.store(this);
}

FlutterEmbedderNative::~FlutterEmbedderNative() {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::~FlutterEmbedderNative");
  if (alive_flag_) {
    alive_flag_->store(false);
  }
  Detach();
  FlutterEmbedderNative* expected = this;
  g_active_embedder_instance.compare_exchange_strong(expected, nullptr);
}

bool FlutterEmbedderNative::IsValid() const {
  return proc_table_.struct_size == sizeof(FlutterEngineProcTable);
}

void FlutterEmbedderNative::SetEngineForTesting(
    FLUTTER_API_SYMBOL(FlutterEngine) engine) {
  engine_ = engine;
  if (vsync_waiter_) {
    vsync_waiter_->SetEngine(engine);
  }
}

bool FlutterEmbedderNative::Attach(JNIEnv* env, jobject flutter_jni) {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::Attach");
  if (env != nullptr && flutter_jni != nullptr && jvm_invoker_ != nullptr) {
    if (!jvm_invoker_->Attach(env, flutter_jni)) {
      return false;
    }
  }
  return IsValid();
}

void FlutterEmbedderNative::Detach() {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::Detach");
  if (alive_flag_) {
    alive_flag_->store(false);
  }
  if (vsync_waiter_) {
    vsync_waiter_->Detach();
  }
  if (engine_ != nullptr) {
    auto handle = engine_;
    engine_ = nullptr;
    if (engine_group_ && engine_group_->IsEngineActive(handle)) {
      engine_group_->ShutdownEngine(handle);
    } else if (proc_table_.Shutdown != nullptr) {
      proc_table_.Shutdown(handle);
    }
  }
  if (custom_asset_resolver_.destruction_callback != nullptr &&
      custom_asset_resolver_.user_data != nullptr) {
    custom_asset_resolver_.destruction_callback(
        custom_asset_resolver_.user_data);
  }
  custom_asset_resolver_ = {};
  if (!is_using_mock_proc_table_) {
    ReleaseAllTextures();
    DestroyAndroidOverlayEGLSurfaces();
    TeardownAndroidEGL();
    {
      std::lock_guard<std::mutex> window_lock(native_window_mutex_);
#if FML_OS_ANDROID
      if (native_window_ != nullptr) {
        ANativeWindow_release(static_cast<ANativeWindow*>(native_window_));
      }
#endif
      native_window_ = nullptr;
    }
  } else {
    std::lock_guard<std::mutex> window_lock(native_window_mutex_);
    native_window_ = nullptr;
  }
  if (jvm_invoker_) {
    jvm_invoker_->Detach();
  }
}

bool FlutterEmbedderNative::RunBundleAndSnapshotFromLibrary(
    JNIEnv* env,
    const std::string& bundle_path,
    const std::string& entrypoint,
    const std::string& library_url,
    jobject asset_manager,
    const std::vector<std::string>& entrypoint_args,
    int64_t engine_id) {
  TRACE_EVENT0("flutter",
               "FlutterEmbedderNative::RunBundleAndSnapshotFromLibrary");
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::Initialize[C-API]");
#if !FLUTTER_RELEASE
  FML_LOG(INFO) << "[EMBEDDER_API_PROOF] path=C_EMBEDDER_API";
#endif
  if (!proc_table_.Initialize || !proc_table_.RunInitialized) {
    FML_LOG(ERROR)
        << "Cannot run bundle: Initialize or RunInitialized missing in "
           "FlutterEngineProcTable.";
    return false;
  }

  engine_id_ = engine_id;

  if (asset_provider_) {
    asset_provider_->UpdateJavaAssetManager(env, asset_manager, bundle_path);
    if (custom_asset_resolver_.destruction_callback != nullptr &&
        custom_asset_resolver_.user_data != nullptr) {
      custom_asset_resolver_.destruction_callback(
          custom_asset_resolver_.user_data);
    }
    custom_asset_resolver_ = asset_provider_->CreateCustomAssetResolver();
  }

  auto global_vm_args = AndroidVMInit::GetGlobalVMArgs();
  AndroidVMArgs vm_args = global_vm_args.value_or(AndroidVMArgs{});
  int api_level = ResolveEffectiveApiLevel(global_vm_args);
  vm_args.api_level = api_level;

  AndroidRenderingAPI rendering_api = SelectRenderingAPI(vm_args);
  if (!is_using_mock_proc_table_ && !vm_args.enable_software_rendering) {
#if FLUTTER_HAS_ANDROID_SURFACE_CONTROL
    if (surface_control_) {
      surface_control_->SetSystemPropertiesForVulkan(
          BuildSystemPropertiesForVulkan(api_level, vm_args, rendering_api));
    }
#endif
    if (rendering_api != AndroidRenderingAPI::kImpellerVulkan) {
      InitializeAndroidEGL();
      void* current_window = nullptr;
      {
        std::lock_guard<std::mutex> window_lock(native_window_mutex_);
        current_window = native_window_;
      }
      if (current_window != nullptr && egl_window_surface_ == nullptr) {
        CreateOrUpdateAndroidWindowSurface(current_window);
      }
    }
  }
  for (const auto& arg : entrypoint_args) {
    auto hcpp = ParseHcppFlag(arg);
    if (hcpp.has_value()) {
      vm_args.enable_surface_control = hcpp.value();
    }
  }
  bool enable_surface_control =
      ShouldEnableSurfaceControl(vm_args, rendering_api);
  enable_surface_control_ = enable_surface_control;

  if (compositor_) {
    compositor_->ConfigureForPlatform(enable_surface_control, api_level);
  }
#if FLUTTER_HAS_ANDROID_PLATFORM_VIEWS_CONTROLLER
  if (platform_views_controller_) {
    platform_views_controller_->SetApiLevel(api_level);
    platform_views_controller_->SetHcppEnabled(enable_surface_control);
    platform_views_controller_->SetDevicePixelRatio(last_pixel_ratio_);
  }
#endif

  std::vector<std::string> cmd_args = SynthesizeCommandLineArgs(
      vm_args.command_line_args, enable_surface_control,
      !is_using_mock_proc_table_ && !vm_args.enable_software_rendering);
  if (vm_args.trace_systrace &&
      std::find(cmd_args.begin(), cmd_args.end(), "--trace-systrace") ==
          cmd_args.end() &&
      std::find(cmd_args.begin(), cmd_args.end(), "--trace-systrace=true") ==
          cmd_args.end()) {
    cmd_args.push_back("--trace-systrace");
  }
  if (!library_url.empty()) {
    cmd_args.push_back("--dart-entrypoint-library=" + library_url);
  }
  {
    std::lock_guard<std::mutex> lock(pending_startup_mutex_);
    if (!initial_route_.empty()) {
      cmd_args.push_back("--route=" + initial_route_);
    }
  }
  std::vector<std::string> full_argv;
  full_argv.reserve(cmd_args.size() + 1);
  full_argv.push_back("flutter");
  for (const auto& arg : cmd_args) {
    full_argv.push_back(arg);
  }
  std::vector<const char*> cmd_argv_ptrs;
  cmd_argv_ptrs.reserve(full_argv.size());
  for (const auto& arg : full_argv) {
    cmd_argv_ptrs.push_back(arg.c_str());
  }

  std::vector<const char*> dart_argv_ptrs;
  dart_argv_ptrs.reserve(entrypoint_args.size());
  for (const auto& arg : entrypoint_args) {
    dart_argv_ptrs.push_back(arg.c_str());
  }

  FlutterRendererConfig renderer_config{};
#if !SLIMPELLER
  if (vm_args.enable_software_rendering) {
    renderer_config.type = kSoftware;
    renderer_config.software.struct_size =
        sizeof(FlutterSoftwareRendererConfig);
    renderer_config.software.surface_present_callback =
        [](void* user_data, const void* allocation, size_t row_bytes,
           size_t height) -> bool {
      return user_data != nullptr &&
             static_cast<FlutterEmbedderNative*>(user_data)
                 ->PresentAndroidSoftware(allocation, row_bytes, height);
    };
  } else
#endif
  {
    renderer_config.type = kDeferred;
    renderer_config.deferred.struct_size =
        sizeof(FlutterDeferredRendererConfig);
    renderer_config.deferred.resolve_callback =
        &FlutterEmbedderNative::OnResolveRendererConfigCallback;
  }

  const FlutterCustomAssetResolver* custom_resolvers[1] = {
      &custom_asset_resolver_,
  };

  image_decoder_registration_ = {};
  image_decoder_registration_.struct_size =
      sizeof(FlutterImageDecoderRegistration);
  image_decoder_registration_.priority = kAndroidSdkImageDecoderPriority;
  image_decoder_registration_.create_decoder =
      &FlutterEmbedderNative::OnCreateImageDecoderCallback;
  image_decoder_registration_.user_data = this;
  image_decoder_registration_.destruction_callback = nullptr;

  const FlutterImageDecoderRegistration* image_decoders[1] = {
      &image_decoder_registration_,
  };

  std::string resolved_assets_path = bundle_path;
  if (!is_using_mock_proc_table_ && !vm_args.kernel_path.empty()) {
    size_t last_slash = vm_args.kernel_path.find_last_of('/');
    if (last_slash != std::string::npos) {
      resolved_assets_path = vm_args.kernel_path.substr(0, last_slash);
    }
  }

  FlutterProjectArgs project_args{};
  project_args.struct_size = sizeof(FlutterProjectArgs);
  project_args.assets_path =
      resolved_assets_path.empty() ? nullptr : resolved_assets_path.c_str();
  project_args.icu_data_path =
      vm_args.icu_data_path.empty() ? nullptr : vm_args.icu_data_path.c_str();
  project_args.command_line_argc = static_cast<int>(cmd_argv_ptrs.size());
  project_args.command_line_argv =
      cmd_argv_ptrs.empty() ? nullptr : cmd_argv_ptrs.data();
  project_args.platform_message_callback =
      &FlutterEmbedderNative::OnPlatformMessageCallback;
  project_args.persistent_cache_path = vm_args.engine_caches_path.empty()
                                           ? nullptr
                                           : vm_args.engine_caches_path.c_str();
  project_args.is_persistent_cache_read_only =
      vm_args.is_persistent_cache_read_only;
  project_args.vsync_callback = &FlutterEmbedderNative::OnVsyncCallback;
  project_args.custom_dart_entrypoint =
      entrypoint.empty() ? nullptr : entrypoint.c_str();
  project_args.custom_task_runners =
      task_runners_ ? task_runners_->GetCustomTaskRunners() : nullptr;
  project_args.shutdown_dart_vm_when_done = true;
  const FlutterCompositor* active_compositor = nullptr;
  if (is_using_mock_proc_table_) {
    active_compositor =
        compositor_ ? compositor_->GetEmbedderCompositor() : nullptr;
  } else if (rendering_api != AndroidRenderingAPI::kSoftware) {
#if FLUTTER_HAS_ANDROID_PLATFORM_VIEWS_CONTROLLER
    if (platform_views_controller_) {
      active_compositor = platform_views_controller_->GetEmbedderCompositor();
    }
#endif
  }
  project_args.compositor = active_compositor;
  project_args.dart_old_gen_heap_size = vm_args.dart_old_gen_heap_size;
  project_args.compute_platform_resolved_locale_callback =
      &FlutterEmbedderNative::OnComputePlatformResolvedLocaleCallback;
  project_args.dart_entrypoint_argc = static_cast<int>(dart_argv_ptrs.size());
  project_args.dart_entrypoint_argv =
      dart_argv_ptrs.empty() ? nullptr : dart_argv_ptrs.data();
  project_args.log_message_callback =
      &FlutterEmbedderNative::OnLogMessageCallback;
  project_args.log_tag =
      vm_args.log_tag.empty() ? "flutter" : vm_args.log_tag.c_str();
  project_args.on_pre_engine_restart_callback =
      &FlutterEmbedderNative::OnPreEngineRestartCallback;
  project_args.update_semantics_callback2 =
      &FlutterEmbedderNative::OnUpdateSemanticsCallback;
  project_args.engine_id = engine_id;
  project_args.enable_wide_gamut = vm_args.enable_wide_gamut;
  project_args.request_dart_deferred_library_callback =
      &FlutterEmbedderNative::OnRequestDartDeferredLibraryCallback;
  project_args.custom_asset_resolvers_count = 1;
  project_args.custom_asset_resolvers = custom_resolvers;

  if (api_level >= kMinApiLevelForNdkImageDecoder) {
    project_args.image_decoders_count = 1;
    project_args.image_decoders = image_decoders;
#if !FLUTTER_RELEASE
    FML_LOG(INFO) << "Registered Android SDK image decoder (API level 28+)";
#endif
  } else {
    project_args.image_decoders_count = 0;
    project_args.image_decoders = nullptr;
  }

  project_args.vm_service_uri_callback = &AndroidVMInit::OnVmServiceUriCallback;
  project_args.enable_direct_platform_message_dispatch = true;
  project_args.scale_font_size_callback =
      &FlutterEmbedderNative::OnScaleFontSizeCallback;

  FLUTTER_API_SYMBOL(FlutterEngine) initialized_engine = nullptr;
  FlutterEngineResult init_result =
      proc_table_.Initialize(FLUTTER_ENGINE_VERSION, &renderer_config,
                             &project_args, this, &initialized_engine);
  if (init_result != kSuccess || initialized_engine == nullptr) {
    if (custom_asset_resolver_.destruction_callback != nullptr &&
        custom_asset_resolver_.user_data != nullptr) {
      custom_asset_resolver_.destruction_callback(
          custom_asset_resolver_.user_data);
    }
    custom_asset_resolver_ = {};
    FML_LOG(ERROR) << "Failed to initialize Flutter engine via proc table: "
                   << init_result;
    return false;
  }
  // Ownership of custom_asset_resolver_.user_data is transferred to the
  // initialized engine (EmbedderCustomAssetResolver invokes
  // destruction_callback when the engine's AssetManager is destroyed).
  custom_asset_resolver_ = {};
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::Initialize[C-API]");

  engine_ = initialized_engine;
  if (vsync_waiter_) {
    vsync_waiter_->SetEngine(engine_);
  }
  if (engine_group_) {
    engine_group_->SetPrimaryEngine(engine_, engine_id);
  }
#if FLUTTER_HAS_ANDROID_SURFACE_CONTROL
  if (surface_control_) {
    surface_control_->SetEngineProcTable(proc_table_, engine_);
  }
#endif

  if (!is_using_mock_proc_table_) {
    UpdateDisplayMetrics(env);
    FlushPendingStartupState();
  }

  FlutterEngineResult run_result = proc_table_.RunInitialized(engine_);
  if (run_result != kSuccess) {
    FML_LOG(ERROR) << "Failed to run initialized Flutter engine: "
                   << run_result;
    if (proc_table_.Shutdown) {
      proc_table_.Shutdown(engine_);
    }
    engine_ = nullptr;
    if (vsync_waiter_) {
      vsync_waiter_->Detach();
    }
    return false;
  }
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::Initialize[C-API]");

  void* current_window = nullptr;
  {
    std::lock_guard<std::mutex> window_lock(native_window_mutex_);
    current_window = native_window_;
  }
  if (!is_using_mock_proc_table_ && current_window != nullptr) {
    ScheduleFrame();
  }

  return true;
}

std::unique_ptr<FlutterEmbedderNative> FlutterEmbedderNative::Spawn(
    JNIEnv* env,
    jobject flutter_jni,
    const std::string& entrypoint,
    const std::string& library_url,
    const std::string& initial_route,
    const std::vector<std::string>& entrypoint_args,
    int64_t engine_id) {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::Spawn");
  if (engine_ == nullptr || !engine_group_) {
    FML_LOG(ERROR) << "Cannot spawn child engine: parent engine not running.";
    return nullptr;
  }

  auto child = std::make_unique<FlutterEmbedderNative>(
      is_using_mock_proc_table_ ? &proc_table_ : nullptr,
      use_engine_owned_task_runners_);
  child->engine_id_ = engine_id;
  child->enable_surface_control_ = enable_surface_control_;
  if (asset_provider_) {
    child->asset_provider_ = asset_provider_->Clone();
  }
  if (env != nullptr && flutter_jni != nullptr) {
    child->Attach(env, flutter_jni);
  }

  if (!child->is_using_mock_proc_table_) {
    auto global_vm_args = AndroidVMInit::GetGlobalVMArgs();
    AndroidVMArgs vm_args = global_vm_args.value_or(AndroidVMArgs{});
    int api_level = ResolveEffectiveApiLevel(global_vm_args);
    vm_args.api_level = api_level;
    AndroidRenderingAPI rendering_api = SelectRenderingAPI(vm_args);
    if (!vm_args.enable_software_rendering) {
#if FLUTTER_HAS_ANDROID_SURFACE_CONTROL
      if (child->surface_control_) {
        child->surface_control_->SetSystemPropertiesForVulkan(
            BuildSystemPropertiesForVulkan(api_level, vm_args, rendering_api));
      }
#endif
      if (rendering_api != AndroidRenderingAPI::kImpellerVulkan) {
        child->InitializeAndroidEGL();
      }
    }
#if FLUTTER_HAS_ANDROID_PLATFORM_VIEWS_CONTROLLER
    if (child->platform_views_controller_) {
      child->platform_views_controller_->SetApiLevel(api_level);
      child->platform_views_controller_->SetHcppEnabled(
          child->enable_surface_control_);
    }
#endif
  }

  AndroidEngineSpawnArgs spawn_args;
  spawn_args.entrypoint = entrypoint.empty() ? "main" : entrypoint;
  spawn_args.library_url = library_url;
  spawn_args.initial_route = initial_route;
  spawn_args.entrypoint_args = entrypoint_args;
  spawn_args.engine_id = engine_id;
  spawn_args.user_data = child.get();
  const FlutterCompositor* child_compositor = nullptr;
  if (child->is_using_mock_proc_table_) {
    child_compositor = child->compositor_
                           ? child->compositor_->GetEmbedderCompositor()
                           : nullptr;
  } else {
    auto vm_args = AndroidVMInit::GetGlobalVMArgs().value_or(AndroidVMArgs{});
    if (!vm_args.enable_software_rendering) {
#if FLUTTER_HAS_ANDROID_PLATFORM_VIEWS_CONTROLLER
      if (child->platform_views_controller_) {
        child_compositor =
            child->platform_views_controller_->GetEmbedderCompositor();
      }
#endif
    }
  }
  spawn_args.compositor = child_compositor;

  FLUTTER_API_SYMBOL(FlutterEngine)
  spawned_engine = engine_group_->SpawnEngine(engine_, spawn_args);
  if (spawned_engine == nullptr) {
    FML_LOG(ERROR) << "Failed to spawn child engine via AndroidEngineGroup.";
    return nullptr;
  }

  child->engine_ = spawned_engine;
  if (child->vsync_waiter_) {
    child->vsync_waiter_->SetEngine(spawned_engine);
  }
#if FLUTTER_HAS_ANDROID_SURFACE_CONTROL
  if (child->surface_control_) {
    child->surface_control_->SetEngineProcTable(child->proc_table_,
                                                spawned_engine);
  }
#endif
  if (!child->is_using_mock_proc_table_) {
    child->UpdateDisplayMetrics(env);
    child->FlushPendingStartupState();
  }
  return child;
}

void FlutterEmbedderNative::UpdateJavaAssetManager(
    JNIEnv* env,
    jobject asset_manager,
    const std::string& asset_bundle_path) {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::UpdateJavaAssetManager");
  if (asset_provider_) {
    asset_provider_->UpdateJavaAssetManager(env, asset_manager,
                                            asset_bundle_path);
  }
}

void FlutterEmbedderNative::SurfaceCreated(JNIEnv* env, jobject jsurface) {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::SurfaceCreated");
  void* window = jsurface;
#if FML_OS_ANDROID
  if (env != nullptr && jsurface != nullptr) {
    window = ANativeWindow_fromSurface(env, jsurface);
  }
#else
  (void)env;
#endif
  if (surface_manager_) {
    surface_manager_->SurfaceCreated(window, surface_width_, surface_height_);
  }
}

void FlutterEmbedderNative::SurfaceWindowChanged(JNIEnv* env,
                                                 jobject jsurface) {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::SurfaceWindowChanged");
  void* window = jsurface;
#if FML_OS_ANDROID
  if (env != nullptr && jsurface != nullptr) {
    window = ANativeWindow_fromSurface(env, jsurface);
  }
#else
  (void)env;
#endif
  if (surface_manager_) {
    surface_manager_->SurfaceWindowChanged(window);
  }
}

void FlutterEmbedderNative::SurfaceChanged(size_t width, size_t height) {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::SurfaceChanged");
  if (surface_manager_) {
    surface_manager_->SurfaceChanged(width, height);
  }
}

void FlutterEmbedderNative::SurfaceDestroyed() {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::SurfaceDestroyed");
  if (surface_manager_) {
    surface_manager_->SurfaceDestroyed();
  }
}

void FlutterEmbedderNative::SetViewportMetrics(
    float device_pixel_ratio,
    int32_t physical_width,
    int32_t physical_height,
    int32_t physical_padding_top,
    int32_t physical_padding_right,
    int32_t physical_padding_bottom,
    int32_t physical_padding_left,
    int32_t physical_view_inset_top,
    int32_t physical_view_inset_right,
    int32_t physical_view_inset_bottom,
    int32_t physical_view_inset_left,
    int32_t system_gesture_inset_top,
    int32_t system_gesture_inset_right,
    int32_t system_gesture_inset_bottom,
    int32_t system_gesture_inset_left,
    int32_t physical_touch_slop,
    const std::vector<int32_t>& display_features_bounds,
    const std::vector<int32_t>& display_features_type,
    const std::vector<int32_t>& display_features_state,
    int32_t display_id,
    int32_t min_width,
    int32_t max_width,
    int32_t min_height,
    int32_t max_height,
    int32_t physical_display_corner_radius_top_left,
    int32_t physical_display_corner_radius_top_right,
    int32_t physical_display_corner_radius_bottom_right,
    int32_t physical_display_corner_radius_bottom_left) {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::SetViewportMetrics");
  if (device_pixel_ratio <= 0.0f) {
    return;
  }
  last_pixel_ratio_ = static_cast<double>(device_pixel_ratio);
  last_display_id_ = display_id;
  surface_width_ = static_cast<size_t>(std::max(0, physical_width));
  surface_height_ = static_cast<size_t>(std::max(0, physical_height));
#if FLUTTER_HAS_ANDROID_PLATFORM_VIEWS_CONTROLLER
  if (platform_views_controller_) {
    platform_views_controller_->SetDevicePixelRatio(last_pixel_ratio_);
  }
#endif

  if (engine_ == nullptr || proc_table_.SendWindowMetricsEvent == nullptr) {
    if (!is_using_mock_proc_table_ && engine_ == nullptr) {
      std::lock_guard<std::mutex> lock(pending_startup_mutex_);
      pending_viewport_metrics_callback_ =
          [this, device_pixel_ratio, physical_width, physical_height,
           physical_padding_top, physical_padding_right,
           physical_padding_bottom, physical_padding_left,
           physical_view_inset_top, physical_view_inset_right,
           physical_view_inset_bottom, physical_view_inset_left,
           system_gesture_inset_top, system_gesture_inset_right,
           system_gesture_inset_bottom, system_gesture_inset_left,
           physical_touch_slop, display_features_bounds, display_features_type,
           display_features_state, display_id, min_width, max_width, min_height,
           max_height, physical_display_corner_radius_top_left,
           physical_display_corner_radius_top_right,
           physical_display_corner_radius_bottom_right,
           physical_display_corner_radius_bottom_left]() {
            SetViewportMetrics(
                device_pixel_ratio, physical_width, physical_height,
                physical_padding_top, physical_padding_right,
                physical_padding_bottom, physical_padding_left,
                physical_view_inset_top, physical_view_inset_right,
                physical_view_inset_bottom, physical_view_inset_left,
                system_gesture_inset_top, system_gesture_inset_right,
                system_gesture_inset_bottom, system_gesture_inset_left,
                physical_touch_slop, display_features_bounds,
                display_features_type, display_features_state, display_id,
                min_width, max_width, min_height, max_height,
                physical_display_corner_radius_top_left,
                physical_display_corner_radius_top_right,
                physical_display_corner_radius_bottom_right,
                physical_display_corner_radius_bottom_left);
          };
    }
    return;
  }

#if FLUTTER_HAS_ANDROID_WINDOW_METRICS_MAPPER
  AndroidViewportMetrics metrics;
  metrics.device_pixel_ratio = device_pixel_ratio;
  metrics.physical_width = physical_width;
  metrics.physical_height = physical_height;
  metrics.physical_padding_top = physical_padding_top;
  metrics.physical_padding_right = physical_padding_right;
  metrics.physical_padding_bottom = physical_padding_bottom;
  metrics.physical_padding_left = physical_padding_left;
  metrics.physical_view_inset_top = physical_view_inset_top;
  metrics.physical_view_inset_right = physical_view_inset_right;
  metrics.physical_view_inset_bottom = physical_view_inset_bottom;
  metrics.physical_view_inset_left = physical_view_inset_left;
  metrics.system_gesture_inset_top = system_gesture_inset_top;
  metrics.system_gesture_inset_right = system_gesture_inset_right;
  metrics.system_gesture_inset_bottom = system_gesture_inset_bottom;
  metrics.system_gesture_inset_left = system_gesture_inset_left;
  metrics.physical_touch_slop = physical_touch_slop;
  metrics.physical_min_width = min_width;
  metrics.physical_max_width = max_width;
  metrics.physical_min_height = min_height;
  metrics.physical_max_height = max_height;
  metrics.physical_display_corner_radius_top_left =
      static_cast<double>(physical_display_corner_radius_top_left);
  metrics.physical_display_corner_radius_top_right =
      static_cast<double>(physical_display_corner_radius_top_right);
  metrics.physical_display_corner_radius_bottom_right =
      static_cast<double>(physical_display_corner_radius_bottom_right);
  metrics.physical_display_corner_radius_bottom_left =
      static_cast<double>(physical_display_corner_radius_bottom_left);
  metrics.display_features_bounds = display_features_bounds;
  metrics.display_features_type = display_features_type;
  metrics.display_features_state = display_features_state;
  metrics.display_id = static_cast<uint64_t>(display_id);
  metrics.view_id = 0;

  MappedWindowMetricsEvent mapped =
      AndroidWindowMetricsMapper::MapViewportMetrics(metrics);
  proc_table_.SendWindowMetricsEvent(engine_, &mapped.event);
#else
  FlutterWindowMetricsEvent event{};
  event.struct_size = sizeof(FlutterWindowMetricsEvent);
  event.width = surface_width_;
  event.height = surface_height_;
  event.pixel_ratio = last_pixel_ratio_;
  event.physical_view_inset_top = static_cast<double>(physical_view_inset_top);
  event.physical_view_inset_right =
      static_cast<double>(physical_view_inset_right);
  event.physical_view_inset_bottom =
      static_cast<double>(physical_view_inset_bottom);
  event.physical_view_inset_left =
      static_cast<double>(physical_view_inset_left);
  event.display_id = static_cast<FlutterEngineDisplayId>(display_id);
  event.physical_padding = {
      .left = static_cast<double>(physical_padding_left),
      .top = static_cast<double>(physical_padding_top),
      .right = static_cast<double>(physical_padding_right),
      .bottom = static_cast<double>(physical_padding_bottom),
  };
  event.physical_system_gesture_insets = {
      .left = static_cast<double>(system_gesture_inset_left),
      .top = static_cast<double>(system_gesture_inset_top),
      .right = static_cast<double>(system_gesture_inset_right),
      .bottom = static_cast<double>(system_gesture_inset_bottom),
  };
  event.physical_touch_slop = static_cast<double>(physical_touch_slop);
  proc_table_.SendWindowMetricsEvent(engine_, &event);
#endif
}

void FlutterEmbedderNative::UpdateDisplayMetrics(JNIEnv* env) {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::UpdateDisplayMetrics");
  if (engine_ == nullptr || proc_table_.NotifyDisplayUpdate == nullptr) {
    return;
  }

  double width = static_cast<double>(surface_width_);
  double height = static_cast<double>(surface_height_);
  double density = last_pixel_ratio_;
  double refresh_rate =
      vsync_waiter_ ? vsync_waiter_->GetRefreshRate() : kFallbackRefreshRateHz;

#if FML_OS_ANDROID
  if (!is_using_mock_proc_table_ && env != nullptr) {
    jclass jni_cls = env->FindClass("io/flutter/embedding/engine/FlutterJNI");
    if (env->ExceptionCheck()) {
      env->ExceptionClear();
      jni_cls = nullptr;
    }
    if (jni_cls != nullptr) {
      jfieldID w_fid = env->GetStaticFieldID(jni_cls, "displayWidth", "F");
      if (env->ExceptionCheck()) {
        env->ExceptionClear();
        w_fid = nullptr;
      }
      jfieldID h_fid = env->GetStaticFieldID(jni_cls, "displayHeight", "F");
      if (env->ExceptionCheck()) {
        env->ExceptionClear();
        h_fid = nullptr;
      }
      jfieldID d_fid = env->GetStaticFieldID(jni_cls, "displayDensity", "F");
      if (env->ExceptionCheck()) {
        env->ExceptionClear();
        d_fid = nullptr;
      }
      jfieldID fps_fid = env->GetStaticFieldID(jni_cls, "refreshRateFPS", "F");
      if (env->ExceptionCheck()) {
        env->ExceptionClear();
        fps_fid = nullptr;
      }
      if (w_fid && h_fid && d_fid) {
        float j_w = env->GetStaticFloatField(jni_cls, w_fid);
        float j_h = env->GetStaticFloatField(jni_cls, h_fid);
        float j_d = env->GetStaticFloatField(jni_cls, d_fid);
        if (j_w > 0.0f && j_h > 0.0f && j_d > 0.0f) {
          width = static_cast<double>(j_w);
          height = static_cast<double>(j_h);
          density = static_cast<double>(j_d);
        }
      }
      if (fps_fid) {
        float j_fps = env->GetStaticFloatField(jni_cls, fps_fid);
        if (j_fps > 0.0f) {
          refresh_rate = static_cast<double>(j_fps);
        }
      }
      env->DeleteLocalRef(jni_cls);
    }
  }
#else
  (void)env;
#endif

  FlutterEngineDisplay display{};
  display.struct_size = sizeof(FlutterEngineDisplay);
  display.display_id = static_cast<FlutterEngineDisplayId>(last_display_id_);
  display.single_display = true;
  display.refresh_rate = refresh_rate;
  display.width = static_cast<size_t>(width);
  display.height = static_cast<size_t>(height);
  display.device_pixel_ratio = density;

  proc_table_.NotifyDisplayUpdate(
      engine_, kFlutterEngineDisplaysUpdateTypeStartup, &display, 1);
}

bool FlutterEmbedderNative::DispatchEmptyPlatformMessage(
    const std::string& channel,
    int32_t response_id) {
  return DispatchPlatformMessage(channel, nullptr, 0, response_id);
}

bool FlutterEmbedderNative::DispatchPlatformMessage(const std::string& channel,
                                                    const uint8_t* message_data,
                                                    size_t message_size,
                                                    int32_t response_id) {
  TRACE_EVENT1("flutter", "FlutterEmbedderNative::DispatchPlatformMessage",
               "channel", channel.c_str());
  if (!is_using_mock_proc_table_ && channel == "flutter/navigation" &&
      message_data != nullptr && message_size > 0) {
    if (auto route =
            ExtractInitialRouteFromNavigationJson(message_data, message_size);
        route.has_value()) {
      std::lock_guard<std::mutex> lock(pending_startup_mutex_);
      initial_route_ = *route;
    }
  }
  if (engine_ == nullptr || proc_table_.SendPlatformMessage == nullptr) {
    if (!is_using_mock_proc_table_ && engine_ == nullptr) {
      PendingPlatformMessage pending;
      pending.channel = channel;
      pending.has_data = (message_data != nullptr);
      if (message_data != nullptr && message_size > 0) {
        pending.data.assign(message_data, message_data + message_size);
      }
      pending.response_id = response_id;
      std::lock_guard<std::mutex> lock(pending_startup_mutex_);
      pending_platform_messages_.push_back(std::move(pending));
      return true;
    }
    return false;
  }

  FlutterPlatformMessageResponseHandle* response_handle = nullptr;
  if (response_id > 0 &&
      proc_table_.PlatformMessageCreateResponseHandle != nullptr) {
    auto* payload = new ResponsePayload();
    auto alive = alive_flag_;
    auto jvm_invoker = jvm_invoker_;
    payload->callback = [alive, jvm_invoker, response_id](const uint8_t* data,
                                                          size_t size) {
      if (!alive || !alive->load() || !jvm_invoker) {
        return;
      }
      if (data == nullptr) {
        jvm_invoker->InvokePlatformMessageEmptyResponseCallback(response_id);
      } else {
        const uint8_t* non_null_bytes = (size == 0) ? &kEmptyByte : data;
        jvm_invoker->InvokePlatformMessageResponseCallback(
            response_id, non_null_bytes, size);
      }
    };
    FlutterEngineResult handle_res =
        proc_table_.PlatformMessageCreateResponseHandle(
            engine_, &PlatformMessageResponseCallbackTrampoline, payload,
            &response_handle);
    if (handle_res != kSuccess) {
      delete payload;
      response_handle = nullptr;
    }
  }

  // Preserve non-null zero-byte messages (&kEmptyByte) so the engine
  // differentiates a 0-capacity ByteBuffer from a null message.
  const uint8_t* effective_bytes = message_data;

  FlutterPlatformMessage platform_message{};
  platform_message.struct_size = sizeof(FlutterPlatformMessage);
  platform_message.channel = channel.c_str();
  platform_message.message = effective_bytes;
  platform_message.message_size = message_size;
  platform_message.response_handle = response_handle;

  FlutterEngineResult send_res =
      proc_table_.SendPlatformMessage(engine_, &platform_message);

  if (response_handle != nullptr &&
      proc_table_.PlatformMessageReleaseResponseHandle != nullptr) {
    proc_table_.PlatformMessageReleaseResponseHandle(engine_, response_handle);
  }

  return send_res == kSuccess;
}

bool FlutterEmbedderNative::InvokePlatformMessageEmptyResponseCallback(
    int32_t response_id) {
  return InvokePlatformMessageResponseCallback(response_id, nullptr, 0);
}

bool FlutterEmbedderNative::InvokePlatformMessageResponseCallback(
    int32_t response_id,
    const uint8_t* response_data,
    size_t response_size) {
  TRACE_EVENT0("flutter",
               "FlutterEmbedderNative::InvokePlatformMessageResponseCallback");
  if (engine_ == nullptr ||
      proc_table_.SendPlatformMessageResponse == nullptr) {
    return false;
  }

  const FlutterPlatformMessageResponseHandle* handle = nullptr;
  {
    std::lock_guard<std::mutex> lock(response_mutex_);
    auto it = pending_engine_responses_.find(response_id);
    if (it == pending_engine_responses_.end()) {
      return false;
    }
    handle = it->second;
    pending_engine_responses_.erase(it);
  }

  const uint8_t* effective_data = response_data;

  FlutterEngineResult res = proc_table_.SendPlatformMessageResponse(
      engine_, handle, effective_data, response_size);
  return res == kSuccess;
}

bool FlutterEmbedderNative::DispatchPointerDataPacket(
    const uint8_t* packet_data,
    size_t packet_size) {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::DispatchPointerDataPacket");
  if (engine_ == nullptr || packet_data == nullptr || packet_size == 0) {
    return false;
  }
#if FLUTTER_HAS_ANDROID_WINDOW_METRICS_MAPPER
  return AndroidWindowMetricsMapper::DispatchPointerDataPacket(
             proc_table_, engine_, packet_data, packet_size) == kSuccess;
#else
  if (proc_table_.SendPointerEvent == nullptr) {
    return false;
  }
  FlutterPointerEvent event{};
  event.struct_size = sizeof(FlutterPointerEvent);
  return proc_table_.SendPointerEvent(engine_, &event, 1) == kSuccess;
#endif
}

bool FlutterEmbedderNative::DispatchSemanticsAction(int32_t node_id,
                                                    int32_t action,
                                                    const uint8_t* args_data,
                                                    size_t args_size) {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::DispatchSemanticsAction");
  if (engine_ == nullptr) {
    return false;
  }
#if FLUTTER_HAS_ANDROID_SEMANTICS_MAPPER
  return AndroidSemanticsMapper::DispatchSemanticsAction(
             proc_table_, engine_, static_cast<uint64_t>(node_id),
             static_cast<FlutterSemanticsAction>(action), args_data,
             args_size) == kSuccess;
#else
  if (proc_table_.SendSemanticsAction != nullptr) {
    FlutterSendSemanticsActionInfo info{};
    info.struct_size = sizeof(FlutterSendSemanticsActionInfo);
    info.view_id = 0;
    info.node_id = static_cast<uint64_t>(node_id);
    info.action = static_cast<FlutterSemanticsAction>(action);
    info.data = args_data;
    info.data_length = args_size;
    return proc_table_.SendSemanticsAction(engine_, &info) == kSuccess;
  }
  if (proc_table_.DispatchSemanticsAction != nullptr) {
    return proc_table_.DispatchSemanticsAction(
               engine_, static_cast<uint64_t>(node_id),
               static_cast<FlutterSemanticsAction>(action), args_data,
               args_size) == kSuccess;
  }
  return false;
#endif
}

bool FlutterEmbedderNative::SetSemanticsEnabled(bool enabled) {
  if (!is_using_mock_proc_table_ && jvm_invoker_) {
    jvm_invoker_->SetSemanticsTreeEnabled(enabled);
  }
  if (engine_ == nullptr || proc_table_.UpdateSemanticsEnabled == nullptr) {
    if (!is_using_mock_proc_table_ && engine_ == nullptr) {
      std::lock_guard<std::mutex> lock(pending_startup_mutex_);
      pending_semantics_enabled_ = enabled;
      return true;
    }
    return false;
  }
  return proc_table_.UpdateSemanticsEnabled(engine_, enabled) == kSuccess;
}

bool FlutterEmbedderNative::SetAccessibilityFeatures(int32_t flags) {
  if (engine_ == nullptr ||
      proc_table_.UpdateAccessibilityFeatures == nullptr) {
    if (!is_using_mock_proc_table_ && engine_ == nullptr) {
      std::lock_guard<std::mutex> lock(pending_startup_mutex_);
      pending_accessibility_features_ = flags;
      return true;
    }
    return false;
  }
  return proc_table_.UpdateAccessibilityFeatures(
             engine_, static_cast<FlutterAccessibilityFeature>(flags)) ==
         kSuccess;
}

bool FlutterEmbedderNative::RegisterTexture(int64_t texture_id,
                                            JNIEnv* env,
                                            jobject surface_texture_wrapper) {
  if (engine_ == nullptr || proc_table_.RegisterExternalTexture == nullptr) {
    return false;
  }
  if (!is_using_mock_proc_table_ && env != nullptr &&
      surface_texture_wrapper != nullptr && env->functions != nullptr &&
      env->functions->NewGlobalRef != nullptr) {
    std::lock_guard<std::mutex> lock(textures_mutex_);
    auto it = surface_textures_.find(texture_id);
    if (it != surface_textures_.end() &&
        it->second.wrapper_global_ref != nullptr &&
        env->functions->DeleteGlobalRef != nullptr) {
      env->DeleteGlobalRef(it->second.wrapper_global_ref);
    }
    SurfaceTextureEntry entry;
    entry.wrapper_global_ref = env->NewGlobalRef(surface_texture_wrapper);
    surface_textures_[texture_id] = std::move(entry);
  }
  return proc_table_.RegisterExternalTexture(engine_, texture_id) == kSuccess;
}

bool FlutterEmbedderNative::RegisterImageTexture(int64_t texture_id,
                                                 JNIEnv* env,
                                                 jobject image_texture_entry,
                                                 bool reset_on_background) {
  if (engine_ == nullptr || proc_table_.RegisterExternalTexture == nullptr) {
    return false;
  }
  if (!is_using_mock_proc_table_ && env != nullptr &&
      image_texture_entry != nullptr && env->functions != nullptr &&
      env->functions->NewGlobalRef != nullptr) {
    std::lock_guard<std::mutex> lock(textures_mutex_);
    auto it = image_textures_.find(texture_id);
    if (it != image_textures_.end() && it->second.entry_global_ref != nullptr &&
        env->functions->DeleteGlobalRef != nullptr) {
      env->DeleteGlobalRef(it->second.entry_global_ref);
    }
    ImageTextureEntry entry;
    entry.entry_global_ref = env->NewGlobalRef(image_texture_entry);
    entry.reset_on_background = reset_on_background;
    image_textures_[texture_id] = std::move(entry);
  }
  return proc_table_.RegisterExternalTexture(engine_, texture_id) == kSuccess;
}

bool FlutterEmbedderNative::MarkTextureFrameAvailable(int64_t texture_id) {
  if (engine_ == nullptr ||
      proc_table_.MarkExternalTextureFrameAvailable == nullptr) {
    return false;
  }
  return proc_table_.MarkExternalTextureFrameAvailable(engine_, texture_id) ==
         kSuccess;
}

bool FlutterEmbedderNative::UnregisterTexture(int64_t texture_id) {
  if (!is_using_mock_proc_table_) {
    JNIEnv* env = jvm_invoker_ ? jvm_invoker_->GetEnv() : nullptr;
    std::lock_guard<std::mutex> lock(textures_mutex_);
    auto st_it = surface_textures_.find(texture_id);
    if (st_it != surface_textures_.end()) {
      if (st_it->second.wrapper_global_ref != nullptr) {
#if FML_OS_ANDROID
        if (eglGetCurrentContext() != EGL_NO_CONTEXT) {
          if (st_it->second.attached && jvm_invoker_) {
            jvm_invoker_->SurfaceTextureDetachFromGLContext(
                st_it->second.wrapper_global_ref);
          }
          if (st_it->second.gl_texture_id != 0) {
            glDeleteTextures(1, &st_it->second.gl_texture_id);
          }
        }
#else
        if (st_it->second.attached && jvm_invoker_) {
          jvm_invoker_->SurfaceTextureDetachFromGLContext(
              st_it->second.wrapper_global_ref);
        }
#endif
        if (env != nullptr && env->functions != nullptr &&
            env->functions->DeleteGlobalRef != nullptr) {
          env->DeleteGlobalRef(st_it->second.wrapper_global_ref);
        }
      }
      if (surface_texture_blitter_) {
        surface_texture_blitter_->ReleaseTexture(texture_id);
      }
      surface_textures_.erase(st_it);
    }
    auto img_it = image_textures_.find(texture_id);
    if (img_it != image_textures_.end()) {
#if FML_OS_ANDROID
      if (img_it->second.egl_image != nullptr && egl_display_ != nullptr) {
        auto destroy_image_fn = reinterpret_cast<PFNEGLDESTROYIMAGEKHRPROC>(
            eglGetProcAddress("eglDestroyImageKHR"));
        if (destroy_image_fn != nullptr) {
          destroy_image_fn(static_cast<EGLDisplay>(egl_display_),
                           static_cast<EGLImageKHR>(img_it->second.egl_image));
        }
      }
      if (img_it->second.gl_texture_id != 0 &&
          eglGetCurrentContext() != EGL_NO_CONTEXT) {
        glDeleteTextures(1, &img_it->second.gl_texture_id);
      }
#endif
      if (img_it->second.entry_global_ref != nullptr && env != nullptr &&
          env->functions != nullptr &&
          env->functions->DeleteGlobalRef != nullptr) {
        env->DeleteGlobalRef(img_it->second.entry_global_ref);
      }
      image_textures_.erase(img_it);
    }
  }
  if (engine_ == nullptr || proc_table_.UnregisterExternalTexture == nullptr) {
    return false;
  }
  return proc_table_.UnregisterExternalTexture(engine_, texture_id) == kSuccess;
}

bool FlutterEmbedderNative::ScheduleFrame() {
  if (engine_ == nullptr || proc_table_.ScheduleFrame == nullptr) {
    return false;
  }
  if (!is_using_mock_proc_table_ &&
      proc_table_.MarkExternalTextureFrameAvailable != nullptr) {
    std::vector<int64_t> texture_ids;
    {
      std::lock_guard<std::mutex> lock(textures_mutex_);
      texture_ids.reserve(surface_textures_.size() + image_textures_.size());
      for (const auto& [id, _] : surface_textures_) {
        texture_ids.push_back(id);
      }
      for (const auto& [id, _] : image_textures_) {
        texture_ids.push_back(id);
      }
    }
    for (int64_t id : texture_ids) {
      proc_table_.MarkExternalTextureFrameAvailable(engine_, id);
    }
  }
  return proc_table_.ScheduleFrame(engine_) == kSuccess;
}

bool FlutterEmbedderNative::NotifyLowMemoryWarning() {
  if (!is_using_mock_proc_table_) {
    std::lock_guard<std::mutex> lock(textures_mutex_);
    for (auto& [id, entry] : image_textures_) {
      if (entry.reset_on_background) {
#if FML_OS_ANDROID
        if (entry.egl_image != nullptr && egl_display_ != nullptr) {
          auto destroy_image_fn = reinterpret_cast<PFNEGLDESTROYIMAGEKHRPROC>(
              eglGetProcAddress("eglDestroyImageKHR"));
          if (destroy_image_fn != nullptr) {
            destroy_image_fn(static_cast<EGLDisplay>(egl_display_),
                             static_cast<EGLImageKHR>(entry.egl_image));
          }
          entry.egl_image = nullptr;
        }
        if (entry.gl_texture_id != 0) {
          if (eglGetCurrentContext() != EGL_NO_CONTEXT) {
            glDeleteTextures(1, &entry.gl_texture_id);
          }
          entry.gl_texture_id = 0;
        }
#endif
        entry.last_ahb.reset();
        entry.last_vulkan_texture.reset();
      }
    }
  }
  if (engine_ == nullptr || proc_table_.NotifyLowMemoryWarning == nullptr) {
    return false;
  }
  return proc_table_.NotifyLowMemoryWarning(engine_) == kSuccess;
}

bool FlutterEmbedderNative::LoadDartDeferredLibrary(
    int32_t loading_unit_id,
    const std::vector<std::string>& search_paths) {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::LoadDartDeferredLibrary");
  if (engine_ == nullptr || proc_table_.LoadDartDeferredLibrary == nullptr) {
    return false;
  }

#if FML_OS_ANDROID
  if (!is_using_mock_proc_table_ && !search_paths.empty()) {
    void* handle = nullptr;
    for (const auto& path : search_paths) {
      handle = ::dlopen(path.c_str(), RTLD_NOW);
      if (handle != nullptr) {
        break;
      }
    }
    if (handle == nullptr) {
      return NotifyDartDeferredLibraryLoadError(
          loading_unit_id, "No lib .so found for provided search paths.", true);
    }
    fml::RefPtr<fml::NativeLibrary> native_lib =
        fml::NativeLibrary::CreateWithHandle(handle, false);
    auto* holder = new DeferredLibraryMappingHolder();
    holder->data_mapping =
        std::make_unique<fml::SymbolMapping>(native_lib, "kDartSnapshotData");
    holder->instructions_mapping =
        std::make_unique<fml::SymbolMapping>(native_lib, "kDartSnapshotText");

    FlutterDartDeferredLibrary library{};
    library.struct_size = sizeof(FlutterDartDeferredLibrary);
    library.loading_unit_id = static_cast<intptr_t>(loading_unit_id);
    library.snapshot_data = holder->data_mapping->GetMapping();
    library.snapshot_data_size = holder->data_mapping->GetSize();
    library.snapshot_instructions = holder->instructions_mapping->GetMapping();
    library.snapshot_instructions_size =
        holder->instructions_mapping->GetSize();
    library.user_data = holder;
    library.destruction_callback = &DestroyDeferredLibraryMappingHolder;

    FlutterEngineResult result =
        proc_table_.LoadDartDeferredLibrary(engine_, &library);
    if (result != kSuccess) {
      delete holder;
      return false;
    }
    return true;
  }
#else
  (void)search_paths;
#endif

  auto* holder = new DeferredLibraryMappingHolder();
  FlutterDartDeferredLibrary library{};
  library.struct_size = sizeof(FlutterDartDeferredLibrary);
  library.loading_unit_id = static_cast<intptr_t>(loading_unit_id);
  library.snapshot_data = nullptr;
  library.snapshot_data_size = 0;
  library.snapshot_instructions = nullptr;
  library.snapshot_instructions_size = 0;
  library.user_data = holder;
  library.destruction_callback = &DestroyDeferredLibraryMappingHolder;

  FlutterEngineResult result =
      proc_table_.LoadDartDeferredLibrary(engine_, &library);
  if (result != kSuccess) {
    delete holder;
    return false;
  }
  return true;
}

bool FlutterEmbedderNative::NotifyDartDeferredLibraryLoadError(
    int32_t loading_unit_id,
    const std::string& error_message,
    bool is_transient) {
  TRACE_EVENT0("flutter",
               "FlutterEmbedderNative::NotifyDartDeferredLibraryLoadError");
  if (engine_ == nullptr ||
      proc_table_.NotifyDartDeferredLibraryLoadError == nullptr) {
    return false;
  }
  FlutterDartDeferredLibraryLoadError error{};
  error.struct_size = sizeof(FlutterDartDeferredLibraryLoadError);
  error.loading_unit_id = static_cast<intptr_t>(loading_unit_id);
  error.error_message = error_message.c_str();
  error.transient = is_transient;

  return proc_table_.NotifyDartDeferredLibraryLoadError(engine_, &error) ==
         kSuccess;
}

// =============================================================================
// Static C-API Callbacks
// =============================================================================

bool FlutterEmbedderNative::OnResolveRendererConfigCallback(
    void* user_data,
    FlutterRendererConfig* config_out) {
  if (!user_data || !config_out) {
    return false;
  }
  return static_cast<FlutterEmbedderNative*>(user_data)->ResolveRendererConfig(
      config_out);
}

bool FlutterEmbedderNative::ResolveRendererConfig(
    FlutterRendererConfig* config_out) {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::ResolveRendererConfig");
  auto vm_args = AndroidVMInit::GetGlobalVMArgs().value_or(AndroidVMArgs{});
  vm_args.api_level = ResolveEffectiveApiLevel(vm_args);
  AndroidRenderingAPI api = SelectRenderingAPI(vm_args);

  std::memset(config_out, 0, sizeof(FlutterRendererConfig));
  if (api == AndroidRenderingAPI::kSoftware ||
      vm_args.enable_software_rendering) {
    config_out->type = kSoftware;
    config_out->software.struct_size = sizeof(FlutterSoftwareRendererConfig);
    config_out->software.surface_present_callback =
        [](void* user_data, const void* allocation, size_t row_bytes,
           size_t height) -> bool {
      return user_data != nullptr &&
             static_cast<FlutterEmbedderNative*>(user_data)
                 ->PresentAndroidSoftware(allocation, row_bytes, height);
    };
    return true;
  }
  if (api == AndroidRenderingAPI::kImpellerVulkan) {
    if (is_using_mock_proc_table_) {
      config_out->type = kVulkan;
      config_out->vulkan.struct_size = sizeof(FlutterVulkanRendererConfig);
      config_out->vulkan.version = kDefaultVulkanApiVersion;
      config_out->vulkan.external_texture_frame_callback =
          &FlutterEmbedderNative::OnVulkanExternalTextureFrameCallback;
      return true;
    }
#if FLUTTER_HAS_ANDROID_SURFACE_CONTROL
    if (surface_control_ &&
        surface_control_->ResolveRendererConfig(config_out)) {
      if (config_out->type == kVulkan) {
        if (vk_texture_provider_) {
          vk_texture_provider_->SetVulkanDevice(
              surface_control_->GetVulkanDevice());
        }
        config_out->vulkan.get_instance_proc_address_callback =
            [](void* user_data, FlutterVulkanInstanceHandle instance,
               const char* name) -> void* {
          auto* self = static_cast<FlutterEmbedderNative*>(user_data);
          return (self && self->surface_control_)
                     ? AndroidSurfaceControl::GetInstanceProcAddressCallback(
                           self->surface_control_.get(), instance, name)
                     : nullptr;
        };
        config_out->vulkan.get_next_image_callback =
            [](void* user_data,
               const FlutterFrameInfo* frame_info) -> FlutterVulkanImage {
          auto* self = static_cast<FlutterEmbedderNative*>(user_data);
          if (!self || !self->surface_control_) {
            FlutterVulkanImage empty{};
            empty.struct_size = sizeof(FlutterVulkanImage);
            return empty;
          }
          return AndroidSurfaceControl::GetNextImageCallback(
              self->surface_control_.get(), frame_info);
        };
        config_out->vulkan.present_image_callback =
            [](void* user_data, const FlutterVulkanImage* image) -> bool {
          auto* self = static_cast<FlutterEmbedderNative*>(user_data);
          if (!self || !self->surface_control_) {
            return false;
          }
          bool ok = AndroidSurfaceControl::PresentImageCallback(
              self->surface_control_.get(), image);
          if (ok) {
            self->NotifyFirstFramePresented();
          }
          return ok;
        };
        config_out->vulkan.external_texture_frame_callback =
            &FlutterEmbedderNative::OnVulkanExternalTextureFrameCallback;
        return true;
      }
      // Vulkan autoselection fell back to OpenGL ES on the raster thread;
      // initialize our real EGL context and fall through to kOpenGL setup.
      InitializeAndroidEGL();
      void* current_window = nullptr;
      {
        std::lock_guard<std::mutex> window_lock(native_window_mutex_);
        current_window = native_window_;
      }
      if (current_window != nullptr && egl_window_surface_ == nullptr) {
        CreateOrUpdateAndroidWindowSurface(current_window);
      }
    }
#endif
  }

  if (!is_using_mock_proc_table_ && egl_display_ == nullptr) {
    InitializeAndroidEGL();
    void* current_window = nullptr;
    {
      std::lock_guard<std::mutex> window_lock(native_window_mutex_);
      current_window = native_window_;
    }
    if (current_window != nullptr && egl_window_surface_ == nullptr) {
      CreateOrUpdateAndroidWindowSurface(current_window);
    }
  }

  std::memset(config_out, 0, sizeof(FlutterRendererConfig));
  config_out->type = kOpenGL;
  config_out->open_gl.struct_size = sizeof(FlutterOpenGLRendererConfig);
  if (is_using_mock_proc_table_) {
    config_out->open_gl.make_current = &NoOpMakeCurrent;
    config_out->open_gl.clear_current = &NoOpClearCurrent;
    config_out->open_gl.present = &NoOpPresent;
    config_out->open_gl.fbo_callback = &NoOpFboCallback;
    config_out->open_gl.make_resource_current = &NoOpMakeCurrent;
  } else {
    config_out->open_gl.make_current = [](void* user_data) -> bool {
      return user_data != nullptr &&
             static_cast<FlutterEmbedderNative*>(user_data)
                 ->MakeAndroidEGLCurrent();
    };
    config_out->open_gl.clear_current = [](void* user_data) -> bool {
      return user_data != nullptr &&
             static_cast<FlutterEmbedderNative*>(user_data)
                 ->ClearAndroidEGLCurrent();
    };
    config_out->open_gl.present = [](void* user_data) -> bool {
      return user_data != nullptr &&
             static_cast<FlutterEmbedderNative*>(user_data)
                 ->PresentAndroidEGL();
    };
    config_out->open_gl.fbo_callback = &NoOpFboCallback;
    config_out->open_gl.make_resource_current = [](void* user_data) -> bool {
      return user_data != nullptr &&
             static_cast<FlutterEmbedderNative*>(user_data)
                 ->MakeAndroidEGLResourceCurrent();
    };
    config_out->open_gl.gl_proc_resolver = &ResolveAndroidGLProcAddress;
  }
  config_out->open_gl.fbo_reset_after_present = true;
  config_out->open_gl.external_texture_frame_callback =
      &FlutterEmbedderNative::OnExternalTextureFrameCallback;
  return true;
}

void FlutterEmbedderNative::OnPlatformMessageCallback(
    const FlutterPlatformMessage* message,
    void* user_data) {
  if (!user_data || !message) {
    return;
  }
  static_cast<FlutterEmbedderNative*>(user_data)
      ->HandlePlatformMessageFromEngine(message);
}

void FlutterEmbedderNative::HandlePlatformMessageFromEngine(
    const FlutterPlatformMessage* message) {
  TRACE_EVENT0("flutter",
               "FlutterEmbedderNative::HandlePlatformMessageFromEngine");
  int32_t response_id = 0;
  if (message->response_handle != nullptr) {
    std::lock_guard<std::mutex> lock(response_mutex_);
    response_id = next_engine_response_id_++;
    pending_engine_responses_[response_id] = message->response_handle;
  }

  if (jvm_invoker_) {
    const uint8_t* payload_ptr = message->message;
    // Preserve non-null zero-byte payloads (&kEmptyByte) so JvmInvoker
    // allocates a 0-capacity ByteBuffer instead of passing null.
    if (message->message != nullptr && message->message_size == 0) {
      payload_ptr = &kEmptyByte;
    }
    jvm_invoker_->HandlePlatformMessage(
        message->channel ? message->channel : "", payload_ptr,
        message->message_size, response_id, 0);
  }
}

void FlutterEmbedderNative::OnUpdateSemanticsCallback(
    const FlutterSemanticsUpdate2* update,
    void* user_data) {
  if (!user_data || !update) {
    return;
  }
  static_cast<FlutterEmbedderNative*>(user_data)
      ->HandleSemanticsUpdateFromEngine(update);
}

void FlutterEmbedderNative::HandleSemanticsUpdateFromEngine(
    const FlutterSemanticsUpdate2* update) {
  TRACE_EVENT0("flutter",
               "FlutterEmbedderNative::HandleSemanticsUpdateFromEngine");
  if (!jvm_invoker_) {
    return;
  }
  if (!is_using_mock_proc_table_ && update != nullptr &&
      update->nodes != nullptr) {
    for (size_t i = 0; i < update->node_count; ++i) {
      const FlutterSemanticsNode2* node = update->nodes[i];
      if (node != nullptr && node->locale != nullptr &&
          node->locale[0] != '\0') {
        jvm_invoker_->SetApplicationLocale(node->locale);
        break;
      }
    }
  }
#if FLUTTER_HAS_ANDROID_SEMANTICS_MAPPER
  MappedSemanticsUpdate mapped = AndroidSemanticsMapper::MapUpdate(update);
  if (!mapped.nodes.buffer.empty() || update->node_count > 0) {
    jvm_invoker_->UpdateSemantics(mapped.nodes.buffer, mapped.nodes.strings,
                                  mapped.nodes.string_attribute_args);
  }
  if (!mapped.actions.buffer.empty() || update->custom_action_count > 0) {
    jvm_invoker_->UpdateCustomAccessibilityActions(mapped.actions.buffer,
                                                   mapped.actions.strings);
  }
#endif
}

void FlutterEmbedderNative::OnVsyncCallback(void* user_data, intptr_t baton) {
  if (!user_data) {
    return;
  }
  auto* embedder = static_cast<FlutterEmbedderNative*>(user_data);
  if (embedder->vsync_waiter_) {
    embedder->vsync_waiter_->AsyncWaitForVsync(baton);
  }
}

void FlutterEmbedderNative::OnRequestDartDeferredLibraryCallback(
    intptr_t loading_unit_id,
    void* user_data) {
  if (!user_data) {
    return;
  }
  auto* embedder = static_cast<FlutterEmbedderNative*>(user_data);
  if (embedder->jvm_invoker_) {
    embedder->jvm_invoker_->RequestDartDeferredLibrary(
        static_cast<int32_t>(loading_unit_id));
  }
}

bool FlutterEmbedderNative::OnScaleFontSizeCallback(
    const FlutterScaleFontSizeInfo* info,
    double* scaled_font_size_out,
    void* user_data) {
  if (!info || !scaled_font_size_out || !user_data) {
    return false;
  }
  auto* embedder = static_cast<FlutterEmbedderNative*>(user_data);
  if (!embedder->jvm_invoker_) {
    return false;
  }
  float scaled = embedder->jvm_invoker_->GetScaledFontSize(
      static_cast<float>(info->font_size),
      static_cast<int32_t>(info->text_scale_factor));
  if (scaled < 0.0f) {
    return false;
  }
  *scaled_font_size_out = static_cast<double>(scaled);
  return true;
}

const FlutterLocale*
FlutterEmbedderNative::OnComputePlatformResolvedLocaleCallback(
    const FlutterLocale** supported_locales,
    size_t number_of_locales) {
  if (supported_locales == nullptr || number_of_locales == 0) {
    return nullptr;
  }
  return supported_locales[0];
}

void FlutterEmbedderNative::OnPreEngineRestartCallback(void* user_data) {
  if (!user_data) {
    return;
  }
  auto* embedder = static_cast<FlutterEmbedderNative*>(user_data);
  if (embedder->jvm_invoker_) {
    embedder->jvm_invoker_->OnPreEngineRestart();
  }
}

void FlutterEmbedderNative::OnLogMessageCallback(const char* tag,
                                                 const char* message,
                                                 void* user_data) {
  (void)user_data;
  const char* safe_tag = (tag && tag[0] != '\0') ? tag : "flutter";
  const char* safe_msg = message ? message : "";
#if FML_OS_ANDROID
  __android_log_print(ANDROID_LOG_INFO, safe_tag, "%s", safe_msg);
#else
  FML_LOG(INFO) << "[" << safe_tag << "] " << safe_msg;
#endif
}

bool FlutterEmbedderNative::OnCreateImageDecoderCallback(
    void* user_data,
    const uint8_t* data,
    size_t data_size,
    FlutterImageDecoder* decoder_out) {
  (void)user_data;
  if (data == nullptr || data_size == 0 || decoder_out == nullptr) {
    return false;
  }
  return false;
}

bool FlutterEmbedderNative::OnExternalTextureFrameCallback(
    void* user_data,
    int64_t texture_id,
    size_t width,
    size_t height,
    FlutterOpenGLExternalTexture* texture_out) {
  if (!texture_out) {
    return false;
  }
  auto* self = static_cast<FlutterEmbedderNative*>(user_data);
  if (self != nullptr && !self->is_using_mock_proc_table_) {
    return self->AcquireOpenGLExternalTextureFrame(texture_id, width, height,
                                                   texture_out);
  }
  *texture_out = {};
  texture_out->struct_size = sizeof(FlutterOpenGLExternalTexture);
  texture_out->width = width;
  texture_out->height = height;
  return true;
}

bool FlutterEmbedderNative::OnVulkanExternalTextureFrameCallback(
    void* user_data,
    int64_t texture_id,
    size_t width,
    size_t height,
    FlutterVulkanExternalTexture* texture_out) {
  if (!texture_out) {
    return false;
  }
  auto* self = static_cast<FlutterEmbedderNative*>(user_data);
  if (self != nullptr && !self->is_using_mock_proc_table_) {
    return self->AcquireVulkanExternalTextureFrame(texture_id, width, height,
                                                   texture_out);
  }
  *texture_out = {};
  texture_out->struct_size = sizeof(FlutterVulkanExternalTexture);
  texture_out->width = width;
  texture_out->height = height;
  return true;
}

bool FlutterEmbedderNative::AcquireOpenGLExternalTextureFrame(
    int64_t texture_id,
    size_t width,
    size_t height,
    FlutterOpenGLExternalTexture* texture_out) {
  if (!texture_out || !jvm_invoker_) {
    return false;
  }
  std::lock_guard<std::mutex> lock(textures_mutex_);
  auto st_it = surface_textures_.find(texture_id);
  if (st_it != surface_textures_.end() &&
      st_it->second.wrapper_global_ref != nullptr) {
    auto& entry = st_it->second;
    if (!entry.attached) {
#if FML_OS_ANDROID
      glGenTextures(1, &entry.gl_texture_id);
#else
      entry.gl_texture_id = 1;
#endif
      jvm_invoker_->SurfaceTextureAttachToGLContext(
          entry.wrapper_global_ref, static_cast<int32_t>(entry.gl_texture_id));
      entry.attached = true;
    }
    jvm_invoker_->SurfaceTextureUpdateTexImage(entry.wrapper_global_ref);
    // 4x4 column-major identity matrix diagonal element indices.
    constexpr size_t kUvMatrixDiag0Index = 0;
    constexpr size_t kUvMatrixDiag1Index = 5;
    constexpr size_t kUvMatrixDiag2Index = 10;
    constexpr size_t kUvMatrixDiag3Index = 15;
    float uv_matrix[android::kOpenGLUvTransformMatrixElementCount] = {};
    uv_matrix[kUvMatrixDiag0Index] = 1.0f;
    uv_matrix[kUvMatrixDiag1Index] = 1.0f;
    uv_matrix[kUvMatrixDiag2Index] = 1.0f;
    uv_matrix[kUvMatrixDiag3Index] = 1.0f;
    jvm_invoker_->SurfaceTextureGetTransformMatrix(entry.wrapper_global_ref,
                                                   uv_matrix);
    return PopulateFlutterOpenGLExternalTextureFromSurfaceTexture(
        entry.gl_texture_id, width, height, uv_matrix, texture_out);
  }

  auto img_it = image_textures_.find(texture_id);
  if (img_it != image_textures_.end() &&
      img_it->second.entry_global_ref != nullptr) {
    auto& entry = img_it->second;
    JNIEnv* env = jvm_invoker_->GetEnv();
    jobject j_image = jvm_invoker_->ImageTextureEntryAcquireLatestImage(
        entry.entry_global_ref);
    if (j_image != nullptr && env != nullptr) {
      jobject j_hb = jvm_invoker_->ImageGetHardwareBuffer(j_image);
      if (j_hb != nullptr && ahb_provider_) {
        auto ahb = ahb_provider_->CreateFromJavaHardwareBuffer(env, j_hb);
        if (ahb && ahb->IsValid()) {
          const bool need_reimport =
              !entry.last_ahb || entry.egl_image == nullptr ||
              entry.gl_texture_id == 0 || ahb->GetId() == 0 ||
              ahb->GetId() != entry.last_ahb->GetId();
          if (need_reimport) {
            entry.last_ahb = std::move(ahb);
#if FML_OS_ANDROID
            if (egl_display_ != nullptr) {
              auto create_image_fn = reinterpret_cast<PFNEGLCREATEIMAGEKHRPROC>(
                  eglGetProcAddress("eglCreateImageKHR"));
              auto destroy_image_fn =
                  reinterpret_cast<PFNEGLDESTROYIMAGEKHRPROC>(
                      eglGetProcAddress("eglDestroyImageKHR"));
              auto get_native_client_buffer_fn =
                  reinterpret_cast<PFNEGLGETNATIVECLIENTBUFFERANDROIDPROC>(
                      eglGetProcAddress("eglGetNativeClientBufferANDROID"));
              auto image_target_tex_fn =
                  reinterpret_cast<PFNGLEGLIMAGETARGETTEXTURE2DOESPROC>(
                      eglGetProcAddress("glEGLImageTargetTexture2DOES"));
              if (create_image_fn && get_native_client_buffer_fn &&
                  image_target_tex_fn) {
                EGLClientBuffer client_buf = get_native_client_buffer_fn(
                    static_cast<const AHardwareBuffer*>(
                        entry.last_ahb->GetHandle()));
                if (client_buf != nullptr) {
                  if (entry.egl_image != nullptr &&
                      destroy_image_fn != nullptr) {
                    destroy_image_fn(static_cast<EGLDisplay>(egl_display_),
                                     static_cast<EGLImageKHR>(entry.egl_image));
                    entry.egl_image = nullptr;
                  }
                  // EGL_IMAGE_PRESERVED_KHR = 0x30D2,
                  // EGL_NATIVE_BUFFER_ANDROID = 0x3140.
                  constexpr EGLint kEglImagePreservedAttr = 0x30D2;
                  constexpr EGLenum kEglNativeBufferAndroidTarget = 0x3140;
                  const EGLint image_attribs[] = {
                      kEglImagePreservedAttr,
                      EGL_TRUE,
                      EGL_NONE,
                  };
                  EGLImageKHR egl_img = create_image_fn(
                      static_cast<EGLDisplay>(egl_display_), EGL_NO_CONTEXT,
                      kEglNativeBufferAndroidTarget, client_buf, image_attribs);
                  if (egl_img != EGL_NO_IMAGE_KHR) {
                    entry.egl_image = egl_img;
                    if (entry.gl_texture_id == 0) {
                      glGenTextures(1, &entry.gl_texture_id);
                    }
                    // GL_TEXTURE_EXTERNAL_OES (0x8D65) and
                    // GL_TEXTURE_BINDING_EXTERNAL_OES (0x8D67) from
                    // <GLES2/gl2ext.h>.
                    constexpr GLenum kGlTextureExternalOes = 0x8D65;
                    constexpr GLenum kGlTextureBindingExternalOes = 0x8D67;
                    GLint prev_tex = 0;
                    glGetIntegerv(kGlTextureBindingExternalOes, &prev_tex);
                    glBindTexture(kGlTextureExternalOes, entry.gl_texture_id);
                    glTexParameteri(kGlTextureExternalOes,
                                    GL_TEXTURE_MIN_FILTER, GL_LINEAR);
                    glTexParameteri(kGlTextureExternalOes,
                                    GL_TEXTURE_MAG_FILTER, GL_LINEAR);
                    glTexParameteri(kGlTextureExternalOes, GL_TEXTURE_WRAP_S,
                                    GL_CLAMP_TO_EDGE);
                    glTexParameteri(kGlTextureExternalOes, GL_TEXTURE_WRAP_T,
                                    GL_CLAMP_TO_EDGE);
                    image_target_tex_fn(
                        kGlTextureExternalOes,
                        static_cast<GLeglImageOES>(entry.egl_image));
                    glBindTexture(kGlTextureExternalOes,
                                  static_cast<GLuint>(prev_tex));
                  }
                }
              }
            }
#endif
          }
        }
        jvm_invoker_->HardwareBufferClose(j_hb);
        if (env->functions && env->functions->DeleteLocalRef) {
          env->DeleteLocalRef(j_hb);
        }
      }
      if (env->functions && env->functions->DeleteLocalRef) {
        env->DeleteLocalRef(j_image);
      }
    }
    if (entry.last_ahb && entry.gl_texture_id != 0) {
      return PopulateFlutterOpenGLExternalTextureFromHardwareBuffer(
          entry.last_ahb.get(), entry.gl_texture_id, texture_out);
    }
  }
  return false;
}

bool FlutterEmbedderNative::AcquireVulkanExternalTextureFrame(
    int64_t texture_id,
    size_t width,
    size_t height,
    FlutterVulkanExternalTexture* texture_out) {
  if (!texture_out || !jvm_invoker_) {
    return false;
  }
  struct VulkanTextureReleaseContext {
    std::shared_ptr<android::AndroidVulkanExternalTexture> vk_texture;
    std::shared_ptr<android::AndroidHardwareBuffer> ahb;
  };
  std::lock_guard<std::mutex> lock(textures_mutex_);
#if FLUTTER_HAS_ANDROID_SURFACE_CONTROL
  if (vk_texture_provider_ && surface_control_ &&
      vk_texture_provider_->GetVulkanDevice() == nullptr &&
      surface_control_->GetVulkanDevice() != nullptr) {
    vk_texture_provider_->SetVulkanDevice(surface_control_->GetVulkanDevice());
  }
#endif

  auto st_it = surface_textures_.find(texture_id);
  if (st_it != surface_textures_.end() &&
      st_it->second.wrapper_global_ref != nullptr && surface_texture_blitter_) {
    auto& entry = st_it->second;
    if (!entry.attached || !entry.last_vulkan_texture ||
        !entry.last_vulkan_texture->IsValid() ||
        jvm_invoker_->SurfaceTextureShouldUpdate(entry.wrapper_global_ref)) {
      surface_texture_blitter_->MakeEglContextCurrent();
      if (!entry.attached) {
#if FML_OS_ANDROID
        glGenTextures(1, &entry.gl_texture_id);
#else
        entry.gl_texture_id = 1;
#endif
        jvm_invoker_->SurfaceTextureAttachToGLContext(
            entry.wrapper_global_ref,
            static_cast<int32_t>(entry.gl_texture_id));
        entry.attached = true;
      }
      jvm_invoker_->SurfaceTextureUpdateTexImage(entry.wrapper_global_ref);
      if (entry.gl_texture_id != 0) {
        constexpr size_t kUvMatrixDiag0Index = 0;
        constexpr size_t kUvMatrixDiag1Index = 5;
        constexpr size_t kUvMatrixDiag2Index = 10;
        constexpr size_t kUvMatrixDiag3Index = 15;
        float uv_matrix[android::kOpenGLUvTransformMatrixElementCount] = {};
        uv_matrix[kUvMatrixDiag0Index] = 1.0f;
        uv_matrix[kUvMatrixDiag1Index] = 1.0f;
        uv_matrix[kUvMatrixDiag2Index] = 1.0f;
        uv_matrix[kUvMatrixDiag3Index] = 1.0f;
        jvm_invoker_->SurfaceTextureGetTransformMatrix(entry.wrapper_global_ref,
                                                       uv_matrix);
        auto vk_tex = surface_texture_blitter_->BlitAndImport(
            texture_id, entry.gl_texture_id, width, height, uv_matrix);
        if (vk_tex && vk_tex->IsValid()) {
          entry.last_vulkan_texture = std::move(vk_tex);
        }
      }
      surface_texture_blitter_->ClearEglContextCurrent();
    }
    if (entry.last_vulkan_texture && entry.last_vulkan_texture->IsValid()) {
      auto* release_ctx =
          new VulkanTextureReleaseContext{entry.last_vulkan_texture, nullptr};
      if (!entry.last_vulkan_texture->PopulateExternalTexture(
              texture_out, release_ctx, [](void* user_data) {
                delete static_cast<VulkanTextureReleaseContext*>(user_data);
              })) {
        delete release_ctx;
        return false;
      }
      return true;
    }
    return false;
  }

  auto img_it = image_textures_.find(texture_id);
  if (img_it != image_textures_.end() &&
      img_it->second.entry_global_ref != nullptr && vk_texture_provider_) {
    auto& entry = img_it->second;
    JNIEnv* env = jvm_invoker_->GetEnv();
    jobject j_image = jvm_invoker_->ImageTextureEntryAcquireLatestImage(
        entry.entry_global_ref);
    if (j_image != nullptr && env != nullptr) {
      jobject j_hb = jvm_invoker_->ImageGetHardwareBuffer(j_image);
      if (j_hb != nullptr && ahb_provider_) {
        auto ahb = ahb_provider_->CreateFromJavaHardwareBuffer(env, j_hb);
        if (ahb && ahb->IsValid()) {
          const bool need_reimport =
              !entry.last_ahb || !entry.last_vulkan_texture ||
              !entry.last_vulkan_texture->IsValid() || ahb->GetId() == 0 ||
              ahb->GetId() != entry.last_ahb->GetId();
          if (need_reimport) {
            auto vk_tex =
                vk_texture_provider_->CreateFromAHardwareBuffer(ahb.get());
            if (vk_tex && vk_tex->IsValid()) {
              entry.last_ahb = std::move(ahb);
              entry.last_vulkan_texture = std::move(vk_tex);
            }
          }
        }
        jvm_invoker_->HardwareBufferClose(j_hb);
        if (env->functions && env->functions->DeleteLocalRef) {
          env->DeleteLocalRef(j_hb);
        }
      }
      if (env->functions && env->functions->DeleteLocalRef) {
        env->DeleteLocalRef(j_image);
      }
    }
    if (entry.last_vulkan_texture && entry.last_vulkan_texture->IsValid()) {
      auto* release_ctx = new VulkanTextureReleaseContext{
          entry.last_vulkan_texture, entry.last_ahb};
      if (!entry.last_vulkan_texture->PopulateExternalTexture(
              texture_out, release_ctx, [](void* user_data) {
                delete static_cast<VulkanTextureReleaseContext*>(user_data);
              })) {
        delete release_ctx;
        return false;
      }
      return true;
    }
  }
  return false;
}

void FlutterEmbedderNative::ReleaseAllTextures() {
  JNIEnv* env = jvm_invoker_ ? jvm_invoker_->GetEnv() : nullptr;
  std::lock_guard<std::mutex> lock(textures_mutex_);
  for (auto& [id, entry] : surface_textures_) {
    if (entry.wrapper_global_ref != nullptr) {
#if FML_OS_ANDROID
      if (eglGetCurrentContext() != EGL_NO_CONTEXT) {
        if (entry.attached && jvm_invoker_) {
          jvm_invoker_->SurfaceTextureDetachFromGLContext(
              entry.wrapper_global_ref);
        }
        if (entry.gl_texture_id != 0) {
          glDeleteTextures(1, &entry.gl_texture_id);
        }
      }
#else
      if (entry.attached && jvm_invoker_) {
        jvm_invoker_->SurfaceTextureDetachFromGLContext(
            entry.wrapper_global_ref);
      }
#endif
      if (env != nullptr && env->functions != nullptr &&
          env->functions->DeleteGlobalRef != nullptr) {
        env->DeleteGlobalRef(entry.wrapper_global_ref);
      }
    }
    if (surface_texture_blitter_) {
      surface_texture_blitter_->ReleaseTexture(id);
    }
  }
  surface_textures_.clear();

  for (auto& [id, entry] : image_textures_) {
#if FML_OS_ANDROID
    if (entry.egl_image != nullptr && egl_display_ != nullptr) {
      auto destroy_image_fn = reinterpret_cast<PFNEGLDESTROYIMAGEKHRPROC>(
          eglGetProcAddress("eglDestroyImageKHR"));
      if (destroy_image_fn != nullptr) {
        destroy_image_fn(static_cast<EGLDisplay>(egl_display_),
                         static_cast<EGLImageKHR>(entry.egl_image));
      }
    }
    if (entry.gl_texture_id != 0 && eglGetCurrentContext() != EGL_NO_CONTEXT) {
      glDeleteTextures(1, &entry.gl_texture_id);
    }
#endif
    if (entry.entry_global_ref != nullptr && env != nullptr &&
        env->functions != nullptr &&
        env->functions->DeleteGlobalRef != nullptr) {
      env->DeleteGlobalRef(entry.entry_global_ref);
    }
  }
  image_textures_.clear();
}

bool FlutterEmbedderNative::InitializeAndroidEGL() {
#if FML_OS_ANDROID
  std::lock_guard<std::mutex> lock(egl_mutex_);
  if (egl_display_ != nullptr && egl_context_ != nullptr) {
    return true;
  }
  EGLDisplay display = eglGetDisplay(EGL_DEFAULT_DISPLAY);
  if (display == EGL_NO_DISPLAY) {
    return false;
  }
  if (!eglInitialize(display, nullptr, nullptr)) {
    return false;
  }

  auto choose_egl_config = [display](EGLint renderable_type,
                                     EGLint surface_type,
                                     EGLint samples) -> EGLConfig {
    std::vector<EGLint> attribs = {
        EGL_RENDERABLE_TYPE, renderable_type, EGL_SURFACE_TYPE, surface_type,
        EGL_RED_SIZE,        kEglChannelBits, EGL_GREEN_SIZE,   kEglChannelBits,
        EGL_BLUE_SIZE,       kEglChannelBits, EGL_ALPHA_SIZE,   kEglChannelBits,
        EGL_DEPTH_SIZE,      kEglDepthBits,   EGL_STENCIL_SIZE, kEglStencilBits,
    };
    if (samples > kEglSingleSample) {
      attribs.push_back(EGL_SAMPLE_BUFFERS);
      attribs.push_back(kEglMsaaSampleBuffers);
      attribs.push_back(EGL_SAMPLES);
      attribs.push_back(samples);
    }
    attribs.push_back(EGL_NONE);
    EGLConfig out_config = nullptr;
    EGLint num_configs = 0;
    if (eglChooseConfig(display, attribs.data(), &out_config, 1,
                        &num_configs) == EGL_TRUE &&
        num_configs >= 1) {
      return out_config;
    }
    return nullptr;
  };

  EGLint renderable_type = kEglOpenGlEs3Bit;
  EGLint client_version = kEglClientVersion3;
  EGLint chosen_samples = kEglMsaaSamples4;
  EGLConfig config =
      choose_egl_config(renderable_type, EGL_WINDOW_BIT, chosen_samples);
  if (config == nullptr) {
    renderable_type = EGL_OPENGL_ES2_BIT;
    client_version = kEglClientVersion2;
    config = choose_egl_config(renderable_type, EGL_WINDOW_BIT, chosen_samples);
  }
  if (config == nullptr) {
    chosen_samples = kEglSingleSample;
    renderable_type = kEglOpenGlEs3Bit;
    client_version = kEglClientVersion3;
    config = choose_egl_config(renderable_type, EGL_WINDOW_BIT, chosen_samples);
    if (config == nullptr) {
      renderable_type = EGL_OPENGL_ES2_BIT;
      client_version = kEglClientVersion2;
      config =
          choose_egl_config(renderable_type, EGL_WINDOW_BIT, chosen_samples);
    }
    if (config == nullptr) {
      return false;
    }
  }

  EGLConfig offscreen_config =
      choose_egl_config(renderable_type, EGL_PBUFFER_BIT, chosen_samples);
  if (offscreen_config == nullptr && chosen_samples > kEglSingleSample) {
    offscreen_config =
        choose_egl_config(renderable_type, EGL_PBUFFER_BIT, kEglSingleSample);
  }
  if (offscreen_config == nullptr) {
    offscreen_config = config;
  }

  EGLint context_attribs[] = {
      EGL_CONTEXT_CLIENT_VERSION,
      client_version,
      EGL_NONE,
  };
  EGLContext context =
      eglCreateContext(display, config, EGL_NO_CONTEXT, context_attribs);
  if (context == EGL_NO_CONTEXT && client_version == kEglClientVersion3) {
    context_attribs[1] = kEglClientVersion2;
    context =
        eglCreateContext(display, config, EGL_NO_CONTEXT, context_attribs);
  }
  if (context == EGL_NO_CONTEXT) {
    return false;
  }
  EGLContext resource_context =
      eglCreateContext(display, offscreen_config, context, context_attribs);

  const EGLint pbuffer_attribs[] = {
      EGL_WIDTH, kEglPbufferDimension, EGL_HEIGHT, kEglPbufferDimension,
      EGL_NONE,
  };
  EGLSurface pbuffer =
      eglCreatePbufferSurface(display, config, pbuffer_attribs);
  if (pbuffer == EGL_NO_SURFACE && offscreen_config != config) {
    pbuffer =
        eglCreatePbufferSurface(display, offscreen_config, pbuffer_attribs);
  }
  EGLSurface resource_pbuffer =
      eglCreatePbufferSurface(display, offscreen_config, pbuffer_attribs);

  egl_display_ = display;
  egl_config_ = config;
  egl_context_ = context;
  egl_resource_context_ = resource_context;
  egl_pbuffer_surface_ = pbuffer;
  egl_resource_pbuffer_surface_ = resource_pbuffer;
  return true;
#else
  return false;
#endif
}

void FlutterEmbedderNative::TeardownAndroidEGL() {
#if FML_OS_ANDROID
  std::lock_guard<std::mutex> lock(egl_mutex_);
  if (egl_display_ == nullptr) {
    return;
  }
  EGLDisplay display = static_cast<EGLDisplay>(egl_display_);
  eglMakeCurrent(display, EGL_NO_SURFACE, EGL_NO_SURFACE, EGL_NO_CONTEXT);
  if (egl_window_surface_ != nullptr) {
    eglDestroySurface(display, static_cast<EGLSurface>(egl_window_surface_));
    egl_window_surface_ = nullptr;
  }
  if (egl_pbuffer_surface_ != nullptr) {
    eglDestroySurface(display, static_cast<EGLSurface>(egl_pbuffer_surface_));
    egl_pbuffer_surface_ = nullptr;
  }
  if (egl_resource_pbuffer_surface_ != nullptr) {
    eglDestroySurface(display,
                      static_cast<EGLSurface>(egl_resource_pbuffer_surface_));
    egl_resource_pbuffer_surface_ = nullptr;
  }
  if (egl_resource_context_ != nullptr) {
    eglDestroyContext(display, static_cast<EGLContext>(egl_resource_context_));
    egl_resource_context_ = nullptr;
  }
  if (egl_context_ != nullptr) {
    eglDestroyContext(display, static_cast<EGLContext>(egl_context_));
    egl_context_ = nullptr;
  }
  egl_display_ = nullptr;
  egl_config_ = nullptr;
#else
  (void)egl_display_;
  (void)egl_config_;
  (void)egl_context_;
  (void)egl_resource_context_;
  (void)egl_pbuffer_surface_;
  (void)egl_resource_pbuffer_surface_;
  (void)egl_window_surface_;
#endif
}

bool FlutterEmbedderNative::CreateOrUpdateAndroidWindowSurface(
    void* native_window) {
#if FML_OS_ANDROID
  if (native_window == nullptr) {
    return false;
  }
  if (egl_display_ == nullptr && !InitializeAndroidEGL()) {
    return false;
  }
  std::lock_guard<std::mutex> lock(egl_mutex_);
  EGLDisplay display = static_cast<EGLDisplay>(egl_display_);
  EGLConfig config = static_cast<EGLConfig>(egl_config_);
  EGLContext context = static_cast<EGLContext>(egl_context_);
  EGLSurface pbuffer = static_cast<EGLSurface>(egl_pbuffer_surface_);
  if (egl_window_surface_ != nullptr) {
    EGLSurface old_surface = static_cast<EGLSurface>(egl_window_surface_);
    if (context != EGL_NO_CONTEXT && eglGetCurrentContext() == context &&
        (eglGetCurrentSurface(EGL_DRAW) == old_surface ||
         eglGetCurrentSurface(EGL_READ) == old_surface)) {
      eglMakeCurrent(display, pbuffer, pbuffer, context);
    }
    eglDestroySurface(display, old_surface);
    egl_window_surface_ = nullptr;
  }
  const EGLint attribs[] = {EGL_NONE};
  EGLint visual_id = 0;
  if (eglGetConfigAttrib(display, config, EGL_NATIVE_VISUAL_ID, &visual_id) ==
      EGL_TRUE) {
    // Passing 0 for width and height preserves the ANativeWindow's existing
    // dimensions while setting the pixel format to the EGL config's visual ID.
    constexpr int32_t kPreserveWindowDimension = 0;
    ANativeWindow_setBuffersGeometry(static_cast<ANativeWindow*>(native_window),
                                     kPreserveWindowDimension,
                                     kPreserveWindowDimension, visual_id);
  }
  EGLSurface win_surface = eglCreateWindowSurface(
      display, config, static_cast<EGLNativeWindowType>(native_window),
      attribs);
  if (win_surface == EGL_NO_SURFACE) {
    return false;
  }
  egl_window_surface_ = win_surface;
  if (context != EGL_NO_CONTEXT && eglGetCurrentContext() == context) {
    eglMakeCurrent(display, win_surface, win_surface, context);
  }
  return true;
#else
  (void)native_window;
  return false;
#endif
}

void FlutterEmbedderNative::DestroyAndroidWindowSurface() {
#if FML_OS_ANDROID
  std::lock_guard<std::mutex> lock(egl_mutex_);
  if (egl_display_ != nullptr && egl_window_surface_ != nullptr) {
    EGLDisplay display = static_cast<EGLDisplay>(egl_display_);
    EGLContext context = static_cast<EGLContext>(egl_context_);
    EGLSurface pbuffer = static_cast<EGLSurface>(egl_pbuffer_surface_);
    EGLSurface old_surface = static_cast<EGLSurface>(egl_window_surface_);
    if (context != EGL_NO_CONTEXT && eglGetCurrentContext() == context &&
        (eglGetCurrentSurface(EGL_DRAW) == old_surface ||
         eglGetCurrentSurface(EGL_READ) == old_surface)) {
      eglMakeCurrent(display, pbuffer, pbuffer, context);
    }
    eglDestroySurface(display, old_surface);
    egl_window_surface_ = nullptr;
  }
#endif
}

bool FlutterEmbedderNative::MakeAndroidEGLCurrent() {
#if FML_OS_ANDROID
  std::lock_guard<std::mutex> lock(egl_mutex_);
  if (egl_display_ == nullptr || egl_context_ == nullptr) {
    return false;
  }
  EGLDisplay display = static_cast<EGLDisplay>(egl_display_);
  EGLContext context = static_cast<EGLContext>(egl_context_);
  EGLSurface surface = egl_window_surface_ != nullptr
                           ? static_cast<EGLSurface>(egl_window_surface_)
                           : static_cast<EGLSurface>(egl_pbuffer_surface_);
  return eglMakeCurrent(display, surface, surface, context) == EGL_TRUE;
#else
  return true;
#endif
}

bool FlutterEmbedderNative::ClearAndroidEGLCurrent() {
#if FML_OS_ANDROID
  std::lock_guard<std::mutex> lock(egl_mutex_);
  if (egl_display_ == nullptr) {
    return true;
  }
  EGLDisplay display = static_cast<EGLDisplay>(egl_display_);
  return eglMakeCurrent(display, EGL_NO_SURFACE, EGL_NO_SURFACE,
                        EGL_NO_CONTEXT) == EGL_TRUE;
#else
  return true;
#endif
}

bool FlutterEmbedderNative::PresentAndroidEGL() {
#if FML_OS_ANDROID
  bool swapped_window = false;
  {
    std::lock_guard<std::mutex> lock(egl_mutex_);
    if (egl_display_ != nullptr && egl_window_surface_ != nullptr) {
      EGLDisplay display = static_cast<EGLDisplay>(egl_display_);
      EGLContext context = static_cast<EGLContext>(egl_context_);
      EGLSurface surface = static_cast<EGLSurface>(egl_window_surface_);
      if (context != EGL_NO_CONTEXT &&
          (eglGetCurrentContext() != context ||
           eglGetCurrentSurface(EGL_DRAW) != surface ||
           eglGetCurrentSurface(EGL_READ) != surface)) {
        eglMakeCurrent(display, surface, surface, context);
      }
      swapped_window = (eglSwapBuffers(display, surface) == EGL_TRUE);
    }
  }
  if (swapped_window) {
    NotifyFirstFramePresented();
  }
  return true;
#else
  return true;
#endif
}

bool FlutterEmbedderNative::ClearAndPresentAndroidEGL() {
#if FML_OS_ANDROID
  bool swapped_window = false;
  {
    std::lock_guard<std::mutex> lock(egl_mutex_);
    if (egl_display_ != nullptr && egl_window_surface_ != nullptr &&
        egl_context_ != nullptr) {
      EGLDisplay display = static_cast<EGLDisplay>(egl_display_);
      EGLContext context = static_cast<EGLContext>(egl_context_);
      EGLSurface surface = static_cast<EGLSurface>(egl_window_surface_);
      if (eglMakeCurrent(display, surface, surface, context) == EGL_TRUE) {
        // Default onscreen window framebuffer ID in OpenGL ES.
        constexpr GLuint kDefaultWindowFramebufferId = 0;
        // Transparent RGBA component value for clearing the background surface.
        constexpr GLclampf kTransparentClearComponent = 0.0f;
        glBindFramebuffer(GL_FRAMEBUFFER, kDefaultWindowFramebufferId);
        glDisable(GL_SCISSOR_TEST);
        glColorMask(GL_TRUE, GL_TRUE, GL_TRUE, GL_TRUE);
        glClearColor(kTransparentClearComponent, kTransparentClearComponent,
                     kTransparentClearComponent, kTransparentClearComponent);
        glClear(GL_COLOR_BUFFER_BIT);
        swapped_window = (eglSwapBuffers(display, surface) == EGL_TRUE);
      }
    }
  }
  if (swapped_window) {
    NotifyFirstFramePresented();
  }
  return true;
#else
  return true;
#endif
}

bool FlutterEmbedderNative::MakeAndroidEGLResourceCurrent() {
#if FML_OS_ANDROID
  std::lock_guard<std::mutex> lock(egl_mutex_);
  if (egl_display_ == nullptr || egl_resource_context_ == nullptr) {
    return false;
  }
  EGLDisplay display = static_cast<EGLDisplay>(egl_display_);
  EGLContext context = static_cast<EGLContext>(egl_resource_context_);
  EGLSurface surface = static_cast<EGLSurface>(egl_resource_pbuffer_surface_);
  return eglMakeCurrent(display, surface, surface, context) == EGL_TRUE;
#else
  return true;
#endif
}

namespace {

struct OverlaySurfaceCallbackUserData {
  FlutterEmbedderNative* embedder = nullptr;
  int32_t overlay_surface_id = 0;
  std::function<bool()> make_current;
};

}  // namespace

bool FlutterEmbedderNative::BindAndroidOverlayEGLSurface(
    int32_t overlay_surface_id,
    void* native_window,
    FlutterBackingStore* backing_store_out) {
  if (backing_store_out == nullptr || native_window == nullptr) {
    return false;
  }
#if FML_OS_ANDROID
  if (egl_display_ == nullptr && !InitializeAndroidEGL()) {
    return false;
  }
  {
    std::lock_guard<std::mutex> lock(egl_mutex_);
    EGLDisplay display = static_cast<EGLDisplay>(egl_display_);
    EGLConfig config = static_cast<EGLConfig>(egl_config_);
    EGLContext context = static_cast<EGLContext>(egl_context_);
    EGLSurface fallback = egl_window_surface_ != nullptr
                              ? static_cast<EGLSurface>(egl_window_surface_)
                              : static_cast<EGLSurface>(egl_pbuffer_surface_);
    auto& entry = egl_overlay_surfaces_[overlay_surface_id];
    if (entry.native_window != native_window && entry.egl_surface != nullptr) {
      EGLSurface old_surface = static_cast<EGLSurface>(entry.egl_surface);
      if (context != EGL_NO_CONTEXT && eglGetCurrentContext() == context &&
          (eglGetCurrentSurface(EGL_DRAW) == old_surface ||
           eglGetCurrentSurface(EGL_READ) == old_surface)) {
        eglMakeCurrent(display, fallback, fallback, context);
      }
      eglDestroySurface(display, old_surface);
      entry.egl_surface = nullptr;
    }
    if (entry.egl_surface == nullptr) {
      const EGLint attribs[] = {EGL_NONE};
      EGLint visual_id = 0;
      if (eglGetConfigAttrib(display, config, EGL_NATIVE_VISUAL_ID,
                             &visual_id) == EGL_TRUE) {
        // Passing 0 for width and height preserves the ANativeWindow's existing
        // dimensions while setting the pixel format to the EGL config's visual
        // ID.
        constexpr int32_t kPreserveWindowDimension = 0;
        ANativeWindow_setBuffersGeometry(
            static_cast<ANativeWindow*>(native_window),
            kPreserveWindowDimension, kPreserveWindowDimension, visual_id);
      }
      EGLSurface surf = eglCreateWindowSurface(
          display, config, static_cast<EGLNativeWindowType>(native_window),
          attribs);
      if (surf == EGL_NO_SURFACE) {
        return false;
      }
      entry.native_window = native_window;
      entry.egl_surface = surf;
    }
  }
#else
  (void)native_window;
#endif

  auto* cb_data = new OverlaySurfaceCallbackUserData{
      this, overlay_surface_id, [this, overlay_surface_id]() {
        return MakeAndroidOverlayEGLCurrent(overlay_surface_id);
      }};
  *backing_store_out = {};
  backing_store_out->struct_size = sizeof(FlutterBackingStore);
  backing_store_out->type = kFlutterBackingStoreTypeOpenGL;
  backing_store_out->open_gl.type = kFlutterOpenGLTargetTypeSurface;
  backing_store_out->open_gl.surface.struct_size = sizeof(FlutterOpenGLSurface);
  backing_store_out->open_gl.surface.user_data = cb_data;
  backing_store_out->open_gl.surface.make_current_callback =
      [](void* user_data, bool* state_changed) -> bool {
    if (state_changed) {
      *state_changed = true;
    }
    auto* data = static_cast<OverlaySurfaceCallbackUserData*>(user_data);
    return data != nullptr && data->make_current && data->make_current();
  };
  backing_store_out->open_gl.surface.clear_current_callback =
      [](void* user_data, bool* state_changed) -> bool {
    if (state_changed) {
      *state_changed = false;
    }
    (void)user_data;
    return true;
  };
  backing_store_out->open_gl.surface.destruction_callback =
      [](void* user_data) {
        delete static_cast<OverlaySurfaceCallbackUserData*>(user_data);
      };
  // Standard RGBA8888 Sized Internal Format (GL_RGBA8 = 0x8058).
  constexpr uint32_t kGlRgba8Format = 0x8058;
  backing_store_out->open_gl.surface.format = kGlRgba8Format;
  return true;
}

bool FlutterEmbedderNative::MakeAndroidOverlayEGLCurrent(
    int32_t overlay_surface_id) {
#if FML_OS_ANDROID
  std::lock_guard<std::mutex> lock(egl_mutex_);
  if (egl_display_ == nullptr || egl_context_ == nullptr) {
    return false;
  }
  auto it = egl_overlay_surfaces_.find(overlay_surface_id);
  if (it == egl_overlay_surfaces_.end() || it->second.egl_surface == nullptr) {
    return false;
  }
  EGLDisplay display = static_cast<EGLDisplay>(egl_display_);
  EGLContext context = static_cast<EGLContext>(egl_context_);
  EGLSurface surface = static_cast<EGLSurface>(it->second.egl_surface);
  return eglMakeCurrent(display, surface, surface, context) == EGL_TRUE;
#else
  (void)overlay_surface_id;
  return true;
#endif
}

bool FlutterEmbedderNative::PresentAndroidOverlayEGL(
    int32_t overlay_surface_id) {
#if FML_OS_ANDROID
  bool swapped = false;
  {
    std::lock_guard<std::mutex> lock(egl_mutex_);
    if (egl_display_ != nullptr) {
      auto it = egl_overlay_surfaces_.find(overlay_surface_id);
      if (it != egl_overlay_surfaces_.end() &&
          it->second.egl_surface != nullptr) {
        EGLDisplay display = static_cast<EGLDisplay>(egl_display_);
        EGLContext context = static_cast<EGLContext>(egl_context_);
        EGLSurface surface = static_cast<EGLSurface>(it->second.egl_surface);
        if (context != EGL_NO_CONTEXT &&
            (eglGetCurrentContext() != context ||
             eglGetCurrentSurface(EGL_DRAW) != surface ||
             eglGetCurrentSurface(EGL_READ) != surface)) {
          eglMakeCurrent(display, surface, surface, context);
        }
        swapped = (eglSwapBuffers(display, surface) == EGL_TRUE);
      }
    }
  }
  if (swapped) {
    NotifyFirstFramePresented();
  }
  return true;
#else
  (void)overlay_surface_id;
  return true;
#endif
}

void FlutterEmbedderNative::DestroyAndroidOverlayEGLSurfaces() {
#if FML_OS_ANDROID
  std::lock_guard<std::mutex> lock(egl_mutex_);
  if (egl_display_ != nullptr) {
    EGLDisplay display = static_cast<EGLDisplay>(egl_display_);
    EGLContext context = static_cast<EGLContext>(egl_context_);
    EGLSurface fallback = egl_window_surface_ != nullptr
                              ? static_cast<EGLSurface>(egl_window_surface_)
                              : static_cast<EGLSurface>(egl_pbuffer_surface_);
    for (auto& [id, entry] : egl_overlay_surfaces_) {
      if (entry.egl_surface != nullptr) {
        EGLSurface old_surface = static_cast<EGLSurface>(entry.egl_surface);
        if (context != EGL_NO_CONTEXT && eglGetCurrentContext() == context &&
            (eglGetCurrentSurface(EGL_DRAW) == old_surface ||
             eglGetCurrentSurface(EGL_READ) == old_surface)) {
          eglMakeCurrent(display, fallback, fallback, context);
        }
        eglDestroySurface(display, old_surface);
        entry.egl_surface = nullptr;
      }
    }
  }
  egl_overlay_surfaces_.clear();
#else
  egl_overlay_surfaces_.clear();
#endif
}

bool FlutterEmbedderNative::PresentAndroidSoftware(const void* allocation,
                                                   size_t row_bytes,
                                                   size_t height) {
  if (!alive_flag_ || !alive_flag_->load() || allocation == nullptr ||
      row_bytes == 0 || height == 0) {
    return true;
  }
  bool presented = false;
  {
    std::lock_guard<std::mutex> lock(native_window_mutex_);
    if (native_window_ == nullptr) {
      return true;
    }
#if FML_OS_ANDROID
    if (!is_using_mock_proc_table_) {
      auto* window = static_cast<ANativeWindow*>(native_window_);
      size_t width_pixels = row_bytes / kBytesPerRgbaPixel;
      ANativeWindow_setBuffersGeometry(
          window, static_cast<int32_t>(width_pixels),
          static_cast<int32_t>(height), WINDOW_FORMAT_RGBA_8888);
      ANativeWindow_Buffer buffer{};
      if (ANativeWindow_lock(window, &buffer, nullptr) ==
          kANativeWindowSuccess) {
        auto* dst = static_cast<uint8_t*>(buffer.bits);
        const auto* src = static_cast<const uint8_t*>(allocation);
        size_t dst_row_bytes =
            static_cast<size_t>(std::max(kMinSurfaceDimension, buffer.stride)) *
            kBytesPerRgbaPixel;
        size_t copy_bytes = std::min(row_bytes, dst_row_bytes);
        size_t copy_rows = std::min(
            height,
            static_cast<size_t>(std::max(kMinSurfaceDimension, buffer.height)));
        for (size_t y = 0; y < copy_rows; ++y) {
          std::memcpy(dst + y * dst_row_bytes, src + y * row_bytes, copy_bytes);
        }
        ANativeWindow_unlockAndPost(window);
        presented = true;
      }
    } else {
      presented = true;
    }
#else
    presented = true;
#endif
  }
  if (presented) {
    NotifyFirstFramePresented();
  }
  return true;
}

void FlutterEmbedderNative::NotifyFirstFramePresented() {
  bool expected = false;
  if (!first_frame_presented_.compare_exchange_strong(expected, true)) {
    return;
  }
  auto platform_runner =
      task_runners_ ? task_runners_->GetPlatformTaskRunner() : nullptr;
  if (platform_runner && !platform_runner->RunsTasksOnCurrentThread()) {
    auto alive = alive_flag_;
    auto jvm_invoker = jvm_invoker_;
    platform_runner->PostTask([alive, jvm_invoker]() {
      if (alive && alive->load() && jvm_invoker) {
        jvm_invoker->OnFirstFrame();
      }
    });
    return;
  }
  if (jvm_invoker_) {
    jvm_invoker_->OnFirstFrame();
  }
}

void FlutterEmbedderNative::FlushPendingStartupState() {
  std::function<void()> viewport_cb;
  std::optional<bool> semantics_enabled;
  std::optional<int32_t> accessibility_features;
  std::vector<PendingPlatformMessage> messages;
  {
    std::lock_guard<std::mutex> lock(pending_startup_mutex_);
    viewport_cb = std::move(pending_viewport_metrics_callback_);
    pending_viewport_metrics_callback_ = nullptr;
    semantics_enabled = pending_semantics_enabled_;
    pending_semantics_enabled_.reset();
    accessibility_features = pending_accessibility_features_;
    pending_accessibility_features_.reset();
    messages = std::move(pending_platform_messages_);
    pending_platform_messages_.clear();
  }
  if (viewport_cb) {
    viewport_cb();
  }
  if (semantics_enabled.has_value()) {
    SetSemanticsEnabled(*semantics_enabled);
  }
  if (accessibility_features.has_value()) {
    SetAccessibilityFeatures(*accessibility_features);
  }
  for (const auto& msg : messages) {
    const uint8_t* ptr = nullptr;
    if (msg.has_data) {
      ptr = msg.data.empty() ? &kEmptyByte : msg.data.data();
    }
    DispatchPlatformMessage(msg.channel, ptr, msg.data.size(), msg.response_id);
  }
}

}  // namespace flutter
