// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterOpenGLRenderer.h"

#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterEngine_Internal.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterExternalTextureGL.h"

#pragma mark - Static methods for openGL callbacks that require the engine.

static bool OnMakeCurrent(FlutterEngine* engine) {
  FlutterOpenGLRenderer* openGLRenderer = reinterpret_cast<FlutterOpenGLRenderer*>(engine.renderer);
  return [openGLRenderer makeCurrent];
}

static bool OnClearCurrent(FlutterEngine* engine) {
  FlutterOpenGLRenderer* openGLRenderer = reinterpret_cast<FlutterOpenGLRenderer*>(engine.renderer);
  return [openGLRenderer clearCurrent];
}

static bool OnPresent(FlutterEngine* engine) {
  FlutterOpenGLRenderer* openGLRenderer = reinterpret_cast<FlutterOpenGLRenderer*>(engine.renderer);
  return [openGLRenderer glPresent];
}

static uint32_t OnFBO(FlutterEngine* engine, const FlutterFrameInfo* info) {
  FlutterOpenGLRenderer* openGLRenderer = reinterpret_cast<FlutterOpenGLRenderer*>(engine.renderer);
  return [openGLRenderer fboForFrameInfo:info];
}

static bool OnMakeResourceCurrent(FlutterEngine* engine) {
  FlutterOpenGLRenderer* openGLRenderer = reinterpret_cast<FlutterOpenGLRenderer*>(engine.renderer);
  return [openGLRenderer makeResourceCurrent];
}

static bool OnAcquireExternalTexture(FlutterEngine* engine,
                                     int64_t textureIdentifier,
                                     size_t width,
                                     size_t height,
                                     FlutterOpenGLTexture* openGlTexture) {
  FlutterOpenGLRenderer* openGLRenderer = reinterpret_cast<FlutterOpenGLRenderer*>(engine.renderer);
  return [openGLRenderer populateTextureWithIdentifier:textureIdentifier
                                         openGLTexture:openGlTexture];
}

#pragma mark - FlutterOpenGLRenderer implementation.

@implementation FlutterOpenGLRenderer {
  FlutterView* _flutterView;

  // The context provided to the Flutter engine for rendering to the FlutterView. This is lazily
  // created during initialization of the FlutterView. This is used to render content into the
  // FlutterView.
  NSOpenGLContext* _openGLContext;

  // The context provided to the Flutter engine for resource loading.
  NSOpenGLContext* _resourceContext;

  __weak FlutterEngine* _flutterEngine;
}

- (instancetype)initWithFlutterEngine:(FlutterEngine*)flutterEngine {
  self = [super initWithDelegate:self engine:flutterEngine];
  if (self) {
    _flutterEngine = flutterEngine;
  }
  return self;
}

- (void)setFlutterView:(FlutterView*)view {
  _flutterView = view;
  if (!view) {
    _resourceContext = nil;
  }
}

- (BOOL)makeCurrent {
  if (!_openGLContext) {
    return false;
  }
  [_openGLContext makeCurrentContext];
  return true;
}

- (BOOL)clearCurrent {
  [NSOpenGLContext clearCurrentContext];
  return true;
}

- (BOOL)glPresent {
  if (!_openGLContext) {
    return false;
  }
  [_flutterView present];
  return true;
}

- (uint32_t)fboForFrameInfo:(const FlutterFrameInfo*)info {
  CGSize size = CGSizeMake(info->size.width, info->size.height);
  FlutterOpenGLRenderBackingStore* backingStore =
      reinterpret_cast<FlutterOpenGLRenderBackingStore*>([_flutterView backingStoreForSize:size]);
  return backingStore.frameBufferID;
}

- (NSOpenGLContext*)resourceContext {
  if (!_resourceContext) {
    NSOpenGLPixelFormatAttribute attributes[] = {
        NSOpenGLPFAColorSize, 24, NSOpenGLPFAAlphaSize, 8, 0,
    };
    NSOpenGLPixelFormat* pixelFormat = [[NSOpenGLPixelFormat alloc] initWithAttributes:attributes];
    _resourceContext = [[NSOpenGLContext alloc] initWithFormat:pixelFormat shareContext:nil];
  }
  return _resourceContext;
}

- (NSOpenGLContext*)openGLContext {
  if (!_openGLContext) {
    NSOpenGLContext* shareContext = [self resourceContext];
    _openGLContext = [[NSOpenGLContext alloc] initWithFormat:shareContext.pixelFormat
                                                shareContext:shareContext];
  }
  return _openGLContext;
}

- (BOOL)makeResourceCurrent {
  [self.resourceContext makeCurrentContext];
  return YES;
}

#pragma mark - FlutterTextureRegistrar

- (BOOL)populateTextureWithIdentifier:(int64_t)textureID
                        openGLTexture:(FlutterOpenGLTexture*)openGLTexture {
  id<FlutterMacOSExternalTexture> texture = [self getTextureWithID:textureID];
  FlutterExternalTextureGL* glTexture = reinterpret_cast<FlutterExternalTextureGL*>(texture);
  return [glTexture populateTexture:openGLTexture];
}

- (id<FlutterMacOSExternalTexture>)onRegisterTexture:(id<FlutterTexture>)texture {
  return [[FlutterExternalTextureGL alloc] initWithFlutterTexture:texture];
}

- (FlutterRendererConfig)createRendererConfig {
  const FlutterRendererConfig rendererConfig = {
      .type = kOpenGL,
      .open_gl.struct_size = sizeof(FlutterOpenGLRendererConfig),
      .open_gl.make_current = reinterpret_cast<BoolCallback>(OnMakeCurrent),
      .open_gl.clear_current = reinterpret_cast<BoolCallback>(OnClearCurrent),
      .open_gl.present = reinterpret_cast<BoolCallback>(OnPresent),
      .open_gl.fbo_with_frame_info_callback = reinterpret_cast<UIntFrameInfoCallback>(OnFBO),
      .open_gl.fbo_reset_after_present = true,
      .open_gl.make_resource_current = reinterpret_cast<BoolCallback>(OnMakeResourceCurrent),
      .open_gl.gl_external_texture_frame_callback =
          reinterpret_cast<TextureFrameCallback>(OnAcquireExternalTexture),
  };
  return rendererConfig;
}

@end
