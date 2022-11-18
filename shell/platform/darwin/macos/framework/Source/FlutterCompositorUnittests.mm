// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>
#import <OCMock/OCMock.h>

#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterCompositor.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterView.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterViewProvider.h"
#import "flutter/testing/testing.h"

@interface FlutterViewMockProviderMetal : NSObject <FlutterViewProvider> {
  FlutterView* _defaultView;
}
/**
 * Create a FlutterViewMockProviderMetal with the provided view as the default view.
 */
- (nonnull instancetype)initWithDefaultView:(nonnull FlutterView*)view;
@end

@implementation FlutterViewMockProviderMetal

- (nonnull instancetype)initWithDefaultView:(nonnull FlutterView*)view {
  self = [super init];
  if (self != nil) {
    _defaultView = view;
  }
  return self;
}

- (nullable FlutterView*)getView:(uint64_t)viewId {
  if (viewId == kFlutterDefaultViewId) {
    return _defaultView;
  }
  return nil;
}

@end

namespace flutter::testing {
namespace {

id<FlutterViewProvider> MockViewProvider() {
  FlutterView* viewMock = OCMClassMock([FlutterView class]);
  FlutterRenderBackingStore* backingStoreMock = OCMClassMock([FlutterRenderBackingStore class]);
  __block id<MTLTexture> textureMock = OCMProtocolMock(@protocol(MTLTexture));
  OCMStub([backingStoreMock texture]).andReturn(textureMock);

  OCMStub([viewMock backingStoreForSize:CGSize{}])
      .ignoringNonObjectArgs()
      .andDo(^(NSInvocation* invocation) {
        CGSize size;
        [invocation getArgument:&size atIndex:2];
        OCMStub([textureMock width]).andReturn(size.width);
        OCMStub([textureMock height]).andReturn(size.height);
      })
      .andReturn(backingStoreMock);

  return [[FlutterViewMockProviderMetal alloc] initWithDefaultView:viewMock];
}
}  // namespace

TEST(FlutterCompositorTest, TestPresent) {
  std::unique_ptr<flutter::FlutterCompositor> macos_compositor =
      std::make_unique<FlutterCompositor>(MockViewProvider(), /*platform_view_controller*/ nullptr,
                                          /*mtl_device*/ nullptr);

  bool flag = false;
  macos_compositor->SetPresentCallback([f = &flag](bool has_flutter_content) {
    *f = true;
    return true;
  });

  ASSERT_TRUE(macos_compositor->Present(0, nil, 0));
  ASSERT_TRUE(flag);
}

TEST(FlutterCompositorTest, TestCreate) {
  std::unique_ptr<flutter::FlutterCompositor> macos_compositor =
      std::make_unique<FlutterCompositor>(MockViewProvider(), /*platform_view_controller*/ nullptr,
                                          /*mtl_device*/ nullptr);

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

TEST(FlutterCompositorTest, TestCompositing) {
  std::unique_ptr<flutter::FlutterCompositor> macos_compositor =
      std::make_unique<FlutterCompositor>(MockViewProvider(), /*platform_view_controller*/ nullptr,
                                          /*mtl_device*/ nullptr);

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
