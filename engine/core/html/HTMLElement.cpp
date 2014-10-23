/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 *           (C) 1999 Antti Koivisto (koivisto@kde.org)
 * Copyright (C) 2004-2008, 2013, 2014 Apple Inc. All rights reserved.
 * Copyright (C) 2009 Torch Mobile Inc. All rights reserved. (http://www.torchmobile.com/)
 * Copyright (C) 2011 Motorola Mobility. All rights reserved.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public License
 * along with this library; see the file COPYING.LIB.  If not, write to
 * the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301, USA.
 *
 */

#include "config.h"
#include "core/html/HTMLElement.h"

#include "bindings/core/v8/ExceptionState.h"
#include "core/HTMLNames.h"
#include "core/V8HTMLElementWrapperFactory.h" // FIXME: should be bindings/core/v8
#include "core/dom/Document.h"
#include "core/dom/ElementTraversal.h"
#include "core/dom/ExceptionCode.h"

namespace blink {

using namespace WTF;

DEFINE_ELEMENT_FACTORY_WITH_TAGNAME(HTMLElement);

String HTMLElement::contentEditable() const
{
    const AtomicString& value = getAttribute(HTMLNames::contenteditableAttr);

    if (value.isNull())
        return "inherit";
    if (value.isEmpty() || equalIgnoringCase(value, "true"))
        return "true";
    if (equalIgnoringCase(value, "false"))
         return "false";
    if (equalIgnoringCase(value, "plaintext-only"))
        return "plaintext-only";

    return "inherit";
}

void HTMLElement::setContentEditable(const String& enabled, ExceptionState& exceptionState)
{
    if (equalIgnoringCase(enabled, "true"))
        setAttribute(HTMLNames::contenteditableAttr, "true");
    else if (equalIgnoringCase(enabled, "false"))
        setAttribute(HTMLNames::contenteditableAttr, "false");
    else if (equalIgnoringCase(enabled, "plaintext-only"))
        setAttribute(HTMLNames::contenteditableAttr, "plaintext-only");
    else if (equalIgnoringCase(enabled, "inherit"))
        removeAttribute(HTMLNames::contenteditableAttr);
    else
        exceptionState.throwDOMException(SyntaxError, "The value provided ('" + enabled + "') is not one of 'true', 'false', 'plaintext-only', or 'inherit'.");
}

bool HTMLElement::spellcheck() const
{
    return isSpellCheckingEnabled();
}

void HTMLElement::setSpellcheck(bool enable)
{
    setAttribute(HTMLNames::spellcheckAttr, enable ? "true" : "false");
}


void HTMLElement::click()
{
    dispatchSimulatedClick(0, SendNoEvents);
}

void HTMLElement::accessKeyAction(bool sendMouseEvents)
{
    dispatchSimulatedClick(0, sendMouseEvents ? SendMouseUpDownEvents : SendNoEvents);
}

String HTMLElement::title() const
{
    return getAttribute(HTMLNames::titleAttr);
}

short HTMLElement::tabIndex() const
{
    if (supportsFocus())
        return Element::tabIndex();
    return -1;
}

// Returns the conforming 'dir' value associated with the state the attribute is in (in its canonical case), if any,
// or the empty string if the attribute is in a state that has no associated keyword value or if the attribute is
// not in a defined state (e.g. the attribute is missing and there is no missing value default).
// http://www.whatwg.org/specs/web-apps/current-work/multipage/common-dom-interfaces.html#limited-to-only-known-values
static inline const AtomicString& toValidDirValue(const AtomicString& value)
{
    DEFINE_STATIC_LOCAL(const AtomicString, ltrValue, ("ltr", AtomicString::ConstructFromLiteral));
    DEFINE_STATIC_LOCAL(const AtomicString, rtlValue, ("rtl", AtomicString::ConstructFromLiteral));
    DEFINE_STATIC_LOCAL(const AtomicString, autoValue, ("auto", AtomicString::ConstructFromLiteral));

    if (equalIgnoringCase(value, ltrValue))
        return ltrValue;
    if (equalIgnoringCase(value, rtlValue))
        return rtlValue;
    if (equalIgnoringCase(value, autoValue))
        return autoValue;
    return nullAtom;
}

const AtomicString& HTMLElement::dir()
{
    return toValidDirValue(getAttribute(HTMLNames::dirAttr));
}

void HTMLElement::setDir(const AtomicString& value)
{
    setAttribute(HTMLNames::dirAttr, value);
}

bool HTMLElement::isInteractiveContent() const
{
    return false;
}

bool HTMLElement::matchesReadOnlyPseudoClass() const
{
    return !matchesReadWritePseudoClass();
}

bool HTMLElement::matchesReadWritePseudoClass() const
{
    if (hasAttribute(HTMLNames::contenteditableAttr)) {
        const AtomicString& value = getAttribute(HTMLNames::contenteditableAttr);

        if (value.isEmpty() || equalIgnoringCase(value, "true") || equalIgnoringCase(value, "plaintext-only"))
            return true;
        if (equalIgnoringCase(value, "false"))
            return false;
        // All other values should be treated as "inherit".
    }

    return parentElement() && parentElement()->hasEditableStyle();
}

const AtomicString& HTMLElement::eventParameterName()
{
    DEFINE_STATIC_LOCAL(const AtomicString, eventString, ("event", AtomicString::ConstructFromLiteral));
    return eventString;
}

v8::Handle<v8::Object> HTMLElement::wrap(v8::Handle<v8::Object> creationContext, v8::Isolate* isolate)
{
    return createV8HTMLWrapper(this, creationContext, isolate);
}

} // namespace blink

#ifndef NDEBUG

// For use in the debugger
void dumpInnerHTML(blink::HTMLElement*);

void dumpInnerHTML(blink::HTMLElement* element)
{
    printf("%s\n", element->innerHTML().ascii().data());
}
#endif
