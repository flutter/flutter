// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef HTMLScriptRunner_h
#define HTMLScriptRunner_h

#include "core/html/HTMLElement.h"
#include "wtf/Vector.h"
#include "wtf/text/TextPosition.h"

namespace blink {

class HTMLScriptRunner {
public:
    HTMLScriptRunner();
    ~HTMLScriptRunner();

    bool isExecutingScript() const { return m_isExecutingScript; }

    void runScript(PassRefPtr<HTMLScriptElement>, TextPosition);

    bool hasPendingScripts() const { return m_pendingScript; }
    void executePendingScripts();

private:
    void executeScript(PassRefPtr<HTMLScriptElement>, TextPosition);

    bool m_isExecutingScript;
    RefPtr<HTMLScriptElement> m_pendingScript;
    TextPosition m_textPosition;
};

} // namespace blink

#endif // HTMLScriptRunner_h
