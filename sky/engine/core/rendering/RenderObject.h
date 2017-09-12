/*
 * Copyright (C) 2000 Lars Knoll (knoll@kde.org)
 *           (C) 2000 Antti Koivisto (koivisto@kde.org)
 *           (C) 2000 Dirk Mueller (mueller@kde.org)
 *           (C) 2004 Allan Sandfeld Jensen (kde@carewolf.com)
 * Copyright (C) 2003, 2004, 2005, 2006, 2007, 2008, 2009, 2012 Apple Inc.
 * All rights reserved.
 * Copyright (C) 2009 Google Inc. All rights reserved.
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

#ifndef SKY_ENGINE_CORE_RENDERING_RENDEROBJECT_H_
#define SKY_ENGINE_CORE_RENDERING_RENDEROBJECT_H_

#include "flutter/sky/engine/core/editing/PositionWithAffinity.h"
#include "flutter/sky/engine/core/rendering/HitTestRequest.h"
#include "flutter/sky/engine/core/rendering/RenderObjectChildList.h"
#include "flutter/sky/engine/core/rendering/SubtreeLayoutScope.h"
#include "flutter/sky/engine/core/rendering/style/RenderStyle.h"
#include "flutter/sky/engine/core/rendering/style/StyleInheritedData.h"
#include "flutter/sky/engine/platform/geometry/FloatQuad.h"
#include "flutter/sky/engine/platform/geometry/LayoutRect.h"
#include "flutter/sky/engine/platform/transforms/TransformationMatrix.h"

namespace blink {

class AffineTransform;
class HitTestLocation;
class HitTestResult;
class InlineBox;
class InlineFlowBox;
class Position;
class RenderBlock;
class RenderBox;
class RenderBoxModelObject;
class RenderGeometryMap;
class RenderLayer;
class RenderView;
class TransformState;

struct PaintInfo;

// Sides used when drawing borders and outlines. The values should run clockwise
// from top.
enum BoxSide { BSTop, BSRight, BSBottom, BSLeft };

enum MarkingBehavior {
  MarkOnlyThis,
  MarkContainingBlockChain,
};

enum MapCoordinatesMode {
  UseTransforms = 1 << 0,
  // FIXME(sky): What is this for? Do we need it?
  ApplyContainerFlip = 1 << 1,
  // FIXME(sky): Remove
  TraverseDocumentBoundaries = 1 << 2,
};
typedef unsigned MapCoordinatesFlags;

const int caretWidth = 1;

struct AnnotatedRegionValue {
  bool operator==(const AnnotatedRegionValue& o) const {
    return draggable == o.draggable && bounds == o.bounds;
  }

  LayoutRect bounds;
  bool draggable;
};

typedef WTF::HashMap<const RenderLayer*, Vector<LayoutRect>> LayerHitTestRects;

#ifndef NDEBUG
const int showTreeCharacterOffset = 39;
#endif

// Base class for all rendering tree objects.
class RenderObject {
  friend class RenderBlock;
  friend class RenderObjectChildList;
  WTF_MAKE_NONCOPYABLE(RenderObject);

 public:
  // TODO(ojan): Pass in a reference since the node can no longer be null.
  explicit RenderObject();
  virtual ~RenderObject();

  virtual const char* renderName() const = 0;

  String debugName() const;

  RenderObject* parent() const { return m_parent; }
  bool isDescendantOf(const RenderObject*) const;

  RenderObject* previousSibling() const { return m_previous; }
  RenderObject* nextSibling() const { return m_next; }

  RenderObject* slowFirstChild() const {
    if (const RenderObjectChildList* children = virtualChildren())
      return children->firstChild();
    return 0;
  }
  RenderObject* slowLastChild() const {
    if (const RenderObjectChildList* children = virtualChildren())
      return children->lastChild();
    return 0;
  }

  virtual RenderObjectChildList* virtualChildren() { return 0; }
  virtual const RenderObjectChildList* virtualChildren() const { return 0; }

  RenderObject* nextInPreOrder() const;
  RenderObject* nextInPreOrder(const RenderObject* stayWithin) const;
  RenderObject* nextInPreOrderAfterChildren() const;
  RenderObject* nextInPreOrderAfterChildren(
      const RenderObject* stayWithin) const;
  RenderObject* previousInPreOrder() const;
  RenderObject* previousInPreOrder(const RenderObject* stayWithin) const;
  RenderObject* childAt(unsigned) const;

  RenderObject* lastLeafChild() const;

  // The following six functions are used when the render tree hierarchy changes
  // to make sure layers get properly added and removed.  Since containership
  // can be implemented by any subclass, and since a hierarchy can contain a
  // mixture of boxes and other object types, these functions need to be in the
  // base class.
  RenderLayer* enclosingLayer() const;
  void addLayers(RenderLayer* parentLayer);
  void removeLayers(RenderLayer* parentLayer);
  void moveLayers(RenderLayer* oldParent, RenderLayer* newParent);
  RenderLayer* findNextLayer(RenderLayer* parentLayer,
                             RenderObject* startPoint,
                             bool checkParent = true);

  // Convenience function for getting to the nearest enclosing box of a
  // RenderObject.
  RenderBox* enclosingBox() const;
  RenderBoxModelObject* enclosingBoxModelObject() const;

#if ENABLE(ASSERT)
  // Helper class forbidding calls to setNeedsLayout() during its lifetime.
  class SetLayoutNeededForbiddenScope {
   public:
    explicit SetLayoutNeededForbiddenScope(RenderObject&);
    ~SetLayoutNeededForbiddenScope();

   private:
    RenderObject& m_renderObject;
    bool m_preexistingForbidden;
  };

  void assertRendererLaidOut() const {
#ifndef NDEBUG
    if (needsLayout())
      showRenderTreeForThis();
#endif
    ASSERT_WITH_SECURITY_IMPLICATION(!needsLayout());
  }

  void assertSubtreeIsLaidOut() const {
    for (const RenderObject* renderer = this; renderer;
         renderer = renderer->nextInPreOrder())
      renderer->assertRendererLaidOut();
  }
#endif

  bool skipInvalidationWhenLaidOutChildren() const;

  // FIXME: This could be used when changing the size of a renderer without
  // children to skip some invalidations.
  bool rendererHasNoBoxEffect() const {
    return !style()->hasVisualOverflowingEffect() && !style()->hasBorder() &&
           !style()->hasBackground();
  }

  // Obtains the nearest enclosing block (including this block) that contributes
  // a first-line style to our inline children.
  virtual RenderBlock* firstLineBlock() const;

  // RenderObject tree manipulation
  //////////////////////////////////////////
  virtual bool canHaveChildren() const { return virtualChildren(); }
  virtual bool isChildAllowed(RenderObject*, RenderStyle*) const {
    return true;
  }
  virtual void addChild(RenderObject* newChild, RenderObject* beforeChild = 0);
  virtual void removeChild(RenderObject*);
  //////////////////////////////////////////

 protected:
  //////////////////////////////////////////
  // Helper functions. Dangerous to use!
  void setPreviousSibling(RenderObject* previous) { m_previous = previous; }
  void setNextSibling(RenderObject* next) { m_next = next; }
  void setParent(RenderObject* parent) { m_parent = parent; }

  //////////////////////////////////////////
 private:
#if ENABLE(ASSERT)
  bool isSetNeedsLayoutForbidden() const { return m_setNeedsLayoutForbidden; }
  void setNeedsLayoutIsForbidden(bool flag) {
    m_setNeedsLayoutForbidden = flag;
  }
#endif

  void addAbsoluteRectForLayer(LayoutRect& result);

 public:
#ifndef NDEBUG
  void showTreeForThis() const;
  void showRenderTreeForThis() const;
  void showLineTreeForThis() const;

  void showRenderObject() const;
  // We don't make printedCharacters an optional parameter so that
  // showRenderObject can be called from gdb easily.
  void showRenderObject(int printedCharacters) const;
  void showRenderTreeAndMark(const RenderObject* markedObject1 = 0,
                             const char* markedLabel1 = 0,
                             const RenderObject* markedObject2 = 0,
                             const char* markedLabel2 = 0,
                             int depth = 0) const;
#endif

  static unsigned instanceCount() { return s_instanceCount; }

#if !ENABLE(OILPAN)
  // RenderObjects are allocated out of the rendering partition.
  void* operator new(size_t);
  void operator delete(void*);
#endif

 public:
  virtual bool isBoxModelObject() const { return false; }
  virtual bool isCanvas() const { return false; }
  virtual bool isImage() const { return false; }
  virtual bool isInlineBlock() const { return false; }
  virtual bool isRenderBlock() const { return false; }
  virtual bool isRenderParagraph() const { return false; }
  virtual bool isRenderInline() const { return false; }
  virtual bool isRenderView() const { return false; }

  bool everHadLayout() const { return m_bitfields.everHadLayout(); }

  bool alwaysCreateLineBoxesForRenderInline() const {
    ASSERT(isRenderInline());
    return m_bitfields.alwaysCreateLineBoxesForRenderInline();
  }
  void setAlwaysCreateLineBoxesForRenderInline(bool alwaysCreateLineBoxes) {
    ASSERT(isRenderInline());
    m_bitfields.setAlwaysCreateLineBoxesForRenderInline(alwaysCreateLineBoxes);
  }

  bool ancestorLineBoxDirty() const {
    return m_bitfields.ancestorLineBoxDirty();
  }
  void setAncestorLineBoxDirty(bool value = true) {
    m_bitfields.setAncestorLineBoxDirty(value);
    if (value)
      setNeedsLayout();
  }

  // SVG uses FloatPoint precise hit testing, and passes the point in parent
  // coordinates instead of in paint invalidaiton container coordinates.
  // Eventually the rest of the rendering tree will move to a similar model.
  virtual bool nodeAtFloatPoint(const HitTestRequest&,
                                HitTestResult&,
                                const FloatPoint& pointInParent);

  bool canHaveWhitespaceChildren() const { return !isFlexibleBox(); }

  bool isOutOfFlowPositioned() const {
    return m_bitfields.isOutOfFlowPositioned();
  }  // absolute or fixed positioning
  bool isPositioned() const { return m_bitfields.isPositioned(); }

  bool isText() const { return m_bitfields.isText(); }
  bool isBox() const { return m_bitfields.isBox(); }
  bool isInline() const { return m_bitfields.isInline(); }  // inline object
  bool isDragging() const { return m_bitfields.isDragging(); }
  bool isReplaced() const {
    return m_bitfields.isReplaced();
  }  // a "replaced" element (see CSS)

  bool hasLayer() const { return m_bitfields.hasLayer(); }

  bool hasBoxDecorationBackground() const {
    return m_bitfields.hasBoxDecorationBackground();
  }
  bool hasBackground() const { return style()->hasBackground(); }
  bool hasEntirelyFixedBackground() const;

  bool needsLayoutBecauseOfChildren() const {
    return needsLayout() && !selfNeedsLayout() &&
           !needsPositionedMovementLayout() &&
           !needsSimplifiedNormalFlowLayout();
  }

  bool needsLayout() const {
    return m_bitfields.selfNeedsLayout() ||
           m_bitfields.normalChildNeedsLayout() ||
           m_bitfields.posChildNeedsLayout() ||
           m_bitfields.needsSimplifiedNormalFlowLayout() ||
           m_bitfields.needsPositionedMovementLayout();
  }

  bool selfNeedsLayout() const { return m_bitfields.selfNeedsLayout(); }
  bool needsPositionedMovementLayout() const {
    return m_bitfields.needsPositionedMovementLayout();
  }
  bool needsPositionedMovementLayoutOnly() const {
    return m_bitfields.needsPositionedMovementLayout() &&
           !m_bitfields.selfNeedsLayout() &&
           !m_bitfields.normalChildNeedsLayout() &&
           !m_bitfields.posChildNeedsLayout() &&
           !m_bitfields.needsSimplifiedNormalFlowLayout();
  }

  bool posChildNeedsLayout() const { return m_bitfields.posChildNeedsLayout(); }
  bool needsSimplifiedNormalFlowLayout() const {
    return m_bitfields.needsSimplifiedNormalFlowLayout();
  }
  bool normalChildNeedsLayout() const {
    return m_bitfields.normalChildNeedsLayout();
  }

  bool preferredLogicalWidthsDirty() const {
    return m_bitfields.preferredLogicalWidthsDirty();
  }

  bool needsOverflowRecalcAfterStyleChange() const {
    return m_bitfields.selfNeedsOverflowRecalcAfterStyleChange() ||
           m_bitfields.childNeedsOverflowRecalcAfterStyleChange();
  }
  bool selfNeedsOverflowRecalcAfterStyleChange() const {
    return m_bitfields.selfNeedsOverflowRecalcAfterStyleChange();
  }
  bool childNeedsOverflowRecalcAfterStyleChange() const {
    return m_bitfields.childNeedsOverflowRecalcAfterStyleChange();
  }

  bool isSelectionBorder() const;

  bool hasClip() const {
    return isOutOfFlowPositioned() && !style()->hasAutoClip();
  }
  bool hasOverflowClip() const { return m_bitfields.hasOverflowClip(); }
  bool hasClipOrOverflowClip() const { return hasClip() || hasOverflowClip(); }

  bool hasTransform() const { return m_bitfields.hasTransform(); }
  bool hasClipPath() const { return style() && style()->clipPath(); }

  inline bool preservesNewline() const;

  bool isRooted() const;

  // Returns the object containing this one. Can be different from parent for
  // positioned elements. If paintInvalidationContainer and
  // paintInvalidationContainerSkipped are not null, on return
  // *paintInvalidationContainerSkipped is true if the renderer returned is an
  // ancestor of paintInvalidationContainer.
  RenderObject* container(const RenderBox* paintInvalidationContainer = 0,
                          bool* paintInvalidationContainerSkipped = 0) const;

  void markContainingBlocksForLayout(bool scheduleRelayout = true,
                                     RenderObject* newRoot = 0,
                                     SubtreeLayoutScope* = 0);
  void setNeedsLayout(MarkingBehavior = MarkContainingBlockChain,
                      SubtreeLayoutScope* = 0);
  void clearNeedsLayout();
  void setChildNeedsLayout(MarkingBehavior = MarkContainingBlockChain,
                           SubtreeLayoutScope* = 0);
  void setNeedsPositionedMovementLayout();
  void setPreferredLogicalWidthsDirty(
      MarkingBehavior = MarkContainingBlockChain);
  void clearPreferredLogicalWidthsDirty();
  void invalidateContainerPreferredLogicalWidths();

  void setNeedsLayoutAndPrefWidthsRecalc() {
    setNeedsLayout();
    setPreferredLogicalWidthsDirty();
  }

  void setPositionState(EPosition position) {
    ASSERT(position != AbsolutePosition || isBox());
    m_bitfields.setPositionedState(position);
  }
  void clearPositionedState() { m_bitfields.clearPositionedState(); }

  void setInline(bool isInline) { m_bitfields.setIsInline(isInline); }

  void setIsText() { m_bitfields.setIsText(true); }
  void setIsBox() { m_bitfields.setIsBox(true); }
  void setReplaced(bool isReplaced) { m_bitfields.setIsReplaced(isReplaced); }
  void setHasOverflowClip(bool hasOverflowClip) {
    m_bitfields.setHasOverflowClip(hasOverflowClip);
  }
  void setHasLayer(bool hasLayer) { m_bitfields.setHasLayer(hasLayer); }
  void setHasTransform(bool hasTransform) {
    m_bitfields.setHasTransform(hasTransform);
  }
  void setHasBoxDecorationBackground(bool b) {
    m_bitfields.setHasBoxDecorationBackground(b);
  }

  void scheduleRelayout();

  void updateFillImages(const FillLayer* oldLayers, const FillLayer& newLayers);
  void updateImage(StyleImage*, StyleImage*);

  // paintOffset is the offset from the origin of the GraphicsContext at which
  // to paint the current object.
  virtual void paint(PaintInfo&,
                     const LayoutPoint& paintOffset,
                     Vector<RenderBox*>& layers);

  // Subclasses must reimplement this method to compute the size and position
  // of this object and all its descendants.
  virtual void layout() = 0;

  /* This function performs a layout only if one is needed. */
  void layoutIfNeeded() {
    if (needsLayout())
      layout();
  }

  void forceLayout();
  void forceChildLayout();

  bool hitTest(const HitTestRequest&,
               HitTestResult&,
               const HitTestLocation& locationInContainer,
               const LayoutPoint& accumulatedOffset);
  virtual void updateHitTestResult(HitTestResult&, const LayoutPoint&);
  virtual bool nodeAtPoint(const HitTestRequest&,
                           HitTestResult&,
                           const HitTestLocation& locationInContainer,
                           const LayoutPoint& accumulatedOffset);

  virtual PositionWithAffinity positionForPoint(const LayoutPoint&);
  PositionWithAffinity createPositionWithAffinity(int offset, EAffinity);
  PositionWithAffinity createPositionWithAffinity(const Position&);

  virtual void dirtyLinesFromChangedChild(RenderObject*);

  // Set the style of the object and update the state of the object accordingly.
  void setStyle(PassRefPtr<RenderStyle>);

  // Updates only the local style ptr of the object.  Does not update the state
  // of the object, and so only should be called when the style is known not to
  // have changed (or from setStyle).
  void setStyleInternal(PassRefPtr<RenderStyle> style) { m_style = style; }

  // returns the containing block level element for this element.
  RenderBlock* containingBlock() const;

  // Convert the given local point to absolute coordinates
  // FIXME: Temporary. If UseTransforms is true, take transforms into account.
  // Eventually localToAbsolute() will always be transform-aware.
  FloatPoint localToAbsolute(const FloatPoint& localPoint = FloatPoint(),
                             MapCoordinatesFlags = 0) const;
  FloatPoint absoluteToLocal(const FloatPoint&, MapCoordinatesFlags = 0) const;

  // Convert a local quad to absolute coordinates, taking transforms into
  // account.
  FloatQuad localToAbsoluteQuad(const FloatQuad& quad,
                                MapCoordinatesFlags mode = 0) const {
    return localToContainerQuad(quad, 0, mode);
  }
  // Convert an absolute quad to local coordinates.
  FloatQuad absoluteToLocalQuad(const FloatQuad&,
                                MapCoordinatesFlags mode = 0) const;

  // Convert a local quad into the coordinate system of container, taking
  // transforms into account.
  FloatQuad localToContainerQuad(const FloatQuad&,
                                 const RenderBox* paintInvalidatinoContainer,
                                 MapCoordinatesFlags = 0) const;
  FloatPoint localToContainerPoint(const FloatPoint&,
                                   const RenderBox* paintInvalidationContainer,
                                   MapCoordinatesFlags = 0) const;

  // Return the offset from the container() renderer (excluding transforms). In
  // multi-column layout, different offsets apply at different points, so return
  // the offset that applies to the given point.
  virtual LayoutSize offsetFromContainer(const RenderObject*,
                                         const LayoutPoint&,
                                         bool* offsetDependsOnPoint = 0) const;
  // Return the offset from an object up the container() chain. Asserts that
  // none of the intermediate objects have transforms.
  LayoutSize offsetFromAncestorContainer(const RenderObject*) const;

  IntRect absoluteBoundingBoxRect() const;

  // Build an array of quads in absolute coords for line boxes
  virtual void absoluteQuads(Vector<FloatQuad>&) const {}

  virtual LayoutUnit minPreferredLogicalWidth() const { return 0; }
  virtual LayoutUnit maxPreferredLogicalWidth() const { return 0; }

  RenderStyle* style() const { return m_style.get(); }

  /* The two following methods are inlined in RenderObjectInlines.h */
  RenderStyle* firstLineStyle() const;
  RenderStyle* style(bool firstLine) const;

  struct AppliedTextDecoration {
    Color color;
    TextDecorationStyle style;
    AppliedTextDecoration()
        : color(Color::transparent), style(TextDecorationStyleSolid) {}
  };

  void getTextDecorations(unsigned decorations,
                          AppliedTextDecoration& underline,
                          AppliedTextDecoration& overline,
                          AppliedTextDecoration& linethrough,
                          bool quirksMode = false,
                          bool firstlineStyle = false);

  // Overriden by RenderText for character length, used in line layout code.
  virtual unsigned length() const { return 1; }

  // FIXME(sky): Remove
  bool isFloatingOrOutOfFlowPositioned() const {
    return isOutOfFlowPositioned();
  }

  bool isTransparent() const { return style()->hasOpacity(); }
  float opacity() const { return style()->opacity(); }

  enum SelectionState {
    SelectionNone,    // The object is not selected.
    SelectionStart,   // The object either contains the start of a selection run
                      // or is the start of a run
    SelectionInside,  // The object is fully encompassed by a selection run
    SelectionEnd,  // The object either contains the end of a selection run or
                   // is the end of a run
    SelectionBoth  // The object contains an entire run or is the sole selected
                   // object in that run
  };

  // The current selection state for an object.  For blocks, the state refers to
  // the state of the leaf descendants (as described above in the SelectionState
  // enum declaration).
  SelectionState selectionState() const { return m_bitfields.selectionState(); }
  virtual void setSelectionState(SelectionState state) {
    m_bitfields.setSelectionState(state);
  }
  inline void setSelectionStateIfNeeded(SelectionState);
  bool canUpdateSelectionOnRootLineBoxes();

  virtual bool canBeSelectionLeaf() const { return false; }
  bool hasSelectedChildren() const { return selectionState() != SelectionNone; }

  bool isSelectable() const;
  // Obtains the selection colors that should be used when painting a selection.
  Color selectionBackgroundColor() const;
  Color selectionForegroundColor() const;
  Color selectionEmphasisMarkColor() const;

  // Whether or not a given block needs to paint selection gaps.
  virtual bool shouldPaintSelectionGaps() const { return false; }

  /**
   * Returns the local coordinates of the caret within this render object.
   * @param caretOffset zero-based offset determining position within the render
   * object.
   * @param extraWidthToEndOfLine optional out arg to give extra width to end of
   * line - useful for character range rect computations
   */
  virtual LayoutRect localCaretRect(InlineBox*,
                                    int caretOffset,
                                    LayoutUnit* extraWidthToEndOfLine = 0);

  // When performing a global document tear-down, the renderer of the document
  // is cleared. We use this as a hook to detect the case of document
  // destruction and don't waste time doing unnecessary work.
  bool documentBeingDestroyed() const;

  virtual void destroy();

  // Virtual function helper for the new FlexibleBox Layout (display:
  // -webkit-flex).
  virtual bool isFlexibleBox() const { return false; }

  virtual int caretMinOffset() const;
  virtual int caretMaxOffset() const;

  virtual int previousOffset(int current) const;
  virtual int previousOffsetForBackwardDeletion(int current) const;
  virtual int nextOffset(int current) const;

  void selectionStartEnd(int& spos, int& epos) const;

  void remove() {
    if (parent())
      parent()->removeChild(this);
  }

  bool supportsTouchAction() const;

  bool visibleToHitTestRequest(const HitTestRequest& request) const {
    return (request.ignorePointerEventsNone() ||
            style()->pointerEvents() != PE_NONE);
  }

  bool visibleToHitTesting() const {
    return style()->pointerEvents() != PE_NONE;
  }

  // Map points and quads through elements, potentially via 3d transforms. You
  // should never need to call these directly; use
  // localToAbsolute/absoluteToLocal methods instead.
  virtual void mapLocalToContainer(
      const RenderBox* paintInvalidationContainer,
      TransformState&,
      MapCoordinatesFlags = ApplyContainerFlip) const;
  virtual void mapAbsoluteToLocalPoint(MapCoordinatesFlags,
                                       TransformState&) const;

  // Pushes state onto RenderGeometryMap about how to map coordinates from this
  // renderer to its container, or ancestorToStopAt (whichever is encountered
  // first). Returns the renderer which was mapped to (container or
  // ancestorToStopAt).
  virtual const RenderObject* pushMappingToContainer(
      const RenderBox* ancestorToStopAt,
      RenderGeometryMap&) const;

  bool shouldUseTransformFromContainer(const RenderObject* container) const;
  void getTransformFromContainer(const RenderObject* container,
                                 const LayoutSize& offsetInContainer,
                                 TransformationMatrix&) const;

  bool createsGroup() const { return isTransparent(); }

  virtual void addFocusRingRects(
      Vector<IntRect>&,
      const LayoutPoint& /* additionalOffset */,
      const RenderBox* /* paintContainer */ = 0) const {};

  RespectImageOrientationEnum shouldRespectImageOrientation() const;

  bool onlyNeededPositionedMovementLayout() const {
    return m_bitfields.onlyNeededPositionedMovementLayout();
  }
  void setOnlyNeededPositionedMovementLayout(bool b) {
    m_bitfields.setOnlyNeededPositionedMovementLayout(b);
  }

  bool neededLayoutBecauseOfChildren() const {
    return m_bitfields.neededLayoutBecauseOfChildren();
  }
  void setNeededLayoutBecauseOfChildren(bool b) {
    m_bitfields.setNeededLayoutBecauseOfChildren(b);
  }

  void setNeedsOverflowRecalcAfterStyleChange();
  void markContainingBlocksForOverflowRecalc();

 protected:
  // Overrides should call the superclass at the end. m_style will be 0 the
  // first time this function will be called.
  virtual void styleWillChange(StyleDifference, const RenderStyle& newStyle);
  // Overrides should call the superclass at the start. |oldStyle| will be 0 the
  // first time this function is called.
  virtual void styleDidChange(StyleDifference, const RenderStyle* oldStyle);

  void drawLineForBoxSide(GraphicsContext*,
                          int x1,
                          int y1,
                          int x2,
                          int y2,
                          BoxSide,
                          Color,
                          EBorderStyle,
                          int adjbw1,
                          int adjbw2,
                          bool antialias = false);
  void drawDashedOrDottedBoxSide(GraphicsContext*,
                                 int x1,
                                 int y1,
                                 int x2,
                                 int y2,
                                 BoxSide,
                                 Color,
                                 int thickness,
                                 EBorderStyle,
                                 bool antialias);
  void drawDoubleBoxSide(GraphicsContext*,
                         int x1,
                         int y1,
                         int x2,
                         int y2,
                         int length,
                         BoxSide,
                         Color,
                         int thickness,
                         int adjacentWidth1,
                         int adjacentWidth2,
                         bool antialias);
  void drawRidgeOrGrooveBoxSide(GraphicsContext*,
                                int x1,
                                int y1,
                                int x2,
                                int y2,
                                BoxSide,
                                Color,
                                EBorderStyle,
                                int adjacentWidth1,
                                int adjacentWidth2,
                                bool antialias);
  void drawSolidBoxSide(GraphicsContext*,
                        int x1,
                        int y1,
                        int x2,
                        int y2,
                        BoxSide,
                        Color,
                        int adjacentWidth1,
                        int adjacentWidth2,
                        bool antialias);

  void addChildFocusRingRects(Vector<IntRect>&,
                              const LayoutPoint& additionalOffset,
                              const RenderBox* paintContainer) const;

  void clearLayoutRootIfNeeded() const;
  virtual void willBeDestroyed();
  void postDestroy();

  void insertedIntoTree();
  void willBeRemovedFromTree();

 private:
  bool hasImmediateNonWhitespaceTextChildOrPropertiesDependentOnColor() const;

  StyleDifference adjustStyleDifference(StyleDifference) const;

  Color selectionColor() const;

