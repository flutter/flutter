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

#ifndef WTF_Forward_h
#define WTF_Forward_h

#include <stddef.h>

namespace WTF {
    template<typename T> class Function;
    template<typename T> class OwnPtr;
    template<typename T> class PassOwnPtr;
    template<typename T> class PassRefPtr;
    template<typename T> class RefPtr;
    template<typename T, size_t inlineCapacity, typename Allocator> class Vector;

    class ArrayBuffer;
    class ArrayBufferView;
    class ArrayPiece;
    class AtomicString;
    class CString;
    class Float32Array;
    class Float64Array;
    class Int8Array;
    class Int16Array;
    class Int32Array;
    template<size_t size>
    class SizeSpecificPartitionAllocator;
    class String;
    template <typename T> class StringBuffer;
    class StringBuilder;
    class StringImpl;
    class Uint8Array;
    class Uint8ClampedArray;
    class Uint16Array;
    class Uint32Array;
}

using WTF::Function;
using WTF::OwnPtr;
using WTF::PassOwnPtr;
using WTF::PassRefPtr;
using WTF::RefPtr;
using WTF::Vector;

using WTF::ArrayBuffer;
using WTF::ArrayBufferView;
using WTF::ArrayPiece;
using WTF::AtomicString;
using WTF::CString;
using WTF::Float32Array;
using WTF::Float64Array;
using WTF::Int8Array;
using WTF::Int16Array;
using WTF::Int32Array;
using WTF::String;
using WTF::StringBuffer;
using WTF::StringBuilder;
using WTF::StringImpl;
using WTF::Uint8Array;
using WTF::Uint8ClampedArray;
using WTF::Uint16Array;
using WTF::Uint32Array;

#endif // WTF_Forward_h
