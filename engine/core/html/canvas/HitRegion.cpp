// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "config.h"
#include "core/html/canvas/HitRegion.h"

#include "core/rendering/RenderBoxModelObject.h"

namespace blink {

HitRegion::HitRegion(const HitRegionOptions& options)
    : m_id(options.id)
    , m_control(options.control)
    , m_path(options.path)
    , m_fillRule(options.fillRule)
{
}

void HitRegion::updateAccessibility(Element* canvas)
{
}

bool HitRegion::contains(const LayoutPoint& point) const
{
    return m_path.contains(point, m_fillRule);
}

void HitRegion::removePixels(const Path& clearArea)
{
    m_path.subtractPath(clearArea);
}

void HitRegion::trace(Visitor* visitor)
{
    visitor->trace(m_control);
}

void HitRegionManager::addHitRegion(PassRefPtr<HitRegion> passHitRegion)
{
    RefPtr<HitRegion> hitRegion = passHitRegion;

    m_hitRegionList.add(hitRegion);

    if (!hitRegion->id().isEmpty())
        m_hitRegionIdMap.set(hitRegion->id(), hitRegion);

    if (hitRegion->control())
        m_hitRegionControlMap.set(hitRegion->control(), hitRegion);
}

void HitRegionManager::removeHitRegion(HitRegion* hitRegion)
{
    if (!hitRegion)
        return;

    if (!hitRegion->id().isEmpty())
        m_hitRegionIdMap.remove(hitRegion->id());

    if (hitRegion->control())
        m_hitRegionControlMap.remove(hitRegion->control());

    m_hitRegionList.remove(hitRegion);
}

void HitRegionManager::removeHitRegionById(const String& id)
{
    if (!id.isEmpty())
        removeHitRegion(getHitRegionById(id));
}

void HitRegionManager::removeHitRegionByControl(Element* control)
{
    removeHitRegion(getHitRegionByControl(control));
}

void HitRegionManager::removeHitRegionsInRect(const FloatRect& rect, const AffineTransform& ctm)
{
    Path clearArea;
    clearArea.addRect(rect);
    clearArea.transform(ctm);

    HitRegionIterator itEnd = m_hitRegionList.rend();
    HitRegionList toBeRemoved;

    for (HitRegionIterator it = m_hitRegionList.rbegin(); it != itEnd; ++it) {
        RefPtr<HitRegion> hitRegion = *it;
        hitRegion->removePixels(clearArea);
        if (hitRegion->path().isEmpty())
            toBeRemoved.add(hitRegion);
    }

    itEnd = toBeRemoved.rend();
    for (HitRegionIterator it = toBeRemoved.rbegin(); it != itEnd; ++it)
        removeHitRegion(it->get());
}

void HitRegionManager::removeAllHitRegions()
{
    m_hitRegionList.clear();
    m_hitRegionIdMap.clear();
    m_hitRegionControlMap.clear();
}

HitRegion* HitRegionManager::getHitRegionById(const String& id) const
{
    return m_hitRegionIdMap.get(id);
}

HitRegion* HitRegionManager::getHitRegionByControl(Element* control) const
{
    if (control)
        return m_hitRegionControlMap.get(control);

    return 0;
}

HitRegion* HitRegionManager::getHitRegionAtPoint(const LayoutPoint& point) const
{
    HitRegionIterator itEnd = m_hitRegionList.rend();

    for (HitRegionIterator it = m_hitRegionList.rbegin(); it != itEnd; ++it) {
        RefPtr<HitRegion> hitRegion = *it;
        if (hitRegion->contains(point))
            return hitRegion.get();
    }

    return 0;
}

unsigned HitRegionManager::getHitRegionsCount() const
{
    return m_hitRegionList.size();
}

void HitRegionManager::trace(Visitor* visitor)
{
#if ENABLE(OILPAN)
    visitor->trace(m_hitRegionList);
    visitor->trace(m_hitRegionIdMap);
    visitor->trace(m_hitRegionControlMap);
#endif
}

DEFINE_EMPTY_DESTRUCTOR_WILL_BE_REMOVED(HitRegionManager)

} // namespace blink
