// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#define FML_USED_ON_EMBEDDER

#include <pthread.h>
#include <sys/resource.h>
#include <sys/time.h>
#include <algorithm>
#include <atomic>
#include <cstdint>
#include <cstring>
#include <memory>
#include <mutex>
#include <optional>
#include <string>
#include <unordered_map>
#include <utility>
#include <vector>

#include "common/settings.h"
#include "flutter/fml/cpu_affinity.h"
#include "flutter/fml/logging.h"
#include "flutter/fml/message_loop.h"
#include "flutter/lib/ui/painting/image_generator_registry.h"
#include "flutter/shell/common/rasterizer.h"
#include "flutter/shell/common/run_configuration.h"
#include "flutter/shell/common/thread_host.h"
#include "flutter/shell/platform/android/android_image_generator.h"
#include "flutter/shell/platform/android/android_rendering_selector.h"
#include "flutter/shell/platform/android/android_shell_holder.h"
#include "flutter/shell/platform/android/context/android_context.h"
#include "flutter/shell/platform/android/platform_view_android.h"
#include "flutter/shell/platform/android/platform_view_android_delegate/platform_view_android_delegate.h"
#include "flutter/shell/platform/embedder/embedder_engine.h"

namespace flutter {

/// Inheriting ThreadConfigurer and use Android platform thread API to configure
/// the thread priorities
static void AndroidPlatformThreadConfigSetter(
    const fml::Thread::ThreadConfig& config) {
  // set thread name
  fml::Thread::SetCurrentThreadName(config);
  // set thread priority
  switch (config.priority) {
    case fml::Thread::ThreadPriority::kBackground: {
      fml::RequestAffinity(fml::CpuAffinity::kEfficiency);
      if (::setpriority(PRIO_PROCESS, 0, 10) != 0) {
        FML_LOG(ERROR) << "Failed to set IO task runner priority";
      }
      break;
    }
    case fml::Thread::ThreadPriority::kDisplay: {
      fml::RequestAffinity(fml::CpuAffinity::kNotEfficiency);
      if (::setpriority(PRIO_PROCESS, 0, -1) != 0) {
        FML_LOG(ERROR) << "Failed to set UI task runner priority";
      }
      break;
    }
    case fml::Thread::ThreadPriority::kRaster: {
      fml::RequestAffinity(fml::CpuAffinity::kNotEfficiency);
      // Android describes -8 as "most important display threads, for
      // compositing the screen and retrieving input events". Conservatively
      // set the raster thread to slightly lower priority than it.
      if (::setpriority(PRIO_PROCESS, 0, -5) != 0) {
        // Defensive fallback. Depending on the OEM, it may not be possible
        // to set priority to -5.
        if (::setpriority(PRIO_PROCESS, 0, -2) != 0) {
          FML_LOG(ERROR) << "Failed to set raster task runner priority";
        }
      }
      break;
    }
    default:
      fml::RequestAffinity(fml::CpuAffinity::kNotPerformance);
      if (::setpriority(PRIO_PROCESS, 0, 0) != 0) {
        FML_LOG(ERROR) << "Failed to set priority";
      }
  }
}
static PlatformData GetDefaultPlatformData() {
  PlatformData platform_data;
  platform_data.lifecycle_state = "AppLifecycleState.detached";
  return platform_data;
}

namespace {

// The ID of the implicit view in single-view mode.
constexpr int64_t kImplicitViewId = 0;

// Matches PointerChange in AndroidTouchProcessor.java.
enum class RawPointerChange : int64_t {
  kCancel = 0,
  kAdd = 1,
  kRemove = 2,
  kHover = 3,
  kDown = 4,
  kMove = 5,
  kUp = 6,
  kPanZoomStart = 7,
  kPanZoomUpdate = 8,
  kPanZoomEnd = 9,
};

// Matches PointerDeviceKind in AndroidTouchProcessor.java.
enum class RawPointerDeviceKind : int64_t {
  kTouch = 0,
  kMouse = 1,
  kStylus = 2,
  kInvertedStylus = 3,
  kTrackpad = 4,
};

// Matches PointerSignalKind in AndroidTouchProcessor.java.
enum class RawPointerSignalKind : int64_t {
  kNone = 0,
  kScroll = 1,
  kScrollInertiaCancel = 2,
  kScale = 3,
};

// Binary layout of each pointer record packed into a direct ByteBuffer by
// AndroidTouchProcessor.java (36 8-byte fields = 288 bytes per record).
struct alignas(8) RawPointerDataRecord {
  int64_t embedder_id;
  int64_t time_stamp;
  RawPointerChange change;
  RawPointerDeviceKind kind;
  RawPointerSignalKind signal_kind;
  int64_t device;
  int64_t pointer_identifier;
  double physical_x;
  double physical_y;
  double physical_delta_x;
  double physical_delta_y;
  int64_t buttons;
  int64_t obscured;
  int64_t synthesized;
  double pressure;
  double pressure_min;
  double pressure_max;
  double distance;
  double distance_max;
  double size;
  double radius_major;
  double radius_minor;
  double radius_min;
  double radius_max;
  double orientation;
  double tilt;
  int64_t platform_data;
  double scroll_delta_x;
  double scroll_delta_y;
  double pan_x;
  double pan_y;
  double pan_delta_x;
  double pan_delta_y;
  double scale;
  double rotation;
  int64_t view_id;
};

// Matches POINTER_DATA_FIELD_COUNT (36) * BYTES_PER_FIELD (8) in
// AndroidTouchProcessor.java.
constexpr size_t kPointerDataFieldCount = 36;
static_assert(sizeof(RawPointerDataRecord) ==
              kPointerDataFieldCount * sizeof(int64_t));

FlutterPointerPhase ToFlutterPointerPhase(RawPointerChange change) {
  switch (change) {
    case RawPointerChange::kCancel:
      return FlutterPointerPhase::kCancel;
    case RawPointerChange::kAdd:
      return FlutterPointerPhase::kAdd;
    case RawPointerChange::kRemove:
      return FlutterPointerPhase::kRemove;
    case RawPointerChange::kHover:
      return FlutterPointerPhase::kHover;
    case RawPointerChange::kDown:
      return FlutterPointerPhase::kDown;
    case RawPointerChange::kMove:
      return FlutterPointerPhase::kMove;
    case RawPointerChange::kUp:
      return FlutterPointerPhase::kUp;
    case RawPointerChange::kPanZoomStart:
      return FlutterPointerPhase::kPanZoomStart;
    case RawPointerChange::kPanZoomUpdate:
      return FlutterPointerPhase::kPanZoomUpdate;
    case RawPointerChange::kPanZoomEnd:
      return FlutterPointerPhase::kPanZoomEnd;
  }
  return FlutterPointerPhase::kCancel;
}

FlutterPointerDeviceKind ToFlutterPointerDeviceKind(RawPointerDeviceKind kind) {
  switch (kind) {
    case RawPointerDeviceKind::kTouch:
      return kFlutterPointerDeviceKindTouch;
    case RawPointerDeviceKind::kMouse:
      return kFlutterPointerDeviceKindMouse;
    case RawPointerDeviceKind::kStylus:
      return kFlutterPointerDeviceKindStylus;
    case RawPointerDeviceKind::kInvertedStylus:
      return kFlutterPointerDeviceKindInvertedStylus;
    case RawPointerDeviceKind::kTrackpad:
      return kFlutterPointerDeviceKindTrackpad;
  }
  return kFlutterPointerDeviceKindTouch;
}

FlutterPointerSignalKind ToFlutterPointerSignalKind(
    RawPointerSignalKind signal_kind) {
  switch (signal_kind) {
    case RawPointerSignalKind::kNone:
      return kFlutterPointerSignalKindNone;
    case RawPointerSignalKind::kScroll:
      return kFlutterPointerSignalKindScroll;
    case RawPointerSignalKind::kScrollInertiaCancel:
      return kFlutterPointerSignalKindScrollInertiaCancel;
    case RawPointerSignalKind::kScale:
      return kFlutterPointerSignalKindScale;
  }
  return kFlutterPointerSignalKindNone;
}

uint64_t NextHolderId() {
  static std::atomic<uint64_t> next_id{1};
  return next_id.fetch_add(1, std::memory_order_relaxed);
}

struct PendingPlatformMessageResponse {
  uint64_t holder_id = 0;
  std::weak_ptr<PlatformViewAndroidJNI> jni_facade;
  int response_id = 0;
};

// Maps integer tokens passed as |user_data| to
// FlutterPlatformMessageCreateResponseHandle back to the originating holder's
// JNI facade and response ID. Using integer tokens rather than heap pointers
// guarantees that neither uncompleted response handles (e.g. when a message is
// sent before the root isolate is launched or intercepted by a mock proc) nor
// callbacks queued on the platform loop when ~AndroidShellHolder() runs can
// leak or dereference freed memory.
class PendingPlatformMessageResponseTable {
 public:
  uintptr_t Register(uint64_t holder_id,
                     const std::shared_ptr<PlatformViewAndroidJNI>& jni_facade,
                     int response_id) {
    std::scoped_lock lock(mutex_);
    uintptr_t token = next_token_++;
    if (token == 0) {
      token = next_token_++;
    }
    entries_.emplace(token, PendingPlatformMessageResponse{
                                holder_id, jni_facade, response_id});
    return token;
  }

