// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterMetalCompositor.h"

#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterIOSurfaceHolder.h"

#include "flutter/fml/logging.h"

namespace flutter {

FlutterMetalCompositor::FlutterMetalCompositor(FlutterViewController* view_controller,
                                               id<MTLDevice> mtl_device)
    : FlutterCompositor(view_controller), mtl_device_(mtl_device) {}

bool FlutterMetalCompositor::CreateBackingStore(const FlutterBackingStoreConfig* config,
                                                FlutterBackingStore* backing_store_out) {
  if (!view_controller_) {
    return false;
  }

  CGSize size = CGSizeMake(config->size.width, config->size.height);

  backing_store_out->metal.struct_size = sizeof(FlutterMetalBackingStore);
  backing_store_out->metal.texture.struct_size = sizeof(FlutterMetalTexture);

  if (GetFrameStatus() != FrameStatus::kStarted) {
    StartFrame();
    // If the backing store is for the first layer, return the MTLTexture for the
    // FlutterView.
    FlutterMetalRenderBackingStore* backingStore =
        reinterpret_cast<FlutterMetalRenderBackingStore*>(
            [view_controller_.flutterView backingStoreForSize:size]);
    backing_store_out->metal.texture.texture =
        (__bridge FlutterMetalTextureHandle)backingStore.texture;
  } else {
    FlutterIOSurfaceHolder* io_surface_holder = [[FlutterIOSurfaceHolder alloc] init];
    [io_surface_holder recreateIOSurfaceWithSize:size];
    auto texture_descriptor =
        [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatBGRA8Unorm
                                                           width:size.width
                                                          height:size.height
                                                       mipmapped:NO];
    texture_descriptor.usage =
        MTLTextureUsageShaderRead | MTLTextureUsageRenderTarget | MTLTextureUsageShaderWrite;

    backing_store_out->metal.texture.texture = (__bridge_retained FlutterMetalTextureHandle)
        [mtl_device_ newTextureWithDescriptor:texture_descriptor
                                    iosurface:[io_surface_holder ioSurface]
                                        plane:0];

    backing_store_out->metal.texture.user_data = (__bridge_retained void*)io_surface_holder;
  }

  backing_store_out->type = kFlutterBackingStoreTypeMetal;
  backing_store_out->metal.texture.destruction_callback = [](void* user_data) {
    if (user_data != nullptr) {
      CFRelease(user_data);
    }
  };

  return true;
}

bool FlutterMetalCompositor::CollectBackingStore(const FlutterBackingStore* backing_store) {
  // If we allocated this MTLTexture ourselves, user_data is not null, and we will need
  // to release it manually.
  if (backing_store->metal.texture.user_data != nullptr &&
      backing_store->metal.texture.texture != nullptr) {
    CFRelease(backing_store->metal.texture.texture);
  }
  return true;
}

bool FlutterMetalCompositor::Present(const FlutterLayer** layers, size_t layers_count) {
  SetFrameStatus(FrameStatus::kPresenting);

  for (size_t i = 0; i < layers_count; ++i) {
    const auto* layer = layers[i];
    FlutterBackingStore* backing_store = const_cast<FlutterBackingStore*>(layer->backing_store);

    switch (layer->type) {
      case kFlutterLayerContentTypeBackingStore: {
        if (backing_store->metal.texture.user_data) {
          FlutterIOSurfaceHolder* io_surface_holder =
              (__bridge FlutterIOSurfaceHolder*)backing_store->metal.texture.user_data;
          IOSurfaceRef io_surface = [io_surface_holder ioSurface];
          InsertCALayerForIOSurface(io_surface);
        }
        break;
      }
      case kFlutterLayerContentTypePlatformView:
        // Add functionality in follow up PR.
        FML_LOG(WARNING) << "Presenting PlatformViews not yet supported";
        break;
    };
  }

  return EndFrame();
}

}  // namespace flutter
