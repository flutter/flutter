// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "config.h"
#include "core/css/BinaryDataFontFaceSource.h"

#include "platform/SharedBuffer.h"
#include "platform/fonts/FontCustomPlatformData.h"
#include "platform/fonts/FontDescription.h"
#include "platform/fonts/SimpleFontData.h"

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
