/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 *           (C) 1999 Antti Koivisto (koivisto@kde.org)
 *           (C) 2007 David Smith (catfish.man@gmail.com)
 * Copyright (C) 2003, 2004, 2005, 2006, 2007, 2008, 2009, 2010, 2011 Apple Inc. All rights reserved.
 * Copyright (C) Research In Motion Limited 2010. All rights reserved.
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

#include "config.h"
#include "core/rendering/FloatingObjects.h"

#include "core/rendering/RenderBlockFlow.h"
#include "core/rendering/RenderBox.h"
#include "core/rendering/RenderView.h"

using namespace WTF;

namespace blink {

struct SameSizeAsFloatingObject {
    void* pointers[2];
    LayoutRect rect;
    uint32_t bitfields : 8;
};

COMPILE_ASSERT(sizeof(FloatingObject) == sizeof(SameSizeAsFloatingObject), FloatingObject_should_stay_small);

FloatingObject::FloatingObject(RenderBox* renderer)
    : m_renderer(renderer)
    , m_originatingLine(0)
    , m_shouldPaint(true)
    , m_isDescendant(false)
    , m_isPlaced(false)
#if ENABLE(ASSERT)
    , m_isInPlacedTree(false)
#endif
{
    EFloat type = renderer->style()->floating();
    ASSERT(type != NoFloat);
    if (type == LeftFloat)
        m_type = FloatLeft;
    else if (type == RightFloat)
        m_type = FloatRight;
}

FloatingObject::FloatingObject(RenderBox* renderer, Type type, const LayoutRect& frameRect, bool shouldPaint, bool isDescendant)
    : m_renderer(renderer)
    , m_originatingLine(0)
    , m_frameRect(frameRect)
    , m_type(type)
    , m_shouldPaint(shouldPaint)
    , m_isDescendant(isDescendant)
    , m_isPlaced(true)
#if ENABLE(ASSERT)
    , m_isInPlacedTree(false)
#endif
{
}

PassOwnPtr<FloatingObject> FloatingObject::create(RenderBox* renderer)
{
    OwnPtr<FloatingObject> newObj = adoptPtr(new FloatingObject(renderer));
    newObj->setShouldPaint(!renderer->hasSelfPaintingLayer()); // If a layer exists, the float will paint itself. Otherwise someone else will.
    newObj->setIsDescendant(true);

    return newObj.release();
}

PassOwnPtr<FloatingObject> FloatingObject::copyToNewContainer(LayoutSize offset, bool shouldPaint, bool isDescendant) const
{
    return adoptPtr(new FloatingObject(renderer(), type(), LayoutRect(frameRect().location() - offset, frameRect().size()), shouldPaint, isDescendant));
}

PassOwnPtr<FloatingObject> FloatingObject::unsafeClone() const
{
    OwnPtr<FloatingObject> cloneObject = adoptPtr(new FloatingObject(renderer(), type(), m_frameRect, m_shouldPaint, m_isDescendant));
    cloneObject->m_isPlaced = m_isPlaced;
    return cloneObject.release();
}

template <FloatingObject::Type FloatTypeValue>
class ComputeFloatOffsetAdapter {
public:
    typedef FloatingObjectInterval IntervalType;

    ComputeFloatOffsetAdapter(const RenderBlockFlow* renderer, int lineTop, int lineBottom, LayoutUnit offset)
        : m_renderer(renderer)
        , m_lineTop(lineTop)
        , m_lineBottom(lineBottom)
        , m_offset(offset)
        , m_outermostFloat(0)
    {
    }

    virtual ~ComputeFloatOffsetAdapter() { }

    int lowValue() const { return m_lineTop; }
    int highValue() const { return m_lineBottom; }
    void collectIfNeeded(const IntervalType&);

    LayoutUnit offset() const { return m_offset; }

protected:
    virtual bool updateOffsetIfNeeded(const FloatingObject&) = 0;

    const RenderBlockFlow* m_renderer;
    int m_lineTop;
    int m_lineBottom;
    LayoutUnit m_offset;
    const FloatingObject* m_outermostFloat;
};

template <FloatingObject::Type FloatTypeValue>
class ComputeFloatOffsetForFloatLayoutAdapter : public ComputeFloatOffsetAdapter<FloatTypeValue> {
public:
    ComputeFloatOffsetForFloatLayoutAdapter(const RenderBlockFlow* renderer, LayoutUnit lineTop, LayoutUnit lineBottom, LayoutUnit offset)
        : ComputeFloatOffsetAdapter<FloatTypeValue>(renderer, lineTop, lineBottom, offset)
    {
    }

