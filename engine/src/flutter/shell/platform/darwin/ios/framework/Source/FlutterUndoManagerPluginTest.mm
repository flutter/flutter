// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterUndoManagerPlugin.h"

#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "flutter/shell/platform/darwin/common/framework/Headers/FlutterMacros.h"
#import "flutter/shell/platform/darwin/ios/framework/Headers/FlutterEngine.h"
#import "flutter/shell/platform/darwin/ios/framework/Headers/FlutterViewController.h"

FLUTTER_ASSERT_ARC

@interface FlutterEngine ()
- (nonnull FlutterUndoManagerPlugin*)undoManagerPlugin;
@end

@interface FlutterUndoManagerPluginForTest : FlutterUndoManagerPlugin
@property(nonatomic, assign) NSUndoManager* undoManager;
@end

@implementation FlutterUndoManagerPluginForTest {
}
@end

@interface FlutterUndoManagerPluginTest : XCTestCase
@property(nonatomic, strong) id engine;
@property(nonatomic, strong) FlutterUndoManagerPluginForTest* undoManagerPlugin;
@property(nonatomic, strong) FlutterViewController* viewController;
@property(nonatomic, strong) NSUndoManager* undoManager;
@end

@implementation FlutterUndoManagerPluginTest {
}

- (void)setUp {
  [super setUp];
  self.engine = OCMClassMock([FlutterEngine class]);

  self.undoManagerPlugin = [[FlutterUndoManagerPluginForTest alloc] initWithDelegate:self.engine];

  self.viewController = [FlutterViewController new];
  self.undoManagerPlugin.viewController = self.viewController;

  self.undoManager = OCMClassMock([NSUndoManager class]);
  self.undoManagerPlugin.undoManager = self.undoManager;
}

- (void)tearDown {
  [self.undoManager removeAllActionsWithTarget:self.undoManagerPlugin];
  self.undoManagerPlugin = nil;
  self.engine = nil;
  self.viewController = nil;
  self.undoManager = nil;
  [super tearDown];
}

- (void)testSetUndoState {
  __block int registerUndoCount = 0;
  __block void (^undoHandler)(id target);
  OCMStub([self.undoManager registerUndoWithTarget:self.undoManagerPlugin handler:[OCMArg any]])
      .andDo(^(NSInvocation* invocation) {
        registerUndoCount++;
        __weak void (^handler)(id target);
        [invocation retainArguments];
        [invocation getArgument:&handler atIndex:3];
        undoHandler = handler;
      });
  __block int removeAllActionsCount = 0;
  OCMStub([self.undoManager removeAllActionsWithTarget:self.undoManagerPlugin])
      .andDo(^(NSInvocation* invocation) {
        removeAllActionsCount++;
      });
  __block int delegateUndoCount = 0;
  OCMStub([self.engine flutterUndoManagerPlugin:[OCMArg any]
                        handleUndoWithDirection:FlutterUndoRedoDirectionUndo])
      .andDo(^(NSInvocation* invocation) {
        delegateUndoCount++;
      });
  __block int delegateRedoCount = 0;
  OCMStub([self.engine flutterUndoManagerPlugin:[OCMArg any]
                        handleUndoWithDirection:FlutterUndoRedoDirectionRedo])
      .andDo(^(NSInvocation* invocation) {
        delegateRedoCount++;
      });
  __block int undoCount = 0;
  OCMStub([self.undoManager undo]).andDo(^(NSInvocation* invocation) {
    undoCount++;
    undoHandler(self.undoManagerPlugin);
  });

  // If canUndo and canRedo are false, only removeAllActionsWithTarget is called.
  FlutterMethodCall* setUndoStateCall =
      [FlutterMethodCall methodCallWithMethodName:@"UndoManager.setUndoState"
                                        arguments:@{@"canUndo" : @NO, @"canRedo" : @NO}];
  [self.undoManagerPlugin handleMethodCall:setUndoStateCall
                                    result:^(id _Nullable result){
                                    }];
  XCTAssertEqual(1, removeAllActionsCount);
  XCTAssertEqual(0, registerUndoCount);

  // If canUndo is true, an undo will be registered.
  setUndoStateCall =
      [FlutterMethodCall methodCallWithMethodName:@"UndoManager.setUndoState"
                                        arguments:@{@"canUndo" : @YES, @"canRedo" : @NO}];
  [self.undoManagerPlugin handleMethodCall:setUndoStateCall
                                    result:^(id _Nullable result){
                                    }];
  XCTAssertEqual(2, removeAllActionsCount);
  XCTAssertEqual(1, registerUndoCount);

  // Invoking the undo handler will invoke the handleUndo delegate method with "undo".
  undoHandler(self.undoManagerPlugin);
  XCTAssertEqual(1, delegateUndoCount);
  XCTAssertEqual(0, delegateRedoCount);
  XCTAssertEqual(2, registerUndoCount);

  // Invoking the redo handler will invoke the handleUndo delegate method with "redo".
  undoHandler(self.undoManagerPlugin);
  XCTAssertEqual(1, delegateUndoCount);
  XCTAssertEqual(1, delegateRedoCount);
  XCTAssertEqual(3, registerUndoCount);

  // If canRedo is true, an undo will be registered and undo will be called.
  setUndoStateCall =
      [FlutterMethodCall methodCallWithMethodName:@"UndoManager.setUndoState"
                                        arguments:@{@"canUndo" : @NO, @"canRedo" : @YES}];
  [self.undoManagerPlugin handleMethodCall:setUndoStateCall
                                    result:^(id _Nullable result){
                                    }];
  XCTAssertEqual(3, removeAllActionsCount);
  XCTAssertEqual(5, registerUndoCount);
  XCTAssertEqual(1, undoCount);

  // Invoking the redo handler will invoke the handleUndo delegate method with "redo".
  undoHandler(self.undoManagerPlugin);
  XCTAssertEqual(1, delegateUndoCount);
  XCTAssertEqual(2, delegateRedoCount);
}

@end
