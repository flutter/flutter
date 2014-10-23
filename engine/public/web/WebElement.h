/*
 * Copyright (C) 2009 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 *     * Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 * copyright notice, this list of conditions and the following disclaimer
 * in the documentation and/or other materials provided with the
 * distribution.
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

#ifndef WebElement_h
#define WebElement_h

#include "../platform/WebImage.h"
#include "WebNode.h"

namespace blink {

class Element;
struct WebRect;

// Provides access to some properties of a DOM element node.
class WebElement : public WebNode {
public:
    WebElement() : WebNode() { }
    WebElement(const WebElement& e) : WebNode(e) { }

    WebElement& operator=(const WebElement& e) { WebNode::assign(e); return *this; }
    void assign(const WebElement& e) { WebNode::assign(e); }

    BLINK_EXPORT bool isFormControlElement() const;
    BLINK_EXPORT bool isTextFormControlElement() const;
    // Returns the qualified name, which may contain a prefix and a colon.
    BLINK_EXPORT WebString tagName() const;
    // Check if this element has the specified local tag name, and the HTML
    // namespace. Tag name matching is case-insensitive.
    BLINK_EXPORT bool hasHTMLTagName(const WebString&) const;
    BLINK_EXPORT bool hasAttribute(const WebString&) const;
    BLINK_EXPORT void removeAttribute(const WebString&);
    BLINK_EXPORT WebString getAttribute(const WebString&) const;
    BLINK_EXPORT bool setAttribute(const WebString& name, const WebString& value);
    BLINK_EXPORT WebString innerText();
    BLINK_EXPORT void requestFullScreen();
    BLINK_EXPORT WebString attributeLocalName(unsigned index) const;
    BLINK_EXPORT WebString attributeValue(unsigned index) const;
    BLINK_EXPORT unsigned attributeCount() const;
    BLINK_EXPORT WebNode shadowRoot() const;

    // Returns the language code specified for this element. This attribute
    // is inherited, so the returned value is drawn from the closest parent
    // element that has the lang attribute set, or from the HTTP
    // "Content-Language" header as a fallback.
    BLINK_EXPORT WebString computeInheritedLanguage() const;

    // Returns the bounds of the element in viewport space. The bounds
    // have been adjusted to include any transformations. This view is
    // also called the Root View in Blink.
    // This function will update the layout if required.
    BLINK_EXPORT WebRect boundsInViewportSpace();

    // Returns the image contents of this element or a null WebImage
    // if there isn't any.
    BLINK_EXPORT WebImage imageContents();

#if BLINK_IMPLEMENTATION
    WebElement(const PassRefPtrWillBeRawPtr<Element>&);
    WebElement& operator=(const PassRefPtrWillBeRawPtr<Element>&);
    operator PassRefPtrWillBeRawPtr<Element>() const;
#endif
};

} // namespace blink

#endif
