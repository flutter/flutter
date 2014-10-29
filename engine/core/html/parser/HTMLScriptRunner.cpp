// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "config.h"
#include "core/html/parser/HTMLScriptRunner.h"

#include "bindings/core/v8/ScriptController.h"
#include "core/dom/Document.h"
#include "core/dom/Microtask.h"
#include "core/frame/LocalFrame.h"
#include "core/html/HTMLScriptElement.h"

namespace blink {

HTMLScriptRunner::HTMLScriptRunner()
    : m_isExecutingScript(false)
{
}

HTMLScriptRunner::~HTMLScriptRunner()
{
}

void HTMLScriptRunner::runScript(PassRefPtr<HTMLScriptElement> element, TextPosition textPosition)
{
    ASSERT(!hasPendingScripts());

    if (!element->document().isScriptExecutionReady()) {
        m_pendingScript = element;
        m_textPosition = textPosition;
        return;
    }

    executeScript(element, textPosition);
}

void HTMLScriptRunner::executePendingScripts()
{
    executeScript(m_pendingScript.release(), m_textPosition);
}

void HTMLScriptRunner::executeScript(PassRefPtr<HTMLScriptElement> element, TextPosition textPosition)
{
    Microtask::performCheckpoint();

    Document& sourceDocument = element->document();
    String source = element->textContent();

    RefPtr<Document> contextDocument = sourceDocument.contextDocument().get();
    if (!contextDocument)
        return;

    LocalFrame* frame = contextDocument->frame();
    if (!frame)
        return;

    ASSERT(!m_isExecutingScript);
    TemporaryChange<bool> executingScript(m_isExecutingScript, true);

    contextDocument->pushCurrentScript(element);
    frame->script().executeModuleScript(sourceDocument, source, textPosition);
    contextDocument->popCurrentScript();
}

}
