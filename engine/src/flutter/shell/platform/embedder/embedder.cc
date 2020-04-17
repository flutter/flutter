// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#define FML_USED_ON_EMBEDDER
#define RAPIDJSON_HAS_STDSTRING 1

#include <iostream>

#include "flutter/fml/build_config.h"
#include "flutter/fml/closure.h"
#include "flutter/fml/make_copyable.h"
#include "flutter/fml/native_library.h"
#include "third_party/dart/runtime/include/dart_native_api.h"

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
#include "flutter/shell/platform/embedder/embedder_platform_message_response.h"
#include "flutter/shell/platform/embedder/embedder_render_target.h"
#include "flutter/shell/platform/embedder/embedder_safe_access.h"
#include "flutter/shell/platform/embedder/embedder_task_runner.h"
#include "flutter/shell/platform/embedder/embedder_thread_host.h"
#include "flutter/shell/platform/embedder/platform_view_embedder.h"
#include "rapidjson/rapidjson.h"
#include "rapidjson/writer.h"

const int32_t kFlutterSemanticsNodeIdBatchEnd = -1;
const int32_t kFlutterSemanticsCustomActionIdBatchEnd = -1;

static FlutterEngineResult LogEmbedderError(FlutterEngineResult code,
                                            const char* reason,
                                            const char* code_name,
                                            const char* function,
                                            const char* file,
                                            int line) {
#if OS_WIN
  constexpr char kSeparator = '\\';
#else
  constexpr char kSeparator = '/';
#endif
  const auto file_base =
      (::strrchr(file, kSeparator) ? strrchr(file, kSeparator) + 1 : file);
  char error[256] = {};
  snprintf(error, (sizeof(error) / sizeof(char)),
           "%s (%d): '%s' returned '%s'. %s", file_base, line, function,
           code_name, reason);
  std::cerr << error << std::endl;
  return code;
}

#define LOG_EMBEDDER_ERROR(code, reason) \
  LogEmbedderError(code, reason, #code, __FUNCTION__, __FILE__, __LINE__)

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

static flutter::Shell::CreateCallback<flutter::PlatformView>
InferOpenGLPlatformViewCreationCallback(
    const FlutterRendererConfig* config,
    void* user_data,
    flutter::PlatformViewEmbedder::PlatformDispatchTable
        platform_dispatch_table,
    std::unique_ptr<flutter::EmbedderExternalViewEmbedder>
        external_view_embedder) {
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

    // If there is an external view embedder, ask it to apply the surface
    // transformation to its surfaces as well.
    if (external_view_embedder) {
      external_view_embedder->SetSurfaceTransformationCallback(
          gl_surface_transformation_callback);
    }
  }

  flutter::GPUSurfaceGLDelegate::GLProcResolver gl_proc_resolver = nullptr;
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

  flutter::EmbedderSurfaceGL::GLDispatchTable gl_dispatch_table = {
      gl_make_current,                     // gl_make_current_callback
      gl_clear_current,                    // gl_clear_current_callback
      gl_present,                          // gl_present_callback
      gl_fbo_callback,                     // gl_fbo_callback
      gl_make_resource_current_callback,   // gl_make_resource_current_callback
      gl_surface_transformation_callback,  // gl_surface_transformation_callback
      gl_proc_resolver,                    // gl_proc_resolver
  };

  return fml::MakeCopyable(
      [gl_dispatch_table, fbo_reset_after_present, platform_dispatch_table,
       external_view_embedder =
           std::move(external_view_embedder)](flutter::Shell& shell) mutable {
        return std::make_unique<flutter::PlatformViewEmbedder>(
            shell,                    // delegate
            shell.GetTaskRunners(),   // task runners
            gl_dispatch_table,        // embedder GL dispatch table
            fbo_reset_after_present,  // fbo reset after present
            platform_dispatch_table,  // embedder platform dispatch table
            std::move(external_view_embedder)  // external view embedder
        );
      });
}

static flutter::Shell::CreateCallback<flutter::PlatformView>
InferSoftwarePlatformViewCreationCallback(
    const FlutterRendererConfig* config,
    void* user_data,
    flutter::PlatformViewEmbedder::PlatformDispatchTable
        platform_dispatch_table,
    std::unique_ptr<flutter::EmbedderExternalViewEmbedder>
        external_view_embedder) {
  if (config->type != kSoftware) {
    return nullptr;
  }

  auto software_present_backing_store =
      [ptr = config->software.surface_present_callback, user_data](
          const void* allocation, size_t row_bytes, size_t height) -> bool {
    return ptr(user_data, allocation, row_bytes, height);
  };

  flutter::EmbedderSurfaceSoftware::SoftwareDispatchTable
      software_dispatch_table = {
          software_present_backing_store,  // required
      };

  return fml::MakeCopyable(
      [software_dispatch_table, platform_dispatch_table,
       external_view_embedder =
           std::move(external_view_embedder)](flutter::Shell& shell) mutable {
        return std::make_unique<flutter::PlatformViewEmbedder>(
            shell,                             // delegate
            shell.GetTaskRunners(),            // task runners
            software_dispatch_table,           // software dispatch table
            platform_dispatch_table,           // platform dispatch table
            std::move(external_view_embedder)  // external view embedder
        );
      });
}

static flutter::Shell::CreateCallback<flutter::PlatformView>
InferPlatformViewCreationCallback(
    const FlutterRendererConfig* config,
    void* user_data,
    flutter::PlatformViewEmbedder::PlatformDispatchTable
        platform_dispatch_table,
    std::unique_ptr<flutter::EmbedderExternalViewEmbedder>
        external_view_embedder) {
  if (config == nullptr) {
    return nullptr;
  }

  switch (config->type) {
    case kOpenGL:
      return InferOpenGLPlatformViewCreationCallback(
          config, user_data, platform_dispatch_table,
          std::move(external_view_embedder));
    case kSoftware:
      return InferSoftwarePlatformViewCreationCallback(
          config, user_data, platform_dispatch_table,
          std::move(external_view_embedder));
    default:
      return nullptr;
  }
  return nullptr;
}

static sk_sp<SkSurface> MakeSkSurfaceFromBackingStore(
    GrContext* context,
    const FlutterBackingStoreConfig& config,
    const FlutterOpenGLTexture* texture) {
  GrGLTextureInfo texture_info;
  texture_info.fTarget = texture->target;
  texture_info.fID = texture->name;
  texture_info.fFormat = texture->format;

  GrBackendTexture backend_texture(config.size.width,   //
                                   config.size.height,  //
                                   GrMipMapped::kNo,    //
                                   texture_info         //
  );

  SkSurfaceProps surface_properties(
      SkSurfaceProps::InitType::kLegacyFontHost_InitType);

  auto surface = SkSurface::MakeFromBackendTexture(
      context,                      // context
      backend_texture,              // back-end texture
      kBottomLeft_GrSurfaceOrigin,  // surface origin
      1,                            // sample count
      kN32_SkColorType,             // color type
      SkColorSpace::MakeSRGB(),     // color space
      &surface_properties,          // surface properties
      static_cast<SkSurface::TextureReleaseProc>(
          texture->destruction_callback),  // release proc
      texture->user_data                   // release context
  );

  if (!surface) {
    FML_LOG(ERROR) << "Could not wrap embedder supplied render texture.";
    texture->destruction_callback(texture->user_data);
    return nullptr;
  }

  return surface;
}