  std::optional<PendingPlatformMessageResponse> Take(uintptr_t token) {
    std::scoped_lock lock(mutex_);
    auto it = entries_.find(token);
    if (it == entries_.end()) {
      return std::nullopt;
    }
    PendingPlatformMessageResponse entry = std::move(it->second);
    entries_.erase(it);
    return entry;
  }

  void RemoveForHolder(uint64_t holder_id) {
    std::scoped_lock lock(mutex_);
    for (auto it = entries_.begin(); it != entries_.end();) {
      if (it->second.holder_id == holder_id) {
        it = entries_.erase(it);
      } else {
        ++it;
      }
    }
  }

 private:
  std::mutex mutex_;
  uintptr_t next_token_ = 1;
  std::unordered_map<uintptr_t, PendingPlatformMessageResponse> entries_;
};

PendingPlatformMessageResponseTable& GetPendingResponseTable() {
  static auto* table = new PendingPlatformMessageResponseTable();
  return *table;
}

// Stages platform-specific flutter::Texture instances created by
// PlatformViewAndroid immediately before FlutterEngineRegisterExternalTexture
// is invoked, so EmbedderExternalTextureResolver can claim ownership by
// (holder_id, texture_id) without exposing C++ texture types in embedder.h.
class PendingTextureTable {
 public:
  void Put(uint64_t holder_id,
           int64_t texture_id,
           std::unique_ptr<Texture> texture) {
    std::scoped_lock lock(mutex_);
    entries_[holder_id][texture_id] = std::move(texture);
  }

  std::unique_ptr<Texture> Take(uint64_t holder_id, int64_t texture_id) {
    std::scoped_lock lock(mutex_);
    auto holder_it = entries_.find(holder_id);
    if (holder_it == entries_.end()) {
      return nullptr;
    }
    auto tex_it = holder_it->second.find(texture_id);
    if (tex_it == holder_it->second.end()) {
      return nullptr;
    }
    std::unique_ptr<Texture> texture = std::move(tex_it->second);
    holder_it->second.erase(tex_it);
    if (holder_it->second.empty()) {
      entries_.erase(holder_it);
    }
    return texture;
  }

  void RemoveForHolder(uint64_t holder_id) {
    std::scoped_lock lock(mutex_);
    entries_.erase(holder_id);
  }

 private:
  std::mutex mutex_;
  std::unordered_map<uint64_t,
                     std::unordered_map<int64_t, std::unique_ptr<Texture>>>
      entries_;
};

PendingTextureTable& GetPendingTextureTable() {
  static auto* table = new PendingTextureTable();
  return *table;
}

std::unique_ptr<EmbedderExternalTextureResolver> MakeExternalTextureResolver(
    uint64_t holder_id) {
  return std::make_unique<EmbedderExternalTextureResolver>(
      [holder_id](int64_t texture_id) -> std::unique_ptr<Texture> {
        return GetPendingTextureTable().Take(holder_id, texture_id);
      });
}

struct FirstFrameCallbackEntry {
  fml::RefPtr<fml::TaskRunner> platform_task_runner;
  std::weak_ptr<PlatformViewAndroidJNI> jni_facade;
};

// Routes the render-thread VoidCallback from FlutterEngineSetNextFrameCallback
// back to the originating holder's platform task runner and JNI facade by
// holder_id, without dereferencing the holder if it is destroyed before the
// posted platform task runs.
class FirstFrameCallbackTable {
 public:
  void Register(uint64_t holder_id,
                fml::RefPtr<fml::TaskRunner> platform_task_runner,
                const std::shared_ptr<PlatformViewAndroidJNI>& jni_facade) {
    std::scoped_lock lock(mutex_);
    entries_[holder_id] =
        FirstFrameCallbackEntry{std::move(platform_task_runner), jni_facade};
  }

  std::optional<FirstFrameCallbackEntry> Find(uint64_t holder_id) {
    std::scoped_lock lock(mutex_);
    auto it = entries_.find(holder_id);
    if (it == entries_.end()) {
      return std::nullopt;
    }
    return it->second;
  }

  void RemoveForHolder(uint64_t holder_id) {
    std::scoped_lock lock(mutex_);
    entries_.erase(holder_id);
  }

