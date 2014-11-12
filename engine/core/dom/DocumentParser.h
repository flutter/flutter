/*
 * Copyright (C) 2000 Peter Kelly (pmk@post.com)
 * Copyright (C) 2005, 2006 Apple Computer, Inc.
 * Copyright (C) 2007 Samuel Weinig (sam@webkit.org)
 * Copyright (C) 2010 Google, Inc.
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

#ifndef DocumentParser_h
#define DocumentParser_h

#include "mojo/public/cpp/system/core.h"
#include "platform/heap/Handle.h"
#include "wtf/Forward.h"
#include "wtf/RefCounted.h"
#include "wtf/text/TextPosition.h"

namespace blink {

class Document;
class SegmentedString;
class HTMLDocumentParser;
class TextResourceDecoder;

class DocumentParser : public RefCounted<DocumentParser> {
public:
    virtual ~DocumentParser();

    virtual void parse(mojo::ScopedDataPipeConsumerHandle) = 0;

    virtual TextPosition textPosition() const = 0;
    virtual void executeScriptsWaitingForResources() = 0;
    virtual bool isWaitingForScripts() const = 0;
    virtual bool isExecutingScript() const = 0;

    bool isParsing() const { return m_state == ParsingState; }

    // stopParsing() is used when a load is canceled/stopped.
    // stopParsing() is currently different from detach(), but shouldn't be.
    // It should NOT be ok to call any methods on DocumentParser after either
    // detach() or stopParsing() but right now only detach() will ASSERT.
    virtual void stopParsing();

    // Document is expected to detach the parser before releasing its ref.
    // After detach, m_document is cleared.  The parser will unwind its
    // callstacks, but not produce any more nodes.
    // It is impossible for the parser to touch the rest of WebCore after
    // detach is called.
    // Oilpan: We don't need to call detach when a Document is destructed.
    virtual void detach();

protected:
    explicit DocumentParser(Document*);

    // document() will return 0 after detach() is called.
    Document* document() const { ASSERT(m_document); return m_document; }

    virtual void prepareToStopParsing();

    bool isStopping() const { return m_state == StoppingState; }
    bool isStopped() const { return m_state >= StoppedState; }
    bool isDetached() const { return m_state == DetachedState; }

private:
    enum ParserState {
        ParsingState,
        StoppingState,
        StoppedState,
        DetachedState
    };
    ParserState m_state;

    // Every DocumentParser needs a pointer back to the document.
    // m_document will be 0 after the parser is stopped.
    Document* m_document;
};

} // namespace blink

#endif // DocumentParser_h
