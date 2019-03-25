// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/embedder/tests/embedder_config_builder.h"

namespace shell {
namespace testing {

EmbedderConfigBuilder::EmbedderConfigBuilder() {
  project_args_.struct_size = sizeof(project_args_);

  software_renderer_config_.struct_size = sizeof(FlutterSoftwareRendererConfig);
  software_renderer_config_.surface_present_callback =
      [](void*, const void*, size_t, size_t) { return true; };
}

EmbedderConfigBuilder::~EmbedderConfigBuilder() = default;

void EmbedderConfigBuilder::SetSoftwareRendererConfig() {
  renderer_config_.type = FlutterRendererType::kSoftware;
  renderer_config_.software = software_renderer_config_;
}

void EmbedderConfigBuilder::SetAssetsPathFromFixture(
    const EmbedderTest* fixture) {
  assets_path_ = fixture->GetAssetsPath();
  project_args_.assets_path = assets_path_.c_str();
}

void EmbedderConfigBuilder::SetSnapshotsFromFixture(
    const EmbedderTest* fixture) {
  if (auto mapping = fixture->GetVMSnapshotData()) {
    project_args_.vm_snapshot_data = mapping->GetMapping();
    project_args_.vm_snapshot_data_size = mapping->GetSize();
  }

  if (auto mapping = fixture->GetVMSnapshotInstructions()) {
    project_args_.vm_snapshot_instructions = mapping->GetMapping();
    project_args_.vm_snapshot_instructions_size = mapping->GetSize();
  }

  if (auto mapping = fixture->GetIsolateSnapshotData()) {
    project_args_.isolate_snapshot_data = mapping->GetMapping();
    project_args_.isolate_snapshot_data_size = mapping->GetSize();
  }

  if (auto mapping = fixture->GetIsolateSnapshotInstructions()) {
    project_args_.isolate_snapshot_instructions = mapping->GetMapping();
    project_args_.isolate_snapshot_instructions_size = mapping->GetSize();
  }
}

UniqueEngine EmbedderConfigBuilder::LaunchEngine(void* user_data) const {
  FlutterEngine engine = nullptr;
  auto result = FlutterEngineRun(FLUTTER_ENGINE_VERSION, &renderer_config_,
                                 &project_args_, user_data, &engine);

  if (result != kSuccess) {
    return {};
  }

  return UniqueEngine{engine};
}

}  // namespace testing
}  // namespace shell
