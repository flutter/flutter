// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "FWFInstanceManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface FWFInstanceManager ()
/**
 * The number of instances stored as a strong reference.
 *
 * Added for debugging purposes.
 */
- (NSUInteger)strongInstanceCount;

/**
 * The number of instances stored as a weak reference.
 *
 * Added for debugging purposes. NSMapTables that store keys or objects as weak reference will be
 * reclaimed nondeterministically.
 */
- (NSUInteger)weakInstanceCount;
@end

NS_ASSUME_NONNULL_END
