/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 *           (C) 1999 Antti Koivisto (koivisto@kde.org)
 *           (C) 2001 Dirk Mueller (mueller@kde.org)
 * Copyright (C) 2004, 2005, 2006, 2008 Apple Inc. All rights reserved.
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

#ifndef DOMImplementation_h
#define DOMImplementation_h

#include "core/dom/Document.h"
#include "wtf/PassRefPtr.h"

namespace blink {

class Document;
class DocumentInit;
class DocumentType;
class ExceptionState;
class LocalFrame;
class HTMLDocument;
class KURL;

class DOMImplementation final : public DummyBase<DOMImplementation>, public ScriptWrappable {
    DEFINE_WRAPPERTYPEINFO();
    WTF_MAKE_FAST_ALLOCATED_WILL_BE_REMOVED;
public:
    static PassOwnPtr<DOMImplementation> create(Document& document)
    {
        return adoptPtr(new DOMImplementation(document));
    }

#if !ENABLE(OILPAN)
    void ref() { m_document->ref(); }
    void deref() { m_document->deref(); }
#endif
    Document& document() const { return *m_document; }

    PassRefPtr<Document> createDocument();

    void trace(Visitor*);

private:
    explicit DOMImplementation(Document&);

    RawPtr<Document> m_document;
};

} // namespace blink

#endif // DOMImplementation_h
