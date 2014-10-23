/*
 * Copyright (C) 2007, 2008 Apple Inc. All rights reserved.
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
 *
 */

#ifndef TextEvent_h
#define TextEvent_h

#include "core/events/TextEventInputType.h"
#include "core/events/UIEvent.h"

namespace blink {

class DocumentFragment;

class TextEvent FINAL : public UIEvent {
    DEFINE_WRAPPERTYPEINFO();
public:
    static PassRefPtrWillBeRawPtr<TextEvent> create();
    static PassRefPtrWillBeRawPtr<TextEvent> create(PassRefPtrWillBeRawPtr<AbstractView>, const String& data, TextEventInputType = TextEventInputKeyboard);
    static PassRefPtrWillBeRawPtr<TextEvent> createForPlainTextPaste(PassRefPtrWillBeRawPtr<AbstractView>, const String& data, bool shouldSmartReplace);
    static PassRefPtrWillBeRawPtr<TextEvent> createForFragmentPaste(PassRefPtrWillBeRawPtr<AbstractView>, PassRefPtrWillBeRawPtr<DocumentFragment> data, bool shouldSmartReplace, bool shouldMatchStyle);
    static PassRefPtrWillBeRawPtr<TextEvent> createForDrop(PassRefPtrWillBeRawPtr<AbstractView>, const String& data);

    virtual ~TextEvent();

    void initTextEvent(const AtomicString& type, bool canBubble, bool cancelable, PassRefPtrWillBeRawPtr<AbstractView>, const String& data);

    String data() const { return m_data; }

    virtual const AtomicString& interfaceName() const OVERRIDE;

    bool isLineBreak() const { return m_inputType == TextEventInputLineBreak; }
    bool isComposition() const { return m_inputType == TextEventInputComposition; }
    bool isPaste() const { return m_inputType == TextEventInputPaste; }
    bool isDrop() const { return m_inputType == TextEventInputDrop; }

    bool shouldSmartReplace() const { return m_shouldSmartReplace; }
    bool shouldMatchStyle() const { return m_shouldMatchStyle; }
    DocumentFragment* pastingFragment() const { return m_pastingFragment.get(); }

    virtual void trace(Visitor*) OVERRIDE;

private:
    TextEvent();

    TextEvent(PassRefPtrWillBeRawPtr<AbstractView>, const String& data, TextEventInputType = TextEventInputKeyboard);
    TextEvent(PassRefPtrWillBeRawPtr<AbstractView>, const String& data, PassRefPtrWillBeRawPtr<DocumentFragment>, bool shouldSmartReplace, bool shouldMatchStyle);

    TextEventInputType m_inputType;
    String m_data;

    RefPtrWillBeMember<DocumentFragment> m_pastingFragment;
    bool m_shouldSmartReplace;
    bool m_shouldMatchStyle;
};

inline bool isTextEvent(const Event& event)
{
    return event.type() == EventTypeNames::textInput && event.hasInterface(EventNames::TextEvent);
}

DEFINE_TYPE_CASTS(TextEvent, Event, event, isTextEvent(*event), isTextEvent(event));

} // namespace blink

#endif // TextEvent_h
