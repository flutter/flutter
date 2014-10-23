/*
    Copyright (C) 2007 Rob Buis <buis@kde.org>

    This library is free software; you can redistribute it and/or
    modify it under the terms of the GNU Library General Public
    License as published by the Free Software Foundation; either
    version 2 of the License, or (at your option) any later version.

    This library is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    Library General Public License for more details.

    You should have received a copy of the GNU Library General Public License
    aint with this library; see the file COPYING.LIB.  If not, write to
    the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
    Boston, MA 02110-1301, USA.
*/

#ifndef PointerEventsHitRules_h
#define PointerEventsHitRules_h

#include "core/rendering/HitTestRequest.h"
#include "core/rendering/style/RenderStyleConstants.h"

namespace blink {

class PointerEventsHitRules {
public:
    enum EHitTesting {
        SVG_IMAGE_HITTESTING,
        SVG_GEOMETRY_HITTESTING,
        SVG_TEXT_HITTESTING
    };

    PointerEventsHitRules(EHitTesting, const HitTestRequest&, EPointerEvents);

    bool requireVisible;
    bool requireFill;
    bool requireStroke;
    bool canHitStroke;
    bool canHitFill;
    bool canHitBoundingBox;
};

}

#endif

// vim:ts=4:noet
