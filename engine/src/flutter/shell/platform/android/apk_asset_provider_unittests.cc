// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <future>
#include <thread>
#include <vector>

#include "flutter/shell/platform/android/apk_asset_provider.h"
#include "gmock/gmock.h"
#include "gtest/gtest.h"

namespace flutter {
namespace testing {

using ::testing::_;
using ::testing::Return;

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
  ASSERT_EQ(first_provider->GetType(),
            AssetResolver::AssetResolverType::kApkAssetProvider);
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

  // Missing asset returns nullptr
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

  // Search in subdir fonts with .ttf
  auto font_mappings = provider->GetAsMappings("ttf", "fonts");
  EXPECT_EQ(font_mappings.size(), 2u);

  // Search with wildcard
  auto all_fonts = provider->GetAsMappings("*", "fonts");
  EXPECT_EQ(all_fonts.size(), 2u);

  // Search in images
  auto images = provider->GetAsMappings("png", "images");
  EXPECT_EQ(images.size(), 1u);
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

TEST(APKAssetProvider, StructSizesAndABI) {
#if UINTPTR_MAX == 0xffffffffffffffff
  EXPECT_EQ(sizeof(FlutterAsset), 40u);
  EXPECT_EQ(sizeof(FlutterAsset) % 8u, 0u);
  EXPECT_EQ(offsetof(FlutterAsset, struct_size), 0u);
  EXPECT_EQ(offsetof(FlutterAsset, data), 8u);
  EXPECT_EQ(offsetof(FlutterAsset, size), 16u);
  EXPECT_EQ(offsetof(FlutterAsset, user_data), 24u);
  EXPECT_EQ(offsetof(FlutterAsset, asset_free_callback), 32u);

  EXPECT_EQ(sizeof(FlutterCustomAssetResolver), 48u);
  EXPECT_EQ(sizeof(FlutterCustomAssetResolver) % 8u, 0u);
  EXPECT_EQ(offsetof(FlutterCustomAssetResolver, struct_size), 0u);
  EXPECT_EQ(offsetof(FlutterCustomAssetResolver, user_data), 8u);
  EXPECT_EQ(offsetof(FlutterCustomAssetResolver, find_asset_callback), 16u);
  EXPECT_EQ(offsetof(FlutterCustomAssetResolver, is_valid_callback), 24u);
  EXPECT_EQ(
      offsetof(FlutterCustomAssetResolver, is_valid_after_change_callback),
      32u);
  EXPECT_EQ(offsetof(FlutterCustomAssetResolver, destruction_callback), 40u);
#else
  EXPECT_EQ(sizeof(FlutterAsset), 24u);
  EXPECT_EQ(sizeof(FlutterAsset) % 8u, 0u);
  EXPECT_EQ(sizeof(FlutterCustomAssetResolver), 24u);
  EXPECT_EQ(sizeof(FlutterCustomAssetResolver) % 8u, 0u);
#endif
}

TEST(APKAssetProvider, CustomAssetResolverBridgeAndAdapter) {
  auto in_memory_impl =
      std::make_shared<InMemoryAPKAssetProviderImpl>("flutter_assets");
  std::string test_data = "CustomResolverPayload";
  in_memory_impl->AddAsset("manifest.json", test_data);

  auto provider = std::make_unique<APKAssetProvider>(in_memory_impl);
  FlutterCustomAssetResolver bridge = provider->CreateCustomAssetResolver();

  EXPECT_EQ(bridge.struct_size, sizeof(FlutterCustomAssetResolver));
  ASSERT_NE(bridge.find_asset_callback, nullptr);
  ASSERT_NE(bridge.is_valid_callback, nullptr);
  ASSERT_NE(bridge.is_valid_after_change_callback, nullptr);
  ASSERT_NE(bridge.destruction_callback, nullptr);

  EXPECT_TRUE(bridge.is_valid_callback(bridge.user_data));
  EXPECT_TRUE(bridge.is_valid_after_change_callback(bridge.user_data));

  // Null parameter safety
  FlutterAsset asset = {};
  EXPECT_FALSE(bridge.find_asset_callback(nullptr, "manifest.json", &asset));
  EXPECT_FALSE(bridge.find_asset_callback(bridge.user_data, nullptr, &asset));
  EXPECT_FALSE(
      bridge.find_asset_callback(bridge.user_data, "manifest.json", nullptr));

  // Resolve existing asset
  EXPECT_TRUE(
      bridge.find_asset_callback(bridge.user_data, "manifest.json", &asset));
  EXPECT_EQ(asset.size, test_data.size());
  EXPECT_EQ(std::string(reinterpret_cast<const char*>(asset.data), asset.size),
            test_data);
  ASSERT_NE(asset.asset_free_callback, nullptr);
  asset.asset_free_callback(asset.user_data);

  // Missing asset
  FlutterAsset missing_asset = {};
  EXPECT_FALSE(bridge.find_asset_callback(bridge.user_data, "missing.dat",
                                          &missing_asset));

  // Wrap into CustomAssetResolverAdapter
  auto adapter = APKAssetProvider::CreateAssetResolver(bridge);
  ASSERT_NE(adapter, nullptr);
  EXPECT_TRUE(adapter->IsValid());
  EXPECT_TRUE(adapter->IsValidAfterAssetManagerChange());
  EXPECT_EQ(adapter->GetType(),
            AssetResolver::AssetResolverType::kApkAssetProvider);

  auto mapping = adapter->GetAsMapping("manifest.json");
  ASSERT_NE(mapping, nullptr);
  EXPECT_EQ(mapping->GetSize(), test_data.size());
  EXPECT_EQ(std::string(reinterpret_cast<const char*>(mapping->GetMapping()),
                        mapping->GetSize()),
            test_data);

  EXPECT_EQ(adapter->GetAsMapping("nonexistent.txt"), nullptr);
}

TEST(APKAssetProvider, ThreadSafeConcurrentMutationsAndReads) {
  auto in_memory_impl =
      std::make_shared<InMemoryAPKAssetProviderImpl>("flutter_assets");
  for (int i = 0; i < 20; ++i) {
    in_memory_impl->AddAsset("initial_" + std::to_string(i),
                             "InitialData_" + std::to_string(i));
  }

  auto provider = std::make_shared<APKAssetProvider>(in_memory_impl);

  constexpr size_t kReaderCount = 6;
  constexpr size_t kIterations = 150;
  std::atomic<bool> stop_writers{false};

  auto writer_future =
      std::async(std::launch::async, [&in_memory_impl, &stop_writers]() {
        int counter = 0;
        while (!stop_writers.load()) {
          std::string name = "dynamic_" + std::to_string(counter % 10);
          in_memory_impl->AddAsset(name,
                                   "DynamicContent_" + std::to_string(counter));
          if (counter % 3 == 0) {
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
        int idx = static_cast<int>((t + iter) % 20);
        std::string name = "initial_" + std::to_string(idx);
        auto mapping = provider->GetAsMapping(name);
        if (!mapping || mapping->GetSize() == 0) {
          return false;
        }
        auto mappings = provider->GetAsMappings("Initial", std::nullopt);
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

TEST(APKAssetProvider, APKAssetMappingDirectBufferAndStreaming) {
  std::vector<uint8_t> payload = {'F', 'L', 'U', 'T', 'T', 'E', 'R'};
  auto mapping = std::make_unique<APKAssetMapping>(payload);

  EXPECT_EQ(mapping->GetSize(), 7u);
  EXPECT_TRUE(mapping->IsDontNeedSafe());
  ASSERT_NE(mapping->GetMapping(), nullptr);
  EXPECT_EQ(std::vector<uint8_t>(mapping->GetMapping(),
                                 mapping->GetMapping() + mapping->GetSize()),
            payload);

  // Multiple concurrent calls to GetMapping on same mapping
  constexpr size_t kThreadCount = 4;
  std::vector<std::future<bool>> futures;
  for (size_t i = 0; i < kThreadCount; ++i) {
    futures.push_back(std::async(std::launch::async, [&mapping]() {
      for (int iter = 0; iter < 100; ++iter) {
        const uint8_t* ptr = mapping->GetMapping();
        if (!ptr || mapping->GetSize() != 7u) {
          return false;
        }
      }
      return true;
    }));
  }
  for (auto& f : futures) {
    EXPECT_TRUE(f.get());
  }
}

TEST(APKAssetProvider, ThreadSafeConcurrentResolution) {
  auto in_memory_impl =
      std::make_shared<InMemoryAPKAssetProviderImpl>("flutter_assets");
  for (int i = 0; i < 20; ++i) {
    std::string name = "asset_" + std::to_string(i) + ".dat";
    std::string content = "Content of asset " + std::to_string(i);
    in_memory_impl->AddAsset(name, content);
  }

  auto provider = std::make_shared<APKAssetProvider>(in_memory_impl);

  constexpr size_t kThreadCount = 6;
  constexpr size_t kIterations = 200;
  std::vector<std::future<bool>> futures;
  futures.reserve(kThreadCount);

  for (size_t t = 0; t < kThreadCount; ++t) {
    futures.push_back(std::async(std::launch::async, [provider, t]() {
      for (size_t iter = 0; iter < kIterations; ++iter) {
        int idx = static_cast<int>((t + iter) % 20);
        std::string name = "asset_" + std::to_string(idx) + ".dat";
        auto mapping = provider->GetAsMapping(name);
        if (!mapping || mapping->GetSize() == 0) {
          return false;
        }
      }
      return true;
    }));
  }

  for (auto& f : futures) {
    EXPECT_TRUE(f.get());
  }
}

}  // namespace testing
}  // namespace flutter
