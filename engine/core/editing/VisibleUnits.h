/*
 * Copyright (C) 2004 Apple Computer, Inc.  All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE COMPUTER, INC. ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL APPLE COMPUTER, INC. OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef VisibleUnits_h
#define VisibleUnits_h

#include "core/editing/EditingBoundary.h"
#include "platform/text/TextDirection.h"

namespace blink {

class LayoutRect;
class PositionWithAffinity;
class RenderObject;
class Node;
class VisiblePosition;

enum EWordSide { RightWordIfOnBoundary = false, LeftWordIfOnBoundary = true };

// words
VisiblePosition startOfWord(const VisiblePosition &, EWordSide = RightWordIfOnBoundary);
VisiblePosition endOfWord(const VisiblePosition &, EWordSide = RightWordIfOnBoundary);
VisiblePosition previousWordPosition(const VisiblePosition &);
VisiblePosition nextWordPosition(const VisiblePosition &);
VisiblePosition rightWordPosition(const VisiblePosition&, bool skipsSpaceWhenMovingRight);
VisiblePosition leftWordPosition(const VisiblePosition&, bool skipsSpaceWhenMovingRight);

// sentences
VisiblePosition startOfSentence(const VisiblePosition &);
VisiblePosition endOfSentence(const VisiblePosition &);
VisiblePosition previousSentencePosition(const VisiblePosition &);
VisiblePosition nextSentencePosition(const VisiblePosition &);

// lines
VisiblePosition startOfLine(const VisiblePosition &);
VisiblePosition endOfLine(const VisiblePosition &);
VisiblePosition previousLinePosition(const VisiblePosition&, int lineDirectionPoint, EditableType = ContentIsEditable);
VisiblePosition nextLinePosition(const VisiblePosition&, int lineDirectionPoint, EditableType = ContentIsEditable);
bool inSameLine(const VisiblePosition &, const VisiblePosition &);
bool isStartOfLine(const VisiblePosition &);
bool isEndOfLine(const VisiblePosition &);
VisiblePosition logicalStartOfLine(const VisiblePosition &);
VisiblePosition logicalEndOfLine(const VisiblePosition &);
bool isLogicalEndOfLine(const VisiblePosition &);
VisiblePosition leftBoundaryOfLine(const VisiblePosition&, TextDirection);
VisiblePosition rightBoundaryOfLine(const VisiblePosition&, TextDirection);

// paragraphs (perhaps a misnomer, can be divided by line break elements)
VisiblePosition startOfParagraph(const VisiblePosition&, EditingBoundaryCrossingRule = CannotCrossEditingBoundary);
VisiblePosition endOfParagraph(const VisiblePosition&, EditingBoundaryCrossingRule = CannotCrossEditingBoundary);
VisiblePosition startOfNextParagraph(const VisiblePosition&);
VisiblePosition previousParagraphPosition(const VisiblePosition &, int x);
VisiblePosition nextParagraphPosition(const VisiblePosition &, int x);
bool isStartOfParagraph(const VisiblePosition &, EditingBoundaryCrossingRule = CannotCrossEditingBoundary);
bool isEndOfParagraph(const VisiblePosition &, EditingBoundaryCrossingRule = CannotCrossEditingBoundary);
bool inSameParagraph(const VisiblePosition &, const VisiblePosition &, EditingBoundaryCrossingRule = CannotCrossEditingBoundary);

// blocks (true paragraphs; line break elements don't break blocks)
VisiblePosition startOfBlock(const VisiblePosition &, EditingBoundaryCrossingRule = CannotCrossEditingBoundary);
VisiblePosition endOfBlock(const VisiblePosition &, EditingBoundaryCrossingRule = CannotCrossEditingBoundary);
bool inSameBlock(const VisiblePosition &, const VisiblePosition &);
bool isStartOfBlock(const VisiblePosition &);
bool isEndOfBlock(const VisiblePosition &);

// document
VisiblePosition startOfDocument(const Node*);
VisiblePosition endOfDocument(const Node*);
VisiblePosition startOfDocument(const VisiblePosition &);
VisiblePosition endOfDocument(const VisiblePosition &);
bool isStartOfDocument(const VisiblePosition &);
bool isEndOfDocument(const VisiblePosition &);

// editable content
VisiblePosition startOfEditableContent(const VisiblePosition&);
VisiblePosition endOfEditableContent(const VisiblePosition&);
bool isEndOfEditableOrNonEditableContent(const VisiblePosition&);

// Rect is local to the returned renderer
LayoutRect localCaretRectOfPosition(const PositionWithAffinity&, RenderObject*&);

} // namespace blink

#endif // VisibleUnits_h
