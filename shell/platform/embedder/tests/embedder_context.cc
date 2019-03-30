// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/embedder/tests/embedder_context.h"

#include "flutter/runtime/dart_vm.h"

namespace shell {
namespace testing {

static std::unique_ptr<fml::Mapping> GetMapping(const fml::UniqueFD& directory,
                                                const char* path,
                                                bool executable) {
  fml::UniqueFD file = fml::OpenFile(directory, path, false /* create */,
                                     fml::FilePermission::kRead);
  if (!file.is_valid()) {
    return nullptr;
  }

  using Prot = fml::FileMapping::Protection;
  std::unique_ptr<fml::FileMapping> mapping;
  if (executable) {
    mapping = std::make_unique<fml::FileMapping>(
        file, std::initializer_list<Prot>{Prot::kRead, Prot::kExecute});
  } else {
    mapping = std::make_unique<fml::FileMapping>(
        file, std::initializer_list<Prot>{Prot::kRead});
  }

  if (mapping->GetSize() == 0 || mapping->GetMapping() == nullptr) {
    return nullptr;
  }

  return mapping;
}

EmbedderContext::EmbedderContext(std::string assets_path)
    : assets_path_(std::move(assets_path)),
      native_resolver_(std::make_shared<::testing::TestDartNativeResolver>()) {
  auto assets_dir = fml::OpenDirectory(assets_path_.c_str(), false,
                                       fml::FilePermission::kRead);
  vm_snapshot_data_ = GetMapping(assets_dir, "vm_snapshot_data", false);
  isolate_snapshot_data_ =
      GetMapping(assets_dir, "isolate_snapshot_data", false);

  if (blink::DartVM::IsRunningPrecompiledCode()) {
    vm_snapshot_instructions_ =
        GetMapping(assets_dir, "vm_snapshot_instr", true);
    isolate_snapshot_instructions_ =
        GetMapping(assets_dir, "isolate_snapshot_instr", true);
  }

  isolate_create_callbacks_.push_back(
      [weak_resolver = std::weak_ptr<::testing::TestDartNativeResolver>{
           native_resolver_}]() {
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

}  // namespace testing
}  // namespace shell
