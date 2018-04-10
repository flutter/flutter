// Copyright 2017 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_COMMON_RUN_CONFIGURATION_H_
#define FLUTTER_SHELL_COMMON_RUN_CONFIGURATION_H_

#include <memory>
#include <string>

#include "flutter/assets/asset_manager.h"
#include "flutter/assets/asset_resolver.h"
#include "flutter/common/settings.h"
#include "flutter/fml/mapping.h"
#include "flutter/shell/common/isolate_configuration.h"
#include "lib/fxl/files/unique_fd.h"
#include "lib/fxl/macros.h"

namespace shell {

class RunConfiguration {
 public:
  static RunConfiguration InferFromSettings(const blink::Settings& settings);

  RunConfiguration(std::unique_ptr<IsolateConfiguration> configuration);

  RunConfiguration(std::unique_ptr<IsolateConfiguration> configuration,
                   fxl::RefPtr<blink::AssetManager> asset_manager);

  RunConfiguration(RunConfiguration&&);

  ~RunConfiguration();

  bool IsValid() const;

  bool AddAssetResolver(std::unique_ptr<blink::AssetResolver> resolver);

  void SetEntrypoint(std::string entrypoint);

  fxl::RefPtr<blink::AssetManager> GetAssetManager() const;

  const std::string& GetEntrypoint() const;

  std::unique_ptr<IsolateConfiguration> TakeIsolateConfiguration();

 private:
  std::unique_ptr<IsolateConfiguration> isolate_configuration_;
  fxl::RefPtr<blink::AssetManager> asset_manager_;
  std::string entrypoint_ = "main";

  FXL_DISALLOW_COPY_AND_ASSIGN(RunConfiguration);
};

}  // namespace shell

#endif  // FLUTTER_SHELL_COMMON_RUN_CONFIGURATION_H_
