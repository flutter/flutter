// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef URL_DEPRECATED_SERIALIZED_ORIGIN_H_
#define URL_DEPRECATED_SERIALIZED_ORIGIN_H_

#include <string>

#include "url/url_export.h"

namespace url {

// DeprecatedSerializedOrigin represents a Web Origin serialized to a string.
// See RFC6454 for details.
//
// TODO(mkwst): Replace callsites with 'url::SchemeHostPort' or 'Origin', once
// those classes exist.
class URL_EXPORT DeprecatedSerializedOrigin {
 public:
  DeprecatedSerializedOrigin();
  explicit DeprecatedSerializedOrigin(const std::string& origin);

  const std::string& string() const { return string_; }

  bool IsSameAs(const DeprecatedSerializedOrigin& that) const {
    return string_ == that.string_;
  }

 private:
  std::string string_;
};

}  // namespace url

#endif  // URL_DEPRECATED_SERIALIZED_ORIGIN_H_
