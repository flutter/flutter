// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/config.h"
#include "sky/engine/core/html/parser/HTMLScriptRunner.h"

#include "sky/engine/core/app/AbstractModule.h"
#include "sky/engine/core/dom/Document.h"
#include "sky/engine/core/dom/Microtask.h"
#include "sky/engine/core/frame/LocalFrame.h"
#include "sky/engine/core/html/HTMLScriptElement.h"
#include "sky/engine/core/script/dart_controller.h"

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
    ASSERT(element->document().haveImportsLoaded());
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

    ASSERT(sourceDocument.module());
    frame->dart().LoadModule(sourceDocument.module(), source, textPosition);
}

}
