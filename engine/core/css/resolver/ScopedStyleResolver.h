/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 * Copyright (C) 2003, 2004, 2005, 2006, 2007, 2008, 2009, 2010, 2011 Apple Inc. All rights reserved.
 * Copyright (C) 2012 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1.  Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 * 2.  Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. AND ITS CONTRIBUTORS ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL APPLE INC. OR ITS CONTRIBUTORS BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
 * ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef SKY_ENGINE_CORE_CSS_RESOLVER_SCOPEDSTYLERESOLVER_H_
#define SKY_ENGINE_CORE_CSS_RESOLVER_SCOPEDSTYLERESOLVER_H_

#include "sky/engine/core/css/ElementRuleCollector.h"
#include "sky/engine/core/css/RuleSet.h"
#include "sky/engine/core/dom/TreeScope.h"
#include "sky/engine/wtf/HashMap.h"
#include "sky/engine/wtf/HashSet.h"
#include "sky/engine/wtf/OwnPtr.h"
#include "sky/engine/wtf/PassOwnPtr.h"

namespace blink {

class StyleSheetContents;
class RuleFeatureSet;

// This class selects a RenderStyle for a given element based on a collection of stylesheets.
class ScopedStyleResolver final {
    WTF_MAKE_NONCOPYABLE(ScopedStyleResolver);
    WTF_MAKE_FAST_ALLOCATED;
public:
    static PassOwnPtr<ScopedStyleResolver> create(TreeScope& scope)
    {
        return adoptPtr(new ScopedStyleResolver(scope));
    }

    const TreeScope& treeScope() const { return *m_scope; }

public:
    const StyleRuleKeyframes* keyframeStylesForAnimation(String animationName);

    void collectMatchingAuthorRules(ElementRuleCollector&, CascadeScope, CascadeOrder = ignoreCascadeOrder);
    void addRulesFromSheet(CSSStyleSheet*);

    void resetAuthorStyle();

    const RuleFeatureSet& features() const { return m_features; }

private:
    explicit ScopedStyleResolver(TreeScope&);

    RawPtr<TreeScope> m_scope;
    Vector<RawPtr<CSSStyleSheet> > m_authorStyleSheets;

    RuleFeatureSet m_features;
};

} // namespace blink

#endif  // SKY_ENGINE_CORE_CSS_RESOLVER_SCOPEDSTYLERESOLVER_H_