#if ENABLE(ASSERT)
  void checkBlockPositionedObjectsNeedLayout();
#endif

  // FIXME(sky): This method is just to avoid copy-paste.
  // Merge container into containingBlock and then get rid of this method.
  bool canContainAbsolutePositionObjects() const {
    return isRenderView() || (hasTransform() && isRenderBlock());
  }

  RefPtr<RenderStyle> m_style;

  RawPtr<RenderObject> m_parent;
  RawPtr<RenderObject> m_previous;
  RawPtr<RenderObject> m_next;

#if ENABLE(ASSERT)
  unsigned m_setNeedsLayoutForbidden : 1;
#if ENABLE(OILPAN)
 protected:
  unsigned m_didCallDestroy : 1;

 private:
#endif
#endif

#define ADD_BOOLEAN_BITFIELD(name, Name) \
 private:                                \
  unsigned m_##name : 1;                 \
                                         \
 public:                                 \
  bool name() const { return m_##name; } \
  void set##Name(bool name) { m_##name = name; }

  class RenderObjectBitfields {
    // FIXME(sky): Remove this enum and just use EPosition directly.
    enum PositionedState {
      IsStaticallyPositioned = 0,
      IsOutOfFlowPositioned = 1,
    };

   public:
    RenderObjectBitfields()
        : m_selfNeedsLayout(false),
          m_onlyNeededPositionedMovementLayout(false),
          m_neededLayoutBecauseOfChildren(false),
          m_needsPositionedMovementLayout(false),
          m_normalChildNeedsLayout(false),
          m_posChildNeedsLayout(false),
          m_needsSimplifiedNormalFlowLayout(false),
          m_preferredLogicalWidthsDirty(false),
          m_selfNeedsOverflowRecalcAfterStyleChange(false),
          m_childNeedsOverflowRecalcAfterStyleChange(false),
          m_isText(false),
          m_isBox(false),
          m_isInline(true),
          m_isReplaced(false),
          m_isDragging(false),
          m_hasLayer(false),
          m_hasOverflowClip(false),
          m_hasTransform(false),
          m_hasBoxDecorationBackground(false),
          m_everHadLayout(false),
          m_ancestorLineBoxDirty(false),
          m_alwaysCreateLineBoxesForRenderInline(false),
          m_positionedState(IsStaticallyPositioned),
          m_selectionState(SelectionNone) {}

    // 32 bits have been used in the first word, and 11 in the second.
    ADD_BOOLEAN_BITFIELD(selfNeedsLayout, SelfNeedsLayout);
    ADD_BOOLEAN_BITFIELD(onlyNeededPositionedMovementLayout,
                         OnlyNeededPositionedMovementLayout);
    ADD_BOOLEAN_BITFIELD(neededLayoutBecauseOfChildren,
                         NeededLayoutBecauseOfChildren);
    ADD_BOOLEAN_BITFIELD(needsPositionedMovementLayout,
                         NeedsPositionedMovementLayout);
    ADD_BOOLEAN_BITFIELD(normalChildNeedsLayout, NormalChildNeedsLayout);
    ADD_BOOLEAN_BITFIELD(posChildNeedsLayout, PosChildNeedsLayout);
    ADD_BOOLEAN_BITFIELD(needsSimplifiedNormalFlowLayout,
                         NeedsSimplifiedNormalFlowLayout);
    ADD_BOOLEAN_BITFIELD(preferredLogicalWidthsDirty,
                         PreferredLogicalWidthsDirty);
    ADD_BOOLEAN_BITFIELD(selfNeedsOverflowRecalcAfterStyleChange,
                         SelfNeedsOverflowRecalcAfterStyleChange);
    ADD_BOOLEAN_BITFIELD(childNeedsOverflowRecalcAfterStyleChange,
                         ChildNeedsOverflowRecalcAfterStyleChange);

    ADD_BOOLEAN_BITFIELD(isText, IsText);
    ADD_BOOLEAN_BITFIELD(isBox, IsBox);
    ADD_BOOLEAN_BITFIELD(isInline, IsInline);
    ADD_BOOLEAN_BITFIELD(isReplaced, IsReplaced);
    ADD_BOOLEAN_BITFIELD(isDragging, IsDragging);

    ADD_BOOLEAN_BITFIELD(hasLayer, HasLayer);
    ADD_BOOLEAN_BITFIELD(
        hasOverflowClip,
        HasOverflowClip);  // Set in the case of overflow:auto/scroll/hidden
    ADD_BOOLEAN_BITFIELD(hasTransform, HasTransform);
    ADD_BOOLEAN_BITFIELD(hasBoxDecorationBackground,
                         HasBoxDecorationBackground);

    ADD_BOOLEAN_BITFIELD(everHadLayout, EverHadLayout);
    ADD_BOOLEAN_BITFIELD(ancestorLineBoxDirty, AncestorLineBoxDirty);

    // from RenderInline
    ADD_BOOLEAN_BITFIELD(alwaysCreateLineBoxesForRenderInline,
                         AlwaysCreateLineBoxesForRenderInline);

   private:
    unsigned m_positionedState : 1;  // PositionedState
    unsigned m_selectionState : 3;   // SelectionState

   public:
    bool isOutOfFlowPositioned() const {
      return m_positionedState == IsOutOfFlowPositioned;
    }
    bool isPositioned() const {
      return m_positionedState != IsStaticallyPositioned;
    }

    void setPositionedState(int positionState) {
      m_positionedState = static_cast<PositionedState>(positionState);
    }
    void clearPositionedState() { m_positionedState = StaticPosition; }

    ALWAYS_INLINE SelectionState selectionState() const {
      return static_cast<SelectionState>(m_selectionState);
    }
    ALWAYS_INLINE void setSelectionState(SelectionState selectionState) {
      m_selectionState = selectionState;
    }
  };

#undef ADD_BOOLEAN_BITFIELD

  RenderObjectBitfields m_bitfields;

  void setSelfNeedsLayout(bool b) { m_bitfields.setSelfNeedsLayout(b); }
  void setNeedsPositionedMovementLayout(bool b) {
    m_bitfields.setNeedsPositionedMovementLayout(b);
  }
  void setNormalChildNeedsLayout(bool b) {
    m_bitfields.setNormalChildNeedsLayout(b);
  }
  void setPosChildNeedsLayout(bool b) { m_bitfields.setPosChildNeedsLayout(b); }
  void setNeedsSimplifiedNormalFlowLayout(bool b) {
    m_bitfields.setNeedsSimplifiedNormalFlowLayout(b);
  }
  void setIsDragging(bool b) { m_bitfields.setIsDragging(b); }
  void setEverHadLayout(bool b) { m_bitfields.setEverHadLayout(b); }
  void setSelfNeedsOverflowRecalcAfterStyleChange(bool b) {
    m_bitfields.setSelfNeedsOverflowRecalcAfterStyleChange(b);
  }
  void setChildNeedsOverflowRecalcAfterStyleChange(bool b) {
    m_bitfields.setChildNeedsOverflowRecalcAfterStyleChange(b);
  }

 private:
  // Store state between styleWillChange and styleDidChange
  static bool s_affectsParentBlock;

  static unsigned s_instanceCount;
};

