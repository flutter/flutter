// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_ANIMATION_CSS_CSSPROPERTYEQUALITY_H_
#define SKY_ENGINE_CORE_ANIMATION_CSS_CSSPROPERTYEQUALITY_H_

#include "gen/sky/core/CSSPropertyNames.h"

namespace blink {

class RenderStyle;

class CSSPropertyEquality {
public:
    static bool propertiesEqual(CSSPropertyID, const RenderStyle&, const RenderStyle&);
};

} // namespace blink

#endif  // SKY_ENGINE_CORE_ANIMATION_CSS_CSSPROPERTYEQUALITY_H_
