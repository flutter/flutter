// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/shell/updater/manifest.h"

#include "base/strings/string_split.h"
#include "base/strings/string_util.h"

namespace sky {
namespace shell {

// static
scoped_ptr<Manifest> Manifest::Parse(const std::string& manifest_data) {
  scoped_ptr<Manifest> manifest(new Manifest);

  // Poor man's YAML parsing.
  // TODO(mpcomplete): use an actual YAML parser.
  base::StringPairs key_values;
  base::SplitStringIntoKeyValuePairs(manifest_data, ':', '\n', &key_values);
  for (const auto& key_value : key_values) {
    auto value = base::TrimWhitespaceASCII(key_value.second, base::TRIM_ALL);
    if (key_value.first == "update_url") {
      manifest->update_url_ = GURL(value.as_string());
    } else if (key_value.first == "version") {
      manifest->version_ = base::Version(value.as_string());
    }
  }
  return manifest;
}

}  // namespace shell
}  // namespace sky
