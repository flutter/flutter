// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_PLATFORM_FONTS_TEXTBLOB_H_
#define SKY_ENGINE_PLATFORM_FONTS_TEXTBLOB_H_

#include "third_party/skia/include/core/SkRefCnt.h"
#include "third_party/skia/include/core/SkTextBlob.h"

namespace blink {

// Holds a (mutable) reference to an immutable SkTextBlob.
// Typedefs are used only to insulate core/ from Skia type names.
typedef sk_sp<const SkTextBlob> TextBlobPtr;

}  // namespace blink

#endif  // SKY_ENGINE_PLATFORM_FONTS_TEXTBLOB_H_
