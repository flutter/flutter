/*
 * Copyright (C) 2013 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer
 *    in the documentation and/or other materials provided with the
 *    distribution.
 * 3. Neither the name of Google Inc. nor the names of its contributors
 *    may be used to endorse or promote products derived from this
 *    software without specific prior written permission.
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

#ifndef CustomElement_h
#define CustomElement_h

#include "core/dom/custom/CustomElementDefinition.h"
#include "wtf/HashMap.h"
#include "wtf/Noncopyable.h"
#include "wtf/PassRefPtr.h"
#include "wtf/RefPtr.h"
#include "wtf/Vector.h"
#include "wtf/text/AtomicString.h"

namespace blink {

class CustomElementMicrotaskImportStep;
class Document;
class Element;
class HTMLImportChild;

class CustomElement {
public:
    enum NameSet {
        EmbedderNames = 1 << 0,
        StandardNames = 1 << 1,
        AllNames = EmbedderNames | StandardNames
    };
    static bool isValidName(const AtomicString& name, NameSet validNames = AllNames);
    static void addEmbedderCustomElementName(const AtomicString& name);

    // API to notify of document-level changes
    static CustomElementMicrotaskImportStep* didCreateImport(HTMLImportChild*);
    static void didFinishLoadingImport(Document& master);

    // API for registration contexts
    static void define(Element*, PassRefPtr<CustomElementDefinition>);

    // API for Element to kick off changes

    static void attributeDidChange(Element*, const AtomicString& name, const AtomicString& oldValue, const AtomicString& newValue);
    static void didAttach(Element*, const Document&);
    static void didDetach(Element*, const Document&);
    static void wasDestroyed(Element*);

private:
    CustomElement();

    static Vector<AtomicString>& embedderCustomElementNames();
};

}

#endif // CustomElement_h
