// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_TONIC_PARSERS_PACKAGES_MAP_H_
#define SKY_ENGINE_TONIC_PARSERS_PACKAGES_MAP_H_

#include <unordered_map>
#include <string>

namespace tonic {

class PackagesMap {
 public:
  PackagesMap();
  ~PackagesMap();

  bool Parse(const std::string& source, std::string* error);
  std::string Resolve(const std::string& package_name);

 private:
  std::unordered_map<std::string, std::string> map_;
};

}  // namespace tonic

#endif  // SKY_ENGINE_TONIC_PARSERS_PACKAGES_MAP_H_
