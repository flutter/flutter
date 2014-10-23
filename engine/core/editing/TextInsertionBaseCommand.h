/*
 * Copyright (C) 2012 Apple Inc. All rights reserved.
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
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL APPLE INC. OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef TextInsertionBaseCommand_h
#define TextInsertionBaseCommand_h

#include "core/editing/CompositeEditCommand.h"
#include "wtf/text/WTFString.h"

namespace blink {

class Document;
class VisibleSelection;

class TextInsertionBaseCommand : public CompositeEditCommand {
public:
    virtual ~TextInsertionBaseCommand() { };

protected:
    explicit TextInsertionBaseCommand(Document&);
    static void applyTextInsertionCommand(LocalFrame*, PassRefPtrWillBeRawPtr<TextInsertionBaseCommand>, const VisibleSelection& selectionForInsertion, const VisibleSelection& endingSelection);
};

String dispatchBeforeTextInsertedEvent(const String& text, const VisibleSelection& selectionForInsertion, bool insertionIsForUpdatingComposition);
bool canAppendNewLineFeedToSelection(const VisibleSelection&);

// LineOperation should define member function "opeartor (size_t lineOffset, size_t lineLength, bool isLastLine)".
// lienLength doesn't include the newline character. So the value of lineLength could be 0.
template <class LineOperation>
void forEachLineInString(const String& string, const LineOperation& operation)
{
    unsigned offset = 0;
    size_t newline;
    while ((newline = string.find('\n', offset)) != kNotFound) {
        operation(offset, newline - offset, false);
        offset = newline + 1;
    }
    if (!offset)
        operation(0, string.length(), true);
    else {
        unsigned length = string.length();
        if (length != offset)
            operation(offset, length - offset, true);
    }
}

}

#endif
