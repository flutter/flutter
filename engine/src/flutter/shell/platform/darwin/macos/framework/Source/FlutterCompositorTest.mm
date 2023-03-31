// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#import <OCMock/OCMock.h>

#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterCompositor.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterView.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterViewProvider.h"
#import "flutter/testing/testing.h"

extern const int64_t kFlutterDefaultViewId;

@interface FlutterViewMockProvider : NSObject <FlutterViewProvider> {
  FlutterView* _defaultView;
}
/**
 * Create a FlutterViewMockProvider with the provided view as the default view.
 */
- (nonnull instancetype)initWithDefaultView:(nonnull FlutterView*)view;
@end

@implementation FlutterViewMockProvider

- (nonnull instancetype)initWithDefaultView:(nonnull FlutterView*)view {
  self = [super init];
  if (self != nil) {
    _defaultView = view;
  }
  return self;
}

- (nullable FlutterView*)viewForId:(int64_t)viewId {
  if (viewId == kFlutterDefaultViewId) {
    return _defaultView;
  }
  return nil;
}

@end

namespace flutter::testing {
namespace {

typedef void (^PresentBlock)(NSArray<FlutterSurfacePresentInfo*>*);

id<FlutterViewProvider> MockViewProvider(PresentBlock onPresent = nil) {
  FlutterView* viewMock = OCMClassMock([FlutterView class]);
  FlutterSurfaceManager* surfaceManagerMock = OCMClassMock([FlutterSurfaceManager class]);
  FlutterSurface* surfaceMock = OCMClassMock([FlutterSurface class]);
  __block id<MTLTexture> textureMock = OCMProtocolMock(@protocol(MTLTexture));

  OCMStub([viewMock surfaceManager]).andReturn(surfaceManagerMock);

  OCMStub([surfaceManagerMock surfaceForSize:CGSize{}])
      .ignoringNonObjectArgs()
      .andDo(^(NSInvocation* invocation) {
        CGSize size;
        [invocation getArgument:&size atIndex:2];
        OCMStub([textureMock width]).andReturn(size.width);
        OCMStub([textureMock height]).andReturn(size.height);
      })
      .andReturn(surfaceMock);

  FlutterMetalTexture texture = {
      .struct_size = sizeof(FlutterMetalTexture),
      .texture_id = 1,
      .texture = (__bridge void*)textureMock,
      .user_data = (__bridge void*)surfaceMock,
      .destruction_callback = nullptr,
  };

  OCMStub([surfaceManagerMock present:[OCMArg any] notify:[OCMArg any]])
      .andDo(^(NSInvocation* invocation) {
        NSArray<FlutterSurfacePresentInfo*>* info;
        [invocation getArgument:&info atIndex:2];
        if (onPresent != nil) {
          onPresent(info);
        }
      });

  OCMStub([surfaceMock asFlutterMetalTexture]).andReturn(texture);

  return [[FlutterViewMockProvider alloc] initWithDefaultView:viewMock];
}
}  // namespace

TEST(FlutterCompositorTest, TestCreate) {
  std::unique_ptr<flutter::FlutterCompositor> macos_compositor =
      std::make_unique<FlutterCompositor>(MockViewProvider(),
                                          /*platform_view_controller*/ nullptr);

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

TEST(FlutterCompositorTest, TestPresent) {
  __block NSArray<FlutterSurfacePresentInfo*>* presentedSurfaces = nil;

  auto onPresent = ^(NSArray<FlutterSurfacePresentInfo*>* info) {
    presentedSurfaces = info;
  };

  std::unique_ptr<flutter::FlutterCompositor> macos_compositor =
      std::make_unique<FlutterCompositor>(MockViewProvider(onPresent),
                                          /*platform_view_controller*/ nullptr);

  FlutterBackingStore backing_store;
  FlutterBackingStoreConfig config;
  config.struct_size = sizeof(FlutterBackingStoreConfig);
  config.size.width = 800;
  config.size.height = 600;
  macos_compositor->CreateBackingStore(&config, &backing_store);

  FlutterLayer layers[] = {{
      .struct_size = sizeof(FlutterLayer),
      .type = kFlutterLayerContentTypeBackingStore,
      .backing_store = &backing_store,
      .offset = {0, 0},
      .size = {800, 600},
  }};
  const FlutterLayer* layers_ptr = layers;

  macos_compositor->Present(kFlutterDefaultViewId, &layers_ptr, 1);

  ASSERT_EQ(presentedSurfaces.count, 1ul);
}

}  // namespace flutter::testing
