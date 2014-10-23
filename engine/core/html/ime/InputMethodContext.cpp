/*
 * Copyright (C) 2013 Google Inc. All rights reserved.
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

#include "config.h"
#include "core/html/ime/InputMethodContext.h"

#include "core/dom/Document.h"
#include "core/dom/Text.h"
#include "core/editing/InputMethodController.h"
#include "core/events/Event.h"
#include "core/frame/LocalFrame.h"

namespace blink {

PassOwnPtrWillBeRawPtr<InputMethodContext> InputMethodContext::create(HTMLElement* element)
{
    return adoptPtrWillBeNoop(new InputMethodContext(element));
}

InputMethodContext::InputMethodContext(HTMLElement* element)
    : m_element(element)
{
    ScriptWrappable::init(this);
}

InputMethodContext::~InputMethodContext()
{
}

String InputMethodContext::locale() const
{
    // FIXME: Implement this.
    return emptyString();
}

HTMLElement* InputMethodContext::target() const
{
    return m_element;
}

unsigned InputMethodContext::compositionStartOffset()
{
    if (hasFocus())
        return inputMethodController().compositionStart();
    return 0;
}

unsigned InputMethodContext::compositionEndOffset()
{
    if (hasFocus())
        return inputMethodController().compositionEnd();
    return 0;
}

void InputMethodContext::confirmComposition()
{
    if (hasFocus())
        inputMethodController().confirmCompositionAndResetState();
}

bool InputMethodContext::hasFocus() const
{
    LocalFrame* frame = m_element->document().frame();
    if (!frame)
        return false;

    const Element* element = frame->document()->focusedElement();
    return element && element->isHTMLElement() && m_element == toHTMLElement(element);
}

String InputMethodContext::compositionText() const
{
    if (!hasFocus())
        return emptyString();

    Text* text = inputMethodController().compositionNode();
    return text ? text->wholeText() : emptyString();
}

CompositionUnderline InputMethodContext::selectedSegment() const
{
    CompositionUnderline underline;
    if (!hasFocus())
        return underline;

    const InputMethodController& controller = inputMethodController();
    if (!controller.hasComposition())
        return underline;

    Vector<CompositionUnderline> underlines = controller.customCompositionUnderlines();
    for (size_t i = 0; i < underlines.size(); ++i) {
        if (underlines[i].thick)
            return underlines[i];
    }

    // When no underline information is available while composition exists,
    // build a CompositionUnderline whose element is the whole composition.
    underline.endOffset = controller.compositionEnd() - controller.compositionStart();
    return underline;

}

int InputMethodContext::selectionStart() const
{
    return selectedSegment().startOffset;
}

int InputMethodContext::selectionEnd() const
{
    return selectedSegment().endOffset;
}

const Vector<unsigned>& InputMethodContext::segments()
{
    m_segments.clear();
    if (!hasFocus())
        return m_segments;
    const InputMethodController& controller = inputMethodController();
    if (!controller.hasComposition())
        return m_segments;

    Vector<CompositionUnderline> underlines = controller.customCompositionUnderlines();
    if (!underlines.size()) {
        m_segments.append(0);
    } else {
        for (size_t i = 0; i < underlines.size(); ++i)
            m_segments.append(underlines[i].startOffset);
    }

    return m_segments;
}

InputMethodController& InputMethodContext::inputMethodController() const
{
    return m_element->document().frame()->inputMethodController();
}

const AtomicString& InputMethodContext::interfaceName() const
{
    return EventTargetNames::InputMethodContext;
}

ExecutionContext* InputMethodContext::executionContext() const
{
    return &m_element->document();
}

void InputMethodContext::dispatchCandidateWindowShowEvent()
{
    dispatchEvent(Event::create(EventTypeNames::candidatewindowshow));
}

void InputMethodContext::dispatchCandidateWindowUpdateEvent()
{
    dispatchEvent(Event::create(EventTypeNames::candidatewindowupdate));
}

void InputMethodContext::dispatchCandidateWindowHideEvent()
{
    dispatchEvent(Event::create(EventTypeNames::candidatewindowhide));
}

void InputMethodContext::trace(Visitor* visitor)
{
    visitor->trace(m_element);
    EventTargetWithInlineData::trace(visitor);
}

} // namespace blink
