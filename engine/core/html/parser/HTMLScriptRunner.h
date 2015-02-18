// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_HTML_PARSER_HTMLSCRIPTRUNNER_H_
#define SKY_ENGINE_CORE_HTML_PARSER_HTMLSCRIPTRUNNER_H_

#include "sky/engine/core/html/HTMLElement.h"
#include "sky/engine/wtf/Vector.h"
#include "sky/engine/wtf/text/TextPosition.h"

namespace blink {

class HTMLScriptRunner {
public:
    HTMLScriptRunner();
    ~HTMLScriptRunner();

    bool isExecutingScript() const { return m_isExecutingScript; }

    void runScript(PassRefPtr<HTMLScriptElement>, TextPosition);

private:
    void executeScript(PassRefPtr<HTMLScriptElement>, TextPosition);

    bool m_isExecutingScript;
    TextPosition m_textPosition;
};

} // namespace blink

#endif  // SKY_ENGINE_CORE_HTML_PARSER_HTMLSCRIPTRUNNER_H_
