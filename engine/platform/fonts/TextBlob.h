// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef TextBlob_h
#define TextBlob_h

#include "third_party/skia/include/core/SkTextBlob.h"
#include "wtf/PassRefPtr.h"
#include "wtf/RefPtr.h"

namespace blink {

// Holds a (mutable) reference to an immutable SkTextBlob.
// Typedefs are used only to insulate core/ from Skia type names.
typedef RefPtr<const SkTextBlob> TextBlobPtr;
typedef PassRefPtr<const SkTextBlob> PassTextBlobPtr;

} // namespace blink

#endif // TextBlob_h