static sk_sp<SkSurface> MakeSkSurfaceFromBackingStore(
    GrContext* context,
    const FlutterBackingStoreConfig& config,
    const FlutterOpenGLFramebuffer* framebuffer) {
  GrGLFramebufferInfo framebuffer_info = {};
  framebuffer_info.fFormat = framebuffer->target;
  framebuffer_info.fFBOID = framebuffer->name;

  GrBackendRenderTarget backend_render_target(
      config.size.width,   // width
      config.size.height,  // height
      1,                   // sample count
      0,                   // stencil bits
      framebuffer_info     // framebuffer info
  );

  SkSurfaceProps surface_properties(
      SkSurfaceProps::InitType::kLegacyFontHost_InitType);

  auto surface = SkSurface::MakeFromBackendRenderTarget(
      context,                      //  context
      backend_render_target,        // backend render target
      kBottomLeft_GrSurfaceOrigin,  // surface origin
      kN32_SkColorType,             // color type
      SkColorSpace::MakeSRGB(),     // color space
      &surface_properties,          // surface properties
      static_cast<SkSurface::RenderTargetReleaseProc>(
          framebuffer->destruction_callback),  // release proc
      framebuffer->user_data                   // release context
  );

  if (!surface) {
    FML_LOG(ERROR) << "Could not wrap embedder supplied frame-buffer.";
    framebuffer->destruction_callback(framebuffer->user_data);
    return nullptr;
  }
  return surface;
}

static sk_sp<SkSurface> MakeSkSurfaceFromBackingStore(
    GrContext* context,
    const FlutterBackingStoreConfig& config,
    const FlutterSoftwareBackingStore* software) {
  const auto image_info =
      SkImageInfo::MakeN32Premul(config.size.width, config.size.height);

  struct Captures {
    VoidCallback destruction_callback;
    void* user_data;
  };
  auto captures = std::make_unique<Captures>();
  captures->destruction_callback = software->destruction_callback;
  captures->user_data = software->user_data;
  auto release_proc = [](void* pixels, void* context) {
    auto captures = reinterpret_cast<Captures*>(context);
    captures->destruction_callback(captures->user_data);
  };

  auto surface = SkSurface::MakeRasterDirectReleaseProc(
      image_info,                               // image info
      const_cast<void*>(software->allocation),  // pixels
      software->row_bytes,                      // row bytes
      release_proc,                             // release proc
      captures.release()                        // release context
  );

  if (!surface) {
    FML_LOG(ERROR)
        << "Could not wrap embedder supplied software render buffer.";
    software->destruction_callback(software->user_data);
    return nullptr;
  }
  return surface;
}

static std::unique_ptr<flutter::EmbedderRenderTarget>
CreateEmbedderRenderTarget(const FlutterCompositor* compositor,
                           const FlutterBackingStoreConfig& config,
                           GrContext* context) {
  FlutterBackingStore backing_store = {};
  backing_store.struct_size = sizeof(backing_store);

  // Safe access checks on the compositor struct have been performed in
  // InferExternalViewEmbedderFromArgs and are not necessary here.
  auto c_create_callback = compositor->create_backing_store_callback;
  auto c_collect_callback = compositor->collect_backing_store_callback;

  {
    TRACE_EVENT0("flutter", "FlutterCompositorCreateBackingStore");
    if (!c_create_callback(&config, &backing_store, compositor->user_data)) {
      FML_LOG(ERROR) << "Could not create the embedder backing store.";
      return nullptr;
    }
  }

  if (backing_store.struct_size != sizeof(backing_store)) {
    FML_LOG(ERROR) << "Embedder modified the backing store struct size.";
    return nullptr;
  }

  // In case we return early without creating an embedder render target, the
  // embedder has still given us ownership of its baton which we must return
  // back to it. If this method is successful, the closure is released when the
  // render target is eventually released.
  fml::ScopedCleanupClosure collect_callback(
      [c_collect_callback, backing_store, user_data = compositor->user_data]() {
        TRACE_EVENT0("flutter", "FlutterCompositorCollectBackingStore");
        c_collect_callback(&backing_store, user_data);
      });

  // No safe access checks on the renderer are necessary since we allocated
  // the struct.

  sk_sp<SkSurface> render_surface;

  switch (backing_store.type) {
    case kFlutterBackingStoreTypeOpenGL:
      switch (backing_store.open_gl.type) {
        case kFlutterOpenGLTargetTypeTexture:
          render_surface = MakeSkSurfaceFromBackingStore(
              context, config, &backing_store.open_gl.texture);
          break;
        case kFlutterOpenGLTargetTypeFramebuffer:
          render_surface = MakeSkSurfaceFromBackingStore(
              context, config, &backing_store.open_gl.framebuffer);
          break;
      }
      break;
    case kFlutterBackingStoreTypeSoftware:
      render_surface = MakeSkSurfaceFromBackingStore(context, config,
                                                     &backing_store.software);
      break;
  };

  if (!render_surface) {
    FML_LOG(ERROR) << "Could not create a surface from an embedder provided "
                      "render target.";
    return nullptr;
  }

  return std::make_unique<flutter::EmbedderRenderTarget>(
      backing_store, std::move(render_surface), collect_callback.Release());
}

static std::pair<std::unique_ptr<flutter::EmbedderExternalViewEmbedder>,
                 bool /* halt engine launch if true */>
InferExternalViewEmbedderFromArgs(const FlutterCompositor* compositor) {
  if (compositor == nullptr) {
    return {nullptr, false};
  }

  auto c_create_callback =
      SAFE_ACCESS(compositor, create_backing_store_callback, nullptr);
  auto c_collect_callback =
      SAFE_ACCESS(compositor, collect_backing_store_callback, nullptr);
  auto c_present_callback =
      SAFE_ACCESS(compositor, present_layers_callback, nullptr);

  // Make sure the required callbacks are present
  if (!c_create_callback || !c_collect_callback || !c_present_callback) {
    FML_LOG(ERROR) << "Required compositor callbacks absent.";
    return {nullptr, true};
  }

  FlutterCompositor captured_compositor = *compositor;

  flutter::EmbedderExternalViewEmbedder::CreateRenderTargetCallback
      create_render_target_callback =
          [captured_compositor](GrContext* context, const auto& config) {
            return CreateEmbedderRenderTarget(&captured_compositor, config,
                                              context);
          };

  flutter::EmbedderExternalViewEmbedder::PresentCallback present_callback =
      [c_present_callback,
       user_data = compositor->user_data](const auto& layers) {
        TRACE_EVENT0("flutter", "FlutterCompositorPresentLayers");
        return c_present_callback(
            const_cast<const FlutterLayer**>(layers.data()), layers.size(),
            user_data);
      };

  return {std::make_unique<flutter::EmbedderExternalViewEmbedder>(
              create_render_target_callback, present_callback),
          false};
}

struct _FlutterPlatformMessageResponseHandle {
  fml::RefPtr<flutter::PlatformMessage> message;
};

