// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef WebSelectionBound_h
#define WebSelectionBound_h

#include "public/platform/WebPoint.h"
#include "public/platform/WebRect.h"

namespace blink {

// An endpoint for an active selection region.
struct WebSelectionBound {
    enum Type {
        Caret,
        SelectionLeft,
        SelectionRight
    };

    explicit WebSelectionBound(Type type)
        : type(type)
        , layerId(0)
    {
    }

    // The logical type of the endpoint. Note that this is dependent not only on
    // the bound's relative location, but also the underlying text direction.
    Type type;

    // The id of the platform layer to which the bound should be anchored.
    int layerId;

    // The one-dimensional rect of the bound's edge in layer coordinates, not to
    // be confused with the selection region.
    // FIXME: Remove when downstream code uses |edge{Top|Bottom}InLayer|,
    // crbug.com/405666.
    WebRect edgeRectInLayer;

    // The bottom and top coordinates of the edge (caret), in layer coordinates,
    // that define the selection bound.
    WebPoint edgeTopInLayer;
    WebPoint edgeBottomInLayer;
};

} // namespace blink

#endif
