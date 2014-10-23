/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 *           (C) 1999 Antti Koivisto (koivisto@kde.org)
 *           (C) 2001 Dirk Mueller (mueller@kde.org)
 *           (C) 2006 Alexey Proskuryakov (ap@webkit.org)
 * Copyright (C) 2004, 2005, 2006, 2007, 2008, 2009, 2010, 2012 Apple Inc. All rights reserved.
 * Copyright (C) 2008, 2009 Torch Mobile Inc. All rights reserved. (http://www.torchmobile.com/)
 * Copyright (C) 2010 Nokia Corporation and/or its subsidiary(-ies)
 * Copyright (C) 2013 Google Inc. All rights reserved.
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

#ifndef DocumentInit_h
#define DocumentInit_h

#include "platform/heap/Handle.h"
#include "platform/weborigin/KURL.h"
#include "wtf/PassRefPtr.h"
#include "wtf/RefPtr.h"
#include "wtf/WeakPtr.h"

namespace blink {

class CustomElementRegistrationContext;
class Document;
class LocalFrame;
class HTMLImportsController;
class Settings;

class DocumentInit FINAL {
    STACK_ALLOCATED();
public:
    explicit DocumentInit(const KURL& = KURL(), LocalFrame* = 0, WeakPtrWillBeRawPtr<Document> = nullptr, HTMLImportsController* = 0);
    DocumentInit(const DocumentInit&);
    ~DocumentInit();

    const KURL& url() const { return m_url; }
    LocalFrame* frame() const { return m_frame; }
    HTMLImportsController* importsController() const { return m_importsController; }

    bool shouldSetURL() const;
    bool isSeamlessAllowedFor(Document* child) const;

    Document* parent() const { return m_parent.get(); }
    Document* owner() const { return m_owner.get(); }
    LocalFrame* ownerFrame() const;
    Settings* settings() const;

    DocumentInit& withRegistrationContext(CustomElementRegistrationContext*);
    DocumentInit& withNewRegistrationContext();
    PassRefPtrWillBeRawPtr<CustomElementRegistrationContext> registrationContext(Document*) const;
    WeakPtrWillBeRawPtr<Document> contextDocument() const;

    static DocumentInit fromContext(WeakPtrWillBeRawPtr<Document> contextDocument, const KURL& = KURL());

private:
    LocalFrame* frameForSecurityContext() const;

    KURL m_url;
    LocalFrame* m_frame;
    RefPtrWillBeMember<Document> m_parent;
    RefPtrWillBeMember<Document> m_owner;
    WeakPtrWillBeMember<Document> m_contextDocument;
    RawPtrWillBeMember<HTMLImportsController> m_importsController;
    RefPtrWillBeMember<CustomElementRegistrationContext> m_registrationContext;
    bool m_createNewRegistrationContext;
};

} // namespace blink

#endif // DocumentInit_h
