// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Cocoa/Cocoa.h>

/**
 * FlutterIOSurfaceHolder maintains an IOSurface
 * and provides an interface to bind the IOSurface to a texture.
 */
@interface FlutterIOSurfaceHolder : NSObject

/**
 * Bind the IOSurface to the provided texture and fbo.
 */
- (void)bindSurfaceToTexture:(GLuint)texture fbo:(GLuint)fbo size:(CGSize)size;

/**
 * Releases the current IOSurface if one exists
 * and creates a new IOSurface with the specified size.
 */
- (void)recreateIOSurfaceWithSize:(CGSize)size;

/**
 * Returns a reference to the underlying IOSurface.
 */
- (const IOSurfaceRef&)ioSurface;

@end
