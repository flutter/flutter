/*
 * Copyright (C) 2010 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 *     * Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 * copyright notice, this list of conditions and the following disclaimer
 * in the documentation and/or other materials provided with the
 * distribution.
 *     * Neither the name of Google Inc. nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef ApplyBlockElementCommand_h
#define ApplyBlockElementCommand_h

#include "core/dom/QualifiedName.h"
#include "core/editing/CompositeEditCommand.h"

namespace blink {

class ApplyBlockElementCommand : public CompositeEditCommand {
protected:
    ApplyBlockElementCommand(Document&, const QualifiedName& tagName, const AtomicString& inlineStyle);
    ApplyBlockElementCommand(Document&, const QualifiedName& tagName);

    virtual void formatSelection(const VisiblePosition& startOfSelection, const VisiblePosition& endOfSelection);
    PassRefPtrWillBeRawPtr<HTMLElement> createBlockElement() const;
    const QualifiedName tagName() const { return m_tagName; }

    virtual void trace(Visitor*) override;

private:
    virtual void doApply() override final;
    virtual void formatRange(const Position& start, const Position& end, const Position& endOfSelection, RefPtrWillBeRawPtr<HTMLElement>&) = 0;
    void rangeForParagraphSplittingTextNodesIfNeeded(const VisiblePosition&, Position&, Position&);
    VisiblePosition endOfNextParagrahSplittingTextNodesIfNeeded(VisiblePosition&, Position&, Position&);

    QualifiedName m_tagName;
    AtomicString m_inlineStyle;
    Position m_endOfLastParagraph;
};

}

#endif
