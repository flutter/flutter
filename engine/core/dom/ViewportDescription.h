/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 *           (C) 1999 Antti Koivisto (koivisto@kde.org)
 *           (C) 2001 Dirk Mueller (mueller@kde.org)
 *           (C) 2006 Alexey Proskuryakov (ap@webkit.org)
 * Copyright (C) 2004, 2005, 2006, 2007, 2008 Apple Inc. All rights reserved.
 * Copyright (C) 2008 Torch Mobile Inc. All rights reserved. (http://www.torchmobile.com/)
 * Copyright (C) 2010 Nokia Corporation and/or its subsidiary(-ies)
 * Copyright (C) 2012-2013 Intel Corporation. All rights reserved.
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

#ifndef ViewportDescription_h
#define ViewportDescription_h

#include "platform/Length.h"
#include "platform/geometry/FloatSize.h"

namespace blink {

class LocalFrame;

struct ViewportDescription {

    enum Type {
        // These are ordered in increasing importance.
        UserAgentStyleSheet,
        HandheldFriendlyMeta,
        MobileOptimizedMeta,
        ViewportMeta,
        AuthorStyleSheet
    } type;

    enum {
        ValueAuto = -1,
        ValueDeviceWidth = -2,
        ValueDeviceHeight = -3,
        ValuePortrait = -4,
        ValueLandscape = -5,
        ValueDeviceDPI = -6,
        ValueLowDPI = -7,
        ValueMediumDPI = -8,
        ValueHighDPI = -9,
        ValueExtendToZoom = -10
    };

    ViewportDescription(Type type = UserAgentStyleSheet)
        : type(type)
        , zoom(ValueAuto)
        , minZoom(ValueAuto)
        , maxZoom(ValueAuto)
        , userZoom(true)
        , orientation(ValueAuto)
        , deprecatedTargetDensityDPI(ValueAuto)
        , zoomIsExplicit(false)
        , minZoomIsExplicit(false)
        , maxZoomIsExplicit(false)
        , userZoomIsExplicit(false)
    {
    }

    Length minWidth;
    Length maxWidth;
    Length minHeight;
    Length maxHeight;
    float zoom;
    float minZoom;
    float maxZoom;
    bool userZoom;
    float orientation;
    float deprecatedTargetDensityDPI; // Only used for Android WebView

    // Whether the computed value was explicitly specified rather than being
    // inferred.
    bool zoomIsExplicit;
    bool minZoomIsExplicit;
    bool maxZoomIsExplicit;
    bool userZoomIsExplicit;

    bool operator==(const ViewportDescription& other) const
    {
        // Used for figuring out whether to reset the viewport or not,
        // thus we are not taking type into account.
        return minWidth == other.minWidth
            && maxWidth == other.maxWidth
            && minHeight == other.minHeight
            && maxHeight == other.maxHeight
            && zoom == other.zoom
            && minZoom == other.minZoom
            && maxZoom == other.maxZoom
            && userZoom == other.userZoom
            && orientation == other.orientation
            && deprecatedTargetDensityDPI == other.deprecatedTargetDensityDPI
            && zoomIsExplicit == other.zoomIsExplicit
            && minZoomIsExplicit == other.minZoomIsExplicit
            && maxZoomIsExplicit == other.maxZoomIsExplicit
            && userZoomIsExplicit == other.userZoomIsExplicit;
    }

    bool operator!=(const ViewportDescription& other) const
    {
        return !(*this == other);
    }

    bool isLegacyViewportType() const { return type >= HandheldFriendlyMeta && type <= ViewportMeta; }
    bool isMetaViewportType() const { return type == ViewportMeta; }
    bool isSpecifiedByAuthor() const { return type != UserAgentStyleSheet; }

    // Reports UMA stat on whether the page is considered mobile or desktop and what kind of
    // mobile it is. Applies only to Android, must only be called once per page load.
    void reportMobilePageStats(const LocalFrame*) const;

private:
    enum Direction { Horizontal, Vertical };
    static float resolveViewportLength(const Length&, const FloatSize& initialViewportSize, Direction);
};

} // namespace blink

#endif // ViewportDescription_h
