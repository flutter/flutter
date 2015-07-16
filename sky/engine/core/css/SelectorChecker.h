/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 *           (C) 2004-2005 Allan Sandfeld Jensen (kde@carewolf.com)
 * Copyright (C) 2006, 2007 Nicholas Shanks (webkit@nickshanks.com)
 * Copyright (C) 2005, 2006, 2007, 2008, 2009, 2010, 2011, 2012, 2013 Apple Inc. All rights reserved.
 * Copyright (C) 2007 Alexey Proskuryakov <ap@webkit.org>
 * Copyright (C) 2007, 2008 Eric Seidel <eric@webkit.org>
 * Copyright (C) 2008, 2009 Torch Mobile Inc. All rights reserved. (http://www.torchmobile.com/)
 * Copyright (c) 2011, Code Aurora Forum. All rights reserved.
 * Copyright (C) Research In Motion Limited 2011. All rights reserved.
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

#ifndef SKY_ENGINE_CORE_CSS_SELECTORCHECKER_H_
#define SKY_ENGINE_CORE_CSS_SELECTORCHECKER_H_

#include "sky/engine/core/dom/Element.h"

namespace blink {

class CSSSelector;
class ContainerNode;
class Element;

class SelectorChecker {
    WTF_MAKE_NONCOPYABLE(SelectorChecker);
public:
    explicit SelectorChecker(const Element&);

    bool match(const CSSSelector&);

    bool matchedAttributeSelector() const { return m_matchedAttributeSelector; }
    bool matchedFocusSelector() const { return m_matchedFocusSelector; }
    bool matchedHoverSelector() const { return m_matchedHoverSelector; }
    bool matchedActiveSelector() const { return m_matchedActiveSelector; }

private:
    bool checkPseudoClass(const CSSSelector&);
    bool checkOne(const CSSSelector&);

    const Element& m_element;
    bool m_matchedAttributeSelector;
    bool m_matchedFocusSelector;
    bool m_matchedHoverSelector;
    bool m_matchedActiveSelector;
};

}

#endif  // SKY_ENGINE_CORE_CSS_SELECTORCHECKER_H_
