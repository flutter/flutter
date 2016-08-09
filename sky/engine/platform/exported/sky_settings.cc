// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/sky/engine/public/platform/sky_settings.h"

#include <memory>

#include "lib/ftl/logging.h"

namespace blink {
namespace {

SkySettings* g_settings = nullptr;

}  // namespace

const SkySettings& SkySettings::Get() {
  FTL_CHECK(g_settings);
  return *g_settings;
}

void SkySettings::Set(const SkySettings& settings) {
  FTL_CHECK(!g_settings);
  g_settings = new SkySettings();
  *g_settings = settings;
}

} // namespace blink
