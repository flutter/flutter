// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "config.h"
#include "core/html/HTMLScriptElement.h"

namespace blink {

HTMLScriptElement::HTMLScriptElement(Document& document)
    : HTMLElement(HTMLNames::scriptTag, document)
{
    ScriptWrappable::init(this);
}

PassRefPtrWillBeRawPtr<HTMLScriptElement> HTMLScriptElement::create(Document& document)
{
    return adoptRefWillBeNoop(new HTMLScriptElement(document));
}

}
