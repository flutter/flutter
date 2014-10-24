/*
 * Copyright (C) 2005, 2006, 2008 Apple Inc. All rights reserved.
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

#ifndef DeleteSelectionCommand_h
#define DeleteSelectionCommand_h

#include "core/editing/CompositeEditCommand.h"

namespace blink {

class EditingStyle;

class DeleteSelectionCommand final : public CompositeEditCommand {
public:
    static PassRefPtrWillBeRawPtr<DeleteSelectionCommand> create(Document& document, bool smartDelete = false, bool mergeBlocksAfterDelete = true, bool expandForSpecialElements = false, bool sanitizeMarkup = true)
    {
        return adoptRefWillBeNoop(new DeleteSelectionCommand(document, smartDelete, mergeBlocksAfterDelete, expandForSpecialElements, sanitizeMarkup));
    }
    static PassRefPtrWillBeRawPtr<DeleteSelectionCommand> create(const VisibleSelection& selection, bool smartDelete = false, bool mergeBlocksAfterDelete = true, bool expandForSpecialElements = false, bool sanitizeMarkup = true)
    {
        return adoptRefWillBeNoop(new DeleteSelectionCommand(selection, smartDelete, mergeBlocksAfterDelete, expandForSpecialElements, sanitizeMarkup));
    }

    virtual void trace(Visitor*) override;

private:
    DeleteSelectionCommand(Document&, bool smartDelete, bool mergeBlocksAfterDelete, bool expandForSpecialElements, bool santizeMarkup);
    DeleteSelectionCommand(const VisibleSelection&, bool smartDelete, bool mergeBlocksAfterDelete, bool expandForSpecialElements, bool sanitizeMarkup);

    virtual void doApply() override;
    virtual EditAction editingAction() const override;

    virtual bool preservesTypingStyle() const override;

    void initializeStartEnd(Position&, Position&);
    void setStartingSelectionOnSmartDelete(const Position&, const Position&);
    void initializePositionData();
    void saveTypingStyleState();
    void handleGeneralDelete();
    void fixupWhitespace();
    void mergeParagraphs();
    void calculateTypingStyleAfterDelete();
    void clearTransientState();
    void makeStylingElementsDirectChildrenOfEditableRootToPreventStyleLoss();
    virtual void removeNode(PassRefPtrWillBeRawPtr<Node>, ShouldAssumeContentIsAlwaysEditable = DoNotAssumeContentIsAlwaysEditable) override;
    virtual void deleteTextFromNode(PassRefPtrWillBeRawPtr<Text>, unsigned, unsigned) override;
    void removeRedundantBlocks();

    bool m_hasSelectionToDelete;
    bool m_smartDelete;
    bool m_mergeBlocksAfterDelete;
    bool m_needPlaceholder;
    bool m_expandForSpecialElements;
    bool m_pruneStartBlockIfNecessary;
    bool m_startsAtEmptyLine;

    // This data is transient and should be cleared at the end of the doApply function.
    VisibleSelection m_selectionToDelete;
    Position m_upstreamStart;
    Position m_downstreamStart;
    Position m_upstreamEnd;
    Position m_downstreamEnd;
    Position m_endingPosition;
    Position m_leadingWhitespace;
    Position m_trailingWhitespace;
    RefPtrWillBeMember<Node> m_startBlock;
    RefPtrWillBeMember<Node> m_endBlock;
    RefPtrWillBeMember<EditingStyle> m_deleteIntoBlockquoteStyle;
    RefPtrWillBeMember<Element> m_startRoot;
    RefPtrWillBeMember<Element> m_endRoot;
    RefPtrWillBeMember<Node> m_temporaryPlaceholder;
};

} // namespace blink

#endif // DeleteSelectionCommand_h
