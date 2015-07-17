// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef URL_URL_UTIL_INTERNAL_H_
#define URL_URL_UTIL_INTERNAL_H_

#include <string>

#include "base/strings/string16.h"
#include "url/third_party/mozilla/url_parse.h"

namespace url {

// Given a string and a range inside the string, compares it to the given
// lower-case |compare_to| buffer.
bool CompareSchemeComponent(const char* spec,
                            const Component& component,
                            const char* compare_to);
bool CompareSchemeComponent(const base::char16* spec,
                            const Component& component,
                            const char* compare_to);

}  // namespace url

#endif  // URL_URL_UTIL_INTERNAL_H_
