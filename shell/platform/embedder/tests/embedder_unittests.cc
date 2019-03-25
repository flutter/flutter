// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <string>
#include "embedder.h"
#include "flutter/fml/file.h"
#include "flutter/fml/mapping.h"
#include "flutter/shell/platform/embedder/tests/embedder_config_builder.h"
#include "flutter/shell/platform/embedder/tests/embedder_test.h"
#include "flutter/testing/testing.h"

namespace shell {
namespace testing {

static void MapAOTAsset(
    std::vector<std::unique_ptr<fml::FileMapping>>& aot_mappings,
    const fml::UniqueFD& fixtures_dir,
    const char* path,
    bool executable,
    const uint8_t** data,
    size_t* size) {
  fml::UniqueFD file =
      fml::OpenFile(fixtures_dir, path, false, fml::FilePermission::kRead);
  std::unique_ptr<fml::FileMapping> mapping;
  if (executable) {
    mapping = std::make_unique<fml::FileMapping>(
        file, std::initializer_list<fml::FileMapping::Protection>{
                  fml::FileMapping::Protection::kRead,
                  fml::FileMapping::Protection::kExecute});
  } else {
    mapping = std::make_unique<fml::FileMapping>(
        file, std::initializer_list<fml::FileMapping::Protection>{
                  fml::FileMapping::Protection::kRead});
  }
  *data = mapping->GetMapping();
  *size = mapping->GetSize();
  aot_mappings.emplace_back(std::move(mapping));
}

TEST(EmbedderTest, MustNotRunWithInvalidArgs) {
  FlutterEngine engine = nullptr;
  FlutterRendererConfig config = {};
  FlutterProjectArgs args = {};
  FlutterEngineResult result = FlutterEngineRun(FLUTTER_ENGINE_VERSION + 1,
                                                &config, &args, NULL, &engine);
  ASSERT_NE(result, FlutterEngineResult::kSuccess);
}

TEST(EmbedderTest, CanLaunchAndShutdownWithValidProjectArgs) {
  FlutterSoftwareRendererConfig renderer;
  renderer.struct_size = sizeof(FlutterSoftwareRendererConfig);
  renderer.surface_present_callback = [](void*, const void*, size_t, size_t) {
    return false;
  };

  FlutterRendererConfig config = {};
  config.type = FlutterRendererType::kSoftware;
  config.software = renderer;

  FlutterProjectArgs args = {};
  args.struct_size = sizeof(FlutterProjectArgs);
  args.assets_path = ::testing::GetFixturesPath();
  args.root_isolate_create_callback = [](void* data) {
    std::string str_data = reinterpret_cast<char*>(data);
    ASSERT_EQ(str_data, "Data");
  };

  fml::UniqueFD fixtures_dir = fml::OpenDirectory(
      ::testing::GetFixturesPath(), false, fml::FilePermission::kRead);
  std::vector<std::unique_ptr<fml::FileMapping>> aot_mappings;
  if (fml::FileExists(fixtures_dir, "vm_snapshot_data")) {
    MapAOTAsset(aot_mappings, fixtures_dir, "vm_snapshot_data", false,
                &args.vm_snapshot_data, &args.vm_snapshot_data_size);
    MapAOTAsset(aot_mappings, fixtures_dir, "vm_snapshot_instr", true,
                &args.vm_snapshot_instructions,
                &args.vm_snapshot_instructions_size);
    MapAOTAsset(aot_mappings, fixtures_dir, "isolate_snapshot_data", false,
                &args.isolate_snapshot_data, &args.isolate_snapshot_data_size);
    MapAOTAsset(aot_mappings, fixtures_dir, "isolate_snapshot_instr", true,
                &args.isolate_snapshot_instructions,
                &args.isolate_snapshot_instructions_size);
  }

  std::string str_data = "Data";
  void* user_data = const_cast<char*>(str_data.c_str());
  FlutterEngine engine = nullptr;
  FlutterEngineResult result = FlutterEngineRun(FLUTTER_ENGINE_VERSION, &config,
                                                &args, user_data, &engine);
  ASSERT_EQ(result, FlutterEngineResult::kSuccess);

  result = FlutterEngineShutdown(engine);
  ASSERT_EQ(result, FlutterEngineResult::kSuccess);
}

using EmbedderFixture = testing::EmbedderTest;

TEST_F(EmbedderFixture, CanLaunchAndShutdownWithFixture) {
  EmbedderConfigBuilder builder;

  builder.SetSoftwareRendererConfig();
  builder.SetAssetsPathFromFixture(this);
  builder.SetSnapshotsFromFixture(this);

  auto engine = builder.LaunchEngine();
  ASSERT_TRUE(engine.is_valid());
}

TEST_F(EmbedderFixture, CanLaunchAndShutdownWithFixtureMultipleTimes) {
  EmbedderConfigBuilder builder;

  builder.SetSoftwareRendererConfig();
  builder.SetAssetsPathFromFixture(this);
  builder.SetSnapshotsFromFixture(this);
  for (size_t i = 0; i < 100; ++i) {
    auto engine = builder.LaunchEngine();
    ASSERT_TRUE(engine.is_valid());
    FML_LOG(INFO) << "Engine launch count: " << i + 1;
  }
}

}  // namespace testing
}  // namespace shell