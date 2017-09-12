/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 *           (C) 1999 Antti Koivisto (koivisto@kde.org)
 * Copyright (C) 2003, 2006, 2007 Apple Inc. All rights reserved.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public License
 * along with this library; see the file COPYING.LIB.  If not, write to
 * the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301, USA.
 *
 */

#ifndef SKY_ENGINE_CORE_RENDERING_RENDERBOX_H_
#define SKY_ENGINE_CORE_RENDERING_RENDERBOX_H_

#include "flutter/sky/engine/core/rendering/RenderBoxModelObject.h"
#include "flutter/sky/engine/core/rendering/RenderOverflow.h"

namespace blink {

struct LayerPaintingInfo;
struct PaintInfo;
class HitTestingTransformState;
class TransformationMatrix;

enum SizeType { MainOrPreferredSize, MinSize, MaxSize };
enum AvailableLogicalHeightType {
  ExcludeMarginBorderPadding,
  IncludeMarginBorderPadding
};
enum MarginDirection { BlockDirection, InlineDirection };

enum ShouldComputePreferred { ComputeActual, ComputePreferred };

enum ContentsClipBehavior { ForceContentsClip, SkipContentsClipIfPossible };

struct RenderBoxRareData {
  WTF_MAKE_NONCOPYABLE(RenderBoxRareData);
  WTF_MAKE_FAST_ALLOCATED;

 public:
  RenderBoxRareData()
      : m_inlineBoxWrapper(0),
        m_overrideLogicalContentHeight(-1),
        m_overrideLogicalContentWidth(-1) {}

  // For inline replaced elements, the inline box that owns us.
  InlineBox* m_inlineBoxWrapper;
  LayoutUnit m_overrideLogicalContentHeight;
  LayoutUnit m_overrideLogicalContentWidth;
};

enum LayerType {
  NoLayer,
  NormalLayer,
  // An overflow clip layer is required for bookkeeping purposes,
  // but does not force a layer to be self painting.
  OverflowClipLayer,
};

struct FontBaselineOrAuto {
  FontBaselineOrAuto() : m_auto(true), m_baseline(AlphabeticBaseline) {}
  FontBaselineOrAuto(FontBaseline baseline)
      : m_auto(false), m_baseline(baseline) {}
  bool m_auto;
  FontBaseline m_baseline;
};

class RenderBox : public RenderBoxModelObject {
 public:
  explicit RenderBox();

  // hasAutoZIndex only returns true if the element is positioned or a flex-item
  // since position:static elements that are not flex-items get their z-index
  // coerced to auto.
  virtual LayerType layerTypeRequired() const {
    if (isPositioned() || createsGroup() || hasClipPath() || hasTransform() ||
        !style()->hasAutoZIndex())
      return NormalLayer;
    if (hasOverflowClip())
      return OverflowClipLayer;
    return NoLayer;
  }

  void destroyLayer();
  void createLayer(LayerType);
  bool hasSelfPaintingLayer() const;
  RenderLayer* layer() const { return m_layer.get(); }

  // Use this with caution! No type checking is done!
  RenderBox* firstChildBox() const;
  RenderBox* lastChildBox() const;

  LayoutUnit x() const { return m_frameRect.x(); }
  LayoutUnit y() const { return m_frameRect.y(); }
  LayoutUnit width() const { return m_frameRect.width(); }
  LayoutUnit height() const { return m_frameRect.height(); }

  int pixelSnappedWidth() const { return m_frameRect.pixelSnappedWidth(); }
  int pixelSnappedHeight() const { return m_frameRect.pixelSnappedHeight(); }

  // These represent your location relative to your container as a physical
  // offset. In layout related methods you almost always want the logical
  // location (e.g. x() and y()).
  LayoutUnit top() const { return location().y(); }
  LayoutUnit left() const { return location().x(); }

  void setX(LayoutUnit x) { m_frameRect.setX(x); }
  void setY(LayoutUnit y) { m_frameRect.setY(y); }
  void setWidth(LayoutUnit width) { m_frameRect.setWidth(width); }
  void setHeight(LayoutUnit height) { m_frameRect.setHeight(height); }

