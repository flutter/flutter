/*
 * (C) 1999-2003 Lars Knoll (knoll@kde.org)
 * (C) 2002-2003 Dirk Mueller (mueller@kde.org)
 * Copyright (C) 2002, 2006, 2008, 2012 Apple Inc. All rights reserved.
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

#ifndef CSSUnknownRule_h
#define CSSUnknownRule_h

#include "core/css/CSSRule.h"

namespace blink {

class CSSUnknownRule final : public CSSRule {
public:
    CSSUnknownRule() : CSSRule(0) { }
    virtual ~CSSUnknownRule() { }

    virtual CSSRule::Type type() const override { return UNKNOWN_RULE; }
    virtual String cssText() const override { return String(); }
    virtual void reattach(StyleRuleBase*) override { }
    virtual void trace(Visitor* visitor) override { CSSRule::trace(visitor); }
};

} // namespace blink

#endif // CSSUnknownRule_h
