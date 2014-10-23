/*
 * Copyright (C) 2012 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE COMPUTER, INC. ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL APPLE COMPUTER, INC. OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef SkSizeHash_h
#define SkSizeHash_h

#include "SkScalar.h"
#include "SkSize.h"

#include "wtf/HashMap.h"

namespace WTF {

template<> struct IntHash<SkSize> {
    static unsigned hash(const SkSize& key) { return pairIntHash(key.width(), key.height()); }
    static bool equal(const SkSize& a, const SkSize& b) { return a == b; }
    static const bool safeToCompareToEmptyOrDeleted = true;
};

template<> struct DefaultHash<SkSize> {
    typedef IntHash<SkSize> Hash;
};

template<> struct HashTraits<SkSize> : GenericHashTraits<SkSize> {
    static const bool emptyValueIsZero = true;
    static const bool needsDestruction = false;
    static SkSize emptyValue() { return SkSize::Make(0, 0); }
    static void constructDeletedValue(SkSize& slot, bool)
    {
        slot = SkSize::Make(-1, -1);
    }
    static bool isDeletedValue(const SkSize& value)
    {
        return value.width() == -1 && value.height() == -1;
    }
};

template<> struct IntHash<SkISize> {
    static unsigned hash(const SkISize& key) { return pairIntHash(key.width(), key.height()); }
    static bool equal(const SkISize& a, const SkISize& b) { return a == b; }
    static const bool safeToCompareToEmptyOrDeleted = true;
};

template<> struct DefaultHash<SkISize> {
    typedef IntHash<SkISize> Hash;
};

template<> struct HashTraits<SkISize> : GenericHashTraits<SkISize> {
    static const bool emptyValueIsZero = true;
    static const bool needsDestruction = false;
    static SkISize emptyValue() { return SkISize::Make(0, 0); }
    static void constructDeletedValue(SkISize& slot, bool)
    {
        slot = SkISize::Make(-1, -1);
    }
    static bool isDeletedValue(const SkISize& value)
    {
        return value.width() == -1 && value.height() == -1;
    }
};

} // namespace WTF

#endif // SkSizeHash_h
