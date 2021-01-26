// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>

#import "FlutterEngine.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * Represents a collection of FlutterEngines who share resources which allows
 * them to be created with less time const and occupy less memory than just
 * creating multiple FlutterEngines.
 *
 * Deleting a FlutterEngineGroup doesn't invalidate existing FlutterEngines, but
 * it eliminates the possibility to create more FlutterEngines in that group.
 *
 * @warning This class is a work-in-progress and may change.
 * @see https://github.com/flutter/flutter/issues/72009
 */
FLUTTER_DARWIN_EXPORT
@interface FlutterEngineGroup : NSObject
- (instancetype)init NS_UNAVAILABLE;

/**
 * Initialize a new FlutterEngineGroup.
 *
 * @param name The name that will present in the threads shared across the
 * engines in this group.
 * @param project The `FlutterDartProject` that all FlutterEngines in this group
 * will be executing.
 */
- (instancetype)initWithName:(NSString*)name
                     project:(nullable FlutterDartProject*)project NS_DESIGNATED_INITIALIZER;

/**
 * Creates a running `FlutterEngine` that shares components with this group.
 *
 * @see FlutterEngineGroup
 */
- (FlutterEngine*)makeEngineWithEntrypoint:(nullable NSString*)entrypoint
                                libraryURI:(nullable NSString*)libraryURI;
@end

NS_ASSUME_NONNULL_END
