// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/embedder_bridge.h"
#include "flutter/shell/common/shell.h"
#include "flutter/shell/platform/embedder/embedder_engine.h"

namespace flutter {

EmbedderBridge::EmbedderBridge(
    const flutter::TaskRunners& task_runners,
    const std::shared_ptr<PlatformViewAndroidJNI>& jni_facade,
    const flutter::Settings& settings)
    : task_runners_(task_runners),
      jni_facade_(jni_facade),
      settings_(settings) {
  FlutterRendererConfig renderer_config = {};
  renderer_config.type = kOpenGL;
  renderer_config.open_gl.struct_size = sizeof(FlutterOpenGLRendererConfig);
  renderer_config.open_gl.make_current = &EmbedderBridge::MakeCurrent;
  renderer_config.open_gl.clear_current = &EmbedderBridge::ClearCurrent;
  renderer_config.open_gl.present = &EmbedderBridge::Present;
  renderer_config.open_gl.fbo_callback = &EmbedderBridge::GetFBO;

  FlutterProjectArgs args = {};
  args.struct_size = sizeof(FlutterProjectArgs);
  std::filesystem::path p(settings.application_kernel_asset);
  args.assets_path = p.parent_path().c_str();
  args.platform_message_callback = &EmbedderBridge::OnPlatformMessage;

  FlutterEngineResult result = FlutterEngineInitialize(
      FLUTTER_ENGINE_VERSION, &renderer_config, &args, this, &engine_);
  if (result != kSuccess || engine_ == nullptr) {
    FML_LOG(ERROR) << "Failed to initialize Flutter engine: " << result;
  }
}

EmbedderBridge::~EmbedderBridge() {
  if (engine_) {
    FlutterEngineShutdown(engine_);
  }
}

bool EmbedderBridge::IsValid() const {
  return engine_ != nullptr;
}

void EmbedderBridge::Run(const std::string& entrypoint) {
  FML_LOG(ERROR) << "Running";
  FlutterRendererConfig renderer_config = {};
  renderer_config.type = kOpenGL;
  renderer_config.open_gl.struct_size = sizeof(FlutterOpenGLRendererConfig);
  renderer_config.open_gl.make_current = &EmbedderBridge::MakeCurrent;
  renderer_config.open_gl.clear_current = &EmbedderBridge::ClearCurrent;
  renderer_config.open_gl.present = &EmbedderBridge::Present;
  renderer_config.open_gl.fbo_callback = &EmbedderBridge::GetFBO;

  FlutterProjectArgs args = {};
  FML_LOG(ERROR) << "Creating Project args";
  args.struct_size = sizeof(FlutterProjectArgs);
  args.assets_path = settings_.assets_path.c_str();
  args.custom_dart_entrypoint = entrypoint.c_str();
  args.platform_message_callback = &EmbedderBridge::OnPlatformMessage;

  FlutterEngineResult result = FlutterEngineRun(
      FLUTTER_ENGINE_VERSION, &renderer_config, &args, this, &engine_);

  if (result != kSuccess || engine_ == nullptr) {
    FML_LOG(ERROR) << "Failed to run Flutter engine.";
  }
}

shell::Shell& EmbedderBridge::GetShell() {
  if (!engine_) {
    return nullptr;
  }
  auto embedder_engine = reinterpret_cast<EmbedderEngine*>(engine_);

  return &embedder_engine->GetShell();
}

void EmbedderBridge::OnVsync(int64_t baton,
                             fml::TimePoint frame_start_time,
                             fml::TimePoint frame_target_time) {
  FlutterEngineOnVsync(engine_, baton,
                       frame_start_time.ToEpochDelta().ToNanoseconds(),
                       frame_target_time.ToEpochDelta().ToNanoseconds());
}

// --- Embedder API Callbacks ---

bool EmbedderBridge::MakeCurrent(void* user_data) {
  // Implementation to make the GL context current.
  return true;
}

bool EmbedderBridge::ClearCurrent(void* user_data) {
  // Implementation to clear the GL context.
  return true;
}

bool EmbedderBridge::Present(void* user_data) {
  // Implementation to present the rendered frame.
  return true;
}

uint32_t EmbedderBridge::GetFBO(void* user_data) {
  // Implementation to get the framebuffer object.
  return 0;
}

void EmbedderBridge::OnPlatformMessage(const FlutterPlatformMessage* message,
                                       void* user_data) {
  // Implementation to handle platform messages.
  FML_LOG(ERROR) << "Platform Message: " << message;
}

void EmbedderBridge::VsyncCallback(void* user_data, intptr_t baton) {
  // Implementation to request a vsync signal from the platform.
}

}  // namespace flutter
