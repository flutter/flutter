/*
 *  Copyright (C) 2006, 2009, 2011 Apple Inc. All rights reserved.
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

#ifndef SKY_ENGINE_WTF_FORWARD_H_
#define SKY_ENGINE_WTF_FORWARD_H_

#include <stddef.h>

namespace WTF {
template <typename T>
class Function;
template <typename T>
class OwnPtr;
template <typename T>
class PassOwnPtr;
template <typename T>
class PassRefPtr;
template <typename T>
class RefPtr;
template <typename T, size_t inlineCapacity, typename Allocator>
class Vector;

class AtomicString;
class CString;
template <size_t size>
class SizeSpecificPartitionAllocator;
class String;
template <typename T>
class StringBuffer;
class StringBuilder;
class StringImpl;
}  // namespace WTF

using WTF::Function;
using WTF::OwnPtr;
using WTF::PassOwnPtr;
using WTF::PassRefPtr;
using WTF::RefPtr;
using WTF::Vector;

using WTF::AtomicString;
using WTF::CString;
using WTF::String;
using WTF::StringBuffer;
using WTF::StringBuilder;
using WTF::StringImpl;

#endif  // SKY_ENGINE_WTF_FORWARD_H_
