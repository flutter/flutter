/*
 * (C) 1999-2003 Lars Knoll (knoll@kde.org)
 * Copyright (C) 2004, 2006, 2008, 2012 Apple Inc. All rights reserved.
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

#ifndef SKY_ENGINE_CORE_CSS_STYLESHEET_H_
#define SKY_ENGINE_CORE_CSS_STYLESHEET_H_

#include "sky/engine/bindings/core/v8/ScriptWrappable.h"
#include "sky/engine/core/css/parser/CSSParserMode.h"
#include "sky/engine/platform/heap/Handle.h"
#include "sky/engine/wtf/Forward.h"
#include "sky/engine/wtf/RefCounted.h"

namespace blink {

class CSSRule;
class KURL;
class MediaList;
class Node;
class StyleSheet;

class StyleSheet : public RefCounted<StyleSheet>, public ScriptWrappable {
    DEFINE_WRAPPERTYPEINFO();
public:
    StyleSheet()
    {
    }
    virtual ~StyleSheet();

    virtual Node* ownerNode() const = 0;
    virtual MediaList* media() const { return 0; }
    virtual String type() const = 0;

    virtual void clearOwnerNode() = 0;
    virtual KURL baseURL() const = 0;
    virtual bool isCSSStyleSheet() const { return false; }
};

} // namespace blink

#endif  // SKY_ENGINE_CORE_CSS_STYLESHEET_H_