// Allow equality comparisons of RenderObjects by reference or pointer,
// interchangeably.
DEFINE_COMPARISON_OPERATORS_WITH_REFERENCES(RenderObject)

inline bool RenderObject::documentBeingDestroyed() const {
  return false;
}

// setNeedsLayout() won't cause full paint invalidations as
// setNeedsLayout() does. Otherwise the two methods are identical.
inline void RenderObject::setNeedsLayout(MarkingBehavior markParents,
                                         SubtreeLayoutScope* layouter) {
  ASSERT(!isSetNeedsLayoutForbidden());
  bool alreadyNeededLayout = m_bitfields.selfNeedsLayout();
  setSelfNeedsLayout(true);
  if (!alreadyNeededLayout) {
    if (markParents == MarkContainingBlockChain &&
        (!layouter || layouter->root() != this))
      markContainingBlocksForLayout(true, 0, layouter);
  }
}

inline void RenderObject::clearNeedsLayout() {
  setOnlyNeededPositionedMovementLayout(needsPositionedMovementLayoutOnly());
  setNeededLayoutBecauseOfChildren(needsLayoutBecauseOfChildren());
  setSelfNeedsLayout(false);
  setEverHadLayout(true);
  setPosChildNeedsLayout(false);
  setNeedsSimplifiedNormalFlowLayout(false);
  setNormalChildNeedsLayout(false);
  setNeedsPositionedMovementLayout(false);
  setAncestorLineBoxDirty(false);
#if ENABLE(ASSERT)
  checkBlockPositionedObjectsNeedLayout();
#endif
}

