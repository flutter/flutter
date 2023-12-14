// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERUNDOMANAGERDELEGATE_H_
#define FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERUNDOMANAGERDELEGATE_H_

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, FlutterUndoRedoDirection) {
  // NOLINTBEGIN(readability-identifier-naming)
  FlutterUndoRedoDirectionUndo,
  FlutterUndoRedoDirectionRedo,
  // NOLINTEND(readability-identifier-naming)
};

@class FlutterUndoManagerPlugin;

@protocol FlutterUndoManagerDelegate <NSObject>
- (void)flutterUndoManagerPlugin:(FlutterUndoManagerPlugin*)undoManagerPlugin
         handleUndoWithDirection:(FlutterUndoRedoDirection)direction;
@end
NS_ASSUME_NONNULL_END

#endif  // FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERUNDOMANAGERDELEGATE_H_
