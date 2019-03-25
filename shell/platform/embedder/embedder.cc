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

extern "C" {
#if FLUTTER_RUNTIME_MODE == FLUTTER_RUNTIME_MODE_DEBUG
// Used for debugging dart:* sources.
extern const uint8_t kPlatformStrongDill[];
extern const intptr_t kPlatformStrongDillSize;
#endif  // FLUTTER_RUNTIME_MODE == FLUTTER_RUNTIME_MODE_DEBUG
}

#include "flutter/shell/platform/embedder/embedder.h"

#include <type_traits>

#include "flutter/assets/directory_asset_bundle.h"
#include "flutter/common/task_runners.h"
#include "flutter/fml/command_line.h"
#include "flutter/fml/file.h"
#include "flutter/fml/make_copyable.h"
#include "flutter/fml/message_loop.h"
#include "flutter/fml/paths.h"
#include "flutter/fml/trace_event.h"
#include "flutter/shell/common/persistent_cache.h"
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

static FlutterEngineResult LogEmbedderError(FlutterEngineResult code,
                                            const char* name,
                                            const char* function,
                                            const char* file,
                                            int line) {
  FML_LOG(ERROR) << "Returning error '" << name << "' (" << code
                 << ") from Flutter Embedder API call to '" << __FUNCTION__
                 << "'. Origin: " << file << ":" << line;
  return code;
}

