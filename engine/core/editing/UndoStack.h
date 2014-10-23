/*
 * Copyright (C) 2009 Google Inc. All rights reserved.
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

#ifndef UndoStack_h
#define UndoStack_h

#include "platform/heap/Handle.h"
#include "wtf/Deque.h"
#include "wtf/Forward.h"

namespace blink {

class LocalFrame;
class UndoStep;

class UndoStack FINAL : public NoBaseWillBeGarbageCollected<UndoStack> {
    DECLARE_EMPTY_DESTRUCTOR_WILL_BE_REMOVED(UndoStack)
public:
    static PassOwnPtrWillBeRawPtr<UndoStack> create();

    void registerUndoStep(PassRefPtrWillBeRawPtr<UndoStep>);
    void registerRedoStep(PassRefPtrWillBeRawPtr<UndoStep>);
    void didUnloadFrame(const LocalFrame&);
    bool canUndo() const;
    bool canRedo() const;
    void undo();
    void redo();

    void trace(Visitor*);

private:
    UndoStack();

    typedef WillBeHeapDeque<RefPtrWillBeMember<UndoStep> > UndoStepStack;

    void filterOutUndoSteps(UndoStepStack&, const LocalFrame&);

    bool m_inRedo;
    UndoStepStack m_undoStack;
    UndoStepStack m_redoStack;
};

} // namespace blink

#endif
