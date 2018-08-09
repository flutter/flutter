// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FLUTTERHEADLESSDARTRUNNER_H_
#define FLUTTER_FLUTTERHEADLESSDARTRUNNER_H_

#import <Foundation/Foundation.h>

#include "FlutterBinaryMessenger.h"
#include "FlutterDartProject.h"
#include "FlutterMacros.h"

/**
A callback for when FlutterHeadlessDartRunner has attempted to start a Dart
Isolate in the background.

- Parameter success: YES if the Isolate was started and run successfully, NO
  otherwise.
*/
typedef void (^FlutterHeadlessDartRunnerCallback)(BOOL success);

/**
 The FlutterHeadlessDartRunner runs Flutter Dart code with a null rasterizer,
 and no native drawing surface. It is appropriate for use in running Dart
 code e.g. in the background from a plugin.
*/
FLUTTER_EXPORT
@interface FlutterHeadlessDartRunner : NSObject <FlutterBinaryMessenger>

/**
 Runs a Dart function on an Isolate that is not the main application's Isolate.
 The first call will create a new Isolate. Subsequent calls will return
 immediately.

 - Parameter entrypoint: The name of a top-level function from the same Dart
   library that contains the app's main() function.
*/
- (void)runWithEntrypoint:(NSString*)entrypoint;

/**
 Runs a Dart function on an Isolate that is not the main application's Isolate.
 The first call will create a new Isolate. Subsequent calls will return
 immediately.

 - Parameter entrypoint: The name of a top-level function from a Dart library.
 - Parameter uri: The URI of the Dart library which contains entrypoint.
*/
- (void)runWithEntrypointAndLibraryUri:(NSString*)entrypoint libraryUri:(NSString*)uri;

@end

#endif  // FLUTTER_FLUTTERHEADLESSDARTRUNNER_H_