#define LOG_EMBEDDER_ERROR(code) \
  LogEmbedderError(code, #code, __FUNCTION__, __FILE__, __LINE__)

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

void PopulateSnapshotMappingCallbacks(const FlutterProjectArgs* args,
                                      blink::Settings& settings) {
  // There are no ownership concerns here as all mappings are owned by the
  // embedder and not the engine.
  auto make_mapping_callback = [](const uint8_t* mapping, size_t size) {
    return [mapping, size]() {
      return std::make_unique<fml::NonOwnedMapping>(mapping, size);
    };
  };

  if (blink::DartVM::IsRunningPrecompiledCode()) {
    if (SAFE_ACCESS(args, vm_snapshot_data_size, 0) != 0 &&
        SAFE_ACCESS(args, vm_snapshot_data, nullptr) != nullptr) {
      settings.vm_snapshot_data = make_mapping_callback(
          args->vm_snapshot_data, args->vm_snapshot_data_size);
    }

    if (SAFE_ACCESS(args, vm_snapshot_instructions_size, 0) != 0 &&
        SAFE_ACCESS(args, vm_snapshot_instructions, nullptr) != nullptr) {
      settings.vm_snapshot_instr = make_mapping_callback(
          args->vm_snapshot_instructions, args->vm_snapshot_instructions_size);
    }

    if (SAFE_ACCESS(args, isolate_snapshot_data_size, 0) != 0 &&
        SAFE_ACCESS(args, isolate_snapshot_data, nullptr) != nullptr) {
      settings.isolate_snapshot_data = make_mapping_callback(
          args->isolate_snapshot_data, args->isolate_snapshot_data_size);
    }

    if (SAFE_ACCESS(args, isolate_snapshot_instructions_size, 0) != 0 &&
        SAFE_ACCESS(args, isolate_snapshot_instructions, nullptr) != nullptr) {
      settings.isolate_snapshot_instr =
          make_mapping_callback(args->isolate_snapshot_instructions,
                                args->isolate_snapshot_instructions_size);
    }
  }

#if !OS_FUCHSIA && (FLUTTER_RUNTIME_MODE == FLUTTER_RUNTIME_MODE_DEBUG)
  settings.dart_library_sources_kernel =
      make_mapping_callback(kPlatformStrongDill, kPlatformStrongDillSize);
#endif  // !OS_FUCHSIA && (FLUTTER_RUNTIME_MODE == FLUTTER_RUNTIME_MODE_DEBUG)
}

FlutterEngineResult FlutterEngineRun(size_t version,
                                     const FlutterRendererConfig* config,
                                     const FlutterProjectArgs* args,
                                     void* user_data,
                                     FlutterEngine* engine_out) {
  // Step 0: Figure out arguments for shell creation.
  if (version != FLUTTER_ENGINE_VERSION) {
    return LOG_EMBEDDER_ERROR(kInvalidLibraryVersion);
  }

  if (engine_out == nullptr) {
    return LOG_EMBEDDER_ERROR(kInvalidArguments);
  }

  if (args == nullptr) {
    return LOG_EMBEDDER_ERROR(kInvalidArguments);
  }

  if (SAFE_ACCESS(args, assets_path, nullptr) == nullptr) {
    return LOG_EMBEDDER_ERROR(kInvalidArguments);
  }

  if (SAFE_ACCESS(args, main_path__unused__, nullptr) != nullptr) {
    FML_LOG(WARNING)
        << "FlutterProjectArgs.main_path is deprecated and should be set null.";
  }

  if (SAFE_ACCESS(args, packages_path__unused__, nullptr) != nullptr) {
    FML_LOG(WARNING) << "FlutterProjectArgs.packages_path is deprecated and "
                        "should be set null.";
  }

  if (!IsRendererValid(config)) {
    return LOG_EMBEDDER_ERROR(kInvalidArguments);
  }

  std::string icu_data_path;
  if (SAFE_ACCESS(args, icu_data_path, nullptr) != nullptr) {
    icu_data_path = SAFE_ACCESS(args, icu_data_path, nullptr);
  }

  if (SAFE_ACCESS(args, persistent_cache_path, nullptr) != nullptr) {
    std::string persistent_cache_path =
        SAFE_ACCESS(args, persistent_cache_path, nullptr);
    shell::PersistentCache::SetCacheDirectoryPath(persistent_cache_path);
  }

  if (SAFE_ACCESS(args, is_persistent_cache_read_only, false)) {
    shell::PersistentCache::gIsReadOnly = true;
  }

  fml::CommandLine command_line;
  if (SAFE_ACCESS(args, command_line_argc, 0) != 0 &&
      SAFE_ACCESS(args, command_line_argv, nullptr) != nullptr) {
    command_line = fml::CommandLineFromArgcArgv(
        SAFE_ACCESS(args, command_line_argc, 0),
        SAFE_ACCESS(args, command_line_argv, nullptr));
  }

  blink::Settings settings = shell::SettingsFromCommandLine(command_line);

  PopulateSnapshotMappingCallbacks(args, settings);

  settings.icu_data_path = icu_data_path;
  settings.assets_path = args->assets_path;

  if (!blink::DartVM::IsRunningPrecompiledCode()) {
    // Verify the assets path contains Dart 2 kernel assets.
    const std::string kApplicationKernelSnapshotFileName = "kernel_blob.bin";
    std::string application_kernel_path = fml::paths::JoinPaths(
        {settings.assets_path, kApplicationKernelSnapshotFileName});
    if (!fml::IsFile(application_kernel_path)) {
      FML_LOG(ERROR) << "Not running in AOT mode but could not resolve the "
                        "kernel binary.";
      return LOG_EMBEDDER_ERROR(kInvalidArguments);
    }
    settings.application_kernel_asset = kApplicationKernelSnapshotFileName;
  }

  settings.task_observer_add = [](intptr_t key, fml::closure callback) {
    fml::MessageLoop::GetCurrent().AddTaskObserver(key, std::move(callback));
  };
  settings.task_observer_remove = [](intptr_t key) {
    fml::MessageLoop::GetCurrent().RemoveTaskObserver(key);
  };
  if (SAFE_ACCESS(args, root_isolate_create_callback, nullptr) != nullptr) {
    VoidCallback callback =
        SAFE_ACCESS(args, root_isolate_create_callback, nullptr);
    settings.root_isolate_create_callback = [callback, user_data]() {
      callback(user_data);
    };
  }

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

  shell::PlatformViewEmbedder::UpdateSemanticsNodesCallback
      update_semantics_nodes_callback = nullptr;
  if (SAFE_ACCESS(args, update_semantics_node_callback, nullptr) != nullptr) {
    update_semantics_nodes_callback =
        [ptr = args->update_semantics_node_callback,
         user_data](blink::SemanticsNodeUpdates update) {
          for (const auto& value : update) {
            const auto& node = value.second;
            SkMatrix transform = static_cast<SkMatrix>(node.transform);
            FlutterTransformation flutter_transform{
                transform.get(SkMatrix::kMScaleX),
                transform.get(SkMatrix::kMSkewX),
                transform.get(SkMatrix::kMTransX),
                transform.get(SkMatrix::kMSkewY),
                transform.get(SkMatrix::kMScaleY),
                transform.get(SkMatrix::kMTransY),
                transform.get(SkMatrix::kMPersp0),
                transform.get(SkMatrix::kMPersp1),
                transform.get(SkMatrix::kMPersp2)};
            const FlutterSemanticsNode embedder_node{
                sizeof(FlutterSemanticsNode),
                node.id,
                static_cast<FlutterSemanticsFlag>(node.flags),
                static_cast<FlutterSemanticsAction>(node.actions),
                node.textSelectionBase,
                node.textSelectionExtent,
                node.scrollChildren,
                node.scrollIndex,
                node.scrollPosition,
                node.scrollExtentMax,
                node.scrollExtentMin,
                node.elevation,
                node.thickness,
                node.label.c_str(),
                node.hint.c_str(),
                node.value.c_str(),
                node.increasedValue.c_str(),
                node.decreasedValue.c_str(),
                static_cast<FlutterTextDirection>(node.textDirection),
                FlutterRect{node.rect.fLeft, node.rect.fTop, node.rect.fRight,
                            node.rect.fBottom},
                flutter_transform,
                node.childrenInTraversalOrder.size(),
                &node.childrenInTraversalOrder[0],
                &node.childrenInHitTestOrder[0],
                node.customAccessibilityActions.size(),
                &node.customAccessibilityActions[0],
            };
            ptr(&embedder_node, user_data);
          }
          const FlutterSemanticsNode batch_end_sentinel = {
              sizeof(FlutterSemanticsNode),
              kFlutterSemanticsNodeIdBatchEnd,
          };
          ptr(&batch_end_sentinel, user_data);
        };
  }

  shell::PlatformViewEmbedder::UpdateSemanticsCustomActionsCallback
      update_semantics_custom_actions_callback = nullptr;
  if (SAFE_ACCESS(args, update_semantics_custom_action_callback, nullptr) !=
      nullptr) {
    update_semantics_custom_actions_callback =
        [ptr = args->update_semantics_custom_action_callback,
         user_data](blink::CustomAccessibilityActionUpdates actions) {
          for (const auto& value : actions) {
            const auto& action = value.second;
            const FlutterSemanticsCustomAction embedder_action = {
                sizeof(FlutterSemanticsCustomAction),
                action.id,
                static_cast<FlutterSemanticsAction>(action.overrideId),
                action.label.c_str(),
                action.hint.c_str(),
            };
            ptr(&embedder_action, user_data);
          }
          const FlutterSemanticsCustomAction batch_end_sentinel = {
              sizeof(FlutterSemanticsCustomAction),
              kFlutterSemanticsCustomActionIdBatchEnd,
          };
          ptr(&batch_end_sentinel, user_data);
        };
  }

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

  shell::VsyncWaiterEmbedder::VsyncCallback vsync_callback = nullptr;
  if (SAFE_ACCESS(args, vsync_callback, nullptr) != nullptr) {
    vsync_callback = [ptr = args->vsync_callback, user_data](intptr_t baton) {
      return ptr(user_data, baton);
    };
  }

  shell::PlatformViewEmbedder::PlatformDispatchTable platform_dispatch_table = {
      update_semantics_nodes_callback,           //
      update_semantics_custom_actions_callback,  //
      platform_message_response_callback,        //
      vsync_callback,                            //
  };

  auto on_create_platform_view = InferPlatformViewCreationCallback(
      config, user_data, platform_dispatch_table);

  if (!on_create_platform_view) {
    return LOG_EMBEDDER_ERROR(kInvalidArguments);
  }

  shell::Shell::CreateCallback<shell::Rasterizer> on_create_rasterizer =
      [](shell::Shell& shell) {
        return std::make_unique<shell::Rasterizer>(shell.GetTaskRunners());
      };

  // TODO(chinmaygarde): This is the wrong spot for this. It belongs in the
  // platform view jump table.
  shell::EmbedderExternalTextureGL::ExternalTextureCallback
      external_texture_callback;
  if (config->type == kOpenGL) {
    const FlutterOpenGLRendererConfig* open_gl_config = &config->open_gl;
    if (SAFE_ACCESS(open_gl_config, gl_external_texture_frame_callback,
                    nullptr) != nullptr) {
      external_texture_callback =
          [ptr = open_gl_config->gl_external_texture_frame_callback, user_data](
              int64_t texture_identifier, GrContext* context,
              const SkISize& size) -> sk_sp<SkImage> {
        FlutterOpenGLTexture texture = {};

        if (!ptr(user_data, texture_identifier, size.width(), size.height(),
                 &texture)) {
          return nullptr;
        }

        GrGLTextureInfo gr_texture_info = {texture.target, texture.name,
                                           texture.format};

        GrBackendTexture gr_backend_texture(size.width(), size.height(),
                                            GrMipMapped::kNo, gr_texture_info);
        SkImage::TextureReleaseProc release_proc = texture.destruction_callback;
        auto image = SkImage::MakeFromTexture(
            context,                   // context
            gr_backend_texture,        // texture handle
            kTopLeft_GrSurfaceOrigin,  // origin
            kRGBA_8888_SkColorType,    // color type
            kPremul_SkAlphaType,       // alpha type
            nullptr,                   // colorspace
            release_proc,              // texture release proc
            texture.user_data          // texture release context
        );

        if (!image) {
          // In case Skia rejects the image, call the release proc so that
          // embedders can perform collection of intermediates.
          if (release_proc) {
            release_proc(texture.user_data);
          }
          FML_LOG(ERROR) << "Could not create external texture.";
          return nullptr;
        }

        return image;
      };
    }
  }

  // Step 1: Create the engine.
  auto embedder_engine =
      std::make_unique<shell::EmbedderEngine>(std::move(thread_host),    //
                                              std::move(task_runners),   //
                                              settings,                  //
                                              on_create_platform_view,   //
                                              on_create_rasterizer,      //
                                              external_texture_callback  //
      );

  if (!embedder_engine->IsValid()) {
    return LOG_EMBEDDER_ERROR(kInvalidArguments);
  }

  // Step 2: Setup the rendering surface.
  if (!embedder_engine->NotifyCreated()) {
    return LOG_EMBEDDER_ERROR(kInvalidArguments);
  }

  // Step 3: Run the engine.
  auto run_configuration = shell::RunConfiguration::InferFromSettings(settings);

  run_configuration.AddAssetResolver(
      std::make_unique<blink::DirectoryAssetBundle>(
          fml::Duplicate(settings.assets_dir)));

  run_configuration.AddAssetResolver(
      std::make_unique<blink::DirectoryAssetBundle>(fml::OpenDirectory(
          settings.assets_path.c_str(), false, fml::FilePermission::kRead)));
  if (!run_configuration.IsValid()) {
    return LOG_EMBEDDER_ERROR(kInvalidArguments);
  }

  if (!embedder_engine->Run(std::move(run_configuration))) {
    return LOG_EMBEDDER_ERROR(kInvalidArguments);
  }

  // Finally! Release the ownership of the embedder engine to the caller.
  *engine_out = reinterpret_cast<FlutterEngine>(embedder_engine.release());
  return kSuccess;
}

FlutterEngineResult FlutterEngineShutdown(FlutterEngine engine) {
  if (engine == nullptr) {
    return LOG_EMBEDDER_ERROR(kInvalidArguments);
  }
  auto embedder_engine = reinterpret_cast<shell::EmbedderEngine*>(engine);
  embedder_engine->NotifyDestroyed();
  delete embedder_engine;
  return kSuccess;
}

FlutterEngineResult FlutterEngineSendWindowMetricsEvent(
    FlutterEngine engine,
    const FlutterWindowMetricsEvent* flutter_metrics) {
  if (engine == nullptr || flutter_metrics == nullptr) {
    return LOG_EMBEDDER_ERROR(kInvalidArguments);
  }

  blink::ViewportMetrics metrics;

  metrics.physical_width = SAFE_ACCESS(flutter_metrics, width, 0.0);
  metrics.physical_height = SAFE_ACCESS(flutter_metrics, height, 0.0);
  metrics.device_pixel_ratio = SAFE_ACCESS(flutter_metrics, pixel_ratio, 1.0);

  return reinterpret_cast<shell::EmbedderEngine*>(engine)->SetViewportMetrics(
             std::move(metrics))
             ? kSuccess
             : LOG_EMBEDDER_ERROR(kInvalidArguments);
}

// Returns the blink::PointerData::Change for the given FlutterPointerPhase.
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
    case kAdd:
      return blink::PointerData::Change::kAdd;
    case kRemove:
      return blink::PointerData::Change::kRemove;
    case kHover:
      return blink::PointerData::Change::kHover;
  }
  return blink::PointerData::Change::kCancel;
}

