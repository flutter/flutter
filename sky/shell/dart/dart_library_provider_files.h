// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_SHELL_DART_DART_LIBRARY_PROVIDER_FILES_H_
#define SKY_SHELL_DART_DART_LIBRARY_PROVIDER_FILES_H_

#include "base/files/file_path.h"
#include "flutter/tonic/dart_library_provider.h"
#include "flutter/tonic/parsers/packages_map.h"

namespace sky {
namespace shell {

class DartLibraryProviderFiles : public blink::DartLibraryProvider {
 public:
  DartLibraryProviderFiles();
  ~DartLibraryProviderFiles() override;

  void LoadPackagesMap(const base::FilePath& packages);

 protected:
  // |DartLibraryProvider| implementation:
  void GetLibraryAsStream(const std::string& name,
                          blink::DataPipeConsumerCallback callback) override;
  Dart_Handle CanonicalizeURL(Dart_Handle library, Dart_Handle url) override;

 private:
  base::FilePath GetFilePathForURL(std::string url);
  base::FilePath GetFilePathForPackageURL(std::string url);
  base::FilePath GetFilePathForFileURL(std::string url);

  base::FilePath packages_;
  tonic::PackagesMap packages_map_;

  DISALLOW_COPY_AND_ASSIGN(DartLibraryProviderFiles);
};

}  // namespace shell
}  // namespace sky

#endif  // SKY_SHELL_DART_DART_LIBRARY_PROVIDER_FILES_H_
