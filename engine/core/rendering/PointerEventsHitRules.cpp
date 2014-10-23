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

#include "config.h"
#include "core/rendering/PointerEventsHitRules.h"

namespace blink {

PointerEventsHitRules::PointerEventsHitRules(EHitTesting hitTesting, const HitTestRequest& request, EPointerEvents pointerEvents)
    : requireVisible(false)
    , requireFill(false)
    , requireStroke(false)
    , canHitStroke(false)
    , canHitFill(false)
    , canHitBoundingBox(false)
{
    if (request.svgClipContent())
        pointerEvents = PE_FILL;

    if (hitTesting == SVG_GEOMETRY_HITTESTING) {
        switch (pointerEvents)
        {
            case PE_BOUNDINGBOX:
                canHitBoundingBox = true;
                break;
            case PE_VISIBLE_PAINTED:
            case PE_AUTO: // "auto" is like "visiblePainted" when in SVG content
                requireFill = true;
                requireStroke = true;
            case PE_VISIBLE:
                requireVisible = true;
                canHitFill = true;
                canHitStroke = true;
                break;
            case PE_VISIBLE_FILL:
                requireVisible = true;
                canHitFill = true;
                break;
            case PE_VISIBLE_STROKE:
                requireVisible = true;
                canHitStroke = true;
                break;
            case PE_PAINTED:
                requireFill = true;
                requireStroke = true;
            case PE_ALL:
                canHitFill = true;
                canHitStroke = true;
                break;
            case PE_FILL:
                canHitFill = true;
                break;
            case PE_STROKE:
                canHitStroke = true;
                break;
            case PE_NONE:
                // nothing to do here, defaults are all false.
                break;
        }
    } else {
        switch (pointerEvents)
        {
            case PE_BOUNDINGBOX:
                canHitBoundingBox = true;
                break;
            case PE_VISIBLE_PAINTED:
            case PE_AUTO: // "auto" is like "visiblePainted" when in SVG content
                requireVisible = true;
                requireFill = true;
                requireStroke = true;
                canHitFill = true;
                canHitStroke = true;
                break;
            case PE_VISIBLE_FILL:
            case PE_VISIBLE_STROKE:
            case PE_VISIBLE:
                requireVisible = true;
                canHitFill = true;
                canHitStroke = true;
                break;
            case PE_PAINTED:
                requireFill = true;
                requireStroke = true;
                canHitFill = true;
                canHitStroke = true;
                break;
            case PE_FILL:
            case PE_STROKE:
            case PE_ALL:
                canHitFill = true;
                canHitStroke = true;
                break;
            case PE_NONE:
                // nothing to do here, defaults are all false.
                break;
        }
    }
}

}

// vim:ts=4:noet
