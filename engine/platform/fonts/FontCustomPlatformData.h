/*
 * Copyright (C) 2007 Apple Computer, Inc.
 * Copyright (c) 2007, 2008, 2009, Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 *     * Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 * copyright notice, this list of conditions and the following disclaimer
 * in the documentation and/or other materials provided with the
 * distribution.
 *     * Neither the name of Google Inc. nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef FontCustomPlatformData_h
#define FontCustomPlatformData_h

#include "platform/PlatformExport.h"
#include "platform/fonts/FontOrientation.h"
#include "platform/fonts/FontWidthVariant.h"
#include "wtf/Forward.h"
#include "wtf/Noncopyable.h"
#include "wtf/RefPtr.h"
#include "wtf/text/WTFString.h"

#if OS(MACOSX)
#include "wtf/RetainPtr.h"
#include <CoreFoundation/CFBase.h>
typedef struct CGFont* CGFontRef;
#endif

class SkTypeface;

namespace blink {

class FontPlatformData;
class SharedBuffer;

class PLATFORM_EXPORT FontCustomPlatformData {
    WTF_MAKE_NONCOPYABLE(FontCustomPlatformData);
public:
    static PassOwnPtr<FontCustomPlatformData> create(SharedBuffer*);
    ~FontCustomPlatformData();

    FontPlatformData fontPlatformData(float size, bool bold, bool italic, FontOrientation = Horizontal, FontWidthVariant = RegularWidth);

    static bool supportsFormat(const String&);

private:
#if OS(MACOSX)
    explicit FontCustomPlatformData(CGFontRef, PassRefPtr<SkTypeface>);
    RetainPtr<CGFontRef> m_cgFont;
#else
    explicit FontCustomPlatformData(PassRefPtr<SkTypeface>);
#endif
    RefPtr<SkTypeface> m_typeface;
};

} // namespace blink

#endif // FontCustomPlatformData_h
