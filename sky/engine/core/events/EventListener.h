/*
 * Copyright (C) 2006, 2008, 2009 Apple Inc. All rights reserved.
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

#ifndef SKY_ENGINE_CORE_EVENTS_EVENTLISTENER_H_
#define SKY_ENGINE_CORE_EVENTS_EVENTLISTENER_H_

#include "sky/engine/wtf/RefCounted.h"

typedef struct _Dart_WeakReferenceSet* Dart_WeakReferenceSet;

namespace blink {
class DartGCVisitor;
class Event;
class ExecutionContext;

class EventListener : public RefCounted<EventListener> {
public:
    virtual ~EventListener() { }
    virtual bool operator==(const EventListener&) = 0;
    virtual void handleEvent(ExecutionContext*, Event*) = 0;

    virtual void AcceptDartGCVisitor(DartGCVisitor& visitor) const = 0;


protected:
    explicit EventListener()
    {
    }
};

}

#endif  // SKY_ENGINE_CORE_EVENTS_EVENTLISTENER_H_
