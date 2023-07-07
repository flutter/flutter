// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <flutter_linux/flutter_linux.h>

#include "include/url_launcher_linux/url_launcher_plugin.h"

// TODO(stuartmorgan): Remove this private header and change the below back to
// a static function once https://github.com/flutter/flutter/issues/88724
// is fixed, and test through the public API instead.

// Handles the canLaunch method call.
FlMethodResponse* can_launch(FlUrlLauncherPlugin* self, FlValue* args);
