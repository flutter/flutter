// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "flutter/fml/macros.h"
#include "impeller/typographer/backends/stb/typeface_stb.h"
#include "impeller/typographer/text_frame.h"

namespace impeller {

std::shared_ptr<TextFrame> MakeTextFrameSTB(
    const std::shared_ptr<TypefaceSTB>& typeface_stb,
    Font::Metrics metrics,
    const std::string& text);

}  // namespace impeller
