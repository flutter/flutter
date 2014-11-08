/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 *           (C) 2004-2005 Allan Sandfeld Jensen (kde@carewolf.com)
 * Copyright (C) 2006, 2007 Nicholas Shanks (webkit@nickshanks.com)
 * Copyright (C) 2005, 2006, 2007, 2008, 2009, 2010, 2011, 2012 Apple Inc. All rights reserved.
 * Copyright (C) 2007 Alexey Proskuryakov <ap@webkit.org>
 * Copyright (C) 2007, 2008 Eric Seidel <eric@webkit.org>
 * Copyright (C) 2008, 2009 Torch Mobile Inc. All rights reserved. (http://www.torchmobile.com/)
 * Copyright (c) 2011, Code Aurora Forum. All rights reserved.
 * Copyright (C) Research In Motion Limited 2011. All rights reserved.
 * Copyright (C) 2012 Google Inc. All rights reserved.
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

#include "config.h"
#include "core/css/CSSDefaultStyleSheets.h"

#include "core/css/MediaQueryEvaluator.h"
#include "core/css/RuleSet.h"
#include "core/css/StyleSheetContents.h"
#include "wtf/LeakAnnotations.h"

namespace blink {

CSSDefaultStyleSheets& CSSDefaultStyleSheets::instance()
{
    DEFINE_STATIC_LOCAL(OwnPtr<CSSDefaultStyleSheets>, cssDefaultStyleSheets, (adoptPtr(new CSSDefaultStyleSheets())));
    return *cssDefaultStyleSheets;
}

static const MediaQueryEvaluator& screenEval()
{
    DEFINE_STATIC_LOCAL(const MediaQueryEvaluator, staticScreenEval, ("screen"));
    return staticScreenEval;
}

static PassRefPtr<StyleSheetContents> parseUASheet(const String& str)
{
    RefPtr<StyleSheetContents> sheet = StyleSheetContents::create(CSSParserContext(0));
    sheet->parseString(str);
    // User Agent stylesheets are parsed once for the lifetime of the renderer
    // and are intentionally leaked.
    WTF_ANNOTATE_LEAKING_OBJECT_PTR(sheet.get());
    return sheet.release();
}

CSSDefaultStyleSheets::CSSDefaultStyleSheets()
    : m_defaultStyle(nullptr)
    , m_defaultViewportStyle(nullptr)
    , m_defaultStyleSheet(nullptr)
    , m_viewportStyleSheet(nullptr)
{
    m_defaultStyle = RuleSet::create();
    m_defaultViewportStyle = RuleSet::create();

    String defaultRules =
        "link, import, meta, script, style, template, title {\n"
        "    display: none;\n"
        "}\n"
        "a {\n"
        "    color: blue;\n"
        "    display: inline;\n"
        "    text-decoration: underline;\n"
        "}\n";

    m_defaultStyleSheet = parseUASheet(defaultRules);
    m_defaultStyle->addRulesFromSheet(defaultStyleSheet(), screenEval());
    m_viewportStyleSheet = parseUASheet(String());
    m_defaultViewportStyle->addRulesFromSheet(viewportStyleSheet(), screenEval());
}

} // namespace blink