// Returns the blink::PointerData::SignalKind for the given
// FlutterPointerSignaKind.
inline blink::PointerData::SignalKind ToPointerDataSignalKind(
    FlutterPointerSignalKind kind) {
  switch (kind) {
    case kFlutterPointerSignalKindNone:
      return blink::PointerData::SignalKind::kNone;
    case kFlutterPointerSignalKindScroll:
      return blink::PointerData::SignalKind::kScroll;
  }
  return blink::PointerData::SignalKind::kNone;
}

FlutterEngineResult FlutterEngineSendPointerEvent(
    FlutterEngine engine,
    const FlutterPointerEvent* pointers,
    size_t events_count) {
  if (engine == nullptr || pointers == nullptr || events_count == 0) {
    return LOG_EMBEDDER_ERROR(kInvalidArguments);
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
    pointer_data.device = SAFE_ACCESS(current, device, 0);
    pointer_data.signal_kind = ToPointerDataSignalKind(
        SAFE_ACCESS(current, signal_kind, kFlutterPointerSignalKindNone));
    pointer_data.scroll_delta_x = SAFE_ACCESS(current, scroll_delta_x, 0.0);
    pointer_data.scroll_delta_y = SAFE_ACCESS(current, scroll_delta_y, 0.0);
    packet->SetPointerData(i, pointer_data);
    current = reinterpret_cast<const FlutterPointerEvent*>(
        reinterpret_cast<const uint8_t*>(current) + current->struct_size);
  }

  return reinterpret_cast<shell::EmbedderEngine*>(engine)
                 ->DispatchPointerDataPacket(std::move(packet))
             ? kSuccess
             : LOG_EMBEDDER_ERROR(kInvalidArguments);
}

