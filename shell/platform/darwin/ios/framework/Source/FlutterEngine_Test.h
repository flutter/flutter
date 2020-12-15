// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/ios/framework/Headers/FlutterEngine.h"
#import "flutter/shell/platform/darwin/ios/rendering_api_selection.h"

extern NSString* const FlutterEngineWillDealloc;

@class FlutterBinaryMessengerRelay;

namespace flutter {
class ThreadHost;
}

// Category to add test-only visibility.
@interface FlutterEngine (Test) <FlutterBinaryMessenger>
- (void)setBinaryMessenger:(FlutterBinaryMessengerRelay*)binaryMessenger;
- (flutter::IOSRenderingAPI)platformViewsRenderingAPI;
- (void)waitForFirstFrame:(NSTimeInterval)timeout callback:(void (^)(BOOL didTimeout))callback;
- (FlutterEngine*)spawnWithEntrypoint:(/*nullable*/ NSString*)entrypoint
                           libraryURI:(/*nullable*/ NSString*)libraryURI;
- (const flutter::ThreadHost&)threadHost;
@end
