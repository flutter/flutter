// Copyright 2018 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_COMMON_ISOLATE_CONFIGURATION_H_
#define FLUTTER_SHELL_COMMON_ISOLATE_CONFIGURATION_H_

#include <memory>
#include <string>

#include "flutter/assets/asset_manager.h"
#include "flutter/assets/asset_resolver.h"
#include "flutter/common/settings.h"
#include "flutter/fml/macros.h"
#include "flutter/fml/mapping.h"
#include "flutter/fml/memory/weak_ptr.h"
#include "flutter/runtime/dart_isolate.h"

namespace shell {

class IsolateConfiguration {
 public:
  static std::unique_ptr<IsolateConfiguration> InferFromSettings(
      const blink::Settings& settings,
      fml::RefPtr<blink::AssetManager> asset_manager);

  static std::unique_ptr<IsolateConfiguration> CreateForAppSnapshot();

  static std::unique_ptr<IsolateConfiguration> CreateForKernel(
      std::unique_ptr<fml::Mapping> kernel);

  static std::unique_ptr<IsolateConfiguration> CreateForKernelList(
      std::vector<std::unique_ptr<fml::Mapping>> kernel_pieces);

  IsolateConfiguration();

  virtual ~IsolateConfiguration();

  bool PrepareIsolate(blink::DartIsolate& isolate);

 protected:
  virtual bool DoPrepareIsolate(blink::DartIsolate& isolate) = 0;

 private:
  FML_DISALLOW_COPY_AND_ASSIGN(IsolateConfiguration);
};

}  // namespace shell

#endif  // FLUTTER_SHELL_COMMON_ISOLATE_CONFIGURATION_H_
