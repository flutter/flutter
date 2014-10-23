// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_VIEWER_CC_WEB_IMAGE_LAYER_IMPL_H_
#define SKY_VIEWER_CC_WEB_IMAGE_LAYER_IMPL_H_

#include "base/memory/scoped_ptr.h"
#include "sky/viewer/cc/sky_viewer_cc_export.h"
#include "sky/engine/public/platform/WebImageLayer.h"
#include "third_party/skia/include/core/SkBitmap.h"

namespace sky_viewer_cc {

class WebLayerImpl;

class WebImageLayerImpl : public blink::WebImageLayer {
 public:
  SKY_VIEWER_CC_EXPORT WebImageLayerImpl();
  virtual ~WebImageLayerImpl();

  // blink::WebImageLayer implementation.
  virtual blink::WebLayer* layer();
  virtual void setBitmap(SkBitmap);

 private:
  scoped_ptr<WebLayerImpl> layer_;

  DISALLOW_COPY_AND_ASSIGN(WebImageLayerImpl);
};

}  // namespace sky_viewer_cc

#endif  // SKY_VIEWER_CC_WEB_IMAGE_LAYER_IMPL_H_
