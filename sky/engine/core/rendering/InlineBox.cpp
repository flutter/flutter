/*
 * Copyright (C) 2003, 2004, 2005, 2006, 2007 Apple Inc. All rights reserved.
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
 */

#include "flutter/sky/engine/core/rendering/InlineBox.h"

#include "flutter/sky/engine/core/rendering/InlineFlowBox.h"
#include "flutter/sky/engine/core/rendering/PaintInfo.h"
#include "flutter/sky/engine/core/rendering/RenderObjectInlines.h"
#include "flutter/sky/engine/core/rendering/RenderParagraph.h"
#include "flutter/sky/engine/core/rendering/RootInlineBox.h"
#include "flutter/sky/engine/platform/Partitions.h"
#include "flutter/sky/engine/platform/fonts/FontMetrics.h"

#ifndef NDEBUG
#include <stdio.h>
#endif

namespace blink {

struct SameSizeAsInlineBox {
  virtual ~SameSizeAsInlineBox() {}
  void* a[4];
  FloatPoint b;
  float c;
  uint32_t d : 32;
#if ENABLE(ASSERT)
  bool f;
#endif
};

COMPILE_ASSERT(sizeof(InlineBox) == sizeof(SameSizeAsInlineBox),
               InlineBox_size_guard);

#if ENABLE(ASSERT)

InlineBox::~InlineBox() {
  if (!m_hasBadParent && m_parent)
    m_parent->setHasBadChildList();
}

#endif

void InlineBox::remove(MarkLineBoxes markLineBoxes) {
  if (parent())
    parent()->removeChild(this, markLineBoxes);
}

void* InlineBox::operator new(size_t sz) {
  return partitionAlloc(Partitions::getRenderingPartition(), sz);
}

void InlineBox::operator delete(void* ptr) {
  partitionFree(ptr);
}

#ifndef NDEBUG
const char* InlineBox::boxName() const {
  return "InlineBox";
}

void InlineBox::showTreeForThis() const {
  renderer().showTreeForThis();
}

void InlineBox::showLineTreeForThis() const {
  renderer().containingBlock()->showLineTreeAndMark(this, "*");
}

void InlineBox::showLineTreeAndMark(const InlineBox* markedBox1,
                                    const char* markedLabel1,
                                    const InlineBox* markedBox2,
                                    const char* markedLabel2,
                                    const RenderObject* obj,
                                    int depth) const {
  int printedCharacters = 0;
  if (this == markedBox1)
    printedCharacters += fprintf(stderr, "%s", markedLabel1);
  if (this == markedBox2)
    printedCharacters += fprintf(stderr, "%s", markedLabel2);
  if (&renderer() == obj)
    printedCharacters += fprintf(stderr, "*");
  for (; printedCharacters < depth * 2; printedCharacters++)
    fputc(' ', stderr);

  showBox(printedCharacters);
}

void InlineBox::showBox(int printedCharacters) const {
  printedCharacters += fprintf(stderr, "%s\t%p", boxName(), this);
  for (; printedCharacters < showTreeCharacterOffset; printedCharacters++)
    fputc(' ', stderr);
  fprintf(stderr, "\t%s %p {pos=%g,%g size=%g,%g} baseline=%i/%i\n",
          renderer().renderName(), &renderer(), x(), y(), width(), height(),
          baselinePosition(AlphabeticBaseline),
          baselinePosition(IdeographicBaseline));
}
#endif

float InlineBox::logicalHeight() const {
  if (hasVirtualLogicalHeight())
    return virtualLogicalHeight();

  if (renderer().isText())
    return m_bitfields.isText()
               ? renderer().style(isFirstLineStyle())->fontMetrics().height()
               : 0;
  if (renderer().isBox() && parent())
    return toRenderBox(renderer()).height().toFloat();

  ASSERT(isInlineFlowBox());
  RenderBoxModelObject* flowObject = boxModelObject();
  const FontMetrics& fontMetrics =
      renderer().style(isFirstLineStyle())->fontMetrics();
  float result = fontMetrics.height();
  if (parent())
    result += flowObject->borderAndPaddingLogicalHeight();
  return result;
}

int InlineBox::baselinePosition(FontBaseline baselineType) const {
  return boxModelObject()->baselinePosition(
      baselineType, m_bitfields.firstLine(), HorizontalLine,
      PositionOnContainingLine);
}

LayoutUnit InlineBox::lineHeight() const {
  return boxModelObject()->lineHeight(m_bitfields.firstLine(), HorizontalLine,
                                      PositionOnContainingLine);
}

int InlineBox::caretMinOffset() const {
  return renderer().caretMinOffset();
}

int InlineBox::caretMaxOffset() const {
  return renderer().caretMaxOffset();
}

void InlineBox::dirtyLineBoxes() {
  markDirty();
  for (InlineFlowBox* curr = parent(); curr && !curr->isDirty();
       curr = curr->parent())
    curr->markDirty();
}

void InlineBox::deleteLine() {
  if (!m_bitfields.extracted() && renderer().isBox())
    toRenderBox(renderer()).setInlineBoxWrapper(0);
  destroy();
}

void InlineBox::extractLine() {
  m_bitfields.setExtracted(true);
  if (renderer().isBox())
    toRenderBox(renderer()).setInlineBoxWrapper(0);
}

void InlineBox::attachLine() {
  m_bitfields.setExtracted(false);
  if (renderer().isBox())
    toRenderBox(renderer()).setInlineBoxWrapper(this);
}

void InlineBox::adjustPosition(float dx, float dy) {
  m_topLeft.move(dx, dy);

  if (renderer().isReplaced())
    toRenderBox(renderer()).move(dx, dy);
}

void InlineBox::paint(PaintInfo& paintInfo,
                      const LayoutPoint& paintOffset,
                      LayoutUnit /* lineTop */,
                      LayoutUnit /*lineBottom*/,
                      Vector<RenderBox*>& layers) {
  renderer().paint(paintInfo, paintOffset, layers);
}

bool InlineBox::nodeAtPoint(const HitTestRequest& request,
                            HitTestResult& result,
                            const HitTestLocation& locationInContainer,
                            const LayoutPoint& accumulatedOffset,
                            LayoutUnit /* lineTop */,
                            LayoutUnit /*lineBottom*/) {
  // Hit test all phases of replaced elements atomically, as though the replaced
  // element established its own stacking context.  (See Appendix E.2,
  // section 6.4 on inline block/table elements in the CSS2.1 specification.)
  LayoutPoint childPoint = accumulatedOffset;
  return renderer().hitTest(request, result, locationInContainer, childPoint);
}

const RootInlineBox& InlineBox::root() const {
  if (m_parent)
    return m_parent->root();
  ASSERT(isRootInlineBox());
  return static_cast<const RootInlineBox&>(*this);
}

RootInlineBox& InlineBox::root() {
  if (m_parent)
    return m_parent->root();
  ASSERT(isRootInlineBox());
  return static_cast<RootInlineBox&>(*this);
}

bool InlineBox::nextOnLineExists() const {
  if (!m_bitfields.determinedIfNextOnLineExists()) {
    m_bitfields.setDeterminedIfNextOnLineExists(true);

    if (!parent())
      m_bitfields.setNextOnLineExists(false);
    else if (nextOnLine())
      m_bitfields.setNextOnLineExists(true);
    else
      m_bitfields.setNextOnLineExists(parent()->nextOnLineExists());
  }
  return m_bitfields.nextOnLineExists();
}

InlineBox* InlineBox::nextLeafChild() const {
  InlineBox* leaf = 0;
  for (InlineBox* box = nextOnLine(); box && !leaf; box = box->nextOnLine())
    leaf = box->isLeaf() ? box : toInlineFlowBox(box)->firstLeafChild();
  if (!leaf && parent())
    leaf = parent()->nextLeafChild();
  return leaf;
}

InlineBox* InlineBox::prevLeafChild() const {
  InlineBox* leaf = 0;
  for (InlineBox* box = prevOnLine(); box && !leaf; box = box->prevOnLine())
    leaf = box->isLeaf() ? box : toInlineFlowBox(box)->lastLeafChild();
  if (!leaf && parent())
    leaf = parent()->prevLeafChild();
  return leaf;
}

InlineBox* InlineBox::nextLeafChildIgnoringLineBreak() const {
  InlineBox* leaf = nextLeafChild();
  if (leaf && leaf->isLineBreak())
    return 0;
  return leaf;
}

InlineBox* InlineBox::prevLeafChildIgnoringLineBreak() const {
  InlineBox* leaf = prevLeafChild();
  if (leaf && leaf->isLineBreak())
    return 0;
  return leaf;
}

RenderObject::SelectionState InlineBox::selectionState() {
  return renderer().selectionState();
}

void InlineBox::clearKnownToHaveNoOverflow() {
  m_bitfields.setKnownToHaveNoOverflow(false);
  if (parent() && parent()->knownToHaveNoOverflow())
    parent()->clearKnownToHaveNoOverflow();
}

FloatPoint InlineBox::locationIncludingFlipping() {
  // FIXME(sky): remove
  return FloatPoint(x(), y());
}

}  // namespace blink

#ifndef NDEBUG

void showTree(const blink::InlineBox* b) {
  if (b)
    b->showTreeForThis();
}

void showLineTree(const blink::InlineBox* b) {
  if (b)
    b->showLineTreeForThis();
}

#endif