  LayoutUnit logicalLeft() const { return x(); }
  LayoutUnit logicalRight() const { return logicalLeft() + logicalWidth(); }
  LayoutUnit logicalTop() const { return y(); }
  LayoutUnit logicalBottom() const { return logicalTop() + logicalHeight(); }
  LayoutUnit logicalWidth() const { return width(); }
  LayoutUnit logicalHeight() const { return height(); }

  LayoutUnit constrainLogicalWidthByMinMax(LayoutUnit,
                                           LayoutUnit,
                                           RenderBlock*) const;
  LayoutUnit constrainLogicalHeightByMinMax(
      LayoutUnit logicalHeight,
      LayoutUnit intrinsicContentHeight) const;
  LayoutUnit constrainContentBoxLogicalHeightByMinMax(
      LayoutUnit logicalHeight,
      LayoutUnit intrinsicContentHeight) const;

  int pixelSnappedLogicalHeight() const { return pixelSnappedHeight(); }
  int pixelSnappedLogicalWidth() const { return pixelSnappedWidth(); }

  void setLogicalLeft(LayoutUnit left) { setX(left); }
  void setLogicalTop(LayoutUnit top) { setY(top); }
  void setLogicalLocation(const LayoutPoint& location) {
    setLocation(location);
  }
  void setLogicalWidth(LayoutUnit size) { setWidth(size); }
  void setLogicalHeight(LayoutUnit size) { setHeight(size); }
  void setLogicalSize(const LayoutSize& size) { setSize(size); }

  LayoutPoint location() const { return m_frameRect.location(); }
  LayoutSize locationOffset() const { return LayoutSize(x(), y()); }
  LayoutSize size() const { return m_frameRect.size(); }
  IntSize pixelSnappedSize() const { return m_frameRect.pixelSnappedSize(); }

  void setLocation(const LayoutPoint& location) {
    m_frameRect.setLocation(location);
  }

  void setSize(const LayoutSize& size) { m_frameRect.setSize(size); }
  void move(LayoutUnit dx, LayoutUnit dy) { m_frameRect.move(dx, dy); }

  LayoutRect frameRect() const { return m_frameRect; }
  IntRect pixelSnappedFrameRect() const {
    return pixelSnappedIntRect(m_frameRect);
  }
  void setFrameRect(const LayoutRect& rect) { m_frameRect = rect; }

  LayoutRect borderBoxRect() const { return LayoutRect(LayoutPoint(), size()); }
  LayoutRect paddingBoxRect() const {
    return LayoutRect(borderLeft(), borderTop(), clientWidth(), clientHeight());
  }
  IntRect pixelSnappedBorderBoxRect() const {
    return IntRect(IntPoint(), m_frameRect.pixelSnappedSize());
  }
  virtual IntRect borderBoundingBox() const override final {
    return pixelSnappedBorderBoxRect();
  }

  // The content area of the box (excludes padding - and intrinsic padding for
  // table cells, etc... - and border).
  LayoutRect contentBoxRect() const {
    return LayoutRect(borderLeft() + paddingLeft(), borderTop() + paddingTop(),
                      contentWidth(), contentHeight());
  }
  // The content box in absolute coords. Ignores transforms.
  IntRect absoluteContentBox() const;
  // The content box converted to absolute coords (taking transforms into
  // account).
  FloatQuad absoluteContentQuad() const;

  FloatPoint perspectiveOrigin() const;

  // This returns the content area of the box (excluding padding and border).
  // The only difference with contentBoxRect is that computedCSSContentBoxRect
  // does include the intrinsic padding in the content box as this is what some
  // callers expect (like getComputedStyle).
  LayoutRect computedCSSContentBoxRect() const {
    return LayoutRect(
        borderLeft() + computedCSSPaddingLeft(),
        borderTop() + computedCSSPaddingTop(),
        clientWidth() - computedCSSPaddingLeft() - computedCSSPaddingRight(),
        clientHeight() - computedCSSPaddingTop() - computedCSSPaddingBottom());
  }

  virtual void addFocusRingRects(
      Vector<IntRect>&,
      const LayoutPoint& additionalOffset,
      const RenderBox* paintContainer = 0) const override;

