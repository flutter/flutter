// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SHELL_PLATFORM_IOS_FRAMEWORK_SOURCE_FLUTTERDARTPROJECT_INTERNAL_H_
#define SHELL_PLATFORM_IOS_FRAMEWORK_SOURCE_FLUTTERDARTPROJECT_INTERNAL_H_

#include "flutter/common/settings.h"
#include "flutter/runtime/window_data.h"
#include "flutter/shell/common/engine.h"
#include "flutter/shell/platform/darwin/ios/framework/Headers/FlutterDartProject.h"

NS_ASSUME_NONNULL_BEGIN

@interface FlutterDartProject ()

- (const flutter::Settings&)settings;
- (const flutter::WindowData)defaultWindowData;

- (flutter::RunConfiguration)runConfiguration;
- (flutter::RunConfiguration)runConfigurationForEntrypoint:(nullable NSString*)entrypointOrNil;
- (flutter::RunConfiguration)runConfigurationForEntrypoint:(nullable NSString*)entrypointOrNil
                                              libraryOrNil:(nullable NSString*)dartLibraryOrNil;

+ (NSString*)flutterAssetsName:(NSBundle*)bundle;

/**
 * The embedder can specify data that the isolate can request synchronously on launch. Engines
 * launched using this configuration can access the persistent isolate data via the
 * `Window.getPersistentIsolateData` accessor.
 *
 * @param data The persistent isolate data. This data is persistent for the duration of the Flutter
 *             application and is available even after isolate restarts. Because of this lifecycle,
 *             the size of this data must be kept to a minimum and platform channels used for
 *             communication that does not require synchronous embedder to isolate communication
 *             close to isolate launch.
 **/
- (void)setPersistentIsolateData:(NSData*)data;

@end

NS_ASSUME_NONNULL_END

#endif  // SHELL_PLATFORM_IOS_FRAMEWORK_SOURCE_FLUTTERDARTPROJECT_INTERNAL_H_
