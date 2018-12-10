// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#define FML_USED_ON_EMBEDDER

#include "flutter/fml/build_config.h"
#include "flutter/fml/native_library.h"

#if OS_WIN
#define FLUTTER_EXPORT __declspec(dllexport)
#else  // OS_WIN
#define FLUTTER_EXPORT __attribute__((visibility("default")))
#endif  // OS_WIN

#include "flutter/shell/platform/embedder/embedder.h"

#include <type_traits>

#include "flutter/assets/directory_asset_bundle.h"
#include "flutter/common/task_runners.h"
#include "flutter/fml/command_line.h"
#include "flutter/fml/file.h"
#include "flutter/fml/make_copyable.h"
#include "flutter/fml/message_loop.h"
#include "flutter/fml/paths.h"
#include "flutter/shell/common/rasterizer.h"
#include "flutter/shell/common/switches.h"
#include "flutter/shell/platform/embedder/embedder.h"
#include "flutter/shell/platform/embedder/embedder_engine.h"
#include "flutter/shell/platform/embedder/platform_view_embedder.h"

#define SAFE_ACCESS(pointer, member, default_value)                      \
  ([=]() {                                                               \
    if (offsetof(std::remove_pointer<decltype(pointer)>::type, member) + \
            sizeof(pointer->member) <=                                   \
        pointer->struct_size) {                                          \
      return pointer->member;                                            \
    }                                                                    \
    return static_cast<decltype(pointer->member)>((default_value));      \
  })()

static bool IsOpenGLRendererConfigValid(const FlutterRendererConfig* config) {
  if (config->type != kOpenGL) {
    return false;
  }

  const FlutterOpenGLRendererConfig* open_gl_config = &config->open_gl;

  if (SAFE_ACCESS(open_gl_config, make_current, nullptr) == nullptr ||
      SAFE_ACCESS(open_gl_config, clear_current, nullptr) == nullptr ||
      SAFE_ACCESS(open_gl_config, present, nullptr) == nullptr ||
      SAFE_ACCESS(open_gl_config, fbo_callback, nullptr) == nullptr) {
    return false;
  }

  return true;
}

static bool IsSoftwareRendererConfigValid(const FlutterRendererConfig* config) {
  if (config->type != kSoftware) {
    return false;
  }

  const FlutterSoftwareRendererConfig* software_config = &config->software;

  if (SAFE_ACCESS(software_config, surface_present_callback, nullptr) ==
      nullptr) {
    return false;
  }

  return true;
}

static bool IsRendererValid(const FlutterRendererConfig* config) {
  if (config == nullptr) {
    return false;
  }

  switch (config->type) {
    case kOpenGL:
      return IsOpenGLRendererConfigValid(config);
    case kSoftware:
      return IsSoftwareRendererConfigValid(config);
    default:
      return false;
  }

  return false;
}

#if OS_LINUX || OS_WIN
static void* DefaultGLProcResolver(const char* name) {
  static fml::RefPtr<fml::NativeLibrary> proc_library =
#if OS_LINUX
      fml::NativeLibrary::CreateForCurrentProcess();
#elif OS_WIN  // OS_LINUX
      fml::NativeLibrary::Create("opengl32.dll");
#endif        // OS_WIN
  return static_cast<void*>(
      const_cast<uint8_t*>(proc_library->ResolveSymbol(name)));
}
#endif  // OS_LINUX || OS_WIN