  // Use this with caution! No type checking is done!
  RenderBox* previousSiblingBox() const;
  RenderBox* nextSiblingBox() const;
  RenderBox* parentBox() const;

  // Visual and layout overflow are in the coordinate space of the box.  This
  // means that they aren't purely physical directions. For horizontal-tb and
  // vertical-lr they will match physical directions, but for horizontal-bt and
  // vertical-rl, the top/bottom and left/right respectively are flipped when
  // compared to their physical counterparts.  For example minX is on the left
  // in vertical-lr, but it is on the right in vertical-rl.
  LayoutRect layoutOverflowRect() const {
    return m_overflow ? m_overflow->layoutOverflowRect() : paddingBoxRect();
  }
  IntRect pixelSnappedLayoutOverflowRect() const {
    return pixelSnappedIntRect(layoutOverflowRect());
  }
  LayoutSize maxLayoutOverflow() const {
    return LayoutSize(layoutOverflowRect().maxX(), layoutOverflowRect().maxY());
  }
  LayoutUnit logicalLefxlayoutOverflow() const {
    return layoutOverflowRect().x();
  }
  LayoutUnit logicalRightLayoutOverflow() const {
    return layoutOverflowRect().maxX();
  }

  virtual LayoutRect visualOverflowRect() const {
    return m_overflow ? m_overflow->visualOverflowRect() : borderBoxRect();
  }
  LayoutUnit logicalLeftVisualOverflow() const {
    return visualOverflowRect().x();
  }
  LayoutUnit logicalRightVisualOverflow() const {
    return visualOverflowRect().maxX();
  }

  LayoutRect contentsVisualOverflowRect() const {
    return m_overflow ? m_overflow->contentsVisualOverflowRect() : LayoutRect();
  }

  void addLayoutOverflow(const LayoutRect&);
  void addVisualOverflow(const LayoutRect&);

  // Clipped by the contents clip, if one exists.
  void addContentsVisualOverflow(const LayoutRect&);

  void addVisualEffectOverflow();
  LayoutBoxExtent computeVisualEffectOverflowExtent() const;
  void addOverflowFromChild(RenderBox* child) {
    addOverflowFromChild(child, child->locationOffset());
  }
  void addOverflowFromChild(RenderBox* child, const LayoutSize& delta);
  void clearLayoutOverflow();
  void clearAllOverflows() { m_overflow.clear(); }

  void updateLayerTransformAfterLayout();

  // This transform has the transform-origin baked in.
  TransformationMatrix* transform() const { return m_transform.get(); }
  bool has3DTransform() const {
    return m_transform && !m_transform->isAffine();
  }

  LayoutUnit contentWidth() const {
    return clientWidth() - paddingLeft() - paddingRight();
  }
  LayoutUnit contentHeight() const {
    return clientHeight() - paddingTop() - paddingBottom();
  }
  LayoutUnit contentLogicalWidth() const { return contentWidth(); }
  LayoutUnit contentLogicalHeight() const { return contentHeight(); }

  // IE extensions. Used to calculate offsetWidth/Height.  Overridden by inlines
  // (RenderFlow) to return the remaining width on a given line (and the height
  // of a single line).
  virtual LayoutUnit offsetWidth() const override { return width(); }
  virtual LayoutUnit offsetHeight() const override { return height(); }

  virtual int pixelSnappedOffsetWidth() const override final;
  virtual int pixelSnappedOffsetHeight() const override final;

  // More IE extensions.  clientWidth and clientHeight represent the interior of
  // an object excluding border and scrollbar.  clientLeft/Top are just the
  // borderLeftWidth and borderTopWidth.
  LayoutUnit clientLeft() const { return borderLeft(); }
  LayoutUnit clientTop() const { return borderTop(); }
  LayoutUnit clientWidth() const;
  LayoutUnit clientHeight() const;
  LayoutUnit clientLogicalWidth() const { return clientWidth(); }
  LayoutUnit clientLogicalHeight() const { return clientHeight(); }
  LayoutUnit clientLogicalBottom() const {
    return borderBefore() + clientLogicalHeight();
  }
  LayoutRect clientBoxRect() const {
    return LayoutRect(clientLeft(), clientTop(), clientWidth(), clientHeight());
  }

