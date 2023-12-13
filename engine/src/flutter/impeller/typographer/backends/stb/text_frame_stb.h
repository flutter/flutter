// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_TYPOGRAPHER_BACKENDS_STB_TEXT_FRAME_STB_H_
#define FLUTTER_IMPELLER_TYPOGRAPHER_BACKENDS_STB_TEXT_FRAME_STB_H_

#include "flutter/fml/macros.h"
#include "impeller/typographer/backends/stb/typeface_stb.h"
#include "impeller/typographer/text_frame.h"

namespace impeller {

std::shared_ptr<TextFrame> MakeTextFrameSTB(
    const std::shared_ptr<TypefaceSTB>& typeface_stb,
    Font::Metrics metrics,
    const std::string& text);

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_TYPOGRAPHER_BACKENDS_STB_TEXT_FRAME_STB_H_
