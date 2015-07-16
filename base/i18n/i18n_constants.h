// Copyright (c) 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_I18N_I18N_CONSTANTS_H_
#define BASE_I18N_I18N_CONSTANTS_H_

#include "base/i18n/base_i18n_export.h"

namespace base {

// Names of codepages (charsets) understood by icu.
BASE_I18N_EXPORT extern const char kCodepageLatin1[];  // a.k.a. ISO 8859-1
BASE_I18N_EXPORT extern const char kCodepageUTF8[];

// The other possible options are UTF-16BE and UTF-16LE, but they are unused in
// Chromium as of this writing.

}  // namespace base

#endif  // BASE_I18N_I18N_CONSTANTS_H_
