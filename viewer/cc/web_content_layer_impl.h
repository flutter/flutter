// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_VIEWER_CC_WEB_CONTENT_LAYER_IMPL_H_
#define SKY_VIEWER_CC_WEB_CONTENT_LAYER_IMPL_H_

#include "base/memory/scoped_ptr.h"
#include "sky/viewer/cc/sky_viewer_cc_export.h"
#include "sky/viewer/cc/web_layer_impl.h"
#include "cc/layers/content_layer_client.h"
#include "sky/engine/public/platform/WebContentLayer.h"

namespace cc {
class IntRect;
class FloatRect;
}

namespace blink {
class WebContentLayerClient;
}

namespace sky_viewer_cc {

class WebContentLayerImpl : public blink::WebContentLayer,
                            public cc::ContentLayerClient {
 public:
  SKY_VIEWER_CC_EXPORT explicit WebContentLayerImpl(blink::WebContentLayerClient*);

  // WebContentLayer implementation.
  virtual blink::WebLayer* layer();
  virtual void setDoubleSided(bool double_sided);
  virtual void setDrawCheckerboardForMissingTiles(bool checkerboard);

 protected:
  virtual ~WebContentLayerImpl();

  // ContentLayerClient implementation.
  virtual void PaintContents(SkCanvas* canvas,
                             const gfx::Rect& clip,
                             ContentLayerClient::GraphicsContextStatus
                                 graphics_context_status) override;
  virtual void DidChangeLayerCanUseLCDText() override;
  virtual bool FillsBoundsCompletely() const override;

  scoped_ptr<WebLayerImpl> layer_;
  blink::WebContentLayerClient* client_;
  bool draws_content_;

 private:
  bool can_use_lcd_text_;
  bool ignore_lcd_text_change_;

  DISALLOW_COPY_AND_ASSIGN(WebContentLayerImpl);
};

}  // namespace sky_viewer_cc

#endif  // SKY_VIEWER_CC_WEB_CONTENT_LAYER_IMPL_H_
