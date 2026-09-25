// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/apk_asset_provider.h"
#include "flutter/shell/platform/embedder/embedder_asset_resolver.h"
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
}

TEST(APKAssetProvider, ToFlutterAssetResolverWithMock) {
  auto mock_impl = std::make_shared<MockAPKAssetProviderImpl>();
  const std::string test_data = "Hello Flutter Assets";

  EXPECT_CALL(*mock_impl, GetAsMapping("test.txt"))
      .WillOnce(::testing::Return(std::make_unique<fml::DataMapping>(
          std::vector<uint8_t>(test_data.begin(), test_data.end()))));

  EXPECT_CALL(*mock_impl, GetAsMapping("missing.txt"))
      .WillOnce(::testing::Return(nullptr));

  auto provider = std::make_unique<APKAssetProvider>(mock_impl);
  FlutterAssetResolver resolver = provider->ToFlutterAssetResolver();

  EXPECT_EQ(resolver.struct_size, sizeof(FlutterAssetResolver));
  ASSERT_NE(resolver.find_asset_callback, nullptr);
  ASSERT_NE(resolver.is_valid_callback, nullptr);
  ASSERT_NE(resolver.is_valid_after_change_callback, nullptr);
  ASSERT_NE(resolver.destruction_callback, nullptr);

  EXPECT_TRUE(resolver.is_valid_callback(resolver.user_data));
  EXPECT_TRUE(resolver.is_valid_after_change_callback(resolver.user_data));

  // Null arguments test.
  EXPECT_FALSE(resolver.find_asset_callback(nullptr, "test.txt", nullptr));
  EXPECT_FALSE(
      resolver.find_asset_callback(resolver.user_data, nullptr, nullptr));

  // Find existing asset.
  FlutterAsset asset = {};
  EXPECT_TRUE(
      resolver.find_asset_callback(resolver.user_data, "test.txt", &asset));
  EXPECT_EQ(asset.struct_size, sizeof(FlutterAsset));
  EXPECT_EQ(asset.size, test_data.size());
  ASSERT_NE(asset.data, nullptr);
  EXPECT_EQ(std::string(reinterpret_cast<const char*>(asset.data), asset.size),
            test_data);
  ASSERT_NE(asset.asset_free_callback, nullptr);
  asset.asset_free_callback(asset.user_data);

  // Missing asset.
  FlutterAsset missing_asset = {};
  EXPECT_FALSE(resolver.find_asset_callback(resolver.user_data, "missing.txt",
                                            &missing_asset));

  // Resolver destruction.
  resolver.destruction_callback(resolver.user_data);
}

TEST(APKAssetProvider, EmbedderAssetResolverIntegration) {
  auto mock_impl = std::make_shared<MockAPKAssetProviderImpl>();
  const std::string test_data = "Integration Asset Content";

  EXPECT_CALL(*mock_impl, GetAsMapping("kernel_blob.bin"))
      .WillOnce(::testing::Return(std::make_unique<fml::DataMapping>(
          std::vector<uint8_t>(test_data.begin(), test_data.end()))));

  auto provider = std::make_unique<APKAssetProvider>(mock_impl);
  FlutterAssetResolver resolver = provider->ToFlutterAssetResolver();

  {
    EmbedderAssetResolver embedder_resolver(resolver);
    EXPECT_TRUE(embedder_resolver.IsValid());
    EXPECT_TRUE(embedder_resolver.IsValidAfterAssetManagerChange());

    auto mapping = embedder_resolver.GetAsMapping("kernel_blob.bin");
    ASSERT_NE(mapping, nullptr);
    EXPECT_EQ(mapping->GetSize(), test_data.size());
    EXPECT_EQ(std::string(reinterpret_cast<const char*>(mapping->GetMapping()),
                          mapping->GetSize()),
              test_data);
  }
}

TEST(APKAssetProvider, CreateFlutterAssetResolverNullAssetManager) {
  FlutterAssetResolver resolver =
      APKAssetProvider::CreateFlutterAssetResolver(nullptr, "");
  EXPECT_FALSE(resolver.is_valid_callback(resolver.user_data));

  FlutterAsset asset = {};
  EXPECT_FALSE(
      resolver.find_asset_callback(resolver.user_data, "any.txt", &asset));

  resolver.destruction_callback(resolver.user_data);
}

}  // namespace testing
}  // namespace flutter
