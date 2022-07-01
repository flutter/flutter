// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/macos/framework/Headers/FlutterPluginMacOS.h"
#import "flutter/shell/platform/darwin/macos/framework/Headers/FlutterPluginRegistrarMacOS.h"
#import "flutter/shell/platform/darwin/macos/framework/Headers/FlutterViewController.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterDartProject_Internal.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterEngine_Internal.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterMenuPlugin.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterMenuPlugin_Internal.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterTextInputSemanticsObject.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterViewController_Internal.h"

#include "flutter/shell/platform/common/platform_provided_menu.h"
#include "gtest/gtest.h"

#import <OCMock/OCMock.h>
#import "flutter/testing/testing.h"

@interface FlutterMenuPluginTestObjc : NSObject
- (bool)testSetMenu;
@end

@implementation FlutterMenuPluginTestObjc

- (bool)testSetMenu {
  // Build a simulation of the default main menu.
  NSMenu* mainMenu = [[NSMenu alloc] init];
  NSMenuItem* appNameMenu = [[NSMenuItem alloc] initWithTitle:@"APP_NAME"
                                                       action:nil
                                                keyEquivalent:@""];
  NSMenu* submenu = [[NSMenu alloc] initWithTitle:@"Prexisting APP_NAME menu"];
  [submenu addItem:[[NSMenuItem alloc] initWithTitle:@"About APP_NAME"
                                              action:nil
                                       keyEquivalent:@""]];
  appNameMenu.submenu = submenu;
  [mainMenu addItem:appNameMenu];
  [NSApp setMainMenu:mainMenu];

  id<FlutterPluginRegistrar> pluginRegistrarMock =
      OCMProtocolMock(@protocol(FlutterPluginRegistrar));
  __block FlutterMethodChannel* pluginChannel;
  __block FlutterMenuPlugin* plugin;
  id binaryMessengerMock = OCMProtocolMock(@protocol(FlutterBinaryMessenger));
  OCMStub([pluginRegistrarMock messenger]).andReturn(binaryMessengerMock);
  OCMStub(  // NOLINT(google-objc-avoid-throwing-exception)
      [pluginRegistrarMock addMethodCallDelegate:[OCMArg any] channel:[OCMArg any]])
      .andDo(^(NSInvocation* invocation) {
        id<FlutterPlugin> delegate;
        FlutterMethodChannel* channel;
        [invocation getArgument:&delegate atIndex:2];
        [invocation getArgument:&channel atIndex:3];
        pluginChannel = channel;
        plugin = delegate;
        [channel setMethodCallHandler:^(FlutterMethodCall* call, FlutterResult result) {
          [delegate handleMethodCall:call result:result];
        }];
      });
  [FlutterMenuPlugin registerWithRegistrar:pluginRegistrarMock];

  NSDictionary* testMenus = @{
    @"0" : @[
      @{
        @"id" : [NSNumber numberWithInt:1],
        @"label" : @"APP_NAME",
        @"enabled" : @(YES),
        @"children" : @[
          @{
            @"id" : [NSNumber numberWithInt:3],
            @"platformProvidedMenu" : @(static_cast<int>(flutter::PlatformProvidedMenu::kQuit)),
            @"enabled" : @(YES),
          },
          @{
            @"id" : [NSNumber numberWithInt:2],
            @"label" : @"APP_NAME Info",
            @"enabled" : @(YES),
            @"shortcutTrigger" : [NSNumber numberWithUnsignedLongLong:0x61],
            @"shortcutModifiers" : [NSNumber numberWithUnsignedInt:0],
          },
        ],
      },
      @{
        @"id" : [NSNumber numberWithInt:4],
        @"label" : @"Help for APP_NAME",
        @"enabled" : @(YES),
        @"children" : @[
          @{
            @"id" : [NSNumber numberWithInt:5],
            @"label" : @"Help me!",
            @"enabled" : @(YES),
          },
          @{
            @"id" : [NSNumber numberWithInt:6],
            @"label" : @"",
            @"enabled" : @(NO),
            @"isDivider" : @(YES),
          },
          @{
            @"id" : [NSNumber numberWithInt:7],
            @"label" : @"Search help",
            @"enabled" : @(NO),
          },
        ],
      },
    ],
  };

  __block id available = @NO;
  [plugin handleMethodCall:[FlutterMethodCall methodCallWithMethodName:@"Menu.isPluginAvailable"
                                                             arguments:nil]
                    result:^(id _Nullable result) {
                      available = result;
                    }];

  EXPECT_TRUE(available);

  [plugin handleMethodCall:[FlutterMethodCall methodCallWithMethodName:@"Menu.setMenus"
                                                             arguments:testMenus]
                    result:^(id _Nullable result){
                    }];

  EXPECT_EQ([NSApp.mainMenu numberOfItems], 2);
  NSMenuItem* firstMenu = [NSApp.mainMenu itemAtIndex:0];
  EXPECT_TRUE([[firstMenu title] isEqualToString:@"flutter_desktop_darwin_unittests"]);
  EXPECT_EQ([firstMenu tag], 1);
  EXPECT_TRUE([firstMenu isEnabled]);
  EXPECT_FALSE([firstMenu isHidden]);
  EXPECT_TRUE([[firstMenu keyEquivalent] isEqualToString:@"\0"]);

  EXPECT_EQ([[firstMenu submenu] numberOfItems], 1);
  NSMenuItem* firstItem = [[firstMenu submenu] itemAtIndex:0];
  EXPECT_TRUE([[firstItem title] isEqualToString:@"flutter_desktop_darwin_unittests Info"]);
  EXPECT_TRUE([[firstItem keyEquivalent] isEqualToString:@"a"]);
  EXPECT_TRUE([firstItem isEnabled]);
  EXPECT_FALSE([firstItem isHidden]);
  EXPECT_TRUE(
      [NSStringFromSelector([firstItem action]) isEqualToString:@"flutterMenuItemSelected:"]);
  EXPECT_EQ([firstItem tag], 2);

  NSMenuItem* secondMenu = [NSApp.mainMenu itemAtIndex:1];
  EXPECT_TRUE([[secondMenu title] isEqualToString:@"Help for flutter_desktop_darwin_unittests"]);
  EXPECT_EQ([secondMenu tag], 4);
  EXPECT_TRUE([secondMenu isEnabled]);
  EXPECT_FALSE([secondMenu isHidden]);

  EXPECT_EQ([[secondMenu submenu] numberOfItems], 3);
  NSMenuItem* secondMenuFirst = [[secondMenu submenu] itemAtIndex:0];
  EXPECT_TRUE([[secondMenuFirst title] isEqualToString:@"Help me!"]);
  EXPECT_TRUE([secondMenuFirst isEnabled]);
  EXPECT_FALSE([secondMenuFirst isHidden]);
  EXPECT_TRUE(
      [NSStringFromSelector([secondMenuFirst action]) isEqualToString:@"flutterMenuItemSelected:"]);
  EXPECT_EQ([secondMenuFirst tag], 5);

  NSMenuItem* secondMenuDivider = [[secondMenu submenu] itemAtIndex:1];
  EXPECT_TRUE([[secondMenuDivider title] isEqualToString:@""]);
  EXPECT_TRUE([[secondMenuDivider keyEquivalent] isEqualToString:@""]);
  EXPECT_FALSE([secondMenuDivider isEnabled]);
  EXPECT_FALSE([secondMenuDivider isHidden]);
  EXPECT_EQ([secondMenuDivider action], nil);
  EXPECT_EQ([secondMenuDivider tag], 0);

  NSMenuItem* secondMenuLast = [[secondMenu submenu] itemAtIndex:2];
  EXPECT_TRUE([[secondMenuLast title] isEqualToString:@"Search help"]);
  EXPECT_FALSE([secondMenuLast isEnabled]);
  EXPECT_FALSE([secondMenuLast isHidden]);
  EXPECT_TRUE(
      [NSStringFromSelector([secondMenuLast action]) isEqualToString:@"flutterMenuItemSelected:"]);
  EXPECT_EQ([secondMenuLast tag], 7);

  return true;
}

@end

namespace flutter::testing {
// TODO(gspencergoog): Re-enabled when deflaked
// https://github.com/flutter/flutter/issues/106589
TEST(FlutterMenuPluginTest, DISABLED_TestSetMenu) {
  ASSERT_TRUE([[FlutterMenuPluginTestObjc alloc] testSetMenu]);
}
}  // namespace flutter::testing
