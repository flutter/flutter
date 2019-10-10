// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/embedder/tests/embedder_test_context.h"

#include "flutter/runtime/dart_vm.h"
#include "flutter/shell/platform/embedder/tests/embedder_assertions.h"
#include "third_party/dart/runtime/bin/elf_loader.h"
#include "third_party/skia/include/core/SkSurface.h"

namespace flutter {
namespace testing {

EmbedderTestContext::EmbedderTestContext(std::string assets_path)
    : assets_path_(std::move(assets_path)),
      native_resolver_(std::make_shared<TestDartNativeResolver>()) {
  auto assets_dir = fml::OpenDirectory(assets_path_.c_str(), false,
                                       fml::FilePermission::kRead);

  if (flutter::DartVM::IsRunningPrecompiledCode()) {
    std::string filename(assets_path_);
    filename += "/app_elf_snapshot.so";

    const uint8_t *vm_snapshot_data = nullptr,
                  *vm_snapshot_instructions = nullptr,
                  *isolate_snapshot_data = nullptr,
                  *isolate_snapshot_instructions = nullptr;
    const char* error = nullptr;

    elf_library_handle_ =
        Dart_LoadELF(filename.c_str(), /*file_offset=*/0, &error,
                     &vm_snapshot_data, &vm_snapshot_instructions,
                     &isolate_snapshot_data, &isolate_snapshot_instructions);

    if (elf_library_handle_ != nullptr) {
      vm_snapshot_data_.reset(new fml::NonOwnedMapping(vm_snapshot_data, 0));
      vm_snapshot_instructions_.reset(
          new fml::NonOwnedMapping(vm_snapshot_instructions, 0));
      isolate_snapshot_data_.reset(
          new fml::NonOwnedMapping(isolate_snapshot_data, 0));
      isolate_snapshot_instructions_.reset(
          new fml::NonOwnedMapping(isolate_snapshot_instructions, 0));
    } else {
      FML_LOG(WARNING) << "Could not load snapshot: " << error;
    }
  }

  isolate_create_callbacks_.push_back(
      [weak_resolver =
           std::weak_ptr<TestDartNativeResolver>{native_resolver_}]() {
        if (auto resolver = weak_resolver.lock()) {
          resolver->SetNativeResolverForIsolate();
        }
      });
}

EmbedderTestContext::~EmbedderTestContext() {
  if (elf_library_handle_ != nullptr) {
    Dart_UnloadELF(elf_library_handle_);
  }
}

const std::string& EmbedderTestContext::GetAssetsPath() const {
  return assets_path_;
}

const fml::Mapping* EmbedderTestContext::GetVMSnapshotData() const {
  return vm_snapshot_data_.get();
}

const fml::Mapping* EmbedderTestContext::GetVMSnapshotInstructions() const {
  return vm_snapshot_instructions_.get();
}

const fml::Mapping* EmbedderTestContext::GetIsolateSnapshotData() const {
  return isolate_snapshot_data_.get();
}

const fml::Mapping* EmbedderTestContext::GetIsolateSnapshotInstructions()
    const {
  return isolate_snapshot_instructions_.get();
}

void EmbedderTestContext::SetRootSurfaceTransformation(SkMatrix matrix) {
  root_surface_transformation_ = matrix;
}

void EmbedderTestContext::AddIsolateCreateCallback(fml::closure closure) {
  if (closure) {
    isolate_create_callbacks_.push_back(closure);
  }
}

VoidCallback EmbedderTestContext::GetIsolateCreateCallbackHook() {
  return [](void* user_data) {
    reinterpret_cast<EmbedderTestContext*>(user_data)
        ->FireIsolateCreateCallbacks();
  };
}

void EmbedderTestContext::FireIsolateCreateCallbacks() {
  for (auto closure : isolate_create_callbacks_) {
    closure();
  }
}

void EmbedderTestContext::AddNativeCallback(const char* name,
                                            Dart_NativeFunction function) {
  native_resolver_->AddNativeCallback({name}, function);
}

void EmbedderTestContext::SetSemanticsNodeCallback(
    SemanticsNodeCallback update_semantics_node_callback) {
  update_semantics_node_callback_ = update_semantics_node_callback;
}

void EmbedderTestContext::SetSemanticsCustomActionCallback(
    SemanticsActionCallback update_semantics_custom_action_callback) {
  update_semantics_custom_action_callback_ =
      update_semantics_custom_action_callback;
}

void EmbedderTestContext::SetPlatformMessageCallback(
    std::function<void(const FlutterPlatformMessage*)> callback) {
  platform_message_callback_ = callback;
}

void EmbedderTestContext::PlatformMessageCallback(
    const FlutterPlatformMessage* message) {
  if (platform_message_callback_) {
    platform_message_callback_(message);
  }
}

FlutterUpdateSemanticsNodeCallback
EmbedderTestContext::GetUpdateSemanticsNodeCallbackHook() {
  return [](const FlutterSemanticsNode* semantics_node, void* user_data) {
    auto context = reinterpret_cast<EmbedderTestContext*>(user_data);
    if (auto callback = context->update_semantics_node_callback_) {
      callback(semantics_node);
    }
  };
}

FlutterUpdateSemanticsCustomActionCallback
EmbedderTestContext::GetUpdateSemanticsCustomActionCallbackHook() {
  return [](const FlutterSemanticsCustomAction* action, void* user_data) {
    auto context = reinterpret_cast<EmbedderTestContext*>(user_data);
    if (auto callback = context->update_semantics_custom_action_callback_) {
      callback(action);
    }
  };
}

void EmbedderTestContext::SetupOpenGLSurface(SkISize surface_size) {
  FML_CHECK(!gl_surface_);
  gl_surface_ = std::make_unique<TestGLSurface>(surface_size);
}

bool EmbedderTestContext::GLMakeCurrent() {
  FML_CHECK(gl_surface_) << "GL surface must be initialized.";
  return gl_surface_->MakeCurrent();
}

bool EmbedderTestContext::GLClearCurrent() {
  FML_CHECK(gl_surface_) << "GL surface must be initialized.";
  return gl_surface_->ClearCurrent();
}

bool EmbedderTestContext::GLPresent() {
  FML_CHECK(gl_surface_) << "GL surface must be initialized.";
  gl_surface_present_count_++;

  FireRootSurfacePresentCallbackIfPresent(
      [&]() { return gl_surface_->GetRasterSurfaceSnapshot(); });

  if (!gl_surface_->Present()) {
    return false;
  }

  return true;
}

uint32_t EmbedderTestContext::GLGetFramebuffer() {
  FML_CHECK(gl_surface_) << "GL surface must be initialized.";
  return gl_surface_->GetFramebuffer();
}

bool EmbedderTestContext::GLMakeResourceCurrent() {
  FML_CHECK(gl_surface_) << "GL surface must be initialized.";
  return gl_surface_->MakeResourceCurrent();
}

void* EmbedderTestContext::GLGetProcAddress(const char* name) {
  FML_CHECK(gl_surface_) << "GL surface must be initialized.";
  return gl_surface_->GetProcAddress(name);
}

FlutterTransformation EmbedderTestContext::GetRootSurfaceTransformation() {
  return FlutterTransformationMake(root_surface_transformation_);
}

void EmbedderTestContext::SetupCompositor() {
  FML_CHECK(!compositor_) << "Already ssetup a compositor in this context.";
  FML_CHECK(gl_surface_)
      << "Setup the GL surface before setting up a compositor.";
  compositor_ = std::make_unique<EmbedderTestCompositor>(
      gl_surface_->GetSurfaceSize(), gl_surface_->GetGrContext());
}

EmbedderTestCompositor& EmbedderTestContext::GetCompositor() {
  FML_CHECK(compositor_)
      << "Accessed the compositor on a context where one was not setup. Use "
         "the config builder to setup a context with a custom compositor.";
  return *compositor_;
}

void EmbedderTestContext::SetNextSceneCallback(
    NextSceneCallback next_scene_callback) {
  if (compositor_) {
    compositor_->SetNextSceneCallback(next_scene_callback);
    return;
  }
  next_scene_callback_ = next_scene_callback;
}

bool EmbedderTestContext::SofwarePresent(sk_sp<SkImage> image) {
  software_surface_present_count_++;

  FireRootSurfacePresentCallbackIfPresent([image] { return image; });

  return true;
}

size_t EmbedderTestContext::GetGLSurfacePresentCount() const {
  return gl_surface_present_count_;
}

size_t EmbedderTestContext::GetSoftwareSurfacePresentCount() const {
  return software_surface_present_count_;
}

void EmbedderTestContext::FireRootSurfacePresentCallbackIfPresent(
    std::function<sk_sp<SkImage>(void)> image_callback) {
  if (!next_scene_callback_) {
    return;
  }
  auto callback = next_scene_callback_;
  next_scene_callback_ = nullptr;
  callback(image_callback());
}

}  // namespace testing
}  // namespace flutter