FlutterEngineResult FlutterEngineSendPlatformMessage(
    FlutterEngine engine,
    const FlutterPlatformMessage* flutter_message) {
  if (engine == nullptr || flutter_message == nullptr) {
    return LOG_EMBEDDER_ERROR(kInvalidArguments);
  }

  if (SAFE_ACCESS(flutter_message, channel, nullptr) == nullptr ||
      SAFE_ACCESS(flutter_message, message, nullptr) == nullptr) {
    return LOG_EMBEDDER_ERROR(kInvalidArguments);
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
             : LOG_EMBEDDER_ERROR(kInvalidArguments);
}

FlutterEngineResult FlutterEngineSendPlatformMessageResponse(
    FlutterEngine engine,
    const FlutterPlatformMessageResponseHandle* handle,
    const uint8_t* data,
    size_t data_length) {
  if (data_length != 0 && data == nullptr) {
    return LOG_EMBEDDER_ERROR(kInvalidArguments);
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

FlutterEngineResult __FlutterEngineFlushPendingTasksNow() {
  fml::MessageLoop::GetCurrent().RunExpiredTasksNow();
  return kSuccess;
}

FlutterEngineResult FlutterEngineRegisterExternalTexture(
    FlutterEngine engine,
    int64_t texture_identifier) {
  if (engine == nullptr || texture_identifier == 0) {
    return LOG_EMBEDDER_ERROR(kInvalidArguments);
  }
  if (!reinterpret_cast<shell::EmbedderEngine*>(engine)->RegisterTexture(
          texture_identifier)) {
    return LOG_EMBEDDER_ERROR(kInternalInconsistency);
  }
  return kSuccess;
}

FlutterEngineResult FlutterEngineUnregisterExternalTexture(
    FlutterEngine engine,
    int64_t texture_identifier) {
  if (engine == nullptr || texture_identifier == 0) {
    return kInvalidArguments;
  }

  if (!reinterpret_cast<shell::EmbedderEngine*>(engine)->UnregisterTexture(
          texture_identifier)) {
    return LOG_EMBEDDER_ERROR(kInternalInconsistency);
  }

  return kSuccess;
}

FlutterEngineResult FlutterEngineMarkExternalTextureFrameAvailable(
    FlutterEngine engine,
    int64_t texture_identifier) {
  if (engine == nullptr || texture_identifier == 0) {
    return LOG_EMBEDDER_ERROR(kInvalidArguments);
  }
  if (!reinterpret_cast<shell::EmbedderEngine*>(engine)
           ->MarkTextureFrameAvailable(texture_identifier)) {
    return LOG_EMBEDDER_ERROR(kInternalInconsistency);
  }
  return kSuccess;
}

FlutterEngineResult FlutterEngineUpdateSemanticsEnabled(FlutterEngine engine,
                                                        bool enabled) {
  if (engine == nullptr) {
    return LOG_EMBEDDER_ERROR(kInvalidArguments);
  }
  if (!reinterpret_cast<shell::EmbedderEngine*>(engine)->SetSemanticsEnabled(
          enabled)) {
    return LOG_EMBEDDER_ERROR(kInternalInconsistency);
  }
  return kSuccess;
}

FlutterEngineResult FlutterEngineUpdateAccessibilityFeatures(
    FlutterEngine engine,
    FlutterAccessibilityFeature flags) {
  if (engine == nullptr) {
    return LOG_EMBEDDER_ERROR(kInvalidArguments);
  }
  if (!reinterpret_cast<shell::EmbedderEngine*>(engine)
           ->SetAccessibilityFeatures(flags)) {
    return LOG_EMBEDDER_ERROR(kInternalInconsistency);
  }
  return kSuccess;
}

FlutterEngineResult FlutterEngineDispatchSemanticsAction(
    FlutterEngine engine,
    uint64_t id,
    FlutterSemanticsAction action,
    const uint8_t* data,
    size_t data_length) {
  if (engine == nullptr) {
    return LOG_EMBEDDER_ERROR(kInvalidArguments);
  }
  auto engine_action = static_cast<blink::SemanticsAction>(action);
  if (!reinterpret_cast<shell::EmbedderEngine*>(engine)
           ->DispatchSemanticsAction(
               id, engine_action,
               std::vector<uint8_t>({data, data + data_length}))) {
    return LOG_EMBEDDER_ERROR(kInternalInconsistency);
  }
  return kSuccess;
}

FlutterEngineResult FlutterEngineOnVsync(FlutterEngine engine,
                                         intptr_t baton,
                                         uint64_t frame_start_time_nanos,
                                         uint64_t frame_target_time_nanos) {
  if (engine == nullptr) {
    return LOG_EMBEDDER_ERROR(kInvalidArguments);
  }

  TRACE_EVENT0("flutter", "FlutterEngineOnVsync");

  auto start_time = fml::TimePoint::FromEpochDelta(
      fml::TimeDelta::FromNanoseconds(frame_start_time_nanos));

  auto target_time = fml::TimePoint::FromEpochDelta(
      fml::TimeDelta::FromNanoseconds(frame_target_time_nanos));

  if (!reinterpret_cast<shell::EmbedderEngine*>(engine)->OnVsyncEvent(
          baton, start_time, target_time)) {
    return LOG_EMBEDDER_ERROR(kInternalInconsistency);
  }

  return kSuccess;
}

void FlutterEngineTraceEventDurationBegin(const char* name) {
  fml::tracing::TraceEvent0("flutter", name);
}

void FlutterEngineTraceEventDurationEnd(const char* name) {
  fml::tracing::TraceEventEnd(name);
}

void FlutterEngineTraceEventInstant(const char* name) {
  fml::tracing::TraceEventInstant0("flutter", name);
}

FlutterEngineResult FlutterEnginePostRenderThreadTask(FlutterEngine engine,
                                                      VoidCallback callback,
                                                      void* baton) {
  if (engine == nullptr || callback == nullptr) {
    return LOG_EMBEDDER_ERROR(kInvalidArguments);
  }

  auto task = [callback, baton]() { callback(baton); };

  return reinterpret_cast<shell::EmbedderEngine*>(engine)->PostRenderThreadTask(
             task)
             ? kSuccess
             : LOG_EMBEDDER_ERROR(kInternalInconsistency);
}
