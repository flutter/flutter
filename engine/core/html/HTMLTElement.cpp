// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/config.h"
#include "sky/engine/core/html/HTMLTElement.h"

#include "gen/sky/core/HTMLNames.h"
#include "sky/engine/core/dom/Document.h"

namespace blink {

HTMLTElement::HTMLTElement(Document& document)
    : HTMLElement(HTMLNames::tTag, document)
{
}

HTMLTElement::~HTMLTElement()
{
}

PassRefPtr<HTMLTElement> HTMLTElement::create(Document& document)
{
    return adoptRef(new HTMLTElement(document));
}

}
