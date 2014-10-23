/**
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 *           (C) 1999 Antti Koivisto (koivisto@kde.org)
 * Copyright (C) 2003, 2004, 2005, 2006, 2010 Apple Inc. All rights reserved.
 * Copyright (C) 2006 Andrew Wellington (proton@wiretapped.net)
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

#include "config.h"
#include "platform/text/BidiCharacterRun.h"

#include "platform/Partitions.h"
#include "wtf/RefCountedLeakCounter.h"

using namespace WTF;

namespace blink {

DEFINE_DEBUG_ONLY_GLOBAL(RefCountedLeakCounter, bidiRunCounter, ("BidiCharacterRun"));

void* BidiCharacterRun::operator new(size_t sz)
{
#ifndef NDEBUG
    bidiRunCounter.increment();
#endif
    return partitionAlloc(Partitions::getRenderingPartition(), sz);
}

void BidiCharacterRun::operator delete(void* ptr)
{
#ifndef NDEBUG
    bidiRunCounter.decrement();
#endif
    partitionFree(ptr);
}

}
