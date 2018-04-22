// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/fml/icu_util.h"

#include <memory>
#include <mutex>

#include "flutter/fml/build_config.h"
#include "flutter/fml/mapping.h"
#include "flutter/fml/paths.h"
#include "lib/fxl/logging.h"
#include "third_party/icu/source/common/unicode/udata.h"

namespace fml {
namespace icu {

#if OS_WIN
static constexpr char kPathSeparator = '\\';
#else
static constexpr char kPathSeparator = '/';
#endif

class ICUContext {
 public:
  ICUContext(const std::string& icu_data_path) : valid_(false) {
    valid_ = SetupMapping(icu_data_path) && SetupICU();
  }

  ~ICUContext() = default;

  bool SetupMapping(const std::string& icu_data_path) {
    // Check if the explicit path specified exists.
    auto path_mapping = std::make_unique<FileMapping>(icu_data_path, false);
    if (path_mapping->GetSize() != 0) {
      mapping_ = std::move(path_mapping);
      return true;
    }

    // Check to see if the mapping is in the resources bundle.
    if (PlatformHasResourcesBundle()) {
      auto resource = GetResourceMapping(icu_data_path);
      if (resource != nullptr && resource->GetSize() != 0) {
        mapping_ = std::move(resource);
        return true;
      }
    }

    // Check if the mapping can by directly accessed via a file path. In this
    // case, the data file needs to be next to the executable.
    auto directory = fml::paths::GetExecutableDirectoryPath();

    if (!directory.first) {
      return false;
    }

    auto file = std::make_unique<FileMapping>(
        directory.second + kPathSeparator + icu_data_path, false);
    if (file->GetSize() != 0) {
      mapping_ = std::move(file);
      return true;
    }

    return false;
  }

  bool SetupICU() {
    if (GetSize() == 0) {
      return false;
    }

    UErrorCode err_code = U_ZERO_ERROR;
    udata_setCommonData(GetMapping(), &err_code);
    return (err_code == U_ZERO_ERROR);
  }

  const uint8_t* GetMapping() const {
    return mapping_ ? mapping_->GetMapping() : nullptr;
  }

  size_t GetSize() const { return mapping_ ? mapping_->GetSize() : 0; }

  bool IsValid() const { return valid_; }

 private:
  bool valid_;
  std::unique_ptr<Mapping> mapping_;

  FML_DISALLOW_COPY_AND_ASSIGN(ICUContext);
};

void InitializeICUOnce(const std::string& icu_data_path) {
  static ICUContext* context = new ICUContext(icu_data_path);
  FXL_CHECK(context->IsValid())
      << "Must be able to initialize the ICU context. Tried: " << icu_data_path;
}

std::once_flag g_icu_init_flag;
void InitializeICU(const std::string& icu_data_path) {
  std::call_once(g_icu_init_flag,
                 [&icu_data_path]() { InitializeICUOnce(icu_data_path); });
}

}  // namespace icu
}  // namespace fml
