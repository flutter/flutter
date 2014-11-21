// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_HTML_HTMLSCRIPTELEMENT_H_
#define SKY_ENGINE_CORE_HTML_HTMLSCRIPTELEMENT_H_

#include "sky/engine/core/html/HTMLElement.h"

namespace blink {

class HTMLScriptElement final : public HTMLElement {
    DEFINE_WRAPPERTYPEINFO();
public:
    static PassRefPtr<HTMLScriptElement> create(Document&);

private:
    explicit HTMLScriptElement(Document&);
};

} // namespace blink

#endif  // SKY_ENGINE_CORE_HTML_HTMLSCRIPTELEMENT_H_
