// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/public/platform/sky_settings.h"

#include <memory>

#include "base/lazy_instance.h"
#include "base/logging.h"

namespace blink {

static base::LazyInstance<SkySettings> s_settings = LAZY_INSTANCE_INITIALIZER;

static bool s_have_settings = false;

const SkySettings& SkySettings::Get() {
  return s_settings.Get();
}

void SkySettings::Set(const SkySettings& settings) {
  CHECK(!s_have_settings);
  s_settings.Get() = settings;
  s_have_settings = true;
}

} // namespace blink
