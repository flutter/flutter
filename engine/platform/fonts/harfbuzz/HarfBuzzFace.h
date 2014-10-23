/*
 * Copyright (c) 2012 Google Inc. All rights reserved.
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

#ifndef HarfBuzzFace_h
#define HarfBuzzFace_h

#include <hb.h>

#include "wtf/HashMap.h"
#include "wtf/PassRefPtr.h"
#include "wtf/RefCounted.h"
#include "wtf/RefPtr.h"

namespace blink {

class FontPlatformData;

class HarfBuzzFace : public RefCounted<HarfBuzzFace> {
public:
    static const hb_tag_t vertTag;
    static const hb_tag_t vrt2Tag;

    static PassRefPtr<HarfBuzzFace> create(FontPlatformData* platformData, uint64_t uniqueID)
    {
        return adoptRef(new HarfBuzzFace(platformData, uniqueID));
    }
    ~HarfBuzzFace();

    hb_font_t* createFont();

    void setScriptForVerticalGlyphSubstitution(hb_buffer_t*);

private:
    HarfBuzzFace(FontPlatformData*, uint64_t);

    hb_face_t* createFace();

    FontPlatformData* m_platformData;
    uint64_t m_uniqueID;
    hb_face_t* m_face;
    WTF::HashMap<uint32_t, uint16_t>* m_glyphCacheForFaceCacheEntry;

    hb_script_t m_scriptForVerticalText;
};

} // namespace blink

#endif // HarfBuzzFace_h
