/*
 * (C) 1999 Lars Knoll (knoll@kde.org)
 * (C) 2000 Dirk Mueller (mueller@kde.org)
 * Copyright (C) 2004-2009, 2013 Apple Inc. All rights reserved.
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

#ifndef SKY_ENGINE_CORE_RENDERING_RENDERTEXT_H_
#define SKY_ENGINE_CORE_RENDERING_RENDERTEXT_H_

#include <vector>

#include "flutter/sky/engine/core/rendering/RenderObject.h"
#include "flutter/sky/engine/platform/LengthFunctions.h"
#include "flutter/sky/engine/platform/text/TextPath.h"
#include "flutter/sky/engine/wtf/Forward.h"
#include "flutter/sky/engine/wtf/PassRefPtr.h"

namespace blink {
class InlineTextBox;
class TextBox;

class RenderText : public RenderObject {
 public:
  // FIXME: If the node argument is not a Text node or the string argument is
  // not the content of the Text node, updating text-transform property
  // doesn't re-transform the string.
  RenderText(PassRefPtr<StringImpl>);
#if ENABLE(ASSERT)
  virtual ~RenderText();
#endif

  virtual const char* renderName() const override;

  void extractTextBox(InlineTextBox*);
  void attachTextBox(InlineTextBox*);
  void removeTextBox(InlineTextBox*);

  const String& text() const { return m_text; }
  virtual unsigned textStartOffset() const { return 0; }

  InlineTextBox* createInlineTextBox();
  void dirtyLineBoxes(bool fullLayout);

  void appendAbsoluteTextBoxesForRange(std::vector<TextBox>&,
                                       unsigned startOffset = 0,
                                       unsigned endOffset = INT_MAX);

  virtual void absoluteQuads(Vector<FloatQuad>&) const override final;
  void absoluteQuadsForRange(Vector<FloatQuad>&,
                             unsigned startOffset = 0,
                             unsigned endOffset = INT_MAX,
                             bool useSelectionHeight = false);

  enum ClippingOption { NoClipping, ClipToEllipsis };
  void absoluteQuads(Vector<FloatQuad>&, ClippingOption = NoClipping) const;

  virtual PositionWithAffinity positionForPoint(const LayoutPoint&) override;

  bool is8Bit() const { return m_text.is8Bit(); }
  const LChar* characters8() const { return m_text.impl()->characters8(); }
  const UChar* characters16() const { return m_text.impl()->characters16(); }
  bool hasEmptyText() const { return m_text.isEmpty(); }
  String substring(unsigned position, unsigned length) const {
    return m_text.substring(position, length);
  }
  UChar characterAt(unsigned) const;
  UChar uncheckedCharacterAt(unsigned) const;
  UChar operator[](unsigned i) const { return uncheckedCharacterAt(i); }
  unsigned textLength() const {
    return m_text.length();
  }  // non virtual implementation of length()
  void positionLineBox(InlineBox*);

  virtual float width(unsigned from,
                      unsigned len,
                      const Font&,
                      float xPos,
                      TextDirection,
                      HashSet<const SimpleFontData*>* fallbackFonts = 0,
                      GlyphOverflow* = 0) const;
  virtual float width(unsigned from,
                      unsigned len,
                      float xPos,
                      TextDirection,
                      bool firstLine = false,
                      HashSet<const SimpleFontData*>* fallbackFonts = 0,
                      GlyphOverflow* = 0) const;

  float minLogicalWidth() const;
  float maxLogicalWidth() const;

  void trimmedPrefWidths(float leadWidth,
                         float& firstLineMinWidth,
                         bool& hasBreakableStart,
                         float& lastLineMinWidth,
                         bool& hasBreakableEnd,
                         bool& hasBreakableChar,
                         bool& hasBreak,
                         float& firstLineMaxWidth,
                         float& lastLineMaxWidth,
                         float& minWidth,
                         float& maxWidth,
                         bool& stripFrontSpaces,
                         TextDirection);

  virtual IntRect linesBoundingBox() const;
  LayoutRect linesVisualOverflowBoundingBox() const;

  FloatPoint firstRunOrigin() const;
  float firstRunX() const;
  float firstRunY() const;

  virtual void setText(PassRefPtr<StringImpl>, bool force = false);
  void setTextWithOffset(PassRefPtr<StringImpl>,
                         unsigned offset,
                         unsigned len,
                         bool force = false);

  virtual bool canBeSelectionLeaf() const override { return true; }
  virtual void setSelectionState(SelectionState s) override final;
  virtual LayoutRect localCaretRect(
      InlineBox*,
      int caretOffset,
      LayoutUnit* extraWidthToEndOfLine = 0) override;

  LayoutUnit marginLeft() const {
    return minimumValueForLength(style()->marginLeft(), 0);
  }
  LayoutUnit marginRight() const {
    return minimumValueForLength(style()->marginRight(), 0);
  }

  InlineTextBox* firstTextBox() const { return m_firstTextBox; }
  InlineTextBox* lastTextBox() const { return m_lastTextBox; }

  virtual int caretMinOffset() const override;
  virtual int caretMaxOffset() const override;
  unsigned renderedTextLength() const;

  virtual int previousOffset(int current) const override final;
  virtual int previousOffsetForBackwardDeletion(
      int current) const override final;
  virtual int nextOffset(int current) const override final;

  bool containsReversedText() const { return m_containsReversedText; }

  void checkConsistency() const;

  bool isAllCollapsibleWhitespace() const;

  bool canUseSimpleFontCodePath() const { return m_canUseSimpleFontCodePath; }

  void removeAndDestroyTextBoxes();

 protected:
  virtual void willBeDestroyed() override;

  virtual void styleWillChange(StyleDifference,
                               const RenderStyle&) override final {}
  virtual void styleDidChange(StyleDifference,
                              const RenderStyle* oldStyle) override;

  virtual void setTextInternal(PassRefPtr<StringImpl>);
  virtual UChar previousCharacter() const;

  InlineTextBox* createTextBox();

 private:
  void computePreferredLogicalWidths(float leadWidth);
  void computePreferredLogicalWidths(
      float leadWidth,
      HashSet<const SimpleFontData*>& fallbackFonts,
      GlyphOverflow&);

  bool computeCanUseSimpleFontCodePath() const;

  // Make length() private so that callers that have a RenderText*
  // will use the more efficient textLength() instead, while
  // callers with a RenderObject* can continue to use length().
  virtual unsigned length() const override final { return textLength(); }

  virtual void paint(PaintInfo&,
                     const LayoutPoint&,
                     Vector<RenderBox*>& layers) override final {
    ASSERT_NOT_REACHED();
  }
  virtual void layout() override final { ASSERT_NOT_REACHED(); }
  virtual bool nodeAtPoint(const HitTestRequest&,
                           HitTestResult&,
                           const HitTestLocation&,
                           const LayoutPoint&) override final {
    ASSERT_NOT_REACHED();
    return false;
  }

  void deleteTextBoxes();
  bool containsOnlyWhitespace(unsigned from, unsigned len) const;
  float widthFromCache(const Font&,
                       int start,
                       int len,
                       float xPos,
                       TextDirection,
                       HashSet<const SimpleFontData*>* fallbackFonts,
                       GlyphOverflow*) const;
  bool isAllASCII() const { return m_isAllASCII; }

  bool isText() const =
      delete;  // This will catch anyone doing an unnecessary check.

  // We put the bitfield first to minimize padding on 64-bit.
  bool m_hasBreakableChar : 1;  // Whether or not we can be broken into multiple
                                // lines.
  bool m_hasBreak : 1;  // Whether or not we have a hard break (e.g., <pre> with
                        // '\n').
  bool m_hasTab : 1;    // Whether or not we have a variable width tab character
                        // (e.g., <pre> with '\t').
  bool m_hasBreakableStart : 1;
  bool m_hasBreakableEnd : 1;
  bool m_hasEndWhiteSpace : 1;
  bool m_linesDirty : 1;  // This bit indicates that the text run has already
                          // dirtied specific line boxes, and this hint will
                          // enable RenderParagraph::layoutChildren to avoid
                          // just dirtying everything when character data is
                          // modified (e.g., appended/inserted or removed).
  bool m_containsReversedText : 1;
  bool m_isAllASCII : 1;
  bool m_canUseSimpleFontCodePath : 1;
  mutable bool m_knownToHaveNoOverflowAndNoFallbackFonts : 1;

  float m_minWidth;
  float m_maxWidth;
  float m_firstLineMinWidth;
  float m_lastLineLineMinWidth;

  String m_text;

  InlineTextBox* m_firstTextBox;
  InlineTextBox* m_lastTextBox;
};

inline UChar RenderText::uncheckedCharacterAt(unsigned i) const {
  ASSERT_WITH_SECURITY_IMPLICATION(i < textLength());
  return is8Bit() ? characters8()[i] : characters16()[i];
}

inline UChar RenderText::characterAt(unsigned i) const {
  if (i >= textLength())
    return 0;

  return uncheckedCharacterAt(i);
}

DEFINE_RENDER_OBJECT_TYPE_CASTS(RenderText, isText());

#if !ENABLE(ASSERT)
inline void RenderText::checkConsistency() const {}
#endif

}  // namespace blink

#endif  // SKY_ENGINE_CORE_RENDERING_RENDERTEXT_H_
