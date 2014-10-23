/*
 * Copyright (C) 2011 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 *     * Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 * copyright notice, this list of conditions and the following disclaimer
 * in the documentation and/or other materials provided with the
 * distribution.
 *     * Neither the name of Google Inc. nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "config.h"

#include "core/dom/MutationRecord.h"

#include "core/dom/Node.h"
#include "core/dom/NodeList.h"
#include "core/dom/QualifiedName.h"
#include "core/dom/StaticNodeList.h"
#include "wtf/StdLibExtras.h"

namespace blink {

namespace {

class ChildListRecord : public MutationRecord {
public:
    ChildListRecord(PassRefPtrWillBeRawPtr<Node> target, PassRefPtrWillBeRawPtr<StaticNodeList> added, PassRefPtrWillBeRawPtr<StaticNodeList> removed, PassRefPtrWillBeRawPtr<Node> previousSibling, PassRefPtrWillBeRawPtr<Node> nextSibling)
        : m_target(target)
        , m_addedNodes(added)
        , m_removedNodes(removed)
        , m_previousSibling(previousSibling)
        , m_nextSibling(nextSibling)
    {
    }

    virtual void trace(Visitor* visitor) OVERRIDE
    {
        visitor->trace(m_target);
        visitor->trace(m_addedNodes);
        visitor->trace(m_removedNodes);
        visitor->trace(m_previousSibling);
        visitor->trace(m_nextSibling);
        MutationRecord::trace(visitor);
    }

private:
    virtual const AtomicString& type() OVERRIDE;
    virtual Node* target() OVERRIDE { return m_target.get(); }
    virtual StaticNodeList* addedNodes() OVERRIDE { return m_addedNodes.get(); }
    virtual StaticNodeList* removedNodes() OVERRIDE { return m_removedNodes.get(); }
    virtual Node* previousSibling() OVERRIDE { return m_previousSibling.get(); }
    virtual Node* nextSibling() OVERRIDE { return m_nextSibling.get(); }

    RefPtrWillBeMember<Node> m_target;
    RefPtrWillBeMember<StaticNodeList> m_addedNodes;
    RefPtrWillBeMember<StaticNodeList> m_removedNodes;
    RefPtrWillBeMember<Node> m_previousSibling;
    RefPtrWillBeMember<Node> m_nextSibling;
};

class RecordWithEmptyNodeLists : public MutationRecord {
public:
    RecordWithEmptyNodeLists(PassRefPtrWillBeRawPtr<Node> target, const String& oldValue)
        : m_target(target)
        , m_oldValue(oldValue)
    {
    }

    virtual void trace(Visitor* visitor) OVERRIDE
    {
        visitor->trace(m_target);
        visitor->trace(m_addedNodes);
        visitor->trace(m_removedNodes);
        MutationRecord::trace(visitor);
    }

private:
    virtual Node* target() OVERRIDE { return m_target.get(); }
    virtual String oldValue() OVERRIDE { return m_oldValue; }
    virtual StaticNodeList* addedNodes() OVERRIDE { return lazilyInitializeEmptyNodeList(m_addedNodes); }
    virtual StaticNodeList* removedNodes() OVERRIDE { return lazilyInitializeEmptyNodeList(m_removedNodes); }

    static StaticNodeList* lazilyInitializeEmptyNodeList(RefPtrWillBeMember<StaticNodeList>& nodeList)
    {
        if (!nodeList)
            nodeList = StaticNodeList::createEmpty();
        return nodeList.get();
    }

    RefPtrWillBeMember<Node> m_target;
    String m_oldValue;
    RefPtrWillBeMember<StaticNodeList> m_addedNodes;
    RefPtrWillBeMember<StaticNodeList> m_removedNodes;
};

class AttributesRecord : public RecordWithEmptyNodeLists {
public:
    AttributesRecord(PassRefPtrWillBeRawPtr<Node> target, const QualifiedName& name, const AtomicString& oldValue)
        : RecordWithEmptyNodeLists(target, oldValue)
        , m_attributeName(name.localName())
    {
    }

private:
    virtual const AtomicString& type() OVERRIDE;
    virtual const AtomicString& attributeName() OVERRIDE { return m_attributeName; }

    AtomicString m_attributeName;
};

class CharacterDataRecord : public RecordWithEmptyNodeLists {
public:
    CharacterDataRecord(PassRefPtrWillBeRawPtr<Node> target, const String& oldValue)
        : RecordWithEmptyNodeLists(target, oldValue)
    {
    }

private:
    virtual const AtomicString& type() OVERRIDE;
};

class MutationRecordWithNullOldValue : public MutationRecord {
public:
    MutationRecordWithNullOldValue(PassRefPtrWillBeRawPtr<MutationRecord> record)
        : m_record(record)
    {
    }

    virtual void trace(Visitor* visitor) OVERRIDE
    {
        visitor->trace(m_record);
        MutationRecord::trace(visitor);
    }

private:
    virtual const AtomicString& type() OVERRIDE { return m_record->type(); }
    virtual Node* target() OVERRIDE { return m_record->target(); }
    virtual StaticNodeList* addedNodes() OVERRIDE { return m_record->addedNodes(); }
    virtual StaticNodeList* removedNodes() OVERRIDE { return m_record->removedNodes(); }
    virtual Node* previousSibling() OVERRIDE { return m_record->previousSibling(); }
    virtual Node* nextSibling() OVERRIDE { return m_record->nextSibling(); }
    virtual const AtomicString& attributeName() OVERRIDE { return m_record->attributeName(); }

    virtual String oldValue() OVERRIDE { return String(); }

    RefPtrWillBeMember<MutationRecord> m_record;
};

const AtomicString& ChildListRecord::type()
{
    DEFINE_STATIC_LOCAL(AtomicString, childList, ("childList", AtomicString::ConstructFromLiteral));
    return childList;
}

const AtomicString& AttributesRecord::type()
{
    DEFINE_STATIC_LOCAL(AtomicString, attributes, ("attributes", AtomicString::ConstructFromLiteral));
    return attributes;
}

const AtomicString& CharacterDataRecord::type()
{
    DEFINE_STATIC_LOCAL(AtomicString, characterData, ("characterData", AtomicString::ConstructFromLiteral));
    return characterData;
}

} // namespace

PassRefPtrWillBeRawPtr<MutationRecord> MutationRecord::createChildList(PassRefPtrWillBeRawPtr<Node> target, PassRefPtrWillBeRawPtr<StaticNodeList> added, PassRefPtrWillBeRawPtr<StaticNodeList> removed, PassRefPtrWillBeRawPtr<Node> previousSibling, PassRefPtrWillBeRawPtr<Node> nextSibling)
{
    return adoptRefWillBeNoop(new ChildListRecord(target, added, removed, previousSibling, nextSibling));
}

PassRefPtrWillBeRawPtr<MutationRecord> MutationRecord::createAttributes(PassRefPtrWillBeRawPtr<Node> target, const QualifiedName& name, const AtomicString& oldValue)
{
    return adoptRefWillBeNoop(new AttributesRecord(target, name, oldValue));
}

PassRefPtrWillBeRawPtr<MutationRecord> MutationRecord::createCharacterData(PassRefPtrWillBeRawPtr<Node> target, const String& oldValue)
{
    return adoptRefWillBeNoop(new CharacterDataRecord(target, oldValue));
}

PassRefPtrWillBeRawPtr<MutationRecord> MutationRecord::createWithNullOldValue(PassRefPtrWillBeRawPtr<MutationRecord> record)
{
    return adoptRefWillBeNoop(new MutationRecordWithNullOldValue(record));
}

MutationRecord::~MutationRecord()
{
}

} // namespace blink
