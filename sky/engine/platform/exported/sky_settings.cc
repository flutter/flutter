// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/public/platform/sky_settings.h"

#include "base/logging.h"

namespace blink {

static SkySettings s_settings;
static bool s_have_settings = false;

const SkySettings& SkySettings::Get() {
  return s_settings;
}

void SkySettings::Set(const SkySettings& settings) {
  CHECK(!s_have_settings);
  s_settings = settings;
  s_have_settings = true;
}

} // namespace blink
