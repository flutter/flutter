// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FLUTTERTEXTURE_H_
#define FLUTTER_FLUTTERTEXTURE_H_

#import <CoreMedia/CoreMedia.h>
#import <Foundation/Foundation.h>

#include "FlutterMacros.h"

NS_ASSUME_NONNULL_BEGIN

FLUTTER_EXPORT
@protocol FlutterTexture<NSObject>
- (CVPixelBufferRef _Nullable)copyPixelBuffer;
@end

FLUTTER_EXPORT
@protocol FlutterTextureRegistry<NSObject>
- (int64_t)registerTexture:(NSObject<FlutterTexture>*)texture;
- (void)textureFrameAvailable:(int64_t)textureId;
- (void)unregisterTexture:(int64_t)textureId;
@end

NS_ASSUME_NONNULL_END

#endif  // FLUTTER_FLUTTERTEXTURE_H_
