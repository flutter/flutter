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

#ifndef InsertIntoTextNodeCommand_h
#define InsertIntoTextNodeCommand_h

#include "core/editing/EditCommand.h"

namespace blink {

class Text;

class InsertIntoTextNodeCommand FINAL : public SimpleEditCommand {
public:
    static PassRefPtrWillBeRawPtr<InsertIntoTextNodeCommand> create(PassRefPtrWillBeRawPtr<Text> node, unsigned offset, const String& text)
    {
        return adoptRefWillBeNoop(new InsertIntoTextNodeCommand(node, offset, text));
    }

    virtual void trace(Visitor*) OVERRIDE;

private:
    InsertIntoTextNodeCommand(PassRefPtrWillBeRawPtr<Text> node, unsigned offset, const String& text);

    virtual void doApply() OVERRIDE;
    virtual void doUnapply() OVERRIDE;

    RefPtrWillBeMember<Text> m_node;
    unsigned m_offset;
    String m_text;
};

} // namespace blink

#endif // InsertIntoTextNodeCommand_h
