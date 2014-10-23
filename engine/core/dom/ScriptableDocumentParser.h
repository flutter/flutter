/*
 * Copyright (C) 2010 Google, Inc. All Rights Reserved.
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

#ifndef ScriptableDocumentParser_h
#define ScriptableDocumentParser_h

#include "core/dom/DecodedDataDocumentParser.h"
#include "core/dom/ParserContentPolicy.h"
#include "wtf/text/TextPosition.h"

namespace blink {

class ScriptableDocumentParser : public DecodedDataDocumentParser {
public:
    // Only used by Document::open for deciding if its safe to act on a
    // JavaScript document.open() call right now, or it should be ignored.
    virtual bool isExecutingScript() const { return false; }

    // FIXME: Only the HTMLDocumentParser ever blocks script execution on
    // stylesheet load, which is likely a bug in the XMLDocumentParser.
    virtual void executeScriptsWaitingForResources() { }

    virtual bool isWaitingForScripts() const = 0;

    // These are used to expose the current line/column to the scripting system.
    virtual OrdinalNumber lineNumber() const = 0;
    virtual TextPosition textPosition() const = 0;

    ParserContentPolicy parserContentPolicy() { return m_parserContentPolicy; }

protected:
    explicit ScriptableDocumentParser(Document&, ParserContentPolicy = AllowScriptingContent);

private:
    virtual ScriptableDocumentParser* asScriptableDocumentParser() OVERRIDE FINAL { return this; }

    ParserContentPolicy m_parserContentPolicy;
};

}

#endif // ScriptableDocumentParser_h
