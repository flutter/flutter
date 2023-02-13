// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <OCMock/OCMock.h>

#import "flutter/shell/platform/darwin/macos/framework/Headers/FlutterEngine.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterDartProject_Internal.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterEngine_Internal.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterRenderer.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterView.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterViewControllerTestUtils.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterViewController_Internal.h"
#include "flutter/shell/platform/embedder/embedder.h"
#include "flutter/shell/platform/embedder/test_utils/proc_table_replacement.h"
#include "flutter/testing/testing.h"

@interface RendererTestViewController : FlutterViewController
- (void)loadMockFlutterView:(FlutterView*)mockView;
@end

@implementation RendererTestViewController {
  FlutterView* _mockFlutterView;
}

- (void)loadMockFlutterView:(FlutterView*)mockView {
  _mockFlutterView = mockView;
  [self loadView];
}

- (nonnull FlutterView*)createFlutterViewWithMTLDevice:(id<MTLDevice>)device
                                          commandQueue:(id<MTLCommandQueue>)commandQueue {
  return _mockFlutterView;
}
@end

namespace flutter::testing {

namespace {
// Returns an engine configured for the test fixture resource configuration.
RendererTestViewController* CreateTestViewController() {
  NSString* fixtures = @(testing::GetFixturesPath());
  FlutterDartProject* project = [[FlutterDartProject alloc]
      initWithAssetsPath:fixtures
             ICUDataPath:[fixtures stringByAppendingString:@"/icudtl.dat"]];
  RendererTestViewController* viewController =
      [[RendererTestViewController alloc] initWithProject:project];
  return viewController;
}

}  // namespace

TEST(FlutterRenderer, PresentDelegatesToFlutterView) {
  RendererTestViewController* viewController = CreateTestViewController();
  FlutterEngine* engine = viewController.engine;

  id viewMock = OCMClassMock([FlutterView class]);
  [viewController loadMockFlutterView:viewMock];
  FlutterRenderer* renderer = [[FlutterRenderer alloc] initWithFlutterEngine:engine];

  id surfaceManagerMock = OCMClassMock([FlutterSurfaceManager class]);
  OCMStub([viewMock surfaceManager]).andReturn(surfaceManagerMock);

  id surfaceMock = OCMClassMock([FlutterSurface class]);

  FlutterMetalTexture texture = {
      .user_data = (__bridge void*)surfaceMock,
  };

  [[surfaceManagerMock expect] present:[OCMArg checkWithBlock:^(id obj) {
                                 NSArray* array = (NSArray*)obj;
                                 return array.count == 1 ? YES : NO;
                               }]
                                notify:nil];

  [renderer present:kFlutterDefaultViewId texture:&texture];
  [surfaceManagerMock verify];
}

TEST(FlutterRenderer, TextureReturnedByFlutterView) {
  RendererTestViewController* viewController = CreateTestViewController();
  FlutterEngine* engine = viewController.engine;

  id viewMock = OCMClassMock([FlutterView class]);
  [viewController loadMockFlutterView:viewMock];
  FlutterRenderer* renderer = [[FlutterRenderer alloc] initWithFlutterEngine:engine];

  id surfaceManagerMock = OCMClassMock([FlutterSurfaceManager class]);
  OCMStub([viewMock surfaceManager]).andReturn(surfaceManagerMock);

  FlutterFrameInfo frameInfo;
  frameInfo.struct_size = sizeof(FlutterFrameInfo);
  FlutterUIntSize dimensions;
  dimensions.width = 100;
  dimensions.height = 200;
  frameInfo.size = dimensions;
  CGSize size = CGSizeMake(dimensions.width, dimensions.height);

  [[surfaceManagerMock expect] surfaceForSize:size];
  [renderer createTextureForView:kFlutterDefaultViewId size:size];
  [surfaceManagerMock verify];
}

}  // namespace flutter::testing
