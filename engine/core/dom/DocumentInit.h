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

#ifndef SKY_ENGINE_CORE_DOM_DOCUMENTINIT_H_
#define SKY_ENGINE_CORE_DOM_DOCUMENTINIT_H_

#include "sky/engine/platform/heap/Handle.h"
#include "sky/engine/platform/weborigin/KURL.h"
#include "sky/engine/wtf/PassRefPtr.h"
#include "sky/engine/wtf/RefPtr.h"
#include "sky/engine/wtf/WeakPtr.h"

namespace blink {

class Document;
class HTMLImportsController;
class LocalFrame;
class NewCustomElementRegistry;
class Settings;

class DocumentInit final {
    STACK_ALLOCATED();
public:
    explicit DocumentInit(const KURL& = KURL(), LocalFrame* = 0, WeakPtr<Document> = nullptr, HTMLImportsController* = 0);
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

    DocumentInit& withElementRegistry(NewCustomElementRegistry&);
    WeakPtr<Document> contextDocument() const;

    NewCustomElementRegistry* elementRegistry() const {
        return m_elementRegistry.get();
    }

    static DocumentInit fromContext(WeakPtr<Document> contextDocument, const KURL& = KURL());

private:
    LocalFrame* frameForSecurityContext() const;

    KURL m_url;
    LocalFrame* m_frame;
    RefPtr<Document> m_parent;
    RefPtr<Document> m_owner;
    WeakPtr<Document> m_contextDocument;
    RawPtr<HTMLImportsController> m_importsController;
    RefPtr<NewCustomElementRegistry> m_elementRegistry;
};

} // namespace blink

#endif  // SKY_ENGINE_CORE_DOM_DOCUMENTINIT_H_
