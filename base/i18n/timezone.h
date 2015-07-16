// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_I18N_TIMEZONE_H_
#define BASE_I18N_TIMEZONE_H_

#include <string>

#include "base/i18n/base_i18n_export.h"

namespace base {

// Checks the system timezone and turns it into a two-character ASCII country
// code. This may fail (for example, it will always fail on Android), in which
// case it will return an empty string.
BASE_I18N_EXPORT std::string CountryCodeForCurrentTimezone();

}  // namespace base

#endif  // BASE_I18N_TIMEZONE_H_
