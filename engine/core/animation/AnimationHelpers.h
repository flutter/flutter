// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef AnimationHelpers_h
#define AnimationHelpers_h

#include "core/css/parser/BisonCSSParser.h"
#include "wtf/text/StringBuilder.h"

namespace blink {

static inline CSSPropertyID camelCaseCSSPropertyNameToID(const String& propertyName)
{
    if (propertyName.find('-') != kNotFound)
        return CSSPropertyInvalid;

    StringBuilder builder;
    size_t position = 0;
    size_t end;
    while ((end = propertyName.find(isASCIIUpper, position)) != kNotFound) {
        builder.append(propertyName.substring(position, end - position) + "-" + toASCIILower((propertyName)[end]));
        position = end + 1;
    }
    builder.append(propertyName.substring(position));
    // Doesn't handle prefixed properties.
    CSSPropertyID id = cssPropertyID(builder.toString());
    return id;
}

} // namespace blink

#endif // AnimationHelpers_h
