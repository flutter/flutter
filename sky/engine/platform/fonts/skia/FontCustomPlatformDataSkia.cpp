/*
 * Copyright (C) 2007 Apple Computer, Inc.
 * Copyright (c) 2007, 2008, 2009, Google Inc. All rights reserved.
 * Copyright (C) 2010 Company 100, Inc.
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

#include "flutter/sky/engine/platform/fonts/FontCustomPlatformData.h"

#include "flutter/sky/engine/platform/SharedBuffer.h"
#include "flutter/sky/engine/platform/fonts/FontCache.h"
#include "flutter/sky/engine/platform/fonts/FontPlatformData.h"
#include "flutter/sky/engine/wtf/PassOwnPtr.h"
#include "third_party/skia/include/core/SkStream.h"
#include "third_party/skia/include/core/SkTypeface.h"

namespace blink {

FontCustomPlatformData::FontCustomPlatformData(sk_sp<SkTypeface> typeface)
    : m_typeface(typeface) {}

FontCustomPlatformData::~FontCustomPlatformData() {}

FontPlatformData FontCustomPlatformData::fontPlatformData(
    float size,
    bool bold,
    bool italic,
    FontOrientation orientation,
    FontWidthVariant) {
  ASSERT(m_typeface);
  return FontPlatformData(m_typeface, "", size, bold && !m_typeface->isBold(),
                          italic && !m_typeface->isItalic(), orientation);
}

PassOwnPtr<FontCustomPlatformData> FontCustomPlatformData::create(
    SharedBuffer* buffer) {
  ASSERT_ARG(buffer, buffer);

  SkMemoryStream* stream = new SkMemoryStream(buffer->getAsSkData());
  sk_sp<SkTypeface> typeface = SkTypeface::MakeFromStream(stream);
  if (!typeface)
    return nullptr;

  return adoptPtr(new FontCustomPlatformData(typeface));
}

bool FontCustomPlatformData::supportsFormat(const String& format) {
  return equalIgnoringCase(format, "truetype") ||
         equalIgnoringCase(format, "opentype");
}

}  // namespace blink
