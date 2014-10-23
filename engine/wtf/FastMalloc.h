/*
 *  Copyright (C) 2005, 2006, 2007, 2008, 2009 Apple Inc. All rights reserved.
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
 *
 */

#ifndef WTF_FastMalloc_h
#define WTF_FastMalloc_h

#include "wtf/WTFExport.h"

namespace WTF {

// Initialization is implicit on first use.
WTF_EXPORT void fastMallocShutdown();

// These functions crash safely if an allocation fails.
WTF_EXPORT void* fastMalloc(size_t);
WTF_EXPORT void* fastZeroedMalloc(size_t);
WTF_EXPORT void* fastRealloc(void*, size_t);
WTF_EXPORT char* fastStrDup(const char*);

WTF_EXPORT void fastFree(void*);

} // namespace WTF

using WTF::fastFree;
using WTF::fastMalloc;
using WTF::fastRealloc;
using WTF::fastStrDup;
using WTF::fastZeroedMalloc;

#endif /* WTF_FastMalloc_h */
