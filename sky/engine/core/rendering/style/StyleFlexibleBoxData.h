/*
 * Copyright (C) 2011 Google Inc. All Rights Reserved.
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
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. AND ITS CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL APPLE INC. OR ITS CONTRIBUTORS BE LIABLE FOR
 * ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
 * DAMAGE.
 *
 */

#ifndef SKY_ENGINE_CORE_RENDERING_STYLE_STYLEFLEXIBLEBOXDATA_H_
#define SKY_ENGINE_CORE_RENDERING_STYLE_STYLEFLEXIBLEBOXDATA_H_

#include "flutter/sky/engine/platform/Length.h"

#include "flutter/sky/engine/wtf/PassRefPtr.h"
#include "flutter/sky/engine/wtf/RefCounted.h"

namespace blink {

class StyleFlexibleBoxData : public RefCounted<StyleFlexibleBoxData> {
 public:
  static PassRefPtr<StyleFlexibleBoxData> create() {
    return adoptRef(new StyleFlexibleBoxData);
  }
  PassRefPtr<StyleFlexibleBoxData> copy() const {
    return adoptRef(new StyleFlexibleBoxData(*this));
  }

  bool operator==(const StyleFlexibleBoxData&) const;
  bool operator!=(const StyleFlexibleBoxData& o) const { return !(*this == o); }

  float m_flexGrow;
  float m_flexShrink;
  Length m_flexBasis;

  unsigned m_flexDirection : 2;  // EFlexDirection
  unsigned m_flexWrap : 2;       // EFlexWrap

 private:
  StyleFlexibleBoxData();
  StyleFlexibleBoxData(const StyleFlexibleBoxData&);
};

}  // namespace blink

#endif  // SKY_ENGINE_CORE_RENDERING_STYLE_STYLEFLEXIBLEBOXDATA_H_
