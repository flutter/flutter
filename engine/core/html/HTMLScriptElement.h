// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef HTMLScriptElement_h
#define HTMLScriptElement_h

#include "core/html/HTMLElement.h"

namespace blink {

class HTMLScriptElement final : public HTMLElement {
    DEFINE_WRAPPERTYPEINFO();
public:
    static PassRefPtrWillBeRawPtr<HTMLScriptElement> create(Document&);

private:
    explicit HTMLScriptElement(Document&);
};

} // namespace blink

#endif // HTMLScriptElement_h
