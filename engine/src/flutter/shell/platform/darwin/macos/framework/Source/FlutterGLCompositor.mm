// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterGLCompositor.h"

#import <OpenGL/gl.h>

#include "flutter/fml/logging.h"
#include "flutter/fml/platform/darwin/cf_utils.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterBackingStore.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterBackingStoreData.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterFrameBufferProvider.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterIOSurfaceHolder.h"
#include "third_party/skia/include/core/SkCanvas.h"
#include "third_party/skia/include/core/SkSurface.h"
#include "third_party/skia/include/gpu/gl/GrGLAssembleInterface.h"
#include "third_party/skia/include/utils/mac/SkCGUtils.h"

namespace flutter {

FlutterGLCompositor::FlutterGLCompositor(FlutterViewController* view_controller,
                                         NSOpenGLContext* opengl_context)
    : FlutterCompositor(view_controller), open_gl_context_(opengl_context) {}

bool FlutterGLCompositor::CreateBackingStore(const FlutterBackingStoreConfig* config,
                                             FlutterBackingStore* backing_store_out) {
  if (!view_controller_) {
    return false;
  }

  CGSize size = CGSizeMake(config->size.width, config->size.height);

  if (GetFrameStatus() != FrameStatus::kStarted) {
    StartFrame();
    // If the backing store is for the first layer, return the fbo for the
    // FlutterView.
    FlutterOpenGLRenderBackingStore* backingStore =
        reinterpret_cast<FlutterOpenGLRenderBackingStore*>(
            [view_controller_.flutterView backingStoreForSize:size]);
    backing_store_out->open_gl.framebuffer.name = backingStore.frameBufferID;
  } else {
    FlutterFrameBufferProvider* fb_provider =
        [[FlutterFrameBufferProvider alloc] initWithOpenGLContext:open_gl_context_];
    FlutterIOSurfaceHolder* io_surface_holder = [FlutterIOSurfaceHolder alloc];

    GLuint fbo = [fb_provider glFrameBufferId];
    GLuint texture = [fb_provider glTextureId];

    [io_surface_holder bindSurfaceToTexture:texture fbo:fbo size:size];

    FlutterBackingStoreData* data =
        [[FlutterBackingStoreData alloc] initWithFbProvider:fb_provider
                                            ioSurfaceHolder:io_surface_holder];

    backing_store_out->open_gl.framebuffer.name = fbo;
    backing_store_out->open_gl.framebuffer.user_data = (__bridge_retained void*)data;
  }

  backing_store_out->type = kFlutterBackingStoreTypeOpenGL;
  backing_store_out->open_gl.type = kFlutterOpenGLTargetTypeFramebuffer;
  backing_store_out->open_gl.framebuffer.target = GL_RGBA8;
  backing_store_out->open_gl.framebuffer.destruction_callback = [](void* user_data) {
    if (user_data != nullptr) {
      // This deletes the OpenGL framebuffer object and texture backing it.
      CFRelease(user_data);
    }
  };

  return true;
}

bool FlutterGLCompositor::CollectBackingStore(const FlutterBackingStore* backing_store) {
  return true;
}

bool FlutterGLCompositor::Present(const FlutterLayer** layers, size_t layers_count) {
  SetFrameStatus(FrameStatus::kPresenting);

  bool has_flutter_content = false;

  for (size_t i = 0; i < layers_count; ++i) {
    const auto* layer = layers[i];
    FlutterBackingStore* backing_store = const_cast<FlutterBackingStore*>(layer->backing_store);
    switch (layer->type) {
      case kFlutterLayerContentTypeBackingStore: {
        if (backing_store->open_gl.framebuffer.user_data) {
          FlutterBackingStoreData* backing_store_data =
              (__bridge FlutterBackingStoreData*)backing_store->open_gl.framebuffer.user_data;

          FlutterIOSurfaceHolder* io_surface_holder = [backing_store_data ioSurfaceHolder];
          IOSurfaceRef io_surface = [io_surface_holder ioSurface];

          // The surface is an OpenGL texture, which means it has origin in bottom left corner
          // and needs to be flipped vertically
          InsertCALayerForIOSurface(io_surface, CATransform3DMakeScale(1, -1, 1));
        }
        has_flutter_content = true;
        break;
      }
      case kFlutterLayerContentTypePlatformView:
        // Add functionality in follow up PR.
        FML_LOG(WARNING) << "Presenting PlatformViews not yet supported";
        break;
    };
  }

  return EndFrame(has_flutter_content);
}

}  // namespace flutter
