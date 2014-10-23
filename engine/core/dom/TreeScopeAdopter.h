/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 *           (C) 1999 Antti Koivisto (koivisto@kde.org)
 *           (C) 2001 Dirk Mueller (mueller@kde.org)
 * Copyright (C) 2004, 2005, 2006, 2007, 2008, 2009, 2010, 2011 Apple Inc. All rights reserved.
 * Copyright (C) 2008 Nokia Corporation and/or its subsidiary(-ies)
 * Copyright (C) 2009 Torch Mobile Inc. All rights reserved. (http://www.torchmobile.com/)
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
 */
#ifndef TreeScopeAdopter_h
#define TreeScopeAdopter_h

#include "core/dom/Node.h"

namespace blink {

class TreeScope;

class TreeScopeAdopter {
    STACK_ALLOCATED();
public:
    TreeScopeAdopter(Node& toAdopt, TreeScope& newScope);

    void execute() const { moveTreeToNewScope(*m_toAdopt); }
    bool needsScopeChange() const { return m_oldScope != m_newScope; }

#if ENABLE(ASSERT)
    static void ensureDidMoveToNewDocumentWasCalled(Document&);
#else
    static void ensureDidMoveToNewDocumentWasCalled(Document&) { }
#endif

private:
    void updateTreeScope(Node&) const;
    void moveTreeToNewScope(Node&) const;
    void moveTreeToNewDocument(Node&, Document& oldDocument, Document& newDocument) const;
    void moveNodeToNewDocument(Node&, Document& oldDocument, Document& newDocument) const;
    TreeScope& oldScope() const { return *m_oldScope; }
    TreeScope& newScope() const { return *m_newScope; }

    RawPtrWillBeMember<Node> m_toAdopt;
    RawPtrWillBeMember<TreeScope> m_newScope;
    RawPtrWillBeMember<TreeScope> m_oldScope;
};

inline TreeScopeAdopter::TreeScopeAdopter(Node& toAdopt, TreeScope& newScope)
    : m_toAdopt(toAdopt)
    , m_newScope(newScope)
    , m_oldScope(toAdopt.treeScope())
{
}

}

#endif
