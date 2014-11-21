/*
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
 */

#ifndef SKY_ENGINE_CORE_PAGE_TOUCHADJUSTMENT_H_
#define SKY_ENGINE_CORE_PAGE_TOUCHADJUSTMENT_H_

#include "sky/engine/platform/geometry/IntPoint.h"
#include "sky/engine/platform/geometry/IntRect.h"
#include "sky/engine/platform/heap/Handle.h"
#include "sky/engine/wtf/RefPtr.h"
#include "sky/engine/wtf/Vector.h"

namespace blink {

class Node;

bool findBestClickableCandidate(Node*& targetNode, IntPoint& targetPoint, const IntPoint& touchHotspot, const IntRect& touchArea, const Vector<RefPtr<Node> >&);

} // namespace blink

#endif  // SKY_ENGINE_CORE_PAGE_TOUCHADJUSTMENT_H_