    virtual ~ComputeFloatOffsetForFloatLayoutAdapter() { }

    LayoutUnit heightRemaining() const;

protected:
    virtual bool updateOffsetIfNeeded(const FloatingObject&) OVERRIDE FINAL;
};

template <FloatingObject::Type FloatTypeValue>
class ComputeFloatOffsetForLineLayoutAdapter : public ComputeFloatOffsetAdapter<FloatTypeValue> {
public:
    ComputeFloatOffsetForLineLayoutAdapter(const RenderBlockFlow* renderer, LayoutUnit lineTop, LayoutUnit lineBottom, LayoutUnit offset)
        : ComputeFloatOffsetAdapter<FloatTypeValue>(renderer, lineTop, lineBottom, offset)
    {
    }

    virtual ~ComputeFloatOffsetForLineLayoutAdapter() { }

protected:
    virtual bool updateOffsetIfNeeded(const FloatingObject&) OVERRIDE FINAL;
};


FloatingObjects::~FloatingObjects()
{
}
void FloatingObjects::clearLineBoxTreePointers()
{
    // Clear references to originating lines, since the lines are being deleted
    FloatingObjectSetIterator end = m_set.end();
    for (FloatingObjectSetIterator it = m_set.begin(); it != end; ++it) {
        ASSERT(!((*it)->originatingLine()) || (*it)->originatingLine()->renderer() == m_renderer);
        (*it)->setOriginatingLine(0);
    }
}

FloatingObjects::FloatingObjects(const RenderBlockFlow* renderer, bool horizontalWritingMode)
    : m_placedFloatsTree(UninitializedTree)
    , m_leftObjectsCount(0)
    , m_rightObjectsCount(0)
    , m_horizontalWritingMode(horizontalWritingMode)
    , m_renderer(renderer)
    , m_cachedHorizontalWritingMode(false)
{
}

void FloatingObjects::clear()
{
    m_set.clear();
    m_placedFloatsTree.clear();
    m_leftObjectsCount = 0;
    m_rightObjectsCount = 0;
    markLowestFloatLogicalBottomCacheAsDirty();
}

LayoutUnit FloatingObjects::lowestFloatLogicalBottom(FloatingObject::Type floatType)
{
    bool isInHorizontalWritingMode = m_horizontalWritingMode;
    if (floatType != FloatingObject::FloatLeftRight) {
        if (hasLowestFloatLogicalBottomCached(isInHorizontalWritingMode, floatType))
            return getCachedlowestFloatLogicalBottom(floatType);
    } else {
        if (hasLowestFloatLogicalBottomCached(isInHorizontalWritingMode, FloatingObject::FloatLeft) && hasLowestFloatLogicalBottomCached(isInHorizontalWritingMode, FloatingObject::FloatRight)) {
            return std::max(getCachedlowestFloatLogicalBottom(FloatingObject::FloatLeft),
                getCachedlowestFloatLogicalBottom(FloatingObject::FloatRight));
        }
    }

    LayoutUnit lowestFloatBottom = 0;
    const FloatingObjectSet& floatingObjectSet = set();
    FloatingObjectSetIterator end = floatingObjectSet.end();
    if (floatType == FloatingObject::FloatLeftRight) {
        LayoutUnit lowestFloatBottomLeft = 0;
        LayoutUnit lowestFloatBottomRight = 0;
        for (FloatingObjectSetIterator it = floatingObjectSet.begin(); it != end; ++it) {
            FloatingObject* floatingObject = it->get();
            if (floatingObject->isPlaced()) {
                FloatingObject::Type curType = floatingObject->type();
                LayoutUnit curFloatLogicalBottom = m_renderer->logicalBottomForFloat(floatingObject);
                if (curType & FloatingObject::FloatLeft)
                    lowestFloatBottomLeft = std::max(lowestFloatBottomLeft, curFloatLogicalBottom);
                if (curType & FloatingObject::FloatRight)
                    lowestFloatBottomRight = std::max(lowestFloatBottomRight, curFloatLogicalBottom);
            }
        }
        lowestFloatBottom = std::max(lowestFloatBottomLeft, lowestFloatBottomRight);
        setCachedLowestFloatLogicalBottom(isInHorizontalWritingMode, FloatingObject::FloatLeft, lowestFloatBottomLeft);
        setCachedLowestFloatLogicalBottom(isInHorizontalWritingMode, FloatingObject::FloatRight, lowestFloatBottomRight);
    } else {
        for (FloatingObjectSetIterator it = floatingObjectSet.begin(); it != end; ++it) {
            FloatingObject* floatingObject = it->get();
            if (floatingObject->isPlaced() && floatingObject->type() == floatType)
                lowestFloatBottom = std::max(lowestFloatBottom, m_renderer->logicalBottomForFloat(floatingObject));
        }
        setCachedLowestFloatLogicalBottom(isInHorizontalWritingMode, floatType, lowestFloatBottom);
    }

    return lowestFloatBottom;
}

bool FloatingObjects::hasLowestFloatLogicalBottomCached(bool isHorizontal, FloatingObject::Type type) const
{
    int floatIndex = static_cast<int>(type) - 1;
    ASSERT(floatIndex < static_cast<int>(sizeof(m_lowestFloatBottomCache) / sizeof(FloatBottomCachedValue)));
    ASSERT(floatIndex >= 0);
    return (m_cachedHorizontalWritingMode == isHorizontal && !m_lowestFloatBottomCache[floatIndex].dirty);
}

LayoutUnit FloatingObjects::getCachedlowestFloatLogicalBottom(FloatingObject::Type type) const
{
    int floatIndex = static_cast<int>(type) - 1;
    ASSERT(floatIndex < static_cast<int>(sizeof(m_lowestFloatBottomCache) / sizeof(FloatBottomCachedValue)));
    ASSERT(floatIndex >= 0);
    return m_lowestFloatBottomCache[floatIndex].value;
}

void FloatingObjects::setCachedLowestFloatLogicalBottom(bool isHorizontal, FloatingObject::Type type, LayoutUnit value)
{
    int floatIndex = static_cast<int>(type) - 1;
    ASSERT(floatIndex < static_cast<int>(sizeof(m_lowestFloatBottomCache) / sizeof(FloatBottomCachedValue)));
    ASSERT(floatIndex >= 0);
    m_cachedHorizontalWritingMode = isHorizontal;
    m_lowestFloatBottomCache[floatIndex].value = value;
    m_lowestFloatBottomCache[floatIndex].dirty = false;
}

void FloatingObjects::markLowestFloatLogicalBottomCacheAsDirty()
{
    for (size_t i = 0; i < sizeof(m_lowestFloatBottomCache) / sizeof(FloatBottomCachedValue); ++i)
        m_lowestFloatBottomCache[i].dirty = true;
}

void FloatingObjects::moveAllToFloatInfoMap(RendererToFloatInfoMap& map)
{
    while (!m_set.isEmpty()) {
        OwnPtr<FloatingObject> floatingObject = m_set.takeFirst();
        RenderBox* renderer = floatingObject->renderer();
        map.add(renderer, floatingObject.release());
    }
    clear();
}

inline void FloatingObjects::increaseObjectsCount(FloatingObject::Type type)
{
    if (type == FloatingObject::FloatLeft)
        m_leftObjectsCount++;
    else
        m_rightObjectsCount++;
}

inline void FloatingObjects::decreaseObjectsCount(FloatingObject::Type type)
{
    if (type == FloatingObject::FloatLeft)
        m_leftObjectsCount--;
    else
        m_rightObjectsCount--;
}

inline FloatingObjectInterval FloatingObjects::intervalForFloatingObject(FloatingObject* floatingObject)
{
    if (m_horizontalWritingMode)
        return FloatingObjectInterval(floatingObject->frameRect().pixelSnappedY(), floatingObject->frameRect().pixelSnappedMaxY(), floatingObject);
    return FloatingObjectInterval(floatingObject->frameRect().pixelSnappedX(), floatingObject->frameRect().pixelSnappedMaxX(), floatingObject);
}

void FloatingObjects::addPlacedObject(FloatingObject* floatingObject)
{
    ASSERT(!floatingObject->isInPlacedTree());

    floatingObject->setIsPlaced(true);
    if (m_placedFloatsTree.isInitialized())
        m_placedFloatsTree.add(intervalForFloatingObject(floatingObject));

#if ENABLE(ASSERT)
    floatingObject->setIsInPlacedTree(true);
#endif
    markLowestFloatLogicalBottomCacheAsDirty();
}

void FloatingObjects::removePlacedObject(FloatingObject* floatingObject)
{
    ASSERT(floatingObject->isPlaced() && floatingObject->isInPlacedTree());

    if (m_placedFloatsTree.isInitialized()) {
        bool removed = m_placedFloatsTree.remove(intervalForFloatingObject(floatingObject));
        ASSERT_UNUSED(removed, removed);
    }

    floatingObject->setIsPlaced(false);
#if ENABLE(ASSERT)
    floatingObject->setIsInPlacedTree(false);
#endif
    markLowestFloatLogicalBottomCacheAsDirty();
}

FloatingObject* FloatingObjects::add(PassOwnPtr<FloatingObject> floatingObject)
{
    FloatingObject* newObject = floatingObject.leakPtr();
    increaseObjectsCount(newObject->type());
    m_set.add(adoptPtr(newObject));
    if (newObject->isPlaced())
        addPlacedObject(newObject);
    markLowestFloatLogicalBottomCacheAsDirty();
    return newObject;
}

void FloatingObjects::remove(FloatingObject* toBeRemoved)
{
    decreaseObjectsCount(toBeRemoved->type());
    OwnPtr<FloatingObject> floatingObject = m_set.take(toBeRemoved);
    ASSERT(floatingObject->isPlaced() || !floatingObject->isInPlacedTree());
    if (floatingObject->isPlaced())
        removePlacedObject(floatingObject.get());
    markLowestFloatLogicalBottomCacheAsDirty();
    ASSERT(!floatingObject->originatingLine());
}

void FloatingObjects::computePlacedFloatsTree()
{
    ASSERT(!m_placedFloatsTree.isInitialized());
    if (m_set.isEmpty())
        return;
    m_placedFloatsTree.initIfNeeded(m_renderer->view()->intervalArena());
    FloatingObjectSetIterator it = m_set.begin();
    FloatingObjectSetIterator end = m_set.end();
    for (; it != end; ++it) {
        FloatingObject* floatingObject = it->get();
        if (floatingObject->isPlaced())
            m_placedFloatsTree.add(intervalForFloatingObject(floatingObject));
    }
}

LayoutUnit FloatingObjects::logicalLeftOffsetForPositioningFloat(LayoutUnit fixedOffset, LayoutUnit logicalTop, LayoutUnit *heightRemaining)
{
    int logicalTopAsInt = roundToInt(logicalTop);
    ComputeFloatOffsetForFloatLayoutAdapter<FloatingObject::FloatLeft> adapter(m_renderer, logicalTopAsInt, logicalTopAsInt, fixedOffset);
    placedFloatsTree().allOverlapsWithAdapter(adapter);

    if (heightRemaining)
        *heightRemaining = adapter.heightRemaining();

    return adapter.offset();
}

LayoutUnit FloatingObjects::logicalRightOffsetForPositioningFloat(LayoutUnit fixedOffset, LayoutUnit logicalTop, LayoutUnit *heightRemaining)
{
    int logicalTopAsInt = roundToInt(logicalTop);
    ComputeFloatOffsetForFloatLayoutAdapter<FloatingObject::FloatRight> adapter(m_renderer, logicalTopAsInt, logicalTopAsInt, fixedOffset);
    placedFloatsTree().allOverlapsWithAdapter(adapter);

    if (heightRemaining)
        *heightRemaining = adapter.heightRemaining();

    return std::min(fixedOffset, adapter.offset());
}

LayoutUnit FloatingObjects::logicalLeftOffset(LayoutUnit fixedOffset, LayoutUnit logicalTop, LayoutUnit logicalHeight)
{
    ComputeFloatOffsetForLineLayoutAdapter<FloatingObject::FloatLeft> adapter(m_renderer, roundToInt(logicalTop), roundToInt(logicalTop + logicalHeight), fixedOffset);
    placedFloatsTree().allOverlapsWithAdapter(adapter);

    return adapter.offset();
}

LayoutUnit FloatingObjects::logicalRightOffset(LayoutUnit fixedOffset, LayoutUnit logicalTop, LayoutUnit logicalHeight)
{
    ComputeFloatOffsetForLineLayoutAdapter<FloatingObject::FloatRight> adapter(m_renderer, roundToInt(logicalTop), roundToInt(logicalTop + logicalHeight), fixedOffset);
    placedFloatsTree().allOverlapsWithAdapter(adapter);

    return std::min(fixedOffset, adapter.offset());
}

FloatingObjects::FloatBottomCachedValue::FloatBottomCachedValue()
    : value(0)
    , dirty(true)
{
}

inline static bool rangesIntersect(int floatTop, int floatBottom, int objectTop, int objectBottom)
{
    if (objectTop >= floatBottom || objectBottom < floatTop)
        return false;

    // The top of the object overlaps the float
    if (objectTop >= floatTop)
        return true;

    // The object encloses the float
    if (objectTop < floatTop && objectBottom > floatBottom)
        return true;

    // The bottom of the object overlaps the float
    if (objectBottom > objectTop && objectBottom > floatTop && objectBottom <= floatBottom)
        return true;

    return false;
}

template<>
inline bool ComputeFloatOffsetForFloatLayoutAdapter<FloatingObject::FloatLeft>::updateOffsetIfNeeded(const FloatingObject& floatingObject)
{
    LayoutUnit logicalRight = m_renderer->logicalRightForFloat(&floatingObject);
    if (logicalRight > m_offset) {
        m_offset = logicalRight;
        return true;
    }
    return false;
}

template<>
inline bool ComputeFloatOffsetForFloatLayoutAdapter<FloatingObject::FloatRight>::updateOffsetIfNeeded(const FloatingObject& floatingObject)
{
    LayoutUnit logicalLeft = m_renderer->logicalLeftForFloat(&floatingObject);
    if (logicalLeft < m_offset) {
        m_offset = logicalLeft;
        return true;
    }
    return false;
}

template <FloatingObject::Type FloatTypeValue>
LayoutUnit ComputeFloatOffsetForFloatLayoutAdapter<FloatTypeValue>::heightRemaining() const
{
    return this->m_outermostFloat ? this->m_renderer->logicalBottomForFloat(this->m_outermostFloat) - this->m_lineTop : LayoutUnit(1);
}

template <FloatingObject::Type FloatTypeValue>
inline void ComputeFloatOffsetAdapter<FloatTypeValue>::collectIfNeeded(const IntervalType& interval)
{
    const FloatingObject* floatingObject = interval.data();
    if (floatingObject->type() != FloatTypeValue || !rangesIntersect(interval.low(), interval.high(), m_lineTop, m_lineBottom))
        return;

    // Make sure the float hasn't changed since it was added to the placed floats tree.
    ASSERT(floatingObject->isPlaced());
    ASSERT(interval.low() == m_renderer->pixelSnappedLogicalTopForFloat(floatingObject));
    ASSERT(interval.high() == m_renderer->pixelSnappedLogicalBottomForFloat(floatingObject));

    bool floatIsNewExtreme = updateOffsetIfNeeded(*floatingObject);
    if (floatIsNewExtreme)
        m_outermostFloat = floatingObject;
}

template<>
inline bool ComputeFloatOffsetForLineLayoutAdapter<FloatingObject::FloatLeft>::updateOffsetIfNeeded(const FloatingObject& floatingObject)
{
    LayoutUnit logicalRight = m_renderer->logicalRightForFloat(&floatingObject);
    if (ShapeOutsideInfo* shapeOutside = floatingObject.renderer()->shapeOutsideInfo()) {
        ShapeOutsideDeltas shapeDeltas = shapeOutside->computeDeltasForContainingBlockLine(*m_renderer, floatingObject, m_lineTop, m_lineBottom - m_lineTop);
        if (!shapeDeltas.lineOverlapsShape())
            return false;

        logicalRight += shapeDeltas.rightMarginBoxDelta();
    }
    if (logicalRight > m_offset) {
        m_offset = logicalRight;
        return true;
    }

    return false;
}

template<>
inline bool ComputeFloatOffsetForLineLayoutAdapter<FloatingObject::FloatRight>::updateOffsetIfNeeded(const FloatingObject& floatingObject)
{
    LayoutUnit logicalLeft = m_renderer->logicalLeftForFloat(&floatingObject);
    if (ShapeOutsideInfo* shapeOutside = floatingObject.renderer()->shapeOutsideInfo()) {
        ShapeOutsideDeltas shapeDeltas = shapeOutside->computeDeltasForContainingBlockLine(*m_renderer, floatingObject, m_lineTop, m_lineBottom - m_lineTop);
        if (!shapeDeltas.lineOverlapsShape())
            return false;

        logicalLeft += shapeDeltas.leftMarginBoxDelta();
    }
    if (logicalLeft < m_offset) {
        m_offset = logicalLeft;
        return true;
    }

    return false;
}

#ifndef NDEBUG
// These helpers are only used by the PODIntervalTree for debugging purposes.
String ValueToString<int>::string(const int value)
{
    return String::number(value);
}

String ValueToString<FloatingObject*>::string(const FloatingObject* floatingObject)
{
    return String::format("%p (%dx%d %dx%d)", floatingObject, floatingObject->frameRect().pixelSnappedX(), floatingObject->frameRect().pixelSnappedY(), floatingObject->frameRect().pixelSnappedMaxX(), floatingObject->frameRect().pixelSnappedMaxY());
}
#endif


} // namespace blink
