// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/embedder/tests/embedder_context.h"

#include "flutter/runtime/dart_vm.h"

namespace flutter {
namespace testing {

EmbedderContext::EmbedderContext(std::string assets_path)
    : assets_path_(std::move(assets_path)),
      native_resolver_(std::make_shared<TestDartNativeResolver>()) {
  auto assets_dir = fml::OpenDirectory(assets_path_.c_str(), false,
                                       fml::FilePermission::kRead);
  vm_snapshot_data_ =
      fml::FileMapping::CreateReadOnly(assets_dir, "vm_snapshot_data");
  isolate_snapshot_data_ =
      fml::FileMapping::CreateReadOnly(assets_dir, "isolate_snapshot_data");

  if (flutter::DartVM::IsRunningPrecompiledCode()) {
    vm_snapshot_instructions_ =
        fml::FileMapping::CreateReadExecute(assets_dir, "vm_snapshot_instr");
    isolate_snapshot_instructions_ = fml::FileMapping::CreateReadExecute(
        assets_dir, "isolate_snapshot_instr");
  }

  isolate_create_callbacks_.push_back(
      [weak_resolver =
           std::weak_ptr<TestDartNativeResolver>{native_resolver_}]() {
        if (auto resolver = weak_resolver.lock()) {
          resolver->SetNativeResolverForIsolate();
        }
      });
}

EmbedderContext::~EmbedderContext() = default;

const std::string& EmbedderContext::GetAssetsPath() const {
  return assets_path_;
}

const fml::Mapping* EmbedderContext::GetVMSnapshotData() const {
  return vm_snapshot_data_.get();
}

const fml::Mapping* EmbedderContext::GetVMSnapshotInstructions() const {
  return vm_snapshot_instructions_.get();
}

const fml::Mapping* EmbedderContext::GetIsolateSnapshotData() const {
  return isolate_snapshot_data_.get();
}

const fml::Mapping* EmbedderContext::GetIsolateSnapshotInstructions() const {
  return isolate_snapshot_instructions_.get();
}

void EmbedderContext::AddIsolateCreateCallback(fml::closure closure) {
  if (closure) {
    isolate_create_callbacks_.push_back(closure);
  }
}

VoidCallback EmbedderContext::GetIsolateCreateCallbackHook() {
  return [](void* user_data) {
    reinterpret_cast<EmbedderContext*>(user_data)->FireIsolateCreateCallbacks();
  };
}

void EmbedderContext::FireIsolateCreateCallbacks() {
  for (auto closure : isolate_create_callbacks_) {
    closure();
  }
}

void EmbedderContext::AddNativeCallback(const char* name,
                                        Dart_NativeFunction function) {
  native_resolver_->AddNativeCallback({name}, function);
}

void EmbedderContext::SetSemanticsNodeCallback(
    SemanticsNodeCallback update_semantics_node_callback) {
  update_semantics_node_callback_ = update_semantics_node_callback;
}

void EmbedderContext::SetSemanticsCustomActionCallback(
    SemanticsActionCallback update_semantics_custom_action_callback) {
  update_semantics_custom_action_callback_ =
      update_semantics_custom_action_callback;
}

void EmbedderContext::SetPlatformMessageCallback(
    std::function<void(const FlutterPlatformMessage*)> callback) {
  platform_message_callback_ = callback;
}

void EmbedderContext::PlatformMessageCallback(
    const FlutterPlatformMessage* message) {
  if (platform_message_callback_) {
    platform_message_callback_(message);
  }
}

FlutterUpdateSemanticsNodeCallback
EmbedderContext::GetUpdateSemanticsNodeCallbackHook() {
  return [](const FlutterSemanticsNode* semantics_node, void* user_data) {
    auto context = reinterpret_cast<EmbedderContext*>(user_data);
    if (auto callback = context->update_semantics_node_callback_) {
      callback(semantics_node);
    }
  };
}

FlutterUpdateSemanticsCustomActionCallback
EmbedderContext::GetUpdateSemanticsCustomActionCallbackHook() {
  return [](const FlutterSemanticsCustomAction* action, void* user_data) {
    auto context = reinterpret_cast<EmbedderContext*>(user_data);
    if (auto callback = context->update_semantics_custom_action_callback_) {
      callback(action);
    }
  };
}

void EmbedderContext::SetupOpenGLSurface() {
  gl_surface_ = std::make_unique<TestGLSurface>();
}

bool EmbedderContext::GLMakeCurrent() {
  FML_CHECK(gl_surface_) << "GL surface must be initialized.";
  return gl_surface_->MakeCurrent();
}

bool EmbedderContext::GLClearCurrent() {
  FML_CHECK(gl_surface_) << "GL surface must be initialized.";
  return gl_surface_->ClearCurrent();
}

bool EmbedderContext::GLPresent() {
  FML_CHECK(gl_surface_) << "GL surface must be initialized.";
  return gl_surface_->Present();
}

uint32_t EmbedderContext::GLGetFramebuffer() {
  FML_CHECK(gl_surface_) << "GL surface must be initialized.";
  return gl_surface_->GetFramebuffer();
}

bool EmbedderContext::GLMakeResourceCurrent() {
  FML_CHECK(gl_surface_) << "GL surface must be initialized.";
  return gl_surface_->MakeResourceCurrent();
}

void* EmbedderContext::GLGetProcAddress(const char* name) {
  FML_CHECK(gl_surface_) << "GL surface must be initialized.";
  return gl_surface_->GetProcAddress(name);
}

}  // namespace testing
}  // namespace flutter
