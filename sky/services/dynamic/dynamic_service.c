// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/services/dynamic/dynamic_service.h"

const struct FlutterServiceVersion* FlutterServiceGetVersion() {
  static const struct FlutterServiceVersion version = {
      .major = 1,  // updated on breaking changes
      .minor = 0,  // updated on augments
      .patch = 0,  // informational, embedder does not care
  };
  return &version;
}

bool FlutterServiceVersionsCompatible(
    const struct FlutterServiceVersion* embedder_version,
    const struct FlutterServiceVersion* service_version) {
  if (embedder_version == NULL || service_version == NULL) {
    return false;
  }

  if (embedder_version->major != service_version->major) {
    return false;
  }

  if (embedder_version->minor < service_version->minor) {
    return false;
  }

  return true;
}
