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
    : open_gl_context_(opengl_context) {
  FML_CHECK(view_controller != nullptr) << "FlutterViewController* cannot be nullptr";
  view_controller_ = view_controller;
}

bool FlutterGLCompositor::CreateBackingStore(const FlutterBackingStoreConfig* config,
                                             FlutterBackingStore* backing_store_out) {
  CGSize size = CGSizeMake(config->size.width, config->size.height);

  if (!frame_started_) {
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

    size_t layer_id = CreateCALayer();

    [io_surface_holder bindSurfaceToTexture:texture fbo:fbo size:size];
    FlutterBackingStoreData* data =
        [[FlutterBackingStoreData alloc] initWithLayerId:layer_id
                                              fbProvider:fb_provider
                                         ioSurfaceHolder:io_surface_holder];

    backing_store_out->open_gl.framebuffer.name = fbo;
    backing_store_out->open_gl.framebuffer.user_data = (__bridge_retained void*)data;
  }

  backing_store_out->type = kFlutterBackingStoreTypeOpenGL;
  backing_store_out->open_gl.type = kFlutterOpenGLTargetTypeFramebuffer;
  backing_store_out->open_gl.framebuffer.target = GL_RGBA8;
  backing_store_out->open_gl.framebuffer.destruction_callback = [](void* user_data) {
    if (user_data != nullptr) {
      CFRelease(user_data);
    }
  };

  return true;
}

bool FlutterGLCompositor::CollectBackingStore(const FlutterBackingStore* backing_store) {
  return true;
}

bool FlutterGLCompositor::Present(const FlutterLayer** layers, size_t layers_count) {
  for (size_t i = 0; i < layers_count; ++i) {
    const auto* layer = layers[i];
    FlutterBackingStore* backing_store = const_cast<FlutterBackingStore*>(layer->backing_store);
    switch (layer->type) {
      case kFlutterLayerContentTypeBackingStore: {
        if (backing_store->open_gl.framebuffer.user_data) {
          FlutterBackingStoreData* backing_store_data =
              (__bridge FlutterBackingStoreData*)backing_store->open_gl.framebuffer.user_data;

          FlutterIOSurfaceHolder* io_surface_holder = [backing_store_data ioSurfaceHolder];
          size_t layer_id = [backing_store_data layerId];

          CALayer* content_layer = ca_layer_map_[layer_id];

          FML_CHECK(content_layer) << "Unable to find a content layer with layer id " << layer_id;

          content_layer.frame = content_layer.superlayer.bounds;

          // The surface is an OpenGL texture, which means it has origin in bottom left corner
          // and needs to be flipped vertically
          content_layer.transform = CATransform3DMakeScale(1, -1, 1);
          IOSurfaceRef io_surface_contents = [io_surface_holder ioSurface];
          [content_layer setContents:(__bridge id)io_surface_contents];
        }
        break;
      }
      case kFlutterLayerContentTypePlatformView:
        // Add functionality in follow up PR.
        FML_LOG(WARNING) << "Presenting PlatformViews not yet supported";
        break;
    };
  }
  // The frame has been presented, prepare FlutterGLCompositor to
  // render a new frame.
  frame_started_ = false;
  return present_callback_();
}

void FlutterGLCompositor::SetPresentCallback(
    const FlutterGLCompositor::PresentCallback& present_callback) {
  present_callback_ = present_callback;
}

void FlutterGLCompositor::StartFrame() {
  // First reset all the state.
  ca_layer_count_ = 0;

  // First remove all CALayers from the superlayer.
  for (auto const& ca_layer_kvp : ca_layer_map_) {
    [ca_layer_kvp.second removeFromSuperlayer];
  }

  // Reset layer map.
  ca_layer_map_.clear();

  frame_started_ = true;
}

size_t FlutterGLCompositor::CreateCALayer() {
  // FlutterGLCompositor manages the lifecycle of content layers.
  // The id for a CALayer starts at 0 and increments by 1 for
  // any given frame.
  CALayer* content_layer = [[CALayer alloc] init];
  [view_controller_.flutterView.layer addSublayer:content_layer];
  ca_layer_map_[ca_layer_count_] = content_layer;
  return ca_layer_count_++;
}

}  // namespace flutter
