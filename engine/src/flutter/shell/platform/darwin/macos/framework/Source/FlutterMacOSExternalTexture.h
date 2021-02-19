// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>

#import "flutter/shell/platform/darwin/common/framework/Headers/FlutterTexture.h"
#import "flutter/shell/platform/embedder/embedder.h"

/*
 * Embedding side texture wrappers for GL and Metal external textures.
 */
@protocol FlutterMacOSExternalTexture

/**
 * Returns the ID for the FlutterTexture instance.
 */
- (int64_t)textureID;

@end
