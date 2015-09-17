// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_TEXT_TEXTSTYLE_H_
#define SKY_ENGINE_CORE_TEXT_TEXTSTYLE_H_

#include "sky/engine/core/painting/CanvasColor.h"
#include "sky/engine/core/text/FontStyle.h"
#include "sky/engine/core/text/FontWeight.h"
#include "sky/engine/core/text/TextDecoration.h"
#include "sky/engine/core/text/TextDecorationStyle.h"
#include "sky/engine/tonic/dart_wrappable.h"
#include "sky/engine/wtf/PassRefPtr.h"
#include "sky/engine/wtf/RefCounted.h"
#include "sky/engine/wtf/Vector.h"

namespace blink {

class TextStyle : public RefCounted<TextStyle>, public DartWrappable {
    DEFINE_WRAPPERTYPEINFO();
public:
    static PassRefPtr<TextStyle> create(
      SkColor color = SK_ColorWHITE,
      const String& fontFamily = nullAtom,
      double fontSize = 0.0,
      FontWeight fontWeight = FontWeightNormal,
      FontStyle fontStyle = FontStyleNormal,
      const Vector<TextDecoration>& decoration = Vector<TextDecoration>(),
      SkColor decorationColor = SK_ColorWHITE,
      TextDecorationStyle decorationStyle = TextDecorationStyleSolid
    ) {
      return adoptRef(new TextStyle(
        color,
        fontFamily,
        fontSize,
        fontWeight,
        fontStyle,
        decoration,
        decorationColor,
        decorationStyle
      ));
    }

    ~TextStyle() override;

    SkColor color() const { return m_color; }
    const String& fontFamily() const { return m_fontFamily; }
    double fontSize() const { return m_fontSize; }
    FontWeight fontWeight() const { return m_fontWeight; }
    FontStyle fontStyle() const { return m_fontStyle; }
    TextDecoration decoration() const { return m_decoration; }
    SkColor decorationColor() const { return m_decorationColor; }
    TextDecorationStyle decorationStyle() const { return m_decorationStyle; }

private:
    explicit TextStyle(
        SkColor color,
        const String& fontFamily,
        double fontSize,
        FontWeight fontWeight,
        FontStyle fontStyle,
        const Vector<TextDecoration>& decoration,
        SkColor decorationColor,
        TextDecorationStyle decorationStyle
    );

    SkColor m_color;
    String m_fontFamily;
    double m_fontSize;
    FontWeight m_fontWeight;
    FontStyle m_fontStyle;
    TextDecoration m_decoration;
    SkColor m_decorationColor;
    TextDecorationStyle m_decorationStyle;
};

} // namespace blink

#endif  // SKY_ENGINE_CORE_TEXT_TEXTSTYLE_H_
