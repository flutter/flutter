// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/apk_asset_provider.h"
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

TEST(APKAssetProvider, ToFlutterAssetResolverDelegatesAndReleases) {
  auto mock_impl = std::make_shared<MockAPKAssetProviderImpl>();
  const std::string expected_content = "asset_payload";
  EXPECT_CALL(*mock_impl, GetAsMapping(::testing::StrEq("found.txt")))
      .WillOnce([&expected_content](const std::string&) {
        return std::make_unique<fml::DataMapping>(expected_content);
      });
  EXPECT_CALL(*mock_impl, GetAsMapping(::testing::StrEq("missing.txt")))
      .WillOnce(::testing::Return(::testing::ByMove(nullptr)));

  auto provider = std::make_unique<APKAssetProvider>(mock_impl);
  FlutterAssetResolver resolver = provider->ToFlutterAssetResolver();

  EXPECT_EQ(resolver.struct_size, sizeof(FlutterAssetResolver));
  ASSERT_NE(resolver.find_asset_callback, nullptr);
  ASSERT_NE(resolver.is_valid_callback, nullptr);
  ASSERT_NE(resolver.is_valid_after_change_callback, nullptr);
  ASSERT_NE(resolver.destruction_callback, nullptr);

  EXPECT_TRUE(resolver.is_valid_callback(resolver.user_data));
  EXPECT_TRUE(resolver.is_valid_after_change_callback(resolver.user_data));

  FlutterAsset asset = {};
  ASSERT_TRUE(
      resolver.find_asset_callback(resolver.user_data, "found.txt", &asset));
  EXPECT_EQ(asset.struct_size, sizeof(FlutterAsset));
  EXPECT_EQ(asset.size, expected_content.size());
  EXPECT_EQ(std::string(reinterpret_cast<const char*>(asset.data), asset.size),
            expected_content);
  ASSERT_NE(asset.asset_free_callback, nullptr);
  asset.asset_free_callback(asset.user_data);

  FlutterAsset missing = {};
  EXPECT_FALSE(resolver.find_asset_callback(resolver.user_data, "missing.txt",
                                            &missing));

  resolver.destruction_callback(resolver.user_data);
}
}  // namespace testing
}  // namespace flutter