void PopulateSnapshotMappingCallbacks(const FlutterProjectArgs* args,
                                      flutter::Settings& settings) {
  // There are no ownership concerns here as all mappings are owned by the
  // embedder and not the engine.
  auto make_mapping_callback = [](const uint8_t* mapping, size_t size) {
    return [mapping, size]() {
      return std::make_unique<fml::NonOwnedMapping>(mapping, size);
    };
  };

  if (flutter::DartVM::IsRunningPrecompiledCode()) {
    if (SAFE_ACCESS(args, vm_snapshot_data, nullptr) != nullptr) {
      settings.vm_snapshot_data = make_mapping_callback(
          args->vm_snapshot_data, SAFE_ACCESS(args, vm_snapshot_data_size, 0));
    }

    if (SAFE_ACCESS(args, vm_snapshot_instructions, nullptr) != nullptr) {
      settings.vm_snapshot_instr = make_mapping_callback(
          args->vm_snapshot_instructions,
          SAFE_ACCESS(args, vm_snapshot_instructions_size, 0));
    }

    if (SAFE_ACCESS(args, isolate_snapshot_data, nullptr) != nullptr) {
      settings.isolate_snapshot_data = make_mapping_callback(
          args->isolate_snapshot_data,
          SAFE_ACCESS(args, isolate_snapshot_data_size, 0));
    }

    if (SAFE_ACCESS(args, isolate_snapshot_instructions, nullptr) != nullptr) {
      settings.isolate_snapshot_instr = make_mapping_callback(
          args->isolate_snapshot_instructions,
          SAFE_ACCESS(args, isolate_snapshot_instructions_size, 0));
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
                                     FLUTTER_API_SYMBOL(FlutterEngine) *
                                         engine_out) {
  auto result =
      FlutterEngineInitialize(version, config, args, user_data, engine_out);

  if (result != kSuccess) {
    return result;
  }

  return FlutterEngineRunInitialized(*engine_out);
}

FlutterEngineResult FlutterEngineInitialize(size_t version,
                                            const FlutterRendererConfig* config,
                                            const FlutterProjectArgs* args,
                                            void* user_data,
                                            FLUTTER_API_SYMBOL(FlutterEngine) *
                                                engine_out) {
  // Step 0: Figure out arguments for shell creation.
  if (version != FLUTTER_ENGINE_VERSION) {
    return LOG_EMBEDDER_ERROR(
        kInvalidLibraryVersion,
        "Flutter embedder version mismatch. There has been a breaking change. "
        "Please consult the changelog and update the embedder.");
  }

  if (engine_out == nullptr) {
    return LOG_EMBEDDER_ERROR(kInvalidArguments,
                              "The engine out parameter was missing.");
  }

  if (args == nullptr) {
    return LOG_EMBEDDER_ERROR(kInvalidArguments,
                              "The Flutter project arguments were missing.");
  }

  if (SAFE_ACCESS(args, assets_path, nullptr) == nullptr) {
    return LOG_EMBEDDER_ERROR(
        kInvalidArguments,
        "The assets path in the Flutter project arguments was missing.");
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
    return LOG_EMBEDDER_ERROR(kInvalidArguments,
                              "The renderer configuration was invalid.");
  }

  std::string icu_data_path;
  if (SAFE_ACCESS(args, icu_data_path, nullptr) != nullptr) {
    icu_data_path = SAFE_ACCESS(args, icu_data_path, nullptr);
  }

  if (SAFE_ACCESS(args, persistent_cache_path, nullptr) != nullptr) {
    std::string persistent_cache_path =
        SAFE_ACCESS(args, persistent_cache_path, nullptr);
    flutter::PersistentCache::SetCacheDirectoryPath(persistent_cache_path);
  }

  if (SAFE_ACCESS(args, is_persistent_cache_read_only, false)) {
    flutter::PersistentCache::gIsReadOnly = true;
  }

  fml::CommandLine command_line;
  if (SAFE_ACCESS(args, command_line_argc, 0) != 0 &&
      SAFE_ACCESS(args, command_line_argv, nullptr) != nullptr) {
    command_line = fml::CommandLineFromArgcArgv(
        SAFE_ACCESS(args, command_line_argc, 0),
        SAFE_ACCESS(args, command_line_argv, nullptr));
  }

  flutter::Settings settings = flutter::SettingsFromCommandLine(command_line);

  PopulateSnapshotMappingCallbacks(args, settings);

  settings.icu_data_path = icu_data_path;
  settings.assets_path = args->assets_path;
  settings.leak_vm = !SAFE_ACCESS(args, shutdown_dart_vm_when_done, false);
  settings.old_gen_heap_size = SAFE_ACCESS(args, dart_old_gen_heap_size, -1);

  if (!flutter::DartVM::IsRunningPrecompiledCode()) {
    // Verify the assets path contains Dart 2 kernel assets.
    const std::string kApplicationKernelSnapshotFileName = "kernel_blob.bin";
    std::string application_kernel_path = fml::paths::JoinPaths(
        {settings.assets_path, kApplicationKernelSnapshotFileName});
    if (!fml::IsFile(application_kernel_path)) {
      return LOG_EMBEDDER_ERROR(
          kInvalidArguments,
          "Not running in AOT mode but could not resolve the kernel binary.");
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

  flutter::PlatformViewEmbedder::UpdateSemanticsNodesCallback
      update_semantics_nodes_callback = nullptr;
  if (SAFE_ACCESS(args, update_semantics_node_callback, nullptr) != nullptr) {
    update_semantics_nodes_callback =
        [ptr = args->update_semantics_node_callback,
         user_data](flutter::SemanticsNodeUpdates update) {
          for (const auto& value : update) {
            const auto& node = value.second;
            SkMatrix transform = node.transform.asM33();
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
                node.platformViewId,
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

  flutter::PlatformViewEmbedder::UpdateSemanticsCustomActionsCallback
      update_semantics_custom_actions_callback = nullptr;
  if (SAFE_ACCESS(args, update_semantics_custom_action_callback, nullptr) !=
      nullptr) {
    update_semantics_custom_actions_callback =
        [ptr = args->update_semantics_custom_action_callback,
         user_data](flutter::CustomAccessibilityActionUpdates actions) {
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

  flutter::PlatformViewEmbedder::PlatformMessageResponseCallback
      platform_message_response_callback = nullptr;
  if (SAFE_ACCESS(args, platform_message_callback, nullptr) != nullptr) {
    platform_message_response_callback =
        [ptr = args->platform_message_callback,
         user_data](fml::RefPtr<flutter::PlatformMessage> message) {
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

  flutter::VsyncWaiterEmbedder::VsyncCallback vsync_callback = nullptr;
  if (SAFE_ACCESS(args, vsync_callback, nullptr) != nullptr) {
    vsync_callback = [ptr = args->vsync_callback, user_data](intptr_t baton) {
      return ptr(user_data, baton);
    };
  }

  auto external_view_embedder_result =
      InferExternalViewEmbedderFromArgs(SAFE_ACCESS(args, compositor, nullptr));
  if (external_view_embedder_result.second) {
    return LOG_EMBEDDER_ERROR(kInvalidArguments,
                              "Compositor arguments were invalid.");
  }

  flutter::PlatformViewEmbedder::PlatformDispatchTable platform_dispatch_table =
      {
          update_semantics_nodes_callback,           //
          update_semantics_custom_actions_callback,  //
          platform_message_response_callback,        //
          vsync_callback,                            //
      };

  auto on_create_platform_view = InferPlatformViewCreationCallback(
      config, user_data, platform_dispatch_table,
      std::move(external_view_embedder_result.first));

  if (!on_create_platform_view) {
    return LOG_EMBEDDER_ERROR(
        kInternalInconsistency,
        "Could not infer platform view creation callback.");
  }

  flutter::Shell::CreateCallback<flutter::Rasterizer> on_create_rasterizer =
      [](flutter::Shell& shell) {
        return std::make_unique<flutter::Rasterizer>(shell,
                                                     shell.GetTaskRunners());
      };

  // TODO(chinmaygarde): This is the wrong spot for this. It belongs in the
  // platform view jump table.
  flutter::EmbedderExternalTextureGL::ExternalTextureCallback
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

        size_t width = size.width();
        size_t height = size.height();

        if (texture.width != 0 && texture.height != 0) {
          width = texture.width;
          height = texture.height;
        }

        GrBackendTexture gr_backend_texture(width, height, GrMipMapped::kNo,
                                            gr_texture_info);
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

  auto thread_host =
      flutter::EmbedderThreadHost::CreateEmbedderOrEngineManagedThreadHost(
          SAFE_ACCESS(args, custom_task_runners, nullptr));

  if (!thread_host || !thread_host->IsValid()) {
    return LOG_EMBEDDER_ERROR(kInvalidArguments,
                              "Could not setup or infer thread configuration "
                              "to run the Flutter engine on.");
  }

  auto task_runners = thread_host->GetTaskRunners();

  if (!task_runners.IsValid()) {
    return LOG_EMBEDDER_ERROR(kInternalInconsistency,
                              "Task runner configuration was invalid.");
  }

  auto run_configuration =
      flutter::RunConfiguration::InferFromSettings(settings);

  if (SAFE_ACCESS(args, custom_dart_entrypoint, nullptr) != nullptr) {
    auto dart_entrypoint = std::string{args->custom_dart_entrypoint};
    if (dart_entrypoint.size() != 0) {
      run_configuration.SetEntrypoint(std::move(dart_entrypoint));
    }
  }

  if (!run_configuration.IsValid()) {
    return LOG_EMBEDDER_ERROR(
        kInvalidArguments,
        "Could not infer the Flutter project to run from given arguments.");
  }

  // Create the engine but don't launch the shell or run the root isolate.
  auto embedder_engine = std::make_unique<flutter::EmbedderEngine>(
      std::move(thread_host),        //
      std::move(task_runners),       //
      std::move(settings),           //
      std::move(run_configuration),  //
      on_create_platform_view,       //
      on_create_rasterizer,          //
      external_texture_callback      //
  );

  // Release the ownership of the embedder engine to the caller.
  *engine_out = reinterpret_cast<FLUTTER_API_SYMBOL(FlutterEngine)>(
      embedder_engine.release());
  return kSuccess;
}

FlutterEngineResult FlutterEngineRunInitialized(
    FLUTTER_API_SYMBOL(FlutterEngine) engine) {
  if (!engine) {
    return LOG_EMBEDDER_ERROR(kInvalidArguments, "Engine handle was invalid.");
  }

  auto embedder_engine = reinterpret_cast<flutter::EmbedderEngine*>(engine);

  // The engine must not already be running. Initialize may only be called once
  // on an engine instance.
  if (embedder_engine->IsValid()) {
    return LOG_EMBEDDER_ERROR(kInvalidArguments, "Engine handle was invalid.");
  }

  // Step 1: Launch the shell.
  if (!embedder_engine->LaunchShell()) {
    return LOG_EMBEDDER_ERROR(
        kInvalidArguments,
        "Could not launch the engine using supplied initialization arguments.");
  }

  // Step 2: Tell the platform view to initialize itself.
  if (!embedder_engine->NotifyCreated()) {
    return LOG_EMBEDDER_ERROR(kInternalInconsistency,
                              "Could not create platform view components.");
  }

  // Step 3: Launch the root isolate.
  if (!embedder_engine->RunRootIsolate()) {
    return LOG_EMBEDDER_ERROR(
        kInvalidArguments,
        "Could not run the root isolate of the Flutter application using the "
        "project arguments specified.");
  }

  return kSuccess;
}

FLUTTER_EXPORT
FlutterEngineResult FlutterEngineDeinitialize(FLUTTER_API_SYMBOL(FlutterEngine)
                                                  engine) {
  if (engine == nullptr) {
    return LOG_EMBEDDER_ERROR(kInvalidArguments, "Engine handle was invalid.");
  }

  auto embedder_engine = reinterpret_cast<flutter::EmbedderEngine*>(engine);
  embedder_engine->NotifyDestroyed();
  embedder_engine->CollectShell();
  return kSuccess;
}

FlutterEngineResult FlutterEngineShutdown(FLUTTER_API_SYMBOL(FlutterEngine)
                                              engine) {
  auto result = FlutterEngineDeinitialize(engine);
  if (result != kSuccess) {
    return result;
  }
  auto embedder_engine = reinterpret_cast<flutter::EmbedderEngine*>(engine);
  delete embedder_engine;
  return kSuccess;
}

FlutterEngineResult FlutterEngineSendWindowMetricsEvent(
    FLUTTER_API_SYMBOL(FlutterEngine) engine,
    const FlutterWindowMetricsEvent* flutter_metrics) {
  if (engine == nullptr || flutter_metrics == nullptr) {
    return LOG_EMBEDDER_ERROR(kInvalidArguments, "Engine handle was invalid.");
  }

  flutter::ViewportMetrics metrics;

  metrics.physical_width = SAFE_ACCESS(flutter_metrics, width, 0.0);
  metrics.physical_height = SAFE_ACCESS(flutter_metrics, height, 0.0);
  metrics.device_pixel_ratio = SAFE_ACCESS(flutter_metrics, pixel_ratio, 1.0);

  if (metrics.device_pixel_ratio <= 0.0) {
    return LOG_EMBEDDER_ERROR(
        kInvalidArguments,
        "Device pixel ratio was invalid. It must be greater than zero.");
  }

  return reinterpret_cast<flutter::EmbedderEngine*>(engine)->SetViewportMetrics(
             std::move(metrics))
             ? kSuccess
             : LOG_EMBEDDER_ERROR(kInvalidArguments,
                                  "Viewport metrics were invalid.");
}

// Returns the flutter::PointerData::Change for the given FlutterPointerPhase.
inline flutter::PointerData::Change ToPointerDataChange(
    FlutterPointerPhase phase) {
  switch (phase) {
    case kCancel:
      return flutter::PointerData::Change::kCancel;
    case kUp:
      return flutter::PointerData::Change::kUp;
    case kDown:
      return flutter::PointerData::Change::kDown;
    case kMove:
      return flutter::PointerData::Change::kMove;
    case kAdd:
      return flutter::PointerData::Change::kAdd;
    case kRemove:
      return flutter::PointerData::Change::kRemove;
    case kHover:
      return flutter::PointerData::Change::kHover;
  }
  return flutter::PointerData::Change::kCancel;
}

// Returns the flutter::PointerData::DeviceKind for the given
// FlutterPointerDeviceKind.
inline flutter::PointerData::DeviceKind ToPointerDataKind(
    FlutterPointerDeviceKind device_kind) {
  switch (device_kind) {
    case kFlutterPointerDeviceKindMouse:
      return flutter::PointerData::DeviceKind::kMouse;
    case kFlutterPointerDeviceKindTouch:
      return flutter::PointerData::DeviceKind::kTouch;
  }
  return flutter::PointerData::DeviceKind::kMouse;
}

// Returns the flutter::PointerData::SignalKind for the given
// FlutterPointerSignaKind.
inline flutter::PointerData::SignalKind ToPointerDataSignalKind(
    FlutterPointerSignalKind kind) {
  switch (kind) {
    case kFlutterPointerSignalKindNone:
      return flutter::PointerData::SignalKind::kNone;
    case kFlutterPointerSignalKindScroll:
      return flutter::PointerData::SignalKind::kScroll;
  }
  return flutter::PointerData::SignalKind::kNone;
}

// Returns the buttons to synthesize for a PointerData from a
// FlutterPointerEvent with no type or buttons set.
inline int64_t PointerDataButtonsForLegacyEvent(
    flutter::PointerData::Change change) {
  switch (change) {
    case flutter::PointerData::Change::kDown:
    case flutter::PointerData::Change::kMove:
      // These kinds of change must have a non-zero `buttons`, otherwise gesture
      // recognizers will ignore these events.
      return flutter::kPointerButtonMousePrimary;
    case flutter::PointerData::Change::kCancel:
    case flutter::PointerData::Change::kAdd:
    case flutter::PointerData::Change::kRemove:
    case flutter::PointerData::Change::kHover:
    case flutter::PointerData::Change::kUp:
      return 0;
  }
  return 0;
}

FlutterEngineResult FlutterEngineSendPointerEvent(
    FLUTTER_API_SYMBOL(FlutterEngine) engine,
    const FlutterPointerEvent* pointers,
    size_t events_count) {
  if (engine == nullptr) {
    return LOG_EMBEDDER_ERROR(kInvalidArguments, "Engine handle was invalid.");
  }

  if (pointers == nullptr || events_count == 0) {
    return LOG_EMBEDDER_ERROR(kInvalidArguments, "Invalid pointer events.");
  }

  auto packet = std::make_unique<flutter::PointerDataPacket>(events_count);

  const FlutterPointerEvent* current = pointers;

  for (size_t i = 0; i < events_count; ++i) {
    flutter::PointerData pointer_data;
    pointer_data.Clear();
    pointer_data.time_stamp = SAFE_ACCESS(current, timestamp, 0);
    pointer_data.change = ToPointerDataChange(
        SAFE_ACCESS(current, phase, FlutterPointerPhase::kCancel));
    pointer_data.physical_x = SAFE_ACCESS(current, x, 0.0);
    pointer_data.physical_y = SAFE_ACCESS(current, y, 0.0);
    // Delta will be generated in pointer_data_packet_converter.cc.
    pointer_data.physical_delta_x = 0.0;
    pointer_data.physical_delta_y = 0.0;
    pointer_data.device = SAFE_ACCESS(current, device, 0);
    // Pointer identifier will be generated in pointer_data_packet_converter.cc.
    pointer_data.pointer_identifier = 0;
    pointer_data.signal_kind = ToPointerDataSignalKind(
        SAFE_ACCESS(current, signal_kind, kFlutterPointerSignalKindNone));
    pointer_data.scroll_delta_x = SAFE_ACCESS(current, scroll_delta_x, 0.0);
    pointer_data.scroll_delta_y = SAFE_ACCESS(current, scroll_delta_y, 0.0);
    FlutterPointerDeviceKind device_kind = SAFE_ACCESS(current, device_kind, 0);
    // For backwards compatibility with embedders written before the device kind
    // and buttons were exposed, if the device kind is not set treat it as a
    // mouse, with a synthesized primary button state based on the phase.
    if (device_kind == 0) {
      pointer_data.kind = flutter::PointerData::DeviceKind::kMouse;
      pointer_data.buttons =
          PointerDataButtonsForLegacyEvent(pointer_data.change);

    } else {
      pointer_data.kind = ToPointerDataKind(device_kind);
      if (pointer_data.kind == flutter::PointerData::DeviceKind::kTouch) {
        // For touch events, set the button internally rather than requiring
        // it at the API level, since it's a confusing construction to expose.
        if (pointer_data.change == flutter::PointerData::Change::kDown ||
            pointer_data.change == flutter::PointerData::Change::kMove) {
          pointer_data.buttons = flutter::kPointerButtonTouchContact;
        }
      } else {
        // Buttons use the same mask values, so pass them through directly.
        pointer_data.buttons = SAFE_ACCESS(current, buttons, 0);
      }
    }
    packet->SetPointerData(i, pointer_data);
    current = reinterpret_cast<const FlutterPointerEvent*>(
        reinterpret_cast<const uint8_t*>(current) + current->struct_size);
  }

  return reinterpret_cast<flutter::EmbedderEngine*>(engine)
                 ->DispatchPointerDataPacket(std::move(packet))
             ? kSuccess
             : LOG_EMBEDDER_ERROR(kInternalInconsistency,
                                  "Could not dispatch pointer events to the "
                                  "running Flutter application.");
}

FlutterEngineResult FlutterEngineSendPlatformMessage(
    FLUTTER_API_SYMBOL(FlutterEngine) engine,
    const FlutterPlatformMessage* flutter_message) {
  if (engine == nullptr) {
    return LOG_EMBEDDER_ERROR(kInvalidArguments, "Invalid engine handle.");
  }

  if (flutter_message == nullptr) {
    return LOG_EMBEDDER_ERROR(kInvalidArguments, "Invalid message argument.");
  }

  if (SAFE_ACCESS(flutter_message, channel, nullptr) == nullptr) {
    return LOG_EMBEDDER_ERROR(
        kInvalidArguments, "Message argument did not specify a valid channel.");
  }

  size_t message_size = SAFE_ACCESS(flutter_message, message_size, 0);
  const uint8_t* message_data = SAFE_ACCESS(flutter_message, message, nullptr);

  if (message_size != 0 && message_data == nullptr) {
    return LOG_EMBEDDER_ERROR(
        kInvalidArguments,
        "Message size was non-zero but the message data was nullptr.");
  }

  const FlutterPlatformMessageResponseHandle* response_handle =
      SAFE_ACCESS(flutter_message, response_handle, nullptr);

  fml::RefPtr<flutter::PlatformMessageResponse> response;
  if (response_handle && response_handle->message) {
    response = response_handle->message->response();
  }

  fml::RefPtr<flutter::PlatformMessage> message;
  if (message_size == 0) {
    message = fml::MakeRefCounted<flutter::PlatformMessage>(
        flutter_message->channel, response);
  } else {
    message = fml::MakeRefCounted<flutter::PlatformMessage>(
        flutter_message->channel,
        std::vector<uint8_t>(message_data, message_data + message_size),
        response);
  }

  return reinterpret_cast<flutter::EmbedderEngine*>(engine)
                 ->SendPlatformMessage(std::move(message))
             ? kSuccess
             : LOG_EMBEDDER_ERROR(kInternalInconsistency,
                                  "Could not send a message to the running "
                                  "Flutter application.");
}

FlutterEngineResult FlutterPlatformMessageCreateResponseHandle(
    FLUTTER_API_SYMBOL(FlutterEngine) engine,
    FlutterDataCallback data_callback,
    void* user_data,
    FlutterPlatformMessageResponseHandle** response_out) {
  if (engine == nullptr) {
    return LOG_EMBEDDER_ERROR(kInvalidArguments, "Engine handle was invalid.");
  }

  if (data_callback == nullptr || response_out == nullptr) {
    return LOG_EMBEDDER_ERROR(
        kInvalidArguments, "Data callback or the response handle was invalid.");
  }

  flutter::EmbedderPlatformMessageResponse::Callback response_callback =
      [user_data, data_callback](const uint8_t* data, size_t size) {
        data_callback(data, size, user_data);
      };

  auto platform_task_runner = reinterpret_cast<flutter::EmbedderEngine*>(engine)
                                  ->GetTaskRunners()
                                  .GetPlatformTaskRunner();

  auto handle = new FlutterPlatformMessageResponseHandle();

  handle->message = fml::MakeRefCounted<flutter::PlatformMessage>(
      "",  // The channel is empty and unused as the response handle is going to
           // referenced directly in the |FlutterEngineSendPlatformMessage| with
           // the container message discarded.
      fml::MakeRefCounted<flutter::EmbedderPlatformMessageResponse>(
          std::move(platform_task_runner), response_callback));
  *response_out = handle;
  return kSuccess;
}

FlutterEngineResult FlutterPlatformMessageReleaseResponseHandle(
    FLUTTER_API_SYMBOL(FlutterEngine) engine,
    FlutterPlatformMessageResponseHandle* response) {
  if (engine == nullptr) {
    return LOG_EMBEDDER_ERROR(kInvalidArguments, "Invalid engine handle.");
  }

  if (response == nullptr) {
    return LOG_EMBEDDER_ERROR(kInvalidArguments, "Invalid response handle.");
  }
  delete response;
  return kSuccess;
}

FlutterEngineResult FlutterEngineSendPlatformMessageResponse(
    FLUTTER_API_SYMBOL(FlutterEngine) engine,
    const FlutterPlatformMessageResponseHandle* handle,
    const uint8_t* data,
    size_t data_length) {
  if (data_length != 0 && data == nullptr) {
    return LOG_EMBEDDER_ERROR(
        kInvalidArguments,
        "Data size was non zero but the pointer to the data was null.");
  }

  auto response = handle->message->response();

  if (response) {
    if (data_length == 0) {
      response->CompleteEmpty();
    } else {
      response->Complete(std::make_unique<fml::DataMapping>(
          std::vector<uint8_t>({data, data + data_length})));
    }
  }

  delete handle;

  return kSuccess;
}

FlutterEngineResult __FlutterEngineFlushPendingTasksNow() {
  fml::MessageLoop::GetCurrent().RunExpiredTasksNow();
  return kSuccess;
}

FlutterEngineResult FlutterEngineRegisterExternalTexture(
    FLUTTER_API_SYMBOL(FlutterEngine) engine,
    int64_t texture_identifier) {
  if (engine == nullptr) {
    return LOG_EMBEDDER_ERROR(kInvalidArguments, "Engine handle was invalid.");
  }

  if (texture_identifier == 0) {
    return LOG_EMBEDDER_ERROR(kInvalidArguments,
                              "Texture identifier was invalid.");
  }
  if (!reinterpret_cast<flutter::EmbedderEngine*>(engine)->RegisterTexture(
          texture_identifier)) {
    return LOG_EMBEDDER_ERROR(kInternalInconsistency,
                              "Could not register the specified texture.");
  }
  return kSuccess;
}

FlutterEngineResult FlutterEngineUnregisterExternalTexture(
    FLUTTER_API_SYMBOL(FlutterEngine) engine,
    int64_t texture_identifier) {
  if (engine == nullptr) {
    return LOG_EMBEDDER_ERROR(kInvalidArguments, "Engine handle was invalid.");
  }

  if (texture_identifier == 0) {
    return LOG_EMBEDDER_ERROR(kInvalidArguments,
                              "Texture identifier was invalid.");
  }

  if (!reinterpret_cast<flutter::EmbedderEngine*>(engine)->UnregisterTexture(
          texture_identifier)) {
    return LOG_EMBEDDER_ERROR(kInternalInconsistency,
                              "Could not un-register the specified texture.");
  }

  return kSuccess;
}

FlutterEngineResult FlutterEngineMarkExternalTextureFrameAvailable(
    FLUTTER_API_SYMBOL(FlutterEngine) engine,
    int64_t texture_identifier) {
  if (engine == nullptr) {
    return LOG_EMBEDDER_ERROR(kInvalidArguments, "Invalid engine handle.");
  }
  if (texture_identifier == 0) {
    return LOG_EMBEDDER_ERROR(kInvalidArguments, "Invalid texture identifier.");
  }
  if (!reinterpret_cast<flutter::EmbedderEngine*>(engine)
           ->MarkTextureFrameAvailable(texture_identifier)) {
    return LOG_EMBEDDER_ERROR(
        kInternalInconsistency,
        "Could not mark the texture frame as being available.");
  }
  return kSuccess;
}

FlutterEngineResult FlutterEngineUpdateSemanticsEnabled(
    FLUTTER_API_SYMBOL(FlutterEngine) engine,
    bool enabled) {
  if (engine == nullptr) {
    return LOG_EMBEDDER_ERROR(kInvalidArguments, "Invalid engine handle.");
  }
  if (!reinterpret_cast<flutter::EmbedderEngine*>(engine)->SetSemanticsEnabled(
          enabled)) {
    return LOG_EMBEDDER_ERROR(kInternalInconsistency,
                              "Could not update semantics state.");
  }
  return kSuccess;
}

FlutterEngineResult FlutterEngineUpdateAccessibilityFeatures(
    FLUTTER_API_SYMBOL(FlutterEngine) engine,
    FlutterAccessibilityFeature flags) {
  if (engine == nullptr) {
    return LOG_EMBEDDER_ERROR(kInvalidArguments, "Invalid engine handle.");
  }
  if (!reinterpret_cast<flutter::EmbedderEngine*>(engine)
           ->SetAccessibilityFeatures(flags)) {
    return LOG_EMBEDDER_ERROR(kInternalInconsistency,
                              "Could not update accessibility features.");
  }
  return kSuccess;
}

FlutterEngineResult FlutterEngineDispatchSemanticsAction(
    FLUTTER_API_SYMBOL(FlutterEngine) engine,
    uint64_t id,
    FlutterSemanticsAction action,
    const uint8_t* data,
    size_t data_length) {
  if (engine == nullptr) {
    return LOG_EMBEDDER_ERROR(kInvalidArguments, "Invalid engine handle.");
  }
  auto engine_action = static_cast<flutter::SemanticsAction>(action);
  if (!reinterpret_cast<flutter::EmbedderEngine*>(engine)
           ->DispatchSemanticsAction(
               id, engine_action,
               std::vector<uint8_t>({data, data + data_length}))) {
    return LOG_EMBEDDER_ERROR(kInternalInconsistency,
                              "Could not dispatch semantics action.");
  }
  return kSuccess;
}

FlutterEngineResult FlutterEngineOnVsync(FLUTTER_API_SYMBOL(FlutterEngine)
                                             engine,
                                         intptr_t baton,
                                         uint64_t frame_start_time_nanos,
                                         uint64_t frame_target_time_nanos) {
  if (engine == nullptr) {
    return LOG_EMBEDDER_ERROR(kInvalidArguments, "Invalid engine handle.");
  }

  TRACE_EVENT0("flutter", "FlutterEngineOnVsync");

  auto start_time = fml::TimePoint::FromEpochDelta(
      fml::TimeDelta::FromNanoseconds(frame_start_time_nanos));

  auto target_time = fml::TimePoint::FromEpochDelta(
      fml::TimeDelta::FromNanoseconds(frame_target_time_nanos));

  if (!reinterpret_cast<flutter::EmbedderEngine*>(engine)->OnVsyncEvent(
          baton, start_time, target_time)) {
    return LOG_EMBEDDER_ERROR(
        kInternalInconsistency,
        "Could not notify the running engine instance of a Vsync event.");
  }

  return kSuccess;
}

FlutterEngineResult FlutterEngineReloadSystemFonts(
    FLUTTER_API_SYMBOL(FlutterEngine) engine) {
  if (engine == nullptr) {
    return LOG_EMBEDDER_ERROR(kInvalidArguments, "Invalid engine handle.");
  }

  TRACE_EVENT0("flutter", "FlutterEngineReloadSystemFonts");

  if (!reinterpret_cast<flutter::EmbedderEngine*>(engine)
           ->ReloadSystemFonts()) {
    return LOG_EMBEDDER_ERROR(kInternalInconsistency,
                              "Could not reload system fonts.");
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

FlutterEngineResult FlutterEnginePostRenderThreadTask(
    FLUTTER_API_SYMBOL(FlutterEngine) engine,
    VoidCallback callback,
    void* baton) {
  if (engine == nullptr) {
    return LOG_EMBEDDER_ERROR(kInvalidArguments, "Invalid engine handle.");
  }

  if (callback == nullptr) {
    return LOG_EMBEDDER_ERROR(kInvalidArguments,
                              "Render thread callback was null.");
  }

  auto task = [callback, baton]() { callback(baton); };

  return reinterpret_cast<flutter::EmbedderEngine*>(engine)
                 ->PostRenderThreadTask(task)
             ? kSuccess
             : LOG_EMBEDDER_ERROR(kInternalInconsistency,
                                  "Could not post the render thread task.");
}

uint64_t FlutterEngineGetCurrentTime() {
  return fml::TimePoint::Now().ToEpochDelta().ToNanoseconds();
}

FlutterEngineResult FlutterEngineRunTask(FLUTTER_API_SYMBOL(FlutterEngine)
                                             engine,
                                         const FlutterTask* task) {
  if (engine == nullptr) {
    return LOG_EMBEDDER_ERROR(kInvalidArguments, "Invalid engine handle.");
  }

  return reinterpret_cast<flutter::EmbedderEngine*>(engine)->RunTask(task)
             ? kSuccess
             : LOG_EMBEDDER_ERROR(kInvalidArguments,
                                  "Could not run the specified task.");
}

static bool DispatchJSONPlatformMessage(FLUTTER_API_SYMBOL(FlutterEngine)
                                            engine,
                                        rapidjson::Document document,
                                        const std::string& channel_name) {
  if (channel_name.size() == 0) {
    return false;
  }

  rapidjson::StringBuffer buffer;
  rapidjson::Writer<rapidjson::StringBuffer> writer(buffer);

  if (!document.Accept(writer)) {
    return false;
  }

  const char* message = buffer.GetString();

  if (message == nullptr || buffer.GetSize() == 0) {
    return false;
  }

  auto platform_message = fml::MakeRefCounted<flutter::PlatformMessage>(
      channel_name.c_str(),                                       // channel
      std::vector<uint8_t>{message, message + buffer.GetSize()},  // message
      nullptr                                                     // response
  );

  return reinterpret_cast<flutter::EmbedderEngine*>(engine)
      ->SendPlatformMessage(std::move(platform_message));
}

FlutterEngineResult FlutterEngineUpdateLocales(FLUTTER_API_SYMBOL(FlutterEngine)
                                                   engine,
                                               const FlutterLocale** locales,
                                               size_t locales_count) {
  if (engine == nullptr) {
    return LOG_EMBEDDER_ERROR(kInvalidArguments, "Invalid engine handle.");
  }

  if (locales_count == 0) {
    return kSuccess;
  }

  if (locales == nullptr) {
    return LOG_EMBEDDER_ERROR(kInvalidArguments, "No locales were specified.");
  }

  rapidjson::Document document;
  auto& allocator = document.GetAllocator();

  document.SetObject();
  document.AddMember("method", "setLocale", allocator);

  rapidjson::Value args(rapidjson::kArrayType);
  args.Reserve(locales_count * 4, allocator);
  for (size_t i = 0; i < locales_count; ++i) {
    const FlutterLocale* locale = locales[i];
    const char* language_code_str = SAFE_ACCESS(locale, language_code, nullptr);
    if (language_code_str == nullptr || ::strlen(language_code_str) == 0) {
      return LOG_EMBEDDER_ERROR(
          kInvalidArguments,
          "Language code is required but not present in FlutterLocale.");
    }

    const char* country_code_str = SAFE_ACCESS(locale, country_code, "");
    const char* script_code_str = SAFE_ACCESS(locale, script_code, "");
    const char* variant_code_str = SAFE_ACCESS(locale, variant_code, "");

    rapidjson::Value language_code, country_code, script_code, variant_code;

    language_code.SetString(language_code_str, allocator);
    country_code.SetString(country_code_str ? country_code_str : "", allocator);
    script_code.SetString(script_code_str ? script_code_str : "", allocator);
    variant_code.SetString(variant_code_str ? variant_code_str : "", allocator);

    // Required.
    args.PushBack(language_code, allocator);
    args.PushBack(country_code, allocator);
    args.PushBack(script_code, allocator);
    args.PushBack(variant_code, allocator);
  }
  document.AddMember("args", args, allocator);

  return DispatchJSONPlatformMessage(engine, std::move(document),
                                     "flutter/localization")
             ? kSuccess
             : LOG_EMBEDDER_ERROR(kInternalInconsistency,
                                  "Could not send message to update locale of "
                                  "a running Flutter application.");
}

bool FlutterEngineRunsAOTCompiledDartCode(void) {
  return flutter::DartVM::IsRunningPrecompiledCode();
}

FlutterEngineResult FlutterEnginePostDartObject(
    FLUTTER_API_SYMBOL(FlutterEngine) engine,
    FlutterEngineDartPort port,
    const FlutterEngineDartObject* object) {
  if (engine == nullptr) {
    return LOG_EMBEDDER_ERROR(kInvalidArguments, "Invalid engine handle.");
  }

  if (!reinterpret_cast<flutter::EmbedderEngine*>(engine)->IsValid()) {
    return LOG_EMBEDDER_ERROR(kInvalidArguments, "Engine not running.");
  }

  if (port == ILLEGAL_PORT) {
    return LOG_EMBEDDER_ERROR(kInvalidArguments,
                              "Attempted to post to an illegal port.");
  }

  if (object == nullptr) {
    return LOG_EMBEDDER_ERROR(kInvalidArguments,
                              "Invalid Dart object to post.");
  }

  Dart_CObject dart_object = {};
  fml::ScopedCleanupClosure typed_data_finalizer;

  switch (object->type) {
    case kFlutterEngineDartObjectTypeNull:
      dart_object.type = Dart_CObject_kNull;
      break;
    case kFlutterEngineDartObjectTypeBool:
      dart_object.type = Dart_CObject_kBool;
      dart_object.value.as_bool = object->bool_value;
      break;
    case kFlutterEngineDartObjectTypeInt32:
      dart_object.type = Dart_CObject_kInt32;
      dart_object.value.as_int32 = object->int32_value;
      break;
    case kFlutterEngineDartObjectTypeInt64:
      dart_object.type = Dart_CObject_kInt64;
      dart_object.value.as_int64 = object->int64_value;
      break;
    case kFlutterEngineDartObjectTypeDouble:
      dart_object.type = Dart_CObject_kDouble;
      dart_object.value.as_double = object->double_value;
      break;
    case kFlutterEngineDartObjectTypeString:
      if (object->string_value == nullptr) {
        return LOG_EMBEDDER_ERROR(kInvalidArguments,
                                  "kFlutterEngineDartObjectTypeString must be "
                                  "a null terminated string but was null.");
      }
      dart_object.type = Dart_CObject_kString;
      dart_object.value.as_string = const_cast<char*>(object->string_value);
      break;
    case kFlutterEngineDartObjectTypeBuffer: {
      auto* buffer = SAFE_ACCESS(object->buffer_value, buffer, nullptr);
      if (buffer == nullptr) {
        return LOG_EMBEDDER_ERROR(kInvalidArguments,
                                  "kFlutterEngineDartObjectTypeBuffer must "
                                  "specify a buffer but found nullptr.");
      }
      auto buffer_size = SAFE_ACCESS(object->buffer_value, buffer_size, 0);
      auto callback =
          SAFE_ACCESS(object->buffer_value, buffer_collect_callback, nullptr);
      auto user_data = SAFE_ACCESS(object->buffer_value, user_data, nullptr);

      // The user has provided a callback, let them manage the lifecycle of
      // the underlying data. If not, copy it out from the provided buffer.

      if (callback == nullptr) {
        dart_object.type = Dart_CObject_kTypedData;
        dart_object.value.as_typed_data.type = Dart_TypedData_kUint8;
        dart_object.value.as_typed_data.length = buffer_size;
        dart_object.value.as_typed_data.values = buffer;
      } else {
        struct ExternalTypedDataPeer {
          void* user_data = nullptr;
          VoidCallback trampoline = nullptr;
        };
        auto peer = new ExternalTypedDataPeer();
        peer->user_data = user_data;
        peer->trampoline = callback;
        // This finalizer is set so that in case of failure of the
        // Dart_PostCObject below, we collect the peer. The embedder is still
        // responsible for collecting the buffer in case of non-kSuccess returns
        // from this method. This finalizer must be released in case of kSuccess
        // returns from this method.
        typed_data_finalizer.SetClosure([peer]() {
          // This is the tiny object we use as the peer to the Dart call so that
          // we can attach the a trampoline to the embedder supplied callback.
          // In case of error, we need to collect this object lest we introduce
          // a tiny leak.
          delete peer;
        });
        dart_object.type = Dart_CObject_kExternalTypedData;
        dart_object.value.as_external_typed_data.type = Dart_TypedData_kUint8;
        dart_object.value.as_external_typed_data.length = buffer_size;
        dart_object.value.as_external_typed_data.data = buffer;
        dart_object.value.as_external_typed_data.peer = peer;
        dart_object.value.as_external_typed_data.callback =
            +[](void* unused_isolate_callback_data,
                Dart_WeakPersistentHandle unused_handle, void* peer) {
              auto typed_peer = reinterpret_cast<ExternalTypedDataPeer*>(peer);
              typed_peer->trampoline(typed_peer->user_data);
              delete typed_peer;
            };
      }
    } break;
    default:
      return LOG_EMBEDDER_ERROR(
          kInvalidArguments,
          "Invalid FlutterEngineDartObjectType type specified.");
  }

  if (!Dart_PostCObject(port, &dart_object)) {
    return LOG_EMBEDDER_ERROR(kInternalInconsistency,
                              "Could not post the object to the Dart VM.");
  }

  // On a successful call, the VM takes ownership of and is responsible for
  // invoking the finalizer.
  typed_data_finalizer.Release();
  return kSuccess;
}

FlutterEngineResult FlutterEngineNotifyLowMemoryWarning(
    FLUTTER_API_SYMBOL(FlutterEngine) raw_engine) {
  auto engine = reinterpret_cast<flutter::EmbedderEngine*>(raw_engine);
  if (engine == nullptr || !engine->IsValid()) {
    return LOG_EMBEDDER_ERROR(kInvalidArguments, "Engine was invalid.");
  }

  engine->GetShell().NotifyLowMemoryWarning();

  rapidjson::Document document;
  auto& allocator = document.GetAllocator();

  document.SetObject();
  document.AddMember("type", "memoryPressure", allocator);

  return DispatchJSONPlatformMessage(raw_engine, std::move(document),
                                     "flutter/system")
             ? kSuccess
             : LOG_EMBEDDER_ERROR(
                   kInternalInconsistency,
                   "Could not dispatch the low memory notification message.");
}

FlutterEngineResult FlutterEnginePostCallbackOnAllNativeThreads(
    FLUTTER_API_SYMBOL(FlutterEngine) engine,
    FlutterNativeThreadCallback callback,
    void* user_data) {
  if (engine == nullptr) {
    return LOG_EMBEDDER_ERROR(kInvalidArguments, "Invalid engine handle.");
  }

  if (callback == nullptr) {
    return LOG_EMBEDDER_ERROR(kInvalidArguments,
                              "Invalid native thread callback.");
  }

  return reinterpret_cast<flutter::EmbedderEngine*>(engine)
                 ->PostTaskOnEngineManagedNativeThreads(
                     [callback, user_data](FlutterNativeThreadType type) {
                       callback(type, user_data);
                     })
             ? kSuccess
             : LOG_EMBEDDER_ERROR(kInvalidArguments,
                                  "Internal error while attempting to post "
                                  "tasks to all threads.");
}