inline void RenderObject::setChildNeedsLayout(MarkingBehavior markParents,
                                              SubtreeLayoutScope* layouter) {
  ASSERT(!isSetNeedsLayoutForbidden());
  bool alreadyNeededLayout = normalChildNeedsLayout();
  setNormalChildNeedsLayout(true);
  // FIXME: Replace MarkOnlyThis with the SubtreeLayoutScope code path and
  // remove the MarkingBehavior argument entirely.
  if (!alreadyNeededLayout && markParents == MarkContainingBlockChain &&
      (!layouter || layouter->root() != this))
    markContainingBlocksForLayout(true, 0, layouter);
}

inline void RenderObject::setNeedsPositionedMovementLayout() {
  bool alreadyNeededLayout = needsPositionedMovementLayout();
  setNeedsPositionedMovementLayout(true);
  ASSERT(!isSetNeedsLayoutForbidden());
  if (!alreadyNeededLayout)
    markContainingBlocksForLayout();
}

inline bool RenderObject::preservesNewline() const {
  return style()->preserveNewline();
}

inline void RenderObject::setSelectionStateIfNeeded(SelectionState state) {
  if (selectionState() == state)
    return;

  setSelectionState(state);
}

#define DEFINE_RENDER_OBJECT_TYPE_CASTS(thisType, predicate)           \
  DEFINE_TYPE_CASTS(thisType, RenderObject, object, object->predicate, \
                    object.predicate)

}  // namespace blink

#ifndef NDEBUG
// Outside the WebCore namespace for ease of invocation from gdb.
void showTree(const blink::RenderObject*);
void showLineTree(const blink::RenderObject*);
void showRenderTree(const blink::RenderObject* object1);
// We don't make object2 an optional parameter so that showRenderTree
// can be called from gdb easily.
void showRenderTree(const blink::RenderObject* object1,
                    const blink::RenderObject* object2);

#endif

#endif  // SKY_ENGINE_CORE_RENDERING_RENDEROBJECT_H_
