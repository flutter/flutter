/*
 * Copyright (C) 2013 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 *     * Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *     * Neither the name of Google Inc. nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "config.h"
#include "core/dom/StyleSheetCandidate.h"

#include "core/dom/Element.h"
#include "core/dom/StyleEngine.h"
#include "core/html/HTMLLinkElement.h"
#include "core/html/HTMLStyleElement.h"
#include "core/html/imports/HTMLImport.h"

namespace blink {

bool StyleSheetCandidate::isImport() const
{
    return m_type == HTMLLink && toHTMLLinkElement(node()).isImport();
}

Document* StyleSheetCandidate::importedDocument() const
{
    ASSERT(isImport());
    return toHTMLLinkElement(node()).import();
}

bool StyleSheetCandidate::canBeActivated() const
{
    StyleSheet* sheet = this->sheet();
    return sheet && sheet->isCSSStyleSheet();
}

StyleSheetCandidate::Type StyleSheetCandidate::typeOf(Node& node)
{
    if (node.isHTMLElement()) {
        if (isHTMLLinkElement(node))
            return HTMLLink;
        if (isHTMLStyleElement(node))
            return HTMLStyle;

        ASSERT_NOT_REACHED();
        return HTMLStyle;
    }

    ASSERT_NOT_REACHED();
    return HTMLStyle;
}

StyleSheet* StyleSheetCandidate::sheet() const
{
    switch (m_type) {
    case HTMLLink:
        return toHTMLLinkElement(node()).sheet();
    case HTMLStyle:
        return toHTMLStyleElement(node()).sheet();
    }

    ASSERT_NOT_REACHED();
    return 0;
}

}
