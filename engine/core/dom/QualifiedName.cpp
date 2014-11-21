/*
 * Copyright (C) 2005, 2006, 2009 Apple Inc. All rights reserved.
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

#include "sky/engine/config.h"

#include "sky/engine/core/dom/QualifiedName.h"

#include "sky/engine/wtf/Assertions.h"
#include "sky/engine/wtf/HashSet.h"
#include "sky/engine/wtf/MainThread.h"
#include "sky/engine/wtf/StaticConstructors.h"

namespace blink {

// Global init routines
DEFINE_GLOBAL(QualifiedName, anyName)
DEFINE_GLOBAL(QualifiedName, nullName)

void QualifiedName::init()
{
    ASSERT(starAtom.impl());
    new ((void*)&anyName) QualifiedName(starAtom);
    new ((void*)&anyName) QualifiedName(nullName);
}

void QualifiedName::createStatic(void* targetAddress, StringImpl* name)
{
    new (targetAddress) QualifiedName(AtomicString(name));
}

}
