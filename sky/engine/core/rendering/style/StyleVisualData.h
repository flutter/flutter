/*
 * Copyright (C) 2000 Lars Knoll (knoll@kde.org)
 *           (C) 2000 Antti Koivisto (koivisto@kde.org)
 *           (C) 2000 Dirk Mueller (mueller@kde.org)
 * Copyright (C) 2003, 2005, 2006, 2007, 2008 Apple Inc. All rights reserved.
 * Copyright (C) 2006 Graham Dennis (graham.dennis@gmail.com)
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public License
 * along with this library; see the file COPYING.LIB.  If not, write to
 * the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301, USA.
 *
 */

#ifndef SKY_ENGINE_CORE_RENDERING_STYLE_STYLEVISUALDATA_H_
#define SKY_ENGINE_CORE_RENDERING_STYLE_STYLEVISUALDATA_H_

#include "flutter/sky/engine/core/rendering/style/RenderStyleConstants.h"
#include "flutter/sky/engine/platform/LengthBox.h"
#include "flutter/sky/engine/wtf/PassRefPtr.h"
#include "flutter/sky/engine/wtf/RefCounted.h"

namespace blink {

class StyleVisualData : public RefCounted<StyleVisualData> {
 public:
  static PassRefPtr<StyleVisualData> create() {
    return adoptRef(new StyleVisualData);
  }
  PassRefPtr<StyleVisualData> copy() const {
    return adoptRef(new StyleVisualData(*this));
  }
  ~StyleVisualData();

  bool operator==(const StyleVisualData& o) const {
    return clip == o.clip && hasAutoClip == o.hasAutoClip &&
           textDecoration == o.textDecoration;
  }
  bool operator!=(const StyleVisualData& o) const { return !(*this == o); }

  LengthBox clip;
  bool hasAutoClip : 1;
  unsigned textDecoration
      : TextDecorationBits;  // Text decorations defined *only* by this element.

 private:
  StyleVisualData();
  StyleVisualData(const StyleVisualData&);
};

}  // namespace blink

#endif  // SKY_ENGINE_CORE_RENDERING_STYLE_STYLEVISUALDATA_H_
