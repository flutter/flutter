/*
 * Copyright (C) 2006, 2008, 2011 Apple Inc. All rights reserved.
 * Copyright (C) 2012 Nokia Corporation and/or its subsidiary(-ies)
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

#include "flutter/sky/engine/core/rendering/HitTestResult.h"

#include "flutter/sky/engine/core/rendering/RenderBox.h"
#include "flutter/sky/engine/core/rendering/RenderObject.h"

namespace blink {

HitTestResult::HitTestResult() {}

HitTestResult::HitTestResult(const LayoutPoint& point)
    : m_hitTestLocation(point), m_pointInInnerNodeFrame(point) {}

HitTestResult::HitTestResult(const LayoutPoint& centerPoint,
                             unsigned topPadding,
                             unsigned rightPadding,
                             unsigned bottomPadding,
                             unsigned leftPadding)
    : m_hitTestLocation(centerPoint,
                        topPadding,
                        rightPadding,
                        bottomPadding,
                        leftPadding),
      m_pointInInnerNodeFrame(centerPoint) {}

HitTestResult::HitTestResult(const HitTestLocation& other)
    : m_hitTestLocation(other),
      m_pointInInnerNodeFrame(m_hitTestLocation.point()) {}

HitTestResult::HitTestResult(const HitTestResult& other)
    : m_hitTestLocation(other.m_hitTestLocation),
      m_localPoint(other.localPoint()) {}

HitTestResult::~HitTestResult() {}

HitTestResult& HitTestResult::operator=(const HitTestResult& other) {
  m_hitTestLocation = other.m_hitTestLocation;
  m_pointInInnerNodeFrame = other.m_pointInInnerNodeFrame;
  m_localPoint = other.localPoint();
  return *this;
}

RenderObject* HitTestResult::renderer() const {
  return 0;
}

bool HitTestResult::isSelected() const {
  return false;
}

Image* HitTestResult::image() const {
  return 0;
}

IntRect HitTestResult::imageRect() const {
  return IntRect();
}

bool HitTestResult::isMisspelled() const {
  return false;
}

// FIXME: This function needs a better name and may belong in a different class.
// It's not really isContentEditable(); it's more like
// needsEditingContextMenu(). In many ways, this function would make more sense
// in the ContextMenu class, except that WebElementDictionary hooks into it.
// Anyway, we should architect this better.
bool HitTestResult::isContentEditable() const {
  return false;
}

void HitTestResult::append(const HitTestResult& other) {}

}  // namespace blink
