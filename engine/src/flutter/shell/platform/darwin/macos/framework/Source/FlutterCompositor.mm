// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterCompositor.h"

#include "flutter/fml/logging.h"

namespace flutter {

FlutterCompositor::FlutterCompositor(id<FlutterViewProvider> view_provider,
                                     FlutterPlatformViewController* platform_view_controller)
    : view_provider_(view_provider), platform_view_controller_(platform_view_controller) {
  FML_CHECK(view_provider != nullptr) << "view_provider cannot be nullptr";
}

bool FlutterCompositor::CreateBackingStore(const FlutterBackingStoreConfig* config,
                                           FlutterBackingStore* backing_store_out) {
  // TODO(dkwingsmt): This class only supports single-view for now. As more
  // classes are gradually converted to multi-view, it should get the view ID
  // from somewhere.
  FlutterView* view = [view_provider_ viewForId:kFlutterDefaultViewId];
  if (!view) {
    return false;
  }

  CGSize size = CGSizeMake(config->size.width, config->size.height);
  FlutterSurface* surface = [view.surfaceManager surfaceForSize:size];
  memset(backing_store_out, 0, sizeof(FlutterBackingStore));
  backing_store_out->struct_size = sizeof(FlutterBackingStore);
  backing_store_out->type = kFlutterBackingStoreTypeMetal;
  backing_store_out->metal.struct_size = sizeof(FlutterMetalBackingStore);
  backing_store_out->metal.texture = surface.asFlutterMetalTexture;
  return true;
}

bool FlutterCompositor::Present(uint64_t view_id,
                                const FlutterLayer** layers,
                                size_t layers_count) {
  FlutterView* view = [view_provider_ viewForId:view_id];
  if (!view) {
    return false;
  }

  NSMutableArray* surfaces = [NSMutableArray array];
  for (size_t i = 0; i < layers_count; i++) {
    const FlutterLayer* layer = layers[i];
    if (layer->type == kFlutterLayerContentTypeBackingStore) {
      FlutterSurface* surface =
          [FlutterSurface fromFlutterMetalTexture:&layer->backing_store->metal.texture];

      if (surface) {
        FlutterSurfacePresentInfo* info = [[FlutterSurfacePresentInfo alloc] init];
        info.surface = surface;
        info.offset = CGPointMake(layer->offset.x, layer->offset.y);
        info.zIndex = i;
        [surfaces addObject:info];
      }
    }
  }

  [view.surfaceManager present:surfaces
                        notify:^{
                          for (size_t i = 0; i < layers_count; i++) {
                            const FlutterLayer* layer = layers[i];
                            switch (layer->type) {
                              case kFlutterLayerContentTypeBackingStore:
                                break;
                              case kFlutterLayerContentTypePlatformView:
                                PresentPlatformView(view, layer, i);
                                break;
                            }
                          }
                          [platform_view_controller_ disposePlatformViews];
                        }];

  return true;
}

void FlutterCompositor::PresentPlatformView(FlutterView* default_base_view,
                                            const FlutterLayer* layer,
                                            size_t layer_position) {
  FML_DCHECK([[NSThread currentThread] isMainThread])
      << "Must be on the main thread to present platform views";

  int64_t platform_view_id = layer->platform_view->identifier;
  NSView* platform_view = [platform_view_controller_ platformViewWithID:platform_view_id];

  FML_DCHECK(platform_view) << "Platform view not found for id: " << platform_view_id;

  CGFloat scale = default_base_view.layer.contentsScale;
  platform_view.frame = CGRectMake(layer->offset.x / scale, layer->offset.y / scale,
                                   layer->size.width / scale, layer->size.height / scale);
  if (platform_view.superview == nil) {
    [default_base_view addSubview:platform_view];
  }
  platform_view.layer.zPosition = layer_position;
}

}  // namespace flutter
