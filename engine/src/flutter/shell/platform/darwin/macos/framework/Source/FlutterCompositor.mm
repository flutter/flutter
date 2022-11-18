// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterCompositor.h"

#include "flutter/fml/logging.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterIOSurfaceHolder.h"

namespace flutter {

FlutterCompositor::FlutterCompositor(id<FlutterViewProvider> view_provider,
                                     FlutterPlatformViewController* platform_view_controller,
                                     id<MTLDevice> mtl_device)
    : view_provider_(view_provider),
      platform_view_controller_(platform_view_controller),
      mtl_device_(mtl_device) {
  FML_CHECK(view_provider != nullptr) << "view_provider cannot be nullptr";
}

bool FlutterCompositor::CreateBackingStore(const FlutterBackingStoreConfig* config,
                                           FlutterBackingStore* backing_store_out) {
  // TODO(dkwingsmt): This class only supports single-view for now. As more
  // classes are gradually converted to multi-view, it should get the view ID
  // from somewhere.
  FlutterView* view = GetView(kFlutterDefaultViewId);
  if (!view) {
    return false;
  }

  CGSize size = CGSizeMake(config->size.width, config->size.height);

  backing_store_out->metal.struct_size = sizeof(FlutterMetalBackingStore);
  backing_store_out->metal.texture.struct_size = sizeof(FlutterMetalTexture);

  if (GetFrameStatus() != FrameStatus::kStarted) {
    StartFrame();
    // If the backing store is for the first layer, return the MTLTexture for the
    // FlutterView.
    FlutterRenderBackingStore* backingStore = [view backingStoreForSize:size];
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

bool FlutterCompositor::CollectBackingStore(const FlutterBackingStore* backing_store) {
  // If we allocated this MTLTexture ourselves, user_data is not null, and we will need
  // to release it manually.
  if (backing_store->metal.texture.user_data != nullptr &&
      backing_store->metal.texture.texture != nullptr) {
    CFRelease(backing_store->metal.texture.texture);
  }
  return true;
}

bool FlutterCompositor::Present(uint64_t view_id,
                                const FlutterLayer** layers,
                                size_t layers_count) {
  FlutterView* view = GetView(view_id);
  if (!view) {
    return false;
  }

  SetFrameStatus(FrameStatus::kPresenting);

  bool has_flutter_content = false;
  for (size_t i = 0; i < layers_count; ++i) {
    const auto* layer = layers[i];
    FlutterBackingStore* backing_store = const_cast<FlutterBackingStore*>(layer->backing_store);

    switch (layer->type) {
      case kFlutterLayerContentTypeBackingStore: {
        if (backing_store->metal.texture.user_data) {
          FlutterIOSurfaceHolder* io_surface_holder =
              (__bridge FlutterIOSurfaceHolder*)backing_store->metal.texture.user_data;
          IOSurfaceRef io_surface = [io_surface_holder ioSurface];
          InsertCALayerForIOSurface(view, io_surface);
        }
        has_flutter_content = true;
        break;
      }
      case kFlutterLayerContentTypePlatformView: {
        PresentPlatformView(view, layer, i);
        break;
      }
    };
  }

  return EndFrame(has_flutter_content);
}

void FlutterCompositor::PresentPlatformView(FlutterView* default_base_view,
                                            const FlutterLayer* layer,
                                            size_t layer_position) {
  // TODO (https://github.com/flutter/flutter/issues/96668)
  // once the issue is fixed, this check will pass.
  FML_DCHECK([[NSThread currentThread] isMainThread])
      << "Must be on the main thread to present platform views";

  int64_t platform_view_id = layer->platform_view->identifier;
  NSView* platform_view = [platform_view_controller_ platformViewWithID:platform_view_id];

  FML_DCHECK(platform_view) << "Platform view not found for id: " << platform_view_id;

  CGFloat scale = [[NSScreen mainScreen] backingScaleFactor];
  platform_view.frame = CGRectMake(layer->offset.x / scale, layer->offset.y / scale,
                                   layer->size.width / scale, layer->size.height / scale);
  if (platform_view.superview == nil) {
    [default_base_view addSubview:platform_view];
  }
  platform_view.layer.zPosition = layer_position;
}

void FlutterCompositor::SetPresentCallback(
    const FlutterCompositor::PresentCallback& present_callback) {
  present_callback_ = present_callback;
}

void FlutterCompositor::StartFrame() {
  // First remove all CALayers from the superlayer.
  for (auto layer : active_ca_layers_) {
    [layer removeFromSuperlayer];
  }

  // Reset active layers.
  active_ca_layers_.clear();
  SetFrameStatus(FrameStatus::kStarted);
}

bool FlutterCompositor::EndFrame(bool has_flutter_content) {
  bool status = present_callback_(has_flutter_content);
  SetFrameStatus(FrameStatus::kEnded);
  return status;
}

FlutterView* FlutterCompositor::GetView(uint64_t view_id) {
  return [view_provider_ getView:view_id];
}

void FlutterCompositor::SetFrameStatus(FlutterCompositor::FrameStatus frame_status) {
  frame_status_ = frame_status;
}

FlutterCompositor::FrameStatus FlutterCompositor::GetFrameStatus() {
  return frame_status_;
}

void FlutterCompositor::InsertCALayerForIOSurface(FlutterView* view,
                                                  const IOSurfaceRef& io_surface,
                                                  CATransform3D transform) {
  // FlutterCompositor manages the lifecycle of CALayers.
  CALayer* content_layer = [[CALayer alloc] init];
  content_layer.transform = transform;
  content_layer.frame = view.layer.bounds;
  [content_layer setContents:(__bridge id)io_surface];
  [view.layer addSublayer:content_layer];

  active_ca_layers_.push_back(content_layer);
}

}  // namespace flutter
