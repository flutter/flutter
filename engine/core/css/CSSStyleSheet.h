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

#ifndef CSSStyleSheet_h
#define CSSStyleSheet_h

#include "core/css/CSSRule.h"
#include "core/css/StyleSheet.h"
#include "platform/heap/Handle.h"
#include "wtf/Noncopyable.h"
#include "wtf/text/TextPosition.h"

namespace blink {

class BisonCSSParser;
class CSSRule;
class CSSRuleList;
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
    DEFINE_WRAPPERTYPEINFO();
public:
    static PassRefPtrWillBeRawPtr<CSSStyleSheet> create(PassRefPtrWillBeRawPtr<StyleSheetContents>);
    static PassRefPtrWillBeRawPtr<CSSStyleSheet> createInline(Node*, const KURL&, const TextPosition& startPosition = TextPosition::minimumPosition());
    static PassRefPtrWillBeRawPtr<CSSStyleSheet> createInline(PassRefPtrWillBeRawPtr<StyleSheetContents>, Node* ownerNode, const TextPosition& startPosition = TextPosition::minimumPosition());

    virtual ~CSSStyleSheet();

    virtual Node* ownerNode() const override { return m_ownerNode; }
    virtual MediaList* media() const override;

    PassRefPtrWillBeRawPtr<CSSRuleList> cssRules();
    unsigned insertRule(const String& rule, unsigned index, ExceptionState&);
    unsigned insertRule(const String& rule, ExceptionState&); // Deprecated.
    void deleteRule(unsigned index, ExceptionState&);

    // IE Extensions
    PassRefPtrWillBeRawPtr<CSSRuleList> rules();
    int addRule(const String& selector, const String& style, int index, ExceptionState&);
    int addRule(const String& selector, const String& style, ExceptionState&);
    void removeRule(unsigned index, ExceptionState& exceptionState) { deleteRule(index, exceptionState); }

    // For CSSRuleList.
    unsigned length() const;
    CSSRule* item(unsigned index);

    virtual void clearOwnerNode() override;

    virtual KURL baseURL() const override;

    Document* ownerDocument() const;
    MediaQuerySet* mediaQueries() const { return m_mediaQueries.get(); }
    void setMediaQueries(PassRefPtrWillBeRawPtr<MediaQuerySet>);

    class RuleMutationScope {
        WTF_MAKE_NONCOPYABLE(RuleMutationScope);
        STACK_ALLOCATED();
    public:
        explicit RuleMutationScope(CSSStyleSheet*);
        explicit RuleMutationScope(CSSRule*);
        ~RuleMutationScope();

    private:
        RawPtrWillBeMember<CSSStyleSheet> m_styleSheet;
    };

    void willMutateRules();
    void didMutateRules();
    void didMutate(StyleSheetUpdateType = PartialRuleUpdate);

    void clearChildRuleCSSOMWrappers();

    StyleSheetContents* contents() const { return m_contents.get(); }

    bool isInline() const { return m_isInlineStylesheet; }
    TextPosition startPositionInSource() const { return m_startPosition; }

    virtual void trace(Visitor*) override;

private:
    CSSStyleSheet(PassRefPtrWillBeRawPtr<StyleSheetContents>);
    CSSStyleSheet(PassRefPtrWillBeRawPtr<StyleSheetContents>, Node* ownerNode, bool isInlineStylesheet, const TextPosition& startPosition);

    virtual bool isCSSStyleSheet() const override { return true; }
    virtual String type() const override { return "text/css"; }

    void reattachChildRuleCSSOMWrappers();

    RefPtrWillBeMember<StyleSheetContents> m_contents;
    bool m_isInlineStylesheet;
    RefPtrWillBeMember<MediaQuerySet> m_mediaQueries;

    RawPtrWillBeMember<Node> m_ownerNode;

    TextPosition m_startPosition;
    mutable RefPtrWillBeMember<MediaList> m_mediaCSSOMWrapper;
    mutable WillBeHeapVector<RefPtrWillBeMember<CSSRule> > m_childRuleCSSOMWrappers;
    mutable OwnPtrWillBeMember<CSSRuleList> m_ruleListCSSOMWrapper;
};

inline CSSStyleSheet::RuleMutationScope::RuleMutationScope(CSSStyleSheet* sheet)
    : m_styleSheet(sheet)
{
    if (m_styleSheet)
        m_styleSheet->willMutateRules();
}

inline CSSStyleSheet::RuleMutationScope::RuleMutationScope(CSSRule* rule)
    : m_styleSheet(rule ? rule->parentStyleSheet() : 0)
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

#endif