 private:
  std::mutex mutex_;
  std::unordered_map<uint64_t, FirstFrameCallbackEntry> entries_;
};

FirstFrameCallbackTable& GetFirstFrameCallbackTable() {
  static auto* table = new FirstFrameCallbackTable();
  return *table;
}

void OnFirstFrameRendered(void* user_data) {
  const auto holder_id =
      static_cast<uint64_t>(reinterpret_cast<uintptr_t>(user_data));
  std::optional<FirstFrameCallbackEntry> entry =
      GetFirstFrameCallbackTable().Find(holder_id);
  if (!entry.has_value() || !entry->platform_task_runner) {
    return;
  }
  entry->platform_task_runner->PostTask([holder_id]() {
    std::optional<FirstFrameCallbackEntry> platform_entry =
        GetFirstFrameCallbackTable().Find(holder_id);
    if (!platform_entry.has_value()) {
      return;
    }
    std::shared_ptr<PlatformViewAndroidJNI> jni_facade =
        platform_entry->jni_facade.lock();
    if (jni_facade) {
      jni_facade->FlutterViewOnFirstFrame();
    }
  });
}

void OnPlatformMessageResponse(const uint8_t* data,
                               size_t size,
                               void* user_data) {
  const auto token = reinterpret_cast<uintptr_t>(user_data);
  std::optional<PendingPlatformMessageResponse> entry =
      GetPendingResponseTable().Take(token);
  if (!entry.has_value()) {
    return;
  }
  std::shared_ptr<PlatformViewAndroidJNI> jni_facade = entry->jni_facade.lock();
  if (!jni_facade) {
    return;
  }
  if (data == nullptr) {
    jni_facade->FlutterViewHandlePlatformMessageResponse(entry->response_id,
                                                         nullptr);
  } else {
    jni_facade->FlutterViewHandlePlatformMessageResponse(
        entry->response_id, std::make_unique<fml::MallocMapping>(
                                fml::MallocMapping::Copy(data, size)));
  }
}

// The holder owns its engine through an embedder API handle. Where embedder.h
// has no equivalent yet, the holder reaches past the handle with a cast or
// GetShell(). Keep each of those visible at its use so that
// ci/bin/android_embedder_ratchet.dart counts it; the counts must reach zero
// before the holder switches to FlutterEngineInitialize.

Shell& GetShell(FLUTTER_API_SYMBOL(FlutterEngine) engine) {
  return reinterpret_cast<EmbedderEngine*>(engine)->GetShell();
}

FlutterEngineProcTable LoadEmbedderApi() {
  FlutterEngineProcTable embedder_api = {};
  embedder_api.struct_size = sizeof(FlutterEngineProcTable);
  FlutterEngineResult result = FlutterEngineGetProcAddresses(&embedder_api);
  FML_CHECK(result == kSuccess)
      << "FlutterEngineGetProcAddresses failed: " << result;
  return embedder_api;
}

// The embedder API callbacks of the PlatformView overrides that
// PlatformViewAndroid no longer has.
PlatformViewAndroid::PlatformDispatchTable MakePlatformDispatchTable(
    const std::shared_ptr<PlatformViewAndroidJNI>& jni_facade,
    const std::shared_ptr<VsyncWaiterAndroid>& vsync_waiter) {
  return {
      .update_semantics_callback =
          [jni_facade](
              int64_t view_id, const flutter::SemanticsNodeUpdates& update,
              const flutter::CustomAccessibilityActionUpdates& actions) {
            PlatformViewAndroidDelegate(jni_facade)
                .UpdateSemantics(update, actions);
          },
      .vsync_callback =
          [vsync_waiter](intptr_t baton) { vsync_waiter->AwaitVSync(baton); },
      .compute_platform_resolved_locale_callback =
          [jni_facade](const std::vector<std::string>& supported_locale_data) {
            return jni_facade->FlutterViewComputePlatformResolvedLocale(
                supported_locale_data);
          },
      .on_pre_engine_restart_callback =
          [jni_facade]() { jni_facade->FlutterViewOnPreEngineRestart(); },
      .set_application_locale_callback =
          [jni_facade](std::string locale) {
            jni_facade->FlutterViewSetApplicationLocale(std::move(locale));
          },
      .set_semantics_tree_enabled_callback =
          [jni_facade](bool enabled) {
            jni_facade->FlutterViewSetSemanticsTreeEnabled(enabled);
          },
      .request_dart_deferred_library_callback =
          [jni_facade](intptr_t loading_unit_id) {
            jni_facade->RequestDartDeferredLibrary(loading_unit_id);
          },
      .get_scaled_font_size_callback =
          [jni_facade](double unscaled_font_size, int configuration_id) {
            return jni_facade->FlutterViewGetScaledFontSize(unscaled_font_size,
                                                            configuration_id);
          },
  };
}

// Gives the vsync source the engine handle once the holder owns the engine,
// or retires it when there is no engine. There is no source when the Shell
// failed before it created the platform view.
void AttachVsyncWaiter(VsyncWaiterAndroid* vsync_waiter,
                       FLUTTER_API_SYMBOL(FlutterEngine) engine,
                       const FlutterEngineProcTable* embedder_api) {
  if (vsync_waiter == nullptr) {
    return;
  }
  if (engine != nullptr) {
    vsync_waiter->Attach(engine, embedder_api);
  } else {
    vsync_waiter->Detach();
  }
}

}  // namespace

AndroidShellHolder::AndroidShellHolder(
    const flutter::Settings& settings,
    std::shared_ptr<PlatformViewAndroidJNI> jni_facade,
    AndroidRenderingAPI android_rendering_api)
    : settings_(settings),
      jni_facade_(jni_facade),
      embedder_api_(LoadEmbedderApi()),
      holder_id_(NextHolderId()),
      android_rendering_api_(android_rendering_api) {
  static size_t thread_host_count = 1;
  auto thread_label = std::to_string(thread_host_count++);

  auto mask = ThreadHost::Type::kRaster | ThreadHost::Type::kIo;
  if (settings.merged_platform_ui_thread !=
      Settings::MergedPlatformUIThread::kEnabled) {
    mask |= ThreadHost::Type::kUi;
  }

  flutter::ThreadHost::ThreadHostConfig host_config(
      thread_label, mask, AndroidPlatformThreadConfigSetter);
  host_config.ui_config = fml::Thread::ThreadConfig(
      flutter::ThreadHost::ThreadHostConfig::MakeThreadName(
          flutter::ThreadHost::Type::kUi, thread_label),
      fml::Thread::ThreadPriority::kDisplay);
  host_config.raster_config = fml::Thread::ThreadConfig(
      flutter::ThreadHost::ThreadHostConfig::MakeThreadName(
          flutter::ThreadHost::Type::kRaster, thread_label),
      fml::Thread::ThreadPriority::kRaster);
  host_config.io_config = fml::Thread::ThreadConfig(
      flutter::ThreadHost::ThreadHostConfig::MakeThreadName(
          flutter::ThreadHost::Type::kIo, thread_label),
      fml::Thread::ThreadPriority::kNormal);

  thread_host_ = std::make_shared<ThreadHost>(host_config);

  fml::WeakPtr<PlatformViewAndroid> weak_platform_view;
  std::shared_ptr<VsyncWaiterAndroid> vsync_waiter;
  AndroidRenderingAPI rendering_api = android_rendering_api_;
  Shell::CreateCallback<PlatformView> on_create_platform_view =
      [&jni_facade, &weak_platform_view, &vsync_waiter,
       rendering_api](Shell& shell) {
        vsync_waiter =
            std::make_shared<VsyncWaiterAndroid>(shell.GetTaskRunners());
        std::unique_ptr<PlatformViewAndroid> platform_view_android;
        platform_view_android = std::make_unique<PlatformViewAndroid>(
            shell,                   // delegate
            shell.GetTaskRunners(),  // task runners
            jni_facade,              // JNI interop
            rendering_api,           // rendering API
            MakePlatformDispatchTable(jni_facade,
                                      vsync_waiter)  // embedder callbacks
        );
        weak_platform_view = platform_view_android->GetWeakPtr();
        return platform_view_android;
      };

  Shell::CreateCallback<Rasterizer> on_create_rasterizer = [](Shell& shell) {
    return std::make_unique<Rasterizer>(shell);
  };

  // The current thread will be used as the platform thread. Ensure that the
  // message loop is initialized.
  fml::MessageLoop::EnsureInitializedForCurrentThread();
  fml::RefPtr<fml::TaskRunner> raster_runner;
  fml::RefPtr<fml::TaskRunner> ui_runner;
  fml::RefPtr<fml::TaskRunner> io_runner;
  fml::RefPtr<fml::TaskRunner> platform_runner =
      fml::MessageLoop::GetCurrent().GetTaskRunner();
  raster_runner = thread_host_->raster_thread->GetTaskRunner();
  if (settings.merged_platform_ui_thread ==
      Settings::MergedPlatformUIThread::kEnabled) {
    ui_runner = platform_runner;
  } else {
    ui_runner = thread_host_->ui_thread->GetTaskRunner();
  }
  io_runner = thread_host_->io_thread->GetTaskRunner();

  flutter::TaskRunners task_runners(thread_label,     // label
                                    platform_runner,  // platform
                                    raster_runner,    // raster
                                    ui_runner,        // ui
                                    io_runner         // io
  );

  // The same Shell::Create that FlutterEngineInitialize ends in, minus what
  // Android does itself: the holder owns the threads behind |task_runners|,
  // and Launch() runs the root isolate once the APK assets are known.
  auto engine = std::make_unique<EmbedderEngine>(
      /*thread_host=*/nullptr, task_runners, settings_,
      /*run_configuration=*/std::nullopt, on_create_platform_view,
      on_create_rasterizer, MakeExternalTextureResolver(holder_id_));
  if (engine->LaunchShell(GetDefaultPlatformData())) {
    engine_.reset(
        reinterpret_cast<FLUTTER_API_SYMBOL(FlutterEngine)>(engine.release()));
  }

  if (engine_) {
    // Concurrent worker threads are raw std::threads without an
    // fml::MessageLoop, whereas the dedicated IO thread (also tagged
    // kFlutterNativeThreadTypeWorker) always has an initialized
    // fml::MessageLoop.
    constexpr int kWorkerThreadPriority = 1;
    FlutterEngineResult priority_result =
        embedder_api_.PostCallbackOnAllNativeThreads(
            engine_.get(),
            [](FlutterNativeThreadType type, void* /*baton*/) {
              if (type == kFlutterNativeThreadTypeWorker &&
                  !fml::MessageLoop::IsInitializedForCurrentThread()) {
                if (::setpriority(PRIO_PROCESS, gettid(),
                                  kWorkerThreadPriority) != 0) {
                  FML_LOG(ERROR)
                      << "Failed to set Workers task runner priority";
                }
              }
            },
            nullptr);
    if (priority_result != kSuccess) {
      FML_LOG(ERROR) << "FlutterEnginePostCallbackOnAllNativeThreads failed: "
                     << priority_result;
    }

    GetShell(engine_.get())
        .RegisterImageDecoder(
            [runner = task_runners.GetIOTaskRunner()](sk_sp<SkData> buffer) {
              return AndroidImageGenerator::MakeFromData(std::move(buffer),
                                                         runner);
            },
            -1);
    FML_DLOG(INFO) << "Registered Android SDK image decoder (API level 28+)";
  }

  platform_view_ = weak_platform_view;
  FML_DCHECK(platform_view_);
  platform_message_handler_ = platform_view_->GetPlatformMessageHandler();
  vsync_waiter_ = std::move(vsync_waiter);
  AttachVsyncWaiter(vsync_waiter_.get(), engine_.get(), &embedder_api_);
  GetFirstFrameCallbackTable().Register(holder_id_, platform_runner,
                                        jni_facade_);
  is_valid_ = engine_ != nullptr;
}

AndroidShellHolder::AndroidShellHolder(
    const Settings& settings,
    const std::shared_ptr<PlatformViewAndroidJNI>& jni_facade,
    const std::shared_ptr<ThreadHost>& thread_host,
    UniqueEngine engine,
    uint64_t holder_id,
    std::unique_ptr<APKAssetProvider> apk_asset_provider,
    const fml::WeakPtr<PlatformViewAndroid>& platform_view,
    std::shared_ptr<VsyncWaiterAndroid> vsync_waiter,
    AndroidRenderingAPI rendering_api)
    : settings_(settings),
      jni_facade_(jni_facade),
      platform_view_(platform_view),
      platform_message_handler_(
          platform_view ? platform_view->GetPlatformMessageHandler() : nullptr),
      thread_host_(thread_host),
      engine_(std::move(engine)),
      embedder_api_(LoadEmbedderApi()),
      vsync_waiter_(std::move(vsync_waiter)),
      holder_id_(holder_id),
      apk_asset_provider_(std::move(apk_asset_provider)),
      android_rendering_api_(rendering_api) {
  FML_DCHECK(jni_facade);
  FML_DCHECK(engine_);
  FML_DCHECK(platform_view_);
  FML_DCHECK(thread_host_);
  fml::MessageLoop::EnsureInitializedForCurrentThread();
  GetFirstFrameCallbackTable().Register(
      holder_id_, fml::MessageLoop::GetCurrent().GetTaskRunner(), jni_facade_);
  // The spawned engine may already wait for a vsync; see VsyncWaiterAndroid.
  AttachVsyncWaiter(vsync_waiter_.get(), engine_.get(), &embedder_api_);
  is_valid_ = engine_ != nullptr;
}

AndroidShellHolder::~AndroidShellHolder() {
  GetFirstFrameCallbackTable().RemoveForHolder(holder_id_);
  if (vsync_waiter_) {
    vsync_waiter_->Detach();
  }
  platform_message_handler_.reset();
  engine_.reset();
  thread_host_.reset();
  GetPendingResponseTable().RemoveForHolder(holder_id_);
  GetPendingTextureTable().RemoveForHolder(holder_id_);
}

void AndroidShellHolder::EngineDeleter::operator()(
    FLUTTER_API_SYMBOL(FlutterEngine) engine) const {
  // Deletes the engine the way the Shell was deleted before it moved behind
  // a handle. FlutterEngineShutdown would also call NotifyDestroyed() on the
  // platform view first.
  delete reinterpret_cast<EmbedderEngine*>(engine);
}

bool AndroidShellHolder::IsValid() const {
  return is_valid_;
}

const flutter::Settings& AndroidShellHolder::GetSettings() const {
  return settings_;
}

std::unique_ptr<AndroidShellHolder> AndroidShellHolder::Spawn(
    std::shared_ptr<PlatformViewAndroidJNI> jni_facade,
    const std::string& entrypoint,
    const std::string& libraryUrl,
    const std::string& initial_route,
    const std::vector<std::string>& entrypoint_args,
    int64_t engine_id) const {
  FML_DCHECK(IsValid()) << "A new Shell can only be spawned "
                           "if the current Shell is properly constructed";

  // Pull out the new PlatformViewAndroid from the new Shell to feed to it to
  // the new AndroidShellHolder.
  //
  // It's a weak pointer because it's owned by the Shell (which we're also)
  // making below. And the AndroidShellHolder then owns the Shell.
  fml::WeakPtr<PlatformViewAndroid> weak_platform_view;

  // Take out the old AndroidContext to reuse inside the PlatformViewAndroid
  // of the new Shell.
  PlatformViewAndroid* android_platform_view = platform_view_.get();
  // There's some indirection with platform_view_ being a weak pointer but
  // we just checked that the engine_ exists above and a valid shell is the
  // owner of the platform view so this weak pointer always exists.
  FML_DCHECK(android_platform_view);
  std::shared_ptr<flutter::AndroidContext> android_context =
      android_platform_view->GetAndroidContext();
  FML_DCHECK(android_context);

  // This is a synchronous call, so the captures don't have race checks.
  std::shared_ptr<VsyncWaiterAndroid> vsync_waiter;
  Shell::CreateCallback<PlatformView> on_create_platform_view =
      [&jni_facade, android_context, &weak_platform_view,
       &vsync_waiter](Shell& shell) {
        vsync_waiter =
            std::make_shared<VsyncWaiterAndroid>(shell.GetTaskRunners());
        std::unique_ptr<PlatformViewAndroid> platform_view_android;
        platform_view_android = std::make_unique<PlatformViewAndroid>(
            shell,                   // delegate
            shell.GetTaskRunners(),  // task runners
            jni_facade,              // JNI interop
            android_context,         // Android context
            MakePlatformDispatchTable(jni_facade,
                                      vsync_waiter)  // embedder callbacks
        );
        weak_platform_view = platform_view_android->GetWeakPtr();
        return platform_view_android;
      };

  Shell::CreateCallback<Rasterizer> on_create_rasterizer = [](Shell& shell) {
    return std::make_unique<Rasterizer>(shell);
  };

  auto config = BuildRunConfiguration(entrypoint, libraryUrl, entrypoint_args);
  if (!config) {
    // If the RunConfiguration was null, the kernel blob wasn't readable.
    // Fail the whole thing.
    return nullptr;
  }
  config->SetEngineId(engine_id);

  const uint64_t spawned_holder_id = NextHolderId();
  // embedder.h has no spawn API yet.
  std::unique_ptr<EmbedderEngine> spawned =
      reinterpret_cast<EmbedderEngine*>(engine_.get())
          ->Spawn(std::move(config.value()), initial_route,
                  on_create_platform_view, on_create_rasterizer,
                  MakeExternalTextureResolver(spawned_holder_id));
  UniqueEngine engine(
      reinterpret_cast<FLUTTER_API_SYMBOL(FlutterEngine)>(spawned.release()));

  return std::unique_ptr<AndroidShellHolder>(new AndroidShellHolder(
      GetSettings(), jni_facade, thread_host_, std::move(engine),
      spawned_holder_id, apk_asset_provider_->Clone(), weak_platform_view,
      std::move(vsync_waiter), android_context->RenderingApi()));
}

void AndroidShellHolder::Launch(
    std::unique_ptr<APKAssetProvider> apk_asset_provider,
    const std::string& entrypoint,
    const std::string& libraryUrl,
    const std::vector<std::string>& entrypoint_args,
    int64_t engine_id) {
  if (!IsValid()) {
    return;
  }

  apk_asset_provider_ = std::move(apk_asset_provider);
  auto config = BuildRunConfiguration(entrypoint, libraryUrl, entrypoint_args);
  if (!config) {
    return;
  }
  config->SetEngineId(engine_id);
  UpdateDisplayMetrics();
  GetShell(engine_.get()).RunEngine(std::move(config.value()));
}

Rasterizer::Screenshot AndroidShellHolder::Screenshot(
    Rasterizer::ScreenshotType type,
    bool base64_encode) {
  if (!IsValid()) {
    return {nullptr, DlISize(), "", Rasterizer::ScreenshotFormat::kUnknown};
  }
  FlutterScreenshotType screenshot_type;
  switch (type) {
    case Rasterizer::ScreenshotType::SkiaPicture:
      screenshot_type = kFlutterScreenshotTypeSkiaPicture;
      break;
    case Rasterizer::ScreenshotType::UncompressedImage:
      screenshot_type = kFlutterScreenshotTypeUncompressedImage;
      break;
    case Rasterizer::ScreenshotType::CompressedImage:
      screenshot_type = kFlutterScreenshotTypeCompressedImage;
      break;
    case Rasterizer::ScreenshotType::SurfaceData:
      screenshot_type = kFlutterScreenshotTypeSurfaceData;
      break;
  }
  FlutterScreenshotRequest request = {
      .struct_size = sizeof(FlutterScreenshotRequest),
      .type = screenshot_type,
      .base64_encode = base64_encode,
  };
  FlutterScreenshot c_screenshot = {
      .struct_size = sizeof(FlutterScreenshot),
  };
  FlutterEngineResult result =
      embedder_api_.Screenshot(engine_.get(), &request, &c_screenshot);
  if (result != kSuccess) {
    return {nullptr, DlISize(), "", Rasterizer::ScreenshotFormat::kUnknown};
  }
  sk_sp<SkData> data =
      c_screenshot.data != nullptr
          ? SkData::MakeWithCopy(c_screenshot.data, c_screenshot.data_length)
          : nullptr;
  DlISize frame_size(static_cast<int32_t>(c_screenshot.width),
                     static_cast<int32_t>(c_screenshot.height));
  std::string format = c_screenshot.format_description != nullptr
                           ? c_screenshot.format_description
                           : "";
  Rasterizer::ScreenshotFormat pixel_format =
      Rasterizer::ScreenshotFormat::kUnknown;
  switch (c_screenshot.format) {
    case kFlutterScreenshotFormatUnknown:
      pixel_format = Rasterizer::ScreenshotFormat::kUnknown;
      break;
    case kFlutterScreenshotFormatR8G8B8A8UNormInt:
      pixel_format = Rasterizer::ScreenshotFormat::kR8G8B8A8UNormInt;
      break;
    case kFlutterScreenshotFormatB8G8R8A8UNormInt:
      pixel_format = Rasterizer::ScreenshotFormat::kB8G8R8A8UNormInt;
      break;
    case kFlutterScreenshotFormatR16G16B16A16Float:
      pixel_format = Rasterizer::ScreenshotFormat::kR16G16B16A16Float;
      break;
  }
  embedder_api_.FreeScreenshot(&c_screenshot);
  return {std::move(data), frame_size, std::move(format), pixel_format};
}

fml::WeakPtr<PlatformViewAndroid> AndroidShellHolder::GetPlatformView() {
  FML_DCHECK(platform_view_);
  return platform_view_;
}

void AndroidShellHolder::NotifyLowMemoryWarning() {
  FML_DCHECK(engine_);
  FlutterEngineResult result =
      embedder_api_.NotifyLowMemoryWarning(engine_.get());
  if (result != kSuccess) {
    FML_LOG(ERROR) << "FlutterEngineNotifyLowMemoryWarning failed: " << result;
  }
}

const std::shared_ptr<PlatformMessageHandler>&
AndroidShellHolder::GetPlatformMessageHandler() const {
  return platform_message_handler_;
}

Shell* AndroidShellHolder::GetShellForTesting() const {
  return engine_ ? &GetShell(engine_.get()) : nullptr;
}

void AndroidShellHolder::SetSemanticsEnabled(bool enabled) {
  FlutterEngineResult result =
      embedder_api_.UpdateSemanticsEnabled(engine_.get(), enabled);
  if (result != kSuccess) {
    FML_LOG(ERROR) << "FlutterEngineUpdateSemanticsEnabled failed: " << result;
  }
}

void AndroidShellHolder::SetAccessibilityFeatures(int32_t flags) {
  FlutterEngineResult result = embedder_api_.UpdateAccessibilityFeatures(
      engine_.get(), static_cast<FlutterAccessibilityFeature>(flags));
  if (result != kSuccess) {
    FML_LOG(ERROR) << "FlutterEngineUpdateAccessibilityFeatures failed: "
                   << result;
  }
}

void AndroidShellHolder::DispatchSemanticsAction(int32_t node_id,
                                                 int32_t action,
                                                 fml::MallocMapping args) {
  // TODO(team-android): Remove implicit view assumption.
  // https://github.com/flutter/flutter/issues/142845
  FlutterSendSemanticsActionInfo info = {
      .struct_size = sizeof(FlutterSendSemanticsActionInfo),
      .view_id = kImplicitViewId,
      .node_id = static_cast<uint64_t>(node_id),
      .action = static_cast<FlutterSemanticsAction>(action),
      .data = args.GetMapping(),
      .data_length = args.GetSize(),
  };
  FlutterEngineResult result =
      embedder_api_.SendSemanticsAction(engine_.get(), &info);
  if (result != kSuccess) {
    FML_LOG(ERROR) << "FlutterEngineSendSemanticsAction failed: " << result;
  }
}

void AndroidShellHolder::ScheduleFrame() {
  FlutterEngineResult result = embedder_api_.ScheduleFrame(engine_.get());
  if (result != kSuccess) {
    FML_LOG(ERROR) << "FlutterEngineScheduleFrame failed: " << result;
  }
}

void AndroidShellHolder::SetViewportMetrics(int64_t view_id,
                                            const ViewportMetrics& metrics) {
  if (metrics.device_pixel_ratio <= 0.0 || metrics.physical_width < 0.0 ||
      metrics.physical_height < 0.0 ||
      metrics.physical_min_width_constraint < 0.0 ||
      metrics.physical_max_width_constraint < 0.0 ||
      metrics.physical_min_height_constraint < 0.0 ||
      metrics.physical_max_height_constraint < 0.0) {
    return;
  }

  const double width = metrics.physical_width;
  const double height = metrics.physical_height;
  const bool tight_zero_width_constraints =
      metrics.physical_min_width_constraint == 0.0 &&
      metrics.physical_max_width_constraint == 0.0;
  const bool tight_zero_height_constraints =
      metrics.physical_min_height_constraint == 0.0 &&
      metrics.physical_max_height_constraint == 0.0;
  const double min_width = tight_zero_width_constraints
                               ? width
                               : metrics.physical_min_width_constraint;
  const double max_width = tight_zero_width_constraints
                               ? width
                               : metrics.physical_max_width_constraint;
  const double min_height = tight_zero_height_constraints
                                ? height
                                : metrics.physical_min_height_constraint;
  const double max_height = tight_zero_height_constraints
                                ? height
                                : metrics.physical_max_height_constraint;

  if ((width == 0.0 && min_width == max_width) ||
      (height == 0.0 && min_height == max_height) || width < min_width ||
      width > max_width || height < min_height || height > max_height) {
    return;
  }

  constexpr size_t kCoordinatesPerFeatureBounds = 4;
  const size_t feature_count =
      std::min({metrics.physical_display_features_bounds.size() /
                    kCoordinatesPerFeatureBounds,
                metrics.physical_display_features_type.size(),
                metrics.physical_display_features_state.size(),
                static_cast<size_t>(kFlutterMaxDisplayFeatures)});

  std::vector<int32_t> feature_types(feature_count);
  std::vector<int32_t> feature_states(feature_count);
  for (size_t i = 0; i < feature_count; ++i) {
    const int32_t raw_type = metrics.physical_display_features_type[i];
    feature_types[i] =
        (raw_type >= kFlutterDisplayFeatureTypeUnknown &&
         raw_type <= kFlutterDisplayFeatureTypeCutout)
            ? raw_type
            : static_cast<int32_t>(kFlutterDisplayFeatureTypeUnknown);
    const int32_t raw_state = metrics.physical_display_features_state[i];
    feature_states[i] =
        raw_state >= kFlutterDisplayFeatureStateUnknown
            ? raw_state
            : static_cast<int32_t>(kFlutterDisplayFeatureStateUnknown);
  }

  FlutterWindowMetricsEvent event = {};
  event.struct_size = sizeof(FlutterWindowMetricsEvent);
  event.width = static_cast<size_t>(width);
  event.height = static_cast<size_t>(height);
  event.pixel_ratio = metrics.device_pixel_ratio;
  event.left = 0;
  event.top = 0;
  event.physical_view_inset_top =
      std::clamp(metrics.physical_view_inset_top, 0.0, height);
  event.physical_view_inset_right =
      std::clamp(metrics.physical_view_inset_right, 0.0, width);
  event.physical_view_inset_bottom =
      std::clamp(metrics.physical_view_inset_bottom, 0.0, height);
  event.physical_view_inset_left =
      std::clamp(metrics.physical_view_inset_left, 0.0, width);
  event.display_id = metrics.display_id;
  event.view_id = view_id;
  event.has_constraints = true;
  event.min_width_constraint = static_cast<size_t>(min_width);
  event.min_height_constraint = static_cast<size_t>(min_height);
  event.max_width_constraint = static_cast<size_t>(max_width);
  event.max_height_constraint = static_cast<size_t>(max_height);
  event.has_extended_metrics = true;
  event.physical_padding_top = std::max(0.0, metrics.physical_padding_top);
  event.physical_padding_right = std::max(0.0, metrics.physical_padding_right);
  event.physical_padding_bottom =
      std::max(0.0, metrics.physical_padding_bottom);
  event.physical_padding_left = std::max(0.0, metrics.physical_padding_left);
  event.physical_system_gesture_inset_top =
      std::max(0.0, metrics.physical_system_gesture_inset_top);
  event.physical_system_gesture_inset_right =
      std::max(0.0, metrics.physical_system_gesture_inset_right);
  event.physical_system_gesture_inset_bottom =
      std::max(0.0, metrics.physical_system_gesture_inset_bottom);
  event.physical_system_gesture_inset_left =
      std::max(0.0, metrics.physical_system_gesture_inset_left);
  event.physical_touch_slop = metrics.physical_touch_slop;
  event.display_features_count = feature_count;
  event.display_features_bounds =
      feature_count > 0 ? metrics.physical_display_features_bounds.data()
                        : nullptr;
  event.display_features_type =
      feature_count > 0 ? feature_types.data() : nullptr;
  event.display_features_state =
      feature_count > 0 ? feature_states.data() : nullptr;
  event.physical_display_corner_radius_top_left =
      metrics.physical_display_corner_radius_top_left;
  event.physical_display_corner_radius_top_right =
      metrics.physical_display_corner_radius_top_right;
  event.physical_display_corner_radius_bottom_right =
      metrics.physical_display_corner_radius_bottom_right;
  event.physical_display_corner_radius_bottom_left =
      metrics.physical_display_corner_radius_bottom_left;

  FlutterEngineResult result =
      embedder_api_.SendWindowMetricsEvent(engine_.get(), &event);
  if (result != kSuccess) {
    FML_LOG(ERROR) << "FlutterEngineSendWindowMetricsEvent failed: " << result;
  }
}

void AndroidShellHolder::DispatchPlatformMessage(const std::string& name,
                                                 const void* message_data,
                                                 int message_position,
                                                 int response_id) {
  if (message_position < 0) {
    return;
  }
  static const uint8_t kEmptyByte = 0;
  const uint8_t* bytes = message_position == 0
                             ? &kEmptyByte
                             : static_cast<const uint8_t*>(message_data);
  SendPlatformMessage(name, bytes, static_cast<size_t>(message_position),
                      response_id);
}

void AndroidShellHolder::DispatchEmptyPlatformMessage(const std::string& name,
                                                      int response_id) {
  SendPlatformMessage(name, nullptr, 0, response_id);
}

void AndroidShellHolder::SendPlatformMessage(const std::string& name,
                                             const uint8_t* message_data,
                                             size_t message_size,
                                             int response_id) {
  FlutterPlatformMessageResponseHandle* response_handle = nullptr;
  uintptr_t response_token = 0;
  if (response_id != 0) {
    response_token = GetPendingResponseTable().Register(holder_id_, jni_facade_,
                                                        response_id);
    FlutterEngineResult create_result =
        embedder_api_.PlatformMessageCreateResponseHandle(
            engine_.get(), &OnPlatformMessageResponse,
            reinterpret_cast<void*>(response_token), &response_handle);
    if (create_result != kSuccess) {
      GetPendingResponseTable().Take(response_token);
      FML_LOG(ERROR) << "FlutterPlatformMessageCreateResponseHandle failed: "
                     << create_result;
      return;
    }
  }

  FlutterPlatformMessage message = {};
  message.struct_size = sizeof(FlutterPlatformMessage);
  message.channel = name.c_str();
  message.message = message_data;
  message.message_size = message_size;
  message.response_handle = response_handle;

  FlutterEngineResult send_result =
      embedder_api_.SendPlatformMessage(engine_.get(), &message);
  if (send_result != kSuccess) {
    if (response_token != 0) {
      GetPendingResponseTable().Take(response_token);
    }
    FML_LOG(ERROR) << "FlutterEngineSendPlatformMessage failed: "
                   << send_result;
  }

  if (response_handle != nullptr) {
    FlutterEngineResult release_result =
        embedder_api_.PlatformMessageReleaseResponseHandle(engine_.get(),
                                                           response_handle);
    if (release_result != kSuccess) {
      FML_LOG(ERROR) << "FlutterPlatformMessageReleaseResponseHandle failed: "
                     << release_result;
    }
  }
}

void AndroidShellHolder::DispatchPointerDataPacket(const uint8_t* buffer,
                                                   int size_bytes) {
  if (buffer == nullptr || size_bytes <= 0) {
    return;
  }
  const auto unsigned_size = static_cast<size_t>(size_bytes);
  if (unsigned_size % sizeof(RawPointerDataRecord) != 0) {
    FML_LOG(ERROR) << "Pointer data packet size (" << size_bytes
                   << ") is not a multiple of " << sizeof(RawPointerDataRecord);
    return;
  }
  const size_t count = unsigned_size / sizeof(RawPointerDataRecord);
  std::vector<FlutterPointerEvent> events(count);
  for (size_t i = 0; i < count; ++i) {
    RawPointerDataRecord record = {};
    std::memcpy(&record, buffer + i * sizeof(RawPointerDataRecord),
                sizeof(RawPointerDataRecord));
    FlutterPointerEvent& event = events[i];
    event.struct_size = sizeof(FlutterPointerEvent);
    event.phase = ToFlutterPointerPhase(record.change);
    event.timestamp = static_cast<size_t>(record.time_stamp);
    event.x = record.physical_x;
    event.y = record.physical_y;
    event.device = static_cast<int32_t>(record.device);
    event.signal_kind = ToFlutterPointerSignalKind(record.signal_kind);
    event.scroll_delta_x = record.scroll_delta_x;
    event.scroll_delta_y = record.scroll_delta_y;
    event.device_kind = ToFlutterPointerDeviceKind(record.kind);
    event.buttons = record.buttons;
    event.pan_x = record.pan_x;
    event.pan_y = record.pan_y;
    event.scale = record.scale;
    event.rotation = record.rotation;
    event.view_id = record.view_id;
    event.pressure = record.pressure;
    event.pressure_min = record.pressure_min;
    event.pressure_max = record.pressure_max;
    event.distance = record.distance;
    event.distance_max = record.distance_max;
    event.size = record.size;
    event.radius_major = record.radius_major;
    event.radius_minor = record.radius_minor;
    event.radius_min = record.radius_min;
    event.radius_max = record.radius_max;
    event.orientation = record.orientation;
    event.tilt = record.tilt;
    event.platform_data = record.platform_data;
    event.embedder_id = record.embedder_id;
  }

  FlutterEngineResult result = embedder_api_.SendPointerEvent(
      engine_.get(), events.data(), events.size());
  if (result != kSuccess) {
    FML_LOG(ERROR) << "FlutterEngineSendPointerEvent failed: " << result;
  }
}

void AndroidShellHolder::LoadDartDeferredLibrary(
    intptr_t loading_unit_id,
    std::unique_ptr<const fml::Mapping> snapshot_data,
    std::unique_ptr<const fml::Mapping> snapshot_instructions) {
  struct DeferredLibraryContext {
    std::unique_ptr<const fml::Mapping> data;
    std::unique_ptr<const fml::Mapping> instructions;
  };
  auto* context = new DeferredLibraryContext{
      .data = std::move(snapshot_data),
      .instructions = std::move(snapshot_instructions),
  };

  FlutterDartDeferredLibrary deferred_library = {};
  deferred_library.struct_size = sizeof(FlutterDartDeferredLibrary);
  deferred_library.loading_unit_id = static_cast<int64_t>(loading_unit_id);
  if (context->data) {
    deferred_library.data = context->data->GetMapping();
    deferred_library.data_size = context->data->GetSize();
  }
  if (context->instructions) {
    deferred_library.instructions = context->instructions->GetMapping();
    deferred_library.instructions_size = context->instructions->GetSize();
  }
  deferred_library.user_data = context;
  deferred_library.destruction_callback = [](void* user_data) {
    delete static_cast<DeferredLibraryContext*>(user_data);
  };

  FlutterEngineResult result =
      embedder_api_.LoadDartDeferredLibrary(engine_.get(), &deferred_library);
  if (result != kSuccess) {
    delete context;
    FML_LOG(ERROR) << "FlutterEngineLoadDartDeferredLibrary failed: " << result;
  }
}

void AndroidShellHolder::LoadDartDeferredLibraryError(
    intptr_t loading_unit_id,
    const std::string& error_message,
    bool transient) {
  FlutterDartDeferredLibraryLoadError error = {};
  error.struct_size = sizeof(FlutterDartDeferredLibraryLoadError);
  error.loading_unit_id = static_cast<int64_t>(loading_unit_id);
  error.error_message = error_message.c_str();
  error.transient = transient;

  FlutterEngineResult result =
      embedder_api_.NotifyDartDeferredLibraryLoadError(engine_.get(), &error);
  if (result != kSuccess) {
    FML_LOG(ERROR) << "FlutterEngineNotifyDartDeferredLibraryLoadError failed: "
                   << result;
  }
}

void AndroidShellHolder::UpdateJavaAssetManager(
    std::unique_ptr<APKAssetProvider> asset_provider) {
  if (!asset_provider) {
    return;
  }
  FlutterAssetResolver resolver = asset_provider->ToFlutterAssetResolver();
  FlutterAssetResolverRegistrationInfo info = {};
  info.struct_size = sizeof(FlutterAssetResolverRegistrationInfo);
  info.resolver = &resolver;

  FlutterEngineResult result =
      embedder_api_.UpdateAssetResolver(engine_.get(), &info);
  if (result != kSuccess) {
    if (resolver.destruction_callback) {
      resolver.destruction_callback(resolver.user_data);
    }
    FML_LOG(ERROR) << "FlutterEngineUpdateAssetResolver failed: " << result;
  }
}

void AndroidShellHolder::RegisterExternalTexture(
    int64_t texture_id,
    const fml::jni::ScopedJavaGlobalRef<jobject>& surface_texture) {
  if (!platform_view_) {
    return;
  }
  std::unique_ptr<Texture> texture =
      platform_view_->CreateSurfaceTexture(texture_id, surface_texture);
  if (!texture) {
    return;
  }
  GetPendingTextureTable().Put(holder_id_, texture_id, std::move(texture));
  FlutterEngineResult result =
      embedder_api_.RegisterExternalTexture(engine_.get(), texture_id);
  GetPendingTextureTable().Take(holder_id_, texture_id);
  if (result != kSuccess) {
    FML_LOG(ERROR) << "FlutterEngineRegisterExternalTexture failed: " << result;
  }
}

void AndroidShellHolder::RegisterImageTexture(
    int64_t texture_id,
    const fml::jni::ScopedJavaGlobalRef<jobject>& image_texture_entry,
    ImageExternalTexture::ImageLifecycle lifecycle) {
  if (!platform_view_) {
    return;
  }
  std::unique_ptr<Texture> texture = platform_view_->CreateImageTexture(
      texture_id, image_texture_entry, lifecycle);
  if (!texture) {
    return;
  }
  GetPendingTextureTable().Put(holder_id_, texture_id, std::move(texture));
  FlutterEngineResult result =
      embedder_api_.RegisterExternalTexture(engine_.get(), texture_id);
  GetPendingTextureTable().Take(holder_id_, texture_id);
  if (result != kSuccess) {
    FML_LOG(ERROR) << "FlutterEngineRegisterExternalTexture failed: " << result;
  }
}

void AndroidShellHolder::UnregisterTexture(int64_t texture_id) {
  FlutterEngineResult result =
      embedder_api_.UnregisterExternalTexture(engine_.get(), texture_id);
  if (result != kSuccess) {
    FML_LOG(ERROR) << "FlutterEngineUnregisterExternalTexture failed: "
                   << result;
  }
}

void AndroidShellHolder::MarkTextureFrameAvailable(int64_t texture_id) {
  FlutterEngineResult result = embedder_api_.MarkExternalTextureFrameAvailable(
      engine_.get(), texture_id);
  if (result != kSuccess) {
    FML_LOG(ERROR) << "FlutterEngineMarkExternalTextureFrameAvailable failed: "
                   << result;
  }
}

void AndroidShellHolder::NotifySurfaceCreated(
    fml::RefPtr<AndroidNativeWindow> native_window) {
  if (platform_view_ &&
      platform_view_->SetNativeWindow(std::move(native_window))) {
    FlutterEngineResult callback_result = embedder_api_.SetNextFrameCallback(
        engine_.get(), &OnFirstFrameRendered,
        reinterpret_cast<void*>(static_cast<uintptr_t>(holder_id_)));
    if (callback_result != kSuccess) {
      FML_LOG(ERROR) << "FlutterEngineSetNextFrameCallback failed: "
                     << callback_result;
    }
  }
  FlutterEngineResult result = embedder_api_.NotifyCreated(engine_.get());
  if (result != kSuccess) {
    FML_LOG(ERROR) << "FlutterEngineNotifyCreated failed: " << result;
  }
}

void AndroidShellHolder::NotifySurfaceWindowChanged(
    fml::RefPtr<AndroidNativeWindow> native_window) {
  if (platform_view_) {
    platform_view_->SwapNativeWindow(std::move(native_window));
  }
  ScheduleFrame();
}

void AndroidShellHolder::NotifySurfaceChanged(int width, int height) {
  if (platform_view_) {
    platform_view_->ResizeSurface(DlISize(width, height));
  }
}

void AndroidShellHolder::NotifySurfaceDestroyed() {
  FlutterEngineResult result = embedder_api_.NotifyDestroyed(engine_.get());
  if (result != kSuccess) {
    FML_LOG(ERROR) << "FlutterEngineNotifyDestroyed failed: " << result;
  }
  if (platform_view_) {
    platform_view_->TeardownSurface();
  }
}

FlutterEngineProcTable& AndroidShellHolder::GetEmbedderApiForTesting() {
  return embedder_api_;
}

std::optional<RunConfiguration> AndroidShellHolder::BuildRunConfiguration(
    const std::string& entrypoint,
    const std::string& libraryUrl,
    const std::vector<std::string>& entrypoint_args) const {
  std::unique_ptr<IsolateConfiguration> isolate_configuration;
  if (flutter::DartVM::IsRunningPrecompiledCode()) {
    isolate_configuration = IsolateConfiguration::CreateForAppSnapshot();
  } else {
    std::unique_ptr<fml::Mapping> kernel_blob =
        fml::FileMapping::CreateReadOnly(
            GetSettings().application_kernel_asset);
    if (!kernel_blob) {
      FML_DLOG(ERROR) << "Unable to load the kernel blob asset.";
      return std::nullopt;
    }
    isolate_configuration =
        IsolateConfiguration::CreateForKernel(std::move(kernel_blob));
  }

  RunConfiguration config(std::move(isolate_configuration));
  config.AddAssetResolver(apk_asset_provider_->Clone());

  {
    if (!entrypoint.empty() && !libraryUrl.empty()) {
      config.SetEntrypointAndLibrary(entrypoint, libraryUrl);
    } else if (!entrypoint.empty()) {
      config.SetEntrypoint(entrypoint);
    }
    if (!entrypoint_args.empty()) {
      config.SetEntrypointArgs(entrypoint_args);
    }
  }
  return config;
}

void AndroidShellHolder::UpdateDisplayMetrics() {
  // Clamp negative sentinel values (-1.0 when the Java FlutterJNI object is
  // absent) to 0.0 before casting to unsigned size_t or validating density.
  constexpr double kMinNonNegativeDisplayMetric = 0.0;
  // Android currently reports a single primary display with ID 0.
  constexpr FlutterEngineDisplayId kPrimaryDisplayId = 0;
  constexpr size_t kSingleDisplayCount = 1;
  const double width =
      std::max(kMinNonNegativeDisplayMetric, jni_facade_->GetDisplayWidth());
  const double height =
      std::max(kMinNonNegativeDisplayMetric, jni_facade_->GetDisplayHeight());
  const double density =
      std::max(kMinNonNegativeDisplayMetric, jni_facade_->GetDisplayDensity());
  FlutterEngineDisplay display = {
      .struct_size = sizeof(FlutterEngineDisplay),
      .display_id = kPrimaryDisplayId,
      .single_display = true,
      .refresh_rate = jni_facade_->GetDisplayRefreshRate(),
      .width = static_cast<size_t>(width),
      .height = static_cast<size_t>(height),
      .device_pixel_ratio = density,
  };
  FlutterEngineResult result = embedder_api_.NotifyDisplayUpdate(
      engine_.get(), kFlutterEngineDisplaysUpdateTypeStartup, &display,
      kSingleDisplayCount);
  if (result != kSuccess) {
    FML_LOG(ERROR) << "FlutterEngineNotifyDisplayUpdate failed: " << result;
  }
}

bool AndroidShellHolder::IsSurfaceControlEnabled() {
  return GetPlatformView()->IsSurfaceControlEnabled();
}

}  // namespace flutter
