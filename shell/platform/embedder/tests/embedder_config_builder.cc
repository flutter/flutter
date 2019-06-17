// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/embedder/tests/embedder_config_builder.h"

namespace flutter {
namespace testing {

EmbedderConfigBuilder::EmbedderConfigBuilder(
    EmbedderContext& context,
    InitializationPreference preference)
    : context_(context) {
  project_args_.struct_size = sizeof(project_args_);
  project_args_.platform_message_callback =
      [](const FlutterPlatformMessage* message, void* context) {
        reinterpret_cast<EmbedderContext*>(context)->PlatformMessageCallback(
            message);
      };

  custom_task_runners_.struct_size = sizeof(FlutterCustomTaskRunners);

  opengl_renderer_config_.struct_size = sizeof(FlutterOpenGLRendererConfig);
  opengl_renderer_config_.make_current = [](void* context) -> bool {
    return reinterpret_cast<EmbedderContext*>(context)->GLMakeCurrent();
  };
  opengl_renderer_config_.clear_current = [](void* context) -> bool {
    return reinterpret_cast<EmbedderContext*>(context)->GLClearCurrent();
  };
  opengl_renderer_config_.present = [](void* context) -> bool {
    return reinterpret_cast<EmbedderContext*>(context)->GLPresent();
  };
  opengl_renderer_config_.fbo_callback = [](void* context) -> uint32_t {
    return reinterpret_cast<EmbedderContext*>(context)->GLGetFramebuffer();
  };
  opengl_renderer_config_.make_resource_current = [](void* context) -> bool {
    return reinterpret_cast<EmbedderContext*>(context)->GLMakeResourceCurrent();
  };
  opengl_renderer_config_.gl_proc_resolver = [](void* context,
                                                const char* name) -> void* {
    return reinterpret_cast<EmbedderContext*>(context)->GLGetProcAddress(name);
  };

  software_renderer_config_.struct_size = sizeof(FlutterSoftwareRendererConfig);
  software_renderer_config_.surface_present_callback =
      [](void*, const void*, size_t, size_t) { return true; };

  if (preference == InitializationPreference::kInitialize) {
    SetSoftwareRendererConfig();
    SetAssetsPath();
    SetSnapshots();
    SetIsolateCreateCallbackHook();
    SetSemanticsCallbackHooks();
  }
}

EmbedderConfigBuilder::~EmbedderConfigBuilder() = default;

void EmbedderConfigBuilder::SetSoftwareRendererConfig() {
  renderer_config_.type = FlutterRendererType::kSoftware;
  renderer_config_.software = software_renderer_config_;
}

void EmbedderConfigBuilder::SetOpenGLRendererConfig() {
  renderer_config_.type = FlutterRendererType::kOpenGL;
  renderer_config_.open_gl = opengl_renderer_config_;
  context_.SetupOpenGLSurface();
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
      EmbedderContext::GetIsolateCreateCallbackHook();
}

void EmbedderConfigBuilder::SetSemanticsCallbackHooks() {
  project_args_.update_semantics_node_callback =
      EmbedderContext::GetUpdateSemanticsNodeCallbackHook();
  project_args_.update_semantics_custom_action_callback =
      EmbedderContext::GetUpdateSemanticsCustomActionCallbackHook();
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

void EmbedderConfigBuilder::SetPlatformMessageCallback(
    std::function<void(const FlutterPlatformMessage*)> callback) {
  context_.SetPlatformMessageCallback(callback);
}

UniqueEngine EmbedderConfigBuilder::LaunchEngine() {
  FlutterEngine engine = nullptr;

  std::vector<const char*> args;
  args.reserve(command_line_arguments_.size());

  for (const auto& arg : command_line_arguments_) {
    args.push_back(arg.c_str());
  }

  if (args.size() > 0) {
    project_args_.command_line_argv = args.data();
    project_args_.command_line_argc = args.size();
  } else {
    // Clear it out in case this is not the first engine launch from the
    // embedder config builder.
    project_args_.command_line_argv = nullptr;
    project_args_.command_line_argc = 0;
  }

  auto result = FlutterEngineRun(FLUTTER_ENGINE_VERSION, &renderer_config_,
                                 &project_args_, &context_, &engine);

  if (result != kSuccess) {
    return {};
  }

  return UniqueEngine{engine};
}

}  // namespace testing
}  // namespace flutter
