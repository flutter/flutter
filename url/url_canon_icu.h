// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef URL_URL_CANON_ICU_H_
#define URL_URL_CANON_ICU_H_

// ICU integration functions.

#include "base/compiler_specific.h"
#include "url/url_canon.h"
#include "url/url_export.h"

typedef struct UConverter UConverter;

namespace url {

// An implementation of CharsetConverter that implementations can use to
// interface the canonicalizer with ICU's conversion routines.
class URL_EXPORT ICUCharsetConverter : public CharsetConverter {
 public:
  // Constructs a converter using an already-existing ICU character set
  // converter. This converter is NOT owned by this object; the lifetime must
  // be managed by the creator such that it is alive as long as this is.
  ICUCharsetConverter(UConverter* converter);

  ~ICUCharsetConverter() override;

  void ConvertFromUTF16(const base::char16* input,
                        int input_len,
                        CanonOutput* output) override;

 private:
  // The ICU converter, not owned by this class.
  UConverter* converter_;
};

}  // namespace url

#endif  // URL_URL_CANON_ICU_H_