static shell::Shell::CreateCallback<shell::PlatformView>
InferOpenGLPlatformViewCreationCallback(
    const FlutterRendererConfig* config,
    void* user_data,
    shell::PlatformViewEmbedder::PlatformDispatchTable
        platform_dispatch_table) {
  if (config->type != kOpenGL) {
    return nullptr;
  }

  auto gl_make_current = [ptr = config->open_gl.make_current,
                          user_data]() -> bool { return ptr(user_data); };

  auto gl_clear_current = [ptr = config->open_gl.clear_current,
                           user_data]() -> bool { return ptr(user_data); };

  auto gl_present = [ptr = config->open_gl.present, user_data]() -> bool {
    return ptr(user_data);
  };

  auto gl_fbo_callback = [ptr = config->open_gl.fbo_callback,
                          user_data]() -> intptr_t { return ptr(user_data); };

  const FlutterOpenGLRendererConfig* open_gl_config = &config->open_gl;
  std::function<bool()> gl_make_resource_current_callback = nullptr;
  if (SAFE_ACCESS(open_gl_config, make_resource_current, nullptr) != nullptr) {
    gl_make_resource_current_callback =
        [ptr = config->open_gl.make_resource_current, user_data]() {
          return ptr(user_data);
        };
  }

  std::function<SkMatrix(void)> gl_surface_transformation_callback = nullptr;
  if (SAFE_ACCESS(open_gl_config, surface_transformation, nullptr) != nullptr) {
    gl_surface_transformation_callback =
        [ptr = config->open_gl.surface_transformation, user_data]() {
          FlutterTransformation transformation = ptr(user_data);
          return SkMatrix::MakeAll(transformation.scaleX,  //
                                   transformation.skewX,   //
                                   transformation.transX,  //
                                   transformation.skewY,   //
                                   transformation.scaleY,  //
                                   transformation.transY,  //
                                   transformation.pers0,   //
                                   transformation.pers1,   //
                                   transformation.pers2    //
          );
        };
  }

  shell::GPUSurfaceGLDelegate::GLProcResolver gl_proc_resolver = nullptr;
  if (SAFE_ACCESS(open_gl_config, gl_proc_resolver, nullptr) != nullptr) {
    gl_proc_resolver = [ptr = config->open_gl.gl_proc_resolver,
                        user_data](const char* gl_proc_name) {
      return ptr(user_data, gl_proc_name);
    };
  } else {
#if OS_LINUX || OS_WIN
    gl_proc_resolver = DefaultGLProcResolver;
#endif
  }

  bool fbo_reset_after_present =
      SAFE_ACCESS(open_gl_config, fbo_reset_after_present, false);

  shell::EmbedderSurfaceGL::GLDispatchTable gl_dispatch_table = {
      gl_make_current,                     // gl_make_current_callback
      gl_clear_current,                    // gl_clear_current_callback
      gl_present,                          // gl_present_callback
      gl_fbo_callback,                     // gl_fbo_callback
      gl_make_resource_current_callback,   // gl_make_resource_current_callback
      gl_surface_transformation_callback,  // gl_surface_transformation_callback
      gl_proc_resolver,                    // gl_proc_resolver
  };

  return [gl_dispatch_table, fbo_reset_after_present,
          platform_dispatch_table](shell::Shell& shell) {
    return std::make_unique<shell::PlatformViewEmbedder>(
        shell,                    // delegate
        shell.GetTaskRunners(),   // task runners
        gl_dispatch_table,        // embedder GL dispatch table
        fbo_reset_after_present,  // fbo reset after present
        platform_dispatch_table   // embedder platform dispatch table
    );
  };
}

static shell::Shell::CreateCallback<shell::PlatformView>
InferSoftwarePlatformViewCreationCallback(
    const FlutterRendererConfig* config,
    void* user_data,
    shell::PlatformViewEmbedder::PlatformDispatchTable
        platform_dispatch_table) {
  if (config->type != kSoftware) {
    return nullptr;
  }

  auto software_present_backing_store =
      [ptr = config->software.surface_present_callback, user_data](
          const void* allocation, size_t row_bytes, size_t height) -> bool {
    return ptr(user_data, allocation, row_bytes, height);
  };

  shell::EmbedderSurfaceSoftware::SoftwareDispatchTable
      software_dispatch_table = {
          software_present_backing_store,  // required
      };

  return
      [software_dispatch_table, platform_dispatch_table](shell::Shell& shell) {
        return std::make_unique<shell::PlatformViewEmbedder>(
            shell,                    // delegate
            shell.GetTaskRunners(),   // task runners
            software_dispatch_table,  // software dispatch table
            platform_dispatch_table   // platform dispatch table
        );
      };
}

static shell::Shell::CreateCallback<shell::PlatformView>
InferPlatformViewCreationCallback(
    const FlutterRendererConfig* config,
    void* user_data,
    shell::PlatformViewEmbedder::PlatformDispatchTable
        platform_dispatch_table) {
  if (config == nullptr) {
    return nullptr;
  }

  switch (config->type) {
    case kOpenGL:
      return InferOpenGLPlatformViewCreationCallback(config, user_data,
                                                     platform_dispatch_table);
    case kSoftware:
      return InferSoftwarePlatformViewCreationCallback(config, user_data,
                                                       platform_dispatch_table);
    default:
      return nullptr;
  }
  return nullptr;
}

struct _FlutterPlatformMessageResponseHandle {
  fml::RefPtr<blink::PlatformMessage> message;
};

