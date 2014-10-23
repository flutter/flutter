/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 *           (C) 1999 Antti Koivisto (koivisto@kde.org)
 *           (C) 2001 Dirk Mueller (mueller@kde.org)
 * Copyright (C) 2004, 2006, 2007 Apple Inc. All rights reserved.
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

#ifndef NodeList_h
#define NodeList_h

#include "bindings/core/v8/ScriptWrappable.h"
#include "wtf/RefCounted.h"

namespace blink {

class Node;

class NodeList : public RefCountedWillBeGarbageCollectedFinalized<NodeList>, public ScriptWrappable {
    DEFINE_WRAPPERTYPEINFO();
public:
    virtual ~NodeList() { }

    // DOM methods & attributes for NodeList
    virtual unsigned length() const = 0;
    virtual Node* item(unsigned index) const = 0;

    // Other methods (not part of DOM)
    virtual bool isEmptyNodeList() const { return false; }
    virtual bool isChildNodeList() const { return false; }

    virtual Node* virtualOwnerNode() const { return 0; }

    virtual void trace(Visitor*) { }

protected:
    NodeList()
    {
        ScriptWrappable::init(this);
    }
};

} // namespace blink

#endif // NodeList_h
