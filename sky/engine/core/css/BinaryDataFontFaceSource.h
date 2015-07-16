// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_CSS_BINARYDATAFONTFACESOURCE_H_
#define SKY_ENGINE_CORE_CSS_BINARYDATAFONTFACESOURCE_H_

#include "sky/engine/core/css/CSSFontFaceSource.h"
#include "sky/engine/wtf/OwnPtr.h"

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

#endif  // SKY_ENGINE_CORE_CSS_BINARYDATAFONTFACESOURCE_H_
