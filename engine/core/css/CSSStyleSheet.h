/*
 * (C) 1999-2003 Lars Knoll (knoll@kde.org)
 * Copyright (C) 2004, 2006, 2007, 2008, 2009, 2010, 2012 Apple Inc. All rights reserved.
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

#ifndef SKY_ENGINE_CORE_CSS_CSSSTYLESHEET_H_
#define SKY_ENGINE_CORE_CSS_CSSSTYLESHEET_H_

#include "sky/engine/wtf/Noncopyable.h"
#include "sky/engine/wtf/RefCounted.h"
#include "sky/engine/wtf/text/TextPosition.h"

namespace blink {

class CSSStyleSheet;
class Document;
class KURL;
class MediaQuerySet;
class Node;
class StyleSheetContents;

class CSSStyleSheet final : public RefCounted<CSSStyleSheet> {
public:
    static PassRefPtr<CSSStyleSheet> create(Node*, const KURL&);
    static PassRefPtr<CSSStyleSheet> create(PassRefPtr<StyleSheetContents>, Node* ownerNode);

    ~CSSStyleSheet();

    Node* ownerNode() const { return m_ownerNode; }

    void clearOwnerNode();

    Document* ownerDocument() const;
    MediaQuerySet* mediaQueries() const { return m_mediaQueries.get(); }
    void setMediaQueries(PassRefPtr<MediaQuerySet>);

    StyleSheetContents* contents() const { return m_contents.get(); }

private:
    CSSStyleSheet(PassRefPtr<StyleSheetContents>, Node* ownerNode);

    RefPtr<StyleSheetContents> m_contents;
    RefPtr<MediaQuerySet> m_mediaQueries;

    Node* m_ownerNode;
};

} // namespace blink

#endif  // SKY_ENGINE_CORE_CSS_CSSSTYLESHEET_H_
