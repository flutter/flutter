// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef StyleInvalidator_h
#define StyleInvalidator_h

#include "platform/heap/Handle.h"

namespace blink {

class DescendantInvalidationSet;
class Document;
class Element;

class StyleInvalidator {
    DISALLOW_ALLOCATION();
public:
    StyleInvalidator();
    ~StyleInvalidator();
    void invalidate(Document&);
    void scheduleInvalidation(PassRefPtrWillBeRawPtr<DescendantInvalidationSet>, Element&);

    // Clears all style invalidation state for the passed node.
    void clearInvalidation(Node&);

    void clearPendingInvalidations();

    void trace(Visitor*);

private:
    struct RecursionData {
        RecursionData()
            : m_invalidateCustomPseudo(false)
            , m_wholeSubtreeInvalid(false)
            , m_treeBoundaryCrossing(false)
        { }

        void pushInvalidationSet(const DescendantInvalidationSet&);
        bool matchesCurrentInvalidationSets(Element&);
        bool hasInvalidationSets() const { return !wholeSubtreeInvalid() && m_invalidationSets.size(); }

        bool wholeSubtreeInvalid() const { return m_wholeSubtreeInvalid; }
        void setWholeSubtreeInvalid() { m_wholeSubtreeInvalid = true; }

        bool treeBoundaryCrossing() const { return m_treeBoundaryCrossing; }

        typedef Vector<const DescendantInvalidationSet*, 16> InvalidationSets;
        InvalidationSets m_invalidationSets;
        bool m_invalidateCustomPseudo;
        bool m_wholeSubtreeInvalid;
        bool m_treeBoundaryCrossing;
    };

    bool invalidate(Element&, RecursionData&);
    bool invalidateChildren(Element&, RecursionData&);
    bool checkInvalidationSetsAgainstElement(Element&, RecursionData&);

    class RecursionCheckpoint {
    public:
        RecursionCheckpoint(RecursionData* data)
            : m_prevInvalidationSetsSize(data->m_invalidationSets.size())
            , m_prevInvalidateCustomPseudo(data->m_invalidateCustomPseudo)
            , m_prevWholeSubtreeInvalid(data->m_wholeSubtreeInvalid)
            , m_treeBoundaryCrossing(data->m_treeBoundaryCrossing)
            , m_data(data)
        { }
        ~RecursionCheckpoint()
        {
            m_data->m_invalidationSets.remove(m_prevInvalidationSetsSize, m_data->m_invalidationSets.size() - m_prevInvalidationSetsSize);
            m_data->m_invalidateCustomPseudo = m_prevInvalidateCustomPseudo;
            m_data->m_wholeSubtreeInvalid = m_prevWholeSubtreeInvalid;
            m_data->m_treeBoundaryCrossing = m_treeBoundaryCrossing;
        }

    private:
        int m_prevInvalidationSetsSize;
        bool m_prevInvalidateCustomPseudo;
        bool m_prevWholeSubtreeInvalid;
        bool m_treeBoundaryCrossing;
        RecursionData* m_data;
    };

    typedef WillBeHeapVector<RefPtrWillBeMember<DescendantInvalidationSet> > InvalidationList;
    typedef WillBeHeapHashMap<RawPtrWillBeMember<Element>, OwnPtrWillBeMember<InvalidationList> > PendingInvalidationMap;

    InvalidationList& ensurePendingInvalidationList(Element&);

    PendingInvalidationMap m_pendingInvalidationMap;
};

} // namespace blink

#endif // StyleInvalidator_h
