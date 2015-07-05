/*
    Copyright (C) 1998 Lars Knoll (knoll@mpi-hd.mpg.de)
    Copyright (C) 2001 Dirk Mueller <mueller@kde.org>
    Copyright (C) 2006 Samuel Weinig (sam.weinig@gmail.com)
    Copyright (C) 2004, 2005, 2006, 2007 Apple Inc. All rights reserved.

    This library is free software; you can redistribute it and/or
    modify it under the terms of the GNU Library General Public
    License as published by the Free Software Foundation; either
    version 2 of the License, or (at your option) any later version.

    This library is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    Library General Public License for more details.

    You should have received a copy of the GNU Library General Public License
    along with this library; see the file COPYING.LIB.  If not, write to
    the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
    Boston, MA 02110-1301, USA.
*/

#ifndef SKY_ENGINE_CORE_FETCH_IMAGERESOURCECLIENT_H_
#define SKY_ENGINE_CORE_FETCH_IMAGERESOURCECLIENT_H_

#include "sky/engine/core/fetch/ResourceClient.h"

namespace blink {

class ImageResource;
class IntRect;

class ImageResourceClient : public ResourceClient {
public:
    virtual ~ImageResourceClient() { }
    static ResourceClientType expectedType() { return ImageType; }
    virtual ResourceClientType resourceClientType() const override final { return expectedType(); }

    // Called whenever a frame of an image changes, either because we got more data from the network or
    // because we are animating. If not null, the IntRect is the changed rect of the image.
    virtual void imageChanged(ImageResource*, const IntRect* = 0) { }
};

}

#endif  // SKY_ENGINE_CORE_FETCH_IMAGERESOURCECLIENT_H_
