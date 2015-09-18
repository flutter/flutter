// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Modeled after Android's ViewConfiguration:
// https://github.com/android/platform_frameworks_base/blob/master/core/java/android/view/ViewConfiguration.java

// TODO(ianh): Figure out actual specced height for status bar
const double kStatusBarHeight = 50.0;

// TODO(eseidel) Toolbar needs to change size based on orientation:
// http://www.google.com/design/spec/layout/structure.html#structure-app-bar
// Mobile Landscape: 48dp
// Mobile Portrait: 56dp
// Tablet/Desktop: 64dp
const double kToolBarHeight = 56.0;

const double kMaterialDrawerHeight = 140.0;
const double kScrollbarSize = 10.0;
const double kScrollbarFadeDuration = 250.0;
const double kScrollbarFadeDelay = 300.0;
const double kFadingEdgeLength = 12.0;
const double kPressedStateDuration = 64.0;
