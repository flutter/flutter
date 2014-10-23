// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_VIEWER_CC_WEB_NINE_PATCH_LAYER_IMPL_H_
#define SKY_VIEWER_CC_WEB_NINE_PATCH_LAYER_IMPL_H_

#include "base/memory/scoped_ptr.h"
#include "sky/viewer/cc/sky_viewer_cc_export.h"
#include "sky/engine/public/platform/WebNinePatchLayer.h"
#include "third_party/skia/include/core/SkBitmap.h"

namespace sky_viewer_cc {

class WebLayerImpl;

class WebNinePatchLayerImpl : public blink::WebNinePatchLayer {
 public:
  SKY_VIEWER_CC_EXPORT WebNinePatchLayerImpl();
  virtual ~WebNinePatchLayerImpl();

  // blink::WebNinePatchLayer implementation.
  virtual blink::WebLayer* layer();

  // TODO(ccameron): Remove setBitmap(SkBitmap, blink::WebRect) in favor of
  // setBitmap(), setAperture(), and setBorder();
  virtual void setBitmap(SkBitmap bitmap, const blink::WebRect& aperture);
  virtual void setBitmap(SkBitmap bitmap);
  virtual void setAperture(const blink::WebRect& aperture);
  virtual void setBorder(const blink::WebRect& border);
  virtual void setFillCenter(bool fill_center);

 private:
  scoped_ptr<WebLayerImpl> layer_;

  DISALLOW_COPY_AND_ASSIGN(WebNinePatchLayerImpl);
};

}  // namespace sky_viewer_cc

#endif  // SKY_VIEWER_CC_WEB_NINE_PATCH_LAYER_IMPL_H_
