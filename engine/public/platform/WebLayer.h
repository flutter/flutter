/*
 * Copyright (C) 2011 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1.  Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 * 2.  Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE AND ITS CONTRIBUTORS "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL APPLE OR ITS CONTRIBUTORS BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef WebLayer_h
#define WebLayer_h

#include "WebBlendMode.h"
#include "WebColor.h"
#include "WebCommon.h"
#include "WebCompositorAnimation.h"
#include "WebFloatPoint3D.h"
#include "WebPoint.h"
#include "WebRect.h"
#include "WebSize.h"
#include "WebString.h"
#include "WebVector.h"

class SkMatrix44;
class SkImageFilter;

namespace blink {
class WebCompositorAnimationDelegate;
class WebFilterOperations;
class WebLayerClient;
class WebLayerScrollClient;
struct WebFloatPoint;
struct WebFloatRect;
struct WebLayerPositionConstraint;

class WebLayer {
public:
    virtual ~WebLayer() { }

    // Returns a positive ID that will be unique across all WebLayers allocated in this process.
    virtual int id() const = 0;

    // Sets a region of the layer as invalid, i.e. needs to update its content.
    virtual void invalidateRect(const WebFloatRect&) = 0;

    // Sets the entire layer as invalid, i.e. needs to update its content.
    virtual void invalidate() = 0;

    // These functions do not take ownership of the WebLayer* parameter.
    virtual void addChild(WebLayer*) = 0;
    virtual void insertChild(WebLayer*, size_t index) = 0;
    virtual void replaceChild(WebLayer* reference, WebLayer* newLayer) = 0;
    virtual void removeFromParent() = 0;
    virtual void removeAllChildren() = 0;

    virtual void setBounds(const WebSize&) = 0;
    virtual WebSize bounds() const = 0;

    virtual void setMasksToBounds(bool) = 0;
    virtual bool masksToBounds() const = 0;

    virtual void setMaskLayer(WebLayer*) = 0;
    virtual void setReplicaLayer(WebLayer*) = 0;

    virtual void setOpacity(float) = 0;
    virtual float opacity() const = 0;

    virtual void setBlendMode(WebBlendMode) = 0;
    virtual WebBlendMode blendMode() const = 0;

    virtual void setIsRootForIsolatedGroup(bool) = 0;
    virtual bool isRootForIsolatedGroup() = 0;

    virtual void setOpaque(bool) = 0;
    virtual bool opaque() const = 0;

    virtual void setPosition(const WebFloatPoint&) = 0;
    virtual WebFloatPoint position() const = 0;

    virtual void setTransform(const SkMatrix44&) = 0;
    virtual SkMatrix44 transform() const = 0;

    virtual void setTransformOrigin(const WebFloatPoint3D&) { }
    virtual WebFloatPoint3D transformOrigin() const { return WebFloatPoint3D(); }

    // Sets whether the layer draws its content when compositing.
    virtual void setDrawsContent(bool) = 0;
    virtual bool drawsContent() const = 0;

    // Sets whether the layer's transform should be flattened.
    virtual void setShouldFlattenTransform(bool) = 0;

    // Sets the id of the layer's 3d rendering context. Layers in the same 3d
    // rendering context id are sorted with one another according to their 3d
    // position rather than their tree order.
    virtual void setRenderingContext(int id) = 0;

    // Mark that this layer should use its parent's transform and double-sided
    // properties in determining this layer's backface visibility instead of
    // using its own properties. If this property is set, this layer must
    // have a parent, and the parent may not have this property set.
    // Note: This API is to work around issues with visibility the handling of
    // WebKit layers that have a contents layer (canvas, plugin, WebGL, video,
    // etc).
    virtual void setUseParentBackfaceVisibility(bool) = 0;

    virtual void setBackgroundColor(WebColor) = 0;
    virtual WebColor backgroundColor() const = 0;

    // Clear the filters in use by passing in a newly instantiated
    // WebFilterOperations object.
    virtual void setFilters(const WebFilterOperations&) = 0;

    // An animation delegate is notified when animations are started and
    // stopped. The WebLayer does not take ownership of the delegate, and it is
    // the responsibility of the client to reset the layer's delegate before
    // deleting the delegate.
    virtual void setAnimationDelegate(WebCompositorAnimationDelegate*) = 0;


    // Returns false if the animation cannot be added.
    // Takes ownership of the WebCompositorAnimation object.
    virtual bool addAnimation(WebCompositorAnimation*) = 0;

    // Removes all animations with the given id.
    virtual void removeAnimation(int animationId) = 0;

    // Removes all animations with the given id targeting the given property.
    virtual void removeAnimation(int animationId, WebCompositorAnimation::TargetProperty) = 0;

    // Pauses all animations with the given id.
    virtual void pauseAnimation(int animationId, double timeOffset) = 0;

    // Returns true if this layer has any active animations - useful for tests.
    virtual bool hasActiveAnimation() = 0;

    // If a scroll parent is set, this layer will inherit its parent's scroll
    // delta and offset even though it will not be a descendant of the scroll
    // in the layer hierarchy.
    virtual void setScrollParent(WebLayer*) = 0;

    // A layer will not respect any clips established by layers between it and
    // its nearest clipping ancestor. Note, the clip parent must be an ancestor.
    // This is not a requirement of the scroll parent.
    virtual void setClipParent(WebLayer*) = 0;

    // Scrolling
    virtual void setScrollPosition(WebPoint) = 0;
    virtual WebPoint scrollPosition() const = 0;

    // To set a WebLayer as scrollable we must specify the corresponding clip layer.
    virtual void setScrollClipLayer(WebLayer*) = 0;
    virtual bool scrollable() const = 0;
    virtual void setUserScrollable(bool horizontal, bool vertical) = 0;
    virtual bool userScrollableHorizontal() const = 0;
    virtual bool userScrollableVertical() const = 0;

    virtual void setHaveWheelEventHandlers(bool) = 0;
    virtual bool haveWheelEventHandlers() const = 0;

    virtual void setHaveScrollEventHandlers(bool) = 0;
    virtual bool haveScrollEventHandlers() const = 0;

    virtual void setShouldScrollOnMainThread(bool) = 0;
    virtual bool shouldScrollOnMainThread() const = 0;

    virtual void setNonFastScrollableRegion(const WebVector<WebRect>&) = 0;
    virtual WebVector<WebRect> nonFastScrollableRegion() const = 0;

    virtual void setTouchEventHandlerRegion(const WebVector<WebRect>&) = 0;
    virtual WebVector<WebRect> touchEventHandlerRegion() const = 0;

    virtual void setIsContainerForFixedPositionLayers(bool) = 0;
    virtual bool isContainerForFixedPositionLayers() const = 0;

    // This function sets layer position constraint. The constraint will be used
    // to adjust layer position during threaded scrolling.
    virtual void setPositionConstraint(const WebLayerPositionConstraint&) = 0;
    virtual WebLayerPositionConstraint positionConstraint() const = 0;

    // The scroll client is notified when the scroll position of the WebLayer
    // changes. Only a single scroll client can be set for a WebLayer at a time.
    // The WebLayer does not take ownership of the scroll client, and it is the
    // responsibility of the client to reset the layer's scroll client before
    // deleting the scroll client.
    virtual void setScrollClient(WebLayerScrollClient*) = 0;

    // Forces this layer to use a render surface. There is no benefit in doing
    // so, but this is to facilitate benchmarks and tests.
    virtual void setForceRenderSurface(bool) = 0;

    // True if the layer is not part of a tree attached to a WebLayerTreeView.
    virtual bool isOrphan() const = 0;

    virtual void setWebLayerClient(WebLayerClient*) = 0;
};

} // namespace blink

#endif // WebLayer_h
