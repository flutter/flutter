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
      int fontWeight = 0,
      int fontStyle = 0,
      const Vector<int>& decoration = Vector<int>(),
      SkColor decorationColor = SK_ColorWHITE,
      int decorationStyle = 0
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

private:
    explicit TextStyle(
        SkColor color,
        const String& fontFamily,
        double fontSize,
        int fontWeight,
        int fontStyle,
        const Vector<int>& decoration,
        SkColor decorationColor,
        int decorationStyle
    );
};

} // namespace blink

#endif  // SKY_ENGINE_CORE_TEXT_TEXTSTYLE_H_
