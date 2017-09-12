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

#ifndef SKY_ENGINE_CORE_RENDERING_STYLE_STYLERARENONINHERITEDDATA_H_
#define SKY_ENGINE_CORE_RENDERING_STYLE_STYLERARENONINHERITEDDATA_H_

#include "flutter/sky/engine/core/rendering/ClipPathOperation.h"
#include "flutter/sky/engine/core/rendering/style/CounterDirectives.h"
#include "flutter/sky/engine/core/rendering/style/DataRef.h"
#include "flutter/sky/engine/core/rendering/style/FillLayer.h"
#include "flutter/sky/engine/core/rendering/style/RenderStyleConstants.h"
#include "flutter/sky/engine/core/rendering/style/ShapeValue.h"
#include "flutter/sky/engine/core/rendering/style/StyleColor.h"
#include "flutter/sky/engine/platform/LengthPoint.h"
#include "flutter/sky/engine/wtf/OwnPtr.h"
#include "flutter/sky/engine/wtf/PassRefPtr.h"
#include "flutter/sky/engine/wtf/Vector.h"

namespace blink {

class LengthSize;
class ShadowList;
class StyleFilterData;
class StyleFlexibleBoxData;
class StyleTransformData;

// This struct is for rarely used non-inherited CSS3, CSS2, and WebKit-specific
// properties. By grouping them together, we save space, and only allocate this
// object when someone actually uses one of these properties.
class StyleRareNonInheritedData : public RefCounted<StyleRareNonInheritedData> {
 public:
  static PassRefPtr<StyleRareNonInheritedData> create() {
    return adoptRef(new StyleRareNonInheritedData);
  }
  PassRefPtr<StyleRareNonInheritedData> copy() const {
    return adoptRef(new StyleRareNonInheritedData(*this));
  }
  ~StyleRareNonInheritedData();

  bool operator==(const StyleRareNonInheritedData&) const;
  bool operator!=(const StyleRareNonInheritedData& o) const {
    return !(*this == o);
  }

  bool counterDataEquivalent(const StyleRareNonInheritedData&) const;
  bool shadowDataEquivalent(const StyleRareNonInheritedData&) const;
  bool hasOpacity() const { return opacity < 1; }

  float opacity;  // Whether or not we're transparent.

  float m_aspectRatioDenominator;
  float m_aspectRatioNumerator;

  float m_perspective;
  Length m_perspectiveOriginX;
  Length m_perspectiveOriginY;

  DataRef<StyleFlexibleBoxData> m_flexibleBox;
  DataRef<StyleTransformData>
      m_transform;  // Transform properties (rotate, scale, skew, etc.)

  DataRef<StyleFilterData>
      m_filter;  // Filter operations (url, sepia, blur, etc.)

  OwnPtr<CounterDirectiveMap> m_counterDirectives;

  RefPtr<ShadowList> m_boxShadow;

  RefPtr<ClipPathOperation> m_clipPath;

  StyleColor m_textDecorationColor;

  int m_order;

  LengthPoint m_objectPosition;

  AtomicString m_ellipsis;
  int m_maxLines;

  unsigned m_transformStyle3D : 1;  // ETransformStyle3D

  unsigned m_alignContent : 3;                 // EAlignContent
  unsigned m_alignItems : 4;                   // ItemPosition
  unsigned m_alignItemsOverflowAlignment : 2;  // OverflowAlignment
  unsigned m_alignSelf : 4;                    // ItemPosition
  unsigned m_alignSelfOverflowAlignment : 2;   // OverflowAlignment
  unsigned m_justifyContent : 3;               // EJustifyContent

  unsigned textOverflow : 1;  // Whether or not lines that spill out should be
                              // truncated with "..."

  unsigned m_textDecorationStyle : 3;  // TextDecorationStyle
  unsigned m_wrapFlow : 3;             // WrapFlow
  unsigned m_wrapThrough : 1;          // WrapThrough

  unsigned m_hasAspectRatio : 1;  // Whether or not an aspect ratio has been
                                  // specified.

  unsigned m_touchAction : TouchActionBits;  // TouchAction

  unsigned m_objectFit : 3;  // ObjectFit

  unsigned m_isolation : 1;  // Isolation

  unsigned m_justifyItems : 4;                   // ItemPosition
  unsigned m_justifyItemsOverflowAlignment : 2;  // OverflowAlignment
  unsigned m_justifyItemsPositionType : 1;  // Whether or not alignment uses the
                                            // 'legacy' keyword.

  unsigned m_justifySelf : 4;                   // ItemPosition
  unsigned m_justifySelfOverflowAlignment : 2;  // OverflowAlignment

 private:
  StyleRareNonInheritedData();
  StyleRareNonInheritedData(const StyleRareNonInheritedData&);
};

}  // namespace blink

#endif  // SKY_ENGINE_CORE_RENDERING_STYLE_STYLERARENONINHERITEDDATA_H_