  int pixelSnappedClientWidth() const;
  int pixelSnappedClientHeight() const;

  virtual LayoutUnit marginTop() const override { return m_marginBox.top(); }
  virtual LayoutUnit marginBottom() const override {
    return m_marginBox.bottom();
  }
  virtual LayoutUnit marginLeft() const override { return m_marginBox.left(); }
  virtual LayoutUnit marginRight() const override {
    return m_marginBox.right();
  }
  void setMarginTop(LayoutUnit margin) { m_marginBox.setTop(margin); }
  void setMarginBottom(LayoutUnit margin) { m_marginBox.setBottom(margin); }
  void setMarginLeft(LayoutUnit margin) { m_marginBox.setLeft(margin); }
  void setMarginRight(LayoutUnit margin) { m_marginBox.setRight(margin); }

  LayoutUnit marginLogicalLeft() const { return m_marginBox.logicalLeft(); }
  LayoutUnit marginLogicalRight() const { return m_marginBox.logicalRight(); }

  virtual LayoutUnit marginBefore(
      const RenderStyle* overrideStyle = 0) const override final {
    return m_marginBox.before();
  }
  virtual LayoutUnit marginAfter(
      const RenderStyle* overrideStyle = 0) const override final {
    return m_marginBox.after();
  }
  virtual LayoutUnit marginStart(
      const RenderStyle* overrideStyle = 0) const override final {
    const RenderStyle* styleToUse = overrideStyle ? overrideStyle : style();
    return m_marginBox.start(styleToUse->direction());
  }
  virtual LayoutUnit marginEnd(
      const RenderStyle* overrideStyle = 0) const override final {
    const RenderStyle* styleToUse = overrideStyle ? overrideStyle : style();
    return m_marginBox.end(styleToUse->direction());
  }
  void setMarginBefore(LayoutUnit value, const RenderStyle* overrideStyle = 0) {
    m_marginBox.setBefore(value);
  }
  void setMarginAfter(LayoutUnit value, const RenderStyle* overrideStyle = 0) {
    m_marginBox.setAfter(value);
  }
  void setMarginStart(LayoutUnit value, const RenderStyle* overrideStyle = 0) {
    const RenderStyle* styleToUse = overrideStyle ? overrideStyle : style();
    m_marginBox.setStart(styleToUse->direction(), value);
  }
  void setMarginEnd(LayoutUnit value, const RenderStyle* overrideStyle = 0) {
    const RenderStyle* styleToUse = overrideStyle ? overrideStyle : style();
    m_marginBox.setEnd(styleToUse->direction(), value);
  }

  virtual void absoluteQuads(Vector<FloatQuad>&) const override;

  bool hitTestLayer(RenderLayer* rootLayer,
                    RenderLayer* containerLayer,
                    const HitTestRequest& request,
                    HitTestResult& result,
                    const LayoutRect& hitTestRect,
                    const HitTestLocation& hitTestLocation,
                    const HitTestingTransformState* transformState = 0,
                    double* zOffset = 0);

  void paintLayer(GraphicsContext*, const LayerPaintingInfo&);

  virtual void layout() override;
  virtual void paint(PaintInfo&,
                     const LayoutPoint&,
                     Vector<RenderBox*>& layers) override;
  virtual bool nodeAtPoint(const HitTestRequest&,
                           HitTestResult&,
                           const HitTestLocation& locationInContainer,
                           const LayoutPoint& accumulatedOffset) override;

  virtual LayoutUnit minPreferredLogicalWidth() const override;
  virtual LayoutUnit maxPreferredLogicalWidth() const override;

  void setMinPreferredLogicalWidth(LayoutUnit);
  void setMaxPreferredLogicalWidth(LayoutUnit);

  // FIXME: We should rename these back to overrideLogicalHeight/Width and have
  // them store the border-box height/width like the regular height/width
  // accessors on RenderBox. Right now, these are different than
  // contentHeight/contentWidth because they still include the scrollbar
  // height/width.
  LayoutUnit overrideLogicalContentWidth() const;
  LayoutUnit overrideLogicalContentHeight() const;
  bool hasOverrideHeight() const;
  bool hasOverrideWidth() const;
  void setOverrideLogicalContentHeight(LayoutUnit);
  void setOverrideLogicalContentWidth(LayoutUnit);
  void clearOverrideSize();
  void clearOverrideLogicalContentHeight();
  void clearOverrideLogicalContentWidth();

