// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/macos/framework/Headers/FlutterViewController.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterDartProject_Internal.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterEngine_Internal.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterTextInputPlugin.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterTextInputSemanticsObject.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterViewController_Internal.h"

#import <OCMock/OCMock.h>
#import "flutter/testing/testing.h"

namespace flutter::testing {

namespace {
// Returns an engine configured for the text fixture resource configuration.
FlutterEngine* CreateTestEngine() {
  NSString* fixtures = @(testing::GetFixturesPath());
  FlutterDartProject* project = [[FlutterDartProject alloc]
      initWithAssetsPath:fixtures
             ICUDataPath:[fixtures stringByAppendingString:@"/icudtl.dat"]];
  return [[FlutterEngine alloc] initWithName:@"test" project:project allowHeadlessExecution:true];
}
}  // namespace

TEST(FlutterTextInputSemanticsObjectTest, DoesInitialize) {
  FlutterEngine* engine = CreateTestEngine();
  NSString* fixtures = @(testing::GetFixturesPath());
  FlutterDartProject* project = [[FlutterDartProject alloc]
      initWithAssetsPath:fixtures
             ICUDataPath:[fixtures stringByAppendingString:@"/icudtl.dat"]];
  FlutterViewController* viewController = [[FlutterViewController alloc] initWithProject:project];
  [viewController loadView];
  [engine setViewController:viewController];
  // Create a NSWindow so that the native text field can become first responder.
  NSWindow* window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 800, 600)
                                                 styleMask:NSBorderlessWindowMask
                                                   backing:NSBackingStoreBuffered
                                                     defer:NO];
  window.contentView = viewController.view;

  engine.semanticsEnabled = YES;

  auto bridge = engine.accessibilityBridge.lock();
  FlutterPlatformNodeDelegateMac delegate(engine, viewController);
  ui::AXTree tree;
  ui::AXNode ax_node(&tree, nullptr, 0, 0);
  ui::AXNodeData node_data;
  node_data.SetValue("initial text");
  ax_node.SetData(node_data);
  delegate.Init(engine.accessibilityBridge, &ax_node);
  // Verify that a FlutterTextField is attached to the view.
  FlutterTextPlatformNode text_platform_node(&delegate, viewController);
  id native_accessibility = text_platform_node.GetNativeViewAccessible();
  EXPECT_TRUE([native_accessibility isKindOfClass:[FlutterTextField class]]);
  auto subviews = [viewController.view subviews];
  EXPECT_EQ([subviews count], 2u);
  EXPECT_TRUE([subviews[0] isKindOfClass:[FlutterTextField class]]);
  FlutterTextField* nativeTextField = subviews[0];
  EXPECT_EQ(text_platform_node.GetNativeViewAccessible(), nativeTextField);
}

}  // namespace flutter::testing
