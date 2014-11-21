/*
 * (C) 1999-2003 Lars Knoll (knoll@kde.org)
 * Copyright (C) 2004, 2006, 2007 Apple Inc. All rights reserved.
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

#ifndef StyleSheetList_h
#define StyleSheetList_h

#include "sky/engine/bindings/core/v8/ScriptWrappable.h"
#include "sky/engine/core/css/CSSStyleSheet.h"
#include "sky/engine/core/dom/TreeScope.h"
#include "sky/engine/wtf/Forward.h"
#include "sky/engine/wtf/PassRefPtr.h"
#include "sky/engine/wtf/RefCounted.h"
#include "sky/engine/wtf/Vector.h"

namespace blink {

class HTMLStyleElement;
class StyleSheet;

class StyleSheetList : public RefCounted<StyleSheetList>, public ScriptWrappable {
    DEFINE_WRAPPERTYPEINFO();
public:
    static PassRefPtr<StyleSheetList> create(TreeScope* treeScope) { return adoptRef(new StyleSheetList(treeScope)); }
    ~StyleSheetList();

    unsigned length();
    StyleSheet* item(unsigned index);

    HTMLStyleElement* getNamedItem(const AtomicString&) const;

    Document* document() { return m_treeScope ? &m_treeScope->document() : 0; }

#if !ENABLE(OILPAN)
    void detachFromDocument();
#endif

    CSSStyleSheet* anonymousNamedGetter(const AtomicString&);

private:
    StyleSheetList(TreeScope*);
    const Vector<RefPtr<StyleSheet> >& styleSheets();

    RawPtr<TreeScope> m_treeScope;
#if !ENABLE(OILPAN)
    Vector<RefPtr<StyleSheet> > m_detachedStyleSheets;
#endif
};

} // namespace blink

#endif // StyleSheetList_h
