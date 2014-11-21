/*
 * Copyright (C) 2010 Nokia Corporation and/or its subsidiary(-ies)
 *
 *  This library is free software; you can redistribute it and/or
 *  modify it under the terms of the GNU Library General Public
 *  License as published by the Free Software Foundation; either
 *  version 2 of the License, or (at your option) any later version.
 *
 *  This library is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 *  Library General Public License for more details.
 *
 *  You should have received a copy of the GNU Library General Public License
 *  along with this library; see the file COPYING.LIB.  If not, write to
 *  the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 *  Boston, MA 02110-1301, USA.
 */

#ifndef SKY_ENGINE_CORE_CSS_MEDIAQUERYLISTLISTENER_H_
#define SKY_ENGINE_CORE_CSS_MEDIAQUERYLISTLISTENER_H_

#include "sky/engine/core/css/MediaQueryList.h"
#include "sky/engine/platform/heap/Handle.h"
#include "sky/engine/wtf/RefCounted.h"

namespace blink {

class MediaQueryList;

// See http://dev.w3.org/csswg/cssom-view/#the-mediaquerylist-interface
class MediaQueryListListener : public RefCounted<MediaQueryListListener> {
public:
    virtual ~MediaQueryListListener();

    virtual void notifyMediaQueryChanged() = 0;
protected:
    MediaQueryListListener();
};

}

#endif  // SKY_ENGINE_CORE_CSS_MEDIAQUERYLISTLISTENER_H_
