/*
 * Copyright (C) 1999-2003 Lars Knoll (knoll@kde.org)
 * Copyright (C) 2004, 2005, 2006, 2007, 2008 Apple Inc. All rights reserved.
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

#ifndef Rect_h
#define Rect_h

#include "bindings/core/v8/ScriptWrappable.h"
#include "core/css/CSSPrimitiveValue.h"
#include "wtf/RefPtr.h"
#include "wtf/text/StringBuilder.h"

namespace blink {

class RectBase : public RefCounted<RectBase>, public ScriptWrappableBase {
    DECLARE_EMPTY_DESTRUCTOR_WILL_BE_REMOVED(RectBase);
public:
    CSSPrimitiveValue* top() const { return m_top.get(); }
    CSSPrimitiveValue* right() const { return m_right.get(); }
    CSSPrimitiveValue* bottom() const { return m_bottom.get(); }
    CSSPrimitiveValue* left() const { return m_left.get(); }

    void setTop(PassRefPtr<CSSPrimitiveValue> top) { m_top = top; }
    void setRight(PassRefPtr<CSSPrimitiveValue> right) { m_right = right; }
    void setBottom(PassRefPtr<CSSPrimitiveValue> bottom) { m_bottom = bottom; }
    void setLeft(PassRefPtr<CSSPrimitiveValue> left) { m_left = left; }

    bool equals(const RectBase& other) const
    {
        return compareCSSValuePtr(m_top, other.m_top)
            && compareCSSValuePtr(m_right, other.m_right)
            && compareCSSValuePtr(m_left, other.m_left)
            && compareCSSValuePtr(m_bottom, other.m_bottom);
    }

protected:
    RectBase() { }
    RectBase(const RectBase& cloneFrom)
        : m_top(cloneFrom.m_top ? cloneFrom.m_top->cloneForCSSOM() : nullptr)
        , m_right(cloneFrom.m_right ? cloneFrom.m_right->cloneForCSSOM() : nullptr)
        , m_bottom(cloneFrom.m_bottom ? cloneFrom.m_bottom->cloneForCSSOM() : nullptr)
        , m_left(cloneFrom.m_left ? cloneFrom.m_left->cloneForCSSOM() : nullptr)
    {
    }

private:
    RefPtr<CSSPrimitiveValue> m_top;
    RefPtr<CSSPrimitiveValue> m_right;
    RefPtr<CSSPrimitiveValue> m_bottom;
    RefPtr<CSSPrimitiveValue> m_left;
};

class Rect : public RectBase {
public:
    static PassRefPtr<Rect> create() { return adoptRef(new Rect); }

    PassRefPtr<Rect> cloneForCSSOM() const { return adoptRef(new Rect(*this)); }

    String cssText() const
    {
        return generateCSSString(top()->cssText(), right()->cssText(), bottom()->cssText(), left()->cssText());
    }

private:
    Rect() { }
    Rect(const Rect& cloneFrom) : RectBase(cloneFrom) { }
    static String generateCSSString(const String& top, const String& right, const String& bottom, const String& left)
    {
        return "rect(" + top + ' ' + right + ' ' + bottom + ' ' + left + ')';
    }

    // NOTE: If adding fields to this class please make the RectBase trace
    // method virtual and add a trace method in this subclass tracing the new
    // fields.
};

class Quad : public RectBase {
public:
    static PassRefPtr<Quad> create() { return adoptRef(new Quad); }

    PassRefPtr<Quad> cloneForCSSOM() const { return adoptRef(new Quad(*this)); }

    String cssText() const
    {
        return generateCSSString(top()->cssText(), right()->cssText(), bottom()->cssText(), left()->cssText());
    }

private:
    Quad() { }
    Quad(const Quad& cloneFrom) : RectBase(cloneFrom) { }
    static String generateCSSString(const String& top, const String& right, const String& bottom, const String& left)
    {
        StringBuilder result;
        // reserve space for the four strings, plus three space separator characters.
        result.reserveCapacity(top.length() + right.length() + bottom.length() + left.length() + 3);
        result.append(top);
        if (right != top || bottom != top || left != top) {
            result.append(' ');
            result.append(right);
            if (bottom != top || right != left) {
                result.append(' ');
                result.append(bottom);
                if (left != right) {
                    result.append(' ');
                    result.append(left);
                }
            }
        }
        return result.toString();
    }

    // NOTE: If adding fields to this class please make the RectBase trace
    // method virtual and add a trace method in this subclass tracing the new
    // fields.
};

} // namespace blink

#endif // Rect_h
