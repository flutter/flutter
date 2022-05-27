// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>

#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterMetalCompositor.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterViewControllerTestUtils.h"
#import "flutter/testing/testing.h"

namespace flutter::testing {

TEST(FlutterMetalCompositorTest, TestPresent) {
  id mockViewController = CreateMockViewController();

  std::unique_ptr<flutter::FlutterMetalCompositor> macos_compositor =
      std::make_unique<FlutterMetalCompositor>(
          mockViewController, /*platform_view_controller*/ nullptr, /*mtl_device*/ nullptr);

  bool flag = false;
  macos_compositor->SetPresentCallback([f = &flag](bool has_flutter_content) {
    *f = true;
    return true;
  });

  ASSERT_TRUE(macos_compositor->Present(nil, 0));
  ASSERT_TRUE(flag);
}

TEST(FlutterMetalCompositorTest, TestCreate) {
  id mockViewController = CreateMockViewController();
  [mockViewController loadView];

  std::unique_ptr<flutter::FlutterMetalCompositor> macos_compositor =
      std::make_unique<FlutterMetalCompositor>(
          mockViewController, /*platform_view_controller*/ nullptr, /*mtl_device*/ nullptr);

  FlutterBackingStore backing_store;
  FlutterBackingStoreConfig config;
  config.struct_size = sizeof(FlutterBackingStoreConfig);
  config.size.width = 800;
  config.size.height = 600;
  macos_compositor->CreateBackingStore(&config, &backing_store);

  ASSERT_EQ(backing_store.type, kFlutterBackingStoreTypeMetal);
  ASSERT_NE(backing_store.metal.texture.texture, nil);
  id<MTLTexture> texture = (__bridge id<MTLTexture>)backing_store.metal.texture.texture;
  ASSERT_EQ(texture.width, 800ul);
  ASSERT_EQ(texture.height, 600ul);
}

TEST(FlutterMetalCompositorTest, TestCompositing) {
  id mockViewController = CreateMockViewController();
  [mockViewController loadView];

  std::unique_ptr<flutter::FlutterMetalCompositor> macos_compositor =
      std::make_unique<FlutterMetalCompositor>(
          mockViewController, /*platform_view_controller*/ nullptr, /*mtl_device*/ nullptr);

  FlutterBackingStore backing_store;
  FlutterBackingStoreConfig config;
  config.struct_size = sizeof(FlutterBackingStoreConfig);
  config.size.width = 800;
  config.size.height = 600;
  macos_compositor->CreateBackingStore(&config, &backing_store);

  ASSERT_EQ(backing_store.type, kFlutterBackingStoreTypeMetal);
  ASSERT_NE(backing_store.metal.texture.texture, nil);
  id<MTLTexture> texture = (__bridge id<MTLTexture>)backing_store.metal.texture.texture;
  ASSERT_EQ(texture.width, 800u);
  ASSERT_EQ(texture.height, 600u);
}

}  // namespace flutter::testing
