// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_VIEWER_CC_WEB_SCROLLBAR_LAYER_IMPL_H_
#define SKY_VIEWER_CC_WEB_SCROLLBAR_LAYER_IMPL_H_

#include "base/memory/scoped_ptr.h"
#include "sky/viewer/cc/sky_viewer_cc_export.h"
#include "sky/engine/public/platform/WebScrollbar.h"
#include "sky/engine/public/platform/WebScrollbarLayer.h"

namespace blink {
class WebScrollbarThemeGeometry;
class WebScrollbarThemePainter;
}

namespace sky_viewer_cc {

class WebLayerImpl;

class WebScrollbarLayerImpl : public blink::WebScrollbarLayer {
 public:
  SKY_VIEWER_CC_EXPORT WebScrollbarLayerImpl(
      blink::WebScrollbar* scrollbar,
      blink::WebScrollbarThemePainter painter,
      blink::WebScrollbarThemeGeometry* geometry);
  SKY_VIEWER_CC_EXPORT WebScrollbarLayerImpl(
      blink::WebScrollbar::Orientation orientation,
      int thumb_thickness,
      int track_start,
      bool is_left_side_vertical_scrollbar);
  virtual ~WebScrollbarLayerImpl();

  // blink::WebScrollbarLayer implementation.
  virtual blink::WebLayer* layer();
  virtual void setScrollLayer(blink::WebLayer* layer);
  virtual void setClipLayer(blink::WebLayer* layer);

 private:
  scoped_ptr<WebLayerImpl> layer_;

  DISALLOW_COPY_AND_ASSIGN(WebScrollbarLayerImpl);
};

}  // namespace sky_viewer_cc

#endif  // SKY_VIEWER_CC_WEB_SCROLLBAR_LAYER_IMPL_H_
