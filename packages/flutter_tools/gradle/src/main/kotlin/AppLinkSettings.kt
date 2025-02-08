// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.flutter.gradle

data class AppLinkSettings(var applicationId: String = "") {
    var deeplinkingFlagEnabled = false
    var deepLinks = mutableSetOf<DeepLink>()
}
