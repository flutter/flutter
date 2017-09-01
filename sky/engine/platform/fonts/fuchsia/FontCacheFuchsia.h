// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_PLATFORM_FONTS_FUCHSIA_FONT_CACHE_FUCHSIA_H_
#define SKY_ENGINE_PLATFORM_FONTS_FUCHSIA_FONT_CACHE_FUCHSIA_H_

#include "lib/fonts/fidl/font_provider.fidl.h"

namespace blink {

void SetFontProvider(fonts::FontProviderPtr provider);

}  // namespace blink

#endif  // SKY_ENGINE_PLATFORM_FONTS_FUCHSIA_FONT_CACHE_FUCHSIA_H_