  virtual LayoutSize offsetFromContainer(
      const RenderObject*,
      const LayoutPoint&,
      bool* offsetDependsOnPoint = 0) const override;

  LayoutUnit adjustBorderBoxLogicalWidthForBoxSizing(LayoutUnit width) const;
  LayoutUnit adjustBorderBoxLogicalHeightForBoxSizing(LayoutUnit height) const;
  LayoutUnit adjustContentBoxLogicalWidthForBoxSizing(LayoutUnit width) const;
  LayoutUnit adjustContentBoxLogicalHeightForBoxSizing(LayoutUnit height) const;

  struct ComputedMarginValues {
    ComputedMarginValues() {}

    LayoutUnit m_before;
    LayoutUnit m_after;
    LayoutUnit m_start;
    LayoutUnit m_end;
  };
  struct LogicalExtentComputedValues {
    LogicalExtentComputedValues() {}

    LayoutUnit m_extent;
    LayoutUnit m_position;
    ComputedMarginValues m_margins;
  };
  // Resolve auto margins in the chosen direction of the containing block so
  // that objects can be pushed to the start, middle or end of the containing
  // block.
  void computeMarginsForDirection(MarginDirection forDirection,
                                  const RenderBlock* containingBlock,
                                  LayoutUnit containerWidth,
                                  LayoutUnit childWidth,
                                  LayoutUnit& marginStart,
                                  LayoutUnit& marginEnd,
                                  Length marginStartLength,
                                  Length marginStartEnd) const;

  // Used to resolve margins in the containing block's block-flow direction.
  void computeAndSetBlockDirectionMargins(const RenderBlock* containingBlock);

  void positionLineBox(InlineBox*);

  virtual InlineBox* createInlineBox();
  void dirtyLineBoxes(bool fullLayout);

  // For inline replaced elements, this function returns the inline box that
  // owns us.  Enables the replaced RenderObject to quickly determine what line
  // it is contained on and to easily iterate over structures on the line.
  InlineBox* inlineBoxWrapper() const {
    return m_rareData ? m_rareData->m_inlineBoxWrapper : 0;
  }
  void setInlineBoxWrapper(InlineBox*);
  void deleteLineBoxWrapper();

  LayoutUnit containingBlockLogicalHeightForContent(
      AvailableLogicalHeightType) const;

  virtual void updateLogicalWidth();
  virtual void updateLogicalHeight();
  virtual void computeLogicalHeight(LayoutUnit logicalHeight,
                                    LayoutUnit logicalTop,
                                    LogicalExtentComputedValues&) const;

  void computeLogicalWidth(LogicalExtentComputedValues&) const;

  virtual LayoutSize intrinsicSize() const { return LayoutSize(); }
  LayoutUnit intrinsicLogicalWidth() const { return intrinsicSize().width(); }
  LayoutUnit intrinsicLogicalHeight() const { return intrinsicSize().height(); }
  virtual LayoutUnit intrinsicContentLogicalHeight() const {
    return m_intrinsicContentLogicalHeight;
  }

  // Whether or not the element shrinks to its intrinsic width (rather than
  // filling the width of a containing block).  HTML4 buttons, <select>s,
  // <input>s, legends, and floating/compact elements do this.
  bool sizesLogicalWidthToFitContent(const Length& logicalWidth) const;

  LayoutUnit computeLogicalWidthUsing(SizeType,
                                      const Length& logicalWidth,
                                      LayoutUnit availableLogicalWidth,
                                      const RenderBlock* containingBlock) const;
  LayoutUnit computeLogicalHeightUsing(const Length& height,
                                       LayoutUnit intrinsicContentHeight) const;
  LayoutUnit computeContentLogicalHeight(
      const Length& height,
      LayoutUnit intrinsicContentHeight) const;
  LayoutUnit computeContentLogicalHeightUsing(
      const Length& height,
      LayoutUnit intrinsicContentHeight) const;
  LayoutUnit computeReplacedLogicalWidthUsing(const Length& width) const;
  LayoutUnit computeReplacedLogicalWidthRespectingMinMaxWidth(
      LayoutUnit logicalWidth,
      ShouldComputePreferred = ComputeActual) const;
  LayoutUnit computeReplacedLogicalHeightUsing(const Length& height) const;
  LayoutUnit computeReplacedLogicalHeightRespectingMinMaxHeight(
      LayoutUnit logicalHeight) const;

