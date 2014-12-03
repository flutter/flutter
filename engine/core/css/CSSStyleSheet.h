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

#include "sky/engine/core/css/StyleSheet.h"
#include "sky/engine/platform/heap/Handle.h"
#include "sky/engine/wtf/Noncopyable.h"
#include "sky/engine/wtf/text/TextPosition.h"

namespace blink {

class BisonCSSParser;
class CSSStyleSheet;
class Document;
class ExceptionState;
class MediaQuerySet;
class StyleSheetContents;

enum StyleSheetUpdateType {
    PartialRuleUpdate,
    EntireStyleSheetUpdate
};

class CSSStyleSheet final : public StyleSheet {
public:
    static PassRefPtr<CSSStyleSheet> createInline(Node*, const KURL&, const TextPosition& startPosition = TextPosition::minimumPosition());
    static PassRefPtr<CSSStyleSheet> createInline(PassRefPtr<StyleSheetContents>, Node* ownerNode, const TextPosition& startPosition = TextPosition::minimumPosition());

    virtual ~CSSStyleSheet();

    virtual Node* ownerNode() const override { return m_ownerNode; }

    unsigned length() const;

    virtual void clearOwnerNode() override;

    virtual KURL baseURL() const override;

    Document* ownerDocument() const;
    MediaQuerySet* mediaQueries() const { return m_mediaQueries.get(); }
    void setMediaQueries(PassRefPtr<MediaQuerySet>);

    class RuleMutationScope {
        WTF_MAKE_NONCOPYABLE(RuleMutationScope);
        STACK_ALLOCATED();
    public:
        explicit RuleMutationScope(CSSStyleSheet*);
        ~RuleMutationScope();

    private:
        RawPtr<CSSStyleSheet> m_styleSheet;
    };

    void willMutateRules();
    void didMutateRules();
    void didMutate(StyleSheetUpdateType = PartialRuleUpdate);

    StyleSheetContents* contents() const { return m_contents.get(); }

    bool isInline() const { return m_isInlineStylesheet; }
    TextPosition startPositionInSource() const { return m_startPosition; }

private:
    CSSStyleSheet(PassRefPtr<StyleSheetContents>);
    CSSStyleSheet(PassRefPtr<StyleSheetContents>, Node* ownerNode, bool isInlineStylesheet, const TextPosition& startPosition);

    virtual bool isCSSStyleSheet() const override { return true; }
    virtual String type() const override { return "text/css"; }

    RefPtr<StyleSheetContents> m_contents;
    bool m_isInlineStylesheet;
    RefPtr<MediaQuerySet> m_mediaQueries;

    RawPtr<Node> m_ownerNode;

    TextPosition m_startPosition;
};

inline CSSStyleSheet::RuleMutationScope::RuleMutationScope(CSSStyleSheet* sheet)
    : m_styleSheet(sheet)
{
    if (m_styleSheet)
        m_styleSheet->willMutateRules();
}

inline CSSStyleSheet::RuleMutationScope::~RuleMutationScope()
{
    if (m_styleSheet)
        m_styleSheet->didMutateRules();
}

DEFINE_TYPE_CASTS(CSSStyleSheet, StyleSheet, sheet, sheet->isCSSStyleSheet(), sheet.isCSSStyleSheet());

} // namespace blink

#endif  // SKY_ENGINE_CORE_CSS_CSSSTYLESHEET_H_
