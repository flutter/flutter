// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/embedder/tests/embedder_config_builder.h"

#include "flutter/runtime/dart_vm.h"
#include "flutter/shell/platform/embedder/embedder.h"
#include "third_party/skia/include/core/SkBitmap.h"

#ifdef SHELL_ENABLE_GL
#include "flutter/shell/platform/embedder/tests/embedder_test_compositor_gl.h"
#include "flutter/shell/platform/embedder/tests/embedder_test_context_gl.h"
#endif

namespace flutter {
namespace testing {

EmbedderConfigBuilder::EmbedderConfigBuilder(
    EmbedderTestContext& context,
    InitializationPreference preference)
    : context_(context) {
  project_args_.struct_size = sizeof(project_args_);
  project_args_.shutdown_dart_vm_when_done = true;
  project_args_.platform_message_callback =
      [](const FlutterPlatformMessage* message, void* context) {
        reinterpret_cast<EmbedderTestContext*>(context)
            ->PlatformMessageCallback(message);
      };

  custom_task_runners_.struct_size = sizeof(FlutterCustomTaskRunners);

#ifdef SHELL_ENABLE_GL
  opengl_renderer_config_.struct_size = sizeof(FlutterOpenGLRendererConfig);
  opengl_renderer_config_.make_current = [](void* context) -> bool {
    return reinterpret_cast<EmbedderTestContextGL*>(context)->GLMakeCurrent();
  };
  opengl_renderer_config_.clear_current = [](void* context) -> bool {
    return reinterpret_cast<EmbedderTestContextGL*>(context)->GLClearCurrent();
  };
  opengl_renderer_config_.present_with_info =
      [](void* context, const FlutterPresentInfo* present_info) -> bool {
    return reinterpret_cast<EmbedderTestContextGL*>(context)->GLPresent(
        present_info->fbo_id);
  };
  opengl_renderer_config_.fbo_with_frame_info_callback =
      [](void* context, const FlutterFrameInfo* frame_info) -> uint32_t {
    return reinterpret_cast<EmbedderTestContextGL*>(context)->GLGetFramebuffer(
        *frame_info);
  };
  opengl_renderer_config_.make_resource_current = [](void* context) -> bool {
    return reinterpret_cast<EmbedderTestContextGL*>(context)
        ->GLMakeResourceCurrent();
  };
  opengl_renderer_config_.gl_proc_resolver = [](void* context,
                                                const char* name) -> void* {
    return reinterpret_cast<EmbedderTestContextGL*>(context)->GLGetProcAddress(
        name);
  };
  opengl_renderer_config_.fbo_reset_after_present = true;
  opengl_renderer_config_.surface_transformation =
      [](void* context) -> FlutterTransformation {
    return reinterpret_cast<EmbedderTestContext*>(context)
        ->GetRootSurfaceTransformation();
  };
#endif

  software_renderer_config_.struct_size = sizeof(FlutterSoftwareRendererConfig);
  software_renderer_config_.surface_present_callback =
      [](void* context, const void* allocation, size_t row_bytes,
         size_t height) {
        auto image_info =
            SkImageInfo::MakeN32Premul(SkISize::Make(row_bytes / 4, height));
        SkBitmap bitmap;
        if (!bitmap.installPixels(image_info, const_cast<void*>(allocation),
                                  row_bytes)) {
          FML_LOG(ERROR) << "Could not copy pixels for the software "
                            "composition from the engine.";
          return false;
        }
        bitmap.setImmutable();
        return reinterpret_cast<EmbedderTestContextSoftware*>(context)->Present(
            SkImage::MakeFromBitmap(bitmap));
      };

  // The first argument is treated as the executable name. Don't make tests have
  // to do this manually.
  AddCommandLineArgument("embedder_unittest");

  if (preference != InitializationPreference::kNoInitialize) {
    SetAssetsPath();
    SetIsolateCreateCallbackHook();
    SetSemanticsCallbackHooks();
    SetLocalizationCallbackHooks();
    AddCommandLineArgument("--disable-observatory");

    if (preference == InitializationPreference::kSnapshotsInitialize ||
        preference == InitializationPreference::kMultiAOTInitialize) {
      SetSnapshots();
    }
    if (preference == InitializationPreference::kAOTDataInitialize ||
        preference == InitializationPreference::kMultiAOTInitialize) {
      SetAOTDataElf();
    }
  }
}

EmbedderConfigBuilder::~EmbedderConfigBuilder() = default;

FlutterProjectArgs& EmbedderConfigBuilder::GetProjectArgs() {
  return project_args_;
}

void EmbedderConfigBuilder::SetSoftwareRendererConfig(SkISize surface_size) {
  renderer_config_.type = FlutterRendererType::kSoftware;
  renderer_config_.software = software_renderer_config_;
  context_.SetupSurface(surface_size);
}

void EmbedderConfigBuilder::SetOpenGLFBOCallBack() {
#ifdef SHELL_ENABLE_GL
  // SetOpenGLRendererConfig must be called before this.
  FML_CHECK(renderer_config_.type == FlutterRendererType::kOpenGL);
  renderer_config_.open_gl.fbo_callback = [](void* context) -> uint32_t {
    FlutterFrameInfo frame_info = {};
    // fbo_callback doesn't use the frame size information, only
    // fbo_callback_with_frame_info does.
    frame_info.struct_size = sizeof(FlutterFrameInfo);
    frame_info.size.width = 0;
    frame_info.size.height = 0;
    return reinterpret_cast<EmbedderTestContextGL*>(context)->GLGetFramebuffer(
        frame_info);
  };
#endif
}

void EmbedderConfigBuilder::SetOpenGLPresentCallBack() {
#ifdef SHELL_ENABLE_GL
  // SetOpenGLRendererConfig must be called before this.
  FML_CHECK(renderer_config_.type == FlutterRendererType::kOpenGL);
  renderer_config_.open_gl.present = [](void* context) -> bool {
    // passing a placeholder fbo_id.
    return reinterpret_cast<EmbedderTestContextGL*>(context)->GLPresent(0);
  };
#endif
}

void EmbedderConfigBuilder::SetOpenGLRendererConfig(SkISize surface_size) {
#ifdef SHELL_ENABLE_GL
  renderer_config_.type = FlutterRendererType::kOpenGL;
  renderer_config_.open_gl = opengl_renderer_config_;
  context_.SetupSurface(surface_size);
#endif
}

void EmbedderConfigBuilder::SetAssetsPath() {
  project_args_.assets_path = context_.GetAssetsPath().c_str();
}

void EmbedderConfigBuilder::SetSnapshots() {
  if (auto mapping = context_.GetVMSnapshotData()) {
    project_args_.vm_snapshot_data = mapping->GetMapping();
    project_args_.vm_snapshot_data_size = mapping->GetSize();
  }

  if (auto mapping = context_.GetVMSnapshotInstructions()) {
    project_args_.vm_snapshot_instructions = mapping->GetMapping();
    project_args_.vm_snapshot_instructions_size = mapping->GetSize();
  }

  if (auto mapping = context_.GetIsolateSnapshotData()) {
    project_args_.isolate_snapshot_data = mapping->GetMapping();
    project_args_.isolate_snapshot_data_size = mapping->GetSize();
  }

  if (auto mapping = context_.GetIsolateSnapshotInstructions()) {
    project_args_.isolate_snapshot_instructions = mapping->GetMapping();
    project_args_.isolate_snapshot_instructions_size = mapping->GetSize();
  }
}

void EmbedderConfigBuilder::SetAOTDataElf() {
  project_args_.aot_data = context_.GetAOTData();
}

void EmbedderConfigBuilder::SetIsolateCreateCallbackHook() {
  project_args_.root_isolate_create_callback =
      EmbedderTestContext::GetIsolateCreateCallbackHook();
}

void EmbedderConfigBuilder::SetSemanticsCallbackHooks() {
  project_args_.update_semantics_node_callback =
      EmbedderTestContext::GetUpdateSemanticsNodeCallbackHook();
  project_args_.update_semantics_custom_action_callback =
      EmbedderTestContext::GetUpdateSemanticsCustomActionCallbackHook();
}

void EmbedderConfigBuilder::SetLocalizationCallbackHooks() {
  project_args_.compute_platform_resolved_locale_callback =
      EmbedderTestContext::GetComputePlatformResolvedLocaleCallbackHook();
}

void EmbedderConfigBuilder::SetDartEntrypoint(std::string entrypoint) {
  if (entrypoint.size() == 0) {
    return;
  }

  dart_entrypoint_ = std::move(entrypoint);
  project_args_.custom_dart_entrypoint = dart_entrypoint_.c_str();
}

void EmbedderConfigBuilder::AddCommandLineArgument(std::string arg) {
  if (arg.size() == 0) {
    return;
  }

  command_line_arguments_.emplace_back(std::move(arg));
}

void EmbedderConfigBuilder::AddDartEntrypointArgument(std::string arg) {
  if (arg.size() == 0) {
    return;
  }

  dart_entrypoint_arguments_.emplace_back(std::move(arg));
}

void EmbedderConfigBuilder::SetPlatformTaskRunner(
    const FlutterTaskRunnerDescription* runner) {
  if (runner == nullptr) {
    return;
  }
  custom_task_runners_.platform_task_runner = runner;
  project_args_.custom_task_runners = &custom_task_runners_;
}

void EmbedderConfigBuilder::SetRenderTaskRunner(
    const FlutterTaskRunnerDescription* runner) {
  if (runner == nullptr) {
    return;
  }

  custom_task_runners_.render_task_runner = runner;
  project_args_.custom_task_runners = &custom_task_runners_;
}

void EmbedderConfigBuilder::SetPlatformMessageCallback(
    const std::function<void(const FlutterPlatformMessage*)>& callback) {
  context_.SetPlatformMessageCallback(callback);
}

void EmbedderConfigBuilder::SetCompositor() {
  context_.SetupCompositor();
  auto& compositor = context_.GetCompositor();
  compositor_.struct_size = sizeof(compositor_);
  compositor_.user_data = &compositor;
  compositor_.create_backing_store_callback =
      [](const FlutterBackingStoreConfig* config,  //
         FlutterBackingStore* backing_store_out,   //
         void* user_data                           //
      ) {
        return reinterpret_cast<EmbedderTestCompositor*>(user_data)
            ->CreateBackingStore(config, backing_store_out);
      };
  compositor_.collect_backing_store_callback =
      [](const FlutterBackingStore* backing_store,  //
         void* user_data                            //
      ) {
        return reinterpret_cast<EmbedderTestCompositor*>(user_data)
            ->CollectBackingStore(backing_store);
      };
  compositor_.present_layers_callback = [](const FlutterLayer** layers,  //
                                           size_t layers_count,          //
                                           void* user_data               //
                                        ) {
    return reinterpret_cast<EmbedderTestCompositor*>(user_data)->Present(
        layers,       //
        layers_count  //

    );
  };
  project_args_.compositor = &compositor_;
}

FlutterCompositor& EmbedderConfigBuilder::GetCompositor() {
  return compositor_;
}

void EmbedderConfigBuilder::SetRenderTargetType(
    EmbedderTestBackingStoreProducer::RenderTargetType type) {
  auto& compositor = context_.GetCompositor();
  // TODO(wrightgeorge): figure out a better way of plumbing through the
  // GrDirectContext
  compositor.SetBackingStoreProducer(
      std::make_unique<EmbedderTestBackingStoreProducer>(
          compositor.GetGrContext(), type));
}

UniqueEngine EmbedderConfigBuilder::LaunchEngine() const {
  return SetupEngine(true);
}

UniqueEngine EmbedderConfigBuilder::InitializeEngine() const {
  return SetupEngine(false);
}

UniqueEngine EmbedderConfigBuilder::SetupEngine(bool run) const {
  FlutterEngine engine = nullptr;
  FlutterProjectArgs project_args = project_args_;

  std::vector<const char*> args;
  args.reserve(command_line_arguments_.size());

  for (const auto& arg : command_line_arguments_) {
    args.push_back(arg.c_str());
  }

  if (args.size() > 0) {
    project_args.command_line_argv = args.data();
    project_args.command_line_argc = args.size();
  } else {
    // Clear it out in case this is not the first engine launch from the
    // embedder config builder.
    project_args.command_line_argv = nullptr;
    project_args.command_line_argc = 0;
  }

  std::vector<const char*> dart_args;
  dart_args.reserve(dart_entrypoint_arguments_.size());

  for (const auto& arg : dart_entrypoint_arguments_) {
    dart_args.push_back(arg.c_str());
  }

  if (dart_args.size() > 0) {
    project_args.dart_entrypoint_argv = dart_args.data();
    project_args.dart_entrypoint_argc = dart_args.size();
  } else {
    // Clear it out in case this is not the first engine launch from the
    // embedder config builder.
    project_args.dart_entrypoint_argv = nullptr;
    project_args.dart_entrypoint_argc = 0;
  }

  auto result =
      run ? FlutterEngineRun(FLUTTER_ENGINE_VERSION, &renderer_config_,
                             &project_args, &context_, &engine)
          : FlutterEngineInitialize(FLUTTER_ENGINE_VERSION, &renderer_config_,
                                    &project_args, &context_, &engine);

  if (result != kSuccess) {
    return {};
  }

  return UniqueEngine{engine};
}

}  // namespace testing
}  // namespace flutter
