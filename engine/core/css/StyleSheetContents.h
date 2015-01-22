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

#ifndef SKY_ENGINE_CORE_CSS_STYLESHEETCONTENTS_H_
#define SKY_ENGINE_CORE_CSS_STYLESHEETCONTENTS_H_

#include "sky/engine/core/css/RuleSet.h"
#include "sky/engine/core/css/parser/CSSParserMode.h"
#include "sky/engine/platform/heap/Handle.h"
#include "sky/engine/platform/weborigin/KURL.h"
#include "sky/engine/wtf/HashMap.h"
#include "sky/engine/wtf/ListHashSet.h"
#include "sky/engine/wtf/RefCounted.h"
#include "sky/engine/wtf/Vector.h"
#include "sky/engine/wtf/text/AtomicStringHash.h"
#include "sky/engine/wtf/text/StringHash.h"
#include "sky/engine/wtf/text/TextPosition.h"


namespace blink {

class CSSStyleSheet;
class Document;
class Node;
class StyleRuleBase;
class StyleRuleFontFace;

class StyleSheetContents : public RefCounted<StyleSheetContents> {
public:
    static PassRefPtr<StyleSheetContents> create(Document* document, const CSSParserContext& context)
    {
        return adoptRef(new StyleSheetContents(document, context));
    }

    ~StyleSheetContents();

    const CSSParserContext& parserContext() const { return m_parserContext; }

    bool parseString(const String&);

    void parserAppendRule(PassRefPtr<StyleRuleBase>);

    const Vector<RefPtr<StyleRuleBase> >& childRules() const { return m_childRules; }

    void shrinkToFit();
    RuleSet& ensureRuleSet();

private:
    explicit StyleSheetContents(Document* document, const CSSParserContext&);

    OwnPtr<RuleSet> m_ruleSet;
    Vector<RefPtr<StyleRuleBase> > m_childRules;
    CSSParserContext m_parserContext;

    RefPtr<Document> m_document;
};

} // namespace

#endif  // SKY_ENGINE_CORE_CSS_STYLESHEETCONTENTS_H_
