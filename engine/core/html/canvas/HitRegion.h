// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_HTML_CANVAS_HITREGION_H_
#define SKY_ENGINE_CORE_HTML_CANVAS_HITREGION_H_

#include "sky/engine/core/dom/Element.h"
#include "sky/engine/platform/graphics/Path.h"
#include "sky/engine/platform/heap/Handle.h"
#include "sky/engine/wtf/Noncopyable.h"
#include "sky/engine/wtf/OwnPtr.h"
#include "sky/engine/wtf/PassOwnPtr.h"
#include "sky/engine/wtf/PassRefPtr.h"
#include "sky/engine/wtf/RefPtr.h"

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

private:
    explicit HitRegion(const HitRegionOptions&);

    String m_id;
    RefPtr<Element> m_control;
    Path m_path;
    WindRule m_fillRule;
};

class HitRegionManager final {
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

#endif  // SKY_ENGINE_CORE_HTML_CANVAS_HITREGION_H_
