/*
 * Copyright (C) 2006, 2007 Apple, Inc.  All rights reserved.
 * Copyright (C) 2012 Google, Inc.  All rights reserved.
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

#include "config.h"
#include "core/editing/Editor.h"

#include "core/events/KeyboardEvent.h"
#include "core/frame/LocalFrame.h"
#include "core/page/EditorClient.h"
#include "platform/PlatformKeyboardEvent.h"

namespace blink {

bool Editor::handleEditingKeyboardEvent(KeyboardEvent* evt)
{
    const PlatformKeyboardEvent* keyEvent = evt->keyEvent();
    // do not treat this as text input if it's a system key event
    if (!keyEvent || keyEvent->isSystemKey())
        return false;

    String commandName = behavior().interpretKeyEvent(*evt);
    Command command = this->command(commandName);

    if (keyEvent->type() == PlatformEvent::RawKeyDown) {
        // WebKit doesn't have enough information about mode to decide how
        // commands that just insert text if executed via Editor should be treated,
        // so we leave it upon WebCore to either handle them immediately
        // (e.g. Tab that changes focus) or let a keypress event be generated
        // (e.g. Tab that inserts a Tab character, or Enter).
        if (command.isTextInsertion() || commandName.isEmpty())
            return false;
        return command.execute(evt);
    }

    if (command.execute(evt))
        return true;

    if (!behavior().shouldInsertCharacter(*evt) || !canEdit())
        return false;

    return insertText(evt->keyEvent()->text(), evt);
}

void Editor::handleKeyboardEvent(KeyboardEvent* evt)
{
    // Give the embedder a chance to handle the keyboard event.
    if (client().handleKeyboardEvent() || handleEditingKeyboardEvent(evt))
        evt->setDefaultHandled();
}

} // namespace blink
