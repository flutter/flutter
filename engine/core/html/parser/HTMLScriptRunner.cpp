// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/config.h"
#include "sky/engine/core/html/parser/HTMLScriptRunner.h"

#include "sky/engine/bindings/core/v8/ScriptController.h"
#include "sky/engine/core/dom/Document.h"
#include "sky/engine/core/dom/Microtask.h"
#include "sky/engine/core/frame/LocalFrame.h"
#include "sky/engine/core/html/HTMLScriptElement.h"

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
    ASSERT(sourceDocument.module());
    frame->script().executeModuleScript(*sourceDocument.module(), source, textPosition);
    contextDocument->popCurrentScript();
}

}
