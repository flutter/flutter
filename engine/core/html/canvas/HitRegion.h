// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef HitRegion_h
#define HitRegion_h

#include "bindings/core/v8/Dictionary.h"
#include "core/dom/Element.h"
#include "platform/graphics/Path.h"
#include "platform/heap/Handle.h"
#include "wtf/Noncopyable.h"
#include "wtf/OwnPtr.h"
#include "wtf/PassOwnPtr.h"
#include "wtf/PassRefPtr.h"
#include "wtf/RefPtr.h"

namespace blink {

struct HitRegionOptions {
    STACK_ALLOCATED();

public:
    String id;
    RefPtr<Element> control;
    Path path;
    WindRule fillRule;
};

class HitRegion final : public RefCounted<HitRegion> {
public:
    static PassRefPtr<HitRegion> create(const HitRegionOptions& options)
    {
        return adoptRef(new HitRegion(options));
    }

    virtual ~HitRegion() { }

    void removePixels(const Path&);
    void updateAccessibility(Element* canvas);

    bool contains(const LayoutPoint&) const;

    const String& id() const { return m_id; }
    const Path& path() const { return m_path; }
    Element* control() const { return m_control.get(); }
    WindRule fillRule() const { return m_fillRule; }

    void trace(Visitor*);

private:
    explicit HitRegion(const HitRegionOptions&);

    String m_id;
    RefPtr<Element> m_control;
    Path m_path;
    WindRule m_fillRule;
};

class HitRegionManager final : public DummyBase<HitRegionManager> {
    WTF_MAKE_NONCOPYABLE(HitRegionManager);
    DECLARE_EMPTY_DESTRUCTOR_WILL_BE_REMOVED(HitRegionManager)
public:
    static PassOwnPtr<HitRegionManager> create() { return adoptPtr(new HitRegionManager()); }

    void addHitRegion(PassRefPtr<HitRegion>);

    void removeHitRegion(HitRegion*);
    void removeHitRegionById(const String& id);
    void removeHitRegionByControl(Element*);
    void removeHitRegionsInRect(const FloatRect&, const AffineTransform&);
    void removeAllHitRegions();

    HitRegion* getHitRegionById(const String& id) const;
    HitRegion* getHitRegionByControl(Element*) const;
    HitRegion* getHitRegionAtPoint(const LayoutPoint&) const;

    unsigned getHitRegionsCount() const;

    void trace(Visitor*);

private:
    HitRegionManager() { }

    typedef ListHashSet<RefPtr<HitRegion> > HitRegionList;
    typedef HitRegionList::const_reverse_iterator HitRegionIterator;
    typedef HashMap<String, RefPtr<HitRegion> > HitRegionIdMap;
    typedef HashMap<RefPtr<Element>, RefPtr<HitRegion> > HitRegionControlMap;

    HitRegionList m_hitRegionList;
    HitRegionIdMap m_hitRegionIdMap;
    HitRegionControlMap m_hitRegionControlMap;
};

} // namespace blink

#endif