  virtual LayoutUnit computeReplacedLogicalWidth(
      ShouldComputePreferred = ComputeActual) const;
  virtual LayoutUnit computeReplacedLogicalHeight() const;

  // Block flows subclass availableWidth/Height to handle multi column layout
  // (shrinking the width/height available to children when laying out.)
  virtual LayoutUnit availableLogicalWidth() const {
    return contentLogicalWidth();
  }
  virtual LayoutUnit availableLogicalHeight(AvailableLogicalHeightType) const;
  LayoutUnit availableLogicalHeightUsing(const Length&,
                                         AvailableLogicalHeightType) const;

  // There are a few cases where we need to refer specifically to the available
  // physical width and available physical height. Relative positioning is one
  // of those cases, since left/top offsets are physical.
  LayoutUnit availableWidth() const { return availableLogicalWidth(); }
  LayoutUnit availableHeight() const {
    return availableLogicalHeight(IncludeMarginBorderPadding);
  }

  virtual LayoutRect localCaretRect(
      InlineBox*,
      int caretOffset,
      LayoutUnit* extraWidthToEndOfLine = 0) override;

  virtual LayoutRect overflowClipRect(const LayoutPoint& location);
  LayoutRect clipRect(const LayoutPoint& location);
  bool pushContentsClip(PaintInfo&,
                        const LayoutPoint& accumulatedOffset,
                        ContentsClipBehavior);
  void popContentsClip(PaintInfo&, const LayoutPoint& accumulatedOffset);

  virtual void paintBoxDecorationBackground(PaintInfo&, const LayoutPoint&);

  // Called when a positioned object moves but doesn't necessarily change size.
  // A simplified layout is attempted that just updates the object's position.
  // If the size does change, the object remains dirty.
  bool tryLayoutDoingPositionedMovementOnly() {
    LayoutUnit oldWidth = width();
    updateLogicalWidth();
    // If we shrink to fit our width may have changed, so we still need full
    // layout.
    if (oldWidth != width())
      return false;
    updateLogicalHeight();
    return true;
  }

  virtual PositionWithAffinity positionForPoint(const LayoutPoint&) override;

  void removeFloatingOrPositionedChildFromBlockLists();

  RenderLayer* enclosingFloatPaintingLayer() const;

  virtual int firstLineBoxBaseline(FontBaselineOrAuto baselineType) const {
    return -1;
  }
  virtual int inlineBlockBaseline(LineDirectionMode) const {
    return -1;
  }  // Returns -1 if we should skip this box when computing the baseline of an
     // inline-block.

  bool isFlexItem() const {
    return !isInline() && !isFloatingOrOutOfFlowPositioned() && parent() &&
           parent()->isFlexibleBox();
  }

  virtual LayoutUnit lineHeight(
      bool firstLine,
      LineDirectionMode,
      LinePositionMode = PositionOnContainingLine) const override;
  virtual int baselinePosition(
      FontBaseline,
      bool firstLine,
      LineDirectionMode,
      LinePositionMode = PositionOnContainingLine) const override;

  virtual LayoutUnit offsetLeft() const override;
  virtual LayoutUnit offsetTop() const override;

  LayoutRect layoutOverflowRectForPropagation() const;

  bool hasRenderOverflow() const { return m_overflow; }
  bool hasVisualOverflow() const {
    return m_overflow &&
           !borderBoxRect().contains(m_overflow->visualOverflowRect());
  }

  virtual bool needsPreferredWidthsRecalculation() const;
  virtual void computeIntrinsicRatioInformation(
      FloatSize& /* intrinsicSize */,
      double& /* intrinsicRatio */) const {}

  virtual bool hasRelativeLogicalHeight() const;

  bool hasSameDirectionAs(const RenderBox* object) const {
    return style()->direction() == object->style()->direction();
  }

