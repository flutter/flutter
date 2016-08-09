// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_ASSETS_ZIP_ASSET_STORE_H_
#define FLUTTER_ASSETS_ZIP_ASSET_STORE_H_

#include <map>
#include <vector>

#include "lib/ftl/macros.h"
#include "lib/ftl/memory/ref_counted.h"
#include "lib/ftl/tasks/task_runner.h"
#include "mojo/public/cpp/system/data_pipe.h"

namespace blink {

class ZipAssetStore : public ftl::RefCountedThreadSafe<ZipAssetStore> {
 public:
  ZipAssetStore(std::string zip_path, ftl::RefPtr<ftl::TaskRunner> task_runner);
  ~ZipAssetStore();

  // Serve this asset from another file instead of using the ZIP contents.
  void AddOverlayFile(std::string asset_name, std::string file_path);

  void GetAsStream(const std::string& asset_name,
                   mojo::ScopedDataPipeProducerHandle producer);
  bool GetAsBuffer(const std::string& asset_name, std::vector<uint8_t>* data);

 private:
  const std::string zip_path_;
  ftl::RefPtr<ftl::TaskRunner> task_runner_;
  std::map<std::string, std::string> overlay_files_;

  FTL_DISALLOW_COPY_AND_ASSIGN(ZipAssetStore);
};

}  // namespace blink

#endif  // FLUTTER_ASSETS_ZIP_ASSET_STORE_H_
