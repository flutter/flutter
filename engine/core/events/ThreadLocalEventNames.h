/*
 * Copyright (C) 2005, 2007 Apple Inc. All rights reserved.
 * Copyright (C) 2006 Jon Shier (jshier@iastate.edu)
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

#ifndef ThreadLocalEventNames_h
#define ThreadLocalEventNames_h

#include "core/EventInterfaces.h"
#include "core/EventNames.h"
#include "core/EventTargetInterfaces.h"
#include "core/EventTargetNames.h"
#include "core/EventTypeNames.h"
#include "wtf/text/AtomicString.h"

namespace blink {

inline bool isTouchEventType(const AtomicString& eventType)
{
    return eventType == EventTypeNames::touchstart
        || eventType == EventTypeNames::touchmove
        || eventType == EventTypeNames::touchend
        || eventType == EventTypeNames::touchcancel;
}

}

#endif