FlutterResult FlutterEngineRun(size_t version,
                               const FlutterRendererConfig* config,
                               const FlutterProjectArgs* args,
                               void* user_data,
                               FlutterEngine* engine_out) {
  // Step 0: Figure out arguments for shell creation.
  if (version != FLUTTER_ENGINE_VERSION) {
    return kInvalidLibraryVersion;
  }

  if (engine_out == nullptr) {
    return kInvalidArguments;
  }

  if (args == nullptr) {
    return kInvalidArguments;
  }

  if (SAFE_ACCESS(args, assets_path, nullptr) == nullptr) {
    return kInvalidArguments;
  }

  if (!IsRendererValid(config)) {
    return kInvalidArguments;
  }

  std::string icu_data_path;
  if (SAFE_ACCESS(args, icu_data_path, nullptr) != nullptr) {
    icu_data_path = SAFE_ACCESS(args, icu_data_path, nullptr);
  }

  fml::CommandLine command_line;
  if (SAFE_ACCESS(args, command_line_argc, 0) != 0 &&
      SAFE_ACCESS(args, command_line_argv, nullptr) != nullptr) {
    command_line = fml::CommandLineFromArgcArgv(
        SAFE_ACCESS(args, command_line_argc, 0),
        SAFE_ACCESS(args, command_line_argv, nullptr));
  }

  blink::Settings settings = shell::SettingsFromCommandLine(command_line);
  settings.icu_data_path = icu_data_path;
  settings.assets_path = args->assets_path;

  // Verify the assets path contains Dart 2 kernel assets.
  const std::string kApplicationKernelSnapshotFileName = "kernel_blob.bin";
  std::string application_kernel_path = fml::paths::JoinPaths(
      {settings.assets_path, kApplicationKernelSnapshotFileName});
  if (!fml::IsFile(application_kernel_path)) {
    return kInvalidArguments;
  }
  settings.application_kernel_asset = kApplicationKernelSnapshotFileName;

  settings.task_observer_add = [](intptr_t key, fml::closure callback) {
    fml::MessageLoop::GetCurrent().AddTaskObserver(key, std::move(callback));
  };
  settings.task_observer_remove = [](intptr_t key) {
    fml::MessageLoop::GetCurrent().RemoveTaskObserver(key);
  };

  // Create a thread host with the current thread as the platform thread and all
  // other threads managed.
  shell::ThreadHost thread_host("io.flutter", shell::ThreadHost::Type::GPU |
                                                  shell::ThreadHost::Type::IO |
                                                  shell::ThreadHost::Type::UI);
  fml::MessageLoop::EnsureInitializedForCurrentThread();
  blink::TaskRunners task_runners(
      "io.flutter",
      fml::MessageLoop::GetCurrent().GetTaskRunner(),  // platform
      thread_host.gpu_thread->GetTaskRunner(),         // gpu
      thread_host.ui_thread->GetTaskRunner(),          // ui
      thread_host.io_thread->GetTaskRunner()           // io
  );

  shell::PlatformViewEmbedder::PlatformMessageResponseCallback
      platform_message_response_callback = nullptr;
  if (SAFE_ACCESS(args, platform_message_callback, nullptr) != nullptr) {
    platform_message_response_callback =
        [ptr = args->platform_message_callback,
         user_data](fml::RefPtr<blink::PlatformMessage> message) {
          auto handle = new FlutterPlatformMessageResponseHandle();
          const FlutterPlatformMessage incoming_message = {
              sizeof(FlutterPlatformMessage),  // struct_size
              message->channel().c_str(),      // channel
              message->data().data(),          // message
              message->data().size(),          // message_size
              handle,                          // response_handle
          };
          handle->message = std::move(message);
          return ptr(&incoming_message, user_data);
        };
  }

  shell::PlatformViewEmbedder::PlatformDispatchTable platform_dispatch_table = {
      platform_message_response_callback,  // platform_message_response_callback
  };

  auto on_create_platform_view = InferPlatformViewCreationCallback(
      config, user_data, platform_dispatch_table);

  if (!on_create_platform_view) {
    return kInvalidArguments;
  }

  shell::Shell::CreateCallback<shell::Rasterizer> on_create_rasterizer =
      [](shell::Shell& shell) {
        return std::make_unique<shell::Rasterizer>(shell.GetTaskRunners());
      };

  // Step 1: Create the engine.
  auto embedder_engine =
      std::make_unique<shell::EmbedderEngine>(std::move(thread_host),   //
                                              std::move(task_runners),  //
                                              settings,                 //
                                              on_create_platform_view,  //
                                              on_create_rasterizer      //
      );

  if (!embedder_engine->IsValid()) {
    return kInvalidArguments;
  }

  // Step 2: Setup the rendering surface.
  if (!embedder_engine->NotifyCreated()) {
    return kInvalidArguments;
  }

  // Step 3: Run the engine.
  auto run_configuration = shell::RunConfiguration::InferFromSettings(settings);

  run_configuration.AddAssetResolver(
      std::make_unique<blink::DirectoryAssetBundle>(
          fml::Duplicate(settings.assets_dir)));

  run_configuration.AddAssetResolver(
      std::make_unique<blink::DirectoryAssetBundle>(fml::OpenDirectory(
          settings.assets_path.c_str(), false, fml::FilePermission::kRead)));

  if (!embedder_engine->Run(std::move(run_configuration))) {
    return kInvalidArguments;
  }

  // Finally! Release the ownership of the embedder engine to the caller.
  *engine_out = reinterpret_cast<FlutterEngine>(embedder_engine.release());
  return kSuccess;
}

