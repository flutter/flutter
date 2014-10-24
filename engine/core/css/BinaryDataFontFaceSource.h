// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BinaryDataFontFaceSource_h
#define BinaryDataFontFaceSource_h

#include "core/css/CSSFontFaceSource.h"
#include "wtf/OwnPtr.h"

namespace blink {

class FontCustomPlatformData;
class SharedBuffer;

class BinaryDataFontFaceSource final : public CSSFontFaceSource {
public:
    explicit BinaryDataFontFaceSource(SharedBuffer*);
    virtual ~BinaryDataFontFaceSource();
    virtual bool isValid() const override;

private:
    virtual PassRefPtr<SimpleFontData> createFontData(const FontDescription&) override;

    OwnPtr<FontCustomPlatformData> m_customPlatformData;
};

} // namespace blink

#endif
