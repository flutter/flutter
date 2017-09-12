/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 *           (C) 1999 Antti Koivisto (koivisto@kde.org)
 * Copyright (C) 2003, 2004, 2005, 2006, 2007, 2008, 2009 Apple Inc.
 * All rights reserved.
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

#ifndef SKY_ENGINE_CORE_RENDERING_RENDERINLINE_H_
#define SKY_ENGINE_CORE_RENDERING_RENDERINLINE_H_

#include "flutter/sky/engine/core/rendering/InlineFlowBox.h"
#include "flutter/sky/engine/core/rendering/RenderBoxModelObject.h"
#include "flutter/sky/engine/core/rendering/RenderLineBoxList.h"

namespace blink {

class RenderInline : public RenderBoxModelObject {
 public:
  explicit RenderInline();

  RenderObject* firstChild() const {
    ASSERT(children() == virtualChildren());
    return children()->firstChild();
  }
  RenderObject* lastChild() const {
    ASSERT(children() == virtualChildren());
    return children()->lastChild();
  }

  // If you have a RenderInline, use firstChild or lastChild instead.
  void slowFirstChild() const = delete;
  void slowLastChild() const = delete;

  virtual void addChild(RenderObject* newChild,
                        RenderObject* beforeChild = 0) override;

  virtual LayoutUnit marginLeft() const override final;
  virtual LayoutUnit marginRight() const override final;
  virtual LayoutUnit marginTop() const override final;
  virtual LayoutUnit marginBottom() const override final;
  virtual LayoutUnit marginBefore(
      const RenderStyle* otherStyle = 0) const override final;
  virtual LayoutUnit marginAfter(
      const RenderStyle* otherStyle = 0) const override final;
  virtual LayoutUnit marginStart(
      const RenderStyle* otherStyle = 0) const override final;
  virtual LayoutUnit marginEnd(
      const RenderStyle* otherStyle = 0) const override final;

  virtual void absoluteQuads(Vector<FloatQuad>&) const override;

  IntRect linesBoundingBox() const;
  LayoutRect linesVisualOverflowBoundingBox() const;

  InlineFlowBox* createAndAppendInlineFlowBox();

  void dirtyLineBoxes(bool fullLayout);
  void deleteLineBoxTree();

  RenderLineBoxList* lineBoxes() { return &m_lineBoxes; }
  const RenderLineBoxList* lineBoxes() const { return &m_lineBoxes; }

  InlineFlowBox* firstLineBox() const { return m_lineBoxes.firstLineBox(); }
  InlineFlowBox* lastLineBox() const { return m_lineBoxes.lastLineBox(); }
  InlineBox* firstLineBoxIncludingCulling() const {
    return alwaysCreateLineBoxes() ? firstLineBox()
                                   : culledInlineFirstLineBox();
  }
  InlineBox* lastLineBoxIncludingCulling() const {
    return alwaysCreateLineBoxes() ? lastLineBox() : culledInlineLastLineBox();
  }

  virtual void addFocusRingRects(
      Vector<IntRect>&,
      const LayoutPoint& additionalOffset,
      const RenderBox* paintContainer = 0) const override final;

  bool alwaysCreateLineBoxes() const {
    return alwaysCreateLineBoxesForRenderInline();
  }
  void setAlwaysCreateLineBoxes(bool alwaysCreateLineBoxes = true) {
    setAlwaysCreateLineBoxesForRenderInline(alwaysCreateLineBoxes);
  }
  void updateAlwaysCreateLineBoxes(bool fullLayout);

  virtual LayoutRect localCaretRect(
      InlineBox*,
      int,
      LayoutUnit* extraWidthToEndOfLine) override final;

  bool hitTestCulledInline(const HitTestRequest&,
                           HitTestResult&,
                           const HitTestLocation& locationInContainer,
                           const LayoutPoint& accumulatedOffset);

 protected:
  virtual void willBeDestroyed() override;

  virtual void styleDidChange(StyleDifference,
                              const RenderStyle* oldStyle) override;

 private:
  virtual RenderObjectChildList* virtualChildren() override final {
    return children();
  }
  virtual const RenderObjectChildList* virtualChildren() const override final {
    return children();
  }
  const RenderObjectChildList* children() const { return &m_children; }
  RenderObjectChildList* children() { return &m_children; }

  virtual const char* renderName() const override;

  virtual bool isRenderInline() const override final { return true; }

  LayoutRect culledInlineVisualOverflowBoundingBox() const;
  InlineBox* culledInlineFirstLineBox() const;
  InlineBox* culledInlineLastLineBox() const;

  template <typename GeneratorContext>
  void generateLineBoxRects(GeneratorContext& yield) const;
  template <typename GeneratorContext>
  void generateCulledLineBoxRects(GeneratorContext& yield,
                                  const RenderInline* container) const;

  virtual void layout() override final {
    ASSERT_NOT_REACHED();
  }  // Do nothing for layout()

  virtual void paint(PaintInfo&,
                     const LayoutPoint&,
                     Vector<RenderBox*>& layers) override final;

  virtual bool nodeAtPoint(const HitTestRequest&,
                           HitTestResult&,
                           const HitTestLocation& locationInContainer,
                           const LayoutPoint& accumulatedOffset) override final;

  virtual LayoutUnit offsetLeft() const override final;
  virtual LayoutUnit offsetTop() const override final;
  virtual LayoutUnit offsetWidth() const override final {
    return linesBoundingBox().width();
  }
  virtual LayoutUnit offsetHeight() const override final {
    return linesBoundingBox().height();
  }

  virtual void mapLocalToContainer(
      const RenderBox* paintInvalidationContainer,
      TransformState&,
      MapCoordinatesFlags = ApplyContainerFlip) const override;

  virtual PositionWithAffinity positionForPoint(
      const LayoutPoint&) override final;

  virtual IntRect borderBoundingBox() const override final {
    IntRect boundingBox = linesBoundingBox();
    return IntRect(0, 0, boundingBox.width(), boundingBox.height());
  }

  virtual InlineFlowBox* createInlineFlowBox();  // Subclassed by SVG and Ruby

  virtual void dirtyLinesFromChangedChild(RenderObject* child) override final {
    m_lineBoxes.dirtyLinesFromChangedChild(this, child);
  }

  virtual LayoutUnit lineHeight(
      bool firstLine,
      LineDirectionMode,
      LinePositionMode = PositionOnContainingLine) const override final;
  virtual int baselinePosition(
      FontBaseline,
      bool firstLine,
      LineDirectionMode,
      LinePositionMode = PositionOnContainingLine) const override final;

  virtual void updateHitTestResult(HitTestResult&,
                                   const LayoutPoint&) override final;

  RenderObjectChildList m_children;
  RenderLineBoxList m_lineBoxes;  // All of the line boxes created for this
                                  // inline flow.  For example,
                                  // <i>Hello<br>world.</i> will have two <i>
                                  // line boxes.
};

DEFINE_RENDER_OBJECT_TYPE_CASTS(RenderInline, isRenderInline());

}  // namespace blink

#endif  // SKY_ENGINE_CORE_RENDERING_RENDERINLINE_H_
