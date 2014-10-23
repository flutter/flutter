// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/viewer/cc/web_nine_patch_layer_impl.h"

#include "base/command_line.h"
#include "cc/base/switches.h"
#include "sky/viewer/cc/web_layer_impl.h"
#include "sky/viewer/cc/web_layer_impl_fixed_bounds.h"
#include "cc/layers/nine_patch_layer.h"
#include "cc/layers/picture_image_layer.h"

namespace sky_viewer_cc {

WebNinePatchLayerImpl::WebNinePatchLayerImpl() {
  layer_.reset(new WebLayerImpl(cc::NinePatchLayer::Create()));
}

WebNinePatchLayerImpl::~WebNinePatchLayerImpl() {
}

blink::WebLayer* WebNinePatchLayerImpl::layer() {
  return layer_.get();
}

void WebNinePatchLayerImpl::setBitmap(SkBitmap bitmap,
                                      const blink::WebRect& aperture) {
  setBitmap(bitmap);
  setAperture(aperture);
  setBorder(blink::WebRect(aperture.x,
                           aperture.y,
                           bitmap.width() - aperture.width,
                           bitmap.height() - aperture.height));
}

void WebNinePatchLayerImpl::setBitmap(SkBitmap bitmap) {
  cc::NinePatchLayer* nine_patch =
      static_cast<cc::NinePatchLayer*>(layer_->layer());
  nine_patch->SetBitmap(bitmap);
}

void WebNinePatchLayerImpl::setAperture(const blink::WebRect& aperture) {
  cc::NinePatchLayer* nine_patch =
      static_cast<cc::NinePatchLayer*>(layer_->layer());
  nine_patch->SetAperture(gfx::Rect(aperture));
}

void WebNinePatchLayerImpl::setBorder(const blink::WebRect& border) {
  cc::NinePatchLayer* nine_patch =
      static_cast<cc::NinePatchLayer*>(layer_->layer());
  nine_patch->SetBorder(gfx::Rect(border));
}

void WebNinePatchLayerImpl::setFillCenter(bool fill_center) {
  cc::NinePatchLayer* nine_patch =
      static_cast<cc::NinePatchLayer*>(layer_->layer());
  nine_patch->SetFillCenter(fill_center);
}

}  // namespace sky_viewer_cc
