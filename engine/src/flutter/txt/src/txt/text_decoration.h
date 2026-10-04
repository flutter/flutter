// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_TXT_SRC_TXT_TEXT_DECORATION_H_
#define FLUTTER_TXT_SRC_TXT_TEXT_DECORATION_H_

namespace txt {

// Multiple decorations can be applied at once. Ex: Underline and overline is
// (0x1 | 0x2)
enum TextDecoration {
  kNone = 0x0,
  kUnderline = 0x1,
  kOverline = 0x2,
  kLineThrough = 0x4,
};

enum TextDecorationStyle { kSolid, kDouble, kDotted, kDashed, kWavy };

}  // namespace txt

#endif  // FLUTTER_TXT_SRC_TXT_TEXT_DECORATION_H_