FlutterResult FlutterEngineShutdown(FlutterEngine engine) {
  if (engine == nullptr) {
    return kInvalidArguments;
  }
  auto embedder_engine = reinterpret_cast<shell::EmbedderEngine*>(engine);
  embedder_engine->NotifyDestroyed();
  delete embedder_engine;
  return kSuccess;
}

FlutterResult FlutterEngineSendWindowMetricsEvent(
    FlutterEngine engine,
    const FlutterWindowMetricsEvent* flutter_metrics) {
  if (engine == nullptr || flutter_metrics == nullptr) {
    return kInvalidArguments;
  }

  blink::ViewportMetrics metrics;

  metrics.physical_width = SAFE_ACCESS(flutter_metrics, width, 0.0);
  metrics.physical_height = SAFE_ACCESS(flutter_metrics, height, 0.0);
  metrics.device_pixel_ratio = SAFE_ACCESS(flutter_metrics, pixel_ratio, 1.0);

  return reinterpret_cast<shell::EmbedderEngine*>(engine)->SetViewportMetrics(
             std::move(metrics))
             ? kSuccess
             : kInvalidArguments;
}

inline blink::PointerData::Change ToPointerDataChange(
    FlutterPointerPhase phase) {
  switch (phase) {
    case kCancel:
      return blink::PointerData::Change::kCancel;
    case kUp:
      return blink::PointerData::Change::kUp;
    case kDown:
      return blink::PointerData::Change::kDown;
    case kMove:
      return blink::PointerData::Change::kMove;
  }
  return blink::PointerData::Change::kCancel;
}

FlutterResult FlutterEngineSendPointerEvent(FlutterEngine engine,
                                            const FlutterPointerEvent* pointers,
                                            size_t events_count) {
  if (engine == nullptr || pointers == nullptr || events_count == 0) {
    return kInvalidArguments;
  }

  auto packet = std::make_unique<blink::PointerDataPacket>(events_count);

  const FlutterPointerEvent* current = pointers;

  for (size_t i = 0; i < events_count; ++i) {
    blink::PointerData pointer_data;
    pointer_data.Clear();
    pointer_data.time_stamp = SAFE_ACCESS(current, timestamp, 0);
    pointer_data.change = ToPointerDataChange(
        SAFE_ACCESS(current, phase, FlutterPointerPhase::kCancel));
    pointer_data.kind = blink::PointerData::DeviceKind::kMouse;
    pointer_data.physical_x = SAFE_ACCESS(current, x, 0.0);
    pointer_data.physical_y = SAFE_ACCESS(current, y, 0.0);
    packet->SetPointerData(i, pointer_data);
    current = reinterpret_cast<const FlutterPointerEvent*>(
        reinterpret_cast<const uint8_t*>(current) + current->struct_size);
  }

  return reinterpret_cast<shell::EmbedderEngine*>(engine)
                 ->DispatchPointerDataPacket(std::move(packet))
             ? kSuccess
             : kInvalidArguments;
}

FlutterResult FlutterEngineSendPlatformMessage(
    FlutterEngine engine,
    const FlutterPlatformMessage* flutter_message) {
  if (engine == nullptr || flutter_message == nullptr) {
    return kInvalidArguments;
  }

  if (SAFE_ACCESS(flutter_message, channel, nullptr) == nullptr ||
      SAFE_ACCESS(flutter_message, message, nullptr) == nullptr) {
    return kInvalidArguments;
  }

  auto message = fml::MakeRefCounted<blink::PlatformMessage>(
      flutter_message->channel,
      std::vector<uint8_t>(
          flutter_message->message,
          flutter_message->message + flutter_message->message_size),
      nullptr);

  return reinterpret_cast<shell::EmbedderEngine*>(engine)->SendPlatformMessage(
             std::move(message))
             ? kSuccess
             : kInvalidArguments;
}

FlutterResult FlutterEngineSendPlatformMessageResponse(
    FlutterEngine engine,
    const FlutterPlatformMessageResponseHandle* handle,
    const uint8_t* data,
    size_t data_length) {
  if (data_length != 0 && data == nullptr) {
    return kInvalidArguments;
  }

  auto response = handle->message->response();

  if (data_length == 0) {
    response->CompleteEmpty();
  } else {
    response->Complete(std::make_unique<fml::DataMapping>(
        std::vector<uint8_t>({data, data + data_length})));
  }

  delete handle;

  return kSuccess;
}

FlutterResult __FlutterEngineFlushPendingTasksNow() {
  fml::MessageLoop::GetCurrent().RunExpiredTasksNow();
  return kSuccess;
}
