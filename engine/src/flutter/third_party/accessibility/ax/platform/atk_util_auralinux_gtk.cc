// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <atk-bridge.h>

#include "base/environment.h"
#include "ui/accessibility/platform/atk_util_auralinux.h"

namespace ui {

void AtkUtilAuraLinux::PlatformInitializeAsync() {
  // AT bridge enabling was disabled before loading GTK to avoid
  // getting GTK implementation ATK root.
  std::unique_ptr<base::Environment> env(base::Environment::Create());
  env->UnSetVar("NO_AT_BRIDGE");
  atk_bridge_adaptor_init(nullptr, nullptr);
}

}  // namespace ui
