// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/viewer/cc/web_content_layer_impl.h"

#include "cc/layers/content_layer.h"
#include "cc/layers/picture_layer.h"
#include "sky/engine/public/platform/WebContentLayerClient.h"
#include "sky/engine/public/platform/WebFloatPoint.h"
#include "sky/engine/public/platform/WebFloatRect.h"
#include "sky/engine/public/platform/WebRect.h"
#include "sky/engine/public/platform/WebSize.h"
#include "third_party/skia/include/utils/SkMatrix44.h"

using cc::ContentLayer;
using cc::PictureLayer;

namespace sky_viewer_cc {

WebContentLayerImpl::WebContentLayerImpl(blink::WebContentLayerClient* client)
    : client_(client), ignore_lcd_text_change_(false) {
  if (WebLayerImpl::UsingPictureLayer())
    layer_ = make_scoped_ptr(new WebLayerImpl(PictureLayer::Create(this)));
  else
    layer_ = make_scoped_ptr(new WebLayerImpl(ContentLayer::Create(this)));
  layer_->layer()->SetIsDrawable(true);
  can_use_lcd_text_ = layer_->layer()->can_use_lcd_text();
}

WebContentLayerImpl::~WebContentLayerImpl() {
  if (WebLayerImpl::UsingPictureLayer())
    static_cast<PictureLayer*>(layer_->layer())->ClearClient();
  else
    static_cast<ContentLayer*>(layer_->layer())->ClearClient();
}

blink::WebLayer* WebContentLayerImpl::layer() {
  return layer_.get();
}

void WebContentLayerImpl::setDoubleSided(bool double_sided) {
  layer_->layer()->SetDoubleSided(double_sided);
}

void WebContentLayerImpl::setDrawCheckerboardForMissingTiles(bool enable) {
  layer_->layer()->SetDrawCheckerboardForMissingTiles(enable);
}

void WebContentLayerImpl::PaintContents(
    SkCanvas* canvas,
    const gfx::Rect& clip,
    ContentLayerClient::GraphicsContextStatus graphics_context_status) {
  if (!client_)
    return;

  blink::WebFloatRect web_opaque;
  client_->paintContents(
      canvas,
      clip,
      can_use_lcd_text_,
      web_opaque,
      graphics_context_status == ContentLayerClient::GRAPHICS_CONTEXT_ENABLED
          ? blink::WebContentLayerClient::GraphicsContextEnabled
          : blink::WebContentLayerClient::GraphicsContextDisabled);
}

void WebContentLayerImpl::DidChangeLayerCanUseLCDText() {
  // It is important to make this comparison because the LCD text status
  // here can get out of sync with that in the layer.
  if (can_use_lcd_text_ == layer_->layer()->can_use_lcd_text())
    return;

  // LCD text cannot be enabled once disabled.
  if (layer_->layer()->can_use_lcd_text() && ignore_lcd_text_change_)
    return;

  can_use_lcd_text_ = layer_->layer()->can_use_lcd_text();
  ignore_lcd_text_change_ = true;
  layer_->invalidate();
}

bool WebContentLayerImpl::FillsBoundsCompletely() const {
  return false;
}

}  // namespace sky_viewer_cc
