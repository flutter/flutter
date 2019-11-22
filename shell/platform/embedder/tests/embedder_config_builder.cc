// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/embedder/tests/embedder_config_builder.h"

#include "flutter/shell/platform/embedder/embedder.h"
#include "third_party/skia/include/core/SkBitmap.h"

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

  opengl_renderer_config_.struct_size = sizeof(FlutterOpenGLRendererConfig);
  opengl_renderer_config_.make_current = [](void* context) -> bool {
    return reinterpret_cast<EmbedderTestContext*>(context)->GLMakeCurrent();
  };
  opengl_renderer_config_.clear_current = [](void* context) -> bool {
    return reinterpret_cast<EmbedderTestContext*>(context)->GLClearCurrent();
  };
  opengl_renderer_config_.present = [](void* context) -> bool {
    return reinterpret_cast<EmbedderTestContext*>(context)->GLPresent();
  };
  opengl_renderer_config_.fbo_callback = [](void* context) -> uint32_t {
    return reinterpret_cast<EmbedderTestContext*>(context)->GLGetFramebuffer();
  };
  opengl_renderer_config_.make_resource_current = [](void* context) -> bool {
    return reinterpret_cast<EmbedderTestContext*>(context)
        ->GLMakeResourceCurrent();
  };
  opengl_renderer_config_.gl_proc_resolver = [](void* context,
                                                const char* name) -> void* {
    return reinterpret_cast<EmbedderTestContext*>(context)->GLGetProcAddress(
        name);
  };
  opengl_renderer_config_.fbo_reset_after_present = true;
  opengl_renderer_config_.surface_transformation =
      [](void* context) -> FlutterTransformation {
    return reinterpret_cast<EmbedderTestContext*>(context)
        ->GetRootSurfaceTransformation();
  };

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
        return reinterpret_cast<EmbedderTestContext*>(context)->SofwarePresent(
            SkImage::MakeFromBitmap(bitmap));
      };

  // The first argument is treated as the executable name. Don't make tests have
  // to do this manually.
  AddCommandLineArgument("embedder_unittest");

  if (preference == InitializationPreference::kInitialize) {
    SetAssetsPath();
    SetSnapshots();
    SetIsolateCreateCallbackHook();
    SetSemanticsCallbackHooks();
    AddCommandLineArgument("--disable-observatory");
  }
}

EmbedderConfigBuilder::~EmbedderConfigBuilder() = default;

FlutterProjectArgs& EmbedderConfigBuilder::GetProjectArgs() {
  return project_args_;
}

void EmbedderConfigBuilder::SetSoftwareRendererConfig(SkISize surface_size) {
  renderer_config_.type = FlutterRendererType::kSoftware;
  renderer_config_.software = software_renderer_config_;

  // TODO(chinmaygarde): The compositor still uses a GL surface for operation.
  // Once this is no longer the case, don't setup the GL surface when using the
  // software renderer config.
  context_.SetupOpenGLSurface(surface_size);
}

void EmbedderConfigBuilder::SetOpenGLRendererConfig(SkISize surface_size) {
  renderer_config_.type = FlutterRendererType::kOpenGL;
  renderer_config_.open_gl = opengl_renderer_config_;
  context_.SetupOpenGLSurface(surface_size);
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