 protected:
  virtual void willBeDestroyed() override;

  virtual void styleWillChange(StyleDifference,
                               const RenderStyle& newStyle) override;
  virtual void styleDidChange(StyleDifference,
                              const RenderStyle* oldStyle) override;

  void paintBackground(const PaintInfo&,
                       const LayoutRect&,
                       const Color& backgroundColor,
                       BackgroundBleedAvoidance = BackgroundBleedNone);
  void paintFillLayer(const PaintInfo&,
                      const Color&,
                      const FillLayer&,
                      const LayoutRect&,
                      BackgroundBleedAvoidance,
                      RenderObject* backgroundObject,
                      bool skipBaseColor = false);
  void paintFillLayers(const PaintInfo&,
                       const Color&,
                       const FillLayer&,
                       const LayoutRect&,
                       BackgroundBleedAvoidance = BackgroundBleedNone,
                       RenderObject* backgroundObject = 0);
  void paintBoxDecorationBackgroundWithRect(PaintInfo&,
                                            const LayoutPoint&,
                                            const LayoutRect&);

  // Information extracted from RenderStyle for box painting.
  // These are always needed during box painting and recomputing them takes
  // time.
  struct BoxDecorationData {
    BoxDecorationData(const RenderStyle&);

    Color backgroundColor;
    bool hasBackground;
    bool hasBorder;
  };

  BackgroundBleedAvoidance determineBackgroundBleedAvoidance(
      GraphicsContext*,
      const BoxDecorationData&) const;
  bool backgroundHasOpaqueTopLayer() const;

  void computePositionedLogicalWidth(LogicalExtentComputedValues&) const;

  LayoutUnit computeIntrinsicLogicalWidthUsing(
      const Length& logicalWidthLength,
      LayoutUnit availableLogicalWidth,
      LayoutUnit borderAndPadding) const;
  LayoutUnit computeIntrinsicLogicalContentHeightUsing(
      const Length& logicalHeightLength,
      LayoutUnit intrinsicContentHeight,
      LayoutUnit borderAndPadding) const;

  virtual bool shouldComputeSizeAsReplaced() const {
    return isReplaced() && !isInlineBlock();
  }

  virtual void mapLocalToContainer(
      const RenderBox* paintInvalidationContainer,
      TransformState&,
      MapCoordinatesFlags = ApplyContainerFlip) const override;

  void updateIntrinsicContentLogicalHeight(
      LayoutUnit intrinsicContentLogicalHeight) const {
    m_intrinsicContentLogicalHeight = intrinsicContentLogicalHeight;
  }

 private:
  void updateTransformationMatrix();
  void updateTransform(const RenderStyle* oldStyle);
  void updateFromStyle();

  PassRefPtr<HitTestingTransformState> createLocalTransformState(
      RenderLayer* rootLayer,
      RenderLayer* containerLayer,
      const LayoutRect& hitTestRect,
      const HitTestLocation& hitTestLocation,
      const HitTestingTransformState* containerTransformState) const;
  bool hitTestNonLayerDescendants(const HitTestRequest& request,
                                  HitTestResult& result,
                                  const LayoutRect& layerBounds,
                                  const HitTestLocation& hitTestLocation);

  void paintLayerContents(GraphicsContext*, const LayerPaintingInfo&);

  void shrinkToFitWidth(const LayoutUnit availableSpace,
                        const LayoutUnit logicalLeftValue,
                        const LayoutUnit bordersPlusPadding,
                        LogicalExtentComputedValues&) const;

  bool skipContainingBlockForPercentHeightCalculation(
      const RenderBox* containingBlock) const;

  LayoutUnit containingBlockLogicalWidthForPositioned(
      const RenderBoxModelObject* containingBlock) const;
  LayoutUnit containingBlockLogicalHeightForPositioned(
      const RenderBoxModelObject* containingBlock) const;

