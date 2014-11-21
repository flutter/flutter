// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/config.h"
#include "sky/engine/core/css/BinaryDataFontFaceSource.h"

#include "sky/engine/platform/SharedBuffer.h"
#include "sky/engine/platform/fonts/FontCustomPlatformData.h"
#include "sky/engine/platform/fonts/FontDescription.h"
#include "sky/engine/platform/fonts/SimpleFontData.h"

namespace blink {

BinaryDataFontFaceSource::BinaryDataFontFaceSource(SharedBuffer* data)
    : m_customPlatformData(FontCustomPlatformData::create(data))
{
}

BinaryDataFontFaceSource::~BinaryDataFontFaceSource()
{
}

bool BinaryDataFontFaceSource::isValid() const
{
    return m_customPlatformData;
}

PassRefPtr<SimpleFontData> BinaryDataFontFaceSource::createFontData(const FontDescription& fontDescription)
{
    return SimpleFontData::create(
        m_customPlatformData->fontPlatformData(fontDescription.effectiveFontSize(),
            fontDescription.isSyntheticBold(), fontDescription.isSyntheticItalic(),
            fontDescription.orientation(), fontDescription.widthVariant()), CustomFontData::create());
}

} // namespace blink
