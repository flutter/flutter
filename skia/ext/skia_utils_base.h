// Copyright (c) 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKIA_EXT_SKIA_UTILS_BASE_H_
#define SKIA_EXT_SKIA_UTILS_BASE_H_

#include "base/pickle.h"
#include "third_party/skia/include/ports/SkFontConfigInterface.h"

namespace skia {

// Return true if the pickle/iterator contains a string. If so, and if str
// is not null, copy that string into str.
SK_API bool ReadSkString(base::PickleIterator* iter, SkString* str);

// Return true if the pickle/iterator contains a FontIdentity. If so, and if
// identity is not null, copy it into identity.
SK_API bool ReadSkFontIdentity(base::PickleIterator* iter,
                               SkFontConfigInterface::FontIdentity* identity);

// Return true if str can be written into the request pickle.
SK_API bool WriteSkString(base::Pickle* pickle, const SkString& str);

// Return true if identity can be written into the request pickle.
SK_API bool WriteSkFontIdentity(
    base::Pickle* pickle,
    const SkFontConfigInterface::FontIdentity& identity);

}  // namespace skia

#endif  // SKIA_EXT_SKIA_UTILS_BASE_H_

