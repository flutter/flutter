// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SHELL_PLATFORM_IOS_FRAMEWORK_SOURCE_FLUTTERUNDOMANAGERDELEGATE_H_
#define SHELL_PLATFORM_IOS_FRAMEWORK_SOURCE_FLUTTERUNDOMANAGERDELEGATE_H_

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, FlutterUndoRedoDirection) {
  FlutterUndoRedoDirectionUndo,
  FlutterUndoRedoDirectionRedo,
};

@class FlutterUndoManagerPlugin;

@protocol FlutterUndoManagerDelegate <NSObject>
- (void)flutterUndoManagerPlugin:(FlutterUndoManagerPlugin*)undoManagerPlugin
         handleUndoWithDirection:(FlutterUndoRedoDirection)direction;
@end
NS_ASSUME_NONNULL_END

#endif  // SHELL_PLATFORM_IOS_FRAMEWORK_SOURCE_FLUTTERUNDOMANAGERDELEGATE_H_