  void computePositionedLogicalHeight(LogicalExtentComputedValues&) const;
  void computePositionedLogicalWidthUsing(
      Length logicalWidth,
      const RenderBoxModelObject* containerBlock,
      TextDirection containerDirection,
      LayoutUnit containerLogicalWidth,
      LayoutUnit bordersPlusPadding,
      const Length& logicalLeft,
      const Length& logicalRight,
      const Length& marginLogicalLeft,
      const Length& marginLogicalRight,
      LogicalExtentComputedValues&) const;
  void computePositionedLogicalHeightUsing(
      Length logicalHeightLength,
      const RenderBoxModelObject* containerBlock,
      LayoutUnit containerLogicalHeight,
      LayoutUnit bordersPlusPadding,
      LayoutUnit logicalHeight,
      const Length& logicalTop,
      const Length& logicalBottom,
      const Length& marginLogicalTop,
      const Length& marginLogicalBottom,
      LogicalExtentComputedValues&) const;

  void computePositionedLogicalHeightReplaced(
      LogicalExtentComputedValues&) const;
  void computePositionedLogicalWidthReplaced(
      LogicalExtentComputedValues&) const;

  LayoutUnit fillAvailableMeasure(LayoutUnit availableLogicalWidth) const;

  virtual void computeIntrinsicLogicalWidths(LayoutUnit& minLogicalWidth,
                                             LayoutUnit& maxLogicalWidth) const;

  // This function calculates the minimum and maximum preferred widths for an
  // object. These values are used in shrink-to-fit layout systems. These
  // include tables, positioned objects, floats and flexible boxes.
  virtual void computePreferredLogicalWidths() {
    clearPreferredLogicalWidthsDirty();
  }

  RenderBoxRareData& ensureRareData() {
    if (!m_rareData)
      m_rareData = adoptPtr(new RenderBoxRareData());
    return *m_rareData.get();
  }

  bool logicalHeightComputesAsNone(SizeType) const;

  bool isBox() const =
      delete;  // This will catch anyone doing an unnecessary check.

  // The width/height of the contents + borders + padding.  The x/y location is
  // relative to our container (which is not always our parent).
  LayoutRect m_frameRect;

  // Our intrinsic height, used for min-height: min-content etc. Maintained by
  // updateLogicalHeight. This is logicalHeight() before it is clamped to
  // min/max.
  mutable LayoutUnit m_intrinsicContentLogicalHeight;

 protected:
  LayoutBoxExtent m_marginBox;

  // The preferred logical width of the element if it were to break its lines at
  // every possible opportunity.
  LayoutUnit m_minPreferredLogicalWidth;

  // The preferred logical width of the element if it never breaks any lines at
  // all.
  LayoutUnit m_maxPreferredLogicalWidth;

  // Our overflow information.
  OwnPtr<RenderOverflow> m_overflow;

  // TODO(ojan): Move these two into RenderBoxRareData.
  OwnPtr<TransformationMatrix> m_transform;

 private:
  OwnPtr<RenderLayer> m_layer;
  OwnPtr<RenderBoxRareData> m_rareData;
};

DEFINE_RENDER_OBJECT_TYPE_CASTS(RenderBox, isBox());

inline RenderBox* RenderBox::previousSiblingBox() const {
  return toRenderBox(previousSibling());
}

inline RenderBox* RenderBox::nextSiblingBox() const {
  return toRenderBox(nextSibling());
}

inline RenderBox* RenderBox::parentBox() const {
  return toRenderBox(parent());
}

inline RenderBox* RenderBox::firstChildBox() const {
  return toRenderBox(slowFirstChild());
}

inline RenderBox* RenderBox::lastChildBox() const {
  return toRenderBox(slowLastChild());
}

inline void RenderBox::setInlineBoxWrapper(InlineBox* boxWrapper) {
  if (boxWrapper) {
    ASSERT(!inlineBoxWrapper());
    // m_inlineBoxWrapper should already be 0. Deleting it is a safeguard
    // against security issues. Otherwise, there will two line box wrappers
    // keeping the reference to this renderer, and only one will be notified
    // when the renderer is getting destroyed. The second line box wrapper will
    // keep a stale reference.
    if (UNLIKELY(inlineBoxWrapper() != 0))
      deleteLineBoxWrapper();
  }

  ensureRareData().m_inlineBoxWrapper = boxWrapper;
}

}  // namespace blink

#endif  // SKY_ENGINE_CORE_RENDERING_RENDERBOX_H_
