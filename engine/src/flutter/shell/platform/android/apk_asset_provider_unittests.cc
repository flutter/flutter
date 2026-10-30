// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/apk_asset_provider.h"

#include <atomic>
#include <future>
#include <thread>
#include <vector>

#include "gmock/gmock.h"
#include "gtest/gtest.h"

namespace flutter {
namespace testing {

class MockAPKAssetProviderImpl : public APKAssetProviderInternal {
 public:
  MOCK_METHOD(std::unique_ptr<fml::Mapping>,
              GetAsMapping,
              (const std::string& asset_name),
              (const, override));

  MOCK_METHOD(std::vector<std::unique_ptr<fml::Mapping>>,
              GetAsMappings,
              (const std::string& asset_pattern,
               const std::optional<std::string>& subdir),
              (const, override));

  MOCK_METHOD(const std::string&, GetDirectory, (), (const, override));
};

TEST(APKAssetProvider, CloneAndEquals) {
  auto first_provider = std::make_unique<APKAssetProvider>(
      std::make_shared<MockAPKAssetProviderImpl>());
  auto second_provider = std::make_unique<APKAssetProvider>(
      std::make_shared<MockAPKAssetProviderImpl>());
  auto third_provider = first_provider->Clone();

  ASSERT_NE(first_provider->GetImpl(), second_provider->GetImpl());
  ASSERT_EQ(first_provider->GetImpl(), third_provider->GetImpl());
  ASSERT_FALSE(*first_provider == *second_provider);
  ASSERT_TRUE(*first_provider == *third_provider);
  ASSERT_TRUE(first_provider->IsValid());
  ASSERT_TRUE(first_provider->IsValidAfterAssetManagerChange());
}

TEST(APKAssetProvider, InMemoryAssetResolution) {
  auto in_memory_impl =
      std::make_shared<InMemoryAPKAssetProviderImpl>("flutter_assets");
  std::string test_data = "Hello Flutter Embedder Asset";
  in_memory_impl->AddAsset("test.txt", test_data);

  auto provider = std::make_unique<APKAssetProvider>(in_memory_impl);
  EXPECT_EQ(provider->GetDirectory(), "flutter_assets");

  auto mapping = provider->GetAsMapping("test.txt");
  ASSERT_NE(mapping, nullptr);
  EXPECT_EQ(mapping->GetSize(), test_data.size());
  EXPECT_EQ(std::string(reinterpret_cast<const char*>(mapping->GetMapping()),
                        mapping->GetSize()),
            test_data);

  EXPECT_EQ(provider->GetAsMapping("nonexistent.bin"), nullptr);
}

TEST(APKAssetProvider, InMemoryDirectoryMappingAndPattern) {
  auto in_memory_impl =
      std::make_shared<InMemoryAPKAssetProviderImpl>("flutter_assets");
  in_memory_impl->AddAsset("fonts/FontA.ttf", "FontAData");
  in_memory_impl->AddAsset("fonts/FontB.ttf", "FontBData");
  in_memory_impl->AddAsset("images/logo.png", "PNGData");
  in_memory_impl->AddAsset("AssetManifest.json", "{}");

  auto provider = std::make_unique<APKAssetProvider>(in_memory_impl);

  constexpr size_t kExpectedFontCount = 2;
  constexpr size_t kExpectedImageCount = 1;

  auto font_mappings = provider->GetAsMappings("ttf", "fonts");
  EXPECT_EQ(font_mappings.size(), kExpectedFontCount);

  auto all_fonts = provider->GetAsMappings("*", "fonts");
  EXPECT_EQ(all_fonts.size(), kExpectedFontCount);

  auto images = provider->GetAsMappings("png", "images");
  EXPECT_EQ(images.size(), kExpectedImageCount);
}

TEST(APKAssetProvider, InMemoryAssetRemovalAndClear) {
  auto in_memory_impl =
      std::make_shared<InMemoryAPKAssetProviderImpl>("flutter_assets");
  in_memory_impl->AddAsset("asset1.bin", "data1");
  in_memory_impl->AddAsset("asset2.bin", "data2");

  auto provider = std::make_unique<APKAssetProvider>(in_memory_impl);
  EXPECT_NE(provider->GetAsMapping("asset1.bin"), nullptr);
  EXPECT_NE(provider->GetAsMapping("asset2.bin"), nullptr);

  in_memory_impl->RemoveAsset("asset1.bin");
  EXPECT_EQ(provider->GetAsMapping("asset1.bin"), nullptr);
  EXPECT_NE(provider->GetAsMapping("asset2.bin"), nullptr);

  in_memory_impl->ClearAssets();
  EXPECT_EQ(provider->GetAsMapping("asset2.bin"), nullptr);
}

TEST(APKAssetProvider, CustomAssetResolverCallbacksAndUpdate) {
  auto in_memory_impl =
      std::make_shared<InMemoryAPKAssetProviderImpl>("flutter_assets");
  std::string test_data = "{\"manifest\":true}";
  in_memory_impl->AddAsset("manifest.json", test_data);

  auto provider = std::make_unique<APKAssetProvider>(in_memory_impl);
  FlutterCustomAssetResolver resolver = provider->CreateCustomAssetResolver();

  EXPECT_EQ(resolver.struct_size, sizeof(FlutterCustomAssetResolver));
  ASSERT_NE(resolver.user_data, nullptr);
  ASSERT_NE(resolver.get_as_mapping_callback, nullptr);
  ASSERT_NE(resolver.destruction_callback, nullptr);

  FlutterAssetMapping asset_mapping = {};
  EXPECT_TRUE(resolver.get_as_mapping_callback(
      "manifest.json", resolver.user_data, &asset_mapping));
  EXPECT_EQ(asset_mapping.struct_size, sizeof(FlutterAssetMapping));
  ASSERT_NE(asset_mapping.mapping, nullptr);
  EXPECT_EQ(asset_mapping.mapping_size, test_data.size());
  EXPECT_EQ(std::string(reinterpret_cast<const char*>(asset_mapping.mapping),
                        asset_mapping.mapping_size),
            test_data);
  if (asset_mapping.destruction_callback) {
    asset_mapping.destruction_callback(asset_mapping.user_data);
  }

  FlutterAssetMapping missing_mapping = {};
  EXPECT_FALSE(resolver.get_as_mapping_callback(
      "missing.dat", resolver.user_data, &missing_mapping));

  // Verify UpdateAssetManager updates directory shared with active resolver.
  provider->UpdateAssetManager(nullptr, nullptr, "updated_assets");
  EXPECT_EQ(provider->GetDirectory(), "updated_assets");

  resolver.destruction_callback(resolver.user_data);
}

TEST(APKAssetProvider, ThreadSafeConcurrentMutationsAndReads) {
  constexpr int kInitialAssetCount = 20;
  constexpr int kDynamicSlotCount = 10;
  constexpr int kRemoveModulo = 3;
  constexpr size_t kReaderCount = 6;
  constexpr size_t kIterations = 150;

  auto in_memory_impl =
      std::make_shared<InMemoryAPKAssetProviderImpl>("flutter_assets");
  for (int i = 0; i < kInitialAssetCount; ++i) {
    in_memory_impl->AddAsset("initial_" + std::to_string(i),
                             "InitialData_" + std::to_string(i));
  }

  auto provider = std::make_shared<APKAssetProvider>(in_memory_impl);
  std::atomic<bool> stop_writers{false};

  auto writer_future =
      std::async(std::launch::async, [&in_memory_impl, &stop_writers]() {
        int counter = 0;
        while (!stop_writers.load()) {
          std::string name =
              "dynamic_" + std::to_string(counter % kDynamicSlotCount);
          in_memory_impl->AddAsset(name,
                                   "DynamicContent_" + std::to_string(counter));
          if (counter % kRemoveModulo == 0) {
            in_memory_impl->RemoveAsset(name);
          }
          counter++;
          std::this_thread::yield();
        }
      });

  std::vector<std::future<bool>> reader_futures;
  reader_futures.reserve(kReaderCount);

  for (size_t t = 0; t < kReaderCount; ++t) {
    reader_futures.push_back(std::async(std::launch::async, [provider, t]() {
      for (size_t iter = 0; iter < kIterations; ++iter) {
        int idx = static_cast<int>((t + iter) % kInitialAssetCount);
        std::string name = "initial_" + std::to_string(idx);
        auto mapping = provider->GetAsMapping(name);
        if (!mapping || mapping->GetSize() == 0) {
          return false;
        }
      }
      return true;
    }));
  }

  for (auto& f : reader_futures) {
    EXPECT_TRUE(f.get());
  }

  stop_writers.store(true);
  writer_future.get();
}

}  // namespace testing
}  // namespace flutter
