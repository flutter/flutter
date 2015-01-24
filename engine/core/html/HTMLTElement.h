// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_HTML_HTMLITELEMENT_H_
#define SKY_ENGINE_CORE_HTML_HTMLITELEMENT_H_

#include "sky/engine/core/html/HTMLElement.h"

namespace blink {

class Document;

class HTMLTElement final : public HTMLElement {
    DEFINE_WRAPPERTYPEINFO();
public:
    static PassRefPtr<HTMLTElement> create(Document&);

private:
    explicit HTMLTElement(Document&);
    ~HTMLTElement();
};

} // namespace blink

#endif  // SKY_ENGINE_CORE_HTML_HTMLITELEMENT_H_
