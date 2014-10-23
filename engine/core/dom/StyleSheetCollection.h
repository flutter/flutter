/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 *           (C) 1999 Antti Koivisto (koivisto@kde.org)
 *           (C) 2001 Dirk Mueller (mueller@kde.org)
 *           (C) 2006 Alexey Proskuryakov (ap@webkit.org)
 * Copyright (C) 2004, 2005, 2006, 2007, 2008, 2009, 2010, 2012 Apple Inc. All rights reserved.
 * Copyright (C) 2008, 2009 Torch Mobile Inc. All rights reserved. (http://www.torchmobile.com/)
 * Copyright (C) 2010 Nokia Corporation and/or its subsidiary(-ies)
 * Copyright (C) 2011 Google Inc. All rights reserved.
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

#ifndef StyleSheetCollection_h
#define StyleSheetCollection_h

#include "platform/heap/Handle.h"
#include "wtf/FastAllocBase.h"
#include "wtf/RefPtr.h"
#include "wtf/Vector.h"

namespace blink {

class CSSStyleSheet;
class StyleSheet;

class StyleSheetCollection : public NoBaseWillBeGarbageCollectedFinalized<StyleSheetCollection> {
    WTF_MAKE_NONCOPYABLE(StyleSheetCollection);
    WTF_MAKE_FAST_ALLOCATED_WILL_BE_REMOVED;
public:
    friend class ActiveDocumentStyleSheetCollector;
    friend class ImportedDocumentStyleSheetCollector;

    StyleSheetCollection();
    virtual ~StyleSheetCollection();

    WillBeHeapVector<RefPtrWillBeMember<CSSStyleSheet> >& activeAuthorStyleSheets() { return m_activeAuthorStyleSheets; }
    WillBeHeapVector<RefPtrWillBeMember<StyleSheet> >& styleSheetsForStyleSheetList() { return m_styleSheetsForStyleSheetList; }
    const WillBeHeapVector<RefPtrWillBeMember<CSSStyleSheet> >& activeAuthorStyleSheets() const { return m_activeAuthorStyleSheets; }
    const WillBeHeapVector<RefPtrWillBeMember<StyleSheet> >& styleSheetsForStyleSheetList() const { return m_styleSheetsForStyleSheetList; }

    void swap(StyleSheetCollection&);
    void swapSheetsForSheetList(WillBeHeapVector<RefPtrWillBeMember<StyleSheet> >&);
    void appendActiveStyleSheets(const WillBeHeapVector<RefPtrWillBeMember<CSSStyleSheet> >&);
    void appendActiveStyleSheet(CSSStyleSheet*);
    void appendSheetForList(StyleSheet*);

    virtual void trace(Visitor*);

protected:
    WillBeHeapVector<RefPtrWillBeMember<StyleSheet> > m_styleSheetsForStyleSheetList;
    WillBeHeapVector<RefPtrWillBeMember<CSSStyleSheet> > m_activeAuthorStyleSheets;
};

}

#endif

