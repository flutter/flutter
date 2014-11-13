// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_VIEWER_CC_WEB_LAYER_IMPL_H_
#define SKY_VIEWER_CC_WEB_LAYER_IMPL_H_

#include <string>

#include "base/memory/ref_counted.h"
#include "base/memory/scoped_ptr.h"
#include "sky/viewer/cc/sky_viewer_cc_export.h"
#include "cc/layers/layer_client.h"
#include "sky/engine/public/platform/WebCString.h"
#include "sky/engine/public/platform/WebColor.h"
#include "sky/engine/public/platform/WebCompositorAnimation.h"
#include "sky/engine/public/platform/WebFloatPoint.h"
#include "sky/engine/public/platform/WebLayer.h"
#include "sky/engine/public/platform/WebPoint.h"
#include "sky/engine/public/platform/WebRect.h"
#include "sky/engine/public/platform/WebSize.h"
#include "sky/engine/public/platform/WebString.h"
#include "sky/engine/public/platform/WebVector.h"
#include "third_party/skia/include/utils/SkMatrix44.h"

namespace blink {
class WebFilterOperations;
class WebLayerClient;
struct WebFloatRect;
}

namespace base {
namespace debug {
class ConvertableToTraceFormat;
}
}

namespace cc {
class Layer;
}

namespace sky_viewer_cc {

class WebToCCAnimationDelegateAdapter;

class WebLayerImpl : public blink::WebLayer, public cc::LayerClient {
 public:
  SKY_VIEWER_CC_EXPORT WebLayerImpl();
  SKY_VIEWER_CC_EXPORT explicit WebLayerImpl(scoped_refptr<cc::Layer>);
  virtual ~WebLayerImpl();

  static bool UsingPictureLayer();
  SKY_VIEWER_CC_EXPORT static void SetImplSidePaintingEnabled(bool enabled);

  SKY_VIEWER_CC_EXPORT cc::Layer* layer() const;

  // WebLayer implementation.
  virtual int id() const;
  // TODO(danakj): Remove WebFloatRect version.
  virtual void invalidateRect(const blink::WebFloatRect&);
  virtual void invalidateRect(const blink::WebRect&);
  virtual void invalidate();
  virtual void addChild(blink::WebLayer* child);
  virtual void insertChild(blink::WebLayer* child, size_t index);
  virtual void replaceChild(blink::WebLayer* reference,
                            blink::WebLayer* new_layer);
  virtual void removeFromParent();
  virtual void removeAllChildren();
  virtual void setBounds(const blink::WebSize& bounds);
  virtual blink::WebSize bounds() const;
  virtual void setMasksToBounds(bool masks_to_bounds);
  virtual bool masksToBounds() const;
  virtual void setMaskLayer(blink::WebLayer* mask);
  virtual void setReplicaLayer(blink::WebLayer* replica);
  virtual void setOpacity(float opacity);
  virtual float opacity() const;
  virtual void setBlendMode(blink::WebBlendMode blend_mode);
  virtual blink::WebBlendMode blendMode() const;
  virtual void setIsRootForIsolatedGroup(bool root);
  virtual bool isRootForIsolatedGroup();
  virtual void setOpaque(bool opaque);
  virtual bool opaque() const;
  virtual void setPosition(const blink::WebFloatPoint& position);
  virtual blink::WebFloatPoint position() const;
  virtual void setTransform(const SkMatrix44& transform);
  virtual void setTransformOrigin(const blink::WebFloatPoint3D& point);
  virtual blink::WebFloatPoint3D transformOrigin() const;
  virtual SkMatrix44 transform() const;
  virtual void setDrawsContent(bool draws_content);
  virtual bool drawsContent() const;
  virtual void setShouldFlattenTransform(bool flatten);
  virtual void setRenderingContext(int context);
  virtual void setUseParentBackfaceVisibility(bool visible);
  virtual void setBackgroundColor(blink::WebColor color);
  virtual blink::WebColor backgroundColor() const;
  virtual void setFilters(const blink::WebFilterOperations& filters);
  virtual void setBackgroundFilters(const blink::WebFilterOperations& filters);
  virtual void setAnimationDelegate(
      blink::WebCompositorAnimationDelegate* delegate);
  virtual bool addAnimation(blink::WebCompositorAnimation* animation);
  virtual void removeAnimation(int animation_id);
  virtual void removeAnimation(int animation_id,
                               blink::WebCompositorAnimation::TargetProperty);
  virtual void pauseAnimation(int animation_id, double time_offset);
  virtual bool hasActiveAnimation();
  virtual void setForceRenderSurface(bool force);
  virtual void setScrollPosition(blink::WebPoint position);
  virtual blink::WebPoint scrollPosition() const;
  virtual void setScrollClipLayer(blink::WebLayer* clip_layer);
  virtual void setScrollClient(blink::WebLayerScrollClient* client);
  virtual bool isOrphan() const;
  virtual void setWebLayerClient(blink::WebLayerClient* client);

  // LayerClient implementation.
  virtual scoped_refptr<base::debug::ConvertableToTraceFormat> TakeDebugInfo()
      override;

  virtual void setScrollParent(blink::WebLayer* parent);
  virtual void setClipParent(blink::WebLayer* parent);

 protected:
  scoped_refptr<cc::Layer> layer_;
  blink::WebLayerClient* web_layer_client_;

 private:
  scoped_ptr<WebToCCAnimationDelegateAdapter> animation_delegate_adapter_;

  DISALLOW_COPY_AND_ASSIGN(WebLayerImpl);
};

}  // namespace sky_viewer_cc

#endif  // SKY_VIEWER_CC_WEB_LAYER_IMPL_H_
