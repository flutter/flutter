/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 *           (C) 1999 Antti Koivisto (koivisto@kde.org)
 *           (C) 2001 Peter Kelly (pmk@post.com)
 *           (C) 2001 Dirk Mueller (mueller@kde.org)
 * Copyright (C) 2003, 2004, 2005, 2006, 2007, 2008, 2009 Apple Inc. All rights reserved.
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
 *
 */

#ifndef Attr_h
#define Attr_h

#include "sky/engine/bindings/core/v8/ScriptWrappable.h"
#include "sky/engine/core/dom/QualifiedName.h"
#include "sky/engine/wtf/RefCounted.h"
#include "sky/engine/wtf/text/AtomicString.h"

namespace blink {

class Attr : public RefCounted<Attr>, public ScriptWrappable {
    DEFINE_WRAPPERTYPEINFO();
public:
    static PassRefPtr<Attr> create(const QualifiedName& name, const AtomicString& value);
    ~Attr();

    String name() const { return m_name.localName(); }
    const AtomicString& value() const { return m_value; }

private:
    Attr(const QualifiedName& name, const AtomicString& value);

    QualifiedName m_name;
    AtomicString m_value;
};

} // namespace blink

#endif // Attr_h
