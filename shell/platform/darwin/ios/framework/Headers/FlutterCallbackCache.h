// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FLUTTERCALLBACKCACHE_H_
#define FLUTTER_FLUTTERCALLBACKCACHE_H_

#import <Foundation/Foundation.h>

#include "FlutterMacros.h"

/**
 * An object containing the result of `FlutterCallbackCache`'s `lookupCallbackInformation`
 * method.
 */
FLUTTER_EXPORT
@interface FlutterCallbackInformation : NSObject
/**
 * The name of the callback.
 */
@property(retain) NSString* callbackName;
/**
 * The class name of the callback.
 */
@property(retain) NSString* callbackClassName;
/**
 * The library path of the callback.
 */
@property(retain) NSString* callbackLibraryPath;
@end

/**
 * The cache containing callback information for spawning a
 * `FlutterHeadlessDartRunner`.
 */
FLUTTER_EXPORT
@interface FlutterCallbackCache : NSObject
/**
 * Returns the callback information for the given callback handle.
 * This callback information can be used when spawning a
 * `FlutterHeadlessDartRunner`.
 *
 * @param handle The handle for a callback, provided by the
 *   Dart method `PluginUtilities.getCallbackHandle`.
 * @return A `FlutterCallbackInformation` object which contains the name of the
 *   callback, the name of the class in which the callback is defined, and the
 *   path of the library which contains the callback. If the provided handle is
 *   invalid, nil is returned.
 */
+ (FlutterCallbackInformation*)lookupCallbackInformation:(int64_t)handle;

@end

#endif  // FLUTTER_FLUTTERCALLBACKCACHE_H_
